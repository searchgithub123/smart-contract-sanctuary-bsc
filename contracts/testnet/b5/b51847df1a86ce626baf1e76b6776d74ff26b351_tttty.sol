/**
 *Submitted for verification at BscScan.com on 2022-08-04
*/

// SPDX-License-Identifier: Unlicensed




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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;



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


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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


pragma solidity ^0.8.4;



contract tttty is Ownable {

    using SafeERC20 for IERC20;
    struct Users {
        uint id;
        address wallet;
        bool intttty;
        uint refCount;
        address invitedBy;
        address[] referrals;
    }
    
    struct Pools {
        uint slotActive;
        uint slotCount;
        bool status;
        mapping(address => uint) lastAction;
        mapping(address => uint) slotLimit;
        mapping(address => uint) earnAmount;
        mapping(address => uint) loseAmount;
        mapping(address => uint) earnByRef;
        mapping(address => uint[]) slots;
        mapping(uint => Slots) Slot;
        IERC20 payToken;
    }
    
    struct Slots {
        address user;
        uint    eventsCount;
        bool    rebuy;
        bool    reentry;
    }

    struct Stat {
        uint    earnOverall;
        uint    loseOverall;
        uint    userCount;
        uint    slotCount;
        uint    cycleCount;
        uint    rebuyBalance;
        uint16  poolCount;
    }

    Stat public stats;
    mapping(address => Users) public User;
    mapping(uint16 => Pools) public Pool;
    mapping(address => uint) public addressToId;
    mapping(uint => address) public idToAddress;
    mapping (address => bool) public Whitelisted;

    event addSlotEvent(uint indexed userid, address indexed wallet, uint16 indexed pool, uint slot, bool rebuy, bool reentry);    
    event payPowerlineEvent(address indexed from, address indexed to, uint amount, uint level, uint userid);
    event payAutopoolEvent(address indexed from, address indexed to, uint amount, uint16 indexed pool, bool refPayment, uint userid, uint slotid);

    mapping (uint => uint) public uplineAmount;
    mapping (uint => uint) public poolEntrance;
    mapping (uint => uint) public poolRebuyPercent;
    uint public _timeLimit = 86400;
    bool private prelaunch;
    address private ownerAddress;
    
    constructor(address _paymentToken, address _initAddress) {

        ownerAddress = _initAddress; 

        uplineAmount[1] = 50;
        uplineAmount[2] = 25;
        uplineAmount[3] = 15;
        uplineAmount[4] = 10;

        poolEntrance[1] = 60 * 10**18;
        poolEntrance[2] = 50 * 10**18;

        poolRebuyPercent[1] = 90;
        poolRebuyPercent[2] = 80;

        prelaunch = true;
        stats.userCount = 1;

        Users storage u = User[ownerAddress];
        u.id = stats.userCount;
        addressToId[ownerAddress] = stats.userCount;
        idToAddress[stats.userCount] = ownerAddress;
        u.wallet = ownerAddress;
        u.intttty = true;
        u.refCount = 0;
        u.invitedBy = address(ownerAddress);
        u.referrals = new address[](0);

        for (uint16 i = 1; i <= 2; i++) {
            Pools storage p = Pool[i];
            p.slotActive = 1;
            p.slotCount = 1;
            p.lastAction[ownerAddress] = block.timestamp;
            p.slotLimit[ownerAddress] = 1;
            p.status = true;
            p.payToken = IERC20(_paymentToken);
            p.Slot[1] = Slots({
                user: ownerAddress,
                eventsCount: 0,
                rebuy: false,
                reentry: false
            });
            p.slots[ownerAddress].push(1);
            stats.poolCount++;
            emit addSlotEvent(u.id, ownerAddress, i, 1, false, false);
        }
        stats.slotCount++;        
    }

    function buyGlobalSlot(uint16 _pool) public {
        uint16 poolID = _pool;
        address _buyer = msg.sender;
        Users storage u = User[_buyer];
        require(u.intttty == true, "Not registered in tttty");
        require(poolID > 1, "Require Globalpool ID");

        Pools storage p = Pool[poolID];
        require(p.status == true, "Pool paused");
        uint _resetTime = 0;
        if(p.slotLimit[_buyer] >= 10) {
            _resetTime = block.timestamp - p.lastAction[_buyer];
            if(_resetTime >= _timeLimit) p.slotLimit[_buyer] = 0;
        }
        p.lastAction[_buyer] = block.timestamp;
        if (prelaunch == true) { require ((p.slotLimit[_buyer] < 1), "Prelaunch slot limit exceed. Wait for launch."); }
        else { require ((p.slotLimit[_buyer] < 10), "Slot limit exceed. Wait for cooldown."); }

        p.slotLimit[_buyer]++;
        address _userActive = p.Slot[p.slotActive].user;

        uint amountToDistribute = poolEntrance[_pool];
        stats.earnOverall += amountToDistribute;

        require ((p.payToken.balanceOf(_buyer) >= poolEntrance[poolID]), "Insufficient balance to buySlot");
        uint256 allowance = p.payToken.allowance(_buyer, address(this));
        require(allowance >= poolEntrance[poolID], "Not enough allowance");
        p.payToken.safeTransferFrom(_buyer, address(this), poolEntrance[poolID]);

        // Pay Valid Referral Bonus
        payRefBonus(poolID, _buyer, amountToDistribute);
        // Pay To Global Active Slot
        bool reenter = payGlobalBonus(poolID, _buyer);
        // Create new Slot
        addSlot(poolID, _buyer, false, false);        

        // Pay Global Pool
        if (reenter) {            
            // rebuy under reentrance
            if (p.payToken.balanceOf(address(this)) >= poolEntrance[poolID]) {
                rebuyGlobalSlot(poolID);
            }

            /// Reentrance of closed slot
            addSlot(poolID, _userActive, false, true);
            stats.cycleCount++;
        }

        // rebuy at the end
        if (p.payToken.balanceOf(address(this)) >= poolEntrance[poolID]) {
            rebuyGlobalSlot(poolID);
        }
    } 

    function rebuyGlobalSlot(uint16 _pool) private {        
        uint16 poolID = _pool;
        address _buyer = ownerAddress;
        Pools storage p = Pool[poolID];
        p.lastAction[_buyer] = block.timestamp;
    
        address _userActive = p.Slot[p.slotActive].user;
        uint amountToDistribute = poolEntrance[_pool];
        stats.earnOverall += amountToDistribute;
        stats.rebuyBalance -= amountToDistribute;

        // Pay Valid Referral Bonus
        payRefBonus(poolID, _buyer, amountToDistribute);
        // Pay To Global Active Slot
        bool reenter = payGlobalBonus(poolID, _buyer);
        // Create new Slot
        addSlot(poolID, _buyer, true, false);

        // Pay Global Pool
        if (reenter) {
            /// Reentrance of closed slot
            addSlot(poolID, _userActive, false, true);
            // Set cursor to next active slot
            stats.cycleCount++;
        }        
    }

    function addSlot(uint16 _pool, address _user, bool _rebuy, bool _reentry) private {
        Pools storage p = Pool[_pool];
        // Increment slot count
        p.slotCount++;
        stats.slotCount++;
        // Add slot to user and pool
        p.slots[_user].push(p.slotCount);
        p.Slot[p.slotCount] = Slots({
            user: _user,
            eventsCount: 0,
            rebuy: _rebuy,
            reentry: _reentry
        });
        emit addSlotEvent(addressToId[_user], _user, _pool, p.slotCount, _rebuy, _reentry);
    }

    function findValidPayee(uint16 _pool, address _user, uint _amount) private returns(address _payee) {
        
        Users memory u = User[_user];
        Pools storage p = Pool[_pool];

        address _valid = address(0x0);
        uint _transferamount = getDistributeAmount(_amount, 1);
        address _checking = u.invitedBy;
        while(_valid == address(0x0)) {            
            Users memory userCheck = User[_checking];
            if (p.slots[userCheck.wallet].length > 0) {
                _valid = _checking;
            } else {
                _checking = userCheck.invitedBy;
                p.loseAmount[userCheck.wallet] += _transferamount;
            }
        }
        return(_valid);        
    }

    function payRefBonus(uint16 _pool, address _user, uint _amount) private {
        // Find Valid Referral
        address _to = findValidPayee(_pool, _user, _amount);
        uint _transferamount = getDistributeAmount(_amount, 1);
        if (_to == ownerAddress) {
            uint leavePercent = 100 - poolRebuyPercent[_pool];
            stats.rebuyBalance += _transferamount * poolRebuyPercent[_pool] / 100;
            _transferamount = _transferamount * leavePercent / 100;
        }
        Pools storage p = Pool[_pool];
        p.earnAmount[_to] += _transferamount;
        p.earnByRef[_to] += _transferamount;
        p.payToken.safeTransfer(_to, _transferamount);
        uint newSlot = p.slotCount + 1;
        emit payAutopoolEvent(_user, _to, _transferamount, _pool, true, addressToId[_user], newSlot);
    }

    function payGlobalBonus(uint16 _pool, address _user) private returns(bool reentrance) { 
        Pools storage p = Pool[_pool];
        address _to = p.Slot[p.slotActive].user;
        uint _amount = poolEntrance[_pool];
        uint _transferamount = getDistributeAmount(_amount, 1);
        if (_to == ownerAddress) {
            uint leavePercent = 100 - poolRebuyPercent[_pool];
            stats.rebuyBalance += _transferamount * poolRebuyPercent[_pool] / 100;
            _transferamount = _transferamount * leavePercent / 100;
        }
        p.earnAmount[_to] += _transferamount;
        p.payToken.safeTransfer(_to, _transferamount);

        uint newSlot = p.slotCount + 1;
        emit payAutopoolEvent(_user, _to, _transferamount, _pool, false, addressToId[_user], newSlot);
        p.Slot[p.slotActive].eventsCount++;
        if (p.Slot[p.slotActive].eventsCount == 3) { 
            p.slotActive++;
            return true;
        }
        return false;
        
    }

    function buyInitSlot(address _invitedBy) public {

        address _buyer = msg.sender;
        Users storage user = User[_buyer];
        require(user.intttty != true, "Already registered");
        if(prelaunch == true) require(Whitelisted[_buyer] == true, 'Not whitelisted');
        stats.userCount++;

        user.id = stats.userCount;
        user.wallet = _buyer;
        user.intttty = true;
        user.refCount = 0;
        user.invitedBy = _invitedBy;
        user.referrals = new address[](0);

        addressToId[_buyer] = stats.userCount;
        idToAddress[stats.userCount] = _buyer;

        Users storage r = User[_invitedBy];
        require(_buyer != _invitedBy && r.id > 0, "Invalid referral");

        r.referrals.push(_buyer);
        r.refCount++;        

        Pools storage p = Pool[1];
        p.slotCount++;
        p.slotActive++;
        p.Slot[p.slotCount] = Slots({
            user: _buyer,
            eventsCount: 0,
            rebuy: false,
            reentry: false
        });

        emit addSlotEvent(user.id, _buyer, 1, p.slotCount, false, false);

        require ((p.payToken.balanceOf(_buyer) >= poolEntrance[1]), "Insufficient balance");
        uint256 allowance = p.payToken.allowance(_buyer, address(this));
        require(allowance >= poolEntrance[1], "Not enough allowance");
        p.payToken.safeTransferFrom(_buyer, address(this), poolEntrance[1]);

        address sponsorAddress = _invitedBy;
        uint amountToDistribute = poolEntrance[1];
        stats.earnOverall += amountToDistribute;
        
        distributeInitPayment(sponsorAddress, amountToDistribute);
        
    }

    function distributeInitPayment(address sponsorAddress, uint amountToDistribute) private {
        Pools storage p = Pool[1];
        uint amountDistributed = 0;
        address _sponsor = sponsorAddress;
        for (uint8 i = 1; i <= 4; i++) {            
            if ( _sponsor != address(0x0) ) {
                uint _transferamount = getDistributeAmount(amountToDistribute, i);
                Users storage u = User[_sponsor];
                if(u.refCount > 0) {
                    if (_sponsor == ownerAddress) { _transferamount = 0; }
                    if (_transferamount > 0) {
                        amountDistributed += _transferamount;
                        p.earnAmount[_sponsor] += _transferamount;
                        p.payToken.safeTransfer(_sponsor, _transferamount);
                        emit payPowerlineEvent(msg.sender, _sponsor, _transferamount, i, addressToId[msg.sender]);
                    }
                }
                _sponsor = User[_sponsor].invitedBy;
            }            
        }
        uint _left = amountToDistribute - amountDistributed;
        if (_left > 0) {
            uint leavePercent = 100 - poolRebuyPercent[1];
            stats.rebuyBalance += _left * poolRebuyPercent[1] / 100;
            _left = _left * leavePercent / 100;
            p.earnAmount[ownerAddress] += _left;
            p.payToken.safeTransfer(ownerAddress, _left);
            emit payPowerlineEvent(msg.sender, ownerAddress, _left, 0, addressToId[msg.sender]);
        }
    }
        
    function getUserPoolSlots(address _user, uint16 _pool) public view returns (Slots[] memory) {
        Pools storage p = Pool[_pool];
        uint[] memory slots = p.slots[_user];
        Slots[] memory id = new Slots[](slots.length);
        for (uint i = 0; i < slots.length; i++) {
            Slots storage slot = p.Slot[slots[i]];
            id[i] = slot;
        }
        return id;
    }

    function getUserPoolData(address _user, uint16 _pool) public view returns (
        uint lastAction,
        uint slotLimit,
        uint earnAmount,
        uint loseAmount,
        uint earnByRef,
        uint[] memory slots
    ) {
        Pools storage p = Pool[_pool];
        return ( 
            p.lastAction[_user],
            p.slotLimit[_user],
            p.earnAmount[_user],
            p.loseAmount[_user],
            p.earnByRef[_user],
            p.slots[_user]
        );
    }

    function getUserData(address _user) public view returns (
        uint id,
        address wallet,
        uint refCount,
        address invitedBy,
        address[] memory referrals
    ) {
        Users memory u = User[_user];
        return (
            u.id,
            u.wallet,
            u.refCount,
            u.invitedBy,
            u.referrals
        );
    }

    function getDistributeAmount(uint amount, uint8 _level) private view returns(uint) {
        return(amount * uplineAmount[_level] / 100);
    }
    function setStateAndLimit(bool _state, uint timeLimit) public onlyOwner {
        if (_timeLimit > 0) _timeLimit = timeLimit;
        prelaunch = _state;
    }
    function modifyWhitelist(address[] memory _list) public onlyOwner returns(uint count) {
        uint _count = 0;
        for (uint256 i = 0; i < _list.length; i++) {
            if(Whitelisted[_list[i]] != true){
                Whitelisted[_list[i]] = true;
                _count++;
            }
        }
        return _count;
    }
    function createPool(address _paymentToken, uint _poolEntrance, uint _rebuyPercent) public onlyOwner {
        require(_rebuyPercent < 100, '_rebuyPercent require <100');
        stats.poolCount++;
        uint16 i = stats.poolCount;
        poolEntrance[i] = _poolEntrance;
        poolRebuyPercent[i] = _rebuyPercent;
        IERC20 poolToken = IERC20(_paymentToken);
        Pools storage p = Pool[i];
        p.slotActive = 1;
        p.slotCount = 1;
        p.lastAction[ownerAddress] = block.timestamp;
        p.slotLimit[ownerAddress] = 1;
        p.payToken = poolToken;
        p.status = true;
        p.Slot[1] = Slots({
            user: ownerAddress,
            eventsCount: 0,
            rebuy: false,
            reentry: false
        });
        p.slots[ownerAddress].push(1);
    }
    function setPool(bool _status, address _paymentToken, uint16 _pool, uint _rebuyPercent, uint _poolEntrance) public onlyOwner returns(
        bool status,
        uint16 pool, 
        address token, 
        uint rebuyPercent, 
        uint poolBuyCost
    ) {
        require(_pool > 1, "Require Globalpool ID");
        require(_rebuyPercent < 100, '_rebuyPercent require <100');
        Pools storage p = Pool[_pool];
        p.status = _status;
        p.payToken = IERC20(_paymentToken);
        poolRebuyPercent[_pool] = _rebuyPercent;
        poolEntrance[_pool] = _poolEntrance;
        return(_status, _pool, _paymentToken, _rebuyPercent, _poolEntrance);
    }
    function manualPush(uint16 _pool) public onlyOwner returns (bool) {
        require(_pool > 1, "Require Globalpool ID");
        Pools storage p = Pool[_pool];
        require (p.payToken.balanceOf(address(this)) >= poolEntrance[_pool], "Not enough balance");
        rebuyGlobalSlot(_pool);
        return true;
    }    
    function recoveryToken(address _token) public onlyOwner {
        IERC20 token = IERC20(_token);
        uint tokenBalance = token.balanceOf(address(this));
        token.safeTransfer(msg.sender, tokenBalance);
    }
    function recoveryFunds() public onlyOwner {
        address payable _owner = payable(msg.sender);
        _owner.transfer(address(this).balance);
    }
    receive() external payable {}
}