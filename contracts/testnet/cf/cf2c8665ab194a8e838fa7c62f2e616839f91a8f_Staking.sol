/**
 *Submitted for verification at BscScan.com on 2023-01-12
*/

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

// File: @openzeppelin/contracts/utils/Counters.sol


// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// File: IBEP20.sol

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

interface IBEP20 {
function totalSupply() external view returns (uint256);
function decimals() external view returns (uint8);
function symbol() external view returns (string memory);
function name() external view returns (string memory);
function getOwner() external view returns (address);
function balanceOf(address account) external view returns (uint256);
function transfer(address recipient, uint256 amount) external returns (bool);
function allowance(address _owner, address spender) external view returns (uint256);
function approve(address spender, uint256 amount) external returns (bool);
function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
function burn(uint256 amount) external returns (bool);
event Transfer(address indexed from, address indexed to, uint256 value);
event Approval(address indexed owner, address indexed spender, uint256 value);
}
// File: Staking.sol


pragma solidity ^0.8.11;




contract Staking is Ownable {
    using Counters for Counters.Counter;

    IBEP20 private stakingToken;

    constructor(address _stakingToken) {
        stakingToken = IBEP20(_stakingToken);
    }

    uint256 private _shouldPaidAmount;
    uint256 private lastUpdatedTime;

    enum TariffPlane {
        Days90,
        Days180,
        Days360,
        Days720
    }

    struct Rate {
        address owner;
        uint256 amount;
        uint256 rate;
        uint256 expiredTime;
        bool isClaimed;
        TariffPlane daysPlane;
    }

    mapping(address => mapping(uint256 => Rate)) private _rates;
    mapping(address => Counters.Counter) private _ratesId;
    mapping(address => uint256) private _balances;

    event Staked(
        uint256 id,
        address indexed owner,
        uint256 amount,
        uint256 rate,
        uint256 expiredTime
    );
    event Claimed(address indexed receiver, uint256 amount, uint256 id);
    event TokenAddressChanged(address oldAddress, address changeAddress);

    modifier amountNot0(uint256 _amount) {
        require(_amount > 0, "The amount must be greater than 0");
        _;
    }

    modifier checkTime(uint256 id) {
        timeUpdate();
        require(
            stakingEndTime(msg.sender, id) < lastUpdatedTime,
            "Token lock time has not yet expired or Id isn't correct"
        );
        _;
    }

    modifier dayIsCorrect(uint256 day) {
        require(
            day == 90 || day == 180 || day == 360 || day == 720,
            "Choose correct plane: 90/180/360/720 days"
        );
        _;
    }

    function earned(uint256 id) private view returns (uint256) {
        return
            (_rates[msg.sender][id].amount * _rates[msg.sender][id].rate) /
            1000;
    }

    function stake(uint256 _amount, uint256 day)
        external
        amountNot0(_amount)
        dayIsCorrect(day)
    {
        uint256 id = _ratesId[msg.sender].current();
        uint256 expiredTime = calculateTime(day);
        uint256 rate = checkPlane(day);

        uint256 totalSupply = getTotalSupply();

        require(
            (_amount * rate) / 1000 <= totalSupply - _shouldPaidAmount,
            "Fund is not enough."
        );

        _rates[msg.sender][id] = Rate(
            msg.sender,
            _amount,
            rate,
            expiredTime,
            false,
            getDaysPlane(day)
        );

        uint256 reward = earned(id) + _amount;
        _shouldPaidAmount += reward;
        _balances[msg.sender] += reward;
        _ratesId[msg.sender].increment();

        stakingToken.transferFrom(
            msg.sender,
            address(this),
            _amount //* (10**stakingToken.decimals())
        );
        emit Staked(id, msg.sender, _amount, rate, expiredTime);
    }

    function claim(uint256 id) external checkTime(id) {
        require(!_rates[msg.sender][id].isClaimed, "Reward already claimed!");

        _rates[msg.sender][id].isClaimed = true;

        uint256 amount = _rates[msg.sender][id].amount;
        uint256 reward = earned(id) + amount;

        _shouldPaidAmount -= reward;
        _balances[msg.sender] -= reward;

        stakingToken.transfer(
            msg.sender,
            reward //* (10**stakingToken.decimals())
        );
        emit Claimed(msg.sender, reward, id);
    }

    function checkPlane(uint256 day) internal pure returns (uint256) {
        if (day == 90) {
            return 25;
        } else if (day == 180) {
            return 50;
        } else if (day == 360) {
            return 150;
        }
        return 200;
    }

    function getMyLastStakedId() external view returns (uint256) {
        return _ratesId[msg.sender].current() - 1;
    }

    function getDaysPlane(uint256 day) internal pure returns (TariffPlane) {
        if (day == 90) {
            return TariffPlane.Days90;
        } else if (day == 180) {
            return TariffPlane.Days180;
        } else if (day == 360) {
            return TariffPlane.Days360;
        }
        return TariffPlane.Days720;
    }

    function calculateTime(uint256 day) internal view returns (uint256) {
        return (block.timestamp + day * 24 * 3600);
    }

    function getStakingToken() external view returns (IBEP20) {
        return stakingToken;
    }

    function getTotalSupply() public view returns (uint256) {
        return stakingToken.balanceOf(address(this)); // (10**stakingToken.decimals());
    }

    function allTokensBalanceOf(address _account)
        external
        view
        returns (uint256)
    {
        return _balances[_account];
    }

    function stakingEndTime(address _account, uint256 id)
        public
        view
        returns (uint256)
    {
        return _rates[_account][id].expiredTime;
    }

    function getLastUpdatedTime() external view returns (uint256) {
        return lastUpdatedTime;
    }

    function timeUpdate() internal {
        lastUpdatedTime = block.timestamp;
    }

    function setTokenAddress(address changeAddress) external onlyOwner {
        emit TokenAddressChanged(address(stakingToken), changeAddress);
        stakingToken = IBEP20(changeAddress);
    }
}