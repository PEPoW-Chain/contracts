    // SPDX-License-Identifier: MIT
    // Created by Alexorbit - https://linkd.in/alexorbit
    pragma solidity ^0.8.0;

    import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
    import "@openzeppelin/contracts/utils/math/SafeMath.sol";

    contract PEPOWToken is ERC20 {
        using SafeMath for uint256;

        struct MinerData {
            uint256 lastMinedBlock;
            uint256 stakeAmount;
        }

        uint256 public miningDifficulty;
        uint256 public lastMinedBlock;
        uint256 public blockReward;
        
        mapping(address => MinerData) public minerData;

        event Staked(address indexed user, uint256 amount, uint256 totalAmount);
        event Unstaked(address indexed user, uint256 amount, uint256 totalAmount);
        event Mined(address indexed user, uint256 reward);

        constructor(uint256 initialSupply, uint256 difficulty, uint256 reward) ERC20("PEPOW Token", "PPOW") {
            _mint(msg.sender, initialSupply);
            miningDifficulty = difficulty;
            blockReward = reward;
        }

        function decimals() public view virtual override returns (uint8) {
            return 6;
        }


        function stake(uint256 amount) public {
            _burn(msg.sender, amount);
            minerData[msg.sender].stakeAmount = minerData[msg.sender].stakeAmount.add(amount);
            emit Staked(msg.sender, amount, minerData[msg.sender].stakeAmount);
        }

        function withdrawStake(uint256 amount) public {
            require(minerData[msg.sender].stakeAmount >= amount, "You don't have enough staked tokens");
            _mint(msg.sender, amount);
            minerData[msg.sender].stakeAmount = minerData[msg.sender].stakeAmount.sub(amount);
            emit Unstaked(msg.sender, amount, minerData[msg.sender].stakeAmount);
        }

        function mine(uint256 nonce) public {
            require(block.number.sub(lastMinedBlock) >= miningDifficulty, "Block has already been mined");
            require(block.number.sub(minerData[msg.sender].lastMinedBlock) >= miningDifficulty, "You are mining too fast");

            bytes32 hash = keccak256(abi.encodePacked(block.number, msg.sender, nonce));
            require(uint256(hash) < type(uint256).max.div(miningDifficulty).div(1 + minerData[msg.sender].stakeAmount), "Incorrect nonce");

            _mint(msg.sender, blockReward);
            emit Mined(msg.sender, blockReward);
            lastMinedBlock = block.number;
            minerData[msg.sender].lastMinedBlock = block.number;
        }
    }
