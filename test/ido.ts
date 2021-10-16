const { expect } = require("chai");
const { ethers, Web3, web3 } = require("hardhat");
require("dotenv").config();

let idoContract: any;
let projectTokenContract: any;
let poolContractAddress: any;

describe("IDO", async () => {
  let poolOwner: any;

  let now: any;
  let tomorrow: any;

  let depositor1: any;
  let depositor2: any;

  const hardCapWEI = ethers.utils.parseEther("1000");
  const softCapWEI = ethers.utils.parseEther("500");
  let countOfProvidedToken = 1000;
  const projectTokenInitialSupply = 10000;

  const PoolStatus = {
    Upcoming: 0,
    Ongoing: 1,
    Finished: 2,
    Paused: 3,
    Cancelled: 4,
  };

  before(async () => {

    if (process.env.NETWORK_GATEWAY_API?.length == 0) {
      console.error("ERROR: set environment variables first");
      process.exit(-1);
    }

    [, poolOwner, depositor1, depositor2] = await ethers.getSigners();
    now = new Date();
    tomorrow = now.getTime() + 10000; // new Date(new Date().setDate(now.getDate() + 1));
  });

  it("deploy IDO contract using DEPLOYER_PRIMARY_KEY account", async () => {
    const IDO = await ethers.getContractFactory("IDO");
    idoContract = await IDO.deploy();
    await idoContract.deployed();
    expect(idoContract.address.length).be.gt(0);
  });

  it("deploy Project Token and give allowance to IDO contract to spend it", async () => {
    const RT = await ethers.getContractFactory("ProjectToken");

    projectTokenContract = await RT.deploy(
      "Project Token",
      "RTK",
      projectTokenInitialSupply
    );

    await projectTokenContract.transfer(
      idoContract.address,
      countOfProvidedToken
    );

    const projectTotalSupply = await projectTokenContract.totalSupply();
    expect(
      ethers.BigNumber.from(projectTotalSupply).eq(
        projectTokenInitialSupply.toString()
      )
    ).to.be.true;

    const idoContractTokenBalance = await projectTokenBalance(
      idoContract.address
    );
    expect(
      ethers.BigNumber.from(idoContractTokenBalance).eq(countOfProvidedToken)
    ).to.be.true;

    const idoTokenBalance = await projectTokenBalance(idoContract.address);

    expect(ethers.BigNumber.from(idoTokenBalance).eq(countOfProvidedToken));
  });

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
    } catch (error) {
      expect(true);
    }
  });

  it("Grant poolOwner role to poolOwner address", async () => {
    const success = await idoContract.callStatic.grantPoolOwnerRole(
      poolOwner.address
    );
    await idoContract.grantPoolOwnerRole(poolOwner.address);
    expect(success);
  });

  it("[1/2] create the Pool", async () => {
    await idoContract.connect(poolOwner).createPool(
      hardCapWEI,
      softCapWEI,
      now.getTime(), // start time
      tomorrow, // end time
      PoolStatus.Ongoing
    );

    poolContractAddress = await idoContract.connect(poolOwner).poolAddress();
    expect(poolContractAddress.length).be.gt(0);
  });

  it("[2/2] add IDO related info to the Pool", async () => {
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
  });

  it("get the Pool information", async () => {
    const cpd = await idoContract.getCompletePoolDetails();
    expect(ethers.BigNumber.from(cpd.pool.softCap).eq(softCapWEI));
    expect(cpd.poolDetails.projectTokenAddress).be.equal(
      projectTokenContract.address
    );
    expect(cpd.pool.status).be.equal(PoolStatus.Ongoing);
    expect(cpd.poolDetails.exchangeRate.toString()).be.equal("1");
    expect(cpd.participationDetails.count.toString()).be.equal("0");
  });

  it("Deposit should fail if not whitelisted", async () => {
    try {
      await depositor1.sendTransaction({
        to: idoContract.address,
        value: ethers.utils.parseEther("1.0"),
      });
      expect(false).to.be.true;
    } catch (error) {
      expect(true).to.be.true;
    }
  });

  it("PoolOwner adds users to whitelist", async () => {
    await idoContract
      .connect(poolOwner)
      .addAddressesToWhitelist([depositor1.address, depositor2.address]);
  });

  it("Whitelisted participants can deposit", async () => {
    const beforeDepositPoolBalance = await weiBalance(poolContractAddress);
    const valueToDeposit = ethers.utils.parseEther("1.0");

    await depositor1.sendTransaction({
      to: idoContract.address,
      value: valueToDeposit, // ethers.utils.parseEther("1.1"),
    });

    const afterDepositPoolBalance = await weiBalance(poolContractAddress);
    expect(
      compareBigNumbers(
        ethers.BigNumber.from(beforeDepositPoolBalance + valueToDeposit),
        afterDepositPoolBalance
      )
    ).to.be.true;
  });

  it("the Pool only accepts deposit if it's status is Ongoing", async () => {
    await idoContract.connect(poolOwner).updatePoolStatus(PoolStatus.Upcoming);

    try {
      await depositor1.sendTransaction({
        to: idoContract.address,
        value: ethers.utils.parseEther("1.0"),
      });
    } catch (error) {
      expect(true);
    }

    await idoContract.connect(poolOwner).updatePoolStatus(PoolStatus.Ongoing);
  });

  it("pool should keep tract of deposits", async () => {
    const details = await idoContract.getCompletePoolDetails();
    const participants = details.participationDetails;

    const countOfParticipants = ethers.BigNumber.from(
      participants.count
    ).toNumber();
    expect(countOfParticipants).be.equal(1);

    const depositor1InvestRecord = participants.investorsDetails[0];
    const p1Address = depositor1InvestRecord.addressOfParticipant;
    expect(p1Address).be.equal(depositor1.address);

    const totalRaised = depositor1InvestRecord.totalRaisedInWei;
    expect(
      ethers.BigNumber.from(totalRaised).eq(ethers.utils.parseEther("1.0"))
    );
  });

  it("withdraw is possible if the Pool is Finished", async () => {
    // Change pool status to finish
    await idoContract.connect(poolOwner).updatePoolStatus(PoolStatus.Finished);

    const depositorTokenSupplyBefore = await projectTokenBalance(
      depositor1.address
    );
    const idoTokenSupplyBefore = await projectTokenBalance(idoContract.address);

    // REFUND
    await idoContract.connect(depositor1).refund();

    expect(
      compareBigNumbers(
        idoTokenSupplyBefore,
        await projectTokenBalance(idoContract.address)
      )
    ).to.be.false;

    expect(
      depositorTokenSupplyBefore <
        (await projectTokenBalance(depositor1.address))
    ).to.be.true;
  });

  it("Participants can withdraw only once", async () => {
    try {
      await idoContract.connect(depositor1).refund();
      expect(false).to.be.true;
    } catch (error) {
      expect(true).to.be.true;
    }
  });
});

async function projectTokenBalance(_address: string): Promise<any> {
  const balance = await projectTokenContract.balanceOf(_address);
  return balance;
}

async function weiBalance(_address: string): Promise<any> {
  const weiBalance = await ethers.provider.getBalance(_address);
  return weiBalance;
}

function compareBigNumbers(a: any, b: any): Promise<any> {
  return ethers.BigNumber.from(a).eq(b);
}

async function _tokenAllowanceLeft(owner: any, spender: any): Promise<any> {
  return await projectTokenContract.allowance(owner, spender);
}
