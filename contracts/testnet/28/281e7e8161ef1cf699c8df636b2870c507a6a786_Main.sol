/**
 *Submitted for verification at BscScan.com on 2023-01-03
*/

// File: contracts\contracts\ownership\ownable.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.6.2;

/**
 * @dev The contract has an owner address, and provides basic authorization control whitch
 * simplifies the implementation of user permissions. This contract is based on the source code at:
 * https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/ownership/Ownable.sol
 */
contract Ownable
{

  /**
   * @dev Error constants.
   */
  string public constant NOT_CURRENT_OWNER = "018001";
  string public constant CANNOT_TRANSFER_TO_ZERO_ADDRESS = "018002";

  /**
   * @dev Current owner address.
   */
  address public owner;

  /**
   * @dev An event which is triggered when the owner is changed.
   * @param previousOwner The address of the previous owner.
   * @param newOwner The address of the new owner.
   */
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev The constructor sets the original `owner` of the contract to the sender account.
   */
  constructor()
  public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner()
  {
    require(msg.sender == owner, NOT_CURRENT_OWNER);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(
    address _newOwner
  )
    public
    onlyOwner
  {
    require(_newOwner != address(0), CANNOT_TRANSFER_TO_ZERO_ADDRESS);
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }

}

// File: @openzeppelin\contracts\utils\Context.sol



pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin\contracts\token\ERC20\IERC20.sol



pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
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

// File: @openzeppelin\contracts\math\SafeMath.sol



pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin\contracts\token\ERC20\ERC20.sol



pragma solidity >=0.6.0 <0.8.0;



/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
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
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
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

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// File: @openzeppelin\contracts\utils\Address.sol



pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

// File: @openzeppelin\contracts\token\ERC20\SafeERC20.sol



pragma solidity >=0.6.0 <0.8.0;



/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: contracts\contracts\tokens\erc721.sol


pragma solidity 0.6.2;

/**
 * @dev ERC-721 non-fungible token standard.
 * See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md.
 */
interface ERC721
{

  /**
   * @dev Emits when ownership of any NFT changes by any mechanism. This event emits when NFTs are
   * created (`from` == 0) and destroyed (`to` == 0). Exception: during contract creation, any
   * number of NFTs may be created and assigned without emitting Transfer. At the time of any
   * transfer, the approved address for that NFT (if any) is reset to none.
   */
  event Transfer(
    address indexed _from,
    address indexed _to,
    uint256 indexed _tokenId
  );

  /**
   * @dev This emits when the approved address for an NFT is changed or reaffirmed. The zero
   * address indicates there is no approved address. When a Transfer event emits, this also
   * indicates that the approved address for that NFT (if any) is reset to none.
   */
  event Approval(
    address indexed _owner,
    address indexed _approved,
    uint256 indexed _tokenId
  );

  /**
   * @dev This emits when an operator is enabled or disabled for an owner. The operator can manage
   * all NFTs of the owner.
   */
  event ApprovalForAll(
    address indexed _owner,
    address indexed _operator,
    bool _approved
  );

  /**
   * @dev Transfers the ownership of an NFT from one address to another address.
   * @notice Throws unless `msg.sender` is the current owner, an authorized operator, or the
   * approved address for this NFT. Throws if `_from` is not the current owner. Throws if `_to` is
   * the zero address. Throws if `_tokenId` is not a valid NFT. When transfer is complete, this
   * function checks if `_to` is a smart contract (code size > 0). If so, it calls
   * `onERC721Received` on `_to` and throws if the return value is not
   * `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`.
   * @param _from The current owner of the NFT.
   * @param _to The new owner.
   * @param _tokenId The NFT to transfer.
   * @param _data Additional data with no specified format, sent in call to `_to`.
   */
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes calldata _data
  )
    external;

  /**
   * @dev Transfers the ownership of an NFT from one address to another address.
   * @notice This works identically to the other function with an extra data parameter, except this
   * function just sets data to ""
   * @param _from The current owner of the NFT.
   * @param _to The new owner.
   * @param _tokenId The NFT to transfer.
   */
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    external;

  /**
   * @dev Throws unless `msg.sender` is the current owner, an authorized operator, or the approved
   * address for this NFT. Throws if `_from` is not the current owner. Throws if `_to` is the zero
   * address. Throws if `_tokenId` is not a valid NFT.
   * @notice The caller is responsible to confirm that `_to` is capable of receiving NFTs or else
   * they may be permanently lost.
   * @param _from The current owner of the NFT.
   * @param _to The new owner.
   * @param _tokenId The NFT to transfer.
   */
  function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    external;

  /**
   * @dev Set or reaffirm the approved address for an NFT.
   * @notice The zero address indicates there is no approved address. Throws unless `msg.sender` is
   * the current NFT owner, or an authorized operator of the current owner.
   * @param _approved The new approved NFT controller.
   * @param _tokenId The NFT to approve.
   */
  function approve(
    address _approved,
    uint256 _tokenId
  )
    external;

  /**
   * @dev Enables or disables approval for a third party ("operator") to manage all of
   * `msg.sender`'s assets. It also emits the ApprovalForAll event.
   * @notice The contract MUST allow multiple operators per owner.
   * @param _operator Address to add to the set of authorized operators.
   * @param _approved True if the operators is approved, false to revoke approval.
   */
  function setApprovalForAll(
    address _operator,
    bool _approved
  )
    external;

  /**
   * @dev Returns the number of NFTs owned by `_owner`. NFTs assigned to the zero address are
   * considered invalid, and this function throws for queries about the zero address.
   * @notice Count all NFTs assigned to an owner.
   * @param _owner Address for whom to query the balance.
   * @return Balance of _owner.
   */
  function balanceOf(
    address _owner
  )
    external
    view
    returns (uint256);

  /**
   * @dev Returns the address of the owner of the NFT. NFTs assigned to the zero address are
   * considered invalid, and queries about them do throw.
   * @notice Find the owner of an NFT.
   * @param _tokenId The identifier for an NFT.
   * @return Address of _tokenId owner.
   */
  function ownerOf(
    uint256 _tokenId
  )
    external
    view
    returns (address);

  /**
   * @dev Get the approved address for a single NFT.
   * @notice Throws if `_tokenId` is not a valid NFT.
   * @param _tokenId The NFT to find the approved address for.
   * @return Address that _tokenId is approved for.
   */
  function getApproved(
    uint256 _tokenId
  )
    external
    view
    returns (address);

  /**
   * @dev Returns true if `_operator` is an approved operator for `_owner`, false otherwise.
   * @notice Query if an address is an authorized operator for another address
   * @param _owner The address that owns the NFTs.
   * @param _operator The address that acts on behalf of the owner.
   * @return True if approved for all, false otherwise.
   */
  function isApprovedForAll(
    address _owner,
    address _operator
  )
    external
    view
    returns (bool);

}

// File: contracts\contracts\tokens\erc721-token-receiver.sol


pragma solidity 0.6.2;

/**
 * @dev ERC-721 interface for accepting safe transfers.
 * See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md.
 */
interface ERC721TokenReceiver
{

  /**
   * @dev Handle the receipt of a NFT. The ERC721 smart contract calls this function on the
   * recipient after a `transfer`. This function MAY throw to revert and reject the transfer. Return
   * of other than the magic value MUST result in the transaction being reverted.
   * Returns `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))` unless throwing.
   * @notice The contract address is always the message sender. A wallet/broker/auction application
   * MUST implement the wallet interface if it will accept safe transfers.
   * @param _operator The address which called `safeTransferFrom` function.
   * @param _from The address which previously owned the token.
   * @param _tokenId The NFT identifier which is being transferred.
   * @param _data Additional data with no specified format.
   * @return Returns `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
   */
  function onERC721Received(
    address _operator,
    address _from,
    uint256 _tokenId,
    bytes calldata _data
  )
    external
    returns(bytes4);

}

// File: contracts\contracts\utils\erc165.sol


pragma solidity 0.6.2;

/**
 * @dev A standard for detecting smart contract interfaces.
 * See: https://eips.ethereum.org/EIPS/eip-165.
 */
interface ERC165
{

  /**
   * @dev Checks if the smart contract includes a specific interface.
   * This function uses less than 30,000 gas.
   * @param _interfaceID The interface identifier, as specified in ERC-165.
   * @return True if _interfaceID is supported, false otherwise.
   */
  function supportsInterface(
    bytes4 _interfaceID
  )
    external
    view
    returns (bool);

}

// File: contracts\contracts\utils\supports-interface.sol


pragma solidity 0.6.2;
/**
 * @dev Implementation of standard for detect smart contract interfaces.
 */
contract SupportsInterface is
  ERC165
{

  /**
   * @dev Mapping of supported intefraces. You must not set element 0xffffffff to true.
   */
  mapping(bytes4 => bool) internal supportedInterfaces;

  /**
   * @dev Contract constructor.
   */
  constructor()
  public {
    supportedInterfaces[0x01ffc9a7] = true; // ERC165
  }

  /**
   * @dev Function to check which interfaces are suported by this contract.
   * @param _interfaceID Id of the interface.
   * @return True if _interfaceID is supported, false otherwise.
   */
  function supportsInterface(
    bytes4 _interfaceID
  )
    external
    override
    view
    returns (bool)
  {
    return supportedInterfaces[_interfaceID];
  }

}

// File: contracts\contracts\utils\address-utils.sol


pragma solidity 0.6.2;

/**
 * @dev Utility library of inline functions on addresses.
 * @notice Based on:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol
 * Requires EIP-1052.
 */
library AddressUtils
{

  /**
   * @dev Returns whether the target address is a contract.
   * @param _addr Address to check.
   * @return addressCheck True if _addr is a contract, false if not.
   */
  function isContract(
    address _addr
  )
    internal
    view
    returns (bool addressCheck)
  {
    // This method relies in extcodesize, which returns 0 for contracts in
    // construction, since the code is only stored at the end of the
    // constructor execution.

    // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
    // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
    // for accounts without code, i.e. `keccak256('')`
    bytes32 codehash;
    bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
    assembly { codehash := extcodehash(_addr) } // solhint-disable-line
    addressCheck = (codehash != 0x0 && codehash != accountHash);
  }

}

// File: contracts\contracts\tokens\nf-token.sol


pragma solidity 0.6.2;




//import "hardhat/console.sol";

/**
 * @dev Implementation of ERC-721 non-fungible token standard.
 */
