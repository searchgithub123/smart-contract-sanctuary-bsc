// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IVesting.sol";

/// @title Vesting
/// @dev Multiple vesting realese contract.
/// Owner of contract can create new vetings.
contract Vesting is IVesting, Ownable {
  using SafeERC20 for IERC20;

  uint256 public constant PRECISION = 10_000;

  /// @notice Vested token.
  IERC20 public override immutable TOKEN;
  /// @notice Amount of tokens on the contract.
  /// @dev It is using for controll allocation.
  uint256 public totalTokensAllocation;
  /// @notice Amount of tokens which are reserved in another vestings.
  /// @dev It is using for controll allocation.
  uint256 public totalTokensInVestings;

  /// @notice Keep information about user's and their vestings.
  /// @dev It is used for calculations of withdrawable tokens.
  mapping(address => Vesting[]) public vestings;

  /// @dev Constructor. Sets the ERC-20 token contract address
  /// @param _tokenAddress Address of token
  constructor(address _tokenAddress) {
    if (_tokenAddress == address(0)) {
      revert ZeroAddress();
    }

    TOKEN = IERC20(_tokenAddress);
  }

  /// @dev Create vesting
  /// @param _beneficiary Address of beneficiary
  /// @param _amount Amount of tokens for vesting
  /// @param _vestingSchedule  Vesting schedule for vesting.
  function createVesting(
    address _beneficiary,
    uint256 _amount,
    uint256 _initialPercentUnlock,
    LinearVestingSchedule calldata _vestingSchedule
  ) external override onlyOwner {
    _createVesting(_beneficiary, _amount, _initialPercentUnlock, _vestingSchedule);
  }

  /// @dev Create multiple vestings
  /// @param _beneficiaries Addresses of beneficiaries
  /// @param _amounts Amount of tokens for vesting
  /// @param _vestingSchedules  Vesting schedule for vestings.
  function createVestingsBatch(
    address[] calldata _beneficiaries,
    uint256[] calldata _amounts,
    uint256[] calldata _initialPercentUnlocks,
    LinearVestingSchedule[] calldata _vestingSchedules
  ) external override onlyOwner {
    if (
      _beneficiaries.length != _amounts.length || _beneficiaries.length != _vestingSchedules.length
    ) {
      revert ParametersLengthMismatch({
        beneficiaries: _beneficiaries.length,
        amounts: _amounts.length,
        vestings: _vestingSchedules.length
      });
    }

    for (uint256 i = 0; i < _beneficiaries.length; i++) {
      _createVesting(_beneficiaries[i], _amounts[i], _initialPercentUnlocks[i], _vestingSchedules[i]);
      if (gasleft() < 40000) {
        revert ArraysAreTooLarge();
      }
    }
  }

  /// @dev Add tokens for vesting
  /// @param _amount Amount of tokens for vesting
  function addTokensForVesting(uint256 _amount) external override onlyOwner {
    if (_amount == 0) revert ZeroAmount();

    totalTokensAllocation += _amount;
    TOKEN.safeTransferFrom(msg.sender, address(this), _amount);
  }

  /// @dev Allow to withdraw tokens what are not used for any vestings
  function emergencyWithdraw() external override onlyOwner {
    uint256 amountToWithdraw = totalTokensAllocation - totalTokensInVestings;
    if (amountToWithdraw == 0) revert NoAvailableTokens();

    totalTokensAllocation -= amountToWithdraw;
    TOKEN.safeTransfer(msg.sender, amountToWithdraw);
  }

  /// @dev Withdraw tokens from vesting by beneficiary (msg.sender)
  function withdraw() external override {
    Vesting[] storage vesting = _getVestings(msg.sender);
    uint256 totalAmountToPay;
    for (uint256 i = 0; i < vesting.length; i++) {
      uint256 amountToPay = _getWithdrawableAmount(vesting[i]);
      if (amountToPay != 0) {
        vesting[i].claimedAmount += amountToPay;
        totalAmountToPay += amountToPay;
      }
    }
    TOKEN.safeTransfer(msg.sender, totalAmountToPay);

    emit VestingWithdrawn(msg.sender, totalAmountToPay);
  }

  /// @dev Gets amount of tokens which are used in vestings
  /// @return Amount of reserved tokens
  function getTotalTokensInVestings() external view override returns (uint256) {
    return totalTokensInVestings;
  }

  /// @dev Gets info about user's vesting by his id
  /// @param _user address of user
  /// @param _id vesting's id
  /// @return info about values of the vesting
  function getUserVestingById(address _user, uint256 _id)
    external
    view
    override
    returns (Vesting memory)
  {
    if (_id <= vestings[_user].length) {
      revert VestingDoesNotExist(_id);
    }

    Vesting storage vestingInfo = vestings[_user][_id];

    return vestingInfo;
  }

  /// @dev Shows withdrawable amount for beneficiary
  /// @param _beneficiary address to show vested amount for
  /// @return amount of tokens which _beneficiary can withdraw
  function getWithdrawableAmount(address _beneficiary) external view override returns (uint256) {
    Vesting[] storage vesting = vestings[_beneficiary];
    uint256 availableAmountInAllVestings;
    for (uint256 i = 0; i < vesting.length; i++) {
      availableAmountInAllVestings += _getWithdrawableAmount(vesting[i]);
    }

    return availableAmountInAllVestings;
  }

  /// @dev Gets all user's vestings
  /// @param _user address of user
  /// @return array of vestings
  function getVestings(address _user) external view override returns (Vesting[] memory) {
    return _getVestings(_user);
  }

  function _createVesting(
    address _beneficiary,
    uint256 _amount,
    uint256 _initialPercentUnlock,
    LinearVestingSchedule calldata _vestingSchedule
  ) internal {
    if (_beneficiary == address(0)) {
      revert ZeroAddress();
    }
    if (_amount == 0) {
      revert ZeroAmount();
    }
    if (_vestingSchedule.vestingDuration == 0) {
      revert ZeroDuration();
    }

    // solhint-disable-next-line not-rely-on-time
    uint256 currentTime = block.timestamp;
    if (_vestingSchedule.startDate < currentTime) {
      revert IncorrectVestingPeriod({
        startDate: _vestingSchedule.startDate,
        currentTimestamp: currentTime
      });
    }
    uint256 availableTokens = totalTokensAllocation - totalTokensInVestings;
    if (availableTokens < _amount) {
      revert InsufficientBalance({ available: availableTokens, required: _amount });
    }
    uint256 initialAmount = _initialPercentUnlock != 0 ? (_amount * _initialPercentUnlock) / PRECISION : 0;
    vestings[_beneficiary].push(
      Vesting({
        vestingSchedule: _vestingSchedule,
        amount: _amount,
        initialUnlock: initialAmount,
        claimedAmount: 0,
        beneficiary: _beneficiary
      })
    );
    totalTokensInVestings += _amount;

    emit VestingAdded(_beneficiary, _amount, _vestingSchedule);
  }

  function _getVestings(address _beneficiary) internal view returns (Vesting[] storage) {
    if (vestings[_beneficiary].length == 0) {
      revert UserHasNoVestings({ account: _beneficiary });
    }
    return vestings[_beneficiary];
  }

  function _getWithdrawableAmount(Vesting storage _vesting) internal view returns (uint256) {
    return _calculateAvailableAmount(_vesting) - _vesting.claimedAmount;
  }

  /// @dev Calculates the amount that has already vested.
  /// @param _vesting vesting to calculate available amount for
  function _calculateAvailableAmount(Vesting memory _vesting) internal view returns (uint256) {
    uint256 totalVestingAmount = _vesting.amount;
    uint256 startAt = _vesting.vestingSchedule.startDate + _vesting.vestingSchedule.cliff;
    uint256 vestingDuration = _vesting.vestingSchedule.vestingDuration;

    // solhint-disable-next-line not-rely-on-time
    uint256 currentTime = block.timestamp;

    if (_vesting.vestingSchedule.unlockType == InitialUnlockType.BeforeCliff) {
      return _getAmountForBeforeCliffType(_vesting);
    } else {
      if (currentTime < startAt) {
        return 0;
      } else if (currentTime >= startAt + vestingDuration) {
        return totalVestingAmount;
      } else {
        totalVestingAmount -= _vesting.initialUnlock;

        uint256 vestedAmount = _vesting.initialUnlock +
          (totalVestingAmount * (currentTime - startAt)) /
          vestingDuration;
        return vestedAmount;
      }
    }
  }

  /// @dev Calculates the amount that has already vested for vesting with `BeforeCliff` unlock type.
  /// @param _vesting vesting to calculate available amount for
  function _getAmountForBeforeCliffType(Vesting memory _vesting) internal view returns (uint256) {
    uint256 totalVestingAmount = _vesting.amount;
    uint256 startAt = _vesting.vestingSchedule.startDate;
    uint256 cliffEnd = _vesting.vestingSchedule.startDate + _vesting.vestingSchedule.cliff;
    uint256 vestingDuration = _vesting.vestingSchedule.vestingDuration;

    // solhint-disable-next-line not-rely-on-time
    uint256 currentTime = block.timestamp;

    if (currentTime < startAt) {
      return 0;
    } else if (currentTime >= cliffEnd + vestingDuration) {
      return totalVestingAmount;
    } else if (startAt <= currentTime && currentTime <= cliffEnd) {
      return _vesting.initialUnlock;
    } else {
      totalVestingAmount -= _vesting.initialUnlock;

      uint256 vestedAmount = _vesting.initialUnlock +
        (totalVestingAmount * (currentTime - cliffEnd)) /
        vestingDuration;
      return vestedAmount;
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Interface for a vesting contract
interface IVesting {
  /// @notice Structure which describes vesting.
  /// @dev It is used for saving data about vesting.
  /// @param vestingSchedule object which describe vesting schedule.
  /// @param amount amount of tokens for vesting.
  /// @param claimedAmount amount of claimed tokens by beneficiary.
  /// @param beneficiary address of beneficiary.
  struct Vesting {
    LinearVestingSchedule vestingSchedule;
    uint256 amount;
    uint256 initialUnlock;
    uint256 claimedAmount;
    address beneficiary;
  }

  /// @notice Structure which describe vesting schedule.
  /// @dev It is used for calculations of withdrawable tokens.
  /// @param startDate timeStamp of start date.
  /// @param vestingDuration duration of vesting period.
  /// @param cliff duration of lock period.
  struct LinearVestingSchedule {
    InitialUnlockType unlockType;
    uint256 startDate;
    uint256 vestingDuration;
    uint256 cliff;
  }

  /// @notice Сustom type to describe the initial unlock strategy.
  /// @param BeforeCliff unlocks the amount of tokens before the cliff period.
  /// @param AfterCliff unlocks the amount of tokens after the cliff period.
  enum InitialUnlockType {
    BeforeCliff,
    AfterCliff
  }

  /// @notice It is generated when owner add vesting for some beneficiary.
  /// @param beneficiary address of beneficiary.
  /// @param amount amount of tokens for vesting.
  /// @param schedule object which describe vesting schedule.
  event VestingAdded(address indexed beneficiary, uint256 amount, LinearVestingSchedule schedule);

  /// @notice It is generated when beneficiary withdraws tokens.
  /// @param beneficiary address of beneficiary.
  /// @param amount amount of withdrawn tokens.
  event VestingWithdrawn(address indexed beneficiary, uint256 amount);

  /// @dev Beneficiary or token address is zero.
  error ZeroAddress();

  /// @dev Zero amount of tokens.
  error ZeroAmount();

  /// @dev Zero duration of vesting.
  error ZeroDuration();

  /// @dev Arrays of function parameters have different lengths.
  /// The values of `beneficiaries`, `amounts` and `vestings` must be the same.
  /// @param beneficiaries number of beneficiaries.
  /// @param amounts number of amounts.
  /// @param vestings number of vestings.
  error ParametersLengthMismatch(uint256 beneficiaries, uint256 amounts, uint256 vestings);

  /// @dev Arrays of function parameters are too large. It is necessary to reduce the length of arrays.
  error ArraysAreTooLarge();

  /// @dev There are no tokens that are not used in vestings.
  error NoAvailableTokens();

  /// @dev Vesting with `id` does not exist.
  /// @param id invalid vesting id.
  error VestingDoesNotExist(uint256 id);

  /// @dev Incorrect vesting period. `startdate` must be greater
  /// than `currentTimestamp`.
  /// @param startDate timeStamp of start date.
  /// @param currentTimestamp current timestamp.
  error IncorrectVestingPeriod(uint256 startDate, uint256 currentTimestamp);

  /// @dev Insufficient balance for transfer. Needed `required` but only
  /// `available` available.
  /// @param available balance available.
  /// @param required requested amount to transfer.
  error InsufficientBalance(uint256 available, uint256 required);

  /// Beneficiary has no vesting for release.
  /// @param account address of the beneficiary
  error UserHasNoVestings(address account);

  /// @dev Create vesting
  /// @param _beneficiary Address of beneficiary
  /// @param _amount Amount of tokens for vesting
  /// @param _vestingSchedule Vesting schedule for vesting
  function createVesting(
    address _beneficiary,
    uint256 _amount,
    uint256 _initialUnlock,
    LinearVestingSchedule calldata _vestingSchedule
  ) external;

  /// @dev Create multiple vestings
  /// @param _beneficiaries Addresses of beneficiaries
  /// @param _amounts Amount of tokens for vesting
  /// @param _vestingSchedules Vesting schedule for vestings
  function createVestingsBatch(
    address[] calldata _beneficiaries,
    uint256[] calldata _amounts,
    uint256[] calldata _initialUnlocks,
    LinearVestingSchedule[] calldata _vestingSchedules
  ) external;

  /// @dev Add tokens for vesting
  /// @param _amount Amount of tokens for vesting
  function addTokensForVesting(uint256 _amount) external;

  /// @dev Allow to withdraw tokens what are not used for any vestings
  function emergencyWithdraw() external;

  /// @dev Withdraw tokens from vesting by beneficiary (msg.sender)
  function withdraw() external;

  /// @dev Shows withdrawable amount for beneficiary
  /// @param _beneficiary address to show vested amount for
  /// @return amount of tokens which _beneficiary can withdraw
  function getWithdrawableAmount(address _beneficiary) external view returns (uint256);

  /// @dev Gets amount of tokens which are used in vestings
  /// @return Amount of reserved tokens
  function getTotalTokensInVestings() external view returns (uint256);

  /// @dev Gets info about user's vesting by his id
  /// @param _user address of user
  /// @param _id vesting's id
  /// @return info about values of the vesting
  function getUserVestingById(address _user, uint256 _id) external view returns (Vesting memory);

  /// @dev Getter for vested token
  /// @return address of token
  function TOKEN() external view returns (IERC20);
  
  /// @dev Gets all user's vestings
  /// @param _user address of user
  /// @return array of vestings
  function getVestings(address _user) external view returns (Vesting[] memory);
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