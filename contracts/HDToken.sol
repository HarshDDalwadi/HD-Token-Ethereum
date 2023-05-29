// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../node_modules/@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract HDToken is ERC20 {
    using SafeMath for uint256;

    uint256 private constant INITIAL_SUPPLY = 1000000 * (10 ** 18);
    uint256 private constant SECONDS_IN_MINUTES = 60;

    struct Stake {
        uint256 amount;
        uint256 startTimestamp;
    }

    mapping(address => Stake) private stakes;
    mapping(address => uint256) private rewards;

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event Claimed(address indexed user, uint256 amount);

    constructor() ERC20("HD Token", "HDT") {
        _mint(msg.sender, INITIAL_SUPPLY);
    }

    function stake(uint256 amount) public {
        require(amount > 0, "Amount must be greater than zero");
        amount = amount * (10 ** decimals());
        require(balanceOf(msg.sender) >= amount, "Insufficient balance");

        if (stakes[msg.sender].amount > 0) {
            uint256 pendingRewards = calculatePendingRewards(msg.sender);
            rewards[msg.sender] = rewards[msg.sender].add(pendingRewards);
        }

        stakes[msg.sender] = Stake(amount, block.timestamp);

        _burn(msg.sender, amount);
        emit Staked(msg.sender, amount);
    }

    function unstake() public {
        require(stakes[msg.sender].amount > 0, "No stakes found");
        uint256 pendingRewards = calculatePendingRewards(msg.sender);
        rewards[msg.sender] = rewards[msg.sender].add(pendingRewards);

        uint256 stakedAmount = stakes[msg.sender].amount;
        delete stakes[msg.sender];

        _mint(msg.sender, stakedAmount);
        emit Unstaked(msg.sender, stakedAmount);
    }

    function claimRewards() public {
        uint256 pendingRewards = rewards[msg.sender];
        require(pendingRewards > 0, "No rewards available");

        rewards[msg.sender] = 0;
        _mint(msg.sender, pendingRewards / (10 ** decimals()));
        emit Claimed(msg.sender, pendingRewards);
    }

    function calculatePendingRewards(
        address account
    ) public view returns (uint256) {
        Stake memory stakeData = stakes[account];
        uint256 stakedAmount = stakeData.amount;
        uint256 startTimestamp = stakeData.startTimestamp;
        uint256 stakingDuration = block.timestamp.sub(startTimestamp);
        uint256 daysStaked = stakingDuration.div(SECONDS_IN_MINUTES);

        uint baseRewards = stakedAmount.div(100);
        uint256 rewardRate = 1;
        uint256 reward = 0;

        for (uint256 i = 0; i < daysStaked; i++) {
            reward = reward.add(baseRewards.mul(rewardRate));
            rewardRate++;
        }

        return reward;
    }
}
