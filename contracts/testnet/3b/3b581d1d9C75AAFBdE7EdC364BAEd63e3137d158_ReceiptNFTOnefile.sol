/**
 *Submitted for verification at BscScan.com on 2022-09-10
*/

//SPDX-License-Identifier: Unlicense
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
}

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    // function name() external view returns (string memory);
    // function symbol() external view returns (string memory);
    // function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

interface IUniswapV2Router01 {
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

interface IUniswapV2Router02 is IUniswapV2Router01 {
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

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}


interface IUniswapV2Pair {
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



interface IDodoStrategy {
  function BONUS_MULTIPLIER (  ) external view returns ( uint256 );
  function CLIP (  ) external view returns ( address );
  function CLIPPerBlock (  ) external view returns ( uint256 );
  function add ( uint256 _allocPoint, address _lpToken, bool _withUpdate ) external;
  function deposit ( uint256 _pid, uint256 _amount ) external;
  function depositedClip (  ) external view returns ( uint256 );
  function devPercent (  ) external view returns ( uint256 );
  function devaddr (  ) external view returns ( address );
  function emergencyWithdraw ( uint256 _pid ) external;
  function enterStaking ( uint256 _amount ) external;
  function getMultiplier ( uint256 _from, uint256 _to ) external view returns ( uint256 );
  function lastBlockDevWithdraw (  ) external view returns ( uint256 );
  function leaveStaking ( uint256 _amount ) external;
  function massUpdatePools (  ) external;
  function migrate ( uint256 _pid ) external;
  function migrator (  ) external view returns ( address );
  function owner (  ) external view returns ( address );
  function pendingCLIP ( uint256 _pid, address _user ) external view returns ( uint256 );
  function percentDec (  ) external view returns ( uint256 );
  function poolInfo ( uint256 ) external view returns ( address lpToken, uint256 allocPoint, uint256 lastRewardBlock, uint256 accCLIPPerShare );
  function poolLength (  ) external view returns ( uint256 );
  function refAddr (  ) external view returns ( address );
  function refPercent (  ) external view returns ( uint256 );
  function renounceOwnership (  ) external;
  function safuPercent (  ) external view returns ( uint256 );
  function safuaddr (  ) external view returns ( address );
  function set ( uint256 _pid, uint256 _allocPoint, bool _withUpdate ) external;
  function setDevAddress ( address _devaddr ) external;
  function setMigrator ( address _migrator ) external;
  function setRefAddress ( address _refaddr ) external;
  function setSafuAddress ( address _safuaddr ) external;
  function stakingPercent (  ) external view returns ( uint256 );
  function startBlock (  ) external view returns ( uint256 );
  function totalAllocPoint (  ) external view returns ( uint256 );
  function transferOwnership ( address newOwner ) external;
  function updateClipPerBlock ( uint256 newAmount ) external;
  function updateMultiplier ( uint256 multiplierNumber ) external;
  function updatePool ( uint256 _pid ) external;
  function userInfo ( uint256, address ) external view returns ( uint256 amount, uint256 rewardDebt );
  function withdraw ( uint256 _pid, uint256 _amount ) external;
  function withdrawDevAndRefFee (  ) external;
  function myStakedBalance() external view returns(uint256);
}

library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}


/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
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
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}


library EnumerableSetExtension {
    /// @dev Function will revert if address is not in set.
    function indexOf(EnumerableSet.AddressSet storage set, address value) internal view returns (uint256 index) {
        return set._inner._indexes[bytes32(uint256(uint160(value)))] - 1;
    }
}


interface IExchangePlugin {
    
    function swap(
        uint256 amountA,
        address tokenA,
        address tokenB,
        address to
    ) external returns (uint256 amountReceivedTokenB);

    /// @notice Returns percent taken by DEX on which we swap provided tokens.
    /// @dev Fee percent has 18 decimals.
    function getFee(address tokenA, address tokenB)
        external
        view
        returns (uint256 feePercent);

    /// @notice Synonym of the uniswapV2's function, estimates amount you receive after swap.
    function getAmountOut(uint256 amountA, address tokenA, address tokenB)
        external
        view
        returns (uint256 amountOut);
}