contract NFToken is
  ERC721,
  SupportsInterface
{
  using AddressUtils for address;

  /**
   * @dev List of revert message codes. Implementing dApp should handle showing the correct message.
   * Based on 0xcert framework error codes.
   */
  string constant ZERO_ADDRESS = "003001";
  string constant NOT_VALID_NFT = "003002";
  string constant NOT_OWNER_OR_OPERATOR = "003003";
  string constant NOT_OWNER_APPROVED_OR_OPERATOR = "003004";
  string constant NOT_ABLE_TO_RECEIVE_NFT = "003005";
  string constant NFT_ALREADY_EXISTS = "003006";
  string constant NOT_OWNER = "003007";
  string constant IS_OWNER = "003008";

  /**
   * @dev Magic value of a smart contract that can receive NFT.
   * Equal to: bytes4(keccak256("onERC721Received(address,address,uint256,bytes)")).
   */
  bytes4 internal constant MAGIC_ON_ERC721_RECEIVED = 0x150b7a02;

  /**
   * @dev A mapping from NFT ID to the address that owns it.
   */
  mapping (uint256 => address) internal idToOwner;

  /**
   * @dev Mapping from NFT ID to approved address.
   */
  mapping (uint256 => address) internal idToApproval;

   /**
   * @dev Mapping from owner address to count of their tokens.
   */
  mapping (address => uint256) private ownerToNFTokenCount;

  /**
   * @dev Mapping from owner address to mapping of operator addresses.
   */
  mapping (address => mapping (address => bool)) internal ownerToOperators;

  /**
   * @dev Guarantees that the msg.sender is an owner or operator of the given NFT.
   * @param _tokenId ID of the NFT to validate.
   */
  modifier canOperate(
    uint256 _tokenId
  )
  {
    address tokenOwner = idToOwner[_tokenId];
    require(
      tokenOwner == msg.sender || ownerToOperators[tokenOwner][msg.sender],
      NOT_OWNER_OR_OPERATOR
    );
    _;
  }

  /**
   * @dev Guarantees that the msg.sender is allowed to transfer NFT.
   * @param _tokenId ID of the NFT to transfer.
   */
  modifier canTransfer(
    uint256 _tokenId
  )
  {
    address tokenOwner = idToOwner[_tokenId];
    require(
      tokenOwner == msg.sender
      || idToApproval[_tokenId] == msg.sender
      || ownerToOperators[tokenOwner][msg.sender],
      NOT_OWNER_APPROVED_OR_OPERATOR
    );
    _;
  }

  /**
   * @dev Guarantees that _tokenId is a valid Token.
   * @param _tokenId ID of the NFT to validate.
   */
  modifier validNFToken(
    uint256 _tokenId
  )
  {
    require(idToOwner[_tokenId] != address(0), NOT_VALID_NFT);
    _;
  }

  /**
   * @dev Contract constructor.
   */
  constructor()
  public {
    supportedInterfaces[0x80ac58cd] = true; // ERC721
  }

  /**
   * @dev Transfers the ownership of an NFT from one address to another address. This function can
   * be changed to payable.
   * @notice Throws unless `msg.sender` is the current owner, an authorized operator, or the
   * approved address for this NFT. Throws if `_from` is not the current owner. Throws if `_to` is
   * the zero address. Throws if `_tokenId` is not a valid NFT. When transfer is complete, this
   * function checks if `_to` is a smart contract (code size > 0). If so, it calls
   * `onERC721Received` on `_to` and throws if the return value is not
   * `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`.
   * @param _from The current owner of the NFT.
   * @param _to The new owner.
   * @param _tokenId The NFT to transfer.
   * @param _data Additional data with no specified format, sent in call to `_to`.
   */
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes calldata _data
  )
    external
    override
    virtual
  {
    _safeTransferFrom(_from, _to, _tokenId, _data);
  }

  /**
   * @dev Transfers the ownership of an NFT from one address to another address. This function can
   * be changed to payable.
   * @notice This works identically to the other function with an extra data parameter, except this
   * function just sets data to ""
   * @param _from The current owner of the NFT.
   * @param _to The new owner.
   * @param _tokenId The NFT to transfer.
   */
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    external
    override
    virtual
  {
    _safeTransferFrom(_from, _to, _tokenId, "");
  }

  /**
   * @dev Throws unless `msg.sender` is the current owner, an authorized operator, or the approved
   * address for this NFT. Throws if `_from` is not the current owner. Throws if `_to` is the zero
   * address. Throws if `_tokenId` is not a valid NFT. This function can be changed to payable.
   * @notice The caller is responsible to confirm that `_to` is capable of receiving NFTs or else
   * they may be permanently lost.
   * @param _from The current owner of the NFT.
   * @param _to The new owner.
   * @param _tokenId The NFT to transfer.
   */
  function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    external
    override
    virtual
    canTransfer(_tokenId)
    validNFToken(_tokenId)
  {
    address tokenOwner = idToOwner[_tokenId];
    require(tokenOwner == _from, NOT_OWNER);
    require(_to != address(0), ZERO_ADDRESS);

    _transfer(_to, _tokenId);
  }

  /**
   * @dev Set or reaffirm the approved address for an NFT. This function can be changed to payable.
   * @notice The zero address indicates there is no approved address. Throws unless `msg.sender` is
   * the current NFT owner, or an authorized operator of the current owner.
   * @param _approved Address to be approved for the given NFT ID.
   * @param _tokenId ID of the token to be approved.
   */
  function approve(
    address _approved,
    uint256 _tokenId
  )
    external
    override
    canOperate(_tokenId)
    validNFToken(_tokenId)
  {
    address tokenOwner = idToOwner[_tokenId];
    require(_approved != tokenOwner, IS_OWNER);

    idToApproval[_tokenId] = _approved;
    emit Approval(tokenOwner, _approved, _tokenId);
  }

  /**
   * @dev Enables or disables approval for a third party ("operator") to manage all of
   * `msg.sender`'s assets. It also emits the ApprovalForAll event.
   * @notice This works even if sender doesn't own any tokens at the time.
   * @param _operator Address to add to the set of authorized operators.
   * @param _approved True if the operators is approved, false to revoke approval.
   */
  function setApprovalForAll(
    address _operator,
    bool _approved
  )
    external
    override
  {
    ownerToOperators[msg.sender][_operator] = _approved;
    emit ApprovalForAll(msg.sender, _operator, _approved);
  }

  /**
   * @dev Returns the number of NFTs owned by `_owner`. NFTs assigned to the zero address are
   * considered invalid, and this function throws for queries about the zero address.
   * @param _owner Address for whom to query the balance.
   * @return Balance of _owner.
   */
  function balanceOf(
    address _owner
  )
    external
    override
    view
    returns (uint256)
  {
    require(_owner != address(0), ZERO_ADDRESS);
    return _getOwnerNFTCount(_owner);
  }

  /**
   * @dev Returns the address of the owner of the NFT. NFTs assigned to the zero address are
   * considered invalid, and queries about them do throw.
   * @param _tokenId The identifier for an NFT.
   * @return _owner Address of _tokenId owner.
   */
  function ownerOf(
    uint256 _tokenId
  )
    external
    override
    view
    returns (address _owner)
  {
    _owner = idToOwner[_tokenId];
    require(_owner != address(0), NOT_VALID_NFT);
  }

  /**
   * @dev Get the approved address for a single NFT.
   * @notice Throws if `_tokenId` is not a valid NFT.
   * @param _tokenId ID of the NFT to query the approval of.
   * @return Address that _tokenId is approved for.
   */
  function getApproved(
    uint256 _tokenId
  )
    external
    override
    view
    validNFToken(_tokenId)
    returns (address)
  {
    return idToApproval[_tokenId];
  }

  /**
   * @dev Checks if `_operator` is an approved operator for `_owner`.
   * @param _owner The address that owns the NFTs.
   * @param _operator The address that acts on behalf of the owner.
   * @return True if approved for all, false otherwise.
   */
  function isApprovedForAll(
    address _owner,
    address _operator
  )
    external
    override
    view
    returns (bool)
  {
    return ownerToOperators[_owner][_operator];
  }

  /**
   * @dev Actually performs the transfer.
   * @notice Does NO checks.
   * @param _to Address of a new owner.
   * @param _tokenId The NFT that is being transferred.
   */
  function _transfer(
    address _to,
    uint256 _tokenId
  )
    internal
  {
    address from = idToOwner[_tokenId];
    _clearApproval(_tokenId);

    _removeNFToken(from, _tokenId);
    _addNFToken(_to, _tokenId);

    emit Transfer(from, _to, _tokenId);
  }

  /**
   * @dev Mints a new NFT.
   * @notice This is an internal function which should be called from user-implemented external
   * mint function. Its purpose is to show and properly initialize data structures when using this
   * implementation.
   * @param _to The address that will own the minted NFT.
   * @param _tokenId of the NFT to be minted by the msg.sender.
   */
  function _mint(
    address _to,
    uint256 _tokenId
  )
    internal
    virtual
  {
    require(_to != address(0), ZERO_ADDRESS);
    require(idToOwner[_tokenId] == address(0), NFT_ALREADY_EXISTS);

    _addNFToken(_to, _tokenId);

    emit Transfer(address(0), _to, _tokenId);
  }

  /**
   * @dev Burns a NFT.
   * @notice This is an internal function which should be called from user-implemented external burn
   * function. Its purpose is to show and properly initialize data structures when using this
   * implementation. Also, note that this burn implementation allows the minter to re-mint a burned
   * NFT.
   * @param _tokenId ID of the NFT to be burned.
   */
  function _burn(
    uint256 _tokenId
  )
    internal
    virtual
    validNFToken(_tokenId)
  {
    address tokenOwner = idToOwner[_tokenId];
    _clearApproval(_tokenId);
    _removeNFToken(tokenOwner, _tokenId);
    emit Transfer(tokenOwner, address(0), _tokenId);
  }

  /**
   * @dev Removes a NFT from owner.
   * @notice Use and override this function with caution. Wrong usage can have serious consequences.
   * @param _from Address from which we want to remove the NFT.
   * @param _tokenId Which NFT we want to remove.
   */
  function _removeNFToken(
    address _from,
    uint256 _tokenId
  )
    internal
    virtual
  {
    require(idToOwner[_tokenId] == _from, NOT_OWNER);
    ownerToNFTokenCount[_from] -= 1;
    delete idToOwner[_tokenId];
  }

  /**
   * @dev Assigns a new NFT to owner.
   * @notice Use and override this function with caution. Wrong usage can have serious consequences.
   * @param _to Address to which we want to add the NFT.
   * @param _tokenId Which NFT we want to add.
   */
  function _addNFToken(
    address _to,
    uint256 _tokenId
  )
    internal
    virtual
  {
    require(idToOwner[_tokenId] == address(0), NFT_ALREADY_EXISTS);

    idToOwner[_tokenId] = _to;
    ownerToNFTokenCount[_to] += 1;
  }

  /**
   * @dev Helper function that gets NFT count of owner. This is needed for overriding in enumerable
   * extension to remove double storage (gas optimization) of owner NFT count.
   * @param _owner Address for whom to query the count.
   * @return Number of _owner NFTs.
   */
  function _getOwnerNFTCount(
    address _owner
  )
    internal
    virtual
    view
    returns (uint256)
  {
    return ownerToNFTokenCount[_owner];
  }

  /**
   * @dev Actually perform the safeTransferFrom.
   * @param _from The current owner of the NFT.
   * @param _to The new owner.
   * @param _tokenId The NFT to transfer.
   * @param _data Additional data with no specified format, sent in call to `_to`.
   */
  function _safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes memory _data
  )
    internal
    canTransfer(_tokenId)
    validNFToken(_tokenId)
  {
    address tokenOwner = idToOwner[_tokenId];
    require(tokenOwner == _from, NOT_OWNER);
    require(_to != address(0), ZERO_ADDRESS);

    _transfer(_to, _tokenId);

     if (_to.isContract())
     {
       bytes4 retval = ERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data);
       require(retval == MAGIC_ON_ERC721_RECEIVED, NOT_ABLE_TO_RECEIVE_NFT);
     }
  }

  /**
   * @dev Clears the current approval of a given NFT ID.
   * @param _tokenId ID of the NFT to be transferred.
   */
  function _clearApproval(
    uint256 _tokenId
  )
    private
  {
    delete idToApproval[_tokenId];
  }

}

