// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0-rc.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0-rc.1) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0-rc.1) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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

/**
 * @author Musket
 */
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

import "../libraries/amm/Liquidity.sol";

interface IAutoMarketMakerCore {
    struct AddLiquidity {
        uint128 baseAmount;
        uint128 quoteAmount;
        uint32 indexedPipRange;
    }

    /// @notice Add liquidity and mint the NFT
    /// @param params Struct AddLiquidity
    /// @dev Depends on data struct with base amount, quote amount and index pip
    /// calculate the liquidity and increase liquidity at index pip
    /// @return baseAmountAdded the base amount will be added
    /// @return quoteAmountAdded the quote amount will be added
    /// @return liquidity calculate from quote and base amount
    /// @return feeGrowthBase tracking growth base
    /// @return feeGrowthQuote tracking growth quote
    function addLiquidity(AddLiquidity calldata params)
        external
        returns (
            uint128 baseAmountAdded,
            uint128 quoteAmountAdded,
            uint256 liquidity,
            uint256 feeGrowthBase,
            uint256 feeGrowthQuote
        );

    /// @notice the struct for remove liquidity avoid deep stack
    struct RemoveLiquidity {
        uint128 liquidity;
        uint32 indexedPipRange;
        uint256 feeGrowthBase;
        uint256 feeGrowthQuote;
    }

    /// @notice Remove liquidity in index pip of nft
    /// @param params Struct Remove liquidity
    /// @dev remove liquidity at index pip and decrease the data of liquidity info
    /// @return baseAmount base amount receive
    /// @return quoteAmount quote amount receive
    function removeLiquidity(RemoveLiquidity calldata params)
        external
        returns (uint128 baseAmount, uint128 quoteAmount);

    /// @notice estimate amount receive when remove liquidity in index pip
    /// @param params struct Remove liquidity
    /// @dev calculate amount of quote and base
    /// @return baseAmount base amount receive
    /// @return quoteAmount quote amount receive
    /// @return liquidityInfo newest of liquidity info
    function estimateRemoveLiquidity(RemoveLiquidity calldata params)
        external
        view
        returns (
            uint128 baseAmount,
            uint128 quoteAmount,
            Liquidity.Info memory liquidityInfo
        );

    /// @notice get liquidity info of any index pip range
    /// @param index want to get info
    /// @dev load data from storage and return
    /// @return sqrtMaxPip sqrt of max pip
    /// @return sqrtMinPip sqrt of min pip
    /// @return quoteReal quote real of liquidity of index
    /// @return baseReal base real of liquidity of index
    /// @return indexedPipRange index of liquidity info
    /// @return feeGrowthBase the growth of base
    /// @return feeGrowthQuote the growth of base
    /// @return sqrtK sqrt of k=quoteReal*baseReal,
    function liquidityInfo(uint256 index)
        external
        view
        returns (
            uint128 sqrtMaxPip,
            uint128 sqrtMinPip,
            uint128 quoteReal,
            uint128 baseReal,
            uint32 indexedPipRange,
            uint256 feeGrowthBase,
            uint256 feeGrowthQuote,
            uint128 sqrtK
        );

    /// @notice get current index pip range
    /// @dev load current index pip range from storage
    /// @return The current pip range
    function pipRange() external view returns (uint128);

    /// @notice get the tick space for external generate orderbook
    /// @dev load current tick space from storage
    /// @return the config tick space
    function tickSpace() external view returns (uint32);

    /// @notice get current index pip range
    /// @dev load current current index pip range from storage
    /// @return the current index pip range
    function currentIndexedPipRange() external view returns (uint256);

    /// @notice get percent fee will be share when market order fill
    /// @dev load config fee from storage
    /// @return the config fee
    function feeShareAmm() external view returns (uint32);
}

/**
 * @author Musket
 */
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

interface IFee {
    /// @notice decrease the fee base
    /// @param baseFee will be decreased
    /// @dev minus the fee base funding
    function decreaseBaseFeeFunding(uint256 baseFee) external;

    /// @notice decrease the fee quote
    /// @param quoteFee will be decreased
    /// @dev minus the fee quote funding
    function decreaseQuoteFeeFunding(uint256 quoteFee) external;

    /// @notice increase the fee base
    /// @param baseFee will be decreased
    /// @dev plus the fee base funding
    function increaseBaseFeeFunding(uint256 baseFee) external;

    /// @notice increase the fee quote`
    /// @param quoteFee will be decreased
    /// @dev plus the fee quote funding
    function increaseQuoteFeeFunding(uint256 quoteFee) external;

    /// @notice reset the fee funding to zero when Position claim fee
    /// @param baseFee will be decreased
    /// @param quoteFee will be decreased
    /// @dev reset baseFee and quoteFee to zero
    function resetFee(uint256 baseFee, uint256 quoteFee) external;

    /// @notice get the fee base funding and fee quote funding
    /// @dev load amount quote and base
    /// @return baseFeeFunding and quoteFeeFunding
    function getFee()
        external
        view
        returns (uint256 baseFeeFunding, uint256 quoteFeeFunding);
}

/**
 * @author Musket
 */
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IAutoMarketMakerCore.sol";
import "./IMatchingEngineCore.sol";
import "./IFee.sol";

interface IMatchingEngineAMM is
    IFee,
    IAutoMarketMakerCore,
    IMatchingEngineCore
{
    struct InitParams {
        IERC20 quoteAsset;
        IERC20 baseAsset;
        uint256 basisPoint;
        uint128 maxFindingWordsIndex;
        uint128 initialPip;
        uint128 pipRange;
        uint32 tickSpace;
        address owner;
        address positionLiquidity;
        address spotHouse;
        address router;
        uint32 feeShareAmm;
    }

    struct ExchangedData {
        uint256 baseAmount;
        uint256 quoteAmount;
        uint256 feeQuoteAmount;
        uint256 feeBaseAmount;
    }

    /// @notice init the pair right after cloned
    /// @param params the init params with struct InitParams
    /// @dev save storage the init data
    function initialize(InitParams memory params) external;

    /// @notice get the base and quote amount can claim
    /// @param pip the pip of the order
    /// @param orderId id of order in pip
    /// @param exData the base amount
    /// @param basisPoint the basis point of price
    /// @param fee the fee percent
    /// @param feeBasis the basis fee froe calculate
    /// @return the Exchanged data
    /// @dev calculate the base and quote from order and pip
    function accumulateClaimableAmount(
        uint128 pip,
        uint64 orderId,
        ExchangedData memory exData,
        uint256 basisPoint,
        uint16 fee,
        uint128 feeBasis
    ) external view returns (ExchangedData memory);
}

