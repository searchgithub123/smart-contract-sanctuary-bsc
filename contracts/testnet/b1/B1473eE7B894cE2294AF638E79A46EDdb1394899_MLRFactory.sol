// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./MultilevelRoyalty.sol";
import "./Depository.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract MLRFactory {
    mapping( address => mapping( uint256 => address ) ) public getMLR;
    
    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private allMLRs;

    struct OrderArgs {
        uint256 tokenPrice;
		uint64 protectionRate;
		uint256 protectionTime;
        bool acceptOffers;
        uint256 offerClosingTime;
    }

    event MLRCreated(
        address nftContract,
        uint256 tokenID,
        address depository,
        address multilevelRoyalty,
        uint count
    );

    event MLRDeleted(
        address nftContract,
        uint256 tokenID,
        address multilevelRoyalty
    );

    function allMLRsLength() external view returns (uint) {
        return allMLRs.length();
    }

    function getMLRByIndex(uint256 index) external view returns (address) {
        return allMLRs.at(index);
    }

    function createMLR(
        address _nftContract,
        uint256 _tokenID,
        uint256 _maxRoyaltyOwner,
        string memory _name,
		string memory _tokenName,
		string memory _tokenSymbol,
        uint32 _royaltyFee,
        uint256 _buyoutPrice,
        OrderArgs memory args
    ) external returns (address depository, address mlr) {
        require( _nftContract != address(0), "NA" );
        require( IERC721(_nftContract).ownerOf(_tokenID) == msg.sender, "Only NFT owner can create MLR" );
        require( _maxRoyaltyOwner > 0, "No Royalty owner" );
        require( getMLR[_nftContract][_tokenID] == address(0), "MLR_EXISTS" );
        // Depository
        depository = address( new Depository() );
        IDepository(depository).initialize();
        // MLR
        mlr = address( new MultilevelRoyalty(_nftContract, _tokenID, _maxRoyaltyOwner, _name, _tokenName, _tokenSymbol, depository) );
        IERC721(_nftContract).safeTransferFrom(msg.sender, mlr, _tokenID);   // send NFT to MLR
        IMultilevelRoyalty(mlr).initialize(_royaltyFee, msg.sender);
        
        getMLR[_nftContract][_tokenID] = mlr;
        allMLRs.add(mlr);

        IMultilevelRoyalty(mlr).createOrder(
            _buyoutPrice,
            args.tokenPrice,
            args.protectionRate,
            args.protectionTime,
            args.acceptOffers,
            args.offerClosingTime
        );

        // IMultilevelRoyalty(mlr).createOrder(
        //     _nftContract,
        //     _tokenID,
        //     tokenPrice,
        //     protectionRate,
        //     protectionTime,
        //     acceptOffers,
        //     offerClosingTime
        // );

        emit MLRCreated(
            _nftContract,
            _tokenID,
            depository,
            mlr,
            allMLRs.length()
        );
    }

    function deleteMLR(
        address _nftContract,
        uint256 _tokenID
    ) external returns ( bool ) {
        require( msg.sender == getMLR[_nftContract][_tokenID], "Only MLR can delete itself" );

        allMLRs.remove(msg.sender);
        delete getMLR[_nftContract][_tokenID];

        emit MLRDeleted(
            _nftContract,
            _tokenID,
            msg.sender
        );

        return true;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// import ERC721 iterface
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IDepository {
	function initialize() external;
    function deposit() external payable returns(uint256);
    function withdraw(uint256 depositId) external returns(uint256);
}

interface IMultilevelRoyalty {
	function initialize(uint32 _royaltyFee, address _nftOwner) external returns (bool);
	function createOrder(
		uint256 _buyoutPrice,
		uint256 _tokenPrice,
		uint64 _protectionRate,
		uint256 _protectionTime,
        bool _acceptOffers,
        uint256 _offerClosingTime
	) external;
}

interface IMLRFactory {
	function deleteMLR(address _nftContract, uint256 _tokenID) external returns (bool);
}

contract MultilevelRoyalty is Ownable, ERC20 {

	uint256 public maxRoyaltyOwner;
	address public nftContract;
	uint256 public tokenID;
	string private _contractName;
	address public factory;
	// define multilevel royalty order
	bool public isInitialized;
	address payable public currentOwner;
	uint256 public buyPrice;	// current buy price
	address payable[] public royaltyHolders;
	mapping( address => uint256 ) public royaltyIndex; // 2 = second index, 0 = no index
	mapping( address => uint256 ) public buyoutPrices;		// if 0, no buyout

	IDepository public depository;

	enum OrderType { FixedPay, AuctionType }
    enum OrderStatus { Active, Bidded, UnderDownsideProtectionPhase, Completed, Cancelled }
    enum BidStatus { NotAccepted, Pending, Refunded, Executed }

	struct Order {
		OrderStatus statusOrder;
        OrderType typeOrder;
		address payable sellerAddress;
        address payable buyerAddress;
        uint256 tokenPrice; // In fix sale - token price. Auction: start price or max offer price
		uint256 buyPrice; // previous buy price, to calculate profit
		// protection
		uint256 protectionAmount;
        uint256 depositId;
        uint64 protectionRate;  // in percent with 2 decimals
        uint256 protectionTime;
		uint256 soldTime; // time when order sold, if equal to 0 than order unsold (so no need to use additional variable "bool saleNFT")
		uint256 offerClosingTime;	// for auction
	}
	
	uint256 public orderIdCount;
	mapping(uint256 => Order) public orders;	// identify offers by offerID
	mapping (address => mapping(uint256 => BidStatus)) public buyerBidStatus;	// To check a buyer's bid status(can be used in frontend)

	event RoyaltyInit(
		address nftOwner,
		address nftContract,
		uint256 tokenID,
		string contractName,
		uint32 royaltyFee
	);
	
	event RoyaltyInfoUpdated(
		address owner,
		address nftContract,
		uint256 tokenID,
		uint32 royaltyFee,
		uint256 buyoutPrice
	);

	event PreviousOwnerChanged(
		address oldPreviousOwner,
		address newPreviousOwner,
		address nftContract,
		uint256 tokenID
	);

	event CreateOrder(
		uint256 orderID,
		OrderType typeOrder,
		uint256 tokenPrice,
		uint64 protectionRate,
		uint256 protectionTime
	);

    event BuyOrder(
		uint256 orderID,
		OrderType typeOrder,
		address indexed buyerAddress,
		uint256 protectionAmount,
		uint256 protectionExpiryTime
	);

    event ClaimDownsideProtection(
		uint256 orderID,
		uint256 statusOrder,
		uint256 soldTime,
		address indexed buyerOrSeller,
		uint256 claimAmount
	);

	event CreateBid(
		uint256 orderID,
		OrderType typeOrder,
		address indexed buyerAddress,
		uint256 bidAmount
	);

	event CancelOrder(
		uint256 orderID
	);

	constructor(
		address _nftContract,
		uint256 _tokenID,
		uint256 _maxRoyaltyOwner,
		string memory _name,
		string memory _tokenName,
		string memory _tokenSymbol,
		address _depository
	) ERC20(_tokenName, _tokenSymbol) {
		require( _nftContract != address(0), "NA" );
		
		factory = msg.sender;
		nftContract = _nftContract;
		tokenID = _tokenID;
		maxRoyaltyOwner = _maxRoyaltyOwner;
		_contractName = _name;
		depository = IDepository( _depository );

	}

	function decimals() public view virtual override returns (uint8) {
        return 2;
    }

	function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
		require(balanceOf(owner) == amount, "Only can transfer entire balance");
        _transfer(owner, to, amount);
		_changeRoyaltyHolder(owner, to);
        return true;
    }

	function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
		require(balanceOf(from) == amount, "Only can transfer entire balance");
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
		_changeRoyaltyHolder(from, to);
        return true;
    }

	function contractName() public view returns (string memory) {
		return _contractName;
	}

	receive() external payable {}

	function onERC721Received(address, address, uint256, bytes memory) public virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }

	// For only factory
	function initialize(
		uint32 _royaltyFee,
		address _nftOwner
	) external returns ( bool ) {
		require( msg.sender == factory, "Only factory can initialize" );
		
		currentOwner = payable( _nftOwner );
		_mint( _nftOwner, _royaltyFee );
		isInitialized = true;

		emit RoyaltyInit(
			_nftOwner,
			nftContract,
			tokenID,
			_contractName,
			_royaltyFee
		);

		return true;
	}

	// For current owner and previous owner
	function updateRoyaltyInfo(
		uint32 _royaltyFee,
		uint256 _buyoutPrice
	) external returns (bool) {
		require( isInitialized, "Royalty should be initialized" );
		
		if ( balanceOf(msg.sender) == 0 ) {	// add royalty
			require( currentOwner == payable(msg.sender), "Only NFT owner can add royalty" );
			require( royaltyHolders.length < maxRoyaltyOwner, "Royalty owner limit is exceeded" );
			
			_mint( msg.sender, _royaltyFee );
		} else {	//update royalty
			require( _royaltyFee < balanceOf(msg.sender), "Royalty Fee can't increase" );
			
			_burn(msg.sender, balanceOf(msg.sender) - _royaltyFee);
			if ( balanceOf(msg.sender) == 0 ) {
				_deleteRoyaltyHolder( msg.sender );
				delete buyoutPrices[msg.sender];
			}
		}

		buyoutPrices[msg.sender] = _buyoutPrice;

		emit RoyaltyInfoUpdated(
			msg.sender,
			nftContract,
			tokenID,
			_royaltyFee,
			_buyoutPrice
		);

		return true;
	}

	function _deleteRoyaltyHolder(address _royaltyHolder) internal {
		uint256 targetIndex = royaltyIndex[_royaltyHolder] - 1;
		for (uint256 index = targetIndex; index < royaltyHolders.length - 1; index ++) {
			royaltyHolders[index] = royaltyHolders[index + 1];
			royaltyHolders.pop();
		}
		delete royaltyIndex[_royaltyHolder];
	}

	// For any user
	function buyOut(
		address _previousOwner
	) external payable {
		require( isInitialized, "Royalty should be initialized" );
		require( royaltyIndex[_previousOwner] > 0 , "Should be royalty owner" );
		uint256 buyoutPrice = buyoutPrices[_previousOwner];	// price per 1%
		uint32 realRoyalty = getRealRoyalty(_previousOwner);
		require( msg.value >= buyoutPrice * realRoyalty / 100 && buyoutPrice > 0, "Less than buyout price or no" );

		uint256 royaltyFee = balanceOf(_previousOwner);
		_burn(_previousOwner, royaltyFee);
		_mint(msg.sender, royaltyFee);

		_changeRoyaltyHolder( _previousOwner, msg.sender );

		payable(_previousOwner).transfer(buyoutPrice * realRoyalty);

		emit PreviousOwnerChanged(
			_previousOwner,
			msg.sender,
			nftContract,
			tokenID
		);
	}

	function getRealRoyalty( address _royaltyHolder ) public view returns (uint32) {
		uint256 targetIndex = royaltyIndex[_royaltyHolder] - 1;
		uint totalAmount = 0;
		uint realRoyalty = 0;
		for(uint256 index = royaltyHolders.length - 1; index >= targetIndex; index --) {
			realRoyalty = (10000 - totalAmount) * balanceOf(royaltyHolders[index]) / 10000;
			totalAmount = totalAmount + realRoyalty;
			if (index == 0) break;
		}

		return uint32(realRoyalty);
	}

	function _changeRoyaltyHolder(
		address _previousOwner,
		address _newOwner
	) internal {
		uint256 targetIndex = royaltyIndex[_previousOwner] - 1;
		royaltyHolders[targetIndex] = payable(_newOwner);
		royaltyIndex[_newOwner] = royaltyIndex[_previousOwner];
		delete royaltyIndex[_previousOwner];

		buyoutPrices[_newOwner] = buyoutPrices[_previousOwner];
		delete buyoutPrices[_previousOwner];
	}

	function getBuyoutList() public view returns (
		address payable[] memory royaltyHolders_,
		uint256[] memory buyoutPrices_
	) {
		uint256 length = 0;
		for(uint256 index = 0; index < royaltyHolders.length; index ++) {
			if ( buyoutPrices[royaltyHolders[index]] > 0 ) {
				length ++;
			}
		}

		royaltyHolders_ = new address payable[](length);
		buyoutPrices_ = new uint256[](length);
		length = 0;
		for(uint256 index = 0; index < royaltyHolders.length; index ++) {
			if ( buyoutPrices[royaltyHolders[index]] > 0 ) {
				royaltyHolders_[length] = royaltyHolders[index];
				buyoutPrices_[length] = buyoutPrices[royaltyHolders[index]];
				length ++;
			}
		}
	}

	// For downside protection and auction

	modifier createOrderValidator(
		uint256 _tokenPrice,
		bool _acceptOffers,
		uint256 _offerClosingTime
	) {
		require( currentOwner == payable(msg.sender) || msg.sender == factory, "Invalid token owner" );
		require( _tokenPrice > 0, "Invalid token price" );
		if ( _acceptOffers ) {
			require( _offerClosingTime > 0, "Auction orders need closing time" );
		}
		_;
	}

	modifier buyFixedPayOrderValidator( uint256 _orderId ) {
        Order storage order = orders[_orderId];
        require( order.statusOrder == OrderStatus.Active, "Invalid OrderStatus" );   
        require( order.typeOrder == OrderType.FixedPay, "Invalid OrderType" );   // AuctionType orders are directly executed by seller
        _;
    }

    modifier onlySeller( uint256 _orderId ) {
        Order storage order = orders[_orderId];
        require( payable(msg.sender) == order.sellerAddress, "Only seller can call function" );
        _;
    }

	function createOrder(
		uint256 _buyoutPrice,
		uint256 _tokenPrice,
		uint64 _protectionRate, // downside protection rate in percentage with 2 decimals (i.e. 3412 = 34.12%)
		uint256 _protectionTime,// downside protection duration (in seconds). I.e. 604800 = 1 week (60*60*24*7)
        bool _acceptOffers,     // false = fix price order, true - auction order
        uint256 _offerClosingTime   // Epoch time (in seconds) when auction will be closed (or fixed order expired)
	) external
	createOrderValidator( _tokenPrice, _acceptOffers, _offerClosingTime )
	{
		require(_protectionRate <= 10000 , "Protection rate above 100%");
		
		orderIdCount ++;
		Order storage order = orders[orderIdCount];

		order.statusOrder = OrderStatus.Active;
		order.typeOrder = _acceptOffers ? OrderType.AuctionType : OrderType.FixedPay;
		order.sellerAddress = currentOwner;
		order.buyerAddress = payable( address(0) );
		order.tokenPrice = _tokenPrice;
		order.protectionRate = _protectionRate;
		order.protectionTime = _protectionTime;
		order.offerClosingTime = _acceptOffers ? _offerClosingTime : 0;

		buyoutPrices[currentOwner] = _buyoutPrice;

		emit CreateOrder(
			orderIdCount,
			order.typeOrder,
			_tokenPrice,
			_protectionRate,
			_protectionTime
		);
	}

	function buyFixedPayOrder( uint256 _orderId ) external payable 
	buyFixedPayOrderValidator( _orderId )
	{
		Order storage order = orders[_orderId];
        require( msg.value >= order.tokenPrice, "token price" );
        
        _proceedPayments( _orderId, order.tokenPrice, order.protectionRate, payable(msg.sender) );
        order.buyerAddress = payable(msg.sender);

        emit BuyOrder(
			_orderId,
			order.typeOrder,
			order.buyerAddress,
			order.protectionAmount,
			order.soldTime + order.protectionTime
		);
	}

	function cancelOrder( uint256 _orderId ) external 
	onlySeller( _orderId )
	{
        Order storage order = orders[_orderId];
        require( order.statusOrder == OrderStatus.Active, "Invalid OrderStatus" );

        order.statusOrder = OrderStatus.Cancelled;        

        emit CancelOrder(_orderId);
    }

	function claimDownsideProtectionAmount( uint256 _orderId ) external {
        Order storage order = orders[_orderId];
        require(order.statusOrder == OrderStatus.UnderDownsideProtectionPhase, "Invalid OrderStatus");   

        // Fetch the token amount worth the face value of protection amount
        if ( msg.sender == order.sellerAddress && 
			block.timestamp > order.soldTime + order.protectionTime && 
			order.soldTime != 0 
		) {
            order.statusOrder = OrderStatus.Completed;
            uint256 value = depository.withdraw( order.depositId );      // Withdraw from depository
			uint256 allRoyaltyFees = 0;
			if ( order.tokenPrice > order.buyPrice ) {
				uint256 profit = value - order.buyPrice * order.protectionRate / 10000;
				allRoyaltyFees = _sendRoyaltyFee( profit );
			}
            order.sellerAddress.transfer( value - allRoyaltyFees );   // Transfer to Seller the whole Yield Amount
            
            emit ClaimDownsideProtection(
				_orderId,
				uint(order.statusOrder),
				order.soldTime,
				msg.sender,
				value
			);
        } else if ( block.timestamp <= order.soldTime + order.protectionTime && 
			order.soldTime != 0
		) {
			require( msg.sender == currentOwner, "sender is not NFT owner" );
            order.statusOrder = OrderStatus.Cancelled;
            currentOwner = order.sellerAddress;     // Send NFT back to seller
			_deleteRoyaltyHolder( currentOwner );
			buyPrice = order.buyPrice;
            
			uint256 value = depository.withdraw( order.depositId );      // Withdraw from depository
            order.buyerAddress.transfer( order.protectionAmount );    // Transfer to Buyer only his protection amount
            order.sellerAddress.transfer( value - order.protectionAmount );   // Transfer to Seller the Yield reward
            
            emit ClaimDownsideProtection(
				_orderId,
				uint(order.statusOrder),
				order.soldTime,
				msg.sender,
				order.protectionAmount
			);
        }
    }

	// claim money from downside protection on seller behalf
    function claimDownsideProtectionOnSellerBehalf(
		address _seller,
		uint256 _orderId
	) external {
        Order storage order = orders[_orderId];
        require(order.statusOrder == OrderStatus.UnderDownsideProtectionPhase, "Invalid OrderStatus");   

        // Fetch the token amount worth the face value of protection amount
        if (
			_seller == order.sellerAddress &&
			block.timestamp > order.soldTime + order.protectionTime &&
			order.soldTime != 0
		) {
            order.statusOrder = OrderStatus.Completed;
            uint256 value = depository.withdraw( order.depositId );      // Withdraw from depository
            uint256 allRoyaltyFees = 0;
			if ( order.tokenPrice > order.buyPrice ) {
				uint256 profit = value - order.buyPrice * order.protectionRate / 10000;
				allRoyaltyFees = _sendRoyaltyFee( profit );
			}
            order.sellerAddress.transfer( value - allRoyaltyFees );   // Transfer to Seller the whole Yield Amount
            
            emit ClaimDownsideProtection(
				_orderId,
				uint(order.statusOrder),
				order.soldTime,
				_seller,
				value
			);
        }
    }

	function createBid( uint256 _orderId ) external payable {
        Order storage order = orders[_orderId];
        uint256 previousMaxOfferAmount = order.tokenPrice;
        
		require( msg.value > previousMaxOfferAmount, "Investment too low" );
        require( order.statusOrder == OrderStatus.Active || order.statusOrder == OrderStatus.Bidded, "Invalid OrderType" );
        require( order.typeOrder == OrderType.AuctionType, "Invalid OrderType" );
        require( order.offerClosingTime >= block.timestamp, "Bidding beyond Closing Time" );

        address payable previousBuyer =  order.buyerAddress;

        // Update the new bidder details
        order.tokenPrice = msg.value;   // maxOfferAmount
        order.buyerAddress = payable(msg.sender);
        buyerBidStatus[msg.sender][_orderId] = BidStatus.Pending;
        order.statusOrder = OrderStatus.Bidded;

        // Return the funds to the previous bidder
        if ( previousBuyer != address(0) ) {
            buyerBidStatus[previousBuyer][_orderId] = BidStatus.Refunded; 
            previousBuyer.transfer( previousMaxOfferAmount );
        }

        emit CreateBid(_orderId, order.typeOrder, msg.sender, msg.value);
    }

	function executeBid( uint256 _orderId ) external {
        Order storage order = orders[_orderId];

        require(order.typeOrder == OrderType.AuctionType, "Invalid OrderType");
        require(order.statusOrder == OrderStatus.Bidded, "Invalid OrderType");
        require(order.offerClosingTime <= block.timestamp, "Executing Bid before Closing Time");

        _proceedPayments( _orderId, order.tokenPrice, order.protectionRate, order.buyerAddress );
        buyerBidStatus[order.buyerAddress][_orderId] = BidStatus.Executed;

        emit BuyOrder(
			_orderId,
			order.typeOrder,
			order.buyerAddress,
			order.protectionAmount,
			order.soldTime + order.protectionTime
		);
    }

	function _proceedPayments(
		uint256 _orderId,
		uint256 _price,
		uint256 _protectionRate,
		address payable buyerAddress
	) internal {
        Order storage order = orders[_orderId];
        order.statusOrder = OrderStatus.UnderDownsideProtectionPhase;
		
        uint256 downsideAmount = _price * _protectionRate / 10000;
		uint256 allRoyaltyFees = 0;
		if ( buyPrice > 0 && _price - buyPrice > 0 ) {
			uint256 profit = (_price - buyPrice) * (10000 - _protectionRate) / 10000;
			allRoyaltyFees = _sendRoyaltyFee( profit );
		}
        order.sellerAddress.transfer( _price - downsideAmount - allRoyaltyFees );        // Transfer the seller his amount

        uint256 depositId = depository.deposit{value: downsideAmount}();     // Invest the downside in Venus
        order.depositId = depositId;

        currentOwner = buyerAddress;     // Transfer the NFT
		royaltyHolders.push( order.sellerAddress );
		royaltyIndex[order.sellerAddress] = royaltyHolders.length;
		order.buyPrice = buyPrice;
		buyPrice = _price;
        order.protectionAmount = downsideAmount;
        order.soldTime = block.timestamp;
    }

	function _sendRoyaltyFee( uint256 _profit ) internal returns ( uint256 allRoyaltyFees_ ) {
		allRoyaltyFees_ = 0;
		if ( royaltyHolders.length > 1 ) {
			for (uint256 index = royaltyHolders.length - 1; index >= 0; index --) {
				uint256 realRoyalty = _profit * getRealRoyalty( royaltyHolders[index] ) / 10000;
				royaltyHolders[index].transfer( realRoyalty );
				allRoyaltyFees_ += realRoyalty;
			}
		}
	}
	
	// For current owner
	function withdrawNFT() external {
		require( isInitialized, "Royalty should be initialized" );
		require( currentOwner == payable(msg.sender), "Only NFT owner can withdraw NFT" );
		require( totalSupply() == 0, "All royalty should be zero" );

		IERC721(nftContract).safeTransferFrom( address(this), currentOwner, tokenID );
		IMLRFactory(factory).deleteMLR(nftContract, tokenID);
		selfdestruct( currentOwner );
	}

	function getParams() external view 
	returns (
		address nftContract_,
		uint256 tokenID_,
		string memory contractName_,
		uint256 maxRoyaltyOwner_,
		address currentOwner_,
		uint256 buyPrice_
	)
	{
		nftContract_ = nftContract;
		tokenID_ = tokenID;
		contractName_ = _contractName;
		maxRoyaltyOwner_ = maxRoyaltyOwner;
		currentOwner_ = currentOwner;
		buyPrice_ = buyPrice;
	}

}

