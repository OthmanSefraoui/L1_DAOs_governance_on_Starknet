const hre = require("hardhat");

async function main() {
    const governor = await hre.ethers.getContractAt("ProtocolGovernor", "0x68DcECAe8C1db38dD16aef81c07a326eB67e5ec7")
    const target = await hre.ethers.getContractAt("DummyTargetContract", "0xbB501Eb61A16e2a33300a79e6A55E32dD22eb531")
    const encodedFunctionCall = target.interface.encodeFunctionData("proposalExecute", [1, 15])
    console.log(encodedFunctionCall)
    /*const proposeTx = await governor.propose(
        ["0xbB501Eb61A16e2a33300a79e6A55E32dD22eb531"],
        [0],
        [encodedFunctionCall],
        "Test proposal !!"
    )*/
    const descriptionHash = hre.ethers.utils.keccak256(hre.ethers.utils.toUtf8Bytes("Test proposal !!"))
    console.log(descriptionHash)
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});