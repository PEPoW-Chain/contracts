// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PPoWbeta is ERC20, Ownable {
    uint256 public miningRate;

    mapping (address => uint256) private _stakes;
    mapping (address => uint256) private _lastClaim;
    mapping (address => uint256) private _nonces;

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event Mined(address indexed user, uint256 reward);

    constructor() ERC20("PEPoW", "PPW") {
        _mint(msg.sender, 100000 * 10**18);
        miningRate = 1;
    }

    function stake(uint256 amount, uint256 nonce) public {
        _burn(msg.sender, amount);
        _stakes[msg.sender] += amount;
        _nonces[msg.sender] = nonce;
        _lastClaim[msg.sender] = block.timestamp;
        emit Staked(msg.sender, amount);
    }

    function unstake(uint256 amount) public {
        require(_stakes[msg.sender] >= amount, "Unstaking more than you have staked");
        mine();
        _stakes[msg.sender] -= amount;
        _mint(msg.sender, amount);
        emit Unstaked(msg.sender, amount);
    }

    function mine() public {
        require(_stakes[msg.sender] > 0, "No stake to mine");
        uint256 toMint = getMineable(msg.sender);
        _lastClaim[msg.sender] = block.timestamp;
        _mint(msg.sender, toMint);
        emit Mined(msg.sender, toMint);
    }

    function getMineable(address account) public view returns (uint256) {
        uint256 stakedAmount = _stakes[account];
        uint256 lastClaimTime = _lastClaim[account];
        uint256 elapsedTime = block.timestamp - lastClaimTime;
        uint256 difficulty = _nonces[account];  // Simplified difficulty calculation based on nonce
        return elapsedTime * stakedAmount * miningRate / difficulty;
    }

    function stakedAmountOf(address account) public view returns (uint256) {
        return _stakes[account];
    }

    function lastClaimTimeOf(address account) public view returns (uint256) {
        return _lastClaim[account];
    }
}
