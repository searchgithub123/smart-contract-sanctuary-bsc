// SPDX-License-Identifier: MIT

pragma solidity ^0.8.5;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
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

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
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
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}

interface IPancakeRouter01 {
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

interface IPancakeRouter02 is IPancakeRouter01 {
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

interface IPancakeFactory {
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

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    modifier isHuman() {
        require(tx.origin == msg.sender, "Humans only");
        _;
    }
}

// pragma solidity >=0.5.0;

interface IPinkAntiBot {
    function setTokenOwner(address owner) external;

    function onPreTransferCheck(
        address from,
        address to,
        uint256 amount
    ) external;
}

// Base class that implements: BEP20 interface, fees & swaps
abstract contract SpaceDogeBase is
    Context,
    IERC20Metadata,
    Ownable,
    ReentrancyGuard
{
    // MAIN TOKEN PROPERTIES
    string private constant NAME = "SpaceDoge";
    string private constant SYMBOL = "SDOGE";
    uint8 private constant DECIMALS = 18;
    uint8 private _liquidityFee; //% of each transaction that will be added as liquidity
    uint8 private _rewardFee; //% of each transaction that will be used for BNB reward pool
    uint8 private _buybackFee; //% of each transaction that will be used for buy back and burn
    uint8 private _marketingFee; //% of each transaction that will be used for development and marketing
    uint8 private _salaryFee; // % of each transaction that will b e used for salary tax
    uint8 private _poolFee; //The total fee to be taken and addedto the pool, this includes all fees

    struct CustomTax {
        uint8 liquidityFee;
        uint8 rewardFee;
        uint8 buybackFee;
        uint8 marketingFee;
        uint8 salaryFee;
    }

    CustomTax private _buyFee;
    CustomTax private _sellFee;

    uint256 private constant _totalTokens = 100000000000 * 10**DECIMALS; //100000000000 total supply
    mapping(address => uint256) private _balances; //The balance of each address.  This is before applying distribution rate.  To get the actual balance, see balanceOf() method
    mapping(address => mapping(address => uint256)) private _allowances;

    // FEES & REWARDS
    bool private _isSwapEnabled; // True if the contract should swap for liquidity & reward pool, false otherwise
    bool private _isFeeEnabled; // True if fees should be applied on transactions, false otherwise
    address public constant BURN_WALLET =
        0x000000000000000000000000000000000000dEaD; //The address that keeps track of all tokens burned
    uint256 private _tokenSwapThreshold = _totalTokens / 10000; //There should be at least 0.0001% of the total supply in the contract before triggering a swap
    uint256 private _totalFeesPooled; // The total fees pooled (in number of tokens)
    uint256 private _totalBNBLiquidityAddedFromFees; // The total number of BNB added to the pool through fees
    mapping(address => bool) private _addressesExcludedFromFees; // The list of addresses that do not pay a fee for transactions

    // TRANSACTION LIMIT
    uint256 private _transactionLimit = _totalTokens / 1000; //100000000 The amount of tokens that can be sold at once
    bool private _isBuyingAllowed; // This is used to make sure that the contract is activated before anyone makes a purchase on PCS.  The contract will be activated once liquidity is added.

    // marketing and moonshield address
    address private _marketingWallet =
        0xcA3c056C7f4639D98EE2F6CC14Ba3E67e9F43bd4;
    address private _salaryWallet = 0x1902108e82a35Af0a3Cdb23824B0cE3d28b39BAc;

    // PANCAKESWAP INTERFACES (For swaps)
    address private _pancakeSwapRouterAddress;
    IPancakeRouter02 private _pancakeswapV2Router;
    address private _pancakeswapV2Pair;
    address private _autoLiquidityWallet;

    IPinkAntiBot public pinkAntiBot;
    bool public antiBotEnabled;

    // EVENTS
    event Swapped(
        uint256 tokensSwapped,
        uint256 bnbReceived,
        uint256 tokensIntoLiqudity,
        uint256 bnbIntoLiquidity
    );
    event AutoBurned(uint256 bnbAmount);

    constructor(address routerAddress, address pinkAntiBot_) {
        _balances[_msgSender()] = totalSupply();

        // Exclude contract from fees
        _addressesExcludedFromFees[address(this)] = true;

        // Initialize PancakeSwap V2 router and SSV2 <-> BNB pair.  Router address will be: 0x10ed43c718714eb63d5aa57b78b54704e256024e or for testnet: 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3
        setPancakeSwapRouter(routerAddress);

        // 2% liquidity fee, 4% reward fee, 1% buyback fee, 7% marketing fee, 1% salary fee for buy
        setBuyFees(2, 4, 1, 7, 1);
        // 3% liquidity fee, 5% reward fee, 1% buyback fee, 7% marketing fee, 1% salary fee for sell
        setSellFees(3, 5, 1, 7, 1);

        emit Transfer(address(0), _msgSender(), totalSupply());

        // Create an instance of the PinkAntiBot variable from the provided address. PinkAntiBot will be: 0x8EFDb3b642eb2a20607ffe0A56CFefF6a95Df002 or for testnet: 0xbb06F5C7689eA93d9DeACCf4aF8546C4Fe0Bf1E5
        pinkAntiBot = IPinkAntiBot(pinkAntiBot_);
        // Register the deployer to be the token owner with PinkAntiBot. You can
        // later change the token owner in the PinkAntiBot contract
        pinkAntiBot.setTokenOwner(msg.sender);
        antiBotEnabled = false;
    }

    // Use this function to control whether to use PinkAntiBot or not instead
    // of managing this in the PinkAntiBot contract
    function setEnableAntiBot(bool _enable) external onlyOwner {
        antiBotEnabled = _enable;
    }

    // This function is used to enable all functions of the contract, after the setup of the token sale (e.g. Liquidity) is completed
    function activate() public onlyOwner {
        setSwapEnabled(true);
        setFeeEnabled(true);
        setAutoLiquidityWallet(owner());
        setTransactionLimit(1000); // only 0.1% of the total supply can be sold at once
        activateBuying();
        onActivated();
    }

    function onActivated() internal virtual {}

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        doTransfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        doTransfer(sender, recipient, amount);
        doApprove(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()] - amount
        ); // Will fail when there is not enough allowance
        return true;
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        doApprove(_msgSender(), spender, amount);
        return true;
    }

