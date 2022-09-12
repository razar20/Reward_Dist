// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");

async function main() {
    // Hardhat always runs the compile task when running scripts with its command
    // line interface.
    //
    // If this script is run directly using `node` you may want to call compile
    // manually to make sure everything is compiled
    // await hre.run('compile');

    // We get the contract to deploy

    const RewardDistributor = await ethers.getContractFactory("RewardDistributor");
    const rewardDistirbutor = await upgrades.deployProxy(RewardDistributor);

    await rewardDistirbutor.deployed();

    console.log("RewardDistributor deployed to:", rewardDistirbutor.address);

    const RewardDistributorController = await ethers.getContractFactory("RewardDistributorController");
    rewardDistributorController = await upgrades.deployProxy(RewardDistributorController,
        [],
        {
            initializer: "initialize",
        });
    await rewardDistributorController.deployed();

    console.log("rewardDistributorController deployed to:", rewardDistributorController.address);

    const StakingRewards = await ethers.getContractFactory("StakingRewardsGTH");
    stakingRewards = await upgrades.deployProxy(
        StakingRewards,
        [],
        {
            initializer: "initialize",
        }
    );
    await stakingRewards.deployed();

    console.log("StakingRewards deployed to:", stakingRewards.address);

}


// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
