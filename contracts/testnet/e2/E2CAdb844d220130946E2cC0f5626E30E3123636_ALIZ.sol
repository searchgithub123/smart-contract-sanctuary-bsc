/**
 *Submitted for verification at BscScan.com on 2022-04-15
*/

pragma solidity ^0.8.6;

// SPDX-License-Identifier: Unlicensed
interface IERC20 {
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract Ownable {
    address public _owner;

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function changeOwner(address newOwner) public onlyOwner {
        _owner = newOwner;
    }
}

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

library DateTimeLibrary {
    uint256 constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint256 constant SECONDS_PER_HOUR = 60 * 60;
    uint256 constant SECONDS_PER_MINUTE = 60;
    int256 constant OFFSET19700101 = 2440588;

    uint256 constant DOW_MON = 1;
    uint256 constant DOW_TUE = 2;
    uint256 constant DOW_WED = 3;
    uint256 constant DOW_THU = 4;
    uint256 constant DOW_FRI = 5;
    uint256 constant DOW_SAT = 6;
    uint256 constant DOW_SUN = 7;

    function _daysToDate(uint256 _days)
        internal
        pure
        returns (
            uint256 year,
            uint256 month,
            uint256 day
        )
    {
        int256 __days = int256(_days);

        int256 L = __days + 68569 + OFFSET19700101;
        int256 N = (4 * L) / 146097;
        L = L - (146097 * N + 3) / 4;
        int256 _year = (4000 * (L + 1)) / 1461001;
        L = L - (1461 * _year) / 4 + 31;
        int256 _month = (80 * L) / 2447;
        int256 _day = L - (2447 * _month) / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;

        year = uint256(_year);
        month = uint256(_month);
        day = uint256(_day);
    }

    function timestampToDate(uint256 timestamp)
        internal
        pure
        returns (
            uint256 year,
            uint256 month,
            uint256 day
        )
    {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
}

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

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
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

contract ALIZ is IERC20, Ownable {
    using SafeMath for uint256;

    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => uint256) private buyAmount;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isExcludedFromVip;
    mapping(address => bool) private _isblacklist;
    mapping(address => bool) isDividendExempt;
    mapping(address => bool) private _updated;

    uint256 private constant MAX = ~uint256(0);
    uint256 public _tTotal;
    uint256 public _rTotal;
    uint256 public _tFeeTotal;

    uint256 currentIndex;
    uint256 distributorGas = 500000;
    uint256 public minPeriod = 1 hours;
    uint256 public LPFeefenhong;

    string private _name;
    string private _symbol;
    uint256 private _decimals;

    address private _bnbtradeaddress;

    address private _destroyAddress =
        address(0x000000000000000000000000000000000000dEaD);
    address private _default = _owner;

    address[] shareholders;
    mapping(address => uint256) shareholderIndexes;

    address public bliz;
    address public blizUniswapV2Pair;

    mapping(address => address) private inviter;
    mapping(address => address[]) private inviterSuns;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;

    address private fromAddress;
    address private toAddress;

    bool inSwapAndLiquify;
    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor(address tokenOwner) {
        //mainnet
        // IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
        //     0x10ED43C718714eb63d5aA57B78B54704E256024E
        // );

        // // Create a uniswap pair for this new token
        // uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
        //     .createPair(address(this), _uniswapV2Router.WETH());

        // // set the rest of the contract variables
        // uniswapV2Router = _uniswapV2Router;

        // //set a uniswap pair for bnb-usdt
        // _bnbtradeaddress = address(0x55d398326f99059fF775485246999027B3197955);

        //testnet
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3
        );

        // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        // set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;

        //set a uniswap pair for bnb-usdt
        _bnbtradeaddress = address(0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd);

        _name = "ALIZ TOKEN";
        _symbol = "ALIZ";

        _decimals = 8;
        _tTotal = 131000000 * 10**_decimals;

        _rTotal = (MAX - (MAX % _tTotal));
        _rOwned[tokenOwner] = _rTotal;
        _isExcludedFromFee[tokenOwner] = true;
        _isExcludedFromFee[address(this)] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[address(0)] = true;
        _owner = msg.sender;
        emit Transfer(address(0), tokenOwner, _tTotal);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint256) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            msg.sender,
            _allowances[sender][msg.sender].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function tokenFromReflection(uint256 rAmount)
        public
        view
        returns (uint256)
    {
        require(
            rAmount <= _rTotal,
            "Amount must be less than total reflections"
        );
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    function setBlizInfo(address newBliz, address newBlizUniswapV2Pair)
        public
        onlyOwner
    {
        bliz = newBliz;
        blizUniswapV2Pair = newBlizUniswapV2Pair;
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function excludeBlockList(address account) public onlyOwner {
        if (_isExcludedFromFee[account]) _isExcludedFromFee[account] = false;
        _isblacklist[account] = true;
    }

    function includeBlockList(address account) public onlyOwner {
        _isblacklist[account] = false;
    }

    function excludeFromVip(address account) public onlyOwner {
        _isExcludedFromVip[account] = true;
    }

    function includeInVip(address account) public onlyOwner {
        _isExcludedFromVip[account] = false;
    }

    //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function getInviter(address user) public view returns (address) {
        return inviter[user];
    }

    function getInviterSuns(address user)
        public
        view
        returns (address[] memory)
    {
        return inviterSuns[user];
    }

    function getInviterSunSize(address user) public view returns (uint256) {
        return inviterSuns[user].length;
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function claimTokens() public onlyOwner {
        payable(_owner).transfer(address(this).balance);
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function isBlockList(address account) public view returns (bool) {
        return _isblacklist[account];
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(!_isExcludedFromVip[from]);

        // Anti-pinch: get the minimum amount of one usdt
        uint256 minAmount = getExchangeCountOfOneUsdtA(address(this));

        bool canInviter = from != uniswapV2Pair &&
            balanceOf(to) == 0 &&
            inviter[to] == address(0) &&
            amount >= minAmount;

        // Whitelisted users do not need to pay fees
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            _tokenTransfer(from, to, amount, false);
        } else {
            if (from == uniswapV2Pair) {
                // buy
                _tokenTransferBuy(from, to, amount, true);
            } else if (to == uniswapV2Pair && !_isblacklist[from]) {
                // sell
                _tokenTransferSell(from, to, amount, true);
            } else {
                if (!_isblacklist[from]) {
                    // common transfer
                    if (balanceOf(_destroyAddress) <= 13100 * 10**8) {
                        _tokenTransfer(from, to, amount, false);
                    } else {
                        _tokenTransfer(from, to, amount, true);
                    }
                }
            }
        }

        if (canInviter) {
            inviter[to] = from;
            inviterSuns[from].push(to);
        }

        if (fromAddress == address(0)) fromAddress = from;
        if (toAddress == address(0)) toAddress = to;
        if (!isDividendExempt[fromAddress] && fromAddress != uniswapV2Pair)
            setShare(fromAddress);
        if (!isDividendExempt[toAddress] && toAddress != uniswapV2Pair)
            setShare(toAddress);

        fromAddress = from;
        toAddress = to;
        if (
            _tOwned[address(this)] >= 1 * 10**5 * 10**9 &&
            from != address(this) &&
            LPFeefenhong.add(minPeriod) <= block.timestamp
        ) {
            process(distributorGas);
            LPFeefenhong = block.timestamp;
        }
    }

    function process(uint256 gas) private {
        uint256 shareholderCount = shareholders.length;

        if (shareholderCount == 0) return;
        uint256 nowbanance = _tOwned[address(this)];
        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();

        uint256 iterations = 0;

        while (gasUsed < gas && iterations < shareholderCount) {
            if (currentIndex >= shareholderCount) {
                currentIndex = 0;
            }

            uint256 amount = nowbanance
                .mul(
                    IERC20(uniswapV2Pair).balanceOf(shareholders[currentIndex])
                )
                .div(IERC20(uniswapV2Pair).totalSupply());
            if (amount < 1 * 10**9) {
                currentIndex++;
                iterations++;
                return;
            }
            if (_tOwned[address(this)] < amount) return;
            distributeDividend(shareholders[currentIndex], amount);

            gasUsed = gasUsed.add(gasLeft.sub(gasleft()));
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }
    }

    function distributeDividend(address shareholder, uint256 amount) internal {
        _tOwned[address(this)] = _tOwned[address(this)].sub(amount);
        _tOwned[shareholder] = _tOwned[shareholder].add(amount);
        emit Transfer(address(this), shareholder, amount);
    }

    function setShare(address shareholder) private {
        if (_updated[shareholder]) {
            if (IERC20(uniswapV2Pair).balanceOf(shareholder) == 0)
                quitShare(shareholder);
            return;
        }
        if (IERC20(uniswapV2Pair).balanceOf(shareholder) == 0) return;
        addShareholder(shareholder);
        _updated[shareholder] = true;
    }

    function addShareholder(address shareholder) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    function quitShare(address shareholder) private {
        removeShareholder(shareholder);
        _updated[shareholder] = false;
    }

    function removeShareholder(address shareholder) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[
            shareholders.length - 1
        ];
        shareholderIndexes[
            shareholders[shareholders.length - 1]
        ] = shareholderIndexes[shareholder];
        shareholders.pop();
    }

    function _tokenTransferBuy(
        address sender,
        address recipient,
        uint256 tAmount,
        bool takeFee
    ) private {
        uint256 currentRate = _getRate();

        uint256 rAmount = tAmount.mul(currentRate);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);

        uint256 rate;
        if (takeFee) {
            // 3% up 3 down 8
            _takeInviterUpFee(
                sender,
                recipient,
                tAmount.mul(3).div(100),
                currentRate
            );

            _takeInviterDownFee(
                sender,
                recipient,
                tAmount.mul(3).div(100),
                currentRate
            );

            // 5% exchange bliz token for bliz uniswap pair
            _takeBlizTransfer(
                sender,
                blizUniswapV2Pair,
                tAmount.mul(5).div(100)
            );

            _takeTransfer(
                sender,
                _destroyAddress,
                tAmount.mul(2).div(100),
                currentRate
            );

            (bool reb, bool reb1) = isoffs();
            uint256 offRate;
            if (reb) offRate += 10;
            if (reb1) offRate += 10;

            // ?% Anti-fall mechanism
            _takeBlizTransfer(
                sender,
                uniswapV2Pair,
                tAmount.mul(offRate).div(100)
            );

            rate = 10 + offRate;
        }

        uint256 recipientRate = 100 - rate;
        _rOwned[recipient] = _rOwned[recipient].add(
            rAmount.div(100).mul(recipientRate)
        );
        emit Transfer(sender, recipient, tAmount.div(100).mul(recipientRate));
    }

