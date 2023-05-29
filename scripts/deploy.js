const hre = require("hardhat");

async function main() {
	const HDToken = await hre.ethers.getContractFactory("HDToken");
	const hdToken = await HDToken.deploy();

	await hdToken.deployed();

	console.log("HDToken Deployed: ", hdToken.address);
}
main().catch((error) => {
	console.error(error);
	process.exitCode = 1;
});
