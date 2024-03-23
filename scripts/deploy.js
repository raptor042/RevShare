// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

async function main() {
  const rev_share = await hre.ethers.deployContract("RevShare", ["0xF47B8bc1CBcdf611ca25Ac8a3c7c23c7F8fd7B2E"]);

  await rev_share.waitForDeployment();

  console.log(
    `RevShare CA deployed to ${rev_share.target}`
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
