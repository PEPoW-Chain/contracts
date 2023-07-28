// SPDX-License-Identifier: MIT
// created by alexorbit
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract PEPOWToken is ERC20, ReentrancyGuard {
    struct MinerData {
        uint256 lastMinedBlock;
        uint256 stakeAmount;
        bool isMining;
    }

    uint256 public miningDifficulty;
    uint256 public totalStakedTokens;
    uint256 public totalStakers;
    uint256 public blockReward;
    uint256 public maxStakeSize;
    uint256 public lastMinedBlock;
    mapping(address => MinerData) public minerData;

    event Staked(address indexed user, uint256 amount, uint256 totalStaked);
    event Unstaked(address indexed user, uint256 amount, uint256 totalStaked);
    event Mined(address indexed user, uint256 reward);
    event MiningStopped(address indexed user);
    event MiningResumed(address indexed user);
    event DifficultyAdjusted(uint256 newDifficulty);
    event BlockRewardAdjusted(uint256 newBlockReward);
    event HashSpeed(uint256 speed);

    constructor(uint256 initialSupply, uint256 _miningDifficulty, uint256 _blockReward, uint256 _maxStakeSize) ERC20("PEPOWToken", "PEPOW") {
        require(initialSupply > 0, "Initial supply must be greater than zero");
        require(_miningDifficulty > 0, "Mining difficulty must be greater than zero");
        require(_blockReward > 0, "Block reward must be greater than zero");
        require(_maxStakeSize > 0, "Max stake size must be greater than zero");

        _mint(msg.sender, initialSupply);
        miningDifficulty = _miningDifficulty;
        blockReward = _blockReward;
        maxStakeSize = _maxStakeSize * (10 ** uint256(decimals()));
    }

    function stake(uint256 amount) public nonReentrant {
        require(amount > 0, "Stake amount must be greater than zero");
        require(balanceOf(msg.sender) >= amount, "Not enough balance to stake");
        require(minerData[msg.sender].stakeAmount + amount <= maxStakeSize, "Stake amount exceeds maximum limit");

        _burn(msg.sender, amount);
        minerData[msg.sender].stakeAmount += amount;
        totalStakedTokens += amount;
        if(!minerData[msg.sender].isMining) {
            minerData[msg.sender].isMining = true;
            totalStakers += 1;
        }
        adjustDifficulty();

        emit Staked(msg.sender, amount, totalStakedTokens);
    }

    function unstake(uint256 amount) public nonReentrant {
        require(amount > 0, "Unstake amount must be greater than zero");
        require(minerData[msg.sender].stakeAmount >= amount, "Not enough staked tokens to unstake");

        _mint(msg.sender, amount);
        minerData[msg.sender].stakeAmount -= amount;
        totalStakedTokens -= amount;
        if(minerData[msg.sender].stakeAmount == 0) {
            minerData[msg.sender].isMining = false;
            totalStakers -= 1;
        }
        adjustDifficulty();

        emit Unstaked(msg.sender, amount, totalStakedTokens);
    }

    function mine(uint256 nonce) public nonReentrant {
        require(minerData[msg.sender].isMining, "You are not currently mining");
        require(block.number > lastMinedBlock + miningDifficulty, "A block has been mined too recently");
        require(block.number > minerData[msg.sender].lastMinedBlock + miningDifficulty, "You are mining too fast");
        
        bytes32 hash = keccak256(abi.encodePacked(block.number, msg.sender, nonce));
        require(uint256(hash) < miningDifficulty * minerData[msg.sender].stakeAmount, "Hash does not meet difficulty requirements");

        _mint(msg.sender, blockReward);
        lastMinedBlock = block.number;
        minerData[msg.sender].lastMinedBlock = block.number;
        adjustBlockReward();

        // Calculate hash speed based on user's staked tokens
        uint256 hashSpeed = minerData[msg.sender].stakeAmount * (block.number - minerData[msg.sender].lastMinedBlock);
        emit HashSpeed(hashSpeed);

        emit Mined(msg.sender, blockReward);
    }

    function stopMining() public {
        require(minerData[msg.sender].isMining, "You are not currently mining");
        minerData[msg.sender].isMining = false;
        emit MiningStopped(msg.sender); 
    }

    function resumeMining() public {
        require(!minerData[msg.sender].isMining, "You are already mining");
        require(minerData[msg.sender].stakeAmount > 0, "You do not have any staked tokens");
        minerData[msg.sender].isMining = true;
        emit MiningResumed(msg.sender);
    }

    function adjustDifficulty() internal {
        if (totalStakers > 0 && block.number > lastMinedBlock) {
            miningDifficulty = miningDifficulty + (totalStakedTokens * maxStakeSize) / (totalStakers * maxStakeSize);
            emit DifficultyAdjusted(miningDifficulty);
        }
    }

    function adjustBlockReward() internal {
        if (totalStakedTokens > 100000 * (10 ** uint256(decimals()))) {
            blockReward = (blockReward * 9) / 10;
        } else if (totalStakedTokens < 50000 * (10 ** uint256(decimals()))) {
            blockReward = (blockReward * 11) / 10;
        }
        emit BlockRewardAdjusted(blockReward);
    }
}
