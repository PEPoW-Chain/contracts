// SPDX-License-Identifier: MIT
// Created by Alexorbit
pragma solidity ^0.8.21;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract PoWToken is ERC20, Ownable, ReentrancyGuard {
    struct MinerData {
        uint256 lastMinedBlock;
        uint256 stakeAmount;
        bool isMining;
    }

    uint256 public miningRate;

    mapping (address => MinerData) private _minerData;

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event Mined(address indexed user, uint256 reward);
    event MiningStarted(address indexed user);
    event MiningStopped(address indexed user);

    constructor() ERC20("PEPoW Miner", "PPW") {
        _mint(msg.sender, 100000 * 10**18);
        miningRate = 1;
    }

    function stake(uint256 amount) external nonReentrant {
        _burn(msg.sender, amount);
        _minerData[msg.sender].stakeAmount += amount;
        if (!_minerData[msg.sender].isMining) {
            _minerData[msg.sender].isMining = true;
            emit MiningStarted(msg.sender);
        }
        emit Staked(msg.sender, amount);
    }

    function unstake(uint256 amount) external nonReentrant {
        require(_minerData[msg.sender].stakeAmount >= amount, "Unstaking more than you have staked");
        mine();
        _minerData[msg.sender].stakeAmount -= amount;
        _mint(msg.sender, amount);
        emit Unstaked(msg.sender, amount);
    }

    function mine() public nonReentrant {
        require(_minerData[msg.sender].stakeAmount > 0, "No stake to mine");
        uint256 toMint = getMineable(msg.sender);
        _mint(msg.sender, toMint);
        _minerData[msg.sender].lastMinedBlock = block.number;
        emit Mined(msg.sender, toMint);
    }

    function getMineable(address account) public view returns (uint256) {
        uint256 stakedAmount = _minerData[account].stakeAmount;
        uint256 lastClaimBlock = _minerData[account].lastMinedBlock;
        uint256 elapsedBlocks = block.number - lastClaimBlock;
        return elapsedBlocks * stakedAmount * miningRate;
    }

    function isMining(address account) public view returns (bool) {
        return _minerData[account].isMining;
    }

    function stopMining() external {
        require(_minerData[msg.sender].isMining, "You are not currently mining");
        _minerData[msg.sender].isMining = false;
        emit MiningStopped(msg.sender);
    }

    function startMining() external {
        require(!_minerData[msg.sender].isMining, "You are already mining");
        require(_minerData[msg.sender].stakeAmount > 0, "You do not have any staked tokens");
        _minerData[msg.sender].isMining = true;
        emit MiningStarted(msg.sender);
    }

    // Override ERC20 functions with the correct visibility and return types

    function totalSupply() public view override returns (uint256) {
        return super.totalSupply();
    }

    function balanceOf(address account) public view override returns (uint256) {
        return super.balanceOf(account);
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return super.allowance(owner, spender);
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        super.approve(spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        super.transferFrom(sender, recipient, amount);
        return true;
    }
}
