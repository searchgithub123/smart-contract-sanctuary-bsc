/**
 *Submitted for verification at BscScan.com on 2023-03-02
*/

// SPDX-License-Identifier: MIT
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


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// File: @openzeppelin/contracts/security/Pausable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
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
}

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// File: @chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol


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

// File: @chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol


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

// File: contracts/ForgottenChroniclesTablePool.sol


pragma solidity ^0.8.17;








contract ForgottenChroniclesTablePool is
    VRFConsumerBaseV2,
    Pausable,
    Ownable,
    ReentrancyGuard
{
    IERC20 FTCtoken;
    VRFCoordinatorV2Interface COORDINATOR;

    uint64 s_subscriptionId;
    //mainnet
    // address vrfCoordinator = 0xc587d9053cd1118f25F645F9E08BB98c9712A4EE;
    // bytes32 keyHash =
    //     0x114f3da0a805b6a67d6e9cd2ec746f7028f1b7376365af575cfea3550dd1aa04;

    //testnet
    address vrfCoordinator = 0x6A2AAd07396B36Fe02a22b33cf443582f682c82f;
    bytes32 keyHash =
        0xd4bb89654db74673a187bd804519e65e3f71a52bc55f11da7601a13dcf505314;


    // Depends on the number of requested values that you want sent to the
    // fulfillRandomWords() function. Storing each word costs about 20,000 gas,
    // so 100,000 is a safe default for this example contract. Test and adjust
    // this limit based on the network that you select, the size of the request,
    // and the processing of the callback request in the fulfillRandomWords()
    // function.
    uint32 callbackGasLimit = 2500000;

    // The default is 3, but you can set this higher.
    uint16 requestConfirmations = 3;

    // Retrieve 100 random values in one request.
    // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
    uint32 numWords = 100;
    uint256 private randomIndex = 0;

    uint256[] private s_randomWords;
    uint256 private s_requestId;

    uint256 private RANGE_DIVIDER = 99999; //so we can have percentage like 0.01
    address payable private factoryBeneficiary;
    mapping(address => bool) private approvedContracts;

    Range[] public ranges;
    struct Range {
        uint256 FTC_minRange;
        uint256 FTC_maxRange;
        uint256 BNB_minRange;
        uint256 BNB_maxRange;
    }

    struct TableNFTDetail {
        address addr;
        uint256 winPerc;
        uint256 tableOwnerPerc;
        uint256 gamePerc;

    }
    struct Table {
        uint256 tableId;
        uint256 rarity;
        uint256 usedCount;
    }

    //paid:
    // 0 not paid
    // 1 paid
    // 2 initiated increase stake and not accepted -> for refund
    struct PlayingUser {
        address player;
        uint256 paid;
        uint256 FTC_refund;
        uint256 BNB_refund;
    }

    // Struct representing a game match
    struct GameMatch {
        string gameId;
        PlayingUser player1;
        PlayingUser player2;
        uint256 FTC_stake;
        uint256 BNB_stake;
        uint256 startTime;
        Table table;
        address winner;
    }

    struct InitGame {
        string gameId;
        address player1;
        address player2;
        uint256 FTC_stake;
        uint256 BNB_stake;
    }

    mapping(string => InitGame) public CheckLock;
    mapping(uint256 => uint256) public averageUsedByRarity;

    mapping(uint256 => Table[]) public tablesByRarity;
    mapping(uint256 => TableNFTDetail) public tablesContractsByRarity;
    mapping(string => GameMatch) public Matches;

    //TODO: make all private
    mapping(uint256 => string) public GameIDs;
    mapping(string => uint256) public GameMatchTimestamp;
    uint256 public GameIDs_size;

    //uint256 constant private MAX_INT = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    event PlayerRandomNumber(address player, uint256 randomNumber);
    event RequestNewRandomList(address player);

    event MatchRefunded(string gameId, uint256 tableID, address tableContract, uint256 refundTime);

    event SendStakeReward(string gameId, uint256 rarity, uint256 tableID, address tableContract, address tableOwner, address winner, 
                            address companyAddress, uint256 FTC_stake, uint256 BNB_stake, uint256 time);

    event MatchCreated(address user, string gameId, uint256 rarity, uint256 FTC_stake, uint256 BNB_stake, uint256 time);

    constructor(uint64 subscriptionId, 
                address payable _beneficiary, 
                IERC20 _FTCtoken)
        VRFConsumerBaseV2(vrfCoordinator)
    {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        s_subscriptionId = subscriptionId;
        factoryBeneficiary = _beneficiary;
        FTCtoken = _FTCtoken;
    }

    function transferBNB(address to, uint256 amount) internal {
        (bool success, ) = payable(to).call{
            value: amount,
            gas: 3000000
        }("");
    }

    function transferFTC(address to, uint256 amount) internal {
        IERC20(FTCtoken).transfer(to, amount);
    }

    function CheckRefundTablesUser(address userAddr) external nonReentrant {
        uint256 i = 0;
        while(true) {
            if(i >= GameIDs_size) {
                return;
            }

            //1 hour + 5 minutes for players payment and connection
            if(Matches[GameIDs[i]].startTime + 65 minutes <= block.timestamp && Matches[GameIDs[i]].winner == address(0)) {

                CheckSendRefundFTC(Matches[GameIDs[i]].player1.FTC_refund, Matches[GameIDs[i]].player1.player);
                CheckSendRefundFTC(Matches[GameIDs[i]].player2.FTC_refund, Matches[GameIDs[i]].player2.player);
                CheckSendRefundBNB(Matches[GameIDs[i]].player1.BNB_refund, Matches[GameIDs[i]].player1.player);
                CheckSendRefundBNB(Matches[GameIDs[i]].player2.BNB_refund, Matches[GameIDs[i]].player2.player);

                if(Matches[GameIDs[i]].FTC_stake > 0) {
                    if(userAddr == Matches[GameIDs[i]].player1.player && Matches[GameIDs[i]].player1.paid > 1) {
                        transferFTC(Matches[GameIDs[i]].player1.player, Matches[GameIDs[i]].FTC_stake / 2);
                    }
                    if(userAddr == Matches[GameIDs[i]].player1.player && Matches[GameIDs[i]].player2.paid > 1) {
                       transferFTC(Matches[GameIDs[i]].player2.player, Matches[GameIDs[i]].FTC_stake / 2); 
                    }
                }

                if(Matches[GameIDs[i]].BNB_stake > 0) {
                    if(userAddr == Matches[GameIDs[i]].player1.player && Matches[GameIDs[i]].player1.paid == 1) {
                        transferBNB(Matches[GameIDs[i]].player1.player, Matches[GameIDs[i]].BNB_stake / 2);  
                    }
                    if(userAddr == Matches[GameIDs[i]].player1.player && Matches[GameIDs[i]].player2.paid == 1) {
                        transferBNB(Matches[GameIDs[i]].player2.player, Matches[GameIDs[i]].BNB_stake / 2);
                    }
                }

                emit MatchRefunded(GameIDs[i], Matches[GameIDs[i]].table.tableId, tablesContractsByRarity[Matches[GameIDs[i]].table.rarity].addr, block.timestamp);

                AddTableToPool(Matches[GameIDs[i]].table);
                
                delete GameMatchTimestamp[GameIDs[i]]; // = MAX_INT; //already used
                GameMatchTimestamp[GameIDs[GameIDs_size - 1]] = i;

                delete Matches[GameIDs[i]];
                delete CheckLock[GameIDs[i]];

                GameIDs[i] = GameIDs[GameIDs_size - 1];
                delete GameIDs[GameIDs_size - 1];

                GameIDs_size --;
            } else {
                i++;
            }
        }
    }

    function CheckRefundTables() external nonReentrant {
        uint256 i = 0;
        while(true) {
            if(i >= GameIDs_size) {
                return;
            }

            //1 hour + 5 minutes for players payment and connection
            if(Matches[GameIDs[i]].startTime + 1 minutes <= block.timestamp && Matches[GameIDs[i]].winner == address(0)) {

                CheckSendRefundFTC(Matches[GameIDs[i]].player1.FTC_refund, Matches[GameIDs[i]].player1.player);
                CheckSendRefundFTC(Matches[GameIDs[i]].player2.FTC_refund, Matches[GameIDs[i]].player2.player);
                CheckSendRefundBNB(Matches[GameIDs[i]].player1.BNB_refund, Matches[GameIDs[i]].player1.player);
                CheckSendRefundBNB(Matches[GameIDs[i]].player2.BNB_refund, Matches[GameIDs[i]].player2.player);

                if(Matches[GameIDs[i]].FTC_stake > 0) {
                    if(Matches[GameIDs[i]].player1.paid == 1) {
                        transferFTC(Matches[GameIDs[i]].player1.player, Matches[GameIDs[i]].FTC_stake / 2);
                    }
                    if(Matches[GameIDs[i]].player2.paid == 1) {
                        transferFTC(Matches[GameIDs[i]].player2.player, Matches[GameIDs[i]].FTC_stake / 2);
                    }
                }

                if(Matches[GameIDs[i]].BNB_stake > 0) {
                    if(Matches[GameIDs[i]].player1.paid == 1) {
                        transferBNB(Matches[GameIDs[i]].player1.player, Matches[GameIDs[i]].BNB_stake / 2);
                        if(Matches[GameIDs[i]].player1.FTC_refund > 0) {
                            transferFTC(Matches[GameIDs[i]].player1.player, Matches[GameIDs[i]].player1.FTC_refund);
                        }
                    }
                    if(Matches[GameIDs[i]].player2.paid == 1) {
                        transferBNB(Matches[GameIDs[i]].player2.player, Matches[GameIDs[i]].BNB_stake / 2);
                    }
                }

                emit MatchRefunded(GameIDs[i], Matches[GameIDs[i]].table.tableId, tablesContractsByRarity[Matches[GameIDs[i]].table.rarity].addr, block.timestamp);

                AddTableToPool(Matches[GameIDs[i]].table);
                
                delete GameMatchTimestamp[GameIDs[i]]; // = MAX_INT; //already used
                GameMatchTimestamp[GameIDs[GameIDs_size - 1]] = i;

                delete Matches[GameIDs[i]];
                delete CheckLock[GameIDs[i]];

                GameIDs[i] = GameIDs[GameIDs_size - 1];
                delete GameIDs[GameIDs_size - 1];

                GameIDs_size --;
            } else {
                i++;
            }
        }
    }

    function AddTableToPoolOwner(Table[] calldata tables) external ownerOrApprovedByOwner {
        for(uint256 i = 0; i < tables.length; i++) {
            tablesByRarity[tables[i].rarity].push(tables[i]);
            averageUsedByRarity[tables[i].rarity] = (averageUsedByRarity[tables[i].rarity] * (tablesByRarity[tables[i].rarity].length - 1) + (tablesByRarity[tables[i].rarity][i].usedCount * 1e18)) / tablesByRarity[tables[i].rarity].length;
        }
    }

    function RemoveTableFromPoolOwner(uint256 _rarity, uint256 tableId) external ownerOrApprovedByOwner {
        //game should be paused and no match playing?
        for(uint256 i = 0; i < tablesByRarity[_rarity].length; i ++) {
            if(tablesByRarity[_rarity][i].tableId == tableId) {
                averageUsedByRarity[_rarity] = (averageUsedByRarity[_rarity] * tablesByRarity[_rarity].length - (tablesByRarity[_rarity][i].usedCount * 1e18)) / (tablesByRarity[_rarity].length - 1);
                tablesByRarity[_rarity][i] = tablesByRarity[_rarity][tablesByRarity[_rarity].length - 1];
                tablesByRarity[_rarity].pop();
                return;
            }
        }
    }

    function AddTableToPool(Table memory table) internal {
        tablesByRarity[table.rarity].push(table);
        averageUsedByRarity[table.rarity] = (averageUsedByRarity[table.rarity] * (tablesByRarity[table.rarity].length - 1) + (table.usedCount * 1e18)) / tablesByRarity[table.rarity].length;
    }

    function RemoveTableFromPool(uint256 _rarity, uint256 _position) internal {
        averageUsedByRarity[_rarity] = (averageUsedByRarity[_rarity] * tablesByRarity[_rarity].length - (tablesByRarity[_rarity][_position].usedCount * 1e18)) / (tablesByRarity[_rarity].length - 1);
        tablesByRarity[_rarity][_position] = tablesByRarity[_rarity][tablesByRarity[_rarity].length - 1];
        tablesByRarity[_rarity].pop();
    }

    //use chainlink VRF
    function GetTableIdByRarity(uint256 stake, bool b_FTC_game) internal returns (Table memory, uint256) {

        uint256 randomNumber = getRandom();
        emit PlayerRandomNumber(msg.sender, randomNumber);

        //always send with 99 with we want random rarity
        uint256 _rarity = b_FTC_game ? returnRarityIndexFromStakeFTC(stake) : returnRarityIndexFromStakeBNB(stake);
        require(_rarity != 99, "invalid rarity");

        //no tables available for _rarity. then try rarities from legendary to common
        if(tablesByRarity[_rarity].length == 0) {
            _rarity = 4;
            while(true) {
                if(tablesByRarity[_rarity].length == 0) {
                    if(_rarity == 0) {
                        return (Table(0, 99, 0), 0);
                    }
                    _rarity --;
                } else {
                    break;
                }
            }
        }

        uint256 index = randomNumber % tablesByRarity[_rarity].length;
        if(tablesByRarity[_rarity][index].usedCount * 1e18 > averageUsedByRarity[_rarity] + 5e16) {
            for(uint256 i = 0; i < tablesByRarity[_rarity].length; i ++) {
                if(tablesByRarity[_rarity][i].usedCount * 1e18 <= averageUsedByRarity[_rarity] + 5e16) {
                    index = i;
                    break;
                }
            }
        }

        return (tablesByRarity[_rarity][index], index);
    }

    //FTC_OR_BNB (true means FTC, false BNB)
    function InitCreate(string memory _gameID, address _player1, address _player2, uint256 _stakeFTC, uint256 _stakeBNB) external ownerOrApprovedByOwner nonReentrant {
       require(CheckLock[_gameID].player1 == address(0), "already inited");
        //_gameID  position in Checklock array is the same as  
        CheckLock[_gameID] = InitGame(_gameID, _player1, _player2, _stakeFTC, _stakeBNB);
    }

    // Create a new game match
    function JoinMatch(string memory _gameID) external payable nonReentrant {
        require(CheckLock[_gameID].FTC_stake != 0 || CheckLock[_gameID].BNB_stake != 0, "not inited ");
        require(msg.sender == CheckLock[_gameID].player1 || msg.sender == CheckLock[_gameID].player2, "Not expected");

        bool b_FTC_game = CheckLock[_gameID].FTC_stake != 0;
        uint256 stake = b_FTC_game ? CheckLock[_gameID].FTC_stake : CheckLock[_gameID].BNB_stake;

        if(Matches[_gameID].FTC_stake == 0 && Matches[_gameID].BNB_stake == 0) // "Match already exists");)
        {
            (Table memory t, uint256 pos) = GetTableIdByRarity(stake, b_FTC_game);
            require(t.rarity != 99, "no table");

            Matches[_gameID] = GameMatch({
                gameId: _gameID,
                player1: PlayingUser(CheckLock[_gameID].player1, 0, 0, 0),
                player2: PlayingUser(CheckLock[_gameID].player2, 0, 0, 0),
                FTC_stake: CheckLock[_gameID].FTC_stake,
                BNB_stake: CheckLock[_gameID].BNB_stake,
                startTime: block.timestamp,
                table: t,
                winner: address(0)
            });
            // Create new match
            GameIDs[GameIDs_size] = _gameID;
            GameMatchTimestamp[_gameID] = GameIDs_size;
            GameIDs_size ++;

            RemoveTableFromPool(Matches[_gameID].table.rarity, pos);

            emit MatchCreated(msg.sender, _gameID, t.rarity, CheckLock[_gameID].FTC_stake, CheckLock[_gameID].BNB_stake, block.timestamp);
        }

        if(b_FTC_game) {
            require(IERC20(FTCtoken).allowance(msg.sender, address(this)) >= Matches[_gameID].FTC_stake / 2, "Low allowance");
            require(IERC20(FTCtoken).balanceOf(msg.sender) >= Matches[_gameID].FTC_stake / 2, "Low FTC");
            require(IERC20(FTCtoken).transferFrom(msg.sender, address(this), Matches[_gameID].FTC_stake / 2), "Fail send FTC");
        } else {
            require(msg.value >= Matches[_gameID].BNB_stake / 2, "Fail send BNB");
        }

        if (msg.sender == Matches[_gameID].player1.player) {
            require(Matches[_gameID].player1.paid == 0, "User1 paid");
            Matches[_gameID].player1.paid = 1;
        } else if (msg.sender == Matches[_gameID].player2.player) {
            require(Matches[_gameID].player2.paid == 0, "User2 paid");
            Matches[_gameID].player2.paid = 1;
        }
    }

    function InitIncrementStake(string calldata gameID, uint256 stake, bool b_FTC_game) external payable nonReentrant {
        require(msg.sender == Matches[gameID].player1.player || msg.sender == Matches[gameID].player2.player, "Not expected");
        require(Matches[gameID].player1.paid == 1 && Matches[gameID].player2.paid == 1, "Not ready");


        if(b_FTC_game) {
            require(IERC20(FTCtoken).allowance(msg.sender, address(this)) >= stake, "Low allowance");
            require(IERC20(FTCtoken).balanceOf(msg.sender) >= stake, "Low FTC");
            require(IERC20(FTCtoken).transferFrom(msg.sender, address(this), stake), "Fail send FTC");
        } else {
            require(msg.value >= stake, "Low BNB");
        }
        
        if (msg.sender == Matches[gameID].player1.player) {
            require(Matches[gameID].player1.paid == 1, "User1 init");
            Matches[gameID].player1.paid = 2;
            if(b_FTC_game) {
                Matches[gameID].player1.FTC_refund = stake;
            } else {
                Matches[gameID].player1.BNB_refund = stake;
            }
        } else if (msg.sender == Matches[gameID].player2.player) {
            require(Matches[gameID].player2.paid == 1, "User2 init");
            Matches[gameID].player2.paid = 2;
            if(b_FTC_game) {
                Matches[gameID].player2.FTC_refund = stake;
            } else {
                Matches[gameID].player2.BNB_refund = stake;
            }
        }
    }

    function AcceptIncrementStake(string calldata gameID) external payable nonReentrant {
        require(msg.sender == Matches[gameID].player1.player || msg.sender == Matches[gameID].player2.player, "Not expected");

        bool b_FTC_game = true;
        if(Matches[gameID].player1.BNB_refund > 0 || Matches[gameID].player2.BNB_refund > 0){
            b_FTC_game = false;
        }

        uint256 stake = 0;
        if(Matches[gameID].player1.paid == 2) {
            stake = b_FTC_game ? Matches[gameID].player1.FTC_refund : Matches[gameID].player1.BNB_refund;
        } else if (Matches[gameID].player2.paid == 2) {
            stake = b_FTC_game ? Matches[gameID].player2.FTC_refund : Matches[gameID].player2.BNB_refund;
        }

        //require(Matches[gameID].player1.paid && Matches[gameID].player2.paid, "Match not started");

        if(b_FTC_game) {
            require(IERC20(FTCtoken).allowance(msg.sender, address(this)) >= stake, "Low allowance");
            require(IERC20(FTCtoken).balanceOf(msg.sender) >= stake, "Low FTC");
            require(IERC20(FTCtoken).transferFrom(msg.sender, address(this), stake), "Fail send FTC");
        } else {
            require(msg.value >= stake, "Low BNB");
        }

        if (msg.sender == Matches[gameID].player1.player) {
            require(Matches[gameID].player1.paid == 1 && Matches[gameID].player2.paid == 2, "User1 init");
            Matches[gameID].player2.paid = 1;
            if(b_FTC_game) {
                Matches[gameID].player2.FTC_refund = 0;
            } else {
                Matches[gameID].player2.BNB_refund = 0;
            }
        } else if (msg.sender == Matches[gameID].player2.player) {
            require(Matches[gameID].player2.paid == 1 && Matches[gameID].player1.paid == 2, "User2 init");
            Matches[gameID].player1.paid = 1;
            if(b_FTC_game) {
                Matches[gameID].player1.FTC_refund = 0;
            } else {
                Matches[gameID].player1.BNB_refund = 0;
            }
        }
        //means both agreed so increment match stake
        if(b_FTC_game) {
            Matches[gameID].FTC_stake += stake;
        } else if(b_FTC_game) {
            Matches[gameID].BNB_stake += stake;
        }
    }

    function EndMatch(string memory _gameId, address _winner) external ownerOrApprovedByOwner nonReentrant {
        require(Matches[_gameId].player1.paid > 0 && Matches[_gameId].player2.paid > 0, "Not paid");

        Matches[_gameId].winner = _winner;
    }

    function ClaimMatchWin(string memory _gameId) external nonReentrant {
        require(Matches[_gameId].winner != address(0), "adr(0)");
        require(msg.sender == Matches[_gameId].winner, "Not winner");
        require(Matches[_gameId].player1.paid > 0 && Matches[_gameId].player2.paid > 0, "Not paid");

        address _winner = Matches[_gameId].winner;

        uint256 FTC_stake = Matches[_gameId].FTC_stake;
        uint256 BNB_stake = Matches[_gameId].BNB_stake;
        uint256 tableId = Matches[_gameId].table.tableId;
        uint256 rarity = Matches[_gameId].table.rarity;
        Matches[_gameId].table.usedCount++;

        AddTableToPool(Matches[_gameId].table);
        //averageUsedByRarity[rarity] = (averageUsedByRarity[rarity] + 1) / tablesByRarity[rarity].length;
        averageUsedByRarity[rarity] = (averageUsedByRarity[rarity] + 1) / 2;

        //TODO: test with only 5 tables to see average for each

        address owner = IERC721(tablesContractsByRarity[rarity].addr).ownerOf(tableId);

        CheckSendRefundFTC(Matches[_gameId].player1.FTC_refund, Matches[_gameId].player1.player);
        CheckSendRefundFTC(Matches[_gameId].player2.FTC_refund, Matches[_gameId].player2.player);
        CheckSendRefundBNB(Matches[_gameId].player1.BNB_refund, Matches[_gameId].player1.player);
        CheckSendRefundBNB(Matches[_gameId].player2.BNB_refund, Matches[_gameId].player2.player);

        if(Matches[_gameId].FTC_stake > 0) {
            uint256 winnerShare = (tablesContractsByRarity[rarity].winPerc * FTC_stake) / 100;
            uint256 tableOwnerShare = (tablesContractsByRarity[rarity].tableOwnerPerc * FTC_stake) / 100;
            uint256 companyShare = (tablesContractsByRarity[rarity].gamePerc * FTC_stake) / 100;

            transferFTC(_winner, winnerShare);
            transferFTC(owner, tableOwnerShare);
            transferFTC(factoryBeneficiary, companyShare);
        }
        if(Matches[_gameId].BNB_stake > 0) {
            uint256 winnerShare = (tablesContractsByRarity[rarity].winPerc * BNB_stake) / 100;
            uint256 tableOwnerShare = (tablesContractsByRarity[rarity].tableOwnerPerc * BNB_stake) / 100;
            uint256 companyShare = (tablesContractsByRarity[rarity].gamePerc * BNB_stake) / 100;

            transferBNB(_winner, winnerShare);
            transferBNB(owner, tableOwnerShare);
            transferBNB(factoryBeneficiary, companyShare);
        }

        emit SendStakeReward(_gameId, rarity, tableId, tablesContractsByRarity[rarity].addr, owner, _winner, factoryBeneficiary, FTC_stake, BNB_stake, block.timestamp);

        uint256 idx_GameID = GameMatchTimestamp[_gameId];
        // if(idx_GameID != MAX_INT) {

        GameIDs[idx_GameID] = GameIDs[GameIDs_size - 1];

        delete GameIDs[GameIDs_size - 1];
        GameIDs_size --;

        delete GameMatchTimestamp[_gameId];// = MAX_INT; //already used
        // }
        delete Matches[_gameId];
        delete CheckLock[_gameId];

    }

    function CheckSendRefundFTC(uint256 refund, address player) internal {
        if(refund > 0) {
            transferFTC(player, refund);
        }
    }


    function CheckSendRefundBNB(uint256 refund, address player) internal {
        if(refund > 0) {
            transferBNB(player, refund);
        }
    }

    /**
     * @dev Pause crowdsale only by owner
     */
    function pause() external ownerOrApprovedByOwner {
        _pause();
    }

    /**
     * @dev Unpause crowdsale only by owner
     */
    function unpause() external ownerOrApprovedByOwner {
        _unpause();
    }

    /**
     * @dev _approvedRemoveContracts `to` to false
     *
     */
    function _approvedRemoveContracts(address to) external onlyOwner {
        approvedContracts[to] = false;
    }

    /**
     * @dev approvedContracts `to` to true
     *
     */
    function _approvedContracts(address to) external onlyOwner {
        approvedContracts[to] = true;
    }

    /**
     * @dev _getApprovedContracts
     *
     */
    function _getApprovedContracts(address to) public view returns (bool) {
        return approvedContracts[to];
    }

    function _ownerOrApprovedByOwner() private view
    {
        require(
            msg.sender == owner() || _getApprovedContracts(msg.sender),
            "Not approved"
        );
    }

    modifier ownerOrApprovedByOwner() {
        _ownerOrApprovedByOwner();
        _;
    }

    function setBeneficiaryAddress(address payable _factoryBeneficiary)
        external
        onlyOwner
    {
        factoryBeneficiary = _factoryBeneficiary;
    }

    function _setTableContractAddress(TableNFTDetail[] calldata tables, uint256[] calldata rarities)
        external
        ownerOrApprovedByOwner
    {
        for(uint256 i = 0; i < tables.length; i++) {
            tablesContractsByRarity[rarities[i]] = tables[i];
        }
    }

    function forwardFunds() external ownerOrApprovedByOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = payable(factoryBeneficiary).call{
            value: balance,
            gas: 3000000
        }("");
    }

    function forwardFTCFunds() external ownerOrApprovedByOwner {
        uint256 balance = IERC20(FTCtoken).balanceOf(address(this));
        IERC20(FTCtoken).transferFrom(msg.sender, address(this), balance);
    }

    function requestRandomWordsFGC() public ownerOrApprovedByOwner {
        s_requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
    }

    function fulfillRandomWords(
        uint256, /* requestId */
        uint256[] memory randomWords
    ) internal override {
        s_randomWords = randomWords;
    }

    function getRandom() internal returns (uint256) {
        uint256 randomNumber = 0;
        randomNumber = s_randomWords[randomIndex];
        randomIndex ++;
        
        if(randomIndex >= numWords) {
            randomIndex = 0;

            approvedContracts[msg.sender] = true;
            requestRandomWordsFGC();
            approvedContracts[msg.sender] = false;
            emit RequestNewRandomList(msg.sender);

        }
        return randomNumber;
    }

    function setRandomIndex(uint256 _randomIndex)
        external
        ownerOrApprovedByOwner
    {
        randomIndex = _randomIndex;
    }

    //NFT region
    function returnRarityIndexFromStakeFTC(uint256 stake)
        internal
        view
        returns (uint256)
    {
        for(uint256 i = 0; i < ranges.length; i ++) {
            if(stake <= ranges[i].FTC_maxRange) {
                if(stake >= ranges[i].FTC_minRange) {
                    return i;
                }
            }
        }
        return 99;
    }

    //NFT region
    function returnRarityIndexFromStakeBNB(uint256 stake)
        internal
        view
        returns (uint256)
    {
        for(uint256 i = 0; i < ranges.length; i ++) {
            if(stake <= ranges[i].BNB_maxRange) {
                if(stake >= ranges[i].BNB_minRange) {
                    return i;
                }
            }
        }
        return 99;
    }

    function _initRanges(Range[] calldata _range) external ownerOrApprovedByOwner {
        for(uint256 i = 0; i < _range.length; i++) {
            ranges.push(_range[i]);
        }
    }

    function _removeRanges() external ownerOrApprovedByOwner {
        uint256 count = ranges.length;
        for(uint256 i = 0; i < count; i++) {
            ranges.pop();
        }
    }
}