contract Exchange is Ownable {
    error RoutedSwapFailed();
    error RouteNotFound();

    struct RouteParams {
        // default exchange to use, could have low slippage but also lower liquidity
        address defaultRoute;
        // whenever input amount is over limit, then should use secondRoute
        uint256 limit;
        // second exchange, could have higher slippage but also higher liquidity
        address secondRoute;
    }

    // which plugin to use for swap for this pair
    // tokenA -> tokenB -> RouteParams
    mapping(address => mapping(address => RouteParams)) public routes;

    uint256 private constant LIMIT_PRECISION = 1e12;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        // lock implementation
        // _disableInitializers();
    }

    // function initialize() external initializer {
    //     __Ownable_init();
    //     __UUPSUpgradeable_init();
    // }

    // function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /// @notice Choose plugin where pair of tokens should be swapped.
    function setRoute(
        address[] calldata tokensA,
        address[] calldata tokensB,
        address[] calldata plugin
    ) external onlyOwner {
        for (uint256 i = 0; i < tokensA.length; i++) {
            (address token0, address token1) = sortTokens(tokensA[i], tokensB[i]);
            routes[token0][token1].defaultRoute = plugin[i];
        }
    }

    function setRouteEx(
        address[] calldata tokensA,
        address[] calldata tokensB,
        RouteParams[] calldata _routes
    ) external onlyOwner {
        for (uint256 i = 0; i < tokensA.length; i++) {
            (address token0, address token1) = sortTokens(tokensA[i], tokensB[i]);
            routes[token0][token1] = _routes[i];
        }
    }

    function getPlugin(
        uint256 amountA,
        address tokenA,
        address tokenB
    ) public view returns (address plugin) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        uint256 limit = routes[token0][token1].limit;
        // decimals: 12 + tokenA.decimals - 12 = tokenA.decimals
        uint256 limitWithDecimalsOfTokenA = limit * 10**ERC20(tokenA).decimals() / LIMIT_PRECISION;
        if (limit == 0 || amountA < limitWithDecimalsOfTokenA) plugin = routes[token0][token1].defaultRoute;
        else plugin = routes[token0][token1].secondRoute;
        if (plugin == address(0)) revert RouteNotFound();
        return plugin;
    }

    function getFee(
        uint256 amountA,
        address tokenA,
        address tokenB
    ) public view returns (uint256 feePercent) {
        address plugin = getPlugin(amountA, address(tokenA), address(tokenB));
        return IExchangePlugin(plugin).getFee(tokenA, tokenB);
    }

    function getAmountOut(
        uint256 amountA,
        address tokenA,
        address tokenB
    ) external view returns (uint256 amountOut) {
        address plugin = getPlugin(amountA, address(tokenA), address(tokenB));
        return IExchangePlugin(plugin).getAmountOut(amountA, tokenA, tokenB);
    }

    function swap(
        uint256 amountA,
        address tokenA,
        address tokenB,
        address to
    ) public returns (uint256 amountReceived) {
        address plugin = getPlugin(amountA, address(tokenA), address(tokenB));
        IERC20(tokenA).transfer(plugin, amountA);
        amountReceived = IExchangePlugin(plugin).swap(amountA, tokenA, tokenB, to);
        if (amountReceived == 0) revert RoutedSwapFailed();
    }

    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    }
}

interface IUsdOracle {
    /// @notice Get usd value of token `base`.
    function getTokenUsdPrice(address base)
        external
        view
        returns (uint256 price, uint8 decimals);
}


// /// @notice This contract contains batch related code, serves as part of StrategyRouter.
// /// @notice This contract should be owned by StrategyRouter.
// contract Batch is Ownable {
//     using EnumerableSet for EnumerableSet.AddressSet;
//     using EnumerableSetExtension for EnumerableSet.AddressSet;

//     /* ERRORS */

//     error AlreadySupportedToken();
//     error CantRemoveTokenOfActiveStrategy();
//     error UnsupportedToken();
//     error NotReceiptOwner();
//     error CycleClosed();
//     error DepositUnderMinimum();
//     error NotEnoughBalanceInBatch();
//     error CallerIsNotStrategyRouter();

//     /// @notice Fires when user withdraw from batch.
//     /// @param token Supported token that user requested to receive after withdraw.
//     /// @param amount Amount of `token` received by user.
//     event WithdrawFromBatch(address indexed user, address token, uint256 amount);
//     event SetAddresses(address _exchange, address _oracle, address _router, address _receiptNft);

