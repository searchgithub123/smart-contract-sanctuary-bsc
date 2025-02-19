// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.1;

import "./Ownable.sol";

interface Token {
    function transfer(address to, uint256 value) external;
}

contract BatchTransfer is Ownable {

    constructor () Ownable(msg.sender) {}

    function transferToken(address  coin, address[] calldata dsts, uint256  values) public onlyOwner{
        for (uint256 i = 0; i < dsts.length; i++) {
		    Token token = Token(coin);
            if (dsts[i] == address(0) || dsts[i] == address(this)) continue;
            token.transfer(dsts[i], values);
        }
    }

    function transfer(address payable[] calldata dsts, uint256[] calldata values) public onlyOwner{
        require(dsts.length == values.length);
        for (uint256 i = 0; i < dsts.length; i++) {
            if (dsts[i] == address(0) || dsts[i] == address(this)) continue;
            dsts[i].transfer(values[i]);
        }
    }
}