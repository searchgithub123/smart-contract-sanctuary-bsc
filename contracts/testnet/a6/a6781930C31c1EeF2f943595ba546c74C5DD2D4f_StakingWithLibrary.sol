/**
 *Submitted for verification at BscScan.com on 2022-12-13
*/

// File: contracts/DetailsLibrary.sol

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

library DetailsLibrary {
    
    struct eachTransaction {
        uint256 initialDeposit;
        uint256 stakeAmount;
        uint256 depositTime;
        uint256 fullWithdrawlTime;
        uint256 withdrawlTime;
        bool claimed;
        uint256 withdrawnReward;
        uint256 lastClaimTime;
        uint256 claimTimeInitialized;
        
    }

    struct UserData {
        uint256 noOfDeposits;
        uint256 noOfWithdrawls;
        mapping(uint256 => eachTransaction) eachUserStakes;
    }

    struct StakeTypeData {
        uint256 stakePeriod;
        uint256 depositFees;
        uint256 withdrawlFees;
        uint256 rewardRate;
    }

    
}
// File: contracts/IRewardToken.sol



pragma solidity ^0.8.0;

interface IRewardToken {
    function mint(address to, uint256 amount) external;
    function transfer(address to, uint256 amount) external returns(bool);
    function transferFrom(address from, address to, uint256 amount) external returns(bool);
    function balanceOf(address owner) external returns(uint256);
}
// File: contracts/IStakedToken.sol



pragma solidity ^0.8.0;

