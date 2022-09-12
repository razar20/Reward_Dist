// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import "./RewardDistributorV2.sol";
import "./interfaces/IRewardDistributorController.sol";

contract RewardDistributorController is IRewardDistributorController, AccessControlUpgradeable{

    bytes32 public constant STAKERS_ROLE = keccak256("STAKERS");
    bytes32 public constant MASTER_NODES_ROLE = keccak256("MASTER_NODES");
    bytes32 public constant PUBLISHERS_ROLE = keccak256("PUBLISHERS");
    bytes32 public constant GATHER_ROLE = keccak256("GATHER");

    RewardDistributorV2 public rewardDistributor;
     
    function initialize(address payable _rewardDistributor) public initializer {
            __AccessControl_init();
            _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

            rewardDistributor = RewardDistributorV2(_rewardDistributor);
    }
    event RewardDistributorOwnerChanged(address owner, address newOwner);
    
    /* ========== Admin only functions ========== */

    function setRewardDistributor(address payable _rewardDistributor) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        rewardDistributor = RewardDistributorV2(_rewardDistributor);
    }

    function updateCoefficients(
        uint256 _newStakersCoefficient,
        uint256 _newMasterNodesCoefficient,
        uint256 _publishersCoefficient,
        uint256 _gatherCoefficient,
        uint256 _burnPublishersCoefficient,
        uint256 _burnGatherCoefficient
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        rewardDistributor.updateCoefficients(
            _newStakersCoefficient,
            _newMasterNodesCoefficient,
            _publishersCoefficient,
            _gatherCoefficient,
            _burnPublishersCoefficient,
            _burnGatherCoefficient
        );
    }

    function withdrawAll(
        address payable stakersReceiver,
        address payable masterNodesReceiver,
        address payable gatherReceiver,
        address payable publishersReceiver
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        rewardDistributor.withdrawAll(
            stakersReceiver,
            masterNodesReceiver,
            gatherReceiver,
            publishersReceiver
        );
    }

    function burn() external override onlyRole(DEFAULT_ADMIN_ROLE) {
        rewardDistributor.burn();
    }

    /* ========== Role based functions, can be called by admin as well ========== */

    function withdrawStakersBalance(address payable receiver) external override onlyRole(STAKERS_ROLE) {
        rewardDistributor.withdrawStakersBalance(receiver);
    }

    function withdrawMasterNodesBalance(address payable receiver) external override onlyRole(MASTER_NODES_ROLE) {
        rewardDistributor.withdrawMasterNodesBalance(receiver);
    }

    function withdrawGatherBalance(address payable receiver) external override onlyRole(GATHER_ROLE) {
        rewardDistributor.withdrawGatherBalance(receiver);
    }

    function withdrawPublishersBalance(address payable receiver) external override onlyRole(PUBLISHERS_ROLE) {
        rewardDistributor.withdrawPublishersBalance(receiver);
    }

    /* ========== Common functions, can be called by anyone ========== */

    function allocateRewards() external override {
      rewardDistributor.allocateRewards();
    }

    function stakersBalance() external view override returns(uint256) {
      return rewardDistributor.stakersBalance();
    }

    function masterNodesBalance() external view override returns(uint256) {
      return rewardDistributor.masterNodesBalance();
    }

    function gatherBalance() external view override returns(uint256) {
      return rewardDistributor.gatherBalance();
    }

    function publishersBalance() external view override returns(uint256) {
      return rewardDistributor.publishersBalance();
    }

    function burnBalance() external view override returns(uint256) {
      return rewardDistributor.burnBalance();
    }

    function changeRewardDistributorOwner(address newOwner) external onlyRole(DEFAULT_ADMIN_ROLE) returns(bool success) {
        require(newOwner != address(0), "New owner can not be zero address"); 
        rewardDistributor.transferOwnership(newOwner); 
        emit RewardDistributorOwnerChanged(address(this), newOwner);
        return true;
    }

    function allocatedBalance() external view override returns(uint256) {
      return rewardDistributor.allocatedBalance();
    }
}