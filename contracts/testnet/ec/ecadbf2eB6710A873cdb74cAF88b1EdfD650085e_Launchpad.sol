// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
pragma abicoder v2;

import "../interfaces/interfaces.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { SafeERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

/**
 * @title Launchpad
 * @author Planetarium
 */
contract Launchpad is Initializable {
  using SafeERC20Upgradeable for IERC20Upgradeable;

  /// @notice Launchpad Operator
  address public LAUNCHPAD_OPERATOR;

   /// @notice WETH ADDRESS (WBNB in BSC Network)
  address private WETH_ADDRESS;

  /// @notice Pancake Swap Factory V2 Contract Address
  address private PANCAKE_FACTORY_V2_ADDRESS;

  /// @notice Project ID (PID)
  uint256 private projectID;

  /// @notice List of Projects
  mapping(uint256 => ProjectData) private PROJECTS;

  /* ========== EVENTS ========== */
  event ProjectInitialized(
    uint256 indexed _pid,
    address _commitCurrency,
    IERC20 _auctionToken,
    address _auctionTokenVault,
    uint256 _startTime,
    uint256 _endTime,
    uint256 _totalOfferingTokens,
    uint256 _minCommitAmount,
    address _treasury,
    address _wallet,
    address _operator
  );
  event LaunchpadOperatorConfigured(address indexed _address);
  event AuctionOperatorConfigured(uint256 indexed _pid, address indexed _address);
  event AuctionTokenTransferredFromVault(uint256 indexed _pid);
  event ProjectCancelledBeforeStart(uint256 indexed _pid);
  event ProjectFinalized(uint256 indexed _pid);
  event UnclaimedAuctionTokenWithdrawn(uint256 indexed _pid);
  event UnclaimedLPTokenWithdrawn(uint256 indexed _pid);
  event AllowlistSignerChanged(uint256 indexed _pid, address indexed _address);
  
  /**
   * @notice Launchpad Operator Modifier
   * @dev olny launchpad operator can init a project and set auction operator
   */
  modifier onlyLaunchpadOperator {
    require(msg.sender == LAUNCHPAD_OPERATOR, 'ONLY_LAUNCHPAD_OPERATOR');
    _;
  }

  /**
   * @notice Auction Operator Modifier
   * @dev only auction operator can manage the project
   */
  modifier onlyAuctionOperator(uint256 _pid) {
    require(msg.sender == PROJECTS[_pid].operator, 'ONLY_AUCTION_OPERATOR');
    _;
  }
 
  /**
   * @notice Check the project was initialized or not 
   */
  modifier isInitialized(uint256 _pid) {
    require(address(PROJECTS[_pid].auction) != address(0), 'PROJECT_SHOULD_BE_INITIALIZED');
    _;
  }

  /**
   * @notice Initializer of the launchpad contract
   * @param _launchpadOperator launchpad Operator
   * @param _wethAddress WETH Address
   * @param _pancakeFactoryV2Address Pancake Swap Factory V2 Address
   */
  function initialize(
    address _launchpadOperator,
    address _wethAddress,
    address _pancakeFactoryV2Address
  ) external initializer {
    LAUNCHPAD_OPERATOR = _launchpadOperator;
    WETH_ADDRESS = _wethAddress;
    PANCAKE_FACTORY_V2_ADDRESS = _pancakeFactoryV2Address;

    // Project ID is initialized as 0
    projectID = 0;
  }

  /**
   * @notice Change Launchpad Operator
   * @param _launchpadOperator new launchpad opertor address
   */
  function changeLaunchpadOperator(address _launchpadOperator)
    external onlyLaunchpadOperator {
    require(_launchpadOperator != address(0), 'INVALID_ADDRESS');
    LAUNCHPAD_OPERATOR = _launchpadOperator;
    emit LaunchpadOperatorConfigured(_launchpadOperator);
  }

  /**
   * @notice Change Auction Operator for each projects
   * @param _auctionOperator auction opertor address
   */
  function changeAuctionOperator(uint256 _pid, address _auctionOperator)
    external isInitialized(_pid) onlyLaunchpadOperator {
    require(_auctionOperator != address(0), 'INVALID_ADDRESS');
    PROJECTS[_pid].operator = _auctionOperator;
    emit AuctionOperatorConfigured(_pid, _auctionOperator);
  }

  /**
   * @notice Initialize Project
   * @param _commitCurrency Commit currency address
   * @param _auctionToken Auction token to sale
   * @param _auctionTokenVault Auction token vault
   * @param _startTime Auction start time
   * @param _endTime Auction end time
   * @param _vestingPeriod Vesting Period
   * @param _claimablePeriod Claimable Period
   * @param _totalOfferingTokens Total Amount of Offering Tokens
   * @param _minCommitAmount Minimum Commitment Amount to success the auction
   * @param _treasury Treasury Wallet Address
   * @param _wallet Auction Wallet Address
   * @param _operator Operator of the auction
   */
  function initProject(
    address _commitCurrency,
    IERC20 _auctionToken,
    address _auctionTokenVault,
    uint256 _startTime,
    uint256 _endTime,
    uint256 _vestingPeriod,
    uint256 _claimablePeriod,
    uint256 _totalOfferingTokens,
    uint256 _minCommitAmount,
    address _treasury,
    address payable _wallet,
    address _operator
  ) external onlyLaunchpadOperator returns (uint256) {

    // Create a new auction
    BatchAuction _auction = new BatchAuction(
      WETH_ADDRESS,
      PANCAKE_FACTORY_V2_ADDRESS
    );

    // Initialize the auction with parameters
    _auction.initAuction(
      _commitCurrency,
      _auctionToken,
      _auctionTokenVault,
      _startTime,
      _endTime,
      _vestingPeriod,
      _claimablePeriod,
      _totalOfferingTokens,
      _minCommitAmount,
      _treasury,
      _wallet
    );

    // ProjectID starts from 1
    projectID += 1;
    PROJECTS[projectID].auction = _auction;
    PROJECTS[projectID].status = ProjectStatus.Initialized;
    PROJECTS[projectID].operator = _operator;

    emit ProjectInitialized(
      projectID,
      _commitCurrency,
      _auctionToken,
      _auctionTokenVault,
      _startTime,
      _endTime,
      _totalOfferingTokens,
      _minCommitAmount,
      _treasury,
      _wallet,
      _operator
    );

    return projectID;
  }

  /**
   * @notice Change Allowlist Signer
   * @param _pid Project ID
   * @param _signer Allowlist Signer Address
   */
  function setAllowlistSigner(uint256 _pid, address _signer)
    external isInitialized(_pid) onlyAuctionOperator(_pid) {
    PROJECTS[_pid].auction.setAllowlistSigner(_signer);
    emit AllowlistSignerChanged(_pid, _signer);
  }

  /**
   * @notice Transfer Auction Token from Auction Token Vault
   * @param _pid Project ID
   */
  function transferAuctionTokenFromVault(uint256 _pid)
    external isInitialized(_pid) onlyAuctionOperator(_pid) {
    PROJECTS[_pid].auction.transferAuctionTokenFromVault();
    emit AuctionTokenTransferredFromVault(_pid);
  }

  /**
   * @notice Cancel the project before start
   * @param _pid Project ID
   */
  function cancelProjectBeforeStart(uint256 _pid)
    external isInitialized(_pid) onlyAuctionOperator(_pid) {
    PROJECTS[_pid].auction.cancelAuctionBeforeStart();
    PROJECTS[_pid].status = ProjectStatus.Cancelled;
    emit ProjectCancelledBeforeStart(_pid);
  }
  
  /**
   * @notice Finalize the project with Success
   * @param _pid Project ID
   * @param _LPAddress LP Address
   * @param _minLP minimum LP value expected to be minted
   */
  function finalizeProjectWithSuccess(uint256 _pid, address _LPAddress, uint256 _minLP)
    external isInitialized(_pid) onlyAuctionOperator(_pid) {
    PROJECTS[_pid].auction.finalizeAuctionWithSuccess(_LPAddress, _minLP);
    PROJECTS[_pid].status = ProjectStatus.Finalized;
    emit ProjectFinalized(_pid);
  }

  /**
   * @notice Finalize the project with Failure
   * @param _pid Project ID
   */
  function finalizeProjectWithFailure(uint256 _pid)
    external isInitialized(_pid) onlyAuctionOperator(_pid) {
    PROJECTS[_pid].auction.finalizeAuctionWithFailure();
    PROJECTS[_pid].status = ProjectStatus.Finalized;
    emit ProjectFinalized(_pid);
  }

  /**
   * @notice Withdraw unclaimed auction token
   * @param _pid Project ID
   */
  function withdrawUnclaimedAuctionToken(uint256 _pid)
    external isInitialized(_pid) onlyAuctionOperator(_pid) {
    PROJECTS[_pid].auction.withdrawUnclaimedAuctionToken();
    emit UnclaimedAuctionTokenWithdrawn(_pid);
  }

  /**
   * @notice Withdraw unclaimed LP token
   * @param _pid Project ID
   */
  function withdrawUnclaimedLPToken(uint256 _pid)
    external isInitialized(_pid) onlyAuctionOperator(_pid) {
    PROJECTS[_pid].auction.withdrawUnclaimedLPToken();
    emit UnclaimedLPTokenWithdrawn(_pid);
  }

  /* ========== EXTERNAL VIEWS ========== */
  /**
   * @notice Get Project Status
   * @param _pid Project ID
   */
  function getProjectStatus(uint256 _pid)
    external view isInitialized(_pid) returns (ProjectStatus) {
    return PROJECTS[_pid].status;
  }

  /**
   * @notice Get Auction Address
   * @param _pid Project ID
   */
  function getAuctionAddress(uint256 _pid)
    external view isInitialized(_pid) returns (address) {
    return address(PROJECTS[_pid].auction);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
import "../launchpad/BatchAuction.sol";

/**
 * @dev Asset Data
 */
struct AssetData {
  uint128 emissionPerSecond;
  uint128 lastUpdateTimestamp;
  uint256 index;
  mapping(address => uint256) users;
}

/**
 * @dev Auction Data
 */
struct AuctionData {
  uint256 startTime;
  uint256 endTime;
  uint256 totalOfferingTokens;
  uint256 totalLPTokenAmount;
  uint256 minCommitmentsAmount;
  uint256 totalCommitments;
  bool finalized;
}

/// @notice Project Status
enum ProjectStatus {
  Initialized,
  Cancelled,
  Finalized
}

/// @notice Project Data
struct ProjectData {
  BatchAuction auction; 
  ProjectStatus status;
  address operator;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

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
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
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
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
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
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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
pragma solidity ^0.8.12;
pragma abicoder v2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../interfaces/interfaces.sol";
import "../interfaces/IPancakeFactoryV2.sol";
import "../interfaces/IPancakePair.sol";
import "../interfaces/IWETH.sol";

/**
 * @title BatchAuction
 * @author Planetarium
 */
contract BatchAuction is Ownable, ReentrancyGuard {
  using ECDSA for bytes32;
  using Math for uint256;
  using SafeERC20 for IERC20;

  /// @notice The auction token to sale
  IERC20 public AUCTION_TOKEN;

  /// @notice Auction Token Vault Address
  address public AUCTION_TOKEN_VAULT;

  /// @notice Where the auction funds will be transferred
  address payable public AUCTION_WALLET;

  /// @notice Auction Treasury Address
  address public AUCTION_TREASURY;

  /// @notice Amount of commitments per user
  mapping(address => uint256) private COMMITMENTS;

  /// @notice Amount of accumulated commitments per user
  mapping(address => uint256) private ACCUMULATED_COMMITMENTS;

  /// @notice Amount of accumulated withdrawals per user
  mapping(address => uint256) private ACCUMULATED_WITHDRAWALS;

  /// @notice To check if the user participated
  mapping(address => bool) private PARTICIPATED;

  /// @notice To count number of participants
  uint256 public numOfParticipants;

  /// @notice Amount of vested token claimed per user
  mapping(address => uint256) private VESTED_LPTOKEN_CLAIMED;

  /// @notice To check the user claimed instant token or not
  mapping(address => bool) private USER_RECEIVED_INSTANT_TOKEN;

  /// @notice Auction Data
  AuctionData private auctionData;

  /// @notice Withdraw cap variables
  uint256 private WITHDRAW_CAP_MIN;
  uint256 private WITHDRAW_CAP_MAX;
  uint256 private WITHDRAW_CAP_LIMIT;
  uint256 private WITHDRAW_CAP_INTERCEPT;
  uint256 private WITHDRAW_CAP_INTERCEPT_PLUS;
  uint256 private WITHDRAW_CAP_INTERCEPT_DIV;

  /// @notice Vesting period in second, 60 days => 5184000 seconds
  uint256 public VESTING_PERIOD;

  /// @notice Token claim period in second, 90 days => 7776000 seconds
  uint256 public CLAIMABLE_PERIOD;

  /// @notice To check commit currency is ETH(BNB) or ERC20 token
  address public COMMIT_CURRENCY;

  /// @notice ETH Address (ETH is BNB in BSC network)
  address private constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

  /// @notice WETH Address (WETH is WBNB in BSC Network)
  address private WETH_ADDRESS;

  /// @notice PancakeSwap Factory Address
  address private pancakeFactoryV2;

  /// @notice PancakeSwap LP Token
  address public PANCAKE_LPTOKEN;

  /// @notice Allowlist Signer
  address private ALLOWLIST_SIGNER;

  /// @notice name for creating domain separator
  string public constant name = 'BatchAuction V1';

  /// @notice domain separator
  bytes32 public DOMAIN_SEPARATOR;

  /* ========== EVENTS ========== */
  event AuctionInitialized(
    address _commitCurrency,
    IERC20 _auctionToken,
    address _auctionTokenVault,
    uint256 _startTime,
    uint256 _endTime,
    uint256 _totalOfferingTokens,
    uint256 _minimumCommitmentAmount,
    address _treasury,
    address _wallet
  );
  event AllowlistSignerConfigured(address indexed _addr);
  event ETHCommitted(address indexed _user, uint256 _amount);
  event TokenCommitted(address indexed _user, uint256 _amount);
  event CommitmentAdded(address indexed _user, uint256 _amount);
  event CommitmentWithdrawn(address indexed _user, uint256 _amount);
  event InstantTokenClaimed(address indexed _user, uint256 _amount, uint256 _userCommitments);
  event VestedLPTokenClaimed(address indexed _user, uint256 _amount);
  event ETHWithdrawn(address indexed _user, uint256 _amount);
  event ERC20TokenWithdrawan(address indexed _user, uint256 _amount);
  event UnclaimedTokenWithdrawan(address indexed _treasury, uint256 _amount);
  event UnclaimedLPTokenWithdrawn(address indexed _treasury, uint256 _amount);
  event GotCommitmentBack(address indexed _user, uint256 _amount);
  event AuctionTokenTransferredFromVault(address indexed _vault, uint256 _amount);
  event AuctionCancelled();
  event FinalizedAuctionWithFailure(uint256 _totalOfferingTokens);
  event FinalizedAuctionWithSuccess(
    uint256 _transferAmount,
    uint256 _token1Amount,
    uint256 _token2Amount,
    address _lpTokenAddress,
    uint256 _lpTokenAmount
  );
  event PancakeSwapPoolCreated(
    address _lpTokenAddress,
    uint256 _token1Amount,
    uint256 _token2Amount,
    uint256 _lpTokenAmount
  );

  /* ========== CONSTRUCTOR ========== */
  constructor(
    address _wethAddress,
    address _pancakeFactoryV2Address
  ) {
    WETH_ADDRESS = _wethAddress;
    pancakeFactoryV2 = _pancakeFactoryV2Address;

    /**
     * @dev creating DOMAIN_SEPARATOR
     * Reference: https://eips.ethereum.org/EIPS/eip-2612
     */
    uint chainId;
    assembly {
      chainId := chainid()
    }
    DOMAIN_SEPARATOR = keccak256(
      abi.encode(
        keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
        keccak256(bytes(name)),
        keccak256(bytes('1')),
        chainId,
        address(this)
      )
    );
  }

  /* ========== MODIFIERS ========== */
  /**
   * @notice only Auction Window
   */
  modifier isAuctionWindow {
    require(auctionData.startTime < block.timestamp 
            && block.timestamp < auctionData.endTime, "INVALID_AUCTION_TIME");
    require(!auctionData.finalized, "AUCTION_SHOULD_NOT_BE_FINALIZED"); 
    _;
  }

  /**
   * @notice Is Valid Claimable Period
   */
  modifier isClaimablePeriod {
    require(_isValidClaimablePeriod(), "INVALID_CLAIMABLE_PERIOD");
    _;
  }

  /**
   * @notice Is Claimable Period Ended
   */
  modifier isClaimablePeriodEnded {
    require((auctionData.endTime + CLAIMABLE_PERIOD) < block.timestamp, "CLAIMABLE_PERIOD_NOT_ENDED");
    _;
  }

  /**
   * @notice Is Auction Finalized With Success
   */
  modifier isAuctionFinalizedWithSuccess {
    require(auctionData.endTime < block.timestamp, "AUCTION_NOT_ENDED");
    require(isAuctionSuccessful(), "AUCTION_SHOULD_BE_SUCCESSFUL");
    require(auctionData.finalized, "AUCTION_SHOULD_BE_FINALIZED");
    _;
  }

  /**
   * @notice User can commitment back
   */
  modifier canCommitmentBack {
    require(auctionData.endTime < block.timestamp, "AUCTION_NOT_ENDED");
    require(!isAuctionSuccessful(), "AUCTION_SHOULD_BE_FAILED");
    require(auctionData.finalized, "AUCTION_SHOULD_BE_FINALIZED"); 
    require(COMMIT_CURRENCY != address(0), "INVALID_COMMIT_CURRENCY");
    _;
  }

  /**
   * @notice Operator can finalize the auction
   */
  modifier canFinalizeAuction {
    require(auctionData.endTime < block.timestamp, "AUCTION_NOT_ENDED");
    require(auctionData.totalOfferingTokens > 0, "NOT_INITIALIZED");
    require(!auctionData.finalized, "AUCTION_SHOULD_NOT_BE_FINALIZED"); 
    _;
  }

  /**
   * @notice can claim vested LP Tokens
   * @param _user Address of the user
   */
  modifier canClaimVestedLPToken(address _user) {
    require(COMMITMENTS[_user] > 0, "NO_COMMITMENTS");
    require(_isValidClaimablePeriod(), "INVALID_CLAIMABLE_PERIOD");
    _;
  }

  /**
   * @notice Set Allowlist Signer
   * @param _signer Allowlist Signer Address
   */
  function setAllowlistSigner(address _signer) external onlyOwner {
    require(_signer != address(0), "INVALID_ADDRESS");
    ALLOWLIST_SIGNER = _signer;
    emit AllowlistSignerConfigured(_signer);
  }

  /**
   * @notice Init Batch Auction
   * @param _commitCurrency Commit Currency
   * @param _auctionToken Auction Token
   * @param _auctionTokenVault Auction Token Vault
   * @param _startTime Start Time of the auction
   * @param _endTime End Time of the auction
   * @param _vestingPeriod Vesting Period
   * @param _claimablePeriod Claimable Period
   * @param _totalOfferingTokens Total Offering Tokens
   * @param _minimumCommitmentAmount Minimum Commitment Amount
   * @param _treasury Treasury Address
   * @param _wallet Auction Wallet Address
   */
  function initAuction(
    address _commitCurrency,
    IERC20 _auctionToken,
    address _auctionTokenVault,
    uint256 _startTime,
    uint256 _endTime,
    uint256 _vestingPeriod,
    uint256 _claimablePeriod,
    uint256 _totalOfferingTokens,
    uint256 _minimumCommitmentAmount,
    address _treasury,
    address payable _wallet
  ) external onlyOwner {
    require(_startTime > block.timestamp, "INVALID_AUCTION_START_TIME");
    require(_startTime < _endTime, "INVALID_AUCTION_END_TIME");
    require(_vestingPeriod > 0, "INVALID_VESTING_PERIOD");
    require(_claimablePeriod > 0, "INVALID_CLAIMABLE_PERIOD");
    require(_vestingPeriod < _claimablePeriod, "INVALID_PERIOD");
    require(_totalOfferingTokens > 0,"INVALID_TOTAL_OFFERING_TOKENS");
    require(_minimumCommitmentAmount > 0,"INVALID_MINIMUM_COMMITMENT_AMOUNT");
    require(_auctionTokenVault != address(0), "INVALID_AUCTION_TOKEN_VAULT");
    require(_treasury != address(0), "INVALID_TREASURY_ADDRESS");
    require(_wallet != address(0), "INVALID_AUCTION_WALLET_ADDRESS");

    COMMIT_CURRENCY = _commitCurrency;
    AUCTION_TOKEN = _auctionToken;
    AUCTION_TOKEN_VAULT = _auctionTokenVault;
    AUCTION_TREASURY = _treasury;
    AUCTION_WALLET = _wallet;
    VESTING_PERIOD = _vestingPeriod;
    CLAIMABLE_PERIOD = _claimablePeriod;

    auctionData.startTime = _startTime;
    auctionData.endTime = _endTime;
    auctionData.totalOfferingTokens = _totalOfferingTokens;
    auctionData.minCommitmentsAmount = _minimumCommitmentAmount;
    auctionData.finalized = false;
    auctionData.totalLPTokenAmount = 0;

    numOfParticipants = 0;

    if (COMMIT_CURRENCY == ETH_ADDRESS) {
      /// Commit Currency is ETH (BNB in BSC Network)
      WITHDRAW_CAP_MIN = 5e18; // 5 BNB
      WITHDRAW_CAP_MAX = 250e18; // 250 BNB
      WITHDRAW_CAP_LIMIT = 75e18; // 75 BNB
      WITHDRAW_CAP_INTERCEPT = 2; 
      WITHDRAW_CAP_INTERCEPT_PLUS = 25e18; // 25 BNB
      WITHDRAW_CAP_INTERCEPT_DIV = 7;
    } else {
      /// Commit Currency is ERC20 (BEP20 in BSC Network)
      WITHDRAW_CAP_MIN = 2000e18; //  2000 USDT
      WITHDRAW_CAP_MAX = 100000e18; // 10000 USDT
      WITHDRAW_CAP_LIMIT = 30000e18; //  30000 USDT
      WITHDRAW_CAP_INTERCEPT = 2;
      WITHDRAW_CAP_INTERCEPT_PLUS = 10000e18; // 10000 USDT
      WITHDRAW_CAP_INTERCEPT_DIV = 7;
    }

    emit AuctionInitialized(
      _commitCurrency,
      _auctionToken,
      _auctionTokenVault,
      _startTime,
      _endTime,
      _totalOfferingTokens,
      _minimumCommitmentAmount,
      _treasury,
      _wallet
    );
  }

  /**
   * @notice Transfer Auction Token to this contract
   * @dev Only Owner can call this function
   */
  function transferAuctionTokenFromVault() external onlyOwner nonReentrant {
    require(getAuctionTokenBalance() == 0, 'AUCTION_TOKEN_BALANCE_SHOULD_BE_ZERO');

    uint256 amount = auctionData.totalOfferingTokens;
    require(amount > 0, 'INVALID_TOTAL_OFFERING_TOKENS');

    IERC20(AUCTION_TOKEN).safeTransferFrom(AUCTION_TOKEN_VAULT, address(this), amount);

    emit AuctionTokenTransferredFromVault(AUCTION_TOKEN_VAULT, amount);
  }

  /**
   * @notice Cancel Auction Before Start
   * @dev Only Owner can cancel the auction before it starts
   */
  function cancelAuctionBeforeStart() external onlyOwner {
    require(!auctionData.finalized, "AUCTION_SHOULD_NOT_BE_FINALIZED"); 
    require(auctionData.totalCommitments == 0, "AUCTION_HAS_COMMITMENTS");

    IERC20(AUCTION_TOKEN).safeTransfer(AUCTION_TOKEN_VAULT, auctionData.totalOfferingTokens);

    auctionData.finalized = true;

    emit AuctionCancelled();
  }

  /**
   * @notice Commit ETH with signature
   * @param _signature Signature of the user
   */
  function commitETH(bytes calldata _signature) external payable isAuctionWindow {
    require(COMMIT_CURRENCY == ETH_ADDRESS, "INVALID_COMMIT_CURRENCY");
    require(isAllowlist(msg.sender, _signature), "USER_NOT_IN_ALLOWLIST");

    _addCommitment(msg.sender, msg.value);

    /// @dev Revert if totalCommitments exceeds the balance
    require(auctionData.totalCommitments <= address(this).balance, "INVALID_TOTAL_COMMITMENTS");

    emit ETHCommitted(msg.sender, msg.value);
  }

  /**
   * @notice Commit ERC20 Token with signature
   * @param _signature Signature of the user
   */
  function commitERC20Token(uint256 _amount, bytes calldata _signature) external isAuctionWindow {
    require(COMMIT_CURRENCY != ETH_ADDRESS, "INVALID_COMMIT_CURRENCY");
    require(isAllowlist(msg.sender, _signature), "USER_NOT_IN_ALLOWLIST");

    _addCommitment(msg.sender, _amount);

    IERC20(COMMIT_CURRENCY).safeTransferFrom(msg.sender, address(this), _amount);

    emit TokenCommitted(msg.sender, _amount);
  }
    
  /**
   * @notice Withdraw ETH during the auction
   * @param _amount Withdraw Amount
   */
  function withdrawETH(uint256 _amount) external isAuctionWindow nonReentrant {
    require(COMMIT_CURRENCY == ETH_ADDRESS, "INVALID_COMMIT_CURRENCY");

    _withdrawCommitment(msg.sender, _amount);

    _safeTransferETH(payable(msg.sender), _amount);

    emit ETHWithdrawn(msg.sender, _amount);
  }

  /**
   * @notice Withdraw ERC20 token during the auction
   * @param _amount Withdraw Amount
   */
  function withdrawERC20Token(uint256 _amount) external isAuctionWindow nonReentrant {
    require(COMMIT_CURRENCY != ETH_ADDRESS, "INVALID_COMMIT_CURRENCY");

    _withdrawCommitment(msg.sender, _amount);

    IERC20(COMMIT_CURRENCY).safeTransfer(msg.sender, _amount);

    emit ERC20TokenWithdrawan(msg.sender, _amount);
  }
  
  /**
   * @notice Claim Instant Token
   * @dev The Auction should be finalized with success and valid claimable period
   */
  function claimInstantToken() external isAuctionFinalizedWithSuccess isClaimablePeriod {
    require(!USER_RECEIVED_INSTANT_TOKEN[msg.sender], "USER_ALREADY_CLAIMED_INSTANT_TOKEN");

    uint256 amount = getInstantTokenAmount(msg.sender);
    require(amount > 0, "NOT_ENOUGH_TOKEN_TO_CLAIM");

    USER_RECEIVED_INSTANT_TOKEN[msg.sender] = true;
    IERC20(AUCTION_TOKEN).safeTransfer(msg.sender, amount);

    emit InstantTokenClaimed(msg.sender, amount, COMMITMENTS[msg.sender]);
  }

  /**
   * @notice Claim Vested LP Token
   * @dev The Auction should be finalized with success and can claim vested lp token
   */
  function claimVestedLPToken() external isAuctionFinalizedWithSuccess canClaimVestedLPToken(msg.sender) {
    uint256 amount = getActualVestedLPTokenAmount(msg.sender);
    require(amount > 0, "NOT_ENOUGH_VESTED_LPTOKEN_TO_CLAIM");

    VESTED_LPTOKEN_CLAIMED[msg.sender] += amount;
    IPancakePair(PANCAKE_LPTOKEN).transfer(msg.sender, amount);

    emit VestedLPTokenClaimed(msg.sender, amount);
  }

  /**
   * @notice withdraw unclaimed Auction token, transferring to Treasury.
   * @dev only operator can execute
   */
  function withdrawUnclaimedAuctionToken() external isClaimablePeriodEnded onlyOwner {
    uint256 amount = getAuctionTokenBalance();
    require(amount > 0, "INVALID_AMOUNT");

    IERC20(AUCTION_TOKEN).safeTransfer(AUCTION_TREASURY, amount);

    emit UnclaimedTokenWithdrawan(AUCTION_TREASURY, amount);
  }

  /**
   * @notice withdraw unclaimed LP token, transferring to Treasury.
   * @dev only operator can execute
   */
  function withdrawUnclaimedLPToken() external isClaimablePeriodEnded onlyOwner {
    uint256 amount = getLPTokenBalance();
    require(amount > 0, "INVALID_AMOUNT");

    IPancakePair(PANCAKE_LPTOKEN).transfer(AUCTION_TREASURY, amount);

    emit UnclaimedLPTokenWithdrawn(AUCTION_TREASURY, amount);
  }

  /**
   * @notice claim commitment when project failed (after auction finished and finalized)
   */
  function getCommitmentBack() external canCommitmentBack nonReentrant {
    uint256 userCommitted = COMMITMENTS[msg.sender];
    require(userCommitted > 0, "NO_COMMITMENTS");

    COMMITMENTS[msg.sender] = 0; 

    if(COMMIT_CURRENCY == ETH_ADDRESS) {
      _safeTransferETH(payable(msg.sender), userCommitted);
    } else {
      IERC20(COMMIT_CURRENCY).safeTransfer(msg.sender, userCommitted);
    }

    emit GotCommitmentBack(msg.sender, userCommitted);
  }

  /**
   * @notice Get Pancake LP Token if the pool exists
   * @return LP Token Address
   */
  function getPancakeLPToken(address _token1, address _token2) external view returns (address) {
    require(_token1 != address(0), "INVALID_TOKEN1_ADDRESS");
    require(_token2 != address(0), "INVALID_TOKEN2_ADDRESS");
    return IPancakeFactoryV2(pancakeFactoryV2).getPair(_token1, _token2);
  }

  /**
   * @notice Create Pancake LP Token if the pool does not exist
   * @return LP Token Address
   */
  function createPancakeLPToken(address _token1, address _token2) external returns (address) {
    require(_token1 != address(0), "INVALID_TOKEN1_ADDRESS");
    require(_token2 != address(0), "INVALID_TOKEN2_ADDRESS");
    return IPancakeFactoryV2(pancakeFactoryV2).createPair(_token1, _token2);
  }

  /**
   * @notice Finalize Auction with Success
   * @dev The auction was successful, transfer contributed tokens to the auction wallet. Only operator can execute.
   * @param _lpTokenAddress LP Token Address
   * @param _minLP minimum LP value expected to be minted
   */
  function finalizeAuctionWithSuccess(address _lpTokenAddress, uint256 _minLP) external canFinalizeAuction onlyOwner {
    require(_lpTokenAddress != address(0), "INVALID_LP_TOKEN_ADDRESS");
    require(isAuctionSuccessful(), "AUCTION_SHOULD_BE_SUCCESSFUL");

    /// 70% of funds goes to the AUCTION_WALLET
    uint256 transferAmount = (auctionData.totalCommitments * 7) / 10; // 70%

    if(COMMIT_CURRENCY == ETH_ADDRESS) {
      _safeTransferETH(AUCTION_WALLET, transferAmount);
    } else {
      IERC20(COMMIT_CURRENCY).safeTransfer(AUCTION_WALLET, transferAmount);
    }

    /// 30% of funds & 30% of AUCTION_TOKEN instantly goes to DEX POOL
    uint256 token1Amount = (auctionData.totalOfferingTokens * 3) / 10; // 30%
    uint256 token2Amount = (auctionData.totalCommitments * 3) / 10; // 30%

    PANCAKE_LPTOKEN = _lpTokenAddress;
    auctionData.totalLPTokenAmount = _setupPancakeSwapPool(
      _lpTokenAddress, address(AUCTION_TOKEN), COMMIT_CURRENCY,
      token1Amount, token2Amount, _minLP
    );

    require(auctionData.totalLPTokenAmount > 0, "INVALID_LPTOKEN_AMOUNT");

    emit FinalizedAuctionWithSuccess(
      transferAmount,
      token1Amount,
      token2Amount,
      _lpTokenAddress,
      auctionData.totalLPTokenAmount
    );
    
    auctionData.finalized = true;
  }

  /**
   * @notice Finalize Auction With Failure
   * @dev only operator can execute
   */
  function finalizeAuctionWithFailure() external canFinalizeAuction onlyOwner {
    require(!isAuctionSuccessful(), "AUCTION_SHOULD_NOT_BE_SUCCESSFUL");

    // If the auction was not successful, return auction tokens to the AUCTION_TOKEN_VAULT
    IERC20(AUCTION_TOKEN).safeTransfer(AUCTION_TOKEN_VAULT, auctionData.totalOfferingTokens);
    emit FinalizedAuctionWithFailure(auctionData.totalOfferingTokens);
    
    auctionData.finalized = true;
  }
  
  /* ========== PUBLIC VIEWS ========== */
  /**
   * @notice Is User in the allowlist
   * @param _user Address of the user
   * @param _signature Signature of the user
   * @return True if the user is in the allowlist
   */
  function isAllowlist(address _user, bytes calldata _signature) public view returns (bool) {
    return _verifySignature(_user, _signature, "ALLOWLIST");
  }

  /**
   * @notice Get Auction Token Balance
   * @return Auction token balance
   */
  function getAuctionTokenBalance() public view returns (uint256) {
    require(address(AUCTION_TOKEN) != address(0), "INVALID_AUCTION_TOKEN");
    return IERC20(AUCTION_TOKEN).balanceOf(address(this));
  }

  /**
   * @notice Get LP Token Balance
   * @return LP Token Balance
   */
  function getLPTokenBalance() public view returns (uint256) {
    require(PANCAKE_LPTOKEN != address(0), "INVALID_PANCAKE_LPTOKEN");
    return IPancakePair(PANCAKE_LPTOKEN).balanceOf(address(this));
  }

  /**
   * @notice Get estimated amount of instant tokens
   * @dev user can claim 70% of tokens instantly without vesting
   * @param _user Address of the user
   * @return Instant token amount
   */
  function getInstantTokenAmount(address _user) public view returns (uint256) {
    require(COMMITMENTS[_user] > 0, "NO_COMMITMENTS");
    uint256 userShare = (COMMITMENTS[_user] * 7) / 10; // 70%
    return (auctionData.totalOfferingTokens * userShare) / auctionData.totalCommitments;
  }

  /**
   * @notice Get actual vested lp token amount
   * @param _user Address of the user
   * @return Total vested LP Token amount
   */
  function getActualVestedLPTokenAmount(address _user)
    public view isAuctionFinalizedWithSuccess canClaimVestedLPToken(_user) returns (uint256) {
    return getTotalVestedLPTokenAmount(_user) - VESTED_LPTOKEN_CLAIMED[_user];
  }

  /**
   * @notice dev Get total vested lp token Amount with Vesting
   * @param _user Address of the user
   * @return Vested LP Token amount
   */
  function getTotalVestedLPTokenAmount(address _user) 
    public view isAuctionFinalizedWithSuccess canClaimVestedLPToken(_user) returns (uint256) {
    uint256 vestingTimeElapsed = block.timestamp - auctionData.endTime;
    if (vestingTimeElapsed > VESTING_PERIOD) {
      vestingTimeElapsed = VESTING_PERIOD;
    }

    return (getAllocatedLPTokenAmount(_user) * vestingTimeElapsed) / VESTING_PERIOD;
  }
  
  /**
   * @notice Get Allocated LP token amount for the user
   * @param _user Address of the user
   * @return Allocated LP Token amount
   */
  function getAllocatedLPTokenAmount(address _user)
    public view isAuctionFinalizedWithSuccess canClaimVestedLPToken(_user) returns (uint256) {
    uint256 userShare = (COMMITMENTS[_user] * 3) / 10; // 30%
    return (auctionData.totalLPTokenAmount * userShare) / auctionData.totalCommitments;
  }

  /**
   * @notice Checks if the auction was successful
   * @return True if tokens sold greater than or equals to the minimum commitment amount
   */
  function isAuctionSuccessful() public view returns (bool) {
    return auctionData.totalCommitments > 0 
      && (auctionData.totalCommitments >= auctionData.minCommitmentsAmount); 
  }

  /* ========== EXTERNAL VIEWS ========== */
  /**
   * @notice Get Auction Data
   */
  function getAuctionData() external view returns (AuctionData memory) {
    return auctionData;
  }

  /**
   * @notice Get the price of Token
   * @return Token price
   */
  function getTokenPrice() external view returns (uint256) {
    if (auctionData.totalCommitments > 0) {
      return (auctionData.totalCommitments * 1e18) / auctionData.totalOfferingTokens;
    } else {
      return 0;
    }
  }

  /**
   * @notice Get Allocated Return 
   * @param _user Address of the user
   * @return (Auction Token Allocated, LP Token Allocated)
   */
  function getAllocatedReturn(address _user)
    external view returns (uint256, uint256) {
    return _calcAllocatedReturn(COMMITMENTS[_user], 0);
  }

  /**
   * @notice Get Allocated Return after deposit
   * @param _user Address of the user
   * @param _deposit Deposit Amount
   * @return (Auction Token Allocated after deposit, LP Token Allocated after deposit)
   */
  function getAllocatedReturnAfterDeposit(address _user, uint256 _deposit)
    external view returns (uint256, uint256) {
    return _calcAllocatedReturn(COMMITMENTS[_user], _deposit);
  }
  
  /**
   * @notice Calculate the amount of Committed Token that can be withdrawn by user
   * @param _user Address of the user
   * @return withdrawable amount per user
   */
  function getWithdrawableAmount(address _user) external view returns (uint256) {
    return _withdrawableAmountPerUser(_user);
  }

  /**
   * @notice Get Committed amount of the user
   * @param _user Address of the user
   * @return Committed amount of the user
   */
  function getCommittedAmount(address _user) external view returns (uint256) {
    return COMMITMENTS[_user];
  }

  /**
   * @notice Get Total Locked amount of the user
   * @param _user Address of the user
   * @return Locked Amount of the user
   */
  function getLockedAmount(address _user) external view returns (uint256) {
    return COMMITMENTS[_user] - _withdrawableAmountPerUser(_user);
  }

  /**
   * @notice Calculate withdrawable amount after deposit
   * @param _user Address of the user
   * @param _deposit Deposit Amount
   * @return Withdrawable amount after deposit
   */
  function getWithdrawableAmountAfterDeposit(address _user, uint256 _deposit) external view returns (uint256) {
    return _withdrawableAmountAfterDeposit(_user, _deposit);
  }

  /**
   * @notice Calculate locked amount after deposit
   * @param _user Address of the user
   * @param _deposit Deposit Amount
   * @return Locked amount after deposit
   */
  function getLockedAmountAfterDeposit(address _user, uint256 _deposit) external view returns (uint256) {
    return (COMMITMENTS[_user] + _deposit) - _withdrawableAmountAfterDeposit(_user, _deposit);
  }

  /**
   * @notice Check if the user already received or not
   * @param _user Address of the user
   * @return True if user received instant token
   */
  function isUserReceivedInstantToken(address _user) external view returns (bool) {
    return USER_RECEIVED_INSTANT_TOKEN[_user];
  }

  /* ========== INTERNAL FUNCTIONS ========== */
  /**
   * @notice Safe Transfer ETH
   */
  function _safeTransferETH(address payable to, uint value) internal {
    (bool success,) = to.call{value:value}(new bytes(0));
    require(success, 'ETH_TRANSFER_FAILED');
  }

  /**
   * @notice Add Commitment
   * @param _user Address of the user
   * @param _amount Amount to add
   */
  function _addCommitment(address _user, uint256 _amount) internal isAuctionWindow {
    require(_amount > 0, "INVALID_AMOUNT");

    COMMITMENTS[_user] += _amount;
    ACCUMULATED_COMMITMENTS[_user] += _amount;
    auctionData.totalCommitments += _amount;

    if (!PARTICIPATED[_user]) {
      numOfParticipants += 1;
      PARTICIPATED[_user] = true;
    }

    emit CommitmentAdded(_user, _amount);
  }

  /**
   * @notice Withdraw Commitment
   * @param _user Address of the user
   * @param _amount Amount to withdraw
   */
  function _withdrawCommitment(address _user, uint256 _amount) internal isAuctionWindow {
    require(_amount > 0, "INVALID_AMOUNT");
    require(_amount <= COMMITMENTS[_user], "INSUFFICIENT_COMMITMENTS_BALANCE");
    require(_amount <= _withdrawableAmountPerUser(_user), "INVALID_WITHDRAW_AMOUNT");

    COMMITMENTS[_user] -= _amount;
    ACCUMULATED_WITHDRAWALS[_user] += _amount;
    auctionData.totalCommitments -= _amount;

    emit CommitmentWithdrawn(_user, _amount);
  }

  /**
   * @notice Withdrawable Amount After Deposit
   * @param _user Address of the user
   * @param _amount Amount to withdraw
   * @return Withdrawable Amount after deposit
   */
  function _withdrawableAmountAfterDeposit(address _user, uint256 _amount) internal view returns (uint256)  {
    require(_amount > 0, "INVALID_AMOUNT");
    return _withdrawableAmountPerCommitments(ACCUMULATED_COMMITMENTS[_user] + _amount) - ACCUMULATED_WITHDRAWALS[_user];
  }
 
  /**
   * @notice Calculate Withdrawable Amount based on user
   * @param _user Address of the user
   * @return Withdrawable Amount per user
   */
  function _withdrawableAmountPerUser(address _user) internal view returns (uint256) {
    require(COMMIT_CURRENCY != address(0), "INVALID_COMMIT_CURRENCY");
    return _withdrawableAmountPerCommitments(ACCUMULATED_COMMITMENTS[_user]) - ACCUMULATED_WITHDRAWALS[_user];
  }

  /**
   * @notice Calculate Withdrawable Amount based on Commitments
   * @param _amount Commitment
   * @return withdraw cap
   */
  function _withdrawableAmountPerCommitments(uint256 _amount) internal view returns (uint256) {
    if (_amount <= WITHDRAW_CAP_MIN) {
      return _amount;
    } else if (_amount < WITHDRAW_CAP_MAX) {
      return ((_amount * WITHDRAW_CAP_INTERCEPT) + WITHDRAW_CAP_INTERCEPT_PLUS) / WITHDRAW_CAP_INTERCEPT_DIV;
    } else { 
      return WITHDRAW_CAP_LIMIT;
    }
  }

  /**
   * @notice Calculate Allocated Return 
   * @param _userCommitment User Commitment
   * @param _deposit Deposit Amount
   * @return (Auction Token Allocated, LP Token Allocated)
   */
  function _calcAllocatedReturn(uint256 _userCommitment, uint256 _deposit)
    internal view returns (uint256, uint256) {
    require((_userCommitment + _deposit) > 0, "INVALID_COMMITMENT");
    uint256 auctionTokenAllocated =
      (auctionData.totalOfferingTokens * (_userCommitment + _deposit)) / (auctionData.totalCommitments + _deposit);
    uint256 lpTokenAllocated = ((_userCommitment + _deposit) * 3) / 10; // 30%
    return (auctionTokenAllocated, lpTokenAllocated);
  }

  /**
   * @notice Setup Pancake Swap Pool
   * @param _lpTokenAddress Pancake Swap LP Address
   * @param _token1 First Token
   * @param _token2 Second Token
   * @param _token1Amount First Token Amount
   * @param _token2Amount Second Token Amount
   * @param _minLP minimum LP value expected to be minted
   * @return LP Token Amount
   */
  function _setupPancakeSwapPool(
    address _lpTokenAddress,
    address _token1,
    address _token2,
    uint256 _token1Amount,
    uint256 _token2Amount,
    uint256 _minLP
  ) internal onlyOwner returns (uint256) {
    require(_lpTokenAddress != address(0), "INVALID_LP_ADDRESS");
    require(_token1Amount > 0, "INVALID_TOKEN1_AMOUNT");
    require(_token2Amount > 0, "INVALID_TOKEN2_AMOUNT");
    require(auctionData.endTime < block.timestamp, "AUCTION_NOT_ENDED");
    require(isAuctionSuccessful(), "AUCTION_SHOULD_BE_SUCCESSFUL");

    uint256 lpTokenAmount = 0;

    if(_token2 == ETH_ADDRESS) {
      _token2 = WETH_ADDRESS; // token2 should be WETH_ADDRESS (WETH is WBNB in BSC)
    }

    IERC20(_token1).safeTransfer(_lpTokenAddress, _token1Amount);

    if(_token2 == WETH_ADDRESS) {
      // If second token is WETH_ADDRESS
      IWETH(_token2).deposit{value: _token2Amount}();
      assert(IWETH(_token2).transfer(_lpTokenAddress, _token2Amount));
    } else {
      // If the second token is ERC20 (BEP20 in BSC Network)
      IERC20(_token2).safeTransfer(_lpTokenAddress, _token2Amount);
    }

    ///@dev mint LP token
    lpTokenAmount = IPancakePair(_lpTokenAddress).mint(address(this));
    require(_minLP <= lpTokenAmount, "LOWER_THAN_EXPECTED_LP_AMOUNT");

    emit PancakeSwapPoolCreated(_lpTokenAddress, _token1Amount, _token2Amount, lpTokenAmount);

    return lpTokenAmount;
  }

  /**
   * @notice Check Valid Claimable Period
   * @return True if valid
   */
  function _isValidClaimablePeriod() internal view returns (bool) {
    return (block.timestamp > auctionData.endTime
         && block.timestamp < (auctionData.endTime + CLAIMABLE_PERIOD));
  }

  /**
   * @notice Verify Signature
   * @param _user Address of the user
   * @param _signature Signature of the user
   * @param _state Allowlist string
   * @return True if verified
   */
  function _verifySignature(address _user, bytes memory _signature, string memory _state)
    internal view returns (bool) {
    return ALLOWLIST_SIGNER == keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32",
        bytes32(abi.encodePacked(_user, _state, DOMAIN_SEPARATOR)))
      ).recover(_signature);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface IWETH {
  function deposit() external payable;
  function transfer(address to, uint value) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface IPancakePair {
  function balanceOf(address owner) external view returns (uint);
  function transfer(address to, uint value) external returns (bool);
  function mint(address to) external returns (uint liquidity);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface IPancakeFactoryV2 {
  function getPair(address tokenA, address tokenB) external view returns (address pair);
  function createPair(address tokenA, address tokenB) external returns (address pair);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
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
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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