/**
 *Submitted for verification at BscScan.com on 2022-10-06
*/

// File: @openzeppelin/[email protected]/utils/Address.sol


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

// File: @openzeppelin/[email protected]/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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

// File: TestToken/IFixedInterestTestToken.sol


pragma solidity ^0.8.0;


interface IFixedInterestTestToken is IERC20 {
    function mintInterest(address account, uint256 amount) external returns (bool);
    function burnTokenFrom(address account, uint256 amount) external returns (bool);
}
// File: TestToken/IFixedGovTestToken.sol


pragma solidity ^0.8.0;


interface IFixedGovTestToken is IERC20 {
    function burnTokenFrom(address account, uint256 amount) external returns (bool);
}
// File: TestToken/IFixedTestToken.sol


pragma solidity ^0.8.0;


interface IFixedTestToken is IERC20 {
    function mintInterest(address account, uint256 amount) external returns (bool);
    function burnTokenFrom(address account, uint256 amount) external returns (bool);
}
// File: @openzeppelin/[email protected]/token/ERC20/utils/SafeERC20.sol


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

// File: @openzeppelin/[email protected]/security/ReentrancyGuard.sol


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

// File: TestToken/TestTokenStaking.sol


pragma solidity ^0.8.0;







/**
 * @title TokenDistributor
 * @notice It handles the distribution of LOOKS token.
 * It auto-adjusts block rewards over a set number of periods.
 */
