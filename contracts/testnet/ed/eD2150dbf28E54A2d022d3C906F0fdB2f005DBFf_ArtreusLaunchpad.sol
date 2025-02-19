/**
 *Submitted for verification at BscScan.com on 2022-10-07
*/

/**
 *Submitted for verification at Etherscan.io on 2022-07-24
*/

// File: contracts/IRevisionHistory.sol

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IRevisionHistory {
    function addFcfsHistory(
        uint256 _gameCode,
        address _userAdress,
        uint256 _tierName,
        address _poolContract
    ) external;

    function addAllocateHistory(
        uint256 _gameCode,
        address _userAdress,
        uint256 _tierName,
        address _poolContract
    ) external;

    function getFcfsHistory(uint256 _gameCode, address _userAddress)
        external
        view
        returns (
            uint256 gameCode,
            address userAdress,
            uint256 tierName,
            address poolContract
        );

    function getAllocateHistory(uint256 _gameCode, address _userAddress)
        external
        view
        returns (
            uint256 gameCode,
            address userAdress,
            uint256 tierName,
            address poolContract
        );
}
// File: contracts/ILockPoolTier.sol


pragma solidity ^0.8.0;

interface ILockPoolTier {
    struct PersonalLockInfo {
        address wallet;
        uint256 lockedAmount;
        uint256 createdAt;
        uint256 withdrawAvailableAt;
        bool withdraw;
        bool quickPool;
    }

    struct Tier {
        uint256 name;
        uint256 amount;
    }

    struct TokenLockInfo {
        uint256 unlockDuration;
        uint256 currentVolume;
        uint256 unlockVolume;
        uint256 totalUsers;
        uint256 unlockedUsers;
        uint256 startedAt;
        uint256 minimumAmount;
        Tier[] tiers;
    }

    event TokenLocked(address indexed wallet, uint256 amount);
    event TokenUnlocked(address indexed wallet, uint256 amount);
    event TokenClaimed(address indexed wallet, uint256 amount);
    event TokenLockPaused(uint256 indexed timestamp);
    event TokenLockResumed(uint256 indexed timestamp);

    function initParams(
        address _lockToken,
        uint256 _unlockDuration,
        uint256 _minimumAmount,
        uint256 _startedAt
    ) external;

    function setAllowEmergentUnlock(bool _value) external;

    function setTiers(uint256[] calldata _amounts, uint256[] calldata _tiers)
        external;

    function pauseTokenLock() external;

    function unpauseTokenLock() external;

    function lock(uint256 _amount) external;

    function unlock() external;

    function claimUnlockedTokens() external;

    function validWhitelist(address _stakeholder, uint256 _requireTier)
        external
        view
        returns (bool);

    function getTierUsers(uint256 _tierName) external view returns (uint256);

    function getWhitelistTier(uint256 _lockedAmount)
        external
        view
        returns (uint256 _tierName, uint256 _amount);