// File: contracts\contracts\tokens\erc721-metadata.sol


pragma solidity 0.6.2;

/**
 * @dev Optional metadata extension for ERC-721 non-fungible token standard.
 * See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md.
 */
interface ERC721Metadata
{

  /**
   * @dev Returns a descriptive name for a collection of NFTs in this contract.
   * @return _name Representing name.
   */
  function name()
    external
    view
    returns (string memory _name);

  /**
   * @dev Returns a abbreviated name for a collection of NFTs in this contract.
   * @return _symbol Representing symbol.
   */
  function symbol()
    external
    view
    returns (string memory _symbol);

  /**
   * @dev Returns a distinct Uniform Resource Identifier (URI) for a given asset. It Throws if
   * `_tokenId` is not a valid NFT. URIs are defined in RFC3986. The URI may point to a JSON file
   * that conforms to the "ERC721 Metadata JSON Schema".
   * @return URI of _tokenId.
   */
  function tokenURI(uint256 _tokenId)
    external
    view
    returns (string memory);

}

// File: contracts\contracts\tokens\nf-token-metadata.sol


pragma solidity 0.6.2;


//import "hardhat/console.sol";

/**
 * @dev Optional metadata implementation for ERC-721 non-fungible token standard.
 */
contract NFTokenMetadata is
  NFToken,
  ERC721Metadata
{

  /**
   * @dev A descriptive name for a collection of NFTs.
   */
  string internal nftName;

  /**
   * @dev An abbreviated name for NFTokens.
   */
  string internal nftSymbol;

  /**
   * @dev Mapping from NFT ID to metadata uri.
   */
  mapping (uint256 => string) internal idToUri;

  uint256 internal randNonce;


  /**
   * @dev Contract constructor.
   * @notice When implementing this contract don't forget to set nftName and nftSymbol.
   */
  constructor()
  public {
    supportedInterfaces[0x5b5e139f] = true; // ERC721Metadata
  }

  /**
   * @dev Returns a descriptive name for a collection of NFTokens.
   * @return _name Representing name.
   */
  function name()
    external
    override
    view
    returns (string memory _name)
  {
    _name = nftName;
  }

  /**
   * @dev Returns an abbreviated name for NFTokens.
   * @return _symbol Representing symbol.
   */
  function symbol()
    external
    override
    view
    returns (string memory _symbol)
  {
    _symbol = nftSymbol;
  }

  /**
   * @dev A distinct URI (RFC 3986) for a given NFT.
   * @param _tokenId Id for which we want uri.
   * @return URI of _tokenId.
   */
  function tokenURI(
    uint256 _tokenId
  )
    external
    virtual
    override
    view
    validNFToken(_tokenId)
    returns (string memory)
  {
    return _tokenURI(_tokenId);
  }

  /**
   * @notice This is an internal function that can be overriden if you want to implement a different
   * way to generate token URI.
   * @param _tokenId Id for which we want uri.
   * @return URI of _tokenId.
   */
  function _tokenURI(
    uint256 _tokenId
  )
    internal
    virtual
    view
    returns (string memory)
  {
    return idToUri[_tokenId];
  }

  function _mint(address _to, uint256 _tokenId) internal override virtual {
    super._mint(_to, _tokenId);
  }

  /**
   * @dev Burns a NFT.
   * @notice This is an internal function which should be called from user-implemented external
   * burn function. Its purpose is to show and properly initialize data structures when using this
   * implementation. Also, note that this burn implementation allows the minter to re-mint a burned
   * NFT.
   * @param _tokenId ID of the NFT to be burned.
   */
  function _burn(
    uint256 _tokenId
  )
    internal
    override
    virtual
  {
    super._burn(_tokenId);
    delete idToUri[_tokenId];
  }

  function _setTokenUri(
    uint256 _tokenId,
    string memory _uri
  )
    internal
    validNFToken(_tokenId)
  {
    idToUri[_tokenId] = _uri;
  }

}

// File: contracts\contracts\tokens\erc721-enumerable.sol


pragma solidity 0.6.2;

/**
 * @dev Optional enumeration extension for ERC-721 non-fungible token standard.
 * See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md.
 */
interface ERC721Enumerable
{

  /**
   * @dev Returns a count of valid NFTs tracked by this contract, where each one of them has an
   * assigned and queryable owner not equal to the zero address.
   * @return Total supply of NFTs.
   */
  function totalSupply()
    external
    view
    returns (uint256);

  /**
   * @dev Returns the token identifier for the `_index`th NFT. Sort order is not specified.
   * @param _index A counter less than `totalSupply()`.
   * @return Token id.
   */
  function tokenByIndex(
    uint256 _index
  )
    external
    view
    returns (uint256);

  /**
   * @dev Returns the token identifier for the `_index`th NFT assigned to `_owner`. Sort order is
   * not specified. It throws if `_index` >= `balanceOf(_owner)` or if `_owner` is the zero address,
   * representing invalid NFTs.
   * @param _owner An address where we are interested in NFTs owned by them.
   * @param _index A counter less than `balanceOf(_owner)`.
   * @return Token id.
   */
  function tokenOfOwnerByIndex(
    address _owner,
    uint256 _index
  )
    external
    view
    returns (uint256);

}

// File: contracts\contracts\tokens\nf-token-enumerable.sol


pragma solidity 0.6.2;


/**
 * @dev Optional enumeration implementation for ERC-721 non-fungible token standard.
 */
contract NFTokenEnumerable is
  NFToken,
  ERC721Enumerable
{

  /**
   * @dev List of revert message codes. Implementing dApp should handle showing the correct message.
   * Based on 0xcert framework error codes.
   */
  string constant INVALID_INDEX = "005007";

  /**
   * @dev Array of all NFT IDs.
   */
  uint256[] internal tokens;

  /**
   * @dev Mapping from token ID to its index in global tokens array.
   */
  mapping(uint256 => uint256) internal idToIndex;

  /**
   * @dev Mapping from owner to list of owned NFT IDs.
   */
  mapping(address => uint256[]) internal ownerToIds;

  /**
   * @dev Mapping from NFT ID to its index in the owner tokens list.
   */
  mapping(uint256 => uint256) internal idToOwnerIndex;

  /**
   * @dev Contract constructor.
   */
  constructor()
  public {
    supportedInterfaces[0x780e9d63] = true; // ERC721Enumerable
  }

  /**
   * @dev Returns the count of all existing NFTokens.
   * @return Total supply of NFTs.
   */
  function totalSupply()
    external
    override
    view
    returns (uint256)
  {
    return tokens.length;
  }

  /**
   * @dev Returns NFT ID by its index.
   * @param _index A counter less than `totalSupply()`.
   * @return Token id.
   */
  function tokenByIndex(
    uint256 _index
  )
    external
    override
    view
    returns (uint256)
  {
    require(_index < tokens.length, INVALID_INDEX);
    return tokens[_index];
  }

  /**
   * @dev returns the n-th NFT ID from a list of owner's tokens.
   * @param _owner Token owner's address.
   * @param _index Index number representing n-th token in owner's list of tokens.
   * @return Token id.
   */
  function tokenOfOwnerByIndex(
    address _owner,
    uint256 _index
  )
    external
    override
    view
    returns (uint256)
  {
    require(_index < ownerToIds[_owner].length, INVALID_INDEX);
    return ownerToIds[_owner][_index];
  }

  /**
   * @dev Mints a new NFT.
   * @notice This is an internal function which should be called from user-implemented external
   * mint function. Its purpose is to show and properly initialize data structures when using this
   * implementation.
   * @param _to The address that will own the minted NFT.
   * @param _tokenId of the NFT to be minted by the msg.sender.
   */
  function _mint(
    address _to,
    uint256 _tokenId
  )
    internal
    override
    virtual
  {
    super._mint(_to, _tokenId);
    tokens.push(_tokenId);
    idToIndex[_tokenId] = tokens.length - 1;
  }

  /**
   * @dev Burns a NFT.
   * @notice This is an internal function which should be called from user-implemented external
   * burn function. Its purpose is to show and properly initialize data structures when using this
   * implementation. Also, note that this burn implementation allows the minter to re-mint a burned
   * NFT.
   * @param _tokenId ID of the NFT to be burned.
   */
  function _burn(
    uint256 _tokenId
  )
    internal
    override
    virtual
  {
    super._burn(_tokenId);

    uint256 tokenIndex = idToIndex[_tokenId];
    uint256 lastTokenIndex = tokens.length - 1;
    uint256 lastToken = tokens[lastTokenIndex];

    tokens[tokenIndex] = lastToken;

    tokens.pop();
    // This wastes gas if you are burning the last token but saves a little gas if you are not.
    idToIndex[lastToken] = tokenIndex;
    idToIndex[_tokenId] = 0;
  }

  /**
   * @dev Removes a NFT from an address.
   * @notice Use and override this function with caution. Wrong usage can have serious consequences.
   * @param _from Address from wich we want to remove the NFT.
   * @param _tokenId Which NFT we want to remove.
   */
  function _removeNFToken(
    address _from,
    uint256 _tokenId
  )
    internal
    override
    virtual
  {
    require(idToOwner[_tokenId] == _from, NOT_OWNER);
    delete idToOwner[_tokenId];

    uint256 tokenToRemoveIndex = idToOwnerIndex[_tokenId];
    uint256 lastTokenIndex = ownerToIds[_from].length - 1;

    if (lastTokenIndex != tokenToRemoveIndex)
    {
      uint256 lastToken = ownerToIds[_from][lastTokenIndex];
      ownerToIds[_from][tokenToRemoveIndex] = lastToken;
      idToOwnerIndex[lastToken] = tokenToRemoveIndex;
    }

    ownerToIds[_from].pop();
  }

  /**
   * @dev Assigns a new NFT to an address.
   * @notice Use and override this function with caution. Wrong usage can have serious consequences.
   * @param _to Address to wich we want to add the NFT.
   * @param _tokenId Which NFT we want to add.
   */
  function _addNFToken(
    address _to,
    uint256 _tokenId
  )
    internal
    override
    virtual
  {
    require(idToOwner[_tokenId] == address(0), NFT_ALREADY_EXISTS);
    idToOwner[_tokenId] = _to;

    ownerToIds[_to].push(_tokenId);
    idToOwnerIndex[_tokenId] = ownerToIds[_to].length - 1;
  }

  /**
   * @dev Helper function that gets NFT count of owner. This is needed for overriding in enumerable
   * extension to remove double storage(gas optimization) of owner NFT count.
   * @param _owner Address for whom to query the count.
   * @return Number of _owner NFTs.
   */
  function _getOwnerNFTCount(
    address _owner
  )
    internal
    override
    virtual
    view
    returns (uint256)
  {
    return ownerToIds[_owner].length;
  }
}

