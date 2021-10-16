import hre, { ethers } from "hardhat";

(async () => {
  try {
    const [deployer] = await ethers.getSigners();
    console.log(`Deploying contract using :${deployer.address} account.`);

    const IDO = await hre.ethers.getContractFactory("IDO");
    const ido = await IDO.deploy();

    console.log(`Contract deployed at: ${ido.address}`);

    process.exit(0);
  } catch (error) {
    console.error(error);
    process.exit(1);
  }
})();
