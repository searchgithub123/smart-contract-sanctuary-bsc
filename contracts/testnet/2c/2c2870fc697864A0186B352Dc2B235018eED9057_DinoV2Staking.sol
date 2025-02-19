// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IERC20.sol";
import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "./interfaces/IWETH.sol";
import "./libraries/SafeMath.sol";
import "./libraries/Context.sol";
import "./libraries/Auth.sol";

contract DinoV2Staking is Context, Auth, IERC20 {
    using SafeMath for uint256;

    //ERC20
    uint8 private _decimals = 18;
    uint256 private _totalSupply;
    string private _name = "DinoV2 Staking";
    string private _symbol = "DinoV2-SP";
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) public totalDistributeToToken;
    uint256 public totalDistributeToWeth;

    address ZERO = 0x0000000000000000000000000000000000000000;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address routerDexAddress;
    address tokenAddress;
    address wbnbAddress;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalClaimed;
    }

    address[] shareholders;
    mapping(address => uint256) shareholderIndexes;
    mapping(address => uint256) shareholderClaims;
    mapping(address => bool) public isCanSetShares;
    mapping(address => Share) public shares;

    uint256 public indexCurrentAutoStaking = 0;

    uint256 public percentTaxDenominator = 10000;

    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 10 ** 36;
    uint256 public totalClaimWeekly = 0;
    uint256 public totalReceiveWeekBSAFU = 0;
    uint256 public totalReceiveWeekBNB = 0;
    uint256 public lastResetAPR = 0;
    uint256 public loopInterest = 0;
    uint256 public APR;
    bool public isCountAPRAYREnable = true;

    event Deposit(address account, uint256 amount);
    event Distribute(address account, uint256 amount);
    event Stake(address account, uint256 amount);
    event UnStake(address account, uint256 amount);

    modifier onlyCanSetShare() {
        require(isCanSetShares[_msgSender()], "DinoV2Staking: Unauthorize for Set Share");
        _;
    }

    constructor(
        address _routerAddress,
        address _tokenAddress,
        address _wbnbAddress
    ) Auth(msg.sender) {
        routerDexAddress = _routerAddress;
        tokenAddress = _tokenAddress;
        wbnbAddress = _wbnbAddress;
        lastResetAPR = block.timestamp;
    }

    receive() external payable {}

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function getOwner() public view virtual override returns (address) {
        return _getOwner();
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
        if (_allowances[sender][msg.sender] != _totalSupply) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender]
            .sub(amount, "DinoV2: Insufficient Allowance");
        }
        _transfer(sender, recipient, amount);
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
            "DinoV2: decreased allowance below zero"
        );
    unchecked {
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);
    }

        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "DinoV2: approve from the zero address");
        require(spender != address(0), "DinoV2: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function burn(uint256 amount) external {
        require(_balances[_msgSender()] >= amount, "DinoV2: Insufficient Amount");
        _burn(_msgSender(), amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        _balances[account] = _balances[account].sub(amount);
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, DEAD, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        _balances[account] = _balances[account].add(amount);
        _totalSupply = _totalSupply.add(amount);
        emit Transfer(ZERO, account, amount);
    }

    function setWbnbAddress(address _wbnbAddress) external onlyOwner {
        wbnbAddress = _wbnbAddress;
    }

    function stake(address account, uint256 amount) external {
        require(amount > 0, "Invalid Amount");
        require(IERC20(tokenAddress).balanceOf(_msgSender()) > 0, "Insufficient Amount");
        IERC20(tokenAddress).transferFrom(_msgSender(), address(this), amount);
        _mint(account, amount);
        _setShare(account, _balances[account]);
        emit Stake(account, amount);
    }

    function unstake(address account, uint256 amount) external {
        require(amount > 0, "DinoV2Staking: Invalid Amount");
        require(_balances[_msgSender()] >= amount, "DinoV2Staking: Insufficient Amount");
        _burn(_msgSender(), amount);
        IERC20(tokenAddress).transfer(account, amount);
        _setShare(account, _balances[account]);
        emit UnStake(_msgSender(), amount);
    }

    function unstakeAll(address account) external {
        require(_balances[_msgSender()] > 0, "Insufficient Amount");
        uint256 amount = _balances[_msgSender()];
        _burn(_msgSender(), amount);
        IERC20(tokenAddress).transfer(account, amount);
        _setShare(account, _balances[account]);
        emit UnStake(_msgSender(), amount);
    }

    function deposit() public payable {
        if (totalShares > 0) {
            uint256 balanceBefore = IWETH(wbnbAddress).balanceOf(address(this));
            IWETH(wbnbAddress).deposit{value : msg.value}();
            uint256 amount = IWETH(wbnbAddress).balanceOf(address(this)).sub(balanceBefore);
            totalDividends = totalDividends.add(amount);
            dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(amount).div(totalShares));
            loopInterest = loopInterest.add(1);
            if (isCountAPRAYREnable) countAPRAPY(msg.value);
            emit Deposit(msg.sender, msg.value);
        }
    }

    function countAPRAPY(uint256 amount) internal {
        if (block.timestamp.sub(lastResetAPR) >= 7 days) {
            totalReceiveWeekBSAFU = 0;
            totalReceiveWeekBNB = 0;
            totalClaimWeekly = 0;
            loopInterest = 1;
            lastResetAPR = block.timestamp;
        }

        totalReceiveWeekBNB = totalReceiveWeekBNB.add(amount);
        IUniswapV2Router02 router = IUniswapV2Router02(routerDexAddress);
        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = tokenAddress;
        uint256[] memory estimate = router.getAmountsOut(amount, path);
        totalReceiveWeekBSAFU = totalReceiveWeekBSAFU.add(estimate[1]);
    unchecked {
        uint year = 365;
        uint day = 7;
        APR = totalReceiveWeekBSAFU.mul(percentTaxDenominator).div(_totalSupply).mul(year.div(day)).mul(100).div(percentTaxDenominator);
    }
    }

    function claimWeth(address to, uint256 amount) external onlyOwner {
        payable(to).transfer(amount);
    }

    function claimFromContract(address _tokenAddress, address to, uint256 amount) external onlyOwner {
        IERC20(_tokenAddress).transfer(to, amount);
    }

    function setCanSetShares(address _address, bool _state) external onlyOwner {
        isCanSetShares[_address] = _state;
    }

    function _setShare(address account, uint256 amount) internal {
        bool isShouldClaim = shouldClaim(account);
        if (shares[account].amount > 0 && isShouldClaim) {
            distributeDividendShareholder(account);
        }

        if (amount > 0 && shares[account].amount == 0) {
            addShareholder(account);
        } else if (amount == 0 && shares[account].amount > 0) {
            removeShareholder(account);
        }

        totalShares = totalShares.sub(shares[account].amount).add(amount);
        shares[account].amount = amount;
        shares[account].totalExcluded = getCumulativeDividend(shares[account].amount);
    }

    function setShare(address account, uint256 amount) public onlyCanSetShare {
        _setShare(account, amount);
    }

    /** Get dividend of account */
    function dividendOf(address account) public view returns (uint256) {

        if (shares[account].amount == 0) {return 0;}

        uint256 shareholderTotalDividends = getCumulativeDividend(shares[account].amount);
        uint256 shareholderTotalExcluded = shares[account].totalExcluded;

        if (shareholderTotalDividends <= shareholderTotalExcluded) {return 0;}

        return shareholderTotalDividends.sub(shareholderTotalExcluded);
    }

    /** Get cumulative dividend */
    function getCumulativeDividend(uint256 share) internal view returns (uint256) {
        return share.mul(dividendsPerShare).div(dividendsPerShareAccuracyFactor);
    }

    function getCurrentBalance() public view returns (uint256){
        return IWETH(wbnbAddress).balanceOf(address(this));
    }

    function shouldClaim(address account) internal view returns (bool) {
        if (getCurrentBalance() == 0) return false;
        if (shares[account].totalClaimed >= shares[account].totalExcluded) return false;
        return true;
    }

    /** Adding share holder */
    function addShareholder(address shareholder) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    /** Remove share holder */
    function removeShareholder(address shareholder) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[shareholders.length - 1];
        shareholderIndexes[shareholders[shareholders.length - 1]] = shareholderIndexes[shareholder];
        shareholders.pop();
    }

    function distributeDividendShareholder(address account) internal {
        if (shouldClaim(account)) {
            _claimToOther(account, tokenAddress);
        }
    }

    function claimToEth(address account) external {
        if (dividendOf(account) > 0) {
            _claimToWeth(account);
        }
    }

    function claimToOther(address account, address targetToken) external {
        if (dividendOf(account) > 0) {
            _claimToOther(account, targetToken);
        }
    }

    /** execute claim to weth */
    function _claimToWeth(address account) internal {
        uint256 amount = dividendOf(account);
        uint256 amountAfterFee = getFee(amount);
        if (amountAfterFee > 0) {
            IWETH(wbnbAddress).withdraw(amountAfterFee);
            payable(account).transfer(amountAfterFee);
            totalDistributeToWeth = totalDistributeToWeth.add(amount);
            setClaimed(account, amount);
        }
    }

    function _claimToOther(address account, address targetToken) internal {
        IUniswapV2Router02 router = IUniswapV2Router02(routerDexAddress);
        uint256 amount = dividendOf(account);
        uint256 amountAfterFee = getFee(amount);
        if (amountAfterFee > 0) {
            IWETH(wbnbAddress).withdraw(amountAfterFee);
            IWETH(router.WETH()).deposit{value : amountAfterFee}();
            address[] memory path = new address[](2);
            path[0] = router.WETH();
            path[1] = targetToken;
            IWETH(router.WETH()).approve(routerDexAddress, amountAfterFee);
            uint256[] memory estimate = router.getAmountsOut(amountAfterFee, path);
            uint256 balanceBeforeSwap = IERC20(targetToken).balanceOf(address(this));
            router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                amountAfterFee,
                estimate[1],
                path,
                address(this),
                block.timestamp
            );
            uint256 balanceAfterSwap = IERC20(targetToken).balanceOf(address(this));
            uint256 balanceTransfer = balanceAfterSwap.sub(balanceBeforeSwap);
            IERC20(targetToken).transfer(account, balanceTransfer);
            totalDistributeToToken[targetToken] = totalDistributeToToken[targetToken].add(amount);
            setClaimed(account, amount);
        }
    }

    function getFee(uint256 amountReward) internal pure returns (uint256){
        return amountReward;
    }

    /** Set claimed state */
    function setClaimed(address account, uint256 amount) internal {
        shareholderClaims[account] = block.timestamp;
        shares[account].totalClaimed = shares[account].totalClaimed.add(amount);
        shares[account].totalExcluded = getCumulativeDividend(shares[account].amount);
        totalDistributed = totalDistributed.add(amount);
        emit Distribute(account, amount);
    }

    function setCountAPRAPY(bool state) external onlyOwner {
        isCountAPRAYREnable = state;
    }


}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
    function balanceOf(address account) external view returns (uint256);
    function approve(address guy, uint wad) external returns (bool);
    function transferFrom(address src, address dst, uint256 wad) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Auth {
    address internal owner;
    mapping(address => bool) internal authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender), "BabyToken: !OWNER");
        _;
    }

    modifier authorized() {
        require(isAuthorized(msg.sender), "BabyToken: !AUTHORIZED");
        _;
    }

    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
    }

    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
    }

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }

    function _getOwner() public view returns (address) {
        return owner;
    }

    event OwnershipTransferred(address owner);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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