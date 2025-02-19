/**
 *Submitted for verification at BscScan.com on 2022-09-27
*/

/***
 * 
 * 
 *    ▄████████  ▄█   ▄█        ▄█       ▄██   ▄      ▄████████    ▄█    █▄       ▄████████    ▄████████    ▄███████▄
 *   ███    ███ ███  ███       ███       ███   ██▄   ███    ███   ███    ███     ███    ███   ███    ███   ███    ███
 *   ███    █▀  ███▌ ███       ███       ███▄▄▄███   ███    █▀    ███    ███     ███    █▀    ███    █▀    ███    ███
 *   ███        ███▌ ███       ███       ▀▀▀▀▀▀███   ███         ▄███▄▄▄▄███▄▄  ▄███▄▄▄      ▄███▄▄▄       ███    ███
 * ▀███████████ ███▌ ███       ███       ▄██   ███ ▀███████████ ▀▀███▀▀▀▀███▀  ▀▀███▀▀▀     ▀▀███▀▀▀     ▀█████████▀
 *          ███ ███  ███       ███       ███   ███          ███   ███    ███     ███    █▄    ███    █▄    ███
 *    ▄█    ███ ███  ███▌    ▄ ███▌    ▄ ███   ███    ▄█    ███   ███    ███     ███    ███   ███    ███   ███
 *  ▄████████▀  █▀   █████▄▄██ █████▄▄██  ▀█████▀   ▄████████▀    ███    █▀      ██████████   ██████████  ▄████▀
 *                   ▀         ▀
 *
 * https://sillysheep.io
 * MIT License
 * ===========
 *
 * Copyright (c) 2022 sillysheep
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
*/// File: @openzeppelin/contracts/utils/math/SafeMath.sol

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

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

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


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

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

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

// File: contracts/interface/IPlayerBook.sol

pragma solidity ^0.8.0;


interface IPlayerBook {

    function settleReward( address from,uint256 amount ) external returns (uint256);
    function bindRefer( address from,string calldata  affCode )  external returns (bool);
    function hasRefer(address from) external returns(bool);
    
}

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

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

// File: contracts/interface/ISheep.sol

pragma solidity ^0.8.0;


interface ISheep is IERC721 {

    struct SheepInfo {
        uint256 level;
        uint256 earnSpeed;
        bool bellwether;
        uint256 rechargeTimes;
    }
    
    function increaseLives(uint256 _sheepId) external;

    function getSheepInfo(uint256 _sheepId)
        external view returns(SheepInfo memory info);
    
    function mint(
        address to,
        SheepInfo calldata _info)
        external returns(uint256);

    function burn(uint256 _sheepId) external;
}

// File: contracts/interface/ISheepProp.sol

pragma solidity ^0.8.0;


interface ISheepProp {

    struct PropInfo {
        uint256 propType; // 1, 2, 3
        uint256 rechargeTimes;
    }
    
    function increaseProp(uint256 _propId, uint256 times) external;

    function getPropInfo(uint256 _propId)
        external view returns(PropInfo memory info);
    
    function mint(
        address to,
        PropInfo calldata _info)
        external returns(uint256);

    function burn(uint256 _propId) external;
}

// File: contracts/nft/SheepFactory.sol


pragma solidity ^0.8.0;


// import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";



