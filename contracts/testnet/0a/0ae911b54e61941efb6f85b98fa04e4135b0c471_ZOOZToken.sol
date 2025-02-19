/**
 *Submitted for verification at BscScan.com on 2023-02-06
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

/*
███████  ██████   ██████  ███████     ████████  ██████  ██   ██ ███████ ███    ██ 
   ███  ██    ██ ██    ██    ███         ██    ██    ██ ██  ██  ██      ████   ██ 
  ███   ██    ██ ██    ██   ███          ██    ██    ██ █████   █████   ██ ██  ██ 
 ███    ██    ██ ██    ██  ███           ██    ██    ██ ██  ██  ██      ██  ██ ██ 
███████  ██████   ██████  ███████        ██     ██████  ██   ██ ███████ ██   ████ 
                                                                                                                                                             

WebSite: https://zooz.finance
GitHub: https://github.com/coalichain/ZOOZToken
*/

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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
     * plain`call` is an unsafe replacement for a function call: use this
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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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
        return a + b;
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
        return a - b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
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
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

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

/**
 * @dev PinkAntiBot Interface
 */
interface IPinkAntiBot {
  function setTokenOwner(address owner) external;

  function onPreTransferCheck(
    address from,
    address to,
    uint256 amount
  ) external;
}

/**
 * @dev ZOOZ Token 
 */
