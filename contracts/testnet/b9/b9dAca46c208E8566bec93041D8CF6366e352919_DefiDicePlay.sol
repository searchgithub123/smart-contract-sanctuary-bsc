// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

contract DefiDicePlay {
    struct Boardplay {
        uint256 coins;
        uint256 money;
        uint256 money2;
        uint256 yield;
        uint256 timestamp;
        uint256 hrs;
        address ref;
        uint256 refs;
        uint256 refDeps;
        uint8[4] dice;
    }

    mapping(address => Boardplay) public boardplays;
    uint256 public totalDice;
    uint256 public totalBoardplay;
    uint256 public totalInvested;
    address public manager = msg.sender;

    function addCoins(address ref) external payable {
        uint256 coins = msg.value / 4e14; 
        require(coins > 0, "Zero coins");
        address user = msg.sender;
        totalInvested += msg.value;
        if (boardplays[user].timestamp == 0) {
            totalBoardplay++;
            ref = boardplays[ref].timestamp == 0 ? manager : ref;
            boardplays[ref].refs++;
            boardplays[user].ref = ref;
            boardplays[user].timestamp = block.timestamp;
        }
        ref = boardplays[user].ref;
        boardplays[ref].coins += (coins * 7) / 100;
        boardplays[ref].money += (coins * 100 * 3) / 100;
        boardplays[ref].refDeps += coins;
        boardplays[user].coins += coins;
        payable(manager).transfer((msg.value * 4) / 100);
    }

    function withdrawMoney() external {
        address user = msg.sender;
        uint256 money = boardplays[user].money;
        boardplays[user].money = 0;
        uint256 amount = money * 4e12;
        payable(user).transfer(address(this).balance < amount ? address(this).balance : amount);
    }

    function collectMoney() public {
        address user = msg.sender;
        syncBoardplay(user);
        boardplays[user].hrs = 0;
        boardplays[user].money += boardplays[user].money2;
        boardplays[user].money2 = 0;
    }

    function upgradeBoardplay(uint256 playerId) external {
        require(playerId < 4, "Max 4 players");
        address user = msg.sender;
        syncBoardplay(user);
        boardplays[user].dice[playerId]++;
        totalDice++;
        uint256 dice = boardplays[user].dice[playerId];
        boardplays[user].coins -= getUpgradePrice(playerId, dice);
        boardplays[user].yield += getYield(playerId, dice);
    }

     function sellBoardplay() external {
        collectMoney();
        address user = msg.sender;
        uint8[4] memory dice = boardplays[user].dice;
        totalDice -= dice[0] + dice[1] + dice[2] + dice[3];
        boardplays[user].money += boardplays[user].yield * 24 * 8;
        boardplays[user].dice = [0, 0, 0, 0];
        boardplays[user].yield = 0;
    }

    function getDice(address addr) external view returns (uint8[4] memory) {
        return boardplays[addr].dice;
    }

    function syncBoardplay(address user) internal {
        require(boardplays[user].timestamp > 0, "User is not registered");
        if (boardplays[user].yield > 0) {
            uint256 hrs = block.timestamp / 3600 - boardplays[user].timestamp / 3600;
            if (hrs + boardplays[user].hrs > 24) {
                hrs = 24 - boardplays[user].hrs;
            }
            boardplays[user].money2 += hrs * boardplays[user].yield;
            boardplays[user].hrs += hrs;
        }
        boardplays[user].timestamp = block.timestamp;
    }

    function getUpgradePrice(uint256 boardplayId, uint256 diceId) internal pure returns (uint256) {
        if (diceId == 1) return [50, 109, 167, 224][boardplayId];
        if (diceId == 2) return [250, 379, 506, 628][boardplayId];
        if (diceId == 3) return [625, 1000, 1375, 1750][boardplayId];
        if (diceId == 4) return [1875, 3000, 4125, 5250][boardplayId];
        if (diceId == 5) return [5000, 8375, 11750, 15125][boardplayId];
        revert("Incorrect diceId");
    }

    function getYield(uint256 boardplayId, uint256 diceId) internal pure returns (uint256) {
        if (diceId == 1) return [5, 11, 17, 23][boardplayId];
        if (diceId == 2) return [26, 40, 54, 68][boardplayId];
        if (diceId == 3) return [68, 111, 155, 201][boardplayId];
        if (diceId == 4) return [218, 358, 504, 658][boardplayId];
        if (diceId == 5) return [630, 1086, 1567, 2080][boardplayId];
        revert("Incorrect diceId");
    }
}