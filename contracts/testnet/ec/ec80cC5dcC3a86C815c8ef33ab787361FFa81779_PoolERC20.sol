/**
 *Submitted for verification at BscScan.com on 2022-11-12
*/

// Sources flattened with hardhat v2.12.0 https://hardhat.org

// File contracts/IPerpetualStaking.sol

pragma solidity ^0.8.9;

interface IPerpetualStaking {
    function maturityDate() external view returns (uint);
    function cliff() external view returns (uint);
    function getRewardOfToken(address tokenAddress) external view returns (uint);
}


// File @openzeppelin/contracts/utils/[email protected]


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


// File @openzeppelin/contracts/access/[email protected]


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


// File @openzeppelin/contracts/token/ERC20/[email protected]


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


// File @openzeppelin/contracts/security/[email protected]


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}


// File @openzeppelin/contracts/utils/math/[email protected]


// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

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
        return a >= b ? a : b;
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
     * @dev Returns the square root of a number. It the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`.
        // We also know that `k`, the position of the most significant bit, is such that `msb(a) = 2**k`.
        // This gives `2**k < a <= 2**(k+1)` ΓåÆ `2**(k/2) <= sqrt(a) < 2 ** (k/2+1)`.
        // Using an algorithm similar to the msb conmputation, we are able to compute `result = 2**(k/2)` which is a
        // good first aproximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1;
        uint256 x = a;
        if (x >> 128 > 0) {
            x >>= 128;
            result <<= 64;
        }
        if (x >> 64 > 0) {
            x >>= 64;
            result <<= 32;
        }
        if (x >> 32 > 0) {
            x >>= 32;
            result <<= 16;
        }
        if (x >> 16 > 0) {
            x >>= 16;
            result <<= 8;
        }
        if (x >> 8 > 0) {
            x >>= 8;
            result <<= 4;
        }
        if (x >> 4 > 0) {
            x >>= 4;
            result <<= 2;
        }
        if (x >> 2 > 0) {
            result <<= 1;
        }

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
        uint256 result = sqrt(a);
        if (rounding == Rounding.Up && result * result < a) {
            result += 1;
        }
        return result;
    }
}


// File contracts/PoolERC20.sol

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
// import "hardhat/console.sol";

contract PoolERC20 is Ownable, ReentrancyGuard {
    //Pool Maturity date: This is the date on which contract will stop accepting fresh deposits and will also stop accruing the rewards.
    // Can be reinitialised
    uint256 private _maturityDate;

    //Pool Start date: the date from which contract will start to accept the assets
    uint256 private immutable _startDate;

    //Cliff: This is the lock-in period until which deposit assets cannot be withdrawn.
    uint256 private immutable _cliff;

    //PlatformFee: For ERC20, For each deposit, the platform may deduct fees.
    uint256 private _platformFee;

    // Treasury to maintain platform fee
    address private _treasury;

    //Maintain reward for each tokens
    address[] private rewardTokens;

    //Deposit token used to create this contract
    address private _depositToken;

    //Claimed rewards
    mapping(address => uint256) private _claimed;

    struct Deposit {
        uint256 depositBalance;
        uint256 depositTime;
    }

    //Maintain multiple deposits of users
    mapping(address => mapping(uint256 => Deposit)) private userDeposits;

    //Maintain user pool count
    mapping(address => uint256) private userPoolCount;

    mapping(address => uint256) private rewardForDeposit;

    //Withdraw state catch
    event Withdraw(address tokenAddress, uint256 amount);

    // Event to record reinitilaized maturityDate
    event MaturityDate(uint256 updatedMaturityDate);

    // Event to record reinitilized platform fee
    event PlatformFee(uint256 platformFee);

    // Event to record updated reward amount of each token
    event RewardForTokens(uint256[] reward, address[] tokenAddress);

    //Claim state catch
    event Claim(address tokenAddress, uint256 amount);

    // --------- FIX REWARD TOKEN WITH ITS VALUE AS WELL - NO UPDATE -----------//
    constructor(
        address depositToken_,
        uint256 startDate_,
        uint256 maturityDate_,
        uint256 cliff_,
        address owner_,
        address[] memory rewardTokens_,
        uint256[] memory rewardUnits_
    ) {
        _depositToken = depositToken_;

        // Cannot be initialized again.
        // State of this variable remain same across functions
        _startDate = startDate_;
        _maturityDate = maturityDate_;
        _cliff = cliff_;
        updateRewardForToken(rewardUnits_, rewardTokens_);
        transferOwnership(owner_);
    }

    // update reward for tokens
    function updateRewardForToken(
        uint256[] memory newReward,
        address[] memory tokenAddress
    ) internal {
        rewardTokens = tokenAddress;
        for (uint256 i = 0; i < tokenAddress.length; i++) {
            rewardForDeposit[tokenAddress[i]] = newReward[i];
        }
        emit RewardForTokens(newReward, tokenAddress);
    }

    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    modifier isExpired() {
        require(block.timestamp > _startDate);
        require(block.timestamp < maturityDate());
        _;
    }

    function deposit(uint256 amount) external nonReentrant isExpired {
        require(
            IERC20(_depositToken).balanceOf(msg.sender) >= amount,
            "You are not the Owner"
        );
        userPoolCount[msg.sender]++;
        userDeposits[msg.sender][userPoolCount[msg.sender]] = Deposit(
            amount,
            block.timestamp
        );
        IERC20(_depositToken).transferFrom(msg.sender, address(this), amount);
    }

    // -------------------- CLAIM ALL TOKEN REWARD IN ONE GO (NO INPUT) ----------------------------- //
    // -------------------- ONE WITHOUT AMOUNT ----------------------//
    // Function to claim Rewards
    // Reward Can be claimed only after cliff
    function claimWithTokenAndAmount(address tokenAddress, uint256 amount)
        external
    {
        uint256 unclaimed;
        for (uint256 i = 1; i <= userPoolCount[msg.sender]; i++) {
            if (
                _cliff < 0 ||
                block.timestamp >
                userDeposits[msg.sender][i].depositTime + _cliff
            ) {
                unclaimed = getReward(tokenAddress, msg.sender, i);
            }
        }
        // console.log("Unclaimed is %o", unclaimed);
        require(unclaimed >= amount, "Trying to claim more than alloted");
        require(
            IERC20(tokenAddress).balanceOf(address(this)) >= amount,
            "Insufficient reward balance in contract"
        );
        IERC20(tokenAddress).transfer(msg.sender, amount);
        _claimed[tokenAddress] = amount;
        emit Claim(tokenAddress, amount);
    }

    function claimWithToken(address tokenAddress) external {
        uint256 unclaimed;
        for (uint256 i = 1; i <= userPoolCount[msg.sender]; i++) {
            if (
                _cliff < 0 ||
                block.timestamp >
                userDeposits[msg.sender][i].depositTime + _cliff
            ) {
                unclaimed = getReward(tokenAddress, msg.sender, i);
            }
        }
        require(
            IERC20(tokenAddress).balanceOf(address(this)) >= unclaimed,
            "Insufficient reward balance in contract"
        );
        IERC20(tokenAddress).transfer(msg.sender, unclaimed);
        _claimed[tokenAddress] = unclaimed;
        emit Claim(tokenAddress, unclaimed);
    }

    function claim() external {
        uint256 unclaimed;
        for (uint256 i = 1; i <= userPoolCount[msg.sender]; i++) {
            if (
                _cliff < 0 ||
                block.timestamp >
                userDeposits[msg.sender][i].depositTime + _cliff
            ) {
                for (uint256 j = 0; j < rewardTokens.length; j++) {
                    unclaimed = getReward(rewardTokens[j], msg.sender, j);
                    require(
                        IERC20(rewardTokens[j]).balanceOf(address(this)) >=
                            unclaimed,
                        "Insufficient reward balance in contract"
                    );
                    IERC20(rewardTokens[j]).transfer(msg.sender, unclaimed);
                    _claimed[rewardTokens[j]] = unclaimed;
                    emit Claim(rewardTokens[j], unclaimed);
                }
            }
        }
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, maturityDate());
    }

    // BalancetoClaim reward = {((current block - depositblock)*reward count)- claimedrewards}
    function getReward(
        address tokenAddress,
        address user,
        uint256 depositID
    ) public view returns (uint256 lastReward) {
        uint256 rewardCount = getRewardPerUnitOfDeposit(tokenAddress) *
            userDeposits[user][depositID].depositBalance;
        lastReward =
            lastReward +
            (((lastTimeRewardApplicable() -
                userDeposits[user][depositID].depositTime) * rewardCount) -
                _claimed[tokenAddress]);
    }

    // Withdraw deposit amount without reward
    // Withdraw happens only after cliff
    // Reward should be claimed seperately After cliff
    function withdraw(uint256 amount) external {
        uint256 pendingAmount = amount;
        uint256 failedCount;
        for (uint256 i = 1; i <= userPoolCount[msg.sender]; i++) {
            if (failedCount > 0) break;
            // Only after cliff
            if (
                cliff() < 0 || block.timestamp > userDeposits[msg.sender][i].depositTime + _cliff
            ) {
                // console.log("Inside loop is %o", block.timestamp);
                // Commented for unit testing (implement block increase)
                // if first pool has greater amount than required, subract and do nothing
                if (
                    userDeposits[msg.sender][i].depositBalance > 0 &&
                    userDeposits[msg.sender][i].depositBalance > pendingAmount
                ) {
                    IERC20(_depositToken).transfer(msg.sender, pendingAmount);
                    userDeposits[msg.sender][i].depositBalance -= pendingAmount;
                }
                // if first pool has lesser amount, subract the amount and save the remaining amount and delete the first pool
                else {
                    pendingAmount =
                        pendingAmount -
                        userDeposits[msg.sender][i].depositBalance;
                    IERC20(_depositToken).transfer(
                        msg.sender,
                        userDeposits[msg.sender][i].depositBalance
                    );
                    delete userDeposits[msg.sender][i];
                }
                emit Withdraw(_depositToken, amount);
            } else {
                failedCount += 1;
            }
        }
    }

    // ------------ CHECK IF CLIFF IS > 0 GLOBAL IN WITHDRAW AND CLAIM  --done
    // deposit - 3 times
    // 1st - 100
    // 15th - 100 //--------------  TERMINATE THE POOL HERE
    // 29th - 100
    // 31 - ATW - 100  - done

    function getRewardPerUnitOfDeposit(address tokenAddress)
        public
        view
        returns (uint256)
    {
        return rewardForDeposit[tokenAddress];
    }

    // return start date of the pool
    function startDate() public view returns (uint256) {
        return _startDate;
    }

    // return maturity date of the pool
    function maturityDate() public view returns (uint256) {
        return _maturityDate;
    }

    // return cliff of the pool
    function cliff() public view returns (uint256) {
        return _cliff;
    }

    // Reassigning maturity Date
    // checks Ownership and internal call
    function updateMaturityDate(uint256 newMaturityDate) external onlyOwner {
        _updateMaturityDate(newMaturityDate);
    }

    // safe Internal call to update MaturityDate
    function _updateMaturityDate(uint256 maturitydate_) internal {
        _maturityDate = maturitydate_;
        emit MaturityDate(_maturityDate);
    }

    // Reassigning platform Fee
    // checks Ownership and internal call
    function updatePlatformFee(uint256 newPlatformFee) external onlyOwner {
        _updatePlatformFee(newPlatformFee);
    }

    // safe Internal call to update MaturityDate
    function _updatePlatformFee(uint256 platformFee_) internal {
        _platformFee = platformFee_;
        emit PlatformFee(_platformFee);
    }

    function updateTreasuryContract(address _treasuryContract)
        external
        onlyOwner
    {
        require(isContract(_treasuryContract), "Address is not a contract");
        _treasury = _treasuryContract;
    }

    function treasuryContract() public view returns (address) {
        return _treasury;
    }

    function depositToken() public view returns (address) {
        return _depositToken;
    }

    function claimed(address tokenAddress) public view returns (uint256) {
        return _claimed[tokenAddress];
    }

    function userDeposit(address userAddress, uint256 poolCount)
        public
        view
        returns (Deposit memory depositdetails)
    {
        return userDeposits[userAddress][poolCount];
    }

    function userDepositCount(address userAddress)
        public
        view
        returns (uint256)
    {
        return userPoolCount[userAddress];
    }
}