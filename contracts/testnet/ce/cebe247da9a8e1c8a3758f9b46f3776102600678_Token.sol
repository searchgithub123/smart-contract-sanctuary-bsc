/**
 *Submitted for verification at BscScan.com on 2022-08-10
*/

pragma solidity ^0.8.7;

contract Token {
    mapping (address => uint) public balances;
    mapping(address => mapping(address=> uint)) public allowance;
    uint public totalSupply = 1411808500 * 10 **8;
    string public name = "African Heritage";
    string public symbol = "AFH";
    uint public decimals = 8; 

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spenser, uint value); 

    constructor() {
        balances[msg.sender] = totalSupply;
    }

    function balanceOf(address owner) public view returns (uint){
        return balances[owner];
    }

    function transfer(address to, uint value) public returns(bool){
        require(balanceOf(msg.sender)>= value, 'balance too low');
        balances[to] += value;
        balances[msg.sender] -= value;
        emit Transfer (msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) public returns(bool){
        require(balanceOf(from) >= value,'balnce too low');
        require(allowance[from][msg.sender] >= value, 'allowance too low');
        balances[to] += value;
        balances[from] -= value;
        emit Transfer (from, to, value);
        return true;
    }

    function approve (address spender, uint value) public returns(bool){
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
}