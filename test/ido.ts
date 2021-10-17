const { expect } = require("chai");
const { ethers, Web3, web3 } = require("hardhat");
require("dotenv").config();

let idoContract: any;
let projectTokenContract: any;
let poolContractAddress: any;

let poolOwner: any;

let now: any;
let tomorrow: any;

let depositor1: any;
let depositor2: any;
let nonWhitelistedDepositor3: any;

const hardCapWEI = ethers.utils.parseEther("1000");
const softCapWEI = ethers.utils.parseEther("500");
let countOfProvidedToken = "1000";
const projectTokenInitialSupply = 10000;
const PoolStatus = {
  Upcoming: 0,
  Ongoing: 1,
  Finished: 2,
  Paused: 3,
  Cancelled: 4,
};

describe("IDO", async () => {
  before(async () => {
    if (process.env.NETWORK_GATEWAY_API?.length == 0) {
      console.error("ERROR: set environment variables first");
      process.exit(-1);
    }

    [, poolOwner, depositor1, depositor2, nonWhitelistedDepositor3] =
      await ethers.getSigners();
    now = new Date();
    tomorrow = now.getTime() + 10000; // new Date(new Date().setDate(now.getDate() + 1));

    await deployIDO();

    await deployProjectToken(projectTokenInitialSupply);
    await transferProjectToken(
      idoContract.address,
      _bigNumber(countOfProvidedToken)
    );
    await afterTokenTransferCheck();
  });

  describe("UC-D1: Create a Pool", async () => {
    it("only poolOwner can create the Pool", async () => {
      try {
        await idoContract
          .connect(poolOwner)
          .createPool(
            hardCapWEI,
            softCapWEI,
            now.getTime(),
            tomorrow,
            PoolStatus.Upcoming
          );
        expect(false).to.be.true;
      } catch (error) {
        expect(true).to.be.true;
      }

      // Grant PoolOwner role to poolOwner account
      const success = await idoContract.callStatic.grantPoolOwnerRole(
        poolOwner.address
      );
      await idoContract.grantPoolOwnerRole(poolOwner.address);
      expect(success);
    });

    it("PoolInfo is only available after creation", async () => {
      try {
        await idoContract.getCompletePoolDetails();
        expect(false).to.be.true;
      } catch (error) {
        expect(true).to.be.true;
      }
    });

    it("[1/2] create the Pool (in Upcoming state)", async () => {
      await createThePool();

      poolContractAddress = await idoContract.connect(poolOwner).poolAddress();
      expect(poolContractAddress.length).be.gt(0);
    });

    it("One time per Project", async () => {
      try {
        await createThePool();
        expect(false).to.be.true;
      } catch (error) {
        expect(true).to.be.true;
      }
    });

    it("[2/2] add IDO related info to the Pool", async () => {
      await addIDOInfo();
    });

    it("Once per Project", async () => {
      try {
        await addIDOInfo();
        expect(false).to.be.true;
      } catch (error) {
        expect(true).to.be.true;
      }
    });
  });

  describe("UC-D2: Get Pool data", async () => {
    it("get the Pool information", async () => {
      const cpd = await idoContract.getCompletePoolDetails();
      expect(ethers.BigNumber.from(cpd.pool.softCap).eq(softCapWEI));
      expect(cpd.poolDetails.projectTokenAddress).be.equal(
        projectTokenContract.address
      );
      expect(cpd.pool.status).be.equal(PoolStatus.Upcoming);
      expect(cpd.poolDetails.exchangeRate.toString()).be.equal("1");
      expect(cpd.participationDetails.count.toString()).be.equal("0");
    });
    // TODO get participations to
  });

  describe("UC-D3: Add Users to whitelist of a Pool", async () => {
    it("PoolOwner adds users to whitelist", async () => {
      await whitelistAddress([depositor1.address]);
      await whitelistAddress([depositor2.address]);
    });
  });

  describe("UC-D4: Invest in a Pool", async () => {
    it("whitelisted accounts, deposit only if the Pool status is Ongoing", async () => {
      const success = await depositETH(depositor1, "1.0");
      expect(success).to.be.false;

      await updatePoolStatus(PoolStatus.Ongoing);

      const poolBalanceBefore = await weiBalance(poolContractAddress);
      const valueToDepositInETH = "1.0";
      const value = ethers.utils.parseEther(valueToDepositInETH);

      expect(await depositETH(depositor1, valueToDepositInETH)).to.be.true;
      expect(await depositETH(depositor2, valueToDepositInETH)).to.be.true;

      const afterDepositPoolBalance = await weiBalance(poolContractAddress);
      expect(
        compareBigNumbers(
          _bigNumber(poolBalanceBefore + value * 2), //Depositor 1 and 2 each deposited 1 ETH
          afterDepositPoolBalance
        )
      ).to.be.true;
    });
    it("non whitelisted can not deposit", async () => {
      const success = await depositETH(nonWhitelistedDepositor3, "1.0");
      expect(success).to.be.false;
    });
  });

  describe("UC-D5: Retrieve tokens from the Pool (from the investor side)", async () => {
    it("pool should keep trac of deposits", async () => {
      const details = await idoContract.getCompletePoolDetails();
      const participants = details.participationDetails;

      expect(_bigNumber(participants.count).toNumber()).be.equal(2);

      expect(participants.investorsDetails[0].addressOfParticipant).be.equal(
        depositor1.address
      );
      expect(participants.investorsDetails[1].addressOfParticipant).be.equal(
        depositor2.address
      );
      expect(details.totalRaised.eq(ethers.utils.parseEther("2.0")));
    });

    it("withdraw can only happen if the Pool status is Finished", async () => {
      expect(await refund(depositor1.address)).to.be.false;

      await updatePoolStatus(PoolStatus.Finished);

      const depositor1TokenSupplyBefore = await projectTokenBalance(
        depositor1.address
      );
      const depositor2TokenSupplyBefore = await projectTokenBalance(
        depositor2.address
      );
      const idoTokenSupplyBefore = await projectTokenBalance(
        idoContract.address
      );

      expect(await refund(depositor1)).to.be.true;
      expect(await refund(depositor2)).to.be.true;

      expect(
        compareBigNumbers(
          idoTokenSupplyBefore,
          await projectTokenBalance(idoContract.address)
        )
      ).to.be.false;

      expect(
        depositor1TokenSupplyBefore <
          (await projectTokenBalance(depositor1.address))
      ).to.be.true;

      expect(
        depositor2TokenSupplyBefore <
          (await projectTokenBalance(depositor2.address))
      ).to.be.true;
    });

    it("Participants can withdraw only once", async () => {
      expect(await refund(depositor1)).to.be.false;
      expect(await refund(depositor2)).to.be.false;
    });
  });
});

