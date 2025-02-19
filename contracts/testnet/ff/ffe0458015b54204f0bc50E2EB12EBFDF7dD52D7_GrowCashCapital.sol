/**
 *Submitted for verification at BscScan.com on 2022-12-15
*/

/**
 *Submitted for verification at BscScan.com on 2022-10-28
*/

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

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
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;




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
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
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
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
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
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
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

// File: smart/GrowCashCapital.sol


pragma solidity ^0.8.16;






contract GrowCashCapital is Context, Ownable {
    
    using SafeMath for uint256;
    
    uint256 constant partner = 0;
    uint256 constant development = 0;
    uint256 constant hardDays = 3 days;
    uint256 constant refPercentage = 0;
    uint256 constant minInvest = 150 ether;
    uint256 constant percentDivider = 10000;
    uint256 constant maxRewards = 200000000000 ether;

    uint256 private usersTotal;
    uint256 private compounds;
    uint256 private dateLaunched;
    uint256 private ovrTotalDeps;
    uint256 private ovrTotalComp;
    uint256 private ovrTotalWiths;
    
    uint256 private lastDepositTimeStep = 2 hours;
    uint256 private lastBuyCurrentRound = 1;
    uint256 private lastDepositPoolBalance;
    uint256 private lastDepositLastDrawAction;
    address private lastDepositPotentialWinner;

    address private previousPoolWinner;
    uint256 private previousPoolRewards;

    bool private initialized;
    bool private lastDepositEnabled;

    struct User {
        uint256 startDate;
        uint256 divs;
        uint256 refBonus;
        uint256 totalInvested;
        uint256 totalWithdrawn;
        uint256 totalCompounded;
        uint256 lastWith;
        uint256 timesCmpd;
        uint256 keyCounter;
        uint256 activeStakesCount;
        DepositList [] depoList;
    }

    struct DepositList {
        uint256 key;
        uint256 depoTime;
        uint256 amt;
        address ref;
        bool initialWithdrawn;
    }

    struct DivPercs{
        uint256 daysInSeconds;
        uint256 divsPercentage;
        uint256 feePercentage;
    }
    
    bool public preventbotActive = true;
    mapping(address => bool) public PreventBotlisted;

    mapping (address => User) public users;
    mapping (uint256 => DivPercs) public PercsKey;

	event NewDeposit(address indexed user, uint256 amount);
	event Withdrawn(address indexed user, uint256 amount);
    event Reinvested(address indexed user, uint256 amount);
	event WithdrawnInitial(address indexed user, uint256 amount);
	event RefBonus(address indexed referrer, address indexed referral, uint256 amount);
    event LastBuyPayout(uint256 indexed round, address indexed addr, uint256 amount, uint256 timestamp);

    address private immutable developmentAddress; 
    address private immutable partnershipAddress; //R, V, P, M

    ERC20 private BUSD = ERC20(0xa284d13C3b985E009fe817c8241d725E532f5b99);

    constructor(address dev, address part) {
            developmentAddress = dev;
            partnershipAddress = part;
            PercsKey[10] = DivPercs(3 days, 20, 300);
            PercsKey[20] = DivPercs(7 days, 22, 250);
            PercsKey[30] = DivPercs(14 days, 25, 200);
            PercsKey[40] = DivPercs(30 days, 28, 150);
            PercsKey[50] = DivPercs(90 days,33, 100);
    }

    modifier isInitialized() {
        require(initialized, "Contract not initialized.");
        _;
    }
    
    function launch(address addr, uint256 amount) public onlyOwner {
        require(!initialized, "Contract already launched.");
        initialized = true;
        lastDepositEnabled = true;
        lastDepositLastDrawAction = block.timestamp;
        dateLaunched = block.timestamp;
        invest(addr, amount);
    }

    function setPreventBotActive(bool isActive) public onlyOwner{
        preventbotActive = isActive;
    }

    function preventBotWallet(address Wallet, bool isPreventBotlisted) public onlyOwner{
        PreventBotlisted[Wallet] = isPreventBotlisted;
    }

    function preventBotMultipleWallets(address[] calldata Wallet, bool isAntiBotlisted) public onlyOwner{
        for(uint256 i = 0; i < Wallet.length; i++) {
            PreventBotlisted[Wallet[i]] = isAntiBotlisted;
        }
    }
    function checkIfPreventBotlisted(address Wallet) public onlyOwner view returns(bool preventbotlisted) {
        preventbotlisted = PreventBotlisted[Wallet];
    }

    function invest(address ref, uint256 amount) public isInitialized {
        require(amount >= minInvest, "Minimum investment not reached.");
        
        BUSD.transferFrom(msg.sender, address(this), amount);
        User storage user = users[msg.sender];

        if (user.lastWith <= 0){
            user.lastWith = block.timestamp;
            user.startDate = block.timestamp;
        }

        if(user.depoList.length == 0) usersTotal++;
        
        uint256 devStakeFee  = amount.mul(development).div(percentDivider); 
        uint256 partStakeFee = amount.mul(partner).div(percentDivider);
        uint256 adjustedAmt  = amount.sub(devStakeFee + partStakeFee); 
        
        user.totalInvested += adjustedAmt; 
        uint256 refAmount = adjustedAmt.mul(refPercentage).div(percentDivider);
        if(ref == msg.sender) ref = address(0);
        if (ref != 0x000000000000000000000000000000000000dEaD || ref != address(0)) users[ref].refBonus += refAmount;

        user.depoList.push(DepositList(user.depoList.length,  block.timestamp, adjustedAmt, ref, false));
        
        user.keyCounter++;
        user.activeStakesCount++;
        ovrTotalDeps += adjustedAmt;
        
        BUSD.transfer(developmentAddress, devStakeFee);
        BUSD.transfer(partnershipAddress, partStakeFee);
        
        drawLastDepositWinner();
        poolLastDeposit(msg.sender, amount);

        emit RefBonus(ref, msg.sender, amount);
        emit NewDeposit(msg.sender, amount);
    }

    function poolLastDeposit(address userAddress, uint256 amount) private {
        if(!lastDepositEnabled) return;

        uint256 poolShare = amount.mul(10).div(percentDivider);

        lastDepositPoolBalance = lastDepositPoolBalance.add(poolShare) > maxRewards ? 
        lastDepositPoolBalance.add(maxRewards.sub(lastDepositPoolBalance)) : lastDepositPoolBalance.add(poolShare);
        lastDepositPotentialWinner = userAddress;
        lastDepositLastDrawAction  = block.timestamp;
    } 

    function drawLastDepositWinner() public {
        if(lastDepositEnabled && block.timestamp.sub(lastDepositLastDrawAction) >= lastDepositTimeStep && lastDepositPotentialWinner != address(0)) {
                        
            uint256 devStakeFee  = lastDepositPoolBalance.mul(development).div(percentDivider); 
            uint256 partStakeFee = lastDepositPoolBalance.mul(partner).div(percentDivider);
            uint256 adjustedAmt  = lastDepositPoolBalance.sub(devStakeFee + partStakeFee);
            BUSD.transfer(lastDepositPotentialWinner, adjustedAmt);
            emit LastBuyPayout(lastBuyCurrentRound, lastDepositPotentialWinner, adjustedAmt, block.timestamp);

            
            previousPoolWinner         = lastDepositPotentialWinner;
            previousPoolRewards        = adjustedAmt;
            lastDepositPoolBalance     = 0;
            lastDepositPotentialWinner = address(0);
            lastDepositLastDrawAction  = block.timestamp; 
            lastBuyCurrentRound++;
        }
    }

    function investRefBonus() public isInitialized { 
        User storage user = users[msg.sender];
        require(user.depoList.length > 0, "User needs to have atleast 1 stake before reinvesting referral rewards.");
        require(user.refBonus > 0, "User has no referral rewards to stake.");

        user.depoList.push(DepositList(user.keyCounter,  block.timestamp, user.refBonus, address(0), false));
        
        ovrTotalComp += user.refBonus;
        user.totalInvested += user.refBonus;
        user.totalCompounded += user.refBonus;
        user.refBonus = 0;
        user.keyCounter++;
        user.activeStakesCount++;

	    emit Reinvested(msg.sender, user.refBonus);
    }

  	function reinvest() public isInitialized {
        User storage user = users[msg.sender];

        uint256 y = getUserDividends(msg.sender);

        for (uint i = 0; i < user.depoList.length; i++){
          if (!user.depoList[i].initialWithdrawn) {
            user.depoList[i].depoTime = block.timestamp;
          }
        }

        user.depoList.push(DepositList(user.keyCounter,  block.timestamp, y, address(0), false));  

        ovrTotalComp += y;
        user.totalCompounded += y;
        user.lastWith = block.timestamp;  
        user.keyCounter++;
        user.activeStakesCount++;
        compounds++;

	    emit Reinvested(msg.sender, user.refBonus);
    }

    function withdraw() public isInitialized returns (uint256 withdrawAmount) {
        if (preventbotActive) {
            require(!PreventBotlisted[msg.sender], "Address is blacklisted.");
        }  
        User storage user = users[msg.sender];
        withdrawAmount = getUserDividends(msg.sender);
      
      	for (uint i = 0; i < user.depoList.length; i++){
          if (!user.depoList[i].initialWithdrawn) {
            user.depoList[i].depoTime = block.timestamp;
          }
        }

        ovrTotalWiths += withdrawAmount;
        user.totalWithdrawn += withdrawAmount;
        user.lastWith = block.timestamp;

        BUSD.transfer(msg.sender, withdrawAmount);

		emit Withdrawn(msg.sender, withdrawAmount);
    }
  
    function withdrawInitial(uint256 key) public isInitialized {
        if (preventbotActive) {
            require(!PreventBotlisted[msg.sender], "Address is blacklisted.");
        }  
        User storage user = users[msg.sender];

        if (user.depoList[key].initialWithdrawn) revert("This user stake is already forfeited.");  
        
        uint256 dailyReturn;
        uint256 refundAmount;
        uint256 amount = user.depoList[key].amt;
        uint256 elapsedTime = block.timestamp.sub(user.depoList[key].depoTime);
        
        if (elapsedTime <= PercsKey[10].daysInSeconds){
          	dailyReturn = amount.mul(PercsKey[10].divsPercentage).div(percentDivider);
            refundAmount = amount + (dailyReturn.mul(elapsedTime).div(hardDays)) - (amount.mul(PercsKey[10].feePercentage).div(percentDivider));
        } else if (elapsedTime > PercsKey[10].daysInSeconds && elapsedTime <= PercsKey[20].daysInSeconds){
          	dailyReturn = amount.mul(PercsKey[20].divsPercentage).div(percentDivider);
            refundAmount = amount + (dailyReturn.mul(elapsedTime).div(hardDays)) - (amount.mul(PercsKey[20].feePercentage).div(percentDivider));
        } else if (elapsedTime > PercsKey[20].daysInSeconds && elapsedTime <= PercsKey[30].daysInSeconds){
          	dailyReturn = amount.mul(PercsKey[30].divsPercentage).div(percentDivider);
            refundAmount = amount + (dailyReturn.mul(elapsedTime).div(hardDays)) - (amount.mul(PercsKey[30].feePercentage).div(percentDivider));
        } else if (elapsedTime > PercsKey[30].daysInSeconds && elapsedTime <= PercsKey[40].daysInSeconds){
          	dailyReturn = amount.mul(PercsKey[40].divsPercentage).div(percentDivider);
            refundAmount = amount + (dailyReturn.mul(elapsedTime).div(hardDays)) - (amount.mul(PercsKey[40].feePercentage).div(percentDivider));
        } else if (elapsedTime > PercsKey[40].daysInSeconds && elapsedTime <= PercsKey[50].daysInSeconds){
          	dailyReturn = amount.mul(PercsKey[50].divsPercentage).div(percentDivider);
            refundAmount = amount + (dailyReturn.mul(elapsedTime).div(hardDays)) - (amount.mul(PercsKey[50].feePercentage).div(percentDivider));
        } else if (elapsedTime > PercsKey[60].daysInSeconds){
          	dailyReturn = amount.mul(PercsKey[60].divsPercentage).div(percentDivider);
            refundAmount = amount + (dailyReturn.mul(elapsedTime).div(hardDays)) - (amount.mul(PercsKey[60].feePercentage).div(percentDivider));
        } else {
            revert("Cannot calculate user's staked days.");
        }

        BUSD.transfer(msg.sender, refundAmount);
        user.activeStakesCount--;
        user.totalInvested -= amount;
        user.depoList[key].amt = 0;
        user.depoList[key].initialWithdrawn = true;
        user.depoList[key].depoTime = block.timestamp;
        
		emit WithdrawnInitial(msg.sender, refundAmount);
    }

    function getUserDividends(address addr) public view returns (uint256) {
        User storage user = users[addr];
        uint256 totalWithdrawable;     
        for (uint256 i = 0; i < user.depoList.length; i++){	
            uint256 elapsedTime = block.timestamp.sub(user.depoList[i].depoTime);
            uint256 amount = user.depoList[i].amt;
            if (user.depoList[i].initialWithdrawn) continue;

            if (elapsedTime <= PercsKey[10].daysInSeconds){
                totalWithdrawable += (amount.mul(PercsKey[10].divsPercentage).div(percentDivider)).mul(elapsedTime).div(hardDays);
            }
            if (elapsedTime > PercsKey[10].daysInSeconds && elapsedTime <= PercsKey[20].daysInSeconds){
                totalWithdrawable += (amount.mul(PercsKey[20].divsPercentage).div(percentDivider)).mul(elapsedTime).div(hardDays);
            }
            if (elapsedTime > PercsKey[20].daysInSeconds && elapsedTime <= PercsKey[30].daysInSeconds){
                totalWithdrawable += (amount.mul(PercsKey[30].divsPercentage).div(percentDivider)).mul(elapsedTime).div(hardDays);
            }
            if (elapsedTime > PercsKey[30].daysInSeconds && elapsedTime <= PercsKey[40].daysInSeconds){
                totalWithdrawable += (amount.mul(PercsKey[40].divsPercentage).div(percentDivider)).mul(elapsedTime).div(hardDays);
            }
            if (elapsedTime > PercsKey[40].daysInSeconds && elapsedTime <= PercsKey[50].daysInSeconds){
                totalWithdrawable += (amount.mul(PercsKey[50].divsPercentage).div(percentDivider)).mul(elapsedTime).div(hardDays);
            }
            if (elapsedTime > PercsKey[60].daysInSeconds){
                totalWithdrawable += (amount.mul(PercsKey[60].divsPercentage).div(percentDivider)).mul(elapsedTime).div(hardDays);
            }
        }
        return totalWithdrawable;
    }
    
    function getUserAmountOfDeposits(address addr) view external returns(uint256) {
		return users[addr].depoList.length;
	}
    
    function getUserTotalDeposits(address addr) view external returns(uint256 amount) {
		for (uint256 i = 0; i < users[addr].depoList.length; i++) {
			amount = amount.add(users[addr].depoList[i].amt);
		}
	}

    function getUserDepositInfo(address userAddress, uint256 index) view external returns(uint256 depoKey, uint256 depositTime, uint256 amount, bool withdrawn) {
        depoKey = users[userAddress].depoList[index].key;
        depositTime = users[userAddress].depoList[index].depoTime;
		amount = users[userAddress].depoList[index].amt;
		withdrawn = users[userAddress].depoList[index].initialWithdrawn;
	}

    function getContractInfo() view external returns(uint256 totalUsers, uint256 launched, uint256 userCompounds, uint256 totalDeposited, uint256 totalCompounded, uint256 totalWithdrawn) {
		totalUsers = usersTotal;
        launched = dateLaunched;
		userCompounds = compounds;
		totalDeposited = ovrTotalDeps;
		totalCompounded = ovrTotalComp;
		totalWithdrawn = ovrTotalWiths;
	}
    
    function lastDepositInfo() view external returns(uint256 currentRound, uint256 currentBalance, uint256 currentStartTime, uint256 currentStep, address currentPotentialWinner, uint256 previousReward, address previousWinner) {
        currentRound = lastBuyCurrentRound;
        currentBalance = lastDepositPoolBalance;
        currentStartTime = lastDepositLastDrawAction;  
        currentStep = lastDepositTimeStep;    
        currentPotentialWinner = lastDepositPotentialWinner;
        previousReward = previousPoolRewards;
        previousWinner = previousPoolWinner;
    }

    function getUserInfo(address userAddress) view external returns(uint256 totalInvested, uint256 totalCompounded, uint256 totalWithdrawn, uint256 totalBonus, uint256 totalActiveStakes, uint256 totalStakesMade) {
		totalInvested = users[userAddress].totalInvested;
        totalCompounded = users[userAddress].totalCompounded;
        totalWithdrawn = users[userAddress].totalWithdrawn;
        totalBonus = users[userAddress].refBonus;
        totalActiveStakes = users[userAddress].activeStakesCount;
        totalStakesMade = users[userAddress].keyCounter;
	}

	    function withDraw () onlyOwner public{
        payable(msg.sender).transfer(address(this).balance);
    }

    function getBalance() view external returns(uint256){
         return BUSD.balanceOf(address(this));
    }
    
    function switchLastDepositEventStatus() external onlyOwner {
        drawLastDepositWinner();
        lastDepositEnabled = !lastDepositEnabled ? true : false;
        if(lastDepositEnabled) lastDepositLastDrawAction = block.timestamp; // reset the start time everytime feature is enabled.
    }
}