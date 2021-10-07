import "@nomiclabs/hardhat-ethers";
import { task } from "hardhat/config";
import "@openzeppelin/hardhat-upgrades";

// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

task("balance", "get balance of first account")
  .addParam("acc", "Account address to get it's balance")
  .setAction(async (taskArgs, hre) => {
    const account = taskArgs.acc;

    const balance = await hre.ethers.getDefaultProvider().getBalance(account);
    console.log(balance);
  });

task(
  "deploy",
  "Deploy smart contracts to local network",
  async (taskArgs, hre, runSuper) => {
    hre.run("compile");
    const poolContract = await hre.ethers.getContractFactory("Pool");
    const pool = await poolContract.deploy(1);
    console.log(`Contract deployed at ${pool.address}`);
  }
);

// task("compile", "Compile contracts", async () => {
//   console.log("Compile task called");
// });

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: {
    compilers: [
      { version: "0.7.0" },
      {
        version: "0.8.4",
        settings: {},
      },
    ],
  },
  defaultNetwork: "localhost",
};
