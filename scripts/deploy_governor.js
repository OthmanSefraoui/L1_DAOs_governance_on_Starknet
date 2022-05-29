const hre = require("hardhat");

async function main() {


    // We get the contract to deploy
    const Governor = await hre.ethers.getContractFactory("ProtocolGovernor");
    const governor = await Governor.deploy('0x96f4be923Ea5d247C31c58f37eEA10400F9cbFba', '0xa79E7bacce21d1A33b5D3BbcfAabb1Fb4039F8C6', 4, 30, 5);

    await governor.deployed();

    console.log("Governor deployed to:", governor.address);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});