// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract LinearVesting is ReentrancyGuard {
    using SafeMath for uint256;

    /// @notice event emitted when a vesting schedule is created
    event ScheduleCreated(
        address indexed _beneficiary,
        uint256 indexed _amount
    );

    /// @notice event emitted when a successful drawn down of vesting fkdTokens is made
    event DrawDown(address indexed _beneficiary, uint256 indexed _amount);

    /// @notice start of vesting period as a timestamp
    uint256 public start;

    /// @notice end of vesting period as a timestamp
    uint256 public end;

    /// @notice cliff duration in seconds
    uint256 public cliffDuration;

    /// @notice amount vested for a beneficiary. Note beneficiary address can not be reused
    mapping(address => uint256) public vestedAmount;

    /// @notice cumulative total of fkdTokens drawn down (and transferred from this vesting contract) per beneficiary
    mapping(address => uint256) public totalDrawn;

    /// @notice last drawn down time (seconds) per beneficiary
    mapping(address => uint256) public lastDrawnAt;

    /// @notice ERC20 fkdToken we are vesting
    IERC20 public fkdToken = IERC20(0x9FeF1Efe8EFa3bdc1826174be54c177982491c25);

    address public crowdsaleContract;

    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not Owner");
        _;
    }

    function transferOwnership(address _newOwner) external onlyOwner {
        owner = _newOwner;
    }

    /**
     * @notice Construct a new vesting contract
     * @param _start start timestamp
     * @param _vestingTime total time for token vesting
     * @param _cliffDurationInSecs cliff duration in seconds
     * @dev caller on constructor set as owner; this can not be changed
     */
    constructor(
        uint256 _start,
        uint256 _vestingTime,
        uint256 _cliffDurationInSecs
    ) {
        start = _start;
        end = _start.add(_vestingTime);
        cliffDuration = _cliffDurationInSecs;
        owner = msg.sender;
    }

    function setCrowdaleContract(address _crowdsaleContract)
        external
        onlyOwner
    {
        crowdsaleContract = _crowdsaleContract;
    }

    /**
     * @notice Vesting schedule and associated data for a beneficiary
     * @dev Must be called directly by the beneficiary assigned the fkdTokens in the schedule
     * @return _amount
     * @return _totalDrawn
     * @return _lastDrawnAt
     * @return _remainingBalance
     */
    function vestingScheduleForBeneficiary(address _beneficiary)
        public
        view
        returns (
            uint256 _amount,
            uint256 _totalDrawn,
            uint256 _lastDrawnAt,
            uint256 _remainingBalance
        )
    {
        return (
            vestedAmount[_beneficiary],
            totalDrawn[_beneficiary],
            lastDrawnAt[_beneficiary],
            vestedAmount[_beneficiary].sub(totalDrawn[_beneficiary]) //fkdTokens still due (and currently locked) from vesting schedule
        );
    }

    /**
     * @notice Draw down amount currently available (based on the block timestamp)
     * @param _beneficiary beneficiary of the vested fkdTokens
     * @return _amount fkdTokens due from vesting schedule
     */
    function availableDrawDownAmount(address _beneficiary)
        public
        view
        returns (uint256 _amount)
    {
        return _availableDrawDownAmount(_beneficiary);
    }

    function rescueFunds(address _fkdToken) external onlyOwner {
        uint256 balance = IERC20(_fkdToken).balanceOf(address(this));
        require(balance > 0, "Insufficient fkdToken balance");
        IERC20(_fkdToken).transfer(owner, balance);
    }

    /**
     * @notice Create a new vesting schedule
     * @dev should only be invoked via contract Owner
     * @notice A transfer is used to bring fkdTokens into this Contract so pre-approval is required
     * @param _beneficiary beneficiary of the vested fkdTokens
     * @param _amount amount of fkdTokens (in wei)
     */
    function createVestingSchedule(address _beneficiary, uint256 _amount)
        external
    {
        require(msg.sender == crowdsaleContract, "Not crowdsale contract");
        require(_beneficiary != address(0), "Beneficiary cannot be empty");
        require(_amount > 0, "Amount cannot be empty");

        vestedAmount[_beneficiary] += _amount;

        // Vest the fkdTokens into this vesting contract and delegate to the beneficiary
        require(
            fkdToken.transferFrom(msg.sender, address(this), _amount),
            "Unable to escrow fkdTokens"
        );

        emit ScheduleCreated(_beneficiary, _amount);
    }

    /**
     * @notice Draws down any vested fkdTokens due
     * @dev Must be called directly by the beneficiary assigned the fkdTokens in the schedule
     */
    function drawDown() external nonReentrant {
        address _beneficiary = msg.sender;
        require(
            vestedAmount[_beneficiary] > 0,
            "There is no schedule currently in flight"
        );

        uint256 amount = _availableDrawDownAmount(_beneficiary);
        require(amount > 0, "No allowance left to withdraw");

        // Update last drawn to now
        lastDrawnAt[_beneficiary] = _getNow();

        // Increase total drawn amount
        totalDrawn[_beneficiary] = totalDrawn[_beneficiary].add(amount);

        // Safety measure - this should never trigger
        assert(totalDrawn[_beneficiary] <= vestedAmount[_beneficiary]);

        // Issue fkdTokens to beneficiary
        require(
            fkdToken.transfer(_beneficiary, amount),
            "Unable to transfer fkdTokens"
        );

        emit DrawDown(_beneficiary, amount);
    }

    // Internal
    function _getNow() internal view returns (uint256) {
        return block.timestamp;
    }

    function _availableDrawDownAmount(address _beneficiary)
        internal
        view
        returns (uint256 _amount)
    {
        // Cliff Period
        if (_getNow() <= start.add(cliffDuration)) {
            // the cliff period has not ended, no fkdTokens to draw down
            return 0;
        }

        // Schedule complete
        if (_getNow() > end) {
            return vestedAmount[_beneficiary].sub(totalDrawn[_beneficiary]);
        }

        // Schedule is active

        // Work out when the last invocation was
        uint256 timeLastDrawnOrStart = lastDrawnAt[_beneficiary] == 0
            ? start
            : lastDrawnAt[_beneficiary];

        // Find out how much time has past since last invocation
        uint256 timePassedSinceLastInvocation = _getNow().sub(
            timeLastDrawnOrStart
        );

        // Work out how many due fkdTokens - time passed * rate per second
        uint256 drawDownRate = vestedAmount[_beneficiary].div(end.sub(start));
        uint256 amount = timePassedSinceLastInvocation.mul(drawDownRate);

        return amount;
    }
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
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