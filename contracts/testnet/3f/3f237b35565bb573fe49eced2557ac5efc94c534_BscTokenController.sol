/**
 *Submitted for verification at BscScan.com on 2023-03-02
*/

// Dependency file: @openzeppelin/contracts/math/SafeMath.sol

// SPDX-License-Identifier: MIT

// pragma solidity >=0.6.0 <0.8.0;

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
}


// Dependency file: contracts/bsc/interface/IBEP20.sol

// pragma solidity >0.4.0 <=0.9.0;

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


// Dependency file: contracts/bsc/common/ProxyStorage.sol

// pragma solidity 0.6.10;

// solhint-disable max-states-count, var-name-mixedcase

/**
 * Defines the storage layout of the token implementation contract. Any
 * newly declared state variables in future upgrades should be appended
 * to the bottom. Never remove state variables from this list, however variables
 * can be renamed. Please add _Deprecated to deprecated variables.
 */
contract ProxyStorage {
    address public owner;
    address public pendingOwner;

    bool initialized;

    uint256 _totalSupply;

    uint256 public burnMin = 0;
    uint256 public burnMax = 0;

    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;

    mapping(address => bool) isBlacklisted;
    mapping(address => bool) public canBurn;

    // Proof of Reserve feed related variables
    uint256 public chainReserveHeartbeat;
    address public chainReserveFeed;
    bool public proofOfReserveEnabled;

    /* Additionally, we have several keccak-based storage locations.
     * If you add more keccak-based storage mappings, such as mappings, you must document them here.
     * If the length of the keccak input is the same as an existing mapping, it is possible there could be a preimage collision.
     * A preimage collision can be used to attack the contract by treating one storage location as another,
     * which would always be a critical issue.
     * Carefully examine future keccak-based storage to ensure there can be no preimage collisions.
     *******************************************************************************************************
     ** length     input                                                         usage
     *******************************************************************************************************
     ** 19         "trueXXX.proxy.owner"                                         Proxy Owner
     ** 27         "trueXXX.pending.proxy.owner"                                 Pending Proxy Owner
     ** 28         "trueXXX.proxy.implementation"                                Proxy Implementation
     ** 64         uint256(address),uint256(14)                                  balanceOf
     ** 64         uint256(address),keccak256(uint256(address),uint256(15))      allowance
     ** 64         uint256(address),keccak256(bytes32,uint256(16))               attributes
     **/
}


// Dependency file: contracts/bsc/common/ClaimableOwnable.sol

// pragma solidity 0.6.10;

// import {ProxyStorage} from "contracts/bsc/common/ProxyStorage.sol";

/**
 * @title ClamableOwnable
 * @dev The ClamableOwnable contract is a copy of Claimable Contract by Zeppelin.
 * and provides basic authorization control functions. Inherits storage layout of
 * ProxyStorage.
 */
contract ClaimableOwnable is ProxyStorage {
    /**
     * @dev emitted when ownership is transferred
     * @param previousOwner previous owner of this contract
     * @param newOwner new owner of this contract
     */
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev sets the original `owner` of the contract to the sender
     * at construction. Must then be reinitialized
     */
    constructor() public {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), owner);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "only Owner");
        _;
    }

    /**
     * @dev Modifier throws if called by any account other than the pendingOwner.
     */
    modifier onlyPendingOwner() {
        require(msg.sender == pendingOwner, "only pending owner");
        _;
    }

    /**
     * @dev Allows the current owner to set the pendingOwner address.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) external onlyOwner {
        pendingOwner = newOwner;
    }

    /**
     * @dev Allows the pendingOwner address to finalize the transfer.
     */
    function claimOwnership() external onlyPendingOwner {
        emit OwnershipTransferred(owner, pendingOwner);
        owner = pendingOwner;
        pendingOwner = address(0);
    }
}


// Dependency file: @openzeppelin/contracts/utils/Context.sol


// pragma solidity >=0.6.0 <0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


// Dependency file: @openzeppelin/contracts/GSN/Context.sol


// pragma solidity >=0.6.0 <0.8.0;

// import "@openzeppelin/contracts/utils/Context.sol";


// Dependency file: contracts/bsc/common/BEP20.sol

// pragma solidity 0.6.10;

// import {ClaimableOwnable} from "contracts/bsc/common/ClaimableOwnable.sol";
// import {IBEP20} from "contracts/bsc/interface/IBEP20.sol";
// import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
// import {Context} from "@openzeppelin/contracts/GSN/Context.sol";

/**
 * @dev Implementation of the {IBEP20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the TIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IBEP20-approve}.
 */
abstract contract BEP20 is ClaimableOwnable, Context, IBEP20 {
    using SafeMath for uint256;

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory);

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory);

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18. This is the value {BEP20} uses,
     * unless {_setupDecimals} is called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IBEP20-balanceOf} and {IBEP20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IBEP20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() public view virtual override returns (address) {
        return owner;
    }

    /**
     * @dev See {IBEP20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IBEP20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IBEP20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IBEP20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IBEP20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the TIP. See the note at the beginning of {BEP20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IBEP20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IBEP20-approve}.
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
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero")
        );
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
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "BEP20: transfer amount exceeds balance");
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
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "BEP20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

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
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "BEP20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "BEP20: burn amount exceeds balance");
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
    ) internal virtual {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    // solhint-disable-next-line no-empty-blocks
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}


// Dependency file: contracts/bsc/common/ReclaimerToken.sol

// pragma solidity 0.6.10;

// import {IBEP20} from "contracts/bsc/interface/IBEP20.sol";
// import {BEP20} from "contracts/bsc/common/BEP20.sol";

/**
 * @title ReclaimerToken
 * @dev BEP20 token which allows owner to reclaim BEP20 tokens
 * or bnb sent to this contract
 */
abstract contract ReclaimerToken is BEP20 {
    /**
     * @dev send all bnb balance in the contract to another address
     * @param _to address to send bnb balance to
     */
    function reclaimBNB(address payable _to) external onlyOwner {
        _to.transfer(address(this).balance);
    }

    /**
     * @dev send all token balance of an arbitrary BEP20 token
     * in the contract to another address
     * @param token token to reclaim
     * @param _to address to send BEP20 balance to
     */
    function reclaimToken(IBEP20 token, address _to) external onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        token.transfer(_to, balance);
    }
}


// Dependency file: contracts/bsc/common/BurnableTokenWithBounds.sol

// pragma solidity 0.6.10;

