// SPDX-License-Identifier: MIT
// created by alexorbit
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract PEPOWToken is ERC20, ReentrancyGuard {
    using SafeMath for uint256;

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

    constructor(uint256 initialSupply, uint256 _miningDifficulty, uint256 _blockReward) ERC20("PEPOWToken", "PEPOW") {
        _mint(msg.sender, initialSupply);
        miningDifficulty = _miningDifficulty;
        blockReward = _blockReward;
        maxStakeSize = 50000 * (10 ** uint256(decimals()));
    }

    function stake(uint256 amount) public nonReentrant {
        require(balanceOf(msg.sender) >= amount, "Not enough balance to stake");
        require(minerData[msg.sender].stakeAmount.add(amount) <= maxStakeSize, "Stake amount exceeds maximum limit");

        _burn(msg.sender, amount);
        minerData[msg.sender].stakeAmount = minerData[msg.sender].stakeAmount.add(amount);
        totalStakedTokens = totalStakedTokens.add(amount);
        if(minerData[msg.sender].stakeAmount == 0) {
            totalStakers = totalStakers.add(1);
        }
        adjustDifficulty();

        emit Staked(msg.sender, amount, totalStakedTokens);
    }

    function unstake(uint256 amount) public nonReentrant {
        require(minerData[msg.sender].stakeAmount >= amount, "Not enough staked tokens to unstake");

        _mint(msg.sender, amount);
        minerData[msg.sender].stakeAmount = minerData[msg.sender].stakeAmount.sub(amount);
        totalStakedTokens = totalStakedTokens.sub(amount);
        if(minerData[msg.sender].stakeAmount == 0) {
            totalStakers = totalStakers.sub(1);
        }
        adjustDifficulty();

        emit Unstaked(msg.sender, amount, totalStakedTokens);
    }

    function mine(uint256 nonce) public nonReentrant {
        require(minerData[msg.sender].isMining, "You are not currently mining");
        require(block.number > lastMinedBlock.add(miningDifficulty), "A block has been mined too recently");
        require(block.number > minerData[msg.sender].lastMinedBlock.add(miningDifficulty), "You are mining too fast");
        
        bytes32 hash = keccak256(abi.encodePacked(block.number, msg.sender, nonce));
        require(uint256(hash) < miningDifficulty.mul(minerData[msg.sender].stakeAmount), "Hash does not meet difficulty requirements");

        _mint(msg.sender, blockReward);
        lastMinedBlock = block.number;
        minerData[msg.sender].lastMinedBlock = block.number;
        adjustBlockReward();

        // Calculate hash speed based on user's staked tokens
        uint256 hashSpeed = minerData[msg.sender].stakeAmount.mul(block.number.sub(minerData[msg.sender].lastMinedBlock));
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
        if (block.number > lastMinedBlock) {
            miningDifficulty = miningDifficulty.add(totalStakedTokens.mul(maxStakeSize).div(totalStakers.mul(maxStakeSize)));
            emit DifficultyAdjusted(miningDifficulty);
        }
    }

    function adjustBlockReward() internal {
        if (totalStakedTokens > 100000 * (10 ** uint256(decimals()))) {
            blockReward = blockReward.mul(9).div(10);
        } else if (totalStakedTokens < 50000 * (10 ** uint256(decimals()))) {
            blockReward = blockReward.mul(11).div(10);
        }
        emit BlockRewardAdjusted(blockReward);
    }
}
