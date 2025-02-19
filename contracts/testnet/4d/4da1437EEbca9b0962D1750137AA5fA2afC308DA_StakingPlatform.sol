/**
 *Submitted for verification at BscScan.com on 2022-12-21
*/

/**
 *Submitted for verification at BscScan.com on 2022-12-13
*/

/**
 *Submitted for verification at BscScan.com on 2022-04-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT:  Beware that changingan allowance with this method brings the risk
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
// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

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

// File: contracts/SafeBEP20.sol

library SafeBEP20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IBEP20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IBEP20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IBEP20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IBEP20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeBEP20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IBEP20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IBEP20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeBEP20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
    
    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IBEP20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.
        
        bytes memory returndata = address(token).functionCall(data, "SafeBEP20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeBEP20: BEP20 operation did not succeed");
        }
    }
}
// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// File: contracts/Staking.sol

contract StakingPlatform is Ownable {
    
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;
    
    // args for _stakers
    struct Staker {
        uint256 stakerCurrentReward;
        uint256 stakedAmount;
        uint256 mode;
        uint256 stakeStartTime;
        uint256 lastUpdatedTime;
        uint256 staked;
    }   
    
    // refer to CRSFANS token. Address: 0x7AD8A62451f79399c940fC1A6FE96358a80B1931
    
    uint256 private _unstakingFeeRate;
    uint256 private _eventPeriod;
    uint256 private _rewardRate;
    uint256 private _rewardFeeRate;
    uint256 private _lockupPeriod;
    uint256 private _minStakeAmount_m;
    uint256 private _minStakeAmount_g;
    uint256 private _minStakeAmount_s;
    uint256 private _minStakeAmount_c;
    
    address[] private _stakers;

    mapping(address => Staker) private _staker;

    uint256 tokenDecimals = 18;

    // Total amount of token staked in staking pool.
    uint256 public totalStaked;
    IBEP20 public token;
    IBEP20 public busd;
    
    // Events triggered when start, stake, unstake(withdraw), get reward.
    event Staked(address staker, uint256 amount);
    event Harvest(address staker, uint256 rewardToClaim);
    event Withdraw(address staker, uint256 amount);
    event SetRewardRate(uint256 rewardRate);
    event SetEventPeriod(uint256 lockupDuration);
    event SetUnstakingFeeRate(uint256 unstakingFeeRate);

    constructor(address _token, uint256 decimals, address _busd) {
        
        Init();
        token = IBEP20(_token);
        busd = IBEP20(_busd);
        tokenDecimals = decimals;
    }
    
    function Init() internal {
        
        _rewardRate = 2; // per day
        _unstakingFeeRate = 1500;
        _rewardFeeRate = 100;
        _eventPeriod = 7;
        _lockupPeriod = 90;
        _minStakeAmount_m = 3* 1e6;
        _minStakeAmount_c = 1e6;
        _minStakeAmount_s = 3 * 1e6;
        _minStakeAmount_g = 7 * 1e6;
    }

    // Update rewards for _stakers according to deposited amount.
    function updateReward() private{
        
        uint256 stakerStakedAmount = _staker[msg.sender].stakedAmount;
        
        uint256 newReward = stakerStakedAmount.mul(block.timestamp.sub(_staker[msg.sender].lastUpdatedTime)).mul(_rewardRate).div(1 days).div(1e4);
        _staker[msg.sender].stakerCurrentReward = _staker[msg.sender].stakerCurrentReward.add(newReward);
        _staker[msg.sender].lastUpdatedTime = block.timestamp;
    }
    
    function startStaking(uint256 _amount, uint256 _mode) external {
        
        require(_amount > 0, "Amount should be greater than 0");
        require(token.balanceOf(msg.sender) > _amount, "Insufficient!");
        require(isLocked(msg.sender) == 0, "Can't start");
        
        if (_mode == 0) require(_amount >= _minStakeAmount_m * tokenDecimals, "Insufficient");
        else if (_mode == 1) require(_amount >= _minStakeAmount_c * tokenDecimals, "Insufficient");
        else if (_mode == 2) require(_amount >= _minStakeAmount_s * tokenDecimals, "Insufficient");
        else if (_mode == 3) require(_amount >= _minStakeAmount_g * tokenDecimals, "Insufficient");
        else require(_amount < 0, "Invalid Mode");
        
        _staker[msg.sender].mode = _mode;
        _staker[msg.sender].stakeStartTime = block.timestamp;
        _staker[msg.sender].staked = 55;
        _stakers.push(msg.sender);
        stake(msg.sender, _amount);
    }
        
    // Staker tries to stake specific amount of token.
    function stake(address addr, uint256 _amount) public{
        
        require(_amount > 0, "Amount should be greater than 0");
        require(token.balanceOf(msg.sender) > _amount, "Insufficient!");
        require(_staker[msg.sender].staked == 55, "Error: invalid staker");
        
        updateReward();
        
        token.safeTransferFrom(addr, address(this), _amount);
        _staker[msg.sender].stakedAmount = _staker[msg.sender].stakedAmount.add(_amount);
        totalStaked = totalStaked.add(_amount);
        
        emit Staked(msg.sender, _amount);
    }

    function getTotalStaked() public view returns (uint256) {

        return totalStaked;
    }

    function getNumberofStakers() public view returns (uint256) {

        return _stakers.length;
    }

    function getStakerMode(address _address) public view returns (uint256) {

        require(isStartStaking(_address) == 55, "Not staker yet");
        return _staker[_address].mode;
    }
    
    function isStartStaking(address _address) public view returns (uint256) {

        return _staker[_address].staked;
    }

    function isLocked(address _address) public view returns (uint256) {

        if (_staker[_address].staked != 55)
            return 0;
        if (_staker[_address].mode != 0)
            return block.timestamp.sub(_staker[_address].stakeStartTime).div(1 days) % 7 == 0 ? 0 : 1;
        else 
            return block.timestamp.sub(_staker[_address].stakeStartTime) >= _lockupPeriod.mul(1 days) ? 0 : 1;
    }
    
    function stakedAmount(address _address) public view returns (uint256) {
        
        return _staker[_address].stakedAmount;
    }

    function getRewardRate() public view returns (uint256) {

        return _rewardRate;
    }

    function lockupPeriod(uint256 mode) public view returns (uint256) {
        
        if (mode == 0) return _lockupPeriod;
        return _eventPeriod;
    }

    function eventPeriod() public view returns (uint256) {
        
        return _eventPeriod;
    }

    function unstakingFeeLate() public view returns (uint256) {

        return _unstakingFeeRate;
    }

    // Amount of reward staker can be guaranteed.
    function rewardToHarvest(address _address) public view returns (uint256){
        
        uint256 stakerStakedAmount = _staker[_address].stakedAmount;
        uint256 newReward = stakerStakedAmount.mul(block.timestamp.sub(_staker[_address].lastUpdatedTime)).mul(_rewardRate).div(1 days).div(1e4);
        
        return _staker[msg.sender].stakerCurrentReward + newReward;
    }

    // Withdraw some of token staked.
    function withdraw(uint256 amount) external{
        
        require(amount > 0, "Amount should be greater than 0");
        require(amount <= _staker[msg.sender].stakedAmount, "Invalid amount");

        updateReward();
        uint256 amountTobeWithdrawn = amount >= token.balanceOf(address(this)) ? token.balanceOf(address(this)) : amount;
        uint256 during = block.timestamp.sub(_staker[msg.sender].stakeStartTime).div(1 days);
        uint256 fee = 100;
        bool isLockupTimeOver = _staker[msg.sender].mode != 0 ? during % _eventPeriod == 0 && during > 0 :
            block.timestamp >= _staker[msg.sender].stakeStartTime.add(_lockupPeriod.mul(1 days));
        if (!isLockupTimeOver) {
            fee = _unstakingFeeRate;
        }
        _staker[msg.sender].stakedAmount = _staker[msg.sender].stakedAmount.sub(amountTobeWithdrawn);
        totalStaked = totalStaked.sub(amountTobeWithdrawn);
        amountTobeWithdrawn = amountTobeWithdrawn.sub(amountTobeWithdrawn.mul(fee).div(1e4));
        token.safeTransfer(msg.sender, amountTobeWithdrawn);

        emit Withdraw(msg.sender, amountTobeWithdrawn);
    }
    
    function setRewardRate(uint256 __rewardRate) external onlyOwner {
        
        require(__rewardRate > 0, "Invalid value");
        
        _rewardRate = __rewardRate;

        emit SetRewardRate(__rewardRate);
    }

    function setEventPeriod(uint256 __eventPeriod) external onlyOwner {
        
        require(__eventPeriod > 0, "Invalid Lockup Duration");

        _eventPeriod = __eventPeriod;

        emit SetEventPeriod(__eventPeriod);
    }

    function setUnstakingFeeRate(uint256 __unstakingFeeRate) external onlyOwner {
        
        require(__unstakingFeeRate > 0, "Invalid Unstaking Fee Rate");

        _unstakingFeeRate = __unstakingFeeRate;

        emit SetUnstakingFeeRate(__unstakingFeeRate);
    }

    function setLockupTime(uint256 lockupTime) external onlyOwner {
        
        require(lockupTime > 0, "Can't be zero");
        
        _lockupPeriod = lockupTime;
    }

    function setThreeMonthMinAmount(uint256 _minAmount) external onlyOwner {
        
        require (_minAmount > 0, "Can't be zero");

        _minStakeAmount_m = _minAmount;
    }
    
    function setCopperMinAmount(uint256 _minAmount) external onlyOwner {

        require (_minAmount > 0, "Can't be zero");

        _minStakeAmount_c = _minAmount;
    }

    function setSilverMinAmount(uint256 _minAmount) external onlyOwner {
        
        require (_minAmount > 0, "Can't be zero");

        _minStakeAmount_s = _minAmount;
    }

    function setGoldMinAmount(uint256 _minAmount) external onlyOwner {
        
        require (_minAmount > 0, "Can't be zero");
        
        _minStakeAmount_g = _minAmount;
    }
    
    // Get reward of msg.sender
    function harvest() public{
        
        updateReward();
        
        uint256 curReward = _staker[msg.sender].stakerCurrentReward;
        
        if (curReward >= token.balanceOf(address(this)))
            curReward = token.balanceOf(address(this));

        uint256 rewardToClaim = curReward.sub(curReward.mul(_rewardFeeRate).div(1e4));
        
        require(rewardToClaim > 0, "Nothing to claim");
        if (rewardToClaim > token.balanceOf(address(this)))
            rewardToClaim = token.balanceOf(address(this));

        harvestBUSD(msg.sender, rewardToClaim * 10**(18 - tokenDecimals));
        
        _staker[msg.sender].stakerCurrentReward = 0;
        
        emit Harvest(msg.sender, rewardToClaim);
    }

    function harvestBUSD(address addr, uint256 amount) private {
        busd.safeTransfer(addr, amount);
    }

    function getMinimumStakingAmount(uint256 _mode) public view returns (uint256) {
        
        uint256 _minStakeAmount = 0;

        if (_mode == 0 || _mode == 2) _minStakeAmount = _minStakeAmount_m;
        else if (_mode == 1) _minStakeAmount = _minStakeAmount_c;
        else if (_mode == 3) _minStakeAmount = _minStakeAmount_g;
        else require (0 > 1, "Invalid Mode");

        return _minStakeAmount;
    }
}