    function _tokenTransferSell(
        address sender,
        address recipient,
        uint256 tAmount,
        bool takeFee
    ) private {
        uint256 currentRate = _getRate();

        uint256 rAmount = tAmount.mul(currentRate);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);

        uint256 rate;
        if (takeFee) {
            // 5% exchange bliz token for msg.sender
            _takeBlizTransfer(
                sender,
                blizUniswapV2Pair,
                tAmount.mul(5).div(100)
            );

            // 5% exchange bliz token for bliz uniswap pair
            _takeBlizTransfer(sender, recipient, tAmount.mul(5).div(100));

            // 3% dividends for holding coins
            _takeTransfer(
                sender,
                address(this),
                tAmount.mul(3).div(100),
                currentRate
            );

            // 2% destroy
            _takeTransfer(
                sender,
                _destroyAddress,
                tAmount.mul(2).div(100),
                currentRate
            );

            rate = 15;
        }

        uint256 recipientRate = 100 - rate;
        _rOwned[recipient] = _rOwned[recipient].add(
            rAmount.div(100).mul(recipientRate)
        );
        emit Transfer(sender, recipient, tAmount.div(100).mul(recipientRate));
    }

    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 tAmount,
        bool takeFee
    ) private {
        uint256 currentRate = _getRate();

        uint256 rAmount = tAmount.mul(currentRate);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);

        uint256 rate;
        if (takeFee) {
            _takeTransfer(
                sender,
                _destroyAddress,
                tAmount.mul(5).div(100),
                currentRate
            );

            rate = 5;
        }

        uint256 recipientRate = 100 - rate;
        _rOwned[recipient] = _rOwned[recipient].add(
            rAmount.div(100).mul(recipientRate)
        );
        emit Transfer(sender, recipient, tAmount.div(100).mul(recipientRate));
    }

    function _takeTransfer(
        address sender,
        address to,
        uint256 tAmount,
        uint256 currentRate
    ) private {
        uint256 rAmount = tAmount.mul(currentRate);
        _rOwned[to] = _rOwned[to].add(rAmount);
        emit Transfer(sender, to, tAmount);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _takeInviterDownFee(
        address sender,
        address recipient,
        uint256 tAmount,
        uint256 currentRate
    ) private {
        address cur;
        address reciver = _default;

        if (sender == uniswapV2Pair) {
            cur = recipient;
        } else {
            cur = sender;
        }

        uint256 rate;
        for (int256 i = 0; i < 8; i++) {
            if (i == 0) {
                rate = 20;
            } else if (i == 1) {
                rate = 10;
            } else {
                rate = 5;
            }

            address[] memory sunList = inviterSuns[cur];
            uint256 index = block.timestamp.mod(sunList.length);
            cur = sunList[index];

            if (cur == address(0)) {
                reciver = _default;
            } else {
                reciver = cur;
            }
            uint256 curTAmount = tAmount.div(100).mul(rate);
            uint256 curRAmount = curTAmount.mul(currentRate);
            _rOwned[reciver] = _rOwned[reciver].add(curRAmount);
            emit Transfer(sender, reciver, curTAmount);
        }
    }

    function _takeInviterUpFee(
        address sender,
        address recipient,
        uint256 tAmount,
        uint256 currentRate
    ) private {
        address cur;
        address reciver = _default;

        if (sender == uniswapV2Pair) {
            cur = recipient;
        } else {
            cur = sender;
        }

        uint256 rate;
        for (int256 i = 0; i < 3; i++) {
            if (i == 0) {
                rate = 25;
            } else if (i == 1) {
                rate = 10;
            } else {
                rate = 5;
            }

            cur = inviter[cur];
            if (cur == address(0)) {
                reciver = _default;
            } else {
                reciver = cur;
            }
            uint256 curTAmount = tAmount.div(1000).mul(rate);
            uint256 curRAmount = curTAmount.mul(currentRate);
            _rOwned[reciver] = _rOwned[reciver].add(curRAmount);
            emit Transfer(sender, reciver, curTAmount);
        }
    }

    function _takeBlizTransfer(
        address sender,
        address recipient,
        uint256 tAmount
    ) private lockTheSwap {
        if (_tOwned[address(this)] < tAmount) return;
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = bliz;
        address getsat = recipient;
        if (sender != uniswapV2Pair) getsat = sender;
        _approve(address(this), address(uniswapV2Router), tAmount);

        swapThisTokenForToken(tAmount, getsat);
    }

    function getExchangeCountOfOneUsdtA(address tradeaddress)
        private
        view
        returns (uint256)
    {
        (uint112 _reserve0, uint112 _reserve1, ) = IUniswapV2Pair(tradeaddress)
            .getReserves();
        uint256 a = _reserve0;
        uint256 b = _reserve1;
        return b.mul(1e18).div(a);
    }

    function getExchangeCountOfOneUsdtB(
        address bnbtrade,
        address tradeaddress,
        address lptoken
    ) private view returns (uint256) {
        (uint112 _reserve0, uint112 _reserve1, ) = IUniswapV2Pair(bnbtrade)
            .getReserves();
        (uint112 _reserve3, uint112 _reserve4, ) = IUniswapV2Pair(tradeaddress)
            .getReserves();

        uint256 balancea = _reserve0;
        uint256 balanceb = _reserve1;
        uint256 balancec = _reserve4;
        uint256 balanced = _reserve3;

        if (IUniswapV2Pair(tradeaddress).token0() == lptoken) {
            balancec = _reserve3;
            balanced = _reserve4;
        }
        if (balancea == 0 || balanceb == 0 || balanced == 0) return 0;
        return balancec.mul(1e18).div(balancea.mul(balanced).div(balanceb));
    }

    function getExchangeCountOfOneUsdt(
        address tokenAddress,
        address lptokenAddress
    ) public view returns (uint256) {
        require(lptokenAddress != address(0));

        if (tokenAddress == address(2) || tokenAddress == address(this)) //BNB
        {
            return
                getExchangeCountOfOneUsdtA(
                    tokenAddress == address(this)
                        ? uniswapV2Pair
                        : _bnbtradeaddress
                );
        } else {
            return
                getExchangeCountOfOneUsdtB(
                    _bnbtradeaddress,
                    lptokenAddress,
                    tokenAddress
                );
        }
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETH(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function swapEthForToken(uint256 ethAmount, address receiver) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[1] = bliz; //代币地址
        path[0] = uniswapV2Router.WETH(); //主币地址

        // _approve(address(this), address(uniswapV2Router), ethAmount);

        // make the swap
        uniswapV2Router.swapExactETHForTokens{value: ethAmount}(
            0, // accept any amount of token
            path,
            receiver,
            block.timestamp
        );
    }

    function swapThisTokenForToken(uint256 thisTokenAmount, address receiver)
        private
    {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this); //本币地址
        path[1] = bliz; //代币地址

        _approve(address(this), address(uniswapV2Router), thisTokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForTokens(
            thisTokenAmount,
            0, // accept any amount of token
            path,
            receiver,
            block.timestamp
        );
    }

    // Anti-fall mechanism
    function getday(uint256 til) public pure returns (uint256) {
        uint256 year;
        uint256 month;
        uint256 day;
        (year, month, day) = DateTimeLibrary.timestampToDate(til);
        uint256 timess = year * 10000 + month * 100 + day;
        return timess;
    }

    uint256 public beforetime;
    uint256 public beforebigp;

    function setbefore(uint256 _beforetime, uint256 _beforebigp)
        public
        onlyOwner
    {
        beforetime = _beforetime;
        beforebigp = _beforebigp;
    }

    uint256 public npo;

    function isoffs() private returns (bool reb, bool reb1) {
        npo = getExchangeCountOfOneUsdtA(address(this)); // token A
        //npo = getExchangeCountOfOneUsdtB(_bnbtradeaddress, blizUniswapV2Pair, bliz); // token B

        if (beforebigp == 0) {
            if (npo > 0) {
                beforebigp = npo;
                beforetime = block.timestamp;
            }
        } else {
            if (npo > beforebigp) {
                // no somethings...
            } else {
                if (block.timestamp.sub(beforetime) >= (24 * 3600)) {
                    beforebigp = npo;
                    beforetime = block.timestamp;
                } else {
                    if (npo < (beforebigp.mul(80).div(100))) {
                        return (true, true);
                    } else if (npo < (beforebigp.mul(90).div(100))) {
                        return (true, false);
                    }
                }
            }
        }
        return (false, false);
    }
}