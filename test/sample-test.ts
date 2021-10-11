const { expect } = require("chai");
const { ethers, Web3, web3 } = require("hardhat");
import bigInt from "bignumber.js";

let rewardTokenAddress: string;
let idoContractAddress: string;
let idoContract: any;

function weiToDecimal(wei: bigInt) {
  return Web3.utils.fromWei(wei);
  // return ethers.utils.formatEther(wei);
}

describe("IDO", async () => {
  let owner;
  let poolOwner: any;
  let raisedWeiReceiver: any;

  beforeEach(async () => {
    [owner, poolOwner, raisedWeiReceiver] = await ethers.getSigners();
  });

  it("deploy IDO contract", async () => {
    const IDO = await ethers.getContractFactory("VentIDO");
    idoContract = await IDO.deploy();
    await idoContract.deployed();
    expect(idoContract.address.length).be.gt(0);
  });

  it("Grant poolOwner role to an address", async () => {
    await idoContract.grantPoolOwnerRole(poolOwner.address);
  });

  it("poolOwner creates a Pool", async () => {
    const now = new Date();
    const tomorrow = new Date(new Date().setDate(now.getDate() + 1));

    await idoContract.connect(poolOwner).createPool(
      1000,
      500, // how much of the raise will be accepted as successful IDO
      now.getTime(),
      tomorrow.getTime(),
      raisedWeiReceiver.address
      // projectTokenAddress: rewardTokenAddress, //the address of the token that project is offering in return
      // minAllocationPerUser: 1,
      // maxAllocationPerUser: 10000,
      // status: "Ongoing", //: by default “Upcoming”,
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

  // it("should add whitelisted users", async () => {
  //   const [, poolOwner] = await ethers.getSigners();

  //   const whitelistedUsersAddress = [
  //     "0x3c44cdddb6a900fa2b585dd299e03d12fa4293bc",
  //     "0x90f79bf6eb2c4f870365e785982e1f101e93b906",
  //   ];

  //   const txHash = await idoContract
  //     .connect(poolOwner.address)
  //     .addAddressesToWhitelist(whitelistedUsersAddress);
  //   console.log(txHash);
  // });

  // it("only poolOwner can create a pool", async () => {
  //   const [, , otherUser] = await ethers.getSigners();

  //   try {
  //     await idoContract.createPool({});
  //   } catch (error) {
  //     console.log(error);
  //     expect(true);
  //   }
  // });

  // it("should not be able to deposit if pool is not open yet", async () => {
  //   //TODO implement
  // });

  // it("poolOwner can create a pool", async () => {
  //   const [owner, poolOwner] = await ethers.getSigners();
  //   await idoContract.connect(poolOwner.address).createPool();
  // });

  // it("revoke poolOwner access from an address", async () => {
  //   const [, poolOwner] = await ethers.getSigners();
  //   await idoContract.revokePoolOwnerRole(poolOwner.address);
  // });

  // const poolOwnerAddress = third.address;

  // const PoolModel = {};

  // const IDO = await ethers.getContractFactory("VentIDO");
  // const ido = await IDO.deploy();
});

describe("TKN", async () => {
  // it("Deploy <Reward Token>", async () => {
  //   // Deploy Reward Token
  //   const totalSupply = "10000";
  //   const Token = await ethers.getContractFactory("RewardToken");
  //   const token = await Token.deploy("Reward Token", "RT", totalSupply);
  //   await token.deployed();
  //   // Check total supply
  //   let totalSupplyDeployed = weiToDecimal(
  //     (await token.totalSupply()).toString()
  //   );
  //   expect(totalSupplyDeployed).be.equal(totalSupply);
  //   const [owner, otherUser] = await ethers.getSigners();
  //   // check balance of owner
  //   const ownerBalance = weiToDecimal(
  //     (await token.balanceOf(owner.address)).toString()
  //   );
  //   expect(ownerBalance).be.equal(totalSupply);
  //   // check balance of one other user
  //   const otherUserBalance = weiToDecimal(
  //     (await token.balanceOf(otherUser.address)).toString()
  //   );
  //   expect(otherUserBalance).be.equal("0");
  //   rewardTokenAddress = token.address;
  // });
});
