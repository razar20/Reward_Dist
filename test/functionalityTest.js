const { ethers, upgrades } = require("hardhat");
const { expect } = require("chai");

describe("RewardDistributor Functionality", function () {
    let provider;
    let owner, staker, masterNode, gather, others;
    let stakerInitialBalance, masterNodeInitialBalance, gatherInitialBalance;
    let rewardDistirbutor;
    beforeEach(async () => {
        [owner, staker, masterNode, gather, ...others] = await ethers.getSigners();
        provider = owner.provider;
        stakerInitialBalance = await staker.getBalance();
        masterNodeInitialBalance = await masterNode.getBalance();
        gatherInitialBalance = await gather.getBalance();

        // Deploy contract
        const RewardDistributor = await ethers.getContractFactory("RewardDistributor");
        rewardDistirbutor = await upgrades.deployProxy(RewardDistributor);
        await rewardDistirbutor.deployed();

        // Fund contract
        await owner.sendTransaction({
            to: rewardDistirbutor.address,
            value: ethers.utils.parseEther("51")
        });
    });

    it("Should have un-allocated funds", async () => {
        const contractBalance = await provider.getBalance(rewardDistirbutor.address);
        expect(contractBalance).to.equal(ethers.utils.parseEther("51"));

        const zero = ethers.utils.parseEther("0");

        // Check zero allocated balances
        expect(await rewardDistirbutor.stakersBalance()).to.equal(zero);
        expect(await rewardDistirbutor.masterNodesBalance()).to.equal(zero);
        expect(await rewardDistirbutor.gatherBalance()).to.equal(zero);
        expect(await rewardDistirbutor.allocatedBalance()).to.equal(zero);
    });

    it("Should do allocation of funds", async () => {
        await rewardDistirbutor.allocateRewards();

        expect(await rewardDistirbutor.stakersBalance()).to.equal(ethers.utils.parseEther("7.5"));
        expect(await rewardDistirbutor.masterNodesBalance()).to.equal(ethers.utils.parseEther("22.5"));
        expect(await rewardDistirbutor.gatherBalance()).to.equal(ethers.utils.parseEther("21"));
        expect(await rewardDistirbutor.allocatedBalance()).to.equal(ethers.utils.parseEther("51"));
    });

    it("Should allow withdrawal of stakers balance", async () => {
        await rewardDistirbutor.allocateRewards();
        await rewardDistirbutor.withdrawStakersBalance(staker.address);
        expect(await staker.getBalance()).to.equal(ethers.utils.parseEther("7.5").add(stakerInitialBalance));

        let contractBalance = await provider.getBalance(rewardDistirbutor.address);
        expect(contractBalance).to.equal(ethers.utils.parseEther("43.5"));

        expect(await rewardDistirbutor.stakersBalance()).to.equal(ethers.utils.parseEther("0"));
        expect(await rewardDistirbutor.allocatedBalance()).to.equal(ethers.utils.parseEther("43.5"));
    });

    it("Should allow withdrawal of master nodes balance", async () => {
        await rewardDistirbutor.allocateRewards();
        await rewardDistirbutor.withdrawMasterNodesBalance(masterNode.address);
        expect(await masterNode.getBalance()).to.equal(ethers.utils.parseEther("22.5").add(masterNodeInitialBalance));

        let contractBalance = await provider.getBalance(rewardDistirbutor.address);
        expect(contractBalance).to.equal(ethers.utils.parseEther("28.5"));

        expect(await rewardDistirbutor.masterNodesBalance()).to.equal(ethers.utils.parseEther("0"));
        expect(await rewardDistirbutor.allocatedBalance()).to.equal(ethers.utils.parseEther("28.5"));
    });

    it("Should allow withdrawal of gather balance", async () => {
        await rewardDistirbutor.allocateRewards();
        await rewardDistirbutor.withdrawGatherBalance(gather.address);
        expect(await gather.getBalance()).to.equal(ethers.utils.parseEther("21").add(gatherInitialBalance));

        let contractBalance = await provider.getBalance(rewardDistirbutor.address);
        expect(contractBalance).to.equal(ethers.utils.parseEther("30"));

        expect(await rewardDistirbutor.gatherBalance()).to.equal(ethers.utils.parseEther("0"));
        expect(await rewardDistirbutor.allocatedBalance()).to.equal(ethers.utils.parseEther("30"));
    });

    it("Should allow withdrawal of all allocated funds", async () => {
        await rewardDistirbutor.allocateRewards();
        await rewardDistirbutor.withdrawAll(staker.address, masterNode.address, gather.address);

        expect(await staker.getBalance()).to.equal(ethers.utils.parseEther("7.5").add(stakerInitialBalance));
        expect(await masterNode.getBalance()).to.equal(ethers.utils.parseEther("22.5").add(masterNodeInitialBalance));
        expect(await gather.getBalance()).to.equal(ethers.utils.parseEther("21").add(gatherInitialBalance));

        let contractBalance = await provider.getBalance(rewardDistirbutor.address);
        expect(contractBalance).to.equal(ethers.utils.parseEther("0"));

        expect(await rewardDistirbutor.stakersBalance()).to.equal(ethers.utils.parseEther("0"));
        expect(await rewardDistirbutor.masterNodesBalance()).to.equal(ethers.utils.parseEther("0"));
        expect(await rewardDistirbutor.gatherBalance()).to.equal(ethers.utils.parseEther("0"));
        expect(await rewardDistirbutor.allocatedBalance()).to.equal(ethers.utils.parseEther("0"));
    });

    it("Should allow update of coefficients", async () => {
        await rewardDistirbutor.updateCoefficients(
            ethers.utils.parseUnits("2000", "wei"),
            ethers.utils.parseUnits("2000", "wei"),
            ethers.utils.parseUnits("6000", "wei"),
            ethers.utils.parseUnits("5000", "wei")
        )

        expect(await rewardDistirbutor.stakersCoefficient()).to.equal(ethers.utils.parseUnits("2000", "wei"));
        expect(await rewardDistirbutor.masterNodesCoefficient()).to.equal(ethers.utils.parseUnits("2000", "wei"));
        expect(await rewardDistirbutor.publishersCoefficient()).to.equal(ethers.utils.parseUnits("6000", "wei"));
        expect(await rewardDistirbutor.gatherCoefficient()).to.equal(ethers.utils.parseUnits("5000", "wei"));
        expect(await rewardDistirbutor.totalCoefficient()).to.equal(ethers.utils.parseUnits("10000", "wei"));
    });
});