    function doTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(
            sender != address(0),
            "Transfer from the zero address is not allowed"
        );
        require(
            recipient != address(0),
            "Transfer to the zero address is not allowed"
        );
        if (antiBotEnabled) {
            pinkAntiBot.onPreTransferCheck(sender, recipient, amount);
        }
        require(amount > 0, "Transfer amount must be greater than zero");
        require(
            !isPancakeSwapPair(sender) || _isBuyingAllowed,
            "Buying is not allowed before contract activation"
        );

        // Ensure that amount is within the limit in case we are selling
        if (isTransferLimited(sender, recipient)) {
            require(
                amount <= _transactionLimit,
                "Transfer amount exceeds the maximum allowed"
            );
        }

        bool isBuyFromLp = isPancakeSwapPair(sender);
        bool isSelltoLp = isPancakeSwapPair(recipient);
        adjustTaxes(isBuyFromLp, isSelltoLp);

        // Perform a swap if needed.  A swap in the context of this contract is the process of swapping the contract's token balance with BNBs in order to provide liquidity and increase the reward pool
        executeSwapIfNeeded(sender, recipient);

        onBeforeTransfer(sender, recipient, amount);

        // Calculate fee rate
        uint256 feeRate = calculateFeeRate(sender, recipient);

        uint256 feeAmount = (amount * feeRate) / 100;
        uint256 transferAmount = amount - feeAmount;

        // Update balances
        updateBalances(sender, recipient, amount, feeAmount);

        // Update total fees, this is just a counter provided for visibility
        _totalFeesPooled += feeAmount;

        emit Transfer(sender, recipient, transferAmount);