// File: @openzeppelin\contracts\utils\EnumerableSet.sol



pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// File: @openzeppelin\contracts\access\AccessControl.sol



pragma solidity >=0.6.0 <0.8.0;



/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// File: @openzeppelin\contracts\utils\Counters.sol



pragma solidity >=0.6.0 <0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 * Since it is not possible to overflow a 256 bit integer with increments of one, `increment` can skip the {SafeMath}
 * overflow check, thereby saving gas. This does assume however correct usage, in that the underlying `_value` is never
 * directly accessed.
 */
library Counters {
    using SafeMath for uint256;

    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        // The {SafeMath} overflow check can be skipped here, see the comment at the top
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

// File: contracts\contracts\mocks\nf-token-metadata-enumerable-mock-nft.sol


pragma solidity 0.6.2;


//import "hardhat/console.sol";


/**
 * @dev This is an example contract implementation of NFToken with enumerable and metadata
 * extensions.
 */
contract NFT is
NFTokenEnumerable,
NFTokenMetadata,
AccessControl
{
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;
  string public baseUri;
  bytes32 public constant MINT_ROLE = keccak256("MINT_ROLE");


  /**
   * @dev Contract constructor.
   * @param _name A descriptive name for a collection of NFTs.
   * @param _symbol An abbreviated name for NFTokens.
   */
  constructor(
    string memory _name,
    string memory _symbol,
    string memory _baseUri
  ) public
  {
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    _setupRole(MINT_ROLE, _msgSender());

    nftName = _name;
    nftSymbol = _symbol;

    baseUri = _baseUri;
  }

  //  function setRoleAdmin(bytes32 roleId, bytes32 adminRoleId) public {
  //    _setRoleAdmin(roleId, adminRoleId);
  //  }

  function mint(
    address _to
  )
  external
  {
    require(hasRole(MINT_ROLE, _msgSender()), "mint: need mint role");
    uint _tokenId = _tokenIds.current();
    super._mint(_to, _tokenId);
    super._setTokenUri(_tokenId, baseUri);
    _tokenIds.increment();
  }

  function mint(
    address _to,
    uint256 _amount
  )
  external
  {
    require(hasRole(MINT_ROLE, _msgSender()), "mint: need mint role");
    for (uint i = 0; i < _amount; i++) {
      uint _tokenId = _tokenIds.current();
      super._mint(_to, _tokenId);
      super._setTokenUri(_tokenId, baseUri);
      _tokenIds.increment();
    }
  }

  /**
   * @dev Removes a NFT from owner.
   * @param _tokenId Which NFT we want to remove.
   */
  function burn(
    uint256 _tokenId
  )
  external
  {
    require(idToOwner[_tokenId] == _msgSender(), "burn: not owner");
    super._burn(_tokenId);
  }

  /**
   * @dev Mints a new NFT.
   * @notice This is an internal function which should be called from user-implemented external
   * mint function. Its purpose is to show and properly initialize data structures when using this
   * implementation.
   * @param _to The address that will own the minted NFT.
   * @param _tokenId of the NFT to be minted by the msg.sender.
   */
  function _mint(
    address _to,
    uint256 _tokenId
  )
  internal
  override(NFTokenMetadata, NFTokenEnumerable)
  virtual
  {
    NFTokenEnumerable._mint(_to, _tokenId);
  }

  /**
   * @dev Burns a NFT.
   * @notice This is an internal function which should be called from user-implemented external
   * burn function. Its purpose is to show and properly initialize data structures when using this
   * implementation. Also, note that this burn implementation allows the minter to re-mint a burned
   * NFT.
   * @param _tokenId ID of the NFT to be burned.
   */
  function _burn(
    uint256 _tokenId
  )
  internal
  override(NFTokenMetadata, NFTokenEnumerable)
  virtual
  {
    NFTokenEnumerable._burn(_tokenId);
    if (bytes(idToUri[_tokenId]).length != 0)
    {
      delete idToUri[_tokenId];
    }
  }

  /**
   * @dev Removes a NFT from an address.
   * @notice Use and override this function with caution. Wrong usage can have serious consequences.
   * @param _from Address from wich we want to remove the NFT.
   * @param _tokenId Which NFT we want to remove.
   */
  function _removeNFToken(
    address _from,
    uint256 _tokenId
  )
  internal
  override(NFToken, NFTokenEnumerable)
  {
    NFTokenEnumerable._removeNFToken(_from, _tokenId);
  }

  /**
   * @dev Assigns a new NFT to an address.
   * @notice Use and override this function with caution. Wrong usage can have serious consequences.
   * @param _to Address to wich we want to add the NFT.
   * @param _tokenId Which NFT we want to add.
   */
  function _addNFToken(
    address _to,
    uint256 _tokenId
  )
  internal
  override(NFToken, NFTokenEnumerable)
  {
    NFTokenEnumerable._addNFToken(_to, _tokenId);
  }

  /**
  *@dev Helper function that gets NFT count of owner. This is needed for overriding in enumerable
   * extension to remove double storage(gas optimization) of owner nft count.
   * @param _owner Address for whom to query the count.
   * @return Number of _owner NFTs.
   */
  function _getOwnerNFTCount(
    address _owner
  )
  internal
  override(NFToken, NFTokenEnumerable)
  view
  returns (uint256)
  {
    return NFTokenEnumerable._getOwnerNFTCount(_owner);
  }

}

// File: contracts\contracts\mocks\nf-token-metadata-enumerable-mock-nfts.sol


pragma solidity 0.6.2;


//import "hardhat/console.sol";


/**
 * @dev This is an example contract implementation of NFToken with enumerable and metadata
 * extensions.
 */
contract NFTS is
NFTokenEnumerable,
NFTokenMetadata,
AccessControl
{
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;
  //  mapping(uint256 => uint256) public typeTotalSupply;
  //  mapping(uint256 => uint256) public typeSupply;
  mapping(uint256 => string) public typeUri;
  mapping(uint256 => uint256) public tokenType;

  bytes32 public constant MINT_ROLE = keccak256("MINT_ROLE");

  string public baseURI;

  /**
   * @dev Contract constructor.
   * @param _name A descriptive name for a collection of NFTs.
   * @param _symbol An abbreviated name for NFTokens.
   */
  constructor(
    string memory _name,
    string memory _symbol
  ) public
  {
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    _setupRole(MINT_ROLE, _msgSender());

    nftName = _name;
    nftSymbol = _symbol;

    //etc: http://img.io/1.png
    typeUri[0] = "1.png";
    typeUri[1] = "2.png";
    typeUri[2] = "3.png";
    typeUri[3] = "4.png";
    typeUri[4] = "5.png";
    typeUri[5] = "6.png";
    typeUri[6] = "7.png";
    typeUri[7] = "8.png";
    typeUri[8] = "9.png";
  }

  function mint(
    address _to,
    uint256 _type
  )
  external
  {
    require(hasRole(MINT_ROLE, _msgSender()), "mint: need mint role");
    //    typeSupply[_type] = typeSupply[_type] + 1;
    //    require(typeSupply[_type] <= typeTotalSupply[_type], "mint: exceeds type maxSupply");
    uint _tokenId = _tokenIds.current();
    super._mint(_to, _tokenId);
    super._setTokenUri(_tokenId, typeUri[_type]);
    tokenType[_tokenId] = _type;
    _tokenIds.increment();
  }

  //disable standard transferFrom, safeTransferFrom
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes calldata _data
  )
  external
  override
  virtual
  {
    require(false, "safeTransferFrom: not good");
  }

  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
  external
  override
  virtual
  {
    require(false, "safeTransferFrom: not good");
  }

  function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
  external
  override
  virtual
  canTransfer(_tokenId)
  validNFToken(_tokenId)
  {
    require(false, "transferFrom: not good");
  }

  function safeTransferFrom0(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes calldata _data
  )
  external
  {
    _safeTransferFrom(_from, _to, _tokenId, _data);
  }

  /**
   * @dev Transfers the ownership of an NFT from one address to another address. This function can
   * be changed to payable.
   * @notice This works identically to the other function with an extra data parameter, except this
   * function just sets data to ""
   * @param _from The current owner of the NFT.
   * @param _to The new owner.
   * @param _tokenId The NFT to transfer.
   */
  function safeTransferFrom0(
    address _from,
    address _to,
    uint256 _tokenId
  )
  external
  {
    _safeTransferFrom(_from, _to, _tokenId, "");
  }

  /**
   * @dev Throws unless `msg.sender` is the current owner, an authorized operator, or the approved
   * address for this NFT. Throws if `_from` is not the current owner. Throws if `_to` is the zero
   * address. Throws if `_tokenId` is not a valid NFT. This function can be changed to payable.
   * @notice The caller is responsible to confirm that `_to` is capable of receiving NFTs or else
   * they may be permanently lost.
   * @param _from The current owner of the NFT.
   * @param _to The new owner.
   * @param _tokenId The NFT to transfer.
   */
  function transferFrom0(
    address _from,
    address _to,
    uint256 _tokenId
  )
  external
  canTransfer(_tokenId)
  validNFToken(_tokenId)
  {
    address tokenOwner = idToOwner[_tokenId];
    require(tokenOwner == _from, NOT_OWNER);
    require(_to != address(0), ZERO_ADDRESS);

    _transfer(_to, _tokenId);
  }


  /**
   * @dev Removes a NFT from owner.
   * @param _tokenId Which NFT we want to remove.
   */
  function burn(
    uint256 _tokenId
  )
  external
  {
    require(idToOwner[_tokenId] == _msgSender(), "burn: not owner");
    super._burn(_tokenId);
  }

  /**
   * @dev Mints a new NFT.
   * @notice This is an internal function which should be called from user-implemented external
   * mint function. Its purpose is to show and properly initialize data structures when using this
   * implementation.
   * @param _to The address that will own the minted NFT.
   * @param _tokenId of the NFT to be minted by the msg.sender.
   */
  function _mint(
    address _to,
    uint256 _tokenId
  )
  internal
  override(NFTokenMetadata, NFTokenEnumerable)
  virtual
  {
    NFTokenEnumerable._mint(_to, _tokenId);
  }

  /**
   * @dev Burns a NFT.
   * @notice This is an internal function which should be called from user-implemented external
   * burn function. Its purpose is to show and properly initialize data structures when using this
   * implementation. Also, note that this burn implementation allows the minter to re-mint a burned
   * NFT.
   * @param _tokenId ID of the NFT to be burned.
   */
  function _burn(
    uint256 _tokenId
  )
  internal
  override(NFTokenMetadata, NFTokenEnumerable)
  virtual
  {
    NFTokenEnumerable._burn(_tokenId);
    if (bytes(idToUri[_tokenId]).length != 0)
    {
      delete idToUri[_tokenId];
    }
  }

  /**
   * @dev Removes a NFT from an address.
   * @notice Use and override this function with caution. Wrong usage can have serious consequences.
   * @param _from Address from wich we want to remove the NFT.
   * @param _tokenId Which NFT we want to remove.
   */
  function _removeNFToken(
    address _from,
    uint256 _tokenId
  )
  internal
  override(NFToken, NFTokenEnumerable)
  {
    NFTokenEnumerable._removeNFToken(_from, _tokenId);
  }

  /**
   * @dev Assigns a new NFT to an address.
   * @notice Use and override this function with caution. Wrong usage can have serious consequences.
   * @param _to Address to wich we want to add the NFT.
   * @param _tokenId Which NFT we want to add.
   */
  function _addNFToken(
    address _to,
    uint256 _tokenId
  )
  internal
  override(NFToken, NFTokenEnumerable)
  {
    NFTokenEnumerable._addNFToken(_to, _tokenId);
  }

  /**
  *@dev Helper function that gets NFT count of owner. This is needed for overriding in enumerable
   * extension to remove double storage(gas optimization) of owner nft count.
   * @param _owner Address for whom to query the count.
   * @return Number of _owner NFTs.
   */
  function _getOwnerNFTCount(
    address _owner
  )
  internal
  override(NFToken, NFTokenEnumerable)
  view
  returns (uint256)
  {
    return NFTokenEnumerable._getOwnerNFTCount(_owner);
  }

  function tokenURI(
    uint256 _tokenId
  )
  external
  override
  view
  validNFToken(_tokenId)
  returns (string memory)
  {
    return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _tokenURI(_tokenId))) : _tokenURI(_tokenId);
  }

  function setBaseURI(string memory _uri) public {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "need admin role");
    baseURI = _uri;
  }

}

