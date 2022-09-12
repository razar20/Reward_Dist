const { ethers, upgrades } = require("hardhat");
const { expect } = require("chai");
const { BigNumber } = require("@ethersproject/bignumber");

describe("RewardDistributor Deployment", function () {
    it('initialization works', async () => {
        const RewardDistributor = await ethers.getContractFactory("RewardDistributor");
        const rewardDistirbutor = await upgrades.deployProxy(RewardDistributor);

        await rewardDistirbutor.deployed();

        expect(rewardDistirbutor.address).to.be.properAddress;
        expect(await rewardDistirbutor.stakersCoefficient()).to.equal(BigNumber.from(750));
        expect(await rewardDistirbutor.masterNodesCoefficient()).to.equal(BigNumber.from(2250));
        expect(await rewardDistirbutor.publishersCoefficient()).to.equal(BigNumber.from(7000));
        expect(await rewardDistirbutor.gatherCoefficient()).to.equal(BigNumber.from(3000));
        expect(await rewardDistirbutor.totalCoefficient()).to.equal(BigNumber.from(10000));
    });

    it('upgrade to v2 works', async () => {
        const RewardDistributor = await ethers.getContractFactory("RewardDistributor");
        const rewardDistirbutor = await upgrades.deployProxy(RewardDistributor);

        await rewardDistirbutor.deployed();

        const RewardDistributorV2 = await ethers.getContractFactory("RewardDistributorV2");
        const rewardDistirbutorV2 = await upgrades.upgradeProxy(rewardDistirbutor.address, RewardDistributorV2);

        // Fund contract to test allocation of pending funds
        const [owner, ...others] = await ethers.getSigners();
        const provider = owner.provider;
        await owner.sendTransaction({
            to: rewardDistirbutorV2.address,
            value: ethers.utils.parseEther("51")
        });

        // Calll initializev2 to get initialize new values
        await rewardDistirbutorV2.initializeV2();

        expect(await rewardDistirbutorV2.stakersCoefficient()).to.equal(BigNumber.from(750));
        expect(await rewardDistirbutorV2.masterNodesCoefficient()).to.equal(BigNumber.from(9250));
        expect(await rewardDistirbutorV2.publishersCoefficient()).to.equal(BigNumber.from(7000));
        expect(await rewardDistirbutorV2.gatherCoefficient()).to.equal(BigNumber.from(3000));
        expect(await rewardDistirbutorV2.totalCoefficient()).to.equal(BigNumber.from(10000));

        // Check new variables
        expect(await rewardDistirbutorV2.newStakersCoefficient()).to.equal(BigNumber.from(750));
        expect(await rewardDistirbutorV2.newMasterNodesCoefficient()).to.equal(BigNumber.from(2250));
        expect(await rewardDistirbutorV2.burnPublishersCoefficient()).to.equal(BigNumber.from(9000));
        expect(await rewardDistirbutorV2.burnGatherCoefficient()).to.equal(BigNumber.from(9000));

        // Check that all balance has been allocated
        const contractBalance = await provider.getBalance(rewardDistirbutorV2.address);
        const allocatedBalance = await rewardDistirbutorV2.allocatedBalance();
        expect(contractBalance).to.equal(allocatedBalance);
    });
});