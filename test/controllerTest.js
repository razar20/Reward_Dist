const { ethers, upgrades } = require("hardhat");
const { expect } = require("chai");

describe("RewardDistributor Functionality", function () {
    let owner, stakerContract, user, others;
    let rewardDistributorAsOwner;
    let rewardDistributorController,
        rewardDistributorControllerAsOwner;

        beforeEach(async () => {
        [owner, stakerContract, user, ...others] = await ethers.getSigners();
        provider = owner.provider;

        // Deploy and initialize v2
        const RewardDistributor = await ethers.getContractFactory("RewardDistributorV2");
        const rewardDistirbutor = await upgrades.deployProxy(RewardDistributor,
            [],
            {
                initializer: "initialize",
            });
        await rewardDistirbutor.deployed();
        rewardDistributorAsOwner = rewardDistirbutor.connect(owner);

        // Fund contract
        await owner.sendTransaction({
            to: rewardDistirbutor.address,
            value: ethers.utils.parseEther("100")
        });

        const RewardDistributorController = await ethers.getContractFactory("RewardDistributorController");
        rewardDistributorController = await upgrades.deployProxy(RewardDistributorController,
            [rewardDistirbutor.address],
            {
                initializer: "initialize",
            });
        await rewardDistributorController.deployed();

        await rewardDistributorAsOwner.transferOwnership(rewardDistributorController.address);

        rewardDistributorControllerAsOwner = rewardDistributorController.connect(owner);
        rewardDistributorControllerAsStaker = rewardDistributorController.connect(stakerContract);
        rewardDistributorControllerAsUser = rewardDistributorController.connect(user);

        const StakingRewards = await ethers.getContractFactory("StakingRewards");
        stakingRewards = await upgrades.deployProxy(
            StakingRewards,
            [rewardDistributorController.address],
            {
                initializer: "initialize",
            }
        );
        await stakingRewards.deployed();
        stakingContractAsOwner = stakingRewards.connect(owner);
    });
   
    it("Should transfer ownership back", async () => {
        await rewardDistributorControllerAsOwner.changeRewardDistributorOwner(owner.address);
        expect(await rewardDistributorAsOwner.owner()).to.be.equal(owner.address)
    });

    it("Should get admin role", async () => {
        expect(await rewardDistributorController.getRoleAdmin(rewardDistributorController.STAKERS_ROLE())).to.be.equal(await rewardDistributorController.DEFAULT_ADMIN_ROLE());
    });

    it("Should the owner of rewardDistributor be rewardDistributorController", async () => {
        expect(await rewardDistributorAsOwner.owner()).to.be.equal(rewardDistributorController.address);
    });

/*     it("Should revert the call allocateRewards by third party", async () => {
        await expect(rewardDistributorControllerAsUser.allocateRewards()).to.revertedWith("The caller is not allowed");
    });  */

});