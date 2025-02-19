// SPDX-License-Identifier: None
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

interface IPEAirdropService {
    function claim(uint256 poolType, address account, uint256 receivedAmount, uint256 receivedVoucher) external;
    function increaseAirdrop(uint256 poolType, address account, uint256 amount) external;
}

contract PEAirdrop is ReentrancyGuard, Ownable, Pausable {
    address public AIRDROP_TOKEN = 0x1FC8d426cDF51062E818A2c55c64dC4af209b272;
    address public PE_AIRDROP_SERVICE = 0x4D415db330B36B59f60717A0cdB2253a4dDBC1b6;

    // PEXO = 1, 50$ = 2, 5$ = 3, 2048 = 4
    uint256 public POOL_TYPE = 1;

    uint256 public CLAIMED_AIRDROP_BEGIN_AT = 1657065600;
    uint256 public CLAIMED_AIRDROP_END_AT = 2663144875;
    uint256 public VOUCHER_PRICE = 160 * 10 ** 18;

    uint256 public TOTAL_VOUCHER_RECEIVED;
    uint256 public TOTAL_AMOUNT_RECEIVED;

    struct UserInfo {
        uint256 value; // Total airdrop can receive
        uint256 receivedAmount; // Reward debt
        uint256 receivedVoucher;
    }

    mapping(address => bool) private _admins;
    mapping(address => UserInfo) public userInfo;

    event AdminsChanged(address indexed account, bool allowance);
    event ClaimAirdrop(uint256 indexed claimType, address indexed receiver, uint256 indexed amount); // 0: cash, 1: voucher
    event PEAirdropServiceContractChanged(address indexed _contract);

    modifier onlyAdmins() {
        require(_admins[_msgSender()], "Caller must be the admin.");
        _;
    }

    constructor() {
        _admins[_msgSender()] = true;
    }

    function setAdmin(address account, bool allowance) external onlyOwner {
        _admins[account] = allowance;
        emit AdminsChanged(account, allowance);
    }

    function setPEAirdropService(address _contract) external onlyOwner {
        PE_AIRDROP_SERVICE = _contract;
        emit PEAirdropServiceContractChanged(_contract);
    }

    function setClaimTime(uint256 _startedAt, uint256 _finishedAt) external onlyAdmins {
        CLAIMED_AIRDROP_BEGIN_AT = _startedAt;
        CLAIMED_AIRDROP_END_AT = _finishedAt;
    }

    function isAdmin(address account) external view returns (bool) {
        return (_admins[account]);
    }

    function increaseAirdropValue(address[] memory recipients, uint256 value) external onlyAdmins {
        for (uint256 i = 0; i < recipients.length; i++) {
            UserInfo storage user = userInfo[recipients[i]];
            user.value = user.value + value;
            IPEAirdropService(PE_AIRDROP_SERVICE).increaseAirdrop(POOL_TYPE, recipients[i], value);
        }
    }

    function claimAirdrop(uint256 _amount, uint256 _voucher) external nonReentrant {
        require(block.timestamp >= CLAIMED_AIRDROP_BEGIN_AT && block.timestamp <= CLAIMED_AIRDROP_END_AT, "Can not claim airdrop at this time");

        UserInfo storage user = userInfo[_msgSender()];
        uint256 remainAmount = user.value - (user.receivedVoucher * VOUCHER_PRICE + user.receivedAmount);
        require(_amount + _voucher * VOUCHER_PRICE <= remainAmount, "Claim airdrop exceeds allowance");

        user.receivedVoucher = user.receivedVoucher + _voucher;
        user.receivedAmount = user.receivedAmount + _amount;

        if (_amount > 0) {
            TOTAL_AMOUNT_RECEIVED = TOTAL_AMOUNT_RECEIVED + _amount;
            IERC20(AIRDROP_TOKEN).transfer(_msgSender(), _amount);
            emit ClaimAirdrop(0, _msgSender(), _amount);
        }

        if (_voucher > 0) {
            TOTAL_VOUCHER_RECEIVED = TOTAL_VOUCHER_RECEIVED + _voucher;
            emit ClaimAirdrop(1, _msgSender(), _voucher);
        }

        IPEAirdropService(PE_AIRDROP_SERVICE).claim(POOL_TYPE, _msgSender(), _amount, _voucher);
    }

    function transferAnyBEP20Token(address _tokenAddress, uint256 _amount) external onlyAdmins {
        require(block.timestamp > CLAIMED_AIRDROP_END_AT, "Can not transfer at this time");
        IERC20(_tokenAddress).transfer(owner(), _amount);
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
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