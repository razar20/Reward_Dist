// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const { ethers, upgrades } = require("hardhat");
const { changeAdminOwner } = require("../secrets.json");

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  // We get the contract to deploy
  const admin = await upgrades.admin.getInstance();
  const oldAdminOwner = await admin.owner();
  console.log("admin address is ", admin.address);
  console.log("Admin owner is ", oldAdminOwner);
  await upgrades.admin.transferProxyAdminOwnership(changeAdminOwner.owner);
  const newAdminOwner = changeAdminOwner.owner; //await admin.owner({blockTag: "pending"});

  console.log(`Changed owner of admin ${admin.address} of from ${oldAdminOwner} to ${newAdminOwner}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
