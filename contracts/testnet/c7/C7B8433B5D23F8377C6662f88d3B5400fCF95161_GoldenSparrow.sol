/**
 *Submitted for verification at BscScan.com on 2022-08-08
*/

/******************************************************************************
Token Name : GOLDEN SPARROW
Short Name : GST
Total Supply : 1000000000000 GST
Decimal : 18
Platform : BEP20 
Project Name : Golden Sparrow !
Website Link : https://www.goldensparrow.info
Whitepaper Link : https://www.goldensparrow.info/assets/file/GST_Whitepaper.pdf
Facebbok : https://www.facebook.com/Golden-Sparrow-Token-104806088937264
Twitter : https://twitter.com/RealGSTArmy?t=KcwL2Acee3_ieRJb2wkQyg&s=09
Telegram : https://telegram.me/+kPIlcohyp6FmYmE1  
Linkdin :  https://www.linkedin.com/in/golden-sparrow-token-86b12b242
Instagram : https://www.instagram.com/goldensparrowtoken/
Publish Date : 06 Aug 2022
********************************************************************************/
//SPDX-License-Identifier: Unlicensed
/* Interface Declaration */
pragma solidity ^0.6.12;
interface IBEP20 {
    /* Get Total Supply */
    function totalSupply() external view returns (uint256);
    /* Get Decimal Places */
    function decimals() external view returns (uint8);
    /* Get Token Symbol OR Short Name */
    function symbol() external view returns (string memory);
    /* Get Token Name */
    function name() external view returns (string memory);
    /* Get Owner Wallet Address */
    function getOwner() external view returns (address);
    /* Get Balance of GST Token of any Wallet Address */
    function balanceOf(address account) external view returns (uint256);
    /* Transfer GST Token on Any Address */
    function transfer(address recipient, uint256 amount) external returns (bool);
    /* Check Allowance of An User of Spender Platform */
    function allowance(address _owner, address spender) external view returns (uint256);
    /* Approve The Amount for Allowance on Spender Platform */
    function approve(address spender, uint256 amount) external returns (bool);
    /* Transfer From Is Basically Used For Transfer on Spender Address After approve the Amount for Spend */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    /* Transfer Event */
    event Transfer(address indexed from, address indexed to, uint256 value);
    /* Approval Event */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
/* Abstract Contract */
//pragma solidity ^0.6.0;
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/bnbereum/solidity/issues/2691
        return msg.data;
    }
}
/* Library For Airthmatic Operation */
//pragma solidity ^0.6.0;
library SafeMath {
    /* Addition of Two Number */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    /* Subscription of Two Number */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }
    /* Multiplication of Two Number */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    /* Divison of Two Number */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
    /* Modulus of Two Number */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
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

interface IUniswapV2Router02 is IUniswapV2Router01 {
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
/* Token Main Contract */
//pragma solidity ^0.6.0;
contract GoldenSparrow is Context, IBEP20 {

    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isIncludedForFee;
    mapping (address => bool) internal _isWhitelistedForFee;
    mapping (address => bool) private _isExcludeForRefelection;
    address[] public reflectionHolders;
    mapping (address => bool) public reflectionpoolEligible;
    mapping (address => bool) public checkUserBlocked;

    struct UserLastSellDetails {
        uint lastSellDateTime;
    }
    mapping (address => UserLastSellDetails) public _UserLastSellDetails;

    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 _sellTimeInterval;

    /* Section For Set Or Manage Sell Tax */

    address public marketingWalletAddress;
    address public submarketingWalletAddress;

    bool public isSellTaxApplicable = false;
    uint public _sellreflectionsPer=3;
    uint public _sellliquidityPer=1;
    uint public _sellmarketingPer=2;
    uint public _sellsubmarketingPer=5;
    uint public _sellburnPer=1;

    /* Section For Set Or Manage Buy Tax */
    bool public isBuyTaxApplicable = false;
    uint public _buymarketingPer=2;
    uint public _buysubmarketingPer=5;    
    uint public _buyburnPer=1;

    /* Minimum & Maximum Transaction Liits */
    uint256 private _maxTransferLimits;
    uint256 private _minTransferLimits;
    uint256 private _maxAntiWhaleLimits;
    uint256 private _minAntiWhaleLimits;

    bool private paused = false;
    bool private reflectionstatus = true;
    bool private canPause = true;
    address private _owner;

    constructor() public {
       _owner = 0x8113090BA0D32330DE1C02AB0963fA4C16821AA9;
       _name = "GOLDEN SPARROW";
       _symbol = "GST";
       _decimals = 18;
	   _totalSupply = 1000000000000000000000000000000;
       _balances[_owner] = _balances[_owner].add(_totalSupply);
       //exclude owner and this contract from fee
       _isWhitelistedForFee[_owner] = true;
       _isWhitelistedForFee[address(this)] = true;
       emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Pause();
    event Unpause();
    event UpdateMarketingWalletAddress();
    event UpdateSubMarketingWalletAddress();
    event UpdateLiquidityWalletAddress();
	event BlockWalletAddress();
    event UnblockWalletAddress();
    event SetSellTimeInterval();
    event UpdateRouter();

    /* Code For Pancake Swap Router Start Here */

    IUniswapV2Router02 public uniswapV2Router; // Set Variable

    function _swapTokensForEth(uint256 _amount) private returns(bool) {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), _amount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            _amount,
            0,
            path,
            address(this),
            block.timestamp
        );
        return true;
    }