// import {ReclaimerToken} from "contracts/bsc/common/ReclaimerToken.sol";

/**
 * @title BurnableTokenWithBounds
 * @dev Burning functions as redeeming money from the system.
 * The platform will keep track of who burns coins,
 * and will send them back the equivalent amount of money (rounded down to the nearest cent).
 */
abstract contract BurnableTokenWithBounds is ReclaimerToken {
    /**
     * @dev Emitted when `value` tokens are burnt from one account (`burner`)
     * @param burner address which burned tokens
     * @param value amount of tokens burned
     */
    event Burn(address indexed burner, uint256 value);

    /**
     * @dev Emitted when new burn bounds were set
     * @param newMin new minimum burn amount
     * @param newMax new maximum burn amount
     * @notice `newMin` should never be greater than `newMax`
     */
    event SetBurnBounds(uint256 newMin, uint256 newMax);

    /**
     * @dev Destroys `amount` tokens from `msg.sender`, reducing the
     * total supply.
     * @param amount amount of tokens to burn
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     * Emits a {Burn} event with `burner` set to `msg.sender`
     *
     * Requirements
     *
     * - `msg.sender` must have at least `amount` tokens.
     *
     */
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    /**
     * @dev Change the minimum and maximum amount that can be burned at once.
     * Burning may be disabled by setting both to 0 (this will not be done
     * under normal operation, but we can't add checks to disallow it without
     * losing a lot of flexibility since burning could also be as good as disabled
     * by setting the minimum extremely high, and we don't want to lock
     * in any particular cap for the minimum)
     * @param _min minimum amount that can be burned at once
     * @param _max maximum amount that can be burned at once
     */
    function setBurnBounds(uint256 _min, uint256 _max) external onlyOwner {
        require(_min <= _max, "BurnableTokenWithBounds: min > max");
        burnMin = _min;
        burnMax = _max;
        emit SetBurnBounds(_min, _max);
    }

    /**
     * @dev Checks if amount is within allowed burn bounds and
     * destroys `amount` tokens from `account`, reducing the
     * total supply.
     * @param account account to burn tokens for
     * @param amount amount of tokens to burn
     *
     * Emits a {Burn} event
     */
    function _burn(address account, uint256 amount) internal virtual override {
        require(amount >= burnMin, "BurnableTokenWithBounds: below min burn bound");
        require(amount <= burnMax, "BurnableTokenWithBounds: exceeds max burn bound");

        super._burn(account, amount);
        emit Burn(account, amount);
    }
}


// Dependency file: contracts/bsc/common/TrueCurrency.sol

// pragma solidity 0.6.10;

// import {BurnableTokenWithBounds} from "contracts/bsc/common/BurnableTokenWithBounds.sol";

/**
 * @title TrueCurrency
 * @dev TrueCurrency is an BEP20 with blacklist & redemption addresses
 *
 * TrueCurrency is a compliant stablecoin with blacklist and redemption
 * addresses. Only the owner can blacklist accounts. Redemption addresses
 * are assigned automatically to the first 0x100000 addresses. Sending
 * tokens to the redemption address will trigger a burn operation. Only
 * the owner can mint or blacklist accounts.
 *
 * This contract is owned by the TokenController, which manages token
 * minting & admin functionality. See TokenController.sol
 *
 * See also: BurnableTokenWithBounds.sol
 *
 * ~~~~ Features ~~~~
 *
 * Redemption Addresses
 * - The first 0x100000 addresses except from address(0) are redemption addresses
 * - Tokens sent to redemption addresses are burned
 * - Redemptions are tracked off-chain
 * - Cannot mint tokens to redemption addresses
 *
 * Blacklist
 * - Owner can blacklist accounts in accordance with local regulatory bodies
 * - Only a court order will merit a blacklist; blacklisting is extremely rare
 *
 * Burn Bounds & CanBurn
 * - Owner can set min & max burn amounts
 * - Only accounts flagged in canBurn are allowed to burn tokens
 * - canBurn prevents tokens from being sent to the incorrect address
 *
 * Reclaimer Token
 * - BEP20 Tokens and BNB sent to this contract can be reclaimed by the owner
 */
abstract contract TrueCurrency is BurnableTokenWithBounds {
    uint256 constant CENT = 10**16;
    uint256 constant REDEMPTION_ADDRESS_COUNT = 0x100000;

    /**
     * @dev Emitted when account blacklist status changes
     */
    event Blacklisted(address indexed account, bool isBlacklisted);

    /**
     * @dev Emitted when `value` tokens are minted for `to`
     * @param to address to mint tokens for
     * @param value amount of tokens to be minted
     */
    event Mint(address indexed to, uint256 value);

    /**
     * @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     * @param account address to mint tokens for
     * @param amount amount of tokens to be minted
     *
     * Emits a {Mint} event
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` cannot be blacklisted.
     * - `account` cannot be a redemption address.
     */
    function mint(address account, uint256 amount) external onlyOwner {
        require(!isBlacklisted[account], "TrueCurrency: account is blacklisted");
        require(!isRedemptionAddress(account), "TrueCurrency: account is a redemption address");
        _mint(account, amount);
        emit Mint(account, amount);
    }

    /**
     * @dev Set blacklisted status for the account.
     * @param account address to set blacklist flag for
     * @param _isBlacklisted blacklist flag value
     *
     * Requirements:
     *
     * - `msg.sender` should be owner.
     */
    function setBlacklisted(address account, bool _isBlacklisted) external onlyOwner {
        require(uint256(account) >= REDEMPTION_ADDRESS_COUNT, "TrueCurrency: blacklisting of redemption address is not allowed");
        isBlacklisted[account] = _isBlacklisted;
        emit Blacklisted(account, _isBlacklisted);
    }

    /**
     * @dev Set canBurn status for the account.
     * @param account address to set canBurn flag for
     * @param _canBurn canBurn flag value
     *
     * Requirements:
     *
     * - `msg.sender` should be owner.
     */
    function setCanBurn(address account, bool _canBurn) external onlyOwner {
        canBurn[account] = _canBurn;
    }

    /**
     * @dev Check if neither account is blacklisted before performing transfer
     * If transfer recipient is a redemption address, burns tokens
     * @notice Transfer to redemption address will burn tokens with a 1 cent precision
     * @param sender address of sender
     * @param recipient address of recipient
     * @param amount amount of tokens to transfer
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        require(!isBlacklisted[sender], "TrueCurrency: sender is blacklisted");
        require(!isBlacklisted[recipient], "TrueCurrency: recipient is blacklisted");

        if (isRedemptionAddress(recipient)) {
            super._transfer(sender, recipient, amount.sub(amount.mod(CENT)));
            _burn(recipient, amount.sub(amount.mod(CENT)));
        } else {
            super._transfer(sender, recipient, amount);
        }
    }

    /**
     * @dev Requere neither accounts to be blacklisted before approval
     * @param owner address of owner giving approval
     * @param spender address of spender to approve for
     * @param amount amount of tokens to approve
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal override {
        require(!isBlacklisted[owner], "TrueCurrency: tokens owner is blacklisted");
        require(!isBlacklisted[spender] || amount == 0, "TrueCurrency: tokens spender is blacklisted");

        super._approve(owner, spender, amount);
    }

    /**
     * @dev Check if tokens can be burned at address before burning
     * @param account account to burn tokens from
     * @param amount amount of tokens to burn
     */
    function _burn(address account, uint256 amount) internal override {
        require(canBurn[account], "TrueCurrency: cannot burn from this address");
        super._burn(account, amount);
    }

    /**
     * @dev First 0x100000-1 addresses (0x0000000000000000000000000000000000000001 to 0x00000000000000000000000000000000000fffff)
     * are the redemption addresses.
     * @param account address to check is a redemption address
     *
     * All transfers to redemption address will trigger token burn.
     *
     * @notice For transfer to succeed, canBurn must be true for redemption address
     *
     * @return is `account` a redemption address
     */
    function isRedemptionAddress(address account) internal pure returns (bool) {
        return uint256(account) < REDEMPTION_ADDRESS_COUNT && account != address(0);
    }
}


