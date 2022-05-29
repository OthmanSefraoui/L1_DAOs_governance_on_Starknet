const hre = require("hardhat");

async function main() {


    // We get the contract to deploy
    const TargetContract = await hre.ethers.getContractFactory("DummyTargetContract");
    const targetContract = await TargetContract.deploy('0x68DcECAe8C1db38dD16aef81c07a326eB67e5ec7');

    await targetContract.deployed();

    console.log("Dummy Target Contract deployed to:", targetContract.address);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});