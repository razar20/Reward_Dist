// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.4;

interface IRewardDistributorController {
    // Admin only functions
    function setRewardDistributor(address payable _rewardDistributor) external;

    function updateCoefficients(
        uint256 _newStakersCoefficient,
        uint256 _newMasterNodesCoefficient,
        uint256 _publishersCoefficient,
        uint256 _gatherCoefficient,
        uint256 _burnPublishersCoefficient,
        uint256 _burnGatherCoefficient
    ) external;

    function withdrawAll(
        address payable stakersReceiver,
        address payable masterNodesReceiver,
        address payable gatherReceiver,
        address payable publishersReceiver
    ) external;

    function burn() external;


    // Role based functions, can be called by admin as well
    function withdrawStakersBalance(address payable receiver) external;
    function withdrawMasterNodesBalance(address payable receiver) external;
    function withdrawGatherBalance(address payable receiver) external;
    function withdrawPublishersBalance(address payable receiver) external;


    // Common functions, can be called by anyone
    function allocateRewards() external;
    function stakersBalance() external view returns(uint256);
    function masterNodesBalance() external view returns(uint256);
    function gatherBalance() external view returns(uint256);
    function publishersBalance() external view returns(uint256);
    function burnBalance() external view returns(uint256);
    function allocatedBalance() external view returns(uint256);
}