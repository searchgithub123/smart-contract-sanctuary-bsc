pragma solidity ^0.5.4;

import './IPancakeRouter.sol';
import './SafeMath.sol';
import './IERC20.sol';
import './IPancakeFactory.sol';


contract ERC20 is IERC20 {
    using SafeMath for uint256;
    mapping (address => uint256) public _balances;
    mapping (address => mapping (address => uint256)) public _allowed;
    uint256 public _totalSupply;

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

    function allowance(address owner,address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }

    function approve(address spender, uint256 value) public returns (bool) {
        require(spender != address(0));
        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function increaseAllowance(address spender,uint256 addedValue) public returns (bool) {
        require(spender != address(0));
        _allowed[msg.sender][spender] = (_allowed[msg.sender][spender].add(addedValue));
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(address spender,uint256 subtractedValue) public returns (bool) {
        require(spender != address(0));
        _allowed[msg.sender][spender] = (_allowed[msg.sender][spender].sub(subtractedValue));
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));
        require(value <= _balances[from]);
        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }
}

contract Context {
    constructor () internal { }

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view  returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    
}


contract TokenTemplate is ERC20,Ownable {
    string  private _name = "AMX";
    string  private _symbol = "AMX";
    uint8   private _decimals = 18;
    address public pancakeToken = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address public usdtToken = 0x55d398326f99059fF775485246999027B3197955;
    address public pancakePair;

    uint256 public MAX_STOP_FEE_TOTAL = 1686 * 10 ** uint256(_decimals);

    

    address public XHtoken;  //销毁token

    mapping (address => bool) private _blackList;
    mapping (address => bool) private _whiteList;


    constructor (uint256 _initialAmount) public {
        _totalSupply = _initialAmount.mul(10 ** uint256(_decimals));
        _balances[msg.sender] = _initialAmount.mul(10 ** uint256(_decimals));
        IPancakeRouter router =  IPancakeRouter(pancakeToken);
        pancakePair =  IPancakeFactory(router.factory()).createPair(address(this), usdtToken);
    }
    
    function setXHtoken(address account) public onlyOwner returns (bool) {
        XHtoken = account;
        return true;
    }
    function setBlack(address account, bool state) public onlyOwner returns (bool) {
        _blackList[account] = state;
        return true;
    }
    function isBlack(address account) public view returns (bool) {
        return _blackList[account];
    }
    function setwhite(address account, bool state) public onlyOwner returns (bool) {
        _whiteList[account] = state;
        return true;
    }
    function iswhite(address account) public view returns (bool) {
        return _whiteList[account];
    }
    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(value <= _allowed[from][msg.sender]);
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        _transfer(from, to, value);
        return true;
    }

     function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));
        require(value <= _balances[from]);

        uint256 fee = value.mul(1).div(100);
        if(_totalSupply > MAX_STOP_FEE_TOTAL){
            if (from == pancakePair) {
                _balances[from] = _balances[from].sub(value);
                _balances[to] = _balances[to].add(value.sub(fee));
                _burn(from, fee);
                emit Transfer(from, to, value.sub(fee));
            } else if(to == pancakePair) {
                _balances[from] = _balances[from].sub(value);
                _balances[to] = _balances[to].add(value.sub(fee));
                _burn(from, fee);
                emit Transfer(from, to, value.sub(fee));
            }else {
                _balances[from] = _balances[from].sub(value);
                _balances[to] = _balances[to].add(value);
                emit Transfer(from, to, value);
            }
        }else{
            _balances[from] = _balances[from].sub(value);
            _balances[to] = _balances[to].add(value);
            emit Transfer(from, to, value);
        }

    }
    function _burn(address account, uint256 amount) internal {
        require(account != address(0));
        // _balances[account] = _balances[account].sub(amount);
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
        require(account != address(0));
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

}