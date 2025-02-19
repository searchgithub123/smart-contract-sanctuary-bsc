// SPDX-License-Identifier: MIT
// Honor Protocol - Mining Token
// Duan
//-----------------------------------------------------------------------------------------------------------------------------------

pragma solidity >= 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./Marketplace.sol";
import "./NFTStaking.sol";

contract HonorMining is Ownable, ReentrancyGuard {

  struct ArmyRankMining {
    uint rank;
    uint mining;
    uint protocol;
    uint creator;
    uint holder;
    uint dev;
    uint global;
    uint counter;
    bool archived;  // allows NFT blacklisting
    uint lastWithdrawalAt; // timestamp of latest reward withdrawal
  }
  uint MiningAmount; uint ProtocolAmount; uint HolderAmount; uint CreatorAmount; uint DevAmount; uint GlobalAmount; uint MiningCounter;

  struct HonorMint {
    uint totalmining;
    uint rank1;
    uint rank2;
    uint rank3;
    uint rank4;
    uint rank5;
    uint rank6;
    uint rank7;
    uint rank8;
    uint totalprotocol;
    uint totalcreator;
    uint totalholder;
    uint totaldev;
    uint totalglobal;
  }
  uint TotalMining; uint TotalProtocol; uint TotalCreator; uint TotalHolder; uint TotalDev; uint TotalGlobal;

  mapping(uint => ArmyRankMining) public ArmyRankMinings;
  mapping(uint => HonorMint) public HonorMints;

  uint [] public MiningAmounts = [
    1     * 10 ** 18, // 0 - PRIVATE:    1.0  HONOR
    1.25  * 10 ** 18, // 1 - CORPORAL:   1.25 HONOR
    1.5   * 10 ** 18, // 2 - SERGEANT:   1.5  HONOR
    1.75  * 10 ** 18, // 3 - LIEUTENANT: 1.75 HONOR
    2     * 10 ** 18, // 4 - CAPTAIN:    2.0  HONOR
    2.3   * 10 ** 18, // 5 - MAJOR:      2.3  HONOR
    2.6   * 10 ** 18, // 6 - COLONEL:    2.6  HONOR
    3     * 10 ** 18  // 7 - GENERAL:    3.0  HONOR
  ];

  HonorProtocol public honorAddress;
  ArmyRankNFT public armyRankNFT;
  Metadata public metadataAddress;
  HonorMarketplace public marketplaceAddress;
  NFTStaking public stakingAddress;
  
  address public honorDao; // Nodes @ Yield Rank
  // uint256 public MiningDay = 864000; // 10 days per token
  uint256 public MiningDay = 120; // 3 minute for testnet
  bool public miningAlive = false;
  address Seller; address Owner; address StakeCreator; address Staker; address Creator; 
  uint MintAmount; uint MinerAmount;

  constructor(HonorProtocol _honorAddress, ArmyRankNFT _armynftAddress, Metadata _metadataAddress, HonorMarketplace _marketplace, NFTStaking _nftstaking) {
    honorAddress = _honorAddress;
    armyRankNFT = _armynftAddress;
    metadataAddress = _metadataAddress;
    marketplaceAddress = _marketplace;
    stakingAddress = _nftstaking;
  }

  function archiveNFT(uint256 _tokenId) external onlyOwner {
    ArmyRankMining storage Id = ArmyRankMinings[_tokenId];
    require(!Id.archived, "This NFT is already archived.");
    Id.archived = true;
  }
  function activateNFT(uint256 _tokenId) external onlyOwner {
    ArmyRankMining storage Id = ArmyRankMinings[_tokenId];
    require(Id.archived, "This NFT is already active.");
    Id.archived = false;
  }

  function miningOn() external onlyOwner {
    miningAlive = true;
  }
  function miningOff() external onlyOwner {
    miningAlive = false;
  }
  // Owner - SET DAO SMART CONTRACT ADDRESS
  function setHonorDao(address _honorDao) external onlyOwner {
    honorDao = _honorDao;
  }
  function setNFTStaking(NFTStaking _stakingAddress) external onlyOwner {
    stakingAddress = _stakingAddress;
  }
  function setMarketplace(HonorMarketplace _marketplaceAddress) external onlyOwner {
    marketplaceAddress = _marketplaceAddress;
  }
  function setMetadata(Metadata _metadataAddress) external onlyOwner {
    metadataAddress = _metadataAddress;
  }
  function setMiningAmounts(uint _MiningAmounts, uint _miningType) external onlyOwner {
    require(_MiningAmounts > 0, "Required amount cant be is zero!");
    require(_miningType >= 0 && _miningType <= 7, "Mining type not recognized - Set mining amount");
    MiningAmounts[_miningType] = _MiningAmounts;
  }
  function setMiningDay(uint _seconds) external onlyOwner {
    require(_seconds >= 864000, "Min 86400 (10 days)");
    MiningDay = _seconds;
  }

  function isMiningAvailable(uint _isType, address _to, uint256 _tokenId, uint _timestamp) external view returns(bool){
    require(_to != address(0), "_to is address 0");
    require (_isType >= 1 && _isType <=2, "Istype is wrong");
    
    if (_isType == 1){
    require(msg.sender == _to, "Only user can see its own funds.");
    require(_to == armyRankNFT.ownerOf(_tokenId), "You are not the owner of this TokenId - (Mining Available)");
    }
    else if (_isType == 2){
    require(_to != armyRankNFT.ownerOf(_tokenId), "You are not the owner of this TokenId - (Mining Available)");
    }

    ArmyRankMining storage Id = ArmyRankMinings[_tokenId];
    require(!Id.archived, "This Token Id is blacklisted.");

    return ((_timestamp - Id.lastWithdrawalAt) / 120) >= 1;
  }

  function addressReturns (uint _tokenId) internal returns (address, address, address, address, address) {
    Seller = marketplaceAddress.checkSeller(_tokenId);
    Creator = marketplaceAddress.checkCreator(_tokenId);
    Owner = armyRankNFT.ownerOf(_tokenId);
    StakeCreator = stakingAddress.checkCreator(_tokenId);
    Staker = stakingAddress.checkStaker(_tokenId);

    return (Seller, Creator, Owner, StakeCreator, Staker);
  }

  function MiningHonor(uint miningType, address _to, uint256 _tokenId) external {
    require(miningAlive == true, "Honor Protocol Mining Offline");
    require(honorDao != address(0) && address(stakingAddress) != address(0) && address(marketplaceAddress) != address(0), "HonorDao or StakeDao or Marketplace address 0 or not match - Mining & Token");
    require(msg.sender == _to, "Only user can mining its own token.");
    require (miningType >= 1 && miningType <=4, " Mining type not recognized");

    (Seller, Creator, Owner, StakeCreator, Staker) = addressReturns(_tokenId);

    if (miningType == 1){
      // Wallet Mining
      require(_to == armyRankNFT.ownerOf(_tokenId),"You are not the owner of this TokenId - (Wallet)"); // Check NFT from wallet (Owner)
      startMining(_to,_tokenId);
    }
    else if (miningType == 2){
      // Marketplace Mining
      require(_to == Seller,"You are not the owner of this TokenId - (Inside Marketplace)"); // Check NFT from marketplace (Owner)
      startMining(_to,_tokenId);
    }
    else if (miningType == 3){
      // NFT Staking Mining
      require(Owner == address(stakingAddress), "You are not the owner of this TokenId - (Inside Staking)");
       startMining(_to,_tokenId);
    }
    else if (miningType == 4){
      // Global Mining
      require(_to != armyRankNFT.ownerOf(_tokenId),"Please use MiningGo - (Wallet)"); // Check NFT from wallet (other Owner
      require(Creator != address(0),"Global minter only - (must at least once Inside Marketplace)"); // Check NFT from marketplace (Creator)
      startMining(_to,_tokenId);
    }
  }

  function startMining(address _to, uint _tokenId) private { 
    ArmyRankMining storage Id = ArmyRankMinings[_tokenId];
    require(!Id.archived, "This Token Id is blacklisted.");
    uint daysSinceLastMining = (block.timestamp - Id.lastWithdrawalAt) / MiningDay;
    require(daysSinceLastMining >= 1, "Not past 10 days");
    uint rank = metadataAddress.checkRank(1,_tokenId);
    require (rank >= 1 && rank <=8, "No Army Rank");
    
    if (rank == 1){
      MinerAmount = MiningAmounts[0];
      (MintAmount) = miningReward(_tokenId, _to, MinerAmount);
      miningShare(_tokenId, rank, MintAmount,_to, MinerAmount);
    }
    else if (rank == 2){
      MinerAmount = MiningAmounts[1];
      (MintAmount) = miningReward(_tokenId, _to, MinerAmount);
      miningShare(_tokenId, rank, MintAmount,_to, MinerAmount);
    }
    else if (rank == 3){
      MinerAmount = MiningAmounts[2];
      (MintAmount) = miningReward(_tokenId, _to, MinerAmount);
      miningShare(_tokenId, rank, MintAmount,_to, MinerAmount);
    }
    else if (rank == 4){
      MinerAmount = MiningAmounts[3];
      (MintAmount) = miningReward(_tokenId, _to, MinerAmount);
      miningShare(_tokenId, rank, MintAmount,_to, MinerAmount);
    }
    else if (rank == 5){
      MinerAmount = MiningAmounts[4];
      (MintAmount) = miningReward(_tokenId, _to, MinerAmount);
      miningShare(_tokenId, rank, MintAmount,_to, MinerAmount);
    }
    else if (rank == 6){
      MinerAmount = MiningAmounts[5];
      (MintAmount) = miningReward(_tokenId, _to, MinerAmount);
      miningShare(_tokenId, rank, MintAmount,_to, MinerAmount);
    }
    else if (rank == 7){
      MinerAmount = MiningAmounts[6];
      (MintAmount) = miningReward(_tokenId, _to, MinerAmount);
      miningShare(_tokenId, rank, MintAmount,_to, MinerAmount);
    }
    else if (rank == 8){
      MinerAmount = MiningAmounts[7];
      (MintAmount) = miningReward(_tokenId, _to, MinerAmount);
      miningShare(_tokenId, rank, MintAmount,_to, MinerAmount);
    }
    Id.lastWithdrawalAt = block.timestamp;
    Id.rank = rank;
  }

  function miningReward(uint256 _tokenId, address _to, uint minerAmount) private returns (uint mintAmount) {
    (Seller, Creator, Owner, StakeCreator, Staker) = addressReturns(_tokenId);

    if (Owner == _to) {
      if (Creator == address(0) || msg.sender == Creator || msg.sender == StakeCreator) {
        mintAmount = minerAmount / 10 * 31;
        return mintAmount;
      }
      else if (msg.sender != Creator || msg.sender != StakeCreator) {
        mintAmount = (minerAmount * 7) / 2;
        return mintAmount; 
      }
    }
    else if (Owner == address(stakingAddress)) {
      if (_to == Staker && _to == StakeCreator) {
        mintAmount = minerAmount / 10 * 31;
        return mintAmount;
      }
      else if (_to == Staker && _to != StakeCreator) {                   
        mintAmount = (minerAmount * 7) / 2;
        return mintAmount;
      }
      else if (_to != Staker) {                                     
        mintAmount = minerAmount * 4;
        return mintAmount;
      }
    }
    else if (Owner == address(marketplaceAddress) || Owner == address(stakingAddress) ){
      if ((_to == Seller && _to == Creator) || (_to == Staker && _to == StakeCreator) ){
        mintAmount = minerAmount / 10 * 31;
        return mintAmount;
      }
      else if ((_to == Seller && _to != Creator) || (_to == Staker && _to != StakeCreator) ){                   
        mintAmount = (minerAmount * 7) / 2;
        return mintAmount;
      }
      else if (_to != Seller || _to != Staker) {                                     
        mintAmount = minerAmount * 4;
        return mintAmount;
      }
    }
    else if ((Owner != _to && Owner != address(marketplaceAddress)) || (Owner != _to && Owner != address(stakingAddress)) ){ 
      if (Creator != address(0) || StakeCreator !=address(0) ){
        mintAmount = minerAmount * 4;
        return mintAmount;
      }
    }
  }

  // Transfer Mining Share
  function miningShare (uint256 _tokenId, uint rank, uint mintAmount, address _to, uint minerAmount) private {
    (Seller, Creator, Owner, StakeCreator, Staker) = addressReturns(_tokenId);
    uint protocolShare = minerAmount * 2;     // Multiply minerAmount by 2    (protocolshare(reward) = 200% from miner amount)
    // uint sellerShare = minerAmount;        // Default minerAmount by Rank  (nftowner across ecosystem marketplace + nftstaking by Global Mining = default amount)
    uint creatorShare = minerAmount / 10 * 4; // Divide minerAmount by 2      (creatorShare after nft sold and permanent for early minter = 40% from miner amount)
    uint devshare = minerAmount / 10 * 1;     // Divide minerAmount by 2      (devshare = 10% from miner amount)
    uint globalShare = minerAmount / 10 * 5;  // Divide minerAmount by 2      (globalShare + non-holder = 50% from miner amount)

    ArmyRankMining storage Id = ArmyRankMinings[_tokenId];
    HonorMint storage Mining = HonorMints[1];
    honorAddress.mint(_to, owner(), mintAmount);

    if (Owner == _to) {
      if (Creator == address(0) || msg.sender == Creator || msg.sender == StakeCreator)  { // Mining Go (Wallet) - Fresh Mint (Delist @ Creator == Holder)
        honorAddress.transfer(_to, minerAmount);
        honorAddress.transfer(honorDao, protocolShare);
      }
      else if (msg.sender != Creator || msg.sender != StakeCreator) {
        honorAddress.transfer(Owner, minerAmount);
        honorAddress.transfer(honorDao, protocolShare);
        honorAddress.transfer(Creator, creatorShare);
      }
    }
    else if (Owner == address(stakingAddress) ){
      if (_to == Staker && _to == StakeCreator) {
        honorAddress.transfer(Staker, minerAmount);
        honorAddress.transfer(honorDao, protocolShare);

      }
      else if (_to == Staker && _to != StakeCreator) {
           honorAddress.transfer(Staker, minerAmount);
        honorAddress.transfer(honorDao, protocolShare);
        honorAddress.transfer(StakeCreator, creatorShare);

      }
      else if (_to != Staker) {
        honorAddress.transfer(Staker, minerAmount);
        honorAddress.transfer(honorDao, protocolShare);
        honorAddress.transfer(StakeCreator, creatorShare);
        honorAddress.transfer(_to, globalShare);
      }
    }
    else if (Owner == address(marketplaceAddress) || Owner == address(stakingAddress) ){
      if ((_to == Seller && _to == Creator) || (_to == Staker && _to == StakeCreator) ){
        honorAddress.transfer(Seller, minerAmount);
        honorAddress.transfer(honorDao, protocolShare);
      }
      else if ((_to == Seller && _to != Creator) || (_to == Staker && _to != StakeCreator) ){                   
        honorAddress.transfer(Seller, minerAmount);
        honorAddress.transfer(honorDao, protocolShare);
        honorAddress.transfer(Creator, creatorShare);
      }
      else if (_to != Seller || _to != Staker) {                                   
        honorAddress.transfer(Seller, minerAmount);
        honorAddress.transfer(honorDao, protocolShare);
        honorAddress.transfer(Creator, creatorShare);
        honorAddress.transfer(_to, globalShare);
      }
    }
    else if ((Owner != _to && Owner != address(marketplaceAddress)) || (Owner != _to && Owner != address(stakingAddress)) ){ 
      if (Creator != address(0) || StakeCreator !=address(0) ){
        honorAddress.transfer(Owner, minerAmount);
        honorAddress.transfer(honorDao, protocolShare);
        honorAddress.transfer(Creator, creatorShare);
        honorAddress.transfer(_to, globalShare);
      }
    }
    honorAddress.transfer(owner(), devshare); 
    updateMiningStruct(Id, mintAmount, protocolShare, creatorShare, minerAmount, devshare, globalShare);
    updateTotalStruct(Mining, rank, mintAmount, protocolShare, creatorShare, minerAmount, devshare, globalShare);
  }

  // Update Single Mining Struct
  function updateMiningStruct (ArmyRankMining storage Id, uint mintAmount, uint protocolShare, uint creatorshare, uint minerAmount, uint devshare, uint globalShare) private {
    MiningCounter = Id.counter;
    MiningAmount = Id.mining;
    ProtocolAmount = Id.protocol;
    CreatorAmount = Id.creator;
    HolderAmount = Id.holder;
    DevAmount = Id.dev;
    GlobalAmount = Id.global;
    
    Id.counter = MiningCounter + 1;
    Id.mining = MiningAmount + mintAmount;
    Id.protocol = ProtocolAmount + protocolShare;
    Id.creator = CreatorAmount + creatorshare;
    Id.holder = HolderAmount + minerAmount;
    Id.dev = DevAmount + devshare;
    Id.global = GlobalAmount + globalShare;
  }

  // Update Global & Rank Mining Struct
  function updateTotalStruct (HonorMint storage Mining, uint rank, uint mintAmount, uint protocolshare, uint creatorShare, uint holdershare, uint devshare, uint globalShare) private {
    TotalMining = Mining.totalmining;
    TotalProtocol = Mining.totalprotocol;
    TotalCreator = Mining.totalcreator;
    TotalHolder = Mining.totalholder;
    TotalDev = Mining.totaldev;
    TotalGlobal = Mining.totalglobal;

    if (rank == 1){
      uint rank1 = Mining.rank1;
      Mining.rank1 = rank1 + mintAmount;
    }
    else if (rank == 2){
      uint rank2 = Mining.rank2;
      Mining.rank2 = rank2 + mintAmount;
    }
    else if (rank == 3){
      uint rank3 = Mining.rank3;
      Mining.rank3 = rank3 + mintAmount;
    }
    else if (rank == 4){
      uint rank4 = Mining.rank4;
      Mining.rank4 = rank4 + mintAmount;
    }
    else if (rank == 5){
      uint rank5 = Mining.rank5;
      Mining.rank5 = rank5 + mintAmount;
    }
    else if (rank == 6){
      uint rank6 = Mining.rank6;
      Mining.rank6 = rank6 + mintAmount;
    }
    else if (rank == 7){
      uint rank7 = Mining.rank7;
      Mining.rank7 = rank7 + mintAmount;
    }
    else if (rank == 8){
      uint rank8 = Mining.rank8;
      Mining.rank8 = rank8 + mintAmount;
    }
    Mining.totalmining = TotalMining + mintAmount;
    Mining.totalprotocol = TotalProtocol + protocolshare;
    Mining.totalcreator = TotalCreator + creatorShare;
    Mining.totalholder = TotalHolder + holdershare;
    Mining.totaldev = TotalDev + devshare;
    Mining.totalglobal = TotalGlobal + globalShare;
  }

}