contract SheepFactory is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    bool private initialized;

    ISheep public sheep;
    ISheepProp public prop;
    uint256[] public lifePrices;
    uint256[] public propPrices;

    uint256 public rechargeRatio; // 6
    uint256 public priceRatio;// 2

    uint256 public lifeIn;
    uint256 public propIn;

    address payable devAddress;

    address public playerBook;

    event Withdraw(address indexed devAddress, uint256 balance);
    event UpdateLifePrices(uint256[] prices, uint256 rechargeRatio, uint256 priceRatio);
    event RechargeLives(address indexed sender, uint256 sheepId, uint256 totalTimes);
    event UpdatePropPrices(uint256[] _propPrices);
    event ImproveProps(address indexed sender, uint256 propId, uint256 totalTimes, uint256 times);
    event UpdateDev(address _newDev);

    // constructor(
    //         address _sheep,
    //         address _prop,
    //         address payable _devAddress, 
    //         address _playerBook) {
    //     sheep = ISheep(_sheep);
    //     prop = ISheepProp(_prop);
    //     devAddress = _devAddress;
    //     playerBook = _playerBook;
    // }

    function initialize(
        address _owner,
        address _sheep,
        address _prop,
        address payable _devAddress, 
        address _playerBook
        ) external {
        require(!initialized, "initialize: Already initialized!");
        _transferOwnership(_owner);
        
        sheep = ISheep(_sheep);
        prop = ISheepProp(_prop);
        devAddress = _devAddress;
        playerBook = _playerBook;

        initialized = true;
    }

    function rechargeLives(uint256 _sheepId, string memory affCode) external virtual payable {
        (uint256 price, uint256 rechargeTimes) = rechargeLivesById(_sheepId);
        require(msg.value >= price, "Value is too low!!!");
        
        emit RechargeLives(msg.sender, _sheepId, rechargeTimes);
        
        sheep.increaseLives(_sheepId);
        lifeIn = lifeIn.add(price);

        if (!IPlayerBook(playerBook).hasRefer(msg.sender)) {
            IPlayerBook(playerBook).bindRefer(msg.sender, affCode);
        }
    }

    function rechargeLivesById(uint256 _sheepId) public view 
    returns(uint256 price, uint256 rechargeTimes){
        ISheep.SheepInfo memory sheepInfo = sheep.getSheepInfo(_sheepId);
        uint256 level = sheepInfo.level;

        uint256 basePrice = lifePrices[level-1];
        rechargeTimes = sheepInfo.rechargeTimes;
        price = basePrice.mul(rechargeTimes).div(rechargeRatio).add(basePrice.div(priceRatio));
    }

    function nextRechargeLivesById(uint256 _sheepId) public view 
    returns(uint256 price, uint256 rechargeTimes){
        ISheep.SheepInfo memory sheepInfo = sheep.getSheepInfo(_sheepId);
        uint256 level = sheepInfo.level;

        uint256 basePrice = lifePrices[level-1];
        rechargeTimes = sheepInfo.rechargeTimes+1;
        price = basePrice.mul(rechargeTimes).div(rechargeRatio).add(basePrice.div(priceRatio));
    }

    function updateLifePrices(
        uint256[] memory _lifePrices,
        uint256 _rechargeRatio,
        uint256 _priceRatio
        ) external onlyOwner {
        lifePrices = _lifePrices;
        rechargeRatio = _rechargeRatio;
        priceRatio = _priceRatio;
        emit UpdateLifePrices(_lifePrices, rechargeRatio, priceRatio);
    }

    function improveProps(uint256 propId, uint256 times, string memory affCode) external virtual payable {
        
        ISheepProp.PropInfo memory info = prop.getPropInfo(propId);
        uint256 propType = info.propType;

        uint256 price = times.mul(propPrices[propType-1]);
        
        require(msg.value >= price, "Value is too low!!!");

        emit ImproveProps(msg.sender, propId, info.rechargeTimes, times);
        
        prop.increaseProp(propId, times);
        propIn = propIn.add(price);

        if (!IPlayerBook(playerBook).hasRefer(msg.sender)) {
            IPlayerBook(playerBook).bindRefer(msg.sender, affCode);
        }
    }
    
    function updatePropPrices(
        uint256[] memory _propPrices
        ) external onlyOwner {
        propPrices = _propPrices;
        emit UpdatePropPrices(_propPrices);
    }
 
    function updateDev(address payable newDev)external onlyOwner {
        devAddress = newDev;
        emit UpdateDev(newDev);
    }

    function withdraw() external onlyOwner {
        uint256 balance =  address(this).balance;
        devAddress.transfer(balance);
        emit Withdraw(devAddress, balance);
    }
    
    receive() payable external {}
}

// File: contracts/interface/IPlayerReward.sol

pragma solidity ^0.8.0;


interface IPlayerReward {
    
    struct Player {
        address addr;
        bytes32 name;
        uint8 nameCount;
        uint256 laff;
        uint256 amount;
        uint256 rreward;
        uint256 allReward;
        uint256 lv1Count;
        uint256 lv2Count;
    }
    
    function settleReward(address from,uint256 amount ) external returns (uint256, address, uint256, address);
    function _pIDxAddr(address from) external view returns(uint256);
    function _plyr(uint256 playerId) external view returns(Player memory player);
    function _pools(address pool) external view returns(bool);
}

// File: contracts/referral/SheepFactoryV2.sol


pragma solidity ^0.8.0;


contract SheepFactoryV2 is SheepFactory {
    using SafeMath for uint256;
    
    address public playerReward;

    function addPlayerReward(address _playerReward) external onlyOwner {
        playerReward = _playerReward;
    }

    function rechargeLives(uint256 _sheepId, string memory affCode) external override payable {
       
        (uint256 price, uint256 rechargeTimes) = rechargeLivesById(_sheepId);
        require(msg.value >= price, "Value is too low!!!");
        
        emit RechargeLives(msg.sender, _sheepId, rechargeTimes);
        
        sheep.increaseLives(_sheepId);
        lifeIn = lifeIn.add(price);

        if (!IPlayerBook(playerBook).hasRefer(msg.sender)) {
            IPlayerBook(playerBook).bindRefer(msg.sender, affCode);
        }

        (uint256 affReward, address laff,
        uint256 aff_affReward, address aff_aff) = IPlayerReward(playerReward).settleReward(msg.sender, price);

        payable(laff).transfer(affReward);
        payable(aff_aff).transfer(aff_affReward);
    }

    function improveProps(uint256 propId, uint256 times, string memory affCode) external override payable {
        
        ISheepProp.PropInfo memory info = prop.getPropInfo(propId);
        uint256 propType = info.propType;

        uint256 price = times.mul(propPrices[propType-1]);
        
        require(msg.value >= price, "Value is too low!!!");

        emit ImproveProps(msg.sender, propId, info.rechargeTimes, times);
        
        prop.increaseProp(propId, times);
        propIn = propIn.add(price);

        if (!IPlayerBook(playerBook).hasRefer(msg.sender)) {
            IPlayerBook(playerBook).bindRefer(msg.sender, affCode);
        }

        (uint256 affReward, address laff,
        uint256 aff_affReward, address aff_aff) = IPlayerReward(playerReward).settleReward(msg.sender, price);

        payable(laff).transfer(affReward);
        payable(aff_aff).transfer(aff_affReward);
    }
}