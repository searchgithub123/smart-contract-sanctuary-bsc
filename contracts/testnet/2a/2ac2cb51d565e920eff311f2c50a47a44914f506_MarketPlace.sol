// SPDX-License-Identifier: GPL

pragma solidity 0.8.0;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "./libs/zeppelin/token/BEP20/IBEP20.sol";
import "./interfaces/IGameNFT.sol";
import "./interfaces/ICitizen.sol";
import "./interfaces/IMarketPlace.sol";
import "./interfaces/IFOTAGame.sol";
import "./interfaces/IFOTAPricer.sol";
import "./interfaces/IEatherTransporter.sol";
import "./libs/fota/Auth.sol";
import "./interfaces/IEnergyManager.sol";

contract MarketPlace is Auth, PausableUpgradeable {
  struct Order {
    address maker;
    uint startingPrice;
    uint endingPrice;
    uint auctionDuration;
    uint rentingDuration;
    uint activatedAt;
    bool rented;
  }
  IBEP20 public fotaToken;
  IBEP20 public busdToken;
  IBEP20 public usdtToken;
  mapping (IMarketPlace.OrderKind => mapping (uint => Order)) public tradingOrders;
  mapping (IMarketPlace.OrderKind => mapping (uint => Order)) public rentingOrders;
  mapping (IMarketPlace.OrderKind => IGameNFT) public nftTokens;
  mapping (address => bool) public lockedUser;
  mapping (uint16 => bool) public lockedHeroClassId;
  mapping (uint16 => bool) public lockedItemClassId;
  mapping (uint => bool) public lockedHeroNFTId;
  mapping (uint => bool) public lockedItemNFTId;
  mapping (IMarketPlace.OrderKind => mapping(uint16 => uint)) public remainingSale;
  address public fundAdmin;
  address public treasuryAddress;
  ICitizen public citizen;
  IMarketPlace.PaymentType public paymentType;
  IFOTAGame public gameProxyContract;
  IFOTAPricer public fotaPricer;
  IEatherTransporter public eatherTransporter;
  uint public referralShare; // decimal 3
  uint public creativeShare; // decimal 3
  uint public treasuryShare; // decimal 3
  mapping(uint16 => uint) public heroPrices;
  mapping(uint16 => uint) public heroMinPrices;
  mapping(uint16 => uint) public itemPrices;
  mapping(uint16 => uint) public itemMinPrices;
  uint public minLevel;
  uint public minGene;
  mapping (address => uint) public currentRentedHeroCounter;
  mapping (uint => address) public currentRentingHero;
  uint public minRentingDuration;
  IEnergyManager public energyManager;
  mapping (uint => address) public currentRentingItem;
  uint public secondInADay;
  bool public allowMaxProfitTrading;

  event RemainingSaleUpdated(
    IMarketPlace.OrderKind kind,
    uint16 classId,
    uint remainingSale
  );
  event OrderCreated(
    IMarketPlace.OrderType indexed orderType,
    IMarketPlace.OrderKind indexed orderKind,
    uint indexed tokenId,
    address maker,
    uint startingPrice,
    uint endingPrice,
    uint auctionDuration,
    uint rentingDuration
  );
  event OrderCanceled(
    IMarketPlace.OrderType indexed orderType,
    IMarketPlace.OrderKind indexed orderKind,
    uint indexed tokenId
  );
  event OrderCanceledByAdmin(
    IMarketPlace.OrderKind indexed orderKind,
    uint indexed tokenId
  );
  event OrderTaken(
    IMarketPlace.OrderKind orderKind,
    IMarketPlace.OrderType indexed orderType,
    uint indexed tokenId,
    address indexed taker,
    IMarketPlace.PaymentType paymentType,
    uint amount,
    IMarketPlace.PaymentCurrency paymentCurrency
  );
  event FoundingOrderTaken(
    IMarketPlace.OrderKind kind,
    uint indexed tokenId,
    address indexed taker,
    IMarketPlace.PaymentType paymentType,
    uint amount,
    IMarketPlace.PaymentCurrency paymentCurrency
  );
  event OrderCompleted(
    IMarketPlace.OrderKind indexed orderKind,
    uint indexed tokenId
  );
  event MinLevelChanged(
    uint8 minLevel
  );
  event MinGeneChanged(
    uint8 minGene
  );
  event PaymentTypeChanged(
    IMarketPlace.PaymentType newMethod
  );
  event UserLocked(
    address user,
    bool locked
  );
  event HeroClassIdLocked(
    uint16 classId,
    bool locked
  );
  event HeroNFTLocked(
    uint id,
    bool locked
  );
  event ItemClassIdLocked(
    uint16 classId,
    bool locked
  );
  event ItemNFTLocked(
    uint id,
    bool locked
  );
  event HeroPriceUpdated(uint16 class, uint price);
  event HeroMinPriceUpdated(uint16 class, uint price);
  event ItemPriceUpdated(uint16 class, uint price);
  event ItemMinPriceUpdated(uint16 class, uint price);
  event ReferralSent(
    address indexed inviter,
    address indexed invitee,
    uint referralSharingAmount,
    IMarketPlace.PaymentCurrency paymentCurrency
  );

  function initialize(
    address _mainAdmin,
    address _citizen,
    IGameNFT _heroNFTToken,
    IGameNFT _itemNFTToken,
    address _treasuryAddress,
    address _fotaPricer,
    address _eatherTransporter
  ) public initializer {
    Auth.initialize(_mainAdmin);
    fundAdmin = _mainAdmin;
    treasuryAddress = _treasuryAddress;
    citizen = ICitizen(_citizen);
    nftTokens[IMarketPlace.OrderKind.hero] = _heroNFTToken;
    nftTokens[IMarketPlace.OrderKind.item] = _itemNFTToken;
    fotaPricer = IFOTAPricer(_fotaPricer);
    eatherTransporter = IEatherTransporter(_eatherTransporter);

    busdToken = IBEP20(0xD8aD05ff852ae4EB264089c377501494EA1D03C9);
    usdtToken = IBEP20(0xF5ed09f4b0E89Dff27fe48AaDf559463505fbac4);
    fotaToken = IBEP20(0x29222fD4706ba81Af5a7FA6a2D685563D76A93ee);
  }

  function makeOrder(
    IMarketPlace.OrderType _type,
    IMarketPlace.OrderKind _kind,
    uint _tokenId,
    uint _startPrice,
    uint _endingPrice,
    uint _auctionDuration,
    uint _rentingDuration
  ) public whenNotPaused {
    _validateUser();
    if (_kind == IMarketPlace.OrderKind.hero) {
      _validateHero(_type, _kind, _tokenId, _startPrice, _endingPrice);
    } else if (_kind == IMarketPlace.OrderKind.item) {
      _validateItem(_type, _kind, _tokenId, _startPrice, _endingPrice);
    }
    if (_startPrice != _endingPrice) {
      require(_auctionDuration >= 1 days && _auctionDuration <= 365 days, "auctionDuration 401");
    }
    if (_type == IMarketPlace.OrderType.renting) {
      require(_rentingDuration >= minRentingDuration && _rentingDuration <= 365 days && _rentingDuration % secondInADay == 0, "rentingDuration 401");
    }
    require(nftTokens[_kind].ownerOf(_tokenId) == msg.sender, "not owner");
    _transferNFTToken(_kind, msg.sender, address(this), _tokenId);
    Order memory order = Order(
      msg.sender,
      _startPrice,
      _endingPrice,
      _auctionDuration,
      _rentingDuration,
      block.timestamp,
      false
    );
    _type == IMarketPlace.OrderType.trading ? tradingOrders[_kind][_tokenId] = order : rentingOrders[_kind][_tokenId] = order;
    emit OrderCreated(_type, _kind, _tokenId, msg.sender, _startPrice, _endingPrice, _auctionDuration, _rentingDuration);
  }

  function cancelOrder(IMarketPlace.OrderKind _kind, uint _tokenId) external whenNotPaused {
    Order storage tradingOrder = tradingOrders[_kind][_tokenId];
    if (_isActive(tradingOrder)) {
      _cancelTradingOrder(_kind, _tokenId, tradingOrder);
    } else {
      _checkCancelRentingOrder(_kind, _tokenId);
    }
  }

  function takeOrder(IMarketPlace.OrderKind _kind, uint _tokenId, IMarketPlace.PaymentCurrency _paymentCurrency) external whenNotPaused {
    _validateTaker(_paymentCurrency);
    uint16 _classId = nftTokens[_kind].getClassId(_tokenId);
    if (_kind == IMarketPlace.OrderKind.hero) {
      require(!lockedHeroNFTId[_tokenId], "hero 401");
      require(!lockedHeroClassId[_classId], "heroClassId 401");
    } else if (_kind == IMarketPlace.OrderKind.item) {
      require(!lockedItemNFTId[_tokenId], "item 401");
      require(!lockedItemClassId[_classId], "itemClassId 401");
    }
    Order storage order = tradingOrders[_kind][_tokenId];
    IMarketPlace.OrderType orderType = IMarketPlace.OrderType.trading;
    if (!_isActive(order)) {
      order = rentingOrders[_kind][_tokenId];
      orderType = IMarketPlace.OrderType.renting;
    }
    require(_isActive(order), "not active");
    require(order.maker != msg.sender, "self buying");
    uint currentPrice = _getCurrentPrice(_kind, _paymentCurrency, order, _tokenId);
    _takeFund(currentPrice, _paymentCurrency);
    address maker = order.maker;
    if (orderType == IMarketPlace.OrderType.trading) {
      _removeTradingOrder(_kind, _tokenId);
    } else {
      _markRentingOrderAsRented(_kind, _tokenId);
    }
    if (currentPrice > 0) {
      _releaseFund(_kind, maker, currentPrice, _tokenId, _paymentCurrency);
    }
    if (orderType == IMarketPlace.OrderType.trading) {
      if (_kind == IMarketPlace.OrderKind.item) {
        nftTokens[_kind].updateFailedUpgradingAmount(_tokenId, 0);
      }
      _transferNFTToken(_kind, address(this), msg.sender, _tokenId);
    }
    emit OrderTaken(_kind, orderType, _tokenId, msg.sender, paymentType, currentPrice, _paymentCurrency);
  }

  function takeFounding(IMarketPlace.OrderKind _kind, uint16 _classId, IMarketPlace.PaymentCurrency _paymentCurrency) external whenNotPaused {
    require(remainingSale[_kind][_classId] > 0, "out of stock");
    remainingSale[_kind][_classId]--;
    _validateTaker(_paymentCurrency);
    uint currentPrice;
    uint tokenId;
    if (_kind == IMarketPlace.OrderKind.hero) {
      currentPrice = heroPrices[_classId];
      tokenId = nftTokens[_kind].mintHero(msg.sender, _classId, currentPrice, 0);
    } else {
      currentPrice = itemPrices[_classId];
      tokenId = nftTokens[_kind].mintItem(msg.sender, 1, _classId, currentPrice, 0);
    }
    if (_isFotaPayment(_paymentCurrency)) {
      currentPrice = currentPrice * 1000 / fotaPricer.fotaPrice();
    }
    require(currentPrice > 0, "price invalid");
    _takeFund(currentPrice, _paymentCurrency);
    _releaseFund(_kind, fundAdmin, currentPrice, tokenId, _paymentCurrency);
    emit FoundingOrderTaken(_kind, tokenId, msg.sender, paymentType, currentPrice, _paymentCurrency);
  }

  function getNFTBack(IMarketPlace.OrderKind _kind, uint _tokenId) external whenNotPaused {
    Order storage order = rentingOrders[_kind][_tokenId];
    require(order.maker == msg.sender, "not owner");
    require(order.rented, "order not completed");
    require(block.timestamp >= order.activatedAt + order.rentingDuration, "wait more time");
    _removeRentingOrder(_kind, _tokenId);
    if (_kind == IMarketPlace.OrderKind.hero) {
      if (currentRentingHero[_tokenId] != address(0)) {
        energyManager.updatePoint(currentRentingHero[_tokenId], -1);
        if (currentRentedHeroCounter[currentRentingHero[_tokenId]] > 0) {
          currentRentedHeroCounter[currentRentingHero[_tokenId]] -= 1;
        }
        delete currentRentingHero[_tokenId];
      }
    } else if (_kind == IMarketPlace.OrderKind.item) {
      delete currentRentingItem[_tokenId];
    }
    _transferNFTToken(_kind, address(this), msg.sender, _tokenId);
    emit OrderCompleted(_kind, _tokenId);
  }

  function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
    return interfaceId == type(IERC721Upgradeable).interfaceId;
  }

  // PRIVATE FUNCTIONS

  function _convertFotaToUsd(uint _amount) private view returns (uint) {
    return _amount * fotaPricer.fotaPrice() / 1000;
  }

  function _validateTaker(IMarketPlace.PaymentCurrency _paymentCurrency) private view {
    _validatePaymentMethod(_paymentCurrency);
    _validateUser();
    require(citizen.isCitizen(msg.sender), "taker 401");
  }

  function _releaseFund(IMarketPlace.OrderKind _kind, address _maker, uint _currentPrice, uint _tokenId, IMarketPlace.PaymentCurrency _paymentCurrency) private {
    uint sharingAmount = _currentPrice * (referralShare + creativeShare + treasuryShare) / 100000;
    _transferFund(_maker, _currentPrice - sharingAmount, _paymentCurrency);
    _shareOrderValue(_kind, _tokenId, sharingAmount, _paymentCurrency);
  }

  function _isFotaPayment(IMarketPlace.PaymentCurrency _paymentCurrency) private view returns (bool) {
    return paymentType == IMarketPlace.PaymentType.fota || (paymentType == IMarketPlace.PaymentType.all && _paymentCurrency == IMarketPlace.PaymentCurrency.fota);
  }

  function _cancelTradingOrder(IMarketPlace.OrderKind _kind, uint _tokenId, Order storage _tradingOrder) private {
    require(_tradingOrder.maker == msg.sender, "not owner of order");
    _removeTradingOrder(_kind, _tokenId);
    _transferNFTToken(_kind, address(this), msg.sender, _tokenId);
    emit OrderCanceled(IMarketPlace.OrderType.trading, _kind, _tokenId);
  }

  function _checkCancelRentingOrder(IMarketPlace.OrderKind _kind, uint _tokenId) private {
    Order storage rentingOrder = rentingOrders[_kind][_tokenId];
    require(_isActive(rentingOrder), "rentingOrder not active");
    require(rentingOrder.maker == msg.sender, "not owner of order");
    _removeRentingOrder(_kind, _tokenId);
    _transferNFTToken(_kind, address(this), msg.sender, _tokenId);
    emit OrderCanceled(IMarketPlace.OrderType.renting, _kind, _tokenId);
  }

  function _isActive(Order storage _order) private view returns (bool) {
    return _order.activatedAt > 0 && !_order.rented;
  }

  function _removeTradingOrder(IMarketPlace.OrderKind _kind, uint _tokenId) private {
    delete tradingOrders[_kind][_tokenId];
  }

  function _markRentingOrderAsRented(IMarketPlace.OrderKind _kind, uint _tokenId) private {
    rentingOrders[_kind][_tokenId].rented = true;
    rentingOrders[_kind][_tokenId].activatedAt = block.timestamp;
    if (_kind == IMarketPlace.OrderKind.hero) {
      currentRentedHeroCounter[msg.sender] += 1;
      currentRentingHero[_tokenId] = msg.sender;
      bool reachMaxProfit = nftTokens[IMarketPlace.OrderKind.hero].reachMaxProfit(_tokenId);
      if (!reachMaxProfit) {
        energyManager.updatePoint(msg.sender, 1);
      }
    } else if (_kind == IMarketPlace.OrderKind.item) {
      currentRentingItem[_tokenId] = msg.sender;
    }
	}
  function _removeRentingOrder(IMarketPlace.OrderKind _kind, uint _tokenId) private {
    delete rentingOrders[_kind][_tokenId];
  }

  function _getCurrentPrice(IMarketPlace.OrderKind _kind, IMarketPlace.PaymentCurrency _paymentCurrency, Order storage _order, uint _tokenId) private view returns (uint) {
    uint currentPrice;

    if (_order.maker == address(this)) {
      currentPrice = _getPriceFromTokenId(_kind, _tokenId);
    } else {
      uint secondPassed;
      if (block.timestamp > _order.activatedAt) {
        secondPassed = block.timestamp - _order.activatedAt;
      }
      if (secondPassed >= _order.auctionDuration) {
        currentPrice = _order.endingPrice;
      } else {
        int changedPrice = int(_order.endingPrice) - int(_order.startingPrice);
        int currentPriceChange = changedPrice * int(secondPassed) / int(_order.auctionDuration);
        int currentPriceInt = int(_order.startingPrice) + currentPriceChange;
        currentPrice = uint(currentPriceInt);
      }
    }

    return _paymentCurrency == IMarketPlace.PaymentCurrency.fota ? currentPrice * 1000 / fotaPricer.fotaPrice() : currentPrice;
  }

  function _getPriceFromTokenId(IMarketPlace.OrderKind _kind, uint _tokenId) private view returns (uint) {
    require(_kind == IMarketPlace.OrderKind.hero || _kind == IMarketPlace.OrderKind.item, "kind invalid");
    if (_kind == IMarketPlace.OrderKind.hero) {
      (,,, uint16 class,,,) = nftTokens[_kind].getHero(_tokenId);
      return heroPrices[class];
    } else {
      (, uint16 class,,,) = nftTokens[_kind].getItem(_tokenId);
      return itemPrices[class];
    }
  }

  function _takeFund(uint _amount, IMarketPlace.PaymentCurrency _paymentCurrency) private {
    if (paymentType == IMarketPlace.PaymentType.fota) {
      _takeFundFOTA(_amount);
    } else if (paymentType == IMarketPlace.PaymentType.usd) {
      _takeFundUSD(_amount, _paymentCurrency);
    } else if (_paymentCurrency == IMarketPlace.PaymentCurrency.fota) {
      _takeFundFOTA(_amount);
    } else {
      _takeFundUSD(_amount, _paymentCurrency);
    }
  }

  function _takeFundUSD(uint _amount, IMarketPlace.PaymentCurrency _paymentCurrency) private {
    require(_paymentCurrency != IMarketPlace.PaymentCurrency.fota, "paymentCurrency invalid");
    IBEP20 usdToken = _paymentCurrency == IMarketPlace.PaymentCurrency.busd ? busdToken : usdtToken;
    require(usdToken.allowance(msg.sender, address(this)) >= _amount, "MarketPlace: insufficient balance");
    require(usdToken.balanceOf(msg.sender) >= _amount, "allowance invalid");
    require(usdToken.transferFrom(msg.sender, address(this), _amount), "transfer error");
  }

  function _takeFundFOTA(uint _amount) private {
    require(fotaToken.allowance(msg.sender, address(this)) >= _amount, "allowance invalid");
    require(fotaToken.balanceOf(msg.sender) >= _amount, "MarketPlace: insufficient balance");
    require(fotaToken.transferFrom(msg.sender, address(this), _amount), "transfer error");
  }

  function _transferFund(address _receiver, uint _amount, IMarketPlace.PaymentCurrency _paymentCurrency) private {
    if (_receiver == address(this)) {
      _receiver = fundAdmin;
    }
    if (paymentType == IMarketPlace.PaymentType.usd) {
      _transferFundUSD(_receiver, _amount, _paymentCurrency);
    } else if (paymentType == IMarketPlace.PaymentType.fota) {
      _transferFundFOTA(_receiver, _amount);
    } else if (_paymentCurrency == IMarketPlace.PaymentCurrency.fota) {
      _transferFundFOTA(_receiver, _amount);
    } else {
      _transferFundUSD(_receiver, _amount, _paymentCurrency);
    }
  }

  function _transferFundUSD(address _receiver, uint _amount, IMarketPlace.PaymentCurrency _paymentCurrency) private {
    if (_paymentCurrency == IMarketPlace.PaymentCurrency.usdt) {
      require(usdtToken.transfer(_receiver, _amount), "transfer usdt error");
    } else {
      require(busdToken.transfer(_receiver, _amount), "transfer busd error");
    }
  }

  function _transferFundFOTA(address _receiver, uint _amount) private {
    require(fotaToken.transfer(_receiver, _amount), "transfer fota error");
  }

  function _transferNFTToken(IMarketPlace.OrderKind _kind, address _from, address _to, uint _tokenId) private {
    nftTokens[_kind].transferFrom(_from, _to, _tokenId);
  }

  function _shareOrderValue(IMarketPlace.OrderKind _kind, uint _tokenId, uint _totalShareAmount, IMarketPlace.PaymentCurrency _paymentCurrency) private {
    uint totalSharePercent = referralShare + creativeShare + treasuryShare;
    uint referralSharingAmount = referralShare * _totalShareAmount / totalSharePercent;
    uint treasurySharingAmount = treasuryShare * _totalShareAmount / totalSharePercent;
    uint creativeSharingAmount = creativeShare * _totalShareAmount / totalSharePercent;
    address inviter = citizen.getInviter(msg.sender);
    if (inviter == address(0)) {
      inviter = treasuryAddress;
    } else {
      bool validInviter = _validateInviter(inviter);
      if (!validInviter) {
        inviter = treasuryAddress;
      }
    }
    emit ReferralSent(inviter, msg.sender, referralSharingAmount, _paymentCurrency);
    _transferFund(inviter, referralSharingAmount, _paymentCurrency);

    address creator = nftTokens[_kind].getCreator(_tokenId);
    if (creator == address(0)) {
      creator = fundAdmin;
    }
    _transferFund(creator, creativeSharingAmount, _paymentCurrency);

    _transferFund(treasuryAddress, treasurySharingAmount, _paymentCurrency);
  }

  function _validateInviter(address _inviter) private view returns (bool) {
    return gameProxyContract.validateInviter(_inviter);
  }

  function _validatePaymentMethod(IMarketPlace.PaymentCurrency _paymentCurrency) private view {
    if (paymentType == IMarketPlace.PaymentType.fota) {
      require(_paymentCurrency == IMarketPlace.PaymentCurrency.fota, "paymentCurrency invalid");
    } else if (paymentType == IMarketPlace.PaymentType.usd) {
      require(_paymentCurrency != IMarketPlace.PaymentCurrency.fota, "paymentCurrency invalid");
    }
  }

  function _validateUser() private view {
    require(!lockedUser[msg.sender], "user locked");
  }

  function _validateHero(IMarketPlace.OrderType _type, IMarketPlace.OrderKind _kind, uint _tokenId, uint _startPrice, uint _endingPrice) private view {
    (,,,uint16 _id,, uint8 level,) = nftTokens[_kind].getHero(_tokenId);
    require(level >= minLevel, "level invalid");
    require(!lockedHeroClassId[_id], "MarketPlace: class hero locked");
    require(!lockedHeroNFTId[_tokenId], "hero locked");
    if(!allowMaxProfitTrading) {
      require(!nftTokens[_kind].reachMaxProfit(_tokenId), "MarketPlace: hero reached max profit");
    }

    if (_type == IMarketPlace.OrderType.trading) {
      require(_startPrice >= heroMinPrices[_id] && _endingPrice >= heroMinPrices[_id], "price invalid");
    }
  }

  function _validateItem(IMarketPlace.OrderType _type, IMarketPlace.OrderKind _kind, uint _tokenId, uint _startPrice, uint _endingPrice) private view {
    (uint gene, uint16 _class,,,) = nftTokens[_kind].getItem(_tokenId);
    if (eatherTransporter.openEather()) {
      require(gene == 0 || gene >= minGene, "gene invalid");
    } else {
      require(gene >= minGene, "MarketPlace: item gene invalid");
    }
    require(!lockedItemClassId[_class], "itemClassId locked");
    require(!lockedItemNFTId[_tokenId], "item locked");

    if (_type == IMarketPlace.OrderType.trading) {
      require(_startPrice >= itemMinPrices[_class] && _endingPrice >= itemMinPrices[_class], "405");
    }
  }

  // ADMIN FUNCTIONS

  function setMinLevel(uint8 _minLevel) external onlyMainAdmin {
    require(_minLevel <= 25);
    minLevel = _minLevel;
    emit MinLevelChanged(_minLevel);
  }

  function setMinGene(uint8 _minGene) external onlyMainAdmin {
    minGene = _minGene;
    emit MinGeneChanged(_minGene);
  }

  function updatePaymentType(IMarketPlace.PaymentType _type) external onlyMainAdmin {
    paymentType = _type;
    emit PaymentTypeChanged(_type);
  }

  function adminCancelOrder(IMarketPlace.OrderKind _kind, uint _tokenId) external onlyMainAdmin {
    Order storage tradingOrder = tradingOrders[_kind][_tokenId];
    address maker;
    if (_isActive(tradingOrder)) {
      maker = tradingOrder.maker;
      _removeTradingOrder(_kind, _tokenId);
      _transferNFTToken(_kind, address(this), maker, _tokenId);
    } else {
      Order storage rentingOrder = rentingOrders[_kind][_tokenId];
      require(_isActive(rentingOrder));
      maker = rentingOrder.maker;
      _removeRentingOrder(_kind, _tokenId);
      _transferNFTToken(_kind, address(this), maker, _tokenId);
    }
    emit OrderCanceledByAdmin(_kind, _tokenId);
  }

  function updateLockUserStatus(address _user, bool _locked) external onlyMainAdmin {
    lockedUser[_user] = _locked;
    emit UserLocked(_user, _locked);
  }

  function updateLockHeroStatus(uint16 _id, bool _locked) external onlyMainAdmin {
    lockedHeroClassId[_id] = _locked;
    emit HeroClassIdLocked(_id, _locked);
  }

  function updateLockHeroNFTIdStatus(uint _id, bool _locked) external onlyMainAdmin {
    lockedHeroNFTId[_id] = _locked;
    emit HeroNFTLocked(_id, _locked);
  }

  function updateLockItemStatus(uint16 _id, bool _locked) external onlyMainAdmin {
    lockedItemClassId[_id] = _locked;
    emit ItemClassIdLocked(_id, _locked);
  }

  function updateLockItemNFTIdStatus(uint _id, bool _locked) external onlyMainAdmin {
    lockedItemNFTId[_id] = _locked;
    emit ItemNFTLocked(_id, _locked);
  }

  function setShares(uint _referralShare, uint _creatorShare, uint _treasuryShare) external onlyMainAdmin {
    require(_referralShare > 0 && _referralShare <= 10000);
    referralShare = _referralShare;
    require(_creatorShare > 0 && _creatorShare <= 10000);
    creativeShare = _creatorShare;
    require(_treasuryShare > 0 && _treasuryShare <= 10000);
    treasuryShare = _treasuryShare;
  }

  function updateFundAdmin(address _address) external onlyMainAdmin {
    require(_address != address(0));
    fundAdmin = _address;
  }

  function updateHeroPrice(uint16 _class, uint _price) external onlyMainAdmin {
    heroPrices[_class] = _price;
    emit HeroPriceUpdated(_class, _price);
  }

  function updateHeroMinPrice(uint16 _class, uint _price) external onlyMainAdmin {
    heroMinPrices[_class] = _price;
    emit HeroMinPriceUpdated(_class, _price);
  }

  function updateItemPrice(uint16 _class, uint _price) external onlyMainAdmin {
    itemPrices[_class] = _price;
    emit ItemPriceUpdated(_class, _price);
  }

  function updateItemMinPrice(uint16 _class, uint _price) external onlyMainAdmin {
    itemMinPrices[_class] = _price;
    emit ItemMinPriceUpdated(_class, _price);
  }

  function updatePauseStatus(bool _paused) external onlyMainAdmin {
    if(_paused) {
      _pause();
    } else {
      _unpause();
    }
  }

  function setRemainingSale(IMarketPlace.OrderKind _kind, uint16 _classId, uint _remainingSale) external onlyMainAdmin {
    if (_kind == IMarketPlace.OrderKind.hero) {
      uint16 totalId = nftTokens[_kind].countId();
      require(_classId <= totalId, "classId invalid");
    }
    remainingSale[_kind][_classId] = _remainingSale;
    emit RemainingSaleUpdated(_kind, _classId, _remainingSale);
  }

  function updateMinRentingDuration(uint _minRentingDuration) external onlyMainAdmin {
    minRentingDuration = _minRentingDuration;
  }

  function updateSecondInADay(uint _secondInDay) external onlyMainAdmin {
    secondInADay = _secondInDay;
  }

  function updateAllowMaxProfitTrading(bool _allowed) external onlyMainAdmin {
    allowMaxProfitTrading = _allowed;
  }

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

