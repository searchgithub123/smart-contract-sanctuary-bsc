/**
 *Submitted for verification at BscScan.com on 2021-09-18
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity 0.6.12;

//
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
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor() internal {}

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IMinter {
    function isMinter(address account) view external returns (bool);
    function setMinter(address minter, bool canMint) external;
    function mintNativeTokens(uint, address) external;
}

contract TokenAddresses {
    string public constant GLOBAL = "GLOBAL";
    string public constant CAKE = "CAKE";
    string public constant BNB = "BNB";   // ERC20 on eth
    string public constant WBNB = "WBNB"; // BEP20 on bsc
    string public constant BUSD = "BUSD";
    string public constant BUNNY = "BUNNY";
    string public constant CAKE_WBNB_LP = "CAKE-WBNB-LP";

    mapping (string => address) private tokens;

    function findByName(string memory _tokenName) external view returns (address) {
        require(tokens[_tokenName] != address(0), "Token does not exists.");
        return tokens[_tokenName];
    }

    function addToken(string memory _tokenName, address _tokenAddress) external {
        require(tokens[_tokenName] == address(0), "Token already exists.");
        tokens[_tokenName] = _tokenAddress;
    }
}

//
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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
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
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IPathFinder {
    function addRouteInfoDirect(address _token) external;
    function addRouteInfoRoute(address _token, address _tokenRoute) external;
    function addRouteInfo(address _token, address _tokenRoute, bool _directBNB) external;
    function removeRouteInfo(address _token) external;
    function isTokenConnected(address _token) external view returns (bool);
    function getRouteInfoTokenRoute(address _token) external view returns (address);
    function getRouteInfoDirectBNB(address _token) external view returns (bool);

    function findPath(address _tokenFrom, address _tokenTo) external view returns (address[] memory);
}

interface IMintNotifier {
    function notify(address _vaultFor, address _userFor, uint _amount) external;
}

/**
 * @title Trusted
 * @dev The Trusted contract has a whitelist of addresses, and provides basic authorization control functions.
 * @dev This simplifies the implementation of "user permissions".
 */
contract Trusted is Context, Ownable {
    mapping(address => bool) public whitelist;

    event WhitelistedAddressAdded(address addr);
    event WhitelistedAddressRemoved(address addr);

    /**
     * @dev Throws if called by any account that's not whitelisted.
     */
    modifier onlyWhitelisted() {
        require(whitelist[msg.sender], 'You are not trusted: you are not in the whitelist');
        _;
    }

    /**
     * @dev Throws if called by any account that's not human.
     */
    modifier onlyHuman() {
        require(msg.sender == tx.origin && !isContract(msg.sender), 'You are not trusted: you are not human');
        _;
    }

    /**
     * @dev Throws if called by any account that's not human and not whitelisted.
     */
    modifier onlyHumanOrWhitelisted() {
        require(whitelist[msg.sender] || (msg.sender == tx.origin && !isContract(msg.sender)), 'You are not trusted: you are not human and not in the whitelist');
        _;
    }


    /**
     * @dev checks address extcodesize
     * @param account address
     * @return success true if the size is bigger than 0,
     * false if size is 0
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
     * @dev Throws if called by any account that's not whitelisted.
     */
    modifier onlyWhitelistedOrHuman() {
        require(whitelist[msg.sender]);
        _;
    }

    /**
     * @dev add an address to the whitelist
     * @param addr address
     * @return success true if the address was added to the whitelist, false if the address was already in the whitelist
     */
    function isAddressWhitelisted(address addr) onlyOwner public view returns(bool success) {
        success = whitelist[addr];
    }

    /**
     * @dev add an address to the whitelist
     * @param addr address
     * @return success true if the address was added to the whitelist, false if the address was already in the whitelist
     */
    function addAddressToWhitelist(address addr) onlyOwner public returns(bool success) {
        if (!whitelist[addr]) {
            whitelist[addr] = true;
            emit WhitelistedAddressAdded(addr);
            success = true;
        }
    }

    /**
     * @dev add addresses to the whitelist
     * @param addrs addresses
     * @return success true if at least one address was added to the whitelist,
     * false if all addresses were already in the whitelist
     */
    function addAddressesToWhitelist(address[] calldata addrs) onlyOwner public returns(bool success) {
        for (uint256 i = 0; i < addrs.length; i++) {
            if (addAddressToWhitelist(addrs[i])) {
                success = true;
            }
        }
    }

    /**
     * @dev remove an address from the whitelist
     * @param addr address
     * @return success true if the address was removed from the whitelist,
     * false if the address wasn't in the whitelist in the first place
     */
    function removeAddressFromWhitelist(address addr) onlyOwner public returns(bool success) {
        if (whitelist[addr]) {
            whitelist[addr] = false;
            emit WhitelistedAddressRemoved(addr);
            success = true;
        }
    }

    /**
     * @dev remove addresses from the whitelist
     * @param addrs addresses
     * @return success true if at least one address was removed from the whitelist,
     * false if all addresses weren't in the whitelist in the first place
     */
    function removeAddressesFromWhitelist(address[] calldata addrs) onlyOwner public returns(bool success) {
        for (uint256 i = 0; i < addrs.length; i++) {
            if (removeAddressFromWhitelist(addrs[i])) {
                success = true;
            }
        }
    }

}

