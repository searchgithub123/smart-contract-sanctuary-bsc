// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;




import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IMasterBalance.sol";

/// @title Admin MasterBalance proxy contract used to add features to MasterBalance admin functions
/// @dev This contract does NOT handle changing the dev address of the MasterBalance because that can only be done
///  by the dev address itself
/// @author DeFiFoFum (Balancetastic)
/// @notice Admin functions are separated into onlyOwner and onlyFarmAdmin to separate concerns
contract MasterBalanceAdmin is Ownable {
    using SafeMath for uint256;

    struct FixedPercentFarmInfo {
        uint256 pid;
        uint256 allocationPercent;
        bool isActive;
    }

    /// @notice Farm admin can manage master Balance farms and fixed percent farms
    address public farmAdmin;
    /// @notice MasterBalance Address
    IMasterBalance immutable public masterBalance;
    /// @notice Address which is eligible to accept ownership of the MasterBalance. Set by the current owner.
    address public pendingMasterBalanceOwner = address(0);
    /// @notice Array of MasterBalance pids that are active fixed percent farms
    uint256[] public fixedPercentFarmPids;
    /// @notice mapping of MasterBalance pids to FixedPercentFarmInfo
    mapping(uint256 => FixedPercentFarmInfo) public getFixedPercentFarmFromPid;
    /// @notice The percentages are divided by 10000
    uint256 constant public PERCENTAGE_PRECISION = 1e4;
    /// @notice Percentage of base pool allocation managed by MasterBalance internally
    /// @dev The BASE_PERCENTAGE needs to be considered in fixed percent farm allocation updates as it's allocation is based on a percentage
    uint256 constant public BASE_PERCENTAGE = PERCENTAGE_PRECISION / 4; // The base staking pool always gets 25%
    /// @notice Approaching max fixed farm percentage makes the fixed farm allocations go to infinity
    uint256 constant public MAX_FIXED_FARM_PERCENTAGE_BUFFER = PERCENTAGE_PRECISION / 10; // 10% Buffer
    /// @notice Percentage available to additional fixed percent farms
    uint256 constant public MAX_FIXED_FARM_PERCENTAGE = PERCENTAGE_PRECISION - BASE_PERCENTAGE - MAX_FIXED_FARM_PERCENTAGE_BUFFER;
    /// @notice Total allocation percentage for fixed percent farms
    uint256 public totalFixedPercentFarmPercentage = 0;
    /// @notice Max multiplier which is possible to be set on the MasterBalance
    uint256 constant public MAX_BONUS_MULTIPLIER = 4;

    event SetPendingMasterBalanceOwner(address pendingMasterBalanceOwner);
    event AddFarm(IERC20 indexed lpToken, uint256 allocation);
    event SetFarm(uint256 indexed pid, uint256 allocation);
    event SyncFixedPercentFarm(uint256 indexed pid, uint256 allocation);
    event AddFixedPercentFarm(uint256 indexed pid, uint256 allocationPercentage);
    event SetFixedPercentFarm(uint256 indexed pid, uint256 previousAllocationPercentage, uint256 allocationPercentage);
    event TransferredFarmAdmin(address indexed previousFarmAdmin, address indexed newFarmAdmin);
    event SweepWithdraw(address indexed to, IERC20 indexed token, uint256 amount);


    constructor(
        IMasterBalance _masterBalance,
        address _farmAdmin
    ) public {
        masterBalance = _masterBalance;
        farmAdmin = _farmAdmin;
    }

    modifier onlyFarmAdmin() {
        require(msg.sender == farmAdmin, "must be called by farm admin");
        _;
    }

    /** External Functions  */

    /// @notice Set an address as the pending admin of the MasterBalance. The address must accept afterward to take ownership.
    /// @param _pendingMasterBalanceOwner Address to set as the pending owner of the MasterBalance.
    function setPendingMasterBalanceOwner(address _pendingMasterBalanceOwner) external onlyOwner {
        pendingMasterBalanceOwner = _pendingMasterBalanceOwner;
        emit SetPendingMasterBalanceOwner(pendingMasterBalanceOwner);
    }

    /// @notice The pendingMasterBalanceOwner takes ownership through this call
    /// @dev Transferring MasterBalance ownership away from this contract renders this contract useless. 
    function acceptMasterBalanceOwnership() external {
        require(msg.sender == pendingMasterBalanceOwner, "not pending owner");
        masterBalance.transferOwnership(pendingMasterBalanceOwner);
        pendingMasterBalanceOwner = address(0);
    }

    /// @notice Update the rewardPerBlock multiplier on the MasterBalance contract
    /// @param _newMultiplier Multiplier to change to
    function updateMasterBalanceMultiplier(uint256 _newMultiplier) external onlyOwner {
        require(_newMultiplier <= MAX_BONUS_MULTIPLIER, 'multiplier greater than max');
        masterBalance.updateMultiplier(_newMultiplier);
    }

    /// @notice Helper function to update MasterBalance pools in batches 
    /// @dev The MasterBalance massUpdatePools function uses a for loop which in the future
    ///  could reach the block gas limit making it incallable. 
    /// @param pids Array of MasterBalance pids to update
    function batchUpdateMasterBalancePools(uint256[] memory pids) external {
        for (uint256 pidIndex = 0; pidIndex < pids.length; pidIndex++) {
            masterBalance.updatePool(pids[pidIndex]);
        }
    }

    // @notice Obtain detailed allocation information regarding a MasterBalance pool
    // @param pid MasterBalance pid to pull detailed information from
    // @return lpToken Address of the stake token for this pool
    // @return poolAllocationPoint Allocation points for this pool
    // @return totalAllocationPoints Total allocation points across all pools
    // @return poolAllocationPercentMantissa Percentage of pool allocation points to total multiplied by 1e18
    // @return poolBalancerBlock Amount of Balance given to the pool per block
    // @return poolBalancerDay Amount of Balance given to the pool per day
    // @return poolBalancerMonth Amount of Balance given to the pool per month
    function getDetailedPoolInfo(uint pid) external view returns (
        address lpToken,
        uint256 poolAllocationPoint,
        uint256 totalAllocationPoints,
        uint256 poolAllocationPercentMantissa,
        uint256 poolBalancePerBlock,
        uint256 poolBalancePerDay,
        uint256 poolBalancePerMonth
    ) {
        uint256 poolBalancePerBlock = masterBalance.cakePerBlock() * masterBalance.BONUS_MULTIPLIER();
        ( lpToken, poolAllocationPoint,,) = masterBalance.getPoolInfo(pid);
        totalAllocationPoints = masterBalance.totalAllocPoint();
        poolAllocationPercentMantissa = (poolAllocationPoint.mul(1e18)).div(totalAllocationPoints);
        poolBalancePerBlock = (poolBalancePerBlock.mul(poolAllocationPercentMantissa)).div(1e18);
        // Assumes a 3 second blocktime
        poolBalancePerDay = poolBalancePerBlock * 1200 * 24;
        poolBalancePerMonth = poolBalancePerDay * 30;
    }

    /// @notice An external function to sweep accidental ERC20 transfers to this contract. 
    ///   Tokens are sent to owner
    /// @param _tokens Array of ERC20 addresses to sweep
    /// @param _to Address to send tokens to
    function sweepTokens(IERC20[] memory _tokens, address _to) external onlyOwner {
        for (uint256 index = 0; index < _tokens.length; index++) {
            IERC20 token = _tokens[index];
            uint256 balance = token.balanceOf(address(this));
            token.transfer(_to, balance);
            emit SweepWithdraw(_to, token, balance);
        }
    }

    /// @notice Transfer the farmAdmin to a new address
    /// @param _newFarmAdmin Address of new farmAdmin
    function transferFarmAdminOwnership(address _newFarmAdmin) external onlyFarmAdmin {
        require(_newFarmAdmin != address(0), 'cannot transfer farm admin to address(0)');
        address previousFarmAdmin = farmAdmin;
        farmAdmin = _newFarmAdmin;
        emit TransferredFarmAdmin(previousFarmAdmin, farmAdmin);
    }

    /// @notice Update pool allocations based on fixed percentage farm percentages
    function syncFixedPercentFarms() external onlyFarmAdmin {
        require(getNumberOfFixedPercentFarms() > 0, 'no fixed farms added');
        _syncFixedPercentFarms();
    }


    /// @notice Add a batch of farms to the MasterBalance contract
    /// @dev syncs fixed percentage farms after update
    /// @param _allocPoints Array of allocation points to set each address
    /// @param _withMassPoolUpdate Mass update pools before update
    /// @param _syncFixedPercentageFarms Sync fixed percentage farm allocations
    function addMasterBalanceFarms(
        uint256[] memory _allocPoints,
        IERC20[] memory _lpTokens,
        bool _withMassPoolUpdate,
        bool _syncFixedPercentageFarms
    ) external onlyFarmAdmin {
        require(_allocPoints.length == _lpTokens.length, "array length mismatch");

        if (_withMassPoolUpdate) {
            masterBalance.massUpdatePools();
        }

        for (uint256 index = 0; index < _allocPoints.length; index++) {
            masterBalance.add(_allocPoints[index], address(_lpTokens[index]), false);
            emit AddFarm(_lpTokens[index], _allocPoints[index]);
        }

        if (_syncFixedPercentageFarms) {
            _syncFixedPercentFarms();
        }
    }

    /// @notice Add a batch of farms to the MasterBalance contract
    /// @dev syncs fixed percentage farms after update
    /// @param _pids Array of MasterBalance pool ids to update
    /// @param _allocPoints Array of allocation points to set each pid
    /// @param _withMassPoolUpdate Mass update pools before update
    /// @param _syncFixedPercentageFarms Sync fixed percentage farm allocations
    function setMasterBalanceFarms(
        uint256[] memory _pids,
        uint256[] memory _allocPoints,
        bool _withMassPoolUpdate,
        bool _syncFixedPercentageFarms
    ) external onlyFarmAdmin {
        require(_pids.length == _allocPoints.length, "array length mismatch");

        if (_withMassPoolUpdate) {
            masterBalance.massUpdatePools();
        }

        uint256 pidIndexes = masterBalance.poolLength();
        for (uint256 index = 0; index < _pids.length; index++) {
            require(_pids[index] < pidIndexes, "pid is out of bounds of MasterBalance");
            // Set all pids with no update
            masterBalance.set(_pids[index], _allocPoints[index], false);
            emit SetFarm(_pids[index], _allocPoints[index]);
        }

        if (_syncFixedPercentageFarms) {
            _syncFixedPercentFarms();
        }
    }

    /// @notice Add a new fixed percentage farm allocation
    /// @dev Must be a new MasterBalance pid and below the max fixed percentage 
    /// @param _pid MasterBalance pid to create a fixed percentage farm for
    /// @param _allocPercentage Percentage based in PERCENTAGE_PRECISION
    /// @param _withMassPoolUpdate Mass update pools before update
    /// @param _syncFixedPercentageFarms Sync fixed percentage farm allocations
    function addFixedPercentFarmAllocation(
        uint256 _pid,
        uint256 _allocPercentage,
        bool _withMassPoolUpdate,
        bool _syncFixedPercentageFarms
    ) external onlyFarmAdmin {
        require(_pid < masterBalance.poolLength(), "pid is out of bounds of MasterBalance");
        require(_pid != 0, "cannot add reserved MasterBalance pid 0");
        require(!getFixedPercentFarmFromPid[_pid].isActive, "fixed percent farm already added");
        uint256 newTotalFixedPercentage = totalFixedPercentFarmPercentage.add(_allocPercentage);
        require(newTotalFixedPercentage <= MAX_FIXED_FARM_PERCENTAGE, "allocation out of bounds");
    
        totalFixedPercentFarmPercentage = newTotalFixedPercentage;
        getFixedPercentFarmFromPid[_pid] = FixedPercentFarmInfo(_pid, _allocPercentage, true);
        fixedPercentFarmPids.push(_pid);
        emit AddFixedPercentFarm(_pid, _allocPercentage);
       
        if (_withMassPoolUpdate) {
            masterBalance.massUpdatePools();
        }

        if (_syncFixedPercentageFarms) {
            _syncFixedPercentFarms();
        }
    }

    /// @notice Update/disable a new fixed percentage farm allocation
    /// @dev If the farm allocation is 0, then the fixed farm will be disabled, but the allocation will be unchanged.
    /// @param _pid MasterBalance pid linked to fixed percentage farm to update
    /// @param _allocPercentage Percentage based in PERCENTAGE_PRECISION
    /// @param _withMassPoolUpdate Mass update pools before update
    /// @param _syncFixedPercentageFarms Sync fixed percentage farm allocations
    function setFixedPercentFarmAllocation(
        uint256 _pid,
        uint256 _allocPercentage,
        bool _withMassPoolUpdate,
        bool _syncFixedPercentageFarms
    ) external onlyFarmAdmin {
        FixedPercentFarmInfo storage fixedPercentFarm = getFixedPercentFarmFromPid[_pid];
        require(fixedPercentFarm.isActive, "not a valid farm pid");
        uint256 newTotalFixedPercentFarmPercentage = _allocPercentage.add(totalFixedPercentFarmPercentage).sub(fixedPercentFarm.allocationPercent);
        require(newTotalFixedPercentFarmPercentage <= MAX_FIXED_FARM_PERCENTAGE, "new allocation out of bounds");

        totalFixedPercentFarmPercentage = newTotalFixedPercentFarmPercentage;
        uint256 previousAllocation = fixedPercentFarm.allocationPercent;
        fixedPercentFarm.allocationPercent = _allocPercentage;

        if(_allocPercentage == 0) {
            // Disable fixed percentage farm and MasterBalance allocation
            fixedPercentFarm.isActive = false;
            // Remove fixed percent farm from pid array
            for (uint256 index = 0; index < fixedPercentFarmPids.length; index++) {
                if(fixedPercentFarmPids[index] == _pid) {
                    _removeFromArray(index, fixedPercentFarmPids);
                    break;
                }
            }
            // NOTE: The MasterBalance pool allocation is left unchanged to not disable a fixed farm 
            //  in case the creation was an accident.
        }
        emit SetFixedPercentFarm(_pid, previousAllocation, _allocPercentage);
      
        if (_withMassPoolUpdate) {
            masterBalance.massUpdatePools();
        }

        if (_syncFixedPercentageFarms) {
            _syncFixedPercentFarms();
        }
    }

    /** Public Functions  */

    /// @notice Get the number of registered fixed percentage farms
    /// @return Number of active fixed percentage farms 
    function getNumberOfFixedPercentFarms() public view returns (uint256) {
        return fixedPercentFarmPids.length;
    }

    /// @notice Get the total percentage allocated to fixed percentage farms on the MasterBalance
    /// @dev Adds the total percent allocated to fixed percentage farms with the percentage allocated to the Balance pool. 
    ///  The MasterBalance manages the Balance pool internally and we need to account for this when syncing fixed percentage farms.
    /// @return Total percentage based in PERCENTAGE_PRECISION 
    function getTotalAllocationPercent() public view returns (uint256) {
        return totalFixedPercentFarmPercentage + BASE_PERCENTAGE;
    }


    /** Internal Functions  */

    /// @notice Run through fixed percentage farm allocations and set MasterBalance allocations to match the percentage.
    /// @dev The MasterBalance contract manages the Balance pool percentage on its own which is accounted for in the calculations below. 
    function _syncFixedPercentFarms() internal {
        uint256 numberOfFixedPercentFarms = getNumberOfFixedPercentFarms();
        if(numberOfFixedPercentFarms == 0) {
            return; 
        }
        uint256 masterBalanceTotalAllocation = masterBalance.totalAllocPoint();
        ( ,uint256 poolAllocation,,) = masterBalance.getPoolInfo(0);
        uint256 currentTotalFixedPercentFarmAllocation = 0;
        // Define local vars that are used multiple times
        uint256 totalAllocationPercent = getTotalAllocationPercent();
        // Calculate the total allocation points of the fixed percent farms
        for (uint256 index = 0; index < numberOfFixedPercentFarms; index++) {
            ( ,uint256 fixedPercentFarmAllocation,,) = masterBalance.getPoolInfo(fixedPercentFarmPids[index]);
            currentTotalFixedPercentFarmAllocation = currentTotalFixedPercentFarmAllocation.add(fixedPercentFarmAllocation);
        }
        // Calculate alloted allocations
        uint256 nonPercentageBasedAllocation = masterBalanceTotalAllocation.sub(poolAllocation).sub(currentTotalFixedPercentFarmAllocation);
        uint256 percentageIncrease = (PERCENTAGE_PRECISION * PERCENTAGE_PRECISION) / (PERCENTAGE_PRECISION.sub(totalAllocationPercent));
        uint256 finalAllocation = nonPercentageBasedAllocation.mul(percentageIncrease).div(PERCENTAGE_PRECISION);
        uint256 allotedFixedPercentFarmAllocation = finalAllocation.sub(nonPercentageBasedAllocation);
        // Update fixed percentage farm allocations
        for (uint256 index = 0; index < numberOfFixedPercentFarms; index++) {
            FixedPercentFarmInfo memory fixedPercentFarm = getFixedPercentFarmFromPid[fixedPercentFarmPids[index]];
            uint256 newFixedPercentFarmAllocation = allotedFixedPercentFarmAllocation.mul(fixedPercentFarm.allocationPercent).div(totalAllocationPercent);
            masterBalance.set(fixedPercentFarm.pid, newFixedPercentFarmAllocation, false);
            emit SyncFixedPercentFarm(fixedPercentFarm.pid, newFixedPercentFarmAllocation);
        }
    }

    /// @notice Remove an index from an array by copying the last element to the index and then removing the last element.
    function _removeFromArray(uint index, uint256[] storage array) internal {
        require(index < array.length, "Incorrect index");
        array[index] = array[array.length-1];
        array.pop();
    }
}

pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;


interface IMasterBalance {
    function transferOwnership(address newOwner) external; // from Ownable.sol
    function updateMultiplier(uint256 multiplierNumber) external; // onlyOwner
    function add(uint256 _allocPoint, address _lpToken, bool _withUpdate) external; // onlyOwner
    function set(uint256 _pid, uint256 _allocPoint, bool _withUpdate) external; // onlyOwner
    function totalAllocPoint() external view returns (uint256);
    function BONUS_MULTIPLIER() external view returns (uint256);
    function cakePerBlock() external view returns (uint256);
    function poolLength() external view returns (uint256);
    function checkPoolDuplicate(address _lpToken) external view;
    function getMultiplier(uint256 _from, uint256 _to) external view returns (uint256);
    function pendingCake(uint256 _pid, address _user) external view returns (uint256);
    function massUpdatePools() external;
    function updatePool(uint256 _pid) external; // validatePool(_pid);
    function deposit(uint256 _pid, uint256 _amount) external; // validatePool(_pid);
    function withdraw(uint256 _pid, uint256 _amount) external; // validatePool(_pid);
    function enterStaking(uint256 _amount) external;
    function leaveStaking(uint256 _amount) external;
    function emergencyWithdraw(uint256 _pid) external;
    function getPoolInfo(uint256 _pid) external view returns(address lpToken, uint256 allocPoint, uint256 lastRewardBlock, uint256 accCakePerShare);
    function dev(address _devaddr) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
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
        require(c >= a, "SafeMath: addition overflow");

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
        return sub(a, b, "SafeMath: subtraction overflow");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
        require(c / a == b, "SafeMath: multiplication overflow");

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
        return div(a, b, "SafeMath: division by zero");
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
        return mod(a, b, "SafeMath: modulo by zero");
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../GSN/Context.sol";
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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}