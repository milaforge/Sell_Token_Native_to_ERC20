import "@nomiclabs/hardhat-web3";
import "@nomiclabs/hardhat-ethers";
import "hardhat-tracer";
import { task } from "hardhat/config";
require("dotenv").config();

// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(
      account.address,
      ethers.utils.formatEther((await account.getBalance()).toString())
    );
  }
});

task(
  "deploy",
  "Deploy smart contracts to local network",
  async (taskArgs, hre, runSuper) => {
    hre.run("compile");
    const IDO = await hre.ethers.getContractFactory("IDO");
    console.log("Deploying contract ...");
    const ido = await IDO.deploy();
    console.log(`IDO Contract deployed at ${ido.address}`);
    process.exit(0);
  }
);

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: {
    version: "0.8.0",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  networks: {
    // rinkeby: {
    //   url: process.env.NETWORK_GATEWAY_API,
    //   accounts: [
    //     process.env.POOL_OWNER_PRIMARY_KEY,
    //     process.env.DEPLOYER_PRIMARY_KEY,
    //     process.env.RAISED_WEI_RECEIVER_PRIMARY_KEY,
    //   ],
    // },
  },
  // defaultNetwork: "localhost",
};