//     uint8 public constant UNIFORM_DECIMALS = 18;
//     // used in rebalance function, UNIFORM_DECIMALS, so 1e17 == 0.1
//     uint256 public constant REBALANCE_SWAP_THRESHOLD = 1e17;

//     uint256 public minDeposit;

//     ReceiptNFTOnefile public receiptContract;
//     Exchange public exchange;
//     StrategyRouter public router;
//     IUsdOracle public oracle;

//     EnumerableSet.AddressSet private supportedTokens;

//     modifier onlyStrategyRouter() {
//         if (msg.sender != address(router)) revert CallerIsNotStrategyRouter();
//         _;
//     }

//     /// @custom:oz-upgrades-unsafe-allow constructor
//     constructor() {
//         // lock implementation
//         // _disableInitializers();
//     }

//     // function initialize() external initializer {
//     //     __Ownable_init();
//     //     __UUPSUpgradeable_init();
//     // }

//     function setAddresses(
//         Exchange _exchange,
//         IUsdOracle _oracle,
//         StrategyRouter _router,
//         ReceiptNFTOnefile _receiptNft
//     ) external onlyOwner {
//         exchange = _exchange;
//         oracle = _oracle;
//         router = _router;
//         receiptContract = _receiptNft;
//         emit SetAddresses(_exchange, _oracle, _router, _receiptNft);
//     }

//     // function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

//     // Universal Functions

//     function supportsToken(address tokenAddress) public view returns (bool) {
//         return supportedTokens.contains(tokenAddress);
//     }

//     /// @dev Returns list of supported tokens.
//     function getSupportedTokens() public view returns (address[] memory) {
//         return supportedTokens.values();
//     }

//     function getBatchValueUsd()
//         public
//         view
//         returns (uint256 totalBalanceUsd, uint256[] memory supportedTokenBalancesUsd)
//     {
//         supportedTokenBalancesUsd = new uint256[](supportedTokens.length());
//         for (uint256 i; i < supportedTokenBalancesUsd.length; i++) {
//             address token = supportedTokens.at(i);
//             uint256 balance = ERC20(token).balanceOf(address(this));

//             (uint256 price, uint8 priceDecimals) = oracle.getTokenUsdPrice(token);
//             balance = ((balance * price) / 10**priceDecimals);
//             balance = toUniform(balance, token);
//             supportedTokenBalancesUsd[i] = balance;
//             totalBalanceUsd += balance;
//         }
//     }

//     // User Functions

//     /// @notice Withdraw tokens from batch while receipts are in batch.
//     /// @notice Receipts are burned.
//     /// @param receiptIds Receipt NFTs ids.
//     /// @dev Only callable by user wallets.
//     function withdraw(
//         address receiptOwner,
//         uint256[] calldata receiptIds,
//         uint256 _currentCycleId
//     ) public onlyStrategyRouter {
//         for (uint256 i = 0; i < receiptIds.length; i++) {
//             uint256 receiptId = receiptIds[i];
//             if (receiptContract.ownerOf(receiptId) != receiptOwner) revert NotReceiptOwner();

//             ReceiptNFTOnefile.ReceiptData memory receipt = receiptContract.getReceipt(receiptId);

//             // only for receipts in current batch
//             if (receipt.cycleId != _currentCycleId) revert CycleClosed();

//             uint256 transferAmount = fromUniform(receipt.tokenAmountUniform, receipt.token);
//             ERC20(receipt.token).transfer(receiptOwner, transferAmount);
//             receiptContract.burn(receiptId);
//             emit WithdrawFromBatch(msg.sender, receipt.token, transferAmount);
//         }
//     }

//     /// @notice converting token USD amount to token amount, i.e $1000 worth of token with price of $0.5 is 2000 tokens
//     function calculateTokenAmountFromUsdAmount(uint256 valueUsd, address token)
//         internal
//         view
//         returns (uint256 tokenAmountToTransfer)
//     {
//         (uint256 tokenUsdPrice, uint8 oraclePriceDecimals) = oracle.getTokenUsdPrice(token);
//         tokenAmountToTransfer = (valueUsd * 10**oraclePriceDecimals) / tokenUsdPrice;
//         tokenAmountToTransfer = fromUniform(tokenAmountToTransfer, token);
//     }

