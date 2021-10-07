const { expect } = require("chai");
const { ethers, Web3, web3 } = require("hardhat");
import bigInt from "bignumber.js";

console.log("Getting here");

describe("TKN", async () => {
  it("Should be deployed", async () => {
    const Token = await ethers.getContractFactory("TKN");
    const token = await Token.deploy("Token", "TKN");
    await token.deployed();

    const address = token.address;
    const totalSupply = await token.totalSupply();

    console.log(totalSupply);
    console.log(Web3.utils.fromWei(totalSupply.toString()));
    console.log(ethers.utils.formatEther(totalSupply.toString()));
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
