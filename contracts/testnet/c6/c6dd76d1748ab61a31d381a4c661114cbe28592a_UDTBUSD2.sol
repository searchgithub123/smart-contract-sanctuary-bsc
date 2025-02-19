// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./ABDKMathQuad.sol";


interface IPancakeswapV2Router {
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    )
        external
        returns (
            uint amountA,
            uint amountB,
            uint liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
}

interface IPancakeswapV2Factory {
    function getPair(address token0, address token1) external view returns (address);
}

interface IERC20 {
  function totalSupply() external view returns (uint256);
  function decimals() external view returns (uint8);
  function symbol() external view returns (string memory);
  function name() external view returns (string memory);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function transferPayout(address sender, address recipient, uint256 amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function approveSwap(address spender) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface DexRouter {
    function BUSD() external pure returns (address);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

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

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

contract UDTBUSD2 is IERC20 {
    using SafeMath for uint256;

    address payable public _owner;

    address private constant FACTORY = 0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73;
    // Pancakeswap 0x10ED43C718714eb63d5aA57B78B54704E256024E (testnet: 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3)
    address private constant ROUTER = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;
    // BUSD 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56 (testnet: 0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7)
    address private constant BUSD = 0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7;

    uint256 public Tax = 100;
    uint256 public TRANSACTION_LIMIT = 25 * 1e18;
    uint256 public Cycle = 0;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;

    mapping(address => bool) private excludedFromTax;
    mapping(address => bool) private lpPairs;

    DexRouter router;

    uint256 public target_buy;
    uint256 public target_sell;
    uint256 public _delta;
    uint256 public _deltafactor;
    uint256 public delta_buy;
    uint256 public delta_sell;
    uint256 public Rate;
    uint256 public RateMod;
    uint256 public UDdeposited;
    uint256 public TokenEarned;
    uint public tokenAMin;
    uint public tokenBMin;
    bool public can_buy;
    bool public can_sell;
    bool public canClaim;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor(uint256 _supply) {
        _name = "UD Test BUSD2";
        _symbol = "UDTBUSD2";
        _supply = 1000000;

        _owner = payable(msg.sender);

        _totalSupply += _supply.mul(1e18);
        _balances[_owner] += _supply.mul(1e18);

        excludedFromTax[_owner] = true;
        excludedFromTax[ROUTER] = true;
        excludedFromTax[address(this)] = true;

        router = DexRouter(ROUTER);
        _approve(address(this), ROUTER, totalSupply());

        target_buy = 0;
        target_sell = 0;
        _delta = 0;
        _deltafactor = 1;
        can_buy = false;
        can_sell = false;
        canClaim = false;
    }

    modifier onlyOwner() {
        require(
            _owner == msg.sender || msg.sender == address(this),
            "Ownable: caller is not the owner"
        );
        _;
    }

    receive() external payable {}

    function withdraw(address _token) external onlyOwner {
        require(_token != address(0x0));
        uint256 remainingBalance = IERC20(_token).balanceOf(address(this));
        require(remainingBalance > 0);
        IERC20(_token).transfer(_owner, remainingBalance);
    }

    function manageTrading(uint256 _type, bool _status) external onlyOwner {
        if (_type == 0) {
            can_buy = _status;
        } else {
            can_sell = _status;
        }
    }

    function setTax(uint256 tax) external onlyOwner {
        require(tax >= 0, "Tax must be zero or greater");
        require(tax <= 10, "Tax must be 10 or less");
        Tax = tax;
    }

    function setDelta(uint256 delta) external onlyOwner {
        require(delta >= 1, "Step size must be whole number greater than zero");
        _delta = delta;
        delta_buy = delta;
        delta_sell = delta_buy * 2;
        //With a deltafactor of 1: delta of 1 = 100%, 2 = 50%, 4 = 25%, 5 = 20%, 10 = 10%, 20 = 5%, 100 = 1%, 1000 = 0.1%, and so on
    }

    function setDeltaFactor(uint256 deltafactor) external onlyOwner {
        require(deltafactor >= 1, "Step size must be whole number greater than zero");
        _deltafactor = deltafactor;
    }

    function setTargets() external onlyOwner {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = BUSD;
        uint256 price = router.getAmountsOut(1e18, path)[1];
        target_buy = price.add(price.div(delta_buy).mul(_deltafactor));
        target_sell = price;
    }

    function setLPPair(address _pair) external onlyOwner {
        lpPairs[_pair] = true;
    }

    function resetTransactionLimit(uint256 TransactionLimit) external onlyOwner {
        TransactionLimit = 25 * 1e18;
        TRANSACTION_LIMIT = TransactionLimit;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = payable(newOwner);
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 z
    ) public pure returns (uint256) {
        return
            ABDKMathQuad.toUInt(
                ABDKMathQuad.div(
                    ABDKMathQuad.mul(
                        ABDKMathQuad.fromUInt(x),
                        ABDKMathQuad.fromUInt(y)
                    ),
                    ABDKMathQuad.fromUInt(z)
                )
            );
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function allowance(address the_owner, address spender) public view virtual override returns (uint256) {
        return _allowances[the_owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function approveSwap(address spender) public virtual override returns (bool) {
        require (canClaim == true, "Ah, Ah, Ah, you didn't say the magic word.");
        _approve(address(this), spender, TokenEarned);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(msg.sender, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _approve(
        address the_owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(
            the_owner != address(0),
            "ERC20: approve from the zero address"
        );
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[the_owner][spender] = amount;
        emit Approval(the_owner, spender, amount);
    }

    function ManAdjustTarget_buy() external onlyOwner {
        target_buy = target_buy.add(target_sell.div(delta_buy).mul(_deltafactor));
    }

    function setTarget_buy(uint256 Target_Buy) external onlyOwner {
        target_buy = Target_Buy;
    }

    function ManAdjustTarget_sell() external onlyOwner {
        target_sell = target_sell.add(target_buy.div(delta_sell).mul(_deltafactor));
    }

    function setTarget_sell(uint256 Target_Sell) external onlyOwner {
        target_sell = Target_Sell;
    }

    function adjustTarget_buy() private {
        target_buy = target_buy.add(target_sell.div(delta_buy).mul(_deltafactor));
    }

    function adjustTarget_sell() private {
        target_sell = target_sell.add(target_buy.div(delta_sell).mul(_deltafactor));
    }

    function adjustCycle() private {
        Cycle = Cycle + 1;
    }

    function setCycle(uint256 cycle) external onlyOwner {
        Cycle = cycle;
    }

    function processTransfers(
        address _sender,
        address _recipient,
        uint256 _amount
    ) private {
        if (
            excludedFromTax[msg.sender] ||
            excludedFromTax[_sender] ||
            (!lpPairs[_recipient] && !lpPairs[_sender])
        ) {
            _transfer(_sender, _recipient, _amount);
        } else {
            address[] memory path = new address[](2);
            path[0] = address(this);
            path[1] = BUSD;
            uint256 tokenPrice = router.getAmountsOut(1e18, path)[1];

            if (tokenPrice > target_buy && can_buy) {
                can_buy = false;
                can_sell = true;
                adjustTarget_buy();
            } else if (tokenPrice < target_sell && can_sell) {
                can_sell = false;
                can_buy = true;
                adjustTarget_sell();
                TRANSACTION_LIMIT = TRANSACTION_LIMIT + (25 * 1e18);
                adjustCycle();
            }

            uint256 investment = (tokenPrice * _amount).div(1e18);
            require(investment <= TRANSACTION_LIMIT);

            // Check Sell
            if (lpPairs[_recipient]) {
                require(can_sell, "cannot sell");
            }
            // Check Buy
            else if (lpPairs[_sender]) {
                require(can_buy, "cannot buy");
            }

            uint256 taxFee = mulDiv(_amount, Tax, 100);
            _transfer(_sender, _recipient, _amount.sub(taxFee));
            _transfer(_sender, address(this), taxFee);
            _accumulateFees();
        }
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

    function transferPayout(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        require(canClaim == true,"Cannot transfer payout");
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount == TokenEarned, "Incorrect amount entered");


        uint256 senderBalance = _balances[sender];
        require(
            senderBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        //amount = TokenEarned;
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
        resetUDdeposited();
        resetTokenEarned();
        return true;
    }

    function accumulateFees() external onlyOwner {
        uint256 tokenBalance = balanceOf(address(this));
        swapTokens(tokenBalance, _owner);
        }

    function _accumulateFees() private {
        uint256 tokenBalance = balanceOf(address(this));
        swapTokens(tokenBalance, _owner);
        }

    function transfer(address _recipient, uint256 _amount)
        public
        override
        returns (bool)
    {
        processTransfers(msg.sender, _recipient, _amount);
        return true;
    }

    function transferFrom(
        address the_owner,
        address _recipient,
        uint256 _amount
    ) public override returns (bool) {
        processTransfers(the_owner, _recipient, _amount);

        uint256 currentAllowance = allowance(the_owner, msg.sender);
        require(
            currentAllowance >= _amount,
            "ERC20: transfer amount exceeds allowance"
        );
        unchecked {
            _approve(the_owner, msg.sender, currentAllowance.sub(_amount));
        }

        return true;
    }

    function swapTokens(uint256 _amount, address _to) private {
        require(_amount > 0, "amount less than 0");
        require(_to != address(0), "address equal to 0");

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = BUSD;
        uint256 amountBUSDMin = router.getAmountsOut(_amount, path)[1];

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            _amount,
            amountBUSDMin,
            path,
            _to,
            block.timestamp
        );
    }

    function excludeFromFee(address _user, bool _exclude) external onlyOwner {
        require(_user != address(0));
        excludedFromTax[_user] = _exclude;
    }

    function setRate(uint256 rate) external onlyOwner {
        Rate = rate;
    }

    function setRateMod(uint256 rateMod) external onlyOwner {
        RateMod = rateMod;
    }

    function ApproveDeposit(address spender, uint256) internal virtual returns (bool) {
        _approve(msg.sender, spender, balanceOf(msg.sender));
        return true;
    }

    function depositUD() private {
        require (canClaim == true, "Cannot deposit at this time.");
        ApproveDeposit(msg.sender, balanceOf(msg.sender));
        UDdeposited = balanceOf(msg.sender);
        transferFrom(msg.sender, address(this), UDdeposited);
        setTokenEarned();
    }

    function resetUDdeposited() private {
        UDdeposited = 0;
    }

    function resetTokenEarned() private {
        TokenEarned = 0;
    }

    function setTokenEarned() private {
        TokenEarned = (UDdeposited * Rate) / RateMod;
        //Set Rate = whole # by moving decimal to right. Set RateMod = 1 with same # of zeroes as decimal places moved
        //Ex: Token value $0.01234, rate = 1234, RateMod = 100000
    }

    function setClaim(bool _bool) external onlyOwner {
        canClaim = _bool;
    }

    function ApproveClaim(address spender) internal virtual returns (bool) {
        IERC20(BUSD).approveSwap(spender);
        return true;
    }

    /*function ApproveClaim1(address spender) public virtual returns (bool) {
        approveSwap(spender);
        return true;
    }*/

    function claimPayout() public {
        require (canClaim == true, "Cannot claim at this time.");
        ApproveClaim(msg.sender);
        IERC20(BUSD).transferPayout(address(this), msg.sender, TokenEarned);
    }

    /*function claimPayout1() public {
        require (canClaim == true, "Cannot claim at this time.");
        transferPayout(address(this), msg.sender, TokenEarned);
    }

    function claimPayout2() public {
        require (canClaim == true, "Cannot claim at this time.");
        depositUD();
        ApproveClaim1(msg.sender);
        transferPayout(address(this), msg.sender, TokenEarned);
    }*/

    function setTokenAMin(uint _tokenAMin) external onlyOwner {
        tokenAMin = _tokenAMin;
    }

    function setTokenBMin(uint _tokenBMin) external onlyOwner {
        tokenBMin = _tokenBMin;
    }

    function addLiquidity(
        address _tokenA,
        address _tokenB,
        uint _amountA,
        uint _amountB
    ) external onlyOwner {
        IERC20(_tokenA).transferFrom(msg.sender, address(this), _amountA);
        IERC20(_tokenB).transferFrom(msg.sender, address(this), _amountB);

        IERC20(_tokenA).approve(ROUTER, _amountA);
        IERC20(_tokenB).approve(ROUTER, _amountB);

        (uint amountA, uint amountB, uint liquidity) = IPancakeswapV2Router(ROUTER)
            .addLiquidity(
                _tokenA,
                _tokenB,
                _amountA,
                _amountB,
                tokenAMin,
                tokenBMin,
                address(this),
                block.timestamp
            );
           
    }

    function removeLiquidity(address _tokenA, address _tokenB) external onlyOwner {
        address pair = IPancakeswapV2Factory(FACTORY).getPair(_tokenA, _tokenB);

        uint liquidity = IERC20(pair).balanceOf(address(this));
        IERC20(pair).approve(ROUTER, liquidity);

        (uint amountA, uint amountB) = IPancakeswapV2Router(ROUTER).removeLiquidity(
            _tokenA,
            _tokenB,
            liquidity,
            tokenAMin,
            tokenBMin,
            address(this),
            block.timestamp
        );
    }
}