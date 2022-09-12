// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "./interfaces/IRewardDistributorController.sol";

// This contract is used for staking GTH and distributing staking rewards among stakers
// Inspired from https://docs.synthetix.io/contracts/source/contracts/stakingrewards
contract StakingRewards is OwnableUpgradeable {
    
    IRewardDistributorController public rewardDistributorController;
    
    // Staked balance tracking variables
    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    // Reward tracking variables
    uint256 public lastUpdateBlock;
    uint256 public prevPendingReward;
    uint256 public rewardPerToken;
    uint256 public lastWithdrawBlock;
    uint256 public totalReward;
    uint256 public rewardDistributed;
    mapping(address => uint256) public userRewards;
    mapping(address => uint256) public userRewardPerToken;

    event Staked(address indexed user, uint256 amount);
    event UnStaked(address indexed user, uint256 amount);
    event RewardClaimed(address indexed user, uint256 reward);
    event RewardRedeployed(address indexed user, uint256 reward);
    event Exited(address indexed user);

    function initialize(address _rewardDistributorController) public initializer {
        __Ownable_init();
        rewardDistributorController = IRewardDistributorController(_rewardDistributorController);
    }
    /* ========== VIEWS ========== */

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    // Reflects state at last mutative interaction by any user
    function earned(address account) public view returns (uint256) {
        return userRewards[account] + (_balances[account] * (rewardPerToken - userRewardPerToken[account]) / 1e18);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function setRewardDistributorController(address _rewardDistributorController) external onlyOwner {
        rewardDistributorController = IRewardDistributorController(_rewardDistributorController);
    }

    function withdrawExcessReward(address payable receiver) external onlyOwner {
        uint256 excessReward = totalReward - rewardDistributed;
        totalReward = totalReward - excessReward;
        (bool sent, ) = receiver.call{value: excessReward}("");
        require(sent, "Receiver did not accept payment");
    }

    // We need to keep it as a function so that we can call it to update rewards 
    // in case there is no user interaction for some time
    function updateReward(address account, bool collect) public {

        // Call allocate only if interaction is happening in new block
        // Updating prevPendingReward for first stake causes reward generated before
        // this first call to be ignored for distribution
        if (block.number > lastUpdateBlock) {
            // Catch error to avoid revert of whole transaction in case second call in same block
            //in future when chain stops generating rewards, this try,Catch would help contract to be running as blocks would be committed but no rewards would be generated.
            try rewardDistributorController.allocateRewards() {} catch {}
            uint256 newPendingReward = rewardDistributorController.stakersBalance();
            uint256 newRewardPerToken = rewardPerToken;
            
            if (_totalSupply > 0) {
                newRewardPerToken = rewardPerToken + ((newPendingReward - prevPendingReward) * 1e18 / _totalSupply);
                rewardDistributed = rewardDistributed + newPendingReward - prevPendingReward;
            }

            // Effects, using check and effects pattern
            lastUpdateBlock = block.number;
            prevPendingReward = newPendingReward;
            rewardPerToken = newRewardPerToken;
        }

        if (collect && block.number > lastWithdrawBlock) {
            // This will withdraw all the GTH allocated to stakers even if there are no stakers
            // in this contract. This way some GTH may be left stuck in this contract forever
            rewardDistributorController.withdrawStakersBalance(payable(address(this)));
            lastWithdrawBlock = block.number;
            totalReward = totalReward + prevPendingReward;
            prevPendingReward = 0;
        } 

        // Need to keep it outside lastUpdateBlock because multiple users can call
        // updateReward in single block
        if (account != address(0)) {
            userRewards[account] = earned(account);
            userRewardPerToken[account] = rewardPerToken;
        }
    }

    function stake() payable external {
        uint256 amount = msg.value;
        require(amount > 0, "Cannot stake 0");
        updateReward(msg.sender, false);

        _totalSupply = _totalSupply + amount;
        _balances[msg.sender] = _balances[msg.sender] + amount;

        emit Staked(msg.sender, amount);
    }

    function unStake(uint256 amount) public {
        require(amount > 0, "Cannot unstake 0");
        require(_balances[msg.sender] >= amount, 
                "Cannot unstake more than available");

        updateReward(msg.sender, false);

        _totalSupply = _totalSupply - amount;
        _balances[msg.sender] = _balances[msg.sender] - amount;

        (bool sent, ) = payable(msg.sender).call{value: amount}("");
        require(sent, "Failed to send GTH");

        emit UnStaked(msg.sender, amount);
    }

    function claimReward() public {
        updateReward(msg.sender, true);

        uint256 reward = userRewards[msg.sender];
        if (reward > 0) {
            userRewards[msg.sender] = 0;

            (bool sent, ) = payable(msg.sender).call{value: reward}("");
            require(sent, "Failed to send GTH");
            
            emit RewardClaimed(msg.sender, reward);
        }
    }

    function redeployReward() public {
        updateReward(msg.sender, true);

        uint256 reward = userRewards[msg.sender];
        if (reward > 0) {
            userRewards[msg.sender] = 0;
            _totalSupply = _totalSupply + reward;
            _balances[msg.sender] = _balances[msg.sender] + reward;

            emit RewardRedeployed(msg.sender, reward);
        }
    }

    function exit() external {
        unStake(_balances[msg.sender]);
        claimReward();
        emit Exited(msg.sender);
    }

    // Required to receive GTH from RewardDistributor contract
    receive() external payable {}
}