        onTransfer(sender, recipient, amount);
    }

    function onBeforeTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {}

    function onTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {}

    function updateBalances(
        address sender,
        address recipient,
        uint256 sentAmount,
        uint256 feeAmount
    ) private {
        // Calculate amount to be received by recipient
        uint256 receivedAmount = sentAmount - feeAmount;

        // Update balances
        _balances[sender] -= sentAmount;
        _balances[recipient] += receivedAmount;

        // Add fees to contract
        _balances[address(this)] += feeAmount;
    }

    function doApprove(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "Cannot approve from the zero address");
        require(spender != address(0), "Cannot approve to the zero address");

        _allowances[owner][spender] = amount;

        emit Approval(owner, spender, amount);
    }

    function calculateFeeRate(address sender, address recipient)
        private
        view
        returns (uint256)
    {
        bool applyFees = _isFeeEnabled &&
            !_addressesExcludedFromFees[sender] &&
            !_addressesExcludedFromFees[recipient];
        if (applyFees) {
            (
                bool ssv2Flag,
                uint256 ssv2BuyFee,
                uint256 ssv2SellFee
            ) = onBeforeCalculateFeeRate();
            if (isPancakeSwapPair(recipient)) {
                // Additional fee when selling
                if (ssv2Flag) {
                    return ssv2SellFee;
                }
                return _poolFee;
            }
            if (isPancakeSwapPair(sender)) {
                // Additional fee when buying
                if (ssv2Flag) {
                    return ssv2BuyFee;
                }
                return _poolFee;
            }
            return _poolFee;
        }

        return 0;
    }

    function onBeforeCalculateFeeRate()
        internal
        view
        virtual
        returns (
            bool,
            uint256,
            uint256
        )
    {
        return (false, 0, 0);
    }

    function executeSwapIfNeeded(address sender, address recipient) private {
        bool applyFees = _isFeeEnabled && !_addressesExcludedFromFees[sender];
        if (!isMarketTransfer(sender, recipient) || !applyFees) {
            return;
        }

        // Check if it's time to swap for liquidity & reward pool
        uint256 tokensAvailableForSwap = balanceOf(address(this));
        if (tokensAvailableForSwap >= _tokenSwapThreshold) {
            // Limit to threshold
            tokensAvailableForSwap = _tokenSwapThreshold;

            // Make sure that we are not stuck in a loop (Swap only once)
            bool isSelling = isPancakeSwapPair(recipient);
            if (_poolFee > 0 && isSelling) {
                executeSwap(tokensAvailableForSwap);
            }
        }
    }

    function executeSwap(uint256 amount) private {
        // Allow pancakeSwap to spend the tokens of the address
        doApprove(address(this), _pancakeSwapRouterAddress, amount);

        uint256 tokensReservedForLiquidity = (amount * _liquidityFee) /
            _poolFee;
        uint256 tokensReservedForBuyback = (amount * _buybackFee) / _poolFee;
        uint256 tokensReservedForMarketing = (amount * _marketingFee) /
            _poolFee;
        uint256 tokensReservedForReward = (amount * _rewardFee) / _poolFee;
        uint256 tokensReservedForSalary = amount -
            tokensReservedForLiquidity -
            tokensReservedForBuyback -
            tokensReservedForMarketing -
            tokensReservedForReward;

        // For the liquidity portion, half of it will be swapped for BNB and the other half will be used to add the BNB into the liquidity
        uint256 tokensToSwapForLiquidity = tokensReservedForLiquidity / 2;
        uint256 tokensToAddAsLiquidity = tokensToSwapForLiquidity;

        uint256 tokensToSwap = tokensReservedForReward +
            tokensToSwapForLiquidity +
            tokensReservedForBuyback +
            tokensReservedForMarketing +
            tokensReservedForSalary;
        uint256 bnbSwapped = swapTokensForBNB(tokensToSwap);

        // Calculate what portion of the swapped BNB is for liquidity and supply it using the other half of the token liquidity portion.  The remaining BNBs in the contract represent the reward pool
        uint256 bnbToBeAddedToLiquidity = (bnbSwapped *
            tokensToSwapForLiquidity) / tokensToSwap;
        (, uint256 bnbAddedToLiquidity, ) = _pancakeswapV2Router
            .addLiquidityETH{value: bnbToBeAddedToLiquidity}(
            address(this),
            tokensToAddAsLiquidity,
            0,
            0,
            _autoLiquidityWallet,
            block.timestamp + 360
        );

        // Keep track of how many BNB were added to liquidity this way
        _totalBNBLiquidityAddedFromFees += bnbAddedToLiquidity;

        //send bnb to marketing wallet
        uint256 bnbToBeSendToMarketing = (bnbSwapped *
            tokensReservedForMarketing) / tokensToSwap;
        (bool sent, ) = _marketingWallet.call{value: bnbToBeSendToMarketing}(
            ""
        );
        require(sent, "Failed to send BNB to marketing wallet");

        //send bnb to salary wallet
        uint256 bnbToBeSendToSalary = (bnbSwapped * tokensReservedForSalary) /
            tokensToSwap;
        (bool sentSalary, ) = _salaryWallet.call{value: bnbToBeSendToSalary}(
            ""
        );
        require(sentSalary, "Failed to send BNB to salary wallet");

        //buyback and burn
        uint256 bnbToBeBuybackAndBurn = (bnbSwapped *
            tokensReservedForBuyback) / tokensToSwap;

        if (swapBNBForTokens(bnbToBeBuybackAndBurn, BURN_WALLET)) {
            emit AutoBurned(bnbToBeBuybackAndBurn);
        }

        emit Swapped(
            tokensToSwap,
            bnbSwapped,
            tokensToAddAsLiquidity,
            bnbToBeAddedToLiquidity
        );
    }

    // This function swaps a {tokenAmount} of SSV2 tokens for BNB and returns the total amount of BNB received
    function swapTokensForBNB(uint256 tokenAmount) internal returns (uint256) {
        uint256 initialBalance = address(this).balance;

        // Generate pair for SSV2 -> WBNB
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _pancakeswapV2Router.WETH();

        // Swap
        _pancakeswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                tokenAmount,
                0,
                path,
                address(this),
                block.timestamp + 360
            );

        // Return the amount received
        return address(this).balance - initialBalance;
    }

    function swapBNBForTokens(uint256 bnbAmount, address to)
        internal
        returns (bool)
    {
        // Generate pair for WBNB -> SSV2
        address[] memory path = new address[](2);
        path[0] = _pancakeswapV2Router.WETH();
        path[1] = address(this);

        // Swap and send the tokens to the 'to' address
        try
            _pancakeswapV2Router
                .swapExactETHForTokensSupportingFeeOnTransferTokens{
                value: bnbAmount
            }(0, path, to, block.timestamp + 360)
        {
            return true;
        } catch {
            return false;
        }
    }

    function swapBNBForCustomeTokens(
        address token,
        uint256 bnbAmount,
        address to
    ) internal returns (bool) {
        // Generate pair for WBNB -> Token
        address[] memory path = new address[](2);
        path[0] = _pancakeswapV2Router.WETH();
        path[1] = token;

        // Swap and send the tokens to the 'to' address
        try
            _pancakeswapV2Router
                .swapExactETHForTokensSupportingFeeOnTransferTokens{
                value: bnbAmount
            }(0, path, to, block.timestamp + 360)
        {
            return true;
        } catch {
            return false;
        }
    }

    // Returns true if the transfer between the two given addresses should be limited by the transaction limit and false otherwise
    function isTransferLimited(address sender, address recipient)
        private
        view
        returns (bool)
    {
        bool isSelling = isPancakeSwapPair(recipient);
        return isSelling && isMarketTransfer(sender, recipient);
    }

    function isSwapTransfer(address sender, address recipient)
        private
        view
        returns (bool)
    {
        bool isContractSelling = sender == address(this) &&
            isPancakeSwapPair(recipient);
        return isContractSelling;
    }

    // Function that is used to determine whether a transfer occurred due to a user buying/selling/transfering and not due to the contract swapping tokens
    function isMarketTransfer(address sender, address recipient)
        internal
        view
        virtual
        returns (bool)
    {
        return !isSwapTransfer(sender, recipient);
    }

    // Returns how many more $SSV2 tokens are needed in the contract before triggering a swap
    function amountUntilSwap() public view returns (uint256) {
        uint256 balance = balanceOf(address(this));
        if (balance > _tokenSwapThreshold) {
            // Swap on next relevant transaction
            return 0;
        }

        return _tokenSwapThreshold - balance;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        doApprove(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + addedValue
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        doApprove(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] - subtractedValue
        );
        return true;
    }

    function setPancakeSwapRouter(address routerAddress) public onlyOwner {
        require(
            routerAddress != address(0),
            "Cannot use the zero address as router address"
        );

        _pancakeSwapRouterAddress = routerAddress;
        _pancakeswapV2Router = IPancakeRouter02(_pancakeSwapRouterAddress);
        _pancakeswapV2Pair = IPancakeFactory(_pancakeswapV2Router.factory())
            .createPair(address(this), _pancakeswapV2Router.WETH());

        onPancakeSwapRouterUpdated();
    }

    function onPancakeSwapRouterUpdated() internal virtual {}

    function isPancakeSwapPair(address addr) internal view returns (bool) {
        return _pancakeswapV2Pair == addr;
    }

    function setBuyFees(
        uint8 liquidityFee,
        uint8 rewardFee,
        uint8 buybackFee,
        uint8 marketingFee,
        uint8 salaryFee
    ) public onlyOwner {
        _buyFee.liquidityFee = liquidityFee;
        _buyFee.rewardFee = rewardFee;
        _buyFee.buybackFee = buybackFee;
        _buyFee.marketingFee = marketingFee;
        _buyFee.salaryFee = salaryFee;
    }

    function setSellFees(
        uint8 liquidityFee,
        uint8 rewardFee,
        uint8 buybackFee,
        uint8 marketingFee,
        uint8 salaryFee
    ) public onlyOwner {
        _sellFee.liquidityFee = liquidityFee;
        _sellFee.rewardFee = rewardFee;
        _sellFee.buybackFee = buybackFee;
        _sellFee.marketingFee = marketingFee;
        _sellFee.salaryFee = salaryFee;
    }

    function adjustTaxes(bool isBuyFromLp, bool isSelltoLp) private {
        _liquidityFee = 0;
        _rewardFee = 0;
        _buybackFee = 0;
        _marketingFee = 0;
        _salaryFee = 0;
        if (isBuyFromLp) {
            _liquidityFee = _buyFee.liquidityFee;
            _rewardFee = _buyFee.rewardFee;
            _buybackFee = _buyFee.buybackFee;
            _marketingFee = _buyFee.marketingFee;
            _salaryFee = _buyFee.salaryFee;
        }
        if (isSelltoLp) {
            _liquidityFee = _sellFee.liquidityFee;
            _rewardFee = _sellFee.rewardFee;
            _buybackFee = _sellFee.buybackFee;
            _marketingFee = _sellFee.marketingFee;
            _salaryFee = _sellFee.salaryFee;
        }
        _poolFee =
            _liquidityFee +
            _rewardFee +
            _buybackFee +
            _marketingFee +
            _salaryFee;
    }

    // This function will be used to reduce the limit later on, according to the price of the token, 100 = 1%, 1000 = 0.1% ...
    function setTransactionLimit(uint256 limit) public onlyOwner {
        require(
            limit >= 1 && limit <= 10000,
            "Limit must be greater than 0.01%"
        );
        _transactionLimit = _totalTokens / limit;
    }

    function transactionLimit() public view returns (uint256) {
        return _transactionLimit;
    }

    function setTokenSwapThreshold(uint256 threshold) public onlyOwner {
        require(threshold > 0, "Threshold must be greater than 0");
        _tokenSwapThreshold = threshold;
    }

    function tokenSwapThreshold() public view returns (uint256) {
        return _tokenSwapThreshold;
    }

    function name() public pure override returns (string memory) {
        return NAME;
    }

    function symbol() public pure override returns (string memory) {
        return SYMBOL;
    }

    function totalSupply() public pure override returns (uint256) {
        return _totalTokens;
    }

    function decimals() public pure override returns (uint8) {
        return DECIMALS;
    }

    function allowance(address user, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[user][spender];
    }

    function pancakeSwapRouterAddress() public view returns (address) {
        return _pancakeSwapRouterAddress;
    }

    function pancakeSwapPairAddress() public view returns (address) {
        return _pancakeswapV2Pair;
    }

    function autoLiquidityWallet() public view returns (address) {
        return _autoLiquidityWallet;
    }

    function setAutoLiquidityWallet(address liquidityWallet) public onlyOwner {
        _autoLiquidityWallet = liquidityWallet;
    }

    function devmarketingWallet() public view returns (address) {
        return _marketingWallet;
    }

    function setMarketingWallet(address marketingWallet) public onlyOwner {
        _marketingWallet = marketingWallet;
    }

    function getSalaryWallet() public view returns (address) {
        return _salaryWallet;
    }

    function setSalaryWallet(address salaryWallet) public onlyOwner {
        _salaryWallet = salaryWallet;
    }

    function totalFeesPooled() public view returns (uint256) {
        return _totalFeesPooled;
    }

    function totalBNBLiquidityAddedFromFees() public view returns (uint256) {
        return _totalBNBLiquidityAddedFromFees;
    }

    function isSwapEnabled() public view returns (bool) {
        return _isSwapEnabled;
    }

    function setSwapEnabled(bool isEnabled) public onlyOwner {
        _isSwapEnabled = isEnabled;
    }

    function isFeeEnabled() public view returns (bool) {
        return _isFeeEnabled;
    }

    function setFeeEnabled(bool isEnabled) public onlyOwner {
        _isFeeEnabled = isEnabled;
    }

    function isExcludedFromFees(address addr) public view returns (bool) {
        return _addressesExcludedFromFees[addr];
    }

    function setExcludedFromFees(address addr, bool value) public onlyOwner {
        _addressesExcludedFromFees[addr] = value;
    }

    function activateBuying() public onlyOwner {
        _isBuyingAllowed = true;
    }

    // Ensures that the contract is able to receive BNB
    receive() external payable {}
}