/**
 * @title ERC20 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
interface IBEP20 {

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

abstract contract Auth is Initializable {

  address public mainAdmin;
  address public contractAdmin;

  event OwnershipTransferred(address indexed _previousOwner, address indexed _newOwner);
  event ContractAdminUpdated(address indexed _newOwner);

  function initialize(address _mainAdmin) virtual public initializer {
    mainAdmin = _mainAdmin;
    contractAdmin = _mainAdmin;
  }

  modifier onlyMainAdmin() {
    require(_isMainAdmin(), "onlyMainAdmin");
    _;
  }

  modifier onlyContractAdmin() {
    require(_isContractAdmin() || _isMainAdmin(), "onlyContractAdmin");
    _;
  }

  function transferOwnership(address _newOwner) onlyMainAdmin external {
    require(_newOwner != address(0x0));
    mainAdmin = _newOwner;
    emit OwnershipTransferred(msg.sender, _newOwner);
  }

  function updateContractAdmin(address _newAdmin) onlyMainAdmin external {
    require(_newAdmin != address(0x0));
    contractAdmin = _newAdmin;
    emit ContractAdminUpdated(_newAdmin);
  }

  function _isMainAdmin() public view returns (bool) {
    return msg.sender == mainAdmin;
  }

  function _isContractAdmin() public view returns (bool) {
    return msg.sender == contractAdmin;
  }
}

// SPDX-License-Identifier: GPL

pragma solidity 0.8.0;

import "./IGameNFT.sol";

interface IMarketPlace {
  enum OrderType {
    trading,
    renting
  }
  enum OrderKind {
    hero,
    item,
    land
  }
  enum PaymentType {
    fota,
    usd,
    all
  }
  enum PaymentCurrency {
    fota,
    busd,
    usdt
  }
  function fotaToken() external view returns (address);
  function busdToken() external view returns (address);
  function usdtToken() external view returns (address);
  function citizen() external view returns (address);
  function takeOrder(OrderKind _kind, uint _tokenId, PaymentCurrency _paymentCurrency) external;
  function paymentType() external view returns (PaymentType);
  function currentRentedHeroCounter(address _user) external view returns (uint);
  function currentRentingHero(uint _heroId) external view returns (address);
  function currentRentingItem(uint _itemId) external view returns (address);
  function increaseCurrentRentedHeroCounter(uint _heroId) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import '@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol';

interface IGameNFT is IERC721Upgradeable {
  function mintHero(address _owner, uint16 _classId, uint _price, uint _index) external returns (uint);
  function mintHeroes(address _owner, uint16 _classId, uint _price, uint _quantity) external;
  function heroes(uint _tokenId) external returns (uint16, uint, uint8, uint32, uint, uint, uint);
  function getHero(uint _tokenId) external view returns (string memory, string memory, string memory, uint16, uint, uint8, uint32);
  function getHeroStrength(uint _tokenId) external view returns (uint, uint, uint, uint, uint);
  function getOwnerHeroes(address _owner) external view returns(uint[] memory);
  function getOwnerTotalHeroThatNotReachMaxProfit(address _owner) external view returns(uint);
  function increaseTotalProfited(uint[] memory _tokenIds, uint[] memory _amounts) external;
  function reachMaxProfit(uint _tokenId) external view returns (bool);
  function mintItem(address _owner, uint8 _gene, uint16 _class, uint _price, uint _index) external returns (uint);
  function getItem(uint _tokenId) external view returns (uint8, uint16, uint, uint, uint);
  function getClassId(uint _tokenId) external view returns (uint16);
  function burn(uint _tokenId) external;
  function getCreator(uint _tokenId) external view returns (address);
  function countId() external view returns (uint16);
  function updateOwnPrice(uint _tokenId, uint _ownPrice) external;
  function updateAllOwnPrices(uint _tokenId, uint _ownPrice, uint _fotaOwnPrice) external;
  function updateFailedUpgradingAmount(uint _tokenId, uint _amount) external;
  function skillUp(uint _tokenId, uint8 _index) external;
  function experienceUp(uint[] memory _tokenIds, uint32[] memory _experiences) external;
  function experienceCheckpoint(uint8 _level) external view returns (uint32);
  function fotaOwnPrices(uint _tokenId) external view returns (uint);
  function fotaFailedUpgradingAmount(uint _tokenId) external view returns (uint);
}

// SPDX-License-Identifier: GPL

pragma solidity 0.8.0;

interface IFOTAPricer {
  function fotaPrice() external view returns (uint);
}

// SPDX-License-Identifier: GPL

pragma solidity 0.8.0;

interface IFOTAGame {
  function validateInviter(address _inviter) external view returns (bool);
  function getTotalWinInDay(address _user) external view returns (uint);
  function getTotalPVEWinInDay(address _user) external view returns (uint);
  function getTotalPVPWinInDay(address _user) external view returns (uint);
  function getTotalDUALWinInDay(address _user) external view returns (uint);
  function updateLandLord(uint _mission, address _landLord) external;
}

// SPDX-License-Identifier: GPL

pragma solidity 0.8.0;

interface IEnergyManager {
  function updateEnergy(uint[] memory _heroIds, uint[] memory _energies) external returns (uint totalIdValue);
  function updatePoint(address _user, int _point) external;
  function getUserCurrentEnergy(address _user) external view returns (uint);
  function energies(address _user) external view returns (uint, uint, uint, int, uint);
}

// SPDX-License-Identifier: GPL

pragma solidity 0.8.0;

interface IEatherTransporter {
  function openEather() external view returns (bool);
}

// SPDX-License-Identifier: GPL

pragma solidity 0.8.0;

interface ICitizen {
  function isCitizen(address _address) external view returns (bool);
  function register(address _address, string memory _userName, address _inviter) external returns (uint);
  function getInviter(address _address) external returns (address);
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
interface IERC165Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}