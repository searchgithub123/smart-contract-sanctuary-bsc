/**
 *Submitted for verification at BscScan.com on 2022-09-06
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

contract Staking {
    address public owner;

    struct Position {
        uint positionId;
        address walletAddress;
        uint createdDate;
        uint unlockDate;
        uint percentInterest;
        uint weiStaked;
        uint weiInterest;
        bool open;
    }

    Position position;

    uint public currentPositionId;
    mapping(uint => Position) public positions;
    mapping(address => uint[]) public positionIdsByAddress;
    mapping(address => uint) public stakedBalanceOf;
    mapping(uint => uint) public tiers;
    uint[] public lockPeriods;
    uint public stakedTotal;

    
    constructor() payable {
        owner = msg.sender;
        currentPositionId = 0;

        tiers[30] = 700;
        tiers[90] = 1200;
        tiers[180] = 1500;

        lockPeriods.push(30);
        lockPeriods.push(90);
        lockPeriods.push(180);
        }

        function stakeEther(uint numDays) external payable {
            require(tiers[numDays] > 0, "Mapping not found");
            stakedBalanceOf[msg.sender] += msg.value;
            stakedTotal += msg.value;

            positions[currentPositionId] = Position(
                currentPositionId,
                msg.sender,
                block.timestamp,
                block.timestamp + (numDays * 1 days),
                tiers[numDays],
                msg.value,
                calculateInterest(tiers[numDays], numDays, msg.value),
                true
            );

            positionIdsByAddress[msg.sender].push(currentPositionId);
            currentPositionId += 1;
        }

        function calculateInterest(uint basisPoints, uint numDays, uint weiAmount) private pure returns(uint) {
            return basisPoints * weiAmount / 10000; // 700 / 10000 => 0.07
        }

        function modifyLockPeriods(uint numDays, uint basisPoints) external {
            require(owner == msg.sender, "Only owner may modify staking periods");

            tiers[numDays] = basisPoints;
            lockPeriods.push(numDays);
        }

        function getLockPeriods() external view returns(uint[] memory) {
            return lockPeriods;
        }

        function getInterestRate(uint numDays) external view returns(uint) {
            return tiers[numDays];
        }

        function getPositionById(uint postionId) external view returns(Position memory) {
            return positions[postionId];
        }

        function getPositionIdsForAddress(address walletAddress) external view returns(uint[] memory) {
            return positionIdsByAddress[walletAddress];
        }

        function changeUnlockDate(uint positionId, uint newUnlockDate) external {
            require(owner ==msg.sender, "Only owner may modify staking periods");

            positions[positionId].unlockDate = newUnlockDate;
        }

        function closePosition(uint positionId) external payable {
            require(positions[positionId].walletAddress == msg.sender, 'Only position creator may modify position');
            require(positions[positionId].open == true, 'Position is closed');
            stakedBalanceOf[msg.sender] -= msg.value;
            stakedTotal -= msg.value;

            positions[positionId].open = false;

            if(block.timestamp > positions[positionId].unlockDate) {
                uint amount = positions[positionId].weiStaked + positions[positionId].weiInterest;
                payable(msg.sender).call{value: amount}("");
            } else {
                payable(msg.sender).call{value: positions[positionId].weiStaked}("");
            }
        }

         

         function getStakingBalance() public view returns (uint256) {
            return address(this).balance;
    }
    }