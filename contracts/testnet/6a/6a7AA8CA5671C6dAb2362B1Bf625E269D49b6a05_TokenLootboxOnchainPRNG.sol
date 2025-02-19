// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ConfirmedOwnerWithProposal.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwner is ConfirmedOwnerWithProposal {
  constructor(address newOwner) ConfirmedOwnerWithProposal(newOwner, address(0)) {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/OwnableInterface.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwnerWithProposal is OwnableInterface {
  address private s_owner;
  address private s_pendingOwner;

  event OwnershipTransferRequested(address indexed from, address indexed to);
  event OwnershipTransferred(address indexed from, address indexed to);

  constructor(address newOwner, address pendingOwner) {
    require(newOwner != address(0), "Cannot set owner to zero");

    s_owner = newOwner;
    if (pendingOwner != address(0)) {
      _transferOwnership(pendingOwner);
    }
  }

  /**
   * @notice Allows an owner to begin transferring ownership to a new address,
   * pending.
   */
  function transferOwnership(address to) public override onlyOwner {
    _transferOwnership(to);
  }

  /**
   * @notice Allows an ownership transfer to be completed by the recipient.
   */
  function acceptOwnership() external override {
    require(msg.sender == s_pendingOwner, "Must be proposed owner");

    address oldOwner = s_owner;
    s_owner = msg.sender;
    s_pendingOwner = address(0);

    emit OwnershipTransferred(oldOwner, msg.sender);
  }

  /**
   * @notice Get the current owner
   */
  function owner() public view override returns (address) {
    return s_owner;
  }

  /**
   * @notice validate, transfer ownership, and emit relevant events
   */
  function _transferOwnership(address to) private {
    require(to != msg.sender, "Cannot transfer to self");

    s_pendingOwner = to;

    emit OwnershipTransferRequested(s_owner, to);
  }

  /**
   * @notice validate access
   */
  function _validateOwnership() internal view {
    require(msg.sender == s_owner, "Only callable by owner");
  }

  /**
   * @notice Reverts if called by anyone other than the contract owner.
   */
  modifier onlyOwner() {
    _validateOwnership();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface OwnableInterface {
  function owner() external returns (address);

  function transferOwnership(address recipient) external;

  function acceptOwnership() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface VRFCoordinatorV2Interface {
  /**
   * @notice Get configuration relevant for making requests
   * @return minimumRequestConfirmations global min for request confirmations
   * @return maxGasLimit global max for request gas limit
   * @return s_provingKeyHashes list of registered key hashes
   */
  function getRequestConfig()
    external
    view
    returns (
      uint16,
      uint32,
      bytes32[] memory
    );

  /**
   * @notice Request a set of random words.
   * @param keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * @param subId  - The ID of the VRF subscription. Must be funded
   * with the minimum subscription balance required for the selected keyHash.
   * @param minimumRequestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * @param callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [0, maxGasLimit]
   * @param numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * @return requestId - A unique identifier of the request. Can be used to match
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(
    bytes32 keyHash,
    uint64 subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external returns (uint256 requestId);

  /**
   * @notice Create a VRF subscription.
   * @return subId - A unique subscription id.
   * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
   * @dev Note to fund the subscription, use transferAndCall. For example
   * @dev  LINKTOKEN.transferAndCall(
   * @dev    address(COORDINATOR),
   * @dev    amount,
   * @dev    abi.encode(subId));
   */
  function createSubscription() external returns (uint64 subId);

  /**
   * @notice Get a VRF subscription.
   * @param subId - ID of the subscription
   * @return balance - LINK balance of the subscription in juels.
   * @return reqCount - number of requests for this subscription, determines fee tier.
   * @return owner - owner of the subscription.
   * @return consumers - list of consumer address which are able to use this subscription.
   */
  function getSubscription(uint64 subId)
    external
    view
    returns (
      uint96 balance,
      uint64 reqCount,
      address owner,
      address[] memory consumers
    );

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @param newOwner - proposed new owner of the subscription
   */
  function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @dev will revert if original owner of subId has
   * not requested that msg.sender become the new owner.
   */
  function acceptSubscriptionOwnerTransfer(uint64 subId) external;

  /**
   * @notice Add a consumer to a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - New consumer which can use the subscription
   */
  function addConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Remove a consumer from a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - Consumer to remove from the subscription
   */
  function removeConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Cancel a subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the remaining LINK to
   */
  function cancelSubscription(uint64 subId, address to) external;

  /*
   * @notice Check to see if there exists a request commitment consumers
   * for all consumers and keyhashes for a given sub.
   * @param subId - ID of the subscription
   * @return true if there exists at least one unfulfilled request for the subscription, false
   * otherwise.
   */
  function pendingRequestExists(uint64 subId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness. It ensures 2 things:
 * @dev 1. The fulfillment came from the VRFCoordinator
 * @dev 2. The consumer contract implements fulfillRandomWords.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash). Create subscription, fund it
 * @dev and your consumer contract as a consumer of it (see VRFCoordinatorInterface
 * @dev subscription management functions).
 * @dev Call requestRandomWords(keyHash, subId, minimumRequestConfirmations,
 * @dev callbackGasLimit, numWords),
 * @dev see (VRFCoordinatorInterface for a description of the arguments).
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomWords method.
 *
 * @dev The randomness argument to fulfillRandomWords is a set of random words
 * @dev generated from your requestId and the blockHash of the request.
 *
 * @dev If your contract could have concurrent requests open, you can use the
 * @dev requestId returned from requestRandomWords to track which response is associated
 * @dev with which randomness request.
 * @dev See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ.
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request. It is for this reason that
 * @dev that you can signal to an oracle you'd like them to wait longer before
 * @dev responding to the request (however this is not enforced in the contract
 * @dev and so remains effective only in the case of unmodified oracle software).
 */
abstract contract VRFConsumerBaseV2 {
  error OnlyCoordinatorCanFulfill(address have, address want);
  address private immutable vrfCoordinator;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   */
  constructor(address _vrfCoordinator) {
    vrfCoordinator = _vrfCoordinator;
  }

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBaseV2 expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomWords the VRF output expanded to the requested number of words
   */
  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual;

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
    if (msg.sender != vrfCoordinator) {
      revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
    }
    fulfillRandomWords(requestId, randomWords);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

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
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV // Deprecated in v4.8
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC1155 {
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC721 {
    function transferFrom(address from, address to, uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external view returns(address);
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

interface IOperatorRole {
  function hasRole(bytes32 role, address account) external view returns (bool);
  function grantRole(bytes32 role, address account) external view returns (bool);
  function revokeRole(bytes32 role, address account) external view returns (bool);
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.0;

import "./IOperatorRole.sol";

interface ITreasury {
  function SUPER_OPERATOR_ROLE() external;

  function withdrawFunds(address payable to, uint256 amount) external;
  function grantAdmin(address account) external;
  function revokeAdmin(address account) external;
  function isAdmin(address account) external view returns (bool);

  function grantSuperOperator(address account) external;
  function revokeSuperOperator(address account) external;
  function isSuperOperator(address account) external view returns (bool);

  function isBlacklisted(address account) external view returns(bool);

  function initialize(address admin) external;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "./interfaces/IERC721.sol";
import "./interfaces/IERC1155.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/ITreasury.sol";

import "./SendValueWithFallbackWithdraw.sol";

abstract contract LootboxBase is
    SendValueWithFallbackWithdraw
{
    ITreasury treasury;

    uint256 _foundationFee;
    uint256 _lootboxId;
    uint256 public creationFee = 0.05 ether;
    mapping(uint256 => Lootbox) lootboxIdToLootbox;

    mapping(uint256 => mapping(uint256 => mapping(uint256 => Token))) lootboxToRarityToTokenIndexToToken;
    mapping(uint256 => mapping(address => mapping(uint256 => uint256))) lootboxToContractToTokenIdToToken;
    mapping(uint256=>mapping(address=>bool)) public lootboxToWhitelistedAddresses;
    mapping(uint256=>mapping(address=>uint256)) public addressPullsOfLootbox;
    mapping(uint256 => mapping(uint256 => mapping(address => mapping(uint256 => Token)))) lootIdToRarityToContractToTokenIdToToken;

    struct Rarity {
        // uint256 chance;
        uint256 availableTokens;
    }
    struct Token {
        address contractAddress;
        uint256 tokenType;
        uint256 tokenId;
        uint256 amount;
        bool available;
        uint256 toTransfer;
    }

    struct Lootbox {
        string metadata;
        address payable seller;
        uint256 price;
        bool initialized;
        // uint256[] raritiesArray;
        mapping(uint256 => Rarity) rarities;
        uint256[] raritiesSummarized;
        uint256 deactivationTimestamp;
        uint256 maxPulls;
        bool isRestricted;
        bool isNFTRestricted;
        mapping(address=>bool) isWhitelistedCollection;
        mapping(address=>mapping(uint256=>uint256)) contractToTokenIdToPulls;
    }

    //Events

    event LootboxCreated(
        address indexed seller,
        uint256[] rarities,
        uint256 Price,
        uint256 lootboxId,
        string metadata,
        uint256 maxPulls,
        bool isRestricted,
        bool isNFTRestricted,
        address[] nftWhitelist
    );

    event TokenAdded(
        address indexed seller,
        address indexed contractAddress,
        uint256 tokenId,
        uint256 lootboxId,
        uint256 rarity,
        uint256 amount,
        uint256 tokenType
    );

    event TokenAdded(
        address indexed seller,
        address indexed contractAddress,
        uint256 amount,
        uint256 lootboxId,
        uint256 rarity,
        uint256 perDraw
    );

    event TokensAdded(
        address seller,
        address[] contracts,
        uint256[] tokenIds,
        uint256 lootboxId,
        uint256 rarity
    );

    event LootboxOpened(
        address indexed opener,
        address indexed contractAddress,
        uint256 tokenId,
        uint256 lootboxId,
        uint256 rarity,
        uint256 amount,
        bool success
    );

    event LootboxUpdated(bool status, string metadata, uint256 price);

    event statusChanged(uint256 lootboxId, bool status);

    event metadataChanged(uint256 lootboxId, string metadata);

    event priceChanged(uint256 lootboxId, uint256 price);

    event maxPullsChanged(uint256 lootboxId, uint256 maxPulls);

    event restrictionChanged(uint256 lootboxId, uint8 restriction, bool isRestricted);

    event lootboxWhitelistChanged(uint256 lootboxId, address[] addresses, bool status);


    event TokenWithdraw(
        uint256 lootboxId,
        address contractAddress,
        uint256 tokenId,
        uint256 amount,
        uint256 rarity
    );

    event TokenWithdraw(
        uint256 lootboxId,
        address contractAddress,
        uint256 rarity,
        uint256 amount
    );

    error LootboxNotFound();
    error isInitialized();

    constructor(address payable _treasury, uint256 foundationFee) {
        treasury = ITreasury(_treasury);
         _foundationFee = foundationFee;
    }


    //Modifiers and internal functions

    modifier lootboxOwnerOnly(uint256 lootboxId) {
        require(
            lootboxIdToLootbox[lootboxId].seller == msg.sender,
            "Lootbox owner only"
        );
        _;
    }



    function _checkPullValidity(uint256 lootboxId, Lootbox storage lootbox) internal {
        if(lootbox.price == 0) {
            revert LootboxNotFound();
        }
        require(!treasury.isBlacklisted(msg.sender), "Blacklisted");
        require(msg.value >= lootbox.price, "Underpriced");
        require(lootbox.initialized, "Not initialized");
        if(lootbox.isRestricted) {
            require(lootboxToWhitelistedAddresses[lootboxId][msg.sender], "Not whitelisted");
        }
        if(lootbox.maxPulls>0) {
            require(lootboxIdToLootbox[lootboxId].maxPulls > addressPullsOfLootbox[lootboxId][msg.sender], "Max pulls reached");
            addressPullsOfLootbox[lootboxId][msg.sender]++;
        }
    }

    function _checkNftWhitelist(Lootbox storage lootbox, address collection, uint256 tokenId) internal {
        require(lootbox.isNFTRestricted,"No NFT whitelist");
        require(lootbox.isWhitelistedCollection[collection],"Collection is not whitelisted");
        require(IERC721(collection).ownerOf(tokenId)==msg.sender,"Not the owner of token");
        if(lootbox.maxPulls>0) {
            require(lootbox.maxPulls>lootbox.contractToTokenIdToPulls[collection][tokenId],"Maximum number of pulls for that token exceeded");
        }
        lootbox.contractToTokenIdToPulls[collection][tokenId]++;
    }

    function getIndexOfRarity(uint256 lootboxId, uint256 rarity)
        internal
        view
        returns (uint256 indexUnsigned)
    {
        Lootbox storage lootbox = lootboxIdToLootbox[lootboxId];
        int256 index = -1;
        for (uint256 i = 0; i < lootbox.raritiesSummarized.length; i++) {
            if (lootbox.raritiesSummarized[i] == rarity) {
                index = int256(i);
            }
        }
        require(index >= 0, "Invalid rarity");
        return uint256(index);
    }

    function getRandomRarity(uint256 seed, Lootbox storage lootbox)
        internal
        view
        returns (uint256 rarity)
    {
        for (uint256 i = 0; i < lootbox.raritiesSummarized.length; i++) {
            if (i == 0 && (seed < lootbox.raritiesSummarized[i])) {
                return i;
            } else if (
                i < lootbox.raritiesSummarized.length - 1 &&
                i > 0 &&
                seed >= lootbox.raritiesSummarized[i - 1] &&
                seed < lootbox.raritiesSummarized[i]
            ) {
                return i;
            } else if (i == lootbox.raritiesSummarized.length - 1) {
                return i;
            }
        }
    }

    function _distributeFunds(address payable seller, uint256 price) internal {
        uint256 foundationFee = (price * _foundationFee) / 10000;
        uint256 sellerFee = price - foundationFee;
        _sendValueWithFallbackWithdrawWithLowGasLimit(
            payable(address(treasury)),
            foundationFee
        );
        _sendValueWithFallbackWithdrawWithMediumGasLimit(seller, sellerFee);
    }

    function transferSelectedToken(Token storage token, address opener) internal {
        if (token.tokenType == 721) {
            IERC721(token.contractAddress).transferFrom(
                address(this),
                opener,
                token.tokenId
            );
        } else if (token.tokenType == 1155) {
            IERC1155(token.contractAddress).safeTransferFrom(
                address(this),
                opener,
                token.tokenId,
                1,
                ""
            );
        } else if (token.tokenType == 20) {
            IERC20(token.contractAddress).transfer(
                opener,
                token.toTransfer
            );
        }
    }


    //Lootbox methods

    //Creation
    function createLootbox(
        uint256[] memory _rarities,
        uint256 _price,
        string memory metadata,
        uint256 _maxPulls,
        bool _isRestricted,
        bool _isNFTRestricted,
        address[] memory _nftWhitelist
    ) public payable {
        _lootboxId++;
        uint256 raritySum;
        for (uint256 i = 0; i < _rarities.length; i++) {
            // lootboxIdToLootbox[_lootboxId].rarities[i].chance = _rarities[i];
            raritySum += _rarities[i];
            lootboxIdToLootbox[_lootboxId].raritiesSummarized.push(raritySum);
        }
        require(!treasury.isBlacklisted(msg.sender), "Blacklisted");
        require(_price > 0, "0 price");
        require(raritySum == 10000, "Invalid rarities");
        require(
            bytes(metadata).length >= 46,
            "Invalid IPFS path"
        );
        if(_isRestricted) {
            require(!_isNFTRestricted,"Only one restriction allowed 0");
            lootboxIdToLootbox[_lootboxId].isRestricted = true;
        }
        if(_isNFTRestricted) {
            require(!_isRestricted,"Only one restriction allowed 1");
            require(_nftWhitelist.length > 0, "Empty NFT whitelist");
            lootboxIdToLootbox[_lootboxId].isNFTRestricted = true;
            for(uint256 i = 0; i < _nftWhitelist.length; i++) {
                lootboxIdToLootbox[_lootboxId].isWhitelistedCollection[_nftWhitelist[i]] = true;
            }
        }
        require(msg.value >= creationFee, "Underpriced");
        _sendValueWithFallbackWithdrawWithLowGasLimit(
            payable(address(treasury)),
            msg.value
        );
        lootboxIdToLootbox[_lootboxId].metadata = metadata;
        lootboxIdToLootbox[_lootboxId].price = _price;
        lootboxIdToLootbox[_lootboxId].seller = payable(msg.sender);
        // lootboxIdToLootbox[_lootboxId].raritiesArray = _rarities;
        lootboxIdToLootbox[_lootboxId].maxPulls = _maxPulls;

        emit LootboxCreated(
            msg.sender,
            _rarities,
            _price,
            _lootboxId,
            metadata,
            _maxPulls,
            _isRestricted,
            _isNFTRestricted,
            _nftWhitelist
        );
    }

    //Lootbox status updates

    function startLootbox(uint256 lootboxId)
        public
        lootboxOwnerOnly(lootboxId)
    {
        Lootbox storage lootbox = lootboxIdToLootbox[lootboxId];
        if(lootbox.price == 0) {
            revert LootboxNotFound();
        }
        if(lootbox.initialized) {
            revert isInitialized();
        }
        require(
            block.timestamp - lootbox.deactivationTimestamp > 1 minutes,
            "Lootbox cooldown 60 sec"
        );
        lootbox.initialized = true;
        emit statusChanged(lootboxId, true);
    }

    function stopLootbox(uint256 lootboxId) public lootboxOwnerOnly(lootboxId) {
        Lootbox storage lootbox = lootboxIdToLootbox[lootboxId];
        if(lootbox.price == 0) {
            revert LootboxNotFound();
        }
        require(lootbox.initialized, "Already frozen");
        lootbox.initialized = false;
        lootbox.deactivationTimestamp = block.timestamp;
        emit statusChanged(lootboxId, false);
    }

    function changeLootboxMetadata(uint256 lootboxId, string memory metadata)
        public
        lootboxOwnerOnly(lootboxId)
    {
        require(
            bytes(metadata).length >= 46,
            "Invalid IPFS path"
        );
        Lootbox storage lootbox = lootboxIdToLootbox[lootboxId];
        if(lootbox.price == 0) {
            revert LootboxNotFound();
        }
        lootbox.metadata = metadata;
        emit metadataChanged(lootboxId, metadata);
    }

    function changeLootboxPrice(uint256 lootboxId, uint256 price)
        public
        lootboxOwnerOnly(lootboxId)
    {
        require(price > 0, "0 price");
        Lootbox storage lootbox = lootboxIdToLootbox[lootboxId];
        if(lootbox.price == 0) {
            revert LootboxNotFound();
        }
        lootbox.price = price;

        emit priceChanged(lootboxId, price);
    }

    function changeLootboxMaxPulls(uint256 lootboxId, uint256 maxPulls)
        public
        lootboxOwnerOnly(lootboxId)
    {
        Lootbox storage lootbox = lootboxIdToLootbox[lootboxId];
        if(lootbox.price == 0) {
            revert LootboxNotFound();
        }
        lootbox.maxPulls = maxPulls;

        emit maxPullsChanged(lootboxId, maxPulls);
    }

    function changeLootboxRestriction(uint256 lootboxId, bool isRestricted)
        public
        lootboxOwnerOnly(lootboxId)
    {
        Lootbox storage lootbox = lootboxIdToLootbox[lootboxId];
        require(!lootbox.isNFTRestricted,"NFT whitelist is in effect");
        if(lootbox.price == 0) {
            revert LootboxNotFound();
        }
        lootbox.isRestricted = isRestricted;

        emit restrictionChanged(lootboxId, 0, isRestricted);
    }

    function changeLootboxNFTRestriction(uint256 lootboxId, bool isRestricted)
        public
        lootboxOwnerOnly(lootboxId)
    {
        Lootbox storage lootbox = lootboxIdToLootbox[lootboxId];
        require(!lootbox.isRestricted,"Address whitelist is in effect");
        if(lootbox.price == 0) {
            revert LootboxNotFound();
        }
        lootbox.isNFTRestricted = isRestricted;

        emit restrictionChanged(lootboxId, 1, isRestricted);
    }

    function addToLootboxWhitelist(uint256 lootboxId, address[] memory addresses)
        public
        lootboxOwnerOnly(lootboxId)
    {
        Lootbox storage lootbox = lootboxIdToLootbox[lootboxId];
        if(lootbox.price == 0) {
            revert LootboxNotFound();
        }
        for (uint256 i = 0; i < addresses.length; i++) {
            lootboxToWhitelistedAddresses[lootboxId][addresses[i]] = true;
        }
        emit lootboxWhitelistChanged(lootboxId, addresses, true);
    }

    function removeFromLootboxWhitelist(uint256 lootboxId, address[] memory addresses)
        public
        lootboxOwnerOnly(lootboxId)
    {
        Lootbox storage lootbox = lootboxIdToLootbox[lootboxId];
        if(lootbox.price == 0) {
            revert LootboxNotFound();
        }
        for (uint256 i = 0; i < addresses.length; i++) {
            lootboxToWhitelistedAddresses[lootboxId][addresses[i]] = false;
        }
        emit lootboxWhitelistChanged(lootboxId, addresses, false);
    }

    // Adding tokens to lootbox

    //ERC721
    function addToken(
        address contractAddress,
        uint256 tokenId,
        uint256 rarity,
        uint256 lootboxId
    ) public lootboxOwnerOnly(lootboxId) {
        Lootbox storage lootbox = lootboxIdToLootbox[lootboxId];
        if(lootbox.price == 0) {
            revert LootboxNotFound();
        }
        if(lootbox.initialized) {
            revert isInitialized();
        }

        Token memory token = Token(contractAddress, 721, tokenId, 1, true, 1);
        uint256 lootboxRarity = getIndexOfRarity(lootboxId, rarity);
        lootbox.rarities[lootboxRarity].availableTokens++;
        lootboxToRarityToTokenIndexToToken[lootboxId][lootboxRarity][lootbox.rarities[lootboxRarity].availableTokens]=token;
        lootboxToContractToTokenIdToToken[lootboxId][contractAddress][tokenId]=lootbox.rarities[lootboxRarity].availableTokens;
        lootIdToRarityToContractToTokenIdToToken[lootboxId][lootboxRarity][contractAddress][tokenId] = token;
        IERC721(contractAddress).transferFrom(
            msg.sender,
            address(this),
            tokenId
        );
        emit TokenAdded(
            msg.sender,
            contractAddress,
            tokenId,
            lootboxId,
            rarity,
            1,
            721
        );
    }

    //ERC721 Bulk
    function addToken(
        address[] memory contracts,
        uint256[] memory tokenIds,
        uint256 rarity,
        uint256 lootboxId
    ) public lootboxOwnerOnly(lootboxId) {
        Lootbox storage lootbox = lootboxIdToLootbox[lootboxId];
        if(lootbox.price == 0) {
            revert LootboxNotFound();
        }
        if(lootbox.initialized) {
            revert isInitialized();
        }
        uint256 lootboxRarity = getIndexOfRarity(lootboxId, rarity);
        for (uint256 i = 0; i < contracts.length; i++) {
            Token memory token = Token(contracts[i], 721, tokenIds[i], 1, true, 1);
            lootbox.rarities[lootboxRarity].availableTokens++;
            lootboxToRarityToTokenIndexToToken[lootboxId][lootboxRarity][lootbox.rarities[lootboxRarity].availableTokens]=token;
            lootboxToContractToTokenIdToToken[lootboxId][contracts[i]][tokenIds[i]]=lootbox.rarities[lootboxRarity].availableTokens;
            lootIdToRarityToContractToTokenIdToToken[lootboxId][lootboxRarity][contracts[i]][tokenIds[i]] = token;
            IERC721(contracts[i]).transferFrom(
                msg.sender,
                address(this),
                tokenIds[i]
            );
        }

        emit TokensAdded(msg.sender, contracts, tokenIds, lootboxId, rarity);
    }

    //ERC1155
    function addToken(
        address contractAddress,
        uint256 tokenId,
        uint256 rarity,
        uint256 lootboxId,
        uint256 amount
    ) public lootboxOwnerOnly(lootboxId) {
        Lootbox storage lootbox = lootboxIdToLootbox[lootboxId];
        if(lootbox.price == 0) {
            revert LootboxNotFound();
        }
        if(lootbox.initialized) {
            revert isInitialized();
        }

        uint256 lootboxRarity = getIndexOfRarity(lootboxId, rarity);

        if(lootIdToRarityToContractToTokenIdToToken[lootboxId][lootboxRarity][contractAddress][tokenId].tokenType==0){
            lootIdToRarityToContractToTokenIdToToken[lootboxId][lootboxRarity][contractAddress][tokenId] 
                = Token(contractAddress, 1155, tokenId, amount, true, 1);
            lootbox.rarities[lootboxRarity].availableTokens++;
            lootboxToRarityToTokenIndexToToken[lootboxId][lootboxRarity]
                [lootbox.rarities[lootboxRarity].availableTokens] = Token(contractAddress, 1155, tokenId, amount, true, 1);
        } else {
            lootIdToRarityToContractToTokenIdToToken[lootboxId][lootboxRarity][contractAddress][tokenId].amount += amount;
            for(uint256 i = 0; i < lootbox.rarities[lootboxRarity].availableTokens; i++) {
                if(lootboxToRarityToTokenIndexToToken[lootboxId][lootboxRarity][i].contractAddress==contractAddress && 
                    lootboxToRarityToTokenIndexToToken[lootboxId][lootboxRarity][i].tokenId==tokenId){
                    lootboxToRarityToTokenIndexToToken[lootboxId][lootboxRarity][i].amount += amount;
                    break;
                }
            }
        }

        IERC1155(contractAddress).safeTransferFrom(
            msg.sender,
            address(this),
            tokenId,
            amount,
            ""
        );
        emit TokenAdded(
            msg.sender,
            contractAddress,
            tokenId,
            lootboxId,
            rarity,
            amount,
            1155
        );
    }

    //ERC20
    function addToken(
        uint256 rarity,
        uint256 lootboxId,
        uint256 amount,
        address contractAddress,
        uint256 perDraw
    ) public lootboxOwnerOnly(lootboxId) {
        Lootbox storage lootbox = lootboxIdToLootbox[lootboxId];
        if(lootbox.price == 0) {
            revert LootboxNotFound();
        }
        if(lootbox.initialized) {
            revert isInitialized();
        }
        uint256 lootboxRarity = getIndexOfRarity(lootboxId, rarity);
        
        if(lootIdToRarityToContractToTokenIdToToken[lootboxId][lootboxRarity][contractAddress][0].tokenType==0){
            lootIdToRarityToContractToTokenIdToToken[lootboxId][lootboxRarity][contractAddress][0] 
                = Token(contractAddress, 20, 0, amount, true, perDraw);
            lootbox.rarities[lootboxRarity].availableTokens++;
            lootboxToRarityToTokenIndexToToken[lootboxId][lootboxRarity]
                [lootbox.rarities[lootboxRarity].availableTokens] = Token(contractAddress, 20, 0, amount, true, perDraw); 
        } else {
            require(lootIdToRarityToContractToTokenIdToToken[lootboxId][lootboxRarity][contractAddress][0].toTransfer==perDraw,"Wrong per draw");
            lootIdToRarityToContractToTokenIdToToken[lootboxId][lootboxRarity][contractAddress][0].amount += amount;
            for(uint256 i = 0; i < lootbox.rarities[lootboxRarity].availableTokens; i++) {
                if(lootboxToRarityToTokenIndexToToken[lootboxId][lootboxRarity][i].contractAddress==contractAddress && 
                    lootboxToRarityToTokenIndexToToken[lootboxId][lootboxRarity][i].toTransfer == perDraw){
                    lootboxToRarityToTokenIndexToToken[lootboxId][lootboxRarity][i].amount += amount;
                    break;
                }
            }
        }

        IERC20(contractAddress).transferFrom(
            msg.sender,
            address(this),
            amount*perDraw
        );
        emit TokenAdded(
            msg.sender,
            contractAddress,
            amount,
            lootboxId,
            rarity,
            perDraw
        );
    }

    //Withdraw ERC721
    function withdrawToken(
        uint256 rarity,
        uint256 tokenId, 
        address contractAddress, 
        uint256 lootboxId
    ) public lootboxOwnerOnly(lootboxId) {
        Lootbox storage lootbox = lootboxIdToLootbox[lootboxId];
        if(lootbox.price == 0) {
            revert LootboxNotFound();
        }
        if(lootbox.initialized) {
            revert isInitialized();
        }
        uint256 chosenToken = lootboxToContractToTokenIdToToken[lootboxId][contractAddress][tokenId];
        uint256 lootboxRarity = getIndexOfRarity(lootboxId, rarity);

        Token storage token = lootboxToRarityToTokenIndexToToken[lootboxId][lootboxRarity][chosenToken];
        require(token.available);
        token.available = false;
        token.amount--;

        if(chosenToken != lootbox.rarities[lootboxRarity].availableTokens) {
            lootboxToRarityToTokenIndexToToken[lootboxId][lootboxRarity][chosenToken] =
                lootboxToRarityToTokenIndexToToken[lootboxId][lootboxRarity][lootbox.rarities[lootboxRarity].availableTokens];
        }
        delete lootIdToRarityToContractToTokenIdToToken[lootboxId][lootboxRarity][contractAddress][tokenId];
        lootbox.rarities[lootboxRarity].availableTokens--;

        IERC721(contractAddress).transferFrom(address(this), msg.sender, tokenId);
        emit TokenWithdraw(lootboxId, contractAddress, tokenId, 1, rarity);
    }

    //Withdraw ERC1155
    function withdrawToken(
        uint256 rarity, 
        address contractAddress, 
        uint256 tokenId, 
        uint256 lootboxId,
        uint256 amount
    ) public lootboxOwnerOnly(lootboxId) {
        Lootbox storage lootbox = lootboxIdToLootbox[lootboxId];
        if(lootbox.price == 0) {
            revert LootboxNotFound();
        }
        if(lootbox.initialized) {
            revert isInitialized();
        }

        uint256 lootboxRarity = getIndexOfRarity(lootboxId, rarity);
        Token storage token = lootIdToRarityToContractToTokenIdToToken[lootboxId][lootboxRarity][contractAddress][tokenId];
        require(token.amount>=amount,"exceeds deposited");

        for(uint256 i = 1; i <= lootbox.rarities[lootboxRarity].availableTokens; i++) {
            if(lootboxToRarityToTokenIndexToToken[lootboxId][lootboxRarity][i].contractAddress==contractAddress && 
                lootboxToRarityToTokenIndexToToken[lootboxId][lootboxRarity][i].tokenId==tokenId){
                lootboxToRarityToTokenIndexToToken[lootboxId][lootboxRarity][i].amount -= amount;
                if(lootboxToRarityToTokenIndexToToken[lootboxId][lootboxRarity][i].amount==0) {
                    if(i!=lootbox.rarities[lootboxRarity].availableTokens) {
                        lootboxToRarityToTokenIndexToToken[lootboxId][lootboxRarity][i] = 
                            lootboxToRarityToTokenIndexToToken[lootboxId][lootboxRarity][lootbox.rarities[lootboxRarity].availableTokens];
                    }
                    delete lootboxToRarityToTokenIndexToToken[lootboxId][lootboxRarity][lootbox.rarities[lootboxRarity].availableTokens];
                    lootbox.rarities[lootboxRarity].availableTokens--;
                }
                break;
            }
        }
        token.amount -= amount;
        if(token.amount == 0) {
            delete lootIdToRarityToContractToTokenIdToToken[lootboxId][lootboxRarity][contractAddress][tokenId];
        }

        IERC1155(contractAddress).safeTransferFrom(address(this), msg.sender, tokenId, amount, "");
        emit TokenWithdraw(lootboxId, contractAddress, tokenId, amount, rarity);
    }

    function getDeposited(uint256 lootboxId, uint256 rarity, address contractAddress) public view returns(Token memory){
        uint256 lootboxRarity = getIndexOfRarity(lootboxId, rarity);
        return lootIdToRarityToContractToTokenIdToToken[lootboxId][lootboxRarity][contractAddress][0];
    }

    //Withdraw ERC20
    function withdrawToken(
        uint256 rarity, 
        address contractAddress, 
        uint256 lootboxId,
        uint256 amount
    ) public lootboxOwnerOnly(lootboxId) {
        Lootbox storage lootbox = lootboxIdToLootbox[lootboxId];
        if(lootbox.price == 0) {
            revert LootboxNotFound();
        }
        if(lootbox.initialized) {
            revert isInitialized();
        }

        uint256 lootboxRarity = getIndexOfRarity(lootboxId, rarity);
        Token storage token = lootIdToRarityToContractToTokenIdToToken[lootboxId][lootboxRarity][contractAddress][0];
        require(token.amount >= amount, "exceeds deposited");
        uint256 tokensToTransfer = amount*token.toTransfer;

        for(uint256 i = 1; i <= lootbox.rarities[lootboxRarity].availableTokens; i++) {
            if(lootboxToRarityToTokenIndexToToken[lootboxId][lootboxRarity][i].contractAddress==contractAddress && 
                lootboxToRarityToTokenIndexToToken[lootboxId][lootboxRarity][i].toTransfer==token.toTransfer){
                lootboxToRarityToTokenIndexToToken[lootboxId][lootboxRarity][i].amount -= amount;
                if(lootboxToRarityToTokenIndexToToken[lootboxId][lootboxRarity][i].amount==0) {
                    if(i!=lootbox.rarities[lootboxRarity].availableTokens) {
                        lootboxToRarityToTokenIndexToToken[lootboxId][lootboxRarity][i] = 
                            lootboxToRarityToTokenIndexToToken[lootboxId][lootboxRarity][lootbox.rarities[lootboxRarity].availableTokens];
                    }
                    delete lootboxToRarityToTokenIndexToToken[lootboxId][lootboxRarity][lootbox.rarities[lootboxRarity].availableTokens];
                    lootbox.rarities[lootboxRarity].availableTokens--;
                }
                break;
            }
        }
        
        token.amount-=amount;
        if(token.amount == 0) {
            delete lootIdToRarityToContractToTokenIdToToken[lootboxId][lootboxRarity][contractAddress][0];
        }

        IERC20(contractAddress).transfer(msg.sender, tokensToTransfer);

        emit TokenWithdraw(lootboxId, contractAddress, rarity, amount);
    }

    //Lootbox opening

    function _lootboxOpenInternal(uint256 randomSeed, Lootbox storage lootbox, uint256 lootboxId) internal {
        uint256 chosenRarity = getRandomRarity(randomSeed % 10000, lootbox);
        if (lootbox.rarities[chosenRarity].availableTokens > 0) {
            uint256 chosenToken = (randomSeed %
                lootbox.rarities[chosenRarity].availableTokens) + 1;
            Token storage token = lootboxToRarityToTokenIndexToToken[lootboxId][
                chosenRarity
            ][chosenToken];
            token.amount--;
            transferSelectedToken(token, msg.sender);
            lootIdToRarityToContractToTokenIdToToken[lootboxId][chosenRarity][token.contractAddress][token.tokenId].amount--;
            if(lootIdToRarityToContractToTokenIdToToken[lootboxId][chosenRarity][token.contractAddress][token.tokenId].amount==0) {
                delete lootIdToRarityToContractToTokenIdToToken[lootboxId][chosenRarity][token.contractAddress][token.tokenId];
            }
            emit LootboxOpened(
                msg.sender,
                token.contractAddress,
                token.tokenId,
                lootboxId,
                lootbox.raritiesSummarized[chosenRarity],
                token.amount,
                token.available
            );
            if (token.amount == 0) {
                if (
                    chosenToken !=
                    lootbox.rarities[chosenRarity].availableTokens
                ) {
                    lootboxToRarityToTokenIndexToToken[lootboxId][
                        chosenRarity
                    ][chosenToken] = lootboxToRarityToTokenIndexToToken[
                        lootboxId
                    ][chosenRarity][
                        lootbox.rarities[chosenRarity].availableTokens
                    ];
                }
                delete lootboxToRarityToTokenIndexToToken[lootboxId][chosenRarity][lootbox.rarities[chosenRarity].availableTokens];
                lootbox.rarities[chosenRarity].availableTokens--;
            }
        } else {
            emit LootboxOpened(
                msg.sender,
                address(0),
                0,
                lootboxId,
                0,
                0,
                false
            );
        }
    }

    //Restricted functions
    function changeCreatorFee(uint256 newFee) public {
        require(treasury.isAdmin(msg.sender), "Not admin");
        creationFee = newFee;
    }

    //update fee for opening
    function updateLootboxFee(uint256 _fee) public {
        require(treasury.isAdmin(msg.sender), "Not admin");
        _foundationFee = _fee;
    }

    //Public calls
    
    // function getLootboxOwner(uint256 lootboxId) public view returns (address) {
    //     return lootboxIdToLootbox[lootboxId].seller;
    // }

    // function getLootbox(uint256 lootboxId) public view returns(
    //     string memory, address, uint256, bool, uint256, bool
    // ) {
    //     Lootbox storage lootbox = lootboxIdToLootbox[lootboxId];
    //     return(lootbox.metadata, lootbox.seller, lootbox.price, lootbox.initialized, lootbox.maxPulls, lootbox.isRestricted);
    // }

    function getLootboxStatus(uint256 lootboxId) public view returns (bool) {
        return lootboxIdToLootbox[lootboxId].initialized;
    }

    // function getLootboxIpfs(uint256 lootboxId)
    //     public
    //     view
    //     returns (string memory)
    // {
    //     return lootboxIdToLootbox[lootboxId].metadata;
    // }

}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

/**
 * @notice Attempt to send ETH and if the transfer fails or runs out of gas, store the balance
 * for future withdrawal instead.
 */
abstract contract SendValueWithFallbackWithdraw is ReentrancyGuardUpgradeable {
  using AddressUpgradeable for address payable;

  mapping(address => uint256) private pendingWithdrawals;

  event WithdrawPending(address indexed user, uint256 amount);
  event Withdrawal(address indexed user, uint256 amount);

  /**
   * @notice Returns how much funds are available for manual withdraw due to failed transfers.
   */
  function getPendingWithdrawal(address user) public view returns (uint256) {
    return pendingWithdrawals[user];
  }

  /**
   * @notice Allows a user to manually withdraw funds which originally failed to transfer to themselves.
   */
  function withdraw() public {
    withdrawFor(payable(msg.sender));
  }

  /**
   * @notice Allows anyone to manually trigger a withdrawal of funds which originally failed to transfer for a user.
   */
  function withdrawFor(address payable user) public nonReentrant {
    uint256 amount = pendingWithdrawals[user];
    require(amount > 0, "No funds are pending withdrawal");
    pendingWithdrawals[user] = 0;
    user.sendValue(amount);
    emit Withdrawal(user, amount);
  }

  /**
   * @dev Attempt to send a user ETH with a reasonably low gas limit of 20k,
   * which is enough to send to contracts as well.
   */
  function _sendValueWithFallbackWithdrawWithLowGasLimit(address payable user, uint256 amount) internal {
    _sendValueWithFallbackWithdraw(user, amount, 20000);
  }

  /**
   * @dev Attempt to send a user or contract ETH with a moderate gas limit of 90k,
   * which is enough for a 5-way split.
   */
  function _sendValueWithFallbackWithdrawWithMediumGasLimit(address payable user, uint256 amount) internal {
    _sendValueWithFallbackWithdraw(user, amount, 210000);
  }

  /**
   * @dev Attempt to send a user or contract ETH and if it fails store the amount owned for later withdrawal.
   */
  function _sendValueWithFallbackWithdraw(
    address payable user,
    uint256 amount,
    uint256 gasLimit
  ) private {
    if (amount == 0) {
      return;
    }
    // Cap the gas to prevent consuming all available gas to block a tx from completing successfully
    // solhint-disable-next-line avoid-low-level-calls
    (bool success, ) = user.call{ value: amount, gas: gasLimit }("");
    if (!success) {
      // Record failed sends for a withdrawal later
      // Transfers could fail if sent to a multisig with non-trivial receiver logic
      // solhint-disable-next-line reentrancy
      pendingWithdrawals[user] += amount;
      emit WithdrawPending(user, amount);
    }
  }

  uint256[499] private ______gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract SignatureControl {
    function _toEthSignedMessage(bytes memory message) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(message.length), message));
    }

    function _toAsciiString(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(42);
        s[0] = "0";
        s[1] = "x";
        for (uint256 i = 0; i < 20; i++) {
        bytes1 b = bytes1(uint8(uint256(uint160(x)) / (2**(8 * (19 - i)))));
        bytes1 hi = bytes1(uint8(b) / 16);
        bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
        s[2 * i + 2] = _char(hi);
        s[2 * i + 3] = _char(lo);
        }
        return string(s);
    }

    function _char(bytes1 b) private pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;
import "./base/Lootbox.sol";
import "./base/SignatureControl.sol";

abstract contract LootboxOffchainPRNG is LootboxBase, SignatureControl {
    function OpenLootbox(
        uint256 lootboxId, 
        bytes memory signature, 
        uint256 timestamp,
        uint256 randomSeed
    )
        public
        payable
    {
        Lootbox storage lootbox = lootboxIdToLootbox[lootboxId];
        _checkSignature(signature, timestamp, randomSeed);
        _checkPullValidity(lootboxId, lootbox);
        _distributeFunds(lootbox.seller, msg.value);
        _lootboxOpenInternal(randomSeed, lootbox, lootboxId);
    }

    function OpenLootbox(
        uint256 lootboxId, 
        bytes memory signature, 
        uint256 timestamp,
        uint256 randomSeed,
        address collection,
        uint256 tokenId
    )
        public
        payable
    {
        Lootbox storage lootbox = lootboxIdToLootbox[lootboxId];
        _checkSignature(signature, timestamp, randomSeed);
        _checkPullValidity(lootboxId, lootbox);
        _checkNftWhitelist(lootbox, collection, tokenId);
        _distributeFunds(lootbox.seller, msg.value);
        _lootboxOpenInternal(randomSeed, lootbox, lootboxId);
    }

    function _checkSignature(bytes memory signature, uint256 timestamp, uint256 seed) internal view {
        require(isValidSignature(signature, timestamp, seed), "Invalid signature");
    }

    function isValidSignature(
        bytes memory signature, 
        uint256 timestamp,
        uint256 randomSeed
    ) internal view returns(bool) {
        bytes memory data = abi.encodePacked(
            _toAsciiString(msg.sender),
            " is verified to open lootbox before ",
            Strings.toString(timestamp),
            " with random seed ",
            Strings.toString(randomSeed)
        );
        bytes32 hash = _toEthSignedMessage(data);
        address signer = ECDSA.recover(hash, signature);
        require(treasury.isSuperOperator(signer), "Mint not verified by operator");
        require(block.timestamp <= timestamp, "Outdated signed message");
        return true;
    }
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "./base/Lootbox.sol";

abstract contract LootboxOnchainPRNG is LootboxBase {

    uint256 nonce;

    function getRandomNumber() internal returns (uint256) {
        uint256 randomness = uint256(
            keccak256(
                abi.encodePacked(block.prevrandao, msg.sender, block.timestamp, nonce++)
            )
        );
        return randomness;
    }

    function OpenLootbox(
        uint256 lootboxId
    )
        public
        payable
    {
        Lootbox storage lootbox = lootboxIdToLootbox[lootboxId];

        _checkPullValidity(lootboxId, lootbox);
        _distributeFunds(lootbox.seller, msg.value);

        _lootboxOpenInternal(getRandomNumber(), lootbox, lootboxId);
    }

    function OpenLootbox(
        uint256 lootboxId,
        address collection,
        uint256 tokenId
    )
        public
        payable
    {
        Lootbox storage lootbox = lootboxIdToLootbox[lootboxId];

        _checkPullValidity(lootboxId, lootbox);
        _checkNftWhitelist(lootbox, collection, tokenId);
        _distributeFunds(lootbox.seller, msg.value);

        _lootboxOpenInternal(getRandomNumber(), lootbox, lootboxId);
    }
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;
// pragma experimental ABIEncoderV2;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";

import "./base/Lootbox.sol";

abstract contract LootboxVRF is
    LootboxBase, VRFConsumerBaseV2, ConfirmedOwner
{
    mapping(uint256 => address) private requestIdToRoller;
    mapping(uint256 => uint256) private requestIdToLootboxId;

    //VRF variables
    uint64 s_subscriptionId;

    bytes32 internal keyHash;
    VRFCoordinatorV2Interface COORDINATOR;
    uint32 callbackGasLimit = 1000000;
    uint16 requestConfirmations = 3;
    uint32 numWords = 1;

    event BoxRolled(
        address indexed opener,
        uint256 lootboxId,
        uint256 requestId
    );

    constructor(
        address _COORDINATOR,
        bytes32 _keyHash,
        uint64 subId
    )
        VRFConsumerBaseV2(_COORDINATOR)
        ConfirmedOwner(msg.sender)
    {
        keyHash = _keyHash;
        COORDINATOR = VRFCoordinatorV2Interface(_COORDINATOR);
        s_subscriptionId = subId;
    }

    //VRF
    function OpenLootbox(
        uint256 lootboxId
        )
        public
        payable
        returns (uint256 requestId)
    {
        Lootbox storage lootbox = lootboxIdToLootbox[lootboxId];
        _checkPullValidity(lootboxId, lootbox);

        requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        requestIdToLootboxId[requestId] = lootboxId;
        requestIdToRoller[requestId] = msg.sender;
        _distributeFunds(lootbox.seller, msg.value);
        emit BoxRolled(msg.sender, lootboxId, requestId);
        return requestId;
    }
    //VRF
    function OpenLootbox(
        uint256 lootboxId,
        address collection,
        uint256 tokenId
        )
        public
        payable
        returns (uint256 requestId)
    {
        Lootbox storage lootbox = lootboxIdToLootbox[lootboxId];
        _checkPullValidity(lootboxId, lootbox);
        _checkNftWhitelist(lootbox, collection, tokenId);

        requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        requestIdToLootboxId[requestId] = lootboxId;
        requestIdToRoller[requestId] = msg.sender;
        _distributeFunds(lootbox.seller, msg.value);
        emit BoxRolled(msg.sender, lootboxId, requestId);
        return requestId;
    }

    //VRF callback
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomness)
        internal
        override
    {
        uint256 lootboxId = requestIdToLootboxId[requestId];
        Lootbox storage lootbox = lootboxIdToLootbox[lootboxId];

        _lootboxOpenInternal(randomness[0], lootbox, lootboxId);
    }

}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

import "./LootboxVRF.sol";
import "./LootboxOnchainPRNG.sol";
import "./LootboxOffchainPRNG.sol";

contract TokenLootboxVRF is
    LootboxVRF,
    ERC1155Holder
{
    constructor(
        address Coordinator,
        bytes32 _keyHash,
        address payable treasury,
        uint256 foundationFee,
        uint64 subId
    ) 
        LootboxVRF(Coordinator, _keyHash, subId) 
        LootboxBase(treasury, foundationFee) 
    {
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155Receiver) returns (bool) {
        return interfaceId == type(ERC1155Receiver).interfaceId || 
            super.supportsInterface(interfaceId);
    }
}

contract TokenLootboxOnchainPRNG is
    LootboxOnchainPRNG,
    ERC1155Holder
{
    constructor(
        address payable treasury,
        uint256 foundationFee
    ) LootboxBase(treasury, foundationFee) {
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155Receiver) returns (bool) {
        return interfaceId == type(ERC1155Receiver).interfaceId || 
            super.supportsInterface(interfaceId);
    }
}

contract TokenLootboxOffchainPRNG is
    LootboxOffchainPRNG,
    ERC1155Holder
{
    constructor(
        address payable treasury,
        uint256 foundationFee
    ) LootboxBase(treasury, foundationFee) {
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override( ERC1155Receiver) returns (bool) {
        return interfaceId == type(ERC1155Receiver).interfaceId || 
            super.supportsInterface(interfaceId);
    }

}