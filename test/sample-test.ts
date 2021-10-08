const { expect } = require("chai");
const { ethers, Web3, web3 } = require("hardhat");
import bigInt from "bignumber.js";

let rewardTokenAddress = null;

function weiToDecimal(wei: bigInt) {
  return Web3.utils.fromWei(wei);
  // return ethers.utils.formatEther(wei);
}

describe("TKN", async () => {
  it("Deploy <Reward Token>", async () => {

    // Deploy Reward Token
    const totalSupply = "10000";
    const Token = await ethers.getContractFactory("RewardToken");
    const token = await Token.deploy("Reward Token", "RT", totalSupply);
    await token.deployed();

    // Check total supply
    let totalSupplyDeployed = weiToDecimal((await token.totalSupply()).toString());
    expect(totalSupplyDeployed).be.equal(totalSupply);

    const [owner, otherUser] = await ethers.getSigners();

    // check balance of owner
    const ownerBalance = weiToDecimal(
      (await token.balanceOf(owner.address)).toString()
    );
    expect(ownerBalance).be.equal(totalSupply);

    // check balance of one other user
    const otherUserBalance = weiToDecimal(
      (await token.balanceOf(otherUser.address)).toString()
    );
    expect(otherUserBalance).be.equal("0");

    rewardTokenAddress = token.address;
  });
});

// describe("Greeter", function () {
//   it("Should return the new greeting once it's changed", async function () {
//     const Greeter = await ethers.getContractFactory("Greeter");
//     const greeter = await Greeter.deploy("Hello, world!");
//     await greeter.deployed();

//     expect(await greeter.greet()).to.equal("Hello, world!");

//     const setGreetingTx = await greeter.setGreeting("Hola, mundo!");

//     // wait until the transaction is mined
//     await setGreetingTx.wait();

//     expect(await greeter.greet()).to.equal("Hola, mundo!");
//   });
// });

// describe("Donate", async function () {
//   let deployedContract = null;

//   it("should be deployed", async () => {
//     const Donate = await ethers.getContractFactory("Donate");
//     const donate = await Donate.deploy();
//     await donate.deployed();

//     const Greet = await web3.eth.Contract();

//     expect(donate.address).not.null;
//     deployedContract = donate;
//   });

//   it("should accept ETH sent", async () => {
//     const [firstUser, secondUser, thirdUser] = await ethers.getSigners();

//     const txResult = await secondUser.sendTransaction({
//       to: deployedContract.address,
//       value: ethers.utils.parseEther("1.0"),
//     });

//     const balance = (await deployedContract.getBalance()).toString();
//     expect(ethers.utils.formatEther(balance)).be.equal("1.0");
//   });

//   it("should keep record of donations", async () => {
//     const [firstUser, secondUser, thirdUser] = await ethers.getSigners();

//     await deployedContract.donate(ethers.utils.parseEther("1.0"));

//     const depositedAmountAtContract = await deployedContract
//       .connect(thirdUser)
//       .getDonationsOfAUser();

//     const balance = ethers.utils.formatEther(
//       await deployedContract.getBalance()
//     );
//     console.log("balance", balance);

//     console.log(ethers.utils.formatEther(depositedAmountAtContract));
//   });
// });