/**
 * @author Musket
 */
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

interface IMatchingEngineCore {
    struct LiquidityOfEachPip {
        uint128 pip;
        uint256 liquidity;
    }

    /// @notice Emitted when market order filled
    /// @param isBuy side of order
    /// @param amount amount filled
    /// @param toPip fill to pip
    /// @param startPip fill start pip
    /// @param remainingLiquidity remaining liquidity in pip
    /// @param filledIndex number of index filled
    event MarketFilled(
        bool isBuy,
        uint256 indexed amount,
        uint128 toPip,
        uint256 startPip,
        uint128 remainingLiquidity,
        uint64 filledIndex
    );

    /// @notice Emitted when market order filled
    /// @param orderId side of order
    /// @param pip amount filled
    /// @param size fill to pip
    /// @param isBuy fill start pip
    event LimitOrderCreated(
        uint64 orderId,
        uint128 pip,
        uint128 size,
        bool isBuy
    );

    /// @notice Emitted limit order cancel
    /// @param size size of order
    /// @param pip of order
    /// @param orderId id of order cancel
    /// @param isBuy fill start pip
    event LimitOrderCancelled(
        bool isBuy,
        uint64 orderId,
        uint128 pip,
        uint256 size
    );

    /// @notice Emitted when update max finding word
    /// @param pairManager address of pair
    /// @param newMaxFindingWordsIndex new value
    event UpdateMaxFindingWordsIndex(
        address pairManager,
        uint128 newMaxFindingWordsIndex
    );

    /// @notice Emitted when update max finding word for limit order
    /// @param newMaxWordRangeForLimitOrder new value
    event MaxWordRangeForLimitOrderUpdated(
        uint128 newMaxWordRangeForLimitOrder
    );

    /// @notice Emitted when update max finding word for market order
    /// @param newMaxWordRangeForMarketOrder new value
    event MaxWordRangeForMarketOrderUpdated(
        uint128 newMaxWordRangeForMarketOrder
    );

    /// @notice Emitted when snap shot reserve
    /// @param pip pip snap shot
    /// @param timestamp time snap shot
    event ReserveSnapshotted(uint128 pip, uint256 timestamp);

    /// @notice Emitted when limit order updated
    /// @param pairManager address of pair
    /// @param orderId id of order
    /// @param pip at order
    /// @param size of order
    event LimitOrderUpdated(
        address pairManager,
        uint64 orderId,
        uint128 pip,
        uint256 size
    );

    /// @notice Emitted when order fill for swap
    /// @param sender address of trader
    /// @param amount0In amount 0 int
    /// @param amount1In amount 1 in
    /// @param amount0Out amount 0 out
    /// @param amount1Out amount 1 out
    /// @param to swap for address
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );

    /// @notice Update the order when partial fill
    /// @param pip the price of order
    /// @param orderId id of order in pip
    function updatePartialFilledOrder(uint128 pip, uint64 orderId) external;

    /// @notice Cancel the limit order
    /// @param pip the price of order
    /// @param orderId id of order in pip
    function cancelLimitOrder(uint128 pip, uint64 orderId)
        external
        returns (uint256 remainingSize, uint256 partialFilled);

    /// @notice Open limit order with size and price
    /// @param pip the price of order
    /// @param baseAmountIn amount of base asset
    /// @param isBuy side of the limit order
    /// @param trader the owner of the limit order
    /// @param quoteAmountIn amount of quote asset
    /// @param feePercent fee of the order
    /// @dev Calculate the order in insert to queue
    /// @return orderId id of order in pip
    /// @return baseAmountFilled when can fill market amount has filled
    /// @return quoteAmountFilled when can fill market amount has filled
    /// @return fee when can fill market amount has filled
    function openLimit(
        uint128 pip,
        uint128 baseAmountIn,
        bool isBuy,
        address trader,
        uint256 quoteAmountIn,
        uint16 feePercent
    )
        external
        returns (
            uint64 orderId,
            uint256 baseAmountFilled,
            uint256 quoteAmountFilled,
            uint256 fee
        );

    /// @notice Open market order with size is base and price
    /// @param size the amount want to open market order
    /// @param isBuy the side of market order
    /// @param trader the owner of the market order
    /// @param feePercent fee of the order
    /// @dev Calculate full the market order with limit order in queue
    /// @return mainSideOut the amount fill of main asset
    /// @return flipSideOut the amount fill of main asset convert to flip asset
    /// @return fee the amount of fee
    function openMarket(
        uint256 size,
        bool isBuy,
        address trader,
        uint16 feePercent
    )
        external
        returns (
            uint256 mainSideOut,
            uint256 flipSideOut,
            uint256 fee
        );

    /// @notice Open market order with size is base and price
    /// @param quoteAmount the quote amount want to open market order
    /// @param isBuy the side of market order
    /// @param trader the owner of the market order
    /// @param feePercent fee of the order
    /// @dev Calculate full the market order with limit order in queue
    /// @return mainSideOut the amount fill of main asset
    /// @return flipSideOut the amount fill of main asset convert to flip asset
    /// @return fee the amount of fee
    function openMarketWithQuoteAsset(
        uint256 quoteAmount,
        bool isBuy,
        address trader,
        uint16 feePercent
    )
        external
        returns (
            uint256 mainSideOut,
            uint256 flipSideOut,
            uint256 fee
        );

    /// @notice check at this pip has liquidity
    /// @param pip the price of order
    /// @dev load and check flag of liquidity
    /// @return the bool of has liquidity
    function hasLiquidity(uint128 pip) external view returns (bool);

    /// @notice Get detail pending order
    /// @param pip the price of order
    /// @param orderId id of order in pip
    /// @dev Load pending order and calculate the amount of base and quote asset
    /// @return isFilled the order is filled
    /// @return isBuy the side of the order
    /// @return size the size of order
    /// @return partialFilled the amount partial order is filled
    function getPendingOrderDetail(uint128 pip, uint64 orderId)
        external
        view
        returns (
            bool isFilled,
            bool isBuy,
            uint256 size,
            uint256 partialFilled
        );

    /// @notice Get amount liquidity pending at current price
    /// @return the amount liquidity pending
    function getLiquidityInCurrentPip() external view returns (uint128);

    function getLiquidityInPipRange(
        uint128 fromPip,
        uint256 dataLength,
        bool toHigher
    ) external view returns (LiquidityOfEachPip[] memory, uint128);

    function getAmountEstimate(
        uint256 size,
        bool isBuy,
        bool isBase
    ) external view returns (uint256 mainSideOut, uint256 flipSideOut);

    function calculatingQuoteAmount(uint256 quantity, uint128 pip)
        external
        view
        returns (uint256);

    /// @notice Get basis point of pair
    /// @return the basis point of pair
    function basisPoint() external view returns (uint256);

    /// @notice Get current price
    /// @return return the current price
    function getCurrentPip() external view returns (uint128);

    /// @notice Calculate the amount of quote asset
    /// @param quoteAmount the quote amount
    /// @param pip the price
    /// @return the base converted
    function quoteToBase(uint256 quoteAmount, uint128 pip)
        external
        view
        returns (uint256);
}