//     /// @notice Deposit token into batch.
//     /// @notice Tokens not deposited into strategies immediately.
//     /// @param depositToken Supported token to deposit (Must be an NFT).
//     /// @param _amount Amount to deposit.
//     /// @dev User should approve `_amount` of `depositToken` to this contract.
//     /// @dev Only callable by user wallets.
//     function deposit(
//         address depositor,
//         address depositToken,
//         uint256 _amount,
//         uint256 _currentCycleId
//     ) external onlyStrategyRouter {
//         if (!supportsToken(depositToken)) revert UnsupportedToken();
//         (uint256 price, uint8 priceDecimals) = oracle.getTokenUsdPrice(depositToken);
//         uint256 depositedUsd = toUniform((_amount * price) / 10**priceDecimals, depositToken);
//         if (minDeposit > depositedUsd) revert DepositUnderMinimum();

//         uint256 amountUniform = toUniform(_amount, depositToken);

//         receiptContract.mint(_currentCycleId, amountUniform, depositToken, depositor);
//     }

//     function transfer(
//         address token,
//         address to,
//         uint256 amount
//     ) external onlyStrategyRouter {
//         ERC20(token).transfer(to, amount);
//     }

//     // Admin functions

//     /// @notice Minimum to be deposited in the batch.
//     /// @param amount Amount of usd, must be `UNIFORM_DECIMALS` decimals.
//     /// @dev Admin function.
//     function setMinDepositUsd(uint256 amount) external onlyStrategyRouter {
//         minDeposit = amount;
//     }

//     /// @notice Rebalance batch, so that token balances will match strategies weight.
//     /// @return balances Amounts to be deposited in strategies, balanced according to strategies weights.
//     function rebalance() public onlyStrategyRouter returns (uint256[] memory balances) {
//         /*
//         1 store supported-tokens (set of unique addresses)
//             [a,b,c]
//         2 store their balances
//             [10, 6, 8]
//         3 store their sum with uniform decimals
//             24
//         4 create array of length = supported_tokens + strategies_tokens (e.g. [a])
//             [a, b, c] + [a] = 4
//         5 store in that array balances from step 2, duplicated tokens should be ignored
//             [10, 0, 6, 8] (instead of [10,10...] we got [10,0...] because first two are both token a)
//         6a get desired balance for every strategy using their weights
//             [12, 0, 4.8, 7.2] (our 1st strategy will get 50%, 2nd and 3rd will get 20% and 30% respectively)
//         6b store amounts that we need to sell or buy for each balance in order to match desired balances
//             toSell [0, 0, 1.2, 0.8]
//             toBuy  [2, 0, 0, 0]
//             these arrays contain amounts with tokens' original decimals
//         7 now sell 'toSell' amounts of respective tokens for 'toBuy' tokens
//             (token to amount connection is derived by index in the array)
//             (also track new strategies balances for cases where 1 token is shared by multiple strategies)
//         */
//         uint256 totalInBatch;

//         // point 1
//         uint256 supportedTokensCount = supportedTokens.length();
//         address[] memory _tokens = new address[](supportedTokensCount);
//         uint256[] memory _balances = new uint256[](supportedTokensCount);

//         // point 2
//         for (uint256 i; i < supportedTokensCount; i++) {
//             _tokens[i] = supportedTokens.at(i);
//             _balances[i] = ERC20(_tokens[i]).balanceOf(address(this));

//             // point 3
//             totalInBatch += toUniform(_balances[i], _tokens[i]);
//         }

//         // point 4
//         uint256 strategiesCount = router.getStrategiesCount();

//         uint256[] memory _strategiesAndSupportedTokensBalances = new uint256[](strategiesCount + supportedTokensCount);

//         // point 5
//         // We fill in strategies balances with tokens that strategies are accepting and ignoring duplicates
//         for (uint256 i; i < strategiesCount; i++) {
//             address depositToken = router.getStrategyDepositToken(i);
//             for (uint256 j; j < supportedTokensCount; j++) {
//                 if (depositToken == _tokens[j] && _balances[j] > 0) {
//                     _strategiesAndSupportedTokensBalances[i] = _balances[j];
//                     _balances[j] = 0;
//                     break;
//                 }
//             }
//         }

//         // we fill in strategies balances with balances of remaining tokens that are supported as deposits but are not
//         // accepted in strategies
//         for (uint256 i = strategiesCount; i < _strategiesAndSupportedTokensBalances.length; i++) {
//             _strategiesAndSupportedTokensBalances[i] = _balances[i - strategiesCount];
//         }

