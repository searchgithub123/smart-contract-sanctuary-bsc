// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

import "./interfaces/IERC20.sol";
import "./libraries/Context.sol";
import "./libraries/Ownable.sol";

contract HexaFinityToken is Context, IERC20, Ownable {
  // using Address for address;

  struct FeeValues {
    uint256 rAmount;
    uint256 rTransferAmount;
    uint256 rHolderRewardsFee;
    uint256 tTransferAmount;
    uint256 tHolderRewardsFee;
    uint256 tLiquidity;
    uint256 tTax;
    uint256 tBurn;
  }

  struct tFeeValues {
    uint256 tTransferAmount;
    uint256 tHolderRewardsFee;
    uint256 tLiquidity;
    uint256 tTax;
    uint256 tBurn;
  }
  mapping(address => uint256) private _rOwned;
  mapping(address => uint256) private _tOwned;
  mapping(address => mapping(address => uint256)) private _allowances;

  mapping(address => bool) private _isExcludedFromFee;

  mapping(address => bool) private _isExcluded;
  address[] private _excluded;

  uint256 private constant MAX = ~uint256(0);
  uint256 private _tTotal = 6000 * 10**9 * 10**18;
  uint256 private _rTotal = (MAX - (MAX % _tTotal));
  uint256 private _tHolderRewardsFeeTotal;

  string private _name = "HexaFinity";
  string private _symbol = "HEXA";
  uint8 private _decimals = 18;

  uint256 public _holderRewardsFee = 1;
  uint256 private _previousHolderRewards = _holderRewardsFee;

  uint256 public _burnFee = 3;
  uint256 private _previousBurnFee = _burnFee;

  uint256 public _taxFee = 6;
  uint256 private _previousTaxFee = _taxFee;

  uint256 public _liquidityFee = 0;
  uint256 private _previousLiquidityFee = _liquidityFee;

  address public _taxReceiverAddress;
  address public _burnAddress = 0x000000000000000000000000000000000000dEaD;

  IUniswapV2Router02 public immutable uniswapV2Router;
  address public immutable uniswapV2Pair;

  bool inSwapAndLiquify;
  bool public swapAndLiquifyEnabled = true;

  uint256 public _maxTxAmount = 30 * 10**9 * 10**18;
  uint256 private numTokensSellToAddToLiquidity = 3 * 10**9 * 10**18;

  event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
  event SwapAndLiquifyEnabledUpdated(bool enabled);
  event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);

  modifier lockTheSwap() {
    inSwapAndLiquify = true;
    _;
    inSwapAndLiquify = false;
  }

  constructor(address _router, address _taxReceiver) {
    _rOwned[_msgSender()] = _rTotal;

    IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(_router);
    // Create a uniswap pair for this new token
    uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(
      address(this),
      _uniswapV2Router.WETH()
    );

    // set tax receiver address
    _taxReceiverAddress = _taxReceiver;

    // set the rest of the contract variables
    uniswapV2Router = _uniswapV2Router;

    //exclude owner and this contract from fee
    _isExcludedFromFee[owner()] = true;
    _isExcludedFromFee[address(this)] = true;
    _isExcludedFromFee[_taxReceiverAddress] = true;

    //exclude tax receiver and burn address from reward
    excludeFromReward(_taxReceiverAddress);
    excludeFromReward(_burnAddress);
    excludeFromReward(uniswapV2Pair);

    emit Transfer(address(0), _msgSender(), _tTotal);
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

  function totalSupply() public view override returns (uint256) {
    return _tTotal;
  }

  function balanceOf(address account) public view override returns (uint256) {
    if (_isExcluded[account]) return _tOwned[account];
    return tokenFromReflection(_rOwned[account]);
  }

  function transfer(address recipient, uint256 amount) public override returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  function allowance(address owner, address spender) public view override returns (uint256) {
    return _allowances[owner][spender];
  }

  function approve(address spender, uint256 amount) public override returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) public override returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);
    return true;
  }

  function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue)
    public
    virtual
    returns (bool)
  {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender] - subtractedValue);
    return true;
  }

  function isExcludedFromReward(address account) public view returns (bool) {
    return _isExcluded[account];
  }

  function totalFees() public view returns (uint256) {
    return _tHolderRewardsFeeTotal;
  }

  function reflectionFromToken(uint256 tAmount, bool deductTransferFee)
    public
    view
    returns (uint256)
  {
    require(tAmount <= _tTotal, "Amount must be less than supply");
    if (!deductTransferFee) {
      FeeValues memory _values = _getValues(tAmount);
      return _values.rAmount;
    } else {
      FeeValues memory _values = _getValues(tAmount);
      return _values.rTransferAmount;
    }
  }

  function tokenFromReflection(uint256 rAmount) public view returns (uint256) {
    require(rAmount <= _rTotal, "Amount must be less than total reflections");
    uint256 currentRate = _getRate();
    return rAmount / currentRate;
  }

  function excludeFromReward(address account) public onlyOwner {
    require(!_isExcluded[account], "Account is already excluded");
    if (_rOwned[account] > 0) {
      _tOwned[account] = tokenFromReflection(_rOwned[account]);
    }
    _isExcluded[account] = true;
    _excluded.push(account);
  }

  function includeInReward(address account) external onlyOwner {
    require(_isExcluded[account], "Account is already excluded");
    for (uint256 i = 0; i < _excluded.length; i++) {
      if (_excluded[i] == account) {
        _excluded[i] = _excluded[_excluded.length - 1];
        _tOwned[account] = 0;
        _isExcluded[account] = false;
        _excluded.pop();
        break;
      }
    }
  }

  function _transferBothExcluded(
    address sender,
    address recipient,
    uint256 tAmount
  ) private {
    FeeValues memory _values = _getValues(tAmount);
    _tOwned[sender] = _tOwned[sender] - tAmount;
    _rOwned[sender] = _rOwned[sender] - _values.rAmount;
    _tOwned[recipient] = _tOwned[recipient] + _values.tTransferAmount;
    _rOwned[recipient] = _rOwned[recipient] + _values.rTransferAmount;
    _takeFees(sender, _values);
    _reflectFee(_values.rHolderRewardsFee, _values.tHolderRewardsFee);
    emit Transfer(sender, recipient, _values.tTransferAmount);
  }

  function excludeFromFee(address account) public onlyOwner {
    _isExcludedFromFee[account] = true;
  }

  function includeInFee(address account) public onlyOwner {
    _isExcludedFromFee[account] = false;
  }

  function setHolderRewardsPercent(uint256 holderRewardsFee) external onlyOwner {
    _holderRewardsFee = holderRewardsFee;
  }

  function setLiquidityFeePercent(uint256 liquidityFee) external onlyOwner {
    _liquidityFee = liquidityFee;
  }

  function setBurnFeePercent(uint256 burnFee) external onlyOwner {
    _burnFee = burnFee;
  }

  function setOwnerFeePercent(uint256 ownerFee) external onlyOwner {
    _taxFee = ownerFee;
  }

  function setTaxReceiverAddress(address _taxReceiver) external onlyOwner {
    require(_taxReceiver != address(0), "HEXA: Address Zero is not allowed");
    excludeFromReward(_taxReceiver);
    excludeFromFee(_taxReceiver);
    _taxReceiverAddress = _taxReceiver;
  }

  function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner {
    _maxTxAmount = (_tTotal * maxTxPercent) / 10**3;
  }

  function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
    swapAndLiquifyEnabled = _enabled;
    emit SwapAndLiquifyEnabledUpdated(_enabled);
  }

  //to recieve ETH from uniswapV2Router when swaping
  receive() external payable {}

  function _reflectFee(uint256 rHolderRewardsFee, uint256 tHolderRewardsFee) private {
    _rTotal = _rTotal - rHolderRewardsFee;
    _tHolderRewardsFeeTotal = _tHolderRewardsFeeTotal + tHolderRewardsFee;
  }

  function _getValues(uint256 tAmount) private view returns (FeeValues memory) {
    tFeeValues memory tValues = _getTValues(tAmount);
    uint256 tTransferFee = tValues.tLiquidity + tValues.tTax + tValues.tBurn;
    (uint256 rAmount, uint256 rTransferAmount, uint256 rHolderRewardsFee) = _getRValues(
      tAmount,
      tValues.tHolderRewardsFee,
      tTransferFee,
      _getRate()
    );
    return
      FeeValues(
        rAmount,
        rTransferAmount,
        rHolderRewardsFee,
        tValues.tTransferAmount,
        tValues.tHolderRewardsFee,
        tValues.tLiquidity,
        tValues.tTax,
        tValues.tBurn
      );
  }

  function _getTValues(uint256 tAmount) private view returns (tFeeValues memory) {
    (
      uint256 calculateTaxFee,
      uint256 calculateOwnerFee,
      uint256 calculateBurnFee,
      uint256 calculateLiquidityFee
    ) = calculateFee(tAmount);

    uint256 tTransferAmount = tAmount -
      calculateTaxFee -
      calculateLiquidityFee -
      calculateBurnFee -
      calculateOwnerFee;
    return
      tFeeValues(
        tTransferAmount,
        calculateTaxFee,
        calculateLiquidityFee,
        calculateOwnerFee,
        calculateBurnFee
      );
  }

  function _getRValues(
    uint256 tAmount,
    uint256 tHolderRewardsFee,
    uint256 tTransferFee,
    uint256 currentRate
  )
    private
    pure
    returns (
      uint256,
      uint256,
      uint256
    )
  {
    uint256 rAmount = tAmount * currentRate;
    uint256 rHolderRewardsFee = tHolderRewardsFee * currentRate;
    uint256 rTransferFee = tTransferFee * currentRate;

    uint256 rTransferAmount = rAmount - rHolderRewardsFee - rTransferFee;
    return (rAmount, rTransferAmount, rHolderRewardsFee);
  }

  function _getRate() private view returns (uint256) {
    (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
    return rSupply / tSupply;
  }

  function _getCurrentSupply() private view returns (uint256, uint256) {
    uint256 rSupply = _rTotal;
    uint256 tSupply = _tTotal;
    for (uint256 i = 0; i < _excluded.length; i++) {
      if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply)
        return (_rTotal, _tTotal);
      rSupply = rSupply - _rOwned[_excluded[i]];
      tSupply = tSupply - _tOwned[_excluded[i]];
    }
    if (rSupply < _rTotal / _tTotal) return (_rTotal, _tTotal);
    return (rSupply, tSupply);
  }

  function calculateFee(uint256 tAmount)
    private
    view
    returns (
      uint256,
      uint256,
      uint256,
      uint256
    )
  {
    uint256 calculateTaxFee = (tAmount * _holderRewardsFee) / 10**3;
    uint256 calculateOwnerFee = (tAmount * _taxFee) / 10**3;
    uint256 calculateBurnFee = (tAmount * _burnFee) / 10**3;
    uint256 calculateLiquidityFee = (tAmount * _liquidityFee) / 10**3;
    return (calculateTaxFee, calculateOwnerFee, calculateBurnFee, calculateLiquidityFee);
  }

  function removeAllFee() private {
    if (_holderRewardsFee == 0 && _liquidityFee == 0 && _taxFee == 0 && _burnFee == 0) return;

    _previousHolderRewards = _holderRewardsFee;
    _previousLiquidityFee = _liquidityFee;
    _previousTaxFee = _taxFee;
    _previousBurnFee = _burnFee;

    _holderRewardsFee = 0;
    _liquidityFee = 0;
    _taxFee = 0;
    _burnFee = 0;
  }

  function restoreAllFee() private {
    _holderRewardsFee = _previousHolderRewards;
    _liquidityFee = _previousLiquidityFee;
    _burnFee = _previousBurnFee;
    _taxFee = _previousTaxFee;
  }

  function isExcludedFromFee(address account) public view returns (bool) {
    return _isExcludedFromFee[account];
  }

  function _approve(
    address owner,
    address spender,
    uint256 amount
  ) private {
    require(owner != address(0), "ERC20: approve from the zero address");
    require(spender != address(0), "ERC20: approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  function _transfer(
    address from,
    address to,
    uint256 amount
  ) private {
    require(from != address(0), "ERC20: transfer from the zero address");
    require(to != address(0), "ERC20: transfer to the zero address");
    require(amount > 0, "Transfer amount must be greater than zero");
    if (from != owner() && to != owner())
      require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");

    // is the token balance of this contract address over the min number of
    // tokens that we need to initiate a swap + liquidity lock?
    // also, don't get caught in a circular liquidity event.
    // also, don't swap & liquify if sender is uniswap pair.
    uint256 contractTokenBalance = balanceOf(address(this));

    if (contractTokenBalance >= _maxTxAmount) {
      contractTokenBalance = _maxTxAmount;
    }

    bool overMinTokenBalance = contractTokenBalance >= numTokensSellToAddToLiquidity;
    if (
      overMinTokenBalance && !inSwapAndLiquify && from != uniswapV2Pair && swapAndLiquifyEnabled
    ) {
      contractTokenBalance = numTokensSellToAddToLiquidity;
      //add liquidity
      swapAndLiquify(contractTokenBalance);
    }

    //indicates if fee should be deducted from transfer
    bool takeFee = true;

    //if any account belongs to _isExcludedFromFee account then remove the fee
    if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
      takeFee = false;
    }

    //transfer amount, it will take tax, burn, liquidity fee
    _tokenTransfer(from, to, amount, takeFee);
  }

  function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
    // split the contract balance into halves
    uint256 half = contractTokenBalance / 2;
    uint256 otherHalf = contractTokenBalance - half;

    // capture the contract's current ETH balance.
    // this is so that we can capture exactly the amount of ETH that the
    // swap creates, and not make the liquidity event include any ETH that
    // has been manually sent to the contract
    uint256 initialBalance = address(this).balance;

    // swap tokens for ETH
    swapTokensForEth(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

    // how much ETH did we just swap into?
    uint256 newBalance = address(this).balance - initialBalance;

    // add liquidity to uniswap
    addLiquidity(otherHalf, newBalance);

    emit SwapAndLiquify(half, newBalance, otherHalf);
  }

  function swapTokensForEth(uint256 tokenAmount) private {
    // generate the uniswap pair path of token -> weth
    address[] memory path = new address[](2);
    path[0] = address(this);
    path[1] = uniswapV2Router.WETH();

    _approve(address(this), address(uniswapV2Router), tokenAmount);

    // make the swap
    uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
      tokenAmount,
      0, // accept any amount of ETH
      path,
      address(this),
      block.timestamp
    );
  }

  function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
    // approve token transfer to cover all possible scenarios
    _approve(address(this), address(uniswapV2Router), tokenAmount);

    // add the liquidity
    uniswapV2Router.addLiquidityETH{value: ethAmount}(
      address(this),
      tokenAmount,
      0, // slippage is unavoidable
      0, // slippage is unavoidable
      owner(),
      block.timestamp
    );
  }

  //this method is responsible for taking all fee, if takeFee is true
  function _tokenTransfer(
    address sender,
    address recipient,
    uint256 amount,
    bool takeFee
  ) private {
    if (!takeFee) removeAllFee();

    if (_isExcluded[sender] && !_isExcluded[recipient]) {
      _transferFromExcluded(sender, recipient, amount);
    } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
      _transferToExcluded(sender, recipient, amount);
    } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
      _transferStandard(sender, recipient, amount);
    } else if (_isExcluded[sender] && _isExcluded[recipient]) {
      _transferBothExcluded(sender, recipient, amount);
    } else {
      _transferStandard(sender, recipient, amount);
    }

    if (!takeFee) restoreAllFee();
  }

  function _transferStandard(
    address sender,
    address recipient,
    uint256 tAmount
  ) private {
    FeeValues memory _values = _getValues(tAmount);
    _rOwned[sender] = _rOwned[sender] - _values.rAmount;
    _rOwned[recipient] = _rOwned[recipient] + _values.rTransferAmount;
    _takeFees(sender, _values);
    _reflectFee(_values.rHolderRewardsFee, _values.tHolderRewardsFee);
    emit Transfer(sender, recipient, _values.tTransferAmount);
  }

  function _transferToExcluded(
    address sender,
    address recipient,
    uint256 tAmount
  ) private {
    FeeValues memory _values = _getValues(tAmount);
    _rOwned[sender] = _rOwned[sender] - _values.rAmount;
    _tOwned[recipient] = _tOwned[recipient] + _values.tTransferAmount;
    _rOwned[recipient] = _rOwned[recipient] + _values.rTransferAmount;
    _takeFees(sender, _values);
    _reflectFee(_values.rHolderRewardsFee, _values.tHolderRewardsFee);
    emit Transfer(sender, recipient, _values.tTransferAmount);
  }

  function _transferFromExcluded(
    address sender,
    address recipient,
    uint256 tAmount
  ) private {
    FeeValues memory _values = _getValues(tAmount);
    _tOwned[sender] = _tOwned[sender] - tAmount;
    _rOwned[sender] = _rOwned[sender] - _values.rAmount;
    _rOwned[recipient] = _rOwned[recipient] + _values.rTransferAmount;
    _takeFees(sender, _values);
    _reflectFee(_values.rHolderRewardsFee, _values.tHolderRewardsFee);
    emit Transfer(sender, recipient, _values.tTransferAmount);
  }

  function _takeFees(address sender, FeeValues memory values) private {
    _takeFee(sender, values.tLiquidity, address(this));
    _takeFee(sender, values.tTax, _taxReceiverAddress);
    _takeBurn(sender, values.tBurn);
  }

  function _takeFee(
    address sender,
    uint256 tAmount,
    address recipient
  ) private {
    if (recipient == address(0)) return;
    if (tAmount == 0) return;

    uint256 currentRate = _getRate();
    uint256 rAmount = tAmount * currentRate;
    _rOwned[recipient] = _rOwned[recipient] + rAmount;
    if (_isExcluded[recipient]) _tOwned[recipient] = _tOwned[recipient] + tAmount;

    emit Transfer(sender, recipient, tAmount);
  }

  function _takeBurn(address sender, uint256 _amount) private {
    if (_amount == 0) return;
    _tOwned[_burnAddress] = _tOwned[_burnAddress] + _amount;

    emit Transfer(sender, _burnAddress, _amount);
  }

  function updateBurnAddress(address _newBurnAddress) external onlyOwner {
    _burnAddress = _newBurnAddress;
    excludeFromReward(_newBurnAddress);
  }
}

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

pragma solidity >=0.5.0;

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

    event Mint(address indexed sender, uint amount0, uint amount1);
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

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IERC20 {

    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "./Context.sol";
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
contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

     /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function geUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    //Locks the contract for owner for the amount of time provided
    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }
    
    //Unlocks the contract for owner when _lockTime is exceeds
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(block.timestamp > _lockTime , "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}

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