contract TestTokenStaking is ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeERC20 for IFixedTestToken;
    using SafeERC20 for IFixedInterestTestToken;
    using SafeERC20 for IFixedGovTestToken;


    struct StakeInfo {
        uint256 dateStaked;
        uint256 initialAmount;
        uint256 balanceAmount;
        uint256 redeemedAmount;
        uint256 interestAmount;
        uint256 buybackAmount;
    }

    struct UserInfo {
        uint256 totalInitialAmount;
        uint256 totalBalanceAmount;
        uint256 totalRedeemedAmount;
        uint256 totalBuybackAmount;
        uint256 totalInterestAmount;
    }

    struct RedeemInfo {
        uint256 buybackAmount;
        uint256 interestAmount;
        uint256 redeemableAmount;
    }


    // Precision factor for calculating rewards
    uint256 public constant PRECISION_FACTOR = 10**8;
    uint256 public buybackRate = 2;
    uint256 public interestRate = 9;
    uint256 public govTokenRatio = 5;
    uint256 public stakeLimit = 5000000 * PRECISION_FACTOR ;

    IFixedTestToken public immutable FixedTestToken;
    IFixedInterestTestToken public immutable FixedInterestTestToken;
    IFixedGovTestToken public immutable FixedGovTestToken;
    address public immutable CommunityDistributor;

    // Total amount staked
    uint256 public totalAmountStaked;

    mapping(address => UserInfo) public userMapping;
    mapping(address => StakeInfo[]) public stakeMapping;

    event Deposit(address indexed user, uint256 amount);
    event Unstake(address indexed user, uint256 amount);
    event RedeemInterest(address indexed user);
    event UpdateDateTest(address indexed user, uint256 day, uint256 index);

    /**
     * @notice Constructor
     * @param _FixedTestToken token address
     * @param _FixedInterestTestToken token address
     * @param _FixedGovTestToken token address
     * @param _CommunityDistributor contract address
     */
    constructor(
        address _FixedTestToken,
        address _FixedInterestTestToken,
        address _FixedGovTestToken,
        address _CommunityDistributor
    ) {

        FixedTestToken = IFixedTestToken(_FixedTestToken);
        FixedInterestTestToken = IFixedInterestTestToken(_FixedInterestTestToken);
        FixedGovTestToken = IFixedGovTestToken(_FixedGovTestToken);
        CommunityDistributor = address(_CommunityDistributor);
    }

    /**
     * @notice Deposit staked tokens and compounds pending rewards
     * @param amount amount to deposit (in LOOKS)
     */
    function deposit(uint256 amount) external nonReentrant {
        require(amount > 0, "Deposit: Amount must be > 0");

        require(amount <= stakeLimit, "Deposit: Amount must be < Stake Limit");

        // Transfer LOOKS tokens to this contract
        FixedTestToken.safeTransferFrom(msg.sender, address(this), amount);

        userMapping[msg.sender].totalInitialAmount += amount;
        userMapping[msg.sender].totalBalanceAmount += amount;
        stakeMapping[msg.sender].push(StakeInfo(block.timestamp, amount, amount, 0, 0, 0));
        
        // Increase totalAmountStaked
        totalAmountStaked += (amount);

        stakeLimit -= (amount);

        emit Deposit(msg.sender, amount);
    }

    function redeemInterest() external nonReentrant {

        RedeemInfo memory redeemResult = calculateTotalRedeemable(msg.sender);
        
        require(redeemResult.redeemableAmount != 0, "Interest: Nothing to redeem");

        if (redeemResult.interestAmount != 0) {
            FixedInterestTestToken.mintInterest(msg.sender, redeemResult.interestAmount);
        } 

        if (redeemResult.buybackAmount != 0) {
            FixedTestToken.safeTransfer(msg.sender, redeemResult.buybackAmount);
        } 
        
        FixedTestToken.burnTokenFrom(msg.sender, redeemResult.buybackAmount);
        FixedInterestTestToken.burnTokenFrom(msg.sender, redeemResult.interestAmount);

        FixedGovTestToken.safeTransferFrom(CommunityDistributor, msg.sender, redeemResult.buybackAmount * 10**10 / govTokenRatio);

        for (uint i = 0; i < stakeMapping[msg.sender].length; i++) {
            uint buybackCount = uint(block.timestamp - stakeMapping[msg.sender][i].dateStaked) / (86400 * 30);
            if (buybackCount > (100 / buybackRate) ) {
                buybackCount = 100 / buybackRate;
            }
            uint buyback = uint(buybackRate * stakeMapping[msg.sender][i].initialAmount * buybackCount) / 100; 
            uint balance = stakeMapping[msg.sender][i].initialAmount;
            uint interest = 0;
            for (uint j = 0; j < buybackCount; j++) {
                interest += uint(interestRate * balance) / 100 / 12 ; 
                balance -= uint(buybackRate * stakeMapping[msg.sender][i].initialAmount) / 100;
            }
            uint buybackAmount = buyback - stakeMapping[msg.sender][i].buybackAmount;
            uint interestAmount = interest - stakeMapping[msg.sender][i].interestAmount;

            stakeMapping[msg.sender][i].balanceAmount -= buybackAmount;
            userMapping[msg.sender].totalBalanceAmount -= buybackAmount;

            stakeMapping[msg.sender][i].interestAmount += interestAmount;
            userMapping[msg.sender].totalInterestAmount += interestAmount;

            stakeMapping[msg.sender][i].buybackAmount += buybackAmount;
            userMapping[msg.sender].totalBuybackAmount += buybackAmount;

            stakeMapping[msg.sender][i].redeemedAmount += buybackAmount + interestAmount;
            userMapping[msg.sender].totalRedeemedAmount += buybackAmount + interestAmount;
        }

        emit RedeemInterest(msg.sender);
    }


    /**
     * @notice Withdraw all staked tokens and collect tokens
     */
    function unstake(uint stakeId) external nonReentrant {

        RedeemInfo memory redeemResult = calculateRedeemable(msg.sender, stakeId);
        
        require(redeemResult.redeemableAmount == 0, "Unstake: Redeemable token unclaim");

        require(stakeMapping[msg.sender][stakeId].balanceAmount > 0, "Withdraw: Amount must be > 0");

        uint256 amountToTransfer = stakeMapping[msg.sender][stakeId].balanceAmount;
        
        // Adjust total amount staked
        totalAmountStaked = totalAmountStaked - stakeMapping[msg.sender][stakeId].balanceAmount;

        userMapping[msg.sender].totalInitialAmount -= stakeMapping[msg.sender][stakeId].balanceAmount;
        userMapping[msg.sender].totalBalanceAmount -= stakeMapping[msg.sender][stakeId].balanceAmount;

        stakeLimit = stakeLimit + stakeMapping[msg.sender][stakeId].balanceAmount;

        for(uint i = stakeId; i < stakeMapping[msg.sender].length - 1; i++){
            stakeMapping[msg.sender][i] = stakeMapping[msg.sender][i + 1];      
        }
        stakeMapping[msg.sender].pop();

        // Transfer LOOKS tokens to the sender
        FixedTestToken.safeTransfer(msg.sender, amountToTransfer);

        emit Unstake(msg.sender, amountToTransfer);
    }

    function getTotalRedeemableAmount(address account) external view returns (RedeemInfo memory) {

        RedeemInfo memory redeemResult = calculateTotalRedeemable(account);

        return redeemResult;
        
    }

    function getRedeemableAmount(address account, uint256 index) external view returns (string[] memory, RedeemInfo memory) {

        RedeemInfo memory redeemResult = calculateRedeemable(account, index);

        string[]  memory category = new string[](3);
        category[0] = string('buybackAmount');
        category[1] = string('interestAmount');
        category[2] = string('redeemableAmount');

        return (category, redeemResult);
        
    }

    function getStakeCount(address account) external view returns (uint) {

        return stakeMapping[account].length;
        
    }

    function calculateTotalRedeemable(address account) internal view returns (RedeemInfo memory) {

        uint256 buybackAmount = 0;
        uint256 interestAmount = 0;

        for (uint i = 0; i < stakeMapping[account].length; i++) {

            RedeemInfo memory redeemResult = calculateRedeemable(account, i);

            buybackAmount += redeemResult.buybackAmount;
            interestAmount += redeemResult.interestAmount;
        }

        RedeemInfo memory totalRedeemResult = RedeemInfo(buybackAmount, interestAmount, buybackAmount + interestAmount);

        return totalRedeemResult;

    }

    function calculateRedeemable(address account, uint256 index) internal view returns (RedeemInfo memory) {

        uint buybackCount = uint(block.timestamp - stakeMapping[account][index].dateStaked) / (86400 * 30);
        uint buyback = uint(buybackRate * stakeMapping[account][index].initialAmount * buybackCount) / 100; 
        uint balance = stakeMapping[account][index].initialAmount;
        uint interest = 0;
        for (uint j = 0; j < buybackCount; j++) {
            interest += uint(interestRate * balance) / 100 / 12 ; 
            balance -= uint(buybackRate * stakeMapping[account][index].initialAmount) / 100;
        }

        uint buybackAmount = buyback - stakeMapping[account][index].buybackAmount;
        uint interestAmount = interest - stakeMapping[account][index].interestAmount;

        RedeemInfo memory redeemResult = RedeemInfo(buybackAmount, interestAmount, buybackAmount + interestAmount);

        return redeemResult;
    }


    function updateDateTest(uint256 day, uint256 index) external nonReentrant {

        stakeMapping[msg.sender][index].dateStaked -= 86400 * day;

        emit UpdateDateTest(msg.sender, day, index);
    }

}