// Dependency file: contracts/bsc/OwnedUpgradeabilityProxy.sol

// solhint-disable const-name-snakecase
// pragma solidity 0.6.10;

/**
 * @title OwnedUpgradeabilityProxy
 * @dev This contract combines an upgradeability proxy with basic authorization control functionalities
 */
contract OwnedUpgradeabilityProxy {
    /**
     * @dev Event to show ownership has been transferred
     * @param previousOwner representing the address of the previous owner
     * @param newOwner representing the address of the new owner
     */
    event ProxyOwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Event to show ownership transfer is pending
     * @param currentOwner representing the address of the current owner
     * @param pendingOwner representing the address of the pending owner
     */
    event NewPendingOwner(address currentOwner, address pendingOwner);

    // Storage position of the owner and pendingOwner of the contract
    bytes32 private constant proxyOwnerPosition = 0x6279e8199720cf3557ecd8b58d667c8edc486bd1cf3ad59ea9ebdfcae0d0dfac; //keccak256("trueUSD.proxy.owner");
    bytes32 private constant pendingProxyOwnerPosition = 0x8ddbac328deee8d986ec3a7b933a196f96986cb4ee030d86cc56431c728b83f4; //keccak256("trueUSD.pending.proxy.owner");

    /**
     * @dev the constructor sets the original owner of the contract to the sender account.
     */
    constructor() public {
        _setUpgradeabilityOwner(msg.sender);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyProxyOwner() {
        require(msg.sender == proxyOwner(), "only Proxy Owner");
        _;
    }

    /**
     * @dev Throws if called by any account other than the pending owner.
     */
    modifier onlyPendingProxyOwner() {
        require(msg.sender == pendingProxyOwner(), "only pending Proxy Owner");
        _;
    }

    /**
     * @dev Tells the address of the owner
     * @return owner the address of the owner
     */
    function proxyOwner() public view returns (address owner) {
        bytes32 position = proxyOwnerPosition;
        assembly {
            owner := sload(position)
        }
    }

    /**
     * @dev Tells the address of the owner
     * @return pendingOwner the address of the pending owner
     */
    function pendingProxyOwner() public view returns (address pendingOwner) {
        bytes32 position = pendingProxyOwnerPosition;
        assembly {
            pendingOwner := sload(position)
        }
    }

    /**
     * @dev Sets the address of the owner
     */
    function _setUpgradeabilityOwner(address newProxyOwner) internal {
        bytes32 position = proxyOwnerPosition;
        assembly {
            sstore(position, newProxyOwner)
        }
    }

    /**
     * @dev Sets the address of the owner
     */
    function _setPendingUpgradeabilityOwner(address newPendingProxyOwner) internal {
        bytes32 position = pendingProxyOwnerPosition;
        assembly {
            sstore(position, newPendingProxyOwner)
        }
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     *changes the pending owner to newOwner. But doesn't actually transfer
     * @param newOwner The address to transfer ownership to.
     */
    function transferProxyOwnership(address newOwner) external onlyProxyOwner {
        require(newOwner != address(0));
        _setPendingUpgradeabilityOwner(newOwner);
        emit NewPendingOwner(proxyOwner(), newOwner);
    }

    /**
     * @dev Allows the pendingOwner to claim ownership of the proxy
     */
    function claimProxyOwnership() external onlyPendingProxyOwner {
        emit ProxyOwnershipTransferred(proxyOwner(), pendingProxyOwner());
        _setUpgradeabilityOwner(pendingProxyOwner());
        _setPendingUpgradeabilityOwner(address(0));
    }

    /**
     * @dev Allows the proxy owner to upgrade the current version of the proxy.
     * @param implementation representing the address of the new implementation to be set.
     */
    function upgradeTo(address implementation) public virtual onlyProxyOwner {
        address currentImplementation;
        bytes32 position = implementationPosition;
        assembly {
            currentImplementation := sload(position)
        }
        require(currentImplementation != implementation);
        assembly {
            sstore(position, implementation)
        }
        emit Upgraded(implementation);
    }

    /**
     * @dev This event will be emitted every time the implementation gets upgraded
     * @param implementation representing the address of the upgraded implementation
     */
    event Upgraded(address indexed implementation);

    // Storage position of the address of the current implementation
    bytes32 private constant implementationPosition = 0x6e41e0fbe643dfdb6043698bf865aada82dc46b953f754a3468eaa272a362dc7; //keccak256("trueUSD.proxy.implementation");

    function implementation() public view returns (address impl) {
        bytes32 position = implementationPosition;
        assembly {
            impl := sload(position)
        }
    }

    /**
     * @dev Fallback functions allowing to perform a delegatecall to the given implementation.
     * This function will return whatever the implementation call returns
     */
    fallback() external payable {
        proxyCall();
    }

    receive() external payable {
        proxyCall();
    }

    function proxyCall() internal {
        bytes32 position = implementationPosition;

        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, returndatasize(), calldatasize())
            let result := delegatecall(gas(), sload(position), ptr, calldatasize(), returndatasize(), returndatasize())
            returndatacopy(ptr, 0, returndatasize())

            switch result
                case 0 {
                    revert(ptr, returndatasize())
                }
                default {
                    return(ptr, returndatasize())
                }
        }
    }
}

