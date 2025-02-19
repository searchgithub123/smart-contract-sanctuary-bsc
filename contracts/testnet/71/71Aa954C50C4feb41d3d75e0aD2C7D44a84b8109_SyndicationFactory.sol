// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Syndication.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract SyndicationFactory {
    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private allSyndications;

    event SyndicationCreated(
        address syndication,
        uint count
    );

    function allSyndicationsLength() external view returns (uint) {
        return allSyndications.length();
    }

    function getSyndicationByIndex(uint256 index) external view returns (address) {
        return allSyndications.at(index);
    }

    function createSyndication(
        address _nftAddress,
        uint256 _tokenId,
        Syndication.TargetNFTStatus _statusNFT,
        uint256 _orderId,
        address _protectedMarketplace
    ) external payable returns ( address syndication ) {
        uint256 _gasLeft = gasleft();
        uint256 _gasPrice = tx.gasprice;
        uint256 _amountForLP = msg.value;
        
        require( _protectedMarketplace != address(0), "NA" );

        syndication = address(
            new Syndication(
                _nftAddress,
                _tokenId,
                _statusNFT,
                _orderId,
                _protectedMarketplace,
                msg.sender
            )
        );

        allSyndications.add(syndication);

        emit SyndicationCreated(
            syndication, 
            allSyndications.length()
        );

        uint256 _gasLeft1 = gasleft();
        ISyndication(syndication).mintLPForDeployer((_gasLeft - _gasLeft1) * _gasPrice);
        if (_amountForLP > 0) {
            ISyndication(syndication).addLiquidity{value:_amountForLP}(msg.sender);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function add32(uint32 a, uint32 b) internal pure returns (uint32) {
        uint32 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function mul32(uint32 a, uint32 b) internal pure returns (uint32) {
        if (a == 0) {
            return 0;
        }

        uint32 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

}

interface IProtectedMarketplace {

    function createOrder(
        address _tokenAddress,  // NFT token contract address (where NFT was minted)
        uint256 _nftTokenId,    // NFT token ID (what to sell)
        uint256 _tokenPrice,    // Fix price or start price of auction
        uint64 _protectionRate, // downside protection rate in percentage with 2 decimals (i.e. 3412 = 34.12%)
        bool _isFixedProtection,    // false -> soldTime + protectionTime, true -> fix date
        uint256 _protectionTime,// downside protection duration (in seconds). I.e. 604800 = 1 week (60*60*24*7)
        bool _acceptOffers,     // false = fix price order, true - auction order
        uint256 _offerClosingTime   // Epoch time (in seconds) when auction will be closed (or fixed order expired)
    ) external;
    function createSubOrder(
        uint256 _orderId, //original order ID
        address payable _buyerAddress,
        uint256 _tokenPrice,
        uint64 _protectionRate,
        uint256 _protectionTime,
        uint256 _validUntil
    ) external;
    function buySubOrder(uint256 _orderId, uint256 _subOrderId) external payable;
    function buyFixedPayOrder(uint256[] memory _orderIds) external payable;
    function cancelOrder(uint256[] memory _orderIds) external ;
    function claimDownsideProtectionAmount(uint256[] memory _orderIds) external returns (bool);
    function createBid(uint256 _orderId) external payable;
    function executeBid(uint256 _orderId) external ;
    function cancelBid(uint256 _orderId) external;

    function createOffer(
        address _tokenAddress,  // NFT token contract address (where NFT was minted)
        uint256 _nftTokenId,    // NFT token ID (what to buy)
        uint256 _tokenPrice,    // Fix price or start price of auction
        uint64 _protectionRate, // downside protection rate in percentage with 2 decimals (i.e. 3412 = 34.12%)
        uint256 _protectionTime,     // downside protection duration (in seconds). I.e. 604800 = 1 week (60*60*24*7)
        uint256 _offerExpiration    // the time when offer is canceled automatically if NFT owner doesn't accept offer
    ) external payable returns (uint256);
    function acceptOffer(int256 _offerId) external returns (bool);
    function claimDownsideProtectionAmountInOffer(uint256 _offerId) external returns (bool);
    function cancelOffer(uint256 _offerId) external;

    function setNewCompany(address payable _newCompany) external;
    function setCompanyFeeRate(uint256 _newRate) external;
    function buyerBidStatus(address, uint256) external view returns (BidStatus);
    function orderIdCount() external view returns (uint256);

    function getOrder(uint256 _orderId) external view returns (Order memory);
    function getOffer(uint256 _offerId) external view returns (Offer memory);
     
    enum OrderType { FixedPay, AuctionType }
    enum OrderStatus { Active, Bidded, UnderDownsideProtectionPhase, Completed, Cancelled }
    enum BidStatus { NotAccepted, Pending, Refunded, Executed }
    enum OfferStatus { NotCreated, Active, UnderDownsideProtectionPhase, Completed, Cancelled }
     
    struct Order {
        OrderStatus statusOrder;
        OrderType typeOrder;
        address tokenAddress;
        uint256 nftTokenId;
        address payable sellerAddress;
        address payable buyerAddress;
        uint256 tokenPrice; // In fix sale - token price. Auction: start price or max offer price
        // protection
        uint256 protectionAmount;
        uint256 depositId;
        uint64 protectionRate;  // in percent with 2 decimals
        bool isFixedProtection; // false -> soldTime + protectionTime, true -> fix date
        uint256 protectionTime;
        //uint256 protectionExpiryTime = soldTime + protectionTime
        uint256 soldTime; // time when order sold, if equal to 0 than order unsold (so no need to use additional variable "bool saleNFT")
        //suborder
        uint256 offerClosingTime;
        uint256[] subOrderList;
    }

    struct Offer {
        OfferStatus statusOffer;
        address tokenAddress;
        uint256 nftTokenId;
        address payable sellerAddress;
        address payable buyerAddress;
        uint256 tokenPrice; // token price
        // protection
        uint256 protectionAmount;
        uint256 depositId;
        uint64 protectionRate;  // in percent with 2 decimals
        uint256 protectionTime;
        //uint256 protectionExpiryTime = soldTime + protectionTime
        uint256 soldTime; // time when order sold, if equal to 0 than order unsold (so no need to use additional variable "bool saleNFT")
        uint256 offerExpiration;
    }

}

interface ISyndication {

    function addLiquidity(address _lpOwner) external payable;
    function mintLPForDeployer( uint256 _gasFee ) external;

}

contract Syndication is ERC20, Ownable{

    using SafeMath for uint256;
    using SafeMath for uint64;

    event AddLiquidity( address depositor, uint256 amount );
    event MintForDeployer( address deployer, uint256 gasFee, uint256 mintLP );
    event Withdrawl( address withdrawer, uint256 amount );
    event BuyNFTOnMarketplace(uint256 orderID, IProtectedMarketplace.OrderType orderType, uint256 buyValue, IProtectedMarketplace.BidStatus bidStatus, uint offerClosingTime);
    event SellNFTOnMarketplace(uint256 orderID, uint256 startPrice, uint64 protectionRate, uint256 protectionTime, uint256 offerClosingTime);
    event BuyNFTByOffer(uint256 offerID, uint256 buyValue, IProtectedMarketplace.OfferStatus offerStatus);

    address public factory;
    uint public totalValue;

    IProtectedMarketplace public marketplace; // address of the deployed contract

    enum SyndicationStatus {Active, UnderDownsideProtectionPhaseAsBuyer, UnderDownsideProtectionPhaseAsSeller, Completed, Cancelled}
    enum TargetNFTStatus {Fixed, Auction, NotListed}
    
    struct Terms {
        address nftAddress; // NFT token contract address
        uint256 tokenId;    // NFT token ID (what to buy)
        TargetNFTStatus statusTargetNFT;
        uint256 buyOrderID; // target NFT listed on marketplace (for buy)
        uint256 sellOrderID;    // target NFT listed on marketplace (for sale)
    }

    Terms public terms;
    SyndicationStatus public statusSyndication;
    uint256 public offerID;
    
    address payable[] public lpHolders;
    address public immutable deployerAddr;
    bool public isMintLPForDeployerEnded;

    constructor(
        address _nftAddress,
        uint256 _tokenId,
        TargetNFTStatus _statusNFT,
        uint256 _orderId,
        address _protectedMarketplace,
        address _deployer
    ) ERC20("Syndication LPToken","SDL"){
        marketplace = IProtectedMarketplace(_protectedMarketplace);

        terms.nftAddress = _nftAddress;
        terms.tokenId = _tokenId;
        terms.statusTargetNFT = _statusNFT;
        
        if ( _statusNFT == TargetNFTStatus.NotListed ) {
            terms.buyOrderID = 0;
        } else {
            terms.buyOrderID = _orderId;
            
            IProtectedMarketplace.Order memory ipo = marketplace.getOrder(_orderId);
            require(ipo.tokenAddress == _nftAddress && ipo.nftTokenId == _tokenId, "NFT is not matched");

            if ( _statusNFT == TargetNFTStatus.Fixed ) {
                require(ipo.typeOrder == IProtectedMarketplace.OrderType.FixedPay, "order type is not matched");
                require(ipo.statusOrder == IProtectedMarketplace.OrderStatus.Active, "invalid order stautus");
            } else {
                require(ipo.typeOrder == IProtectedMarketplace.OrderType.AuctionType, "order type is not matched");
                require(ipo.statusOrder == IProtectedMarketplace.OrderStatus.Active || ipo.statusOrder == IProtectedMarketplace.OrderStatus.Bidded, "invalid order stautus");
            }
        }

        deployerAddr = _deployer;
        statusSyndication = SyndicationStatus.Active;
        factory = msg.sender;
    }
        
    /**
     * @notice Mint LP tokens for the corresponding sent amount.
     */
    function addLiquidity(address _lpOwner) external payable {
        
        require(statusSyndication == SyndicationStatus.Active, "Funding Ended");
        require(_lpOwner != address(0), "NA");
        
        uint256 inputAmount = msg.value;
        totalValue = totalValue.add(inputAmount);

        if ( terms.statusTargetNFT == TargetNFTStatus.Fixed ) { // fixed
            IProtectedMarketplace.Order memory ipo = marketplace.getOrder(terms.buyOrderID);

            if ( getBuyOrderStatus() != IProtectedMarketplace.OrderStatus.Active ) {
                totalValue = totalValue.sub(inputAmount);
                payable(_lpOwner).transfer(inputAmount);
                inputAmount = 0;
            } else if ( totalValue >= ipo.tokenPrice ) {
                uint256 refundAmount = totalValue.sub(ipo.tokenPrice);
                inputAmount = inputAmount.sub(refundAmount);
                totalValue = ipo.tokenPrice;
                payable(_lpOwner).transfer(refundAmount);
            }
        } else if ( terms.statusTargetNFT == TargetNFTStatus.Auction ) {    // auction
            if ( getBidStatus() == IProtectedMarketplace.BidStatus.Executed ) { // when accepted
                totalValue = totalValue.sub(inputAmount);
                payable(_lpOwner).transfer(inputAmount);
                inputAmount = 0;
            }
        } else {    // not listed
            if ( getOfferStatus() == IProtectedMarketplace.OfferStatus.UnderDownsideProtectionPhase ) { // when accepted
                totalValue = totalValue.sub(inputAmount);
                payable(_lpOwner).transfer(inputAmount);
                inputAmount = 0;
            }
        }

        _mintLP(_lpOwner, inputAmount);
        bool buyEnd = _buyNftOnMarketplace();
        if (buyEnd) {
            statusSyndication = SyndicationStatus.UnderDownsideProtectionPhaseAsBuyer;
        }
        
        emit AddLiquidity(_lpOwner, inputAmount);

    }

    function mintLPForDeployer( uint256 _gasFee ) external onlyOwner {

        require(!isMintLPForDeployerEnded, "Deployer LP already exists");

        isMintLPForDeployerEnded = true;
        uint lpAmount = _mintLP(deployerAddr, _gasFee);

        emit MintForDeployer(deployerAddr, _gasFee, lpAmount);

    }

    function _mintLP( address _receiver, uint256 _etherAmount ) internal returns (uint256) {
        
        uint256 lpAmount;
        
        if (totalValue == 0) {
            lpAmount = _etherAmount;
        } else {
            lpAmount = totalSupply().mul(_etherAmount).div(totalValue);
        } 
        
        if(balanceOf(_receiver) == 0) {
            lpHolders.push(payable(_receiver));
        }

        _mint(_receiver, lpAmount);

        return lpAmount;

    }

    /**
     * @notice Redeems LP amount for its underlying token amount.
     * @param _lpamount The amount of LP tokens to redeem
     */
    function withdraw( uint256 _lpamount ) external {
        
        require(statusSyndication == SyndicationStatus.Active, "Funding Ended");
        require(_lpamount > 0 && _lpamount <= balanceOf(msg.sender), "AMOUNT_INSUFFICIENT");
        
        uint amount = _lpamount.mul(totalValue).div(totalSupply());
        totalValue = totalValue.sub(amount);
        
        _burn(msg.sender, _lpamount);
        
        if (balanceOf(msg.sender) == 0) {
            removeFromHolders(msg.sender);
        }
        payable(msg.sender).transfer(amount);

        bool buyEnd = _buyNftOnMarketplace();
        if (buyEnd) {
            statusSyndication = SyndicationStatus.UnderDownsideProtectionPhaseAsBuyer;
        }
        
        emit Withdrawl(msg.sender, amount);

    }

    function removeFromHolders(address _holder) internal {
        for (uint256 i = 0; i < lpHolders.length; i++) {
            if (lpHolders[i] == _holder) {
                lpHolders[i] = lpHolders[lpHolders.length - 1];
                lpHolders.pop();
                break;
            }
        }
    }

    /**
     * @notice used to buy Marketplace NFT that is satisfied by token price
     */
    function _buyNftOnMarketplace() internal returns (bool) {
        
        if (terms.statusTargetNFT == TargetNFTStatus.Fixed) {
            
            IProtectedMarketplace.Order memory ipo = marketplace.getOrder(terms.buyOrderID);

            if ( getBuyOrderStatus() != IProtectedMarketplace.OrderStatus.Active ) {
                _refundToInvestors();
                return false;
            }

            if (totalValue < ipo.tokenPrice) {
                return false;
            }

            uint256[] memory _orderIds = new uint256[](1);
            _orderIds[0] = terms.buyOrderID;
            marketplace.buyFixedPayOrder{value:ipo.tokenPrice}(_orderIds);
            _sellNftOnMarketplace();
            
            emit BuyNFTOnMarketplace(terms.buyOrderID, ipo.typeOrder, ipo.tokenPrice, IProtectedMarketplace.BidStatus.NotAccepted, 0);

            return true;

        } else if (terms.statusTargetNFT == TargetNFTStatus.Auction) {

            IProtectedMarketplace.Order memory ipo = marketplace.getOrder(terms.buyOrderID);

            if ( getBidStatus() == IProtectedMarketplace.BidStatus.Pending ) {
                marketplace.cancelBid(terms.buyOrderID); // balance will be totalValue
            } else if ( getBidStatus() == IProtectedMarketplace.BidStatus.Executed ) {
                _sellNftOnMarketplace();
                
                emit BuyNFTOnMarketplace(terms.buyOrderID, ipo.typeOrder, totalValue, IProtectedMarketplace.BidStatus.Executed, ipo.offerClosingTime);

                return true;
            }

            marketplace.createBid{value: totalValue}(terms.buyOrderID);   //FIXME
             //When bid is closed ?????? So we called ExecuteBid fucntion
        } else {

            if ( getOfferStatus() == IProtectedMarketplace.OfferStatus.Active ) {
                marketplace.cancelOffer(offerID);
            } else if ( getOfferStatus() == IProtectedMarketplace.OfferStatus.UnderDownsideProtectionPhase ) {
                _sellNftOnMarketplace();
                
                emit BuyNFTByOffer(offerID, totalValue, IProtectedMarketplace.OfferStatus.UnderDownsideProtectionPhase);

                return true;
            }

            offerID = marketplace.createOffer{value: totalValue}(
                terms.nftAddress,
                terms.tokenId,
                totalValue,
                10000,
                365 days,
                block.timestamp.add(7 days) 
            );

        }

        return false;

    }

    /**
     * @notice used to create order to sell Marketplace NFT by nft sell criteria.
     */
    function _sellNftOnMarketplace() internal returns (bool) {

        uint256 period;
        uint256 auctionTime;
        uint256 protectionTime;
        uint64 protectionRate;
        bool isFixedProtection;
        uint256 tokenPrice;

        if (terms.statusTargetNFT == TargetNFTStatus.NotListed) {
            
            IProtectedMarketplace.Offer memory ipo = marketplace.getOffer(offerID);

            uint256 protectionExpiryTime = ipo.soldTime.add(ipo.protectionTime);
            period = protectionExpiryTime.sub(block.timestamp);
            protectionRate = ipo.protectionRate;
            isFixedProtection = false;
            tokenPrice = ipo.tokenPrice;

        } else {

            IProtectedMarketplace.Order memory ipo = marketplace.getOrder(terms.buyOrderID);

            uint256 protectionExpiryTime = ipo.isFixedProtection ? ipo.protectionTime : (ipo.soldTime.add(ipo.protectionTime));
            period = protectionExpiryTime.sub(block.timestamp);
            protectionRate = ipo.protectionRate == 0 ? 10000 : ipo.protectionRate;
            isFixedProtection = ipo.isFixedProtection;
            tokenPrice = ipo.tokenPrice;

        }

        if ( period <= 1 days ) {
            auctionTime = 7 days;
            protectionTime = 365 days;                
        } else if ( period < 8 days ) {
            auctionTime = period.sub(1 days);
            protectionTime = 0;
        } else {
            auctionTime = 7 days;
            protectionTime = period.sub(1 days).sub(auctionTime);
        }

        marketplace.createOrder(terms.nftAddress, terms.tokenId, tokenPrice, protectionRate, isFixedProtection, protectionTime, true, block.timestamp.add(auctionTime));
        terms.sellOrderID = marketplace.orderIdCount();
        
        emit SellNFTOnMarketplace(terms.sellOrderID, tokenPrice, protectionRate, protectionTime, block.timestamp.add(auctionTime));
        
        return true;
    
    }

    function getBidStatus() public view returns (IProtectedMarketplace.BidStatus) {
        return marketplace.buyerBidStatus(address(this), terms.buyOrderID);
    }

    function getOfferStatus() public view returns (IProtectedMarketplace.OfferStatus) {
        IProtectedMarketplace.Offer memory offer = marketplace.getOffer(offerID);

        return offer.statusOffer;
    }

    function getBuyOrderStatus() public view returns (IProtectedMarketplace.OrderStatus) {
        IProtectedMarketplace.Order memory order = marketplace.getOrder(terms.buyOrderID);

        return order.statusOrder;
    }

    function getSellOrderStatus() public view returns (IProtectedMarketplace.OrderStatus) {
        IProtectedMarketplace.Order memory order = marketplace.getOrder(terms.sellOrderID);

        return order.statusOrder;
    }

    function redeem() external returns (bool){

        require(statusSyndication != SyndicationStatus.Active, "cannot redeem now");
        require(balanceOf(msg.sender) > 0, "Only LP Token owners can redeem");
        require(getSellOrderStatus() != IProtectedMarketplace.OrderStatus.Active, "invalid sell order status");

        if ( statusSyndication == SyndicationStatus.UnderDownsideProtectionPhaseAsBuyer || statusSyndication == SyndicationStatus.UnderDownsideProtectionPhaseAsSeller ) {
            _changeStatus();
        }

        if ( statusSyndication == SyndicationStatus.Completed || statusSyndication == SyndicationStatus.Cancelled ) {
            totalValue = address(this).balance;
            uint256 amountForLP = totalValue * balanceOf(msg.sender) / totalSupply();
            require(address(this).balance >= amountForLP, "Insufficient balance");

            _burn(msg.sender, balanceOf(msg.sender));
            payable(msg.sender).transfer(amountForLP);

            return true;
        }

        return false;

    }

    function _changeStatus() internal {

        if ( getSellOrderStatus() == IProtectedMarketplace.OrderStatus.Bidded ) {
            marketplace.executeBid(terms.sellOrderID);
            statusSyndication = SyndicationStatus.UnderDownsideProtectionPhaseAsSeller;
        } else if ( getSellOrderStatus() == IProtectedMarketplace.OrderStatus.UnderDownsideProtectionPhase ) {
            uint256[] memory _orderIds = new uint256[](1);
            _orderIds[0] = terms.sellOrderID;
            bool result = marketplace.claimDownsideProtectionAmount(_orderIds);
            if (result) {
                statusSyndication = SyndicationStatus.Completed;
            }
        } else if ( getSellOrderStatus() == IProtectedMarketplace.OrderStatus.Cancelled ) {
            bool result;
            if ( terms.statusTargetNFT == TargetNFTStatus.NotListed ) {
                result = marketplace.claimDownsideProtectionAmountInOffer(offerID);
            } else {
                uint256[] memory _orderIds = new uint256[](1);
                _orderIds[0] = terms.buyOrderID;
                result = marketplace.claimDownsideProtectionAmount(_orderIds);
            }
            if (result) {
                statusSyndication = SyndicationStatus.Cancelled;
            }
        }

    }

    function _refundToInvestors() internal {

        statusSyndication = SyndicationStatus.Cancelled;

        for(uint256 i = 0; i < lpHolders.length; i ++) {
            uint256 amountForLP = totalValue * balanceOf(lpHolders[i]) / totalSupply();
            require(address(this).balance >= amountForLP, "Insufficient balance");
            lpHolders[i].transfer(amountForLP);
        }

        totalValue = 0;
        _burnAllLPTokens();
    }

    function _burnAllLPTokens() internal {

        for(uint256 i = 0; i < lpHolders.length; i ++) {
            _burn(lpHolders[i], balanceOf(lpHolders[i]));
        }

    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
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
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
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

        assembly {
            result := store
        }

        return result;
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