// SPDX-License-Identifier: MIT
// Honor Protocol - NFT MarketPlace
// Duan
//-----------------------------------------------------------------------------------------------------------------------------------

pragma solidity >= 0.8.17;

import "./Metadata.sol";
import "./Ecos.sol";

contract HonorMarketplace is ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _itemsIds;
    Counters.Counter private _itemsSold;
    Counters.Counter private _itemsCanceled;

    event Received(address, uint);
        receive() external payable {
        emit Received(msg.sender, msg.value);
    }
    
    address payable owner;
    // uint256 listingPrice = 0 ether;
    uint256 public buyGasFee = 0.0005 ether;
    uint256 public delistGasFee = 0 ether;
    Busd public busdAddress;
    Metadata public metadataAddress;
    HonorEcosystem public ecosystemAddress;

    constructor(Busd _busdAddress, Metadata _metadataAddress, HonorEcosystem _ecosystemAddress) {
        owner = payable(msg.sender);
        busdAddress = _busdAddress;
        metadataAddress = _metadataAddress;
        ecosystemAddress = _ecosystemAddress;
    }

    struct MarketItem {
        uint256 itemId;
        address nftContract;
        uint256 tokenId;
        uint256 rank;
        address creator;
        address payable seller;
        address payable owner;
        uint256 price;
        bool sold;
        bool delisting;
        bool discount;
    }

    mapping(uint256 => MarketItem) public idToMarketItem;
    mapping(uint256 => MarketItem) public storageTokenId;

    event MarketItemCreated(
        uint256 indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address creator,
        address seller,
        address owner,
        uint256 price
    );

    event ProductUpdated(
      uint256 indexed itemId,
      uint256 indexed oldPrice,
      uint256 indexed newPrice
    );

    // event MarketItemDeleted(uint256 itemId);

    event ProductSold(
        uint256 indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address creator,
        address seller,
        address owner,
        uint256 price,
        bool delisting
    );

     event ProductListed(
        uint256 indexed itemId
    );

    modifier onlyProductOrMarketPlaceOwner(uint256 id) {
        if (idToMarketItem[id].owner != address(0)) {
            require(idToMarketItem[id].owner == msg.sender);
        } else {
            require(
                idToMarketItem[id].seller == msg.sender || msg.sender == owner
            );
        }
        _;
    }

    modifier onlyProductSeller(uint256 id) {
        require(
            idToMarketItem[id].owner == address(0) &&
                idToMarketItem[id].seller == msg.sender, "Only the product can do this operation"
        );
        _;
    }

    modifier onlyItemOwner(uint256 id) {
        require(
            idToMarketItem[id].owner == msg.sender,
            "Only product owner can do this operation"
        );
        _;
    }

    // function getListingPrice() public view returns (uint256) {
    //   return listingPrice;
    // }
    function checkTokenId(uint256 _tokenId) public view returns (uint256) {
        return storageTokenId[_tokenId].tokenId;
    }
    function checkSeller(uint256 _tokenId) external view returns (address) {
        return storageTokenId[_tokenId].seller;
    }
    function checkCreator(uint256 _tokenId) external view returns (address) {
        return storageTokenId[_tokenId].creator;
    }
    function setMetadata(address _metadataAddress) external {
        require(msg.sender == owner, "You must be the owner to run this.");
        metadataAddress = Metadata(_metadataAddress);
    }
    function setEcosystem(address _ecosystemAddress) external {
        require(msg.sender == owner, "You must be the owner to run this.");
        ecosystemAddress = HonorEcosystem(_ecosystemAddress);
    }
    function setGasFee(uint _buyGasFee, uint _delistGasFee) external {
       require(msg.sender == owner, "You must be the owner to run this.");
        buyGasFee = _buyGasFee;
        delistGasFee = _delistGasFee;
    }
    function addLiquidity() external payable {
        require(msg.sender == owner, "You must be the owner to run this.");
        bool sent = payable(address(this)).send(msg.value);
        require(sent, "Failed to add NFT Liquidity");
    }

    function bnbBalance() public view returns (uint) {
        return address(this).balance;
    }
    function busdBalance() public view returns (uint) {
     return busdAddress.balanceOf(address(this));
    } 
    // Withdrawal BNB
    function withdrawBNB() external {
       require(msg.sender == owner, "You must be the owner to run this.");
        (bool os, ) = payable(owner).call{value: address(this).balance}("");
        require(os);
    }
    // Withdrawal Busd
    function withdrawBusd() external {
       require(msg.sender == owner, "You must be the owner to run this.");
        busdAddress.transfer(owner, busdBalance());
    }

    // Create NFT Sale
    function createMarketItem(address nftContract, uint256 tokenId, uint256 price) public nonReentrant {
        require(price > 0, "Price must be at least 1 wei");
        // require(msg.value == listingPrice, "Listing fee required"); // Obligates the seller to pay the listing price
        uint256 checkId = checkTokenId(tokenId);
        require(tokenId != checkId, "Please Use Resell");           // Added this function to ignore ovewrite NFT minter & itemid

        uint rank = metadataAddress.checkRank(1,tokenId);         // Call rank from Metadata
        require(rank > 0, "No Rank, Contract Dev");
        address creator = metadataAddress.checkCreator(1,tokenId);   
        require(creator != address(0), "No Creator, Contract Dev");
        bool Discount = metadataAddress.checkDiscount(1,tokenId);     // Call discount from Metadata

        _itemsIds.increment();
        uint256 itemId = _itemsIds.current();

        ecosystemAddress.metadataEcos(msg.sender, 1, 1, tokenId); // Ecosystem add update

        idToMarketItem[itemId] = MarketItem(
            itemId,
            nftContract,
            tokenId,
            rank,
            creator,
            payable(msg.sender),
            payable(address(0)),
            price,
            false,
            false,
            Discount
        );

        storageTokenId[tokenId] = MarketItem(
            itemId,
            nftContract,
            tokenId,
            rank,
            creator,
            payable(msg.sender),
            payable(address(0)),
            price,
            false,
            false,
            Discount
        );

        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);

        emit MarketItemCreated(
            itemId,
            nftContract,
            tokenId,
            msg.sender,
            msg.sender,
            address(0),
            price
        );
    }

    function updatePrice(uint256 id, uint256 newPrice) public onlyProductSeller(id) {
        MarketItem storage item = idToMarketItem[id];
        uint256 tokenId = idToMarketItem[id].tokenId;
        uint256 oldPrice = item.price;
        item.price = newPrice;

        emit ProductUpdated(id, oldPrice, newPrice);
        storageTokenId[tokenId].price = newPrice;
    }

    // 5% Tax | 3% Creator Royalty ! 2% Protocol
    function payment(address _account, address creator, address seller, address nftContract, uint tokenId, uint price) private {
        uint creatorroyality = price / 100 * 3;
        uint protocolroyality = price / 100 * 2;
        uint selleramnount = price / 100 * 95;
        
        ecosystemAddress.metadataEcos(address(0), 1, 1, tokenId); // Ecosystem remove update

        busdAddress.transferFrom(_account, creator, creatorroyality); // Creator Royalty
        busdAddress.transferFrom(_account, owner, protocolroyality); // Dev @ Honor Protocol
        busdAddress.transferFrom(_account, seller, selleramnount); // Seller
        IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);
        // idToMarketItem[itemId].seller.transfer(msg.value);  // Send eth/bnb as payment
    }
    function buySaleNFT(address _account, address nftContract, uint256 itemId, uint _price) public nonReentrant {
        uint256 price = idToMarketItem[itemId].price;
        require(_price == price, "Please submit the asking price in order to complete the purchase");
        
        uint256 tokenId = idToMarketItem[itemId].tokenId;
        address seller = idToMarketItem[itemId].seller;
        address creator = idToMarketItem[itemId].creator;
        payment(_account, creator, seller, nftContract, tokenId, price);

        idToMarketItem[itemId].owner = payable(msg.sender);
        idToMarketItem[itemId].sold = true;
        _itemsSold.increment();

        // payable(seller).transfer(listingPrice);
        payable(seller).transfer(buyGasFee);

        emit ProductSold(
            idToMarketItem[itemId].itemId,
            idToMarketItem[itemId].nftContract,
            idToMarketItem[itemId].tokenId,
            idToMarketItem[itemId].creator,
            idToMarketItem[itemId].seller,
            payable(msg.sender),
            idToMarketItem[itemId].price,
            idToMarketItem[itemId].delisting
        );
        storageTokenId[tokenId].owner = payable(msg.sender);
        storageTokenId[tokenId].seller = payable(address(0));
        storageTokenId[tokenId].sold = true;
    }

    // Delist NFT sale
    function delistSale(address nftContract, uint256 itemId) public nonReentrant
    {
        idToMarketItem[itemId].price = 0;
        uint256 tokenId = idToMarketItem[itemId].tokenId;
        address seller = idToMarketItem[itemId].seller;
        require(msg.sender == idToMarketItem[itemId].seller, "You Not Owner");

        IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);
        idToMarketItem[itemId].owner = payable(msg.sender);
        idToMarketItem[itemId].delisting = true;
        _itemsSold.increment();
        _itemsCanceled.increment();

        // payable(seller).transfer(listingPrice);
        payable(seller).transfer(delistGasFee);

        ecosystemAddress.metadataEcos(address(0), 1, 1, tokenId); // Ecosystem remove update

        emit ProductSold(
            idToMarketItem[itemId].itemId,
            idToMarketItem[itemId].nftContract,
            idToMarketItem[itemId].tokenId,
            idToMarketItem[itemId].creator,
            msg.sender,
            payable(msg.sender),
            idToMarketItem[itemId].price,
            idToMarketItem[itemId].delisting
        );
        storageTokenId[tokenId].owner = payable(msg.sender);
        storageTokenId[tokenId].price;
        storageTokenId[tokenId].delisting = true;
    }

    // Resell, itemid available at struct
    function Resell(address nftContract, uint256 itemId, uint256 newPrice) public nonReentrant onlyItemOwner(itemId) {
        require(newPrice > 0, "Price must be at least 1 wei");
        // require(msg.value == listingPrice,"Price must be equal to listing price");
        uint256 tokenId = idToMarketItem[itemId].tokenId;
        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);
   
        uint rank = metadataAddress.checkRank(1,tokenId);         // Call rank from Metadata
        require(rank > 0, "No Rank, Contract Dev");
        address creator = metadataAddress.checkCreator(1,tokenId);   
        require(creator != address(0), "No Creator, Contract Dev");
        bool Discount = metadataAddress.checkDiscount(1,tokenId);     // Call discount from Metadata

        ecosystemAddress.metadataEcos(msg.sender, 1, 1, tokenId); // Ecosystem add update

        address payable oldOwner = idToMarketItem[itemId].owner;
        idToMarketItem[itemId].owner = payable(address(0));
        idToMarketItem[itemId].seller = oldOwner;
        idToMarketItem[itemId].price = newPrice;
        idToMarketItem[itemId].sold = false;
        idToMarketItem[itemId].creator = creator;
        idToMarketItem[itemId].rank = rank;
        idToMarketItem[itemId].discount = Discount;
        _itemsSold.decrement();

        emit ProductListed(itemId);

        storageTokenId[tokenId].owner = payable(address(0));
        storageTokenId[tokenId].seller = payable(msg.sender);
        storageTokenId[tokenId].price = newPrice;
        storageTokenId[tokenId].sold = false;
        storageTokenId[tokenId].creator = creator;
        storageTokenId[tokenId].rank = rank;
        storageTokenId[tokenId].discount = Discount;
    }

    function fetchMarketItems() public view returns (MarketItem[] memory) {
        uint256 itemCount = _itemsIds.current();
        uint256 unsoldItemCount = _itemsIds.current() - _itemsSold.current();
        uint256 currentIndex = 0;

        MarketItem[] memory items = new MarketItem[](unsoldItemCount);
        for (uint256 i = 0; i < itemCount; i++) {
            if (
                idToMarketItem[i + 1].owner == address(0) &&
                idToMarketItem[i + 1].sold == false &&
                idToMarketItem[i + 1].tokenId != 0
            ) {
                uint256 currentId = i + 1;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    function fetchSingleItem(uint256 id) public view returns (MarketItem memory) {
        return idToMarketItem[id];
    }

    function fetchMyNFTs() public view returns (MarketItem[] memory) {
        uint256 totalItemCount = _itemsIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].owner == msg.sender) {
                itemCount += 1;
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].owner == msg.sender) {
                uint256 currentId = i + 1;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    function fetchAuthorsCreations(address author) public view returns (MarketItem[] memory){
        uint256 totalItemCount = _itemsIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].creator == author && !idToMarketItem[i + 1].sold) {
                itemCount += 1;
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].creator == author && !idToMarketItem[i + 1].sold) {
                uint256 currentId = i + 1;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }
}

