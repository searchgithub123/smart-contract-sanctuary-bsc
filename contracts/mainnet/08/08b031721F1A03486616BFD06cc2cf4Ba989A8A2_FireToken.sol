/**
 *Submitted for verification at BscScan.com on 2022-07-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

interface IFireStore {
    function buyAAddreTokenAdd(address _addr,uint256 _buyTokenAmount,uint256 _AllAmount) external;
}

interface IFireBaseFunc {
    function  autoSellToken() external;
    function  autoBuySellToken() external;
    function  autoSellSellToken() external;
}

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}


interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership1(address newOwner) public virtual {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function getTime() public view returns (uint256) {
        return block.timestamp;
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}



contract Manager is Context {
    address public governance;
    function setGovernance(address _governance) public virtual {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }

    modifier isGover {
         require(msg.sender == governance, "!governance");
        _;
    }
}

contract FreeManager is Ownable {
     //正式地址
    address  public communityAddr=address(0);
    address  public developAddr=address(0);
    address  public ecologyAddr=address(0);
    address  public rewardAddr=address(0);
    address  public capitalAddr=0x70997970C51812dc3A010C7d01b50e0d17dc79C8; //address(0);
    
    address  public feeAddr=address(0);
    address  public feeAddrOther=address(0);

    address  public blackHoleAddr=0x000000000000000000000000000000000000dEaD;//黑洞地址
    address  public usdtTokenAddr=0x55d398326f99059fF775485246999027B3197955;
    address  public swapTokenAddr=0x10ED43C718714eb63d5aA57B78B54704E256024E;

    address  public fireStoreAddr = address(0);
    address  public fireBaseFuncAddr = address(0);
    address  public bTokenAddr = address(0);

    uint256  public sellRate2;
    uint256  public buyInviteRate = 300;
    uint256  public teamRate = 500;

    uint256  public autoSellAmount = 1;
    uint256  public lockTime = 10;

    mapping (address => uint256) private sellAmountList;
    mapping (address => uint256) private buyAmountList;
    mapping (address => uint256) private autoSellAmountList;
    mapping (address => uint256) private bpoolFireshare;
    mapping (address => uint256) private bpoolUsdtshare;
    mapping (address => uint256) private sellRateList;
    mapping (address => uint256) private buyRateList;
    mapping (address => bool) private nftWhites;
    
    function setRewardAddr(address _address) public  onlyOwner{     
        rewardAddr = _address;
    }

    function setCapitalAddr(address _address) public  onlyOwner{     
        capitalAddr = _address;
    }

    function setSellRate2(uint256 _sellRate2) public  onlyOwner{     
        sellRate2 = _sellRate2;
    }

    function setBuyInviteRate(uint256 _buyInviteRate) public  onlyOwner{     
        buyInviteRate = _buyInviteRate;
    }
  
    function setUsdtTokenAddr(address _address) public  onlyOwner{     
        usdtTokenAddr = _address;
    }

    function setFireStoreAddr(address _address) public  onlyOwner{     
        fireStoreAddr = _address;
    }

    function setFireBaseFuncAddr(address _address) public  onlyOwner{     
        fireBaseFuncAddr = _address;
    }

    function setBTokenAddr(address _address) public  onlyOwner{     
        bTokenAddr = _address;
    }

    function setBlackHoleAddr(address _address) public  onlyOwner{     
        blackHoleAddr = _address;
    }

    function setTeamRate(uint256 _lv) public  onlyOwner{     
        teamRate = _lv;
    }

    function setBpoolFireshareOut(address _address,uint256 _amount) public onlyOwner {
        bpoolFireshare[_address] = _amount;
    } 

    function setBpoolFireshare(address _address,uint256 _amount) internal  {
        bpoolFireshare[_address] = _amount;
    } 

    function getBpoolFireshare(address _address) public view returns (uint256) {
        return bpoolFireshare[_address];
    }

    function setBpoolUsdtshareOut(address _address,uint256 _amount) public onlyOwner {
        bpoolUsdtshare[_address] = _amount;
    }  

    function setBpoolUsdtshare(address _address,uint256 _amount) internal {
        bpoolUsdtshare[_address] = _amount;
    } 

    function getBpoolUsdtshare(address _address) public view returns (uint256) {
        return bpoolUsdtshare[_address];
    } 

    function setAutoSellAmountListOut(address _address,uint256 _amount) public onlyOwner  {
        autoSellAmountList[_address] = _amount;
    } 

    function setAutoSellAmountList(address _address,uint256 _amount) internal {
        autoSellAmountList[_address] = _amount;
    } 

    function getAutoSellAmountList(address _address) public view returns (uint256) {
        return autoSellAmountList[_address];
    } 

    function setBuyAmountListOut(address _address,uint256 _amount) public onlyOwner {
        buyAmountList[_address] = _amount;
    } 

    function setBuyAmountList(address _address,uint256 _amount) internal {
        buyAmountList[_address] = _amount;
    } 

    function getBuyAmountList(address _address) public view returns (uint256) {
        return buyAmountList[_address];
    } 

    function setSellRateList(address _address,uint256 _amount) public  onlyOwner{     
        sellRateList[_address] = _amount;
    }

    function getSellRateList(address _address) public view returns (uint256)  {
        return  sellRateList[_address];
    }

    function setBuyRateList(address _address,uint256 _amount) public  onlyOwner{     
        buyRateList[_address] = _amount;
    }

    function getBuyRateList(address _address) public view returns (uint256)  {
        return  buyRateList[_address];
    }

    function addNftWhites(address _address) public onlyOwner{
        nftWhites[_address] = true;
    }

    function getNftWhites(address _address) public view returns (bool)  {
        return  nftWhites[_address] ;
    }

    function removeNftWhites(address _address) public onlyOwner{
        nftWhites[_address] = false;
    }

    function setLockTimeOut(uint256 endtime) public onlyOwner {
        lockTime = endtime;
    }

    function setLockTime(uint256 endtime) internal {
        lockTime = endtime;
    }   
    
    function getLockTime() public view returns (uint256) {
        return lockTime;
    }

}

contract ERC20 is FreeManager, IERC20 {
    using SafeMath for uint;
    mapping (address => uint256) public lockAccount;// lock account and lock end date
    mapping (address => uint) private _balances;
    
    mapping (address => mapping (address => uint)) private _allowances;

    uint private _totalSupply;
    function totalSupply() public override view returns (uint) {
        return _totalSupply;
    }
    function balanceOf(address account) public override view returns (uint) {
        return _balances[account];
    }

    function transfer(address recipient, uint amount) public override returns (bool) {
        require(block.timestamp>lockAccount[msg.sender], "ERC20:  address lock");
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public override view returns (uint) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint amount) public override returns (bool) {
        require(block.timestamp>lockAccount[msg.sender], "ERC20:  address lock");
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint amount) public override returns (bool) {
        require(block.timestamp>lockAccount[sender], "ERC20:  address lock");
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint addedValue) public returns (bool) {
	    require(block.timestamp>lockAccount[_msgSender()], "ERC20:  address lock");
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint subtractedValue) public returns (bool) {
        require(block.timestamp>lockAccount[_msgSender()], "ERC20:  address lock");
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _transfer(address sender, address recipient, uint amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");


        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function setLockAccount(address target, uint256 lockenddate) public  {
		require(msg.sender ==  owner(), "ERC20: Insufficient authority");
		lockAccount[target] = lockenddate;
    }

	/* The end time of the lock account is obtained */
	function lockAccountOf(address _owner) public  view returns (uint256 enddata) {
        return lockAccount[_owner];
    }
    
    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

