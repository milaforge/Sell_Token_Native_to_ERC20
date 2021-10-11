import "@nomiclabs/hardhat-web3";
import "@nomiclabs/hardhat-ethers";
import { task } from "hardhat/config";
require("dotenv").config();

// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

task(
  "deploy",
  "Deploy smart contracts to local network",
  async (taskArgs, hre, runSuper) => {
    hre.run("compile");
    const IDO = await hre.ethers.getContractFactory("VentIDO");
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
    rinkeby: {
      url: process.env.NETWORK_GATEWAY_API,
      accounts: [
        process.env.POOL_OWNER_PK,
        process.env.DEPLOYER_PK,
        process.env.RAISED_WEI_RECEIVER_PK,
      ],
    },
  },
  defaultNetwork: "localhost",
};
