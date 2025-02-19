// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";

contract HmineMain2 is Ownable, ReentrancyGuard
{
	using Address for address;
	using SafeERC20 for IERC20;

	struct AccountInfo {
		string nickname; // user nickname
		uint256 amount; // xHMINE staked
		uint256 reward; // BUSD reward accumulated but not claimed
		uint256 accRewardDebt; // BUSD reward debt from PCS distribution algorithm
		uint16 period; // user selected grace period for expirations
		uint64 day; // the day index of the last user interaction
		bool whitelisted; // flag indicating whether or not account pays withdraw penalties
	}

	struct PeriodInfo {
		uint256 amount; // total amount staked for a given period
		uint256 fee; // the period percentual fee
		bool available; // whether or not the period is valid/available
		mapping(uint64 => DayInfo) dayInfo; // period info per day
	}

	struct DayInfo {
		uint256 accRewardPerShare; // BUSD reward debt from PCS distribution algorithm for a given period/day
		uint256 expiringReward; // BUSD reward to expire for a given period/day
	}

	address constant FURNACE = 0x000000000000000000000000000000000000dEaD;

	address constant DEFAULT_BANKROLL = 0x25be1fcF5F51c418a0C30357a4e8371dB9cf9369; // multisig
	address constant DEFAULT_BUYBACK = 0x7674D2a14076e8af53AC4ba9bBCf0c19FeBe8899;

	uint256 constant DAY = 1 days;
	uint256 constant TZ_OFFSET = 23 hours; // UTC-1

	address public immutable hmineToken; // xHMINE
	address public immutable rewardToken; // BUSD
	address public immutable hmineMain1;

	address public bankroll = DEFAULT_BANKROLL;
	address public buyback = DEFAULT_BUYBACK;

	bool public whitelistAll = false;

	uint256 public totalStaked = 0; // total staked balance
	uint256 public totalReward = 0; // total reward balance

	uint64 public day = today();

	uint16[] public periodIndex;
	mapping(uint16 => PeriodInfo) public periodInfo;

	address[] public accountIndex;
	mapping(address => AccountInfo) public accountInfo;

	bool public migrated = false;

	function periodIndexLength() external view returns (uint256 _length)
	{
		return periodIndex.length;
	}

	function accountIndexLength() external view returns (uint256 _length)
	{
		return accountIndex.length;
	}

	function getAccountByIndex(uint256 _index) external view returns (AccountInfo memory _accountInfo)
	{
		return accountInfo[accountIndex[_index]];
	}

	function dayInfo(uint16 _period, uint64 _day) external view returns (DayInfo memory _dayInfo)
	{
		return periodInfo[_period].dayInfo[_day];
	}

	function today() public view returns (uint64 _today)
	{
		return uint64((block.timestamp + TZ_OFFSET) / DAY);
	}

	constructor(address _hmineToken, address _rewardToken, address _hmineMain1)
	{
		require(_rewardToken != _hmineToken, "invalid token");
		hmineToken = _hmineToken;
		rewardToken = _rewardToken;
		hmineMain1 = _hmineMain1;

		periodIndex.push(1); periodInfo[1].fee = 0e16; periodInfo[1].available = true;
		periodIndex.push(2); periodInfo[2].fee = 10e16; periodInfo[2].available = true;
		periodIndex.push(4); periodInfo[4].fee = 15e16; periodInfo[4].available = true;
		periodIndex.push(7); periodInfo[7].fee = 20e16; periodInfo[7].available = true;
		periodIndex.push(30); periodInfo[30].fee = 50e16; periodInfo[30].available = true;
	}

	function migrate(uint256 _totalStaked, uint256 _totalReward, uint256[] calldata _periodAmounts, address[] calldata _accounts, AccountInfo[] calldata _accountInfo) external onlyOwner nonReentrant
	{
		require(_accounts.length == _accountInfo.length, "lenght mismatch");
		require(!migrated, "unavailable");
		migrated = true;
		totalStaked = _totalStaked;
		totalReward = _totalReward;
		for (uint256 _i = 0; _i < periodIndex.length; _i++) {
			uint16 _period = periodIndex[_i];
			periodInfo[_period].amount = _periodAmounts[_i];
		}
		for (uint256 _i = 0; _i < _accounts.length; _i++) {
			address _account = _accounts[_i];
			accountIndex.push(_account);
			accountInfo[_account] = _accountInfo[_i];
		}
		IERC20(hmineToken).safeTransferFrom(msg.sender, address(this), totalStaked);
		IERC20(rewardToken).safeTransferFrom(msg.sender, address(this), totalReward);
	}

	// updates the bankroll address
	function setBankroll(address _bankroll) external onlyOwner
	{
		require(_bankroll != address(0), "invalid address");
		bankroll = _bankroll;
	}

	// updates the buyback address
	function setBuyback(address _buyback) external onlyOwner
	{
		require(_buyback != address(0), "invalid address");
		buyback = _buyback;
	}

	// flags all accounts for withdrawing without penalty (useful for migration)
	function updateWhitelistAll(bool _whitelistAll) external onlyOwner
	{
		whitelistAll = _whitelistAll;
	}

	// flags multiple accounts for withdrawing without penalty
	function updateWhitelist(address[] calldata _accounts, bool _whitelisted) external onlyOwner
	{
		for (uint256 _i; _i < _accounts.length; _i++) {
			accountInfo[_accounts[_i]].whitelisted = _whitelisted;
		}
	}

	// this is a safety net method for recovering funds that are not being used
	function recoverFunds(address _token) external onlyOwner nonReentrant
	{
		uint256 _amount = IERC20(_token).balanceOf(address(this));
		if (_token == hmineToken) _amount -= totalStaked;
		else
		if (_token == rewardToken) _amount -= totalReward;
		if (_amount > 0) {
			IERC20(_token).safeTransfer(msg.sender, _amount);
		}
	}

	// updates account nickname
	function updateNickname(string calldata _nickname) external
	{
		AccountInfo storage _accountInfo = accountInfo[msg.sender];
		require(_accountInfo.period != 0, "unknown account");
		_accountInfo.nickname = _nickname;
	}

	// updates account period
	function updatePeriod(address _account, uint16 _newPeriod) external nonReentrant
	{
		PeriodInfo storage _periodInfo = periodInfo[_newPeriod];
		require(_periodInfo.available, "unavailable");
		require(msg.sender == _account || msg.sender == owner() && _account.isContract(), "access denied");

		_updateDay();

		_updateAccount(_account, 0);

		AccountInfo storage _accountInfo = accountInfo[_account];
		uint16 _oldPeriod = _accountInfo.period;
		require(_newPeriod != _oldPeriod, "no change");

		periodInfo[_oldPeriod].amount -= _accountInfo.amount;
		_periodInfo.amount += _accountInfo.amount;

		DayInfo storage _dayInfo = _periodInfo.dayInfo[day];
		_accountInfo.accRewardDebt = _accountInfo.amount * _dayInfo.accRewardPerShare / 1e18;
		_accountInfo.period = _newPeriod;
	}

	// stakes xHMINE
	function deposit(uint256 _amount) external
	{
		depositOnBehalfOf(_amount, msg.sender);
	}

	// stakes xHMINE on behalf of another account
	function depositOnBehalfOf(uint256 _amount, address _account) public nonReentrant
	{
		require(_amount > 0, "invalid amount");

		_updateDay();

		_updateAccount(_account, int256(_amount));

		totalStaked += _amount;

		IERC20(hmineToken).safeTransferFrom(msg.sender, address(this), _amount);

		emit Deposit(_account, hmineToken, _amount);
	}

	// unstakes xHMINE
	function withdraw(uint256 _amount) external
	{
		require(_amount > 0, "invalid amount");

		AccountInfo storage _accountInfo = accountInfo[msg.sender];
		require(_amount <= _accountInfo.amount, "insufficient balance");

		_updateDay();

		_updateAccount(msg.sender, -int256(_amount));

		totalStaked -= _amount;

		if (_accountInfo.whitelisted || whitelistAll) {
			IERC20(hmineToken).safeTransfer(msg.sender, _amount);
		} else {
			uint256 _10percent = _amount * 10e16 / 100e16;
			uint256 _netAmount = _amount - 2 * _10percent;
			IERC20(hmineToken).safeTransfer(FURNACE, _10percent);
			IERC20(hmineToken).safeTransfer(bankroll, _10percent);
			IERC20(hmineToken).safeTransfer(msg.sender, _netAmount);
		}

		emit Withdraw(msg.sender, hmineToken, _amount);
	}

	// claims BUSD rewards
	function claim() external returns (uint256 _amount)
	{
		return claimOnBehalfOf(msg.sender);
	}

	// claims BUSD rewards on behalf of a given user (available only to HmineMain1)
	function claimOnBehalfOf(address _account) public nonReentrant returns (uint256 _amount)
	{
		require(msg.sender == _account || msg.sender == hmineMain1, "access denied");

		_updateDay();

		_updateAccount(_account, 0);

		AccountInfo storage _accountInfo = accountInfo[_account];
		_amount = _accountInfo.reward;
		_accountInfo.reward = 0;

		if (_amount > 0) {
			totalReward -= _amount;

			IERC20(rewardToken).safeTransfer(msg.sender, _amount);
		}

		emit Claim(_account, rewardToken, _amount);

		return _amount;
	}

	// sends BUSD to a set of accounts
	function reward(address[] calldata _accounts, uint256[] calldata _amounts) external nonReentrant
	{
		require(_accounts.length == _amounts.length, "lenght mismatch");

		uint256 _amount = 0;

		for (uint256 _i = 0; _i < _accounts.length; _i++) {
			address _account = _accounts[_i];
			AccountInfo storage _accountInfo = accountInfo[_account];

			_accountInfo.reward += _amounts[_i];

			emit Reward(_account, rewardToken, _amounts[_i]);

			_amount += _amounts[_i];
		}

		if (_amount > 0) {
			totalReward += _amount;

			IERC20(rewardToken).safeTransferFrom(msg.sender, address(this), _amount);
		}
	}

	// sends BUSD to all stakers
	function rewardAll(uint256 _amount) external nonReentrant
	{
		require(_amount > 0, "invalid amount");

		if (totalStaked == 0) {
			IERC20(rewardToken).safeTransferFrom(msg.sender, address(this), _amount);
			return;
		}

		_updateDay();

		for (uint256 _i = 0; _i < periodIndex.length; _i++) {
			uint16 _period = periodIndex[_i];
			PeriodInfo storage _periodInfo = periodInfo[_period];

			// splits proportionally by period
			uint256 _subamount = _amount * _periodInfo.amount / totalStaked;
			if (_subamount == 0) continue;

			// rewards according to stake using PCS distribution algorithm
			DayInfo storage _dayInfo = _periodInfo.dayInfo[day];
			_dayInfo.accRewardPerShare += _subamount * 1e18 / _periodInfo.amount;
			_dayInfo.expiringReward += _subamount;
		}

		totalReward += _amount;

		IERC20(rewardToken).safeTransferFrom(msg.sender, address(this), _amount);

		emit RewardAll(msg.sender, rewardToken, _amount);
	}

	// sends BUSD to the top 20 stakers (list computed off-chain)
	function sendBonusDiv(uint256 _amount, address[] memory _topTen, address[] memory _topTwenty) external nonReentrant
	{
		require(_amount > 0, "invalid amount");
		require(_topTen.length == 10 && _topTwenty.length == 10, "invalid length");

		uint256 _topTenAmount = (_amount * 75e16 / 100e16) / _topTen.length;

		for (uint256 _i = 0; _i < _topTen.length; _i++) {
			address _account = _topTen[_i];
			AccountInfo storage _accountInfo = accountInfo[_account];

			_accountInfo.reward += _topTenAmount;

			emit Reward(_account, rewardToken, _topTenAmount);
		}

		uint256 _topTwentyAmount = (_amount * 25e16 / 100e16) / _topTwenty.length;

		for (uint256 _i = 0; _i < _topTwenty.length; _i++) {
			address _account = _topTwenty[_i];
			AccountInfo storage _accountInfo = accountInfo[_account];

			_accountInfo.reward += _topTwentyAmount;

			emit Reward(_account, rewardToken, _topTenAmount);
		}

		totalReward += _amount;

		IERC20(rewardToken).safeTransferFrom(msg.sender, address(this), _amount);
	}

	// performs the daily expiration of rewards from staking (BUSD)
	function updateDay() external nonReentrant
	{
		_updateDay();
	}

	// updates the user account as if he had interacted with this contract (available only to HmineMain1)
	function updateAccount(address _account) external nonReentrant
	{
		require(msg.sender == hmineMain1, "access denied");

		_updateDay();

		_updateAccount(_account, 0);
	}

	function _updateDay() internal
	{
		uint64 _today = today();

		if (day == _today) return;

		uint256 _amount = 0;

		for (uint256 _i = 0; _i < periodIndex.length; _i++) {
			uint16 _period = periodIndex[_i];
			PeriodInfo storage _periodInfo = periodInfo[_period];

			for (uint64 _day = day; _day < _today; _day++) {
				// carry over accRewardPerShare to the next day
				{
					_periodInfo.dayInfo[_day + 1].accRewardPerShare = _periodInfo.dayInfo[_day].accRewardPerShare;
				}

				// sum up the rewards that expired for a given day
				{
					DayInfo storage _dayInfo = _periodInfo.dayInfo[_day - _period];
					_amount += _dayInfo.expiringReward;
					_dayInfo.expiringReward = 0;
				}
			}
		}

		day = _today;

		if (_amount > 0) {
			totalReward -= _amount;

			IERC20(rewardToken).safeTransfer(buyback, _amount);
		}
	}

	function _updateAccount(address _account, int256 _amount) internal
	{
		AccountInfo storage _accountInfo = accountInfo[_account];
		uint16 _period = _accountInfo.period;
		if (_period == 0) {
			// initializes and adds account to index
			_period = 1;

			accountIndex.push(_account);

			_accountInfo.period = _period;
			_accountInfo.day = day - (_period + 1);
		}
		PeriodInfo storage _periodInfo = periodInfo[_period];

		uint256 _rewardBefore = _accountInfo.reward;

		// if account rewards expire, then
		{
			// if rewards beyond reach, resets to the and of previous day
			if (_accountInfo.day < day - _period) {
				DayInfo storage _dayInfo = _periodInfo.dayInfo[day - 1];
				_accountInfo.accRewardDebt = _accountInfo.amount * _dayInfo.accRewardPerShare / 1e18;
			} else {
				// collects rewards for the past days
				for (uint64 _day = _accountInfo.day; _day < day; _day++) {
					DayInfo storage _dayInfo = _periodInfo.dayInfo[_day];
					uint256 _accRewardDebt = _accountInfo.amount * _dayInfo.accRewardPerShare / 1e18;
					uint256 _reward = _accRewardDebt - _accountInfo.accRewardDebt;
					_dayInfo.expiringReward -= _reward;
					_accountInfo.reward += _reward;
					_accountInfo.accRewardDebt = _accRewardDebt;
				}
			}
		}

		// collects rewards for the current day and adjusts balance
		{
			DayInfo storage _dayInfo = _periodInfo.dayInfo[day];
			uint256 _reward = _accountInfo.amount * _dayInfo.accRewardPerShare / 1e18 - _accountInfo.accRewardDebt;
			_dayInfo.expiringReward -= _reward;
			_accountInfo.reward += _reward;
			if (_amount > 0) {
				_accountInfo.amount += uint256(_amount);
				_periodInfo.amount += uint256(_amount);
			}
			else
			if (_amount < 0) {
				_accountInfo.amount -= uint256(-_amount);
				_periodInfo.amount -= uint256(-_amount);
			}
			_accountInfo.accRewardDebt = _accountInfo.amount * _dayInfo.accRewardPerShare / 1e18;
		}

		_accountInfo.day = day;

		// collect period fees from the account reward
		if (_periodInfo.fee > 0) {
			uint256 _rewardAfter = _accountInfo.reward;

			uint256 _reward = _rewardAfter - _rewardBefore;
			uint256 _fee = _reward * _periodInfo.fee / 1e18;
			if (_fee > 0) {
				_accountInfo.reward -= _fee;

				totalReward -= _fee;

				IERC20(rewardToken).safeTransfer(buyback, _fee);
			}
		}
	}

	event Deposit(address indexed _account, address indexed _hmineToken, uint256 _amount);
	event Withdraw(address indexed _account, address indexed _hmineToken, uint256 _amount);
	event Claim(address indexed _account, address indexed _rewardToken, uint256 _amount);
	event Reward(address indexed _account, address indexed _rewardToken, uint256 _amount);
	event RewardAll(address indexed _account, address indexed _rewardToken, uint256 _amount);
}

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

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
     * by making the `nonReentrant` function external, and make it call a
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

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

import "../IERC20.sol";
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

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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

// SPDX-License-Identifier: MIT

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