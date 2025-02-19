/**
 *Submitted for verification at BscScan.com on 2023-03-03
*/

// Sources flattened with hardhat v2.9.3 https://hardhat.org
// SPDX-License-Identifier: MIT
// File @openzeppelin/contracts-upgradeable/utils/[email protected]


// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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


// File @openzeppelin/contracts-upgradeable/proxy/utils/[email protected]


// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

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
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
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
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
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
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}


// File @openzeppelin/contracts-upgradeable/utils/[email protected]


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


// File @openzeppelin/contracts-upgradeable/access/[email protected]


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


// File @openzeppelin/contracts-upgradeable/security/[email protected]


// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}


// File contracts/MetafameSale_Lottery_t_v2.sol

//2023-02-17 ver.

pragma solidity ^0.8.10;


/**
* @title Metafame NFT 附屬的抽獎合約
* @notice 輸入抽獎者，並於一定條件達成後進行抽獎
*/
contract MetafameLotteryV0_5 is OwnableUpgradeable, PausableUpgradeable{

    bool public status;                //參加狀態，若為true才開放投入參加者
    uint256 public round;              //目前第幾輪

    address[] public players;          //抽獎者池
    address[] public winnerPool;       //獲獎者池

    uint256[] public prizeAmount;      //各獎項數量
    uint256[] public prizePercent;     //各獎項百分比(單位%)
    uint256[] public prizePerPeople;   //各獎項之獲獎者一人可獲得之獎金數量
    uint256 public pickTimesLimit;     //單輪抽獎次數上限
    uint256 public poolPercent;        //營收占比(單位%)
    uint256 public poolRequirement;    //開獎所需獎金
    uint256[3] public mintTickets;     //tier對應的抽獎券數量(mint)
    uint256[3] public shareTickets;    //tier對應的抽獎券數量(share)
    uint256 public ticketLimitPerRound;//每一輪的獎金總數上限

    struct Info{
        uint256 now;            //目前有多少
        uint256 total;          //最多有多少
    }
    struct TicketInfo{
        uint256 amount;         //張數
        uint256 timestamp;      //時間
        uint256 from;           //分享的NFT ID (若mint則為自己)
    }
    struct PlayerInfo{
        uint256 total;          //累積抽獎券數
        uint256 receiveTimes;   //獲得抽獎券的次數
        uint256 getPrizeTimes;  //獲獎次數
    }
    struct GetPrizeInfo{
        uint256 timestamp;      //獲獎區塊時間
        uint256 prizeIndex;     //獲獎的winner pool index
    }

    mapping(uint256 => Info) public prize;                                //獎金總數資訊 round => Info    
    mapping(uint256 => Info) public ticket;                               //抽獎券數數資訊 round => Info
    mapping(uint256 => mapping(address => TicketInfo[])) public receiveHistory; //參加者之獲券資訊紀錄 round => (address => Tickets[])
    mapping(uint256 => mapping(address => PlayerInfo)) public playerInfo;       //參加者之獎券數量資訊 round => (address => PlayerInfo)
    mapping(uint256 => mapping(address => GetPrizeInfo[])) public playerGetPrizeHistory;            //參加者之獲獎資訊紀錄 round => (address => GetPrizeInfo[])

    event Participate(uint256 tickets, address indexed userAddr, uint256 priceAmount);
    event Add(uint256 tickets, address indexed userAddr, uint256 nftId);
    event Pick(uint256 indexed roundId, uint256 indexed pickTimes);
    event SetRoundId(uint256 indexed roundId);

    address public adminAddress;       //操作者帳戶(屬於owner)
    address public admin2Address;       //操作者帳戶2(屬於owner)

    /**
    * @dev 合約參數初始化
    *      - 手動部署後必先執行此函式、合約預設初始為未暫停狀態與關閉參加狀態
    */
    function initialize() initializer public {
        __Ownable_init();
        __Pausable_init();

        status = false;
        prizeAmount = [1,5,20,100,200,500];
        pickTimesLimit = 826;
        prizePercent = [15,10,10,20,20,25]; 
        prizePerPeople = [11400,1520,380,152,76,38];
        mintTickets = [60,22,2];
        shareTickets = [30,11,1];

        poolPercent = 8;
        poolRequirement = 950000;
        ticketLimitPerRound = 247500; //兩倍

        adminAddress = 0xa95f48396B0530D3208B607CBe0b43705af25571;
        admin2Address = 0xA2669Ca2810Ed2AB3b0ad2526D42A47EaaDC5945;
    }

    /**
    * @dev 使用者購買NFT後，管理者將抽獎券加入到players抽獎池當中
    *      - 只有管理者帳戶能執行、合約未暫停時才可執行、參加狀態(status)為true才可執行
    * @param tickets    此次要加入的抽獎券數量，必須大於0
    * @param userAddr    要加入的抽獎者帳戶地址，不可為address(0)
    * @param priceAmount 此批抽獎券對應到的NFT價格總額，應大於0，並且當下應未達獎金上限
    * @param nftId    購買者買到的nftId
    */
    function participate(
        uint256 tickets, 
        address userAddr, 
        uint256 priceAmount,
        uint256 nftId
        ) 
        whenNotPaused 
        statusCheck
        inputCheck(tickets, userAddr, nftId) 
        senderCheck 
        public 
        {
        require(priceAmount > 0, "Metafame_Lottery: Wrong price amount");
        require(prize[round].now < prize[round].total, "Metafame_Lottery: The prize amount is too much");

        //寫入金額、票券數量到now
        prize[round].now += priceAmount;
        ticket[round].now += tickets;
        playerInfo[round][userAddr].total += tickets;
        playerInfo[round][userAddr].receiveTimes += 1;
        receiveHistory[round][userAddr].push(TicketInfo(tickets,block.timestamp,nftId));

        for(uint i=0 ; i<tickets ; i++){
            players.push(userAddr);
        }
        
        emit Participate(tickets, userAddr, priceAmount);
        
    }

    /**
    * @dev 使用者透過購買NFT以外之管道獲得抽獎券，管理者將抽獎券加入到players抽獎池當中
    *      - 只有管理者帳戶能執行、合約未暫停時才可執行、參加狀態(status)為true才可執行
    * @param tickets    此次要加入的抽獎券數量，必須大於0
    * @param userAddr    要加入的抽獎者帳戶地址，不可為address(0)
    * @param nftId    分享者的nftId
    */
    function addTicket(
        uint256 tickets, 
        address userAddr,
        uint256 nftId
        ) 
        whenNotPaused 
        statusCheck 
        inputCheck(tickets, userAddr, nftId)
        senderCheck 
        public 
        {
        ticket[round].now += tickets;
        playerInfo[round][userAddr].total += tickets;
        playerInfo[round][userAddr].receiveTimes += 1;
        receiveHistory[round][userAddr].push(TicketInfo(tickets,block.timestamp,nftId));

        for(uint i=0 ; i<tickets ; i++){
            players.push(userAddr);
        }

        emit Add(tickets, userAddr, nftId);
    }

    /**
    * @dev 管理者從palyers抽獎池當中抽出所有獎項，按照順序加入到winnerPool獲獎池當中，接著會將參加狀態(status)關閉轉換為false
    *      - 只有管理者帳戶能執行、合約未暫停時才可執行、參加狀態(status)為true才可執行
    * @param pickTimes    此次要抽獎的次數(應為所有獎項數量之總和)，必須大於０
    */
    function pickWinner(
        uint256 pickTimes
        ) 
        whenNotPaused 
        statusCheck 
        senderCheck2 
        public 
        {
        require(players.length > 0, "Metafame_Lottery: There are no player in this round");
        require((pickTimes + winnerPool.length) <= pickTimesLimit, "Metafame_Lottery: Too much pick times");
        require(prize[round].now >= prize[round].total, "Metafame_Lottery: Prize amount is not enough to pick winners");

        uint256 index;
        address[] memory _players = players;
        for(uint i=0 ; i<pickTimes ; i++){
            index = random() % _players.length;
            winnerPool.push(_players[index]);
            playerInfo[round][_players[index]].getPrizeTimes += 1;
            playerGetPrizeHistory[round][_players[index]].push(GetPrizeInfo(block.timestamp, winnerPool.length-1));
        }
        
        //抽獎完之後將參加抽獎狀態改成false
        if( winnerPool.length == pickTimesLimit){
            status = false;
        }
        
        emit Pick(round, pickTimes);
    }

    /**
    * @dev 查詢抽獎池
    * @return 所有的參加者帳戶(會重複)
    */
    function getPlayers() public view returns (address[] memory) {
        return players;
    }
    
    /**
    * @dev 查詢獲獎池
    * @return 所有的獲獎者帳戶(可能重複)
    */
    function getWinnerPool() public view returns (address[] memory) {
        return winnerPool;
    }

    /**
    * @dev 管理者設定新的輪次，接著會將參加狀態(status)開啟轉換為true
    *      - 只有管理者帳戶能執行、合約暫停時才可執行
    * @param id    要設定的輪次id
    */
    function setRoundId(uint256 id) onlyOwner whenPaused public {
        require(id == round + 1, "Metafame_Lottery: Wrong id");
        require(id > 0 && id < 5, "Metafame_Lottery: Wrong id");
        round = id;
        prize[id].total = poolRequirement;
        ticket[id].total = ticketLimitPerRound;

        //重置array
        delete players;
        delete winnerPool;

        //新輪次將參加抽獎狀態改成true
        status = true;

        emit SetRoundId(id);
    }

    /**
    * @dev 管理者設定每個獎項的數量
    *      - 只有管理者帳戶能執行、合約暫停時才可執行
    * @param prizeArray[]    要設定的獎項數量陣列
    */
    function setPrizeAmount(uint256[] calldata prizeArray) onlyOwner whenPaused public {
        delete prizeAmount;
        prizeAmount = prizeArray;
        pickTimesLimit = 0;
        for(uint i=0 ; i<prizeArray.length ; i++){
            pickTimesLimit += prizeArray[i];
        }
    } 

    /**
    * @dev 管理者設定每個獎項的百分比
    *      - 只有管理者帳戶能執行、合約暫停時才可執行
    * @param percentArray[]    要設定的獎項百分比陣列
    */
    function setPrizePercent(uint256[] calldata percentArray) onlyOwner whenPaused public {
        delete prizePercent;
        prizePercent = percentArray;
    }

    /**
    * @dev 管理者設定每個獎項的獎金
    *      - 只有管理者帳戶能執行、合約暫停時才可執行
    * @param prizeArray[]    要設定的獎項獎金陣列
    */
    function setPrizePerPeople(uint256[] calldata prizeArray) onlyOwner whenPaused public {
        delete prizePerPeople;
        prizePerPeople = prizeArray;
    }

    /**
    * @dev 管理者設定抽獎次數上限(通常要等於獎項數量總和)
    *      - 只有管理者帳戶能執行、合約暫停時才可執行
    * @param limit    要設定的上限
    */
    function setPickTimesLimit(uint256 limit) onlyOwner whenPaused public {
        pickTimesLimit = limit;
    }

    /**
    * @dev 管理者設定每個tier對應的抽獎券數量(from mint)
    *      - 只有管理者帳戶能執行、合約暫停時才可執行
    * @param ticketArray[]    要設定的抽獎券數量陣列
    */
    function setMintTickets(uint256[3] calldata ticketArray) onlyOwner whenPaused public {
        delete mintTickets;
        mintTickets = ticketArray;
    }

    /**
    * @dev 管理者設定每個tier對應的抽獎券數量(from share)
    *      - 只有管理者帳戶能執行、合約暫停時才可執行
    * @param ticketArray[]    要設定的抽獎券數量陣列
    */
    function setShareTickets(uint256[3] calldata ticketArray) onlyOwner whenPaused public {
        delete shareTickets;
        shareTickets = ticketArray;
    } 

    /**
    * @dev 管理者設定營運獎金百分比
    *      - 只有管理者帳戶能執行、合約暫停時才可執行
    * @param percent    要設定的百分比
    */
    function setPoolPercent(uint256 percent) onlyOwner whenPaused public {
        poolPercent = percent;
    }

    /**
    * @dev 管理者設定開獎所需獎金
    *      - 只有管理者帳戶能執行、合約暫停時才可執行
    * @param number    要設定的開獎所需獎金
    */
    function setPoolRequirement(uint256 number) onlyOwner whenPaused public {
        poolRequirement = number;
    } 

    /**
    * @dev 管理者設定每輪抽獎券總數上限
    *      - 只有管理者帳戶能執行、合約暫停時才可執行
    * @param limit    要設定的上限
    */
    function setTicketLimitPerRound(uint256 limit) onlyOwner whenPaused public {
        ticketLimitPerRound = limit;
    }

    /**
    * @dev 管理者設定admin帳戶地址
    *      - 只有管理者帳戶能執行、合約暫停時才可執行
    * @param addr    要設定的帳戶地址
    */
    function setAdminAddress(address addr) onlyOwner whenPaused public {
        adminAddress = addr;
    }

    /**
    * @dev 管理者設定admin2帳戶地址
    *      - 只有管理者帳戶能執行、合約暫停時才可執行
    * @param addr    要設定的帳戶地址
    */
    function setAdmin2Address(address addr) onlyOwner whenPaused public {
        admin2Address = addr;
    }

    /**
    * @dev 抽獎時產生隨機數
    */
    function random() private view returns(uint) {
        return uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty, winnerPool.length)));
    }

    /**
    * @dev 暫停合約
    *      - 只有管理者帳戶能執行
    */
    function pause() onlyOwner public  {
        _pause();
    }

    /**
    * @dev 解除暫停合約
    *      - 只有管理者帳戶能執行
    */
    function unpause() onlyOwner public {
        _unpause();
    }

    /**
    * @dev 狀態檢查
    */
    modifier statusCheck() {
        require(status == true, "Metafame_Lottery: Wrong status");
        _;
    }

    /**
    * @dev 呼叫者檢查
    */
    modifier senderCheck() {
        require(_msgSender() == adminAddress || _msgSender() == owner(), "Metafame_Lottery: Invalid msg sender");
        _;
    }

    /**
    * @dev 呼叫者檢查2
    */
    modifier senderCheck2() {
        require(_msgSender() == admin2Address || _msgSender() == owner(), "Metafame_Lottery: Invalid msg sender");
        _;
    }

    /**
    * @dev 輸入檢查
    */
    modifier inputCheck(uint256 tickets, address userAddr, uint256 nftId) {
        require(tickets > 0, "Metafame_Lottery: Wrong tickets number");
        require(userAddr != address(0), "Metafame_Lottery: Wrong address");
        require(nftId > 0, "Metafame_Lottery: Wrong nftId");
        _;
    }

    /**
    * @dev 查詢獎項數量
    * @return 所有的獎項數量資訊
    */
    function getPrizeAmount() public view returns (uint256[] memory) {
        return prizeAmount;
    }

    /**
    * @dev 查詢獎項對應之每人獎金
    * @return 所有的獎項獎金資訊
    */
    function getPrizePerPeople() public view returns (uint256[] memory) {
        return prizePerPeople;
    }

    /**
    * @dev 查詢獎項對應之獎金佔比
    * @return 所有的獎項獎金佔比資訊
    */
    function getPrizePercent() public view returns (uint256[] memory) {
        return prizePercent;
    }

    /**
    * @dev 查詢該輪獎金是否已達開獎門檻
    * @return 是否已達開獎門檻(true/false)
    */
    function getCanDraw(uint256 _round) public view returns (bool) {
        if(prize[_round].now >= poolRequirement){
            return true;
        }
        else{
            return false;
        }
    }

    /**
    * @dev 查詢該輪獎金目前累積多少
    * @return 累積獎金
    */
    function getCurrentPrize(uint256 _round) public view returns (uint256) {
        return prize[_round].now;
    }

}