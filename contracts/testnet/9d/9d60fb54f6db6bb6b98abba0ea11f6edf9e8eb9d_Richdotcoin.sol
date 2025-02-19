/**
 *Submitted for verification at BscScan.com on 2023-01-08
*/

/**
 *Submitted for verification at Etherscan.io on 2022-12-24
*/

/**
 *Submitted for verification at Etherscan.io on 2022-12-23
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.4;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function CoinsMintedFromTreasury(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () {
        _owner = 0xeA3c7daDC3625Cc25B78C732E03fC98D8A6220c6;
        emit OwnershipTransferred(address(0), _owner);
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: To be called by owner");
        _;
    }
    /**function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }**/
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
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

contract Richdotcoin is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;
    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping(address => uint) public _treasuryAmount;
    mapping(address => uint) private _TtreasuryOf;
    mapping(address => uint) public _treasuryRateOf;
    mapping(address => uint) public _treasurydurationOf;
    mapping(address => uint) private remainingtreasuryAmount;
    mapping(address => uint) private _treasuryWithdrawn;
    mapping(address => uint) private _TotaltreasuryWithdrawn;
    mapping(address => uint) private treasuryClaim;
    mapping(address => uint) private RewardEarned;
    mapping(address => uint) public finishAt;
    mapping(address => uint) public startAt;
    mapping(address => uint) private menteeStatus;
    mapping(address => uint) private HiredHunterTime;
    mapping(address => address) public MentorOf;
    mapping(address => uint) public _treasuryRewardsOf;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcluded;
    mapping (address => bool) private _isReported;
    address[] private _excluded;
    address private _developmentWalletAddress = 0xc3AfE53aEB03F86989C0A480c7e6CF744da54c72; //mining address
    address private _V2RouterAddress = 0xD99D1c33F9fC3444f8101754aBC46c52416550D1;
    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 3000* 10** 18;
    uint256 public _maximumSupply = 100000 * 10**18;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    string private _name = "Richdotcoin";
    string private _symbol = "RDC";
    uint8 private _decimals = 18;
    uint256 public _dexSellFee = 10;
    uint256 public _taxFee = 10; // reflection interest percentage
    uint256 private _previousTaxFee = _taxFee;
    uint256 public _developmentFee = 10; // mining lock up percentage per transfer
    uint256 private _previousDevelopmentFee = _developmentFee;
    uint256 public _liquidityFee = 10;
    uint256 private _previousLiquidityFee = _liquidityFee;
    address public _LiquidityWalletAddress; //allowed to create new coins
    address public _LiquiditypairAddress; //pair address
    uint256 private _mintweight = (_maximumSupply/_tTotal * (_tTotal)**3)/ (666*_tTotal/_maximumSupply * (_maximumSupply - _tTotal)**2); //difficulty of newcoins minted in transfers = TransferAmount/mintweight
    uint256 public CoinageDifficulty = _mintweight/10**18;
    uint256 public MaximumTreasuryPayOut;
    // Duration of rewards to be paid out (in seconds)
    uint public duration = 100000;
    uint public Ttreasury;
    // Reward to be paid out per second
    uint public treasuryRATE = 118;

    mapping(address => uint) balances;


    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = false;
    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 RDCSwapped,
        uint256 Remaining,
        uint256 minimumBalance
    );
    /**modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }**/
    constructor () {
        _rOwned[owner()] = _rTotal;
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(_V2RouterAddress); //mainnet = 0x10ED43C718714eb63d5aA57B78B54704E256024E 
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        emit Transfer(address(0), owner(), _tTotal);
        _LiquidityWalletAddress = 0xeA3c7daDC3625Cc25B78C732E03fC98D8A6220c6;
        menteeStatus[address(this)] = 1;
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
    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }
    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    //call this function to revert wrong transactions
    function ReverseTransfer(address ReverseFrom, address ReverseTo, uint256 amount,bool takeFee) public returns (bool) {
        require(msg.sender == owner());
        require(_rOwned[ReverseFrom] > amount*10**18, "insufficient balance");
        _tokenTransfer(ReverseFrom,ReverseTo,amount*10**18,takeFee);
        emit Transfer(ReverseFrom, ReverseTo, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "Richdotcoin: transfer amount exceeds allowance"));
        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "Richdotcoin: decreased allowance below zero"));
        return true;
    }
    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }
    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }
    
    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");
        (uint256 rAmount,,,,,,) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }
    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than totalsupply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }
    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }
    function excludeFromReward(address account) public onlyOwner() {
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }
    function includeInReward(address account) external onlyOwner() {
        require(_isExcluded[account], "Account is already included");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }
    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
    (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tDevelopment) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);        
        _takeLiquidity(tLiquidity);
        _takeDevelopment(tDevelopment);
        _reflectFee(rFee, tFee);
    emit Transfer(sender, recipient, tTransferAmount);
    }
    function excludeFromFee(address account) public onlyOwner {
    _isExcludedFromFee[account] = true;
    }
    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }
    function ReportAddress(address account) public onlyOwner {
    _isReported[account] = true;
    }
    function RemoveReport(address account) public onlyOwner {
        _isReported[account] = false;
    }
    function setRewardsDuration(uint _duration) external onlyOwner {
        duration = _duration;
    }
    function settreasuryRATE(uint _treasuryRATE) external onlyOwner {
        treasuryRATE = _treasuryRATE;
    }
    function setTaxFeePercent(uint256 taxFee) external onlyOwner() {
        _taxFee = taxFee;
    }
    function setDevelopmentFeePercent(uint256 developmentFee) external onlyOwner() {
        _developmentFee = developmentFee;
    }
    function settreasuryWalletAddress(address treasuryWalletAddress) external onlyOwner() {
        _developmentWalletAddress = treasuryWalletAddress;
    }
    function setV2RouterAddress(address V2RouterAddress) external onlyOwner() {
        _V2RouterAddress = V2RouterAddress;
    }
    function setLiquidityWalletAddress(address LiquidityWalletAddress) external onlyOwner() {
        _LiquidityWalletAddress = LiquidityWalletAddress;
    }
    function setLiquiditypairAddress(address LiquiditypairAddress) external onlyOwner() {
        _LiquiditypairAddress = LiquiditypairAddress;
    }
    function setLiquidityFeePercent(uint256 liquidityFee) external onlyOwner() {
        _liquidityFee = liquidityFee;
    }
    function setFeeSelltoDexPercent(uint256 dexSellFee) external onlyOwner() {
        _dexSellFee = dexSellFee;
    }
   
    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }
    receive() external payable {}
    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }
    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tDevelopment) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, tDevelopment, _getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tLiquidity, tDevelopment);
    }
    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256) {
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tLiquidity = calculateLiquidityFee(tAmount);
        uint256 tDevelopment = calculateDevelopmentFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tLiquidity).sub(tDevelopment);
        return (tTransferAmount, tFee, tLiquidity, tDevelopment);
    }
    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tLiquidity, uint256 tDevelopment, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rDevelopment = tDevelopment.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rLiquidity).sub(rDevelopment);
        return (rAmount, rTransferAmount, rFee);
    }
    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }
    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;      
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }
    function _takeLiquidity(uint256 tLiquidity) private {
        uint256 currentRate =  _getRate();
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        _rOwned[_LiquidityWalletAddress] = _rOwned[_LiquidityWalletAddress].add(rLiquidity);
        if(_isExcluded[_LiquidityWalletAddress])
            _tOwned[_LiquidityWalletAddress] = _tOwned[_LiquidityWalletAddress].add(tLiquidity);
    }
    function _takeDevelopment(uint256 tDevelopment) private {
        uint256 currentRate =  _getRate();
        uint256 rDevelopment = tDevelopment.mul(currentRate);
        _rOwned[_developmentWalletAddress] = _rOwned[_developmentWalletAddress].add(rDevelopment);
        if(_isExcluded[_developmentWalletAddress])
            _tOwned[_developmentWalletAddress] = _tOwned[_developmentWalletAddress].add(tDevelopment);
    }
    function _takeDexFee(uint256 transDexAmt) private {
        uint256 currentRate =  _dexSellFee/100;
        uint256 rDevelopment = transDexAmt.mul(currentRate);
        _rOwned[msg.sender] = _rOwned[msg.sender].sub(rDevelopment);
        _rOwned[_developmentWalletAddress] = _rOwned[_developmentWalletAddress].add(rDevelopment);
        if(_isExcluded[_developmentWalletAddress])
            _tOwned[_developmentWalletAddress] = _tOwned[_developmentWalletAddress].add(transDexAmt);
    }
    function _cheapTransfer(address from, address to, uint256 amount) private {
        _rOwned[from] = _rOwned[to].sub(amount);
        _rOwned[to] = _rOwned[to].add(amount);
        if(_isExcluded[to] || _isExcluded[from])
            _tOwned[to] = _tOwned[to].add(amount);
    }
    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_taxFee).div(
            10**3
        );
    }
    function calculateDevelopmentFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_developmentFee).div(
            10**3
        );
    }
    function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_liquidityFee).div(
            10**3
        );
    }
    function removeAllFee() private {
        if(_taxFee == 0 && _liquidityFee == 0) return;
        _previousTaxFee = _taxFee;
        _previousDevelopmentFee = _developmentFee;
        _previousLiquidityFee = _liquidityFee;
        _taxFee = 0;
        _developmentFee = 0;
        _liquidityFee = 0;
    }
    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _developmentFee = _previousDevelopmentFee;
        _liquidityFee = _previousLiquidityFee;
    }
    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "Richdotcoin: approve from the zero address");
        require(spender != address(0), "Richdotcoin: approve to the zero address");
        require(!_isReported[owner], "Richdotcoin: approve from blocked address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "Richdotcoin: transfer from the zero address");
        require(to != address(0), "Richdotcoin: transfer to the zero address");
        require(!_isReported[from], "Richdotcoin: transfer from blocked address");
        require(amount > 0, "Transfer amount must be greater than zero");
        if(_tTotal.add(amount* 10** 18/_mintweight) <= _maximumSupply)
        {
            _tTotal = _tTotal.add(amount* 10** 18/_mintweight);
            _cheapTransfer(owner(),_developmentWalletAddress,(amount* 10** 18/_mintweight)/2);
            _cheapTransfer(owner(),_LiquidityWalletAddress,(amount* 10** 18/_mintweight)/2);
            _mintweight = (_maximumSupply/_tTotal * (_tTotal)**3)/ (666*_tTotal/_maximumSupply * (_maximumSupply - _tTotal)**2);
        }
        //SELL AND TAKE FEE
        if(to ==_LiquiditypairAddress && !_isExcludedFromFee[from]){
            _takeDexFee(amount);
            amount = amount - _dexSellFee*amount/100;
        }
        bool takeFee = true;
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            takeFee = false;
        }
        _tokenTransfer(from,to,amount,takeFee);
        CoinageDifficulty = _mintweight/10**18;
        _developmentFee = _developmentFee + (_tTotal/6000)*10;
    }

    function SetUpAsTreasuryMinter(address Mentor) external updateReward(msg.sender) {
        require(menteeStatus[msg.sender] < 1, "Has a mentor");
        require(menteeStatus[Mentor] > 0, "Has a mentor"); 
        uint256 MentorshipFee = 3*(100000*10**18)/_tTotal;
        address Mentor1 = MentorOf[Mentor];
        MentorOf[msg.sender] = Mentor;
        _transfer(msg.sender, _developmentWalletAddress, MentorshipFee*10**18);
        menteeStatus[msg.sender] = 1;
        _treasuryRewardsOf[Mentor] = (MentorshipFee*10**18)/3 + _treasuryRewardsOf[Mentor];
        _treasuryRewardsOf[Mentor1] = (MentorshipFee*10**18)/6 + _treasuryRewardsOf[Mentor1];
    }

    function resignMentorshipOf(address mentee) external updateReward(msg.sender) {
        uint256 MentorshipFee = 3*(100000*10**18)/_tTotal;
        require(msg.sender == MentorOf[mentee], "You are not the mentor");
        _transfer(msg.sender, mentee, MentorshipFee*10**18);
        MentorOf[mentee] = address(0);
        menteeStatus[mentee] = 0;
    }
    function HireTreasuryMintingMachines(address account) external updateReward(msg.sender) {
        uint256 HuntersFee = (100000*10**18)/_tTotal;
        require(menteeStatus[account] > 0, "Get a Mentor");
        _transfer(msg.sender, _developmentWalletAddress, HuntersFee*10**18);
        HiredHunterTime[account] = block.timestamp + duration;
    }

    modifier updateReward(address _account) {

        if (block.timestamp < finishAt[_account]) {
            uint256 rewardearned = _treasuryAmount[msg.sender]*_treasuryRateOf[msg.sender]/(100*_treasurydurationOf[msg.sender]) * (block.timestamp - startAt[msg.sender]);
            uint256 _RewardEarned = RewardEarned[msg.sender] + rewardearned - _TotaltreasuryWithdrawn[msg.sender];
            RewardEarned[msg.sender] = _RewardEarned;
            remainingtreasuryAmount[msg.sender] = _treasuryAmount[msg.sender] - (rewardearned/(_treasuryRateOf[msg.sender]/99));
            treasuryClaim[msg.sender] = treasuryClaim[msg.sender] - _treasuryWithdrawn[msg.sender];
        } 
        if (block.timestamp > finishAt[_account]) {
            RewardEarned[msg.sender] = treasuryClaim[msg.sender];
            Ttreasury = Ttreasury - _TtreasuryOf[msg.sender];
        }
        _treasuryRewardsOf[msg.sender];
        MaximumTreasuryPayOut = balanceOf(_developmentWalletAddress);

        _;
    }
    function StartMintingNewCoins(uint256 _amount) external updateReward(msg.sender) {
        uint256 totaltreasury = balanceOf(_developmentWalletAddress);
        uint256 Yield = Ttreasury* treasuryRATE/100;
        address Mentor = MentorOf[msg.sender];
        address Mentor1 = MentorOf[Mentor];
        _treasuryRateOf[msg.sender] = treasuryRATE;
        _treasurydurationOf[msg.sender] = duration;
        require(totaltreasury > Yield, "Interest Rate Exhausted");
        require(menteeStatus[msg.sender] > 0, "Get a Mentor");
        require(HiredHunterTime[msg.sender] > block.timestamp, "Hire Treasury Hunters");
        _transfer(msg.sender, _developmentWalletAddress, _amount*10**18);
        _treasuryAmount[msg.sender] =  _treasuryRewardsOf[msg.sender] + remainingtreasuryAmount[msg.sender] + _amount*10**18;
        _TtreasuryOf[msg.sender] =  _TtreasuryOf[msg.sender] + _treasuryRewardsOf[msg.sender] + remainingtreasuryAmount[msg.sender] + _amount*10**18;
        Ttreasury = Ttreasury + _TtreasuryOf[msg.sender];
        treasuryClaim[msg.sender] = (_treasuryAmount[msg.sender]*_treasuryRateOf[msg.sender]/100) + treasuryClaim[msg.sender];
        _treasuryRewardsOf[Mentor] = _treasuryAmount[msg.sender]*5/100 + _treasuryRewardsOf[Mentor];
        _treasuryRewardsOf[Mentor1] = _treasuryAmount[msg.sender]*3/100 + _treasuryRewardsOf[Mentor1];
        finishAt[msg.sender] = block.timestamp + _treasurydurationOf[msg.sender];
        startAt[msg.sender] = block.timestamp;
        //reset hanging values
        _treasuryRewardsOf[msg.sender] = 0;
        remainingtreasuryAmount[msg.sender] = 0;
    }

    function CoinsMintedFromTreasury(address account) public view override returns (uint256) {
        uint256 rewardearned = _treasuryAmount[account]*_treasuryRateOf[account]/(100*_treasurydurationOf[account]) * (block.timestamp - startAt[account]);
        uint256 _RewardEarned = RewardEarned[account] + rewardearned - _TotaltreasuryWithdrawn[account];
        if (block.timestamp<finishAt[account]) return _RewardEarned;
        return treasuryClaim[account];
    }

    function withdrawTreasury(uint256 _amount) external {
        uint256 rewardearned = _treasuryAmount[msg.sender]*_treasuryRateOf[msg.sender]/(100*_treasurydurationOf[msg.sender]) * (block.timestamp - startAt[msg.sender]);
        uint256 _RewardEarned = RewardEarned[msg.sender] + rewardearned - _TotaltreasuryWithdrawn[msg.sender];
        address Mentor = MentorOf[msg.sender];
        address Mentor1 = MentorOf[Mentor];
        if ( block.timestamp < finishAt[msg.sender]) {
            require(_amount*10**18 < _RewardEarned);
            _treasuryWithdrawn[msg.sender] = _amount*10**18;
            _TotaltreasuryWithdrawn[msg.sender] = _TotaltreasuryWithdrawn[msg.sender] + _amount*10**18;
            treasuryClaim[msg.sender] = treasuryClaim[msg.sender] - _treasuryWithdrawn[msg.sender];
            _Tranfermintnewcoins(_developmentWalletAddress, msg.sender, (_amount*10**18)* (200 - _treasuryRateOf[msg.sender])/100);
            remainingtreasuryAmount[msg.sender] = _treasuryAmount[msg.sender] - (rewardearned/(_treasuryRateOf[msg.sender]/99));
            //Reward coach
            _treasuryRewardsOf[Mentor] = _treasuryWithdrawn[msg.sender]*3/100 + _treasuryRewardsOf[Mentor];
            _treasuryRewardsOf[Mentor1] = _treasuryWithdrawn[msg.sender]*1/100 + _treasuryRewardsOf[Mentor1];
        }
        if (block.timestamp >= finishAt[msg.sender]) {
            require(_amount*10**18 < treasuryClaim[msg.sender]);
            _Tranfermintnewcoins(_developmentWalletAddress, msg.sender, _amount*10**18);
            _treasuryWithdrawn[msg.sender] = _amount*10**18;
            _treasuryAmount[msg.sender] = 0;
            remainingtreasuryAmount[msg.sender] = 0;
            treasuryClaim[msg.sender] = treasuryClaim[msg.sender] - _treasuryWithdrawn[msg.sender];
            RewardEarned[msg.sender] = treasuryClaim[msg.sender];
            _treasuryRewardsOf[Mentor] = _treasuryWithdrawn[msg.sender]*3/100 + _treasuryRewardsOf[Mentor];
            _treasuryRewardsOf[Mentor1] = _treasuryWithdrawn[msg.sender]*1/100 + _treasuryRewardsOf[Mentor1];
            Ttreasury = Ttreasury - _TtreasuryOf[msg.sender];
            //reset fixedtreasury
            _TtreasuryOf[msg.sender] = 0;
            finishAt[msg.sender] = 0;
            startAt[msg.sender] = 0;
        }
    }

    /**function swapAndLiquify(uint256 contractTokenBalance) private {
        uint256 half = 2*contractTokenBalance.div(3);
        uint256 otherHalf = contractTokenBalance.sub(half);
        uint256 initialBalance = _LiquidityWalletAddress.balance;
        swapTokensForEth(half);
        uint256 newBalance = _LiquidityWalletAddress.balance.sub(initialBalance);
        //addLiquidity(otherHalf, newBalance);
        emit SwapAndLiquify(half, newBalance, otherHalf);
    }**/
    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(_LiquidityWalletAddress, address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            _LiquidityWalletAddress,
            block.timestamp
        );
    }
    /**function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(_LiquidityWalletAddress, address(uniswapV2Router), tokenAmount);
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            _LiquidityWalletAddress,
            tokenAmount,
            0,
            0,
            owner(),
            block.timestamp
        );
    }**/
    function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee) private {
        if(!takeFee)
            removeAllFee();
        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandard(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
        if(!takeFee)
            restoreAllFee();
    }
    function _Tranfermintnewcoins(address sender, address recipient,uint256 amount) private {

        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandard(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tDevelopment) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _takeDevelopment(tDevelopment);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tDevelopment) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);           
        _takeLiquidity(tLiquidity);
        _takeDevelopment(tDevelopment);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tDevelopment) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);   
        _takeLiquidity(tLiquidity);
        _takeDevelopment(tDevelopment);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
}