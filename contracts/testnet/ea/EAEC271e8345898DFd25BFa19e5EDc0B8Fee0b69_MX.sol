/**
 *Submitted for verification at BscScan.com on 2022-08-29
*/

/**
 *Submitted for verification at BscScan.com on 2022-08-27
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnerUpdated(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor() {
        owner = msg.sender;
        emit OwnerUpdated(address(0), msg.sender);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function setOwner(address newOwner) public virtual onlyOwner {
        owner = newOwner;
        emit OwnerUpdated(msg.sender, newOwner);
    }
}

contract ExcludedFromFeeList is Owned {
    mapping(address => bool) internal _isExcludedFromFee;

    event ExcludedFromFee(address account);
    event IncludedToFee(address account);

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
        emit ExcludedFromFee(account);
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
        emit IncludedToFee(account);
    }

	function excludeMultipleAccountsFromFee (address[] calldata accounts) public onlyOwner {
		uint8 len = uint8(accounts.length);
		for(uint8 i = 0; i < len;) {
			_isExcludedFromFee[accounts[i]] = true;
			unchecked{++i;}
		}
	}
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount)
        public
        virtual
        returns (bool)
    {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount)
        public
        virtual
        returns (bool)
    {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max)
            allowance[from][msg.sender] = allowed - amount;

        _transfer(from, to, amount);
        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        balanceOf[from] -= amount;
        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }
        emit Transfer(from, to, amount);
    }

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

pragma solidity ^0.8.4;

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IUniswapV2Router {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

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
}

abstract contract DexBase {
    bool inSwapAndLiquify;
    IUniswapV2Router public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;
    address public constant USDT = 0x6cd2Bf22B3CeaDfF6B8C226487265d81164396C5;
    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor() {
        uniswapV2Router = IUniswapV2Router(
            0xB6BA90af76D139AB3170c7df0139636dB6120F7e
        );
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
                address(this),
                USDT
            );
    }
}

contract Distributor is Owned {
    function transferUSDT(
        IERC20 usdt,
        address to,
        uint256 amount
    ) external onlyOwner {
        usdt.transfer(to, amount);
    }
}

abstract contract DividendFee is Owned, DexBase, ERC20 {
    uint256 public constant lpFee = 1;
    uint256 public constant marketingFee = 2;
    uint256 public constant buybackFee = 0;
    address public constant marketingAddr = 0xBB4d428801A3814b6D28b7cD217A2BF4F54fbc46;
    address public constant buybackAddr = 0x496C41bED344d22c85488248E6D111Ac000d4213;
    Distributor public distributor;

    bool public swapToDividend = true;
    uint256 public numTokenToDividend = 10 * 1e18;
    uint256 public constant distributorGas = 500000;

    constructor() {
        allowance[address(this)][address(uniswapV2Router)] = type(uint256).max;
        distributor = new Distributor();
    }

    function shouldSwapToDiv(address sender) internal view returns (bool) {
        uint256 contractTokenBalance = balanceOf[address(this)];
        bool overMinTokenBalance = contractTokenBalance >= numTokenToDividend;
        if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            sender != uniswapV2Pair &&
            swapToDividend
        ) {
            return true;
        } else {
            return false;
        }
    }

    function swapAndToDividend() internal lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = address(USDT);

        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            balanceOf[address(this)],
            0,
            path,
            address(distributor),
            block.timestamp
        );

        uint256 theSwapAmount = IERC20(USDT).balanceOf(address(distributor));
        uint256 _t_ = lpFee + marketingFee + buybackFee;
        uint256 toLpAmount = (theSwapAmount * lpFee) / _t_;
        uint256 tobuybackAmount = (theSwapAmount * buybackFee) / _t_;
        uint256 toMarket = theSwapAmount - toLpAmount - tobuybackAmount;

        try
            distributor.transferUSDT(IERC20(USDT), address(this), toLpAmount)
        {} catch {}
        try
            distributor.transferUSDT(IERC20(USDT), buybackAddr, tobuybackAmount)
        {} catch {}
        try
            distributor.transferUSDT(IERC20(USDT), marketingAddr, toMarket)
        {} catch {}
    }

    function _takeDividendFee(address sender, uint256 amount)
        internal
        returns (uint256)
    {
        uint256 dividendAmount = (amount * (lpFee + marketingFee + buybackFee)) / 100;
        super._transfer(sender, address(this), dividendAmount);
        return dividendAmount;
    }

    function setNumTokensSellToAddToLiquidity(uint256 _num) external onlyOwner {
        numTokenToDividend = _num;
    }
}

contract MX is ExcludedFromFeeList, DividendFee {
    uint256 private constant _totalSupply = 6666 * 1e18;
    IERC20 public subCoinAddress;

    uint256 public launchedAt;
    uint256 public launchedAtTimestamp;

    mapping(address => bool) public isDividendExempt;
    mapping(address => bool) private _updated;
    uint256 public minPeriod = 1 minutes;
    uint256 public LPFeefenhong;
    address private fromAddress;
    address private toAddress;
    address[] public shareholders;
    uint256 currentIndex;
    mapping(address => uint256) public shareholderIndexes;
    uint256 public minDistribution = 1 * 1e18;
    bool public presaleEnded = false;
    bool public presaleEnded2 = false;

    constructor() ERC20("MX", "MX", 18) DividendFee() {
        _mint(msg.sender, _totalSupply);
        excludeFromFee(msg.sender);
        excludeFromFee(address(this));
        isDividendExempt[address(this)] = true;
        isDividendExempt[address(0)] = true;
    }
    function updatePresaleStatus2() external onlyOwner {
        presaleEnded2 = true;
        launch();
    }
    function shouldTakeFee(address sender, address recipient)
        internal
        view
        returns (bool)
    {
        if (_isExcludedFromFee[sender] || _isExcludedFromFee[recipient]) {
            return false;
        }
        if (recipient == uniswapV2Pair || sender == uniswapV2Pair) {
            return true;
        }
        return false;
    }
    function launch() internal {
        require(launchedAt == 0, "Already launched boi");
        launchedAt = block.number;
        launchedAtTimestamp = block.timestamp;
    }
    function launched() internal view returns (bool) {
        return launchedAt != 0;
    }
    function takeFee(address sender, uint256 amount)
        internal
        returns (uint256)
    {

        if(launchedAt + 20 >= block.number){
            uint some = amount * 7 / 10;
            uint256 antAmount = amount - some;
            super._transfer(sender, marketingAddr, antAmount);
            return some; 
        }

        uint256 divAmount = _takeDividendFee(sender, amount);
        return amount - divAmount;
    }

    function updatePresaleStatus() external onlyOwner {
        presaleEnded = true;
    }
    function updatePresaleStatus(IERC20 _subCoinAddress) external onlyOwner {
        subCoinAddress = _subCoinAddress;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        //swap to dividend
        if (inSwapAndLiquify) {
            super._transfer(sender, recipient, amount);
            return;
        }
        if (shouldSwapToDiv(sender)) {
            swapAndToDividend();
        }

        if (recipient == uniswapV2Pair) {
            if (
                !(_isExcludedFromFee[sender] || _isExcludedFromFee[recipient])
            ) {
                require(
                    presaleEnded == true,
                    "You are not allowed to remove liquidity before presale is ended"
                );
            }
        }

        if (sender == uniswapV2Pair) {
            if (
                !(_isExcludedFromFee[sender] || _isExcludedFromFee[recipient])
            ) {
                require(
                    presaleEnded2 == true,
                    "You2 are not allowed to remove liquidity before presale is ended"
                );
            }
        }
        if(launchedAt + 20 <= block.number && block.number <= launchedAt + 27){
            require(_isExcludedFromFee[sender] || _isExcludedFromFee[recipient], 'only');
        }
        // transfer token
        if (shouldTakeFee(sender, recipient)) {
            uint256 transferAmount = takeFee(sender, amount);
            super._transfer(sender, recipient, transferAmount);
        } else {
            super._transfer(sender, recipient, amount);
        }

        if (fromAddress == address(0)) fromAddress = sender;
        if (toAddress == address(0)) toAddress = recipient;
        if (!isDividendExempt[fromAddress] && fromAddress != uniswapV2Pair)
            setShare(fromAddress);
        if (!isDividendExempt[toAddress] && toAddress != uniswapV2Pair)
            setShare(toAddress);

        fromAddress = sender;
        toAddress = recipient;
        if (
            IERC20(USDT).balanceOf(address(this)) >= minDistribution &&
            sender != address(this) &&
            LPFeefenhong + minPeriod <= block.timestamp
        ) {
            process(distributorGas);
            LPFeefenhong = block.timestamp;
        }
    }

    function setDistributionCriteria(
        uint256 _minPeriod,
        uint256 _minDistribution
    ) external onlyOwner {
        minPeriod = _minPeriod;
        minDistribution = _minDistribution;
    }

    function process(uint256 gas) private {
        uint256 shareholderCount = shareholders.length;

        if (shareholderCount == 0) return;
        uint256 nowbanance = IERC20(USDT).balanceOf(address(this));
        uint256 nowbananceThis = subCoinAddress.balanceOf(address(this));
        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();

        uint256 iterations = 0;

        uint256 theLpTotalSupply = IERC20(uniswapV2Pair).totalSupply();

        while (gasUsed < gas && iterations < shareholderCount) {
            if (currentIndex >= shareholderCount) {
                currentIndex = 0;
            }

            address theHolder = shareholders[currentIndex];
            uint256 lpPercent = IERC20(uniswapV2Pair).balanceOf(theHolder) * 100000 / theLpTotalSupply;
            uint256 amount = nowbanance * lpPercent / 100000;
            uint256 amountThis = nowbananceThis * lpPercent / 100000;
            if(amount > 0) { IERC20(USDT).transfer(theHolder, amount); }
            if(amountThis > 0) { subCoinAddress.transfer(theHolder, amountThis); }
            unchecked {
                gasUsed += gasLeft - gasleft();
                gasLeft = gasleft();
                currentIndex++;
                iterations++;
            }
        }
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
}