contract ZOOZToken is Ownable, IERC20 {
	IPinkAntiBot public pinkAntiBot;
	bool public antiBotEnabled = false;
	
	using SafeMath for uint256;
	using Address for address;
	
	mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => Holder) internal _balances;

	mapping (address => bool) internal _pairs;
    mapping (address => mapping (address => bool)) internal _bots;
    mapping (address => mapping (address => bool)) internal _blocked;
	
	string public name = 'ZOOZ Token';
    string public symbol = 'ZOOZ';
    uint8 public decimals = 9;
	uint256 public _totalSupply = 750 * 10**6 * 10**9;

	address public rewardsAddress = address(0);	
	address public managerAddress = address(0);	
	
	address public governance1Address = address(0);	
	address public governance2Address = address(0);	
	address public governance3Address = address(0);	
	
	event RewardAddressChanged(
        address rewardsAddress
    );	
	
	event ManagerAddressChanged(
        address managerAddress
    );
	
	event GovernanceAddressChanged(
        address governance,
		uint number
    );
	
	event PairAddressAdded(
        address pairAddress
    );
	
	event PairAddressRemoved(
        address pairAddress
    );
	
	event BotAddressAdded(
        address botAddress
	);	
	
	event BotAddressRemoved(
        address botAddress
    );
	
	event AddressBlocked(
        address blockedAddress
    );
	
	event AddressUnblocked(
        address unblockedAddress
    );

	modifier onlyManager() {
        require(managerAddress == _msgSender() || owner() == _msgSender(), "ZOOZ: caller is not allowed");
        _;
    }
	
	modifier onlyGovernance() {
        require(governance1Address == _msgSender() 
				|| governance2Address == _msgSender() 
				|| governance3Address == _msgSender() 
				|| owner() == _msgSender(), "ZOOZ: caller is not allowed");
        _;
    }
	
	struct Holder {
        uint256 token;  
		uint timestamp;
    }
	
	struct HolderView {
		address addr;
        uint256 token;  
		uint timestamp;
    }

	constructor() {
		_balances[_msgSender()].token = _totalSupply;
		_balances[_msgSender()].timestamp = block.timestamp;
		
		emit Transfer(address(0), _msgSender(), _totalSupply);
	}
		 
	function totalSupply() public view override returns (uint256)  {
		return _totalSupply;
    }
	
	function balanceOf(address account) public view override returns (uint256)  {
		return _balances[account].token;
    }
	
	function timestampOf(address account) public view returns (uint256)  {
		return _balances[account].timestamp;
    }
	
	function balancesOf(address[] memory accounts) public view returns (HolderView[] memory)  {
		HolderView[] memory tmp = new HolderView[](accounts.length);

        for (uint i = 0; i < accounts.length; i++) {
            tmp[i].token = _balances[accounts[i]].token;
            tmp[i].timestamp = _balances[accounts[i]].timestamp;
            tmp[i].addr = accounts[i];
        }

        return tmp;
    }
	
	function transfer(address recipient, uint256 amount) public override returns (bool) {
		 _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "Transfer amount exceeds allowance"));
        return true;
    }
	
	function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "Approve from the zero address");
        require(spender != address(0), "Approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
	
	function _transfer(address sender, address recipient, uint256 amount) private {
        require(!_isBlocked(sender) && !_isBlocked(recipient), "This address is blocked, contact the governance team");
		
		if (antiBotEnabled)
			pinkAntiBot.onPreTransferCheck(sender, recipient, amount);
		
		bool isBot = _isBot(sender) || _isBot(recipient);
		
		if(!isBot && _pairs[recipient]) {
			uint fees = _getFees(_balances[sender].timestamp);
			
			uint256 rewardAmount = amount.mul(fees).div(100);
			amount = amount.sub(rewardAmount);

			_stdTransfer(sender, rewardsAddress, rewardAmount);
		}
		
		_holdDateHook(sender, recipient);
		_stdTransfer(sender, recipient, amount);
	}

	/**
	* @dev determine if addr is blocked or not
	*/
	function _isBlocked(address addr) internal view returns(bool) {
		return _blocked[addr][governance1Address] 
				&& _blocked[addr][governance2Address] 
				&& _blocked[addr][governance3Address];
	}

	/**
	* @dev determine if addr is a bot or not
	*/
	function _isBot(address addr) internal view returns(bool) {
		return _bots[addr][governance1Address] 
				&& _bots[addr][governance2Address] 
				&& _bots[addr][governance3Address];
	}
	 
	/**
     * @dev get fees depending on the hold time
     */
	function _getFees(uint timestamp) internal view returns(uint256) {
		if(timestamp == 0 || timestamp >= block.timestamp) 
			return 14;

		uint diff = block.timestamp - timestamp;

		// 1 Week: 3600 * 24 * 7
		if(diff <= 604800) 
			return 14;

		// 1 Month: 3600 * 24 * 30
		if(diff <= 2592000) 
			return 10;		

		// 3 Months: 3600 * 24 * 30 * 3
		if(diff <= 7776000) 
			return 5;

		// 6 Months: 3600 * 24 * 30 * 6
		if(diff <= 15552000) 
			return 2;

		// > 6 Months
		return 0; 
	}	

	/**
     * @dev change sender and recipiend timestamp wallet date 
     */
	function _holdDateHook(address sender, address recipient) internal {
		if(_balances[recipient].timestamp == 0)
			_balances[recipient].timestamp = block.timestamp;
			
		_balances[sender].timestamp = block.timestamp;
    }
	
	/**
     * @dev standard erc20 transfer 
     */
	function _stdTransfer(address sender, address recipient, uint256 amount) private {
		if(amount == 0)
			return;
		
		_balances[sender].token = _balances[sender].token.sub(amount, "transfer amount exceeds balance");
		_balances[recipient].token = _balances[recipient].token.add(amount);
		
		emit Transfer(sender, recipient, amount);
	}
	
	/**
     * @dev change manager address
     */
	function setManagerAddress(address newAddress) public onlyManager()  {
		managerAddress = newAddress;
		
		emit ManagerAddressChanged(managerAddress);
    }	
	
	/**
     * @dev change rewards address
     */
	function setRewardsTeamAddress(address newAddress) public onlyManager()  {
		rewardsAddress = newAddress;
		
		emit RewardAddressChanged(rewardsAddress);
    }
	
	/**
     * @dev block or unblock an holder
     */
	function setBlocked(address holderAddress, bool blocked) public onlyGovernance()  {
		require(holderAddress != address(0), "HolderAddress can't be the zero address");
			
        _blocked[holderAddress][_msgSender()] = blocked;
		 		
		if(blocked) {
			emit AddressBlocked(holderAddress);
			return;
		}
		
		emit AddressUnblocked(holderAddress);
    }	
	
	/**
     * @dev add or remove bot 
     */
	function setBot(address botAddress, bool isbot) public onlyGovernance()  {
		require(botAddress != address(0), "BotAddress can't be the zero address");
		
		_bots[botAddress][_msgSender()] = isbot;

		if(isbot) {
			emit BotAddressAdded(botAddress);
			return;
		}
		
		emit BotAddressRemoved(botAddress);
    }	
	
	/**
     * @dev add or remove pair address 
     */
	function setPair(address pairAddress, bool isPair) public onlyManager()  {
        require(pairAddress != address(0), "PairAddress can't be the zero address");

        _pairs[pairAddress] = isPair;
		
		if(isPair) {
			emit PairAddressAdded(pairAddress);
			return;
		}
		
		emit PairAddressRemoved(pairAddress);
    }	
	
	/**
     * @dev enabled or disabled pinksale antibot system
     */
	function setEnableAntiBot(bool enable) external onlyManager() {
		antiBotEnabled = enable;
	}
	
	/**
     * @dev change pinksale antibot system address
     */
	function setAntiBotAddr(address pinkbotAddr) external onlyManager() {
		pinkAntiBot = IPinkAntiBot(pinkbotAddr);
		pinkAntiBot.setTokenOwner(msg.sender);
	}
	
	/**
     * @dev add or remove gouvernance
     */
	function setGovernance(address governanceAddress, uint number) public onlyOwner()  {
		require(governanceAddress != address(0), "GovernanceAddress can't be the zero address");
		require(number >= 1 && number <= 3, "Number must be 1, 2 or 3");
		
		if(number == 1) 
			governance1Address = governanceAddress;
		if(number == 2) 
			governance2Address = governanceAddress;
		if(number == 3) 
			governance3Address = governanceAddress;
		
		emit GovernanceAddressChanged(governanceAddress, number);
    }	
}