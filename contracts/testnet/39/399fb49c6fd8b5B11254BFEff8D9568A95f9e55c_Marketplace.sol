// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./IMarketplace.sol";

contract Marketplace is Ownable, Pausable, IMarketplace {
    using Address for address;
    using SafeMath for uint256;
    //using SafeERC20 for IERC20;

    address public weth;
    address public acceptedToken;
    uint256 public buyFeePerMillion; // 10% cut
    uint256 public sellFeePerMillion;
    address private adminAddress;

    // From ERC721 registry assetId to Order (to avoid asset collision)
    mapping(address => mapping(uint256 => Order)) public orderByAssetId;

    // From ERC721 registry assetId to Bid (to avoid asset collision)
    // mapping(address => mapping(uint256 => Bid)) public bidByOrderId;

    // 721 Interfaces
    bytes4 public constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    /**
     * @dev Initialize this contract. Acts as a constructor
     * @param _weth- eth currency for payments
     */
    constructor(address _weth) {
        weth = _weth;
        // acceptedTokens.push(_weth);
        acceptedToken = _weth;
        buyFeePerMillion = 100000;
        sellFeePerMillion = 100000;
        adminAddress = msg.sender;
    }

    // function setWETH(address _weth) public onlyOwner {
    //     weth = _weth;
    //     acceptedTokens.push(_weth);
    // }

    // function addAcceptedToken(address _acceptedToken) public onlyOwner {
    //     acceptedTokens.push(_acceptedToken);
    // }

    // function removeAcceptedToken(uint256 tokenIndex) public onlyOwner {
    //     acceptedTokens[tokenIndex] = acceptedTokens[acceptedTokens.length - 1];
    //     acceptedTokens.pop();
    // }

    function setSellFee(uint256 _sellFee) public onlyOwner {
        sellFeePerMillion = _sellFee;
    }

    function setBuyFee(uint256 _sellFee) public onlyOwner {
        buyFeePerMillion = _sellFee;
    }

    // function setRoyalty(address _nftAddress, uint256 fee) external {
    //     address collectionOwner;
    //     try Ownable(_nftAddress).owner() returns (address owner) {
    //         collectionOwner = owner;
    //     } catch {}

    //     require(
    //         collectionOwner == msg.sender,
    //         "You should be owner of this contract"
    //     );
    //     require(fee <= maxRoyaltyPerMillion, "Invald fee amount");
    //     royaltyPerMillions[_nftAddress] = fee;
    // }

    /**
     * @dev Sets the paused failsafe. Can only be called by owner
     * @param _setPaused - paused state
     */
    function setPaused(bool _setPaused) public onlyOwner {
        return (_setPaused) ? _pause() : _unpause();
    }

    // function isAcceptedToken(address _addr) public view returns (bool){
    //     bool isExist = false;
    //     for(uint256 i=0; i<acceptedTokens.length; i++){
    //         if(acceptedTokens[i] == _addr){
    //             isExist == true;
    //         }
    //     }

    //     return isExist;
    // }


    /**
     * @dev Creates a new order
     * @param _nftAddress - Non fungible registry address
     * @param _assetId - ID of the published NFT
     * @param _acceptedToken - accepted token to buy NFT
     * @param _price - Price in Wei for the supported coin
     * @param _expiresAt - Duration of the order (in hours)
     */
    function createOrder(
        address _nftAddress,
        address owner,
        uint256 _assetId,
        address _acceptedToken,
        uint256 _price,
        uint256 _expiresAt,
        address daddr
    ) public override whenNotPaused {
        // bool isExist = isAcceptedToken(_acceptedToken);
        // require(isExist, "Your acceptedToken is invalid.");
        address directAddress;
        if(daddr != owner){
            directAddress = daddr;
        }
        else{
            directAddress = address(0);
        }


        uint256 buyShareAmount = _price.mul(sellFeePerMillion).div(1e6);
        uint256 approved_amount = IERC20(_acceptedToken).allowance(msg.sender, address(this));
        require(approved_amount >= buyShareAmount, "The approved amount should be more than sell fee");
        bool suc = IERC20(_acceptedToken).transferFrom(msg.sender, address(this), buyShareAmount);
        require(suc == true, "You should pay sell fee");


        _createOrder(
            _nftAddress,
            owner,
            _assetId,
            _acceptedToken,
            _price,
            _expiresAt,
            directAddress
        );
    }

    /**
     * @dev Cancel an already published order
     *  can only be canceled by seller or the contract owner
     * @param _nftAddress - Address of the NFT registry
     * @param _assetId - ID of the published NFT
     */
    function cancelOrder(address _nftAddress, uint256 _assetId)
        public
        whenNotPaused
    {
        Order memory order = orderByAssetId[_nftAddress][_assetId];
        require(
            order.seller == msg.sender || msg.sender == owner(),
            "Marketplace: unauthorized sender"
        );

        // Remove pending bid if any
        // Bid memory bid = bidByOrderId[_nftAddress][_assetId];   kpr_bid

        // if (bid.id != 0) {
        //     _cancelBid(bid.id, _nftAddress, _assetId, bid.bidder, bid.price);
        // }

        // Cancel order.
        _cancelOrder(order.id, _nftAddress, _assetId, msg.sender);
    }

    /**
     * @dev Update an already published order
     *  can only be updated by seller
     * @param _nftAddress - Address of the NFT registry
     * @param _assetId - ID of the published NFT
     */
    function updateOrder(
        address _nftAddress,
        uint256 _assetId,
        uint256 _price,
        uint256 _expiresAt
    ) public whenNotPaused {
        Order memory order = orderByAssetId[_nftAddress][_assetId];

        // Check valid order to update
        require(order.id != 0, "Marketplace: asset not published");
        require(order.seller == msg.sender, "Marketplace: sender not allowed");
        require(
            order.expiresAt >= block.timestamp,
            "Marketplace: order expired"
        );

        // check order updated params
        require(_price > 0, "Marketplace: Price should be bigger than 0");
        require(
            _expiresAt > block.timestamp.add(1 minutes),
            "Marketplace: Expire time should be more than 1 minute in the future"
        );

        order.price = _price;
        order.expiresAt = _expiresAt;

        emit OrderUpdated(order.id, _price, _expiresAt);
    }

    /**
     * @dev Executes the sale for a published NFT and checks for the asset fingerprint
     * @param _nftAddress - Address of the NFT registry
     * @param _assetId - ID of the published NFT
     * @param _price - Order price
     */
    function ExecuteOrder(
        address _nftAddress,
        uint256 _assetId,
        uint256 _price
    ) public whenNotPaused {
        // Get the current valid order for the asset or fail
        Order memory order = _getValidOrder(_nftAddress, _assetId);
        address buyer;

        // Check the execution price matches the order price
        // require(order.price == _price, "Marketplace: invalid price");
        // if (order.acceptedToken == weth) {
        //     require(order.price == msg.value, "Marketplace: invalid price");
        // }

        // calc market fees
        if(order.daddr == address(0)){
            buyer = msg.sender;
        }else{
            require(order.daddr == msg.sender, "Your address is disabled");
            buyer = msg.sender;
        }

        uint256 saleShareAmount = _price.mul(buyFeePerMillion).div(1e6);
        uint256 total_price = _price + saleShareAmount;
        uint256 approved_amount = IERC20(order.acceptedToken).allowance(msg.sender, address(this));
        require(approved_amount >= total_price, "The approved amount should be more than buy fee.");
        bool success_transform = IERC20(order.acceptedToken).transferFrom(msg.sender, address(this), total_price);
        require(success_transform == true, "You should pay buy fee");

        bool success_transform_seller = IERC20(order.acceptedToken).transfer(order.seller, _price);
        require(success_transform_seller == true, "You should pay price");

        // royalty
        // uint256 royaltyAmount = _price
        //     .mul(FeeManager.royaltyPerMillions[_nftAddress])
        //     .div(1e6);

        // address collectionOwner;
        // try Ownable(_nftAddress).owner() returns (address owner) {
        //     collectionOwner = owner;
        // } catch {}

        // if (royaltyAmount != 0) {
        //     if (order.acceptedToken == weth) {
        //         payable(collectionOwner).transfer(royaltyAmount);
        //     } else {
        //         IERC20(order.acceptedToken).transferFrom(
        //             msg.sender, //buyer
        //             collectionOwner,
        //             royaltyAmount
        //         );
        //     }
        // }
        // Transfer accepted token amount minus market fee to seller

        // if (order.acceptedToken == weth) {
        //     payable(owner()).transfer(saleShareAmount);
        //     // payable(order.seller).transfer(
        //     //     order.price.sub(saleShareAmount).sub(royaltyAmount)
        //     // );
        // } else {
        //     // Transfer share amount for marketplace Owner
        //     IERC20(order.acceptedToken).transferFrom(
        //         msg.sender, //buyer
        //         owner(),
        //         saleShareAmount
        //     );
        //     // IERC20(order.acceptedToken).transferFrom(
        //     //     msg.sender, //buyer
        //     //     order.seller, // seller
        //     //     order.price.sub(saleShareAmount).sub(royaltyAmount)
        //     // );
        // }

        // Remove pending bid if any
        // Bid memory bid = bidByOrderId[_nftAddress][_assetId];   kpr_bid

        // if (bid.id != 0) {
        //     _cancelBid(bid.id, _nftAddress, _assetId, bid.bidder, bid.price);
        // }

        _executeOrder(
            order.id,
            buyer, // buyer
            _nftAddress,
            _assetId,
            _price
        );
    }

    address public adminAddress_test;


    mapping(uint256 => Order) public enableMultiOrder;
    mapping(uint256 => Order) public disableMultiOrder;
    address[] public seller;
    /**
    * @dev multi-NFT sale
    */

    // struct BatchOrder {
    //     address nftAddress;
    //     uint256 assetId;
    //     uint256 price;
    // }

    function multiSale(
        address[] calldata nftAddressArray,
        uint256[] calldata assetIdArray,
        uint256[] calldata priceArray
    ) public whenNotPaused {
        uint256 count_price = 0;

        Order memory order0 = _getValidOrder(nftAddressArray[0], assetIdArray[0]);

        for(uint256 i = 0; i < priceArray.length; i++){
            count_price += priceArray[i];

            Order memory order = _getValidOrder(nftAddressArray[i], assetIdArray[i]);
            seller.push(order.seller);
        }

        uint256 saleShareAmount = count_price.mul(buyFeePerMillion).div(1e6);
        uint256 total_price = count_price + saleShareAmount;

        uint256 approved_amount = IERC20(order0.acceptedToken).allowance(msg.sender, address(this));
        require(approved_amount >= total_price, "The approved amount should be more than buy fee.");

        bool success_transform_totalPrice = IERC20(order0.acceptedToken).transferFrom(msg.sender, address(this), total_price);
        require(success_transform_totalPrice == true, "You should pay buy fee");

        for(uint256 i = 0 ; i<assetIdArray.length; i++){
            bool success_transform_seller = IERC20(order0.acceptedToken).transfer(seller[i], priceArray[i]);
            require(success_transform_seller == true, "You should pay price");
        }

        for(uint256 i = 0 ; i<assetIdArray.length; i++){
            delete orderByAssetId[nftAddressArray[i]][assetIdArray[i]];
            IERC721(nftAddressArray[i]).transferFrom(address(this), msg.sender, assetIdArray[i]);
        }

        emit MultiOrderSuccessful(assetIdArray.length, count_price);
    }

    /**
     * @dev Drectly transform between seller and buyer
     * @param daddr buyer address
    */

    function directSale(
        address daddr,
        address _nftAddress,
        uint256 _assetId,
        address _acceptedToken,
        uint256 _price
    ) public payable whenNotPaused {
        Order memory order = _getValidOrder(_nftAddress, _assetId);

        // bool isExistAcceptedToken = isAcceptedToken(_acceptedToken);
        // require(isExistAcceptedToken == true, "Your acceptedToken doesn't exist.");

        uint256 approved_amount = IERC20(_acceptedToken).allowance(msg.sender, daddr);
        require(approved_amount >= _price, "The approved amount should be more than price");
        bool suc = IERC20(_acceptedToken).transferFrom(daddr, msg.sender, _price);
        require(suc == true, "You should pay price.");
        _executeOrder(
            order.id,
            daddr,
            _nftAddress,
            _assetId,
            _price
        );
    }

    /**
     * @dev Places a bid for a published NFT and checks for the asset fingerprint
     * @param _nftAddress - Address of the NFT registry
     * @param _assetId - ID of the published NFT
     * @param _price - Bid price in weth currency
     * @param _expiresAt - Bid expiration time
     */
    // function PlaceBid(
    //     address _nftAddress,
    //     uint256 _assetId,
    //     uint256 _price,
    //     uint256 _expiresAt
    // ) public payable whenNotPaused {
    //     _createBid(_nftAddress, _assetId, _price, _expiresAt);
    // }

    /**
     * @dev Cancel an already published bid
     *  can only be canceled by seller or the contract owner
     * @param _nftAddress - Address of the NFT registry
     * @param _assetId - ID of the published NFT
     */
    // function cancelBid(address _nftAddress, uint256 _assetId)            kpr_bid
    //     public
    //     whenNotPaused
    // {
    //     Bid memory bid = bidByOrderId[_nftAddress][_assetId];

    //     require(
    //         bid.bidder == msg.sender || msg.sender == owner(),
    //         "Marketplace: Unauthorized sender"
    //     );

    //     _cancelBid(bid.id, _nftAddress, _assetId, bid.bidder, bid.price);
    // }

    /**
     * @dev Executes the sale for a published NFT by accepting a current bid
     * @param _nftAddress - Address of the NFT registry
     * @param _assetId - ID of the published NFT
     * @param _price - Bid price in wei in acceptedTokens currency
     */
    // function acceptBid(          kpr_bid
    //     address _nftAddress,
    //     uint256 _assetId,
    //     uint256 _price
    // ) public whenNotPaused {
    //     // check order validity
    //     Order memory order = _getValidOrder(_nftAddress, _assetId);

    //     // item seller is the only allowed to accept a bid
    //     require(order.seller == msg.sender, "Marketplace: unauthorized sender");

    //     Bid memory bid = bidByOrderId[_nftAddress][_assetId];

    //     require(bid.price == _price, "Marketplace: invalid bid price");
    //     require(
    //         bid.expiresAt >= block.timestamp,
    //         "Marketplace: the bid expired"
    //     );

    //     // remove bid
    //     delete bidByOrderId[_nftAddress][_assetId];

    //     emit BidAccepted(bid.id);

    //     // calc market fees
    //     uint256 saleShareAmount = bid.price.mul(FeeManager.cutPerMillion).div(
    //         1e6
    //     );

    //     // royalty
    //     uint256 royaltyAmount = _price
    //         .mul(FeeManager.royaltyPerMillions[_nftAddress])
    //         .div(1e6);

    //     address collectionOwner;
    //     try Ownable(_nftAddress).owner() returns (address owner) {
    //         collectionOwner = owner;
    //     } catch {}

    //     if (royaltyAmount != 0) {
    //         if (order.acceptedToken == weth) {
    //             payable(collectionOwner).transfer(royaltyAmount);
    //         } else {
    //             IERC20(order.acceptedToken).transferFrom(
    //                 msg.sender, //buyer
    //                 collectionOwner,
    //                 royaltyAmount
    //             );
    //         }
    //     }
    //     if (order.acceptedToken == weth) {
    //         payable(owner()).transfer(saleShareAmount);
    //     } else {
    //         // Transfer share amount for marketplace Owner
    //         IERC20(order.acceptedToken).transferFrom(
    //             msg.sender, //buyer
    //             owner(),
    //             saleShareAmount
    //         );
    //     }

    //     // transfer escrowed bid amount minus market fee to seller
    //     if (order.acceptedToken == weth) {
    //         payable(order.seller).transfer(bid.price.sub(saleShareAmount));
    //     } else {
    //         // Transfer share amount for marketplace Owner
    //         IERC20(order.acceptedToken).transferFrom(
    //             msg.sender, //buyer
    //             order.seller, // seller
    //             bid.price.sub(saleShareAmount)
    //         );
    //     }

    //     _executeOrder(order.id, bid.bidder, _nftAddress, _assetId, _price);
    // }

    /**
     * @dev Internal function gets Order by nftRegistry and assetId. Checks for the order validity
     * @param _nftAddress - Address of the NFT registry
     * @param _assetId - ID of the published NFT
     */

    function _getValidOrder(address _nftAddress, uint256 _assetId)
        internal
        view
        returns (Order memory order)
    {
        order = orderByAssetId[_nftAddress][_assetId];

        require(order.id != 0, "Marketplace: asset not published");
        require(
            order.expiresAt >= block.timestamp,
            "Marketplace: order expired"
        );
    }

    /**
     * @dev Executes the sale for a published NFT
     * @param _orderId - Order Id to execute
     * @param _buyer - address
     * @param _nftAddress - Address of the NFT registry
     * @param _assetId - NFT id
     * @param _price - Order price
     */
    function _executeOrder(
        bytes32 _orderId,
        address _buyer,
        address _nftAddress,
        uint256 _assetId,
        uint256 _price
    ) internal {
        // remove order
        delete orderByAssetId[_nftAddress][_assetId];

        // Transfer NFT asset
        IERC721(_nftAddress).transferFrom(address(this), _buyer, _assetId);

        // Notify ..
        emit OrderSuccessful(_orderId, _buyer, _price);
    }

    /**
     * @dev Creates a new order
     * @param _nftAddress - Non fungible registry address
     * @param _assetId - ID of the published NFT
     * @param _price - Price in Wei for the supported coin
     * @param _expiresAt - Expiration time for the order
     */

    
    function _createOrder(
        address _nftAddress,
        address _owner,
        uint256 _assetId,
        address _acceptedToken,
        uint256 _price,
        uint256 _expiresAt,
        address _daddr
    ) internal {
        // Check nft registry
        IERC721 nftRegistry = _requireERC721(_nftAddress);

        // Check order creator is the asset owner
        address assetOwner = nftRegistry.ownerOf(_assetId);

        require(
            assetOwner == msg.sender,
            "Marketplace: Only the asset owner can create orders"
        );

        require(_price > 0, "Marketplace: Price should be bigger than 0");

        require(
            _expiresAt > block.timestamp.add(1 minutes),
            "Marketplace: Publication should be more than 1 minute in the future"
        );

        // get NFT asset from seller

        IERC721(nftRegistry).transferFrom(assetOwner, address(this), _assetId);

        // create the orderId
        bytes32 orderId = keccak256(
            abi.encodePacked(
                block.timestamp,
                _owner,
                _nftAddress,
                _assetId,
                _acceptedToken,
                _price,
                _daddr
            )
        );

        // save order
        orderByAssetId[_nftAddress][_assetId] = Order({
            id: orderId,
            seller: _owner,
            nftAddress: _nftAddress,
            acceptedToken: _acceptedToken,
            price: _price,
            expiresAt: _expiresAt,
            daddr : _daddr
        });

        emit OrderCreated(
            orderId,
            _owner,
            _nftAddress,
            _assetId,
            _acceptedToken,
            _price,
            _expiresAt,
            _daddr
        );
    }

    /**
     * @dev Creates a new bid on a existing order
     * @param _nftAddress - Non fungible registry address
     * @param _assetId - ID of the published NFT
     * @param _price - Price in Wei for the supported coin
     * @param _expiresAt - expires time
     */
    // function _createBid(             
    //     address _nftAddress,
    //     uint256 _assetId,
    //     uint256 _price,
    //     uint256 _expiresAt
    // ) internal {
    //     // Checks order validity
    //     Order memory order = _getValidOrder(_nftAddress, _assetId);

    //     uint256 expiresAt = _expiresAt;
    //     // check on expire time
    //     if (_expiresAt > order.expiresAt) {
    //         expiresAt = order.expiresAt;
    //     }

    //     // Check price if theres previous a bid
    //     Bid memory bid = bidByOrderId[_nftAddress][_assetId];

    //     // if theres no previous bid, just check price > 0
    //     if (bid.id != 0) {
    //         if (bid.expiresAt >= block.timestamp) {
    //             require(
    //                 _price > bid.price,
    //                 "Marketplace: bid price should be higher than last bid"
    //             );
    //         } else {
    //             require(_price > 0, "Marketplace: bid should be > 0");
    //         }

    //         _cancelBid(bid.id, _nftAddress, _assetId, bid.bidder, bid.price);
    //     } else {
    //         require(_price > 0, "Marketplace: bid should be > 0");
    //     }

    //     // Transfer sale amount from bidder to escrow
    //     if (order.acceptedToken == weth)
    //         require(msg.value == _price, "invalid value for price");
    //     else
    //         IERC20(order.acceptedToken).transferFrom(
    //             msg.sender, // bidder
    //             address(this),
    //             _price
    //         );

    //     // Create bid
    //     bytes32 bidId = keccak256(
    //         abi.encodePacked(
    //             block.timestamp,
    //             msg.sender,
    //             order.id,
    //             _price,
    //             expiresAt
    //         )
    //     );

    //     // Save Bid for this order
    //     bidByOrderId[_nftAddress][_assetId] = Bid({
    //         id: bidId,
    //         bidder: msg.sender,
    //         price: _price,
    //         expiresAt: expiresAt
    //     });

    //     emit BidCreated(
    //         bidId,
    //         _nftAddress,
    //         _assetId,
    //         msg.sender, // bidder
    //         _price,
    //         expiresAt
    //     );
    // }

    /**
     * @dev Cancel an already published order
     *  can only be canceled by seller or the contract owner
     * @param _orderId - Bid identifier
     * @param _nftAddress - Address of the NFT registry
     * @param _assetId - ID of the published NFT
     * @param _seller - Address
     */
    function _cancelOrder(
        bytes32 _orderId,
        address _nftAddress,
        uint256 _assetId,
        address _seller
    ) internal {
        delete orderByAssetId[_nftAddress][_assetId];

        /// send asset back to seller
        IERC721(_nftAddress).transferFrom(address(this), _seller, _assetId);

        emit OrderCancelled(_orderId);
    }

    // /**
    //  * @dev Cancel bid from an already published order
    //  *  can only be canceled by seller or the contract owner
    //  * @param _bidId - Bid identifier
    //  * @param _nftAddress - registry address
    //  * @param _assetId - ID of the published NFT
    //  * @param _bidder - Address
    //  * @param _escrowAmount - in acceptenToken currency
    //  */
    // function _cancelBid(         KPR_BID 
    //     bytes32 _bidId,
    //     address _nftAddress,
    //     uint256 _assetId,
    //     address _bidder,
    //     uint256 _escrowAmount
    // ) internal {
    //     delete bidByOrderId[_nftAddress][_assetId];
    //     Order memory order = _getValidOrder(_nftAddress, _assetId);

    //     if (order.acceptedToken == weth) {
    //         payable(_bidder).transfer(_escrowAmount);
    //     } else {
    //         // return escrow to canceled bidder
    //         IERC20(order.acceptedToken).transfer(_bidder, _escrowAmount);
    //     }
    //     emit BidCancelled(_bidId);
    // }
 
    function _requireERC721(address _nftAddress)
        internal
        view
        returns (IERC721)
    {
        require(
            _nftAddress.isContract(),
            "The NFT Address should be a contract"
        );
        // require(
        //     IERC721(_nftAddress).supportsInterface(_INTERFACE_ID_ERC721),
        //     "The NFT contract has an invalid ERC721 implementation"
        // );
        return IERC721(_nftAddress);
    }
}
// import "./LandNFT.sol";

// contract LandNFTMarket {
//     RentableLandNFT private token;
//     struct nftForSale {
//         uint256 id;
//         uint256 tokenId;
//         address payable seller;
//         uint256 price;
//         bool isSold;
//     }
//     nftForSale[] public nftsForSale;
//     mapping(uint256 => bool) public activeNFTs;

//     event nftAddedForSale(uint256 id, uint256 tokenId, uint256 price);
//     event nftSold(uint256 id, address buyer, uint256 price);

//     constructor(RentableLandNFT _token) {
//         token = _token;
//     }

//     modifier onlyNFTOwner(uint256 tokenId) {
//         require(
//             token.ownerOf(tokenId) == msg.sender,
//             "Sender does not own the item"
//         );
//         _;
//     }

//     modifier HasTransferApproval(uint256 tokenId) {
//         require(
//             token.getApproved(tokenId) == address(this),
//             "Market is not approved"
//         );
//         _;
//     }

//     modifier nftExists(uint256 id) {
//         require(
//             id < nftsForSale.length && nftsForSale[id].id == id,
//             "Could not find nft."
//         );
//         _;
//     }

//     modifier IsForSale(uint256 id) {
//         require(!nftsForSale[id].isSold, "NFT is already sold");
//         _;
//     }

//     function putNftForSale(uint256 tokenId, uint256 price)
//         external
//         onlyNFTOwner(tokenId)
//         HasTransferApproval(tokenId)
//         returns (uint256)
//     {
//         require(!activeNFTs[tokenId], "NFT is already up for sale");
//         uint256 newItemId = nftsForSale.length;
//         nftsForSale.push(
//             nftForSale({
//                 id: newItemId,
//                 tokenId: tokenId,
//                 seller: payable(msg.sender),
//                 price: price,
//                 isSold: false
//             })
//         );
//         activeNFTs[tokenId] = true;
//         assert(nftsForSale[newItemId].id == newItemId);
//         emit nftAddedForSale(newItemId, tokenId, price);
//         return newItemId;
//     }