// Implements rewards & burns
contract SpaceDoge is SpaceDogeBase {
    // REWARD CYCLE
    uint256 private _rewardCyclePeriod = 43200; // The duration of the reward cycle (e.g. can claim rewards once 12 hours)
    uint256 private _rewardCycleExtensionThreshold; // If someone sends or receives more than a % of their balance in a transaction, their reward cycle date will increase accordingly
    mapping(address => uint256) private _nextAvailableClaimDate; // The next available reward claim date for each address

    uint256 private _totalBNBLiquidityAddedFromFees; // The total number of BNB added to the pool through fees
    uint256 private _totalBNBClaimed; // The total number of BNB claimed by all addresses
    uint256 private _totalBNBAsSSV2Claimed; // The total number of BNB that was converted to SSV2 and claimed by all addresses
    mapping(address => uint256) private _bnbRewardClaimed; // The amount of BNB claimed by each address
    mapping(address => uint256) private _bnbAsSSV2Claimed; // The amount of BNB converted to SSV2 and claimed by each address
    mapping(address => bool) private _addressesExcludedFromRewards; // The list of addresses excluded from rewards
    mapping(address => mapping(address => bool)) private _rewardClaimApprovals; //Used to allow an address to claim rewards on behalf of someone else
    mapping(address => uint256) private _claimRewardAsTokensPercentage; //Allows users to optionally use a % of the reward pool to buy SSV2 automatically
    uint256 private _minRewardBalance; //5 billion The minimum balance required to be eligible for rewards
    uint256 private _maxClaimAllowed = 100 ether; // Can only claim up to 100 bnb at a time.
    uint256 private _globalRewardDampeningPercentage = 3; // Rewards are reduced by 3% at the start to fill the main BNB pool faster and ensure consistency in rewards
    uint256 private _mainBnbPoolSize = 5000 ether; // Any excess BNB after the main pool will be used as reserves to ensure consistency in rewards
    bool private _rewardAsTokensEnabled; //If enabled, the contract will give out tokens instead of BNB according to the preference of each user
    uint256 private _gradualBurnMagnitude; // The contract can optionally burn tokens (By buying them from reward pool).  This is the magnitude of the burn (1 = 0.01%).
    uint256 private _gradualBurnTimespan = 1 days; //Burn every 1 day by default
    uint256 private _lastBurnDate; //The last burn date

    // AUTO-CLAIM
    bool private _autoClaimEnabled;
    uint256 private _maxGasForAutoClaim = 600000; // The maximum gas to consume for processing the auto-claim queue
    address[] _rewardClaimQueue;
    mapping(address => uint256) _rewardClaimQueueIndices;
    uint256 private _rewardClaimQueueIndex;
    mapping(address => bool) _addressesInRewardClaimQueue; // Mapping between addresses and false/true depending on whether they are queued up for auto-claim or not
    bool private _reimburseAfterSSV2ClaimFailure; // If true, and SSV2 reward claim portion fails, the portion will be given as BNB instead
    bool private _processingQueue; //Flag that indicates whether the queue is currently being processed and sending out rewards
    mapping(address => bool) private _whitelistedExternalProcessors; //Contains a list of addresses that are whitelisted for low-gas queue processing
    uint256 private _sendWeiGasLimit;
    bool private _excludeNonHumansFromRewards = true;

    mapping(address => bool) private _isBlacklisted;
    mapping(address => address) private _claimRewardAsTokens;
    mapping(address => bool) private _isExcludedFromReward;

    bool public isTradingEnabled = true;
    uint256 private _tradingPausedTimestamp;

    event RewardClaimed(
        address recipient,
        uint256 amountBnb,
        uint256 amountTokens,
        uint256 nextAvailableClaimDate
    );
    event Burned(uint256 bnbAmount);
    event BlacklistChange(address indexed holder, bool indexed status);
    event CustomTaxPeriodChange(
        uint256 indexed newValue,
        uint256 indexed oldValue,
        string indexed taxType,
        bytes23 period
    );

    constructor(address routerAddress, address pinkAntiBot_)
        SpaceDogeBase(routerAddress, pinkAntiBot_)
    {
        // Exclude addresses from rewards
        _addressesExcludedFromRewards[BURN_WALLET] = true;
        _addressesExcludedFromRewards[owner()] = true;
        _addressesExcludedFromRewards[address(this)] = true;
        _addressesExcludedFromRewards[address(0)] = true;

        // If someone sends or receives more than 15% of their balance in a transaction, their reward cycle date will increase accordingly
        setRewardCycleExtensionThreshold(15);
    }

    // This function is used to enable all functions of the contract, after the setup of the token sale (e.g. Liquidity) is completed
    function onActivated() internal override {
        super.onActivated();

        setRewardAsTokensEnabled(true);
        setAutoClaimEnabled(true);
        setReimburseAfterSSV2ClaimFailure(true);
        setMinRewardBalance((100000000000 * 10**decimals()) / 1000);
        setGradualBurnMagnitude(1); //Buy tokens using 0.01% of reward pool and burn them
        activateTrading();
        _lastBurnDate = block.timestamp;
    }

    function onBeforeTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        super.onBeforeTransfer(sender, recipient, amount);
        require(!_isBlacklisted[sender], "SSV2: Account is blacklisted");
        require(!_isBlacklisted[recipient], "SSV2: Account is blacklisted");

        if (!isTradingEnabled) {
            require(
                !isPancakeSwapPair(recipient),
                "SSV2: Trading is currently disabled."
            );
            require(
                !isPancakeSwapPair(sender),
                "SSV2: Trading is currently disabled."
            );
        }

        if (!isMarketTransfer(sender, recipient)) {
            return;
        }

        // Extend the reward cycle according to the amount transferred.  This is done so that users do not abuse the cycle (buy before it ends & sell after they claim the reward)
        _nextAvailableClaimDate[recipient] += calculateRewardCycleExtension(
            balanceOf(recipient),
            amount
        );
        _nextAvailableClaimDate[sender] += calculateRewardCycleExtension(
            balanceOf(sender),
            amount
        );

        bool isSelling = isPancakeSwapPair(recipient);
        if (!isSelling) {
            // Wait for a dip, stellar diamond hands
            return;
        }

        // Process gradual burns
        bool burnTriggered = processGradualBurn();

        // Do not burn & process queue in the same transaction
        if (!burnTriggered && isAutoClaimEnabled()) {
            // Trigger auto-claim
            try this.processRewardClaimQueue(_maxGasForAutoClaim) {} catch {}
        }
    }

    function onTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        super.onTransfer(sender, recipient, amount);

        if (!isMarketTransfer(sender, recipient)) {
            return;
        }

        // Update auto-claim queue after balances have been updated
        updateAutoClaimQueue(sender);
        updateAutoClaimQueue(recipient);
    }

    function processGradualBurn() private returns (bool) {
        if (!shouldBurn()) {
            return false;
        }

        uint256 burnAmount = (address(this).balance * _gradualBurnMagnitude) /
            10000;
        doBuyAndBurn(burnAmount);
        return true;
    }

    function updateAutoClaimQueue(address user) private {
        bool isQueued = _addressesInRewardClaimQueue[user];

        if (!isIncludedInRewards(user)) {
            if (isQueued) {
                // Need to dequeue
                uint256 index = _rewardClaimQueueIndices[user];
                address lastUser = _rewardClaimQueue[
                    _rewardClaimQueue.length - 1
                ];

                // Move the last one to this index, and pop it
                _rewardClaimQueueIndices[lastUser] = index;
                _rewardClaimQueue[index] = lastUser;
                _rewardClaimQueue.pop();

                // Clean-up
                delete _rewardClaimQueueIndices[user];
                delete _addressesInRewardClaimQueue[user];
            }
        } else {
            if (!isQueued) {
                // Need to enqueue
                _rewardClaimQueue.push(user);
                _rewardClaimQueueIndices[user] = _rewardClaimQueue.length - 1;
                _addressesInRewardClaimQueue[user] = true;
            }
        }
    }

    function doClaimReward(address user) private returns (bool) {
        require(
            _isExcludedFromReward[user] == false,
            "This user is excluded from reward"
        );
        // Update the next claim date & the total amount claimed
        _nextAvailableClaimDate[user] = block.timestamp + rewardCyclePeriod();

        (
            uint256 claimBnb,
            uint256 claimBnbAsTokens,
            uint256 taxFee
        ) = calculateClaimRewards(user);

        claimBnb = claimBnb - (claimBnb * taxFee) / 100;
        claimBnbAsTokens = claimBnbAsTokens - (claimBnbAsTokens * taxFee) / 100;

        bool tokenClaimSuccess = true;
        // Claim SSV2 tokens
        if (!claimRewardToken(user, claimBnbAsTokens)) {
            // If token claim fails for any reason, award whole portion as BNB
            if (_reimburseAfterSSV2ClaimFailure) {
                claimBnb += claimBnbAsTokens;
            } else {
                tokenClaimSuccess = false;
            }

            claimBnbAsTokens = 0;
        }

        // Claim BNB
        bool bnbClaimSuccess = claimBNB(user, claimBnb);

        // Fire the event in case something was claimed
        if (tokenClaimSuccess || bnbClaimSuccess) {
            emit RewardClaimed(
                user,
                claimBnb,
                claimBnbAsTokens,
                _nextAvailableClaimDate[user]
            );
        }

        return bnbClaimSuccess && tokenClaimSuccess;
    }

    function claimBNB(address user, uint256 bnbAmount) private returns (bool) {
        if (bnbAmount == 0) {
            return true;
        }

        // Send the reward to the caller
        if (_sendWeiGasLimit > 0) {
            (bool sent, ) = user.call{value: bnbAmount, gas: _sendWeiGasLimit}(
                ""
            );
            if (!sent) {
                return false;
            }
        } else {
            (bool sent, ) = user.call{value: bnbAmount}("");
            if (!sent) {
                return false;
            }
        }

        _bnbRewardClaimed[user] += bnbAmount;
        _totalBNBClaimed += bnbAmount;
        return true;
    }

    function claimRewardToken(address user, uint256 bnbAmount)
        private
        returns (bool)
    {
        if (bnbAmount == 0) {
            return true;
        }
        bool success = swapBNBForCustomeTokens(
            claimRewardAsToken(user),
            bnbAmount,
            user
        );
        if (!success) {
            return false;
        }

        _bnbAsSSV2Claimed[user] += bnbAmount;
        _totalBNBAsSSV2Claimed += bnbAmount;
        return true;
    }

    // Processes users in the claim queue and sends out rewards when applicable. The amount of users processed depends on the gas provided, up to 1 cycle through the whole queue.
    // Note: Any external processor can process the claim queue (e.g. even if auto claim is disabled from the contract, an external contract/user/service can process the queue for it
    // and pay the gas cost). "gas" parameter is the maximum amount of gas allowed to be consumed
    function processRewardClaimQueue(uint256 gas) public {
        require(gas > 0, "Gas limit is required");

        uint256 queueLength = _rewardClaimQueue.length;

        if (queueLength == 0) {
            return;
        }

        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();
        uint256 iteration = 0;
        _processingQueue = true;

        // Keep claiming rewards from the list until we either consume all available gas or we finish one cycle
        while (gasUsed < gas && iteration < queueLength) {
            if (_rewardClaimQueueIndex >= queueLength) {
                _rewardClaimQueueIndex = 0;
            }

            address user = _rewardClaimQueue[_rewardClaimQueueIndex];
            if (isRewardReady(user) && isIncludedInRewards(user)) {
                doClaimReward(user);
            }

            uint256 newGasLeft = gasleft();

            if (gasLeft > newGasLeft) {
                uint256 consumedGas = gasLeft - newGasLeft;
                gasUsed += consumedGas;
                gasLeft = newGasLeft;
            }

            iteration++;
            _rewardClaimQueueIndex++;
        }

        _processingQueue = false;
    }

    // Allows a whitelisted external contract/user/service to process the queue and have a portion of the gas costs refunded.
    // This can be used to help with transaction fees and payout response time when/if the queue grows too big for the contract.
    // "gas" parameter is the maximum amount of gas allowed to be used.
    function processRewardClaimQueueAndRefundGas(uint256 gas) external {
        require(
            _whitelistedExternalProcessors[msg.sender],
            "Not whitelisted - use processRewardClaimQueue instead"
        );

        uint256 startGas = gasleft();
        processRewardClaimQueue(gas);
        uint256 gasUsed = startGas - gasleft();

        payable(msg.sender).transfer(gasUsed);
    }

    function isRewardReady(address user) public view returns (bool) {
        return _nextAvailableClaimDate[user] <= block.timestamp;
    }

    function isIncludedInRewards(address user) public view returns (bool) {
        if (_excludeNonHumansFromRewards) {
            if (isContract(user)) {
                return false;
            }
        }

        return
            balanceOf(user) >= _minRewardBalance &&
            !_addressesExcludedFromRewards[user];
    }

    // This function calculates how much (and if) the reward cycle of an address should increase based on its current balance and the amount transferred in a transaction
    function calculateRewardCycleExtension(uint256 balance, uint256 amount)
        public
        view
        returns (uint256)
    {
        uint256 basePeriod = rewardCyclePeriod();

        if (balance == 0) {
            // Receiving $SSV2 on a zero balance address:
            // This means that either the address has never received tokens before (So its current reward date is 0) in which case we need to set its initial value
            // Or the address has transferred all of its tokens in the past and has now received some again, in which case we will set the reward date to a date very far in the future
            return block.timestamp + basePeriod;
        }

        uint256 rate = (amount * 100) / balance;

        // Depending on the % of $SSV2 tokens transferred, relative to the balance, we might need to extend the period
        if (rate >= _rewardCycleExtensionThreshold) {
            // If new balance is X percent higher, then we will extend the reward date by X percent
            uint256 extension = (basePeriod * rate) / 100;

            // Cap to the base period
            if (extension >= basePeriod) {
                extension = basePeriod;
            }

            return extension;
        }

        return 0;
    }

    function calculateClaimRewards(address ofAddress)
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 reward = calculateBNBReward(ofAddress);
        uint256 taxFee = 0;
        if (reward >= 35 * 10**16) {
            taxFee = 20;
        } else if (reward >= 20 * 10**16) {
            taxFee = 10;
        }
        uint256 claimBnbAsTokens = 0;
        if (_rewardAsTokensEnabled) {
            uint256 percentage = _claimRewardAsTokensPercentage[ofAddress];
            claimBnbAsTokens = (reward * percentage) / 100;
        }

        uint256 claimBnb = reward - claimBnbAsTokens;

        return (claimBnb, claimBnbAsTokens, taxFee);
    }

    function calculateBNBReward(address ofAddress)
        public
        view
        returns (uint256)
    {
        uint256 holdersAmount = totalAmountOfTokensHeld();

        uint256 balance = balanceOf(ofAddress);
        uint256 bnbPool = (address(this).balance *
            (100 - _globalRewardDampeningPercentage)) / 100;

        // Limit to main pool size.  The rest of the pool is used as a reserve to improve consistency
        if (bnbPool > _mainBnbPoolSize) {
            bnbPool = _mainBnbPoolSize;
        }

        // If an address is holding X percent of the supply, then it can claim up to X percent of the reward pool
        uint256 reward = (bnbPool * balance) / holdersAmount;

        if (reward > _maxClaimAllowed) {
            reward = _maxClaimAllowed;
        }

        return reward;
    }

    function onPancakeSwapRouterUpdated() internal override {
        _addressesExcludedFromRewards[pancakeSwapRouterAddress()] = true;
        _addressesExcludedFromRewards[pancakeSwapPairAddress()] = true;
    }

    function isMarketTransfer(address sender, address recipient)
        internal
        view
        override
        returns (bool)
    {
        // Not a market transfer when we are burning or sending out rewards
        return
            super.isMarketTransfer(sender, recipient) &&
            !isBurnTransfer(sender, recipient) &&
            !_processingQueue;
    }

    function isBurnTransfer(address sender, address recipient)
        private
        view
        returns (bool)
    {
        return isPancakeSwapPair(sender) && recipient == BURN_WALLET;
    }

    function shouldBurn() public view returns (bool) {
        return
            _gradualBurnMagnitude > 0 &&
            block.timestamp - _lastBurnDate > _gradualBurnTimespan;
    }

    // Up to 1% manual buyback & burn
    function buyAndBurn(uint256 bnbAmount) external onlyOwner {
        require(
            bnbAmount <= address(this).balance / 100,
            "Manual burn amount is too high!"
        );
        require(bnbAmount > 0, "Amount must be greater than zero");

        doBuyAndBurn(bnbAmount);
    }

    function doBuyAndBurn(uint256 bnbAmount) private {
        if (bnbAmount > address(this).balance) {
            bnbAmount = address(this).balance;
        }

        if (bnbAmount == 0) {
            return;
        }

        if (swapBNBForTokens(bnbAmount, BURN_WALLET)) {
            emit Burned(bnbAmount);
        }

        _lastBurnDate = block.timestamp;
    }

    function isContract(address account) public view returns (bool) {
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function totalAmountOfTokensHeld() public view returns (uint256) {
        return
            totalSupply() -
            balanceOf(address(0)) -
            balanceOf(BURN_WALLET) -
            balanceOf(pancakeSwapPairAddress());
    }

    function bnbRewardClaimed(address byAddress) public view returns (uint256) {
        return _bnbRewardClaimed[byAddress];
    }

    function bnbRewardClaimedAsSSV2(address byAddress)
        public
        view
        returns (uint256)
    {
        return _bnbAsSSV2Claimed[byAddress];
    }

    function totalBNBClaimed() public view returns (uint256) {
        return _totalBNBClaimed;
    }

    function totalBNBClaimedAsSSV2() public view returns (uint256) {
        return _totalBNBAsSSV2Claimed;
    }

    function rewardCyclePeriod() public view returns (uint256) {
        return _rewardCyclePeriod;
    }

    function setRewardCyclePeriod(uint256 period) public onlyOwner {
        require(
            period >= 3600 && period <= 86400,
            "RewardCycle must be updated to between 1 and 24 hours"
        );
        _rewardCyclePeriod = period;
    }

    function setRewardCycleExtensionThreshold(uint256 threshold)
        public
        onlyOwner
    {
        _rewardCycleExtensionThreshold = threshold;
    }

    function nextAvailableClaimDate(address ofAddress)
        public
        view
        returns (uint256)
    {
        return _nextAvailableClaimDate[ofAddress];
    }

    function maxClaimAllowed() public view returns (uint256) {
        return _maxClaimAllowed;
    }

    function setMaxClaimAllowed(uint256 value) public onlyOwner {
        require(value > 0, "Value must be greater than zero");
        _maxClaimAllowed = value;
    }

    function minRewardBalance() public view returns (uint256) {
        return _minRewardBalance;
    }

    function setMinRewardBalance(uint256 balance) public onlyOwner {
        _minRewardBalance = balance;
    }

    function maxGasForAutoClaim() public view returns (uint256) {
        return _maxGasForAutoClaim;
    }

    function setMaxGasForAutoClaim(uint256 gas) public onlyOwner {
        _maxGasForAutoClaim = gas;
    }

    function isAutoClaimEnabled() public view returns (bool) {
        return _autoClaimEnabled;
    }

    function setAutoClaimEnabled(bool isEnabled) public onlyOwner {
        _autoClaimEnabled = isEnabled;
    }

    function isExcludedFromRewards(address addr) public view returns (bool) {
        return _addressesExcludedFromRewards[addr];
    }

    // Will be used to exclude unicrypt fees/token vesting addresses from rewards
    function setExcludedFromRewards(address addr, bool isExcluded)
        public
        onlyOwner
    {
        _addressesExcludedFromRewards[addr] = isExcluded;
        updateAutoClaimQueue(addr);
    }

    function globalRewardDampeningPercentage() public view returns (uint256) {
        return _globalRewardDampeningPercentage;
    }

    function setGlobalRewardDampeningPercentage(uint256 value)
        public
        onlyOwner
    {
        require(value <= 90, "Cannot be greater than 90%");
        _globalRewardDampeningPercentage = value;
    }

    function approveClaim(address byAddress, bool isApproved) public {
        require(byAddress != address(0), "Invalid address");
        _rewardClaimApprovals[msg.sender][byAddress] = isApproved;
    }

    function isClaimApproved(address ofAddress, address byAddress)
        public
        view
        returns (bool)
    {
        return _rewardClaimApprovals[ofAddress][byAddress];
    }

    function isRewardAsTokensEnabled() public view returns (bool) {
        return _rewardAsTokensEnabled;
    }

    function setRewardAsTokensEnabled(bool isEnabled) public onlyOwner {
        _rewardAsTokensEnabled = isEnabled;
    }

    function gradualBurnMagnitude() public view returns (uint256) {
        return _gradualBurnMagnitude;
    }

    function setGradualBurnMagnitude(uint256 magnitude) public onlyOwner {
        require(magnitude <= 100, "Must be equal or less to 100");
        _gradualBurnMagnitude = magnitude;
    }

    function gradualBurnTimespan() public view returns (uint256) {
        return _gradualBurnTimespan;
    }

    function setGradualBurnTimespan(uint256 timespan) public onlyOwner {
        require(timespan >= 5 minutes, "Cannot be less than 5 minutes");
        _gradualBurnTimespan = timespan;
    }

    function claimRewardAsTokensPercentage(address ofAddress)
        public
        view
        returns (uint256)
    {
        return _claimRewardAsTokensPercentage[ofAddress];
    }

    function setClaimRewardAsTokensPercentage(uint256 percentage) public {
        require(percentage <= 100, "Cannot exceed 100%");
        _claimRewardAsTokensPercentage[msg.sender] = percentage;
    }

    function mainBnbPoolSize() public view returns (uint256) {
        return _mainBnbPoolSize;
    }

    function setMainBnbPoolSize(uint256 size) public onlyOwner {
        require(size >= 10 ether, "Size is too small");
        _mainBnbPoolSize = size;
    }

    function isInRewardClaimQueue(address addr) public view returns (bool) {
        return _addressesInRewardClaimQueue[addr];
    }

    function reimburseAfterSSV2ClaimFailure() public view returns (bool) {
        return _reimburseAfterSSV2ClaimFailure;
    }

    function setReimburseAfterSSV2ClaimFailure(bool value) public onlyOwner {
        _reimburseAfterSSV2ClaimFailure = value;
    }

    function lastBurnDate() public view returns (uint256) {
        return _lastBurnDate;
    }

    function rewardClaimQueueLength() public view returns (uint256) {
        return _rewardClaimQueue.length;
    }

    function rewardClaimQueueIndex() public view returns (uint256) {
        return _rewardClaimQueueIndex;
    }

    function isWhitelistedExternalProcessor(address addr)
        public
        view
        returns (bool)
    {
        return _whitelistedExternalProcessors[addr];
    }

    function setWhitelistedExternalProcessor(address addr, bool isWhitelisted)
        public
        onlyOwner
    {
        require(addr != address(0), "Invalid address");
        _whitelistedExternalProcessors[addr] = isWhitelisted;
    }

    function setSendWeiGasLimit(uint256 amount) public onlyOwner {
        _sendWeiGasLimit = amount;
    }

    function setExcludeNonHumansFromRewards(bool exclude) public onlyOwner {
        _excludeNonHumansFromRewards = exclude;
    }

    function blacklistAccount(address account) public onlyOwner {
        require(
            !_isBlacklisted[account],
            "SSV2: Account is already blacklisted"
        );
        _isBlacklisted[account] = true;
        emit BlacklistChange(account, true);
    }

    function unBlacklistAccount(address account) public onlyOwner {
        require(_isBlacklisted[account], "SSV2: Account is not blacklisted");
        _isBlacklisted[account] = false;
        emit BlacklistChange(account, false);
    }

    function setExcludedFromReward(address _user, bool _state)
        public
        onlyOwner
    {
        _isExcludedFromReward[_user] = _state;
    }

    function isExcludedFromReward(address _user) public view returns (bool) {
        return _isExcludedFromReward[_user];
    }

    function claimRewardAsToken(address ofAddress)
        public
        view
        returns (address)
    {
        if (_claimRewardAsTokens[ofAddress] != address(0)) {
            return _claimRewardAsTokens[ofAddress];
        } else {
            return address(this);
        }
    }

    function setClaimRewardAsToken(address token) public {
        require(
            token != address(0),
            "Cannot use the zero address as reward address"
        );
        require(
            token != _claimRewardAsTokens[msg.sender],
            "SSV2: Cannot update claimToken to same value"
        );
        IPancakeRouter02 pancakeswapV2RouterAddress = IPancakeRouter02(
            pancakeSwapRouterAddress()
        );
        address pairAddress = IPancakeFactory(
            pancakeswapV2RouterAddress.factory()
        ).getPair(token, pancakeswapV2RouterAddress.WETH());
        require(
            pairAddress != address(0),
            "Cannot use this address as reward address because this address is not added on pancakeswap"
        );
        _claimRewardAsTokens[msg.sender] = token;
    }

    function setClaimRewardAsTokenAndPercentage(
        address token,
        uint256 percentage
    ) public {
        setClaimRewardAsToken(token);
        setClaimRewardAsTokensPercentage(percentage);
    }

    function _getNow() private view returns (uint256) {
        return block.timestamp;
    }

    function activateTrading() public onlyOwner {
        isTradingEnabled = true;
    }

    function deactivateTrading() public onlyOwner {
        isTradingEnabled = false;
        _tradingPausedTimestamp = _getNow();
    }
}