    function lockPoolInformation(address _stakeholder)
        external
        view
        returns (
            address wallet,
            uint256 lockedAmount,
            uint256 createdAt,
            uint256 withdrawAvailableAt,
            bool withdraw,
            bool quickPool,
            uint256 tier
        );
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

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

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
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
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

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;



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
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: contracts/lauchpads.sol

pragma solidity ^0.8.0;


contract ArtreusLaunchpad is Ownable {
    // Contract libs
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event LaunchPadTokenClaimed(address indexed wallet, uint256 amount);
    event LaunchPadTokenBought(address indexed wallet, uint256 amount);

    struct LaunchPadVestingInfo {
        address wallet;
        uint256 lockDuration;
        uint256 vestDuration;
        uint256 amount;
        uint256 paymentAmount;
        uint256 leftOverAmount;
        uint256 released;
        uint256 upfrontAmount;
        bool upfrontAmountClaimed;
        uint256 vestInterval;
        uint256 lastReleasedAt;
    }

    struct LaunchPadAllocationInfo {
        uint256 totalUsers;
        uint256 inputTokenAmount;
        uint256 outputTokenAmount;
        uint256 snapshotDate;
    }

    uint256 public launchPadSaleDate;
    uint256 public launchPadEndDate;
    uint256 public launchPadTGE;
    uint256 public launchPadLockDuration;
    uint256 public launchPadVestDuration;
    uint256 public launchPadVestInterval;
    uint256 public launchPadUpfrontPercent;
    address public launchPadPaymentReceiveWallet;
    IERC20 public paymentToken;
    IERC20 public launchPadToken;
    ILockPoolTier public lockPool;
    IRevisionHistory public historyContract;
    uint256 public historyCode;

    mapping(address => LaunchPadVestingInfo) public vestingInfo;
    LaunchPadAllocationInfo public allocationInfo;

    address[] public vestingInfoAddresses;

    // Launch pad maximum cap
    uint256 public maxAllocateAmount;
    // Payment maximum cap
    uint256 public maxCapAmount;
    uint256 public currentCapAmount;

    // Tier
    uint256 public tierName;

    // only owner or added beneficiaries can release the vesting amount
    modifier onlyVestingUser() {
        require(
            vestingInfo[_msgSender()].amount > 0,
            "You cannot release tokens!"
        );
        _;
    }

    function setRevisionHistory(address _historyContract, uint256 _historyCode)
        public
        onlyOwner
    {
        historyContract = IRevisionHistory(_historyContract);
        historyCode = _historyCode;
    }

    function setInitParams(
        address _token,
        uint256 _maxAllocateAmount,
        uint256 _maxCapAmount,
        address _paymentToken,
        address _lockPool
    ) public onlyOwner {
        launchPadToken = IERC20(_token);
        maxAllocateAmount = _maxAllocateAmount;
        maxCapAmount = _maxCapAmount;
        paymentToken = IERC20(_paymentToken);
        lockPool = ILockPoolTier(_lockPool);
    }

    function setTierParams(uint256 _tierName) public onlyOwner {
        tierName = _tierName;
    }

    function takeSnapshot() public onlyOwner {
        uint256 snapshotUsers = lockPool.getTierUsers(tierName);
        require(
            snapshotUsers > 0,
            "LaunchPad: zero users counter. Can not take users snapshot"
        );
        uint256 tokenPerUser = maxAllocateAmount.div(snapshotUsers);
        uint256 paymentPerUser = maxCapAmount.div(snapshotUsers);

        allocationInfo = LaunchPadAllocationInfo({
            totalUsers: snapshotUsers,
            inputTokenAmount: paymentPerUser,
            outputTokenAmount: tokenPerUser,
            snapshotDate: block.timestamp
        });
    }

    function setlaunchPadParams(
        uint256 _saleDate,
        uint256 _upfrontPercent,
        uint256 _vestDuration,
        uint256 _lockDuration,
        uint256 _vestInterval,
        address _launchPadPaymentReceiveWallet
    ) public onlyOwner {
        launchPadSaleDate = _saleDate;
        launchPadUpfrontPercent = _upfrontPercent;
        launchPadLockDuration = _lockDuration;
        launchPadVestDuration = _vestDuration;
        launchPadVestInterval = _vestInterval;
        launchPadPaymentReceiveWallet = _launchPadPaymentReceiveWallet;
    }

    /**
     * @dev Set launch pad timeline
     */
    function setlaunchPadTGE(uint256 _TGEDate) public onlyOwner {
        launchPadTGE = _TGEDate;
    }

    function setlaunchPadEndDate(uint256 _date) public onlyOwner {
        launchPadEndDate = _date;
    }

    /**
     * @dev Buy launch pad token
     */
    function buylaunchPadTokens() public {
        require(
            allocationInfo.totalUsers > 0,
            "LaunchPad: no user can join this launch pad pool."
        );

        // launch pad has not started yet
        require(
            launchPadSaleDate < block.timestamp,
            "LaunchPad: launch pad has not started yet."
        );

        require(
            launchPadEndDate == 0 || block.timestamp <= launchPadEndDate,
            "LaunchPad: to late to join this pool. Please wait for next sale pool"
        );
        // check lock pool conditions
        require(
            lockPool.validWhitelist(_msgSender(), tierName),
            "LaunchPad: you are not in the whitelist for this launch pad"
        );

        require(
            paymentToken.balanceOf(_msgSender()) >=
                allocationInfo.inputTokenAmount,
            "LaunchPad: your balance is not enough to buy tokens."
        );

        require(
            paymentToken.allowance(_msgSender(), address(this)) >=
                allocationInfo.inputTokenAmount,
            "LaunchPad: invalid allowance to buy launch pad tokens."
        );

        // no duplicated wallet
        require(
            vestingInfo[_msgSender()].paymentAmount == 0,
            "LaunchPad: you has joined the launch pad already."
        );

        // add launch pad information
        uint256 upfrontAmount = allocationInfo
            .outputTokenAmount
            .mul(launchPadUpfrontPercent)
            .div(100);

        uint256 leftOverAmount = allocationInfo.outputTokenAmount.sub(
            upfrontAmount
        );
        // transfer payment to address
        paymentToken.safeTransferFrom(
            _msgSender(),
            launchPadPaymentReceiveWallet,
            allocationInfo.inputTokenAmount
        );

        vestingInfo[_msgSender()] = LaunchPadVestingInfo({
            wallet: _msgSender(),
            lockDuration: launchPadLockDuration,
            vestDuration: launchPadVestDuration,
            amount: allocationInfo.outputTokenAmount,
            paymentAmount: allocationInfo.inputTokenAmount,
            leftOverAmount: leftOverAmount,
            released: upfrontAmount,
            upfrontAmount: upfrontAmount,
            vestInterval: launchPadVestInterval,
            lastReleasedAt: 0,
            upfrontAmountClaimed: false
        });

        vestingInfoAddresses.push(_msgSender());
        currentCapAmount = currentCapAmount.add(
            allocationInfo.inputTokenAmount
        );
        historyContract.addAllocateHistory(
            historyCode,
            _msgSender(),
            tierName,
            address(this)
        );
        emit LaunchPadTokenBought(
            _msgSender(),
            allocationInfo.outputTokenAmount
        );
    }

    /**
     * @dev Get launch pad stats information.
     */
    function launchPadInformation()
        public
        view
        returns (
            uint256 _launchPadSaleDate,
            uint256 _launchPadEndDate,
            uint256 _inputTokenAmount,
            uint256 _outputTokenAmount,
            uint256 _maxCapAmount,
            uint256 _currentCapAmount,
            uint256 _launchPadLockDuration,
            uint256 _launchPadVestDuration,
            uint256 _launchPadVestInterval,
            uint256 _launchPadUpfrontPercent
        )
    {
        return (
            launchPadSaleDate,
            launchPadEndDate,
            allocationInfo.inputTokenAmount,
            allocationInfo.outputTokenAmount,
            maxCapAmount,
            currentCapAmount,
            launchPadLockDuration,
            launchPadVestDuration,
            launchPadVestInterval,
            launchPadUpfrontPercent
        );
    }

    /**
     * @dev Get new vested amount of beneficiary base on vesting schedule of this beneficiary.
     */
    function releasableAmount(address _wallet)
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        LaunchPadVestingInfo memory info = vestingInfo[_wallet];
        if (info.amount == 0) {
            return (0, 0, block.timestamp);
        }

        (uint256 _vestedAmount, uint256 _lastIntervalDate) = vestedAmount(
            _wallet
        );

        return (
            _vestedAmount,
            _vestedAmount.sub(info.released),
            _lastIntervalDate
        );
    }