async function deployIDO(): Promise<void> {
  const IDO = await ethers.getContractFactory("IDO");
  idoContract = await IDO.deploy();
  await idoContract.deployed();
  expect(idoContract.address.length).be.gt(0);
}

async function deployProjectToken(
  _initialSupply: string | number
): Promise<void> {
  const RT = await ethers.getContractFactory("ProjectToken");

  projectTokenContract = await RT.deploy(
    "Project Token",
    "RTK",
    _initialSupply
  );
}

async function transferProjectToken(
  _idoContractAddress: string,
  _amount: string
): Promise<void> {
  await projectTokenContract.transfer(_idoContractAddress, _amount);
}

async function projectTokenBalance(_address: string): Promise<any> {
  const balance = await projectTokenContract.balanceOf(_address);
  return balance;
}

async function weiBalance(_address: string): Promise<any> {
  const weiBalance = await ethers.provider.getBalance(_address);
  return weiBalance;
}

async function afterTokenTransferCheck() {
  const idoTokenBalance = await projectTokenBalance(idoContract.address);
  expect(_bigNumber(idoTokenBalance).eq(countOfProvidedToken));
}

async function createThePool(): Promise<void> {
  await idoContract.connect(poolOwner).createPool(
    hardCapWEI,
    softCapWEI,
    now.getTime(), // start time
    tomorrow, // end time
    PoolStatus.Upcoming
  );
}

async function addIDOInfo(): Promise<void> {
  await idoContract.connect(poolOwner).addIDOInfo(
    process.env.RAISED_WEI_RECEIVER_ADDRESS, // project owner
    projectTokenContract.address,
    1, // min allocation per user
    10, // max allocation per user
    1000000, // total token provided 1_000_000
    1, // exchange rate
    1, // token price
    0 // total token sold
  );
}

async function updatePoolStatus(_newStatus: number): Promise<void> {
  await idoContract.connect(poolOwner).updatePoolStatus(_newStatus);
}

async function depositETH(
  _senderAccount: any,
  _valueInETH: string
): Promise<boolean> {
  try {
    await _senderAccount.sendTransaction({
      to: idoContract.address,
      value: ethers.utils.parseEther(_valueInETH),
    });
    return true;
  } catch (error) {
    return false;
  }
}

async function whitelistAddress(_addresses: string[]): Promise<void> {
  await idoContract.connect(poolOwner).addAddressesToWhitelist(_addresses);
}

async function refund(_participantAccount: string): Promise<boolean> {
  try {
    await idoContract.connect(_participantAccount).refund();
    return true;
  } catch (error) {
    return false;
  }
}

function _bigNumber(_num: string | number) {
  //TODO how to specify return type BigNumber
  return ethers.BigNumber.from(_num);
}

function compareBigNumbers(a: any, b: any): Promise<any> {
  return ethers.BigNumber.from(a).eq(b);
}
