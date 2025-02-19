// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

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
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
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
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";


contract BscBusdGame is OwnableUpgradeable{
    using SafeMath for uint256; 
    IERC20Upgradeable public busd; 
    uint256 private baseDivider;
    uint256 public feePercents; 
    uint256 public starPercents;
    uint256 public managerPercents;
    uint256 public dayPerCycle; 
    uint256 public maxAddFreeze;
    uint256 public timeStep;
    uint256 public minDeposit;
    uint256 public maxDeposit;
    uint256 private leaderStart;
    uint256 private managerStart;
    uint256 public totalUsers; 
    
    struct UserInfo {
        address referrer;
        uint256 refNo;
        uint256 myLastDeposit;
        uint256 totalIncome;
        uint256 totalWithdraw;
        uint256 isStar;
        uint256 isLeader;
        uint256 isManager;
        uint256 split;
        uint256 splitAct;
        uint256 splitTrnx;
        uint256 myRegister;
        uint256 myActDirect;
        mapping(uint256 => uint256) levelTeam;
        mapping(uint256 => uint256) incomeArray;
        mapping(uint256 => uint256) directBuz;
    }
    mapping(address=>UserInfo) public userInfo;

    struct DepositHistory{
        address useAddress;
        uint256 amount;
        uint256 depTime;
    }
    
    struct UserDept{
        uint256 amount;
        uint256 depTime;
        uint256 unfreeze; 
        bool isUnfreezed;
    }
    struct SingleLoop{
        uint256 ind;
    }
    struct SingleIndex{
        address ads;
    }
    
    mapping(uint => SingleIndex) public singleIndex;
    mapping(address => SingleLoop) public singleAds;
    mapping(address => UserDept[]) public userDepts;
    mapping(address => bool) public _isBlackListed;
    DepositHistory[] public depositHistory;
    uint256 allIndex;
    
    address public feeReceiver;
    address public feeReceiver2;
    address public defaultRefer;
    uint256 public startTime;
    
    mapping(uint256 => uint256) reward;
    mapping(uint256 => uint256) manager_reward;
    address [] reward_array;
    address [] manager_array;
    
    event Register(address user, address referral);
    event Deposit(address user, uint256 amount);
    event DepositBySplit(address user, uint256 amount);
    event TransferBySplit(address user, address receiver, uint256 amount);
    
    uint[] public level_bonuses;  
    uint[] public single_bonuses;  
   
    function initialize() public initializer {
        __Ownable_init();
        busd = IERC20Upgradeable(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56); 
        startTime = block.timestamp;
        singleIndex[0].ads=0x7d2B098eee42B14541bb3d60CDC59E6b8Ad526Dd;
        singleAds[0x7d2B098eee42B14541bb3d60CDC59E6b8Ad526Dd].ind=0;
        baseDivider = 10000;
        feePercents = 300; 
        starPercents = 40;
        managerPercents = 60;
        dayPerCycle = 10 days;
        maxAddFreeze = 45 days;
        timeStep = 1 days;
        minDeposit = 50e18;
        maxDeposit = 2000e18;
        leaderStart = 0;
        managerStart = 0;
        feeReceiver = 0x437995fd81cE34603eB0CC3feeaCE5939528cC6B;
        feeReceiver2 = 0x5A1196C94E076f97e5d4B4f487E2bEAF6a4Ee40D;
        defaultRefer = 0x437995fd81cE34603eB0CC3feeaCE5939528cC6B;
        level_bonuses = [500, 100, 200, 300, 100, 200, 100, 100, 100, 100, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50];
        single_bonuses = [200, 100, 100, 50, 50, 100, 100, 50, 50, 50, 100, 100, 50, 50, 50, 50, 50, 50, 50, 50];
        allIndex=1;
    }


    function contractInfo() public view returns(uint256 balance, uint256 init){
       return (busd.balanceOf(address(this)),startTime);
    }
    
    function register(address _referral) external {
        require(userInfo[_referral].myLastDeposit > 0 || _referral == defaultRefer, "invalid refer");
        UserInfo storage user = userInfo[msg.sender];
        require(user.referrer == address(0), "referrer bonded");
        user.referrer = _referral;
        user.refNo = userInfo[_referral].myRegister;
        userInfo[_referral].myRegister++;
        totalUsers = totalUsers.add(1);
        emit Register(msg.sender, _referral);
    }
    
    function deposit(uint256 _busd) external {
        _deposit(msg.sender, _busd, false);
        emit Deposit(msg.sender, _busd);
    }
    function _deposit(address _user, uint256 _amount, bool isSplit) private {
        require(_amount>=minDeposit && _amount<=maxDeposit && _amount.mod(minDeposit) == 0, "Minimum 50 And Multiple 50");
        require(userInfo[_user].referrer != address(0), "register first");
        require(_amount>=userInfo[_user].myLastDeposit, "Amount greater than previous Deposit");
        if(isSplit==false){
            busd.transferFrom(msg.sender, address(this),_amount);
        }
        bool _isReDept = false;
        if(userInfo[_user].myLastDeposit==0){
            userInfo[userInfo[_user].referrer].myActDirect++;
        }else{
            _isReDept=true;
        }
        
        userInfo[_user].myLastDeposit=_amount;
        
        _distributeDeposit(_amount);
        
        uint256 addFreeze = userDepts[_user].length.mul(timeStep);
        if(addFreeze > maxAddFreeze){
            addFreeze = maxAddFreeze;
        }
        
        uint256 unfreezeTime = block.timestamp.add(dayPerCycle).add(addFreeze);
        userDepts[_user].push(UserDept(
            _amount,
            block.timestamp,
            unfreezeTime,
            false
        ));

        depositHistory.push(DepositHistory(
            msg.sender,
            _amount,
            block.timestamp
        ));

        if(singleAds[msg.sender].ind==0){
            singleIndex[allIndex].ads=msg.sender;
            singleAds[msg.sender].ind=allIndex;
            allIndex++;
        }
        _setReferral(_user,userInfo[_user].referrer,_amount,_isReDept);
        _setSingle(_user,userInfo[_user].referrer,_amount);
        
        if(_amount>=2000e18 && userInfo[_user].incomeArray[9]>=2000e18){
            userInfo[_user].totalIncome+=2000e18;
            userInfo[_user].incomeArray[9]-=2000e18;
        }else{
            unfreezeDepts(_user);
        }
        
        uint256 totalDays=getCurDay();
        reward[totalDays]+=_amount.mul(starPercents).div(baseDivider);
        manager_reward[totalDays]+=_amount.mul(managerPercents).div(baseDivider);
        updateLeader(totalDays);
        updateManager(totalDays);
    }
    function _setReferral(address _user,address _referral, uint256 _refAmount, bool _isReDept) private {
        for(uint8 i = 0; i < level_bonuses.length; i++) {
            if(_isReDept==false){
                userInfo[_referral].levelTeam[userInfo[_user].refNo]+=1;
            }
            userInfo[_referral].directBuz[userInfo[_user].refNo]+=_refAmount;
            if(userInfo[_referral].isStar==0 || userInfo[_referral].isLeader==0 || userInfo[_referral].isManager==0){
                (uint256 ltA,uint256 ltB,uint256 lbA, uint256 lbB)=teamBuzInfo(_referral);
                if(userInfo[_referral].isStar==0 && userInfo[_referral].myActDirect>=5 && ltA>=5 && ltB>=15 && userInfo[_referral].myLastDeposit>=500e18 && lbA>=5000e18 && lbB>=5000e18){
                   userInfo[_referral].isStar=1;
                }
                if(userInfo[_referral].isLeader==0 && userInfo[_referral].myActDirect>=7 && ltA>=10 && ltB>=30 && userInfo[_referral].myLastDeposit>=1000e18 && lbA>=10000e18 && lbB>=10000e18){
                   userInfo[_referral].isLeader=1;
                   reward_array.push(_referral);
                }
                if(userInfo[_referral].isManager==0 && userInfo[_referral].myActDirect>=10 && ltA>=30 && ltB>=90 && userInfo[_referral].myLastDeposit>=2000e18 && lbA>=30000e18 && lbB>=30000e18){
                   userInfo[_referral].isManager=1;
                   manager_array.push(_referral);
                }
            }
            uint256 levelOn=_refAmount;
            if(_refAmount>userInfo[_referral].myLastDeposit){
                levelOn=userInfo[_referral].myLastDeposit;
            }
            if(i==0){
                userInfo[_referral].totalIncome+=levelOn.mul(level_bonuses[i]).div(baseDivider);
                userInfo[_referral].incomeArray[2]+=levelOn.mul(level_bonuses[i]).div(baseDivider);
            }else{
                if(userInfo[_referral].isStar==1 && i < 5){
                    userInfo[_referral].totalIncome+=levelOn.mul(level_bonuses[i]).div(baseDivider);
                    userInfo[_referral].incomeArray[3]+=levelOn.mul(level_bonuses[i]).div(baseDivider);
                }else if(userInfo[_referral].isLeader==1 && i >= 5 && i < 10){
                    userInfo[_referral].incomeArray[9]+=levelOn.mul(level_bonuses[i]).div(baseDivider);
                    userInfo[_referral].incomeArray[4]+=levelOn.mul(level_bonuses[i]).div(baseDivider);
                }else if(userInfo[_referral].isManager==1 && i >= 10){
                    userInfo[_referral].incomeArray[9]+=levelOn.mul(level_bonuses[i]).div(baseDivider);
                    userInfo[_referral].incomeArray[5]+=levelOn.mul(level_bonuses[i]).div(baseDivider);
                }
            }
            
           _user = _referral;
           _referral = userInfo[_referral].referrer;
            if(_referral == address(0)) break;
        }
    }
    function _setSingle(address _myAds, address _referral, uint256 _refAmount) private {
        uint256 selfIndex=singleAds[_myAds].ind > 0 ? singleAds[_myAds].ind-1 : 0;
        uint256 selfLimit=(selfIndex>19)?selfIndex-19:0;
        uint256 s=0;
        for(uint256 k = selfIndex; k >=selfLimit; k--) {
            uint256 levelSelf=_refAmount;
            address selfads=singleIndex[k].ads;
            if(s<5 || (s>=5 && s<10 && userInfo[selfads].myLastDeposit>=500e18) || (s>=10 && userInfo[selfads].myLastDeposit>=1000e18)){
                if(_refAmount>userInfo[selfads].myLastDeposit){
                    levelSelf=userInfo[selfads].myLastDeposit;
                }
                userInfo[selfads].incomeArray[9]+=levelSelf.mul(single_bonuses[s]).div(baseDivider);
                userInfo[selfads].incomeArray[8]+=levelSelf.mul(single_bonuses[s]).div(baseDivider);
            }    
            s++;
            
            if(k<1) break;
        }
        uint256 myIndex=singleAds[_referral].ind>0 ? singleAds[_referral].ind-1 : 0;
        uint256 myLimit=(myIndex>19)?myIndex-19:0;
        uint256 j=0;
        for(uint256 i = myIndex; i >=myLimit; i--) {
            uint256 levelOn=_refAmount;
            address myads=singleIndex[i].ads;
            if(j<5 || (j>=5 && j<10 && userInfo[myads].myLastDeposit>=500e18) || (j>=10 && userInfo[myads].myLastDeposit>=1000e18)){
                if(_refAmount>userInfo[myads].myLastDeposit){
                    levelOn=userInfo[myads].myLastDeposit;
                }
                userInfo[myads].incomeArray[9]+=levelOn.mul(single_bonuses[j]).div(baseDivider);
                userInfo[myads].incomeArray[8]+=levelOn.mul(single_bonuses[j]).div(baseDivider);
            }   
            j++;
            if(i<1) break;
        }
    }
    function _distributeDeposit(uint256 _amount) private {
        uint256 fee = _amount.mul(feePercents).div(baseDivider);
        busd.transfer(feeReceiver,fee);
        busd.transfer(feeReceiver2,fee);
    }
    function depositBySplit(uint256 _amount) external {
        require(_amount >= minDeposit  && _amount<=maxDeposit && _amount.mod(minDeposit) == 0, "amount err");
        require(userInfo[msg.sender].myLastDeposit == 0, "actived");
        uint256 splitLeft = userInfo[msg.sender].split.sub(userInfo[msg.sender].splitAct).sub(userInfo[msg.sender].splitTrnx);
        require(splitLeft >= _amount, "insufficient split");
        userInfo[msg.sender].splitAct = userInfo[msg.sender].splitAct.add(_amount);
        _deposit(msg.sender, _amount,true);
        emit DepositBySplit(msg.sender, _amount);
    }

    function transferBySplit(uint256 _amount,address _receiver) external {
        require(_amount >= minDeposit && _amount<=maxDeposit && _amount.mod(minDeposit) == 0, "amount err");
        uint256 splitLeft = userInfo[msg.sender].split.sub(userInfo[msg.sender].splitAct).sub(userInfo[msg.sender].splitTrnx);
        require(splitLeft >= _amount, "insufficient income");
        userInfo[msg.sender].splitTrnx = userInfo[msg.sender].splitTrnx.add(_amount);
        userInfo[_receiver].split = userInfo[_receiver].split.add(_amount);
        emit TransferBySplit(msg.sender, _receiver, _amount);
    }
    function unfreezeDepts(address _addr) private {
        uint8 isdone;
        for(uint i=0;i<userDepts[_addr].length;i++){
            UserDept storage pl = userDepts[_addr][i];
            if(pl.isUnfreezed==false && block.timestamp>=pl.unfreeze && isdone==0){
                pl.isUnfreezed=true;
                userInfo[_addr].totalIncome+=pl.amount;
                userInfo[_addr].totalIncome+=pl.amount.mul(150).div(1000);
                userInfo[_addr].incomeArray[0]+=pl.amount;
                userInfo[_addr].incomeArray[1]+=pl.amount.mul(150).div(1000);
                
                isdone=1;
                address _referral = userInfo[_addr].referrer;
                for(uint8 j = 0; j < level_bonuses.length; j++) {
                    userInfo[_referral].directBuz[userInfo[_addr].refNo]-=pl.amount;
                    _addr = _referral;
                   _referral = userInfo[_referral].referrer;
                    if(_referral == address(0)) break;
                }
                break;
            }
        }
    }
    function teamBuzInfo(address _addr) view private returns(uint256 ltA,uint256 ltB,uint256 lbA,uint256 lbB) {
        uint256 lbATemp;
        uint256 lb;
        uint256 lTeam;
        uint256 lbTTemp;
        for(uint256 i=0;i<userInfo[_addr].myRegister;i++){
            lTeam+=userInfo[_addr].levelTeam[i];
            if(lbTTemp==0 || userInfo[_addr].levelTeam[i]>lbTTemp){
               lbTTemp=userInfo[_addr].levelTeam[i]; 
            }
            lb+=userInfo[_addr].directBuz[i];
            if(lbATemp==0 || userInfo[_addr].directBuz[i]>lbATemp){
               lbATemp=userInfo[_addr].directBuz[i]; 
            }
        }
        lbB=lb-lbATemp;
        ltB=lTeam-lbTTemp;
        return (
           lbTTemp,
           ltB,
           lbATemp,
           lbB
        );
    }
    
    function updateLeader(uint256 totalDays) private {
        if(leaderStart==0){
            if(reward_array.length>0){
                uint256 distLAmount;
                for(uint256 i=0; i < totalDays; i++){
                    distLAmount+=reward[i];
                    reward[i]=0;
                }
                distLAmount=distLAmount.div(reward_array.length);
                for(uint8 i = 0; i < reward_array.length; i++) {
                    userInfo[reward_array[i]].totalIncome+=distLAmount;
                    userInfo[reward_array[i]].incomeArray[6]+=distLAmount;
                }
                leaderStart=1;
            }
            
        }else if(leaderStart>0 && reward[totalDays > 0 ? totalDays-1 : 0]>0){
            if(reward_array.length>0){
                uint256 distLAmount=reward[totalDays > 0 ? totalDays-1 : 0].div(reward_array.length);
                for(uint8 i = 0; i < reward_array.length; i++) {
                    userInfo[reward_array[i]].totalIncome+=distLAmount;
                    userInfo[reward_array[i]].incomeArray[6]+=distLAmount;
                }
                reward[totalDays > 0 ? totalDays-1 : 0]=0;
            }
        }
    }
    function updateManager(uint256 totalDays) private {
        if(managerStart==0){
            if(manager_array.length>0){
                uint256 distAmount;
                for(uint256 i=0; i < totalDays; i++){
                    distAmount+=manager_reward[i];
                    manager_reward[i]=0;
                }
                distAmount=distAmount.div(manager_array.length);
                for(uint8 i = 0; i < manager_array.length; i++) {
                    userInfo[manager_array[i]].totalIncome+=distAmount;
                    userInfo[manager_array[i]].incomeArray[7]+=distAmount;
                }
                managerStart=1;
            }
            
        }else if(managerStart>0 && manager_reward[totalDays > 0 ? totalDays-1 : 0]>0){
            if(manager_array.length>0){
                uint256 distAmount=manager_reward[totalDays > 0 ? totalDays-1 : 0].div(manager_array.length);
                for(uint8 i = 0; i < manager_array.length; i++) {
                    userInfo[manager_array[i]].totalIncome+=distAmount;
                    userInfo[manager_array[i]].incomeArray[7]+=distAmount;
                }
                manager_reward[totalDays > 0 ? totalDays-1 : 0]=0;
            } 
        }
    }
    function getCurDay() public view returns(uint256) {
        return (block.timestamp.sub(startTime)).div(timeStep);
    }
    function leaderPool() view external returns(uint256 lp,uint256 lr,uint256 lpTeam,uint256 mp,uint256 mr,uint256 mpTeam) {
        uint256 totalDays=getCurDay();
        if(reward_array.length==0){
            for(uint256 i=0; i <= totalDays; i++){
                lp+=reward[i];
            }
            lr=lp-reward[totalDays > 0 ? totalDays - 1 : 0];
        }else{
            lp=reward[totalDays];
            lr=reward[totalDays > 0 ? totalDays - 1 : 0];
        }
        if(manager_array.length==0){
            for(uint256 i=0; i <= totalDays; i++){
                mp+=manager_reward[i];
            }
            mr=mp-manager_reward[totalDays > 0 ? totalDays - 1 : 0];
        }else{
            mp=manager_reward[totalDays];
            mr=manager_reward[totalDays > 0 ? totalDays - 1 : 0];
        }
        return (lp,lr,reward_array.length,mp,mr,manager_array.length);
    }
    function incomeDetails(address _addr) view external returns(uint256[11] memory p) {
        for(uint8 i=0;i<=10;i++){
            p[i]=userInfo[_addr].incomeArray[i];
        }
        return (
           p
        );
    }
    function userDetails(address _addr) view external returns(address ref,uint256 ltA,uint256 ltB,uint256 lbA,uint256 lbB,uint256 myDirect) {
        UserInfo storage player = userInfo[_addr];
        
        uint256 lbATemp;
        uint256 lb;
        uint256 lTeam;
        uint256 lbTTemp;
        for(uint256 i=0;i<player.myRegister;i++){
            lTeam+=player.levelTeam[i];
            if(lbTTemp==0 || player.levelTeam[i]>lbTTemp){
               lbTTemp=player.levelTeam[i]; 
            }
            lb+=player.directBuz[i];
            if(lbATemp==0 || player.directBuz[i]>lbATemp){
               lbATemp=player.directBuz[i]; 
            }
        }
        lbB=lb-lbATemp;
        ltB=lTeam-lbTTemp;
        return (
           player.referrer,
           lbTTemp,
           ltB,
           lbATemp,
           lbB,
           player.myRegister
        );
    }
    function withdraw(uint256 _amount) public{
        require(
            !_isBlackListed[msg.sender],
            "Account is blacklisted"
        );
        require(_amount >= 10e18, "Minimum 10 need");
        
        UserInfo storage player = userInfo[msg.sender];
        uint256 bonus;
        bonus=player.totalIncome-player.totalWithdraw;
        require(_amount<=bonus,"Amount exceeds withdrawable");
        player.totalWithdraw+=_amount;
        uint256 tempSplit=(bonus-player.incomeArray[0]).mul(30).div(100);
        player.incomeArray[0]=0;
        player.split+=tempSplit;
        uint256 wamount=_amount.sub(tempSplit);
        busd.transfer(msg.sender,wamount);
    }
    
    function getUserDeposits(address _address) external view returns( UserDept[] memory ) {
        return userDepts[_address];
    }

    function setfeePercents(uint256 _fees) public onlyOwner{
        feePercents = _fees;
    } 

    function setStarPercents(uint256 _per) public onlyOwner{
        starPercents = _per;
    } 


    function setManagerPercents(uint256 _per) public onlyOwner{
        managerPercents = _per;
    } 
    function setDayPerCycle(uint256 _cycle) public onlyOwner{
        dayPerCycle = _cycle;
    } 
    function setMaxAddFreeze(uint256 _maxAddFreeze) public onlyOwner{
        maxAddFreeze = _maxAddFreeze;
    } 
    function setTimeStep(uint256 _timeStep) public onlyOwner{
        timeStep = _timeStep;
    } 
    function setMinDeposit(uint256 _minDeposit) public onlyOwner{
        minDeposit = _minDeposit;
    } 
    function setMaxDeposit(uint256 _maxDeposit) public onlyOwner{
        maxDeposit = _maxDeposit;
    } 
   
    function setFeeReceiver(address _feeReceiver) public onlyOwner{
        feeReceiver = _feeReceiver;
    } 
    function setFeeReceiver2(address _feeReceiver2) public onlyOwner{
        feeReceiver2 = _feeReceiver2;
    } 
    function setDefaultRefer(address _defaultRefer) public onlyOwner{
        defaultRefer = _defaultRefer;
    }

    function setLevelBonous(uint[] memory _bonous) public onlyOwner{
        level_bonuses = _bonous;
    } 
    function setSinglebonuses(uint[] memory _bonous) public onlyOwner{
        single_bonuses = _bonous;
    } 

    function setBlackList(address addr, bool value) external onlyOwner {
        _isBlackListed[addr] = value;
    }

    function depositLength() public view returns(uint256){
        return depositHistory.length;
    }

    function rescueBNB(address payable _reciever, uint256 _amount) public onlyOwner {
        _reciever.transfer(_amount); 
    }

    function rescueToken( address payaddress ,address tokenAddress, uint256 tokens ) public onlyOwner 
    {
       IERC20Upgradeable(tokenAddress).transfer(payaddress, tokens);
    }
}

library SafeMath {
   
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

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

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}