    /**
     * @dev Get total vested amount of beneficiary base on vesting schedule of this beneficiary.
     */
    function vestedAmount(address _wallet)
        public
        view
        returns (uint256, uint256)
    {
        LaunchPadVestingInfo memory info = vestingInfo[_wallet];
        require(
            info.amount > 0,
            "LaunchPad: The beneficiary's address cannot be found"
        );

        if (launchPadTGE == 0) {
            return (info.released, info.lastReleasedAt);
        }

        uint256 startDate = launchPadTGE.add(info.lockDuration);
        // No vesting (All amount unlock at the purchase time)
        if (info.vestDuration == 0) {
            return (info.amount, startDate);
        }

        // Vesting has not started yet
        if (block.timestamp < startDate) {
            return (info.released, info.lastReleasedAt);
        }

        // Vesting is done
        if (block.timestamp >= startDate.add(info.vestDuration)) {
            return (info.amount, startDate.add(info.vestDuration));
        }

        // It's too soon to next release
        if (
            info.lastReleasedAt > 0 &&
            block.timestamp.sub(info.vestInterval) < info.lastReleasedAt
        ) {
            return (info.released, info.lastReleasedAt);
        }

        // Vesting is interval counter
        uint256 totalVestedAmount = info.released;
        uint256 lastIntervalDate = info.lastReleasedAt > 0
            ? info.lastReleasedAt
            : startDate;

        uint256 multiplyIntervals;
        while (block.timestamp >= lastIntervalDate.add(info.vestInterval)) {
            multiplyIntervals = multiplyIntervals.add(1);
            lastIntervalDate = lastIntervalDate.add(info.vestInterval);
        }

        if (multiplyIntervals > 0) {
            uint256 newVestedAmount = info
                .leftOverAmount
                .mul(multiplyIntervals.mul(info.vestInterval))
                .div(info.vestDuration);

            totalVestedAmount = totalVestedAmount.add(newVestedAmount);
        }

        return (totalVestedAmount, lastIntervalDate);
    }