// SPDX-License-Identifier: MIT
// Honor Protocol - NFT Staking
// Duan
//-----------------------------------------------------------------------------------------------------------------------------------

pragma solidity >= 0.8.17;

import "@openzeppelin/contracts/utils/Counters.sol";
import "./Metadata.sol";
import "./Ecos.sol";

contract NFTStaking is Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _itemsIds;
    Counters.Counter private _itemsUnstake;
 
    Metadata public metadataAddress;
    HonorProtocol public honorAddress;
    HonorEcosystem public ecosystemAddress;

    // uint multiplierConstant = 78894000; // 40% APR Yearly | 2.5 * 365.25 * 86400 ( Per Second Calculation )
    uint multiplierConstant = 315576;      // 10000 % for testnet
    uint defaultstake = 100 * 10 ** 18;    // 100 Honor Token Built-in Per NFT (100 * 10 ** 18)
    uint totalnft;
    bool public stakingAlive = false;

    constructor(HonorProtocol _honorAddress, Metadata _metadataAddress, HonorEcosystem _ecosystemAddress) {
        honorAddress = _honorAddress;
        metadataAddress = _metadataAddress;
        ecosystemAddress = _ecosystemAddress;
    }

    struct Staker {
        uint honorRewards;
        uint lastWithdrawalAt;
        uint nftLength;
        uint updatedAt;
    }
    struct StakeItem {
        uint256 itemId;
        address nftContract;
        uint256 tokenId;
        address creator;    // The First Minter -- > Metadata Ecosystem
        address staker;     // Staker or Owner address
        address owner;      // Temporary address of Owners for listing
        bool staking;
    }

    mapping(uint256 => StakeItem) public idToStakeItem;
    mapping(address => Staker) public stakers;

    event DepositNFT(address indexed account, uint256 depositedNFTAmount);
    event WithdrawNFT(address indexed account, uint256 depositedNFTAmount);
    event WithdrawReward(address indexed account, uint256 depositedNFTAmount);

    event StakeItemCreated(
        uint256 indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address creator,
        address staker,
        address owner
    );

    event Unstake(
        uint256 indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address creator,
        address staker,
        address owner
    );

    event StakeListed(uint256 indexed itemId);

    modifier onlyItemOwner(uint256 id) {
        require(idToStakeItem[id].owner == address(0),"Only product owner can do this operation");
        _;
    }
    
    function StakingOn() external onlyOwner {
        stakingAlive = true;
     }
    function StakingOff() external onlyOwner {
        stakingAlive = false;
    }
    function checkTokenId(uint256 _tokenId) public view returns (uint256) {
        return idToStakeItem[_tokenId].tokenId;
    }
    function checkItemId(uint256 _tokenId) public view returns (uint256) {
        return idToStakeItem[_tokenId].itemId;
    }
    function checkStaker(uint256 _tokenId) external view returns (address) {
        return idToStakeItem[_tokenId].staker;
    }
    function checkCreator(uint256 _tokenId) external view returns (address) {
        return idToStakeItem[_tokenId].creator;
    }
    function setMetadata(address _metadataAddress) external onlyOwner {
        metadataAddress = Metadata(_metadataAddress);
    }
    function setEcosystem(address _ecosystemAddress) external onlyOwner {
        ecosystemAddress = HonorEcosystem(_ecosystemAddress);
    }

    function depositNFT(address nftContract, uint256 tokenId) public {
        require(stakingAlive == true, "Honor Protocol Token Staking Offline");
        uint256 checkId = checkTokenId(tokenId);
        require(tokenId != checkId, "Please Use ReStake");  // Added this function to keep itemId

        address creator = metadataAddress.checkCreator(1,tokenId);   
        require(creator != address(0), "No Creator, Contract Dev");

        _itemsIds.increment();
        uint256 itemId = _itemsIds.current();

        ecosystemAddress.metadataEcos(msg.sender, 2, 1, tokenId); // Ecosytem add update

        idToStakeItem[itemId] = StakeItem(
            itemId,
            nftContract,
            tokenId,
            creator,
            msg.sender,
            address(0),
            true
        );

        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);

        emit StakeItemCreated(
            itemId,
            nftContract,
            tokenId,
            creator,
            msg.sender,
            address(0)
        );

        stakers[msg.sender].honorRewards += pendingHonorRewards(block.timestamp); // update pending rewards at deposit
        stakers[msg.sender].updatedAt = block.timestamp;
        Staker storage idStaker = stakers[msg.sender];
        idStaker.nftLength++;
        totalnft++;

        emit DepositNFT(address(msg.sender), tokenId);
    }
    function pendingHonorRewards(uint _timestamp) public view returns(uint) {
        uint secondsElapsed = _timestamp - stakers[msg.sender].updatedAt;
        return (stakers[msg.sender].nftLength * (defaultstake) * secondsElapsed) / multiplierConstant;
    }
    function totalHonorRewards(uint _timestamp) public view returns(uint) {
        return stakers[msg.sender].honorRewards + pendingHonorRewards(_timestamp);
    }
    function withdrawReward(uint _amount) public {
        stakers[msg.sender].honorRewards += pendingHonorRewards(block.timestamp); // update pending rewards at withdrawal
        require(_amount <= stakers[msg.sender].honorRewards, 'HONOR Amount error');

        stakers[msg.sender].honorRewards -= _amount; // withdraw amount
        stakers[msg.sender].updatedAt = block.timestamp;
        honorAddress.transfer(msg.sender, _amount);

        emit WithdrawReward(address(msg.sender), _amount);
    }
    function totalStakeNFT() external view returns(uint){
        return totalnft;
    }
    // In the future it might be necessary to remove the reward token from the pool
    function emergencyWithdrawHonor(uint _amount) external onlyOwner {
        honorAddress.transfer(msg.sender, _amount);
    }
    
    function unstakeNFT(address nftContract, uint256 itemId) public {
        uint256 tokenId = idToStakeItem[itemId].tokenId;
        address fusionstaker = ecosystemAddress.checkEcosystem(1,3,tokenId);
        require(fusionstaker == address(0), "Please unstake Fusion Staking first");
        require(msg.sender == idToStakeItem[itemId].staker, "You Not Owner");

        IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);
        idToStakeItem[itemId].owner = address(0);
        idToStakeItem[itemId].staker = address(0);
        idToStakeItem[itemId].staking = false;
        _itemsUnstake.increment();

        ecosystemAddress.metadataEcos(address(0), 2, 1, tokenId); // Ecosystem remove update

        emit Unstake(
            idToStakeItem[itemId].itemId,
            idToStakeItem[itemId].nftContract,
            idToStakeItem[itemId].tokenId,
            idToStakeItem[itemId].creator,
            address(0),
            msg.sender
        );

        stakers[msg.sender].honorRewards += pendingHonorRewards(block.timestamp);
        Staker storage idStaker = stakers[msg.sender];
        idStaker.nftLength--;
        totalnft--;

        emit WithdrawNFT(address(msg.sender), tokenId);

    }
    // ReStake, keep ItemId
    function reStake(address nftContract, uint256 itemId) public onlyItemOwner(itemId) {
        require(stakingAlive == true, "Honor Protocol Token Staking Offline");

        uint256 tokenId = idToStakeItem[itemId].tokenId;
        ecosystemAddress.metadataEcos(msg.sender, 2, 1, tokenId); // Ecosytem add update
        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);
    
        idToStakeItem[itemId].owner = address(0);
        idToStakeItem[itemId].staker = msg.sender;
        idToStakeItem[itemId].staking = true;
        _itemsUnstake.decrement();

        emit StakeListed(itemId);

        stakers[msg.sender].honorRewards += pendingHonorRewards(block.timestamp); // update pending rewards at deposit
        stakers[msg.sender].updatedAt = block.timestamp;
        Staker storage idStaker = stakers[msg.sender];
        idStaker.nftLength++;
        totalnft++;

        emit DepositNFT(address(msg.sender), tokenId);
    }

    function fetchStakeItems() public view returns (StakeItem[] memory) {
        uint256 itemCount = _itemsIds.current();
        uint256 unsoldItemCount = _itemsIds.current() - _itemsUnstake.current();
        uint256 currentIndex = 0;

        StakeItem[] memory items = new StakeItem[](unsoldItemCount);
        for (uint256 i = 0; i < itemCount; i++) {
            if (
                idToStakeItem[i + 1].owner == address(0) &&
                idToStakeItem[i + 1].staking == true &&
                idToStakeItem[i + 1].tokenId != 0
            ) {
                uint256 currentId = i + 1;
                StakeItem storage currentItem = idToStakeItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }
    function fetchSingleItem(uint256 id) public view returns (StakeItem memory) {
        return idToStakeItem[id];
    }
    function fetchMyStakes(address account) public view returns (StakeItem[] memory){
        uint256 totalItemCount = _itemsIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToStakeItem[i + 1].staker == account && idToStakeItem[i + 1].staking) {
                itemCount += 1;
            }
        }

        StakeItem[] memory items = new StakeItem[](itemCount);
        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToStakeItem[i + 1].staker == account && idToStakeItem[i + 1].staking) {
                uint256 currentId = i + 1;
                StakeItem storage currentItem = idToStakeItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
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

// SPDX-License-Identifier: MIT
// Honor Protocol - NFT Metadata Part I (Security)
// Duan
//-----------------------------------------------------------------------------------------------------------------------------------

pragma solidity >= 0.8.17;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./HonorProtocol.sol";
import "./Busd.sol";
import "./ArmyRankNFT.sol";
import "./EmblemNFT.sol";
import "./WarHeroNFT.sol";
import "./Ecos.sol";

contract Metadata is Ownable, ReentrancyGuard {

 HonorProtocol public honorAddress;
 Busd public busdAddress;
 ArmyRankNFT public armyRankNFT;
 EmblemNFT public emblemRankNFT;
 WarHeroNFT public warHeroNFT;
 HonorEcosystem public ecosystemAddress;
    
 address public honorDao; // Node @ Yield Rank
 address public stakeDao; // Staking
 address public miningDao; // Mining
 address public marketDao; // Marketplace
 address public ateDao; // Anything to Earn
 address public rentDao; // Rent
 address public fusionDao; // Fusion Staking
 address public migrateDao; // Migration

 uint256 public BusdCost =  10 * 10 ** 18; // Price in Busd
 uint256 public HonorCost =  1 * 10 ** 18; // Price in Token
 bool specialDay = false; // No tax day 

 struct ArmyMetadata {
  uint tokenid;
  address creator;
  uint rank;
  uint level;
  uint armyCounter;
  uint reward;
  uint multiplier;
  bool discount;
  bool rent;
 }
 struct EmblemMetadata {
  uint tokenid;
  address creator;
  uint emblem; // rank
  uint level;
  uint emblemCounter;
  uint reward;
  uint multiplier;
  bool reset;
  bool rent;
 }
 struct HeroMetadata {
  uint tokenid;
  address creator;
  uint hero; // rank
  uint level;
  uint heroCounter;
  uint reward;
  uint multiplier;
  bool support;
  bool rent;
 }

 mapping(uint => ArmyMetadata) ArmyMetadatas;
 mapping(uint => EmblemMetadata) EmblemMetadatas;
 mapping(uint => HeroMetadata) HeroMetadatas;
 mapping(uint256 => bool) tokenIdForDiscount;   // Army Rank NFT
 mapping(uint256 => bool) tokenIdForReset;      // Emblem Rank NFT
 mapping(uint256 => bool) tokenIdForSupport;    // War Hero NFT
 mapping(uint256 => bool) tokenIdForRent;       // Rent status
 address Seller; address Staker; address FusionStaker; address RentOwner; address Renter;

 constructor(HonorProtocol _honorAddress, Busd _busdAddress, ArmyRankNFT _armynftAddress){
    honorAddress = _honorAddress;
    busdAddress = _busdAddress;
    armyRankNFT = _armynftAddress;
 }
 
 // OWNER - Set DAO Smart Contracts & etc
 function setHonorDaoContract(address _honorDao) external onlyOwner {
    honorDao = _honorDao;
 }
 function setStakeContract(address _stakeDao) external onlyOwner {
    stakeDao = _stakeDao;
 }
 function setMiningContract(address _miningDao) external onlyOwner {
    miningDao = _miningDao;
 }
 function setATEContract(address _ateDao) external onlyOwner {
    ateDao = _ateDao;
 }
 function setRentContract(address _rentDao) external onlyOwner {
    rentDao = _rentDao;
 }
 function setMigrateContract(address _migrateDao) external onlyOwner {
    migrateDao = _migrateDao;
 }
 function setHonorNFT(address _emblemnftAddress, address _warnftAddress) external onlyOwner {
    emblemRankNFT = EmblemNFT(_emblemnftAddress);
    warHeroNFT = WarHeroNFT(_warnftAddress);
 }
 function setEcosystem(address _ecosystemAddress) external onlyOwner {
    ecosystemAddress = HonorEcosystem(_ecosystemAddress);
  }
 function setCost(uint _busdCost, uint _honorCost) external onlyOwner {
    BusdCost = _busdCost;
    HonorCost = _honorCost;
 }

 //-----------------------------------------------------------------------------------------------------------------------------------
 // RETURNS
 function checkMetadata(uint collection, uint _tokenId) public view returns (uint Collection, uint TokenID, address Creator, uint Rank, uint Level, uint Counter, uint Reward, uint Multiplier, bool Discount, bool Rent) {
    if (collection == 1){
      require(_tokenId <= armyRankNFT.totalSupply(), "NFT Not Yet Mint");
      ArmyMetadata memory Id = ArmyMetadatas[_tokenId];
      return (collection, Id.tokenid, Id.creator, Id.rank, Id.level, Id.armyCounter, Id.reward, Id.multiplier, Id.discount, Id.rent);
    }
    else if (collection == 2){
      require(_tokenId <= emblemRankNFT.totalSupply(), "NFT Not Yet Mint");
      EmblemMetadata memory Id2 = EmblemMetadatas[_tokenId];            
      return (collection, Id2.tokenid, Id2.creator, Id2.emblem, Id2.level, Id2.emblemCounter, Id2.reward, Id2.multiplier, Id2.reset, Id2.rent);
    }
    else if (Collection == 3){
      require(_tokenId <= warHeroNFT.totalSupply(), "NFT Not Yet Mint");
      HeroMetadata memory Id3 = HeroMetadatas[_tokenId];                
      return (collection, Id3.tokenid, Id3.creator, Id3.hero, Id3.level, Id3.heroCounter, Id3.reward, Id3.multiplier, Id3.support, Id3.rent);
    }
 }
 function checkSpecialDay() public view returns (bool) {
    return specialDay;
 }
 function checkRank(uint Collection, uint _tokenId) public view returns (uint Rank) {
    if (Collection == 1){
      require(_tokenId <= armyRankNFT.totalSupply(), "NFT Not Yet Mint");
      return (ArmyMetadatas[_tokenId].rank);
    }
    else if (Collection == 2){
      require(_tokenId <= emblemRankNFT.totalSupply(), "NFT Not Yet Mint"); 
      return EmblemMetadatas[_tokenId].emblem;
    }
    else if (Collection == 3){
      require(_tokenId <= warHeroNFT.totalSupply(), "NFT Not Yet Mint"); 
      return HeroMetadatas[_tokenId].hero;
    }
 }
 function checkCounter(uint Collection, uint _tokenId) public view returns (uint Counter) {
    if (Collection == 1){
      return ArmyMetadatas[_tokenId].armyCounter;
    }
    else if (Collection == 2){
      return EmblemMetadatas[_tokenId].emblemCounter;
    }
    else if (Collection == 3){
      return HeroMetadatas[_tokenId].heroCounter;
    }
 }
 function checkDiscount(uint Collection, uint256 _tokenId) public view returns (bool Discount) {
    if (Collection == 1){
      return tokenIdForDiscount[_tokenId];
    }
    else if (Collection == 2){
      return tokenIdForReset[_tokenId];
    }
    else if (Collection == 3){
      return tokenIdForSupport[_tokenId];
    }
 }
 function checkRent(uint Collection, uint256 _tokenId) public view returns (bool Rent) {
    if (Collection == 1){
      return ArmyMetadatas[_tokenId].rent;
    }
    else if (Collection == 2){
      return EmblemMetadatas[_tokenId].rent;
    }
    else if (Collection == 3){
      return HeroMetadatas[_tokenId].rent;
    }
 }
 function checkCreator(uint Collection, uint256 _tokenId) public view returns (address Creator) {
    if (Collection == 1){
      return ArmyMetadatas[_tokenId].creator;
    }
    else if (Collection == 2){
      return EmblemMetadatas[_tokenId].creator;
    }
    else if (Collection == 3){
      return HeroMetadatas[_tokenId].creator;
    }
 }
 function checkLRM(uint Collection, uint Type, uint256 _tokenId) public view returns (uint LRM) {
    if (Collection == 1){ // ArmyRank
     if (Type == 1){ // Level
      return ArmyMetadatas[_tokenId].level;
     }
     else if (Type == 2){ // Reward
      return ArmyMetadatas[_tokenId].reward;
     }
     else if (Type == 3){ // Multiplier
      return ArmyMetadatas[_tokenId].multiplier;
     }
    }
    else if (Collection == 2){ //Emblem
     if (Type == 1){ // Level
      return EmblemMetadatas[_tokenId].level; 
     }
     else if (Type == 2){ // Reward
      return EmblemMetadatas[_tokenId].reward; 
     }
     else if (Type == 3){ // Multiplier
      return EmblemMetadatas[_tokenId].multiplier;
     }
    }
    else if (Collection == 3){ // War Hero
     if (Type == 1){ // Level
      return HeroMetadatas[_tokenId].level;
     }
     else if (Type == 2){ // Reward
      return HeroMetadatas[_tokenId].reward;
     }
     else if (Type == 3){ // Multiplier
      return HeroMetadatas[_tokenId].multiplier;
     }
    }
 }
 
 //-----------------------------------------------------------------------------------------------------------------------------------
 // HOLDERS - Reset Counter Army Rank NFT
 function maintenanceNFT(address _address, uint Collection, uint _busdAmount, uint _honorAmount, uint256 _tokenId) external {
    require(_busdAmount >= BusdCost, "You must provide enough BUSD for the Maintenance NFT");
    require(_honorAmount >= HonorCost, "You must provide enough HONOR for the Maintenance NFT");

    if (Collection == 1){
      require(msg.sender == armyRankNFT.ownerOf(_tokenId),"Invalid Token ID");
      ArmyMetadata storage Id = ArmyMetadatas[_tokenId];                
      Id.armyCounter = 0;
    }
    else if (Collection == 2){
      require(msg.sender == emblemRankNFT.ownerOf(_tokenId),"Invalid Token ID");
      EmblemMetadata storage Id = EmblemMetadatas[_tokenId];                
      Id.emblemCounter = 0;
    }
    else if (Collection == 3){
      require(msg.sender == warHeroNFT.ownerOf(_tokenId),"Invalid Token ID");
      HeroMetadata storage Id = HeroMetadatas[_tokenId];                
      Id.heroCounter = 0;
    }
    busdAddress.transferFrom(_address, address(this), _busdAmount);
    honorAddress.transferFrom(_address, address(this), _honorAmount);
 }

 // HOLDERS - Discard Discount After Purchasing Node (FUNCTION USED BY OTHER SMART CONTRACT)
 function removeDiscount (uint256 _tokenId, bool Discount) external { // owner()
    require(msg.sender == honorDao || msg.sender == owner(), "Protected by HonorDao or Owner - Remove Discount");
    tokenIdForDiscount[_tokenId] = Discount;
    ArmyMetadata storage Id = ArmyMetadatas[_tokenId];
    Id.discount = Discount;
 }

 //HOLDERS - Emblem NFT, RESET Army Rank NFT (Discount Can Use Again)
 function DiscountON (address _address, uint256 _tokenId, uint256 _tokenId2) external {
    require(_address == armyRankNFT.ownerOf(_tokenId),"You are not the owner of this TokenId");
    require(_address == emblemRankNFT.ownerOf(_tokenId2),"You are not the owner of this TokenId");
    require(!tokenIdForReset[_tokenId]," Emblem Already Used");
    ArmyMetadata storage Id = ArmyMetadatas[_tokenId];
    EmblemMetadata storage Id2 = EmblemMetadatas[_tokenId2];
    bool Discount = false;
    bool Reset = true;
    tokenIdForDiscount[_tokenId] = Discount;
    tokenIdForReset[_tokenId2] = Reset;
    Id.discount = Discount;
    Id2.reset = Reset;
 }

 // HOLDERS -  War Hero NFT, RESET Emblem NFT (Reset Can Use Again)
 function ResetON (address _address, uint256 _tokenId2, uint256 _tokenId3) external {
    require(_address == emblemRankNFT.ownerOf(_tokenId2),"You are not the owner of this TokenId");
    require(_address == warHeroNFT.ownerOf(_tokenId3),"You are not the owner of this TokenId");
    require(!tokenIdForSupport[_tokenId3],"War Hero Already Used");
    EmblemMetadata storage Id2 = EmblemMetadatas[_tokenId2];
    HeroMetadata storage Id3 = HeroMetadatas[_tokenId3];
    bool Reset = false;
    bool War = true;
    tokenIdForReset[_tokenId2] = Reset;
    tokenIdForSupport[_tokenId3] = War;
    Id2.reset = Reset;
    Id3.support = War;
 }

 //-----------------------------------------------------------------------------------------------------------------------------------
 // OWNER/DAO - TOKEN RANK METADATA INPUT & ADD RANK
 function metadataUpdate (uint Collection, uint _tokenId, address _creator, uint _rank, uint _level, uint _counter, uint _reward, bool _discount, uint _multiplier, bool _rent) external { // owner()
    require(msg.sender == fusionDao || msg.sender == ateDao || msg.sender == rentDao || msg.sender == migrateDao || msg.sender == owner(), "Protected, Can only be used by Honor Protocol Dao or owner. - Metadata Input");
    require(_rank >= 1 && _rank <= 8, "Invalid Rank type");
    ArmyMetadata storage Id = ArmyMetadatas[_tokenId];
    EmblemMetadata storage Id2 = EmblemMetadatas[_tokenId];
    HeroMetadata storage Id3 = HeroMetadatas[_tokenId];

    if (Collection == 1){
      Id.tokenid = _tokenId;
      Id.creator = _creator;
      Id.rank = _rank;
      Id.level = _level;
      Id.armyCounter = _counter;
      Id.reward = _reward;
      Id.multiplier = _multiplier;
      Id.discount = _discount;
      Id.rent = _rent;
    }
    else if (Collection == 2){
      Id2.tokenid = _tokenId;
      Id2.creator = _creator;
      Id2.emblem = _rank;
      Id2.level = _level;
      Id2.emblemCounter = _counter;
      Id2.reward = _reward;
      Id2.multiplier = _multiplier;
      Id2.reset = _discount;
      Id2.rent = _rent;
    }
    else if (Collection == 3){
      Id3.tokenid = _tokenId;
      Id3.creator = _creator;
      Id3.hero = _rank;
      Id3.level = _level;
      Id3.heroCounter = _counter;
      Id3.reward = _reward;
      Id3.multiplier = _multiplier;
      Id3.support = _discount;
      Id3.rent = _rent;
    }
 }

 // OWNER - ADD RANK
 function metadataSync (uint Collection, uint _tokenId, uint _rank) external onlyOwner { // owner()
    require(_rank >= 1 && _rank <= 8, "Invalid Rank type");

    if (Collection == 1){
      ArmyMetadata storage Id = ArmyMetadatas[_tokenId];
      Id.rank = _rank;
    }
    else if (Collection == 2){
      EmblemMetadata storage Id2 = EmblemMetadatas[_tokenId];
      Id2.emblem = _rank;
    }
    else if (Collection == 3){
      HeroMetadata storage Id3 = HeroMetadatas[_tokenId];
      Id3.hero = _rank;
    }
 }
 
 // OWNER - SPECIAL DAY ON & OFF & WITHDRAWAL
 function specialDayON () external onlyOwner {
    specialDay = true;
 }
 function specialDayOFF () external onlyOwner {
    specialDay = false;
 }
 function withdrawBusd() external onlyOwner {
    busdAddress.transfer(owner(), busdBalance());
 }
 function busdBalance() public view returns (uint) {
    return busdAddress.balanceOf(address(this));
 }
 function withdrawHonor() external onlyOwner {
    honorAddress.transfer(owner(), honorBalance());
 }
 function honorBalance() public view returns (uint) {
    return honorAddress.balanceOf(address(this));
 }

 //-------------------------------------------------------------------------------------------------------------------------------------
 // SMART CONTRACT ACCESS 
 // HOLDERS - Mint NFT Creator Metadata
 function mintCreator (uint Collection, uint _tokenId, address _creator) external {
    address Duan = address(armyRankNFT); 
    require(msg.sender == Duan || msg.sender == address(emblemRankNFT) || msg.sender == address(warHeroNFT), "Protected, Can only be used by Honor Protocol Dao. - NFT Creator Input");

    if (Collection == 1){
      ArmyMetadata storage Id = ArmyMetadatas[_tokenId];
      Id.tokenid = _tokenId;
      Id.creator = _creator;
      Id.level = 1;
      Id.multiplier = 1;
    }
    else if (Collection == 2){
      EmblemMetadata storage Id2 = EmblemMetadatas[_tokenId];
      Id2.tokenid = _tokenId;
      Id2.creator = _creator;
      Id2.level = 1;
      Id2.multiplier = 1;
    }
    else if (Collection == 3){
      HeroMetadata storage Id3 = HeroMetadatas[_tokenId];
      Id3.tokenid = _tokenId;
      Id3.creator = _creator;
      Id3.level = 1;
      Id3.multiplier = 1;
    }
 }

 function CollectionOne(uint _tokenId) private {
    Seller = ecosystemAddress.checkEcosystem(1,1,_tokenId);
    Staker = ecosystemAddress.checkEcosystem(1,2,_tokenId);
    FusionStaker = ecosystemAddress.checkEcosystem(1,3,_tokenId);
    RentOwner = ecosystemAddress.checkEcosystem(1,4,_tokenId);
    Renter = ecosystemAddress.checkEcosystem(1,5,_tokenId);
    
 }
 function CollectionTwo(uint _tokenId) private {
    Seller = ecosystemAddress.checkEcosystem(2,1,_tokenId);
    Staker = ecosystemAddress.checkEcosystem(2,2,_tokenId);
    FusionStaker = ecosystemAddress.checkEcosystem(2,3,_tokenId);
    RentOwner = ecosystemAddress.checkEcosystem(2,4,_tokenId);
    Renter = ecosystemAddress.checkEcosystem(2,5,_tokenId);
 }
  function CollectionThree(uint _tokenId) private {
    Seller = ecosystemAddress.checkEcosystem(3,1,_tokenId);
    Staker = ecosystemAddress.checkEcosystem(3,2,_tokenId);
    FusionStaker = ecosystemAddress.checkEcosystem(3,3,_tokenId);
    RentOwner = ecosystemAddress.checkEcosystem(3,4,_tokenId);
    Renter = ecosystemAddress.checkEcosystem(3,5,_tokenId);
 }

 // HOLDERS - Add RankCounter
 function addCounter (address _to, uint _wdType, uint256 _tokenId, uint256 _tokenId2) external { //owner();
    require(msg.sender == honorDao || msg.sender == stakeDao || msg.sender == fusionDao || msg.sender == ateDao || msg.sender == rentDao, "Protected, Can only be used by Honor Protocol Dao - Add Counter");

    ArmyMetadata storage TokenId = ArmyMetadatas[_tokenId];
    ArmyMetadata storage TokenId2 = ArmyMetadatas[_tokenId2];
    EmblemMetadata storage TokenId3 = EmblemMetadatas[_tokenId2];
    uint armyCounter;

    if(_wdType == 2){
      // Withdraw counter and checker for 1 NFT (5% Tax Deduction) - Daily
      CollectionOne(_tokenId);
      require(_to == armyRankNFT.ownerOf(_tokenId) || _to == Seller || _to == Staker || _to == FusionStaker || _to == RentOwner || _to == Renter,"You not owner this TokenId - Input Token Army");
      armyCounter = TokenId.armyCounter;
      TokenId.armyCounter = armyCounter + 1;
    }
    else if(_wdType == 4){
      // Withdraw counter and checker for 1 NFT (NFT Reward 5%) - 30 days
      CollectionOne(_tokenId);
      require(_to == armyRankNFT.ownerOf(_tokenId) || _to == Seller || _to == Staker || _to == FusionStaker || _to == RentOwner || _to == Renter,"You not owner this TokenId - Input Token Army");
      armyCounter = TokenId.armyCounter;
      TokenId.armyCounter = armyCounter + 1;
    }
    else if(_wdType == 1){
      // Withdraw counter and checker for 2 NFTs - Remove All Tax (ROT) - Daily
      require(_tokenId != _tokenId2, "Token ID Cannot Be The Same");

      CollectionOne(_tokenId);
      require(_to == armyRankNFT.ownerOf(_tokenId) || _to == Seller || _to == Staker || _to == FusionStaker || _to == RentOwner || _to == Renter,"You not owner this TokenId - Input Token Army");
      armyCounter = TokenId.armyCounter;
      TokenId.armyCounter = armyCounter + 1; // Army A

      CollectionOne(_tokenId2);
      require(_to == armyRankNFT.ownerOf(_tokenId) || _to == Seller || _to == Staker || _to == FusionStaker || _to == RentOwner || _to == Renter,"You not owner this TokenId - Input Token Army");
      uint armyCounter2 = TokenId2.armyCounter;
      TokenId2.armyCounter = armyCounter2 + 1; // Army B
    }
    else if(_wdType == 5){
      // Withdraw counter and checker for 2 NFTs - (NFT Reward 10%) - Army + Emblem - 30 day
      CollectionOne(_tokenId);
      require(_to == armyRankNFT.ownerOf(_tokenId) || _to == Seller || _to == Staker || _to == FusionStaker || _to == RentOwner || _to == Renter,"You not owner this TokenId - Input Token Army");
      armyCounter = TokenId.armyCounter;
      TokenId.armyCounter = armyCounter + 1; // Army A
      CollectionTwo(_tokenId2);
      require(_to == emblemRankNFT.ownerOf(_tokenId) || _to == Seller || _to == Staker || _to == FusionStaker || _to == RentOwner || _to == Renter,"You not owner this TokenId - Input Token Emblem");
      uint emblemCounter = TokenId3.emblemCounter;
      TokenId3.emblemCounter = emblemCounter + 1; // Emblem A  
    }
 }

 // HOLDERS - Level-Up
 function levelUp (address _to, uint Collection, uint _tokenId, uint _levelup) external { 
    require(msg.sender == honorDao || msg.sender == stakeDao || msg.sender == fusionDao || msg.sender == ateDao || msg.sender == rentDao || msg.sender == owner(), "Protected, Can only be used by Honor Protocol Dao or owner. - Level-up");

    if (Collection == 1){
      CollectionOne(_tokenId);
      require(_to == armyRankNFT.ownerOf(_tokenId) || _to == Seller || _to == Staker || _to == FusionStaker || _to == RentOwner || _to == Renter,"You not owner this TokenId - Input Token Army");
      ArmyMetadata storage Id = ArmyMetadatas[_tokenId];
      uint level = Id.level;
      Id.level = level + _levelup;
    }
    else if (Collection == 2){
      CollectionTwo(_tokenId);
      require(_to == emblemRankNFT.ownerOf(_tokenId) || _to == Seller || _to == Staker || _to == FusionStaker || _to == RentOwner || _to == Renter,"You not owner this TokenId - Input Token Emblem");
      EmblemMetadata storage Id2 = EmblemMetadatas[_tokenId];
      uint level = Id2.level;
      Id2.level = level + _levelup;
    }
    else if (Collection == 3){
      CollectionThree(_tokenId);
      require(_to == warHeroNFT.ownerOf(_tokenId) || _to == Seller || _to == Staker || _to == FusionStaker || _to == RentOwner || _to == Renter,"You not owner this TokenId - Input Token Hero");
      HeroMetadata storage Id3 = HeroMetadatas[_tokenId];
      uint level = Id3.level;
      Id3.level = level + _levelup;
    }
 }

}

// SPDX-License-Identifier: MIT
// Honor Protocol - NFT Metadata Part II (Ecosystem)
// Duan
//-----------------------------------------------------------------------------------------------------------------------------------

pragma solidity >= 0.8.17;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract HonorEcosystem is Ownable, ReentrancyGuard {

 address public marketDao; // Marketplace
 address public nftstakeDao; // NFTStaking
 address public fusionDao; // Fusion Staking
 address public ateDao; // Anything to Earn
 address public rentDao; // Rent
 
 struct Ecosystem {
  address seller;
  address staker;
  address fusionstaker;
  address rentowner;
  address renter;
 }
  address Seller; address Staker; address FusionStaker; address RentOwner; address Renter;

 mapping(uint => Ecosystem) ArmyEcosystem;
 mapping(uint => Ecosystem) EmblemEcosystem;
 mapping(uint => Ecosystem) HeroEcosystem;

 constructor(){
 }

 // OWNER - Set DAO Smart Contracts & etc
 function setMarketplace(address _marketDao) external onlyOwner {
    marketDao = _marketDao;
 }
  function setNftStakeDao(address _nftstakeDao) external onlyOwner {
    nftstakeDao = _nftstakeDao;
 }
  function setFusioDao(address _fusionDao) external onlyOwner {
    fusionDao = _fusionDao;
 }
  function setAteDao(address _ateDao) external onlyOwner {
    ateDao = _ateDao;
 }
  function setRentDao(address _rentDao) external onlyOwner {
    rentDao = _rentDao;
 }

 function metadataEcos (address _address, uint ecoType, uint Collection, uint _tokenId) external { // owner
    require(msg.sender == marketDao || msg.sender == nftstakeDao || msg.sender == fusionDao || msg.sender == rentDao || msg.sender == owner() , "Protected, Can only be used by Honor Protocol Dao or owner. - Ecosystems");

    Ecosystem storage Id = ArmyEcosystem[_tokenId];
    Ecosystem storage Id2 = EmblemEcosystem[_tokenId];
    Ecosystem storage Id3 = HeroEcosystem[_tokenId];

    if (ecoType == 1) { // Marketplace Seller
        if (Collection == 1){ 
            Id.seller = _address;
        }
        else if (Collection == 2){
            Id2.seller = _address;
        }
        else if (Collection == 3){
            Id3.seller = _address;
        }
    }
    else if (ecoType == 2) { // NFT Staking
        if (Collection == 1){
            Id.staker = _address;
        }
        else if (Collection == 2){
            Id2.staker = _address;
        }
        else if (Collection == 3){
            Id3.staker = _address;
        }
    }
    else if (ecoType == 3) { // Fusion Staker
        if (Collection == 1){
            Id.fusionstaker = _address;
        }
        else if (Collection == 2){
            Id2.fusionstaker = _address;
        }
         else if (Collection == 3){
            Id3.fusionstaker = _address;
         }
    }
    else if (ecoType == 4) { // Rent Owner
        if (Collection == 1){
            Id.rentowner = _address;
        }
        else if (Collection == 2){
            Id2.rentowner = _address;
        }
        else if (Collection == 3){
            Id3.rentowner = _address;
        }
    }
    else if (ecoType == 5) { // Renter
        if (Collection == 1){
            Id.renter = _address;
        }
        else if (Collection == 2){
            Id2.renter = _address;
        }
        else if (Collection == 3){
            Id3.renter = _address;
        }
    }
 }   

 //-----------------------------------------------------------------------------------------------------------------------------------
 // RETURNS
 function checkEcosystem(uint Collection, uint ecoType, uint _tokenId) public view returns (address ECS) {
    if (Collection == 1){ // ArmyRank
        if (ecoType == 1){ // seller
            return ArmyEcosystem[_tokenId].seller;
        }
        else if (ecoType == 2){ // staker
            return ArmyEcosystem[_tokenId].staker;
        }
        else if (ecoType == 3){ // fusion staker
            return ArmyEcosystem[_tokenId].fusionstaker;
        }
        else if (ecoType == 4){ // rent owner
            return ArmyEcosystem[_tokenId].rentowner;
        }
        else if (ecoType == 5){ // renter
            return ArmyEcosystem[_tokenId].renter;
        }
    }
    else if (Collection == 2){ //Emblem
        if (ecoType == 1){ // seller
            return EmblemEcosystem[_tokenId].seller;
        }
        else if (ecoType == 2){ // staker
            return EmblemEcosystem[_tokenId].staker;
        }
        else if (ecoType == 3){ // fusion staker
            return EmblemEcosystem[_tokenId].fusionstaker;
        }
        else if (ecoType == 4){ // rent owner
            return EmblemEcosystem[_tokenId].rentowner;
        }
        else if (ecoType == 5){ // renter
            return EmblemEcosystem[_tokenId].renter;
        }
    }
    else if (Collection == 3){ // War Hero
        if (ecoType == 1){ // seller
            return HeroEcosystem[_tokenId].seller;
        }
        else if (ecoType == 2){ // staker
            return HeroEcosystem[_tokenId].staker;
        }
        else if (ecoType == 3){ // fusion staker
            return HeroEcosystem[_tokenId].fusionstaker;
        }
        else if (ecoType == 4){ // rent owner
            return HeroEcosystem[_tokenId].rentowner;
        }
        else if (ecoType == 5){ // renter
            return HeroEcosystem[_tokenId].renter;
        }
    }
 }

}

// SPDX-License-Identifier: MIT
// Honor Protocol - Token
// Duan 
//-----------------------------------------------------------------------------------------------------------------------------------

pragma solidity >= 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract HonorProtocol is ERC20, Ownable {

  struct ArmyRank {
    uint vote;
    address contracts;
    address voter;
    uint castAt;
  }

  struct Governance {
    uint totalvotes;
    uint totalmint;
    uint countmint;
    uint lastmint;
  }

  mapping(address => Governance) public Governances;
  mapping(uint256 => ArmyRank) public ArmyRanks;

  address public miningDao; // Mining Contract
  ERC721 public armyRankNFT;
  address nftaddress;
 
  uint public maxSupply = 25000000 * 10 ** 18; // Reserved for Yield, Staking, Mining & ATE & Future Utility - Honor Ecosystem - 25M (Governance)
  uint public governanceMaxAmount = 1250000 * 10 ** 18;
  uint public miningAmount = 50 * 10 ** 18;
  // uint public cooldownTimeInSeconds = 7884000; // 90 days in seconds
  uint public cooldownTimeInSeconds = 180; // 5 minutes for testnet
  bool public voteStatus = false;
  
  constructor() ERC20('Honor Protocol', 'HONOR') {
    _mint(msg.sender, 2500000 * 10 ** 18); // Initial Total Supply 10% (2.5m)
  }

  function voteOn() external onlyOwner {
    voteStatus = true;
  }
  function voteOff() external onlyOwner {
    voteStatus = false;
  }

  // Set Mining Contract
  function setMiningContract(address _miningDao) external onlyOwner {
    if (miningDao == address(0)) {
      miningDao = _miningDao;
    }
    else {
      // require(Governances[address(this)].totalvotes >= 5, "Not Enough 10% Votes"); // 1000 NFTs out of 10,000
      require(Governances[address(this)].totalvotes >= 5, "Not Enough 10% Votes"); //  5 NFT for testnet
      miningDao = _miningDao;
    }
  }

  // Set NFT Army Ranks Contract
  function setNFTContract(address _nftaddress) external onlyOwner {
    // require(nftaddress == address(0), "One Time Only"); // disabled for testnet
    armyRankNFT = ERC721(_nftaddress);
    nftaddress = address(armyRankNFT);
  }

  // Mint = Mining & Honor Protocol Ecosystem
  function mint(address _address, address _owner, uint256 _amount) public {
    require(msg.sender == miningDao, "Protected, Can only be used by Honor Protocol Mining Ecosystem - Token"); // Only MiningDao can access
    require(_address != owner() || _address != _owner, "Blocked, your are the owner - Token"); // Block OWNER both side (Token & Mining Dao) for safety reasons

    uint256 supply = totalSupply();
    require(_amount + supply <= maxSupply, "Max Supply 25,000,000 - 25M");
    require(_amount <= miningAmount, "Max Minining 50 Token"); // Maximum Mining Token (Max Level NFT General)
    _mint(msg.sender, _amount);
  }

  // Auto Burn
  function burn(uint256 _amount) public {
    _burn(msg.sender, _amount);
  }

  // Goverance Mint (Community Driven)
  function governanceMint(uint _amount) external onlyOwner {
    Governance storage Gov = Governances[address(this)];
    uint daysSinceLastMint = (block.timestamp - Gov.lastmint) / cooldownTimeInSeconds; // Next 90 days can Governance Mint again
    require(daysSinceLastMint >= 1, "Not Past 90 Days");

    uint256 supply = totalSupply();
    require(_amount <= governanceMaxAmount, "Max Governance Mint Amount Exceeded - 1.25M");
    require(_amount + supply <= maxSupply, "Max Supply 25,000,000 - 25M");
    // require(Governances[address(this)].totalvotes >= 3, "Not Enough 55% Votes"); // 5500 NFTs out of 10,000
    require(Governances[address(this)].totalvotes >= 5, "Not Enough 55% Votes"); // 5 for testnet
    _mint(msg.sender, _amount);
    
    uint govamount = Gov.totalmint;
    uint govcount = Gov.countmint;
    Gov.totalvotes = 0;
    Gov.totalmint = govamount + _amount;
    Gov.countmint = govcount + 1;
    Gov.lastmint = block.timestamp;
  }

  // Community Vote
  function castvote(uint _tokenId) public {
    require(voteStatus == true, "Honor Protocol Vote Offline");
    require(nftaddress != address(0), "NFT address is address 0");
    require(msg.sender != owner(), "Owner cannot Vote");
    require(msg.sender == armyRankNFT.ownerOf(_tokenId),"You are not the owner of this TokenId");
    uint votecheck = ArmyRanks[_tokenId].vote;

    if (votecheck == 0){
    ArmyRanks[_tokenId] = ArmyRank(
      1,
      msg.sender,
      nftaddress,
      block.timestamp
      );
    }
    else if (votecheck >= 1) {
      uint daysSinceLastVote = (block.timestamp - ArmyRanks[_tokenId].castAt) / cooldownTimeInSeconds; // Next 90 days can vote again
      require(daysSinceLastVote >= 1, "Not Past 90 Days");

      uint holdervotes = ArmyRanks[_tokenId].vote;
      ArmyRanks[_tokenId] = ArmyRank(
        holdervotes + 1,
        msg.sender,
        nftaddress,
        block.timestamp
      );
    }
    else{
      // no else cases
      revert("Error");
    }

    Governance storage Gov = Governances[address(this)];
    uint addvote = Gov.totalvotes;
    Gov.totalvotes = addvote + 1;
  }

}

// SPDX-License-Identifier: MIT
// Honor Protocol - Busd Mock Token
// Duan
//-----------------------------------------------------------------------------------------------------------------------------------

pragma solidity >= 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// Mock BUSD Token
contract Busd is ERC20, Ownable {

  constructor() ERC20('Mock BUSD token', 'mBUSD') {
    _mint(msg.sender, 2500000 * 10 ** 18); // 25m
  }
  
}

// SPDX-License-Identifier: MIT
// Honor Protocol - Mock Emblem NFT Collection
// Duan
//-----------------------------------------------------------------------------------------------------------------------------------

pragma solidity >= 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

// Mock Emblem NFT
contract EmblemNFT is ERC721Enumerable, Ownable {
      constructor(string memory _name, string memory _symbol, string memory _initBaseURI) ERC721(_name, _symbol) {
  }
}

// SPDX-License-Identifier: MIT
// Honor Protocol - Army Rank NFT Collection
// Duan
//-----------------------------------------------------------------------------------------------------------------------------------

pragma solidity >= 0.8.17;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./Metadata.sol";

contract ArmyRankNFT is ERC721Enumerable, Ownable {
  using Strings for uint256;

  Busd public busdAddress;
  Metadata public metadataAddress;

  string internal baseURI;
  string internal baseExtension = ".json";
  uint256 public busdCost =  300 * 10 ** 18; // Price in busd
  uint256 public maxSupply = 10000;
  uint256 public pubSupply = 9500; // Total supply for public mint
  uint256 maxMintAmount = 1;
  uint256 maxMintAmountDev = 10; // Dev max mint
  bool internal paused = false;
  
  struct PubSale {
    uint Counter;
  }
  mapping(uint256 => PubSale) public PubSales; 
  mapping(address => bool) public whitelisted;

  constructor(string memory _name, string memory _symbol, string memory _initBaseURI, Busd _busdAddress) ERC721(_name, _symbol) {
    setBaseURI(_initBaseURI);
    busdAddress = _busdAddress;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function mint(address _address, uint256 _mintAmount) public payable {
    require(msg.sender == _address, "Only user can mint nft");
    uint256 supply = totalSupply();
    require(!paused);
    require(_mintAmount > 0);
    require(_mintAmount <= maxMintAmount, "Minimun Mint is 1");
    require(supply + _mintAmount <= maxSupply, "Cant Mint Anymore, Sold Out");
    require(busdAddress.balanceOf(_address) >= busdCost, "Not Enough BUSD");

    if (msg.sender != owner()) {
        if(whitelisted[msg.sender] != true) {
          uint CheckCount = PubSales[1].Counter;
          require(CheckCount < pubSupply, "Public Sale, Sold Out");
          require(busdAddress.balanceOf(_address) >= busdCost * _mintAmount, "Not Enough BUSD");
          PubSale storage Sale = PubSales[1];
          Sale.Counter = Sale.Counter + 1;
        }
    }
    for (uint256 i = 1; i <= _mintAmount; i++) {
      _safeMint(_address, supply + i);
      metadataAddress.mintCreator(1,supply + i, _address);
    }
    busdAddress.transferFrom(msg.sender, address(this), busdCost);
  }

  // Mint for Dev
  function devMint(address _to, uint256 _mintAmount) public payable onlyOwner {
    uint256 supply = totalSupply();
    require(!paused);
    require(_mintAmount > 0);
    require(_mintAmount <= maxMintAmountDev);
    require(supply + _mintAmount <= maxSupply, "Cant Mint Anymore, SOLD OUT");

    for (uint256 i = 1; i <= _mintAmount; i++) {
      _safeMint(_to, supply + i);
    }
  }

  function walletOfOwner(address _owner) public view returns (uint256[] memory) {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
      for (uint256 i; i < ownerTokenCount; i++) {
        tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
      }
    return tokenIds;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId),"ERC721Metadata: URI query for nonexistent token");

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
      ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
      : "";
  }

  // Owner - Set
  function setMetadata(address _metadataAddress) external onlyOwner {
    metadataAddress = Metadata(_metadataAddress);
  }
  function setBusdCost(uint256 _BusdCost) external onlyOwner {
    busdCost = _BusdCost;
  }
  function setBaseURI(string memory _BaseURI) public onlyOwner {
    baseURI = _BaseURI;
  }
  function setBaseExtension(string memory _BaseExtension) external onlyOwner {
    baseExtension = _BaseExtension;
  }
  function pause(bool _state) external onlyOwner {
    paused = _state;
  }
 function whitelistUser(address _user) external onlyOwner {
    whitelisted[_user] = true;
  }
  function removeWhitelistUser(address _user) external onlyOwner {
    whitelisted[_user] = false;
  }

  // Owner - Withdrawal Busd
  function withdrawBusd() external onlyOwner {
    busdAddress.transfer(owner(), busdBalance());
  }
  function busdBalance() public view returns (uint) {
    return busdAddress.balanceOf(address(this));
  }

}

// SPDX-License-Identifier: MIT
// Honor Protocol - Mock War Hero NFT Collection
// Duan
//-----------------------------------------------------------------------------------------------------------------------------------

pragma solidity >= 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

// Mock War Hero NFT
contract WarHeroNFT is ERC721Enumerable, Ownable {
      constructor(string memory _name, string memory _symbol, string memory _initBaseURI) ERC721(_name, _symbol) {
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

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
        _approve(owner, spender, allowance(owner, spender) + addedValue);
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
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
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
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
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
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
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