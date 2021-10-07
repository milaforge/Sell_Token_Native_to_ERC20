const hre = require("hardhat");

async function main() {
  const Pool = await hre.ethers.getContractFactory("Pool");
  const pool = await Pool.deploy(1);

  console.log("Contract deployed to:", pool.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