// File: contracts\contracts\mocks\nf-token-metadata-enumerable-mock-nft300.sol


pragma solidity 0.6.2;


//import "hardhat/console.sol";


/**
 * @dev This is an example contract implementation of NFToken with enumerable and metadata
 * extensions.
 */
contract NFT300 is
NFTokenEnumerable,
NFTokenMetadata,
AccessControl
{
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;
//  mapping(uint256 => uint256) public typeTotalSupply;
//  mapping(uint256 => uint256) public typeSupply;
  mapping(uint256 => string) public typeUri;
  mapping(uint256 => uint256) public tokenType;

  bytes32 public constant MINT_ROLE = keccak256("MINT_ROLE");
  bytes32 public constant TRANSFER_ROLE = keccak256("TRANSFER_ROLE");

  string public baseURI;

  /**
   * @dev Contract constructor.
   * @param _name A descriptive name for a collection of NFTs.
   * @param _symbol An abbreviated name for NFTokens.
   */
  constructor(
    string memory _name,
    string memory _symbol
  ) public
  {
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    _setupRole(MINT_ROLE, _msgSender());
    _setupRole(TRANSFER_ROLE, _msgSender());

    nftName = _name;
    nftSymbol = _symbol;

    typeUri[0] =  "nft_001.png";
    typeUri[1] =  "nft_002.png";
    typeUri[2] =  "nft_003.png";
    typeUri[3] =  "nft_004.png";
    typeUri[4] =  "nft_005.png";
    typeUri[5] =  "nft_006.png";
    typeUri[6] =  "nft_007.png";
    typeUri[7] =  "nft_008.png";
    typeUri[8] =  "nft_009.png";
    typeUri[9] =  "nft_010.png";
    typeUri[10] = "nft_011.png";
    typeUri[11] = "nft_012.png";
    typeUri[12] = "nft_013.png";
    typeUri[13] = "nft_014.png";
    typeUri[14] = "nft_015.png";
    typeUri[15] = "nft_016.png";
    typeUri[16] = "nft_017.png";
    typeUri[17] = "nft_018.png";
    typeUri[18] = "nft_019.png";
    typeUri[19] = "nft_020.png";
    typeUri[20] = "nft_021.png";
    typeUri[21] = "nft_022.png";
    typeUri[22] = "nft_023.png";
    typeUri[23] = "nft_024.png";
    typeUri[24] = "nft_025.png";
    typeUri[25] = "nft_026.png";
    typeUri[26] = "nft_027.png";
    typeUri[27] = "nft_028.png";
    typeUri[28] = "nft_029.png";
    typeUri[29] = "nft_030.png";
    typeUri[30] = "nft_031.png";
    typeUri[31] = "nft_032.png";
    typeUri[32] = "nft_033.png";
    typeUri[33] = "nft_034.png";
    typeUri[34] = "nft_035.png";
    typeUri[35] = "nft_036.png";
    typeUri[36] = "nft_037.png";
    typeUri[37] = "nft_038.png";
    typeUri[38] = "nft_039.png";
    typeUri[39] = "nft_040.png";
    typeUri[40] = "nft_041.png";
    typeUri[41] = "nft_042.png";
    typeUri[42] = "nft_043.png";
    typeUri[43] = "nft_044.png";
    typeUri[44] = "nft_045.png";
    typeUri[45] = "nft_046.png";
    typeUri[46] = "nft_047.png";
    typeUri[47] = "nft_048.png";
    typeUri[48] = "nft_049.png";
    typeUri[49] = "nft_050.png";
    typeUri[50] = "nft_051.png";
    typeUri[51] = "nft_052.png";
    typeUri[52] = "nft_053.png";
    typeUri[53] = "nft_054.png";
    typeUri[54] = "nft_055.png";
    typeUri[55] = "nft_056.png";
    typeUri[56] = "nft_057.png";
    typeUri[57] = "nft_058.png";
    typeUri[58] = "nft_059.png";
    typeUri[59] = "nft_060.png";
    typeUri[60] = "nft_061.png";
    typeUri[61] = "nft_062.png";
    typeUri[62] = "nft_063.png";
    typeUri[63] = "nft_064.png";
    typeUri[64] = "nft_065.png";
    typeUri[65] = "nft_066.png";
    typeUri[66] = "nft_067.png";
    typeUri[67] = "nft_068.png";
    typeUri[68] = "nft_069.png";
    typeUri[69] = "nft_070.png";
    typeUri[70] = "nft_071.png";
    typeUri[71] = "nft_072.png";
    typeUri[72] = "nft_073.png";
    typeUri[73] = "nft_074.png";
    typeUri[74] = "nft_075.png";
    typeUri[75] = "nft_076.png";
    typeUri[76] = "nft_077.png";
    typeUri[77] = "nft_078.png";
    typeUri[78] = "nft_079.png";
    typeUri[79] = "nft_080.png";
    typeUri[80] = "nft_081.png";
    typeUri[81] = "nft_082.png";
    typeUri[82] = "nft_083.png";
    typeUri[83] = "nft_084.png";
    typeUri[84] = "nft_085.png";
    typeUri[85] = "nft_086.png";
    typeUri[86] = "nft_087.png";
    typeUri[87] = "nft_088.png";
    typeUri[88] = "nft_089.png";
    typeUri[89] = "nft_090.png";
    typeUri[90] = "nft_091.png";
    typeUri[91] = "nft_092.png";
    typeUri[92] = "nft_093.png";
    typeUri[93] = "nft_094.png";
    typeUri[94] = "nft_095.png";
    typeUri[95] = "nft_096.png";
    typeUri[96] = "nft_097.png";
    typeUri[97] = "nft_098.png";
    typeUri[98] = "nft_099.png";
    typeUri[99] = "nft_100.png";
    typeUri[100] = "nft_101.png";
    typeUri[101] = "nft_102.png";
    typeUri[102] = "nft_103.png";
    typeUri[103] = "nft_104.png";
    typeUri[104] = "nft_105.png";
    typeUri[105] = "nft_106.png";
    typeUri[106] = "nft_107.png";
    typeUri[107] = "nft_108.png";
    typeUri[108] = "nft_109.png";
    typeUri[109] = "nft_110.png";
    typeUri[110] = "nft_111.png";
    typeUri[111] = "nft_112.png";
    typeUri[112] = "nft_113.png";
    typeUri[113] = "nft_114.png";
    typeUri[114] = "nft_115.png";
    typeUri[115] = "nft_116.png";
    typeUri[116] = "nft_117.png";
    typeUri[117] = "nft_118.png";
    typeUri[118] = "nft_119.png";
    typeUri[119] = "nft_120.png";
    typeUri[120] = "nft_121.png";
    typeUri[121] = "nft_122.png";
    typeUri[122] = "nft_123.png";
    typeUri[123] = "nft_124.png";
    typeUri[124] = "nft_125.png";
    typeUri[125] = "nft_126.png";
    typeUri[126] = "nft_127.png";
    typeUri[127] = "nft_128.png";
    typeUri[128] = "nft_129.png";
    typeUri[129] = "nft_130.png";
    typeUri[130] = "nft_131.png";
    typeUri[131] = "nft_132.png";
    typeUri[132] = "nft_133.png";
    typeUri[133] = "nft_134.png";
    typeUri[134] = "nft_135.png";
    typeUri[135] = "nft_136.png";
    typeUri[136] = "nft_137.png";
    typeUri[137] = "nft_138.png";
    typeUri[138] = "nft_139.png";
    typeUri[139] = "nft_140.png";
    typeUri[140] = "nft_141.png";
    typeUri[141] = "nft_142.png";
    typeUri[142] = "nft_143.png";
    typeUri[143] = "nft_144.png";
    typeUri[144] = "nft_145.png";
    typeUri[145] = "nft_146.png";
    typeUri[146] = "nft_147.png";
    typeUri[147] = "nft_148.png";
    typeUri[148] = "nft_149.png";
    typeUri[149] = "nft_150.png";
    typeUri[150] = "nft_151.png";
    typeUri[151] = "nft_152.png";
    typeUri[152] = "nft_153.png";
    typeUri[153] = "nft_154.png";
    typeUri[154] = "nft_155.png";
    typeUri[155] = "nft_156.png";
    typeUri[156] = "nft_157.png";
    typeUri[157] = "nft_158.png";
    typeUri[158] = "nft_159.png";
    typeUri[159] = "nft_160.png";
    typeUri[160] = "nft_161.png";
    typeUri[161] = "nft_162.png";
    typeUri[162] = "nft_163.png";
    typeUri[163] = "nft_164.png";
    typeUri[164] = "nft_165.png";
    typeUri[165] = "nft_166.png";
    typeUri[166] = "nft_167.png";
    typeUri[167] = "nft_168.png";
    typeUri[168] = "nft_169.png";
    typeUri[169] = "nft_170.png";
    typeUri[170] = "nft_171.png";
    typeUri[171] = "nft_172.png";
    typeUri[172] = "nft_173.png";
    typeUri[173] = "nft_174.png";
    typeUri[174] = "nft_175.png";
    typeUri[175] = "nft_176.png";
    typeUri[176] = "nft_177.png";
    typeUri[177] = "nft_178.png";
    typeUri[178] = "nft_179.png";
    typeUri[179] = "nft_180.png";
    typeUri[180] = "nft_181.png";
    typeUri[181] = "nft_182.png";
    typeUri[182] = "nft_183.png";
    typeUri[183] = "nft_184.png";
    typeUri[184] = "nft_185.png";
    typeUri[185] = "nft_186.png";
    typeUri[186] = "nft_187.png";
    typeUri[187] = "nft_188.png";
    typeUri[188] = "nft_189.png";
    typeUri[189] = "nft_190.png";
    typeUri[190] = "nft_191.png";
    typeUri[191] = "nft_192.png";
    typeUri[192] = "nft_193.png";
    typeUri[193] = "nft_194.png";
    typeUri[194] = "nft_195.png";
    typeUri[195] = "nft_196.png";
    typeUri[196] = "nft_197.png";
    typeUri[197] = "nft_198.png";
    typeUri[198] = "nft_199.png";
    typeUri[199] = "nft_200.png";
    typeUri[200] = "nft_201.png";
    typeUri[201] = "nft_202.png";
    typeUri[202] = "nft_203.png";
    typeUri[203] = "nft_204.png";
    typeUri[204] = "nft_205.png";
    typeUri[205] = "nft_206.png";
    typeUri[206] = "nft_207.png";
    typeUri[207] = "nft_208.png";
    typeUri[208] = "nft_209.png";
    typeUri[209] = "nft_210.png";
    typeUri[210] = "nft_211.png";
    typeUri[211] = "nft_212.png";
    typeUri[212] = "nft_213.png";
    typeUri[213] = "nft_214.png";
    typeUri[214] = "nft_215.png";
    typeUri[215] = "nft_216.png";
    typeUri[216] = "nft_217.png";
    typeUri[217] = "nft_218.png";
    typeUri[218] = "nft_219.png";
    typeUri[219] = "nft_220.png";
    typeUri[220] = "nft_221.png";
    typeUri[221] = "nft_222.png";
    typeUri[222] = "nft_223.png";
    typeUri[223] = "nft_224.png";
    typeUri[224] = "nft_225.png";
    typeUri[225] = "nft_226.png";
    typeUri[226] = "nft_227.png";
    typeUri[227] = "nft_228.png";
    typeUri[228] = "nft_229.png";
    typeUri[229] = "nft_230.png";
    typeUri[230] = "nft_231.png";
    typeUri[231] = "nft_232.png";
    typeUri[232] = "nft_233.png";
    typeUri[233] = "nft_234.png";
    typeUri[234] = "nft_235.png";
    typeUri[235] = "nft_236.png";
    typeUri[236] = "nft_237.png";
    typeUri[237] = "nft_238.png";
    typeUri[238] = "nft_239.png";
    typeUri[239] = "nft_240.png";
    typeUri[240] = "nft_241.png";
    typeUri[241] = "nft_242.png";
    typeUri[242] = "nft_243.png";
    typeUri[243] = "nft_244.png";
    typeUri[244] = "nft_245.png";
    typeUri[245] = "nft_246.png";
    typeUri[246] = "nft_247.png";
    typeUri[247] = "nft_248.png";
    typeUri[248] = "nft_249.png";
    typeUri[249] = "nft_250.png";
    typeUri[250] = "nft_251.png";
    typeUri[251] = "nft_252.png";
    typeUri[252] = "nft_253.png";
    typeUri[253] = "nft_254.png";
    typeUri[254] = "nft_255.png";
    typeUri[255] = "nft_256.png";
    typeUri[256] = "nft_257.png";
    typeUri[257] = "nft_258.png";
    typeUri[258] = "nft_259.png";
    typeUri[259] = "nft_260.png";
    typeUri[260] = "nft_261.png";
    typeUri[261] = "nft_262.png";
    typeUri[262] = "nft_263.png";
    typeUri[263] = "nft_264.png";
    typeUri[264] = "nft_265.png";
    typeUri[265] = "nft_266.png";
    typeUri[266] = "nft_267.png";
    typeUri[267] = "nft_268.png";
    typeUri[268] = "nft_269.png";
    typeUri[269] = "nft_270.png";
    typeUri[270] = "nft_271.png";
    typeUri[271] = "nft_272.png";
    typeUri[272] = "nft_273.png";
    typeUri[273] = "nft_274.png";
    typeUri[274] = "nft_275.png";
    typeUri[275] = "nft_276.png";
    typeUri[276] = "nft_277.png";
    typeUri[277] = "nft_278.png";
    typeUri[278] = "nft_279.png";
    typeUri[279] = "nft_280.png";
    typeUri[280] = "nft_281.png";
    typeUri[281] = "nft_282.png";
    typeUri[282] = "nft_283.png";
    typeUri[283] = "nft_284.png";
    typeUri[284] = "nft_285.png";
    typeUri[285] = "nft_286.png";
    typeUri[286] = "nft_287.png";
    typeUri[287] = "nft_288.png";
    typeUri[288] = "nft_289.png";
    typeUri[289] = "nft_290.png";
    typeUri[290] = "nft_291.png";
    typeUri[291] = "nft_292.png";
    typeUri[292] = "nft_293.png";
    typeUri[293] = "nft_294.png";
    typeUri[294] = "nft_295.png";
    typeUri[295] = "nft_296.png";
    typeUri[296] = "nft_297.png";
    typeUri[297] = "nft_298.png";
    typeUri[298] = "nft_299.png";
    typeUri[299] = "nft_300.png";

  }

  function mint(
    address _to,
    uint256 _type
  )
  external
  {
    require(hasRole(MINT_ROLE, _msgSender()), "mint: need mint role");
//    typeSupply[_type] = typeSupply[_type] + 1;
//    require(typeSupply[_type] <= typeTotalSupply[_type], "mint: exceeds type maxSupply");
    uint _tokenId = _tokenIds.current();
    super._mint(_to, _tokenId);
    super._setTokenUri(_tokenId, typeUri[_type]);
    tokenType[_tokenId] = _type;
    _tokenIds.increment();
  }

  /**
   * @dev Removes a NFT from owner.
   * @param _tokenId Which NFT we want to remove.
   */
  function burn(
    uint256 _tokenId
  )
  external
  {
    require(idToOwner[_tokenId] == _msgSender(), "burn: not owner");
    super._burn(_tokenId);
  }

  /**
   * @dev Mints a new NFT.
   * @notice This is an internal function which should be called from user-implemented external
   * mint function. Its purpose is to show and properly initialize data structures when using this
   * implementation.
   * @param _to The address that will own the minted NFT.
   * @param _tokenId of the NFT to be minted by the msg.sender.
   */
  function _mint(
    address _to,
    uint256 _tokenId
  )
  internal
  override(NFTokenMetadata, NFTokenEnumerable)
  virtual
  {
    NFTokenEnumerable._mint(_to, _tokenId);
  }

  /**
   * @dev Burns a NFT.
   * @notice This is an internal function which should be called from user-implemented external
   * burn function. Its purpose is to show and properly initialize data structures when using this
   * implementation. Also, note that this burn implementation allows the minter to re-mint a burned
   * NFT.
   * @param _tokenId ID of the NFT to be burned.
   */
  function _burn(
    uint256 _tokenId
  )
  internal
  override(NFTokenMetadata, NFTokenEnumerable)
  virtual
  {
    NFTokenEnumerable._burn(_tokenId);
    if (bytes(idToUri[_tokenId]).length != 0)
    {
      delete idToUri[_tokenId];
    }
  }

  /**
   * @dev Removes a NFT from an address.
   * @notice Use and override this function with caution. Wrong usage can have serious consequences.
   * @param _from Address from wich we want to remove the NFT.
   * @param _tokenId Which NFT we want to remove.
   */
  function _removeNFToken(
    address _from,
    uint256 _tokenId
  )
  internal
  override(NFToken, NFTokenEnumerable)
  {
    NFTokenEnumerable._removeNFToken(_from, _tokenId);
  }

  /**
   * @dev Assigns a new NFT to an address.
   * @notice Use and override this function with caution. Wrong usage can have serious consequences.
   * @param _to Address to wich we want to add the NFT.
   * @param _tokenId Which NFT we want to add.
   */
  function _addNFToken(
    address _to,
    uint256 _tokenId
  )
  internal
  override(NFToken, NFTokenEnumerable)
  {
    NFTokenEnumerable._addNFToken(_to, _tokenId);
  }

  /**
  *@dev Helper function that gets NFT count of owner. This is needed for overriding in enumerable
   * extension to remove double storage(gas optimization) of owner nft count.
   * @param _owner Address for whom to query the count.
   * @return Number of _owner NFTs.
   */
  function _getOwnerNFTCount(
    address _owner
  )
  internal
  override(NFToken, NFTokenEnumerable)
  view
  returns (uint256)
  {
    return NFTokenEnumerable._getOwnerNFTCount(_owner);
  }

  /**
   * @dev Transfers the ownership of an NFT from one address to another address. This function can
   * be changed to payable.
   * @notice Throws unless `msg.sender` is the current owner, an authorized operator, or the
   * approved address for this NFT. Throws if `_from` is not the current owner. Throws if `_to` is
   * the zero address. Throws if `_tokenId` is not a valid NFT. When transfer is complete, this
   * function checks if `_to` is a smart contract (code size > 0). If so, it calls
   * `onERC721Received` on `_to` and throws if the return value is not
   * `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`.
   * @param _from The current owner of the NFT.
   * @param _to The new owner.
   * @param _tokenId The NFT to transfer.
   * @param _data Additional data with no specified format, sent in call to `_to`.
   */
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes calldata _data
  )
  external
  override
  {
    require(hasRole(TRANSFER_ROLE, _msgSender()), "mint: need transfer role");
    super._safeTransferFrom(_from, _to, _tokenId, _data);
  }

  /**
   * @dev Transfers the ownership of an NFT from one address to another address. This function can
   * be changed to payable.
   * @notice This works identically to the other function with an extra data parameter, except this
   * function just sets data to ""
   * @param _from The current owner of the NFT.
   * @param _to The new owner.
   * @param _tokenId The NFT to transfer.
   */
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
  external
  override
  {
    require(hasRole(TRANSFER_ROLE, _msgSender()), "mint: need transfer role");
    super._safeTransferFrom(_from, _to, _tokenId, "");
  }

  /**
   * @dev Throws unless `msg.sender` is the current owner, an authorized operator, or the approved
   * address for this NFT. Throws if `_from` is not the current owner. Throws if `_to` is the zero
   * address. Throws if `_tokenId` is not a valid NFT. This function can be changed to payable.
   * @notice The caller is responsible to confirm that `_to` is capable of receiving NFTs or else
   * they may be permanently lost.
   * @param _from The current owner of the NFT.
   * @param _to The new owner.
   * @param _tokenId The NFT to transfer.
   */
  function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
  external
  override
  canTransfer(_tokenId)
  validNFToken(_tokenId)
  {
    address tokenOwner = idToOwner[_tokenId];
    require(tokenOwner == _from, NOT_OWNER);
    require(_to != address(0), ZERO_ADDRESS);
    require(hasRole(TRANSFER_ROLE, _msgSender()), "mint: need transfer role");

    _transfer(_to, _tokenId);
  }

  function tokenURI(
    uint256 _tokenId
  )
  external
  override
  view
  validNFToken(_tokenId)
  returns (string memory)
  {
    return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _tokenURI(_tokenId))) : _tokenURI(_tokenId);
  }

  function setBaseURI(string memory _uri) public {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "need admin role");
    baseURI = _uri;
  }

}

