/**
 *Submitted for verification at BscScan.com on 2022-09-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

library EnumerableSet {
    struct Set {
        bytes32[] _values;
        mapping(bytes32 => uint256) _indexes;
    }

    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    function _remove(Set storage set, bytes32 value) private returns (bool) {
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];
                set._values[toDeleteIndex] = lastValue;
                set._indexes[lastValue] = valueIndex;
            }

            set._values.pop();

            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    function _contains(Set storage set, bytes32 value)
        private
        view
        returns (bool)
    {
        return set._indexes[value] != 0;
    }

    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    function _at(Set storage set, uint256 index)
        private
        view
        returns (bytes32)
    {
        return set._values[index];
    }

    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    function adds(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    function remove(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(AddressSet storage set, uint256 index)
        internal
        view
        returns (address)
    {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    function values(AddressSet storage set)
        internal
        view
        returns (address[] memory)
    {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
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

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

contract ERC20 is Context, IERC20 {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(
            senderBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _createInitialSupply(address account, uint256 amount)
        internal
        virtual
    {
        require(account != address(0), "ERC20: to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() external virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IDexRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
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

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IDexFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IDexPair {
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

interface IDividendDistributor {
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external;
    function setShare(address shareholder, uint256 amount) external;
    function deposit() external payable;
    function process(uint256 gas) external;
}

contract DividendDistributor is IDividendDistributor {
    using SafeMath for uint256;

    address _token;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    IERC20 BUSD = IERC20(0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7);
    address WBNB = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
    IDexRouter router;

    address[] shareholders;
    mapping (address => uint256) shareholderIndexes;
    mapping (address => uint256) shareholderClaims;

    mapping (address => Share) public shares;

    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 10 ** 36;

    uint256 public minPeriod = 1 hours;
    uint256 public minDistribution = 1 * (10 ** 18);

    uint256 currentIndex;

    bool initialized;
    modifier initialization() {
        require(!initialized);
        _;
        initialized = true;
    }

    modifier onlyToken() {
        require(msg.sender == _token); _;
    }

    constructor (address _router) {
        router = _router != address(0)
        ? IDexRouter(_router)
        : IDexRouter(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
        _token = msg.sender;
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external override onlyToken {
        minPeriod = _minPeriod;
        minDistribution = _minDistribution;
    }

    function setShare(address shareholder, uint256 amount) external override onlyToken {
        if(shares[shareholder].amount > 0){
            distributeDividend(shareholder);
        }

        if(amount > 0 && shares[shareholder].amount == 0){
            addShareholder(shareholder);
        }else if(amount == 0 && shares[shareholder].amount > 0){
            removeShareholder(shareholder);
        }

        totalShares = totalShares.sub(shares[shareholder].amount).add(amount);
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
    }

    function deposit() external payable override onlyToken {
        uint256 balanceBefore = BUSD.balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = WBNB;
        path[1] = address(BUSD);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amount = BUSD.balanceOf(address(this)).sub(balanceBefore);

        totalDividends = totalDividends.add(amount);
        dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(amount).div(totalShares));
    }

    function process(uint256 gas) external override onlyToken {
        uint256 shareholderCount = shareholders.length;

        if(shareholderCount == 0) { return; }

        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();

        uint256 iterations = 0;

        while(gasUsed < gas && iterations < shareholderCount) {
            if(currentIndex >= shareholderCount){
                currentIndex = 0;
            }

            if(shouldDistribute(shareholders[currentIndex])){
                distributeDividend(shareholders[currentIndex]);
            }

            gasUsed = gasUsed.add(gasLeft.sub(gasleft()));
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }
    }

    function shouldDistribute(address shareholder) internal view returns (bool) {
        return shareholderClaims[shareholder] + minPeriod < block.timestamp
        && getUnpaidEarnings(shareholder) > minDistribution;
    }

    function distributeDividend(address shareholder) internal {
        if(shares[shareholder].amount == 0){ return; }

        uint256 amount = getUnpaidEarnings(shareholder);
        if(amount > 0){
            totalDistributed = totalDistributed.add(amount);
            BUSD.transfer(shareholder, amount);
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised = shares[shareholder].totalRealised.add(amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
        }
    }

    function claimDividend() external {
        distributeDividend(msg.sender);
    }

    function getUnpaidEarnings(address shareholder) public view returns (uint256) {
        if(shares[shareholder].amount == 0){ return 0; }

        uint256 shareholderTotalDividends = getCumulativeDividends(shares[shareholder].amount);
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;

        if(shareholderTotalDividends <= shareholderTotalExcluded){ return 0; }

        return shareholderTotalDividends.sub(shareholderTotalExcluded);
    }

    function getCumulativeDividends(uint256 share) internal view returns (uint256) {
        return share.mul(dividendsPerShare).div(dividendsPerShareAccuracyFactor);
    }

    function addShareholder(address shareholder) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    function removeShareholder(address shareholder) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[shareholders.length-1];
        shareholderIndexes[shareholders[shareholders.length-1]] = shareholderIndexes[shareholder];
        shareholders.pop();
    }
}

contract Pankie is ERC20, Ownable {
	using SafeMath for uint256;
	address BUSD = 0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7;
    address public WBNB = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
    uint256 public maxBuyAmount;
    uint256 public maxSellAmount;
    uint256 public maxWalletAmount;

    address[] public buyerList;
    uint256 public timeBetweenBuysForJackpot = 5 minutes;
    uint256 public numberOfBuysForJackpot = 5;
    uint256 public minBuyAmount = .1 ether;
    bool public minBuyEnforced = true;
    uint256 public percentForJackpot = 25;
    bool public jackpotEnabled = true;
    uint256 public lastBuyTimestamp;

    IDexRouter public dexRouter;
    address public lpPair;

    bool private swapping;
    uint256 public swapTokensAtAmount;

    address marketingAddress;
    address buybackAddress;

    uint256 public tradingActiveBlock = 0; // 0 means trading is not active
    uint256 public blockForPenaltyEnd;
    mapping(address => bool) public restrictedWallet;
    mapping (address => bool) isDividendExempt;
    uint256 public botsCaught;

    DividendDistributor distributor;
    address public distributorAddress;

    uint256 distributorGas = 500000;

    bool public limitsInEffect = true;
    bool public tradingActive = false;
    bool public swapEnabled = false;

    uint256 public buyTotalFees;
    uint256 public buyMarketingFee;
    uint256 public buyReflectionFee;
    uint256 public buyLiquidityFee;
    uint256 public buyJackpotFee;

    uint256 public originalSellMarketingFee;
    uint256 public originalSellReflectionFee;
    uint256 public originalSellLiquidityFee;
    uint256 public originalSellJackpotFee;    

    uint256 public sellTotalFees;
    uint256 public sellMarketingFee;
    uint256 public sellReflectionFee;
    uint256 public sellLiquidityFee;
    uint256 public sellJackpotFee;

    uint256 public tokensForMarketing;
    uint256 public tokensForReflection;
    uint256 public tokensForLiquidity;
    uint256 public tokensForJackpot;

    uint256 public FEE_DENOMINATOR = 10000;

    /******************/

    // exlcude from fees and max transaction amount
    mapping(address => bool) public _isExcludedFromFees;
    mapping(address => bool) public _isExcludedMaxTransactionAmount;

    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping(address => bool) public automatedMarketMakerPairs;

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event EnabledTrading();

    event EnabledLimits();

    event RemovedLimits();

    event DisabledJeetTaxes();

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event UpdatedMaxBuyAmount(uint256 newAmount);

    event UpdatedMaxSellAmount(uint256 newAmount);

    event UpdatedMaxWalletAmount(uint256 newAmount);

    event UpdatedMarketingAddress(address indexed newWallet);
    event UpdatedBuybackAddress(address indexed newWallet);

    event MaxTransactionExclusion(address _address, bool excluded);

    event BuyBackTriggered(uint256 amount);

    event OwnerForcedSwapBack(uint256 timestamp);

    event CaughtBot(address sniper);

    event TransferForeignToken(address token, uint256 amount);

    event JackpotTriggered(uint256 indexed amount, address indexed wallet);

    constructor(address _dexRouter) payable ERC20("Pankie", "PANK") {
        address newOwner = msg.sender;

        // PCS Main
        dexRouter = IDexRouter(_dexRouter);

        // PCS Test
        //dexRouter = IDexRouter(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);        

        // create pair
        lpPair = IDexFactory(dexRouter.factory()).createPair(
            address(this),
            dexRouter.WETH()
        );

        distributor = new DividendDistributor(_dexRouter);
        distributorAddress = address(distributor);

        _excludeFromMaxTransaction(address(lpPair), true);
        _setAutomatedMarketMakerPair(address(lpPair), true);
        isDividendExempt[lpPair] = true;
        isDividendExempt[address(this)] = true;

        marketingAddress = address(0x34C599d2491d4307fE0015469f55491CDE6A43eE);
        buybackAddress = address(0x34C599d2491d4307fE0015469f55491CDE6A43eE);

        uint256 totalSupply = 1 * 1e9 * 1e18;

        maxBuyAmount = (totalSupply * 4) / 1000; // 0.4%
        maxSellAmount = (totalSupply * 4) / 1000; // 0.4%
        maxWalletAmount = (totalSupply * 55) / 10000; // 0.55%
        swapTokensAtAmount = (totalSupply * 25) / 100000; // 0.025%

        buyMarketingFee = 300;
        buyReflectionFee = 300;
        buyLiquidityFee = 100;
        buyJackpotFee = 500;
        buyTotalFees = buyMarketingFee + buyReflectionFee + buyLiquidityFee + buyJackpotFee;

        originalSellMarketingFee = 300;
        originalSellReflectionFee = 300;
        originalSellLiquidityFee = 100;
        originalSellJackpotFee = 500;

        sellMarketingFee = 400;
        sellReflectionFee = 400;
        sellLiquidityFee = 100;
        sellJackpotFee = 500;
        sellTotalFees = sellMarketingFee + sellReflectionFee + sellLiquidityFee + sellJackpotFee;

        _excludeFromMaxTransaction(newOwner, true);
        _excludeFromMaxTransaction(msg.sender, true);
        _excludeFromMaxTransaction(marketingAddress, true);
        _excludeFromMaxTransaction(address(this), true);
        _excludeFromMaxTransaction(address(0xdead), true);
        _excludeFromMaxTransaction(address(dexRouter), true);

        excludeFromFees(newOwner, true);
        excludeFromFees(msg.sender, true);
        excludeFromFees(marketingAddress, true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);
        excludeFromFees(address(dexRouter), true);

        _createInitialSupply(newOwner, totalSupply); // Tokens for liquidity

        transferOwnership(newOwner);
    }

    receive() external payable {}

    // only use if conducting a presale
    function addPresaleAddressForExclusions(address _presaleAddress)
        external
        onlyOwner
    {
        excludeFromFees(_presaleAddress, true);
        _excludeFromMaxTransaction(_presaleAddress, true);
    }    

    function enableTrading(uint256 blocksForPenalty) external onlyOwner {
        require(blockForPenaltyEnd == 0);
        tradingActive = true;
        swapEnabled = true;
        tradingActiveBlock = block.number;
        blockForPenaltyEnd = tradingActiveBlock + blocksForPenalty;
        lastBuyTimestamp = block.timestamp;
        emit EnabledTrading();
    }

    // remove limits after token is stable
    function removeLimits() external onlyOwner {
        limitsInEffect = false;
        emit RemovedLimits();
    }

    function enableLimits() external onlyOwner {
        limitsInEffect = true;
        emit EnabledLimits();
    }

    function setJackpotEnabled(bool enabled) external onlyOwner {
        jackpotEnabled = enabled;
    }

    function manageRestrictedWallets(
        address[] calldata wallets,
        bool restricted
    ) external onlyOwner {
        for (uint256 i = 0; i < wallets.length; i++) {
            restrictedWallet[wallets[i]] = restricted;
        }
    }

    function updateMaxBuyAmount(uint256 newNum) external onlyOwner {
        require(newNum >= ((totalSupply() * 25) / 10000) / (10**decimals()));
        maxBuyAmount = newNum * (10**decimals());
        emit UpdatedMaxBuyAmount(maxBuyAmount);
    }

    function updateMaxSellAmount(uint256 newNum) external onlyOwner {
        require(newNum >= ((totalSupply() * 25) / 10000) / (10**decimals()));
        maxSellAmount = newNum * (10**decimals());
        emit UpdatedMaxSellAmount(maxSellAmount);
    }

    function updateMaxWallet(uint256 newNum) external onlyOwner {
        require(newNum >= ((totalSupply() * 25) / 10000) / (10**decimals()));
        maxWalletAmount = newNum * (10**decimals());
        emit UpdatedMaxWalletAmount(maxWalletAmount);
    }

    // change the minimum amount of tokens to sell from fees
    function updateSwapTokensAtAmount(uint256 newAmount) external onlyOwner {
        require(newAmount >= (totalSupply() * 1) / 100000);
        require(newAmount <= (totalSupply() * 1) / 1000);
        swapTokensAtAmount = newAmount;
    }

    function _excludeFromMaxTransaction(address updAds, bool isExcluded)
        private
    {
        _isExcludedMaxTransactionAmount[updAds] = isExcluded;
        emit MaxTransactionExclusion(updAds, isExcluded);
    }

    function setIsDividendExempt(address holder, bool exempt) external onlyOwner {
        require(holder != address(this) && holder != lpPair);
        isDividendExempt[holder] = exempt;
        if(exempt){
            distributor.setShare(holder, 0);
        }else{
            distributor.setShare(holder, balanceOf(holder));
        }
    }

    function airdropToWallets(
        address[] memory wallets,
        uint256[] memory amountsInTokens
    ) external onlyOwner {
        require(wallets.length == amountsInTokens.length);
        require(wallets.length < 600); // allows for airdrop + launch at the same exact time, reducing delays and reducing sniper input.
        for (uint256 i = 0; i < wallets.length; i++) {
            super._transfer(msg.sender, wallets[i], amountsInTokens[i]);
        }
    }

    function setNumberOfBuysForJackpot(uint256 num) external onlyOwner {
        require(
            num >= 2 && num <= 100,
            "Must keep number of buys between 2 and 100"
        );
        numberOfBuysForJackpot = num;
    }

    function excludeFromMaxTransaction(address updAds, bool isEx)
        external
        onlyOwner
    {
        if (!isEx) {
            require(
                updAds != lpPair,
                "Cannot remove uniswap pair from max txn"
            );
        }
        _isExcludedMaxTransactionAmount[updAds] = isEx;
    }

    function setAutomatedMarketMakerPair(address pair, bool value)
        external
        onlyOwner
    {
        require(
            pair != lpPair,
            "The pair cannot be removed from automatedMarketMakerPairs"
        );

        _setAutomatedMarketMakerPair(pair, value);
        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;

        _excludeFromMaxTransaction(pair, value);

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function updateBuyFees(
        uint256 _marketingFee,
        uint256 _reflectionFee,
        uint256 _liquidityFee,
        uint256 _jackpotFee
    ) external onlyOwner {
        buyMarketingFee = _marketingFee;
        buyReflectionFee = _reflectionFee;
        buyLiquidityFee = _liquidityFee;
        buyJackpotFee = _jackpotFee;
        buyTotalFees = buyMarketingFee + buyReflectionFee + buyLiquidityFee + buyJackpotFee;
        require(buyTotalFees <= 1500, "Must keep fees at 15% or less");
    }

    function updateSellFees(
        uint256 _marketingFee,
        uint256 _reflectionFee,
        uint256 _liquidityFee,
        uint256 _jackpotFee
    ) external onlyOwner {
        sellMarketingFee = _marketingFee;
        sellReflectionFee = _reflectionFee;
        sellLiquidityFee = _liquidityFee;
        sellJackpotFee = _jackpotFee;
        sellTotalFees = sellMarketingFee + sellReflectionFee + sellLiquidityFee + sellJackpotFee;
        require(sellTotalFees <= 2000, "Must keep fees at 20% or less");
    }

    function disableJeetTaxes() external onlyOwner {
        sellMarketingFee = originalSellMarketingFee;
        sellReflectionFee = originalSellReflectionFee;
        sellLiquidityFee = originalSellLiquidityFee;
        sellJackpotFee = originalSellJackpotFee;
        sellTotalFees = sellMarketingFee + sellReflectionFee + sellLiquidityFee + sellJackpotFee;
        
        emit DisabledJeetTaxes();
    }    

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "ERC20: transfer must be greater than 0");

        if (!tradingActive) {
            require(
                _isExcludedFromFees[from] || _isExcludedFromFees[to],
                "Trading is not active."
            );
        }

        if (!earlyBuyPenaltyInEffect() && blockForPenaltyEnd > 0) {
            require(
                !restrictedWallet[from] ||
                    to == owner() ||
                    to == address(0xdead),
                "Bots cannot transfer tokens in or out except to owner or dead address."
            );
        }

        if (limitsInEffect) {
            if (
                from != owner() &&
                to != owner() &&
                to != address(0) &&
                to != address(0xdead) &&
                !_isExcludedFromFees[from] &&
                !_isExcludedFromFees[to]
            ) {
                //when buy
                if (
                    automatedMarketMakerPairs[from] &&
                    !_isExcludedMaxTransactionAmount[to]
                ) {
                    require(amount <= maxBuyAmount);
                    require(amount + balanceOf(to) <= maxWalletAmount);
                }
                //when sell
                else if (
                    automatedMarketMakerPairs[to] &&
                    !_isExcludedMaxTransactionAmount[from]
                ) {
                    require(amount <= maxSellAmount);
                } else if (!_isExcludedMaxTransactionAmount[to]) {
                    require(amount + balanceOf(to) <= maxWalletAmount);
                }
            }
        }

        uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if (
            canSwap &&
            swapEnabled &&
            !swapping &&
            !automatedMarketMakerPairs[from] &&
            !_isExcludedFromFees[from] &&
            !_isExcludedFromFees[to]
        ) {
            swapping = true;
            swapBack();
            swapping = false;
        }

        bool takeFee = true;
        // if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        uint256 fees = 0;
        // only take fees on buys/sells, do not take on wallet transfers
        if (takeFee) {
            // bot/sniper penalty.
            if (
                earlyBuyPenaltyInEffect() &&
                automatedMarketMakerPairs[from] &&
                !automatedMarketMakerPairs[to]
            ) {
                if (!restrictedWallet[to]) {
                    restrictedWallet[to] = true;
                    botsCaught += 1;
                    emit CaughtBot(to);
                }

                if (buyTotalFees > 0) {
                    fees = (amount * (buyTotalFees)) / FEE_DENOMINATOR;
                    tokensForLiquidity +=
                        (fees * buyLiquidityFee) /
                        buyTotalFees;
                    tokensForMarketing +=
                        (fees * buyMarketingFee) /
                        buyTotalFees;
                    tokensForReflection +=
                        (fees * buyReflectionFee) /
                        buyTotalFees;
                    tokensForJackpot += (fees * buyJackpotFee) / buyTotalFees;
                }
            }
            // on sell
            else if (automatedMarketMakerPairs[to] && sellTotalFees > 0) {
                fees = (amount * (sellTotalFees)) / FEE_DENOMINATOR;
                tokensForLiquidity += (fees * sellLiquidityFee) / sellTotalFees;
                tokensForMarketing +=
                    (fees * sellMarketingFee) /
                    sellTotalFees;
                tokensForReflection +=
                    (fees * sellReflectionFee) /
                    sellTotalFees;
                tokensForJackpot += (fees * sellJackpotFee) / sellTotalFees;
            }
            // on buy
            else if (automatedMarketMakerPairs[from]) {
                if (jackpotEnabled) {
                    if (
                        block.timestamp >=
                        lastBuyTimestamp + timeBetweenBuysForJackpot &&
                        address(this).balance > 0.1 ether &&
                        buyerList.length >= numberOfBuysForJackpot
                    ) {
                        payoutRewards(to);
                    } else {
                        gasBurn();
                    }
                }

                if (!minBuyEnforced || amount > getPurchaseAmount()) {
                    buyerList.push(to);
                }

                lastBuyTimestamp = block.timestamp;

                if (buyTotalFees > 0) {
                    fees = (amount * (buyTotalFees)) / FEE_DENOMINATOR;
                    tokensForLiquidity +=
                        (fees * buyLiquidityFee) /
                        buyTotalFees;
                    tokensForMarketing +=
                        (fees * buyMarketingFee) /
                        buyTotalFees;
                    tokensForReflection +=
                        (fees * buyReflectionFee) /
                        buyTotalFees;
                    tokensForJackpot += (fees * buyJackpotFee) / buyTotalFees;
                }
            }

            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }

            
        }
           amount -= fees;
           
        if(!isDividendExempt[from]){ try distributor.setShare(from, balanceOf(from)) {} catch {} }
        if(!isDividendExempt[to]){ try distributor.setShare(to, balanceOf(to)) {} catch {} }

        try distributor.process(distributorGas) {} catch {}

        super._transfer(from, to, amount);
    }

    function earlyBuyPenaltyInEffect() public view returns (bool) {
        return block.number < blockForPenaltyEnd;
    }

    function getPurchaseAmount() public view returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = dexRouter.WETH();
        path[1] = address(this);

        uint256[] memory amounts = new uint256[](2);
        amounts = dexRouter.getAmountsOut(minBuyAmount, path);
        return amounts[1];
    }

    // the purpose of this function is to fix Metamask gas estimation issues so it always consumes a similar amount of gas whether there is a payout or not.
    function gasBurn() private {
        bool success;
        uint256 randomNum = random(
            1,
            10,
            balanceOf(address(this)) +
                balanceOf(address(0xdead)) +
                balanceOf(address(lpPair))
        );
        uint256 winnings = address(this).balance / 2;
        address winner = address(this);
        winnings = 0;
        randomNum = 0;
        (success, ) = address(winner).call{value: winnings}("");
    }

    function payoutRewards(address to) private {
        bool success;
        // get a pseudo random winner
        uint256 randomNum = random(
            1,
            numberOfBuysForJackpot,
            balanceOf(address(this)) +
                balanceOf(address(0xdead)) +
                balanceOf(address(to))
        );
        address winner = buyerList[buyerList.length - randomNum];
        uint256 winnings = (address(this).balance * percentForJackpot) / 100;
        (success, ) = address(winner).call{value: winnings}("");
        if (success) {
            emit JackpotTriggered(winnings, winner);
        }
        delete buyerList;
    }

    function random(
        uint256 from,
        uint256 to,
        uint256 salty
    ) private view returns (uint256) {
        uint256 seed = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp +
                        block.difficulty +
                        ((
                            uint256(keccak256(abi.encodePacked(block.coinbase)))
                        ) / (block.timestamp)) +
                        block.gaslimit +
                        ((uint256(keccak256(abi.encodePacked(msg.sender)))) /
                            (block.timestamp)) +
                        block.number +
                        salty
                )
            )
        );
        return (seed % (to - from)) + from;
    }

    function updateJackpotTimeCooldown(uint256 timeInMinutes)
        external
        onlyOwner
    {
        require(timeInMinutes > 0 && timeInMinutes <= 360);
        timeBetweenBuysForJackpot = timeInMinutes * 1 minutes;
    }

    function updatePercentForJackpot(uint256 percent) external onlyOwner {
        require(percent >= 10 && percent <= 100);
        percentForJackpot = percent;
    }

    function updateMinBuyToTriggerReward(uint256 minBuy) external onlyOwner {
        minBuyAmount = minBuy;
    }

    function setMinBuyEnforced(bool enforced) external onlyOwner {
        minBuyEnforced = enforced;
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external onlyOwner {
        distributor.setDistributionCriteria(_minPeriod, _minDistribution);
    }

    function setDistributorSettings(uint256 gas) external onlyOwner {
         require(gas < 750000);
        distributorGas = gas;
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = dexRouter.WETH();

        _approve(address(this), address(dexRouter), tokenAmount);

        // make the swap
        dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(dexRouter), tokenAmount);

        // add the liquidity
        dexRouter.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(0xdead),
            block.timestamp
        );
    }

    function swapBack() private {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = tokensForLiquidity +
            tokensForMarketing + tokensForReflection +
            tokensForJackpot;

        if (contractBalance == 0 || totalTokensToSwap == 0) {
            return;
        }

        if (contractBalance > swapTokensAtAmount * 100) {
            contractBalance = swapTokensAtAmount * 100;
        }

        bool success;

        // Halve the amount of liquidity tokens
        uint256 liquidityTokens = (contractBalance * tokensForLiquidity) /
            totalTokensToSwap /
            2;

        uint256 initialBalance = address(this).balance;
        swapTokensForEth(contractBalance - liquidityTokens);

        uint256 ethBalance = address(this).balance - initialBalance;
        uint256 ethForLiquidity = ethBalance;

        uint256 ethForMarketing = (ethBalance * tokensForMarketing) /
            (totalTokensToSwap - (tokensForLiquidity / 2));
        uint256 ethForReflection = (ethBalance * tokensForReflection) /
            (totalTokensToSwap - (tokensForLiquidity / 2));
        uint256 ethForJackpot = (ethBalance * tokensForJackpot) /
            (totalTokensToSwap - (tokensForLiquidity / 2));

        ethForLiquidity -= ethForMarketing + ethForReflection + ethForJackpot;

        tokensForLiquidity = 0;
        tokensForMarketing = 0;
        tokensForReflection = 0;
        tokensForJackpot = 0;

        if (liquidityTokens > 0 && ethForLiquidity > 0) {
            addLiquidity(liquidityTokens, ethForLiquidity);
        }

        if (ethForMarketing > 0) {
            (success, ) = address(marketingAddress).call{
                value: ethForMarketing
            }("");
        }

        if (ethForReflection > 0) {
            try distributor.deposit{value: ethForReflection}() {} catch {}
        }
        // remaining ETH stays for Jackpot
    }

    function transferForeignToken(address _token, address _to)
        external
        onlyOwner
        returns (bool _sent)
    {
        require(_token != address(0));
        require(_token != address(this));
        uint256 _contractBalance = IERC20(_token).balanceOf(address(this));
        _sent = IERC20(_token).transfer(_to, _contractBalance);
        emit TransferForeignToken(_token, _contractBalance);
    }

    // withdraw ETH
    function withdrawStuckETH() external onlyOwner {
        bool success;
        (success, ) = address(owner()).call{value: address(this).balance}("");
    }

    function setMarketingAddress(address _marketingAddress)
        external
        onlyOwner
    {
        require(_marketingAddress != address(0));
        marketingAddress = payable(_marketingAddress);
    }

    // force Swap back if slippage issues.
    function forceSwapBack() external onlyOwner {
        require(
            balanceOf(address(this)) >= swapTokensAtAmount,
            "Can only swap when token amount is at or higher than restriction"
        );
        swapping = true;
        swapBack();
        swapping = false;
        emit OwnerForcedSwapBack(block.timestamp);
    }

    function getBuyerListLength() external view returns (uint256) {
        return buyerList.length;
    }
}