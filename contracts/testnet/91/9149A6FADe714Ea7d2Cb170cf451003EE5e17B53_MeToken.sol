/**
 *Submitted for verification at BscScan.com on 2022-09-17
*/

// File: @uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol


pragma solidity >=0.5.0;

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

// File: @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol


pragma solidity >=0.6.2;

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

// File: @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol


pragma solidity >=0.6.2;


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

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
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
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
    event Approval(address indexed owner, address indexed spender, uint256 value);

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

// File: contracts/Me/MeToken.sol

pragma solidity ^0.8.16;
//SPDX-License-Identifier: UNLICENSED





interface MyNftEX {
    function rewardBalance(address account) external view returns (uint256);
    function claimRewards(address account) external;
    function currentReward(address account) external view returns(uint256);
    function totalRewards() external view returns(uint256);
    function totalExcludedRewardAmount() external view returns(uint256);
    function setRewardStop(uint256 timestamp) external;

}

contract MeToken is Ownable, IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 public _totalSupply;
    uint256 private _maxSupply;
    uint256 public rewardSupply;
    uint256 public _totalBurn;//黑洞总量
    address public routerAddr;
    address public usdtAddr;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    MyNftEX public myNftEX;
    IUniswapV2Router02 public router;
    address public pair;
    mapping (address => bool) public _isExcludedFromFee;
    bool inSwap;
    // fees
    uint256 private _totalBuyFee;
    uint256 private _totalSellFee;
    uint256 private _feeRate;
    // fee distribution wallets
    address public _token_trusteeship;//币值管理
    address public _security_fund;//保障基金
    address public _burnWallet;//黑洞销毁
    address public _dao_reward;//Dao奖励
    // liquidity
    uint256 public numTokensToAddToLiquidity;//达到这个数进行自动LP
    uint256 public waitAutoLPTokenNum;//等待自动LP
    //liquidity bonus
    uint256 public swapTokensAtAmount;//达到这个数进行分红
    address[] public buyUser;//参与流动性的用户
    mapping(address => bool) public havePushBuyUser;
    uint8 public splitTimesPerTran = 5;//每次分20个
    uint256 public currentSplitIndex;
    uint256 public waitLPHolderDividendTokenNum;//等待分红的ME
    uint256 public processingLPHolderDividendTokenNum;//正在分红的ME
    uint256 public waitTrustenshipTokenNum;//币值管理等待卖出ME
    address manager;
    address public _meConsensus;//Me共识

    // usdt
    IERC20 public usdt;

    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
    event AutoLP(bool flag);
    event Received(address, uint256);

    function init() private onlyOwner {
        uint256 tenMillion = (10**_decimals) * (10**7);
        _totalSupply = tenMillion; // 1 milion
        rewardSupply = tenMillion * 20; // 20 million
        _maxSupply = _totalSupply + rewardSupply; // 21 milion
        _balances[msg.sender] = _totalSupply;

        setupLP();
        _totalBuyFee = 800;     // buy fee  : 8%
        _totalSellFee = 1200;   // sell fee : 12%
        _feeRate = 10000;
        numTokensToAddToLiquidity = 100 ether;//自动LP
        swapTokensAtAmount = 100 ether; //分红价格

        _token_trusteeship = address(0xb3eA4141585D2fD6C19C19512f77c5bD39c3F2ab);
        _dao_reward= address(0xf92DD02Dfd9577Cedcd62E9291261B862E74f0bc);
        _burnWallet = address(0);
    }

    constructor (address security_fund_) {
        manager = owner();
        _security_fund = security_fund_;
        _name = "MyNFTex";
        _symbol = "ME";
        _decimals = 18;
        init();
    }

    function setupLP() private onlyOwner {
        IUniswapV2Router02 _uniswapV2Router;
        //正式网上线时删除
        if (block.chainid == 56) // bsc mainnet
        {
            routerAddr = address(0x10ED43C718714eb63d5aA57B78B54704E256024E);
            usdtAddr = address(0x55d398326f99059fF775485246999027B3197955);
        }
        else if (block.chainid == 97) // bsc testnet
        {
            routerAddr = address(0x1Ed675D5e63314B760162A3D1Cae1803DCFC87C7);
            usdtAddr = address(0x0B7E566590D26Ec368e08e23cEa6B18e618f541c);
        }
        _uniswapV2Router = IUniswapV2Router02(routerAddr);
        usdt = IERC20(usdtAddr);
        // Create a uniswap pair for this new token
        pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), usdtAddr);
        // set the rest of the contract variables
        router = _uniswapV2Router;
        //exclude owner and this contract from fee
        _isExcludedFromFee[manager] = true;
        _isExcludedFromFee[address(this)] = true;
        _approve(address(this), routerAddr, 10**50);
    }

    function setSplitTimesPerTran(uint8 splitTimesPerTran_) public onlyOwner {
        splitTimesPerTran = splitTimesPerTran_;
    }

    //分红控制
    function setSwapTokensAtAmount(uint256 _swapTokensAtAmount) public onlyOwner {
        swapTokensAtAmount = _swapTokensAtAmount;
    }

    function setAutoLPThreshold(uint256 amount) public onlyOwner {
        numTokensToAddToLiquidity = amount;
    }

    //清除流动性为0的用户
    function clearBuyUser() public {
        if (buyUser.length <= 0) {
            return;
        }

        uint256 buyUserLen = buyUser.length;
        for(uint256 i = buyUserLen - 1; i >= 0; ) {
            address user = buyUser[i];
            if (IERC20(pair).balanceOf(user) <= 0) {
                buyUser[i] = buyUser[buyUser.length - 1];
                buyUser.pop();
                havePushBuyUser[user] = false;
            }
            if (i > 0) {
                i --;
            } else {
                break;
            }
        }
    }

    //为添加流动性的人分红
    function splitLPHolderToken() private {
        address user;
        uint256 totalAmount = IERC20(pair).totalSupply();
        uint256 rate;

        uint256 buySize = buyUser.length;
        uint256 thisTimeSize = currentSplitIndex + splitTimesPerTran > buySize ? buySize : currentSplitIndex + splitTimesPerTran;
        uint256 userAmt;
        for(uint256 i = currentSplitIndex; i < thisTimeSize; i++){
            user = buyUser[i];

            rate = IERC20(pair).balanceOf(user) * 1000000 / totalAmount;
            userAmt = swapTokensAtAmount * rate / 1000000;

            if (userAmt > 1e17) {
                if(processingLPHolderDividendTokenNum < userAmt){
                    currentSplitIndex = buySize;
                    break;
                }
                _basicTransfer(address(this), user, userAmt);
                processingLPHolderDividendTokenNum -= userAmt;
                if(processingLPHolderDividendTokenNum == userAmt){
                    currentSplitIndex = buySize;
                    break;
                }
            }

            currentSplitIndex ++;
        }

        if(currentSplitIndex >= buySize){
            currentSplitIndex = 0;
            if(processingLPHolderDividendTokenNum > 0){
                waitLPHolderDividendTokenNum += processingLPHolderDividendTokenNum;
            }
        }
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

    function totalSupply() public view returns (uint256) {
        uint256 totalRewardFromNft = 0;
        if (address(myNftEX) != address(0)) {
            totalRewardFromNft = myNftEX.totalRewards();
        }
        return _totalSupply + totalRewardFromNft;
    }

    function maxSupply() public view returns(uint256) {
        return _maxSupply;
    }

    //奖励供应
    function setRewardSupply(uint256 _rewardSupply) public onlyOwner {
        rewardSupply = _rewardSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        uint256 balance = _balances[account];
        if (address(myNftEX) != address(0))
            balance += myNftEX.currentReward(account);
        return balance;
    }

    function _beforeTokenTransfer(
        address from,
        address to
    ) internal {
        if (address(myNftEX) == address(0))
            return;
        myNftEX.claimRewards(from);
        myNftEX.claimRewards(to);
    }

    function refreshTotalSupply() public returns (uint256) {
        if (address(myNftEX) == address(0))
            return 0;
        require(msg.sender == address(myNftEX), "[METoken] This function can be called only from reward NFT!");
        _totalSupply += myNftEX.totalRewards();
        return _totalSupply;
    }

    function _basicTransfer(address from, address to, uint256 amount) internal {

        uint256 fromBalance = _balances[from];
        require(
            fromBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );

        _balances[from] = fromBalance - amount;
        _balances[to] += amount;

        emit Transfer(from, to, amount);
    }

    function _transferWithBuyFee(address from, address to, uint256 amount) internal {
        uint256 feeAmount = (amount * _totalBuyFee) / _feeRate;
        uint256 tAmount = amount - feeAmount;
        uint256 amountA = (feeAmount * 200) / _totalBuyFee;
        uint256 amountB = (feeAmount * 200) / _totalBuyFee;
        uint256 amountC = (feeAmount * 200) / _totalBuyFee;
        uint256 amountD = (feeAmount * 200) / _totalBuyFee;

        _basicTransfer(from, address(this), amountA);//LP分红
        waitLPHolderDividendTokenNum += amountA;

        _basicTransfer(from, address(this), amountB);//币值管理
        waitTrustenshipTokenNum += amountB;

        _burn(from,amountC);//黑洞

        _basicTransfer(from, _security_fund, amountD);//保障池
        _basicTransfer(from, to, tAmount);
    }

    function _transferWithSellFee(address from, address to, uint256 amount) internal {
        uint256 feeAmount = (amount * _totalSellFee) / _feeRate;
        uint256 tAmount = amount - feeAmount;
        uint256 amountA = (feeAmount * 200) / _totalSellFee;
        uint256 amountB = (feeAmount * 200) / _totalSellFee;
        uint256 amountC = (feeAmount * 200) / _totalSellFee;
        uint256 amountD = (feeAmount * 200) / _totalSellFee;
        uint256 amountE = (feeAmount * 400) / _totalSellFee;

        _basicTransfer(from, address(this), amountA);//LP分红
        waitLPHolderDividendTokenNum += amountA;

        _basicTransfer(from, address(this), amountB);//自动LP
        waitAutoLPTokenNum += amountB;

        _burn(from,amountC);//黑洞

        _basicTransfer(from, _security_fund, amountD);//保障池
        _basicTransfer(from, _dao_reward, amountE);//DAO
        _basicTransfer(from, to, tAmount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount,"ERC20: burn transfer amount exceeds balance");
        require(
            _totalSupply >= amount,
            "ERC20: burn transfer amount exceeds totalSupply"
        );
    unchecked {
        _balances[account] = accountBalance - amount;
    }
        _totalSupply -= amount;
        _balances[address(0)] = _balances[address(0)] + amount;
        _totalBurn += amount;
        emit Transfer(account, address(0), amount);
    }

    //ME兑换USDT
    function swapTokens(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = address(usdt);
        // make the swap
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            manager,
            block.timestamp
        );
    }

    //兑换USDT并转给币值管理
    function swapUSDTTOTrusteeship(uint256 tokenAmount) private swapping{
        uint256 initialBalance = usdt.balanceOf(manager);
        swapTokens(tokenAmount);
        uint256 newBalance = usdt.balanceOf(manager) - initialBalance;
        usdt.transferFrom(manager, _token_trusteeship, newBalance);
    }

    //兑换自动LP
    function swapAndLiquify(uint256 contractTokenBalance) private swapping {
        // split the contract balance into halves
        uint256 half = contractTokenBalance / 2;
        uint256 otherHalf = contractTokenBalance - half;

        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = usdt.balanceOf(manager);

        swapTokens(half);

        // how much ETH did we just swap into?
        uint256 newBalance = usdt.balanceOf(manager) - initialBalance;

        // add liquidity to uniswap
        usdt.transferFrom(manager, address(this), newBalance);
        addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function autoLP() private {
        bool overMinTokenBalance = waitAutoLPTokenNum >= numTokensToAddToLiquidity;
        if (overMinTokenBalance) {
            // add liquidity
            waitAutoLPTokenNum = waitAutoLPTokenNum - numTokensToAddToLiquidity;
            swapAndLiquify(numTokensToAddToLiquidity);
        }
        emit AutoLP(overMinTokenBalance);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to);

        if(from == address(this) || to == address(this) || from == _meConsensus){
            _basicTransfer(from, to, amount);
            return;
        }

        if (!inSwap){
            //分红
            if(currentSplitIndex > 0 || waitLPHolderDividendTokenNum >= swapTokensAtAmount){
                if(currentSplitIndex == 0){
                    processingLPHolderDividendTokenNum = swapTokensAtAmount;
                    waitLPHolderDividendTokenNum -= swapTokensAtAmount;
                }
                splitLPHolderToken();
            } else {
                clearBuyUser();
            }

            if(from != pair){
                //处理币值管理
                if(waitTrustenshipTokenNum > 0 ){
                    swapUSDTTOTrusteeship(waitTrustenshipTokenNum);//币值管理
                    waitTrustenshipTokenNum = 0;
                }
                //自动LP
                autoLP();

            }
        }

        if (inSwap) {
            // swaping
            _basicTransfer(from, to, amount);
        } else if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            // excluded from fee
            _basicTransfer(from, to, amount);
        } else if (from == pair) {
            // buy
            _transferWithBuyFee(from, to, amount);
        } else if (to == pair) {
            // sell
            _transferWithSellFee(from, to, amount);
        } else {
            // normal transfer
            _basicTransfer(from, to, amount);
        }

        if(!havePushBuyUser[from] && to == pair) {
            havePushBuyUser[from] = true;
            buyUser.push(from);
        }

    }

    function transfer(address to, uint256 amount) public returns (bool) {
        address owner = msg.sender;
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(address owner, address spender)
    public
    view
    returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, amount);
        return true;
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

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount,
                "ERC20: insufficient allowance"
            );
            _approve(owner, spender, currentAllowance - amount);
        }
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public returns (bool) {
        address spender = msg.sender;
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function setMyNFTEX(address myNftEXAddr) public onlyOwner {
        myNftEX = MyNftEX(myNftEXAddr);
    }

    function setMeConsensus(address meConsensusAddr) public onlyOwner {
        _meConsensus = meConsensusAddr;
    }

    modifier onlyNFT() {
        if (address(myNftEX) == address(0))
            return;
        require(msg.sender == address(myNftEX), "[METoken] This function can be called only from reward NFT!");
        _;
    }

    function refreshBalance(address account) public onlyNFT {
        uint256 amount = myNftEX.rewardBalance(account);
        _balances[account] += amount;
    }

    function increaseBalance(address account, uint256 amount) public onlyNFT {
        _balances[account] += amount;
        _totalSupply += amount;

        //停止发币
        if( totalSupply() + _totalBurn >= _maxSupply )
            myNftEX.setRewardStop(block.timestamp);
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(router), tokenAmount);
        usdt.approve(address(router), ethAmount);
        router.addLiquidity(
            address(this),
            address(usdt),
            tokenAmount,
            ethAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
                manager,
            block.timestamp
        );
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}