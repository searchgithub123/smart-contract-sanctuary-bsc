/**
 *Submitted for verification at BscScan.com on 2023-01-10
*/

pragma solidity >= 0.4.22 <0.9.0;

// File: contracts/library/SafeMathInt.sol
interface IDexRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(address token, uint256 amountTokenDesired, uint256 amountTokenMin, uint256 amountETHMin, address to, uint256 deadline) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
    function removeLiquidityETH(address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external returns (uint amountToken, uint amountETH);
}

pragma solidity ^0.8.0;

library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    /**
     * @dev Multiplies two int256 variables and fails on overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a * b;

        // Detect overflow when multiplying MIN_INT256 with -1
        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }

    /**
     * @dev Division of two int256 variables and fails on overflow.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        // Prevent overflow when dividing MIN_INT256 by -1
        require(b != -1 || a != MIN_INT256);

        // Solidity already throws when dividing by 0.
        return a / b;
    }

    /**
     * @dev Subtracts two int256 variables and fails on overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }

    /**
     * @dev Adds two int256 variables and fails on overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }

    /**
     * @dev Converts to absolute value, and fails on overflow.
     */
    function abs(int256 a) internal pure returns (int256) {
        require(a != MIN_INT256);
        return a < 0 ? -a : a;
    }


    function toUint256Safe(int256 a) internal pure returns (uint256) {
        require(a >= 0);
        return uint256(a);
    }
}

// File: contracts/library/SafeMathUint.sol


pragma solidity ^0.8.0;

library SafeMathUint {
  function toInt256Safe(uint256 a) internal pure returns (int256) {
    int256 b = int256(a);
    require(b >= 0);
    return b;
  }
}
// File: contracts/interfaces/DividendPayingTokenOptionalInterface.sol


pragma solidity ^0.8.0;


interface DividendPayingTokenOptionalInterface {
  /// @notice View the amount of dividend in wei that an address can withdraw.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` can withdraw.
  function withdrawableDividendOf(address _owner) external view returns(uint256);

  /// @notice View the amount of dividend in wei that an address has withdrawn.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` has withdrawn.
  function withdrawnDividendOf(address _owner) external view returns(uint256);

  /// @notice View the amount of dividend in wei that an address has earned in total.
  /// @dev accumulativeDividendOf(_owner) = withdrawableDividendOf(_owner) + withdrawnDividendOf(_owner)
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` has earned in total.
  function accumulativeDividendOf(address _owner) external view returns(uint256);
}
// File: contracts/interfaces/DividendPayingTokenInterface.sol


pragma solidity ^0.8.0;

interface DividendPayingTokenInterface {
  /// @notice View the amount of dividend in wei that an address can withdraw.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` can withdraw.
  function dividendOf(address _owner) external view returns(uint256);

  /// @notice Distributes ether to token holders as dividends.
  /// @dev SHOULD distribute the paid ether to token holders as dividends.
  ///  SHOULD NOT directly transfer ether to token holders in this function.
  ///  MUST emit a `DividendsDistributed` event when the amount of distributed ether is greater than 0.
  function distributeDividends() external payable;

  /// @notice Withdraws the ether distributed to the sender.
  /// @dev SHOULD transfer `dividendOf(msg.sender)` wei to `msg.sender`, and `dividendOf(msg.sender)` SHOULD be 0 after the transfer.
  ///  MUST emit a `DividendWithdrawn` event if the amount of ether transferred is greater than 0.
  function withdrawDividend() external;

  /// @dev This event MUST emit when ether is distributed to token holders.
  /// @param from The address which sends ether to this contract.
  /// @param weiAmount The amount of distributed ether in wei.
  event DividendsDistributed(
    address indexed from,
    uint256 weiAmount
  );

  /// @dev This event MUST emit when an address withdraws their dividend.
  /// @param to The address which withdraws ether from this contract.
  /// @param weiAmount The amount of withdrawn ether in wei.
  event DividendWithdrawn(
    address indexed to,
    uint256 weiAmount
  );
}
// File: contracts/library/EnumerableSet.sol


pragma solidity ^0.8.0;

library EnumerableSet {

    struct Set {
        bytes32[] _values;
        mapping(bytes32 => uint256) _indexes;
    }

    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    function _remove(Set storage set, bytes32 value) private returns (bool) {
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];
                set._values[toDeleteIndex] = lastValue;
                set._indexes[lastValue] = valueIndex;
            }

            set._values.pop();

            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }


    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

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

    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}
// File: contracts/library/SafeMath.sol


pragma solidity ^0.8.0;

