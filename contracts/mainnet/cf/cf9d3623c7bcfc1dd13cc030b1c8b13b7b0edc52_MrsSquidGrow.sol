/**
 *Submitted for verification at BscScan.com on 2022-08-05
*/

/**
 https://t.me/MrsSquidGrowPortal
*/

pragma solidity 0.8.4;
// SPDX-License-Identifier: Unlicensed

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

interface PancakeSwapFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface PancakeSwapRouter {
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

// Contracts and libraries

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {return 0;}
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        authorizations[_owner] = true;
        emit OwnershipTransferred(address(0), msgSender);
    }
    mapping (address => bool) internal authorizations;

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }


    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract MrsSquidGrow is Ownable, IBEP20 {
    using SafeMath for uint256;

    uint8 constant _decimals = 18;

    uint256 _totalSupply = 100000000000 * (10 ** _decimals);
    uint256 public _maxTxAmount = _totalSupply * 1000 / 1000;
    uint256 public _walletMax = _totalSupply * 10 / 1000;
    address public lpToken = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    address DEAD_WALLET = 0x000000000000000000000000000000000000dEaD;
    address ZERO_WALLET = 0x0000000000000000000000000000000000000000;

    address pancakeAddress = 0x10ED43C718714eb63d5aA57B78B54704E256024E;

    string constant _name = "MrsSquidGrow";
    string constant _symbol = "MrsSquidGrow";

    bool public restrictWhales = true;

    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;

    mapping(address => bool) public isFeeExempt;
    mapping(address => bool) public isTxLimitExempt;

    uint256 public liquidityFee = 1;
    uint256 public marketingFee = 9;
    uint256 public devFee = 0;
    uint256 public extraSellFee = 0;

    uint256 private oldLiquidityFee = liquidityFee;
    uint256 private oldMarketingFee = marketingFee;
    uint256 private oldDevFee = devFee;

    uint256 public totalFee = 0;
    uint256 public totalFeeIfSelling = 0;

    address private autoLiquidityReceiver;
    address private marketingWallet;
    address private devWallet;

    PancakeSwapRouter public router;
    address public pair;

    uint256 public launchedAt;
    bool public tradingOpen = true;
    bool public blacklistMode = true;
    bool public canBlacklist = true;
    mapping(address => bool) public isBlacklisted;

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    bool public swapAndLiquifyByLimitOnly = false;
    bool public takeBuyFee = true;
    bool public takeSellFee = true;
    bool public takeTransferFee = false;
    bool public happyHour = false;

    uint256 public swapThreshold = _totalSupply * 6 / 2000;

    event AutoLiquify(uint256 amountLPTOKEN, uint256 amountBOG);

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor() {
        router = PancakeSwapRouter(pancakeAddress);
        pair = PancakeSwapFactory(router.factory()).createPair(lpToken, address(this));
        _allowances[address(this)][address(router)] = type(uint256).max;
        _allowances[address(this)][address(pair)] = type(uint256).max;

        isFeeExempt[msg.sender] = true;
        isFeeExempt[address(this)] = true;
        isFeeExempt[DEAD_WALLET] = true;

        isTxLimitExempt[msg.sender] = true;
        isTxLimitExempt[pair] = true;
        isTxLimitExempt[DEAD_WALLET] = true;

        autoLiquidityReceiver = msg.sender;
        marketingWallet = 0xAdd38EA5B1c9b7c9A0E913ee33860059Cce50588;
        devWallet = 0xa2EE89738a0780770C61916c4d7ab297146Cb345;
        
        isFeeExempt[marketingWallet] = true;
        totalFee = liquidityFee.add(marketingFee).add(devFee);
        totalFeeIfSelling = totalFee;

        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable {}

    function name() external pure override returns (string memory) {return _name;}

    function symbol() external pure override returns (string memory) {return _symbol;}

    function decimals() external pure override returns (uint8) {return _decimals;}

    function totalSupply() external view override returns (uint256) {return _totalSupply;}

    function getOwner() external view override returns (address) {return owner();}

    function balanceOf(address account) public view override returns (uint256) {return _balances[account];}

    function allowance(address holder, address spender) external view override returns (uint256) {return _allowances[holder][spender];}

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD_WALLET)).sub(balanceOf(ZERO_WALLET));
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, type(uint256).max);
    }

    function launched() internal view returns (bool) {
        return launchedAt != 0;
    }

    function launch() internal {
        launchedAt = block.number;
    }

    function checkTxLimit(address sender, uint256 amount) internal view {
        require(amount <= _maxTxAmount || isTxLimitExempt[sender], "TX Limit Exceeded");
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function setBridgeOrExchange(address WTaddress) public onlyOwner{
        isFeeExempt[WTaddress] = true;
        isTxLimitExempt[WTaddress] = true;
    }
    
    function setFeeReceivers(address newMktWallet, address newDevWallet, address newLpWallet) public onlyOwner{
        autoLiquidityReceiver = newLpWallet;
        marketingWallet = newMktWallet;
        devWallet = newDevWallet;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if (_allowances[sender][msg.sender] != type(uint256).max) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }
        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        if (inSwapAndLiquify) {return _basicTransfer(sender, recipient, amount);}
        if(!authorizations[sender] && !authorizations[recipient]){
            require(tradingOpen, "Trading not open yet");
        }

        require(amount <= _maxTxAmount || isTxLimitExempt[sender], "TX Limit Exceeded");
        if (msg.sender != pair && !inSwapAndLiquify && swapAndLiquifyEnabled && _balances[address(this)] >= swapThreshold) {marketingAndLiquidity();}
        if (!launched() && recipient == pair) {
            require(_balances[sender] > 0, "Zero balance violated!");
            launch();
        }    

        // Blacklist
        if (blacklistMode) {
            require(!isBlacklisted[sender],"Blacklisted");
        }

        //Exchange tokens
         _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

        if (!isTxLimitExempt[recipient] && restrictWhales) {
            require(_balances[recipient].add(amount) <= _walletMax, "Max wallet violated!");
        }

        uint256 finalAmount = !isFeeExempt[sender] && !isFeeExempt[recipient] ? extractFee(sender, recipient, amount) : amount;
        _balances[recipient] = _balances[recipient].add(finalAmount);

        emit Transfer(sender, recipient, finalAmount);
        return true;
    }

    function marketingAndLiquidity() internal lockTheSwap {
        inSwapAndLiquify = true;        
        
        uint256 tokensToLiquify = _balances[address(this)];
        uint256 amountToLiquify = tokensToLiquify.mul(liquidityFee).div(totalFee).div(2);
        uint256 amountToSwap = tokensToLiquify.sub(amountToLiquify);

        address[] memory path_long = new address[](3);
        address[] memory path = new address[](2);

        path_long[0] = address(this);
        path_long[1] = lpToken;
        path_long[2] = router.WETH();

        // cant go to busd directly from token, need to go bia bnb
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path_long,
            address(this),
            block.timestamp
        ); 

        uint256 amountBNB = address(this).balance;
        uint256 totalBNBFee = totalFee.sub(liquidityFee.div(2));
        uint256 amountBNBLiquidity = amountBNB.mul(liquidityFee).div(totalBNBFee).div(2);
    
        uint256 amountBNBMarketing = amountBNB.mul(marketingFee).div(totalBNBFee);
        uint256 amountBNBDev = amountBNB.mul(devFee).div(totalBNBFee);
    
        (bool tmpSuccess1,) = payable(marketingWallet).call{value: amountBNBMarketing, gas: 30000}("");
        (bool tmpSuccess2,) = payable(devWallet).call{value: amountBNBDev, gas: 30000}("");

        path[0] = router.WETH();
        path[1] = lpToken;
        
        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amountBNBLiquidity}(
            0,
            path,
            address(this),
            block.timestamp
        );
     
        // only to supress warning msg
        tmpSuccess1 = false;
        tmpSuccess2 = false;

        uint256 amountLPIDk = amountToLiquify;

        if(amountToLiquify > 0){
            inSwapAndLiquify = true;

            uint256 lpTokenBalance = IBEP20(lpToken).balanceOf(address(this));            
            IBEP20(lpToken).approve(address(router), lpTokenBalance);        

            router.addLiquidity(
                lpToken,
                address(this),
                lpTokenBalance,                
                amountLPIDk,
                0,
                0,
                autoLiquidityReceiver,
                block.timestamp
            );    

            emit AutoLiquify(lpTokenBalance, amountLPIDk);
        }

        inSwapAndLiquify = false;

    }

    function extractFee(address sender, address recipient, uint256 amount) internal returns (uint256) {
        uint feeApplicable = 0;
        if (recipient == pair && takeSellFee) {
            feeApplicable = totalFeeIfSelling;        
        }
        if (sender == pair && takeBuyFee) {
            feeApplicable = totalFee;        
        }
        if (sender != pair && recipient != pair){
            if (takeTransferFee){
                feeApplicable = totalFeeIfSelling; 
            }
            else{
                feeApplicable = 0;
            }
        }
        uint256 feeAmount = amount.mul(feeApplicable).div(100);

        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);

        return amount.sub(feeAmount);
    }


    // CONTRACT OWNER FUNCTIONS

    function setWalletLimitPercent1000(uint256 newLimit) external onlyOwner {
        require(newLimit >= 10, "Limit must be at least 1%");
        _walletMax = _totalSupply * newLimit / 1000;
    }

    function setTxLimitPercent1000(uint256 newLimit) external onlyOwner {
        require(newLimit >= 5, "Limit must be at least 0.5%");
        _maxTxAmount = _totalSupply * newLimit / 1000;
    }

    function openTrading() public onlyOwner {
        tradingOpen = true;
    }

    function setIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
    }

    function setIsTxLimitExempt(address holder, bool exempt) external onlyOwner {
        isTxLimitExempt[holder] = exempt;
    }

    function setTakeBuyfee(bool status) public onlyOwner{
        takeBuyFee = status;
    }

    function setTakeSellfee(bool status) public onlyOwner{
        takeSellFee = status;
    }

    function setTakeTransferfee(bool status) public onlyOwner{
        takeTransferFee = status;
    }

    function manualMarketingAndLiquidity() external onlyOwner {
        marketingAndLiquidity();
    }

    function setFees(uint256 newLiqFee, uint256 newMarketingFee, uint256 newDevFee, uint256 newExtraSellFee) external onlyOwner {
        require(!happyHour, "Happy hour is active");
        liquidityFee = newLiqFee;
        marketingFee = newMarketingFee;
        devFee = newDevFee;

        totalFee = liquidityFee.add(marketingFee).add(devFee);
        totalFeeIfSelling = totalFee + newExtraSellFee;
        require (totalFeeIfSelling < 15);
    }

    function startHappyHour() external onlyOwner {
        happyHour = true;
        takeBuyFee = false;
        oldLiquidityFee = liquidityFee;
        oldMarketingFee = marketingFee;
        oldDevFee = devFee;
        liquidityFee = 5;
        marketingFee = 10;
        devFee = 0;
        totalFee = liquidityFee.add(marketingFee).add(devFee);
        totalFeeIfSelling = totalFee;
    }

    function endHappyHour() external onlyOwner {
        happyHour = false;
        takeBuyFee = true;
        liquidityFee = oldLiquidityFee;
        marketingFee = oldMarketingFee;
        devFee = oldDevFee;
        totalFee = liquidityFee.add(marketingFee).add(devFee);
        totalFeeIfSelling = totalFee + extraSellFee;
    }

    function disableNewBlacklists() public onlyOwner {
        canBlacklist = false;
    }

    function enable_blacklist(bool _status) public onlyOwner {
        blacklistMode = _status;
    }

    function manage_blacklist(address[] calldata addresses, bool status) public onlyOwner {
        require(canBlacklist, "Blacklisting is disabled");
        for (uint256 i; i < addresses.length; ++i) {
            require(addresses[i] != address(this), "Cannot blacklist yourself");
            require(addresses[i] != pancakeAddress, "Cannot blacklist the Pancake Swap Router");
            require(addresses[i] != pair, "Cannot blacklist the Pancake LP Pool");
            isBlacklisted[addresses[i]] = status;
        }
    }

    function rescueToken(address tokenAddress, uint256 tokens) public returns (bool success) {
        require(tokenAddress != address(this), "You can't rescue your own token");
        return IBEP20(tokenAddress).transfer(devWallet, tokens);
    }

    function clearStuckBalance(uint256 amountPercentage) external {
        uint256 amountETH = address(this).balance;
        payable(devWallet).transfer(amountETH * amountPercentage / 100);
    }

    function multiTransfer_fixed( address[] calldata addresses, uint256 tokens) external onlyOwner {
        require(addresses.length < 2001,"GAS Error: max airdrop limit is 2000 addresses"); // to prevent overflow
        uint256 SCCC = tokens * addresses.length;
        require(balanceOf(msg.sender) >= SCCC, "Not enough tokens in wallet");
        for(uint i=0; i < addresses.length; i++){
            _basicTransfer(msg.sender, addresses[i], tokens);
        }
    }
    
}