/**
 *Submitted for verification at BscScan.com on 2022-09-07
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// pragma solidity >=0.5.0;

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


// pragma solidity >=0.5.0;

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

    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// pragma solidity >=0.6.2;

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

// pragma solidity >=0.6.2;

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

contract Initialize is IERC20, Ownable {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    address payable public marketingAddress;

    bool private swapping;

    uint256 public numTokensSellDivisor;
    uint256 public maxTxAmount;
    uint256 public maxWalletAmount;

    mapping (address => bool) private _isExcludedFromFees;
    mapping (address => bool) private _isExcludedFromSellCooldown;
    mapping (address => bool) private _isExcludedFromMaxWallet;

    // store addresses that are automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping (address => bool) public automatedMarketMakerPairs;

    // amount of native token that was initialized for a given address
    mapping (address => uint256) private initialization;
    uint256 public initializationAccumulation;

    mapping (address => uint256) private lastSell;
    uint256 public sellCooldown;

    bool private awarding;
    uint256 public lastBuy;
    uint256 public jackpotMinimumBuy;
    uint256 public jackpotDelay;
    uint256 public jackpotLimit;
    address private lastJackpotWinner;
    uint256 private lastJackpotAmount;
    uint256 private lastJackpotTimestamp;

    uint256 public liquidityFee;
    uint256 public marketingFee;
    uint256 public jackpotFee;

    mapping(address => bool) private blacklist;

    event addedLiquidity(uint256 tokenAmount, uint256 ethAmount);

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 totalSupply_,
        address uniswapV2Router_,
        address marketingAddress_
    ) payable {
        maxTxAmount = totalSupply_.div(1000);
        maxWalletAmount = totalSupply_.div(100);

        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;

        if (uniswapV2Router_ != address(0)) {
            IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(uniswapV2Router_);
            
             // Create a uniswap pair for this new token
            address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
                .createPair(address(this), _uniswapV2Router.WETH());
            
            uniswapV2Router = _uniswapV2Router;
            uniswapV2Pair = _uniswapV2Pair;

            automatedMarketMakerPairs[_uniswapV2Pair] = true;

            _approve(address(this), address(uniswapV2Router), totalSupply_);
            _approve(address(this), uniswapV2Pair, totalSupply_);
        }

        marketingAddress = payable(marketingAddress_);

        _isExcludedFromFees[owner()] = true;
        _isExcludedFromFees[address(this)] = true;
        _isExcludedFromFees[address(marketingAddress)] = true;

        _isExcludedFromMaxWallet[owner()] = true;
        _isExcludedFromMaxWallet[address(this)] = true;
        _isExcludedFromMaxWallet[address(uniswapV2Pair)] = true;
        _isExcludedFromMaxWallet[address(marketingAddress)] = true;

        sellCooldown = 604800;

        jackpotMinimumBuy = 10**17;
        jackpotDelay = 900;
        jackpotLimit = 10**18;

        numTokensSellDivisor = totalSupply_.div(10000);

        liquidityFee = 30;
        marketingFee = 20;
        jackpotFee = 10;

        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(owner(), totalSupply_);
    }

    // must be here to receive BNB
    receive() external payable {
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint8) {
        return _decimals;
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
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
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
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");

        require(!blacklist[sender], "Sender is backlisted.");
        require(!blacklist[recipient], "Recipient is backlisted.");

        if (sender != owner() && recipient != owner()) {
            require(amount <= maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
        }

        if (!_isExcludedFromMaxWallet[recipient]) {
             require((balanceOf(recipient) + amount) <= maxWalletAmount, "Maximum wallet amount will be reached.");
        }

        _beforeTokenTransfer(sender, recipient, amount);

        if(amount == 0) {
             _transferAmount(sender, recipient, 0);
            return;
        }
        
        uint256 contractTokenBalance = balanceOf(address(this));
        uint256 swapTokensAtAmount = _totalSupply.div(numTokensSellDivisor);

        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if (canSwap &&
            !swapping &&
            !automatedMarketMakerPairs[sender] &&
            sender != owner() &&
            recipient != owner()
        ) {
            swapping = true;

            if (contractTokenBalance > 0) {
                swapAndLiquify(swapTokensAtAmount);
            }
            
            swapping = false;
        }

        bool takeFee = !swapping;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFees[sender] || _isExcludedFromFees[recipient]) {
            takeFee = false;
        }

        uint256 _liquidityFee = 0;
        uint256 _marketingFee = 1000;
        uint256 _jackpotFee = 0;

        if (automatedMarketMakerPairs[sender]) {
            _liquidityFee = liquidityFee;
            _marketingFee = marketingFee;
            _jackpotFee = jackpotFee;

            uint256 amountOut = 0;

            if (!awarding && (address(this).balance > 0) && ((block.timestamp - lastBuy) >= jackpotLimit)) {
                amountOut = getAmountOut(amount);

                if (amountOut >= jackpotMinimumBuy) {
                    awarding = true;

                    uint256 jackpotAmount = (address(this).balance > jackpotLimit) ? jackpotLimit : address(this).balance;
                    (bool success, /* bytes memory data */) = recipient.call{value: jackpotAmount}("");

                    if (success) {
                        lastJackpotWinner = address(recipient);
                        lastJackpotAmount = jackpotAmount;
                        lastJackpotTimestamp = block.timestamp;
                    }

                    awarding = false;
                }
            }

            if (!isInitialized(recipient)) {
                amountOut = (amountOut > 0) ? amountOut : getAmountOut(amount);
                initialization[recipient] = amountOut;
            }

            lastBuy = block.timestamp;
        }

        if (automatedMarketMakerPairs[recipient]) {
            _liquidityFee = liquidityFee;
            _marketingFee = marketingFee;
            _jackpotFee = jackpotFee;

            require((_isExcludedFromSellCooldown[sender]) || ((block.timestamp - lastSell[sender]) >= sellCooldown), "Initialize: Sell cooldown is active for that address.");

            if (isInitialized(sender)) {
                uint256 amountOut = getAmountOut(amount);
                require(amountOut <= getInitializationAccumulation(sender), "Initialize: Sell amount exceeds initialization of that address.");
                lastSell[sender] = block.timestamp;
            }
        }

        if (takeFee && ((liquidityFee + marketingFee + jackpotFee) > 0)) {
            uint256 fees = amount.mul(_liquidityFee).div(1000).add(amount.mul(_marketingFee).div(1000).add(amount.mul(_jackpotFee).div(1000)));

            amount = amount.sub(fees);

            _transferAmount(sender, address(this), fees);
        }
    
        _transferAmount(sender, recipient, amount);
    }

    function _transferAmount(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        _balances[sender] = _balances[sender].sub(
            amount,
            "ERC20: transfer amount exceeds balance"
        );
        _balances[recipient] = _balances[recipient].add(amount);

        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(
            amount,
            "ERC20: burn amount exceeds balance"
        );
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
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

    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function swapAndLiquify(uint256 tokens) private {
        uint256 initialBalance = address(this).balance;
        uint256 totalFees = liquidityFee + marketingFee + jackpotFee;

        uint256 liquidityTokens = tokens.mul(liquidityFee).div(totalFees).div(2);
        uint256 remainingTokens = tokens - liquidityTokens;

        swapTokensForEth(remainingTokens);

        uint256 newBalance = address(this).balance.sub(initialBalance);
        uint256 marketingBalance = newBalance.mul(marketingFee).div(totalFees);
        uint256 jackpotBalance = newBalance.mul(jackpotFee).div(totalFees);
        uint256 liquidityBalance = newBalance.sub(marketingBalance.add(jackpotBalance));

        addLiquidity(liquidityTokens, liquidityBalance);

        (bool success, /* bytes memory data */) = marketingAddress.call{value: marketingBalance}("");

        require(success, "Initialize: Could not transfer liquified tokens to marketing address.");
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        //_approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp.add(30)
        );

    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios

        //_approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this),
            block.timestamp.add(300)
        );

        emit addedLiquidity(tokenAmount, ethAmount);
    }

    function getAmountOut(uint256 amountIn) private view returns(uint256) {
        address[] memory path;
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        uint256[] memory amountsOut = uniswapV2Router.getAmountsOut(amountIn, path);

        return amountsOut[1];
    }

    function getInitializationAccumulation(address account) private view returns(uint256) {
        uint256 timeElapsed = block.timestamp - lastSell[account];
        uint256 initializationMultiplier = timeElapsed / sellCooldown;
        return initialization[account].mul(initializationMultiplier);
    }

    function setFees(uint256 liquidityFee_, uint256 marketingFee_, uint256 jackpotFee_) external onlyOwner {
        liquidityFee = liquidityFee_;
        marketingFee = marketingFee_;
        jackpotFee = jackpotFee_;
    }

    function excludeFromFees(address account) public onlyOwner {
        _isExcludedFromFees[account] = true;
    }
    
    function includeInFees(address account) public onlyOwner {
        _isExcludedFromFees[account] = false;
    }

    function setRouterAddress(address newRouter) public onlyOwner() {
        IUniswapV2Router02 _newPancakeRouter = IUniswapV2Router02(newRouter);
        uniswapV2Pair = IUniswapV2Factory(_newPancakeRouter.factory()).createPair(address(this), _newPancakeRouter.WETH());
        uniswapV2Router = _newPancakeRouter;
        _approve(address(this), address(uniswapV2Router), _totalSupply);
    }

    function rescueToken(address token, address to) external onlyOwner {
        IERC20(token).transfer(to, IERC20(token).balanceOf(address(this)));
    }

    function setBlacklist(address address_, bool status_) external onlyOwner {
        blacklist[address_] = status_;
    }

    function isBlacklisted(address address_) external view returns(bool) {
        return blacklist[address_];
    }

    function setMaxTxAmount(uint256 maxTxAmount_) external onlyOwner {
        maxTxAmount = maxTxAmount_;
    }

    function setMaxWalletAmount(uint256 maxWalletAmount_) external onlyOwner {
        maxWalletAmount = maxWalletAmount_;
    }

    function setNumTokensSellDivisor(uint256 numTokensSellDivisor_) external onlyOwner {
        numTokensSellDivisor = numTokensSellDivisor_;
    }

    function setAutomatedMarketMakerPairs(address address_, bool status_) external onlyOwner {
        automatedMarketMakerPairs[address_] = status_;
    }

    function burnTokens(uint256 tokenAmount_) external onlyOwner {
        _burn(owner(), tokenAmount_);
    }

    function isInitialized(address address_) public view returns (bool) {
        return abi.encodePacked(initialization[address_]).length > 0 ? true : false;
    }

    function getInitialization(address address_) public view returns (uint256) {
        return initialization[address_];
    }

    function getLastSell(address address_) public view returns (uint256) {
        return lastSell[address_];
    }

    function setSellCooldown(uint256 sellCooldown_) external onlyOwner {
        sellCooldown = sellCooldown_;
    }

    function excludeFromSellCooldown(address address_, bool status_) external onlyOwner {
        _isExcludedFromSellCooldown[address_] = status_;
    }

    function excludeFromMaxWallet(address address_, bool status_) external onlyOwner {
        _isExcludedFromMaxWallet[address_] = status_;
    }

    function setMarketingAddress(address payable address_) external onlyOwner {
        marketingAddress = address_;
    }

    function setJackpotSettings(uint256 jackpotMinimumBuy_, uint256 jackpotDelay_, uint256 jackpotLimit_) external onlyOwner {
        jackpotMinimumBuy = jackpotMinimumBuy_;
        jackpotDelay = jackpotDelay_;
        jackpotLimit = jackpotLimit_;
    }

    function getLastJackpot() public view returns (address, uint256, uint256) {
        return (lastJackpotWinner, lastJackpotAmount, lastJackpotTimestamp);
    }

    function setInitializationAccumulation(uint256 initializationAccumulation_) external onlyOwner {
        initializationAccumulation = initializationAccumulation_;
    }
}