    /**
     * @dev Release vested tokens to a specified beneficiary.
     */
    function releaseTo(
        address _wallet,
        uint256 _amount,
        uint256 _lastIntervalDate
    ) internal returns (bool) {
        LaunchPadVestingInfo storage info = vestingInfo[_wallet];
        if (block.timestamp < _lastIntervalDate) {
            return false;
        }
        // Update beneficiary information
        info.released = info.released.add(_amount);
        info.lastReleasedAt = _lastIntervalDate;

        // Transfer new released amount to vesting beneficiary
        launchPadToken.safeTransfer(_wallet, _amount);
        // Emit event to of new release
        emit LaunchPadTokenClaimed(_wallet, _amount);
        return true;
    }

    /**
     * @dev Release vested tokens to current beneficiary.
     */
    function claimTokens() public onlyVestingUser {
        // Calculate the releasable amount
        (
            ,
            uint256 _newReleaseAmount,
            uint256 _lastIntervalDate
        ) = releasableAmount(_msgSender());

        // Release new vested token to the beneficiary
        if (_newReleaseAmount > 0) {
            releaseTo(_msgSender(), _newReleaseAmount, _lastIntervalDate);
        }
    }

    /**
     * @dev Release vested tokens to current beneficiary.
     */
    function claimUpfrontTokens() public onlyVestingUser {
        LaunchPadVestingInfo storage info = vestingInfo[_msgSender()];
        require(
            launchPadTGE > 0 && block.timestamp > launchPadTGE,
            "LaunchPad: Token TGE is not set or too soon to claim TGE upfront amount"
        );
        require(
            !info.upfrontAmountClaimed && info.upfrontAmount > 0,
            "LaunchPad: You have no upfront amount or upfront amount claimed"
        );
        info.upfrontAmountClaimed = true;
        // transfer upfront amount
        launchPadToken.safeTransfer(_msgSender(), info.upfrontAmount);
        // imit event
        emit LaunchPadTokenClaimed(_msgSender(), info.upfrontAmount);
    }
}