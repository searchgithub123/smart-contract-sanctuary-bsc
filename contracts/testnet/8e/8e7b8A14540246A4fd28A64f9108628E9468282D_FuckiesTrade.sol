// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
                /// @solidity memory-safe-assembly
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
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface StorageInterfaceV5{
    struct Trade{
        address trader;
        uint pairIndex;
        uint index;
        uint initialPosToken;       // 1e18
        uint positionSizeDai;       // 1e18
        uint openPrice;             // PRECISION
        bool buy;
        uint leverage;
        uint tp;                    // PRECISION
        uint sl;                    // PRECISION
    }
}

interface GNSTradingInterfaceV6_2 {
    function startFreeTrade(StorageInterfaceV5.Trade memory tradeConditions) external returns(uint);
}

contract FuckiesTrade is Pausable, Ownable {
    using SafeERC20 for IERC20;

    event FuckiesFreeTradeRequested(
        address trader,
        uint orderId,
        uint pairIndex,
        uint price,
        bool long
    );

    event FuckiesFreeTradeOpened(
        address trader,
        uint orderId,
        uint pairIndex,
        uint tradeIndex
    );

    event FuckiesFreeTradeClosed(
        address trader,
        uint orderId,
        uint pairIndex,
        uint tradeIndex,
        bool win
    );

    struct TradeInfo {
        uint pairIndex;
        uint tradeIndex;
    }           

    mapping(address => uint) private dailyFirstTrade;
    mapping(address => uint) private tradesToday;
    mapping(address => uint) private openedTrades;
    mapping(address => uint) private BUSDToClaim;
    mapping(uint => address) private orderIdToTrader;
    mapping(address => TradeInfo[]) private trades;
    mapping(address => uint) private lastRequest;
    mapping(bytes32 => address) private TradeInfoHashToTrader;
    mapping(bytes32 => uint) private TradeInfoHashToOrderId;

    uint private fuckiesPerTrade;
    uint private maxTradesPerDayTotal;
    uint private maxTradesPerDayWallet;
    uint private maxTradesSimultaneously;
    uint private dayStarting;
    uint private totalTradesToday;
    uint private totalRequestedTrades;
    uint private winningTrades;
    uint private losingTrades;
    uint private winningAmount;
    uint private losingAmount;
    uint private tpPercent; // 10 decimals
    uint private slPercent; // 10 decimals
    uint private tradeAmount;
    uint private payoutAmount;


    modifier isNotPaused() {
        require(!paused(), "The promotion has ended.");
        _;
    }

    modifier onlyCallbacks() {
        require(msg.sender == callbacksContractAddress, "Callback not allowed");
        _;
    }

    // External Contracts Addresses
    address private BUSDContractAddress;
    address private FUCKIESContractAddress;
    address private tradingContractAddress;
    address private tradingStorageContractAddress;
    address private callbacksContractAddress;

    GNSTradingInterfaceV6_2 private tradingContract;
    IERC20 private BUSDContract;
    IERC20 private FUCKIESContract;

    // Max integer
    uint constant MAX_UINT = 115792089237316195423570985008687907853269984665640564039457584007913129639935;
    
    constructor(address _BUSDContractAddress, address _FUCKIESContractAddress, address _tradingContractAddress, address _tradingStorageContractAddress, address _callbacksContractAddress, uint _fuckiesPerTrade, uint _maxTradesPerDayTotal, uint _maxTradesPerDayWallet, uint _maxTradesSimultaneously) {
        // Store settings
        BUSDContractAddress = _BUSDContractAddress;
        FUCKIESContractAddress = _FUCKIESContractAddress;
        tradingContractAddress = _tradingContractAddress;
        tradingStorageContractAddress = _tradingStorageContractAddress;
        callbacksContractAddress = _callbacksContractAddress;
        fuckiesPerTrade = _fuckiesPerTrade;
        maxTradesPerDayTotal = _maxTradesPerDayTotal;
        maxTradesPerDayWallet = _maxTradesPerDayWallet;
        maxTradesSimultaneously = _maxTradesSimultaneously;
        dayStarting = block.timestamp;
        tradingContract = GNSTradingInterfaceV6_2(tradingContractAddress);
        BUSDContract = IERC20(BUSDContractAddress);
        FUCKIESContract = IERC20(FUCKIESContractAddress);
        tpPercent = 20000000000; // +- 2%
        slPercent = 2500000000;  // +- 0,25%
        tradeAmount = 50000000000000000000; // 50$
        payoutAmount = 20000000000000000000; // 20$
        //Pause the contract
        _pause();
        // Allowance for Trading Contract
        BUSDContract.approve(tradingStorageContractAddress,MAX_UINT);
    }

    function startFreeTrade(uint _pairIndex, uint _marketPrice, bool _long) public isNotPaused {
        // Update Daily Timestamp
        setTodayTimeStamp();
        // Fixed Pairs
        require((_pairIndex == 0 || _pairIndex == 1 || _pairIndex == 15), "Pair not valid");
        // No Reentracy 1 minute
        require((block.timestamp - lastRequest[msg.sender] > 60), "Try it again in 1 minute");
        // Has Ticket
        require(buyFreeTradeTicket(msg.sender), "No free trade ticket");
        // No more than maxTradesPerDayTotal
        require(totalTradesToday < maxTradesPerDayTotal, "Not more free trades today");
        // No more than maxTradesSimultaneously
        require(openedTrades[msg.sender] < maxTradesSimultaneously, "Not more simultaneously trades");
        // Check max daily trades per wallet
        // If first trade date is today...
        if ((dailyFirstTrade[msg.sender] > dayStarting) && (dailyFirstTrade[msg.sender] < dayStarting + 1 days)) {
            // Check number of today trades
            require(tradesToday[msg.sender] < maxTradesPerDayWallet, "Max free trades per wallet/day");
        }
        // If first trade date is NOT today...
        else {
            dailyFirstTrade[msg.sender] = block.timestamp;
            tradesToday[msg.sender] = 0;
        }
        // Store request timestamp
        lastRequest[msg.sender] = block.timestamp;
        // Trade info
        StorageInterfaceV5.Trade memory tradeConditions;
        tradeConditions.trader = address(this);
        tradeConditions.pairIndex = _pairIndex;
        tradeConditions.index = 0;
        tradeConditions.initialPosToken = 0;
        tradeConditions.positionSizeDai = tradeAmount;
        tradeConditions.openPrice = _marketPrice;
        tradeConditions.buy = _long;
        tradeConditions.leverage = 100;
        tradeConditions.tp = _long ? _marketPrice+(((_marketPrice/100)*tpPercent)/10000000000) : _marketPrice-(((_marketPrice/100)*tpPercent)/10000000000); // +- x%
        tradeConditions.sl = _long ? _marketPrice-(((_marketPrice/100)*slPercent)/10000000000) : _marketPrice+(((_marketPrice/100)*slPercent)/10000000000); // +- x%
        // Increment trades counter
        totalRequestedTrades += 1;
        // Request Trade
        uint orderId = tradingContract.startFreeTrade(tradeConditions);
        // Store OrderId
        orderIdToTrader[orderId] = msg.sender;
        // Emit the event
        emit FuckiesFreeTradeRequested(msg.sender, orderId, _pairIndex, _marketPrice, _long);
    }

    function startFreeTradeCallback(uint _orderId, uint _pairIndex, uint _tradeIndex) external onlyCallbacks {
        // Recovering trader address
        address trader = orderIdToTrader[_orderId];
        // Storing trade
        trades[trader].push(TradeInfo(_pairIndex, _tradeIndex));
        // Update wallet daily trades
        tradesToday[trader] += 1;
        // Update openedTrades
        openedTrades[trader] +=1;
        // Update total daily trades
        totalTradesToday++;
        // Calculate TradeInfoHash
        TradeInfoHashToTrader[keccak256(abi.encode(TradeInfo(_pairIndex, _tradeIndex)))] = trader;
        // Store OrderId & Trade
        TradeInfoHashToOrderId[keccak256(abi.encode(TradeInfo(_pairIndex, _tradeIndex)))] = _orderId;
        // Emit the event
        emit FuckiesFreeTradeOpened(trader, _orderId, _pairIndex, _tradeIndex);
    }

    function closeFreeTradeCallback(uint _toPay, uint _pairIndex, uint _tradeIndex) external onlyCallbacks {
        // Find trader address
        address trader = TradeInfoHashToTrader[keccak256(abi.encode(TradeInfo(_pairIndex, _tradeIndex)))];
        // Find orderId
        uint orderId = TradeInfoHashToOrderId[keccak256(abi.encode(TradeInfo(_pairIndex, _tradeIndex)))];
        // Update openedTrades
        if (openedTrades[trader] > 0) openedTrades[trader] -= 1;
        // Add winnings to trader balance and store trade result
        bool win = (_toPay > tradeAmount) ? true : false;
        if (win) {
            BUSDToClaim[trader] += payoutAmount;
            winningTrades += 1;
            winningAmount += _toPay - tradeAmount;
        }
        else {
            losingTrades += 1;
            losingAmount += tradeAmount - _toPay;
        }
        // Find and remove trade
        for (uint i; i<trades[trader].length; i++) {
            if ((trades[trader][i].pairIndex == _pairIndex) && (trades[trader][i].tradeIndex == _tradeIndex)) {
                trades[trader][i] = trades[trader][trades[trader].length-1];
                trades[trader].pop();
                break;
            }
        }
        // Emit the event
        emit FuckiesFreeTradeClosed(trader, orderId, _pairIndex, _tradeIndex, win);
        // Clean mappings
        TradeInfoHashToTrader[keccak256(abi.encode(TradeInfo(_pairIndex, _tradeIndex)))] = address(0);
        TradeInfoHashToOrderId[keccak256(abi.encode(TradeInfo(_pairIndex, _tradeIndex)))] = 0;
    }

    function buyFreeTradeTicket(address _trader) internal returns(bool) {
        // Fuckies deposit
        // Remember to set this contract as spender in the Fuckies contract, it is usually done
        // from the frontend.
        require(FUCKIESContract.balanceOf(_trader) >= fuckiesPerTrade, "Not enough FUCKIES to trade");
        FUCKIESContract.safeTransferFrom(_trader, address(this), fuckiesPerTrade);
        return true;
    }

    function setTodayTimeStamp() internal {
        // Set the new starting day timestamp if we reach the end of the day before
        while (block.timestamp > dayStarting + 1 days) {
            // Setting a new day
            dayStarting = dayStarting + 1 days;
            // Reseting total daily trades
            totalTradesToday = 0;
        }
    }

    // ===================
    //   Pause functions
    // ===================
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    // ======================
    //   Withdraw functions
    // ======================
    function withdrawBUSD(uint _amount) public onlyOwner {
        require(BUSDContract.balanceOf(address(this)) >= _amount, "Amount exceeds balance");
        BUSDContract.safeTransfer(owner(), _amount);
    }

    function withdrawFUCKIES() public onlyOwner {
        uint balance = FUCKIESContract.balanceOf(address(this));
        require(balance > 0, "No FUCKIES to claim");
        FUCKIESContract.safeTransfer(owner(), balance);
    }

    function withdrawERC20Token(address _address) public onlyOwner {
        uint balance = IERC20(_address).balanceOf(address(this));
        require(balance > 0, "No tokens to claim");
        IERC20(_address).safeTransfer(owner(), balance);
    }

    function claimEarnings() public {
        require(BUSDToClaim[msg.sender] > 0,"No earnings to claim");
        BUSDContract.safeTransfer(msg.sender, BUSDToClaim[msg.sender]);
        BUSDToClaim[msg.sender] = 0;
    }

    // ====================
    //   Setter functions
    // ====================
    function setBUSDContractAddress(address _address) public onlyOwner {
        BUSDContractAddress = _address;
    }

    function setFUCKIESContractAddress(address _address) public onlyOwner {
        FUCKIESContractAddress = _address;
    }

    function setTradingContractAddress(address _address) public onlyOwner {
        tradingContractAddress = _address;
    }

    function setTradingStorageContractAddress(address _address) public onlyOwner {
        tradingContractAddress = _address;
    }

    function setCallbacksContractAddress(address _address) public onlyOwner {
        callbacksContractAddress = _address;
    }

    function setFuckiesPerTrade(uint _amount) public onlyOwner {
        fuckiesPerTrade = _amount;
    }

    function setMaxTradesPerDayTotal(uint _amount) public onlyOwner {
        maxTradesPerDayTotal = _amount;
    }

    function setMaxTradesPerDayWallet(uint _amount) public onlyOwner {
        maxTradesPerDayWallet = _amount;
    }

    function setMaxTradesSimultaneously(uint _amount) public onlyOwner {
        maxTradesSimultaneously = _amount;
    }

    function setDayStarting(uint _timestamp) public onlyOwner {
        dayStarting = _timestamp;
    }

    function setTpPercent(uint _value) public onlyOwner {
        tpPercent = _value;
    }

    function setSlPercent(uint _value) public onlyOwner {
        slPercent = _value;
    }

    function setTradeAmount(uint _value) public onlyOwner {
        tradeAmount = _value;
    }

    function setPayoutAmount(uint _value) public onlyOwner {
        payoutAmount = _value;
    }

    // ====================
    //   Getter functions
    // ====================
    function getBUSDContractAddress() public view returns(address) {
        return BUSDContractAddress;
    }

    function getFUCKIESContractAddress() public view returns(address) {
        return FUCKIESContractAddress;
    }

    function getTradingContractAddress() public view returns(address) {
        return tradingContractAddress;
    }

    function getTradingStorageContractAddress() public view returns(address) {
        return tradingContractAddress;
    }

    function getCallbacksContractAddress() public view returns(address) {
        return callbacksContractAddress;
    }

    function getDailyFirstTrade(address _address) public view returns(uint) {
        return dailyFirstTrade[_address];
    }

    function getFuckiesPerTrade() public view returns(uint) {
        return fuckiesPerTrade;
    }

    function getMaxTradesPerDayTotal() public view returns(uint) {
        return maxTradesPerDayTotal;
    }

    function getMaxTradesPerDayWallet() public view returns(uint) {
        return maxTradesPerDayWallet;
    }

    function getMaxTradesSimultaneously() public view returns(uint) {
        return maxTradesSimultaneously;
    }

    function getDayStarting() public view returns(uint) {
        return dayStarting;
    }

    function getTotalTradesToday() public view returns(uint) {
        return totalTradesToday;
    }

    function getWinningTrades() public view returns(uint) {
        return winningTrades;
    }

    function getLosingTrades() public view returns(uint) {
        return losingTrades;
    }

    function getWinningAmount() public view returns(uint) {
        return winningAmount;
    }

    function getLosingAmount() public view returns(uint) {
        return losingAmount;
    }

    function getBUSDToClaim(address _address) public view returns(uint) {
        return BUSDToClaim[_address];
    }

    function getFUCKIESBalance(address _address) public view returns(uint) {
        return FUCKIESContract.balanceOf(_address);
    }

    function getContractBUSDBalance() public view returns(uint) {
        return BUSDContract.balanceOf(address(this));
    }

    function getContractFUCKIESBalance() public view returns(uint) {
        return FUCKIESContract.balanceOf(address(this));
    }

    function getTrades(address _address) public view returns(TradeInfo[] memory) {
        return trades[_address];
    }

    function getOpenedTrades(address _address) public view returns(uint) {
        return openedTrades[_address];
    }

    function getTradesToday(address _address)  public view returns(uint) {
        return tradesToday[_address];
    }

    function getTotalRequestedTrades() public view returns(uint) {
        return totalRequestedTrades;
    }

    function getTpPercent() public view returns(uint) {
        return tpPercent;
    }

    function getSlPercent() public view returns(uint) {
        return slPercent;
    }

    function getTradeAmount() public view returns(uint) {
        return tradeAmount;
    }

    function getPayoutAmount() public view returns(uint) {
        return payoutAmount;
    }
}