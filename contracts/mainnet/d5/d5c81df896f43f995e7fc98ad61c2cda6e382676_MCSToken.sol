/**
 *Submitted for verification at BscScan.com on 2022-08-06
*/

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ERC20 is IERC20{

    using SafeMath for uint256;
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply = 0;
    uint256 private _totalBurn = 0;
    uint256 public _initialSupply = 3000000000 * 1000000;
    uint256 public _totalFreeze = 497000000000 * 1000000;
    
    address public totalAddress = address(0x80F7f8D86D60659CB1511fecb494633b72725C6d);
    address public freezeAddress = address(0x72e1D820e7E07e389211B2AB6e50173eaFa4C236);
    address public burnProfitAddress = address(0x80529E2E4777f88a41c35644ADB824d038bC36E5);

    constructor (string memory tokenName, string memory tokenSymbol, uint8 tokenDecimals) {
        _name = tokenName;
        _symbol = tokenSymbol;
        _decimals = tokenDecimals;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    function totalBurn() public view returns (uint256) {
        return _totalBurn;
    }

    function totalFreeze() public view returns (uint256) {
        return getUserFreeze(freezeAddress);
    }

    function balanceOf(address account) public override view returns (uint256) {
        return _balances[account];
    }

    function getUserFreeze(address account) public view returns(uint){
        if(account == freezeAddress){
            uint total = _totalBurn.mul(85).div(100);
            if(_totalFreeze > total){
                return _totalFreeze.sub(total);
            }
        } 
        return 0;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public override view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 value) public override returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0) && spender != address(0));
        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(recipient != address(0));
        require(_balances[sender] >= amount.add(getUserFreeze(sender)), "Insufficient balance...");
        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function burn(uint256 value) public {
        require(_balances[msg.sender] >= value.add(getUserFreeze(msg.sender)), "Insufficient balance...");
        _totalSupply = _totalSupply.sub(value.mul(30).div(100));
        _totalBurn = _totalBurn.add(value.mul(30).div(100));
        _transfer(msg.sender, burnProfitAddress, value.mul(70).div(100));
        _balances[msg.sender] = _balances[msg.sender].sub(value);
    }

    function _mint(address account, uint256 amount) internal returns (bool){
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
        return true;
    }

}

contract MCSToken is ERC20 {
    constructor () 
        ERC20("Meta cosmos", "MCS", 6) {
        _mint(totalAddress, _initialSupply);
        _mint(freezeAddress, _totalFreeze);
    }
}