library SafeMath {
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
        uint256 c = a + b;
        require(c >= a, 'SafeMath: addition overflow');

        return c;
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
        return sub(a, b, 'SafeMath: subtraction overflow');
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
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
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, 'SafeMath: multiplication overflow');

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, 'SafeMath: division by zero');
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, 'SafeMath: modulo by zero');
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}
// File: contracts/interfaces/IEHXToken.sol


pragma solidity ^0.8.0;


interface IEHXToken {
    function mintTokens(address account, uint256 amount) external;
}
// File: contracts/interfaces/IERC20.sol


pragma solidity ^0.8.0;

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

// File: contracts/DividendPayingToken.sol



pragma solidity ^0.8.0;









contract DividendPayingToken is DividendPayingTokenInterface, DividendPayingTokenOptionalInterface, Ownable {
  using SafeMath for uint256;
  using SafeMathUint for uint256;
  using SafeMathInt for int256;

  // With `magnitude`, we can properly distribute dividends even if the amount of received ether is small.
  // For more discussion about choosing the value of `magnitude`,
  //  see https://github.com/ethereum/EIPs/issues/1726#issuecomment-472352728
  uint256 constant internal magnitude = 2**128;

  uint256 internal magnifiedDividendPerShare;
 
  address public token;
                                                                                    
  // About dividendCorrection:
  // If the token balance of a `_user` is never changed, the dividend of `_user` can be computed with:
  //   `dividendOf(_user) = dividendPerShare * balanceOf(_user)`.
  // When `balanceOf(_user)` is changed (via minting/burning/transferring tokens),
  //   `dividendOf(_user)` should not be changed,
  //   but the computed value of `dividendPerShare * balanceOf(_user)` is changed.
  // To keep the `dividendOf(_user)` unchanged, we add a correction term:
  //   `dividendOf(_user) = dividendPerShare * balanceOf(_user) + dividendCorrectionOf(_user)`,
  //   where `dividendCorrectionOf(_user)` is updated whenever `balanceOf(_user)` is changed:
  //   `dividendCorrectionOf(_user) = dividendPerShare * (old balanceOf(_user)) - (new balanceOf(_user))`.
  // So now `dividendOf(_user)` returns the same value before and after `balanceOf(_user)` is changed.
  mapping(address => int256) internal magnifiedDividendCorrections;
  mapping(address => uint256) internal withdrawnDividends;
  
  mapping (address => uint256) public holderBalance;
  uint256 public totalBalance;

  
  mapping (address => uint256) public amountEarned;


  uint256 public totalDividendsDistributed;
  uint256 public totalDividendsWaitingToSend;

  /// @dev Distributes dividends whenever ether is paid to this contract.
  receive() external payable {
    distributeDividends();
  }

  /// @notice Distributes ether to token holders as dividends.
  /// @dev It reverts if the total supply of tokens is 0.
  /// It emits the `DividendsDistributed` event if the amount of received ether is greater than 0.
  /// About undistributed ether:
  ///   In each distribution, there is a small amount of ether not distributed,
  ///     the magnified amount of which is
  ///     `(msg.value * magnitude) % totalSupply()`.
  ///   With a well-chosen `magnitude`, the amount of undistributed ether
  ///     (de-magnified) in a distribution can be less than 1 wei.
  ///   We can actually keep track of the undistributed ether in a distribution
  ///     and try to distribute it in the next distribution,
  ///     but keeping track of such data on-chain costs much more than
  ///     the saved ether, so we don't do that.
    
  function distributeDividends() public override payable {
    require(false, "Cannot send BNB directly to tracker as it is unrecoverable"); // 
  }
  
  function distributeTokenDividends() external onlyOwner {
    if(totalBalance > 0){
        uint256 tokensToAdd;
        uint256 balance = IERC20(token).balanceOf(address(this));

        if(totalDividendsWaitingToSend < balance){
            tokensToAdd = balance - totalDividendsWaitingToSend;
        } else {
            tokensToAdd = 0;
        }

        if (tokensToAdd > 0) {
        magnifiedDividendPerShare = magnifiedDividendPerShare.add(
            (tokensToAdd).mul(magnitude) / totalBalance
        );
        emit DividendsDistributed(msg.sender, tokensToAdd);

        totalDividendsDistributed = totalDividendsDistributed.add(tokensToAdd);
        totalDividendsWaitingToSend = totalDividendsWaitingToSend.add(tokensToAdd);
        }
    }
  }

  /// @notice Withdraws the ether distributed to the sender.
  /// @dev It emits a `DividendWithdrawn` event if the amount of withdrawn ether is greater than 0.
  function withdrawDividend() external virtual override {
    _withdrawDividendOfUser(payable(msg.sender));
  }

  /// @notice Withdraws the ether distributed to the sender.
  /// @dev It emits a `DividendWithdrawn` event if the amount of withdrawn ether is greater than 0.
  function _withdrawDividendOfUser(address payable user) internal returns (uint256) {
    uint256 _withdrawableDividend = withdrawableDividendOf(user);
    if (_withdrawableDividend > 0) {
      withdrawnDividends[user] = withdrawnDividends[user].add(_withdrawableDividend);
      if(totalDividendsWaitingToSend >= _withdrawableDividend){
        totalDividendsWaitingToSend -= _withdrawableDividend;
      }
      else {
        totalDividendsWaitingToSend = 0;  
      }
      emit DividendWithdrawn(user, _withdrawableDividend);
      amountEarned[user]+=_withdrawableDividend;
      bool success = IERC20(token).transfer(user, _withdrawableDividend);

      if(!success) {
        withdrawnDividends[user] = withdrawnDividends[user].sub(_withdrawableDividend);
        return 0;
      }

      return _withdrawableDividend;
    }

    return 0;
  }


  /// @notice View the amount of dividend in wei that an address can withdraw.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` can withdraw.
  function dividendOf(address _owner) external view override returns(uint256) {
    return withdrawableDividendOf(_owner);
  }

  /// @notice View the amount of dividend in wei that an address can withdraw.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` can withdraw.
  function withdrawableDividendOf(address _owner) public view override returns(uint256) {
    return accumulativeDividendOf(_owner).sub(withdrawnDividends[_owner]);
  }

  /// @notice View the amount of dividend in wei that an address has withdrawn.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` has withdrawn.
  function withdrawnDividendOf(address _owner) external view override returns(uint256) {
    return withdrawnDividends[_owner];
  }


  /// @notice View the amount of dividend in wei that an address has earned in total.
  /// @dev accumulativeDividendOf(_owner) = withdrawableDividendOf(_owner) + withdrawnDividendOf(_owner)
  /// = (magnifiedDividendPerShare * balanceOf(_owner) + magnifiedDividendCorrections[_owner]) / magnitude
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` has earned in total.
  function accumulativeDividendOf(address _owner) public view override returns(uint256) {

    return magnifiedDividendPerShare.mul(holderBalance[_owner]).toInt256Safe()
      .add(magnifiedDividendCorrections[_owner]).toUint256Safe() / magnitude;
  }

  /// @dev Internal function that increases tokens to an account.
  /// Update magnifiedDividendCorrections to keep dividends unchanged.
  /// @param account The account that will receive the created tokens.
  /// @param value The amount that will be created.
  function _increase(address account, uint256 value) internal {
    magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account]
      .sub( (magnifiedDividendPerShare.mul(value)).toInt256Safe() );
  }

  /// @dev Internal function that reduces an amount of the token of a given account.
  /// Update magnifiedDividendCorrections to keep dividends unchanged.
  /// @param account The account whose tokens will be burnt.
  /// @param value The amount that will be burnt.
  function _reduce(address account, uint256 value) internal {
    magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account]
      .add( (magnifiedDividendPerShare.mul(value)).toInt256Safe() );
  }

  function _setBalance(address account, uint256 newBalance) internal {
    uint256 currentBalance = holderBalance[account];
    holderBalance[account] = newBalance;
    if(newBalance > currentBalance) {
      uint256 increaseAmount = newBalance.sub(currentBalance);

      _increase(account, increaseAmount);
      totalBalance += increaseAmount;
    } else if(newBalance < currentBalance) {
      uint256 reduceAmount = currentBalance.sub(newBalance);
      _reduce(account, reduceAmount);
      totalBalance -= reduceAmount;
    }
  }

  ///////CHANGE
  
  function dividendEarned(address _user) public view returns(uint256){
    return amountEarned[_user];
  }
}
// File: contracts/DividendTracker.sol



pragma solidity ^0.8.0;



contract DividendTracker is DividendPayingToken {
    using SafeMath for uint256;
    using SafeMathInt for int256;

    struct Map {
        address[] keys;
        mapping(address => uint) values;
        mapping(address => uint) indexOf;
        mapping(address => bool) inserted;
    }

    function get(address key) private view returns (uint) {
        return tokenHoldersMap.values[key];
    }

    function getIndexOfKey(address key) private view returns (int) {
        if(!tokenHoldersMap.inserted[key]) {
            return -1;
        }
        return int(tokenHoldersMap.indexOf[key]);
    }

    function getKeyAtIndex(uint index) private view returns (address) {
        return tokenHoldersMap.keys[index];
    }



    function size() private view returns (uint) {
        return tokenHoldersMap.keys.length;
    }

    function set(address key, uint val) private {
        if (tokenHoldersMap.inserted[key]) {
            tokenHoldersMap.values[key] = val;
        } else {

            tokenHoldersMap.inserted[key] = true;
            tokenHoldersMap.values[key] = val;
            tokenHoldersMap.indexOf[key] = tokenHoldersMap.keys.length;
            tokenHoldersMap.keys.push(key);
        }
    }

    function remove(address key) private {
        if (!tokenHoldersMap.inserted[key]) {
            return;
        }

        delete tokenHoldersMap.inserted[key];
        delete tokenHoldersMap.values[key];

        uint index = tokenHoldersMap.indexOf[key];
        uint lastIndex = tokenHoldersMap.keys.length - 1;
        address lastKey = tokenHoldersMap.keys[lastIndex];

        tokenHoldersMap.indexOf[lastKey] = index;
        delete tokenHoldersMap.indexOf[key];

        tokenHoldersMap.keys[index] = lastKey;
        tokenHoldersMap.keys.pop();
    }

    Map private tokenHoldersMap;
    uint256 public lastProcessedIndex;

    mapping (address => bool) public excludedFromDividends;
    mapping (address=> uint256) public amountEarn;
    mapping (address => uint256) public lastClaimTimes;

    uint256 public claimWait;
    uint256 public immutable minimumTokenBalanceForDividends;

    event ExcludeFromDividends(address indexed account);
    event IncludeInDividends(address indexed account);
    event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);

    event Claim(address indexed account, uint256 amount, bool indexed automatic);

    constructor(address _token) {
    	claimWait = 1;
        minimumTokenBalanceForDividends = 1;
        token = _token;
    }

    function excludeFromDividends(address account) external onlyOwner {
    	excludedFromDividends[account] = true;

    	_setBalance(account, 0);
    	remove(account);

    	emit ExcludeFromDividends(account);
    }
    
    function includeInDividends(address account) external onlyOwner {
    	require(excludedFromDividends[account]);
    	excludedFromDividends[account] = false;

    	emit IncludeInDividends(account);
    }

    function updateClaimWait(uint256 newClaimWait) external onlyOwner {
        require(newClaimWait >= 1200 && newClaimWait <= 86400, "Dividend_Tracker: claimWait must be updated to between 1 and 24 hours");
        require(newClaimWait != claimWait, "Dividend_Tracker: Cannot update claimWait to same value");
        emit ClaimWaitUpdated(newClaimWait, claimWait);
        claimWait = newClaimWait;
    }

    function getLastProcessedIndex() external view returns(uint256) {
    	return lastProcessedIndex;
    }

    function getNumberOfTokenHolders() external view returns(uint256) {
        return tokenHoldersMap.keys.length;
    }

    // Check to see if I really made this contract or if it is a clone!
    // @Sir_Tris on TG, @SirTrisCrypto on Twitter

    function getAccount(address _account)
        public view returns (
            address account,
            int256 index,
            int256 iterationsUntilProcessed,
            uint256 withdrawableDividends,
            uint256 totalDividends,
            uint256 lastClaimTime,
            uint256 nextClaimTime,
            uint256 secondsUntilAutoClaimAvailable) {
        account = _account;

        index = getIndexOfKey(account);

        iterationsUntilProcessed = -1;

        if(index >= 0) {
            if(uint256(index) > lastProcessedIndex) {
                iterationsUntilProcessed = index.sub(int256(lastProcessedIndex));
            }
            else {
                uint256 processesUntilEndOfArray = tokenHoldersMap.keys.length > lastProcessedIndex ?
                                                        tokenHoldersMap.keys.length.sub(lastProcessedIndex) :
                                                        0;


                iterationsUntilProcessed = index.add(int256(processesUntilEndOfArray));
            }
        }


        withdrawableDividends = withdrawableDividendOf(account);
        totalDividends = accumulativeDividendOf(account);

        lastClaimTime = lastClaimTimes[account];

        nextClaimTime = lastClaimTime > 0 ?
                                    lastClaimTime.add(claimWait) :
                                    0;

        secondsUntilAutoClaimAvailable = nextClaimTime > block.timestamp ?
                                                    nextClaimTime.sub(block.timestamp) :
                                                    0;
    }

    function getAccountAtIndex(uint256 index)
        external view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
    	if(index >= size()) {
            return (0x0000000000000000000000000000000000000000, -1, -1, 0, 0, 0, 0, 0);
        }

        address account = getKeyAtIndex(index);

        return getAccount(account);
    }

    function canAutoClaim(uint256 lastClaimTime) private view returns (bool) {
    	if(lastClaimTime > block.timestamp)  {
    		return false;
    	}

    	return block.timestamp.sub(lastClaimTime) >= claimWait;
    }

    function setBalance(address payable account, uint256 newBalance) external onlyOwner {
    	if(excludedFromDividends[account]) {
    		return;
    	}
    	if(newBalance >= minimumTokenBalanceForDividends) {
            _setBalance(account, newBalance);
    		set(account, newBalance);
    	}
    	else {

            _setBalance(account, 0);
    		remove(account);
    	}

    	processAccount(account, true);
    }
    
    
    function process(uint256 gas) external returns (uint256, uint256, uint256) {
    	uint256 numberOfTokenHolders = tokenHoldersMap.keys.length;

    	if(numberOfTokenHolders == 0) {
    		return (0, 0, lastProcessedIndex);
    	}

    	uint256 _lastProcessedIndex = lastProcessedIndex;

    	uint256 gasUsed = 0;

    	uint256 gasLeft = gasleft();

    	uint256 iterations = 0;
    	uint256 claims = 0;

    	while(gasUsed < gas && iterations < numberOfTokenHolders) {
    		_lastProcessedIndex++;

    		if(_lastProcessedIndex >= tokenHoldersMap.keys.length) {
    			_lastProcessedIndex = 0;
    		}

    		address account = tokenHoldersMap.keys[_lastProcessedIndex];

    		if(canAutoClaim(lastClaimTimes[account])) {
    			if(processAccount(payable(account), true)) {
    				claims++;
    			}
    		}

    		iterations++;

    		uint256 newGasLeft = gasleft();

    		if(gasLeft > newGasLeft) {
    			gasUsed = gasUsed.add(gasLeft.sub(newGasLeft));
    		}
    		gasLeft = newGasLeft;
    	}

    	lastProcessedIndex = _lastProcessedIndex;

    	return (iterations, claims, lastProcessedIndex);
    }

    function processAccount(address payable account, bool automatic) public onlyOwner returns (bool) {
        uint256 amount = _withdrawDividendOfUser(account);
        amountEarn[account] += amount;
    	if(amount > 0) {
    		lastClaimTimes[account] = block.timestamp;
            // claimedAmount[account] = amount;
            emit Claim(account, amount, automatic);
    		return true;
    	}

    	return false;
    }
}
// File: contracts/EHXLPStaking.sol

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;







contract EHXLPStaking is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    using EnumerableSet for EnumerableSet.AddressSet;

    DividendTracker public dividendTracker;

    IERC20 public immutable USDC;

    IDexRouter public immutable dexRouter;

    // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many staking tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        uint256 unstakeUnlock;
        uint256 stakeCollected;
        uint256 rewardsClaimTime;
        uint256 unstakeAmount;
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken;           // Address of staking token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. Tokens to distribute per block.
        uint256 lastRewardBlock;  // Last block number that Tokens distribution occurs.
        uint256 accTokensPerShare; // Accumulated Tokens per share, times 1e12. See below.
    }

    uint256 public totalPendingUnstakedTokens;
    uint256 public unstakeLockDuration = 60 seconds;
    uint256 public constant MAX_UNSTAKE_DURATION = 21 days;

    IERC20 public immutable stakingToken;
    IERC20 public immutable rewardToken;
    mapping (address => uint256) public holderUnlockTime;

    uint256 public totalStaked;
    uint256 public rewardsPerBlock;
    uint256 public lockDuration;
    uint256 public exitPenaltyPerc;

    // Info of each user that stakes LP tokens.
    mapping (address => UserInfo) public userInfo;
    mapping (address => uint256) public stakedTokens;
    mapping(address => uint256) public rewardsClaimed;
    PoolInfo public pool;

    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 private totalAllocPoint = 0;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event WithdrawUnstakedTokens(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);
    event StakedNFT(address indexed nftAddress, uint256 indexed tokenId, address indexed sender);
    event UnstakedNFT(address indexed nftAddress, uint256 indexed tokenId, address indexed sender);

    constructor(address _stakingLPToken, address _rewardToken, uint256 _rewardsPerBlock, uint256 _lockDuration, uint256 _exitPenalty) {
        stakingToken = IERC20(_stakingLPToken);
        rewardToken = IERC20(_rewardToken);
        address _dexRouter;

        if(block.chainid == 1){
            _dexRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; // ETH: Uniswap V2
        } else if(block.chainid == 56){
            _dexRouter = 0x10ED43C718714eb63d5aA57B78B54704E256024E; // BNB Chain: PCS V2
        } else if(block.chainid == 97){
            _dexRouter = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3; // BNB Chain Testnet: PCS V2
        } else if(block.chainid == 42161){
            _dexRouter = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506; // Arbitrum: SushiSwap
        } else {
            // revert("Chain not configured");
        }

        dexRouter = IDexRouter(_dexRouter);

        rewardsPerBlock = _rewardsPerBlock;

        address profitSharingToken;

        if(block.chainid == 1){
            profitSharingToken = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48; // USDC
        } else if(block.chainid == 4){
            profitSharingToken  = 0xE7d541c18D6aDb863F4C570065c57b75a53a64d3; // Rinkeby Testnet USDC
        } else if(block.chainid == 56){
            profitSharingToken  = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56; // BUSD
        } else if(block.chainid == 97){
            profitSharingToken  = 0xD0Db716Bff27bc4cDc9dD855Ed86f20c4390BEd6; // BSC Testnet BUSD
        } else {
            profitSharingToken  = 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512;
            // revert("Chain not configured");
        }
         
        USDC = IERC20(address(profitSharingToken));

        dividendTracker = new DividendTracker(profitSharingToken);

        lockDuration = _lockDuration;
        exitPenaltyPerc = _exitPenalty;

        // staking pool
        // poolInfo.push(PoolInfo({
        //     lpToken: stakingToken,
        //     allocPoint: 1000,
        //     lastRewardBlock: block.number,
        //     accTokensPerShare: 0
        // }));
        pool.lpToken = stakingToken;
        pool.allocPoint = 1000;
        pool.lastRewardBlock = block.number;
        pool.accTokensPerShare = 0;

        totalAllocPoint = 1000;

        rewardToken.approve(address(dexRouter), type(uint256).max);
        stakingToken.approve(address(dexRouter), type(uint256).max);
    }

    function stopReward() external onlyOwner {
        updatePool();
        rewardsPerBlock = 0;
    }

    function updateAllowanceForLP() external onlyOwner {
        rewardToken.approve(address(dexRouter), type(uint256).max);
        stakingToken.approve(address(dexRouter), type(uint256).max);
    }

    // View function to see pending Reward on frontend.
    function pendingReward(address _user) public view returns (uint256) {
        // PoolInfo storage pool = pool;
        UserInfo storage user = userInfo[_user];
        if(pool.lastRewardBlock == 99999999999){
            return 0;
        }
        uint256 accTokensPerShare = pool.accTokensPerShare;
        uint256 lpSupply = totalStaked;
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 tokenReward = calculateNewRewards().mul(pool.allocPoint).div(totalAllocPoint);
            accTokensPerShare = accTokensPerShare.add(tokenReward.mul(1e12).div(lpSupply));
        }
        return user.amount.mul(accTokensPerShare).div(1e12).sub(user.rewardDebt);
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool() internal {
        // transfer any accumulated tokens.
        if(USDC.balanceOf(address(this)) > 0){
            USDC.transfer(address(dividendTracker), USDC.balanceOf(address(this)));
            dividendTracker.distributeTokenDividends();
        }
        
        // PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = totalStaked;
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 tokenReward = calculateNewRewards().mul(pool.allocPoint).div(totalAllocPoint);
        IEHXToken(address(rewardToken)).mintTokens(address(this), tokenReward);
        pool.accTokensPerShare = pool.accTokensPerShare.add(tokenReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public onlyOwner {
            updatePool();
    }

    // Stake primary tokens
    function depositUnpaired(uint256 _amountInTokens, uint256 tokenOutput, uint256 ethOutput) payable public nonReentrant {

        uint256 lpTokenInitialBalance = stakingToken.balanceOf(address(this));
        uint256 rewardTokenInitialBalance = rewardToken.balanceOf(address(this));
        rewardToken.transferFrom(msg.sender, address(this), _amountInTokens);
        uint256 deltaRewardTokenBalance = rewardToken.balanceOf(address(this)) - rewardTokenInitialBalance;
        stakedTokens[msg.sender] += deltaRewardTokenBalance;
        addLiquidity(deltaRewardTokenBalance, msg.value, tokenOutput, ethOutput);
        uint256 _amount = stakingToken.balanceOf(address(this)) - lpTokenInitialBalance;

        if(holderUnlockTime[msg.sender] == 0){
            holderUnlockTime[msg.sender] = block.timestamp + lockDuration;
        }
        // PoolInfo storage pool = pool;
        UserInfo storage user = userInfo[msg.sender];

        updatePool();
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accTokensPerShare).div(1e12).sub(user.rewardDebt);
            if(pending > 0) {
                if(pending >= rewardsRemaining()){
                    pending = rewardsRemaining();
                }
                rewardsClaimed[msg.sender] += pending;   
                user.rewardsClaimTime= block.timestamp;                ////////////////////////////UPDATE
                rewardToken.transfer(address(msg.sender), pending);
            }
        }

        // uint256 amountTransferred = 0;
        if(_amount > 0) {
            // uint256 initialBalance = pool.lpToken.balanceOf(address(this));
            // pool.lpToken.transferFrom(address(msg.sender), address(this), _amount);
            // amountTransferred = pool.lpToken.balanceOf(address(this)) - initialBalance;
            user.amount = user.amount.add(_amount);
            totalStaked += _amount;
        }
        dividendTracker.setBalance(payable(msg.sender), user.amount);
        user.rewardDebt = user.amount.mul(pool.accTokensPerShare).div(1e12);
        emit Deposit(msg.sender, _amount);
    }

    // Stake primary tokens
    function deposit(uint256 _amount) public nonReentrant {
        if(holderUnlockTime[msg.sender] == 0){
            holderUnlockTime[msg.sender] = block.timestamp + lockDuration;
        }
        // PoolInfo storage pool = pool;
        UserInfo storage user = userInfo[msg.sender];

        updatePool();
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accTokensPerShare).div(1e12).sub(user.rewardDebt);
            if(pending > 0) {
                if(pending >= rewardsRemaining()){
                    pending = rewardsRemaining();
                }
                rewardsClaimed[msg.sender] += pending;  
                user.rewardsClaimTime= block.timestamp;                ////////////////////////////UPDATE
                rewardToken.transfer(address(msg.sender), pending);
            }
        }
        uint256 amountTransferred = 0;
        if(_amount > 0) {
            uint256 initialBalance = pool.lpToken.balanceOf(address(this));
            pool.lpToken.transferFrom(address(msg.sender), address(this), _amount);
            amountTransferred = pool.lpToken.balanceOf(address(this)) - initialBalance;
            user.amount = user.amount.add(amountTransferred);
            totalStaked += amountTransferred;
        }

        dividendTracker.setBalance(payable(msg.sender), user.amount);
        user.rewardDebt = user.amount.mul(pool.accTokensPerShare).div(1e12);

        emit Deposit(msg.sender, _amount);
    }

    // Withdraw primary tokens from STAKING.

    function withdraw(uint256 _amount) public nonReentrant {

        require(holderUnlockTime[msg.sender] <= block.timestamp, "May not do normal withdraw early");
        
        // PoolInfo storage pool = pool;
        UserInfo storage user = userInfo[msg.sender];

        updatePool();
        uint256 pending = user.amount.mul(pool.accTokensPerShare).div(1e12).sub(user.rewardDebt);
        if(pending > 0) {
            if(pending >= rewardsRemaining()){
                pending = rewardsRemaining();
            }
            rewardsClaimed[msg.sender]+=pending;                   ////////////////////////////
            user.rewardsClaimTime= block.timestamp;                ////////////////////////////UPDATE
            rewardToken.transfer(payable(address(msg.sender)), pending);
        }

        if(_amount > 0) {
            user.amount -= _amount;
            totalStaked -= _amount;
            user.unstakeUnlock = block.timestamp + unstakeLockDuration;
            user.unstakeAmount += _amount;
            totalPendingUnstakedTokens += _amount;
        }

        dividendTracker.setBalance(payable(msg.sender), user.amount);
        user.rewardDebt = user.amount.mul(pool.accTokensPerShare).div(1e12);
        
        if(user.amount > 0){
            holderUnlockTime[msg.sender] = block.timestamp + lockDuration;
        } else {
            holderUnlockTime[msg.sender] = 0;
        }
        emit Withdraw(msg.sender, _amount);
    }

    function withdrawUnstakedTokens() external  nonReentrant {
        UserInfo storage user = userInfo[msg.sender];
        require(user.unstakeUnlock > 0, "No tokens to unstake");
        require(user.unstakeUnlock <= block.timestamp, "Tokens not unlocked yet");
        uint256 amountToWithdraw = user.unstakeAmount;
        // PoolInfo storage pool = pool;
        user.unstakeUnlock = 0;
        user.unstakeAmount = 0;
        totalPendingUnstakedTokens -= amountToWithdraw;
        pool.lpToken.transfer(address(msg.sender), amountToWithdraw);
        emit WithdrawUnstakedTokens(msg.sender, amountToWithdraw);
    }

    function withdrawAndSplitUnstakedTokens(uint256 tokenOutputMin, uint256 ethOutputMin) external  nonReentrant {
        UserInfo storage user = userInfo[msg.sender];
        require(user.unstakeUnlock > 0, "No tokens to unstake");
        require(user.unstakeUnlock <= block.timestamp, "Tokens not unlocked yet");
        uint256 amountToWithdraw = user.unstakeAmount;
        // PoolInfo storage pool = pool;
        user.unstakeUnlock = 0;
        user.unstakeAmount = 0;
        totalPendingUnstakedTokens -= amountToWithdraw;
        stakedTokens[msg.sender] = 0;
        removeLiquidity(msg.sender, amountToWithdraw, tokenOutputMin, ethOutputMin);

        emit WithdrawUnstakedTokens(msg.sender, amountToWithdraw);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw() external nonReentrant {
        
        UserInfo storage user = userInfo[msg.sender];
        uint256 _amount = user.amount;
        totalStaked -= _amount;
        // exit penalty for early unstakers, penalty held on contract as rewards.
        if(holderUnlockTime[msg.sender] >= block.timestamp){
            _amount -= _amount * exitPenaltyPerc / 100;
        }
        holderUnlockTime[msg.sender] = 0;
        user.unstakeUnlock = block.timestamp + unstakeLockDuration;
        user.unstakeAmount += _amount;
        totalPendingUnstakedTokens += _amount;
        user.amount = 0;
        user.rewardDebt = 0;
        dividendTracker.setBalance(payable(msg.sender), 0);
        emit EmergencyWithdraw(msg.sender, _amount);
    }

    function getUnstakeUnlockTime(address account) external view returns (uint256 secondsRemaining, uint256 unstakeTimestamp){
        UserInfo memory user = userInfo[account];
        if(user.unstakeUnlock == 0){
            return (0, 0);
        } else if (user.unstakeUnlock <= block.timestamp) {
            return (0, user.unstakeUnlock);
        } else {
            return (user.unstakeUnlock - block.timestamp, user.unstakeUnlock);
        }
    }

    // Withdraw reward. EMERGENCY ONLY. This allows the owner to migrate rewards to a new staking pool since we are not minting new tokens.
    function emergencyRewardWithdraw(uint256 _amount) external onlyOwner {
        require(_amount <= rewardsRemaining(), 'not enough tokens to take out');
        rewardsClaimed[msg.sender]+=_amount;
        rewardToken.transfer(address(msg.sender), _amount);
    }

    function setUnstakeUnlockDuration(uint256 durationInSeconds) external onlyOwner {
        require(durationInSeconds <= MAX_UNSTAKE_DURATION, "Too high");
        unstakeLockDuration = durationInSeconds;
    }

    function calculateNewRewards() public view returns (uint256) {
        // PoolInfo storage pool = pool;
        if(pool.lastRewardBlock > block.number){
            return 0;
        }
        return ((block.number - pool.lastRewardBlock) * rewardsPerBlock);
    }

    function rewardsRemaining() public view returns (uint256){
        return rewardToken.balanceOf(address(this));
    }

    function updateRewardsPerBlock(uint256 newRewardsPerBlock) external onlyOwner {
        updatePool();
        rewardsPerBlock = newRewardsPerBlock;
    }

    function updateExitPenalty(uint256 newPenaltyPerc) external onlyOwner {
        require(newPenaltyPerc <= 20, "May not set higher than 20%");
        exitPenaltyPerc = newPenaltyPerc;
    }

    function claim() external nonReentrant {
        dividendTracker.processAccount(payable(msg.sender), false);
    }

    function getTotalDividendsDistributed() external view returns (uint256) {
        return dividendTracker.totalDividendsDistributed();
    }

    function withdrawableDividendOf(address account) public view returns(uint256) {
    	return dividendTracker.withdrawableDividendOf(account);
  	}

	function dividendTokenBalanceOf(address account) public view returns (uint256) {
		return dividendTracker.holderBalance(account);
	}

    function getAccountDividendsInfo(address account)
        external view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
        return dividendTracker.getAccount(account);
    }

    function getNumberOfDividendTokenHolders() external view returns(uint256) {
        return dividendTracker.getNumberOfTokenHolders();
    }
    
    function getNumberOfDividends() external view returns(uint256) {
        return dividendTracker.totalBalance();
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount, uint256 tokenOutput, uint256 ethOutput) private {
    //function addLiquidityETH(address token, uint256 amountTokenDesired, uint256 amountTokenMin, 
    //uint256 amountETHMin, address to, uint256 deadline) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
        // add the liquidity
        dexRouter.addLiquidityETH{value: ethAmount}(
            address(rewardToken),
            tokenAmount,
            tokenOutput,
            ethOutput,
            address(this),
            block.timestamp
        );
    }

    function removeLiquidity(address to, uint256 lpAmount, uint256 tokenOutput, uint256 ethOutput) private {
        // remove the liquidity
        dexRouter.removeLiquidityETH(
            address(rewardToken),
            lpAmount,
            tokenOutput,
            ethOutput,
            address(to),
            block.timestamp
        );
    }
}

//