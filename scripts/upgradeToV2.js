// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const { ethers, upgrades } = require("hardhat");
const { upgrade } = require("../secrets.json");

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  // We get the contract to deploy
  const rewardDistirbutor = upgrade.rewardDistributor;

  const RewardDistributorV2 = await ethers.getContractFactory("RewardDistributorV2");
  const rewardDistirbutorV2 = await upgrades.upgradeProxy(rewardDistirbutor, RewardDistributorV2);

  console.log("RewardDistributor upgraded to new implementation");
  console.log("Executing initializV2 function to initialize new variables");

  // Calll initializev2 to get initialize new values
  await rewardDistirbutorV2.initializeV2();

  console.log("RewardDistributor upgraded complete with initilization of new values:", rewardDistirbutorV2.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });