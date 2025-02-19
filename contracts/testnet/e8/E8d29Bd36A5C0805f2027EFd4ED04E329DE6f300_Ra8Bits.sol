// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";




interface IERC1155 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(
        address indexed account,
        address indexed operator,
        bool approved
    );

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator)
        external
        view
        returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

library BytesLibrary {
    function toString(bytes32 value) internal pure returns (string memory) {
        bytes memory alphabet = "0123456789abcdef";
        bytes memory str = new bytes(64);
        for (uint256 i = 0; i < 32; i++) {
            str[i * 2] = alphabet[uint8(value[i] >> 4)];
            str[1 + i * 2] = alphabet[uint8(value[i] & 0x0f)];
        }
        return string(str);
    }
}

library UintLibrary {
    using SafeMath for uint256;

    function toString(uint256 i) internal pure returns (string memory) {
        if (i == 0) {
            return "0";
        }
        uint256 j = i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len - 1;
        while (i != 0) {
            bstr[k--] = bytes1(uint8(48 + (i % 10)));
            i /= 10;
        }
        return string(bstr);
    }

    function bp(uint256 value, uint256 bpValue)
        internal
        pure
        returns (uint256)
    {
        return value.mul(bpValue).div(10000);
    }
}

library StringLibrary {
    using UintLibrary for uint256;

    function append(string memory a, string memory b)
        internal
        pure
        returns (string memory)
    {
        bytes memory ba = bytes(a);
        bytes memory bb = bytes(b);
        bytes memory bab = new bytes(ba.length + bb.length);
        uint256 k = 0;
        for (uint256 i = 0; i < ba.length; i++) bab[k++] = ba[i];
        for (uint256 i = 0; i < bb.length; i++) bab[k++] = bb[i];
        return string(bab);
    }

    function append(
        string memory a,
        string memory b,
        string memory c
    ) internal pure returns (string memory) {
        bytes memory ba = bytes(a);
        bytes memory bb = bytes(b);
        bytes memory bc = bytes(c);
        bytes memory bbb = new bytes(ba.length + bb.length + bc.length);
        uint256 k = 0;
        for (uint256 i = 0; i < ba.length; i++) bbb[k++] = ba[i];
        for (uint256 i = 0; i < bb.length; i++) bbb[k++] = bb[i];
        for (uint256 i = 0; i < bc.length; i++) bbb[k++] = bc[i];
        return string(bbb);
    }

    function recover(
        string memory message,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        bytes memory msgBytes = bytes(message);
        bytes memory fullMessage = concat(
            bytes("\x19Ethereum Signed Message:\n"),
            bytes(msgBytes.length.toString()),
            msgBytes,
            new bytes(0),
            new bytes(0),
            new bytes(0),
            new bytes(0)
        );
        return ecrecover(keccak256(fullMessage), v, r, s);
    }

    function concat(
        bytes memory ba,
        bytes memory bb,
        bytes memory bc,
        bytes memory bd,
        bytes memory be,
        bytes memory bf,
        bytes memory bg
    ) internal pure returns (bytes memory) {
        bytes memory resultBytes = new bytes(
            ba.length +
                bb.length +
                bc.length +
                bd.length +
                be.length +
                bf.length +
                bg.length
        );
        uint256 k = 0;
        for (uint256 i = 0; i < ba.length; i++) resultBytes[k++] = ba[i];
        for (uint256 i = 0; i < bb.length; i++) resultBytes[k++] = bb[i];
        for (uint256 i = 0; i < bc.length; i++) resultBytes[k++] = bc[i];
        for (uint256 i = 0; i < bd.length; i++) resultBytes[k++] = bd[i];
        for (uint256 i = 0; i < be.length; i++) resultBytes[k++] = be[i];
        for (uint256 i = 0; i < bf.length; i++) resultBytes[k++] = bf[i];
        for (uint256 i = 0; i < bg.length; i++) resultBytes[k++] = bg[i];
        return resultBytes;
    }
}

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */


abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return interfaceId == type(IERC165).interfaceId;
    }
}

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC1155Receiver).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

contract Ra8Bits is Context, Ownable, ERC1155Holder {
    using SafeMath for uint256;
    using StringLibrary for string;
    using BytesLibrary for bytes32;

    struct NFTInfo {
        uint256 parentA;
        uint256 parentB;
        string chromosome;
        uint256 score1;
        uint256 score2;
        uint256 score3;
        uint256 score4;
        uint256 breedCount;
        uint256 generation;
        uint256 costForBreed;
    }

    struct claimedNft {
        bool parentAClaimed;
        bool parentBClaimed;
    }

    struct tonkenSendForBreedingInfo {
        uint256 parentATokens;
        uint256 parentBTokens;
    }

    struct specialNftInfo {
        uint256 specialOfParentA;
        uint256 specialOfParentB;
        address specialtANFTAddress;
        address specialtBNFTBddress;
    }

    struct BreedInfo {
        uint256 breedId;
        uint256 parentA;
        address ownerOfParentA;
        address parentANFTAddress;
        address ownerOfParentB;
        address parentBNFTAddress;
        uint256 parentB;
        uint256 costParentA;
        uint256 costParentB;
        uint256 startTime;
        uint256 endTime;
        uint256 maxtier;
    }

    struct DiscountTier {
        uint256 tokensToStake;
        uint256 breedingTime;
        uint256 discount;
    }

    struct TokenListForBreedingInfoList {
        uint256 tokenId;
        uint256 tokenAmount;
    }

    mapping(uint256 => NFTInfo) public nftDetails;
    mapping(uint256 => bool) public isExist;
    mapping(uint256 => DiscountTier) public discountTierList;
    mapping(uint256 => BreedInfo) public breedInfoList;
    mapping(uint256 => claimedNft) public claimDetails;
    mapping(uint256 => specialNftInfo) public specialDetails;
    mapping(uint256 => tonkenSendForBreedingInfo) public tonkenSendForBreeding;
    mapping(uint256 => TokenListForBreedingInfoList) public TokenListForBreedingInfo;
    mapping(uint256 => uint256) public tierList;
    mapping(uint256 =>uint256) public isSuperliked;

    address public ratBitTokens = 0xae14cDD3824229a57902EeDA44106fC7a3B272E9;
    address public Gen0NFTAddress = 0xdd33c523D549d0739993F3e6c22D79a5f8Cc1fAA;
    address public tokenBurnAddress =0xdd33c523D549d0739993F3e6c22D79a5f8Cc1fAA;
    address public nftAddress = 0xdd33c523D549d0739993F3e6c22D79a5f8Cc1fAA;
    address public authAddress = 0x350F84C2f5272973646342Be1AdbE232324A552E;
    //variable which used to maintain SuperLike rules in  game
    uint256 public costForSuperLike = 10000000000;
    uint256 public amountForCarrotTier = 10000000000;
    uint256 public tokenAmountForSwiping = 10000000000;
    uint256 public timeLimitToRespond = 2 days;
    //superLikeList info (toNftId,userAddress,forNftId,NftAddrss)
    //Breeding
    uint256 public costForBreeding = 10000000000;
    uint256 public sendSpecialNftAmount = 10000000000;
    uint256 public waitForPartnerTime = 2 days;
    uint256 public breedingTime;
    mapping(address => mapping(uint256 => bool)) public isBreeding;
    uint256 public breedId = 1;
    uint256 public breedingTokenListId = 1;
    uint256 public _superLikeNFTId=0;

    //costCalculations
    uint256 public percentageForGenGap = 25;

    address public transferAddress;

   event superLike(uint256 indexed fromNftId,uint256 indexed toNftId,address fromAddress,uint256 time,address toNftAddress,uint256 costForSuperLike,uint256 seed,uint256 superLikeNFTId);
    event SuperLikeResponse(uint256 indexed fromNftId,uint256 indexed toNftId,address fromAddress,uint256 time,bool isAccepted,address toNftAddress,uint256 seed,uint256 superLikeNFTId);
    event ClaimPendingTokensFromSuperLike(uint256 indexed fromNftId,uint256 indexed toNftId,address fromAddress,uint256 time,uint256 tokenAmount,address toNftAddress,uint256 seed,uint256 superLikeNFTId);
    event BreedParentA(uint256 indexed parentA,uint256 indexed parentB,uint256 breedId,address user);
    event BreedParentB(uint256 indexed parentA,uint256 indexed parentB,uint256 breedId,address user);
    event WithdrawalNft(uint256 indexed breedId,address user,uint256 indexed nftId);
    event ClaimNft(uint256 indexed breedId,address user,uint256 indexed nftId);
    event SendSpecialNft(uint256 _breedId, uint256 specialNft, address user);
    event SendTokenToBreeding(uint256 _breedId,uint256 amount,uint256 tokenId,address user);
    event SendTokensForSwiping(address user,uint256 amount,uint256 indexed time);

    constructor(address _transferAddress) {
        transferAddress = _transferAddress;
        discountTierList[0].tokensToStake = 1000000000;
        discountTierList[0].breedingTime = 2 days;
        discountTierList[0].discount = 10;
    }

    function superLikeNFT(uint256 fromNftId,address formNftAddress,uint256 toNftId,address toNftAddress,uint256 seed,uint8 v,bytes32 r,bytes32 s) external {
        
        require(IERC20(ratBitTokens).transferFrom(_msgSender(),address(this),costForSuperLike));
        emit superLike(fromNftId,toNftId,_msgSender(),block.timestamp,toNftAddress,costForSuperLike,seed,_superLikeNFTId);
        isSuperliked[_superLikeNFTId]=costForSuperLike;
        _superLikeNFTId=_superLikeNFTId.add(1);
    }

    function acceptSuperLike(
        uint256 fromNftId,
        address formNftAddress,
        uint256 toNftId,
        address toNftAddress,
        uint256 seed,
        uint256 superLikeNFTId,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        string memory hash = keccak256(abi.encode(fromNftId,formNftAddress,toNftId,toNftAddress,superLikeNFTId,seed,_msgSender())).toString();
        address signer = hash.recover(v, r, s);
        require(signer == authAddress, "Invalid signature");
        require(isSuperliked[superLikeNFTId]>0,"super like already accepted");
        require(IERC20(ratBitTokens).transfer(_msgSender(),costForSuperLike.div(50)));
        require(IERC20(ratBitTokens).transfer(tokenBurnAddress,costForSuperLike.div(25)));
        require(IERC20(ratBitTokens).transfer(transferAddress,costForSuperLike.div(25)));
        isSuperliked[superLikeNFTId]=0;
        emit SuperLikeResponse(fromNftId,toNftId,_msgSender(),block.timestamp,true,toNftAddress,seed,superLikeNFTId);
    }

    function rejectSuperLike(
        uint256 fromNftId,
        address formNftAddress,
        uint256 toNftId,
        address toNftAddress,
        uint256 seed,
        uint256 superLikeNFTId,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        string memory hash = keccak256(abi.encode(fromNftId,formNftAddress,toNftId,toNftAddress,seed,superLikeNFTId,_msgSender())).toString();
        address signer = hash.recover(v, r, s);
        require(signer == authAddress, "Invalid signature");
        require(isSuperliked[superLikeNFTId]>0,"super like already accepted");
        require((IERC1155(toNftAddress).balanceOf(_msgSender(), toNftId) > 0),"You are not owner of NFT");
        require(IERC20(ratBitTokens).transfer(formNftAddress, costForSuperLike));
        isSuperliked[superLikeNFTId]=0;
        emit SuperLikeResponse(fromNftId,toNftId,_msgSender(),block.timestamp,false,toNftAddress,seed,superLikeNFTId);
    }

    function claimPendingTokensFromSuperLike(
        uint256 fromNftId,
        address formNftAddress,
        uint256 toNftId,
        address toNftAddress,
        uint256 seed,
        uint256 superLikeNFTId,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        string memory hash = keccak256(abi.encode(fromNftId,formNftAddress,toNftId,toNftAddress,seed,superLikeNFTId,_msgSender())).toString();
        address signer = hash.recover(v, r, s);
        require(signer == authAddress, "Invalid signature");
        require(isSuperliked[superLikeNFTId]>0,"super like already accepted");
        require((IERC1155(toNftAddress).balanceOf(_msgSender(), fromNftId) > 0),"You are not owner of NFT");
        require(IERC20(ratBitTokens).transfer(formNftAddress, isSuperliked[superLikeNFTId]));
        isSuperliked[superLikeNFTId]=0;
        emit ClaimPendingTokensFromSuperLike(fromNftId,toNftId,_msgSender(),block.timestamp,isSuperliked[superLikeNFTId],toNftAddress,seed,superLikeNFTId);
    }

    function calculateTimeAndDiscount(uint256 tier)internal view returns (uint256)
    {
        require(discountTierList[tier].breedingTime > 0, "Invalid tier");
        return discountTierList[tier].discount;
    }

    function calculateCostforBreeding(uint256 parentA, uint256 parentB) internal view returns (uint256 amount)
    {
        uint256 genGap = 0;
        if (nftDetails[parentA].generation > nftDetails[parentB].generation) {
            genGap = nftDetails[parentA].generation.sub(nftDetails[parentB].generation);
        } else if (nftDetails[parentA].generation < nftDetails[parentB].generation) {
            genGap = nftDetails[parentB].generation.sub(nftDetails[parentA].generation);
        }
        if (genGap == 0) {
            return (costForBreeding);
        } else {
            return (costForBreeding).mul(genGap.mul(percentageForGenGap)).div(100);
        }
    }

    function calculateCost(
        uint256 parentA,
        uint256 parentB,
        uint256 tier,
        bool isPaying
    ) public view returns (uint256) {
        if (isPaying) {
            uint256 _costForBreeding = costForBreeding.add(
                calculateCostforBreeding(parentA, parentB)
            );
            uint256 discount = calculateTimeAndDiscount(tier);
            if (discount > 0) return _costForBreeding.mul(discount).div(100);
            else {
                return _costForBreeding;
            }
        } else {
            return 0;
        }
    }

    function sendToBreedingRoomFirst(
        uint256 parentA,
        uint256 parentB,
        uint256 tier,
        address NFTAddress,
        bool isPaying
    ) external {
        uint256 finalCost = calculateCost(parentA, parentB, tier, isPaying);
        require(
            IERC20(ratBitTokens).transferFrom(
                _msgSender(),
                address(this),
                finalCost
            )
        );
        require(!isBreeding[NFTAddress][parentA], "NFT is already in breeding");
        IERC1155(NFTAddress).safeTransferFrom(_msgSender(),address(this),parentA,1,"0x");
        isBreeding[NFTAddress][parentA] = true;
        BreedInfo memory details = BreedInfo({
            breedId: breedId,
            parentA: parentA,
            parentANFTAddress: NFTAddress,
            ownerOfParentB: address(0),
            parentBNFTAddress: address(0),
            parentB: parentB,
            ownerOfParentA: _msgSender(),
            costParentA: finalCost,
            costParentB: 0,
            startTime: block.timestamp,
            endTime: block.timestamp,
            maxtier: tier
        });
        breedInfoList[breedId] = details;
        emit BreedParentA(parentA, parentB, breedId, _msgSender());
        breedId = breedId.add(1);
    }

    function sendToBreedingRoomSecond(
        uint256 tier,
        uint256 _breedId,
        address NFTAddress,
        bool isPaying
    ) external {
        require(checkValidBid(_breedId), "Invalid id");
        IERC1155(NFTAddress).safeTransferFrom(_msgSender(),address(this),breedInfoList[_breedId].parentB,1,"");
        isBreeding[NFTAddress][breedInfoList[_breedId].parentB] = true;
        uint256 finalCost = calculateCost(breedInfoList[_breedId].parentA,breedInfoList[_breedId].parentB,tier,isPaying);
        require(IERC20(ratBitTokens).transferFrom(_msgSender(),address(this),finalCost));
        uint256 _breedingTime = breedingTime;
        if (
            discountTierList[breedInfoList[_breedId].maxtier].breedingTime <
            discountTierList[tier].breedingTime
        ) {
            _breedingTime = discountTierList[breedInfoList[_breedId].maxtier]
                .breedingTime;
        } else {
            _breedingTime = discountTierList[tier].breedingTime;
        }
        breedInfoList[_breedId].endTime = block.timestamp.add(_breedingTime);
        breedInfoList[_breedId].ownerOfParentB = _msgSender();
        breedInfoList[_breedId].parentBNFTAddress = NFTAddress;
        breedInfoList[_breedId].costParentB = finalCost;
        emit BreedParentB(breedInfoList[_breedId].parentA,breedInfoList[_breedId].parentB,_breedId,_msgSender());
    }

    function checkValidBid(uint256 _breedId) public view returns (bool) {
        if (breedInfoList[_breedId].ownerOfParentA == _msgSender() || breedInfoList[_breedId].ownerOfParentB == _msgSender()) 
        return true;
        else
         return false;
    }

    function isBreedingStart(uint256 _breedId) public view returns (bool) {
        if (breedInfoList[_breedId].ownerOfParentA == _msgSender() || breedInfoList[_breedId].ownerOfParentB == _msgSender()) 
        return true;
        else
         return false;
    }

    function getNewGeneration(
        uint256 parentAGeneration,
        uint256 parentBGeneration
    ) internal pure returns (uint256) {
        if (parentAGeneration > parentBGeneration) {
            return parentAGeneration + 1;
        } else {
            return parentBGeneration + 1;
        }
    }

    function sendTokensForSwiping() external {
        require(IERC20(ratBitTokens).transferFrom(_msgSender(),transferAddress,tokenAmountForSwiping));
        emit SendTokensForSwiping(_msgSender(),tokenAmountForSwiping,block.timestamp);
    }

    function withdrawalNft(uint256 _breedId) public {
        require(checkValidBid(_breedId), "Invalid id");
        BreedInfo memory details = breedInfoList[_breedId];
        require(
            details.endTime < block.timestamp,
            "Need to wait at least two days"
        );
        if (details.ownerOfParentA == _msgSender()) {
            require(!claimDetails[_breedId].parentAClaimed, "Allready claimed");
            require(
                isBreeding[details.parentANFTAddress][details.parentA],
                "Breeding is on"
            );
            claimDetails[_breedId].parentAClaimed = true;
            isBreeding[details.parentANFTAddress][details.parentA] = false;
            IERC1155(Gen0NFTAddress).safeTransferFrom(
                address(this),
                _msgSender(),
                details.parentA,
                1,
                ""
            );
            emit WithdrawalNft(_breedId, _msgSender(), details.parentA);
        } else {
            require(!claimDetails[_breedId].parentBClaimed, "Allready claimed");
            require(
                isBreeding[details.parentBNFTAddress][details.parentB],
                "Breeding is on"
            );
            isBreeding[details.parentANFTAddress][details.parentB] = false;
            claimDetails[_breedId].parentBClaimed = true;
            IERC1155(Gen0NFTAddress).safeTransferFrom(
                address(this),
                _msgSender(),
                details.parentB,
                1,
                ""
            );
            emit WithdrawalNft(_breedId, _msgSender(), details.parentB);
        }
    }

    function sendSpecialNft(
        uint256 _breedId,
        uint256 specialNft,
        address specialtANFTAddress
    ) public {
        require(checkValidBid(_breedId), "Invalid id");
        require(
            !isBreeding[specialtANFTAddress][specialNft],
            "Nft is using for Breeding"
        );
        require(
            breedInfoList[_breedId].endTime > block.timestamp,
            "breeding is end"
        );
        require(
            IERC20(ratBitTokens).balanceOf(_msgSender()) > amountForCarrotTier,
            "need  Carrot Tier"
        );
        require(
            IERC20(ratBitTokens).transferFrom(
                _msgSender(),
                transferAddress,
                sendSpecialNftAmount
            )
        );
        IERC1155(specialtANFTAddress).safeTransferFrom(
            _msgSender(),
            address(this),
            specialNft,
            1,
            "0x"
        );
        if (breedInfoList[_breedId].ownerOfParentA == _msgSender()) {
            require(
                specialDetails[_breedId].specialOfParentA < 1,
                "only one Special Nft for breeding"
            );
            specialDetails[_breedId].specialOfParentA = specialNft;
            specialDetails[_breedId].specialtANFTAddress = specialtANFTAddress;
        } else {
            require(
                specialDetails[_breedId].specialOfParentA < 1,
                "only one Special Nft for breeding"
            );
            specialDetails[_breedId].specialOfParentB = specialNft;
            specialDetails[_breedId].specialtBNFTBddress = specialtANFTAddress;
        }
        emit SendSpecialNft(_breedId, specialNft, _msgSender());
    }

    function sendTokenToBreeding(uint256 _breedId) public {
        require(checkValidBid(_breedId), "Invalid id");
        require(
            breedInfoList[_breedId].endTime > block.timestamp,
            "breeding is end"
        );
        if (breedInfoList[_breedId].ownerOfParentA == _msgSender()) {
            require(
                tonkenSendForBreeding[_breedId].parentATokens < 1,
                "Token already send"
            );
            require(
                IERC20(ratBitTokens).transferFrom(
                    _msgSender(),
                    transferAddress,
                    TokenListForBreedingInfo[0].tokenAmount
                )
            );
            tonkenSendForBreeding[_breedId]
                .parentATokens = TokenListForBreedingInfo[0].tokenAmount;
        } else {
            require(
                tonkenSendForBreeding[_breedId].parentBTokens < 1,
                "Token already send"
            );
            require(
                IERC20(ratBitTokens).transferFrom(
                    _msgSender(),
                    transferAddress,
                    TokenListForBreedingInfo[0].tokenAmount
                )
            );
            tonkenSendForBreeding[_breedId]
                .parentBTokens = TokenListForBreedingInfo[0].tokenAmount;
        }
        emit SendTokenToBreeding(
            _breedId,
            TokenListForBreedingInfo[0].tokenAmount,
            0,
            _msgSender()
        );
    }

    function claimNft(uint256 _breedId) public {
        require(checkValidBid(_breedId), "Invalid id");
        BreedInfo memory details = breedInfoList[_breedId];
        require(
            details.endTime < block.timestamp,
            "Need to wait at least two days"
        );
        if (details.ownerOfParentA == _msgSender()) {
            sendNftToUser(
                claimDetails[_breedId].parentAClaimed,
                details.parentANFTAddress,
                details.parentA
            );
            claimDetails[_breedId].parentAClaimed = true;
            if (specialDetails[_breedId].specialOfParentA < 1) {
                IERC1155(specialDetails[_breedId].specialtANFTAddress)
                    .safeTransferFrom(
                        address(this),
                        _msgSender(),
                        specialDetails[_breedId].specialOfParentA,
                        1,
                        ""
                    );
            }
            if (details.costParentA < 1) {
                require(
                    IERC20(ratBitTokens).transferFrom(
                        address(this),
                        _msgSender(),
                        details.costParentB.div(50)
                    )
                );
            }
            // else{

            // }
            emit ClaimNft(_breedId, _msgSender(), details.parentA);
        } else {
            sendNftToUser(
                claimDetails[_breedId].parentAClaimed,
                details.parentBNFTAddress,
                details.parentB
            );
            claimDetails[_breedId].parentBClaimed = true;
            if (specialDetails[_breedId].specialOfParentB < 1) {
                IERC1155(specialDetails[_breedId].specialtBNFTBddress)
                    .safeTransferFrom(
                        address(this),
                        _msgSender(),
                        specialDetails[_breedId].specialOfParentB,
                        1,
                        ""
                    );
            }
            if (details.costParentA < 1) {
                require(
                    IERC20(ratBitTokens).transferFrom(
                        address(this),
                        _msgSender(),
                        details.costParentA.div(50)
                    )
                );
            }
            // else{

            // }
            emit ClaimNft(_breedId, _msgSender(), details.parentB);
        }
    }

    function addTokenListForBreeding(uint256 _tokenAmount) external onlyOwner {
        TokenListForBreedingInfoList
            memory tokenDetails = TokenListForBreedingInfoList({
                tokenId: breedingTokenListId,
                tokenAmount: _tokenAmount
            });
        TokenListForBreedingInfo[breedingTokenListId] = tokenDetails;
        breedingTokenListId = breedingTokenListId.add(1);
    }

    function changeTireAmount(uint256 tierId, uint256 amount)
        external
        onlyOwner
    {
        tierList[tierId] = amount;
    }

    function sendNftToUser(
        bool parentClaimed,
        address parentNFTAddress,
        uint256 NftId
    ) internal {
        require(!parentClaimed, "Allready claimed");
        require(isBreeding[parentNFTAddress][NftId], "Breeding is on");
        isBreeding[parentNFTAddress][NftId] = false;
        IERC1155(parentNFTAddress).safeTransferFrom(
            address(this),
            _msgSender(),
            NftId,
            1,
            ""
        );
    }

    function setCostForSuperLike(uint256 _cost) external onlyOwner {
        costForSuperLike = _cost;
    }

    function setTimeLimitSuperLike(uint256 _timespan) external onlyOwner {
        timeLimitToRespond = _timespan;
    }

    function setCostForBreeding(uint256 _cost) external onlyOwner {
        costForBreeding = _cost;
    }

    function setWaitTimeForBreeding(uint256 _timespan) external onlyOwner {
        waitForPartnerTime = _timespan;
    }

    function setBreedingTime(uint256 _timespan) external onlyOwner {
        breedingTime = _timespan;
    }

    function checkNFTAddress(address NFTAddress) internal view returns (bool) {
        return (Gen0NFTAddress == NFTAddress || nftAddress == NFTAddress);
    }

    function setRatBitTokens(address _address) external onlyOwner {
        require(_address != address(0));
        ratBitTokens = _address;
    }

    function setGen0NFTAddress(address _address) external onlyOwner {
        require(_address != address(0));
        Gen0NFTAddress = _address;
    }

    function setTokenBurnAddress(address _address) external onlyOwner {
        require(_address != address(0));
        tokenBurnAddress = _address;
    }

    function setAuthAddress(address _address) external onlyOwner {
        require(_address != address(0));
        authAddress = _address;
    }

    function setNftAddress(address _address) external onlyOwner {
        require(_address != address(0));
        nftAddress = _address;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

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
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
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
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

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