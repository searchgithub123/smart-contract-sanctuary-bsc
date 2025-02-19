/**
 *Submitted for verification at BscScan.com on 2022-09-21
*/

// File: utils/SafeMath.sol
//  SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;


// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
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

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
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

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
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

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
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

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
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

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
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

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
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

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
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

// File: utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)


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

// File: utils/Pausable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)



/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// File: utils/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)



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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

// File: contracts/Blacklist.sol



contract Blacklist is Ownable {
    mapping(address => bool) public isBlacklisted;

    function addBlacklist(address _user) public onlyOwner {
        require(!isBlacklisted[_user], "Error: User already blacklisted");
        isBlacklisted[_user] = true;
    }

    function removeFromBlacklist(address _user) public onlyOwner {
        require(isBlacklisted[_user], "Error: User already whitelisted");
        isBlacklisted[_user] = false;
    }

    function isUserBlacklisted(address _user) public view returns (bool) {
        return isBlacklisted[_user];
    }
}

// File: contracts/IBEP20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/BEP20/IBEP20.sol)


/**
 * @dev Interface of the BEP20 standard as defined in the EIP.
 */
interface IBEP20 {
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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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

// File: contracts/extensions/IBEP20Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/BEP20/extensions/IBEP20Metadata.sol)



/**
 * @dev Interface for the optional metadata functions from the BEP20 standard.
 *
 * _Available since v4.1._
 */
interface IBEP20Metadata is IBEP20 {
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

// File: contracts/BEP20.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/BEP20/BEP20.sol)








/**
 * @dev Implementation of the {IBEP20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {BEP20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-BEP20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of BEP20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IBEP20-approve}.
 */
contract BEP20 is
    Context,
    IBEP20,
    IBEP20Metadata,
    Ownable,
    Pausable,
    Blacklist
{
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimal
    ) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimal;
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
     * Ether and Wei. This is the value {BEP20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IBEP20-balanceOf} and {IBEP20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IBEP20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IBEP20-balanceOf}.
     */
    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }

    /**
     * @dev See {IBEP20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount)
        public
        virtual
        override
        whenNotPaused
        returns (bool)
    {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IBEP20-allowance}.
     */
    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IBEP20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount)
        public
        virtual
        override
        whenNotPaused
        returns (bool)
    {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IBEP20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {BEP20}.
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
    ) public virtual override whenNotPaused returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IBEP20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        whenNotPaused
        returns (bool)
    {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IBEP20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        whenNotPaused
        returns (bool)
    {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(
            currentAllowance >= subtractedValue,
            "BEP20: decreased allowance below zero"
        );
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
        require(from != address(0), "BEP20: transfer from the zero address");
        require(to != address(0), "BEP20: transfer to the zero address");
        require(!isBlacklisted[from], "Error: Sender is blacklisted");
        require(!isBlacklisted[to], "Error: Receiver is blacklisted");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(
            fromBalance >= amount,
            "BEP20: transfer amount exceeds balance"
        );
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);
        _afterTokenTransfer(from, to, amount);
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

    uint256 public supply = 63800000 * (10**9);

    function _mint(address account, uint256 amount) internal virtual {
        require(supply >= amount, "Error: Limit is reached");
        require(account != address(0), "BEP20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);
        supply -= amount;
        _totalSupply += amount;
        _balances[account] += amount;
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
        require(account != address(0), "BEP20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "BEP20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

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
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

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
            require(
                currentAllowance >= amount,
                "BEP20: insufficient allowance"
            );
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

// File: contracts/RTC_Plus.sol




contract RTC_Plus is BEP20 {
    uint256 private initialSupply;
    uint256 public max_supply = 34800000 * (10**9);

    using SafeMath for uint256;
    uint256 public totalMint;

    constructor() BEP20("RTC_PLUS", "RTC+", 9) {
        initialSupply = 29000000 * (10**9);
        _mint(owner(), initialSupply);
    }

    function mint(uint256 amount) public onlyOwner {
        require(totalMint < 34800000000000000, "Error: Limit has reached");
        _mint(owner(), amount);
        totalMint += amount;
        initialSupply += amount;
    }

    function transferPrice(
        address from,
        address to,
        uint256 amount
    ) public {
        _transfer(from, to, amount);
    }

    function withdrawFunds(uint256 amount) private onlyOwner {
        transferPrice(address(this), owner(), amount);
    }
}

// File: contracts/swap.sol






contract swap is Ownable {
    using SafeMath for uint256;

    RTC_Plus public RTC_Plus_address;
    BEP20 public RTCTokenAddress;
    uint256 private RTC_price = 50000000;
    uint256 private RTCC_price = 500000000;

    event swapped(
        uint256 rtc_token,
        uint256 rtc_toke_in_usdt,
        uint256 returnAmount
    );

    function initialize(RTC_Plus _RTC_Plus_Address, BEP20 _RTCTokenAddress)
        public
        onlyOwner
    {
        RTC_Plus_address = RTC_Plus(_RTC_Plus_Address);
        RTCTokenAddress = BEP20(_RTCTokenAddress);
    }

    function set_rtc_price(uint256 price) public onlyOwner {
        RTC_price = price;
    }

    function get_rtc_price() public view returns (uint256) {
        return RTC_price;
    }

    function set_rtcc_price(uint256 price) public onlyOwner {
        RTCC_price = price;
    }

    function get_rtcc_price() public view returns (uint256) {
        return RTCC_price;
    }

    function withdrawFromContractAddress(uint256 amount) public onlyOwner {
        require(
            msg.sender == owner(),
            "Error: Only Owner is make this transaction"
        );
        require(
            amount <= RTC_Plus_address.balanceOf(address(this)),
            "Error : Insufficient Balance"
        );
        RTC_Plus_address.transferPrice(address(this), owner(), amount);
    }

    function Swap(uint256 rtc_token) public {
        RTCTokenAddress.transferFrom(msg.sender, owner(), rtc_token);
        uint256 amount_in_USDT = rtc_token.mul(RTC_price);
        uint256 return_token_in_RTCC = amount_in_USDT / RTCC_price;
        RTC_Plus_address.transferPrice(
            owner(),
            msg.sender,
            return_token_in_RTCC
        );
        emit swapped(rtc_token, amount_in_USDT, return_token_in_RTCC);
    }
}

// File: contracts/stake.sol






contract stake is Ownable {
    struct Tariff {
        uint256 time;
        uint256 percent;
    }

    struct Deposit {
        uint256 tariff;
        uint256 amount;
        uint256 at; //Deposit at
        bool reinvest;
        uint256 withdrawPrincipal;
        uint256 withdrawPrincipalAt; //Time at which principal is withdraw
        uint256 nextPrincipalWithdrawAt;
    }

    struct retopup {
        uint256 amount;
        uint256 timeAt;
        uint256 withdrawnPrincipalAmt;
        uint256 withdrawnPrincipalAt;
        uint256 nextWithdrawnPrincipalAt;
    }

    struct Investor {
        Deposit[] deposits;
        retopup[] _retopup;
        bool registered;
        uint256 invested;
        uint256 paidAt;
        uint256 withdrawn;
        uint256 reinvest;
    }

    uint256 min_deposit = 10 * (10**9);
    uint256 min_withdrawl = 10 * (10**9);
    // address public owner = msg.sender;
    address public updater = msg.sender;
    bool public depositStatus;

    Tariff[] public tariffs;
    uint256 public totalInvesters;
    uint256 public totalInvested;
    uint256 public totalWithdrawl;
    uint256 public totalReinvest;
    uint256 public prinicipleWithdrawlInterval = 7 days;

    mapping(address => Investor) public investors;

    event DepositAt(address user, uint256 tariff, uint256 amount, uint256 date);
    event OwnershipTransferred(address new_owner);
    event ReDepositAt(address user, uint256 tariff, uint256 amount);
    event Withdraw(address user, uint256 amount);
    event WithdrawPrincipal(
        address user,
        uint256 amount,
        uint256 withdrawnAt,
        uint256 plan
    );
    event swapped(
        uint256 rtc_token,
        uint256 rtc_toke_in_usdt,
        uint256 returnAmount
    );

    event claimRetopup(address user, uint256 amount);

    constructor() {
        tariffs.push(Tariff(360 days, 12 * 3)); //1 year plan
        tariffs.push(Tariff(720 days, 24 * 5)); // 2 year plan
        tariffs.push(Tariff(1440 days, 48 * 6)); // 4 year plan

        updater = msg.sender;
        depositStatus = true;
    }

    RTC_Plus public RTC_Plus_address;
    BEP20 public RTCTokenAddress;
    swap public swapContractAddress;

    function initialize(
        RTC_Plus _RTC_Plus_Address,
        BEP20 _RTCTokenAddress,
        swap _swapContractAddress
    ) public onlyOwner {
        RTC_Plus_address = RTC_Plus(_RTC_Plus_Address);
        RTCTokenAddress = BEP20(_RTCTokenAddress);
        swapContractAddress = swap(_swapContractAddress);
    }

    function changeUpdater(address to) external onlyOwner {
        // require(msg.sender == owner, "Only owner");
        require(to != address(0), "Cannot change updater to zero address");
        updater = to;
    }

    function changeDepositStatus(bool _depositStatus) external onlyOwner {
        // require(msg.sender == owner, " Only Owner");
        depositStatus = _depositStatus;
    }

    function deposit(uint256 tariff, uint256 amount) external {
        require(amount >= min_deposit, "Error: please deposit 10 tokens");
        require(tariff < tariffs.length, "Error: Not a valid tariff plan");
        if (!investors[msg.sender].registered) {
            investors[msg.sender].registered = true;
            totalInvesters++;
        } //else
        investors[msg.sender].invested += amount;
        totalInvested += amount;
        Tariff storage tariffObj = tariffs[tariff];
        uint256 nextPrincipalWithdrawDate = tariffObj.time + block.timestamp;
        investors[msg.sender].deposits.push(
            Deposit(
                tariff,
                amount,
                block.timestamp,
                false,
                0,
                block.timestamp,
                nextPrincipalWithdrawDate
            )
        );
        // BEP20 _tokenRTC_PLUS = BEP20(RTC_Plus_address);
        require(
            RTC_Plus_address.balanceOf(msg.sender) >= amount,
            "Error: Insufficient amount of balance"
        );
        RTC_Plus_address.transferPrice(msg.sender, address(this), amount);
        emit DepositAt(msg.sender, tariff, amount, nextPrincipalWithdrawDate);
    }

    function swapContract(
        address addr,
        uint256[] memory _amounts,
        uint256[] memory _times
    ) external onlyOwner {
        require(msg.sender == updater, "Permission error");
        require(_amounts.length == _times.length, "Array length error");
        uint256 len = _amounts.length;
        uint256 tariff = 1;
        Tariff storage tariffObj = tariffs[tariff];
        for (uint256 i = 0; i < len; i++) {
            uint256 amount = _amounts[i];
            uint256 currentTime = _times[i];
            investors[addr].registered = true;

            investors[addr].invested += amount;

            uint256 nextPrincipalWithdrawalDate = tariffObj.time + currentTime;
            investors[addr].deposits.push(
                Deposit(
                    tariff,
                    amount,
                    currentTime,
                    false,
                    0,
                    currentTime,
                    nextPrincipalWithdrawalDate
                )
            );
        }
    }

    function swapContractMultiple(
        address[] memory _addr,
        uint256[][] memory _amounts,
        uint256[][] memory _times
    ) external onlyOwner {
        require(msg.sender == updater, "Permission error");
        uint256 tariff = 1;
        Tariff storage tariffObj = tariffs[tariff];
        for (uint256 j = 0; j < _addr.length; j++) {
            require(
                _amounts[j].length == _times[j].length,
                "Array length error"
            );
            uint256 len = _amounts[j].length;
            address addr = _addr[j];
            for (uint256 i = 0; i < len; i++) {
                uint256 amount = _amounts[j][i];
                uint256 currentTime = _times[j][i];
                investors[addr].registered = true;

                investors[addr].invested += amount;

                uint256 nextPrincipalWithdrawalDate = tariffObj.time +
                    currentTime;
                investors[addr].deposits.push(
                    Deposit(
                        tariff,
                        amount,
                        currentTime,
                        false,
                        0,
                        currentTime,
                        nextPrincipalWithdrawalDate
                    )
                );
            }
        }
    }

    function reDeposit(uint256 tariff) external {
        uint256 amount = withdrawableMint(msg.sender);

        require(amount >= min_deposit);
        require(
            tariff == 1 || tariff == 2,
            "Re Deposit allowed only in Plan 2 and Plan 3"
        );
        uint256 currentTime = block.timestamp;
        if (!investors[msg.sender].registered) {
            investors[msg.sender].registered = true;
            totalInvesters++;
        }
        investors[msg.sender].reinvest += amount;
        investors[msg.sender].paidAt = currentTime;
        totalReinvest += amount;

        investors[msg.sender].invested += amount;
        totalInvested += amount;

        Tariff storage tariffObj = tariffs[tariff];

        uint256 nextPrincipalWithdrawalDate = tariffObj.time + currentTime;
        investors[msg.sender].deposits.push(
            Deposit(
                tariff,
                amount,
                currentTime,
                true,
                0,
                currentTime,
                nextPrincipalWithdrawalDate
            )
        );

        emit ReDepositAt(msg.sender, tariff, amount);
    }

    function withdrawPrincipal(uint256 index) external {
        Investor storage investor = investors[msg.sender];
        Deposit storage dep = investor.deposits[index];
        require(investor.registered == true, "Invalid User");
        require(
            dep.nextPrincipalWithdrawAt <= block.timestamp,
            "Withdrawn Time not reached"
        );

        require(dep.withdrawPrincipal < dep.amount, "No Principal Found");
        uint256 currentTime = block.timestamp;

        uint256 withdrawnAmt = (dep.amount * 5) / 100;

        BEP20 _token = BEP20(RTCTokenAddress);
        require(
            _token.balanceOf(address(this)) >= withdrawnAmt,
            "Insufficient Contract Balance"
        );
        _token.transfer(msg.sender, withdrawnAmt);

        dep.withdrawPrincipal += withdrawnAmt;
        dep.withdrawPrincipalAt = currentTime;
        //dep.nextPrincipalWithdrawalAt =  currentTime + 7 days;
        dep.nextPrincipalWithdrawAt = currentTime + prinicipleWithdrawlInterval;

        emit WithdrawPrincipal(msg.sender, withdrawnAmt, currentTime, index);
    }

    function withdrawMint() external {
        require(investors[msg.sender].registered == true, "Invalid User");
        uint256 amount = withdrawableMint(msg.sender);
        require(amount >= min_withdrawl, "Minimum Withdraw Limit Exceed");
        BEP20 _token = BEP20(RTCTokenAddress);
        require(
            _token.balanceOf(address(this)) >= amount,
            "Insufficient Contract Balance"
        );
        if (_token.transfer(msg.sender, amount)) {
            investors[msg.sender].withdrawn += amount;
            investors[msg.sender].paidAt = block.timestamp;
            totalWithdrawl += amount;

            emit Withdraw(msg.sender, amount);
        }
    }

    function withdrawalToAddress(address payable to, uint256 amount)
        external
        onlyOwner
    {
        to.transfer(amount);
    }

    // Only owner can withdraw token
    function withdrawToken(
        address tokenAddress,
        address to,
        uint256 amount
    ) external onlyOwner {
        BEP20 tokenNew = BEP20(tokenAddress);
        tokenNew.transfer(to, amount);
    }

    function withdrawableMint(address user)
        public
        view
        returns (uint256 amount)
    {
        Investor storage investor = investors[user];

        for (uint256 i = 0; i < investor.deposits.length; i++) {
            Deposit storage dep = investor.deposits[i];
            Tariff storage tariff = tariffs[dep.tariff];

            uint256 finish = dep.at + tariff.time;
            uint256 since = investor.paidAt > dep.at ? investor.paidAt : dep.at;
            uint256 till = block.timestamp > finish ? finish : block.timestamp;

            if (since < till) {
                amount +=
                    (dep.amount * (till - since) * tariff.percent) /
                    tariff.time /
                    100;
            }
        }
    }

    /// Show Package Details
    function packageDetails(address addr)
        public
        view
        returns (
            bool isRegsitered,
            uint256[] memory packageAmt,
            uint256[] memory planType,
            uint256[] memory purchaseAt,
            uint256[] memory withdrawnPrincipalAmt,
            uint256[] memory withdrawnPrincipalAt,
            uint256[] memory nextWithdrawnPrincipalAt,
            bool[] memory withdrawBtn,
            bool[] memory reinvestStatus
        )
    {
        Investor storage investor = investors[addr];

        uint256 len = investor.deposits.length;
        packageAmt = new uint256[](len);
        planType = new uint256[](len);
        purchaseAt = new uint256[](len);
        withdrawnPrincipalAmt = new uint256[](len);
        withdrawnPrincipalAt = new uint256[](len);
        nextWithdrawnPrincipalAt = new uint256[](len);
        withdrawBtn = new bool[](len);
        reinvestStatus = new bool[](len);
        for (uint256 i = 0; i < investor.deposits.length; i++) {
            Deposit storage dep = investor.deposits[i];

            packageAmt[i] = dep.amount;
            planType[i] = dep.tariff;
            purchaseAt[i] = dep.at;
            reinvestStatus[i] = dep.reinvest;
            withdrawnPrincipalAmt[i] = dep.withdrawPrincipal;
            withdrawnPrincipalAt[i] = dep.withdrawPrincipalAt;
            nextWithdrawnPrincipalAt[i] = dep.nextPrincipalWithdrawAt;
            withdrawBtn[i] = (dep.nextPrincipalWithdrawAt < block.timestamp &&
                dep.amount > dep.withdrawPrincipalAt)
                ? true
                : false;
        }
        return (
            investor.registered,
            packageAmt,
            planType,
            purchaseAt,
            withdrawnPrincipalAmt,
            withdrawnPrincipalAt,
            nextWithdrawnPrincipalAt,
            withdrawBtn,
            reinvestStatus
        );
    }

    uint256 private RTC = 0;
    uint256 private RTCC = 1;

    function retopupStaking(uint256 amount, uint256 tokenID) public {
        require(tokenID < 2, "Error: input 0 for RTC and 1 for RTCC tokenID");
        require(amount >= min_deposit, "Error: please deposit 10 tokens");
        if (!investors[msg.sender].registered) {
            investors[msg.sender].registered = true;
            totalInvesters++;
        }

        uint256 rtcPrice = swapContractAddress.get_rtc_price();
        uint256 rtccPrice = swapContractAddress.get_rtcc_price();
        uint256 amount_in_USDT = amount * rtcPrice;
        uint256 return_token_in_RTCC = amount_in_USDT / rtccPrice;

        if (tokenID == 0) {
            RTCTokenAddress.transferFrom(msg.sender, owner(), amount);
            RTC_Plus_address.transferPrice(
                owner(),
                address(this),
                return_token_in_RTCC
            );
            investors[msg.sender].invested += return_token_in_RTCC;
            totalInvested += return_token_in_RTCC;
            investors[msg.sender]._retopup.push(
                retopup(return_token_in_RTCC, block.timestamp, 0, 0, 0)
            );
        } else if (tokenID == 1) {
            RTC_Plus_address.transferPrice(msg.sender, address(this), amount);
            investors[msg.sender].invested += amount;
            totalInvested += amount;
            investors[msg.sender]._retopup.push(
                retopup(amount, block.timestamp, 0, 0, 0)
            );
        }

        emit swapped(amount, amount_in_USDT, return_token_in_RTCC);
    }

    function generatedRewardForRetopup(address user)
        public
        view
        returns (uint256 amount)
    {
        Investor storage investor = investors[user];
        for (uint256 i = 0; i < investor._retopup.length; i++) {
            retopup storage retop = investor._retopup[i];
            uint256 secondsIN1000Days = 1000 * 24 * 60 * 60;
            uint256 matureTime = retop.timeAt + secondsIN1000Days;
            uint256 startingTime = investor.paidAt > retop.timeAt
                ? investor.paidAt
                : retop.timeAt;
            uint256 coolingPeriod = block.timestamp > matureTime
                ? matureTime
                : block.timestamp;

            if (startingTime < coolingPeriod) {
                amount +=
                    (retop.amount / secondsIN1000Days) *
                    (coolingPeriod - startingTime);
            }
        }
    }

    function claimRetopupReward() public {
        require(investors[msg.sender].registered == true, "Invalid User");
        uint256 amount = generatedRewardForRetopup(msg.sender);
        // require(amount >= min_withdrawl, "Minimum Withdraw Limit Exceed");
        RTC_Plus_address.transferPrice(address(this), msg.sender, amount);
        investors[msg.sender].withdrawn += amount;
        investors[msg.sender].paidAt = block.timestamp;
        totalWithdrawl += amount;

        emit claimRetopup(msg.sender, amount);
    }

    function packageDetailsForRetopup(address user)
        public
        view
        returns (
            bool isRegistered,
            uint256[] memory stakeAmount,
            uint256[] memory stakeAmountAt,
            uint256[] memory withdrawnPrincipalAmt,
            uint256[] memory withdrawnPrincipalAt,
            uint256[] memory nextWithdrawnPrincipalAt,
            bool[] memory withdrawBtn
        )
    {
        Investor storage investor = investors[user];
        uint256 len = investor._retopup.length;
        stakeAmount = new uint256[](len);
        stakeAmountAt = new uint256[](len);
        withdrawnPrincipalAmt = new uint256[](len);
        withdrawnPrincipalAt = new uint256[](len);
        nextWithdrawnPrincipalAt = new uint256[](len);
        withdrawBtn = new bool[](len);
        for (uint256 i = 0; i < investor._retopup.length; i++) {
            retopup storage retop = investor._retopup[i];
            stakeAmount[i] = retop.amount;
            stakeAmountAt[i] = retop.timeAt;
            withdrawnPrincipalAmt[i] = retop.withdrawnPrincipalAmt;
            withdrawnPrincipalAt[i] = retop.withdrawnPrincipalAt;
            nextWithdrawnPrincipalAt[i] = retop.nextWithdrawnPrincipalAt;
            withdrawBtn[i] = (retop.nextWithdrawnPrincipalAt <
                block.timestamp &&
                retop.amount > retop.withdrawnPrincipalAt)
                ? true
                : false;
        }
        return (
            investor.registered,
            stakeAmount,
            stakeAmountAt,
            withdrawnPrincipalAmt,
            withdrawnPrincipalAt,
            nextWithdrawnPrincipalAt,
            withdrawBtn
        );
    }
}