// SPDX-License-Identifier: No License (None)
pragma solidity ^0.8.0;

interface VBep20Interface {
    function transfer(address dst, uint amount) external returns (bool);
    function transferFrom(address src, address dst, uint amount) external returns (bool);
    function approve(address spender, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function balanceOfUnderlying(address owner) external returns (uint);
    function getAccountSnapshot(address account) external view returns (uint, uint, uint, uint);
    function borrowRatePerBlock() external view returns (uint);
    function supplyRatePerBlock() external view returns (uint);
    function totalBorrowsCurrent() external returns (uint);
    function borrowBalanceCurrent(address account) external returns (uint);
    function borrowBalanceStored(address account) external view returns (uint);
    function exchangeRateCurrent() external returns (uint);
    function exchangeRateStored() external view returns (uint);
    function getCash() external view returns (uint);
    function accrueInterest() external returns (uint);
    function seize(address liquidator, address borrower, uint seizeTokens) external returns (uint);
    //function mint(uint mintAmount) external returns (uint);
    function mint() external payable;
    function redeem(uint redeemTokens) external returns (uint);
    function redeemUnderlying(uint redeemAmount) external returns (uint);
    function borrow(uint borrowAmount) external returns (uint);
    function repayBorrow(uint repayAmount) external returns (uint);
    function repayBorrowBehalf(address borrower, uint repayAmount) external returns (uint);
}

abstract contract Ownablee {
    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

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
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


contract Depository is Ownablee {

    struct DepositData {
        uint128 reserve;
        uint128 shares;
    }

    mapping(address => mapping(uint256 => DepositData)) public deposits;    // user => deposit ID => deposit details
    uint256 public depositCounter;
    uint256 public pending_vBNB;    // pending amount of BNB tokens the should be redeemed
    uint256 public reserveRate;     // percentage of deposited amount that should be left on contract.
    VBep20Interface public vBNB;    // Venus BNB token contract

    event Deposit(address indexed user, uint256 indexed depositId, uint256 value);
    event Withdraw(address indexed user, uint256 indexed depositId, uint256 value);
    event Redeem(address indexed user, uint256 indexed depositId, uint256 value);
    event RedeemPending(uint256 sharesRedeemed);
    event Pending(uint256 addedToPending, uint256 insuficiantAmount); // addedToPending - tokens that should be redeemed, insuficiantAmount - insuficiant BNB amount

    function initialize() external {
        require(_owner == address(0), "Already initialized");
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
        vBNB = VBep20Interface(0x2E7222e51c0f6e98610A1543Aa3836E092CDe62c); // BSC testnet
        //vBNB = VBep20Interface(0xA07c5b74C9B40447a954e1466938b865b6BBea36); // BSC main net
        //vBNB = VBep20Interface(0x859e9d8a4edadfEDb5A2fF311243af80F85A91b8); // ETH Ropsten testnet
        //vBNB = VBep20Interface(0x41B5844f4680a8C38fBb695b7F9CFd1F64474a72); // ETH Kovan testnet
        //vBNB = VBep20Interface(0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5); // ETH main net
    }

    // Set percentage of deposited amount that should be left on contract.
    function setReserveRate(uint256 rate) external onlyOwner {
        require(reserveRate <= 100, "Wrong rate");
        reserveRate = rate;
    }
    
    // Set Venus vBNB contract address
    function set_vBNB(address _addr) external onlyOwner {
        require(_addr != address(0));
        vBNB = VBep20Interface(_addr);
    }

    // redeem deposit from Venus on user behalf. If `amount` = 0, redeem entire deposit
    function redeemDeposit(address user, uint256 depositId, uint256 amount) external onlyOwner {
        DepositData storage d = deposits[user][depositId];
        require (d.shares != 0, "No deposit");
        uint256 balance = address(this).balance;
        if (amount == 0) amount = uint256(d.shares);
        uint256 error = vBNB.redeem(amount);
        require (error == 0, "redeem error");
        uint256 value = address(this).balance - balance;
        d.reserve += uint128(value);
        emit Redeem(user, depositId, value);
    }

    // deposit BNB
    function deposit() external payable returns(uint256 depositId){
        depositId = ++depositCounter;
        uint256 reserve = msg.value * reserveRate / 100;
        uint256 depositAmount = msg.value - reserve;
        uint256 shares;
        if (depositAmount != 0) {
            uint256 balanceBefore = vBNB.balanceOf(address(this));
            vBNB.mint{value: depositAmount}();
            shares = vBNB.balanceOf(address(this)) - balanceBefore;
        }
        deposits[msg.sender][depositId] = DepositData(uint128(reserve), uint128(shares));
        emit Deposit(msg.sender, depositId, msg.value);
    }

    // withdraw BNB
    function withdraw(uint256 depositId) external returns(uint256 value){
        DepositData memory d = deposits[msg.sender][depositId];
        require (d.reserve != 0 || d.shares != 0, "No deposit");
        uint256 balance = address(this).balance;
        value = d.reserve;
        if (balance < value) {
            redeemPending();
            balance = address(this).balance;
            // TEST do we need to update d.reserve and d.shares
            if (balance < value) {
                emit Pending(0, value - balance);
                return 0;  // Not enough balance
            }
        }
        if (d.shares != 0) {
            uint256 error = vBNB.redeem(uint256(d.shares));
            if (error != 0) {
                (uint256 shares, uint256 underlyingBalance) = _redeemMax(d.shares);
                pending_vBNB = pending_vBNB + shares;
                balance = address(this).balance;
                if (balance >= underlyingBalance + value) { //there is enough money when use reserve
                    value += underlyingBalance; // amount to return
                    emit Pending(shares, 0);
                } else {
                    d.reserve += uint128(underlyingBalance);
                    d.shares = 0;
                    emit Pending(shares, d.reserve - balance);
                    return 0;
                }
            } else {
                value = address(this).balance - balance + value; // amount to return
            }
        }
        delete deposits[msg.sender][depositId];
        safeTransferETH(msg.sender, value);
        emit Withdraw(msg.sender, depositId, value);
    }

    // redeem pending shares
    function redeemPending() public {
        (uint256 shares,) = _redeemMax(pending_vBNB);
        pending_vBNB = shares;
    }

    // redeem as many as possible shares
    // returns number of shares remain, underlyingBalance - amount that should be received for all shares
    function _redeemMax(uint256 shares) internal returns(uint256, uint256) {
        require(shares != 0, "No shares");
        uint256 underlyingBalance = vBNB.balanceOfUnderlying(address(this));
        uint256 total_vBNB = vBNB.balanceOf(address(this));
        underlyingBalance = underlyingBalance * shares / total_vBNB;    // underlyingBalance for shares
        uint256 cash = vBNB.getCash();
        require (underlyingBalance >= cash, "Redeem error"); // there is cash, but redeem error // TEST this, underlyingBalance <= cash
        uint256 error = vBNB.redeemUnderlying(cash);  // redeem available cash
        require (error == 0, "redeemUnderlying error");
        uint256 redeemedShares = total_vBNB - vBNB.balanceOf(address(this));
        require (shares >= redeemedShares, "Redeemed more shares");
        shares -= redeemedShares; // shares remain
        emit RedeemPending(redeemedShares);
        return (shares, underlyingBalance);
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }

    receive() external payable {}
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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