    function _addLiquidity(uint256 _amount, uint256 _ethAmount) private {
        _approve(address(this), address(uniswapV2Router), _amount);
        uniswapV2Router.addLiquidityETH{value: _ethAmount}(
            address(this),
            _amount,
            0, 
            0, 
            address(this),
            block.timestamp
        );
    }

    function _liquidityFee(uint256 liquidityFeeAmount) private returns(uint256) {
        uint256 half = liquidityFeeAmount / 2;
        uint256 otherHalf = liquidityFeeAmount - half;
        uint256 initialBalance = address(this).balance;
        _swapTokensForEth(half);
        uint256 newBalance = address(this).balance - initialBalance;
        _addLiquidity(otherHalf, newBalance);
        return liquidityFeeAmount;
    }

    function _marketingFee(uint marketingFeeAmount) private {
        _swapTokensForEth(marketingFeeAmount);
        payable(marketingWalletAddress).transfer(IBEP20(uniswapV2Router.WETH()).balanceOf(address(this)));
    }

    function _subMarketingFee(uint subMarketingFeeAmount) private {
        _swapTokensForEth(subMarketingFeeAmount);
        payable(submarketingWalletAddress).transfer(IBEP20(uniswapV2Router.WETH()).balanceOf(address(this)));
    }

    /* Code For Pancake Swap Router End Here */
    /*Throws if called by any account other than the owner.*/
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
   /* Smart Contract Owner Can Pause The Token Transaction if And Only If canPause is true */
   function pause() onlyOwner public {
        require(canPause == true,"Pause Feature Is Not Enabled !");
        paused = true;
        emit Pause();
   } 
   /* Smart Contract Owner Can Unpause The Token Transaction if token previously paused */
    function unpause() onlyOwner public {
        require(paused == true,"Token Is No Paused Earlier !");
        paused = false;
        emit Unpause();
    }
    /* Contarct Owner to update the wallet address where marketing fee will recived */
    function update_marketingWalletAddress(address _marketingWalletAddress,address _submarketingWalletAddress) onlyOwner public {
        marketingWalletAddress = _marketingWalletAddress;
        submarketingWalletAddress = _submarketingWalletAddress;
        reflectionpoolEligible[marketingWalletAddress] = true;
        reflectionpoolEligible[submarketingWalletAddress] = true;
        emit UpdateMarketingWalletAddress();
    }
    /* Contract Owner can update Router */
    function update_Router(address routerAddress) onlyOwner public {
        uniswapV2Router=IUniswapV2Router02(routerAddress);
        emit UpdateRouter();
    }
	/* Contract Owner can block wallet address in case any needed */
    function block_WalletAddress(address WalletAddress) onlyOwner public {
        checkUserBlocked[WalletAddress] = true;
        emit BlockWalletAddress();
    }
    /* Contract Owner can un block wallet address that earlier blocked */
    function unblock_WalletAddress(address WalletAddress) onlyOwner public {
        checkUserBlocked[WalletAddress] = false;
        emit UnblockWalletAddress();
    }
    /* Contract Owner can set Sell Time Interval */
    function set_sellTimeInterval(uint256 sellTimeInterval) onlyOwner public {
        _sellTimeInterval=sellTimeInterval;
        emit SetSellTimeInterval();
    }
    /* Contarct Owner Can Enable OR Disable The Sell Tax */
    function _isSellTaxApplicable(bool status) public onlyOwner {
        isSellTaxApplicable=status;
    }
    /* Contarct Owner Can Enable OR Disable The Buy Tax */
    function _isBuyTaxApplicable(bool status) public onlyOwner {
        isBuyTaxApplicable=status;
    }
    /* Contarct Owner Can Update The Minimum & Maximum Transaction Limits */
    function update_TransactionLimits(uint256 minTransferLimits,uint256 maxTransferLimits,uint256 maxAntiWhaleLimits,uint256 minAntiWhaleLimits) public onlyOwner {
       _minTransferLimits=minTransferLimits;
       _maxTransferLimits=maxTransferLimits;
       _maxAntiWhaleLimits=maxAntiWhaleLimits;
       _minAntiWhaleLimits=minAntiWhaleLimits;
    }
    /* Contarct Owner Can Include Router So That System Can Apply Fee For Buy & Sell */
    function IncludeRouterForFee(address _routeraddress) public onlyOwner {
        _isIncludedForFee[_routeraddress] = true;
    }
    /* Contarct Owner Can Execlude Router So That System Will Not Apply Any Kind of Fee For Buy & Sell */
    function ExcludeRouterForFee(address _routeraddress) public onlyOwner {
        _isIncludedForFee[_routeraddress] = false;
    }
    /* Contarct Owner Can Whitelist Any Address For Skip Buy/Sell Fee & Minimum & maximum Transaction Limits */
    function WhitelistAddress(address _walletaddress) public onlyOwner {
        _isWhitelistedForFee[_walletaddress] = true;
    }
    /* Contarct Owner Can Blacklist Any Address For That Earlier Whitelisted */
    function RemoveFromWhiteList(address _walletaddress) public onlyOwner {
        _isWhitelistedForFee[_walletaddress] = false;
    }
    /* Check Whitelist Status of Any Address */
    function checkWhitelistStatus(address _walletaddress) public view returns(bool) {
        return _isWhitelistedForFee[_walletaddress];
    }
    /* Verify Reflection Status */
    function verify_Reflection(bool _reflectionstatus) public onlyOwner {
      reflectionstatus=_reflectionstatus;
    }
    /* Check Fee Status For Router Either applicable Or Not */
    function checkRouterFeeStatus(address _routeraddress) public view returns(bool) {
        return _isIncludedForFee[_routeraddress];
    }
    /* User Can Get Total Sell Tax Percentage */
    function sellTaxPer() public view returns(uint) {
        return (_sellreflectionsPer+_sellliquidityPer+_sellmarketingPer+_sellburnPer);
    }
    /* User Can Get Total Buy Tax Percentage */
    function buyTaxPer() public view returns(uint) {
        return (_buymarketingPer+_buyburnPer);
    }
    /* Check Reflecton Status of Any Wallet */
    function checkReflectionStatus(address account) public view returns(bool) {
        return _isExcludeForRefelection[account];
    }
    /* Contarct Owner Can Execlude Any Wallet Address From Reflection Pool */
    function ExcludeFromReflection(address account) public onlyOwner {
        _isExcludeForRefelection[account] = true;
    }
    /* Contarct Owner Can Include Any Wallet Address For Reflection Pool */
    function IncludeInReflection(address account) public onlyOwner {
        _isExcludeForRefelection[account] = false;
    }
    /* Contarct Owner Can Release The Ownership From Contract IfNeeded Like No One Will Be The Owner of Contarct */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    /* Contarct Owner Can Transfer The Ownership To Any Wallet Address */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    /* Get Contarct Owner */
    function getOwner() public override view returns (address) {
        return _owner;
    }
    /* Get Decimal Places of Coin */
    function decimals() public override view returns (uint8) {
        return _decimals;
    }
    /* Get Coin Short Name */
    function symbol() public override view returns (string memory) {
        return _symbol;
    }
    /* Get Coin Full Name */
    function name() public override view returns (string memory) {
        return _name;
    }
    /* Get Toatl Supply of Coin */
    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
    /**
     * BEP20-transfer.
     *
     * Requirements:
     *
     * - recipient cannot be the zero address.
     * - the caller must have a balance of at least amount.
     */
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    /**
     * BEP20-allowance.
     */
    function allowance(address owner, address spender) external override view returns (uint256) {
        return _allowances[owner][spender];
    }
    /**
     * BEP20-approve.
     *
     * Requirements:
     *
     * - spender cannot be the zero address.
     */
    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    /**
     * BEP20-transferFrom.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {BEP20};
     *
     *   Requirements:
     * - sender and recipient cannot be the zero address.
     * - sender must have a balance of at least amount.
     * - the caller must have allowance for sender's tokens of at least
     * - amount.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
        return true;
    }
    /**
     * Automatically increases the allowance granted to spender by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {BEP20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - spender cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
    /*
     * Automatically decreases the allowance granted to spender by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {BEP20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - spender cannot be the zero address.
     * - spender must have allowance for the caller of at least
     * subtractedValue.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
        return true;
    }
    /*
    * Burn amount tokens and decreasing the total supply.
    */
    function burn(uint256 amount) public returns (bool) {
        _burn(_msgSender(), amount);
        return true;
    }
    // Get Current Time Stamp
    function getCurrentTimeStamp() public view returns(uint _timestamp){
       return (block.timestamp);
    }
    // Get no of Hour Between Two Timestamp
    function getHour(uint _startDate,uint _endDate) public view returns(uint256){
        return ((_endDate - _startDate) / 60 / 60);
    }
    function checkSellEligibility(address user) public view returns(bool){
       if(_UserLastSellDetails[user].lastSellDateTime==0) {
           return true;
       }
       else{
           uint noofHour=getHour(_UserLastSellDetails[user].lastSellDateTime,getCurrentTimeStamp());
           if(noofHour>=_sellTimeInterval){
               return true;
           }
           else{
               return false;
           }
       }
    }
    /* Update Sell Time Stamp */
    function updateSellTimestamp(address user) internal{
        UserLastSellDetails storage userLastSellDetails = _UserLastSellDetails[user];
        userLastSellDetails.lastSellDateTime=getCurrentTimeStamp();
    }
    /* Claim Token */
    function claimTokens() public onlyOwner {
        payable(_owner).transfer(address(this).balance);
    }
    /*
    * Moves tokens amount from sender torecipient.
    *
    * This is internal function is equivalent to {transfer}, and can be used to
    * e.g. implement automatic token fees, slashing mechanisms, etc.
    *
    * Emits a {Transfer} event.
    *
    * Requirements:
    *
    * - sender cannot be the zero address.
    * - recipient cannot be the zero address.
    * - sender must have a balance of at least amount.
    */
    function _transfer(address sender, address recipient, uint256 amount) internal {

      require(sender != address(0), "BEP20: transfer from the zero address !");
      require(recipient != address(0), "BEP20: transfer to the zero address !");
      require(paused != true, "BEP20: Token Is Paused now !");     
      require(checkUserBlocked[sender] != true , "BEP20: Sender Is Blocked !");
      require(checkUserBlocked[recipient] != true , "BEP20: Receiver Is Blocked !");
     
      //indicates if fee should be deducted from transfer
      bool sellFeeStatus = false;
      bool buyFeeStatus = false;   
      //if any account belongs to _isIncludedForFee account then take the fee start Fee Here
      //If User Coin Buy Then Sender Will Be Router Address of Any Defi Exchange
      if(_isIncludedForFee[sender] && isBuyTaxApplicable==true){
        buyFeeStatus = true;
      }
      //If User Coin Sell Then Receiver Will Be Router Address of Any Defi Exchange
      else if(_isIncludedForFee[recipient] && isSellTaxApplicable==true){
        sellFeeStatus = true;
      }
      //if any account belongs to _isIncludedForFee account then take the fee end Fee Here
      // Check Whitelisting Status Start Here
      if(_isWhitelistedForFee[sender]){
        buyFeeStatus = false;
      }
      //If User Coin Sell Then Receiver Will Be Router Address of Any Defi Exchange
      else if(_isWhitelistedForFee[recipient]){
        sellFeeStatus = false;
      }
      // Check Whitelisting Status End Here 
      uint256 netamount=amount;

      if(sellFeeStatus == true) {  

      require(amount <= _maxAntiWhaleLimits, "BEP20: Sell Qty Exceed !");
      require(amount >= _minAntiWhaleLimits, "BEP20: Sell Qty Does Not Match !"); 
      require(checkSellEligibility(sender), "BEP20: Try After Sell Time Interval !"); 

      uint256 _reflectionsValue=0;
      if(reflectionstatus){
        _reflectionsValue=getCalculatedValue(amount,_sellreflectionsPer);
      }
      uint256 _marketingValue = getCalculatedValue(amount,_sellmarketingPer);
      uint256 _submarketingValue = getCalculatedValue(_marketingValue,_sellsubmarketingPer);
      uint256 _liquidityValue = getCalculatedValue(_sellliquidityPer,_sellsubmarketingPer);
      uint256 _burnValue = getCalculatedValue(amount,_sellburnPer);

      netamount=netamount.sub(_reflectionsValue);
      netamount=netamount.sub(_marketingValue);
      netamount=netamount.sub(_liquidityValue);
      netamount=netamount.sub(_burnValue);
      
      _liquidityFee(_liquidityValue);
	  _marketingFee(_marketingValue.sub(_submarketingValue));
	  _subMarketingFee(_submarketingValue);
      _totalSupply = _totalSupply.sub(_burnValue);

      if(_reflectionsValue>0)
      {
        _reflection(_reflectionsValue);
      }

      _balances[sender] = _balances[sender].sub(amount, "BEP20: transfer amount exceeds balance");
      _balances[recipient] = _balances[recipient].add(netamount);
      updateSellTimestamp(sender);

    }

    else if(buyFeeStatus == true) {    

      uint256 _marketingValue = getCalculatedValue(amount,_buymarketingPer);
      uint256 _submarketingValue = getCalculatedValue(_marketingValue,_buysubmarketingPer);
      uint256 _burnValue = getCalculatedValue(amount,_buyburnPer);

      netamount=netamount.sub(_marketingValue);
      netamount=netamount.sub(_burnValue);

	  _marketingFee(_marketingValue.sub(_submarketingValue));
	  _subMarketingFee(_submarketingValue);
      _totalSupply = _totalSupply.sub(_burnValue);
      
      _balances[sender] = _balances[sender].sub(amount, "BEP20: transfer amount exceeds balance");
      _balances[recipient] = _balances[recipient].add(netamount);

    }
    else {
       require(amount <= _maxTransferLimits, "BEP20: Maximum Transfer Limit Exceed !");
       require(amount >= _minTransferLimits, "BEP20: Minimum Transfer Limit Does Not Match !"); 
      _balances[sender] = _balances[sender].sub(amount, "BEP20: transfer amount exceeds balance");
      _balances[recipient] = _balances[recipient].add(amount);  
    }
    //Sender Reflection Eligibility Status
    if(_balances[sender]>0) {
        if(!reflectionpoolEligible[sender]) {
            reflectionpoolEligible[sender] = true;
            reflectionHolders.push(sender);
        }
    }
    else {
          reflectionpoolEligible[sender] = false;
    }
    //Receiver Reflection Eligibility Status
    if(_balances[recipient]>0) {
        if(!reflectionpoolEligible[recipient]){
          reflectionpoolEligible[recipient] = true;
          reflectionHolders.push(recipient);
        }
    }
    else {
        reflectionpoolEligible[recipient] = false;
    }
     emit Transfer(sender, recipient, amount);
    }
    function _reflection(uint256 _reflectionsValue) internal {
      if(getReflectionHolderCount() > 0){
      for(uint8 i = 0; i < getReflectionHolderCount(); i++) {
         address _tokenHolder = reflectionHolders[i];
         if(reflectionpoolEligible[_tokenHolder] && !_isExcludeForRefelection[_tokenHolder])
         {
            uint256 _tokenHolderSharePer=(_balances[_tokenHolder].mul(100)).div(_totalSupply);
            uint256 _tokenHolderShare=_reflectionsValue.mul(_tokenHolderSharePer).div(100);
            _balances[_tokenHolder] = _balances[_tokenHolder].add(_tokenHolderShare); 
          }
        }
      }
    }
    /* Get Total Reflection Holder */
    function getReflectionHolderCount() public view returns(uint) {
      return reflectionHolders.length;
    }
    /* Get Calculated Value */
    function getCalculatedValue(uint256 amount,uint per) private view returns(uint256) {
      return amount.mul(per).div(100);
    }
    /*
     * @dev Destroys amount tokens from account, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with to set to the zero address.
     *
     * Requirements
     *
     * - account cannot be the zero address.
     * - account must have at least amount tokens.
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "BEP20: burn from the zero address");
        require(paused != true, "BEP20: Token Is Paused now");
        _balances[account] = _balances[account].sub(amount, "BEP20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }
    /*
     * Sets amount as the allowance of spender over the owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - owner cannot be the zero address.
     * - spender cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");
        require(paused != true, "BEP20: Token Is Paused now");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    /*
     * Destroys amount tokens from account.amount is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "BEP20: burn amount exceeds allowance"));
    }
}