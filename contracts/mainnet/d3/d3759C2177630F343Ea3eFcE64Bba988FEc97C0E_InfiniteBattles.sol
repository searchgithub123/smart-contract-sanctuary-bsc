pragma solidity 0.8.5;
//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract InfiniteBattles is Ownable {
    
    using EnumerableSet for EnumerableSet.UintSet;

    struct Block {
        uint256 blockId;
        IERC20 rewardToken;
        uint256 battleStartedBlock;
        uint256 rewards;
        uint256 tokensPerBlock;
        address owner;
        uint256 rewardsCalUntilBlock;
        uint256 lastRewardsBlock;
        uint256 apr;
    }

    struct User {
        uint256 pendingRewards;
        uint256 claimedRewards;
        EnumerableSet.UintSet blockIdsOwn;
    }

    uint256 public battleFee = 420 * 10**18;
    uint256 public battleWinnerPercentageTake = 70; // 70%
    uint256 public boosterPrice = 420 * 10**18;
    uint256 public blockUnclaimableForSeconds = 260; // 260 = 4m20s
    uint256 public treasuryRewards;

    mapping(address => User) users;
    mapping(uint256 => Block) public blocks;
    mapping(address => uint256) public rewardsPerToken;
    uint256 public blockIds;
    IERC20 public blsToken;
    address private backend;

    event EmergencySweepWithdraw(address indexed user, IERC20 indexed token, uint256 amount);
    event BattleInitiated(address indexed user, uint256 indexed blockId, uint256 attackerId);
    event BoosterBought(address indexed user);
    event RewardsClaimed(address indexed user, uint256 amountClaimed);
    event TreasuryRewardsClaimed(address indexed user, uint256 amountClaimed);
    event BlockCreated(uint256 indexed blockId, uint256 amountRewards, uint256 runsForDays, uint256 blockApr);
    event BattleWon(address indexed winnerAddress, uint256 lastBlockReward, uint256 blockApr);

    modifier onlyBackend {
        require(msg.sender == backend);
        _;
    }

    constructor(IERC20 blsToken_) {
        blsToken = IERC20(blsToken_);
    }

    function initiateBattle(uint256 blockId_, uint256 attackerId_) external returns(uint256) {

        require(block.number > blocks[blockId_].battleStartedBlock + (blockUnclaimableForSeconds / 3), "Battle in progress");
        if(blocks[blockId_].lastRewardsBlock != 0){
            require(block.number < blocks[blockId_].lastRewardsBlock - (blockUnclaimableForSeconds / 3), "Too late to claim");
        }
        
        blocks[blockId_].battleStartedBlock = block.number;
        IERC20 rewardToken = blocks[blockId_].rewardToken;
        // transfer battle fee to contract
        rewardToken.transferFrom(msg.sender, address(this), battleFee);
        // get event into that
        emit BattleInitiated(msg.sender, blockId_, attackerId_);
    }

    function battleWinner(uint256 blockId_, address winner_) external onlyBackend {
        
        Block storage currentBlock = blocks[blockId_];
        
        uint256 winnerRewards = battleFee * battleWinnerPercentageTake / 100;
        if(currentBlock.owner != winner_){ // Block owner changes
            
            if(currentBlock.owner == address(0)){
                // this was initial attack, calculate last reward block
                currentBlock.lastRewardsBlock = block.number + currentBlock.rewards / currentBlock.tokensPerBlock;
            }
            // remove block id from this users portfolio
            EnumerableSet.remove(users[currentBlock.owner].blockIdsOwn, blockId_);
            // add block id to new users portfolio
            EnumerableSet.add(users[winner_].blockIdsOwn, blockId_);
            
            //Get winner 70% of BLS rewards
            users[winner_].pendingRewards += winnerRewards;
            // stop rewards distribution to previous block owner
            users[currentBlock.owner].pendingRewards += (block.number - currentBlock.rewardsCalUntilBlock) * currentBlock.tokensPerBlock;
            // change block owner on block itself
            currentBlock.owner = winner_;
            currentBlock.rewardsCalUntilBlock = block.number;
        }else{
            // If defender managed to defend, then remove "block not claimable at the moment" status
            currentBlock.battleStartedBlock = block.number;
            // block owner does not change at all
            users[currentBlock.owner].pendingRewards += winnerRewards;
        }
        treasuryRewards += (battleFee - winnerRewards);
        emit BattleWon(winner_, currentBlock.lastRewardsBlock, currentBlock.apr);
    }

    function amountOfBlocksUserOwns(address user_) view public returns(uint256) {
        return EnumerableSet.length(users[user_].blockIdsOwn);
    }

    function pendingRewards(address user_) view public returns(uint256) {
        EnumerableSet.UintSet storage usersBlocks = users[user_].blockIdsOwn;
        uint256 amountBlocksOwn = EnumerableSet.length(usersBlocks);
        uint256 rewards;
        for(uint256 i = 0; i < amountBlocksOwn; i++){
            uint256 blockId = EnumerableSet.at(usersBlocks, i);
            Block storage blockOwned = blocks[blockId];
            if(blockOwned.lastRewardsBlock > block.number){
                rewards += (block.number - blockOwned.rewardsCalUntilBlock) * blockOwned.tokensPerBlock;
            }else{
                rewards += (blockOwned.lastRewardsBlock - blockOwned.rewardsCalUntilBlock) * blockOwned.tokensPerBlock;
            }
        }
        return rewards + users[user_].pendingRewards - users[user_].claimedRewards;
    }

    function claimRewards() external {

        uint256 amountToClaim = pendingRewards(msg.sender);
        users[msg.sender].claimedRewards += amountToClaim;
        blsToken.transfer( msg.sender, amountToClaim);
        // get event into that
        emit RewardsClaimed(msg.sender, amountToClaim);
    }

    function createBlock(IERC20 rewardToken_, uint256 amountRewards_, uint256 runsForSeconds_) external onlyOwner {

        require(rewardsPerToken[address(rewardToken_)] >= amountRewards_, "Not enough rewards to init block");
        Block memory newBlock;
        newBlock.blockId = blockIds;
        newBlock.rewardToken = rewardToken_;
        newBlock.rewards = amountRewards_;
        newBlock.tokensPerBlock = amountRewards_ / (runsForSeconds_ / 3);
        uint256 runForDays = runsForSeconds_ > 86400 ? (runsForSeconds_ / 86400) : 1;
        uint256 calculatedBlockApr = amountRewards_ * 365 * 100 / runForDays / battleFee;

        newBlock.apr = calculatedBlockApr;
        blocks[blockIds] = newBlock;
        
        emit BlockCreated(blockIds, amountRewards_, runForDays, calculatedBlockApr);
        ++blockIds;
    }

    function depositRewards(IERC20 token, uint256 amountOfTokens) external onlyOwner {
        token.transferFrom(msg.sender, address(this), amountOfTokens);
        rewardsPerToken[address(token)] += amountOfTokens;
    }

    function buyBooster() external {
        blsToken.transferFrom(msg.sender, address(this), boosterPrice);
        emit BoosterBought(msg.sender);
    }

    function setBoosterPrice(uint256 price_) external onlyOwner {
        boosterPrice = price_;
    }
    
    function setBattleInvestmentFee(uint256 battleFee_) external onlyOwner {
        battleFee = battleFee_;
    }

    function setBackendAddress(address backend_) external onlyOwner {
        backend = backend_;
    }
    
    function setBblockUnclaimableForSeconds(uint256 seconds_) external onlyOwner {
        blockUnclaimableForSeconds = seconds_;
    }
    
    function setBattleWinnerPercentageTake(uint256 percentage_) external onlyOwner {
        battleWinnerPercentageTake = percentage_;
    }
    
    function claimTreasuryFees() external onlyOwner {        
        blsToken.transfer(msg.sender, treasuryRewards);
        emit TreasuryRewardsClaimed(msg.sender, treasuryRewards);
        treasuryRewards = 0;
    }

    /// @notice A public function to sweep accidental BEP20 transfers to this contract. Emergency only!
    ///   Tokens are sent to owner
    /// @param token The address of the BEP20 token to sweep
    function sweepToken(IERC20 token) external onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        token.transfer(msg.sender, balance);
        emit EmergencySweepWithdraw(msg.sender, token, balance);
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

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
        mapping(bytes32 => uint256) _indexes;
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

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

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
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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