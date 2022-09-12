const { ethers } = require("hardhat");
const { changeOwner } = require("../secrets.json");

async function main() {
  const RewardDistributor = await ethers.getContractFactory("RewardDistributor");
  const rewardDistirbutor = await RewardDistributor.attach(changeOwner.rewardDistributor);

  const oldOwner = await rewardDistirbutor.owner();
  const transferOwnership = await rewardDistirbutor.transferOwnership(changeOwner.ownerSafe);
  await transferOwnership.wait();
  const newOwner = await rewardDistirbutor.owner();

  console.log(`Change owner of ${changeOwner.rewardDistributor} from ${oldOwner} to ${newOwner}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });