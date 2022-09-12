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
contract RewardDistributorV2 is OwnableUpgradeable {
    // all values were multiplied by 100 because solidity doesn't have float number
    uint256 public stakersCoefficient; //this variable is not used in the contract calculations. It is used just by geth code to calculate the reward for coinbase address
    uint256 public masterNodesCoefficient; //this variable is not used in the contract calculations. It is used just by geth code to calculate the reward for coinbase address
    uint256 public publishersCoefficient;
    uint256 public gatherCoefficient;
    uint256 public totalCoefficient;

    // frozen balance for each case of reward
    uint256 public stakersBalance;
    uint256 public masterNodesBalance;
    uint256 public gatherBalance;
    uint256 public allocatedBalance;
    
    // first upgrade to v2 new variables start
    bool private _initializedV2;
    uint256 public publishersBalance;
    uint256 public burnBalance;

    uint256 public newStakersCoefficient;
    uint256 public newMasterNodesCoefficient;
    uint256 public burnPublishersCoefficient;
    uint256 public burnGatherCoefficient;
    
    address constant burnAddress =  0x0000000000000000000000000000000000000000;
    // first upgrade to v2 new variables end
    
    modifier validReceiver(
        address payable receiver
    ) {
        require(
            receiver != address(0) && receiver != address(this), 
            "Distribution: provided address should not be zero address or self"
        );
        _;
    }

    event WithdrawStakersBalance(uint256 stakersBalance);
    event WithdrawMasterNodesBalance(uint256 masterNodesBalance);
    event WithdrawGatherBalance(uint256 gatherBalance);
    event WithdrawPublishersBalance(uint256 publishersBalance);
    event Burn(uint256 burnBalance);

    event UpdateCoefficients(
        uint256 newStakersCoefficient,
        uint256 newMasterNodesCoefficient,
        uint256 publishersCoefficient,
        uint256 gatherCoefficient,
        uint256 burnPublishersCoefficient,
        uint256 burnGatherCoefficient);

    event AllocateRewards(
        uint256 totalBlockReward, 
        uint256 masterNodesBalance, 
        uint256 stakersBalance, 
        uint256 burnBalance,
        uint256 publishersBalance,
        uint256 gatherBalance, 
        uint256 allocatedBalance);    

    function initialize() public initializer {
        __Ownable_init();
        stakersCoefficient = 750; // uses for 7.5% this variable is not used in the contract calculations. It is used just by geth code to calculate the reward for coinbase address
        masterNodesCoefficient = 2250; // uses for 22.5%
        publishersCoefficient = 7000; // uses for 70%
        gatherCoefficient = 3000; // uses for 30%
        totalCoefficient = 100 * 100;
    }

    // Initialize new variables and change required new variables
    // This function does not have initializer modifier because proxy has already been initialized
    function initializeV2() public {
        require(!_initializedV2, "V2 already initialized");
        
        // Allocate pending rewards till now before updating coefficients
        allocateRewardsOld();

        masterNodesCoefficient = 9250; // 92.5%  this variable is not used in the contract calculations. It is used just by geth code to calculate the reward for coinbase address

        newMasterNodesCoefficient = 2250; // uses for 22.5%
        newStakersCoefficient = 750;
        burnPublishersCoefficient = 9000;
        burnGatherCoefficient = 9000;

        _initializedV2 = true;
    }

    function validateCoefficients(
        uint256 _newStakersCoefficient,
        uint256 _newMasterNodesCoefficient,
        uint256 _publishersCoefficient,
        uint256 _gatherCoefficient,
        uint256 _burnPublishersCoefficient,
        uint256 _burnGatherCoefficient
    ) public view {
        require(
            _newStakersCoefficient + _newMasterNodesCoefficient + _publishersCoefficient == totalCoefficient,
            "Distribution: Total amount of coefficients should be equal to total coefficient."
        );

        require(
            _gatherCoefficient <= totalCoefficient,
            "Distribution: A coefficient for _gatherCoefficient should be less or equal to total coefficient."
        );
        require(
            _burnPublishersCoefficient <= totalCoefficient,
            "Distribution: A coefficient for _burnPublishersCoefficient should be less or equal to total coefficient."
        );
        require(
            _burnGatherCoefficient <= totalCoefficient,
            "Distribution: A coefficient for _burnGatherCoefficient should be less or equal to total coefficient."
        );
    }

    function _withdrawStakersBalance(
        address payable receiver
    ) internal validReceiver(receiver) {
        if (stakersBalance > 0) {
            (bool sent, ) = receiver.call{value: stakersBalance}("");
            require(sent, "Failed to send GTH");
            emit WithdrawStakersBalance(stakersBalance);
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
            emit WithdrawMasterNodesBalance(masterNodesBalance);
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
            emit WithdrawGatherBalance(gatherBalance);
            allocatedBalance = allocatedBalance - gatherBalance;
            gatherBalance = 0;
        }
    }

    // Added at upgrade to V2
    function _withdrawPublishersBalance(
        address payable receiver
    ) internal validReceiver(receiver) {
        if (publishersBalance > 0) {
            (bool sent, ) = receiver.call{value: publishersBalance}("");
            require(sent, "Failed to send GTH");
            emit WithdrawPublishersBalance(publishersBalance);
            allocatedBalance = allocatedBalance - publishersBalance;
            publishersBalance = 0;
        }
    }

    // Added at upgrade to V2
    function _burn() internal {
        if (burnBalance > 0) {
            (bool sent, ) = payable(burnAddress).call{value: burnBalance}("");
            require(sent, "Failed to send GTH");
            emit Burn(burnBalance);
            allocatedBalance = allocatedBalance - burnBalance;
            burnBalance = 0;
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

    // Added at upgrade to V2
    function withdrawPublishersBalance(
        address payable receiver
    ) public onlyOwner {
        _withdrawPublishersBalance(receiver);
    }

    // Added at upgrade to V2
    function burn() public onlyOwner {
        _burn();
    }

    // Updated at upgrade to V2
    function withdrawAll(
        address payable stakersReceiver,
        address payable masterNodesReceiver,
        address payable gatherReceiver,
        address payable publishersReceiver
    ) public onlyOwner {
        _withdrawStakersBalance(stakersReceiver);
        _withdrawMasterNodesBalance(masterNodesReceiver);
        _withdrawGatherBalance(gatherReceiver);
        _withdrawPublishersBalance(publishersReceiver);
        _burn();
    }

    /*
    Updated at upgrade to V2
    All values for coefficients should be mul by 100
    For ex: if it needs to have a stakersCoefficient as 67.9 %
    then it needs to be provided 6790 value for _stakersCoefficient
    */
    function updateCoefficients(
        uint256 _newStakersCoefficient,
        uint256 _newMasterNodesCoefficient,
        uint256 _publishersCoefficient,
        uint256 _gatherCoefficient,
        uint256 _burnPublishersCoefficient,
        uint256 _burnGatherCoefficient
    ) public onlyOwner {
        validateCoefficients(
            _newStakersCoefficient,
            _newMasterNodesCoefficient,
            _publishersCoefficient,
            _gatherCoefficient,
            _burnPublishersCoefficient,
            _burnGatherCoefficient
        );
        if (newStakersCoefficient != _newStakersCoefficient)
            newStakersCoefficient = _newStakersCoefficient;
        if (newMasterNodesCoefficient != _newMasterNodesCoefficient)
            newMasterNodesCoefficient = _newMasterNodesCoefficient;
        if (publishersCoefficient != _publishersCoefficient)
            publishersCoefficient = _publishersCoefficient;
        if (gatherCoefficient != _gatherCoefficient)
            gatherCoefficient = _gatherCoefficient;
        if (burnPublishersCoefficient != _burnPublishersCoefficient)
            burnPublishersCoefficient = _burnPublishersCoefficient;
        if (burnGatherCoefficient != _burnGatherCoefficient)
            burnGatherCoefficient = _burnGatherCoefficient;
        
        emit UpdateCoefficients(
            newStakersCoefficient,
            newMasterNodesCoefficient,
            publishersCoefficient,
            gatherCoefficient,
            burnPublishersCoefficient,
            burnGatherCoefficient);
    }

    function allocateRewardsOld() internal {
        uint256 toBeAllocatedBalance = address(this).balance - allocatedBalance;
        if (toBeAllocatedBalance == 0) {
            return;
        }

        uint256 numerator = toBeAllocatedBalance * totalCoefficient;
        uint256 divider = stakersCoefficient + masterNodesCoefficient + ((publishersCoefficient * gatherCoefficient)/totalCoefficient);
        uint256 totalBlockReward = numerator / divider;

        stakersBalance = stakersBalance + ((totalBlockReward * stakersCoefficient) / totalCoefficient);
        
        masterNodesBalance = masterNodesBalance + ((totalBlockReward * masterNodesCoefficient) / totalCoefficient);
        
        uint256 publishersPart = (totalBlockReward * publishersCoefficient) / totalCoefficient;
        gatherBalance = gatherBalance + ((publishersPart * gatherCoefficient) / totalCoefficient);

        allocatedBalance = stakersBalance + masterNodesBalance + gatherBalance;
    }

    /*
    Updated at upgrade to V2

    s + m + p = total

    s = total * sc/100
    m = total * mc/100
    p = total * pc/100
    g = p * gc/100

    available balance = s + m + p
    total = availableBalance

     */
    function allocateRewards() public onlyOwner {
        require(
            allocatedBalance < address(this).balance,
            "Distribution: Did not recevie rewards after last distribution"
        );

        uint256 totalBlockReward = address(this).balance - allocatedBalance;

        masterNodesBalance = masterNodesBalance + ((totalBlockReward * newMasterNodesCoefficient) / totalCoefficient);

        stakersBalance = stakersBalance + ((totalBlockReward * newStakersCoefficient) / totalCoefficient);
        
        uint256 totalPublishersBalance = (totalBlockReward * publishersCoefficient) / totalCoefficient;
        uint256 gatherBalanceBeforeBurn = (totalPublishersBalance * gatherCoefficient) / totalCoefficient ;
        uint256 publishersBalanceBeforeBurn = totalPublishersBalance - gatherBalanceBeforeBurn;
        
        uint256 gatherBurnAmount = (gatherBalanceBeforeBurn * burnGatherCoefficient) / totalCoefficient;
        uint256 publishersBurnAmount = (publishersBalanceBeforeBurn * burnPublishersCoefficient) / totalCoefficient;
        
        burnBalance = burnBalance + gatherBurnAmount + publishersBurnAmount;
        
        publishersBalance = publishersBalance + publishersBalanceBeforeBurn - publishersBurnAmount;

        gatherBalance = gatherBalance + gatherBalanceBeforeBurn - gatherBurnAmount;

        allocatedBalance = stakersBalance + masterNodesBalance + gatherBalance + publishersBalance + burnBalance;

        emit AllocateRewards(
            totalBlockReward, 
            masterNodesBalance, 
            stakersBalance, 
            burnBalance,
            publishersBalance,
            gatherBalance, 
            allocatedBalance);
    }

    receive() external payable {}
}