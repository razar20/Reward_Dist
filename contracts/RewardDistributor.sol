// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/*
    Stakers get 7.5%
    Masternodes get 22.5%
    Publishers get 70%
    Gather commission is 30% on Publishers' portion
    (so in effect publishers get 70% of the 70% they are entitled to; 30% of that 70% goes to gather as commission)
*/
contract RewardDistributor is OwnableUpgradeable {
    // all values were multiplied by 100 because solidity doesn't have float number
    uint256 public stakersCoefficient;
    uint256 public masterNodesCoefficient;
    uint256 public publishersCoefficient;
    uint256 public gatherCoefficient;
    uint256 public totalCoefficient;

    // frozen balance for each case of reward
    uint256 public stakersBalance;
    uint256 public masterNodesBalance;
    uint256 public gatherBalance;
    uint256 public allocatedBalance;

    modifier validReceiver(
        address payable receiver
    ) {
        require(
            receiver != address(0) && receiver != address(this), 
            "Distribution: provided address should not be zero address or self"
        );
        _;
    }

    function initialize() public initializer {
        __Ownable_init();
        stakersCoefficient = 750; // uses for 7.5%
        masterNodesCoefficient = 2250; // uses for 22.5%
        publishersCoefficient = 7000; // uses for 70%
        gatherCoefficient = 3000; // uses for 30%
        totalCoefficient = 100 * 100;
    }

    function validateCoefficients(
        uint256 _stakersCoefficient,
        uint256 _masterNodesCoefficient,
        uint256 _publishersCoefficient,
        uint256 _gatherCoefficient
    ) public view {
        require(
            _stakersCoefficient + _masterNodesCoefficient + _publishersCoefficient == totalCoefficient,
            "Distribution: Total amount of coefficients should be equal to total coefficient."
        );

        require(
            _gatherCoefficient <= totalCoefficient,
            "Distribution: A coefficient for _gatherCoefficient should be less or equal to total coefficient."
        );
    }

    function _withdrawStakersBalance(
        address payable receiver
    ) internal validReceiver(receiver) {
        if (stakersBalance > 0) {
            (bool sent, ) = receiver.call{value: stakersBalance}("");
            require(sent, "Failed to send GTH");
            allocatedBalance = allocatedBalance - stakersBalance;
            stakersBalance = 0;
        }
    }

    function _withdrawMasterNodesBalance(
        address payable receiver
    ) internal validReceiver(receiver) {
        if (masterNodesBalance > 0) {
            (bool sent, ) = receiver.call{value: masterNodesBalance}("");
            require(sent, "Failed to send GTH");
            allocatedBalance = allocatedBalance - masterNodesBalance;
            masterNodesBalance = 0;
        }
    }

    function _withdrawGatherBalance(
        address payable receiver
    ) internal validReceiver(receiver) {
        if (gatherBalance > 0) {
            (bool sent, ) = receiver.call{value: gatherBalance}("");
            require(sent, "Failed to send GTH");
            allocatedBalance = allocatedBalance - gatherBalance;
            gatherBalance = 0;
        }
    }

    function withdrawStakersBalance(
        address payable receiver
    ) public onlyOwner {
        _withdrawStakersBalance(receiver);
    }

    function withdrawMasterNodesBalance(
        address payable receiver
    ) public onlyOwner {
        _withdrawMasterNodesBalance((receiver));
    }

    function withdrawGatherBalance(
        address payable receiver
    ) public onlyOwner {
        _withdrawGatherBalance(receiver);
    }

    function withdrawAll(
        address payable stakersReceiver,
        address payable masterNodesReceiver,
        address payable gatherReceiver
    ) public onlyOwner {
        _withdrawStakersBalance(stakersReceiver);
        _withdrawMasterNodesBalance(masterNodesReceiver);
        _withdrawGatherBalance(gatherReceiver);
    }

    /*
    All values for coefficients should be mul by 100
    For ex: if it needs to have a stakersCoefficient as 67.9 %
    then it needs to be provided 6790 value for _stakersCoefficient
    */
    function updateCoefficients(
        uint256 _stakersCoefficient,
        uint256 _masterNodesCoefficient,
        uint256 _publishersCoefficient,
        uint256 _gatherCoefficient
    ) public onlyOwner {
        validateCoefficients(
            _stakersCoefficient,
            _masterNodesCoefficient,
            _publishersCoefficient,
            _gatherCoefficient
        );
        if (stakersCoefficient != _stakersCoefficient)
            stakersCoefficient = _stakersCoefficient;
        if (masterNodesCoefficient != _masterNodesCoefficient)
            masterNodesCoefficient = _masterNodesCoefficient;
        if (publishersCoefficient != _publishersCoefficient)
            publishersCoefficient = _publishersCoefficient;
        if (gatherCoefficient != _gatherCoefficient)
            gatherCoefficient = _gatherCoefficient;
    }

    /*
    s + m + p = total

    s = total * sc/100
    m = total * mc/100
    p = total * pc/100
    g = p * gc/100

    available balance = s + m + g

    available * 100 = total * (sc + mc + (pc * gc/100))

    total = available * 100 / (sc + mc + (pc * gc/100))
     */
    function allocateRewards() public onlyOwner {
        require(
            allocatedBalance < address(this).balance,
            "Distribution: Did not recevie rewards after last distribution"
        );

        uint256 toBeAllocatedBalance = address(this).balance - allocatedBalance;

        uint256 numerator = toBeAllocatedBalance * totalCoefficient;
        uint256 divider = stakersCoefficient + masterNodesCoefficient + ((publishersCoefficient * gatherCoefficient)/totalCoefficient);
        uint256 totalBlockReward = numerator / divider;

        stakersBalance = stakersBalance + ((totalBlockReward * stakersCoefficient) / totalCoefficient);
        
        masterNodesBalance = masterNodesBalance + ((totalBlockReward * masterNodesCoefficient) / totalCoefficient);
        
        uint256 publishersPart = (totalBlockReward * publishersCoefficient) / totalCoefficient;
        gatherBalance = gatherBalance + ((publishersPart * gatherCoefficient) / totalCoefficient);

        allocatedBalance = stakersBalance + masterNodesBalance + gatherBalance;
    }

    receive() external payable {}
}