//         // point 6a
//         uint256[] memory toBuy = new uint256[](strategiesCount);
//         uint256[] memory toSell = new uint256[](_strategiesAndSupportedTokensBalances.length);
//         for (uint256 i; i < strategiesCount; i++) {
//             uint256 desiredBalance = (totalInBatch * router.getStrategyPercentWeight(i)) / 1e18;
//             desiredBalance = fromUniform(desiredBalance, router.getStrategyDepositToken(i));
//             // we skip safemath check since we already do comparison in if clauses
//             unchecked {
//                 // point 6b
//                 if (desiredBalance > _strategiesAndSupportedTokensBalances[i]) {
//                     toBuy[i] = desiredBalance - _strategiesAndSupportedTokensBalances[i];
//                 } else if (desiredBalance < _strategiesAndSupportedTokensBalances[i]) {
//                     toSell[i] = _strategiesAndSupportedTokensBalances[i] - desiredBalance;
//                 }
//             }
//         }

//         // point 7
//         // all tokens we accept to deposit but are not part of strategies therefore we are going to swap them
//         // to tokens that strategies are accepting
//         for (uint256 i = strategiesCount; i < _strategiesAndSupportedTokensBalances.length; i++) {
//             toSell[i] = _strategiesAndSupportedTokensBalances[i];
//         }

//         for (uint256 i; i < _strategiesAndSupportedTokensBalances.length; i++) {
//             for (uint256 j; j < strategiesCount; j++) {
//                 // if we are not going to buy this token (nothing to sell), we simply skip to the next one
//                 // if we can sell this token we go into swap routine
//                 // we proceed to swap routine if there is some tokens to buy and some tokens sell
//                 // if found which token to buy and which token to sell we proceed to swap routine
//                 if (toSell[i] > 0 && toBuy[j] > 0) {
//                     // if toSell's 'i' greater than strats-1 (e.g. strats 2, tokens 2, i=2, 2>2-1==true)
//                     // then take supported_token[2-2=0]
//                     // otherwise take strategy_token[0 or 1]
//                     address sellToken = i > strategiesCount - 1
//                         ? _tokens[i - strategiesCount]
//                         : router.getStrategyDepositToken(i);
//                     address buyToken = router.getStrategyDepositToken(j);

//                     uint256 toSellUniform = toUniform(toSell[i], sellToken);
//                     uint256 toBuyUniform = toUniform(toBuy[j], buyToken);
//                     /*
//                     Weight of strategies is in token amount not usd equivalent
//                     In case of stablecoin depeg an administrative decision will be made to move out of the strategy
//                     that has exposure to depegged stablecoin.
//                     curSell should have sellToken decimals
//                     */
//                     uint256 curSell = toSellUniform > toBuyUniform
//                         ? changeDecimals(toBuyUniform, UNIFORM_DECIMALS, ERC20(sellToken).decimals())
//                         : toSell[i];

//                     // no need to swap small amounts
//                     if (toUniform(curSell, sellToken) < REBALANCE_SWAP_THRESHOLD) {
//                         toSell[i] = 0;
//                         toBuy[j] -= changeDecimals(curSell, ERC20(sellToken).decimals(), ERC20(buyToken).decimals());
//                         break;
//                     }
//                     uint256 received = _trySwap(curSell, sellToken, buyToken);

//                     _strategiesAndSupportedTokensBalances[i] -= curSell;
//                     _strategiesAndSupportedTokensBalances[j] += received;
//                     toSell[i] -= curSell;
//                     toBuy[j] -= changeDecimals(curSell, ERC20(sellToken).decimals(), ERC20(buyToken).decimals());
//                 }
//             }
//         }

//         _balances = new uint256[](strategiesCount);
//         for (uint256 i; i < strategiesCount; i++) {
//             _balances[i] = _strategiesAndSupportedTokensBalances[i];
//         }

//         return _balances;
//     }

//     /// @notice Set token as supported for user deposit and withdraw.
//     /// @dev Admin function.
//     function setSupportedToken(address tokenAddress, bool supported) external onlyStrategyRouter {
//         if (supported && supportsToken(tokenAddress)) revert AlreadySupportedToken();

//         if (supported) {
//             supportedTokens.add(tokenAddress);
//         } else {
//             uint8 len = uint8(router.getStrategiesCount());
//             // don't remove tokens that are in use by active strategies
//             for (uint256 i = 0; i < len; i++) {
//                 if (router.getStrategyDepositToken(i) == tokenAddress) {
//                     revert CantRemoveTokenOfActiveStrategy();
//                 }
//             }
//             supportedTokens.remove(tokenAddress);
//         }
//     }