// Dependency file: contracts/bsc/Registry.sol

// pragma solidity 0.6.10;

// import {IBEP20} from "contracts/bsc/interface/IBEP20.sol";

interface RegistryClone {
    function syncAttributeValue(
        address _who,
        bytes32 _attribute,
        uint256 _value
    ) external;
}

contract Registry {
    struct AttributeData {
        uint256 value;
        bytes32 notes;
        address adminAddr;
        uint256 timestamp;
    }

    // never remove any storage variables
    address public owner;
    address public pendingOwner;
    bool initialized;

    // Stores arbitrary attributes for users. An example use case is an IBEP20
    // token that requires its users to go through a KYC/AML check - in this case
    // a validator can set an account's "hasPassedKYC/AML" attribute to 1 to indicate
    // that account can use the token. This mapping stores that value (1, in the
    // example) as well as which validator last set the value and at what time,
    // so that e.g. the check can be renewed at appropriate intervals.
    mapping(address => mapping(bytes32 => AttributeData)) attributes;
    // The logic governing who is allowed to set what attributes is abstracted as
    // this accessManager, so that it may be replaced by the owner as needed
    bytes32 constant WRITE_PERMISSION = keccak256("canWriteTo-");
    mapping(bytes32 => RegistryClone[]) subscribers;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event SetAttribute(address indexed who, bytes32 attribute, uint256 value, bytes32 notes, address indexed adminAddr);
    event SetManager(address indexed oldManager, address indexed newManager);
    event StartSubscription(bytes32 indexed attribute, RegistryClone indexed subscriber);
    event StopSubscription(bytes32 indexed attribute, RegistryClone indexed subscriber);

    /**
     * @dev sets the original `owner` of the contract to the sender
     * at construction. Must then be reinitialized
     */
    constructor() public {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), owner);
    }

    function initialize() public {
        require(!initialized, "already initialized");
        owner = msg.sender;
        emit OwnershipTransferred(address(0), owner);
        initialized = true;
    }

    // Allows a write if either a) the writer is that Registry's owner, or
    // b) the writer is writing to attribute foo and that writer already has
    // the canWriteTo-foo attribute set (in that same Registry)
    function confirmWrite(bytes32 _attribute, address _admin) internal view returns (bool) {
        return (_admin == owner || hasAttribute(_admin, keccak256(abi.encodePacked(WRITE_PERMISSION ^ _attribute))));
    }

    // Writes are allowed only if the accessManager approves
    function setAttribute(
        address _who,
        bytes32 _attribute,
        uint256 _value,
        bytes32 _notes
    ) public {
        require(confirmWrite(_attribute, msg.sender));
        attributes[_who][_attribute] = AttributeData(_value, _notes, msg.sender, block.timestamp);
        emit SetAttribute(_who, _attribute, _value, _notes, msg.sender);

        RegistryClone[] storage targets = subscribers[_attribute];
        uint256 index = targets.length;
        while (index-- > 0) {
            targets[index].syncAttributeValue(_who, _attribute, _value);
        }
    }

    function subscribe(bytes32 _attribute, RegistryClone _syncer) external onlyOwner {
        subscribers[_attribute].push(_syncer);
        emit StartSubscription(_attribute, _syncer);
    }

    function unsubscribe(bytes32 _attribute, uint256 _index) external onlyOwner {
        uint256 length = subscribers[_attribute].length;
        require(_index < length);
        emit StopSubscription(_attribute, subscribers[_attribute][_index]);
        subscribers[_attribute][_index] = subscribers[_attribute][length - 1];
        subscribers[_attribute].pop();
    }

    function subscriberCount(bytes32 _attribute) public view returns (uint256) {
        return subscribers[_attribute].length;
    }

    function setAttributeValue(
        address _who,
        bytes32 _attribute,
        uint256 _value
    ) public {
        require(confirmWrite(_attribute, msg.sender));
        attributes[_who][_attribute] = AttributeData(_value, "", msg.sender, block.timestamp);
        emit SetAttribute(_who, _attribute, _value, "", msg.sender);
        RegistryClone[] storage targets = subscribers[_attribute];
        uint256 index = targets.length;
        while (index-- > 0) {
            targets[index].syncAttributeValue(_who, _attribute, _value);
        }
    }

    // Returns true if the uint256 value stored for this attribute is non-zero
    function hasAttribute(address _who, bytes32 _attribute) public view returns (bool) {
        return attributes[_who][_attribute].value != 0;
    }

    // Returns the exact value of the attribute, as well as its metadata
    function getAttribute(address _who, bytes32 _attribute)
        public
        view
        returns (
            uint256,
            bytes32,
            address,
            uint256
        )
    {
        AttributeData memory data = attributes[_who][_attribute];
        return (data.value, data.notes, data.adminAddr, data.timestamp);
    }

    function getAttributeValue(address _who, bytes32 _attribute) public view returns (uint256) {
        return attributes[_who][_attribute].value;
    }

    function getAttributeAdminAddr(address _who, bytes32 _attribute) public view returns (address) {
        return attributes[_who][_attribute].adminAddr;
    }

    function getAttributeTimestamp(address _who, bytes32 _attribute) public view returns (uint256) {
        return attributes[_who][_attribute].timestamp;
    }

    function syncAttribute(
        bytes32 _attribute,
        uint256 _startIndex,
        address[] calldata _addresses
    ) external {
        RegistryClone[] storage targets = subscribers[_attribute];
        uint256 index = targets.length;
        while (index-- > _startIndex) {
            RegistryClone target = targets[index];
            for (uint256 i = _addresses.length; i-- > 0; ) {
                address who = _addresses[i];
                target.syncAttributeValue(who, _attribute, attributes[who][_attribute].value);
            }
        }
    }

    function reclaimBNB(address payable _to) external onlyOwner {
        _to.transfer(address(this).balance);
    }

    function reclaimToken(IBEP20 token, address _to) external onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        token.transfer(_to, balance);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "only Owner");
        _;
    }

    /**
     * @dev Modifier throws if called by any account other than the pendingOwner.
     */
    modifier onlyPendingOwner() {
        require(msg.sender == pendingOwner);
        _;
    }

    /**
     * @dev Allows the current owner to set the pendingOwner address.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        pendingOwner = newOwner;
    }

    /**
     * @dev Allows the pendingOwner address to finalize the transfer.
     */
    function claimOwnership() public onlyPendingOwner {
        emit OwnershipTransferred(owner, pendingOwner);
        owner = pendingOwner;
        pendingOwner = address(0);
    }
}