interface IStakedToken {
    function transfer(address to, uint256 amount) external returns(bool);
    function transferFrom(address from, address to, uint256 amount) external returns(bool);
    function balanceOf(address owner) external returns(uint256);
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

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        (bool success, bytes memory returndata) = target.delegatecall(data);
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

// File: @openzeppelin/contracts/proxy/utils/Initializable.sol


// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;


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
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
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
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// File: contracts/StakingWithLibrary.sol



pragma solidity ^0.8.0;






contract StakingWithLibrary is Initializable, Ownable {
    using DetailsLibrary for DetailsLibrary.UserData;
    using DetailsLibrary for DetailsLibrary.StakeTypeData;

    IStakedToken public stakedToken;
    IRewardToken public rewardToken;
    address public ownerWallet;

    bool public claimAndWithdrawFreeze;

    mapping(uint256 => DetailsLibrary.StakeTypeData) public stakeTypes;

    mapping(uint256 => bool) public stakeTypeExist;

    mapping(address => DetailsLibrary.UserData) public usersStakes;

    mapping(address => mapping(uint256 => DetailsLibrary.eachTransaction)) public userInfo;

    // mapping(address => mapping(uint256 => uint256)) public userTxIdWithType;

    event Deposit(uint256 stakeAmount, uint256 stakeType, uint256 id, uint256 stakePeriod);
    event Withdraw(uint256 stakeAmount, uint256 stakeType, uint256 id, uint256 stakePeriod, uint256 rewardAmount);
    event Claim(uint256 rewardAmount, uint256 stakeType, uint256 id);



    function initialize(address _ownerWallet, IStakedToken _stakedToken, IRewardToken _rewardToken, uint256 _stakeType, uint256 _stakePeriod, uint256 _depositFees, uint256 _withdrawlsFees, uint256 _rewardRate) external initializer  {
        require(_depositFees < 100 && _withdrawlsFees < 100, "FEES_CANNOT_BE_EQUAL_OR_MORE_THAN_100");
        require(_rewardRate > 0, "INTEREST_RATE_CANNOT_BE_ZERO");
        stakedToken = _stakedToken;
        rewardToken = _rewardToken;
        stakeTypes[_stakeType].stakePeriod = _stakePeriod;
        stakeTypes[_stakeType].depositFees = _depositFees;
        stakeTypes[_stakeType].withdrawlFees = _withdrawlsFees;
        stakeTypes[_stakeType].rewardRate = _rewardRate;
        stakeTypeExist[_stakeType] = true;
        ownerWallet = _ownerWallet;        

    }

    function deposit(uint256 _amount, uint256 _stakeType) external {
        require(_amount>0, "STAKE_MORE_THAN_ZERO");
        require(stakeTypeExist[_stakeType], "STAKE_TYPE_DOES_NOT_EXIST");

        uint256 id = usersStakes[msg.sender].noOfDeposits;
        usersStakes[msg.sender].noOfDeposits++;
        
        usersStakes[msg.sender].eachUserStakes[id].depositTime = block.timestamp;
        usersStakes[msg.sender].eachUserStakes[id].claimTimeInitialized = block.timestamp;
        usersStakes[msg.sender].eachUserStakes[id].lastClaimTime = block.timestamp;
        usersStakes[msg.sender].eachUserStakes[id].fullWithdrawlTime = block.timestamp + stakeTypes[_stakeType].stakePeriod;
        // userTxIdWithType[msg.sender][id] = _stakeType;
        usersStakes[msg.sender].eachUserStakes[id].initialDeposit = _amount;

        if(stakeTypes[_stakeType].depositFees !=0) {
            uint256 fees = _amount * stakeTypes[_stakeType].depositFees *10 / 1000;
            uint256 actualAmount = _amount - fees;
            usersStakes[msg.sender].eachUserStakes[id].stakeAmount = actualAmount;
            stakedToken.transferFrom(msg.sender, ownerWallet, fees);
            bool success = stakedToken.transferFrom(msg.sender, address(this), actualAmount);
            if(!success) revert();
            emit Deposit(actualAmount, _stakeType, id, stakeTypes[_stakeType].stakePeriod);

        } else {
            usersStakes[msg.sender].eachUserStakes[id].stakeAmount = _amount;
            bool success = stakedToken.transferFrom(msg.sender, address(this), _amount);
            if(!success) revert();
            emit Deposit(_amount, _stakeType, id, stakeTypes[_stakeType].stakePeriod);
        }

        userInfo[msg.sender][id] = usersStakes[msg.sender].eachUserStakes[id];

        

    }

    function withdraw(uint256 _amount, uint256 _stakeType, uint256 _id) external {
        require(_amount>0, "INVALID_WITHDRAW_AMOUNT");

        uint256 stakedValue = usersStakes[msg.sender].eachUserStakes[_id].stakeAmount;
        uint256 _initialDeposit = usersStakes[msg.sender].eachUserStakes[_id].initialDeposit;
        require(_amount == stakedValue, "CAN'T_UNSTAKE_AMOUNT_LESS_THAN_STAKED_AMOUNT");
        
        require(stakeTypeExist[_stakeType], "STAKE_TYPE_DOES_NOT_EXIST");
        require(!usersStakes[msg.sender].eachUserStakes[_id].claimed, "ALREADY_CLAIMED");

        usersStakes[msg.sender].eachUserStakes[_id].withdrawlTime = block.timestamp;

        uint256 stakeTimecheck = usersStakes[msg.sender].eachUserStakes[_id].withdrawlTime - usersStakes[msg.sender].eachUserStakes[_id].depositTime;
            require(stakeTimecheck >= stakeTypes[_stakeType].stakePeriod, "CANT_UNSTAKE_BEFORE_LOCKPERIOD");

        uint256 stakeTimeForReward;
        if(usersStakes[msg.sender].eachUserStakes[_id].lastClaimTime != usersStakes[msg.sender].eachUserStakes[_id].claimTimeInitialized) {
            
            stakeTimeForReward = (usersStakes[msg.sender].eachUserStakes[_id].fullWithdrawlTime - usersStakes[msg.sender].eachUserStakes[_id].lastClaimTime);
            

        } else {
            
            stakeTimeForReward = (usersStakes[msg.sender].eachUserStakes[_id].fullWithdrawlTime - usersStakes[msg.sender].eachUserStakes[_id].depositTime);
            
        }

        usersStakes[msg.sender].noOfWithdrawls++;

        uint256 withdrawFees = stakeTypes[_stakeType].withdrawlFees;

        if (withdrawFees !=0) {
            uint256 fees = stakedValue * withdrawFees * 10 / 1000;
            uint256 withdrawableAmount = stakedValue - fees;
            
            usersStakes[msg.sender].eachUserStakes[_id].stakeAmount -= stakedValue;
            usersStakes[msg.sender].eachUserStakes[_id].claimed = true;

            if(stakeTimeForReward == 0) {
                stakedToken.transfer(ownerWallet, fees);
                bool success = stakedToken.transfer(msg.sender, withdrawableAmount);
                if(!success) revert();

            } else {
                stakedToken.transfer(ownerWallet, fees);
                bool success = stakedToken.transfer(msg.sender, withdrawableAmount);
                if(!success) revert();
                
                uint256 calculatedReward = rewardCalculation(_initialDeposit, _stakeType, stakeTimeForReward);
                usersStakes[msg.sender].eachUserStakes[_id].withdrawnReward += calculatedReward;
                claimReward(msg.sender, calculatedReward);
                
            }

            emit Withdraw(withdrawableAmount, _stakeType, _id, stakeTypes[_stakeType].stakePeriod, usersStakes[msg.sender].eachUserStakes[_id].withdrawnReward);
            
        } else {
            usersStakes[msg.sender].eachUserStakes[_id].stakeAmount -= stakedValue;
            usersStakes[msg.sender].eachUserStakes[_id].claimed = true;

            if(stakeTimeForReward == 0) {
                bool success = stakedToken.transfer(msg.sender, stakedValue);
                if(!success) revert();
            } else {
                bool success = stakedToken.transfer(msg.sender, stakedValue);
                if(!success) revert();
                
                uint256 calculatedReward = rewardCalculation(_initialDeposit, _stakeType, stakeTimeForReward);
                usersStakes[msg.sender].eachUserStakes[_id].withdrawnReward += calculatedReward;
                claimReward(msg.sender, calculatedReward);
                
            }

            emit Withdraw(stakedValue, _stakeType, _id, stakeTypes[_stakeType].stakePeriod, usersStakes[msg.sender].eachUserStakes[_id].withdrawnReward);
        }
         userInfo[msg.sender][_id] = usersStakes[msg.sender].eachUserStakes[_id];


    }

    function rewardCalculation(uint256 _amount, uint256 _stakeType, uint256 _time) public view returns(uint256) {
        require(_amount > 0, "AMOUNT_SHOULD_BE_GREATER_ZERO");
        require(stakeTypeExist[_stakeType], "STAKE_TYPE_DOES_NOT_EXISTS");
        require(_time > 0, "INVALID_TIME");
        uint256 rate = stakeTypes[_stakeType].rewardRate;
        
        uint256 interest = (_amount * rate * 10 * _time) / (1000 * stakeTypes[_stakeType].stakePeriod);
        return interest;
        
    }

    function claimReward(address to, uint256 _rewardAmount) internal {
        require(to != address(0), "INVALID_CLAIMER");
        require(_rewardAmount > 0, "INVALID_REWARD_AMOUNT");
        uint256 ownerBal = rewardToken.balanceOf(ownerWallet);
        if(_rewardAmount > ownerBal) claimAndWithdrawFreeze = true;
        require(!claimAndWithdrawFreeze, "CLAIM_AND_WITHDRAW_FREEZED");
        bool success = rewardToken.transferFrom(ownerWallet, to, _rewardAmount);
        if(!success) revert();
        

    }

    function claim(uint256 _stakeType, uint256 _id) external {
        uint256 valueStaked = usersStakes[msg.sender].eachUserStakes[_id].stakeAmount;
        require(valueStaked > 0, "NOTHING_AT_STAKE");
        uint256 _initialDeposit = usersStakes[msg.sender].eachUserStakes[_id].initialDeposit;
        uint256 _lastClaimTime = usersStakes[msg.sender].eachUserStakes[_id].lastClaimTime;
        // require(_lastClaimTime <= usersStakes[msg.sender].eachUserStakes[_id].fullWithdrawlTime, "ALL_CLAIMED");

        uint256 _withdrawlTime = usersStakes[msg.sender].eachUserStakes[_id].withdrawlTime;
        require(_withdrawlTime==0, "ALREADY_WITHDRAWN");

        // uint256 withdrawFees = stakeTypes[_stakeType].withdrawlFees;
        // if( withdrawFees !=0 ) {
        //     uint256 fees = valueStaked * withdrawFees * 10 / 1000;
        //     valueStaked = valueStaked - fees;
        // }

        if (block.timestamp <= usersStakes[msg.sender].eachUserStakes[_id].fullWithdrawlTime) {
            usersStakes[msg.sender].eachUserStakes[_id].lastClaimTime = block.timestamp;
            uint256 claimTimeCheck = usersStakes[msg.sender].eachUserStakes[_id].lastClaimTime - _lastClaimTime   ;
            

            require(claimTimeCheck > 0, "ALL_CLAIMED");
            
            
            uint256 rewardValue = rewardCalculation(_initialDeposit, _stakeType, claimTimeCheck);
            
            usersStakes[msg.sender].eachUserStakes[_id].withdrawnReward += rewardValue; 
            
            claimReward(msg.sender, rewardValue);
            
            emit Claim(rewardValue, _stakeType, _id);
        } else {
            usersStakes[msg.sender].eachUserStakes[_id].lastClaimTime = usersStakes[msg.sender].eachUserStakes[_id].fullWithdrawlTime;
            uint256 claimTimeCheck = usersStakes[msg.sender].eachUserStakes[_id].lastClaimTime - _lastClaimTime;
            
            require(claimTimeCheck > 0, "ALL_CLAIMED");
            
            uint256 rewardValue = rewardCalculation(_initialDeposit, _stakeType, claimTimeCheck);
            
            usersStakes[msg.sender].eachUserStakes[_id].withdrawnReward += rewardValue; 
            
            claimReward(msg.sender, rewardValue);
            
            emit Claim(rewardValue, _stakeType, _id);
        }

        userInfo[msg.sender][_id] = usersStakes[msg.sender].eachUserStakes[_id];

    }

    function addStakedType(uint256 _stakeType, uint _stakePeriod, uint _depositFees, uint _withdrawlFees, uint _rewardRate) external onlyOwner {
        require(!stakeTypeExist[_stakeType], "STAKE_TYPE_EXISTS");
        require(_depositFees < 100 && _withdrawlFees < 100, "FEES_CANNOT_BE_EQUAL_OR_MORE_THAN_100");
        require(_rewardRate > 0, "INTEREST_RATE_CANNOT_BE_ZERO");
        stakeTypeExist[_stakeType] = true;
        stakeTypes[_stakeType].stakePeriod = _stakePeriod;
        stakeTypes[_stakeType].depositFees = _depositFees;
        stakeTypes[_stakeType].withdrawlFees = _withdrawlFees;
        stakeTypes[_stakeType].rewardRate = _rewardRate;

    }

    // function emergencyWithdraw(uint256 _stakeType, uint256 _id) external {
    //     uint256 emergencyFund = usersStakes[msg.sender].eachUserStakes[_id].stakeAmount;
    //     require(emergencyFund > 0, "NO_FUND_TO_WITHDRAW");
    //     uint256 fee = stakeTypes[_stakeType].withdrawlFees;
    //     usersStakes[msg.sender].eachUserStakes[_id].stakeAmount = 0;
    //     usersStakes[msg.sender].eachUserStakes[_id].claimed = true;
    //     usersStakes[msg.sender].eachUserStakes[_id].withdrawlTime = block.timestamp;

    //     if(fee !=0) {
    //         uint256 feeAmount = emergencyFund * fee * 10 / 1000;
    //         uint256 actualFund = emergencyFund - feeAmount;
    //         stakedToken.transfer(ownerWallet, feeAmount);
    //         bool success = stakedToken.transfer(msg.sender, actualFund);
    //         if(!success) revert();
    //     } else {
    //         bool success = stakedToken.transfer(msg.sender, emergencyFund);
    //         if(!success) revert();
    //     }
    //     userInfo[msg.sender][_id] = usersStakes[msg.sender].eachUserStakes[_id];
        
    // }

}