//     // Internals

//     /// @dev Change decimal places of number from `oldDecimals` to `newDecimals`.
//     function changeDecimals(
//         uint256 amount,
//         uint8 oldDecimals,
//         uint8 newDecimals
//     ) private pure returns (uint256) {
//         if (oldDecimals < newDecimals) {
//             return amount * (10**(newDecimals - oldDecimals));
//         } else if (oldDecimals > newDecimals) {
//             return amount / (10**(oldDecimals - newDecimals));
//         }
//         return amount;
//     }

//     /// @dev Swap tokens if they are different (i.e. not the same token)
//     function _trySwap(
//         uint256 amount, // tokenFromAmount
//         address from, // tokenFrom
//         address to // tokenTo
//     ) private returns (uint256 result) {
//         if (from != to) {
//             IERC20(from).transfer(address(exchange), amount);
//             result = exchange.swap(amount, from, to, address(this));
//             return result;
//         }
//         return amount;
//     }

//     /// @dev Change decimal places from token decimals to `UNIFORM_DECIMALS`.
//     function toUniform(uint256 amount, address token) private view returns (uint256) {
//         return changeDecimals(amount, ERC20(token).decimals(), UNIFORM_DECIMALS);
//     }

//     /// @dev Convert decimal places from `UNIFORM_DECIMALS` to token decimals.
//     function fromUniform(uint256 amount, address token) private view returns (uint256) {
//         return changeDecimals(amount, UNIFORM_DECIMALS, ERC20(token).decimals());
//     }
// }

// interface IStrategy {
//      /* EVENTS */

//     /// @notice Fires when user deposits in batch.
//     /// @param token Supported token that user want to deposit.
//     /// @param amount Amount of `token` transferred from user.
//     event Deposit(address indexed user, address token, uint256 amount);
//     /// @notice Fires when batch is deposited into strategies.
//     /// @param closedCycleId Index of the cycle that is closed.
//     /// @param amount Sum of different tokens deposited into strategies.
//     event AllocateToStrategies(uint256 indexed closedCycleId, uint256 amount);
//     /// @notice Fires when user withdraw from batch.
//     /// @param token Supported token that user requested to receive after withdraw.
//     /// @param amount Amount of `token` received by user.
//     event WithdrawFromBatch(address indexed user, address token, uint256 amount);
//     /// @notice Fires when user withdraw from strategies.
//     /// @param token Supported token that user requested to receive after withdraw.
//     /// @param amount Amount of `token` received by user.
//     event WithdrawFromStrategies(address indexed user, address token, uint256 amount);
//     /// @notice Fires when user converts his receipt into shares token.
//     /// @param shares Amount of shares received by user.
//     /// @param receiptIds Indexes of the receipts burned.
//     event RedeemReceiptsToShares(address indexed user, uint256 shares, uint256[] receiptIds);
//     /// @notice Fires when moderator converts foreign receipts into shares token.
//     /// @param receiptIds Indexes of the receipts burned.
//     event RedeemReceiptsToSharesByModerators(address indexed moderator, uint256[] receiptIds);

//     // Events for setters.
//     event SetMinDeposit(uint256 newAmount);
//     event SetCycleDuration(uint256 newDuration);
//     event SetMinUsdPerCycle(uint256 newAmount);
//     event SetFeeAddress(address newAddress);
//     event SetFeePercent(uint256 newPercent);
//     event SetAddresses(
//         Exchange _exchange,
//         IUsdOracle _oracle,
//         SharesToken _sharesToken,
//         Batch _batch,
//         ReceiptNFTOnefile _receiptNft
//     );

//     /* ERRORS */
//     error AmountExceedTotalSupply();
//     error UnsupportedToken();
//     error NotReceiptOwner();
//     error CycleNotClosed();
//     error CycleClosed();
//     error InsufficientShares();
//     error DuplicateStrategy();
//     error CycleNotClosableYet();
//     error AmountNotSpecified();
//     error CantRemoveLastStrategy();
//     error NothingToRebalance();
//     error NotModerator();
//     error NodepositDetected();


//     /// @notice Token used to deposit to strategy.
//     function depositToken() external view returns (address);

//     /// @notice Deposit token to strategy.
//     function deposit(uint256 amount) external;

