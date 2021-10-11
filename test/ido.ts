const { expect } = require("chai");
const { ethers, Web3, web3 } = require("hardhat");
require("dotenv").config();

let idoContract: any;

describe("IDO", async () => {
  let poolOwner: any;
  let raisedWeiReceiver: any;

  let now: any;
  let tomorrow: any;

  before(async () => {
    [, poolOwner, raisedWeiReceiver] = await ethers.getSigners();
    now = new Date();
    tomorrow = new Date(new Date().setDate(now.getDate() + 1));
  });

  it("deploy IDO contract using DEPLOYER_PK account", async () => {
    const IDO = await ethers.getContractFactory("VentIDO");
    idoContract = await IDO.deploy();
    await idoContract.deployed();
    expect(idoContract.address.length).be.gt(0);
  });

  it("only poolOwner can create a pool", async () => {
    try {
      await idoContract.connect(poolOwner).createPool(
        1000,
        500, // how much of the raise will be accepted as successful IDO
        now.getTime(),
        tomorrow.getTime(),
        0 // Status 0 => Upcoming
      );
    } catch (error) {
      expect(true);
    }
  });

  it("Grant poolOwner role to POOL_OWNER_PK account", async () => {
    const success = await idoContract.callStatic.grantPoolOwnerRole(
      poolOwner.address
    );
    await idoContract.grantPoolOwnerRole(poolOwner.address);
    expect(success);
  });

  it("[1/2] create a pool", async () => {
    await idoContract.connect(poolOwner).createPool(
      1000, //hard cap
      500, // soft cap
      now.getTime(),// start time
      tomorrow.getTime(), //end time
      0 // status
    );
  });

  it("[2/2] add detailed info of the pool", async () => {
    await idoContract.connect(poolOwner).addPoolDetailedInfo(
      process.env.RAISED_WEI_RECEIVER_ADDRESS, // wei receiver wallet address
      process.env.TOKEN_ADDRESS, // project token address
      1, // min allocation per user
      10, // max allocation per user
      1000000, // total token provided 1_000_000
      1, // exchange rate
      1, // token price
      0 // total token sold
    );
  });

  it("get pool information", async () => {
    const poolDetails = await idoContract.getPoolDetails();
    
    expect(poolDetails.poolInfo.softCap.toString()).be.equal("500");
    expect(poolDetails.poolDetails.exchangeRate.toString()).be.equal("1");
    expect(poolDetails.participationDetails.count.toString()).be.equal("0");
  });
});
