const { ethers, upgrades } = require("hardhat");
const { expect } = require("chai");

describe("RewardDistributor Functionality", function () {
    let provider;
    let owner, staker, masterNode, gather, publisher, others;
    let stakerInitialBalance, masterNodeInitialBalance, gatherInitialBalance, publisherInitialBalance;
    let rewardDistirbutorV2;
    beforeEach(async () => {
        [owner, staker, masterNode, gather, publisher, ...others] = await ethers.getSigners();
        provider = owner.provider;
        stakerInitialBalance = await staker.getBalance();
        masterNodeInitialBalance = await masterNode.getBalance();
        gatherInitialBalance = await gather.getBalance();
        publisherInitialBalance = await publisher.getBalance();

        // Deploy and initialize v2
        const RewardDistributor = await ethers.getContractFactory("RewardDistributor");
        const rewardDistirbutor = await upgrades.deployProxy(RewardDistributor);
        await rewardDistirbutor.deployed();
        const RewardDistributorV2 = await ethers.getContractFactory("RewardDistributorV2");
        rewardDistirbutorV2 = await upgrades.upgradeProxy(rewardDistirbutor.address, RewardDistributorV2);
        await rewardDistirbutorV2.deployed();
        await rewardDistirbutorV2.initializeV2();

        // Fund contract
        await owner.sendTransaction({
            to: rewardDistirbutorV2.address,
            value: ethers.utils.parseEther("100")
        });
    });

    it("Should not initialize twice", async () => {
        await expect(rewardDistirbutorV2.initializeV2()).to.revertedWith("V2 already initialized");
    });

    it("Should have un-allocated funds", async () => {
        const contractBalance = await provider.getBalance(rewardDistirbutorV2.address);
        expect(contractBalance).to.equal(ethers.utils.parseEther("100"));

        const zero = ethers.utils.parseEther("0");

        // Check zero allocated balances
        expect(await rewardDistirbutorV2.stakersBalance()).to.equal(zero);
        expect(await rewardDistirbutorV2.masterNodesBalance()).to.equal(zero);
        expect(await rewardDistirbutorV2.publishersBalance()).to.equal(zero);
        expect(await rewardDistirbutorV2.burnBalance()).to.equal(zero);
        expect(await rewardDistirbutorV2.gatherBalance()).to.equal(zero);
        expect(await rewardDistirbutorV2.allocatedBalance()).to.equal(zero);
    });

    it("Should do allocation of funds", async () => {
        await rewardDistirbutorV2.allocateRewards();

        expect(await rewardDistirbutorV2.stakersBalance()).to.equal(ethers.utils.parseEther("7.5"));
        expect(await rewardDistirbutorV2.masterNodesBalance()).to.equal(ethers.utils.parseEther("22.5"));
        expect(await rewardDistirbutorV2.gatherBalance()).to.equal(ethers.utils.parseEther("2.1"));
        expect(await rewardDistirbutorV2.publishersBalance()).to.equal(ethers.utils.parseEther("4.9"));
        expect(await rewardDistirbutorV2.burnBalance()).to.equal(ethers.utils.parseEther("63"));
        expect(await rewardDistirbutorV2.allocatedBalance()).to.equal(ethers.utils.parseEther("100"));
    });

    it("Should allow withdrawal of stakers balance", async () => {
        await rewardDistirbutorV2.allocateRewards();
        await rewardDistirbutorV2.withdrawStakersBalance(staker.address);
        expect(await staker.getBalance()).to.equal(ethers.utils.parseEther("7.5").add(stakerInitialBalance));

        let contractBalance = await provider.getBalance(rewardDistirbutorV2.address);
        expect(contractBalance).to.equal(ethers.utils.parseEther("92.5"));

        expect(await rewardDistirbutorV2.stakersBalance()).to.equal(ethers.utils.parseEther("0"));
        expect(await rewardDistirbutorV2.allocatedBalance()).to.equal(ethers.utils.parseEther("92.5"));
    });

    it("Should allow withdrawal of master nodes balance", async () => {
        await rewardDistirbutorV2.allocateRewards();
        await rewardDistirbutorV2.withdrawMasterNodesBalance(masterNode.address);
        expect(await masterNode.getBalance()).to.equal(ethers.utils.parseEther("22.5").add(masterNodeInitialBalance));

        let contractBalance = await provider.getBalance(rewardDistirbutorV2.address);
        expect(contractBalance).to.equal(ethers.utils.parseEther("77.5"));

        expect(await rewardDistirbutorV2.masterNodesBalance()).to.equal(ethers.utils.parseEther("0"));
        expect(await rewardDistirbutorV2.allocatedBalance()).to.equal(ethers.utils.parseEther("77.5"));


        await owner.sendTransaction({
            to: rewardDistirbutorV2.address,
            value: ethers.utils.parseEther("100")
        });

        await rewardDistirbutorV2.allocateRewards();

        contractBalance = await provider.getBalance(rewardDistirbutorV2.address);
        expect(contractBalance).to.equal(ethers.utils.parseEther("177.5"));

        expect(await rewardDistirbutorV2.masterNodesBalance()).to.equal(ethers.utils.parseEther("22.5"));
        expect(await rewardDistirbutorV2.burnBalance()).to.equal(ethers.utils.parseEther("126"));
        expect(await rewardDistirbutorV2.allocatedBalance()).to.equal(ethers.utils.parseEther("177.5"));

    });

    it("Should allow withdrawal of gather balance", async () => {
        await rewardDistirbutorV2.allocateRewards();
        await rewardDistirbutorV2.withdrawGatherBalance(gather.address);
        expect(await gather.getBalance()).to.equal(ethers.utils.parseEther("2.1").add(gatherInitialBalance));

        let contractBalance = await provider.getBalance(rewardDistirbutorV2.address);
        expect(contractBalance).to.equal(ethers.utils.parseEther("97.9"));

        expect(await rewardDistirbutorV2.gatherBalance()).to.equal(ethers.utils.parseEther("0"));
        expect(await rewardDistirbutorV2.allocatedBalance()).to.equal(ethers.utils.parseEther("97.9"));
    });

    it("Should allow withdrawal of publishers balance", async () => {
        await rewardDistirbutorV2.allocateRewards();
        await rewardDistirbutorV2.withdrawPublishersBalance(publisher.address);
        expect(await publisher.getBalance()).to.equal(ethers.utils.parseEther("4.9").add(publisherInitialBalance));

        let contractBalance = await provider.getBalance(rewardDistirbutorV2.address);
        expect(contractBalance).to.equal(ethers.utils.parseEther("95.1"));

        expect(await rewardDistirbutorV2.publishersBalance()).to.equal(ethers.utils.parseEther("0"));
        expect(await rewardDistirbutorV2.allocatedBalance()).to.equal(ethers.utils.parseEther("95.1"));
    });

    it("Should allow burn balance for burning", async () => {
        await rewardDistirbutorV2.allocateRewards();
        await rewardDistirbutorV2.burn();

        let contractBalance = await provider.getBalance(rewardDistirbutorV2.address);
        expect(contractBalance).to.equal(ethers.utils.parseEther("37"));

        expect(await rewardDistirbutorV2.burnBalance()).to.equal(ethers.utils.parseEther("0"));
        expect(await rewardDistirbutorV2.allocatedBalance()).to.equal(ethers.utils.parseEther("37"));
    });

    it("Should allow withdrawal of all allocated funds", async () => {
        await rewardDistirbutorV2.allocateRewards();
        await rewardDistirbutorV2.withdrawAll(staker.address, masterNode.address, gather.address, publisher.address);

        expect(await staker.getBalance()).to.equal(ethers.utils.parseEther("7.5").add(stakerInitialBalance));
        expect(await masterNode.getBalance()).to.equal(ethers.utils.parseEther("22.5").add(masterNodeInitialBalance));
        expect(await gather.getBalance()).to.equal(ethers.utils.parseEther("2.1").add(gatherInitialBalance));
        expect(await publisher.getBalance()).to.equal(ethers.utils.parseEther("4.9").add(publisherInitialBalance));

        let contractBalance = await provider.getBalance(rewardDistirbutorV2.address);
        expect(contractBalance).to.equal(ethers.utils.parseEther("0"));

        expect(await rewardDistirbutorV2.stakersBalance()).to.equal(ethers.utils.parseEther("0"));
        expect(await rewardDistirbutorV2.masterNodesBalance()).to.equal(ethers.utils.parseEther("0"));
        expect(await rewardDistirbutorV2.gatherBalance()).to.equal(ethers.utils.parseEther("0"));
        expect(await rewardDistirbutorV2.publishersBalance()).to.equal(ethers.utils.parseEther("0"));
        expect(await rewardDistirbutorV2.allocatedBalance()).to.equal(ethers.utils.parseEther("0"));
    });

    it("Should allow update of coefficients", async () => {
        await rewardDistirbutorV2.updateCoefficients(
            ethers.utils.parseUnits("2000", "wei"),
            ethers.utils.parseUnits("2000", "wei"),
            ethers.utils.parseUnits("6000", "wei"),
            ethers.utils.parseUnits("5000", "wei"),
            ethers.utils.parseUnits("0", "wei"),
            ethers.utils.parseUnits("0", "wei")
        )

        expect(await rewardDistirbutorV2.newStakersCoefficient()).to.equal(ethers.utils.parseUnits("2000", "wei"));
        expect(await rewardDistirbutorV2.newMasterNodesCoefficient()).to.equal(ethers.utils.parseUnits("2000", "wei"));
        expect(await rewardDistirbutorV2.publishersCoefficient()).to.equal(ethers.utils.parseUnits("6000", "wei"));
        expect(await rewardDistirbutorV2.gatherCoefficient()).to.equal(ethers.utils.parseUnits("5000", "wei"));
        expect(await rewardDistirbutorV2.burnPublishersCoefficient()).to.equal(ethers.utils.parseUnits("0", "wei"));
        expect(await rewardDistirbutorV2.burnGatherCoefficient()).to.equal(ethers.utils.parseUnits("0", "wei"));
        expect(await rewardDistirbutorV2.totalCoefficient()).to.equal(ethers.utils.parseUnits("10000", "wei"));
    });
});