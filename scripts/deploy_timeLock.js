const hre = require("hardhat");

async function main() {


  // We get the contract to deploy
  const TimeLock = await hre.ethers.getContractFactory("TimeLock");
  const timeLock = await TimeLock.deploy(60, ["0x56A617E336045C9be6653f8ACEeCcE4D32c57cE2"], ["0x56A617E336045C9be6653f8ACEeCcE4D32c57cE2"]);

  await timeLock.deployed();

  console.log("TimeLock deployed to:", timeLock.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