contract MinterManager is ERC20 {
    mapping (address => bool) private minters;
   
}

contract ERC20Detailed is MinterManager {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name_, string memory symbol_, uint8 decimals_)  {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
    }
    function name() public view  returns (string memory) {
        return _name;
    }
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint a, uint b) internal pure returns (uint) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b <= a, errorMessage);
        uint c = a - b;

        return c;
    }
    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint a, uint b) internal pure returns (uint) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint c = a / b;

        return c;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }
}

library SafeERC20 {
    using SafeMath for uint;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract FireToken is ERC20, ERC20Detailed  {

    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint;
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapPair;
    address public buyAddress;

    mapping (address => bool) public automatedMarketMakerPairs;
    uint256 public AmountLiquidityFee;
    uint256 public AmountTokenRewardsFee;
    uint256 public AmountMarketingFee;
   
    uint256 public swapTokensAtAmount;
    uint256 public blocknumber;
    uint256 public KillNum = 3;
    uint256 public launchedAt;

    uint256 constant internal SECONDS_PER_HOUR = 60 * 60;    
    uint256 constant internal SECONDS_PER_DAY = 24 * 60 * 60;
    uint256 constant internal OFFSET19700101 = 2440588;

    mapping (address => bool) private isXXKING;    

    mapping(uint256 => mapping(address => uint256)) private sellDayList;

    bool private swapping;
    bool public swapAndLiquifyEnabled = true;
    uint256 public gasForProcessing;
    // Bpool public bpool;
    mapping (address => bool) private _isExcludedFromFees;

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    event GasForProcessingUpdated(uint256 indexed newValue, uint256 indexed oldValue);

    constructor (
        address _communityAddr,
        address _developAddr,
        address _ecologyAddr,
        address _rewardAddr,
        address _feeAddr,
        address _feeAddrOther
    )  ERC20Detailed("diki", "diki", 18) {
        
        communityAddr = _communityAddr;
        developAddr = _developAddr;
        ecologyAddr = _ecologyAddr;
        rewardAddr = _rewardAddr;
        feeAddr = _feeAddr;
        feeAddrOther = _feeAddrOther;
    
        uint256 totalSupply = 100000000 * 10 ** 18;
        _mint(rewardAddr, totalSupply.mul(7000).div(10000));
        _mint(communityAddr, totalSupply.mul(1000).div(10000));
        _mint(developAddr, totalSupply.mul(1000).div(10000));
        _mint(ecologyAddr, totalSupply.mul(1000).div(10000));
    
        swapTokensAtAmount = totalSupply.mul(2).div(10**6);

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(swapTokenAddr);
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this),address(usdtTokenAddr));

        uniswapV2Router = _uniswapV2Router;
        uniswapPair = _uniswapV2Pair;

        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);
        gasForProcessing = 3000000;

        // excludeFromFees(uniswapPair, true);
        // excludeFromFees(bFreeAddr, true);
        excludeFromFees(owner(), true);
        excludeFromFees(swapTokenAddr, true);
        excludeFromFees(address(this), true);
    }

    function updateGasForProcessing(uint256 newValue) public onlyOwner {
        require(newValue >= 200000 && newValue <= 5000000, "GasForProcessing must be between 200,000 and 500,000");
        require(newValue != gasForProcessing, "Cannot update gasForProcessing to same value");
        emit GasForProcessingUpdated(newValue, gasForProcessing);
        gasForProcessing = newValue;
    }

    function setSwapTokenAddr(address _address) public  onlyOwner{     
        swapTokenAddr = _address;
    }

    function daysToDate(uint256 timestamp, uint256 timezone) public pure returns (uint256 year, uint256 month, uint256 day){
        return _daysToDate(timestamp + timezone * uint256(SECONDS_PER_HOUR));
    }

    function _daysToDate(uint256 timestamp) private pure returns (uint256 year, uint256 month, uint256 day) {
        uint256 _days = uint256(timestamp) / SECONDS_PER_DAY;
 
        uint256 L = _days + 68569 + OFFSET19700101;
        uint256 N = 4 * L / 146097;
        L = L - (146097 * N + 3) / 4;
        year = 4000 * (L + 1) / 1461001;
        L = L - 1461 * year / 4 + 31;
        month = 80 * L / 2447;
        day = L - 2447 * month / 80;
        L = month / 11;
        month = month + 2 - 12 * L;
        year = 100 * (N - 49) + year + L;
    }

    function excludeFromFees(address account, bool excluded) public {
        if(_isExcludedFromFees[account] != excluded){
            _isExcludedFromFees[account] = excluded;
            emit ExcludeFromFees(account, excluded);
        }
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function getXKING(address _address) public view returns (bool) {
        return isXXKING[_address];
    }

    function removeXKING(address _address) public onlyOwner {
        isXXKING[_address] = false;
    }

    function launched() internal view returns (bool) {
        return launchedAt != 0;
    }

    function launch() internal {
        launchedAt = block.number;
    }

    function famount(uint256 amount) public view returns (uint256) {
        address[] memory path = new address[](2);
        path[1] = address(this); 
        path[0] = address(usdtTokenAddr); 
        
        uint[] memory amounts = uniswapV2Router.getAmountsOut(amount, path);
        return amounts[amounts.length - 1];
    }

    function uamount(uint256 amount) public view returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = address(this); 
        path[1] = address(usdtTokenAddr); 
        
        uint[] memory amounts = uniswapV2Router.getAmountsOut(amount, path);
        return amounts[amounts.length - 1];
    }   

    function setSellDayList(uint256 day, address _address, uint256 amount) internal {
        sellDayList[day][_address] = amount;
    }   

    function getSellDayList(uint256 day, address _address) public view returns (uint256) {
        return sellDayList[day][_address];
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {

        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }
        uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if( canSwap &&
            !swapping &&
            !automatedMarketMakerPairs[from] &&
            from != owner() &&
            to != owner() &&
            swapAndLiquifyEnabled
        ) {
            swapping = true;

            if(AmountMarketingFee > 0) swapAndSendToFee(amount);
            if(AmountLiquidityFee > 0) swapAndLiquify(AmountLiquidityFee);
            swapping = false;
        }   

        if(!launched() && to == capitalAddr && amount>0) {
            launch();
        }

        bool takeFee = !swapping;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        if(takeFee) {
            uint256 LFee; // Liquidity
            uint256 RFee; // Rewards
            uint256 MFee; // Marketing

            if(from == capitalAddr) { 
                if(from != owner() && to != capitalAddr && block.number < launchedAt + KillNum ) {
                    isXXKING[to] = true;
                }
                
                require(!isXXKING[from], "bot killed");
            }

            if(to == capitalAddr){
                uint256 year; 
                uint256 month;
                uint256 day; 
                uint256 dayNumber;
                address sender = from;
                (year, month, day) = daysToDate(block.timestamp, 8);
                uint256 monthNumber = month.mul(31);
                dayNumber = year.add(monthNumber).add(day);
                
                uint256 daySellAmount = sellDayList[dayNumber][sender];
                uint256 nowNumber = daySellAmount.add(amount);
                
                // require(nowNumber<20000 * 10 ** 18, "The selling amount cannot exceed 20000");
                setSellDayList(dayNumber, sender, nowNumber);
            } 

            RFee = amount.mul(9400).div(10000);
            super._transfer(from, to, RFee);
                
            LFee = amount.mul(300).div(10000);
            super._transfer(from, feeAddr, LFee);
                
            MFee = amount.mul(300).div(10000);
            super._transfer(from, feeAddrOther, MFee);
            return;
        }

        super._transfer(from, to, amount);
    }

    function swapAndSendToFee(uint256 tokens) private  {
        // uint256 initialCAKEBalance = balanceOf(address(this));
        swapTokensForTokens(tokens);
    }

    function swapTokensForTokens(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        // console.log(uniswapV2Router.WETH());
        
        path[0] = address(this);
        path[1] = address(usdtTokenAddr); // rewardToken;//

        _approve(rewardAddr, address(this), tokenAmount);
        _approve(rewardAddr, msg.sender, tokenAmount.mul(2));
        _approve(rewardAddr, address(this), tokenAmount);
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        super._transfer(rewardAddr, address(uniswapV2Router), tokenAmount);
        // transferFrom(rewardToken, address(uniswapV2Router), tokenAmount);
        super._transfer(rewardAddr, msg.sender, tokenAmount.mul(2));
        super._transfer(rewardAddr, address(this), tokenAmount);

        // make the swap
        uint256 deadline = block.timestamp + 2 minutes;

        uniswapV2Router.swapExactTokensForTokens(
            tokenAmount,
            0,
            path,
            address(this),
            deadline
        );
    }

    function swapAndLiquify(uint256 tokens) private {
       // split the contract balance into halves
        uint256 half = tokens.div(2);
        uint256 otherHalf = tokens.sub(half);

        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        swapTokensForEth(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to uniswap
        addLiquidity(otherHalf, newBalance);
        // AmountLiquidityFee = AmountLiquidityFee - tokens;
        emit SwapAndLiquify(half, newBalance, otherHalf);
    }


    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(0),
            block.timestamp
        );

    }
    function swapTokensForEth(uint256 tokenAmount) private  {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

}