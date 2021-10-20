const { expect } = require("chai");
const { ethers } = require("hardhat");

const Status = {
  Upcoming: 0,
  Ongoing: 1,
  Finished: 2,
  Paused: 3,
  Cancelled: 4,
};

const ONE_ETH = ethers.utils.parseEther("1");

describe("IDO stateful fuzz and invariant tests", () => {
  let snapshot: string;

  beforeEach(async () => {
    snapshot = await ethers.provider.send("evm_snapshot", []);
  });

  afterEach(async () => {
    await ethers.provider.send("evm_revert", [snapshot]);
  });

  async function fixture() {
    const signers = await ethers.getSigners();
    const owner = signers[1];
    const users = signers.slice(2, 7);
    const IDO = await ethers.getContractFactory("IDO");
    const ido = await IDO.deploy();
    await ido.deployed();

    const Token = await ethers.getContractFactory("ProjectToken");
    const token = await Token.deploy("Project Token", "PT", 1_000_000);
    await token.deployed();
    await token.transfer(ido.address, 100_000);

    const now = (await ethers.provider.getBlock("latest")).timestamp;
    await ido.grantPoolOwnerRole(owner.address);
    await ido.connect(owner).createPool(
      ethers.utils.parseEther("20"),
      ethers.utils.parseEther("5"),
      now + 10,
      now + 10_000,
      Status.Upcoming
    );
    await ido.connect(owner).addIDOInfo(
      owner.address,
      token.address,
      1,
      10,
      100,
      1,
      1,
      0
    );
    await ido.connect(owner).addAddressesToWhitelist(users.map((user: any) => user.address));
    await ethers.provider.send("evm_setNextBlockTimestamp", [now + 10]);
    return { ido, token, owner, users };
  }

  async function setStatus(ido: any, owner: any, status: number) {
    await ido.connect(owner).updatePoolStatus(status);
  }

  async function totalRaised(ido: any) {
    const details = await ido.getCompletePoolDetails();
    return details.totalRaised;
  }

  async function expectRevert(action: Promise<any>) {
    let reverted = false;
    try {
      await action;
    } catch (error) {
      reverted = true;
    }
    expect(reverted).to.be.true;
  }

  it("preserves cap and participant-total invariants across generated deposits", async () => {
    const { ido, owner, users } = await fixture();
    await setStatus(ido, owner, Status.Ongoing);

    // Deterministic pseudo-random sequence, seed 0x5eed.
    let seed = 0x5eed;
    let expectedRaised = ethers.constants.Zero;
    const expectedByUser: Record<string, any> = {};

    for (let i = 0; i < 24; i++) {
      seed = (seed * 1103515245 + 12345) >>> 0;
      const user = users[seed % users.length];
      const amount = ((seed >>> 8) % 3) + 1;
      const value = ONE_ETH.mul(amount);
      const before = await ido.getCompletePoolDetails();
      const previous = expectedByUser[user.address] || ethers.constants.Zero;
      const accepted = previous.add(value).lte(ethers.utils.parseEther("10"));

      if (accepted && expectedRaised.add(value).lte(ethers.utils.parseEther("20"))) {
        await user.sendTransaction({ to: ido.address, value });
        expectedRaised = expectedRaised.add(value);
        expectedByUser[user.address] = previous.add(value);
      } else {
        await expectRevert(user.sendTransaction({ to: ido.address, value }));
        expect((await totalRaised(ido)).eq(before.totalRaised)).to.be.true;
      }

      const details = await ido.getCompletePoolDetails();
      expect(details.totalRaised.eq(expectedRaised)).to.be.true;
      expect(details.totalRaised.lte(ethers.utils.parseEther("20"))).to.be.true;
      const summed = details.participationDetails.investorsDetails.reduce(
        (sum: any, participant: any) => sum.add(participant.totalRaisedInWei),
        ethers.constants.Zero
      );
      expect(summed.eq(details.totalRaised)).to.be.true;
    }
  });

  it("enforces cumulative allocation bounds and rolls back rejected deposits", async () => {
    const { ido, owner, users } = await fixture();
    await setStatus(ido, owner, Status.Ongoing);

    await expectRevert(users[0].sendTransaction({ to: ido.address, value: ONE_ETH.div(2) }));
    await users[0].sendTransaction({ to: ido.address, value: ONE_ETH.mul(4) });
    const before = await totalRaised(ido);

    await expectRevert(users[0].sendTransaction({ to: ido.address, value: ONE_ETH.mul(7) }));
    expect((await totalRaised(ido)).eq(before)).to.be.true;

    await users[1].sendTransaction({ to: ido.address, value: ONE_ETH.mul(10) });
    await expectRevert(users[2].sendTransaction({ to: ido.address, value: ONE_ETH.mul(11) }));
    expect((await totalRaised(ido)).eq(ethers.utils.parseEther("14"))).to.be.true;
  });

  it("conserves funded tokens and pays each generated participant once", async () => {
    const { ido, token, owner, users } = await fixture();
    await setStatus(ido, owner, Status.Ongoing);
    for (let i = 0; i < users.length; i++) {
      await users[i].sendTransaction({ to: ido.address, value: ONE_ETH });
    }
    await setStatus(ido, owner, Status.Finished);

    const initialBalance = await token.balanceOf(ido.address);
    let paid = ethers.constants.Zero;
    for (const user of [...users].reverse()) {
      const before = await token.balanceOf(user.address);
      await ido.connect(user).refund();
      const amount = (await token.balanceOf(user.address)).sub(before);
      expect(amount.eq(1)).to.be.true;
      paid = paid.add(amount);
      await expectRevert(ido.connect(user).refund());
    }
    expect((await token.balanceOf(ido.address)).eq(initialBalance.sub(paid))).to.be.true;
    expect(paid.eq(users.length)).to.be.true;
  });

  it("accepts only the declared lifecycle transitions", async () => {
    const allowed: Record<number, number[]> = {
      [Status.Upcoming]: [Status.Ongoing, Status.Cancelled],
      [Status.Ongoing]: [Status.Paused, Status.Finished, Status.Cancelled],
      [Status.Paused]: [Status.Ongoing, Status.Cancelled],
    };

    for (const current of [Status.Upcoming, Status.Ongoing, Status.Paused, Status.Finished, Status.Cancelled]) {
      const candidates = [Status.Upcoming, Status.Ongoing, Status.Finished, Status.Paused, Status.Cancelled];
      for (const next of candidates) {
        const state = await fixture();
        if (current === Status.Ongoing) {
          await setStatus(state.ido, state.owner, Status.Ongoing);
        } else if (current === Status.Paused) {
          await setStatus(state.ido, state.owner, Status.Ongoing);
          await setStatus(state.ido, state.owner, Status.Paused);
        } else if (current === Status.Finished) {
          await setStatus(state.ido, state.owner, Status.Ongoing);
          await setStatus(state.ido, state.owner, Status.Finished);
        } else if (current === Status.Cancelled) {
          await setStatus(state.ido, state.owner, Status.Cancelled);
        }
        const shouldPass = (allowed[current] || []).includes(next);
        if (shouldPass) {
          await state.ido.connect(state.owner).updatePoolStatus(next);
        } else {
          await expectRevert(state.ido.connect(state.owner).updatePoolStatus(next));
        }
      }
    }
  });
});
