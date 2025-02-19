pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./interfaces/IUniswapV2Rollover.sol";
import "./external/interfaces/IPancakeCallee.sol";
import "./BaseRollover.sol";

contract PancakeswapRollover is IUniswapV2Rollover, IPancakeCallee, BaseRollover {

  using SafeERC20 for IERC20;

  mapping(address => IUniswapV2Pair) public override tokenToPair;


  // _______USER FUNCTIONS_______

  function rolloverLoan(
    RolloverContractParams calldata contracts,
    uint256 loanId,
    LoanLibrary.LoanTerms calldata newLoanTerms,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external override virtual {
    ILoanCore sourceLoanCore = contracts.sourceLoanCore;
    LoanLibrary.LoanData memory loanData = sourceLoanCore.getLoan(loanId);
    LoanLibrary.LoanTerms memory loanTerms = loanData.terms;

    _validateRollover(sourceLoanCore, contracts.targetLoanCore, loanTerms, newLoanTerms, loanData.borrowerNoteId);
    

    {
      address token = loanTerms.payableCurrency;

      bytes memory params = abi.encode(
        OperationData({ contracts: contracts, loanId: loanId, newLoanTerms: newLoanTerms, v: v, r: r, s: s })
      );

      IUniswapV2Pair pair = tokenToPair[token];
      uint256 amount0Out;
      uint256 amount1Out;

      if (pair.token0() == token) {
        amount0Out = loanTerms.principal + loanTerms.interest;
      } else {
        amount1Out = loanTerms.principal + loanTerms.interest;
      }


      // Flash loan based on principal + interest
      pair.swap(amount0Out, amount1Out, address(this), params);
    }

    // Should not have any funds leftover
    require(IERC20(loanTerms.payableCurrency).balanceOf(address(this)) == 0, "leftover balance");
  }

  // _______ADMIN FUNCTIONS_______


  function setPairs(address[] calldata tokens, IUniswapV2Pair[] calldata pairs) public override onlyOwner {
    uint256 length = tokens.length;
    require(length == pairs.length, "mismatch length");
    for (uint256 i = 0; i < length; i++) {
      _setPair(tokens[i], pairs[i]);
    }

    emit SetPairs(tokens, pairs);
  }

  // _______HOOKS_______
  function pancakeCall(address initiator, uint256 amount0, uint256 amount1, bytes calldata data) external override {
    require(initiator == address(this), "not initiator");

    uint256 amount;
    address token;
    uint fee;
    {
      address token0 = IUniswapV2Pair(msg.sender).token0();
      address token1 = IUniswapV2Pair(msg.sender).token1();

      if (amount0 > 0) {
        amount = amount0;
        token = token0;
      } else {
        amount = amount1;
        token = token1;
      }

      require(amount0 == 0 || amount1 == 0, "this strategy is unidirectional");
      require(msg.sender == address(tokenToPair[token]), "invalid pair");

      // fee = amount * 3 / 997
      fee = ((amount + 332) * 3 / 997 ); // trick for minimal round up fee (332 = ((997 - 1) / 3))
    }

    _onLoan(IERC20(token), amount, fee, abi.decode(data, (OperationData)));
  }

  // _______INTERNAL FUNCTIONS_______

  function _setPair(address token, IUniswapV2Pair pair) internal {
    tokenToPair[token] = pair;
  }

  function _onLoan(
    IERC20 token,
    uint256 amount,
    uint256 fee,
    OperationData memory opData
  ) internal {
    OperationContracts memory opContracts = _getContracts(opData.contracts);

    // Get loan details
    LoanLibrary.LoanData memory loanData = opContracts.loanCore.getLoan(opData.loanId);

    address borrower = opContracts.borrowerNote.ownerOf(loanData.borrowerNoteId);
    address lender = opContracts.lenderNote.ownerOf(loanData.lenderNoteId);

    // Do accounting to figure out amount each party needs to receive
    (uint256 flashAmountDue, uint256 needFromBorrower, uint256 leftoverPrincipal) = _ensureFunds(
      amount,
      fee,
      opContracts.feeController.getOriginationFee(),
      opData.newLoanTerms.principal
    );


    if (needFromBorrower > 0) {
      require(token.balanceOf(borrower) >= needFromBorrower, "borrower cannot pay");
      require(token.allowance(borrower, address(this)) >= needFromBorrower, "lacks borrower approval");
    }

    _repayLoan(opContracts, loanData, borrower);
    uint256 newLoanId = _initializeNewLoan(
      opContracts, borrower, lender, loanData.terms.collateralTokenAddress, loanData.terms.collateralTokenId, opData
    );

    if (leftoverPrincipal > 0) {
      token.safeTransfer(borrower, leftoverPrincipal);
    } else if (needFromBorrower > 0) {
      token.safeTransferFrom(borrower, address(this), needFromBorrower);
    }

    // Set the allowance to payback the flash loan
    IERC20(token).safeTransfer(msg.sender, flashAmountDue);

    emit Rollover(lender, borrower, loanData.terms.collateralTokenId, newLoanId);

    if (address(opData.contracts.sourceLoanCore) != address(opData.contracts.targetLoanCore)) {
      emit Migration(address(opContracts.loanCore), address(opContracts.targetLoanCore), newLoanId);
    }
  }
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

import "../external/interfaces/IUniswapV2Pair.sol";


interface IUniswapV2Rollover {
  event SetPairs(
    address[] tokens,
    IUniswapV2Pair[] pairs
  );

  function tokenToPair(address) external returns (IUniswapV2Pair);

  function setPairs(address[] calldata tokens, IUniswapV2Pair[] calldata pairs) external;
}

pragma solidity ^0.8.0;

interface IPancakeCallee {
  function pancakeCall(
    address sender,
    uint256 amount0,
    uint256 amount1,
    bytes calldata data
  ) external;
}

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IRollover.sol";

abstract contract BaseRollover is IRollover, Ownable {


  // _______USER FUNCTIONS_______

  function rolloverLoan(
    RolloverContractParams calldata contracts,
    uint256 loanId,
    LoanLibrary.LoanTerms calldata newLoanTerms,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external override virtual;


  // _______HOOKS_______

  // _______ADMIN FUNCTIONS_______
  function flushToken(IERC20 token, address to) external override onlyOwner {
    uint256 balance = token.balanceOf(address(this));
    require(balance > 0, "no balance");

    token.transfer(to, balance);
  }

  // _______INTERNAL FUNCTIONS_______

  function _ensureFunds(
    uint256 amount,
    uint256 fee,
    uint256 originationFee,
    uint256 newPrincipal
  )
    internal
    pure
    returns (
      uint256 flashAmountDue,
      uint256 needFromBorrower,
      uint256 leftoverPrincipal
    )
  {
    // Make sure new loan, minus rifi fees, can be repaid
    flashAmountDue = amount + fee;
    uint256 willReceive = newPrincipal - ((newPrincipal * originationFee) / 10_000);

    if (flashAmountDue > willReceive) {
      // Not enough - have borrower pay the difference
      needFromBorrower = flashAmountDue - willReceive;
    } else if (willReceive > flashAmountDue) {
      // Too much - will send extra to borrower
      leftoverPrincipal = willReceive - flashAmountDue;
    }

    // Either leftoverPrincipal or needFromBorrower should be 0
    require(leftoverPrincipal == 0 || needFromBorrower == 0, "funds conflict");
  }

  function _repayLoan(
    OperationContracts memory contracts,
    LoanLibrary.LoanData memory loanData,
    address borrower
  ) internal {
    // Take BorrowerNote from borrower
    // Must be approved for withdrawal
    contracts.borrowerNote.transferFrom(borrower, address(this), loanData.borrowerNoteId);

    // Approve repayment
    IERC20(loanData.terms.payableCurrency).approve(
      address(contracts.repaymentController),
      loanData.terms.principal + loanData.terms.interest
    );

    // Repay loan
    contracts.repaymentController.repay(loanData.borrowerNoteId);

    // contract now has asset wrapper but has lost funds
    require(IERC721(loanData.terms.collateralTokenAddress).ownerOf(loanData.terms.collateralTokenId) == address(this), "collateral ownership");
  }

  function _initializeNewLoan(
    OperationContracts memory contracts,
    address borrower,
    address lender,
    address collateralTokenAddress,
    uint256 collateralTokenId,
    OperationData memory opData
  ) internal returns (uint256) {
    // approve originationController
    IERC721(collateralTokenAddress).approve(address(contracts.originationController), collateralTokenId);

    // start new loan
    // stand in for borrower to meet OriginationController's requirements
    uint256 newLoanId = contracts.originationController.initializeLoan(
      opData.newLoanTerms,
      address(this),
      lender,
      opData.v,
      opData.r,
      opData.s
    );

    LoanLibrary.LoanData memory newLoanData = contracts.targetLoanCore.getLoan(newLoanId);
    contracts.targetBorrowerNote.safeTransferFrom(address(this), borrower, newLoanData.borrowerNoteId);

    return newLoanId;
  }

  function _getContracts(RolloverContractParams memory contracts) internal returns (OperationContracts memory) {
    return
      OperationContracts({
        loanCore: contracts.sourceLoanCore,
        borrowerNote: contracts.sourceLoanCore.borrowerNote(),
        lenderNote: contracts.sourceLoanCore.lenderNote(),
        feeController: contracts.targetLoanCore.feeController(),
        repaymentController: contracts.sourceRepaymentController,
        originationController: contracts.targetOriginationController,
        targetLoanCore: contracts.targetLoanCore,
        targetBorrowerNote: contracts.targetLoanCore.borrowerNote()
      });
  }

  function _validateRollover(
    ILoanCore sourceLoanCore,
    ILoanCore targetLoanCore,
    LoanLibrary.LoanTerms memory sourceLoanTerms,
    LoanLibrary.LoanTerms calldata newLoanTerms,
    uint256 borrowerNoteId
  ) internal {
    require(sourceLoanCore.borrowerNote().ownerOf(borrowerNoteId) == msg.sender, "caller not borrower");

    require(newLoanTerms.payableCurrency == sourceLoanTerms.payableCurrency, "currency mismatch");

    require(
      newLoanTerms.collateralTokenAddress == sourceLoanTerms.collateralTokenAddress &&
      newLoanTerms.collateralTokenId == sourceLoanTerms.collateralTokenId, 
      "collateral mismatch"
    );

    require(sourceLoanTerms.durationSecs >= newLoanTerms.durationSecs, "new term duration could not be longer than old one");
  }

 
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

pragma solidity ^0.8.0;

interface IUniswapV2Pair {

  function token0() external view returns (address);
  function token1() external view returns (address);


  function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./ILoanCore.sol";
import "./IOriginationController.sol";
import "./IRepaymentController.sol";
import "./IAssetWrapper.sol";
import "./IFeeController.sol";

interface IRollover {
  event Rollover(
    address indexed lender, 
    address indexed borrower, 
    uint256 collateralTokenId, 
    uint256 newLoanId
  );
  event Migration(
    address indexed oldLoanCore, 
    address indexed newLoanCore, 
    uint256 newLoanId
  );

  /**
   * The contract references needed to roll
   * over the loan. Other dependent contracts
   * (asset wrapper, promissory notes) can
   * be fetched from the relevant LoanCore
   * contracts.
   */
  struct RolloverContractParams {
    ILoanCore sourceLoanCore;
    ILoanCore targetLoanCore;
    IRepaymentController sourceRepaymentController;
    IOriginationController targetOriginationController;
  }

  /**
   * Holds parameters passed through flash loan
   * control flow that dictate terms of the new loan.
   * Contains a signature by lender for same terms.
   * isLegacy determines which loanCore to look for the
   * old loan in.
   */
  struct OperationData {
    RolloverContractParams contracts;
    uint256 loanId;
    LoanLibrary.LoanTerms newLoanTerms;
    uint8 v;
    bytes32 r;
    bytes32 s;
  }

  /**
   * Defines the contracts that should be used for a
   * flash loan operation. May change based on if the
   * old loan is on the current loanCore or legacy (in
   * which case it requires migration).
   */
  struct OperationContracts {
    ILoanCore loanCore;
    IERC721 borrowerNote;
    IERC721 lenderNote;
    IFeeController feeController;
    IRepaymentController repaymentController;
    IOriginationController originationController;
    ILoanCore targetLoanCore;
    IERC721 targetBorrowerNote;
  }

  function rolloverLoan(
    RolloverContractParams calldata contracts,
    uint256 loanId,
    LoanLibrary.LoanTerms calldata newLoanTerms,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  function flushToken(IERC20 token, address to) external;

}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "../libraries/LoanLibrary.sol";

import "./IPromissoryNote.sol";
import "./IAssetWrapper.sol";
import "./IFeeController.sol";
import "./ILoanCore.sol";

/**
 * @dev Interface for the LoanCore contract
 */
interface ILoanCore {
    /**
     * @dev Emitted on initialization to share location of dependent notes
     */
    event Initialized(address assetWrapperToken, address borrowerNote, address lenderNote);

    /**
     * @dev Emitted when a loan is initially created
     */
    event LoanCreated(LoanLibrary.LoanTerms terms, uint256 loanId);

    /**
     * @dev Emitted when a loan is started and principal is distributed to the borrower.
     */
    event LoanStarted(uint256 loanId, address lender, address borrower);

    /**
     * @dev Emitted when a loan is repaid by the borrower
     */
    event LoanRepaid(uint256 loanId);

    /**
     * @dev Emitted when a loan collateral is claimed by the lender
     */
    event LoanClaimed(uint256 loanId);

    /**
     * @dev Emitted when fees are claimed by admin
     */
    event FeesClaimed(address token, address to, uint256 amount);

    /**
     * @dev Get LoanData by loanId
     */
    function getLoan(uint256 loanId) external view returns (LoanLibrary.LoanData calldata loanData);

    /**
     * @dev Create store a loan object with some given terms
     */
    function createLoan(LoanLibrary.LoanTerms calldata terms) external returns (uint256 loanId);

    /**
     * @dev Start a loan with the given borrower and lender
     *  Distributes the principal less the protocol fee to the borrower
     *
     * Requirements:
     *  - This function can only be called by a whitelisted OriginationController
     *  - The proper principal and collateral must have been sent to this contract before calling.
     */
    function startLoan(
        address lender,
        address borrower,
        uint256 loanId
    ) external;

    /**
     * @dev Repay the given loan
     *
     * Requirements:
     *  - The caller must be a holder of the borrowerNote
     *  - The caller must send in principal + interest
     *  - The loan must be in state Active
     */
    function repay(uint256 loanId) external;

    /**
     * @dev Claim the collateral of the given delinquent loan
     *
     * Requirements:
     *  - The caller must be a holder of the lenderNote
     *  - The loan must be in state Active
     *  - The current time must be beyond the dueDate
     */
    function claim(uint256 loanId) external;

    /**
     * @dev Claim the underlying assets from the collateral of the given delinquent loan
     * also return these assets one transaction
     *
     * Requirements:
     *  - The caller must be a holder of the borrowerNote
     *  - The loan must be in state Active
     *  - The collateral token must support flash claim
     */
    function flashClaim(uint256 loanId, address to, bytes calldata params) external;

    /**
     * @dev Getters for integrated contracts
     *
     */
    function borrowerNote() external returns (IPromissoryNote);

    function lenderNote() external returns (IPromissoryNote);

    function assetWrapperToken() external returns (IERC721);

    function feeController() external returns (IFeeController);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../libraries/LoanLibrary.sol";

/**
 * @dev Interface for the OriginationController contracts
 */
interface IOriginationController {
    /**
     * @dev initializes loan from loan core
     * Requirements:
     * - The caller must be a borrower or lender
     * - The external signer must not be msg.sender
     * - The external signer must be a borrower or lender
     * @param loanTerms - struct containing specifics of loan made between lender and borrower
     * @param borrower - address of borrowerPromissory note
     * @param lender - address of lenderPromissory note
     * @param v, r, s - signature from erc20
     */
    function initializeLoan(
        LoanLibrary.LoanTerms calldata loanTerms,
        address borrower,
        address lender,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 loanId);

    /**
     * @dev creates a new loan, with permit attached
     * @param loanTerms - struct containing specifics of loan made between lender and borrower
     * @param borrower - address of borrowerPromissory note
     * @param lender - address of lenderPromissory note
     * @param v, r, s - signature from erc20
     * @param collateralV, collateralR, collateralS - signature from collateral
     * @param permitDeadline - timestamp at which the collateral signature becomes invalid
     */
    function initializeLoanWithCollateralPermit(
        LoanLibrary.LoanTerms calldata loanTerms,
        address borrower,
        address lender,
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint8 collateralV,
        bytes32 collateralR,
        bytes32 collateralS,
        uint256 permitDeadline
    ) external returns (uint256 loanId);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IRepaymentController {
    /**
     * @dev used to repay a currently active loan.
     *
     * The loan must be in the Active state, and the
     * payableCurrency must be approved for withdrawal by the
     * repayment controller. This call will withdraw tokens
     * from the caller's wallet.
     *
     */
    function repay(uint256 borrowerNoteId) external;

    /**
     * @dev used to repay a currently active loan that is past due.
     *
     * The loan must be in the Active state, and the caller must
     * be the holder of the lender note.
     */
    function claim(uint256 lenderNoteId) external;
}

// SPDX-License-Identifier: MIT

import "./IAsset.sol";

pragma solidity ^0.8.0;

/**
 * @dev Interface for an AssetWrapper contract
 */
interface IAssetWrapper is IAsset {
    /**
     * @dev Emitted when an ERC20 token is deposited
     */
    event DepositERC20(address indexed depositor, uint256 indexed bundleId, address tokenAddress, uint256 amount);

    /**
     * @dev Emitted when an ERC721 token is deposited
     */
    event DepositERC721(address indexed depositor, uint256 indexed bundleId, address tokenAddress, uint256 tokenId);

    /**
     * @dev Emitted when an ERC1155 token is deposited
     */
    event DepositERC1155(
        address indexed depositor,
        uint256 indexed bundleId,
        address tokenAddress,
        uint256 tokenId,
        uint256 amount
    );

    /**
     * @dev Emitted when ETH is deposited
     */
    event DepositETH(address indexed depositor, uint256 indexed bundleId, uint256 amount);

    /**
     * @dev Emitted when a bundle is unwrapped.
     */
    event Withdraw(address indexed withdrawer, uint256 indexed bundleId);

    /**
     * @dev Creates a new bundle token for `to`. Its token ID will be
     * automatically assigned (and available on the emitted {IERC721-Transfer} event)
     *
     * See {ERC721-_mint}.
     */
    function initializeBundle(address to) external returns (uint256);

    /**
     * @dev Deposit some ERC20 tokens into a given bundle
     *
     * Requirements:
     *
     * - The bundle with id `bundleId` must have been initialized with {initializeBundle}
     * - `amount` tokens from `msg.sender` on `tokenAddress` must have been approved to this contract
     */
    function depositERC20(
        address tokenAddress,
        uint256 amount,
        uint256 bundleId
    ) external;

    /**
     * @dev Deposit an ERC721 token into a given bundle
     *
     * Requirements:
     *
     * - The bundle with id `bundleId` must have been initialized with {initializeBundle}
     * - The `tokenId` NFT from `msg.sender` on `tokenAddress` must have been approved to this contract
     */
    function depositERC721(
        address tokenAddress,
        uint256 tokenId,
        uint256 bundleId
    ) external;

    /**
     * @dev Deposit an ERC1155 token into a given bundle
     *
     * Requirements:
     *
     * - The bundle with id `bundleId` must have been initialized with {initializeBundle}
     * - The `tokenId` from `msg.sender` on `tokenAddress` must have been approved for at least `amount`to this contract
     */
    function depositERC1155(
        address tokenAddress,
        uint256 tokenId,
        uint256 amount,
        uint256 bundleId
    ) external;

    /**
     * @dev Deposit some ETH into a given bundle
     *
     * Requirements:
     *
     * - The bundle with id `bundleId` must have been initialized with {initializeBundle}
     */
    function depositETH(uint256 bundleId) external payable;

    /**
     * @dev Withdraw all assets in the given bundle, returning them to the msg.sender
     *
     * Requirements:
     *
     * - The bundle with id `bundleId` must have been initialized with {initializeBundle}
     * - The bundle with id `bundleId` must be owned by or approved to msg.sender
     */
    function withdraw(uint256 bundleId) external;
}

pragma solidity ^0.8.0;

interface IFeeController {
    /**
     * @dev Emitted when origination fee is updated
     */
    event UpdateOriginationFee(uint256 _newFee);

    function setOriginationFee(uint256 _originationFee) external;

    function getOriginationFee() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

library LoanLibrary {
    /**
     * @dev Enum describing the current state of a loan
     * State change flow:
     *  Created -> Active -> Repaid
     *                    -> Defaulted
     */
    enum LoanState {
        // We need a default that is not 'Created' - this is the zero value
        DUMMY_DO_NOT_USE,
        // The loan data is stored, but not initiated yet.
        Created,
        // The loan has been initialized, funds have been delivered to the borrower and the collateral is held.
        Active,
        // The loan has been repaid, and the collateral has been returned to the borrower. This is a terminal state.
        Repaid,
        // The loan was delinquent and collateral claimed by the lender. This is a terminal state.
        Defaulted
    }

    /**
     * @dev The raw terms of a loan
     */
    struct LoanTerms {
        // The number of seconds representing relative due date of the loan
        uint256 durationSecs;
        // The amount of principal in terms of the payableCurrency
        uint256 principal;
        // The amount of interest in terms of the payableCurrency
        uint256 interest;
        // The token address of the collateral
        address collateralTokenAddress;
        // The tokenID of the collateral
        uint256 collateralTokenId;
        // The payable currency for the loan principal and interest
        address payableCurrency;
        // The deadline of making a transaction
        uint256 deadline;
    }

    /**
     * @dev The data of a loan. This is stored once the loan is Active
     */
    struct LoanData {
        // The tokenId of the borrower note
        uint256 borrowerNoteId;
        // The tokenId of the lender note
        uint256 lenderNoteId;
        // The raw terms of the loan
        LoanTerms terms;
        // The current state of the loan
        LoanState state;
        // Timestamp representing absolute due date date of the loan
        uint256 dueDate;
    }
}

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

interface IPromissoryNote is IERC721 {
    // Getter for mapping: mapping(uint256 => uint256) public loanIdByNoteId;
    function loanIdByNoteId(uint256 noteId) external view returns (uint256);

    function mint(address to, uint256 loanId) external returns (uint256);

    function burn(uint256 tokenId) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAsset {
  struct ERC20Holding {
    address tokenAddress;
    uint256 amount;
  }

  struct ERC721Holding {
    address tokenAddress;
    uint256 tokenId;
  }

  struct ERC1155Holding {
    address tokenAddress;
    uint256 tokenId;
    uint256 amount;
  }
}