// Dependency file: contracts/bsc/interface/IHasOwner.sol

// pragma solidity 0.6.10;

interface IHasOwner {
    function claimOwnership() external;

    function transferOwnership(address newOwner) external;
}


// Dependency file: contracts/bsc/interface/IProofOfReserveToken.sol

// pragma solidity 0.6.10;

interface IProofOfReserveToken {
    /*** Admin Functions ***/

    function setChainReserveFeed(address newFeed) external;

    function setChainReserveHeartbeat(uint256 newHeartbeat) external;

    function enableProofOfReserve() external;

    function disableProofOfReserve() external;

    /*** Events ***/

    /**
     * @notice Event emitted when the feed is updated
     */
    event NewChainReserveFeed(address oldFeed, address newFeed);

    /**
     * @notice Event emitted when the heartbeat of chain reserve feed is updated
     */
    event NewChainReserveHeartbeat(uint256 oldHeartbeat, uint256 newHeartbeat);

    /**
     * @notice Event emitted when Proof of Reserve is enabled
     */
    event ProofOfReserveEnabled();

    /**
     * @notice Event emitted when Proof of Reserve is disabled
     */
    event ProofOfReserveDisabled();
}


// Root file: contracts/bsc/BscTokenController.sol

pragma solidity 0.6.10;

// import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
// import {IBEP20} from "contracts/bsc/interface/IBEP20.sol";
// import {TrueCurrency} from "contracts/bsc/common/TrueCurrency.sol";
// import {OwnedUpgradeabilityProxy} from "contracts/bsc/OwnedUpgradeabilityProxy.sol";
// import {Registry} from "contracts/bsc/Registry.sol";
// import {IHasOwner} from "contracts/bsc/interface/IHasOwner.sol";
// import {IProofOfReserveToken} from "contracts/bsc/interface/IProofOfReserveToken.sol";

/** @title TokenController
 * @dev This contract allows us to split ownership of the TrueCurrency contract
 * into two addresses. One, called the "owner" address, has unfettered control of the TrueCurrency contract -
 * it can mint new tokens, transfer ownership of the contract, etc. However to make
 * extra sure that TrueCurrency is never compromised, this owner key will not be used in
 * day-to-day operations, allowing it to be stored at a heightened level of security.
 * Instead, the owner appoints an various "admin" address.
 * There are 3 different types of admin addresses;  MintKey, MintRatifier, and MintPauser.
 * MintKey can request and revoke mints one at a time.
 * MintPausers can pause individual mints or pause all mints.
 * MintRatifiers can approve and finalize mints with enough approval.

 * There are three levels of mints: instant mint, ratified mint, and multiSig mint. Each have a different threshold
 * and deduct from a different pool.
 * Instant mint has the lowest threshold and finalizes instantly without any ratifiers. Deduct from instant mint pool,
 * which can be refilled by one ratifier.
 * Ratify mint has the second lowest threshold and finalizes with one ratifier approval. Deduct from ratify mint pool,
 * which can be refilled by three ratifiers.
 * MultiSig mint has the highest threshold and finalizes with three ratifier approvals. Deduct from multiSig mint pool,
 * which can only be refilled by the owner.
*/