// File: contracts\contracts\tokens\IMH.sol



pragma solidity ^0.6.0;

interface IMH is IERC20{
    function mint(address account, uint256 amount) external;
    function burn(uint256 amount) external;
}

// File: contracts\contracts\mocks\buyNFT.sol


pragma solidity ^0.6.0;


//import "hardhat/console.sol";





/**
 * @dev This is an example contract implementation of NFToken buy.
 */
contract Main is
Ownable
{
  using SafeMath for uint256;
  using SafeERC20 for ERC20;
  IMH public mh0;
  IMH public mh1;
  IMH public mh2;
  NFT public nftx;
  NFTS public nfts;
  NFT300 public nft300;

  address public usdt;
  address public three;
  // hmc price
  uint256 public price;
  uint256 public usdtPrice;
  uint256 public threePrice;
  // open blind box
  uint256 public fee1 = 10 ether;
  // compound nft300
  uint256 public fee2 = 10 ether;
  // transfer nfts
  uint256 public fee3 = 10 ether;
  uint256 public constant times = 10 ** 12;

  mapping(uint256 => uint256[]) public openCfgMap;
  uint256[] public nft300Cfg;

  mapping(address => uint256) public openMap;
  mapping(address => uint256) public rewardMap;
  mapping(address => uint256) public threeRewardMap;

  event Withdraw(address indexed user, uint256 amount);
  event Buy(address indexed user, uint256 amount);
  event TransferNfts(address indexed user, uint256 _tokenIdOld, uint256 _tokenIdNew);
  event TransferNFT(address indexed user, uint256 _tokenId1, uint256 _tokenId2, uint256 _tokenId3, address to);
  event TransferNFTX(address indexed user, uint256 _fromTokenId, uint256 _toTokenId, uint256 _flag);
  event Claim(address indexed user, uint256 amount);
  event OpenBox(address indexed user, uint256 indexed flag, uint256 amountType, uint256 tokenId);
  event Compound(address indexed user, uint256 indexed _type, uint256 tokenId);

  constructor(
    IMH _mh0,
    IMH _mh1,
    IMH _mh2,
    NFT _nftx,
    NFTS _nfts,
    NFT300 _nft300,

    address _usdt,
    address _three,

    uint256 _usdtPrice,
    uint256 _threePrice,
    uint256 _hmcPrice,

    uint256 _fee1,
    uint256 _fee2,
    uint256 _fee3
  ) public
  {
    mh0 = _mh0;
    mh1 = _mh1;
    mh2 = _mh2;
    nftx = _nftx;
    nfts = _nfts;
    nft300 = _nft300;

    usdt = _usdt;
    three = _three;

    usdtPrice = _usdtPrice;
    threePrice = _threePrice;
    price = _hmcPrice;

    fee1 = _fee1;
    fee2 = _fee2;
    fee3 = _fee3;
  }

  function setPrice(uint _hmcPrice, uint _usdtPrice, uint _threePrice) onlyOwner external {
    price = _hmcPrice;
    usdtPrice = _usdtPrice;
    threePrice = _threePrice;
  }

  function setFee(uint _fee1, uint _fee2, uint _fee3) onlyOwner external {
    fee1 = _fee1;
    fee2 = _fee2;
    fee3 = _fee3;
  }

  function setThree(address _three) onlyOwner external {
    three = _three;
  }

  function setNft300Cfg(uint p1, uint p2, uint p3) onlyOwner external {
    if (nft300Cfg.length > 0) {
      for (uint i = 0; i < nft300Cfg.length; i++) {
        nft300Cfg.pop();
      }
    }
    nft300Cfg.push(p1);
    nft300Cfg.push(p2);
    nft300Cfg.push(p3);
  }

  function withdraw(uint256 _amount, address _token) onlyOwner external {
    uint256 lpSupply = ERC20(_token).balanceOf(address(this));
    require(lpSupply >= _amount, "withdraw: not good");
    ERC20(_token).transfer(address(msg.sender), _amount);
    emit Withdraw(msg.sender, _amount);
  }

  function withdrawFee() onlyOwner external {
    uint256 amount = address(this).balance;
    msg.sender.transfer(amount);
  }

  function buyMH1(uint256 _amount, uint256 _coin) payable public {
    require(_coin == 0 || _coin == 1 || _coin == 2, "buy: _coin not good");
    if (_coin == 0) {
      require(msg.value == _amount.mul(price), "buy: balance not sufficient");
    } else {
      uint256 _price = usdtPrice;
      address _token = usdt;
      if (_coin == 2) {
        _price = threePrice;
        _token = three;
      }
      require(ERC20(_token).balanceOf(msg.sender) >= _amount.mul(_price), "buy: balance not sufficient");
      ERC20(_token).safeTransferFrom(
        address(msg.sender),
        address(this),
        _amount.mul(_price)
      );

    }
    mh1.mint(address(msg.sender), _amount * 1 ether);
    emit Buy(address(msg.sender), _amount * 1 ether);
  }

  function setOpenBox(uint _flag, uint256[] memory _amounts, uint256[] memory _ps) public onlyOwner {
    require(_flag == 0 || _flag == 1 || _flag == 2, "_flag not good");
    require(_amounts.length == _ps.length && _ps.length > 0, "len check not good");
    uint len = openCfgMap[_flag].length;
    if (len > 0) {
      for (uint i = 0; i < len; i++) {
        openCfgMap[_flag].pop();
      }
    }
    for (uint i = 0; i < _amounts.length; i++) {
      openCfgMap[_flag].push(_amounts[i]);
      openCfgMap[_flag].push(_ps[i]);
    }

  }

  function openBox() public payable {
    IERC20(three).transferFrom(address(msg.sender), address(this), fee1);
    uint256 _flag = 10;
    IMH _mh = mh0;
    if (IERC20(mh0).balanceOf(msg.sender) >= 1 ether) {
      _flag = 0;
      _mh = mh0;
    } else if (IERC20(mh1).balanceOf(msg.sender) >= 1 ether) {
      _flag = 1;
      _mh = mh1;
    } else if (IERC20(mh2).balanceOf(msg.sender) >= 1 ether) {
      _flag = 2;
      _mh = mh2;
    }
    require(_flag != 10, "openBox: balance not good");
    _mh.transferFrom(msg.sender, address(this), 1 ether);
    uint256 p = uint256(keccak256(abi.encodePacked(msg.sender, block.timestamp, block.number, _flag))) % 100000;
    uint256[] memory cfg = openCfgMap[_flag];
    require(cfg.length == 40, "openBox: open not set");
    if (p < cfg[1]) {
      threeRewardMap[msg.sender] = threeRewardMap[msg.sender].add(cfg[0]);
      emit OpenBox(msg.sender, 0, cfg[0], 0);
    } else if (p >= cfg[1] && p < cfg[3]) {
      threeRewardMap[msg.sender] = threeRewardMap[msg.sender].add(cfg[2]);
      emit OpenBox(msg.sender, 0, cfg[2], 0);
    } else if (p >= cfg[3] && p < cfg[5]) {
      threeRewardMap[msg.sender] = threeRewardMap[msg.sender].add(cfg[4]);
      emit OpenBox(msg.sender, 0, cfg[4], 0);
    } else if (p >= cfg[5] && p < cfg[7]) {
      threeRewardMap[msg.sender] = threeRewardMap[msg.sender].add(cfg[6]);
      emit OpenBox(msg.sender, 0, cfg[6], 0);
    } else if (p >= cfg[7] && p < cfg[9]) {
      threeRewardMap[msg.sender] = threeRewardMap[msg.sender].add(cfg[8]);
      emit OpenBox(msg.sender, 0, cfg[6], 0);
    } else if (p >= cfg[9] && p < cfg[11]) {
      threeRewardMap[msg.sender] = threeRewardMap[msg.sender].add(cfg[10]);
      emit OpenBox(msg.sender, 0, cfg[6], 0);
    } else if (p >= cfg[11] && p < cfg[13]) {
      threeRewardMap[msg.sender] = threeRewardMap[msg.sender].add(cfg[12]);
      emit OpenBox(msg.sender, 0, cfg[6], 0);
    } else if (p >= cfg[13] && p < cfg[15]) {
      threeRewardMap[msg.sender] = threeRewardMap[msg.sender].add(cfg[14]);
      emit OpenBox(msg.sender, 0, cfg[6], 0);
    } else if (p >= cfg[15] && p < cfg[17]) {
      threeRewardMap[msg.sender] = threeRewardMap[msg.sender].add(cfg[16]);
      emit OpenBox(msg.sender, 0, cfg[6], 0);
    } else if (p >= cfg[17] && p < cfg[19]) {
      threeRewardMap[msg.sender] = threeRewardMap[msg.sender].add(cfg[18]);
      emit OpenBox(msg.sender, 0, cfg[6], 0);
    } else if (p >= cfg[19] && p < cfg[21]) {
      nftx.mint(msg.sender);
      emit OpenBox(msg.sender, 1, 0, nftx.tokenOfOwnerByIndex(msg.sender, nftx.balanceOf(msg.sender) - 1));
    } else if (p >= cfg[21] && p < cfg[23]) {
      nfts.mint(address(msg.sender), 0);
      emit OpenBox(msg.sender, 2, 0, nfts.tokenOfOwnerByIndex(msg.sender, nfts.balanceOf(msg.sender) - 1));
    } else if (p >= cfg[23] && p < cfg[25]) {
      nfts.mint(address(msg.sender), 1);
      emit OpenBox(msg.sender, 2, 1, nfts.tokenOfOwnerByIndex(msg.sender, nfts.balanceOf(msg.sender) - 1));
    } else if (p >= cfg[25] && p < cfg[27]) {
      nfts.mint(address(msg.sender), 2);
      emit OpenBox(msg.sender, 2, 2, nfts.tokenOfOwnerByIndex(msg.sender, nfts.balanceOf(msg.sender) - 1));
    } else if (p >= cfg[27] && p < cfg[29]) {
      nfts.mint(address(msg.sender), 3);
      emit OpenBox(msg.sender, 2, 3, nfts.tokenOfOwnerByIndex(msg.sender, nfts.balanceOf(msg.sender) - 1));
    } else if (p >= cfg[29] && p < cfg[31]) {
      nfts.mint(address(msg.sender), 4);
      emit OpenBox(msg.sender, 2, 4, nfts.tokenOfOwnerByIndex(msg.sender, nfts.balanceOf(msg.sender) - 1));
    } else if (p >= cfg[31] && p < cfg[33]) {
      nfts.mint(address(msg.sender), 5);
      emit OpenBox(msg.sender, 2, 5, nfts.tokenOfOwnerByIndex(msg.sender, nfts.balanceOf(msg.sender) - 1));
    } else if (p >= cfg[33] && p < cfg[35]) {
      nfts.mint(address(msg.sender), 6);
      emit OpenBox(msg.sender, 2, 6, nfts.tokenOfOwnerByIndex(msg.sender, nfts.balanceOf(msg.sender) - 1));
    } else if (p >= cfg[35] && p < cfg[37]) {
      nfts.mint(address(msg.sender), 7);
      emit OpenBox(msg.sender, 2, 7, nfts.tokenOfOwnerByIndex(msg.sender, nfts.balanceOf(msg.sender) - 1));
    } else if (p >= cfg[38]) {
      nfts.mint(address(msg.sender), 8);
      emit OpenBox(msg.sender, 2, 8, nfts.tokenOfOwnerByIndex(msg.sender, nfts.balanceOf(msg.sender) - 1));
    }
    openMap[msg.sender] = openMap[msg.sender] + 1;
    if (openMap[msg.sender].div(6) > rewardMap[msg.sender]) {
      uint256 reward = openMap[msg.sender].div(6).sub(rewardMap[msg.sender]);
      rewardMap[msg.sender] = rewardMap[msg.sender].add(reward);
      for (uint i = 0; i < reward; i++) {
        mh0.mint(msg.sender, 1 ether);
        emit OpenBox(msg.sender, 3, 0, 1 ether);
      }
    }
  }

  function claim() external {
    uint256 balance = threeRewardMap[msg.sender];
    require(balance > 0, "claim: balance not good");
    threeRewardMap[msg.sender] = 0;
    IERC20(three).transfer(msg.sender, balance);
    emit Claim(msg.sender, balance);
  }

  function compound() payable public {
    //require(msg.value == fee2, "compound: fee not good");
    IERC20(three).transferFrom(address(msg.sender), address(this), fee2);
    uint256 bal = nfts.balanceOf(msg.sender);
    require(bal >= 9, "compound: balance not good");
    bool[9] memory typeArr = [false, false, false, false, false, false, false, false, false];
    uint256[9] memory idArr = [uint(0), 0, 0, 0, 0, 0, 0, 0, 0];
    bool allBurned = false;
    for (uint256 i = bal - 1; i >= 1; i--) {
      if (typeArr[0] && typeArr[1] && typeArr[2] && typeArr[3] && typeArr[4] && typeArr[5] && typeArr[6] && typeArr[7] && typeArr[8]) {
        allBurned = true;
        break;
      } else {
        uint256 tokenId = nfts.tokenOfOwnerByIndex(msg.sender, i);
        uint256 _type = nfts.tokenType(tokenId);
        if (typeArr[_type] == false) {
          typeArr[_type] = true;
          idArr[_type] = tokenId;
          nfts.transferFrom0(msg.sender, address(this), tokenId);
          nfts.burn(tokenId);
        }
      }
    }
    if (allBurned) {
      uint256 _p = uint256(keccak256(abi.encodePacked(msg.sender, block.timestamp, idArr[1], idArr[3], idArr[5], idArr[7]))) % 100;
      uint256 _type = uint256(keccak256(abi.encodePacked(msg.sender, block.timestamp, idArr[2], idArr[4], idArr[6], idArr[7]))) % 100;
      if (_p >= 0 && _p < nft300Cfg[0]) {
        nft300.mint(msg.sender, _type);
        emit Compound(msg.sender, _type, nft300.tokenOfOwnerByIndex(msg.sender, nft300.balanceOf(msg.sender) - 1));
      } else if (_p >= nft300Cfg[0] && _p < nft300Cfg[1]) {
        nft300.mint(msg.sender, _type + 100);
        emit Compound(msg.sender, _type + 100, nft300.tokenOfOwnerByIndex(msg.sender, nft300.balanceOf(msg.sender) - 1));
      } else {
        nft300.mint(msg.sender, _type + 200);
        emit Compound(msg.sender, _type + 200, nft300.tokenOfOwnerByIndex(msg.sender, nft300.balanceOf(msg.sender) - 1));
      }

    }
  }

  //transfer from type one to type another
  function transferNfts(uint256 _tokenId) payable public {
    IERC20(three).transferFrom(address(msg.sender), address(this), fee3);
    require(nfts.ownerOf(_tokenId) == msg.sender);
    nfts.transferFrom0(address(msg.sender), address(this), _tokenId);
    nfts.burn(_tokenId);
    uint256 _type = uint256(keccak256(abi.encodePacked(msg.sender, block.timestamp, block.number, _tokenId))) % 9;
    nfts.mint(address(msg.sender), _type);
    emit TransferNfts(msg.sender, _tokenId, nfts.tokenOfOwnerByIndex(msg.sender, nfts.balanceOf(msg.sender) - 1));
  }

  function transferNFT(uint256 _tokenId1, uint256 _tokenId2, uint256 _tokenId3, address _to) external {
    require(nfts.tokenType(_tokenId1) == nfts.tokenType(_tokenId2) && nfts.tokenType(_tokenId1) == nfts.tokenType(_tokenId3), "transferNFT: type not equal");
    nfts.transferFrom0(msg.sender, address(this), _tokenId1);
    nfts.transferFrom0(msg.sender, address(this), _tokenId2);
    nfts.burn(_tokenId1);
    nfts.burn(_tokenId2);
    nfts.transferFrom0(msg.sender, _to, _tokenId3);
    emit TransferNFT(msg.sender, _tokenId1, _tokenId2, _tokenId3, _to);
  }

  function transferNFTX(uint _tokenId, uint _flag) public {
    require(_flag >= 0 && _flag <= 9, "flag not good");
    require(nftx.ownerOf(_tokenId) == msg.sender, "tokenId not good");
    IERC20(three).transferFrom(address(msg.sender), address(this), fee3);
    nftx.transferFrom(msg.sender, address(this), _tokenId);
    nftx.burn(_tokenId);
    nfts.mint(msg.sender, _flag);
    emit TransferNFTX(msg.sender, _tokenId, nfts.tokenOfOwnerByIndex(msg.sender, nfts.balanceOf(msg.sender) - 1), _flag);
  }

}