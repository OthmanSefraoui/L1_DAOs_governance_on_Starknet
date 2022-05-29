const hre = require("hardhat");

async function main() {


  // We get the contract to deploy
  const GovernanceDummyToken = await hre.ethers.getContractFactory("GovernanceDummyToken");
  const governanceDummyToken = await GovernanceDummyToken.deploy();

  await governanceDummyToken.deployed();

  console.log("GovernanceDummyToken deployed to:", governanceDummyToken.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
