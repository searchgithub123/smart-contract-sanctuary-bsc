/**
 *Submitted for verification at BscScan.com on 2022-11-06
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * SAFEMATH LIBRARY
 */
library SafeMath {
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

interface IBEP20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function getOwner() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address _owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

abstract contract Auth {
    address internal owner;
    mapping(address => bool) internal authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }

    /**
     * Function modifier to require caller to be contract owner
     */
    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER");
        _;
    }

    /**
     * Function modifier to require caller to be authorized
     */
    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED");
        _;
    }

    /**
     * Authorize address. Owner only
     */
    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
    }

    /**
     * Remove address' authorization. Owner only
     */
    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
    }

    /**
     * Check if address is owner
     */
    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    /**
     * Return address' authorization status
     */
    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    /**
     * Transfer ownership to new address. Caller must be owner. Leaves old owner authorized
     */
    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IDEXRouter {
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

contract TechStop is IBEP20, Auth {
    using SafeMath for uint256;

    uint256 public constant MASK = type(uint128).max;
    address public WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address constant ZERO = 0x0000000000000000000000000000000000000000;
    address constant DEAD_NON_CHECKSUM =
        0x000000000000000000000000000000000000dEaD;
    address constant _dexRouter = 0x10ED43C718714eb63d5aA57B78B54704E256024E;

    string constant _name = "TechStop";
    string constant _symbol = "$$TS";
    uint8 constant _decimals = 9;

    uint256 _totalSupply = 1_000_000 * (10**_decimals);

    uint256 public _maxWalletHoldingAmount = _totalSupply.mul(2).div(100);

    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;

    mapping(address => bool) isFeeExempt;

    mapping(address => bool) isWalletHoldingLimitExempt;
    mapping(address => bool) private _isAllowed;
    mapping(address => bool) private _isNFTHolder;

    uint256 internal liquidityFee = 3;
    uint256 internal MarketingFee = 12;
    uint256 internal totalFee = 15;

    uint256 internal sellliquidityFee = 3;
    uint256 internal sellMarketingFee = 12;

    uint256 internal feeDenominator = 100;

    address public autoLiquidityReceiver;
    address internal MarketingFeeReceiver =
        address(0x9d06d5EA43cCbAca88f7119C1Ba8e58E05d02c7B);

    uint256 targetLiquidity = 25;
    uint256 targetLiquidityDenominator = 100;

    IDEXRouter public router;
    address public pair;

    uint256 public LaunchedAt = 0;
    bool public tradingStatus = false;
    bool public swapEnabled = true;
    uint256 public swapThreshold = _totalSupply / 1000;
    bool inSwap;
    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    event UpdatedMaxTxLimit(uint256 maxTxLimit);
    event UpdatedMaxWalletLimit(uint256 maxWalletLimit);
    event UpdatedThresholdValues(bool status, uint256 threshold);
    event UpdatedTaxFeePercentages(uint256 taxFee);
    event UpdatedBuyTaxFeePercentages(uint256 buyTaxFee);
    event UpdatedSellTaxFeePercentages(uint256 sellTaxFee);

    constructor() Auth(address(0x44BCfC23c3D66CEB5C3e6b0FBE76171a3ec464E4)) {
        router = IDEXRouter(_dexRouter);
        pair = IDEXFactory(router.factory()).createPair(WBNB, address(this));
        _allowances[address(this)][address(router)] = _totalSupply;
        WBNB = router.WETH();

        isFeeExempt[address(0x9d06d5EA43cCbAca88f7119C1Ba8e58E05d02c7B)] = true;
        isFeeExempt[address(0x44BCfC23c3D66CEB5C3e6b0FBE76171a3ec464E4)] = true;
        autoLiquidityReceiver = address(
            0x44BCfC23c3D66CEB5C3e6b0FBE76171a3ec464E4
        );
        isWalletHoldingLimitExempt[pair] = true;
        isWalletHoldingLimitExempt[address(0x44BCfC23c3D66CEB5C3e6b0FBE76171a3ec464E4)] = true;
        isWalletHoldingLimitExempt[address(0x9d06d5EA43cCbAca88f7119C1Ba8e58E05d02c7B)] = true;
        _isAllowed[0x9d06d5EA43cCbAca88f7119C1Ba8e58E05d02c7B] = true;
        _isAllowed[0x44BCfC23c3D66CEB5C3e6b0FBE76171a3ec464E4] = true;
        _isAllowed[address(this)] = true;

        approve(_dexRouter, _totalSupply);
        approve(address(pair), _totalSupply);
        _balances[
            address(0x44BCfC23c3D66CEB5C3e6b0FBE76171a3ec464E4)
        ] = _totalSupply;
        emit Transfer(
            address(0),
            address(0x44BCfC23c3D66CEB5C3e6b0FBE76171a3ec464E4),
            _totalSupply
        );
    }

    receive() external payable {}

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function decimals() external pure override returns (uint8) {
        return _decimals;
    }

    function symbol() external pure override returns (string memory) {
        return _symbol;
    }

    function name() external pure override returns (string memory) {
        return _name;
    }

    function getOwner() external view override returns (address) {
        return owner;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function allowance(address holder, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowances[holder][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, _totalSupply);
    }

    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        if (_allowances[sender][msg.sender] != _totalSupply) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender]
                .sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        if (!_isAllowed[sender] && sender != owner && recipient != owner) {
            if (pair == sender && _isAllowed[recipient]) {} else {
                require(tradingStatus, "trading is off");
            }
        }
        if (inSwap) {
            return _basicTransfer(sender, recipient, amount);
        }

        checkWalletHoldingLimit(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(
            amount,
            "Insufficient Balance"
        );

        uint256 amountReceived = shouldNotTakeFee(sender, recipient)
            ? amount
            : takeFee(sender, recipient, amount);

        if (shouldSwapBack()) {
            swapBack();
        }

        _balances[recipient] = _balances[recipient].add(amountReceived);

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }

    function shouldNotTakeFee(address sender, address recipient)
        internal
        view
        returns (bool)
    {
        return isFeeExempt[sender] || isFeeExempt[recipient];
    }

    function _basicTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(
            amount,
            "Insufficient Balance"
        );
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function checkWalletHoldingLimit(
        address sender,
        address recipient,
        uint256 amount
    ) internal view {
        if (
            !isWalletHoldingLimitExempt[recipient] &&
            sender != owner &&
            recipient != owner
        ) {
            require(
                balanceOf(recipient).add(amount) <= _maxWalletHoldingAmount,
                "Wallet holding Limit Exceeded"
            );
        }
    }

    function setWalletHoldingLimitExempt(address holder, bool exempt)
        external
        authorized
    {
        isWalletHoldingLimitExempt[holder] = exempt;
    }

    function getTotalFee(bool selling, address receiver)
        internal
        returns (uint256)
    {
        if (selling) {
            totalFee = sellliquidityFee.add(sellMarketingFee);
            return totalFee;
        }
        if (!selling) {
            if (_isNFTHolder[receiver]) {
                return 0;
            } else {
                totalFee = liquidityFee.add(MarketingFee);
                return totalFee;
            }
        }
        return liquidityFee.add(MarketingFee);
    }

    function takeFee(
        address sender,
        address receiver,
        uint256 amount
    ) internal returns (uint256) {
        uint256 feeAmount = amount
            .mul(getTotalFee(receiver == pair, receiver))
            .div(feeDenominator);
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        return amount.sub(feeAmount);
    }

    function shouldSwapBack() internal view returns (bool) {
        return
            msg.sender != pair &&
            !inSwap &&
            swapEnabled &&
            _balances[address(this)] >= swapThreshold;
    }

    function swapBack() internal swapping {
        uint256 dynamicLiquidityFee = isOverLiquified(
            targetLiquidity,
            targetLiquidityDenominator
        )
            ? 0
            : sellliquidityFee;
        uint256 amountToLiquify = swapThreshold
            .mul(dynamicLiquidityFee)
            .div(totalFee)
            .div(2);
        uint256 amountToSwap = swapThreshold.sub(amountToLiquify);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WBNB;
        uint256 balanceBefore = address(this).balance;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountBNB = address(this).balance.sub(balanceBefore);

        uint256 totalBNBFee = totalFee.sub(dynamicLiquidityFee.div(2));

        uint256 amountBNBLiquidity = amountBNB
            .mul(dynamicLiquidityFee)
            .div(totalBNBFee)
            .div(2);

        uint256 amountBNBMarketing = amountBNB.mul(sellMarketingFee).div(
            totalBNBFee
        );
        if (amountBNBMarketing > 0) {
            payable(MarketingFeeReceiver).transfer(amountBNBMarketing);
        }

        if (amountToLiquify > 0) {
            router.addLiquidityETH{value: amountBNBLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                autoLiquidityReceiver,
                block.timestamp
            );
            emit AutoLiquify(amountBNBLiquidity, amountToLiquify);
        }
        if (address(this).balance > 0) {
            payable(MarketingFeeReceiver).transfer(address(this).balance);
        }
    }

    function setAllowToTradeStatus(address account, bool status)
        external
        authorized
    {
        _isAllowed[account] = status;
    }

    function isNFTHolder(address account) external view returns (bool) {
        return _isNFTHolder[account];
    }

    function setNFTHolderStatus(address account, bool status)
        external
        authorized
    {
        _isNFTHolder[account] = status;
    }

    function setMultiAllowedToTradeAddressesStatus(
        address[] calldata addresses,
        bool status
    ) external authorized {
        require(addresses.length < 20, "You can't set more than 20 addresses");
        for (uint256 i = 0; i < addresses.length; i++) {
            _isAllowed[addresses[i]] = status;
        }
    }

    function setMultiNFTHolderAddressesStatus(address[] calldata addresses, bool status)
        external
        authorized
    {
        require(addresses.length < 20, "You can't set more than 20 addresses");
        for (uint256 i = 0; i < addresses.length; i++) {
            _isNFTHolder[addresses[i]] = status;
        }
    }

    function isTradingAllowed(address account) external view returns (bool) {
        return _isAllowed[account];
    }

    function setWalletHoldingLimit(uint256 amount) external authorized {
        _maxWalletHoldingAmount = amount * 10**_decimals;

        emit UpdatedMaxWalletLimit(_maxWalletHoldingAmount);
    }

    function PublicLaunch() external authorized {
        require(LaunchedAt == 0, "Already Launched");
        tradingStatus = true;
        LaunchedAt = block.timestamp;
    }

    function setIsFeeExempt(address holder, bool exempt) external authorized {
        isFeeExempt[holder] = exempt;
    }

    function setBuyFees(
        uint256 _buyliquidityFee,
        uint256 _buyMarketingFee,
        uint256 _feeDenominator
    ) external authorized {
        liquidityFee = _buyliquidityFee;
        MarketingFee = _buyMarketingFee;
        feeDenominator = _feeDenominator;
        emit UpdatedBuyTaxFeePercentages(totalFee);
    }

    function setSellFees(
        uint256 _SellliquidityFee,
        uint256 _SellMarketingFee,
        uint256 _feeDenominator
    ) external authorized {
        sellliquidityFee = _SellliquidityFee;
        sellMarketingFee = _SellMarketingFee;
        feeDenominator = _feeDenominator;
        emit UpdatedSellTaxFeePercentages(totalFee);
    }

    function setFeeReceivers(
        address _autoLiquidityReceiver,
        address _MarketingFeeReceiver
    ) external authorized {
        autoLiquidityReceiver = _autoLiquidityReceiver;
        MarketingFeeReceiver = _MarketingFeeReceiver;
    }

    function setSwapBackSettings(bool _enabled, uint256 _amount)
        external
        authorized
    {
        swapEnabled = _enabled;
        swapThreshold = _amount;
        emit UpdatedThresholdValues(swapEnabled, swapThreshold);
    }

    function setTargetLiquidity(uint256 _target, uint256 _denominator)
        external
        authorized
    {
        targetLiquidity = _target;
        targetLiquidityDenominator = _denominator;
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }

    function getLiquidityBacking(uint256 accuracy)
        public
        view
        returns (uint256)
    {
        return accuracy.mul(balanceOf(pair).mul(2)).div(getCirculatingSupply());
    }

    function isOverLiquified(uint256 target, uint256 accuracy)
        public
        view
        returns (bool)
    {
        return getLiquidityBacking(accuracy) > target;
    }

    event AutoLiquify(uint256 amountBNB, uint256 amountBOG);
}