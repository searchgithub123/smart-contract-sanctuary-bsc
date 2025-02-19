/**
 *Submitted for verification at BscScan.com on 2023-01-06
*/

/**
 *Submitted for verification at BscScan.com on 2022-05-10
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

contract Lotteryfee {
    address public owner;
    address payable[] public players;
    uint public lotteryId;
    mapping (uint => address payable) public lotteryHistory;
    address payable owner2;

    constructor() {
        owner = msg.sender;
        lotteryId = 1;
        
        
    }
function setOwner2(address payable newOwner2) public onlyowner {
    owner2 = newOwner2;
}

    function getWinnerByLottery(uint lottery) public view returns (address payable) {
        return lotteryHistory[lottery];
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function getPlayers() public view returns (address payable[] memory) {
        return players;
    }

    function enter() public payable {
        require(msg.value > .01 ether);

        // address of player entering lottery
        players.push(payable(msg.sender));
    }

    function getRandomNumber() public view returns (uint) {
        return uint(keccak256(abi.encodePacked(owner, block.timestamp)));
    }
function pickWinner() public onlyowner {
    uint index = getRandomNumber() % players.length;
 
 players[index].transfer((address(this).balance / 20) * 19);
    owner2.transfer(address(this).balance / 10);


    lotteryHistory[lotteryId] = players[index];
    lotteryId++;

    // reset the state of the contract
    players = new address payable[](0);
}



    modifier onlyowner() {
      require(msg.sender == owner);
      _;
    }
}