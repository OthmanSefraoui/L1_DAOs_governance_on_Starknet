const hre = require("hardhat");

async function main() {
    const governor = await hre.ethers.getContractAt("ProtocolGovernor", "0x68DcECAe8C1db38dD16aef81c07a326eB67e5ec7")
    const target = await hre.ethers.getContractAt("DummyTargetContract", "0xbB501Eb61A16e2a33300a79e6A55E32dD22eb531")
    const encodedFunctionCall = target.interface.encodeFunctionData("proposalExecute", [3, 15])
    console.log(hre.ethers.utils.keccak256(encodedFunctionCall))
    /*const proposeTx = await governor.propose(
        ["0xbB501Eb61A16e2a33300a79e6A55E32dD22eb531"],
        [0],
        [encodedFunctionCall],
        "Test proposal !!"
    )*/
    const descriptionHash = hre.ethers.utils.keccak256(hre.ethers.utils.toUtf8Bytes("Test proposal !!"))
    console.log(descriptionHash)
    const hash = await governor.hashProposal(
        ["0xbB501Eb61A16e2a33300a79e6A55E32dD22eb531"],
        [0],
        [encodedFunctionCall],
        descriptionHash
    )
    console.log(hash)

}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});