//
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (a dev) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the dev with powers account will be the one that deploys the contract. This
 * can later be changed with {transferDevPower}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyDevPower`, which can be applied to your functions to restrict their use to
 * the dev with powers.
 */
contract DevPower is Context {
    address private _devPower;

    event DevPowerTransferred(address indexed previousDevPower, address indexed newDevPower);

    /**
     * @dev Initializes the contract setting the deployer as the initial dev with powers.
     */
    constructor() internal {
        address msgSender = _msgSender();
        _devPower = msgSender;
        emit DevPowerTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current dev with powers.
     */
    function GetDevPowerAddress() public view returns (address) {
        return _devPower;
    }

    /**
     * @dev Throws if called by any account other than the dev with powers.
     */
    modifier onlyDevPower() {
        require(_devPower == _msgSender(), 'DevPower: caller is not the dev with powers');
        _;
    }

    /**
     * @dev Leaves the contract without dev with powers. It will not be possible to call
     * `onlyDevPower` functions anymore. Can only be called by the current dev with powers.
     *
     * NOTE: Renouncing to have a dev account with powers will leave the contract without a manager,
     * thereby removing any functionality that is only available to the dev with powers.
     */
    function renounceDevPower() public onlyDevPower {
        emit DevPowerTransferred(_devPower, address(0));
        _devPower = address(0);
    }

    /**
     * @dev Transfers dev powers of the contract to a new account (`newDevPower`).
     * Can only be called by the current dev with powers.
     */
    function transferDevPower(address newDevPower) public onlyDevPower {
        _transferDevPower(newDevPower);
    }

    /**
     * @dev Transfers DevPower of the contract to a new account (`newDevPower`).
     */
    function _transferDevPower(address newDevPower) internal {
        require(newDevPower != address(0), 'DevPower: new dev with powers is the zero address');
        emit DevPowerTransferred(_devPower, newDevPower);
        _devPower = newDevPower;
    }
}

// File: @openzeppelin/contracts/utils/ReentrancyGuard.sol

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

    constructor () internal {
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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }

    function min(uint x, uint y) internal pure returns (uint z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

/**
 * @title SafeBEP20
 * @dev Wrappers around BEP20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeBEP20 for IBEP20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeBEP20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IBEP20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IBEP20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IBEP20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            'SafeBEP20: approve from non-zero to non-zero allowance'
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            'SafeBEP20: decreased allowance below zero'
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IBEP20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, 'SafeBEP20: low-level call failed');
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), 'SafeBEP20: BEP20 operation did not succeed');
        }
    }
}

interface IBEP20 {

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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
 * @dev Implementation of the {IBEP20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {BEP20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-BEP20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of BEP20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IBEP20-approve}.
 */
contract BEP20 is Context, IBEP20, Ownable, DevPower {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
    }

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external override view returns (address) {
        return owner();
    }

    /**
     * @dev Returns the token name.
     */
    function name() public override view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the token decimals.
     */
    function decimals() public override view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev Returns the token symbol.
     */
    function symbol() public override view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {BEP20-totalSupply}.
     */
    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {BEP20-balanceOf}.
     */
    function balanceOf(address account) public override view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {BEP20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {BEP20-allowance}.
     */
    function allowance(address owner, address spender) public override view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {BEP20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {BEP20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {BEP20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(amount, 'BEP20: transfer amount exceeds allowance')
        );
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {BEP20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {BEP20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(subtractedValue, 'BEP20: decreased allowance below zero')
        );
        return true;
    }

    /**
     * @dev Creates `amount` tokens and assigns them to `msg.sender`, increasing
     * the total supply.
     *
     * Requirements
     *
     * - `msg.sender` must be the token owner
     */
    function mint(uint256 amount) public onlyOwner returns (bool) {
        _mint(_msgSender(), amount);
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), 'BEP20: transfer from the zero address');
        require(recipient != address(0), 'BEP20: transfer to the zero address');

        _balances[sender] = _balances[sender].sub(amount, 'BEP20: transfer amount exceeds balance');
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), 'BEP20: mint to the zero address');

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), 'BEP20: burn from the zero address');

        _balances[account] = _balances[account].sub(amount, 'BEP20: burn amount exceeds balance');
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), 'BEP20: approve from the zero address');
        require(spender != address(0), 'BEP20: approve to the zero address');

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(
            account,
            _msgSender(),
            _allowances[account][_msgSender()].sub(amount, 'BEP20: burn amount exceeds allowance')
        );
    }
}

/* /////////////////////////////////////////////////CAMBIAR: Nombre del swap y del token en constructor BEP20, una mica + a baix!!!!!*/
contract NativeToken is BEP20{

    // DS: Burn address podria ser 0x0 però mola més un 0x...dEaD;
    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    //Antibot system
    mapping (address => bool) private blacklisted;

    bool tradingOpen = false;
    uint256 launchTime;

    // DS: màxim antiwhale que podem posar. Per defecte, ningú podrà enviar més del 15% del supply mai.
    // DS: no hi ha mínim, perque si hi ha un atac, podria ser-nos útil evitar que hi hagi transfers de tokens.
    uint16 public constant MAX_ANTIWHALE = 1500;

    // DS: A aquestes adreces no els hi aplica el mecanisme antiwhale
    mapping(address => bool) private _antiWhaleWhiteList;

    // DS: 2% del supply és el màxim que es pot transferir inicialment (es podrà modificar després). En diferent base per evitar decimals.
    uint16 public antiWhalePercent = MAX_ANTIWHALE;

    // DS: El dev és el únic que pot modificar les variables propies del token.
    address private _mainDevWallet;

    // Events
    event MaxTransferAntiWhale(address indexed devPower, uint256 oldAntiWhalePercent, uint256 newAntiWhalePercent);

    // DS: Constructor del token. Els paràmetres passen pel constructor del BEP20 + afegim adreces antiwhale whitelisted.
    // DS: OnlyOwner i DevPower = msg.sender.
    constructor() public BEP20('Global', 'GLB'){
        // DS: el dev/contracte poden transferir entre ells o enviar a BURN_ADDRESS/address(0) sense problemes.
        _antiWhaleWhiteList[msg.sender] = true;
        _antiWhaleWhiteList[address(this)] = true;
        _antiWhaleWhiteList[BURN_ADDRESS] = true;
        _antiWhaleWhiteList[address(0)] = true;
    }

    // DS: Getter if excluded from antiwhale
    function GetIfExcludedFromAntiWhale(address addr) public view returns (bool) {
        return _antiWhaleWhiteList[addr];
    }

    // DS: Per emergències o coses puntuals, si hem d'activar/desactivar alguna direcció de l'antiwhale
    function setExcludedFromAntiWhale(address addr, bool _excluded) public onlyDevPower {
        _antiWhaleWhiteList[addr] = _excluded;
    }

    // DS: Calculem el màxim de tokens que ens permetrà transferir l'antiwhale (depèn del totalSupply(), implementat a BEP20 + IBEP20).
    function maxTokensTransferAmountAntiWhaleMethod() public view returns (uint256) {
        return totalSupply().mul(antiWhalePercent).div(10000);
    }

    // DS: setejem un nou antiwhale percent. Lo normal serà anar baixant aquest valor a mesura que puji el marketcap.
    function updateMaxTransferAntiWhale(uint16 _newAntiWhalePercent) public onlyDevPower {
        require(_newAntiWhalePercent <= MAX_ANTIWHALE, "[!] Antiwhale method triggered. You are trying to set a % which is too high Check MAX_ANTIWHALE in the SC.");
        emit MaxTransferAntiWhale(msg.sender, antiWhalePercent, _newAntiWhalePercent);
        antiWhalePercent = _newAntiWhalePercent;
    }

    // DS: Setejem una condició a comprovar a una funció (transfer) abans d'executar-la.
    modifier antiWhale(address origen, address destinataria, uint256 q) {

        // DS: Comprovació simple per saber que no hi ha hagut problemes. El número de tokens mínims permesos en una transfer ha de ser superior a 0.
        if (maxTokensTransferAmountAntiWhaleMethod() > 0) {

            // DS: només podem saltar-nos l'antiwhale si tan origen com destí estàn whitelisted. Un dev no se'l pot saltar amb un user.
            if (_antiWhaleWhiteList[origen] == false && _antiWhaleWhiteList[destinataria] == false)
            {
                require(q <= maxTokensTransferAmountAntiWhaleMethod(), "[!] Antiwhale method triggered. You are trying to transfer too many tokens. Calm down and don't panic sell bro.");
            }
        }
        _;
    }

    function openTrading() external onlyOwner() {
        tradingOpen = true;
        launchTime = block.timestamp;
    }

    function closeTrading() external onlyOwner() {
        tradingOpen = false;
    }

    // DS: fem override del _transfer, que és la funció que fa el _transfer "final" i serveix per poder aplicar característiques pròpies [Veure BEP20.sol].
    function _transfer(address sender, address recipient, uint256 amount) internal virtual override antiWhale(sender, recipient, amount) {
        require(!blacklisted[sender], "You have no power here!");
        require(!blacklisted[recipient], "You have no power here!");
        if (block.timestamp == launchTime) {
            blacklisted[recipient] = true;
        }
        require(tradingOpen || msg.sender == owner(),"The market is closed");
        // Fem servir el transfer normal.
        super._transfer(sender, recipient, amount);
    }

    /// @notice Creates `_amount` token to `_to`. Must only be called by the owner (MasterChef).
    // TODO: mint to mints because of duplicated name with mint BEP20
    function mints(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
        _moveDelegates(address(0), _delegates[_to], _amount);
    }

    function safe32(uint n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function getChainId() internal pure returns (uint) {
        uint256 chainId;
        assembly { chainId := chainid() }
        return chainId;
    }

    /// @dev A record of each accounts delegate
    mapping (address => address) internal _delegates;

    /// @dev A checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint32 fromBlock;
        uint256 votes;
    }

    /// @dev A record of votes checkpoints for each account, by index
    mapping (address => mapping (uint32 => Checkpoint)) public checkpoints;

    /// @dev The number of checkpoints for each account
    mapping (address => uint32) public numCheckpoints;

    /// @dev The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    /// @dev The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    /// @dev of states for signing / validating signatures
    mapping (address => uint) public nonces;

    /// @dev An event thats emitted when an account changes its delegate
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /// @dev An event thats emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(address indexed delegate, uint previousBalance, uint newBalance);

    /**
     * @dev Delegate votes from `msg.sender` to `delegatee`
     * @param delegator The address to get delegatee for
     */
    function delegates(address delegator) external view returns (address)
    {
        return _delegates[delegator];
    }

    /**
     * @dev votes from `msg.sender` to `delegatee`
     * @param delegatee The address to delegate votes to
     */
    function delegate(address delegatee) external {
        return _delegate(msg.sender, delegatee);
    }

    /**
     * @dev Delegates votes from signatory to `delegatee`
     * @param delegatee The address to delegate votes to
     * @param nonce The contract state required to match the signature
     * @param expiry The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function delegateBySig(
        address delegatee,
        uint nonce,
        uint expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
    external
    {
        bytes32 domainSeparator = keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes(name())),
                getChainId(),
                address(this)
            )
        );

        bytes32 structHash = keccak256(
            abi.encode(
                DELEGATION_TYPEHASH,
                delegatee,
                nonce,
                expiry
            )
        );

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeparator,
                structHash
            )
        );

        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "GLOBAL::delegateBySig: invalid signature");
        require(nonce == nonces[signatory]++, "GLOBAL::delegateBySig: invalid nonce");
        require(now <= expiry, "GLOBAL::delegateBySig: signature expired");
        return _delegate(signatory, delegatee);
    }

    /**
     * @notice Gets the current votes balance for `account`
     * @param account The address to get votes balance
     * @return The number of current votes for `account`
     */
    function getCurrentVotes(address account)
    external
    view
    returns (uint256)
    {
        uint32 nCheckpoints = numCheckpoints[account];
        return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }

    /**
     * @notice Determine the prior number of votes for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param account The address of the account to check
     * @param blockNumber The block number to get the vote balance at
     * @return The number of votes the account had as of the given block
     */
    function getPriorVotes(address account, uint blockNumber)
    external
    view
    returns (uint256)
    {
        require(blockNumber < block.number, "GLOBAL::getPriorVotes: not yet determined");

        uint32 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
            return checkpoints[account][nCheckpoints - 1].votes;
        }

        // Next check implicit zero balance
        if (checkpoints[account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = checkpoints[account][center];
            if (cp.fromBlock == blockNumber) {
                return cp.votes;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[account][lower].votes;
    }

    function _delegate(address delegator, address delegatee)
    internal
    {
        address currentDelegate = _delegates[delegator];
        uint256 delegatorBalance = balanceOf(delegator); // balance of underlying NativeTokens (not scaled);
        _delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    function _moveDelegates(address srcRep, address dstRep, uint256 amount) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                // decrease old representative
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint256 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                uint256 srcRepNew = srcRepOld.sub(amount);
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                // increase new representative
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint256 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                uint256 dstRepNew = dstRepOld.add(amount);
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(
        address delegatee,
        uint32 nCheckpoints,
        uint256 oldVotes,
        uint256 newVotes
    )
    internal
    {
        uint32 blockNumber = safe32(block.number, "GLOBAL::_writeCheckpoint: block number exceeds 32 bits");

        if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
            checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
        } else {
            checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
            numCheckpoints[delegatee] = nCheckpoints + 1;
        }

        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }

    function isBlacklisted(address account) public view returns (bool) {
        return blacklisted[account];
    }

    function addBlacklisted(address account) external onlyOwner() {
        require(!blacklisted[account], "Account is already blacklisted");
        blacklisted[account] = true;
    }

    function removeBlacklisted(address account) external onlyOwner() {
        require(blacklisted[account], "Account is not blacklisted");
        blacklisted[account] = false;
    }
}

interface IPancakeERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}

interface IPair is IPancakeERC20 {
    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

interface IRouterV1 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IRouterV2 is IRouterV1 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// MC owner of MCInternal
contract MasterChefInternal {
    TokenAddresses public tokenAddresses;

    constructor(address _tokenAddresses) public {
        tokenAddresses = TokenAddresses(_tokenAddresses);
    }

    function checkTokensRoutes(IPathFinder pathFinder, IBEP20 _lpToken) public returns (bool bothConnected)
    {
        address WBNB = tokenAddresses.findByName(tokenAddresses.BNB());
        IPair pair = IPair(address(_lpToken));
        //TODO remove both connected
        bothConnected = false;
        if(pair.token0()==WBNB)
        {
            pathFinder.addRouteInfoDirect(pair.token1());
            bothConnected = true;
        }
        else if(pair.token1()==WBNB)
        {
            pathFinder.addRouteInfoDirect(pair.token0());
            bothConnected = true;
        }
        else if(!pathFinder.isTokenConnected(pair.token0()) && pathFinder.getRouteInfoDirectBNB(pair.token1()))
        {
            pathFinder.addRouteInfoRoute(pair.token0(),pair.token1());
            bothConnected = true;
        }
        else if(!pathFinder.isTokenConnected(pair.token1()) && pathFinder.getRouteInfoDirectBNB(pair.token0()))
        {
            pathFinder.addRouteInfoRoute(pair.token1(),pair.token0());
            bothConnected = true;
        }
        else if(pathFinder.isTokenConnected(pair.token0()) && pathFinder.isTokenConnected(pair.token1()))
        {
            bothConnected = true;
        }
    }
}

// HEM DE FER IMPORT DE LA INTERFACE I DEL SC DEL VAULT!!!!!!!!!


// PER AFEGIR:
// La funció de withdraw, enlloc danar a la teva wallet, ha danar a la pool de GLOBALS VESTED. Podriem posar que la pool de pid = 0 és la vested de forma automàtica (pasarla pel constructor) i així ja la creem i sempre és la mateixa.
// S'HAURÀ DE REPASSAR TOT EL CODI DE PANTHER I VEURE QUE NO ENS DEIXEM RES!!!!!!!!! i els modificadors public-private etc

// podem fer un stop all rewards per deixar morir al masterchef if needed i reemplaçarlo per un altre. Hem de fer que totes les fees siguin 0 si fem STOP.
// poder fer whitelist i blacklist d'una direcicó per si apareix hacker. devpower per evitar timelock, q llavors no serveix per res. també hem de posar un activar-desactivar whitelist-blacklist.
// És a dir, fem un activar la funcionalitat i després posem white or black lists.
// happy hour pel amm!! les fees allà: baixem els % de tot durant X to Y hores i fem boost del burn oper pujar otken?
// transaction frontrun pay miners??? sushiswap
// Falta poder fer update dels routers i tot això...
// és possible fer lockdown i transferir el ownership de pools i vaults individualment, o ja fem servir el migrator per aixop??

// idea: mesura antiwhale en una pool. si un vault té més de 1m$ de toksn, no es pot fer un dipòsit de més del 20% del vault.
//aixi evitem els flash loans attacks també, perque ningú es pot quedar amb el 99% del vault degut a flash loans
// Per revisar: que no ens deixem cap funció de pancake/panther, private-public-internal-external, transfer i safetransfer, onlydevpower i onlyowner.








// We hope code is bug-free. For everyone's life savings.
contract MasterChef is Ownable, DevPower, ReentrancyGuard, IMinter, Trusted {
    using SafeMath for uint16;
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;     		// How many LP tokens the user has provided.
        uint256 rewardDebt; 		// Rewards que se li deuen a un usuari particular. Reward debt. See explanation below.
        uint256 rewardLockedUp;  	// Rewards que se li deuen a un usuari particular i que no pot cobrar.
        uint256 nextHarvestUntil; 	// Moment en el que l'usuari ja té permís per fer harvest..
        uint256 withdrawalOrPerformanceFees; 		// Ens indica si ha passat més de X temps per saber si cobrem una fee o una altra.
        bool whitelisted;
        //
        // We do some fancy math here. Basically, any point in time, the amount of Native tokens
        // entitled to a user but is pending to be distributed is:
        //
        //   Aquesta explicació fot cagar. El total de rewards pendents, si traiem lo
        //	 que li hem de pagar a un usuari, és el següent:
        //   pending reward = (user.amount * pool.accNativeTokenPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accNativeTokenPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each farming pool.
    struct PoolInfo {
        IBEP20 lpToken;           							// Address of LP token contract.
        uint256 allocPoint;       							// Pes de la pool per indicar % de rewards que tindrà respecte el total. How many allocation points assigned to this pool. Weight of native tokens to distribute per block.
        uint256 lastRewardBlock;  							// Últim bloc que ha mintat native tokens.
        uint256 accNativeTokenPerShare; 					// Accumulated Native tokens per share, times 1e12.
        uint256 harvestInterval;  							// Freqüència amb la que podràs fer claim en aquesta pool.
        uint256 maxWithdrawalInterval;						// Punt d'inflexió per decidir si cobres withDrawalFeeOfLps o bé performanceFeesOfNativeTokens
        uint16 withDrawalFeeOfLpsBurn;						// % (10000 = 100%) dels LPs que es cobraran com a fees que serviran per fer buyback.
        uint16 withDrawalFeeOfLpsTeam;						// % (10000 = 100%) dels LPs que es cobraran com a fees que serviran per operations/marketing.
        uint16 performanceFeesOfNativeTokensBurn;			// % (10000 = 100%) dels rewards que es cobraran com a fees que serviran per fer buyback
        uint16 performanceFeesOfNativeTokensToLockedVault;	// % (10000 = 100%) dels rewards que es cobraran com a fees que serviran per fer boost dels native tokens locked
    }

    // Inicialitzem el nostre router Global
    IRouterV2 public routerGlobal;

    // Our token {~Cake}
    NativeToken public nativeToken;

    // Burn address podria ser 0x0 però mola més un 0x...dEaD;
    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    TokenAddresses private tokenAddresses;

    // En cas d'exploit, deixem sortir a la gent per l'emergency sense pagar LP fees. Not safu = no LPs fees in emergencywithdraw
    bool safu = true;

    // Vault where locked tokens are
    address public nativeTokenLockedVaultAddr;

    // Dev address.
    address public devAddr;

    // Native tokens creats per block.
    // No es minteja a cada block. Els tokens es queden com a deute i es cobren quan s'interactua amb la blockchain, sabent quants haig de pagar per bloc amb això.
    uint256 public nativeTokenPerBlock;

    // Bonus muliplier for early native tokens makers.
    uint256 public BONUS_MULTIPLIER = 1;

    // Max interval: 7 days.
    // Seguretat per l'usuari per indicar-li que el bloqueig serà de 7 dies màxim en el pitjor dels casos.
    uint256 public constant MAX_INTERVAL = 7 days;

    // Seguretat per l'usuari per indicar-li que no cobrarem mai més d'un 5% de withdrawal performance fee
    uint16 public constant MAX_FEE_PERFORMANCE = 500;

    // Max withdrawal fee of the LPs deposited: 1.5%.
    uint16 public constant MAX_FEE_LPS = 150;

    // The migrator contract. It has a lot of power. Can only be set through governance (owner).
    // Intentar evitar fer-lo servir.
    //IMigratorChef public migrator;

    // Info of each pool.
    PoolInfo[] public poolInfo;

    // Total de fees pendents d'enviar a cremar
    uint256 totalFeesToBurn = 0;
    // Total de fees pendens d'enviar al vaul de native token locked.
    uint256 totalFeesToBoostLocked = 0;
    // Cada 25 iteracions fem els envios per posar una freqüència i no fer masses envios petits
    uint16 counterForTransfers = 0;

    // Info of each user that stakes LP tokens.
    // Info d'un usuari en una pool en concret.
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    // Comptador del total de pes de les pools.
    uint256 public totalAllocPoint = 0;
    // The block number when Native tokens mining starts.
    // Inici del farming.
    uint256 public startBlock;

    // Rewards locked de tots els usuaris.
    uint256 public totalLockedUpRewards;
    // Llistat de pools que poden demanar tokens natius
    mapping(address => bool) private _minters;

    IPathFinder public pathFinder;
    IMintNotifier public mintNotifier;
    MasterChefInternal private masterChefInternal;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount, uint256 finalAmount);
    event EmissionRateUpdated(address indexed caller, uint256 previousAmount, uint256 newAmount);
    event RewardLockedUp(address indexed user, uint256 indexed pid, uint256 amountLockedUp);

    constructor(
        address _masterChefInternal,
        NativeToken _nativeToken,
        uint256 _nativeTokenPerBlock,
        uint256 _startBlock,
        address _routerGlobal,
        address _tokenAddresses,
        address _pathFinder
    ) public {
        masterChefInternal = MasterChefInternal(_masterChefInternal);
        nativeToken = _nativeToken;
        nativeTokenPerBlock = _nativeTokenPerBlock;
        startBlock = _startBlock;
        devAddr = msg.sender;
        routerGlobal = IRouterV2(_routerGlobal);
        tokenAddresses = TokenAddresses(_tokenAddresses);
        pathFinder = IPathFinder(_pathFinder);
        // Aquípodem inicialitzar totes les pools de Native Token ja. //////////////////////////////////////////////////////////////////////
        // tOT I QUE MOLaria més tenir vaults apart on enviem la pasta i que es gestionin de forma independent, així no liem el masterchef... lo únic q aquells contractes no podràn mintar dentrada perque no farem whitelist, només serveixen per repartir tokens

        //TODO check allocation point
        poolInfo.push(PoolInfo({
            lpToken: _nativeToken,
            allocPoint: 0,  //TODO was 1000
            lastRewardBlock: _startBlock,
            accNativeTokenPerShare: 0,
            harvestInterval: 0,
            maxWithdrawalInterval: 0,
            withDrawalFeeOfLpsBurn: 0,
            withDrawalFeeOfLpsTeam: 0,
            performanceFeesOfNativeTokensBurn: 0,
            performanceFeesOfNativeTokensToLockedVault: 0
        }));
        //TODO added
        //totalAllocPoint = 1000;
    }

    function manageTokens(
        address _token,
        uint256 _amountToBurn,
        uint256 _amountForDevs
    ) private {
        //burn
        {
            if(_token != address(nativeToken)){
                routerGlobal.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                    _amountToBurn,
                    0,
                    pathFinder.findPath(_token, tokenAddresses.findByName(tokenAddresses.GLOBAL())),
                    BURN_ADDRESS,
                    block.timestamp);
            }else{
                IBEP20(tokenAddresses.findByName(tokenAddresses.GLOBAL())).transfer(BURN_ADDRESS, _amountToBurn);
            }
        }
        //devfees. ATTENTION, we do not unwrap weth to eth here
        {
            if(_token != tokenAddresses.findByName(tokenAddresses.BNB())) // passem a WETH
            {
                routerGlobal.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                    _amountForDevs,
                    0,
                    pathFinder.findPath(_token, tokenAddresses.findByName(tokenAddresses.BNB())),
                    devAddr,
                    block.timestamp);
            }else{
                IBEP20(tokenAddresses.findByName(tokenAddresses.BNB())).transfer(devAddr, _amountForDevs);
            }
        }
    }


    function setRouter(address _router) public onlyOwner {
        routerGlobal = IRouterV2(_router);
    }

    function setPathFinder(address _pathFinder) public onlyOwner {
        pathFinder = IPathFinder(_pathFinder);
    }

    function addRouteToPathFinder(
        address _token, address _tokenRoute, bool _directBNB
    ) public onlyOwner {
        pathFinder.addRouteInfo(_token,_tokenRoute, _directBNB);
    }

    function removeRouteToPathFinder(
        address _token
    ) public onlyOwner {
        pathFinder.removeRouteInfo(_token);
    }

    function setLockedVaultAddress(address _newLockedVault) external onlyOwner{
        require(_newLockedVault != address(0), "(f) SetLockedVaultAddress: you can't set the locked vault address to 0.");
        nativeTokenLockedVaultAddr = _newLockedVault;
    }

    function getLockedVaultAddress() external view returns(address){
        return nativeTokenLockedVaultAddr;
    }

    function setSAFU(bool _safu) external onlyDevPower{
        safu = _safu;
    }
    function isSAFU() public view returns(bool){
        return safu;
    }

    function setWhitelistedUser(uint256 _pid, address _user, bool isWhitelisted) external onlyOwner {
        userInfo[_pid][_user].whitelisted = isWhitelisted;
    }
    function isWhitelistedUser(uint256 _pid, address _user) view external returns (bool) {
        return userInfo[_pid][_user].whitelisted;
    }

    /// Funcions de l'autocompound

    function setMintNotifier(address _mintNotifier) public onlyOwner {
        mintNotifier = IMintNotifier(_mintNotifier);
    }

    function getMintNotifierAddress() view external returns (address) {
        return address(mintNotifier);
    }

    function updateMultiplier(uint256 multiplierNumber) public onlyOwner {
        BONUS_MULTIPLIER = multiplierNumber;
    }

    // Cridarem a aquesta funció per afegir un vault, per indicar-li al masterchef que tindrà permís per mintejar native tokens
    function setMinter(address minter, bool canMint) external override onlyOwner {
        if (canMint) {
            _minters[minter] = canMint;
        } else {
            delete _minters[minter];
        }
    }

    // Afegim modificador que només es podrà fer servir pels contractes afegits (whitelisted)
    modifier onlyMinter {
        // require(isMinter(msg.sender) == true, "[f] OnlyMinter: caller is not the minter.");
        require(_minters[msg.sender] == true, "[f] OnlyMinter: caller is not the minter.");
        _;
    }

    // Comprovem si un contracte té permís per cridar el masterchef (aquest SC) i mintejar tokens
    function isMinter(address account) view external override returns (bool) {
        // El masterchef ha de ser l'owner del token per poder-los mintar
        if (nativeToken.getOwner() != address(this)) {
            return false;
        }

        return _minters[account];
    }

    // La funció de mintfor al nostre MC només requerirà saber quants tokens MINTEJEM i li enviem al vualt, ja que les fees son independents de cada pool i es tractaran individualment.
    // Per lo tant, els càlculs de quants tokens volem, sempre es faràn al propi vault. La lògica queda delegada al vault.
    function mintNativeTokens(uint _quantityToMint, address userFor) external override onlyMinter {
        // Mintem un ~10% dels tokens a l'equip (10/110)
        nativeToken.mints(devAddr, _quantityToMint.div(10));

        // Mintem tokens al que ens ho ha demanat
        nativeToken.mints(msg.sender, _quantityToMint);

        if(address(mintNotifier) != address(0))
        {
            mintNotifier.notify(msg.sender, userFor, _quantityToMint);
        }
    }

    // Quantes pools tenim en marxa?
    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function addPool(
        uint256 _allocPoint,
        IBEP20 _lpToken,
        uint256 _harvestInterval,
        bool _withUpdate,
        uint256 _maxWithdrawalInterval,
        uint16 _withDrawalFeeOfLpsBurn,
        uint16 _withDrawalFeeOfLpsTeam,
        uint16 _performanceFeesOfNativeTokensBurn,
        uint16 _performanceFeesOfNativeTokensToLockedVault
    ) public onlyOwner {
        require(_harvestInterval <= MAX_INTERVAL, "[f] Add: invalid harvest interval");
        require(_maxWithdrawalInterval <= MAX_INTERVAL, "[f] Add: invalid withdrawal interval. Owner, there is a limit! Check your numbers.");
        require(_withDrawalFeeOfLpsTeam.add(_withDrawalFeeOfLpsBurn) <= MAX_FEE_LPS, "[f] Add: invalid withdrawal fees. Owner, you are trying to charge way too much! Check your numbers.");
        require(_performanceFeesOfNativeTokensBurn.add(_performanceFeesOfNativeTokensToLockedVault) <= MAX_FEE_PERFORMANCE, "[f] Add: invalid performance fees. Owner, you are trying to charge way too much! Check your numbers.");
        require(masterChefInternal.checkTokensRoutes(pathFinder, _lpToken), "[f] Add: token/s not connected to WBNB");

        if (_withUpdate) {
            massUpdatePools();
        }

        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);

        poolInfo.push(PoolInfo({
        lpToken: _lpToken,
        allocPoint: _allocPoint,
        lastRewardBlock: lastRewardBlock,
        accNativeTokenPerShare: 0,
        harvestInterval: _harvestInterval,
        maxWithdrawalInterval: _maxWithdrawalInterval,
        withDrawalFeeOfLpsBurn: _withDrawalFeeOfLpsBurn,
        withDrawalFeeOfLpsTeam: _withDrawalFeeOfLpsTeam,
        performanceFeesOfNativeTokensBurn: _performanceFeesOfNativeTokensBurn,
        performanceFeesOfNativeTokensToLockedVault: _performanceFeesOfNativeTokensToLockedVault
        }));
    }

    // Update the given pool's Native tokens allocation point, withdrawal fees, performance fees and harvest interval. Can only be called by the owner.
    function setPool(
        uint256 _pid,
        uint256 _allocPoint,
        uint256 _harvestInterval,
        bool _withUpdate,
        uint256 _maxWithdrawalInterval,
        uint16 _withDrawalFeeOfLpsBurn,
        uint16 _withDrawalFeeOfLpsTeam,
        uint16 _performanceFeesOfNativeTokensBurn,
        uint16 _performanceFeesOfNativeTokensToLockedVault
    ) public onlyOwner {
        require(_harvestInterval <= MAX_INTERVAL, "[f] Set: invalid harvest interval");
        require(_maxWithdrawalInterval <= MAX_INTERVAL, "[f] Set: invalid withdrawal interval. Owner, there is a limit! Check your numbers.");
        require(_withDrawalFeeOfLpsTeam.add(_withDrawalFeeOfLpsBurn) <= MAX_FEE_LPS, "[f] Set: invalid withdrawal fees. Owner, you are trying to charge way too much! Check your numbers.");
        require(_performanceFeesOfNativeTokensBurn.add(_performanceFeesOfNativeTokensToLockedVault) <= MAX_FEE_PERFORMANCE, "[f] Set: invalid performance fees. Owner, you are trying to charge way too much! Check your numbers.");

        if (_withUpdate) {
            massUpdatePools();
        }

        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
        poolInfo[_pid].harvestInterval = _harvestInterval;
        poolInfo[_pid].maxWithdrawalInterval = _maxWithdrawalInterval;
        poolInfo[_pid].withDrawalFeeOfLpsBurn = _withDrawalFeeOfLpsBurn;
        poolInfo[_pid].withDrawalFeeOfLpsTeam = _withDrawalFeeOfLpsTeam;
        poolInfo[_pid].performanceFeesOfNativeTokensBurn = _performanceFeesOfNativeTokensBurn;
        poolInfo[_pid].performanceFeesOfNativeTokensToLockedVault = _performanceFeesOfNativeTokensToLockedVault;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        return _to.sub(_from).mul(BONUS_MULTIPLIER);
    }

    // View function to see pending native tokens on frontend.
    function pendingNativeToken(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accNativeTokenPerShare = pool.accNativeTokenPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));

        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 nativeTokenReward = multiplier.mul(nativeTokenPerBlock).mul(pool.allocPoint).div(totalAllocPoint);

            // Quants rewards acumulats pendents de cobrar té la pool + els que acabem de calcular
            accNativeTokenPerShare = accNativeTokenPerShare.add(nativeTokenReward.mul(1e12).div(lpSupply));
        }

        // Tokens pendientes de recibir
        uint256 pending = user.amount.mul(accNativeTokenPerShare).div(1e12).sub(user.rewardDebt);
        return pending.add(user.rewardLockedUp);
    }

    // View function to see if user can harvest.
    // Retornem + si el block.timestamp és superior al block límit de harvest.
    function canHarvest(uint256 _pid, address _user) public view returns (bool) {
        UserInfo storage user = userInfo[_pid][_user];
        return block.timestamp >= user.nextHarvestUntil || user.whitelisted;
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Actualitzem accNativeTokenPerShare i el número de tokens a mintar per cada bloc
    // Això, en principi només per LP, no per l'optimiser
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];

        // Si ja tenim la data actualitzada fins l'últim block, no cal fer res més
        if (block.number <= pool.lastRewardBlock) {
            return;
        }

        // Total de LP tokens que tenim en aquesta pool.
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));

        // Si no tenim LPs, diem que està tot updated a aquest block i out. No hi ha info a tenir en compte
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        } // else...

        // Quants rewards (multiplicador) hem tingut entre l'últim block actualitzat i l'actual
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);

        // (Tokens per block X multiplicador entre últim rewards donats i ara)     X     (Alloc points de la pool)   /     (total Alloc points)   = Tokens que s'han de pagar entre últim block mirat i l'actual. Es paga a operacions i al contracte.
        uint256 nativeTokenReward = multiplier.mul(nativeTokenPerBlock).mul(pool.allocPoint).div(totalAllocPoint);

        // Mintem un ~10% dels tokens a l'equip (10/110)
        nativeToken.mints(devAddr, nativeTokenReward.div(10));

        // Mintem tokens a aquest contracte.
        nativeToken.mints(address(this), nativeTokenReward);

        // Al accNativeTokenPerShare de la pool li afegim [els rewards mintats ara dividit entre el total de LPs]. Bàsicament, actualitzem accNativeTokenPerShare per indicar els rewards a cobrar per cada LP.
        pool.accNativeTokenPerShare = pool.accNativeTokenPerShare.add(nativeTokenReward.mul(1e12).div(lpSupply));

        // Últim block amb rewards actualitzat és l'actual
        pool.lastRewardBlock = block.number;
    }

    // Paguem els rewards o no es poden pagar?
    // Si fem un diposit,un harvest (= diposit de 0 tokens) o un withdraw tornem a afegir el temps de harvest (reiniciem el comptador bàsicament) i sempre es paguen els rewards pendents de rebre
    function payOrLockupPendingNativeToken(uint256 _pid) internal returns (bool) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        bool performanceFee = withdrawalOrPerformanceFee(_pid, msg.sender);

        // Si és el primer cop que entrem (AKA, fem dipòsit), el user.nextHarvestUntil serà 0, pel que li afegim al user el harvestr interval
        if (user.nextHarvestUntil == 0) {
            user.nextHarvestUntil = block.timestamp.add(pool.harvestInterval);
        } // Else...

        // Rewards pendents de pagar al usuari.  LPs   X    Rewards/LPs       -     Rewards ja cobrats
        uint256 pending = user.amount.mul(pool.accNativeTokenPerShare).div(1e12).sub(user.rewardDebt);

        // L'usuari pot fer harvest?
        if (canHarvest(_pid, msg.sender)) {

            // Si té rewards pendents de cobrar o ha acumulat per cobrar que estaven locked
            if (pending > 0 || user.rewardLockedUp > 0) {

                // Sumem el total de rewards a cobrar
                uint256 totalRewards = pending.add(user.rewardLockedUp);

                // reset lockup
                totalLockedUpRewards = totalLockedUpRewards.sub(user.rewardLockedUp);
                user.rewardLockedUp = 0;

                // Reiniciem harvest
                user.nextHarvestUntil = block.timestamp.add(pool.harvestInterval);

                // En cas de cobrar performance fees, li restem als rewards que li anavem a pagar
                if (performanceFee && !user.whitelisted){

                    // Tocarà fer una transfer, augmentem el comptador
                    counterForTransfers++;

                    // Rewards que finalment rebrà l'usuari: total rewards - feesTaken
                    //TODO, perque no guardar aixo en una var, i despres restarlo a on toca?
                    totalRewards = totalRewards.sub(totalRewards.mul(pool.performanceFeesOfNativeTokensBurn.add(pool.performanceFeesOfNativeTokensToLockedVault)).div(10000));

                    // Fees que cremarem i fees que enviarem per fer boost dels locked. Les acumulem a l'espera d'enviarles quan toquin
                    totalFeesToBurn = totalFeesToBurn.add(totalRewards.mul(pool.performanceFeesOfNativeTokensBurn.div(10000)));
                    totalFeesToBoostLocked = totalFeesToBoostLocked.add(totalRewards.mul(pool.performanceFeesOfNativeTokensToLockedVault.div(10000)));

                    // Si ja hem fet més de 25 transaccions, ja hem acumulat suficient per tractar-les
                    if (counterForTransfers > 25){

                        // Reiniciem el comptador.
                        counterForTransfers = 0;

                        // Cremem els tokens. Dracarys.
                        SafeNativeTokenTransfer(BURN_ADDRESS, totalFeesToBurn);
                        // Reiniciem el comptador de fees. Ho podem fer així i no cal l'increment de k com al AMM perque tota la info està al contracte
                        totalFeesToBurn = 0;

                        // Enviem les fees acumulades cap al vault de Global locked per fer boost dels rewards allà
                        SafeNativeTokenTransfer(nativeTokenLockedVaultAddr, totalFeesToBoostLocked);

                        // Reiniciem el comptador de fees. Ho podem fer així i no cal l'increment de k com al AMM perque tota la info està al contracte
                        totalFeesToBoostLocked = 0;
                    }
                }

                // Enviem els rewards pendents a l'usuari (es poden haver descomptat els performance fees)
                SafeNativeTokenTransfer(msg.sender, totalRewards);
            }

            // Si no pot fer harvest encara i se li deuen tokens...
        } else if (pending > 0) {

            // Guardem quants rewards s'ha de cobrar l'usuari encara
            user.rewardLockedUp = user.rewardLockedUp.add(pending);

            // Augmentem el total de rewards que estàn pendents de ser cobrats
            totalLockedUpRewards = totalLockedUpRewards.add(pending);

            // Mostrem avís
            emit RewardLockedUp(msg.sender, _pid, pending);
        }

        return performanceFee;
    }

    // Deposit 0 tokens = harvest. Deposit for LP pairs, not for staking.
    function deposit(uint256 _pid, uint256 _amount) public nonReentrant{
        require (_pid != 0, 'deposit GLOBAL by staking');
        require (_pid < poolInfo.length, 'This pool does not exist yet');

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        // Actualitzem quants rewards pagarem per cada LP
        updatePool(_pid);

        // Fem el pagament dels rewards pendents si en tenim i si no estàn locked (en cas que ho estiguin, quedaràn pendents)
        payOrLockupPendingNativeToken(_pid);

        // En cas de ser = 0, seria un harvest/claim i ens saltariem aquesta part. En cas de ser > 0, fem el dipòsit al contracte
        if (_amount > 0) {

            // Transferim els LPs a aquest contracte (MC)
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);

            // Indiquem que l'usuari té X tokens LP depositats
            user.amount = user.amount.add(_amount);

            // Indiquem el moment en el que depositem per saber quines withdrawal fees es cobraran
            user.withdrawalOrPerformanceFees = block.timestamp.add(pool.maxWithdrawalInterval);
        }

        // LPs que tenim multiplicat pels tokensrewards/LPs de la pool mitjos històrics -- Quan fas deposit, ho cobres tot (per això no falla aquesta funció). Si ho tenies en harvest lockup, van a pending rewards i ja t'ho cobraràs.
        user.rewardDebt = user.amount.mul(pool.accNativeTokenPerShare).div(1e12);

        // Emetem un event.
        emit Deposit(msg.sender, _pid, _amount);


    }

    function getLPFees(uint256 _pid, uint256 _amount) private returns(uint256){
        PoolInfo storage pool = poolInfo[_pid];

        // L'usuari rebrà els seus LPs menys els que li hem tret com a fees.
        uint256 finalAmount = _amount.sub(
            _amount.mul(pool.withDrawalFeeOfLpsBurn.add(pool.withDrawalFeeOfLpsTeam)).div(10000)
        );

        if (finalAmount != _amount)
        {
            // Fins aquí hem acabat la gestió de l'user. Ara gestionem la comissió. Tenim un LP. El volem desfer i enviar-lo a BURN i a OPERATIONS
            // Això s'ha de testejar bé perque és molt fàcil que hi hagin errors
            // Si el router no té permís perque address(this) es gasti els tokens, li donem permís
            if (IBEP20(pool.lpToken).allowance(address(this), address(routerGlobal)) == 0) {
                IBEP20(pool.lpToken).safeApprove(address(routerGlobal), uint(- 1));
            }

            // Fem remove liquidity del LP i rebrem els dos tokens
            (uint amountToken0, uint amountToken1) = routerGlobal.removeLiquidity(
                IPair(address(pool.lpToken)).token0(),
                IPair(address(pool.lpToken)).token1(),
                _amount.mul(pool.withDrawalFeeOfLpsBurn.add(pool.withDrawalFeeOfLpsTeam)).div(10000),
                0, 0, address(this), block.timestamp);

            // Ens assegurem que podem gastar els dos tokens i així els passem a BNB/Global i fem burn/team
            if (IBEP20(IPair(address(pool.lpToken)).token0()).allowance(address(this), address(routerGlobal)) == 0) {
                IBEP20(IPair(address(pool.lpToken)).token0()).safeApprove(address(routerGlobal), uint(- 1));
            }
            if (IBEP20(IPair(address(pool.lpToken)).token1()).allowance(address(this), address(routerGlobal)) == 0) {
                IBEP20(IPair(address(pool.lpToken)).token1()).safeApprove(address(routerGlobal), uint(- 1));
            }

            // Agafem el que cremem i el que enviem al equip per cada token rebut després de cremar LPs
            uint256 totalsplit = pool.withDrawalFeeOfLpsBurn.add(pool.withDrawalFeeOfLpsTeam);
            uint256 lpsToBuyNativeTokenAndBurn0 = amountToken0.mul(pool.withDrawalFeeOfLpsBurn).div( totalsplit );
            uint256 lpsToBuyNativeTokenAndBurn1 = amountToken1.mul(pool.withDrawalFeeOfLpsBurn).div( totalsplit);
            uint256 lpsToBuyBNBAndTransferForOperations0 = amountToken0.sub(lpsToBuyNativeTokenAndBurn0);
            uint256 lpsToBuyBNBAndTransferForOperations1 = amountToken1.sub(lpsToBuyNativeTokenAndBurn1);

            // Cremem i enviem els tokens a l'equip
            manageTokens(IPair(address(pool.lpToken)).token0(), lpsToBuyNativeTokenAndBurn0, lpsToBuyBNBAndTransferForOperations0);
            manageTokens(IPair(address(pool.lpToken)).token1(), lpsToBuyNativeTokenAndBurn1, lpsToBuyBNBAndTransferForOperations1);
        }
        return finalAmount;
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) public nonReentrant{
        require (_pid != 0, 'withdraw GLOBAL by unstaking');
        require (_pid < poolInfo.length, 'This pool does not exist yet');

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "[f] Withdraw: you are trying to withdraw more tokens than you have. Cheeky boy. Try again.");

        uint256 finalAmount = _amount;
        // Actualitzem # rewards per tokens LP i paguem rewards al contracte
        updatePool(_pid);

        // Paguem els rewards pendents o els deixem locked. Si feeTaken = true, no fem res, perque ja hem cobrat el fee dels rewards. En canvi, si és false, encara hem de cobrar fee sobre els LPs.
        // Aquí s'actualitza el accNativeTokenPerShare
        bool performancefeeTaken = payOrLockupPendingNativeToken(_pid);

        if(_amount > 0){
        // TESTEJAR AQUESTA FUNCIÓ MOLT PERÒ MOLT A FONS!!! ÉS NOVA I ÉS ON LA PODEM LIAR. Aquí s'actualitza el user.amount.
            if (!performancefeeTaken && !user.whitelisted){ 
                finalAmount = getLPFees(_pid, _amount);
            }

            // Possibles fallos que pot donar per aquí: usar IBEP20 enlloc de IPair o IPancakeERC20. swapAndLiquifyEnabled. Approves.
            // L'usuari deixa de tenir els tokens que ha demanat treure, pel que s'actualitza els LPs que li queden. Quan li enviem els LPs, li enviarem ["_amount demanat" - les fees cobrades] (si n'hi han).
            user.amount = user.amount.sub(_amount);

            // Al usuari li enviem els tokens LP demanats menys els LPs trets de fees, si fos el cas
            pool.lpToken.safeTransfer(address(msg.sender), finalAmount);
        }

        // Revisar això a fons (és nou). En principi, guardem els LPs actuals i la quantitat que ha cobrat per ells (total). El que li haguem restat després perque ens ho hem cobrat per fees, no hauria d'afectar, ja que és a posteriori i no de cara al usuari.
        // User ha rebut menys tokens si s'0han cobrat fees però a la info del user li és igual, només li interessa saber el total que se li ha gestionat per cobrar. El que se li desviï després, no hauria d'afectar
        user.rewardDebt = user.amount.mul(pool.accNativeTokenPerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Stake CAKE tokens to MasterChef
    function enterStaking(uint256 _amount) public onlyWhitelisted nonReentrant{
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[0][msg.sender];
        updatePool(0);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accNativeTokenPerShare).div(1e12).sub(user.rewardDebt);
            if(pending > 0) {
                SafeNativeTokenTransfer(msg.sender, pending);
            }
        }
        if(_amount > 0) {
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            user.amount = user.amount.add(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accNativeTokenPerShare).div(1e12);

        emit Deposit(msg.sender, 0, _amount);
    }

    // Withdraw CAKE tokens from STAKING.
    function leaveStaking(uint256 _amount) public onlyWhitelisted nonReentrant{
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[0][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(0);
        uint256 pending = user.amount.mul(pool.accNativeTokenPerShare).div(1e12).sub(user.rewardDebt);
        if(pending > 0) {
            SafeNativeTokenTransfer(msg.sender, pending);
        }
        if(_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accNativeTokenPerShare).div(1e12);

        emit Withdraw(msg.sender, 0, _amount);
    }

    // Withdraw of all tokens. Rewards are lost.
    function emergencyWithdraw(uint256 _pid) public nonReentrant {
        UserInfo storage user = userInfo[_pid][msg.sender];

        if (user.amount == 0){
            return;
        }

        uint256 finalAmount = user.amount;
        PoolInfo storage pool = poolInfo[_pid];

        // Si l'usuari vol sortir fent emergencyWithdraw és OK, però li hem de cobrar les fees si toca. En cas contrari, se les podria estalviar per la cara.
        if (safu && !withdrawalOrPerformanceFee(_pid, msg.sender) && !user.whitelisted){
            finalAmount = getLPFees(_pid, user.amount);
        }

        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        user.rewardLockedUp = 0;
        user.nextHarvestUntil = 0;
        user.withdrawalOrPerformanceFees = 0;
        pool.lpToken.safeTransfer(address(msg.sender), finalAmount);
        emit EmergencyWithdraw(msg.sender, _pid, amount, finalAmount);
    }

    // View function to see what kind of fee will be charged
    // Retornem + si cobrarem performance. False si cobrarem dels LPs.
    function withdrawalOrPerformanceFee(uint256 _pid, address _user) public view returns (bool) {
        UserInfo storage user = userInfo[_pid][_user];
        return block.timestamp >= user.withdrawalOrPerformanceFees;
    }

    // Update dev address by the previous dev.
    function setDevAddress(address _devAddress) public {
        require(msg.sender == devAddr, "[f] Dev: You don't have permissions to change the dev address. DRACARYS.");
        require(_devAddress != address(0), "[f] Dev: _devaddr can't be address(0).");
        devAddr = _devAddress;
    }

    // Safe native token transfer function, just in case if rounding error causes pool to not have enough native tokens.
    function SafeNativeTokenTransfer(address _to, uint256 _amount) internal {
        uint256 nativeTokenBal = nativeToken.balanceOf(address(this));
        if (_amount > nativeTokenBal) {
            nativeToken.transfer(_to, nativeTokenBal);
        } else {
            nativeToken.transfer(_to, _amount);
        }
    }

    function updateEmissionRate(uint256 _nativeTokenPerBlock) public onlyOwner {
        massUpdatePools();
        emit EmissionRateUpdated(msg.sender, nativeTokenPerBlock, _nativeTokenPerBlock);
        nativeTokenPerBlock = _nativeTokenPerBlock;
    }
}