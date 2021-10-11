const { expect } = require("chai");
const { ethers, Web3, web3 } = require("hardhat");

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
        raisedWeiReceiver.address
        // projectTokenAddress: rewardTokenAddress, //the address of the token that project is offering in return
        // minAllocationPerUser: 1,
        // maxAllocationPerUser: 10000,
        // totalTokenProvided: 10000,
        // exchangeRate: 1,
        // tokenPrice: 1,
        // totalTokenSold: 0,
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

  it("create a pool", async () => {
    await idoContract.connect(poolOwner).createPool(
      1000,
      500, // how much of the raise will be accepted as successful IDO
      now.getTime(),
      tomorrow.getTime(),
      raisedWeiReceiver.address
      // projectTokenAddress: rewardTokenAddress, //the address of the token that project is offering in return
      // minAllocationPerUser: 1,
      // maxAllocationPerUser: 10000,
      // totalTokenProvided: 10000,
      // exchangeRate: 1,
      // tokenPrice: 1,
      // totalTokenSold: 0,
    );
  });

  it("get pool information", async () => {
    const poolDetails = await idoContract.getPoolDetails();
    expect(poolDetails.minAllocationPerUser).be.equal(1);
    expect(poolDetails.participationDetails.count.toString()).be.equal("0");
  });
});
