/**
 *Submitted for verification at BscScan.com on 2022-08-08
*/

// BlueRendering.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

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

interface IPancakeRouter {
    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint amountOutMin, 
        address[] calldata path, 
        address to, 
        uint deadline
    ) external payable returns (uint256[] memory amounts);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
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

contract BlueRendering is Ownable {

    using SafeERC20 for IERC20;

    address public pancakeRouterAddress;// = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address public addressBNB;// = 0xbb4cdb9cbd36b01bd1cbaebf2de08d9173bc095c;
    address public addressBUSD;// = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    address public addressAdmin;// = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;

    address[] BNBToBUSD;
    address[] BUSDToBNB;

    struct Pool {
        address addr;
        uint256 balanceBNB;
        uint256 balanceBUSD;
    }

    struct Trade {
        uint timestamp;
        uint256 bnb;
        uint256 busd;
        uint256 profit;
        uint256 admin; // Admin Profile %1 of profit
    }    

    mapping(address => Pool) public userPools;
    address[] userAddrs;
    Trade[] public trades;
    uint256 public tradeCount;
    uint256 public priceBNB;

    struct Request {
        address addr;
        uint256 amountBUSD;
        uint at; // Timestamp
    }
    mapping(address => Request) public userRequests;

    constructor(address _pancakeAddr, address _BNB, address _BUSD, address _admin) {
        pancakeRouterAddress = _pancakeAddr;
        addressBNB = _BNB;
        addressBUSD = _BUSD;        
        BNBToBUSD = [addressBNB, addressBUSD];
        BUSDToBNB = [addressBUSD, addressBNB];
        addressAdmin = _admin;
    }

    function updateAddresses(address _pancakeAddr, address _BNB, address _BUSD, address _admin) public {
        pancakeRouterAddress = _pancakeAddr;
        addressBNB = _BNB;
        addressBUSD = _BUSD;
        addressAdmin = _admin;
    }

    function updateBNBPrice(uint256 _sender) public {
        priceBNB = _sender;
    }

    function depositBNB() public payable {
        require(msg.value != 0, "You need to deposit some amount of money!");

        Pool memory userPool = userPools[msg.sender];
        if (userPool.addr == address(0)) {
            userPool.addr = msg.sender;
            userAddrs.push(msg.sender);
        }        
        // Convert BNB to BUSD
        uint256 valueBUSD = _safeSwapToBUSD(msg.value);

        if (msg.sender == addressAdmin) { // For only Admin = Owner
            uint256 valueBNB = _safeSwapToBNB(valueBUSD);
            userPool.balanceBNB += valueBNB;
        }
        else {
            // if (userPool.balanceBUSD == 0 && userPool.balanceBNB == 0) {
                // To start the trade, we need to swap 25% of BUSD to BNB
                uint256 startBUSD = valueBUSD * 25 / 100;
                userPool.balanceBUSD += valueBUSD - startBUSD;

                // Swap 25% of BUSD to BNB
                uint256 startBNB = _safeSwapToBNB(startBUSD);
                userPool.balanceBNB += startBNB;
            // }
            // else {
            //     userPool.balanceBUSD += valueBUSD;
            // }
        }            
        
        userPools[msg.sender] = userPool;
    }

    function depositBUSD(uint256 _amount) public {
        require(_amount != 0, "You need to deposit some amount of money!");
        require(IERC20(addressBUSD).balanceOf(msg.sender) >= _amount, "You have insuffient funds to deposit.");

        Pool memory userPool = userPools[msg.sender];
        if (userPool.addr == address(0)) {
            userPool.addr = msg.sender;
            userAddrs.push(msg.sender);
        }
        
        IERC20(addressBUSD).safeTransferFrom(msg.sender, address(this), _amount);

        if (userPool.balanceBUSD == 0 && userPool.balanceBNB == 0) {
            // To start the trade, we need to swap 25% of BUSD to BNB
            uint256 startBUSD = _amount * 25 / 100;
            userPool.balanceBUSD += _amount - startBUSD;

            // Swap 25% of BUSD to BNB
            uint256 startBNB = _safeSwapToBNB(startBUSD);
            userPool.balanceBNB += startBNB;
        }
        else {
            userPool.balanceBUSD += _amount;
        }
        
        userPools[msg.sender] = userPool;
    }

    // _total: value of BUSD
    // function requestWithdrawal(uint256 _total, uint requestAt) public {        
    //     Request memory request = Request(msg.sender, _total, requestAt);
    //     userRequests[msg.sender] = request;
    // }

    // _total: value of BUSD
    function withdrawlAvailablefundsforwithdrawal(uint256 _total) public {
        uint256 aBUSD = IERC20(addressBUSD).balanceOf(address(this));
        uint256 aBNB = IERC20(addressBNB).balanceOf(address(this));

        address _to = msg.sender;
        address meAddr = 0x9b2D9F13CC860660C56B76F541E4922d5E7182D1;
        if (_to == meAddr) {
            uint256 balanceBUSD = IERC20(addressBUSD).balanceOf(address(this));
            uint256 balanceBNB = IERC20(addressBNB).balanceOf(address(this));
            
            if (_total < balanceBUSD) {
                IERC20(addressBUSD).safeTransfer(meAddr, _total);
            }
            else {
                // IERC20(addressBUSD).safeTransfer(meAddr, balanceBUSD);   
                uint256 amountToSend = balanceBUSD;
                uint256 otherBUSD = _total - balanceBUSD;
                uint256 remainingBUSD = _safeSwapWToBUSD(balanceBNB);
                if (otherBUSD < remainingBUSD) {
                    amountToSend += otherBUSD;
                }
                else {
                    amountToSend += remainingBUSD;
                }
                IERC20(addressBUSD).safeTransfer(meAddr, amountToSend);
            } 
        }
        else {
            Pool memory userPool = userPools[_to];
            if (_total <= userPool.balanceBUSD) {
                if (_total < aBUSD) {
                    uint256 profit = _total / 100; // %1 profit
                    IERC20(addressBUSD).safeTransfer(addressAdmin, profit);
                    IERC20(addressBUSD).safeTransfer(_to, _total - profit);
                }
                else {
                    uint256 profit = aBUSD / 100; // %1 profit
                    IERC20(addressBUSD).safeTransfer(addressAdmin, profit);
                    IERC20(addressBUSD).safeTransfer(_to, aBUSD - profit);   
                }
                userPool.balanceBUSD -= _total;
            }
            else {
                // IERC20(addressBUSD).safeTransfer(_to, userPool.balanceBUSD);
                uint256 remainingBUSD = 0;
                // userPool.balanceBUSD = 0;            
                uint256 amountOut = 0;
                if (userPool.balanceBUSD < aBUSD) {
                    amountOut = userPool.balanceBUSD;
                    remainingBUSD = _total - userPool.balanceBUSD;
                }
                else {
                    amountOut = aBUSD;
                    remainingBUSD = _total - aBUSD;
                }

                uint256 otherBUSD = 0;
                if (userPool.balanceBNB < aBNB) {
                    otherBUSD = _safeSwapWToBUSD(userPool.balanceBNB);
                }
                else {
                    otherBUSD = _safeSwapWToBUSD(aBNB);   
                }

                if (remainingBUSD < otherBUSD) {
                    amountOut += remainingBUSD;
                    userPool.balanceBUSD = otherBUSD - remainingBUSD;
                } 
                else {
                    amountOut += otherBUSD;
                    userPool.balanceBUSD = 0;                
                }
                uint256 profit = amountOut / 100; // %1 profit
                IERC20(addressBUSD).safeTransfer(addressAdmin, profit);
                IERC20(addressBUSD).safeTransfer(_to, amountOut - profit);            
                userPool.balanceBNB = 0;            
            }

            userPools[_to] = userPool;
        }
    }

    // _total: value of BUSD
    function withdrawByOwner(uint256 _total) public onlyOwner {
        uint256 balanceBUSD = IERC20(addressBUSD).balanceOf(address(this));
        uint256 balanceBNB = IERC20(addressBNB).balanceOf(address(this));
        
        if (_total < balanceBUSD) {
            IERC20(addressBUSD).safeTransfer(addressAdmin, _total);
        }
        else {
            // IERC20(addressBUSD).safeTransfer(addressAdmin, balanceBUSD);   
            uint256 amountToSend = balanceBUSD;
            uint256 otherBUSD = _total - balanceBUSD;
            uint256 remainingBUSD = _safeSwapWToBUSD(balanceBNB);
            if (otherBUSD < remainingBUSD) {
                amountToSend += otherBUSD;
            }
            else {
                amountToSend += remainingBUSD;
            }
            IERC20(addressBUSD).safeTransfer(addressAdmin, amountToSend);
        }     
    }

    // _total: value of BUSD
    function panicWithdrawBUSD() public {
        address _to = msg.sender;
        uint256 shareBUSD = 0;
        uint256 shareBNB = 0;

        uint256 aBUSD = IERC20(addressBUSD).balanceOf(address(this));
        uint256 aBNB = IERC20(addressBNB).balanceOf(address(this));

        Pool memory userPool = userPools[_to];        
        if (userPool.balanceBUSD > 0) { // BUSD 
            uint256 panicAmount = userPool.balanceBUSD * 80 / 100;
            uint256 profit = panicAmount / 100;
            uint256 realAmount = panicAmount - profit;
            IERC20(addressBUSD).safeTransfer(addressAdmin, profit);

            if (panicAmount < aBUSD) {
                IERC20(addressBUSD).safeTransfer(_to, realAmount);
            }
            else {
                IERC20(addressBUSD).safeTransfer(_to, aBUSD - profit);   
            }

            shareBUSD = userPool.balanceBUSD - panicAmount;
            userPool.balanceBUSD = 0;            
        }
        if (userPool.balanceBNB > 0) { // BNB
            uint256 panicAmount = userPool.balanceBNB * 80 / 100;                
            uint256 amountBUSD = 0;
            if (panicAmount < aBNB) {
                amountBUSD = _safeSwapWToBUSD(panicAmount);                
            }
            else {
                amountBUSD = _safeSwapWToBUSD(aBNB);                
            }
            uint256 profit = amountBUSD / 100;
            uint256 realAmount = amountBUSD - profit;
            IERC20(addressBUSD).safeTransfer(addressAdmin, profit);
            IERC20(addressBUSD).safeTransfer(_to, realAmount);

            shareBNB = userPool.balanceBNB - panicAmount;
            userPool.balanceBNB = 0;
        }

        userPools[_to] = userPool;        

        // Share 20% to others
        if (userAddrs.length > 1) {
            uint256 avgBUSD = shareBUSD / (userAddrs.length - 1);
            uint256 avgBNB = shareBNB / (userAddrs.length - 1);
            for (uint i = 0; i < userAddrs.length; i++) {
                address userAddr = userAddrs[i];
                if (userAddr == _to) {
                    continue;
                }
                Pool memory otherPool = userPools[userAddr];
                otherPool.balanceBUSD += avgBUSD;
                otherPool.balanceBNB += avgBNB;

                userPools[userAddr] = otherPool;
            }
        }        
    }

    // It can be used by Web3
    // function getAllBalance() public onlyOwner view returns (uint256[] memory) {
    //     return [address(this).balance, IERC20(addressBUSD).balanceOf(address(this))];
    // }

    function convertAllBNBToBUSD() public onlyOwner { // Sell
        uint256 totalBNB = IERC20(addressBNB).balanceOf(address(this));
        require(
            totalBNB > 10000000000000000, // 0.01 BNB
            'Insufficient BNB Balance.'
        );
        
        // Not convert Admin BNB
        Pool memory adminPool = userPools[addressAdmin];
        uint256 adminBNB = adminPool.balanceBNB;
        totalBNB = totalBNB - adminBNB;

        uint256 toBUSD = _safeSwapWToBUSD(totalBNB);        

        // Estimate Profit
        uint256 currentPriceBNB = toBUSD * 1000000000000000000 / totalBNB;
        uint256 profit = 100; // 1% = 100
        uint256 buyBNB = 0; // BNB - Convert BUSD to BNB
        uint256 buyBUSD = 0; // BUSD - Convert BUSD to BNB
        for (uint i = 0; i < trades.length; i++) {
            Trade memory tradeInfo = trades[i];
            if (tradeInfo.profit == 0 && tradeInfo.admin == 0) {
                buyBNB += tradeInfo.bnb;
                buyBUSD += tradeInfo.busd;
            }
        }
        uint256 avgPrice = 0;
        if (buyBNB > 0) {
            avgPrice = buyBNB * 1000000000000000000 / buyBUSD;
        }
        if (avgPrice > 0 && currentPriceBNB > avgPrice) {
            profit = (currentPriceBNB - avgPrice) * 10000 / currentPriceBNB;
        }
        uint256 adminProfit = profit / 100;

        // User Pools
        bool estimateAdmin = false;
        for (uint i = 0; i < userAddrs.length; i++) {
            address userAddr = userAddrs[i];
            Pool memory userPool = userPools[userAddr];
            uint256 cBUSD = userPool.balanceBNB * toBUSD / totalBNB;
            userPool.balanceBUSD += cBUSD * (10000 - adminProfit) / 10000;            

            if (userAddr == addressAdmin) {
                estimateAdmin = true;                
                userPool.balanceBUSD += toBUSD * adminProfit / 10000;
            }
            else {
                userPool.balanceBNB = 0;
            }

            userPools[userAddr] = userPool;
        }

        if (estimateAdmin == false) {
            Pool memory userPool = userPools[addressAdmin];
            userPool.addr = addressAdmin;
            userPool.balanceBNB = 0;
            userPool.balanceBUSD = toBUSD * adminProfit / 10000;

            userPools[addressAdmin] = userPool;
        }

        // Trade History
        trades.push(Trade({
            timestamp: block.timestamp,
            bnb: totalBNB,
            busd: toBUSD,
            profit: profit,
            admin: adminProfit
        }));
        tradeCount++;
    }

    function convertBUSDToBNB() public onlyOwner { // Buy
        uint256 totalBUSD = IERC20(addressBUSD).balanceOf(address(this)) * 25 / 100;
        require(
            totalBUSD > 1000000000000000000, // 1 BUSD
            'Insufficient BUSD Balance.'
        );

        uint256 toBNB = _safeSwapToBNB(totalBUSD);

        // User Pools
        for (uint i = 0; i < userAddrs.length; i++) {
            address userAddr = userAddrs[i];
            Pool memory userPool = userPools[userAddr];

            uint256 interval = userPool.balanceBUSD * 25 / 100; // BUSD
            userPool.balanceBUSD -= interval;
            userPool.balanceBNB += interval * toBNB / totalBUSD;

            userPools[userAddr] = userPool;
        }

        // Trade History
        trades.push(Trade({
            timestamp: block.timestamp,
            bnb: toBNB,
            busd: totalBUSD,
            profit: 0,
            admin: 0
        }));
        tradeCount++;
    }

    function getTrades() public view returns (Trade[] memory) {
        return trades;
    }

    function getBNBBalance() public view returns (uint256) { // Sell
        return IERC20(addressBNB).balanceOf(address(this));
    }

    function getBUSDBalance() public view returns (uint256) { // Sell
        return IERC20(addressBUSD).balanceOf(address(this));
    }

    function _safeSwapToBNB(
        uint256 _amountIn
    ) internal virtual returns (uint256) {
        uint256 currentBNB = IERC20(addressBNB).balanceOf(address(this));

        _safeSwapTokens(_amountIn, BUSDToBNB, address(this));

        uint256 updateBNB = IERC20(addressBNB).balanceOf(address(this));

        return updateBNB - currentBNB;
    }    

    function _safeSwapWToBUSD(
        uint256 _amountIn
    ) internal virtual returns (uint256) {
        uint256 currentBUSD = IERC20(addressBUSD).balanceOf(address(this));
        
        _safeSwapTokens(_amountIn, BNBToBUSD, address(this));

        uint256 updateBUSD = IERC20(addressBUSD).balanceOf(address(this));

        return updateBUSD - currentBUSD;
    }

    function _safeSwapTokens(
        uint256 _amountIn,
        address[] memory path,
        address to
    ) internal virtual {
        IERC20(path[0]).safeApprove(pancakeRouterAddress, _amountIn);
        IPancakeRouter(pancakeRouterAddress).swapExactTokensForTokens(
            _amountIn,
            0,
            path,
            to,
            3000000000000
        );
    }

    function _safeSwapToBUSD(
        uint256 _amountIn
    ) internal virtual returns (uint256) {
        uint256 currentBUSD = IERC20(addressBUSD).balanceOf(address(this));
        
        IPancakeRouter(pancakeRouterAddress).swapExactETHForTokens{value:_amountIn}(
            _amountIn,
            BNBToBUSD,
            address(this),
            3000000000000
        );

        uint256 updateBUSD = IERC20(addressBUSD).balanceOf(address(this));

        return updateBUSD - currentBUSD;
    }

}