//     function buyItem(uint256 id)
//         external
//         payable
//         nftExists(id)
//         IsForSale(id)
//         HasTransferApproval(nftsForSale[id].tokenId)
//     {
//         require(msg.value >= nftsForSale[id].price, "Not enough funds sent");
//         require(msg.sender != nftsForSale[id].seller);

//         nftsForSale[id].isSold = true;
//         activeNFTs[nftsForSale[id].tokenId] = false;
//         token.safeTransferFrom(
//             nftsForSale[id].seller,
//             msg.sender,
//             nftsForSale[id].tokenId
//         );
//         nftsForSale[id].seller.transfer(msg.value);

//         emit nftSold(id, msg.sender, nftsForSale[id].price);
//     }

//     function totalnftsForSale() external view returns (uint256) {
//         return nftsForSale.length;
//     }
// }

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

interface IMarketplace {
    struct Order {
        // Order ID
        bytes32 id;
        // Owner of the NFT
        address seller;
        // NFT registry address
        address nftAddress;
        // accepted token for trading item
        address acceptedToken;
        // Price (in wei) for the published item
        uint256 price;
        // Time when this sale ends
        uint256 expiresAt;
        // Direct address
        address daddr;
    }

    struct Bid {
        // Bid Id
        bytes32 id;
        // Bidder address
        address bidder;
        // Price for the bid in wei
        uint256 price;
        // Time when this bid ends
        uint256 expiresAt;
    }

    // ORDER EVENTS
    event OrderCreated(
        bytes32 id,
        address indexed seller,
        address indexed nftAddress,
        uint256 indexed assetId,
        address acceptedToken,
        uint256 price,
        uint256 expiresAt,
        address daddr
    );

    event OrderUpdated(bytes32 id, uint256 price, uint256 expiresAt);

    event OrderSuccessful(bytes32 id, address indexed buyer, uint256 price);

    event MultiOrderSuccessful(uint256 count, uint256 price);

    event OrderCancelled(bytes32 id);

    // BID EVENTS
    event BidCreated(
        bytes32 id,
        address indexed nftAddress,
        uint256 indexed assetId,
        address indexed bidder,
        uint256 price,
        uint256 expiresAt
    );

    event BidAccepted(bytes32 id);
    event BidCancelled(bytes32 id);

    event BuyCreated(
        address indexed nftAddress,
        uint256 indexed assetId,
        address indexed bidder,
        address seller,
        uint256 price
    );

    function createOrder(
        address _nftAddress,
        address owner,
        uint256 _assetId,
        address _acceptedToken,
        uint256 _price,
        uint256 _expiresAt,
        address daddr
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

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
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

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