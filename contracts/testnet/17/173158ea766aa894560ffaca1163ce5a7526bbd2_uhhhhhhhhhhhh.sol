/**
 *Submitted for verification at BscScan.com on 2022-12-16
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;





interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Auth {
    address internal owner;
    mapping (address => bool) internal authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }

    /**
     * Function modifier to require caller to be contract owner
     */
    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }

    /**
     * Function modifier to require caller to be authorized
     */
    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED"); _;
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
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDEXRouter {
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

interface IDividendDistributor {
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external;
    function setShare(address shareholder, uint256 amount) external;
    function deposit() external payable;
    function process(uint256 gas) external;
}
// DOGE DIVIDEND DISTRIBUTOR
contract DividendDistributor is IDividendDistributor {
    using SafeMath for uint256;

    address _token;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    IBEP20 DOGE = IBEP20(0xbA2aE424d960c26247Dd6c32edC70B295c744C43);
    address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    IDEXRouter router;

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
        ? IDEXRouter(_router)
        : IDEXRouter(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);
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
        uint256 balanceBefore = DOGE.balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = WBNB;
        path[1] = address(DOGE);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amount = DOGE.balanceOf(address(this)).sub(balanceBefore);

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
            DOGE.transfer(shareholder, amount);
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
// SHIB DIVIDEND DISTRIBUTOR
contract DividendDistributor1 is IDividendDistributor {
    using SafeMath for uint256;

    address _token;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    IBEP20 SHIB = IBEP20(0x2859e4544C4bB03966803b044A93563Bd2D0DD4D);
    address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    IDEXRouter router;

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
        ? IDEXRouter(_router)
        : IDEXRouter(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);
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
        uint256 balanceBefore = SHIB.balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = WBNB;
        path[1] = address(SHIB);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amount = SHIB.balanceOf(address(this)).sub(balanceBefore);

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
            SHIB.transfer(shareholder, amount);
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
 // FLOKI DIVIDEND DISTRIBUTOR
 contract DividendDistributor2 is IDividendDistributor {
    using SafeMath for uint256;

    address _token;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    IBEP20 FLOKI = IBEP20(0xfb5B838b6cfEEdC2873aB27866079AC55363D37E);
    address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    IDEXRouter router;

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
        ? IDEXRouter(_router)
        : IDEXRouter(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);
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
        uint256 balanceBefore = FLOKI.balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = WBNB;
        path[1] = address(FLOKI);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amount = FLOKI.balanceOf(address(this)).sub(balanceBefore);

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
          FLOKI.transfer(shareholder, amount);
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
// BABYDOGE DIVIDEND DISTRIBUTOR
 contract DividendDistributor3 is IDividendDistributor {
    using SafeMath for uint256;

    address _token;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    IBEP20 BABYDOGE = IBEP20(0xc748673057861a797275CD8A068AbB95A902e8de);
    address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    IDEXRouter router;

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
        ? IDEXRouter(_router)
        : IDEXRouter(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);
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
        uint256 balanceBefore = BABYDOGE.balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = WBNB;
        path[1] = address(BABYDOGE);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amount = BABYDOGE.balanceOf(address(this)).sub(balanceBefore);

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
           BABYDOGE.transfer(shareholder, amount);
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
 // BUSD DIVIDEND DISTRIBUTOR
 contract DividendDistributor4 is IDividendDistributor {
    using SafeMath for uint256;

    address _token;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    IBEP20 BUSD = IBEP20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
    address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    IDEXRouter router;

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
        ? IDEXRouter(_router)
        : IDEXRouter(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);
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
 // USDT DIVIDEND DISTRIBUTOR
 contract DividendDistributor5 is IDividendDistributor {
    using SafeMath for uint256;

    address _token;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    IBEP20 USDT = IBEP20(0x55d398326f99059fF775485246999027B3197955);
    address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    IDEXRouter router;

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
        ? IDEXRouter(_router)
        : IDEXRouter(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);
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
        uint256 balanceBefore = USDT.balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = WBNB;
        path[1] = address(USDT);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amount = USDT.balanceOf(address(this)).sub(balanceBefore);

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
          USDT.transfer(shareholder, amount);
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
 // DAI DIVIDEND DISTRIBUTOR
 contract DividendDistributor6 is IDividendDistributor {
    using SafeMath for uint256;

    address _token;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    IBEP20 DAI = IBEP20(0x1AF3F329e8BE154074D8769D1FFa4eE058B1DBc3);
    address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    IDEXRouter router;

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
        ? IDEXRouter(_router)
        : IDEXRouter(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);
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
        uint256 balanceBefore = DAI.balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = WBNB;
        path[1] = address(DAI);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amount = DAI.balanceOf(address(this)).sub(balanceBefore);

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
            DAI.transfer(shareholder, amount);
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
  // BIG POPPA BTC DIVIDEND DISTRIBUTOR
 contract DividendDistributor7 is IDividendDistributor {
    using SafeMath for uint256;

    address _token;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    IBEP20 BTC = IBEP20(0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c);
    address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    IDEXRouter router;

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
        ? IDEXRouter(_router)
        : IDEXRouter(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);
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
        uint256 balanceBefore = BTC.balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = WBNB;
        path[1] = address(BTC);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amount = BTC.balanceOf(address(this)).sub(balanceBefore);

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
            BTC.transfer(shareholder, amount);
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
 /**
 * SAFEMATH LIBRARY
 */
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
       // lets Have some fun guys:) we can only succeed together

contract uhhhhhhhhhhhh is IBEP20, Auth {
    using SafeMath for uint256;

    uint256 public constant MASK = type(uint128).max;
    address BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    address USDT = 0x55d398326f99059fF775485246999027B3197955;               
    address DOGE =  0xbA2aE424d960c26247Dd6c32edC70B295c744C43;                                                             
    address BTC  = 0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c;
    address SHIB  = 0x2859e4544C4bB03966803b044A93563Bd2D0DD4D;
    address FLOKI  = 0xfb5B838b6cfEEdC2873aB27866079AC55363D37E;
    address DAI  = 0x1AF3F329e8BE154074D8769D1FFa4eE058B1DBc3;
    address BABYDOGE  = 0xc748673057861a797275CD8A068AbB95A902e8de;
    address public WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;
    address DEAD_NON_CHECKSUM = 0x000000000000000000000000000000000000dEaD;

    string private _name = "Meme Family Holiday";
    string private _symbol = "$MFH";
    uint8 constant _decimals = 9;
    // sorry snipers your not screwing our members
    bool private gasLimitActive = true;
    uint256 private constant gasPriceLimit = 70 * 1 gwei; // do not allow over x gwei for launch

    uint256 _totalSupply = 1_000_000_000_000_000 * (10 ** _decimals);
    uint256 public _maxTxAmount = _totalSupply * 2 / 100; // 2.0% can buy and sell up to 2% each transaction 
    uint256 public _maxWallet =_totalSupply * 3 / 100; // 3.0%  // to be fair to everyone
    uint256 public swapThreshold = _totalSupply / 2000; // SWAP TOKENS AT THIS AMOUNT

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;
// These have been exempted the team will pay the same tax as everyone else for any tokens we purchase
    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;
    mapping (address => bool) isMaxWalletExempt;
    mapping (address => bool) isDividendExempt;

// total fees collected needs to be kept to 10% 
    uint256 liquidityFee;
    uint256 buybackFee;
    uint256 projektFee;
    uint256 reflectionFee;
    uint256 totalFee;
    
    uint256 SellFeeMult = 10000;// first day
    uint256 feeDenominator = 10000;
    
//PROJECT PERCENTAGES   small percentage split between 4 devs 
    uint256 T1PRC;
    uint256 T2PRC;
    uint256 T3PRC;
    uint256 T4PRC;
    uint256 MKRPRC;
    uint256 CHARPRC;
    uint256 totaltp;
//DIVIDEND PERCENTAGES percentages to be adjusted based on bear or bull market settings
    uint256 Div1;
    uint256 Div2;
    uint256 Div3;
    uint256 Div4;
    uint256 totaldv;
// WALLET RECIEVERS
    address public autoLiquidityReceiver;   
    address public projecktreciever1; 
    address public projecktreciever2;
    address public projecktreciever3;  
    address public projecktreciever4; 
    address public marketingreciever;
    address public charityreciever;                                    
   
    uint256 targetLiquidity = 25;
    uint256 targetLiquidityDenominator = 100;

    IDEXRouter public router;
    address public pair;

    uint256 public launchedAt;
    uint256 public launchedAtTimestamp;
    // AUTO BUY BACK AND BURN SET ON DURRING EXTREAME SLOW DAYS ALL TO BENIFIT THE PROJECT
    uint256 buybackMultiplierNumerator = 200;
    uint256 buybackMultiplierDenominator = 100;
    uint256 buybackMultiplierTriggeredAt;
    uint256 buybackMultiplierLength = 30 minutes;
    bool public autoBuybackEnabled = false;
    mapping (address => bool) buyBacker;
    uint256 autoBuybackCap;
    uint256 autoBuybackAccumulator;
    uint256 autoBuybackAmount;
    uint256 autoBuybackBlockPeriod;
    uint256 autoBuybackBlockLast;
 
// THE REALLY GOOD STUFF HERE PAY THE HOLDERS BABY
    DividendDistributor distributor;
    address public distributorAddress;// DOGE
     DividendDistributor1 distributor1;
    address public distributorAddress1;//SHIB
     DividendDistributor2 distributor2;
    address public distributorAddress2;//FLOKI
    DividendDistributor3 distributor3;
    address public distributorAddress3;//BABYDOGE
    DividendDistributor4 distributor4;
    address public distributorAddress4;//BUSD
    DividendDistributor5 distributor5;
    address public distributorAddress5;//USDT
    DividendDistributor6 distributor6;
    address public distributorAddress6;//DAI
    DividendDistributor7 distributor7;
    address public distributorAddress7;//BIG POPPA BTC
   // PROCESS GAS
    uint256 distributorGas = 500000;
    // IS TOKEN SET FOR TRADING CAN NOT BE DISABLED
    bool public isTokenLive = false;// SET TRADING LIVE DISABLE CAN NOT HAPPEN
    bool public swapEnabled = true;// SWAP AND LIQUIFY ENABLED
    bool public MEMEHOLIDAY = false;// SET MEME MODE
    bool public BULLMODE = false; // SET BULL MODE
    bool public PUMPHOUR = false; // SET BULL MODE
   
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

   // SET DURING DEPLOYMENT ONE SHOT ONLY
     constructor (
        address _dexRouter
    ) Auth(msg.sender) {
        router = IDEXRouter(_dexRouter);
        pair = IDEXFactory(router.factory()).createPair(WBNB, address(this));
        _allowances[address(this)][address(router)] = _totalSupply;
        WBNB = router.WETH();
        distributor = new DividendDistributor(_dexRouter);
        distributorAddress = address(distributor);
        distributor1 = new DividendDistributor1(_dexRouter);
        distributorAddress1 = address(distributor1);
        distributor2 = new DividendDistributor2(_dexRouter);
        distributorAddress2 = address(distributor2);
        distributor3 = new DividendDistributor3(_dexRouter);
        distributorAddress3 = address(distributor3);
        distributor4 = new DividendDistributor4(_dexRouter);
        distributorAddress4 = address(distributor4);
        distributor5 = new DividendDistributor5(_dexRouter);
        distributorAddress5 = address(distributor5);
        distributor6 = new DividendDistributor6(_dexRouter);
        distributorAddress6 = address(distributor6);
        distributor7 = new DividendDistributor7(_dexRouter);
        distributorAddress7 = address(distributor7);
    

        // EXEMPTION STATUS
        isFeeExempt[msg.sender] = true;
        isTxLimitExempt[msg.sender] = true;
        isMaxWalletExempt[msg.sender] = true;
        isMaxWalletExempt[DEAD] = true;
        isMaxWalletExempt[pair] = true;
        isDividendExempt[pair] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[DEAD] = true;
        buyBacker[msg.sender] = true;
        autoLiquidityReceiver = msg.sender;
        projecktreciever1 = msg.sender;
        projecktreciever2 = msg.sender;
        projecktreciever3 = msg.sender;
        projecktreciever4 = msg.sender;
        marketingreciever = msg.sender;
        charityreciever = msg.sender;
        approve(_dexRouter, _totalSupply);
        approve(address(pair), _totalSupply);
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
// IF YOU WANT TO RECIEVE BNB TO EXTERNAL TAX WALLET
    receive() external payable { }

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external view override returns (string memory) { return _symbol; }
    function name() external view override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner; }
    modifier onlyBuybacker() { require(buyBacker[msg.sender] == true, ""); _; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
        // WAIT TO GO LIVE (WE CARE ONLY ABOUT OUR PRESALE HOLDERS GETTING THERE TOKENS BEFORE TRADING IS LIVE WE GOT TO BE FAIR GUYS)
        
        function _goLive() external onlyOwner() {
        require(!isTokenLive, "MFH is already live");
        isTokenLive = true;
           liquidityFee= 100;
           projektFee = 400;
           reflectionFee = 500;
           buybackFee = 0;
           totalFee = 1000;

           T1PRC = 20;
           T2PRC  = 20;
           T3PRC  = 20;
           T4PRC  = 20;
           MKRPRC = 10;
           CHARPRC = 10;
           totaltp = 100;
           
             Div1 = 25;
             Div2 = 25;
             Div3 = 25;
             Div4 = 25;
            totaldv = 100;
           PUMPHOUR = false;
           MEMEHOLIDAY = false;
           BULLMODE = false;
           
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, _totalSupply);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != _totalSupply){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        if(inSwap){ return _basicTransfer(sender, recipient, amount); }
        require(isFeeExempt[sender] || isFeeExempt[recipient] || isTokenLive, "MFH is not live yet");
     
     
        checkMXWallet(recipient, amount); // CHECK THE TOKEN HOLDERS MAX AMOUNT WE NEED TO BE FAIR
        checkTxLimit(sender, amount);   // SORRY GUYS CANT DUMP THE WHOLE BAG ON HOLDERS AT ONCE


      if(gasLimitActive){ 
       require(tx.gasprice <= gasPriceLimit, "Gas price exceeds limit.");// SORRY BOTS NOT COOL

       }// CHECK FOR SWAP AND LIQUIFY CONDITIONS
        if(shouldSwapBack()){ swapBack(); }
        if(shouldAutoBuyback()){ triggerAutoBuyback(); }
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        uint256 amountReceived = shouldTakeFee(sender) ? takeFee(sender, recipient, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);

         // VERIFY STATUS OF DIVIDEND EXEMPTION
        if(!isDividendExempt[sender]){ try distributor.setShare(sender, _balances[sender]) {} catch {} }
        if(!isDividendExempt[recipient]){ try distributor.setShare(recipient, _balances[recipient]) {} catch {} }       
        if(!isDividendExempt[sender]){ try distributor1.setShare(sender, _balances[sender]) {} catch {} }
        if(!isDividendExempt[recipient]){ try distributor1.setShare(recipient, _balances[recipient]) {} catch {} }  
        if(!isDividendExempt[sender]){ try distributor2.setShare(sender, _balances[sender]) {} catch {} }
        if(!isDividendExempt[recipient]){ try distributor2.setShare(recipient, _balances[recipient]) {} catch {} }
        if(!isDividendExempt[sender]){ try distributor3.setShare(sender, _balances[sender]) {} catch {} }
        if(!isDividendExempt[recipient]){ try distributor3.setShare(recipient, _balances[recipient]) {} catch {} }
        if(!isDividendExempt[sender]){ try distributor4.setShare(sender, _balances[sender]) {} catch {} }
        if(!isDividendExempt[recipient]){ try distributor4.setShare(recipient, _balances[recipient]) {} catch {} }
        if(!isDividendExempt[sender]){ try distributor5.setShare(sender, _balances[sender]) {} catch {} }
        if(!isDividendExempt[recipient]){ try distributor5.setShare(recipient, _balances[recipient]) {} catch {} }
        if(!isDividendExempt[sender]){ try distributor6.setShare(sender, _balances[sender]) {} catch {} }
        if(!isDividendExempt[recipient]){ try distributor6.setShare(recipient, _balances[recipient]) {} catch {} }
        if(!isDividendExempt[sender]){ try distributor7.setShare(sender, _balances[sender]) {} catch {} }
        if(!isDividendExempt[recipient]){ try distributor7.setShare(recipient, _balances[recipient]) {} catch {} }
        try distributor.process(distributorGas) {} catch {}
        try distributor1.process(distributorGas) {} catch {}
        try distributor2.process(distributorGas) {} catch {}
        try distributor3.process(distributorGas) {} catch {}
        try distributor4.process(distributorGas) {} catch {}
        try distributor5.process(distributorGas) {} catch {}
        try distributor6.process(distributorGas) {} catch {}
        try distributor7.process(distributorGas) {} catch {}

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }// BASIC TRANSFER
    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        return true;
    }// MAX WALLET SETTINGS BE FAIR TO HOLDERS VERIFY
    function checkMXWallet(address recipient, uint256 amount) internal view {
        uint256 heldTokens = balanceOf(recipient);
       require((heldTokens + amount)<= _maxWallet||isMaxWalletExempt[recipient],"Over wallet limit.");
      
    }
// VERIFY WITHIN TX LIMITS
    function checkTxLimit(address sender, uint256 amount) internal view {
        require(amount <= _maxTxAmount || isTxLimitExempt[sender], "TX Limit Exceeded");
    }

     function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }
    function getTotalFee(bool selling) public view returns (uint256) {
        if(launchedAt + 1 >= block.number){ return feeDenominator.sub(1); }
        if(selling){ return getMultipliedFee(); }
        return totalFee;
    }  // FIRST DAY DONT WORRY WE WANT TO KEEP IT AT 10%
    function getMultipliedFee() public view returns (uint256) {
        if (launchedAtTimestamp + 1 days > block.timestamp) {
            return totalFee.mul(SellFeeMult).div(feeDenominator);
        } else if (buybackMultiplierTriggeredAt.add(buybackMultiplierLength) > block.timestamp) {
            uint256 remainingTime = buybackMultiplierTriggeredAt.add(buybackMultiplierLength).sub(block.timestamp);
            uint256 feeIncrease = totalFee.mul(buybackMultiplierNumerator).div(buybackMultiplierDenominator).sub(totalFee);
            return totalFee.add(feeIncrease.mul(remainingTime).div(buybackMultiplierLength));
        }
        return totalFee;
    } // SORRY GUYS FEES ARE A NECASSARY EVIL HOLD TIGHT ITS A GOOD TOKEN PROJECT
    function takeFee(address sender, address receiver, uint256 amount) internal returns (uint256) {
        uint256 feeAmount = amount.mul(getTotalFee(receiver == pair)).div(feeDenominator);

        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);

        return amount.sub(feeAmount);
    }
    // WE GOOD TO SWAP 
    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != pair
        && !inSwap
        && swapEnabled
        && _balances[address(this)] >= swapThreshold;
    }
        // OK WERE SWAPPING!
    function swapBack() internal swapping {
        uint256 MemeLiquidityFee = isOverLiquified(targetLiquidity, targetLiquidityDenominator) ? 0 : liquidityFee;
        uint256 amountToLiquify = swapThreshold.mul(MemeLiquidityFee).div(totalFee).div(2);
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
         // TOTAL FEES
        uint256 amountBNB = address(this).balance.sub(balanceBefore); // TOTAL COLLECTED
        uint256 totalBNBFee = totalFee.sub(MemeLiquidityFee.div(2));  // GOT TO TAKE THE LP
           // ADDED LP AMOUNT
        uint256 amountBNBLiquidity = amountBNB.mul(MemeLiquidityFee).div(totalBNBFee).div(2);

        if (PUMPHOUR){
         {   
        uint256 amountBNBReflection1 = amountBNB.mul(reflectionFee).div(totalBNBFee).mul(12).div(10**2);
        uint256 amountBNBReflection2 = amountBNB.mul(reflectionFee).div(totalBNBFee).mul(12).div(10**2);
        uint256 amountBNBReflection3 = amountBNB.mul(reflectionFee).div(totalBNBFee).mul(12).div(10**2);
        uint256 amountBNBReflection4 = amountBNB.mul(reflectionFee).div(totalBNBFee).mul(12).div(10**2);
        try distributor.deposit{value: amountBNBReflection1}() {} catch {} //DOGE
        try distributor1.deposit{value: amountBNBReflection2}() {} catch {} //SHIB
        try distributor2.deposit{value: amountBNBReflection3}() {} catch {} //FLOKI
        try distributor3.deposit{value: amountBNBReflection4}() {} catch {} //BABYDOGE
         }{
        uint256 amountBNBReflection5 = amountBNB.mul(reflectionFee).div(totalBNBFee).mul(12).div(10**2);
        uint256 amountBNBReflection6 = amountBNB.mul(reflectionFee).div(totalBNBFee).mul(12).div(10**2);
        uint256 amountBNBReflection7 = amountBNB.mul(reflectionFee).div(totalBNBFee).mul(14).div(10**2);
        uint256 amountBNBReflection8 = amountBNB.mul(reflectionFee).div(totalBNBFee).mul(14).div(10**2);
        try distributor4.deposit{value: amountBNBReflection5}() {} catch {} //BUSD
        try distributor5.deposit{value: amountBNBReflection6}() {} catch {} //USDT
        try distributor6.deposit{value: amountBNBReflection7}() {} catch {} //DAI
        try distributor7.deposit{value: amountBNBReflection8}() {} catch {} //BTC   
           }
        }else {// BNB FOR REFLECTION PURPOSES YAHHHHH BABY 
        uint256 amountBNBReflection1 = amountBNB.mul(reflectionFee).div(totalBNBFee).mul(Div1).div(10**2);
        uint256 amountBNBReflection2 = amountBNB.mul(reflectionFee).div(totalBNBFee).mul(Div2).div(10**2);
        uint256 amountBNBReflection3 = amountBNB.mul(reflectionFee).div(totalBNBFee).mul(Div3).div(10**2);
        uint256 amountBNBReflection4 = amountBNB.mul(reflectionFee).div(totalBNBFee).mul(Div4).div(10**2); 
            if(MEMEHOLIDAY)
             { // TOP RATED MEMES HAPPY HOLIDAYS
          try distributor.deposit{value: amountBNBReflection1}() {} catch {} //DOGE
          try distributor1.deposit{value: amountBNBReflection2}() {} catch {} //SHIB
          try distributor2.deposit{value: amountBNBReflection3}() {} catch {} //FLOKI
          try distributor3.deposit{value: amountBNBReflection4}() {} catch {} //BABYDOGE
            }else if(BULLMODE) { 
              // WERE IN A BULL BABY EARN THEM REWARDS
          try distributor5.deposit{value: amountBNBReflection2}() {} catch {} //USDT
          try distributor7.deposit{value: amountBNBReflection4}() {} catch {} //BTC
          try distributor.deposit{value: amountBNBReflection1}() {} catch {} //DOGE
          try distributor1.deposit{value: amountBNBReflection2}() {} catch {}//SHIB
                }else
           {// OK THINGS ARE BEARISH LETS HOOK UP HOLDERS WITH SOME STABLES     
          try distributor4.deposit{value: amountBNBReflection1}() {} catch {} //BUSD
          try distributor5.deposit{value: amountBNBReflection2}() {} catch {} //USDT
          try distributor6.deposit{value: amountBNBReflection3}() {} catch {} //DAI
          try distributor7.deposit{value: amountBNBReflection4}() {} catch {} //BTC   
          }
           }

        { // BNB FOR PROJECT TEAM 4 DEVS SPLIT A SMALL PERCENTAGE // COME ON GUYS I WORKED ON THIS FOR A MONTH
        uint256 amountBNBforProjekt1 = amountBNB.mul(projektFee).div(totalBNBFee).mul(T1PRC).div(10**2);
        uint256 amountBNBforProjekt2 = amountBNB.mul(projektFee).div(totalBNBFee).mul(T2PRC).div(10**2);
        uint256 amountBNBforProjekt3 = amountBNB.mul(projektFee).div(totalBNBFee).mul(T3PRC).div(10**2);
        uint256 amountBNBforProjekt4 = amountBNB.mul(projektFee).div(totalBNBFee).mul(T4PRC).div(10**2);
          // PAYDAY BABY (KING NEEDS SNOW TIRES TRUST ME HE NEVER SHUTS UP)
         payable(projecktreciever1).transfer(amountBNBforProjekt1);//R dev1
         payable(projecktreciever2).transfer(amountBNBforProjekt2);//N dev2
         payable(projecktreciever3).transfer(amountBNBforProjekt3);//K dev3
         payable(projecktreciever4).transfer(amountBNBforProjekt4);//S dev4
          }
        { // BNB FOR MARKETING AND FOR CHARITY HOLIDAY CHARITY
        uint256 amountBNBforProjekt5 = amountBNB.mul(projektFee).div(totalBNBFee).mul(MKRPRC).div(10**2);
        uint256 amountBNBforProjekt6 = amountBNB.mul(projektFee).div(totalBNBFee).mul(CHARPRC).div(10**2);
         // CALLS AND DOING SOME GOOD ITS HOLIDAY MEME GUYS A SMALL CHARITY PERCENTAGE CAN REALLY MAKE A DIFFRENCE
         payable(marketingreciever).transfer(amountBNBforProjekt5);// amount for marketing
         payable(charityreciever).transfer(amountBNBforProjekt6);// amount for charity 
          }
         // Lets add that LP lp tokens to be added and locked each week 
       if(amountToLiquify > 0){
            router.addLiquidityETH{value: amountBNBLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                autoLiquidityReceiver,// WILL MOVE TO DEAD ADDRESS AFTER TOKEN STABLE
                block.timestamp
            );
            emit AutoLiquify(amountBNBLiquidity, amountToLiquify);
        }
    }
    
    function shouldAutoBuyback() internal view returns (bool) {
        return msg.sender != pair
        && !inSwap
        && autoBuybackEnabled
        && autoBuybackBlockLast + autoBuybackBlockPeriod <= block.number // After N blocks from last buyback
        && address(this).balance >= autoBuybackAmount;
    } // AUTO BUY BACK AND BURN GUYS DEFLATE THIS TOKEN      
    function triggerMemeBuyback(uint256 amount, bool triggerBuybackMultiplier) external authorized {
        buyTokens(amount, DEAD);
        if(triggerBuybackMultiplier){
            buybackMultiplierTriggeredAt = block.timestamp;
            emit BuybackMultiplierActive(buybackMultiplierLength);
        }
    }
    function clearBuybackMultiplier() external authorized {
        buybackMultiplierTriggeredAt = 0;
    }// WILL AUTOBUY BACK WHEN ENABLED DURING SLOW PERIODS AS PROMISED
    function triggerAutoBuyback() internal {
        buyTokens(autoBuybackAmount, DEAD);
        autoBuybackBlockLast = block.number;
        autoBuybackAccumulator = autoBuybackAccumulator.add(autoBuybackAmount);
        if(autoBuybackAccumulator > autoBuybackCap){ autoBuybackEnabled = false; }
    }

    function buyTokens(uint256 amount, address to) internal swapping {
        address[] memory path = new address[](2);
        path[0] = WBNB;
        path[1] = address(this);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0,
            path,
            to,
            block.timestamp
        );
    }
    function setAutoBuybackSettings(bool _enabled, uint256 _cap, uint256 _amount, uint256 _period) external authorized {
        autoBuybackEnabled = _enabled;
        autoBuybackCap = _cap;
        autoBuybackAccumulator = 0;
        autoBuybackAmount = _amount;
        autoBuybackBlockPeriod = _period;
        autoBuybackBlockLast = block.number;
    }
    function setBuybackMultiplierSettings(uint256 numerator, uint256 denominator, uint256 length) external authorized {
        require(numerator / denominator <= 2 && numerator > denominator);
        buybackMultiplierNumerator = numerator;
        buybackMultiplierDenominator = denominator;
        buybackMultiplierLength = length;
    }
    function launched() internal view returns (bool) {
        return launchedAt != 0;
    }
// SETS BLOCK AND TIME OF LAUNCH 
    function launch() public authorized {
        require(launchedAt == 0, "Already launched so relax and pump");
        launchedAt = block.number;
        launchedAtTimestamp = block.timestamp;
    }
    // remove limits after token is stable
    function removeLimits() external authorized returns (bool){
        gasLimitActive = false;
        return true;
    }
    function setTxLimit(uint256 amount) external authorized {
        require(amount >= _totalSupply / 1000);
        _maxTxAmount = amount;
    }
    function setMxWallet(uint256 amount) external authorized {
        require(amount >= _totalSupply / 1000);
        _maxWallet = amount;
    }
     // only use if conducting a presale (more specifically on DxSale where there is both an address and a router, PinkSale only uses one address, you can paste it in here twice with no issue)
    function addPresaleAddressForExclusions(address _presaleAddress, address _presaleRouterAddress) external authorized { 
        isFeeExempt[_presaleAddress] = true;
        isFeeExempt[_presaleRouterAddress] = true;
        isDividendExempt[_presaleAddress] = true;
        isDividendExempt[_presaleRouterAddress] = true;  
        isMaxWalletExempt[_presaleAddress] = true;
        isMaxWalletExempt[_presaleRouterAddress] = true;   
       
    }
     // SORRY SOME THINGS JUST HAVE TO BE EXCLUDED FROM DIVS 
    function setIsDividendExempt(address holder, bool exempt) external authorized {
        require(holder != address(this) && holder != pair);
        isDividendExempt[holder] = exempt;
        if(exempt){
            distributor.setShare(holder, 0);
            distributor1.setShare(holder, 0);
            distributor2.setShare(holder, 0);
            distributor3.setShare(holder, 0);
            distributor4.setShare(holder, 0);
            distributor5.setShare(holder, 0);
            distributor6.setShare(holder, 0);
            distributor7.setShare(holder, 0);
        }else{
            distributor.setShare(holder, _balances[holder]);
            distributor1.setShare(holder, _balances[holder]);
            distributor2.setShare(holder, _balances[holder]);
            distributor3.setShare(holder, _balances[holder]);
            distributor4.setShare(holder, _balances[holder]);
            distributor5.setShare(holder, _balances[holder]);
            distributor6.setShare(holder, _balances[holder]);
            distributor7.setShare(holder, _balances[holder]);
        }
    }

    function setIsFeeExempt(address holder, bool exempt) external authorized {
        isFeeExempt[holder] = exempt;
    }
    function setIsTxLimitExempt(address holder, bool exempt) external authorized {
        isTxLimitExempt[holder] = exempt;
    }
    function setIsMaxwalletExempt(address holder, bool exempt) external authorized {
        isMaxWalletExempt[holder] = exempt;
    }
    function setFees1(uint256 _liquidityFee, uint256 _buybackFee, uint256 _reflectionFee, uint256 _projektFee, uint256 _feeDenominator) external authorized {
        liquidityFee = _liquidityFee;
        buybackFee = _buybackFee;
        reflectionFee = _reflectionFee;
        projektFee = _projektFee;
        totalFee = _liquidityFee.add(_buybackFee).add(_reflectionFee).add(_projektFee);
        feeDenominator = _feeDenominator;
        require(totalFee < feeDenominator/4);
    }
// BNB FEES ARE COLLECTED HERE GUYS 
    function setFeeReceivers(address _autoLiquidityReceiver, address _projecktreciever1,address _projecktreciever2,address _projecktreciever3,address _projecktreciever4,address _marketingreciever,address _charitytreciever) external authorized {
        autoLiquidityReceiver = _autoLiquidityReceiver;
        projecktreciever1 = _projecktreciever1;
        projecktreciever2 = _projecktreciever2;
        projecktreciever3 = _projecktreciever3;
        projecktreciever4 = _projecktreciever4;
        marketingreciever = _marketingreciever;
        charityreciever = _charitytreciever;
    }
    // OK OK GUYS THIS IS 4% SPLIT BETWEEN MARKETING CHARITY AND 4 HARDWORKING DEVS GIVING U A NICE FUN SAFE MEME WITH MASSIVE UTILITY
    function setTeamPercentage(uint256 _T1PRC, uint256 _T2PRC, uint256 _T3PRC, uint256 _T4PRC, uint256 _MKRPRC, uint256 _CHARPRC) external onlyOwner{
        T1PRC = _T1PRC;
        T2PRC = _T2PRC;
        T3PRC = _T3PRC;
        T4PRC = _T4PRC;
        MKRPRC = _MKRPRC;
        CHARPRC = _CHARPRC;
        totaltp = T1PRC+T2PRC+T3PRC+T4PRC+MKRPRC+CHARPRC;
        require(totaltp == 100, "Total does not equal 100.");
    }
    // PERCENTAGE FOR THE 4 DIVS BEAR AND BULL SETTINGS WILL APPLY MUST EQUAL 100% OF COLLECTED TAX
    function setDivPercentage(uint256 _DIV1, uint256 _DIV2, uint256 _DIV3, uint256 _DIV4) external onlyOwner{
        Div1 = _DIV1;
        Div2 = _DIV2;
        Div3 = _DIV3;
        Div4 = _DIV4;
        totaldv = Div1+Div2+Div3+Div4;
        require(totaldv == 100, "Total does not equal 100.");
    }
    function setSwapBackSettings(bool _enabled, uint256 _amount) external authorized {
        swapEnabled = _enabled;
        swapThreshold = _amount;
    }
    function setPumpcondition(bool _enabled) external authorized {
    //No mode selected we have bear conditions
        PUMPHOUR = _enabled; //HOLIDAY MODE
        if (PUMPHOUR=true) {
           BULLMODE = false;
           liquidityFee= 100;
           projektFee = 400;
           reflectionFee = 500;
           buybackFee = 0;
           totalFee = 1000;

           T1PRC = 25;
           T2PRC  = 25;
           T3PRC  = 25;
           T4PRC  = 25;
           MKRPRC = 0;
           CHARPRC = 0;
           totaltp = 100;
       } 
    } 
    function setMemecondition(bool _enabled) external authorized {
    //No mode selected we have bear conditions
        MEMEHOLIDAY = _enabled; //HOLIDAY MODE
        if (MEMEHOLIDAY=true) {
           BULLMODE = false;
           liquidityFee= 100;
           projektFee = 400;
           reflectionFee = 500;
           buybackFee = 0;
           totalFee = 1000;

           T1PRC = 20;
           T2PRC  = 20;
           T3PRC  = 20;
           T4PRC  = 20;
           MKRPRC = 10;
           CHARPRC = 10;
           totaltp = 100;
       } 
   }function setBullcondition(bool _enabled) external authorized {
       //No mode selected we have bear conditions
        BULLMODE = _enabled; //BULL MODE
        if (BULLMODE = true) {
            MEMEHOLIDAY = false;

            liquidityFee= 100;
           projektFee = 400;
           reflectionFee = 500;
           buybackFee = 0;
           totalFee = 1000;

           T1PRC = 20;
           T2PRC  = 20;
           T3PRC  = 20;
           T4PRC  = 20;
           MKRPRC = 10;
           CHARPRC = 10;
           totaltp = 100;
       }  
   }
    function setTargetLiquidity(uint256 _target, uint256 _denominator) external authorized {
        targetLiquidity = _target;
        targetLiquidityDenominator = _denominator;
    }
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution ) external authorized {
        distributor.setDistributionCriteria(_minPeriod, _minDistribution);
         }    
    function setDistributionCriteria1(uint256 _minPeriod, uint256 _minDistribution ) external authorized {
        distributor1.setDistributionCriteria(_minPeriod, _minDistribution);
         }
    function setDistributionCriteria2(uint256 _minPeriod, uint256 _minDistribution ) external authorized {
        distributor2.setDistributionCriteria(_minPeriod, _minDistribution);
         }
    function setDistributionCriteria3(uint256 _minPeriod, uint256 _minDistribution ) external authorized {
        distributor3.setDistributionCriteria(_minPeriod, _minDistribution);
         }
    function setDistributionCriteria4(uint256 _minPeriod, uint256 _minDistribution ) external authorized {
        distributor4.setDistributionCriteria(_minPeriod, _minDistribution);
         }
    function setDistributionCriteria5(uint256 _minPeriod, uint256 _minDistribution ) external authorized {
        distributor5.setDistributionCriteria(_minPeriod, _minDistribution);
         }
    function setDistributionCriteria6(uint256 _minPeriod, uint256 _minDistribution ) external authorized {
        distributor6.setDistributionCriteria(_minPeriod, _minDistribution);
         }
    function setDistributionCriteria7(uint256 _minPeriod, uint256 _minDistribution ) external authorized {
        distributor7.setDistributionCriteria(_minPeriod, _minDistribution);
         }

// HELL YA BABY WE ARE GOING FULL CHAMELON HERE NEVER NEED TO BUY ANOTHER SHITCOIN AGAIN
    function changeTokenName(string memory newName , string memory newSymbol)  external authorized {
     _name = newName;
     _symbol = newSymbol;

    }
    function setDistributorSettings(uint256 gas) external authorized {
        require(gas < 750000);
        distributorGas = gas;
    }
    //Use this in case BNB are sent to the contract by mistake ONLY OWNER CAN PERFORM! RETURN TO ADDRESS
    function rescueBNB(uint256 weiAmount) external onlyOwner {
        require(address(this).balance >= weiAmount, "insufficient BNB balance");
        payable(msg.sender).transfer(weiAmount);
    }
    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }
    function getLiquidityBacking(uint256 accuracy) public view returns (uint256) {
        return accuracy.mul(balanceOf(pair).mul(2)).div(getCirculatingSupply());
    }
    function isOverLiquified(uint256 target, uint256 accuracy) public view returns (bool) {
        return getLiquidityBacking(accuracy) > target;
    }
    event AutoLiquify(uint256 amountBNB, uint256 amountBOG);
    event BuybackMultiplierActive(uint256 duration);
}