//     /// @notice Withdraw tokens from strategy.
//     /// @dev Max withdrawable amount is returned by totalTokens.
//     function withdraw(uint256 amount) external returns (uint256 amountWithdrawn);

//     /// @notice Harvest rewards and reinvest them.
//     function compound() external;

//     /// @notice Approximated amount of token on the strategy.
//     function totalTokens() external view returns (uint256);

//     /// @notice Withdraw all tokens from strategy.
//     function withdrawAll() external returns (uint256 amountWithdrawn);
// }

// interface InterfaceClipswap {
//   function BONUS_MULTIPLIER (  ) external view returns ( uint256 );
//   function CLIP (  ) external view returns ( address );
//   function CLIPPerBlock (  ) external view returns ( uint256 );
//   function add ( uint256 _allocPoint, address _lpToken, bool _withUpdate ) external;
//   function deposit ( uint256 _pid, uint256 _amount ) external;
//   function depositedClip (  ) external view returns ( uint256 );
//   function devPercent (  ) external view returns ( uint256 );
//   function devaddr (  ) external view returns ( address );
//   function emergencyWithdraw ( uint256 _pid ) external;
//   function enterStaking ( uint256 _amount ) external;
//   function getMultiplier ( uint256 _from, uint256 _to ) external view returns ( uint256 );
//   function lastBlockDevWithdraw (  ) external view returns ( uint256 );
//   function leaveStaking ( uint256 _amount ) external;
//   function massUpdatePools (  ) external;
//   function migrate ( uint256 _pid ) external;
//   function migrator (  ) external view returns ( address );
//   function owner (  ) external view returns ( address );
//   function pendingCLIP ( uint256 _pid, address _user ) external view returns ( uint256 );
//   function percentDec (  ) external view returns ( uint256 );
//   function poolInfo ( uint256 ) external view returns ( address lpToken, uint256 allocPoint, uint256 lastRewardBlock, uint256 accCLIPPerShare );
//   function poolLength (  ) external view returns ( uint256 );
//   function refAddr (  ) external view returns ( address );
//   function refPercent (  ) external view returns ( uint256 );
//   function renounceOwnership (  ) external;
//   function safuPercent (  ) external view returns ( uint256 );
//   function safuaddr (  ) external view returns ( address );
//   function set ( uint256 _pid, uint256 _allocPoint, bool _withUpdate ) external;
//   function setDevAddress ( address _devaddr ) external;
//   function setMigrator ( address _migrator ) external;
//   function setRefAddress ( address _refaddr ) external;
//   function setSafuAddress ( address _safuaddr ) external;
//   function stakingPercent (  ) external view returns ( uint256 );
//   function startBlock (  ) external view returns ( uint256 );
//   function totalAllocPoint (  ) external view returns ( uint256 );
//   function transferOwnership ( address newOwner ) external;
//   function updateClipPerBlock ( uint256 newAmount ) external;
//   function updateMultiplier ( uint256 multiplierNumber ) external;
//   function updatePool ( uint256 _pid ) external;
//   function userInfo ( uint256, address ) external view returns ( uint256 amount, uint256 rewardDebt );
//   function withdraw ( uint256 _pid, uint256 _amount ) external;
//   function withdrawDevAndRefFee (  ) external;
//   function myStakedBalance() external view returns(uint256);
// }


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

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

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
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}


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


/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}


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
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
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
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
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
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

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
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
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
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
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
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
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
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
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

        _afterTokenTransfer(address(0), to, tokenId);
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

        _afterTokenTransfer(owner, address(0), tokenId);
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
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
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

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}



