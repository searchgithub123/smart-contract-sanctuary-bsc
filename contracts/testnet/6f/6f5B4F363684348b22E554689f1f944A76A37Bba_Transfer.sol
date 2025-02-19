// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
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
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

contract ReEntrancyGuard {
    bool internal locked;

    modifier noReentrant() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./security/ReEntrancyGuard.sol";

contract Transfer is ReEntrancyGuard, Ownable {
    /// @dev pause contract
    bool public status;

    /// @dev token address
    address private usdtAddress;
    address private busdAddress;

    /// @dev admin address
    mapping(address => bool) private isAdmin;

    /// @dev Token transfer event is triggered whenever a admin transfer tokens
    event WithdrawAdminEvent(
        address _client,
        uint256 _amount,
        string _tokenTypeSymbol
    );

    /// @dev Token transfer event is triggered whenever a admin transfer tokens
    event WithdrawMassiveEvent(
        address[] _client,
        uint256[] _amount,
        string _tokenTypeSymbol
    );

    /// @dev Only admin can call this function
    modifier onlyAdmin() {
        require(isAdmin[msg.sender], "You are not admin");
        _;
    }

    /// @dev Verify if the contract is active
    modifier pausable() {
        require(status, "Require the contract is active");
        _;
    }

    /**
     * @dev initialized tue USDT and BUSD address
     */
    constructor(address _usdtAddress, address _busdAddress) {
        usdtAddress = _usdtAddress;
        busdAddress = _busdAddress;
        status = false;
    }

    /**
     * @dev change the token address.
     * @param _tokenAddress The address of the token to change.
     * @param _tokenSymbol The symbol of the token to change.
     */
    function changeTokenAddress(
        address _tokenAddress,
        string memory _tokenSymbol
    ) public onlyOwner {
        if (keccak256(bytes(_tokenSymbol)) == keccak256("USDT")) {
            usdtAddress = _tokenAddress;
        } else if (keccak256(bytes(_tokenSymbol)) == keccak256("BUSD")) {
            busdAddress = _tokenAddress;
        }
    }

    /**
     * @dev Functionality to withdraw only by admin accounts.
     * @param _amount quitity of tokens to transfer.
     * @param _tokenTypeSymbol The symbol of the token to transfer.
     * @param _client The address of the client to transfer.
     */
    function adminWithdraw(uint256 _amount, string memory _tokenTypeSymbol, address _client)
        public
        onlyAdmin
        pausable
        noReentrant
    {
        if (keccak256(bytes(_tokenTypeSymbol)) == keccak256("USDT")) {
            require(
                IERC20(usdtAddress).balanceOf(address(this)) >= _amount,
                "TransferTokensFor: Vendor contract has not enough tokens in its balance"
            );

            require(
                IERC20(usdtAddress).transfer(_client, _amount),
                "TransferTokensFor: Failed to transfer tokens from the vendor to the admin"
            );
        } else if (keccak256(bytes(_tokenTypeSymbol)) == keccak256("BUSD")) {
            require(
                IERC20(busdAddress).balanceOf(address(this)) >= _amount,
                "TransferTokensFor: Vendor contract has not enough tokens in its balance"
            );

            require(
                IERC20(busdAddress).transfer(_client, _amount),
                "TransferTokensFor: Failed to transfer tokens from the vendor to the admin"
            );
        } else if (keccak256(bytes(_tokenTypeSymbol)) == keccak256("BNB")) {
            require(
                address(this).balance >= _amount,
                "TransferTokensFor: Vendor contract has not enough tokens in its balance"
            );

            (bool success, ) = payable(_client).call{value: _amount}("");
            require(
                success,
                "TransferTokensFor: Failed to transfer tokens from vender to client"
            );
        }

        emit WithdrawAdminEvent(_client, _amount, _tokenTypeSymbol);
    }

    /**
     * @dev Functionality to withdraw to the diferents accounts.
     * @param _wallets is the array of wallets to withdraw.
     * @param _amounts is the array of the amounts to withdraw.
     * @param _tokenTypeSymbol is the type of token to withdraw.
     */
    function withdrawMassive(
        address[] memory _wallets,
        uint256[] memory _amounts,
        string memory _tokenTypeSymbol
    ) public onlyAdmin pausable noReentrant {
        if (keccak256(bytes(_tokenTypeSymbol)) == keccak256("USDT")) {
            for (uint256 i; i < _wallets.length; i++) {
                require(
                    IERC20(usdtAddress).balanceOf(address(this)) >= _amounts[i],
                    "TransferTokensFor: Vendor contract has not enough tokens in its balance"
                );
                require(
                    IERC20(usdtAddress).transfer(_wallets[i], _amounts[i]),
                    "TransferTokensFor: Failed to transfer tokens from the vendor to the client"
                );
            }
        } else if (keccak256(bytes(_tokenTypeSymbol)) == keccak256("BUSD")) {
            for (uint256 i; i < _wallets.length; i++) {
                require(
                    IERC20(busdAddress).balanceOf(address(this)) >= _amounts[i],
                    "TransferTokensFor: Vendor contract has not enough tokens in its balance"
                );

                require(
                    IERC20(busdAddress).transfer(_wallets[i], _amounts[i]),
                    "TransferTokensFor: Failed to transfer tokens from the vendor to the client"
                );
            }
        } else if (keccak256(bytes(_tokenTypeSymbol)) == keccak256("BNB")) {
            for (uint256 i; i < _wallets.length; i++) {
                require(
                    address(this).balance >= _amounts[i],
                    "TransferTokensFor: Vendor contract has not enough tokens in its balance"
                );

                (bool success, ) = payable(_wallets[i]).call{
                    value: _amounts[i]
                }("");
                require(
                    success,
                    "TransferTokensFor: Failed to transfer tokens from vender to client"
                );
            }
        }
        emit WithdrawMassiveEvent(_wallets, _amounts, _tokenTypeSymbol);
    }

    /**
     * @dev verify vendor balance.
     * @param _tokenTypeSymbol is the token to verify the balance.
     */
    function verifyBalance(string memory _tokenTypeSymbol)
        public
        view
        returns (uint256)
    {
        if (keccak256(bytes(_tokenTypeSymbol)) == keccak256("USDT")) {
            return IERC20(usdtAddress).balanceOf(address(this));
        } else if (keccak256(bytes(_tokenTypeSymbol)) == keccak256("BUSD")) {
            return IERC20(busdAddress).balanceOf(address(this));
        } else if (keccak256(bytes(_tokenTypeSymbol)) == keccak256("BNB")) {
            return address(this).balance;
        }
        return 0;
    }

    /**
     * @dev Set admin account.
     */
    function setAdmin(address _account) public onlyOwner {
        isAdmin[_account] = true;
    }

    /**
     * @dev Remove admin account.
     */
    function removeAdmin(address _account) public onlyOwner {
        isAdmin[_account] = false;
    }

    /**
     * @dev Pause contract.
     */
    function setStatusActive() public onlyOwner returns (bool) {
        status = !status;
        return status;
    }

    fallback() external payable {
        // Do nothing
    }

    receive() external payable {
        // Do nothing
    }
}