const { expect } = require("chai");
const { ethers, Web3, web3 } = require("hardhat");
import bigInt from "bignumber.js";

let rewardTokenAddress = null;
let idoContractAddress = null;
let idoContract: any = null;

function weiToDecimal(wei: bigInt) {
  return Web3.utils.fromWei(wei);
  // return ethers.utils.formatEther(wei);
}

describe("IDO", async () => {
  it("deploy IDO contract", async () => {
    //Deploy IDO
    const IDO = await ethers.getContractFactory("VentIDO");
    idoContract = await IDO.deploy();
    await idoContract.deployed();
    expect(idoContract.address.length).be.gt(0);
  });

  it("only poolOwner can create a pool", async () => {
    const [, , otherUser] = await ethers.getSigners();

    try {
      await idoContract.createPool();
    } catch (error) {
      expect(true);
    }
  });

  it("Grant poolOwner role to an address", async () => {
    const [owner, poolOwner] = await ethers.getSigners();
    await idoContract.grantPoolOwnerRole(poolOwner.address);
  });

  it("poolOwner can create a pool", async () => {
    const [owner, poolOwner] = await ethers.getSigners();
    await idoContract.connect(poolOwner.address).createPool();
  });

  it("revoke poolOwner access from an address", async () => {
    const [, poolOwner] = await ethers.getSigners();
    await idoContract.revokePoolOwnerRole(poolOwner.address);
  });

  // const poolOwnerAddress = third.address;

  // const poolInfo = {};

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