contract BscTokenController {
    using SafeMath for uint256;

    struct MintOperation {
        address to;
        uint256 value;
        uint256 requestedBlock;
        uint256 numberOfApproval;
        bool paused;
        mapping(address => bool) approved;
    }

    address payable public owner;
    address payable public pendingOwner;

    bool public initialized;

    uint256 public instantMintThreshold;
    uint256 public ratifiedMintThreshold;
    uint256 public multiSigMintThreshold;

    uint256 public instantMintLimit;
    uint256 public ratifiedMintLimit;
    uint256 public multiSigMintLimit;

    uint256 public instantMintPool;
    uint256 public ratifiedMintPool;
    uint256 public multiSigMintPool;
    address[2] public ratifiedPoolRefillApprovals;

    uint8 public constant RATIFY_MINT_SIGS = 1; //number of approvals needed to finalize a Ratified Mint
    uint8 public constant MULTISIG_MINT_SIGS = 3; //number of approvals needed to finalize a MultiSig Mint

    bool public mintPaused;
    uint256 public mintReqInvalidBeforeThisBlock; //all mint request before this block are invalid
    address public mintKey;
    MintOperation[] public mintOperations; //list of a mint requests

    TrueCurrency public token;
    Registry public registry;

    // Proof Of Reserve
    address public proofOfReserveEnabler;

    // Registry attributes for admin keys
    bytes32 public constant IS_MINT_PAUSER = "isTUSDMintPausers";
    bytes32 public constant IS_MINT_RATIFIER = "isTUSDMintRatifier";
    bytes32 public constant IS_REGISTRY_ADMIN = "isRegistryAdmin";

    // paused version of TrueCurrency in Production
    // pausing the contract upgrades the proxy to this implementation
    address public constant PAUSED_IMPLEMENTATION = 0xb41B645512D1334E1CF3ee67AD2cF91C07997df2;

    modifier onlyMintKeyOrOwner() {
        require(msg.sender == mintKey || msg.sender == owner, "must be mintKey or owner");
        _;
    }

    modifier onlyMintPauserOrOwner() {
        require(registry.hasAttribute(msg.sender, IS_MINT_PAUSER) || msg.sender == owner, "must be pauser or owner");
        _;
    }

    modifier onlyMintRatifierOrOwner() {
        require(registry.hasAttribute(msg.sender, IS_MINT_RATIFIER) || msg.sender == owner, "must be ratifier or owner");
        _;
    }

    modifier onlyRegistryAdminOrOwner() {
        require(registry.hasAttribute(msg.sender, IS_REGISTRY_ADMIN) || msg.sender == owner, "must be registry admin or owner");
        _;
    }

    //mint operations by the mintkey cannot be processed on when mints are paused
    modifier mintNotPaused() {
        if (msg.sender != owner) {
            require(!mintPaused, "minting is paused");
        }
        _;
    }

    /// @dev Emitted when ownership of controller was transferred
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    /// @dev Emitted when ownership of controller transfer procedure was started
    event NewOwnerPending(address indexed currentOwner, address indexed pendingOwner);
    /// @dev Emitted when new registry was set
    event SetRegistry(address indexed registry);
    /// @dev Emitted when owner was transferred for child contract
    event TransferChild(address indexed child, address indexed newOwner);
    /// @dev Emitted when child ownership was claimed
    event RequestReclaimContract(address indexed other);
    /// @dev Emitted when child token was changed
    event SetToken(TrueCurrency newContract);
    /// @dev Emitted when canBurn status of the `burner` was changed to `canBurn`
    event CanBurn(address burner, bool canBurn);

    /// @dev Emitted when mint was requested
    event RequestMint(address indexed to, uint256 indexed value, uint256 opIndex, address mintKey);
    /// @dev Emitted when mint was finalized
    event FinalizeMint(address indexed to, uint256 indexed value, uint256 opIndex, address mintKey);
    /// @dev Emitted on instant mint
    event InstantMint(address indexed to, uint256 indexed value, address indexed mintKey);

    /// @dev Emitted when mint key was replaced
    event TransferMintKey(address indexed previousMintKey, address indexed newMintKey);
    /// @dev Emitted when Proof Of Reserve enabler was set
    event ProofOfReserveEnablerSet(address previousEnabler, address newEnabler);
    /// @dev Emitted when mint was ratified
    event MintRatified(uint256 indexed opIndex, address indexed ratifier);
    /// @dev Emitted when mint is revoked
    event RevokeMint(uint256 opIndex);
    /// @dev Emitted when all mining is paused (status=true) or unpaused (status=false)
    event AllMintsPaused(bool status);
    /// @dev Emitted when opIndex mint is paused (status=true) or unpaused (status=false)
    event MintPaused(uint256 opIndex, bool status);
    /// @dev Emitted when mint is approved
    event MintApproved(address approver, uint256 opIndex);
    /// @dev Emitted when fast pause contract is changed
    event FastPauseSet(address _newFastPause);

    /// @dev Emitted when mint threshold changes
    event MintThresholdChanged(uint256 instant, uint256 ratified, uint256 multiSig);
    /// @dev Emitted when mint limits change
    event MintLimitsChanged(uint256 instant, uint256 ratified, uint256 multiSig);
    /// @dev Emitted when instant mint pool is refilled
    event InstantPoolRefilled();
    /// @dev Emitted when instant mint pool is ratified
    event RatifyPoolRefilled();
    /// @dev Emitted when multisig mint pool is ratified
    event MultiSigPoolRefilled();

    /*
    ========================================
    Ownership functions
    ========================================
    */

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "only Owner");
        _;
    }

    /**
     * @dev Modifier throws if called by any account other than the pendingOwner.
     */
    modifier onlyPendingOwner() {
        require(msg.sender == pendingOwner);
        _;
    }

    /**
     * @dev Modifier throws if called by any account other than proofOfReserveEnabler or owner.
     */
    modifier onlyProofOfReserveEnablerOrOwner() {
        require(msg.sender == proofOfReserveEnabler || msg.sender == owner, "only proofOfReserveEnabler or owner");
        _;
    }

    /**
     * @dev sets the original `owner` of the contract to the sender
     * at construction. Must then be reinitialized
     */
    constructor() public {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), owner);
    }

    function initialize() public {
        require(!initialized, "already initialized");
        owner = msg.sender;
        emit OwnershipTransferred(address(0), owner);

        instantMintThreshold = 150_000_000_000_000_000_000_000_000; // 150 M
        ratifiedMintThreshold = 300_000_000_000_000_000_000_000_000; // 300 M
        multiSigMintThreshold = 1_000_000_000_000_000_000_000_000_000; // 1 B
        emit MintThresholdChanged(
            150_000_000_000_000_000_000_000_000,
            300_000_000_000_000_000_000_000_000,
            1_000_000_000_000_000_000_000_000_000
        );
        instantMintLimit = 150_000_000_000_000_000_000_000_000; // 150 M
        ratifiedMintLimit = 300_000_000_000_000_000_000_000_000; // 300 M
        multiSigMintLimit = 1_000_000_000_000_000_000_000_000_000; // 1 B
        emit MintLimitsChanged(
            150_000_000_000_000_000_000_000_000,
            300_000_000_000_000_000_000_000_000,
            1_000_000_000_000_000_000_000_000_000
        );

        initialized = true;
    }

    /**
     * @dev Allows the current owner to set the pendingOwner address.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address payable newOwner) external onlyOwner {
        pendingOwner = newOwner;
        emit NewOwnerPending(address(owner), address(pendingOwner));
    }

    /**
     * @dev Allows the pendingOwner address to finalize the transfer.
     */
    function claimOwnership() external onlyPendingOwner {
        emit OwnershipTransferred(address(owner), address(pendingOwner));
        owner = pendingOwner;
        pendingOwner = address(0);
    }

    /*
    ========================================
    proxy functions
    ========================================
    */

    function transferTrueCurrencyProxyOwnership(address _newOwner) external onlyOwner {
        OwnedUpgradeabilityProxy(address(uint160(address(token)))).transferProxyOwnership(_newOwner);
    }

    function claimTrueCurrencyProxyOwnership() external onlyOwner {
        OwnedUpgradeabilityProxy(address(uint160(address(token)))).claimProxyOwnership();
    }

    function upgradeTrueCurrencyProxyImplTo(address _implementation) external onlyOwner {
        OwnedUpgradeabilityProxy(address(uint160(address(token)))).upgradeTo(_implementation);
    }

    /*
    ========================================
    Minting functions
    ========================================
    */

    /**
     * @dev set the threshold for a mint to be considered an instant mint,
     * ratify mint and multiSig mint. Instant mint requires no approval,
     * ratify mint requires 1 approval and multiSig mint requires 3 approvals
     */
    function setMintThresholds(
        uint256 _instant,
        uint256 _ratified,
        uint256 _multiSig
    ) external onlyOwner {
        require(_instant <= _ratified && _ratified <= _multiSig);
        instantMintThreshold = _instant;
        ratifiedMintThreshold = _ratified;
        multiSigMintThreshold = _multiSig;
        emit MintThresholdChanged(_instant, _ratified, _multiSig);
    }

    /**
     * @dev set the limit of each mint pool. For example can only instant mint up to the instant mint pool limit
     * before needing to refill
     */
    function setMintLimits(
        uint256 _instant,
        uint256 _ratified,
        uint256 _multiSig
    ) external onlyOwner {
        require(_instant <= _ratified && _ratified <= _multiSig);
        instantMintLimit = _instant;
        if (instantMintPool > instantMintLimit) {
            instantMintPool = instantMintLimit;
        }
        ratifiedMintLimit = _ratified;
        if (ratifiedMintPool > ratifiedMintLimit) {
            ratifiedMintPool = ratifiedMintLimit;
        }
        multiSigMintLimit = _multiSig;
        if (multiSigMintPool > multiSigMintLimit) {
            multiSigMintPool = multiSigMintLimit;
        }
        emit MintLimitsChanged(_instant, _ratified, _multiSig);
    }

    /**
     * @dev Ratifier can refill instant mint pool
     */
    function refillInstantMintPool() external onlyMintRatifierOrOwner {
        ratifiedMintPool = ratifiedMintPool.sub(instantMintLimit.sub(instantMintPool));
        instantMintPool = instantMintLimit;
        emit InstantPoolRefilled();
    }

    /**
     * @dev Owner or 3 ratifiers can refill Ratified Mint Pool
     */
    function refillRatifiedMintPool() external onlyMintRatifierOrOwner {
        if (msg.sender != owner) {
            address[2] memory refillApprovals = ratifiedPoolRefillApprovals;
            require(msg.sender != refillApprovals[0] && msg.sender != refillApprovals[1]);
            if (refillApprovals[0] == address(0)) {
                ratifiedPoolRefillApprovals[0] = msg.sender;
                return;
            }
            if (refillApprovals[1] == address(0)) {
                ratifiedPoolRefillApprovals[1] = msg.sender;
                return;
            }
        }
        delete ratifiedPoolRefillApprovals; // clears the whole array
        multiSigMintPool = multiSigMintPool.sub(ratifiedMintLimit.sub(ratifiedMintPool));
        ratifiedMintPool = ratifiedMintLimit;
        emit RatifyPoolRefilled();
    }

    /**
     * @dev Owner can refill MultiSig Mint Pool
     */
    function refillMultiSigMintPool() external onlyOwner {
        multiSigMintPool = multiSigMintLimit;
        emit MultiSigPoolRefilled();
    }

    /**
     * @dev mintKey initiates a request to mint _value for account _to
     * @param _to the address to mint to
     * @param _value the amount requested
     */
    function requestMint(address _to, uint256 _value) external mintNotPaused onlyMintKeyOrOwner {
        MintOperation memory op = MintOperation(_to, _value, block.number, 0, false);
        emit RequestMint(_to, _value, mintOperations.length, msg.sender);
        mintOperations.push(op);
    }

    /**
     * @dev Instant mint without ratification if the amount is less
     * than instantMintThreshold and instantMintPool
     * @param _to the address to mint to
     * @param _value the amount minted
     */
    function instantMint(address _to, uint256 _value) external mintNotPaused onlyMintKeyOrOwner {
        require(_value <= instantMintThreshold, "over the instant mint threshold");
        require(_value <= instantMintPool, "instant mint pool is dry");
        instantMintPool = instantMintPool.sub(_value);
        emit InstantMint(_to, _value, msg.sender);
        token.mint(_to, _value);
    }

    /**
     * @dev ratifier ratifies a request mint. If the number of
     * ratifiers that signed off is greater than the number of
     * approvals required, the request is finalized
     * @param _index the index of the requestMint to ratify
     * @param _to the address to mint to
     * @param _value the amount requested
     */
    function ratifyMint(
        uint256 _index,
        address _to,
        uint256 _value
    ) external mintNotPaused onlyMintRatifierOrOwner {
        MintOperation memory op = mintOperations[_index];
        require(op.to == _to, "to address does not match");
        require(op.value == _value, "amount does not match");
        require(!mintOperations[_index].approved[msg.sender], "already approved");
        mintOperations[_index].approved[msg.sender] = true;
        mintOperations[_index].numberOfApproval = mintOperations[_index].numberOfApproval.add(1);
        emit MintRatified(_index, msg.sender);
        if (hasEnoughApproval(mintOperations[_index].numberOfApproval, _value)) {
            finalizeMint(_index);
        }
    }

    /**
     * @dev finalize a mint request, mint the amount requested to the specified address
     * @param _index of the request (visible in the RequestMint event accompanying the original request)
     */
    function finalizeMint(uint256 _index) public mintNotPaused {
        MintOperation memory op = mintOperations[_index];
        address to = op.to;
        uint256 value = op.value;
        if (msg.sender != owner) {
            require(canFinalize(_index));
            _subtractFromMintPool(value);
        }
        delete mintOperations[_index];
        token.mint(to, value);
        emit FinalizeMint(to, value, _index, msg.sender);
    }

    /**
     * assumption: only invoked when canFinalize
     */
    function _subtractFromMintPool(uint256 _value) internal {
        if (_value <= ratifiedMintPool && _value <= ratifiedMintThreshold) {
            ratifiedMintPool = ratifiedMintPool.sub(_value);
        } else {
            multiSigMintPool = multiSigMintPool.sub(_value);
        }
    }

    /**
     * @dev compute if the number of approvals is enough for a given mint amount
     */
    function hasEnoughApproval(uint256 _numberOfApproval, uint256 _value) public view returns (bool) {
        if (_value <= ratifiedMintPool && _value <= ratifiedMintThreshold) {
            if (_numberOfApproval >= RATIFY_MINT_SIGS) {
                return true;
            }
        }
        if (_value <= multiSigMintPool && _value <= multiSigMintThreshold) {
            if (_numberOfApproval >= MULTISIG_MINT_SIGS) {
                return true;
            }
        }
        if (msg.sender == owner) {
            return true;
        }
        return false;
    }

    /**
     * @dev compute if a mint request meets all the requirements to be finalized
     * utility function for a front end
     */
    function canFinalize(uint256 _index) public view returns (bool) {
        MintOperation memory op = mintOperations[_index];
        require(op.requestedBlock > mintReqInvalidBeforeThisBlock, "this mint is invalid"); //also checks if request still exists
        require(!op.paused, "this mint is paused");
        require(hasEnoughApproval(op.numberOfApproval, op.value), "not enough approvals");
        return true;
    }

    /**
     * @dev revoke a mint request, Delete the mintOperation
     * @param _index of the request (visible in the RequestMint event accompanying the original request)
     */
    function revokeMint(uint256 _index) external onlyMintKeyOrOwner {
        delete mintOperations[_index];
        emit RevokeMint(_index);
    }

    /**
     * @dev get mint operatino count
     * @return mint operation count
     */
    function mintOperationCount() public view returns (uint256) {
        return mintOperations.length;
    }

    /*
    ========================================
    Key management
    ========================================
    */

    /**
     * @dev Replace the current mintkey with new mintkey
     * @param _newMintKey address of the new mintKey
     */
    function transferMintKey(address _newMintKey) external onlyOwner {
        require(_newMintKey != address(0), "new mint key cannot be 0x0");
        emit TransferMintKey(mintKey, _newMintKey);
        mintKey = _newMintKey;
    }

    function setProofOfReserveEnabler(address enabler) external onlyOwner {
        emit ProofOfReserveEnablerSet(proofOfReserveEnabler, enabler);
        proofOfReserveEnabler = enabler;
    }

    /*
    ========================================
    Mint Pausing
    ========================================
    */

    /**
     * @dev invalidates all mint request initiated before the current block
     */
    function invalidateAllPendingMints() external onlyOwner {
        mintReqInvalidBeforeThisBlock = block.number;
    }

    /**
     * @dev pause any further mint request and mint finalizations
     */
    function pauseMints() external onlyMintPauserOrOwner {
        mintPaused = true;
        emit AllMintsPaused(true);
    }

    /**
     * @dev unpause any further mint request and mint finalizations
     */
    function unpauseMints() external onlyOwner {
        mintPaused = false;
        emit AllMintsPaused(false);
    }

    /**
     * @dev pause a specific mint request
     * @param  _opIndex the index of the mint request the caller wants to pause
     */
    function pauseMint(uint256 _opIndex) external onlyMintPauserOrOwner {
        mintOperations[_opIndex].paused = true;
        emit MintPaused(_opIndex, true);
    }

    /**
     * @dev unpause a specific mint request
     * @param  _opIndex the index of the mint request the caller wants to unpause
     */
    function unpauseMint(uint256 _opIndex) external onlyOwner {
        mintOperations[_opIndex].paused = false;
        emit MintPaused(_opIndex, false);
    }

    /*
    ========================================
    set and claim contracts, administrative
    ========================================
    */

    /**
     * @dev Update this contract's token pointer to newContract (e.g. if the
     * contract is upgraded)
     */
    function setToken(TrueCurrency _newContract) external onlyOwner {
        token = _newContract;
        emit SetToken(_newContract);
    }

    /**
     * @dev Update this contract's registry pointer to _registry
     */
    function setRegistry(Registry _registry) external onlyOwner {
        registry = _registry;
        emit SetRegistry(address(registry));
    }

    /**
     * @dev Claim ownership of an arbitrary IHasOwner contract
     */
    function issueClaimOwnership(address _other) public onlyOwner {
        IHasOwner other = IHasOwner(_other);
        other.claimOwnership();
    }

    /**
     * @dev Transfer ownership of _child to _newOwner.
     * Can be used e.g. to upgrade this TokenController contract.
     * @param _child contract that tokenController currently Owns
     * @param _newOwner new owner/pending owner of _child
     */
    function transferChild(IHasOwner _child, address _newOwner) external onlyOwner {
        _child.transferOwnership(_newOwner);
        emit TransferChild(address(_child), _newOwner);
    }

    /**
     * @dev send all bnb in token address to the owner of tokenController
     */
    function requestReclaimBNB() external onlyOwner {
        token.reclaimBNB(owner);
    }

    /**
     * @dev transfer all tokens of a particular type in token address to the
     * owner of tokenController
     * @param _token token address of the token to transfer
     */
    function requestReclaimToken(IBEP20 _token) external onlyOwner {
        token.reclaimToken(_token, owner);
    }

    /**
     * @dev pause all pausable actions on TrueCurrency, mints/burn/transfer/approve
     */
    function pauseToken() external virtual onlyOwner {
        OwnedUpgradeabilityProxy(address(uint160(address(token)))).upgradeTo(PAUSED_IMPLEMENTATION);
    }

    /**
     * @dev Change the minimum and maximum amounts that TrueCurrency users can
     * burn to newMin and newMax
     * @param _min minimum amount user can burn at a time
     * @param _max maximum amount user can burn at a time
     */
    function setBurnBounds(uint256 _min, uint256 _max) external onlyOwner {
        token.setBurnBounds(_min, _max);
    }

    /**
     * @dev Owner can send bnb balance in contract address
     * @param _to address to which the funds will be send to
     */
    function reclaimBNB(address payable _to) external onlyOwner {
        _to.transfer(address(this).balance);
    }

    /**
     * @dev Owner can send bep20 token balance in contract address
     * @param _token address of the token to send
     * @param _to address to which the funds will be send to
     */
    function reclaimToken(IBEP20 _token, address _to) external onlyOwner {
        uint256 balance = _token.balanceOf(address(this));
        _token.transfer(_to, balance);
    }

    /**
     * @dev Owner can allow address to burn tokens
     * @param burner address of the token that can burn
     * @param canBurn true if account is allowed to burn, false otherwise
     */
    function setCanBurn(address burner, bool canBurn) external onlyRegistryAdminOrOwner {
        token.setCanBurn(burner, canBurn);
        emit CanBurn(burner, canBurn);
    }

    /**
     * @dev Set blacklisted status for the account.
     * @param account address to set blacklist flag for
     * @param isBlacklisted blacklist flag value
     */
    function setBlacklisted(address account, bool isBlacklisted) external onlyOwner {
        token.setBlacklisted(account, isBlacklisted);
    }

    /*
    ========================================
    Proof of Reserve, administrative
    ========================================
    */

    /**
     * Set new chainReserveFeed address
     */
    function setChainReserveFeed(address newFeed) external onlyOwner {
        IProofOfReserveToken(address(token)).setChainReserveFeed(newFeed);
    }

    /**
     * Set new chainReserveHeartbeat
     */
    function setChainReserveHeartbeat(uint256 newHeartbeat) external onlyProofOfReserveEnablerOrOwner {
        IProofOfReserveToken(address(token)).setChainReserveHeartbeat(newHeartbeat);
    }

    /**
     * Disable Proof of Reserve check
     */
    function disableProofOfReserve() external onlyProofOfReserveEnablerOrOwner {
        IProofOfReserveToken(address(token)).disableProofOfReserve();
    }

    /**
     * Enable Proof of Reserve check
     */
    function enableProofOfReserve() external onlyProofOfReserveEnablerOrOwner {
        IProofOfReserveToken(address(token)).enableProofOfReserve();
    }
}