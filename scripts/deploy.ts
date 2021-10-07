import hre from "hardhat";

async function main() {
  const Token = await hre.ethers.getContractFactory("TKN");
  const token = await Token.deploy("Token", "TKN");

  console.log("Contract deployed to:", token.address);
  console.log(
    "Total supply is:",
    hre.ethers.utils.formatEther(
      (await token.totalSupply()).toString()
    )
  );
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
