/**
 *Submitted for verification at BscScan.com on 2022-12-06
*/

pragma solidity 0.8.17;

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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity 0.8.17;

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;
    constructor () {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

/**
 * @title Owner
 * @dev Set & change owner
 */
contract Ownable {

    address private owner;
    
    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    
    // modifier to check if caller is owner
    modifier onlyOwner() {
        // If the first argument of 'require' evaluates to 'false', execution terminates and all
        // changes to the state and to Ether balances are reverted.
        // This used to consume all gas in old EVM versions, but not anymore.
        // It is often a good idea to use 'require' to check if functions are called correctly.
        // As a second argument, you can also provide an explanation about what went wrong.
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    /**
     * @dev Set contract deployer as owner
     */
    constructor() {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnerSet(address(0), owner);
    }

    /**
     * @dev Change owner
     * @param newOwner address of new owner
     */
    function changeOwner(address newOwner) public onlyOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }

    /**
     * @dev Return owner address 
     * @return address of owner
     */
    function getOwner() external view returns (address) {
        return owner;
    }
}

pragma solidity 0.8.17;



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

pragma solidity 0.8.17;

interface IERC20 {

    function totalSupply() external view returns (uint256);
    
    function symbol() external view returns(string memory);
    
    function name() external view returns(string memory);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);
    
    /**
     * @dev Returns the number of decimal places
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity 0.8.17;



interface ILUCAX {
    function xSwapRouter() external view returns (address);
}

interface StableSwapRouter {
    function exchange(address source, address tokenIn, address tokenOut, uint256 amountTokenIn, address destination) external;
}

interface LUCAXRoyalty {
    function getFee() external view returns (uint256);
    function getFeeRecipient() external view returns (address);
}

/**
 *  Contract: USDP Powered by LUCAX
 *  Appreciating Stable Coin Inheriting The IP Of LUCAX by xSurge
 *  Visit MDB.fund and xsurge.net to learn more about appreciating stable coins
 */
contract CryptoPeso is IERC20, Ownable, ReentrancyGuard {
    
    using SafeMath for uint256;

    // token data
    mapping ( address => StableAsset ) public stableAssets;
    string private constant _name = "Crypto Peso";
    string private constant _symbol = "USDP";
    uint8 private constant _decimals = 18;
    uint256 private constant precision = 10**18;
    
    // 1 initial supply
    uint256 private _totalSupply = 100000000*10**18; 
    
    // balances
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    // address -> Fee Exemption
    mapping ( address => bool ) public isTransferFeeExempt;

    // Token Activation
    mapping ( address => bool ) public canTransactPreLaunch;
    bool public tokenActivated;

    // Max Holdings Exempt
    mapping ( address => bool ) public max_holdings_exempt;

    // Dead Wallet
    address private constant DEAD = 0x000000000000000000000000000000000000dEaD;

    // PCS Router
    IUniswapV2Router02 private router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

     mapping (address => bool) private _isBlackList;
    // LUCAX Token
    address public LUCAX;
    address public PUSD;

    // Royalty Data Fetcher
    LUCAXRoyalty private royaltyTracker;

    // Swap Path From BNB -> BUSD
    address[] path;
    uint256 public resourceAllocationPercentage;
      // Underlying Asset
    struct StableAsset {
        bool isApproved;
        bool mintDisabled;
        uint8 index;
    }
    address[] public stables;
      address private _resourceCollector;
    // Fees
    uint256 public mintFee        = 99250;            // 0.75% mint fee
    uint256 public sellFee        = 99750;            // 0.25% redeem fee 
    uint256 public transferFee    = 99750;            // 0.25% transfer fee
    uint256 public stableSwapFee  = 99950;            // 0.05% stable swap fee
    uint256 private constant feeDenominator = 10**5;

    // Maximum Holdings
    uint256 public max_holdings = 50_000_000_000 * 10**18;
    uint256 public min_max_holdings = 20_000_000_000 * 10**18;
    
    // Underlying Asset Is BUSD
    IERC20 public underlying = IERC20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
    
    // initialize some stuff
    constructor(address routAddr,address _underlying, address _PUSD) {
        // Fee Exempt PCS Router And Creator For Initial Distribution
        isTransferFeeExempt[address(router)] = true;
        isTransferFeeExempt[msg.sender] = true;
        router =IUniswapV2Router02(routAddr);

        // Allows Mint Access Pre Activation
        canTransactPreLaunch[msg.sender] = true;
        max_holdings_exempt[msg.sender] = true;

      underlying= IERC20(_underlying);
        // Swap Path For BNB -> BUSD
        path = new address[](2);
        path[0] = router.WETH();
        path[1] = address(underlying);
        // allocate initial 1 token
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
              address BUSD = _underlying;
        stables.push(BUSD);
        stableAssets[BUSD].isApproved = true;
        stableAssets[BUSD].index = 0;
        PUSD=_PUSD;

        stables.push(PUSD);
        stableAssets[PUSD].isApproved = true;
        stableAssets[PUSD].index = 0;

    }

    function setLUCAXAddress(address royaltyAddress, address LUCAXAddr)public onlyOwner{
          LUCAX = LUCAXAddr;
        royaltyTracker = LUCAXRoyalty(royaltyAddress);
    }

    /** Returns the total number of tokens in existence */
    function totalSupply() external view override returns (uint256) { 
        return _totalSupply; 
    }

    /** Returns the number of tokens owned by `account` */
    function balanceOf(address account) public view override returns (uint256) { 
        return _balances[account]; 
    }

    /** Returns the number of tokens `spender` can transfer from `holder` */
    function allowance(address holder, address spender) external view override returns (uint256) { 
        return _allowances[holder][spender]; 
    }
    

     function liquidityInStableCoinSwap() public view returns (uint256 total) {
        for (uint i = 0; i < stables.length; i++) {
            total += IERC20(stables[i]).balanceOf(address(this));
        }
    }

    ///////////////////////////////////
    //////  INTERNAL FUNCTIONS  ///////
    ///////////////////////////////////
      function calculateBacking() public view returns (uint256) {
        uint total = liquidityInStableCoinSwap();
        return total + IERC20(PUSD).totalSupply();
    }

    /** Token Name */
    function name() public pure override returns (string memory) {
        return _name;
    }

    /** Token Ticker Symbol */
    function symbol() public pure override returns (string memory) {
        return _symbol;
    }

    /** Tokens decimals */
    function decimals() public pure override returns (uint8) {
        return _decimals;
    }

    /** Approves `spender` to transfer `amount` tokens from caller */
    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }  
    /** Transfer Function */
    function transfer(address recipient, uint256 amount) external override nonReentrant returns (bool) {
        if (recipient == msg.sender) {
            _sell(msg.sender, amount, msg.sender);
            return true;
        } else {
            return _transferFrom(msg.sender, recipient, amount);
        }
    }

    /** Transfer Function */
    function transferFrom(address sender, address recipient, uint256 amount) external override nonReentrant returns (bool) {
        _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, 'Insufficient Allowance');
        return _transferFrom(sender, recipient, amount);
    }
    
     function addBlackList (address _evilUser) public onlyOwner {
        _isBlackList[_evilUser] = true;
    }
    
    function removeBlackList (address _clearedUser) public onlyOwner {
        _isBlackList[_clearedUser] = false;
    }
     function _getBlackStatus(address _maker) private view returns (bool) {
        return _isBlackList[_maker];
    }
    /** Internal Transfer */
    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        // make standard checks
        require(recipient != address(0) && sender != address(0), "Transfer To Zero");
        require(amount > 0, "Transfer Amt Zero");
        // track price change
            require(_getBlackStatus(sender) == false && _getBlackStatus(recipient) == false, "Address in blacklist");
        uint256 oldPrice = _calculatePrice();
        // amount to give recipient
        uint256 tAmount = (isTransferFeeExempt[sender] || isTransferFeeExempt[recipient]) ? amount : amount.mul(transferFee).div(feeDenominator);
        // tax taken from transfer
         bool isExempt = isTransferFeeExempt[sender] || isTransferFeeExempt[recipient];
        uint256 tax = amount.sub(tAmount);
        // subtract from sender
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

     
        // give reduced amount to receiver
        _balances[recipient] = _balances[recipient].add(tAmount);

        // burn the tax
        if (tax > 0) {
            // Take Fee
            _takeFee(tax);
            _totalSupply = _totalSupply.sub(tax);
            emit Transfer(sender, address(0), tax);
        }
        
        // require price rises
        _requirePriceRises(oldPrice);

        // require maximum holdings is not met
        if (!max_holdings_exempt[recipient]) {
            require(
                getValueOfHoldings(recipient) <= max_holdings,
                'Value Exceeds Maximum Holdings'
            );
        }
        
        // Transfer Event
        emit Transfer(sender, recipient, tAmount);
        return true;
    }

    /**
        Mint USDP Tokens With The Native Token ( Smart Chain BNB )
        This will purchase BUSD with BNB received
        It will then mint tokens to `recipient` based on the number of stable coins received
        `minOut` should be set to avoid the Transaction being front runned

        @param recipient Account to receive minted USDP Tokens
        @param minOut minimum amount out from BNB -> BUSD - prevents front run attacks
        @return received number of USDP tokens received
     */
    function mintWithNative(address recipient, uint256 minOut) external payable returns (uint256) {
        _checkGarbageCollector(address(this));
        _checkGarbageCollector(DEAD);
        return _mintWithNative(recipient, minOut);
    }


    /** 
        Mint USDP Tokens For `recipient` By Depositing BUSD Into The Contract
            Requirements:
                Approval from the BUSD prior to purchase
        
        @param numTokens number of BUSD tokens to mint USDP with
        @param recipient Account to receive minted USDP tokens
        @return tokensMinted number of USDP tokens minted
    */
    function mintWithBacking(uint256 numTokens, address recipient) external nonReentrant returns (uint256) {
        
        _checkGarbageCollector(address(this));
        _checkGarbageCollector(DEAD);
        return _mintWithBacking(numTokens, recipient);
    }
   

   function addStable(address newStable) external onlyOwner {
        require(!stableAssets[newStable].isApproved);
        require(newStable != address(0));
        require(IERC20(newStable).decimals() == 18);

        stableAssets[newStable].isApproved = true;
        stableAssets[newStable].index = uint8(stables.length);
        stables.push(newStable);
    }
     function removeStable(address stable, address stableToSwapWith) external nonReentrant onlyOwner {
        require(stableAssets[stable].isApproved);
        require(stableAssets[stableToSwapWith].isApproved);
        require(stableToSwapWith != stable, 'Matching Swap');

        // price before Tx
        uint256 oldPrice = _calculatePrice();

        // last element's index set to removed element's index
        stableAssets[
            stables[stables.length - 1]
        ].index = stableAssets[stable].index;

        // replace removed element with last element
        stables[
            stableAssets[stable].index
        ] = stables[stables.length - 1];

        // remove last element of array
        stables.pop();
        delete stableAssets[stable];
        
        // transfer in approved stable
        uint256 bal = IERC20(stable).balanceOf(address(this));
        uint256 received = _transferIn(stableToSwapWith, bal);
        
        // transfer out removed stable
        require(
            IERC20(stable).transfer(msg.sender, received),
            'Failure Transfer Out'
        );

        // require no change to price
        _requirePriceRises(oldPrice);
    }

    

     function isUnderlyingAsset(address token) external view returns (bool) {
        return stableAssets[token].isApproved;
    }

       function getUnderlyingAssets() external view returns(address[] memory) {
        return stables;
    }

    /** 
        Burns Sender's USDP Tokens and redeems their value in BUSD
        @param tokenAmount Number of USDP Tokens To Redeem, Must be greater than 0
    */
    function sell(uint256 tokenAmount) external nonReentrant returns (uint256) {
        return _sell(msg.sender, tokenAmount, msg.sender);
    }
    
    /** 
        Burns Sender's USDP Tokens and redeems their value in BUSD for `recipient`
        @param tokenAmount Number of USDP Tokens To Redeem, Must be greater than 0
        @param recipient Recipient Of BUSD transfer, Must not be address(0)
    */
    function sell(uint256 tokenAmount, address recipient) external nonReentrant returns (uint256) {
        return _sell(msg.sender, tokenAmount, recipient);
    }

    /**
        Exchanges TokenIn For TokenOut 1:1 So Long As:
            - TokenIn  is an approved LUCAX stable and not address(0) or tokenOut
            - TokenOut is an approved LUCAX stable and not address(0) or tokenIn
            - TokenIn and TokenOut have the same decimal count

        @param tokenIn - Token To Give LUCAX in exchange for TokenOut
        @param tokenOut - Token To receive from swap
        @param tokenInAmount - Amount of `tokenIn` to exchange for tokenOut
        @param recipient - Recipient of `tokenOut` tokens
     */

    function exchange(address tokenIn, address tokenOut, uint256 tokenInAmount, address recipient) external nonReentrant {
        require(
            tokenIn != address(0) && 
            tokenOut != address(0) && 
            recipient != address(0) &&
            tokenIn != tokenOut &&
            tokenInAmount > 0,
            'Invalid Params'
        );
        // log old price
        uint oldPrice = _calculatePrice();
        // instantiate xSwap Router
        StableSwapRouter swapRouter = StableSwapRouter(ILUCAX(LUCAX).xSwapRouter());
        require(
            address(swapRouter) != address(0),
            'Zero Address'
        );
        // transfer in tokenIn
        uint received = _transferIn(tokenIn, tokenInAmount);
        // take fee for contract
        uint toSend = received.mul(stableSwapFee).div(feeDenominator);
        // exchange tokenIn for tokenOut
        swapRouter.exchange(LUCAX, tokenIn, tokenOut, toSend, recipient);
        // require price did not somehow fall
        _requirePriceRises(oldPrice);
    }
    
    /** 
        Allows A User To Erase Their Holdings From Supply 
        DOES NOT REDEEM UNDERLYING ASSET FOR USER
        @param amount Number of USDP Tokens To Burn
    */
    function burn(uint256 amount) external nonReentrant {
        // get balance of caller
        uint256 bal = _balances[msg.sender];
        require(bal >= amount && bal > 0, 'Zero Holdings');
        // Track Change In Price
        uint256 oldPrice = _calculatePrice();
        // take fee
        _takeFee(amount);
        // burn tokens from sender + supply
        _burn(msg.sender, amount);
        // require price rises
        _requirePriceRises(oldPrice);
        // Emit Call
        emit Burn(msg.sender, amount);
    }


    ///////////////////////////////////
    //////  INTERNAL FUNCTIONS  ///////
    ///////////////////////////////////
    
    /** Purchases USDP Token and Deposits Them in Recipient's Address */
    function _mintWithNative(address recipient, uint256 minOut) internal nonReentrant returns (uint256) {        
        require(msg.value > 0, 'Zero Value');
        require(recipient != address(0), 'Zero Address');
        require(
            tokenActivated || canTransactPreLaunch[msg.sender],
            'Token Not Activated'
        );
        
        // calculate price change
        uint256 oldPrice = _calculatePrice();
        
        // previous backing
        uint256 previousBacking = calculateBacking();
        
        // swap BNB for stable
        uint256 received = _purchaseBUSD(minOut);

        // if this is the first purchase, use new amount
        uint256 relevantBacking = previousBacking == 0 ? calculateBacking() : previousBacking;

        // mint to recipient
        return _mintTo(recipient, received, relevantBacking, oldPrice);
    }
    
    /** Stake Tokens and Deposits USDP in Sender's Address, Must Have Prior Approval For BUSD */
    function _mintWithBacking(uint256 numBUSD, address recipient) internal returns (uint256) {
        require(
            tokenActivated || canTransactPreLaunch[msg.sender],
            'Token Not Activated'
        );
        // users token balance
        uint256 userTokenBalance = underlying.balanceOf(msg.sender);
        // ensure user has enough to send
        require(userTokenBalance > 0 && numBUSD <= userTokenBalance, 'Insufficient Balance');

        // calculate price change
        uint256 oldPrice = _calculatePrice();

        // previous backing
        uint256 previousBacking = calculateBacking();

        // transfer in token
        uint256 received = _transferIn(address(underlying), numBUSD);

        // if this is the first purchase, use new amount
        uint256 relevantBacking = previousBacking == 0 ? received : previousBacking;

        // Handle Minting
        return _mintTo(recipient, received, relevantBacking, oldPrice);
    }
    
    /** Burns USDP Tokens And Deposits BUSD Tokens into Recipients's Address */
    function _sell(address seller, uint256 tokenAmount, address recipient) internal returns (uint256) {
        require(tokenAmount > 0 && _balances[seller] >= tokenAmount);
        require(seller != address(0) && recipient != address(0));
        
        // calculate price change
        uint256 oldPrice = _calculatePrice();
        
        // tokens post fee to swap for underlying asset
        uint256 tokensToSwap = isTransferFeeExempt[seller] ? 
            tokenAmount.sub(10, 'Minimum Exemption') :
            tokenAmount.mul(sellFee).div(feeDenominator);

        // value of taxed tokens
        uint256 amountUnderlyingAsset = amountOut(tokensToSwap);

        // Take Fee
        if (!isTransferFeeExempt[msg.sender]) {
            uint fee = tokenAmount.sub(tokensToSwap);
            _takeFee(fee);
        }

        // burn from sender + supply 
        _burn(seller, tokenAmount);
        
        // send Tokens to Seller
        require(
            underlying.transfer(recipient, amountUnderlyingAsset), 
            'Underlying Transfer Failure'
        );

        // require price rises
        _requirePriceRises(oldPrice);
        // Differentiate Sell
        emit Redeemed(seller, tokenAmount, amountUnderlyingAsset);
        // return token redeemed and amount underlying
        return amountUnderlyingAsset;
    }

    /** Handles Minting Logic To Create New USDP */
    function _mintTo(address recipient, uint256 received, uint256 totalBacking, uint256 oldPrice) private returns(uint256) {
        
        // find the number of tokens we should mint to keep up with the current price
        uint256 calculatedSupply = _totalSupply == 0 ? 10**18 : _totalSupply;
        uint256 tokensToMintNoTax = calculatedSupply.mul(received).div(totalBacking);
        
        // apply fee to minted tokens to inflate price relative to total supply
        uint256 tokensToMint = isTransferFeeExempt[msg.sender] ? 
                tokensToMintNoTax.sub(10, 'Minimum Exemption') :
                tokensToMintNoTax.mul(mintFee).div(feeDenominator);
        require(tokensToMint > 0, 'Zero Amount');
        
        // mint to Buyer
        _mint(recipient, tokensToMint);

        // apply fee to tax taken
        if (!isTransferFeeExempt[msg.sender]) {
            uint fee = tokensToMintNoTax.sub(tokensToMint);
            _takeFee(fee);
        }

        // require price rises
        _requirePriceRises(oldPrice);
        // require maximum holdings is not met
        if (!max_holdings_exempt[recipient]) {
            require(
                getValueOfHoldings(recipient) <= max_holdings,
                'Value Exceeds Maximum Holdings'
            );
        }
        // differentiate purchase
        emit Minted(recipient, tokensToMint);
        return tokensToMint;
    }

    /** Takes Fee */
    function _takeFee(uint mFee) internal {
        (uint fee, address feeRecipient) = getFeeAndRecipient();
        if (fee > 0) {
            uint fFee = mFee.mul(fee).div(100);
            uint bFee = amountOut(fFee);
            if (bFee > 0 && feeRecipient != address(0)) {
                underlying.transfer(feeRecipient, bFee);
            }
        }
    }

    /** Swaps BNB for BUSD, must get at least `minOut` BUSD back from swap to be successful */
    function _purchaseBUSD(uint256 minOut) internal returns (uint256) {

        // previous amount of Tokens before we received any
        uint256 prevTokenAmount = underlying.balanceOf(address(this));

        // swap BNB For stable of choice
        router.swapExactETHForTokens{value: address(this).balance}(minOut, path, address(this), block.timestamp + 300);

        // amount after swap
        uint256 currentTokenAmount = underlying.balanceOf(address(this));
        require(currentTokenAmount > prevTokenAmount);
        return currentTokenAmount - prevTokenAmount;
    }

    /** Requires The Price Of USDP To Rise For The Transaction To Conclude */
    function _requirePriceRises(uint256 oldPrice) internal {
        // Calculate Price After Transaction
        uint256 newPrice = _calculatePrice();
        // Require Current Price >= Last Price
        require(newPrice >= oldPrice, 'Price Cannot Fall');
        // Emit The Price Change
        emit PriceChange(oldPrice, newPrice, _totalSupply);
    }

    /** Transfers `desiredAmount` of `token` in and verifies the transaction success */
    function _transferIn(address token, uint256 desiredAmount) internal returns (uint256) {
        uint256 balBefore = IERC20(token).balanceOf(address(this));
        bool s = IERC20(token).transferFrom(msg.sender, address(this), desiredAmount);
        uint256 received = IERC20(token).balanceOf(address(this)) - balBefore;
        require(s && received > 0 && received <= desiredAmount);
        return received;
    }
    
    /** Mints Tokens to the Receivers Address */
    function _mint(address receiver, uint amount) private {
        _balances[receiver] = _balances[receiver].add(amount);
        _totalSupply = _totalSupply.add(amount);
        emit Transfer(address(0), receiver, amount);
    }
    
    /** Burns `amount` of tokens from `account` */
    function _burn(address account, uint amount) private {
        _balances[account] = _balances[account].sub(amount, 'Insufficient Balance');
        _totalSupply = _totalSupply.sub(amount, 'Negative Supply');
        emit Transfer(account, address(0), amount);
    }

    /** Make Sure there's no Native Tokens in contract */
    function _checkGarbageCollector(address burnLocation) internal {
        uint256 bal = _balances[burnLocation];
        if (bal > 10**3) {
            // Track Change In Price
            uint256 oldPrice = _calculatePrice();
            // take fee
            _takeFee(bal);
            // burn amount
            _burn(burnLocation, bal);
            // Emit Collection
            emit GarbageCollected(bal);
            // Require price rises
            _requirePriceRises(oldPrice);
        }
    }
    
    ///////////////////////////////////
    //////    READ FUNCTIONS    ///////
    ///////////////////////////////////
    

    /** Price Of USDP in BUSD With 18 Points Of Precision */
    function calculatePrice() external view returns (uint256) {
        return _calculatePrice();
    }
    
    /** Returns the Current Price of 1 Token */
    function _calculatePrice() internal view returns (uint256) {
        uint256 totalShares = _totalSupply == 0 ? 1 : _totalSupply;
        uint256 backingValue = calculateBacking();
        return (backingValue.mul(precision)).div(totalShares);
    }

    /**
        Amount Of Underlying To Receive For `numTokens` of USDP
     */
    function amountOut(uint256 numTokens) public view returns (uint256) {
        return _calculatePrice().mul(numTokens).div(precision);
    }

    /** Returns the value of `holder`'s holdings */
    function getValueOfHoldings(address holder) public view returns(uint256) {
        return amountOut(_balances[holder]);
    }

    /** Returns Royalty Fee And Fee Recipient For Taxes */
    function getFeeAndRecipient() public view returns (uint256, address) {
        uint fee = royaltyTracker.getFee();
        address recipient = royaltyTracker.getFeeRecipient();
        return (fee, recipient);
    }
    
    ///////////////////////////////////
    //////   OWNER FUNCTIONS    ///////
    ///////////////////////////////////

    /** Activates Token, Enabling Trading For All */
    function activateToken() external onlyOwner {
        tokenActivated = true;
        emit TokenActivated(block.number);
    }
    
    /** Registers List Of Addresses To Transact Before Token Goes Live */
    function registerUserToBuyPreLaunch(address[] calldata users) external onlyOwner {
        for (uint i = 0; i < users.length; i++) {
            canTransactPreLaunch[users[i]] = true;
        }
    }

    /** Set Maximum Holdings */
    function setMaxHoldings(uint256 maxHoldings) external onlyOwner {
        require(maxHoldings >= min_max_holdings, 'Minimum Reached');
        max_holdings = maxHoldings;
        emit SetMaxHoldings(maxHoldings);
    }
       function setMinMaxHoldings(uint256 MinmaxHoldings) external onlyOwner {
        require(MinmaxHoldings >= min_max_holdings, 'Minimum Reached');
        min_max_holdings = MinmaxHoldings;
    }

    /** Updates The Address Of The Router To Purchase BUSD */
    function upgradeRouter(address newRouter) external onlyOwner {
        require(newRouter != address(0));
        isTransferFeeExempt[newRouter] = true;
        router = IUniswapV2Router02(newRouter);
        emit SetRouter(newRouter);
    }

    /** Withdraws Tokens Incorrectly Sent To USDP */
    function withdrawNonStableToken(address token) public onlyOwner {
        require(address(token) != address(underlying), 'Cannot Withdraw Underlying Asset');
        require(address(token) != address(0), 'Zero Address');
        IERC20(token).transfer(msg.sender, IERC20(token).balanceOf(address(this)));
    }

    /** 
        Sells Tokens On Behalf Of Other User
            Requirements:
                User MUST have more than the max_holdings quantity in BUSD
                Can only redeem as much as they have excess in BUSD
     */
    function sellDownAccountToMaximumHoldings(address account) external nonReentrant onlyOwner {
        require(account != address(0), 'Zero Address');
        require(!max_holdings_exempt[account], 'Account Is Max Holdings Exempt');
        // value of accounts holdings
        uint valueOfHoldings = getValueOfHoldings(account);
        require(
            valueOfHoldings > max_holdings,
            'User Does Not Exceed Max Holdings'
        );

        // amount to sell to bring to max holdings
        uint256 amtToSellBUSD = valueOfHoldings.sub(max_holdings);

        // convert to USDP
        uint256 mdbPlusToSell = amtToSellBUSD.mul(precision).div(_calculatePrice());

        // sell excess tokens
        if (mdbPlusToSell > 0) {
            _sell(
                account,
                mdbPlusToSell, 
                account
            );
        }
    }

    /** 
        Sets Mint, Transfer, Sell Fee
        Must Be Within Bounds ( Between 0% - 2% ) 
    */
    function setFees(uint256 _mintFee, uint256 _transferFee, uint256 _sellFee, uint256 _stableSwapFee) external onlyOwner {
              require(_mintFee >= 97000);       // capped at 3% fee
        require(_transferFee >= 97000);   // capped at 3% fee
        require(_sellFee >= 97000);       // capped at 3% fee
        require(_stableSwapFee >= 99000); // capped at 3% fee         
        mintFee = _mintFee;
        transferFee = _transferFee;
        sellFee = _sellFee;
        stableSwapFee = _stableSwapFee;
        emit SetFees(_mintFee, _transferFee, _sellFee, _stableSwapFee);
    }
    
    /** Excludes Contract From Transfer Fees */
    function setPermissions(address Contract, bool transferFeeExempt) external onlyOwner {
        require(Contract != address(0), 'Zero Address');
        isTransferFeeExempt[Contract] = transferFeeExempt;
        emit SetPermissions(Contract, transferFeeExempt);
    }

    /** Excludes Contract From Transfer Fees */
    function setMaxHoldingsExempt(address account, bool isHoldingsExempt) external onlyOwner {
        require(account != address(0), 'Zero Address');
        max_holdings_exempt[account] = isHoldingsExempt;
        emit SetMaxHoldingsExempt(account, isHoldingsExempt);
    }
    
    /** Mint Tokens to Buyer */
    receive() external payable {
        _mintWithNative(msg.sender, 0);
        _checkGarbageCollector(address(this));
        _checkGarbageCollector(DEAD);
    }
    
    
    ///////////////////////////////////
    //////        EVENTS        ///////
    ///////////////////////////////////
    
    // Data Tracking
    event PriceChange(uint256 previousPrice, uint256 currentPrice, uint256 totalSupply);
    event TokenActivated(uint blockNo);

    // Balance Tracking
    event Burn(address from, uint256 amountTokensErased);
    event GarbageCollected(uint256 amountTokensErased);
    event Redeemed(address seller, uint256 amountMDB, uint256 amountBUSD);
    event Minted(address recipient, uint256 numTokens);

    // Upgradable Contract Tracking
    event SetMaxHoldings(uint256 maxHoldings);
    event SetRouter(address newRouter);

    // Governance Tracking
    event SetPermissions(address Contract, bool feeExempt);
    event SetMaxHoldingsExempt(address account, bool isExempt);
    event SetFees(uint mintFee, uint transferFee, uint sellFee, uint stableSwapFee);
}