contract ReceiptNFTOnefile is ERC721, Ownable {

    error NonExistingToken();
    error ReceiptAmountCanOnlyDecrease();
    error NotManager();
    /// Invalid query range (`start` >= `stop`).
    error InvalidQueryRange();

    struct ReceiptData {
        uint256 cycleId;
        uint256 tokenAmountUniform; // in token
        address token;
    }

    uint256 private _receiptsCounter;

    mapping(uint256 => ReceiptData) public receipts;
    mapping(address => bool) public managers;

    modifier onlyManager() {
        if (managers[msg.sender] == false) revert NotManager();
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address strategyRouter, address batch) ERC721("Receipt NFT", "RECEIPT") {
        // lock implementation
        // _disableInitializers();
        managers[strategyRouter] = true;
        managers[batch] = true;
    }

    // function initialize(address strategyRouter, address batch) external initializer {
    //     // __Ownable_init();
    //     // __UUPSUpgradeable_init();
    //     // __ERC721_init("Receipt NFT", "RECEIPT");

    //     managers[strategyRouter] = true;
    //     managers[batch] = true;
    // }

    // function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function setAmount(uint256 receiptId, uint256 amount) external onlyManager {
        if (!_exists(receiptId)) revert NonExistingToken();
        if (receipts[receiptId].tokenAmountUniform < amount) revert ReceiptAmountCanOnlyDecrease();
        receipts[receiptId].tokenAmountUniform = amount;
    }

    function mint(
        uint256 cycleId,
        uint256 amount,
        address token,
        address wallet
    ) external onlyManager {
        uint256 _receiptId = _receiptsCounter;
        receipts[_receiptId] = ReceiptData({cycleId: cycleId, token: token, tokenAmountUniform: amount});
        _mint(wallet, _receiptId);
        _receiptsCounter++;
    }

    function burn(uint256 receiptId) external onlyManager {
        if(!_exists(receiptId)) revert NonExistingToken();
        _burn(receiptId);
        delete receipts[receiptId];
    }

    /// @notice Get receipt data recorded in NFT.
    function getReceipt(uint256 receiptId) external view returns (ReceiptData memory) {
        if (_exists(receiptId) == false) revert NonExistingToken();
        return receipts[receiptId];
    }

    /**
     * @dev Returns an array of token IDs owned by `owner`,
     * in the range [`start`, `stop`].
     *
     * This function allows for tokens to be queried if the collection
     * grows too big for a single call of {ReceiptNFTOnefile-getTokensOfOwner}.
     *
     * Requirements:
     *
     * - `start <= receiptId < stop`
     */
    function getTokensOfOwnerIn(
        address owner,
        uint256 start,
        uint256 stop
    ) public view returns (uint256[] memory receiptIds) {
        unchecked {
            if (start >= stop) revert InvalidQueryRange();
            uint256 receiptIdsIdx;
            uint256 stopLimit = _receiptsCounter;
            // Set `stop = min(stop, stopLimit)`.
            if (stop > stopLimit) {
                // At this point `start` could be greater than `stop`.
                stop = stopLimit;
            }
            uint256 receiptIdsMaxLength = balanceOf(owner);
            // Set `receiptIdsMaxLength = min(balanceOf(owner), stop - start)`,
            // to cater for cases where `balanceOf(owner)` is too big.
            if (start < stop) {
                uint256 rangeLength = stop - start;
                if (rangeLength < receiptIdsMaxLength) {
                    receiptIdsMaxLength = rangeLength;
                }
            } else {
                receiptIdsMaxLength = 0;
            }
            receiptIds = new uint256[](receiptIdsMaxLength);
            if (receiptIdsMaxLength == 0) {
                return receiptIds;
            }

            // We want to scan tokens in range [start <= receiptId < stop].
            // And if whole range is owned by user or when receiptIdsMaxLength is less than range,
            // then we also want to exit loop when array is full.
            uint256 receiptId = start;
            while (receiptId != stop && receiptIdsIdx != receiptIdsMaxLength) {
                if (_exists(receiptId) && ownerOf(receiptId) == owner) {
                    receiptIds[receiptIdsIdx++] = receiptId;
                }
                receiptId++;
            }

            // If after scan we haven't filled array, then downsize the array to fit.
            assembly {
                mstore(receiptIds, receiptIdsIdx)
            }
            return receiptIds;
        }
    }

    /**
     * @dev Returns an array of token IDs owned by `owner`.
     *
     * This function scans the ownership mapping and is O(totalSupply) in complexity.
     * It is meant to be called off-chain.
     *
     * See {ReceiptNFTOnefile-getTokensOfOwnerIn} for splitting the scan into
     * multiple smaller scans if the collection is large enough to cause
     * an out-of-gas error.
     */
    function getTokensOfOwner(address owner) public view returns (uint256[] memory receiptIds) {
        uint256 balance = balanceOf(owner);
        receiptIds = new uint256[](balance);
        uint256 receiptId;

        while (balance > 0) {
            if (_exists(receiptId) && ownerOf(receiptId) == owner) {
                receiptIds[--balance] = receiptId;
            }
            receiptId++;
        }
    }
}