/**
 * @author Musket
 */
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

library Liquidity {
    struct Info {
        uint128 sqrtMaxPip;
        uint128 sqrtMinPip;
        uint128 quoteReal;
        uint128 baseReal;
        uint32 indexedPipRange;
        uint256 feeGrowthBase;
        uint256 feeGrowthQuote;
        uint128 sqrtK;
    }

    /// @notice Define the new pip range when the first time add liquidity
    /// @param self the liquidity info
    /// @param sqrtMaxPip the max pip
    /// @param sqrtMinPip the min pip
    /// @param indexedPipRange the index of liquidity info
    function initNewPipRange(
        Liquidity.Info storage self,
        uint128 sqrtMaxPip,
        uint128 sqrtMinPip,
        uint32 indexedPipRange
    ) internal {
        self.sqrtMaxPip = sqrtMaxPip;
        self.sqrtMinPip = sqrtMinPip;
        self.indexedPipRange = indexedPipRange;
    }

    /// @notice update the liquidity info when add liquidity
    /// @param self the liquidity info
    /// @param updater of struct Liquidity.Info, this is new value of liquidity info
    function updateAddLiquidity(
        Liquidity.Info storage self,
        Liquidity.Info memory updater
    ) internal {
        if (self.sqrtK == 0) {
            self.sqrtMaxPip = updater.sqrtMaxPip;
            self.sqrtMinPip = updater.sqrtMinPip;
            self.indexedPipRange = updater.indexedPipRange;
        }
        self.quoteReal = updater.quoteReal;
        self.baseReal = updater.baseReal;
        self.sqrtK = updater.sqrtK;
    }

    /// @notice growth fee base and quote
    /// @param self the liquidity info
    /// @param feeGrowthBase the growth of base
    /// @param feeGrowthQuote the growth of base
    function updateFeeGrowth(
        Liquidity.Info storage self,
        uint256 feeGrowthBase,
        uint256 feeGrowthQuote
    ) internal {
        self.feeGrowthBase = feeGrowthBase;
        self.feeGrowthQuote = feeGrowthQuote;
    }

    /// @notice update the liquidity info when after trade and save to storage
    /// @param self the liquidity info
    /// @param baseReserve the new value of baseReserve
    /// @param quoteReserve the new value of quoteReserve
    /// @param feeGrowth new growth value increase
    /// @param isBuy the side of trade
    function updateAMMReserve(
        Liquidity.Info storage self,
        uint128 quoteReserve,
        uint128 baseReserve,
        uint256 feeGrowth,
        bool isBuy
    ) internal {
        self.quoteReal = quoteReserve;
        self.baseReal = baseReserve;

        if (isBuy) {
            self.feeGrowthBase += feeGrowth;
        } else {
            self.feeGrowthQuote += feeGrowth;
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

import "../libraries/liquidity/Liquidity.sol";

//import "../spot-exchange/libraries/liquidity/PoolLiquidity.sol";
//import "../spot-exchange/libraries/liquidity/LiquidityInfo.sol";

interface ILiquidityManager {
    enum ModifyType {
        INCREASE,
        DECREASE
    }

    //------------------------------------------------------------------------------------------------------------------
    // FUNCTIONS
    //------------------------------------------------------------------------------------------------------------------

    // @dev get all data of nft
    function getAllDataTokens(uint256[] memory tokens)
        external
        view
        returns (UserLiquidity.Data[] memory);

    // @dev get data of nft
    function concentratedLiquidity(uint256 tokenId)
        external
        view
        returns (
            uint128 liquidity,
            uint32 indexedPipRange,
            uint256 feeGrowthBase,
            uint256 feeGrowthQuote,
            IMatchingEngineAMM pool
        );

    //------------------------------------------------------------------------------------------------------------------
    // EVENTS
    //------------------------------------------------------------------------------------------------------------------

    event LiquidityAdded(
        address indexed user,
        address indexed pool,
        uint256 indexed nftId,
        uint256 amountBaseAdded,
        uint256 amountQuoteAdded,
        uint64 indexedPipRange,
        uint256 trackingId
    );

    event LiquidityRemoved(
        address indexed user,
        address indexed pool,
        uint256 indexed nftId,
        uint256 amountBaseRemoved,
        uint256 amountQuoteRemoved,
        uint64 indexedPipRange,
        uint128 removedLiquidity,
        uint256 trackingId
    );

    event LiquidityModified(
        address indexed user,
        address indexed pool,
        uint256 indexed nftId,
        uint256 amountBaseModified,
        uint256 amountQuoteModified,
        // 0: increase
        // 1: decrease
        ModifyType modifyType,
        uint64 indexedPipRange,
        uint128 modifiedLiquidity,
        uint256 trackingId
    );

    event LiquidityShiftRange(
        address indexed user,
        address indexed pool,
        uint256 indexed nftId,
        uint64 oldIndexedPipRange,
        uint128 liquidityRemoved,
        uint256 amountBaseRemoved,
        uint256 amountQuoteRemoved,
        uint64 newIndexedPipRange,
        uint128 newLiquidity,
        uint256 amountBaseAdded,
        uint256 amountQuoteAded,
        uint256 trackingId
    );
}

pragma solidity ^0.8.9;

interface IPositionRouter {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
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

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function isPosiDexSupportPair(address tokenA, address tokenB)
        external
        view
        returns (
            address baseToken,
            address quoteToken,
            address pairManager
        );

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

/**
 * @author Musket
 */
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

import "../libraries/types/SpotHouseStorage.sol";
import "@positionex/matching-engine/contracts/interfaces/IMatchingEngineAMM.sol";

interface ISpotDex {
    //------------------------------------------------------------------------------------------------------------------
    // EVENTS
    //------------------------------------------------------------------------------------------------------------------

    event SpotHouseInitialized(address owner);

    event MarketOrderOpened(
        address trader,
        uint256 quantity,
        uint256 openNational,
        SpotHouseStorage.Side side,
        IMatchingEngineAMM spotManager,
        uint128 currentPip,
        uint256 trackingId
    );
    event LimitOrderOpened(
        uint64 orderId,
        address trader,
        uint256 quantity,
        uint256 sizeOut,
        uint128 pip,
        SpotHouseStorage.Side _side,
        address spotManager,
        uint256 trackingId
    );

    event LimitOrderCancelled(
        address trader,
        IMatchingEngineAMM spotManager,
        uint128 pip,
        SpotHouseStorage.Side _side,
        uint64 orderId,
        uint256 trackingId
    );

    event AllLimitOrderCancelled(
        address trader,
        IMatchingEngineAMM spotManager,
        uint128[] pips,
        uint64[] orderIds,
        SpotHouseStorage.Side[] sides,
        uint256 trackingId
    );

    event AssetClaimed(
        address trader,
        IMatchingEngineAMM spotManager,
        uint256 quoteAmount,
        uint256 baseAmount
    );

    //------------------------------------------------------------------------------------------------------------------
    // FUNCTIONS
    //------------------------------------------------------------------------------------------------------------------

    function openLimitOrder(
        IMatchingEngineAMM _spotManager,
        SpotHouseStorage.Side _side,
        uint256 _quantity,
        uint128 _pip
    ) external payable;

    function openBuyLimitOrderExactInput(
        IMatchingEngineAMM pairManager,
        SpotHouseStorage.Side side,
        uint256 quantity,
        uint128 pip
    ) external payable;

    function openMarketOrder(
        IMatchingEngineAMM _spotManager,
        SpotHouseStorage.Side _side,
        uint256 _quantity
    ) external payable;

    function openMarketOrderWithQuote(
        IMatchingEngineAMM _pairManager,
        SpotHouseStorage.Side _side,
        uint256 _quoteAmount
    ) external payable;

    function cancelLimitOrder(
        IMatchingEngineAMM _spotManager,
        uint64 _orderIdx,
        uint128 _pip
    ) external;

    function claimAsset(IMatchingEngineAMM _spotManager) external;

    function getAmountClaimable(
        IMatchingEngineAMM _spotManager,
        address _trader
    )
        external
        view
        returns (
            uint256 quoteAsset,
            uint256 baseAsset,
            uint256 basisPoint
        );

    function cancelAllLimitOrder(IMatchingEngineAMM _spotManager) external;

    function getPendingLimitOrders(
        IMatchingEngineAMM _spotManager,
        address _trader
    ) external view returns (SpotHouseStorage.PendingLimitOrder[] memory);

    function setFactory(address _factoryAddress) external;

    function openMarketOrder(
        IMatchingEngineAMM _pairManager,
        SpotHouseStorage.Side _side,
        uint256 _quantity,
        address _payer,
        address _recipient
    ) external payable returns (uint256[] memory);

    function openMarketOrderWithQuote(
        IMatchingEngineAMM _pairManager,
        SpotHouseStorage.Side _side,
        uint256 _quoteAmount,
        address _payer,
        address _recipient
    ) external payable returns (uint256[] memory);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

interface ISpotFactory {
    event PairManagerInitialized(
        address quoteAsset,
        address baseAsset,
        uint256 basisPoint,
        uint128 maxFindingWordsIndex,
        uint128 initialPip,
        address owner,
        address pairManager,
        uint256 pipRange,
        uint256 tickSpace
    );

    struct Pair {
        address BaseAsset;
        address QuoteAsset;
    }

    function createPairManager(
        address quoteAsset,
        address baseAsset,
        uint256 basisPoint,
        uint128 maxFindingWordsIndex,
        uint128 initialPip,
        uint128 pipRange,
        uint32 tickSpace
    ) external;

    function getPairManager(address quoteAsset, address baseAsset)
        external
        view
        returns (address pairManager);

    function getQuoteAndBase(address pairManager)
        external
        view
        returns (Pair memory);

    function isPairManagerExist(address pairManager)
        external
        view
        returns (bool);

    function getPairManagerSupported(address tokenA, address tokenB)
        external
        view
        returns (
            address baseToken,
            address quoteToken,
            address pairManager
        );

    function pairOfStakingManager(address owner, address pair)
        external
        view
        returns (address);

    function ownerPairManager(address pair) external view returns (address);

    function getTrackingRequestId(address pair) external returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

import "@positionex/matching-engine/contracts/interfaces/IMatchingEngineAMM.sol";
import "../libraries/types/SpotHouseStorage.sol";
import "./ISpotDex.sol";
import "./ILiquidityManager.sol";

interface ISpotHouse is ISpotDex {}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.9;

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.9;

interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
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

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

pragma solidity ^0.8.9;

interface IWBNB {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address src,
        address dst,
        uint256 wad
    ) external returns (bool);

    function withdraw(uint256) external;

    function approve(address guy, uint256 wad) external returns (bool);

    function balanceOf(address guy) external view returns (uint256);
}

/**
 * @author Musket
 */
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

interface IWithdrawBNB {
    function withdraw(address recipient, uint256 _amount) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

library SpotLimitOrder {
    struct Data {
        uint128 pip;
        uint64 orderId;
        bool isBuy;
        uint40 blockNumber;
        uint16 fee;
        uint128 quoteAmount;
        uint128 baseAmount;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

library DexErrors {
    string public constant DEX_ONLY_OWNER = "DEX_01";
    string public constant DEX_EMPTY_ADDRESS = "DEX_02";
    string public constant DEX_NEED_MORE_BNB = "DEX_03";
    string public constant DEX_MARKET_NOT_FULL_FILL = "DEX_04";
    string public constant DEX_MUST_NOT_TOKEN_RFI = "DEX_05";
    string public constant DEX_MUST_ORDER_BUY = "DEX_06";
    string public constant DEX_NO_LIMIT_TO_CANCEL = "DEX_07";
    string public constant DEX_ORDER_MUST_NOT_FILLED = "DEX_08";
    string public constant DEX_INVALID_ORDER_ID = "DEX_09";
    string public constant DEX_NO_AMOUNT_TO_CLAIM = "DEX_10";
    string public constant DEX_SPOT_MANGER_EXITS = "DEX_11";
    string public constant DEX_MUST_IDENTICAL_ADDRESSES = "DEX_12";
    string public constant DEX_MUST_BNB = "DEX_13";
    string public constant DEX_ONLY_COUNTER_PARTY = "DEX_14";
    string public constant DEX_INVALID_PAIR_INFO = "DEX_15";
    string public constant DEX_ONLY_ROUTER = "DEX_16";
    string public constant DEX_MAX_FEE = "DEX_17";

    string public constant LQ_NOT_IMPLEMENT_YET = "LQ_01";
    string public constant LQ_EMPTY_STAKING_MANAGER = "LQ_02";
    string public constant LQ_NO_LIQUIDITY = "LQ_03";
    string public constant LQ_POOL_EXIST = "LQ_04";
    string public constant LQ_INDEX_RANGE_NOT_DIFF = "LQ_05";
    string public constant LQ_INVALID_NUMBER = "LQ_06";
    string public constant LQ_NOT_SUPPORT = "LQ_07";
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library TransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(
                IERC20.transferFrom.selector,
                from,
                to,
                value
            )
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "STF"
        );
    }

    function transferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        token.transferFrom(from, to, value);
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(
            success,
            "TransferHelper::safeTransferETH: ETH transfer failed"
        );
    }
}

/**
 * @author Musket
 */
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

import "@positionex/matching-engine/contracts/interfaces/IMatchingEngineAMM.sol";

library UserLiquidity {
    struct Data {
        uint128 liquidity;
        uint32 indexedPipRange;
        uint256 feeGrowthBase;
        uint256 feeGrowthQuote;
        IMatchingEngineAMM pool;
    }

    struct CollectFeeData {
        uint256 feeBaseAmount;
        uint256 feeQuoteAmount;
        uint256 newFeeGrowthBase;
        uint256 newFeeGrowthQuote;
    }

    /// @notice update the liquidity of user
    /// @param liquidity the liquidity of user
    /// @param indexedPipRange the index of liquidity info
    /// @param feeGrowthBase the growth of base
    /// @param feeGrowthQuote the growth of quote
    function updateLiquidity(
        Data storage self,
        uint128 liquidity,
        uint32 indexedPipRange,
        uint256 feeGrowthBase,
        uint256 feeGrowthQuote
    ) internal {
        self.liquidity = liquidity;
        self.indexedPipRange = indexedPipRange;
        self.feeGrowthBase = feeGrowthBase;
        self.feeGrowthQuote = feeGrowthQuote;
    }
}

/**
 * @author Musket
 */
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

import "../../interfaces/IUniswapV2Router.sol";
import "../../interfaces/ISpotFactory.sol";
import "../../interfaces/ISpotHouse.sol";
import "../../interfaces/IUniswapV2Router.sol";

contract PositionRouterStorage {
    ISpotFactory public factory;

    ISpotHouse public spotHouse;

    IWithdrawBNB public withdrawBNB;

    address public WBNB;

    IUniswapV2Router02 public uniSwapRouterV2;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../interfaces/ISpotFactory.sol";

abstract contract SpotFactoryStorage is ISpotFactory {
    address public spotHouse;

    address public positionLiquidity;

    //  baseAsset address => quoteAsset address => spotManager address
    mapping(address => mapping(address => address)) internal pathPairManagers;

    mapping(address => Pair) internal allPairManager;

    mapping(address => bool) public allowedAddressAddPair;

    // pair manager => owner
    mapping(address => address) public override ownerPairManager;

    // owner => pair manager => staking manager
    mapping(address => mapping(address => address))
        public
        override pairOfStakingManager;

    address public templatePair;
    uint32 public feeShareAmm;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;

    mapping(address => uint256) public trackingRequestId;

    address public positionRouter;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

import "../exchange/SpotOrderData.sol";
import "../../interfaces/ISpotFactory.sol";
import "../../WithdrawBNB.sol";

contract SpotHouseStorage {
    using SpotLimitOrder for mapping(address => mapping(address => SpotLimitOrder.Data[]));

    ISpotFactory public spotFactory;

    address public WBNB;

    mapping(address => mapping(address => SpotLimitOrder.Data[]))
        public limitOrders;
    enum Side {
        BUY,
        SELL
    }

    enum Asset {
        Quote,
        Base,
        Fee
    }

    struct PendingLimitOrder {
        bool isBuy;
        uint256 quantity;
        uint256 partialFilled;
        uint128 pip;
        uint256 blockNumber;
        uint256 orderIdOfTrader;
        uint64 orderId;
        uint16 fee;
    }

    struct OpenLimitResp {
        uint64 orderId;
        uint256 sizeOut;
    }

    address public positionRouter;

    IWithdrawBNB public withdrawBNB;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;

    mapping(address => uint256) public trackingId;
}

/**
 * @author Musket
 * @author NiKa
 */
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@positionex/matching-engine/contracts/interfaces/IMatchingEngineAMM.sol";

import "./interfaces/ISpotFactory.sol";
import "./interfaces/IWBNB.sol";
import "./interfaces/ISpotHouse.sol";
import "./libraries/types/SpotHouseStorage.sol";
import "./libraries/types/SpotFactoryStorage.sol";
import "./interfaces/IUniswapV2Router.sol";
import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./libraries/types/PositionRouterStorage.sol";
import "./interfaces/IPositionRouter.sol";
import "./libraries/helper/DexErrors.sol";
import "./libraries/helper/TransferHelper.sol";

contract PositionRouter is
    IPositionRouter,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable,
    PositionRouterStorage
{
    modifier ensure(uint256 deadline) {
        require(deadline >= blockNumber(), "PositionRouter: EXPIRED");
        _;
    }

    receive() external payable {
        assert(_msgSender() == WBNB); // only accept BNB via fallback from the WBNB contract
    }

    function initialize(
        ISpotFactory _factory,
        ISpotHouse _spotHouse,
        IUniswapV2Router02 _uniSwapRouterV2,
        address _WBNB
    ) public initializer {
        __ReentrancyGuard_init();
        __Ownable_init();
        __Pausable_init();
        factory = _factory;
        spotHouse = _spotHouse;
        uniSwapRouterV2 = _uniSwapRouterV2;
        WBNB = _WBNB;
    }

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    )
        external
        virtual
        override
        ensure(deadline)
        returns (uint256[] memory amounts)
    {
        SideAndPair[] memory sidesAndPairs = getSidesAndPairs(path);
        if (sidesAndPairs[0].pairManager == address(0)) {
            amounts = uniSwapRouterV2.getAmountsOut(amountIn, path);
            _deposit(path[0], _msgSender(), amounts[0]);
            if (!isApprove(path[0])) {
                _approve(path[0]);
            }
            uniSwapRouterV2.swapExactTokensForTokens(
                amountIn,
                amountOutMin,
                path,
                to,
                deadline
            );
        } else {
            amounts = new uint256[](sidesAndPairs.length + 1);
            amounts[0] = amountIn;
            return _swap(amounts, sidesAndPairs, to);
        }
    }

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    )
        external
        virtual
        override
        ensure(deadline)
        returns (uint256[] memory amounts)
    {
        (
            SpotHouseStorage.Side side,
            address pairManager
        ) = getSideAndPairManager(path);
        if (pairManager == address(0)) {
            amounts = uniSwapRouterV2.getAmountsIn(amountOut, path);
            _deposit(path[0], _msgSender(), amounts[0]);
            if (!isApprove(path[0])) {
                _approve(path[0]);
            }
            uniSwapRouterV2.swapTokensForExactTokens(
                amountOut,
                amountInMax,
                path,
                to,
                deadline
            );
        } else {
            if (side == SpotHouseStorage.Side.BUY) {
                amounts = spotHouse.openMarketOrder(
                    IMatchingEngineAMM(pairManager),
                    side,
                    uint256(amountOut),
                    _msgSender(),
                    to
                );
            } else {
                amounts = spotHouse.openMarketOrderWithQuote(
                    IMatchingEngineAMM(pairManager),
                    side,
                    uint256(amountOut),
                    _msgSender(),
                    to
                );
            }
        }
    }

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    )
        external
        payable
        virtual
        override
        ensure(deadline)
        returns (uint256[] memory amounts)
    {
        require(path[0] == WBNB, DexErrors.DEX_MUST_BNB);
        SideAndPair[] memory sidesAndPairs = getSidesAndPairs(path);

        if (sidesAndPairs[0].pairManager == address(0)) {
            if (!isApprove(path[0])) {
                _approve(path[0]);
            }
            uniSwapRouterV2.swapExactETHForTokens{value: msg.value}(
                amountOutMin,
                path,
                to,
                deadline
            );
        } else {
            amounts = new uint256[](sidesAndPairs.length + 1);
            amounts[0] = msg.value;
            return _swap(amounts, sidesAndPairs, to);
        }
    }

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    )
        external
        virtual
        override
        ensure(deadline)
        returns (uint256[] memory amounts)
    {
        require(path[path.length - 1] == WBNB, DexErrors.DEX_MUST_BNB);
        (
            SpotHouseStorage.Side side,
            address pairManager
        ) = getSideAndPairManager(path);

        if (pairManager == address(0)) {
            amounts = uniSwapRouterV2.getAmountsIn(amountOut, path);
            _deposit(path[0], _msgSender(), amounts[0]);
            if (!isApprove(path[0])) {
                _approve(path[0]);
            }
            uniSwapRouterV2.swapTokensForExactETH(
                amountOut,
                amountInMax,
                path,
                to,
                deadline
            );
        } else {
            if (side == SpotHouseStorage.Side.BUY) {
                amounts = spotHouse.openMarketOrder(
                    IMatchingEngineAMM(pairManager),
                    side,
                    amountOut,
                    _msgSender(),
                    to
                );
            } else {
                amounts = spotHouse.openMarketOrderWithQuote(
                    IMatchingEngineAMM(pairManager),
                    side,
                    amountOut,
                    _msgSender(),
                    to
                );
            }
        }
    }

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    )
        external
        virtual
        override
        ensure(deadline)
        returns (uint256[] memory amounts)
    {
        require(path[path.length - 1] == WBNB, DexErrors.DEX_MUST_BNB);
        SideAndPair[] memory sidesAndPairs = getSidesAndPairs(path);

        if (sidesAndPairs[0].pairManager == address(0)) {
            amounts = uniSwapRouterV2.getAmountsOut(amountIn, path);
            _deposit(path[0], _msgSender(), amounts[0]);

            if (!isApprove(path[0])) {
                _approve(path[0]);
            }
            uniSwapRouterV2.swapExactTokensForETH(
                amountIn,
                amountOutMin,
                path,
                to,
                deadline
            );
        } else {
            amounts = new uint256[](sidesAndPairs.length + 1);
            amounts[0] = amountIn;
            return _swap(amounts, sidesAndPairs, to);
        }
    }

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    )
        external
        payable
        virtual
        override
        ensure(deadline)
        returns (uint256[] memory amounts)
    {
        (
            SpotHouseStorage.Side side,
            address pairManager
        ) = getSideAndPairManager(path);

        if (pairManager == address(0)) {
            if (!isApprove(path[0])) {
                _approve(path[0]);
            }
            uniSwapRouterV2.swapExactETHForTokens{value: msg.value}(
                amountOut,
                path,
                to,
                deadline
            );
        } else {
            if (side == SpotHouseStorage.Side.BUY) {
                amounts = spotHouse.openMarketOrder{value: msg.value}(
                    IMatchingEngineAMM(pairManager),
                    side,
                    amountOut,
                    _msgSender(),
                    to
                );
            } else {
                amounts = spotHouse.openMarketOrderWithQuote{value: msg.value}(
                    IMatchingEngineAMM(pairManager),
                    side,
                    uint256(msg.value),
                    _msgSender(),
                    to
                );
            }
        }
    }

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual override ensure(deadline) {
        SideAndPair[] memory sidesAndPairs = getSidesAndPairs(path);

        if (sidesAndPairs[0].pairManager == address(0)) {
            uint256 balanceBefore = IERC20(path[0]).balanceOf(address(this));
            _deposit(path[0], _msgSender(), amountIn);
            uint256 balanceAfter = IERC20(path[0]).balanceOf(address(this));
            if (!isApprove(path[0])) {
                _approve(path[0]);
            }
            uniSwapRouterV2
                .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                    balanceAfter - balanceBefore,
                    amountOutMin,
                    path,
                    to,
                    deadline
                );
        } else {
            uint256[] memory amounts = new uint256[](sidesAndPairs.length + 1);
            amounts[0] = amountIn;
            _swap(amounts, sidesAndPairs, to);
        }
    }

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable virtual override ensure(deadline) {
        require(path[0] == WBNB, DexErrors.DEX_MUST_BNB);
        SideAndPair[] memory sidesAndPairs = getSidesAndPairs(path);

        if (sidesAndPairs[0].pairManager == address(0)) {
            if (!isApprove(path[0])) {
                _approve(path[0]);
            }
            uniSwapRouterV2.swapExactETHForTokensSupportingFeeOnTransferTokens{
                value: msg.value
            }(amountOutMin, path, to, deadline);
        } else {
            uint256[] memory amounts = new uint256[](sidesAndPairs.length + 1);
            amounts[0] = msg.value;
            _swap(amounts, sidesAndPairs, to);
        }
    }

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual override ensure(deadline) {
        require(path[path.length - 1] == WBNB, DexErrors.DEX_MUST_BNB);
        SideAndPair[] memory sidesAndPairs = getSidesAndPairs(path);

        if (sidesAndPairs[0].pairManager == address(0)) {
            uint256 balanceBefore = IERC20(path[0]).balanceOf(address(this));
            _deposit(path[0], _msgSender(), amountIn);
            uint256 balanceAfter = IERC20(path[0]).balanceOf(address(this));

            if (!isApprove(path[0])) {
                _approve(path[0]);
            }
            uniSwapRouterV2.swapExactTokensForETHSupportingFeeOnTransferTokens(
                balanceAfter - balanceBefore,
                amountOutMin,
                path,
                to,
                deadline
            );
        } else {
            uint256[] memory amounts = new uint256[](sidesAndPairs.length + 1);
            amounts[0] = amountIn;
            _swap(amounts, sidesAndPairs, to);
        }
    }

    //------------------------------------------------------------------------------------------------------------------
    // INTERNAL FUNCTIONS
    //------------------------------------------------------------------------------------------------------------------

    function _swap(
        uint256[] memory amounts,
        SideAndPair[] memory sidesAndPairs,
        address to
    ) internal returns (uint256[] memory) {
        uint256 mainSideOut;
        uint256 flipSideOut;
        uint256 fee;
        address _trader = _msgSender();
        for (uint256 i = 0; i < sidesAndPairs.length; i++) {
            if (sidesAndPairs[i].side == SpotHouseStorage.Side.BUY) {
                if (sidesAndPairs[i].quoteToken == WBNB) {
                    _depositBNB(sidesAndPairs[i].pairManager, amounts[i]);
                } else {
                    amounts[i] = _transferFromRealBalance(
                        IERC20(sidesAndPairs[i].quoteToken),
                        i == 0 ? _trader : sidesAndPairs[i - 1].pairManager,
                        sidesAndPairs[i].pairManager,
                        amounts[i]
                    );
                }
                (mainSideOut, flipSideOut, fee) = IMatchingEngineAMM(
                    sidesAndPairs[i].pairManager
                ).openMarketWithQuoteAsset(amounts[i], true, _msgSender(), 20);
            } else {
                if (sidesAndPairs[i].baseToken == WBNB) {
                    _depositBNB(sidesAndPairs[i].pairManager, amounts[i]);
                } else {
                    amounts[i] = _transferFromRealBalance(
                        IERC20(sidesAndPairs[i].baseToken),
                        i == 0 ? _trader : sidesAndPairs[i - 1].pairManager,
                        sidesAndPairs[i].pairManager,
                        amounts[i]
                    );
                }
                (mainSideOut, flipSideOut, fee) = IMatchingEngineAMM(
                    sidesAndPairs[i].pairManager
                ).openMarket(amounts[i], false, _msgSender(), 20);
            }
            require(
                mainSideOut == amounts[i],
                DexErrors.DEX_MARKET_NOT_FULL_FILL
            );
            amounts[i + 1] = flipSideOut - fee;
            emitMarketOrderOpened(
                _trader,
                sidesAndPairs[i].side == SpotHouseStorage.Side.BUY
                    ? amounts[i + 1]
                    : amounts[i],
                sidesAndPairs[i].side == SpotHouseStorage.Side.BUY
                    ? amounts[i]
                    : amounts[i + 1],
                sidesAndPairs[i].side,
                IMatchingEngineAMM(sidesAndPairs[i].pairManager),
                IMatchingEngineAMM(sidesAndPairs[i].pairManager).getCurrentPip()
            );
        }
        _transferAfterBridge(
            amounts[sidesAndPairs.length],
            sidesAndPairs[sidesAndPairs.length - 1],
            to
        );

        return amounts;
    }

    event MarketOrderOpened(
        address trader,
        uint256 quantity,
        uint256 openNational,
        SpotHouseStorage.Side side,
        IMatchingEngineAMM spotManager,
        uint128 currentPip,
        uint256 trackingId
    );

    function emitMarketOrderOpened(
        address trader,
        uint256 quantity,
        uint256 openNational,
        SpotHouseStorage.Side side,
        IMatchingEngineAMM spotManager,
        uint128 currentPip
    ) internal {
        emit MarketOrderOpened(
            trader,
            quantity,
            openNational,
            side,
            spotManager,
            currentPip,
            0
        );
    }

    function _transferFromRealBalance(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal returns (uint256) {
        uint256 balanceBefore = token.balanceOf(to);

        TransferHelper.transferFrom(token, from, to, amount);

        return token.balanceOf(to) - balanceBefore;
    }

    function _deposit(
        address token,
        address from,
        uint256 amount
    ) internal {
        IERC20(token).transferFrom(from, address(this), amount);
    }

    function _depositBNB(address _pairManagerAddress, uint256 _amount)
        internal
    {
        require(msg.value >= _amount, DexErrors.DEX_NEED_MORE_BNB);
        IWBNB(WBNB).deposit{value: _amount}();
        assert(IWBNB(WBNB).transfer(_pairManagerAddress, _amount));
    }

    function _withdrawBNB(
        address _trader,
        address _pairManagerAddress,
        uint256 _amount
    ) internal {
        IWBNB(WBNB).transferFrom(
            _pairManagerAddress,
            address(withdrawBNB),
            _amount
        );
        withdrawBNB.withdraw(_trader, _amount);
    }

    function _transferAfterBridge(
        uint256 amount,
        SideAndPair memory sidesAndPairs,
        address to
    ) internal {
        if (sidesAndPairs.side == SpotHouseStorage.Side.BUY) {
            if (sidesAndPairs.baseToken == WBNB) {
                _withdrawBNB(to, sidesAndPairs.pairManager, amount);
            } else {
                TransferHelper.transferFrom(
                    IERC20(sidesAndPairs.baseToken),
                    sidesAndPairs.pairManager,
                    to,
                    amount
                );
            }
        } else {
            if (sidesAndPairs.quoteToken == WBNB) {
                _withdrawBNB(to, sidesAndPairs.pairManager, amount);
            } else {
                TransferHelper.transferFrom(
                    IERC20(sidesAndPairs.quoteToken),
                    sidesAndPairs.pairManager,
                    to,
                    amount
                );
            }
        }
    }

    function _approve(address token) internal {
        IERC20(token).approve(address(uniSwapRouterV2), type(uint256).max);
    }

    //------------------------------------------------------------------------------------------------------------------
    // ONLY OWNER FUNCTIONS
    //------------------------------------------------------------------------------------------------------------------

    function setFactory(ISpotFactory _newFactory) public onlyOwner {
        factory = _newFactory;
    }

    function setWithdrawBNB(IWithdrawBNB _withdrawBNB) external onlyOwner {
        withdrawBNB = _withdrawBNB;
    }

    function setUniSwpRouter(IUniswapV2Router02 _newUniSwpRouter)
        public
        onlyOwner
    {
        uniSwapRouterV2 = _newUniSwpRouter;
    }

    function setWBNB(address _newWBNB) external onlyOwner {
        WBNB = _newWBNB;
    }

    function setSpotHouse(ISpotHouse _newSpotHouse) external onlyOwner {
        spotHouse = _newSpotHouse;
    }

    //------------------------------------------------------------------------------------------------------------------
    // VIEWS FUNCTIONS
    //------------------------------------------------------------------------------------------------------------------

    function getSideAndPairManager(address[] calldata path)
        public
        view
        returns (SpotHouseStorage.Side side, address pairManager)
    {
        address quoteToken;
        (, quoteToken, pairManager) = isPosiDexSupportPair(
            path[0],
            path[path.length - 1]
        );

        if (quoteToken == path[0]) {
            // Buy
            // path[0] -> path[path.length - 1] and path[0] is quote
            side = SpotHouseStorage.Side.BUY;
        } else {
            side = SpotHouseStorage.Side.SELL;
        }
    }

    struct SideAndPair {
        SpotHouseStorage.Side side;
        address pairManager;
        address baseToken;
        address quoteToken;
    }

    function getSidesAndPairs(address[] calldata path)
        public
        view
        returns (SideAndPair[] memory)
    {
        SideAndPair[] memory sidesAndPairs = new SideAndPair[](path.length - 1);
        address baseToken;
        address quoteToken;
        address pairManager;

        for (uint256 i = 0; i < path.length - 1; i++) {
            (baseToken, quoteToken, pairManager) = isPosiDexSupportPair(
                path[i],
                path[i + 1]
            );

            if (quoteToken == path[i]) {
                // Buy
                // path[0] -> path[path.length - 1] and path[0] is quote
                sidesAndPairs[i].side = SpotHouseStorage.Side.BUY;
            } else {
                sidesAndPairs[i].side = SpotHouseStorage.Side.SELL;
            }
            sidesAndPairs[i].pairManager = pairManager;
            sidesAndPairs[i].baseToken = baseToken;
            sidesAndPairs[i].quoteToken = quoteToken;
        }

        return sidesAndPairs;
    }

    function getReserves(address tokenA, address tokenB)
        external
        view
        returns (uint256 reservesA, uint256 reservesB)
    {
        (reservesA, reservesB, ) = IUniswapV2Pair(
            IUniswapV2Factory(uniSwapRouterV2.factory()).getPair(tokenA, tokenB)
        ).getReserves();
    }

    function isApprove(address token) public view returns (bool) {
        return
            IERC20(token).allowance(address(this), address(uniSwapRouterV2)) > 0
                ? true
                : false;
    }

    function isPosiDexSupportPair(address tokenA, address tokenB)
        public
        view
        override
        returns (
            address baseToken,
            address quoteToken,
            address pairManager
        )
    {
        (baseToken, quoteToken, pairManager) = factory.getPairManagerSupported(
            tokenA,
            tokenB
        );
    }

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        public
        view
        virtual
        override
        returns (uint256[] memory amounts)
    {
        (
            SpotHouseStorage.Side side,
            address pairManagerAddress
        ) = getSideAndPairManager(path);

        uint256 sizeOut;
        uint256 openOtherSide;

        if (pairManagerAddress != address(0)) {
            IMatchingEngineAMM pairManager = IMatchingEngineAMM(
                pairManagerAddress
            );
            amounts = new uint256[](2);
            if (side == SpotHouseStorage.Side.BUY) {
                // quote
                (sizeOut, openOtherSide) = pairManager.getAmountEstimate(
                    amountIn,
                    true,
                    false
                );
                amounts[0] = sizeOut;
                amounts[1] = openOtherSide;
            } else {
                (sizeOut, openOtherSide) = pairManager.getAmountEstimate(
                    amountIn,
                    false,
                    true
                );
                amounts[0] = sizeOut;
                amounts[1] = openOtherSide;
            }
        } else {
            amounts = uniSwapRouterV2.getAmountsOut(amountIn, path);
        }
    }

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        public
        view
        virtual
        override
        returns (uint256[] memory amounts)
    {
        (
            SpotHouseStorage.Side side,
            address pairManagerAddress
        ) = getSideAndPairManager(path);
        uint256 sizeOut;
        uint256 openOtherSide;

        if (pairManagerAddress != address(0)) {
            IMatchingEngineAMM pairManager = IMatchingEngineAMM(
                pairManagerAddress
            );
            amounts = new uint256[](2);

            if (side == SpotHouseStorage.Side.BUY) {
                // quote
                (sizeOut, openOtherSide) = pairManager.getAmountEstimate(
                    amountOut,
                    true,
                    true
                );

                amounts[0] = openOtherSide;
                amounts[1] = sizeOut;
            } else {
                (sizeOut, openOtherSide) = pairManager.getAmountEstimate(
                    amountOut,
                    false,
                    false
                );
                amounts[0] = openOtherSide;
                amounts[1] = sizeOut;
            }
        } else {
            amounts = uniSwapRouterV2.getAmountsIn(amountOut, path);
        }
    }

    function blockNumber() internal view virtual returns (uint256) {
        return block.timestamp;
    }

    function _msgSender()
        internal
        view
        override(ContextUpgradeable)
        returns (address)
    {
        return msg.sender;
    }
}

/**
 * @author Musket
 */
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

import {DexErrors} from "./libraries/helper/DexErrors.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./interfaces/IWBNB.sol";
import "./interfaces/IWithdrawBNB.sol";

contract WithdrawBNB is IWithdrawBNB {
    using Address for address payable;
    IWBNB public WBNB;
    address public owner;
    mapping(address => bool) counterParties;

    modifier onlyOwner() {
        require(msg.sender == owner, DexErrors.DEX_ONLY_OWNER);
        _;
    }

    modifier onlyCounterParty() {
        require(counterParties[msg.sender], DexErrors.DEX_ONLY_COUNTER_PARTY);
        _;
    }

    receive() external payable {
        assert(msg.sender == address(WBNB));
        // only accept BNB via fallback from the WBNB contract
    }

    constructor(IWBNB _WBNB) {
        owner = msg.sender;
        WBNB = _WBNB;
    }

    function setWBNB(IWBNB _newWBNB) external onlyOwner {
        WBNB = _newWBNB;
    }

    function transferOwner(address _newOwner) external onlyOwner {
        owner = _newOwner;
    }

    function setCounterParty(address _newCounterParty) external onlyOwner {
        counterParties[_newCounterParty] = true;
    }

    function revokeCounterParty(address _account) external onlyOwner {
        counterParties[_account] = false;
    }

    function withdraw(address recipient, uint256 amount)
        external
        override
        onlyCounterParty
    {
        WBNB.withdraw(amount);
        payable(recipient).sendValue(amount);
    }
}