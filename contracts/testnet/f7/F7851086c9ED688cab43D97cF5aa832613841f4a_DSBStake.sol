// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

interface DSBNFTs {
    function walletOfOwner(address _owner)
        external
        view
        returns (uint256[] memory);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external returns (bool);

    function totalSupply() external view returns (uint256);

    function ownerOf(uint256 tokenId) external view returns (address);

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);
}

interface DSBTOKEN {
    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);
}

interface PancakeRouter {
    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

contract DSBStake is Ownable {
    address public DSBNFT_ADDRESS = address(0);
    address public DSBTOKEN_ADDRESS = address(0);

    modifier onlyEOA() {
        require(msg.sender == tx.origin, "Only EOA");
        _;
    }

    modifier onlyVERIFIED(address addr) {
        require(
            addr == DSBNFT_ADDRESS || addr == DSBTOKEN_ADDRESS,
            "Only verified allowed"
        );
        _;
    }

    uint256 minRewardPeriod = 30 days;

    struct StakeInfo {
        bool isStaked;
        bool isFirstDone;
        uint256 commitDate;
        address lastOwner;
        address currentOwner;
    }

    mapping(uint256 => StakeInfo) stakeTracker;

    DSBNFTs dsbNFTInstance;
    DSBTOKEN dsbTokenInstance;
    PancakeRouter pRouter =
        PancakeRouter(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);

    //ALIGNMENT

    function setDSBNFTAddress(address addr) external onlyOwner {
        DSBNFT_ADDRESS = addr;
        dsbNFTInstance = DSBNFTs(addr);
    }

    function setDSBTOKENAddress(address addr) external onlyOwner {
        DSBTOKEN_ADDRESS = addr;
        dsbTokenInstance = DSBTOKEN(addr);
    }

    function setPoolRouter(address addr) external onlyOwner {
        pRouter = PancakeRouter(addr);
    }

    //STATEFUL

    function stake(uint256[] memory tokenId) public onlyEOA {
        require(tokenId.length > 0, "cannot stake zero value tokenid");
        require(
            dsbNFTInstance.isApprovedForAll(msg.sender, address(this)),
            "need approval from owner"
        );

        for (uint256 i = 0; i < tokenId.length; i++) {
            StakeInfo storage sInfo = stakeTracker[tokenId[i]];

            if (
                dsbNFTInstance.ownerOf(tokenId[i]) != msg.sender &&
                sInfo.isStaked != false
            ) {
                revert();
            } else {
                dsbNFTInstance.safeTransferFrom(
                    msg.sender,
                    address(this),
                    tokenId[i]
                );

                if (sInfo.lastOwner != msg.sender) {
                    sInfo.isFirstDone = false;
                } else {
                    sInfo.isFirstDone = true;
                }
                sInfo.commitDate = block.timestamp;
                sInfo.isStaked = true;
                sInfo.lastOwner = msg.sender;
                sInfo.currentOwner = msg.sender;
            }
        }
    }

    function unStake(uint256[] memory tokenId) public onlyEOA {
        require(tokenId.length > 0, "argument needed");

        require(
            dsbNFTInstance.isApprovedForAll(msg.sender, address(this)),
            "need approval from owner"
        );

        for (uint256 i = 0; i < tokenId.length; i++) {
            StakeInfo storage sInfo = stakeTracker[tokenId[i]];
            if (
                dsbNFTInstance.ownerOf(tokenId[i]) != msg.sender &&
                sInfo.isStaked != true
            ) {
                revert();
            } else {
                sInfo.isStaked = false;
                sInfo.currentOwner = address(0);
                dsbNFTInstance.safeTransferFrom(
                    address(this),
                    msg.sender,
                    tokenId[i]
                );
            }
        }
    }

    function claim() public onlyEOA returns (bool) {
        uint256[] memory stakedNft = getStakedNFT(msg.sender);
        require(
            dsbTokenInstance.balanceOf(address(this)) > 0,
            "nothing to claim yet"
        );
        require(stakedNft.length > 0, "no staked nfts are available to claim");

        uint256 claimAble = calculateReward(msg.sender);
        require(claimAble > 0, "null claim");
        for (uint256 i = 0; i < stakedNft.length; i++) {
            StakeInfo storage sInfo = stakeTracker[stakedNft[i]];
            if (sInfo.isFirstDone == false) {
                sInfo.isFirstDone = true;
            }
        }

        require(dsbTokenInstance.transfer(msg.sender, claimAble), "tx failed");
        return true;
    }

    //VIEW

    function getStakedNFT(address addr) public view returns (uint256[] memory) {
        uint256[] memory getTokenId = dsbNFTInstance.walletOfOwner(addr);
        uint256[] memory output = new uint256[](getTokenId.length);
        require(getTokenId.length > 0, "address does not own a single nft");
        for (uint256 i = 0; i < getTokenId.length; i++) {
            StakeInfo storage sInfo = stakeTracker[getTokenId[i]];
            if (sInfo.currentOwner == addr && sInfo.isStaked == true) {
                output[i] = getTokenId[i];
            }
        }
        return output;
    }

    function viewRewardPool() public view returns (uint256) {
        return dsbTokenInstance.balanceOf(address(this));
    }

    function calculateReward(address addr) public view returns (uint256) {
        uint256[] memory stakedNft = getStakedNFT(addr);
        address[] memory path = new address[](2);
        path[0] = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
        path[1] = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
        uint256[] memory output = pRouter.getAmountsOut(
            400000000000000000,
            path
        );
        uint256 baseReward = output[1];
        uint256 bp;
        uint256 totalReward;
        for (uint256 i = 0; i < stakedNft.length; i++) {
            StakeInfo storage sInfo = stakeTracker[stakedNft[i]];
            if (sInfo.isStaked == true) {
                if (
                    block.timestamp - sInfo.commitDate >= 30 days &&
                    sInfo.isFirstDone == false
                ) {
                    bp = 50;
                } else if (block.timestamp - sInfo.commitDate < 30 days) {
                    // bp = 0;
                    bp = 10;
                } else {
                    bp = 30;
                }
                totalReward += (baseReward * (bp * 100)) / 10000;
            }
        }

        return totalReward;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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