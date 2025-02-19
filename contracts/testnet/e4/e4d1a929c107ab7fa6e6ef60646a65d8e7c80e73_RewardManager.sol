// SPDX-License-Identifier: GPL

pragma solidity 0.8.0;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "../libs/fota/RewardAuth.sol";
import "../interfaces/IGameMiningPool.sol";
import "../interfaces/IFOTAGame.sol";
import "../interfaces/ICitizen.sol";
import "../interfaces/IFOTAPricer.sol";
import "../interfaces/IGameNFT.sol";
import "../libs/fota/Math.sol";
import "../interfaces/IFarm.sol";
import "../interfaces/IFOTAToken.sol";
import "../interfaces/ILandLordManager.sol";

contract RewardManager is RewardAuth, PausableUpgradeable {
  using Math for uint;
  enum PaymentType {
    fota,
    usd,
    all,
    other
  }
  enum PaymentCurrency {
    fota,
    busd,
    usdt,
    other
  }

  IGameNFT public heroNft;
  IGameMiningPool public gameMiningPool;
  IFOTAGame public gameProxyContract;
  ICitizen public citizen;
  IFOTAPricer public fotaPricer;
  IFarm public farm;
  IFOTAToken public fotaToken;
  IBEP20 public busdToken;
  IBEP20 public usdtToken;
  PaymentType public paymentType;
  address public fundAdmin;
  ILandLordManager public landLordManager;
  uint public farmShare; // decimal 3
  uint public referralShare; // decimal 3
  uint public landLordShare; // decimal 3
  uint public dailyQuestReward;
  address public treasuryAddress;
  mapping (address => uint) public userRewards;
  mapping (address => uint) public userPrestigeShards;
  uint public treasuryShareAmount;
  uint public farmShareAmount;
  uint public fotaDiscount; // decimal 3 //todo remove mainnet
  uint constant oneHundredPercentageDecimal3 = 100000;
  uint public prestigeShardCheckpoint;
  uint public gemRate;
  IBEP20 public otherPayment;
  uint[4] private discounts; // decimal 3

  event DiscountUpdated(uint[4] discounts);
  event GemRateUpdated(uint gemRate, uint timestamp);
  event Deposited(address indexed user, uint amount, uint discount, uint timestamp, PaymentCurrency paymentCurrency);
  event PaymentTypeUpdated(PaymentType newMethod);
  event PrestigeShardCheckpointUpdated(uint prestigeShardCheckpoint, uint timestamp);
  event ShareUpdated(uint referralShare, uint farmShare, uint landLordShare);
  event StoreDeposited(address[] users, uint[] amounts, uint timestamp);
  event UserRewardChanged(address indexed user, int amount, uint remainingAmount);

  function initialize(address _mainAdmin, address _citizen, address _fotaPricer) public initializer {
    super.initialize(_mainAdmin);
    citizen = ICitizen(_citizen);
    fotaPricer = IFOTAPricer(_fotaPricer);
    fotaToken = IFOTAToken(0x0A4E1BdFA75292A98C15870AeF24bd94BFFe0Bd4);
//    gameMiningPool = IFOTAToken(0x0A4E1BdFA75292A98C15870AeF24bd94BFFe0Bd4); // TODO use this on mainnet deploy
    farmShare = 3000;
    referralShare = 2000;
    landLordShare = 1000;

    busdToken = IBEP20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
    usdtToken = IBEP20(0x55d398326f99059fF775485246999027B3197955);
  }

  // _data: 0: userReward, 1: prestigeShard, 2: referralReward, 3: farmShare, 4: biggestFinishMission, 5: timestamp, 6->n: landLord
  function addPVEReward(address _user, uint[] memory _data) external onlyGameContract {
    // add user reward
    userRewards[_user] += _data[0];
    userPrestigeShards[_user] += _data[1];
    // inviter or treasury
    address inviterOrTreasury = citizen.getInviter(_user);
    if (inviterOrTreasury == address(0)) {
      inviterOrTreasury = treasuryAddress;
    }
    bool validInviter = gameProxyContract.validateInviter(inviterOrTreasury);
    if (validInviter) {
      userRewards[inviterOrTreasury] += _data[2];
    } else {
      treasuryShareAmount += _data[2];
    }
    // farm
    farmShareAmount += _data[3];
    // land lord
    uint halfLandlordLength = (_data.length - 6) / 2;
    uint endForLoop = 5 + halfLandlordLength;
    for(uint i = 6; i <= endForLoop; i++) {
      landLordManager.giveReward(_data[i], _data[i + halfLandlordLength]);
    }
    emit UserRewardChanged(_user, int(_data[0]), userRewards[_user]);
  }

  function addPVPReward(address _user, int gem) external onlyGameContract {
    if (gem > 0) {
      userRewards[_user] += uint(gem);
    } else {
      userRewards[_user] -= uint(gem * -1);
    }
    emit UserRewardChanged(_user, gem, userRewards[_user]);
  }

  function deposit(uint _amount, PaymentCurrency _paymentCurrency) external whenNotPaused {
    uint fundAmountInDollar = _amount / gemRate; // _amount is in GEM decimal 18, need to convert to $ before take fund
    uint discount;
    if(_paymentCurrency == PaymentCurrency.fota) {
      discount = discounts[0];
      _takeFund(_convertUsdToFota(fundAmountInDollar) * (oneHundredPercentageDecimal3 - discount) / oneHundredPercentageDecimal3, _paymentCurrency);
    } else if(_paymentCurrency == PaymentCurrency.busd) {
      discount = discounts[1];
      _takeFund(fundAmountInDollar  * (oneHundredPercentageDecimal3 - discount) / oneHundredPercentageDecimal3, _paymentCurrency);
    } else if(_paymentCurrency == PaymentCurrency.usdt) {
      discount = discounts[2];
      _takeFund(fundAmountInDollar  * (oneHundredPercentageDecimal3 - discount) / oneHundredPercentageDecimal3, _paymentCurrency);
    } else {
      require(address(otherPayment) != address(0), "RewardManager: not supported for now");
      _takeFund(fundAmountInDollar  * (oneHundredPercentageDecimal3 - discount) / oneHundredPercentageDecimal3, _paymentCurrency);
    }
    userRewards[msg.sender] += _amount;
    emit Deposited(msg.sender, _amount, discount, block.timestamp, _paymentCurrency);
  }

  function getDiscounts() external view returns (uint[4] memory) {
    return discounts;
  }

  // ADMIN FUNCTIONS

  function storeDeposit(address[] calldata _users, uint[] calldata _amounts) external onlyContractAdmin {
    for (uint i = 0; i < _users.length; i++) {
      userRewards[_users[i]] += _amounts[i];
    }
    emit StoreDeposited(_users, _amounts, block.timestamp);
  }

  function updatePaymentType(PaymentType _type) external onlyMainAdmin {
    paymentType = _type;
    emit PaymentTypeUpdated(_type);
  }

  function updateTreasuryAddress(address _newAddress) external onlyMainAdmin {
    require(_newAddress != address(0), "Invalid address");
    treasuryAddress = _newAddress;
  }

  function updateFundAdmin(address _address) external onlyMainAdmin {
    require(_address != address(0));
    fundAdmin = _address;
  }

  function updateDiscounts(uint[4] calldata _discounts) external onlyMainAdmin {
    for (uint i = 0; i < _discounts.length; i++) {
      require(_discounts[i] >= 0 && _discounts[i] <= oneHundredPercentageDecimal3, "Invalid data");
    }
    discounts = _discounts;
    emit DiscountUpdated(discounts);
  }

  function updatePrestigeShardCheckpoint(uint _prestigeShardCheckpoint) external onlyMainAdmin {
    prestigeShardCheckpoint = _prestigeShardCheckpoint;
    emit PrestigeShardCheckpointUpdated(prestigeShardCheckpoint, block.timestamp);
  }

  function updateGemRate(uint _gemRate) external onlyMainAdmin {
    gemRate = _gemRate;
    emit GemRateUpdated(_gemRate, block.timestamp);
  }

  function setShares(uint _referralShare, uint _farmShare, uint _landLordShare) external onlyMainAdmin {
    require(_referralShare > 0 && _referralShare <= 10000);
    referralShare = _referralShare;
    require(_farmShare > 0 && _farmShare <= 10000);
    farmShare = _farmShare;
    require(_landLordShare > 0 && _landLordShare <= 10000);
    landLordShare = _landLordShare;
    emit ShareUpdated(referralShare, farmShare, landLordShare);
  }

  function setContracts(address _heroNft, address _fotaToken, address _landLordManager, address _farmAddress, address _gameProxyContract, address _fotaPricer, address _citizen, address _gameMiningPool) external onlyMainAdmin {
    heroNft = IGameNFT(_heroNft);
    fotaToken = IFOTAToken(_fotaToken);
    landLordManager = ILandLordManager(_landLordManager);
    gameProxyContract = IFOTAGame(_gameProxyContract);
    fotaPricer = IFOTAPricer(_fotaPricer);
    citizen = ICitizen(_citizen);
    gameMiningPool = IGameMiningPool(_gameMiningPool);
    require(_farmAddress != address(0), "Invalid address");
    farm = IFarm(_farmAddress);
    fotaToken.approve(_landLordManager, type(uint).max);
    fotaToken.approve(_farmAddress, type(uint).max);
  }

  function updatePauseStatus(bool _paused) external onlyMainAdmin {
    if(_paused) {
      _pause();
    } else {
      _unpause();
    }
  }

  function useTreasuryShareAmount(uint _amount) external onlyMainAdmin {
    require(_amount <= treasuryShareAmount, "Data invalid");
    treasuryShareAmount -= _amount;
    gameMiningPool.releaseGameAllocation(treasuryAddress, _convertUsdToFota(_amount / gemRate));
  }

  function useFarmShareAmount(uint _amount) external onlyMainAdmin {
    require(_amount <= farmShareAmount, "Data invalid");
    farmShareAmount -= _amount;
    uint distributedToFarm = _convertUsdToFota(_amount / gemRate);
    gameMiningPool.releaseGameAllocation(address(this), distributedToFarm);
    farm.fundFOTA(distributedToFarm);
  }

  function summonHero(address _user, uint _heroPrice) external onlyContractAdmin {
    uint gemAmount = _heroPrice * gemRate;
    require(userRewards[_user] >= gemAmount, "RewardManager: insufficient balance");
    userRewards[_user] -= gemAmount;
    emit UserRewardChanged(_user, int(gemAmount) * -1, userRewards[_user]);
  }

  function summonPrestigeHero(address _user, uint _heroPrice) external onlyContractAdmin {
    uint gemAmount = _heroPrice * gemRate;
    require(userRewards[_user] >= gemAmount, "RewardManager: insufficient balance");
    require(userPrestigeShards[_user] > 0, "RewardManager: insufficient prestige shard balance");
    userRewards[_user] -= gemAmount;
    userPrestigeShards[_user] -= 1;
    emit UserRewardChanged(_user, int(gemAmount) * -1, userRewards[_user]);
  }

  // TODO for testing purpose only

  function setUserPrestigeShards(address _user, uint _amount) external onlyMainAdmin {
    userPrestigeShards[_user] = _amount;
  }

  function setPaymentCurrencyToken(address _busd, address _usdt, address _fota, address _other) external onlyMainAdmin {
    require(_busd != address(0) && _usdt != address(0) && _fota != address(0), "RewardManager: invalid address");

    busdToken = IBEP20(_busd);
    usdtToken = IBEP20(_usdt);
    fotaToken = IFOTAToken(_fota);
    otherPayment = IBEP20(_other);
  }

  // PRIVATE FUNCTIONS

  function _convertUsdToFota(uint _amount) private view returns (uint) {
    return _amount * 1000 / fotaPricer.fotaPrice();
  }

  function _takeFund(uint _amount, PaymentCurrency _paymentCurrency) private {
    if (paymentType == PaymentType.fota) {
      _takeFundFOTA(_amount);
    } else if (paymentType == PaymentType.usd) {
      _takeFundUSD(_amount, _paymentCurrency);
    } else if (paymentType == PaymentType.other) {
      _takeFundOther(_amount);
    } else if (_paymentCurrency == PaymentCurrency.fota) {
      _takeFundFOTA(_amount);
    }  else if (_paymentCurrency == PaymentCurrency.other) {
      _takeFundOther(_amount);
    } else {
      _takeFundUSD(_amount, _paymentCurrency);
    }
  }

  function _takeFundUSD(uint _amount, PaymentCurrency _paymentCurrency) private {
    require(_paymentCurrency != PaymentCurrency.fota, "RewardManagerV2: paymentCurrency invalid");
    IBEP20 usdToken = _paymentCurrency == PaymentCurrency.busd ? busdToken : usdtToken;
    require(usdToken.allowance(msg.sender, address(this)) >= _amount, "RewardManagerV2: allowance invalid");
    require(usdToken.balanceOf(msg.sender) >= _amount, "RewardManagerV2: insufficient balance");
    require(usdToken.transferFrom(msg.sender, fundAdmin, _amount), "RewardManagerV2: transfer error");
  }

  function _takeFundFOTA(uint _amount) private {
    require(fotaToken.allowance(msg.sender, address(this)) >= _amount, "RewardManagerV2: allowance invalid");
    require(fotaToken.balanceOf(msg.sender) >= _amount, "RewardManagerV2: insufficient balance");
    require(fotaToken.transferFrom(msg.sender, fundAdmin, _amount), "RewardManagerV2: transfer error");
  }

  function _takeFundOther(uint _amount) private {
    require(otherPayment.allowance(msg.sender, address(this)) >= _amount, "RewardManagerV2: allowance invalid");
    require(otherPayment.balanceOf(msg.sender) >= _amount, "RewardManagerV2: insufficient balance");
    require(otherPayment.transferFrom(msg.sender, fundAdmin, _amount), "RewardManagerV2: transfer error");
  }

  // TODO for testing purpose only

  function setTokenContract(address _fotaToken, address _busdToken, address _usdtToken) external onlyMainAdmin {
    fotaToken = IFOTAToken(_fotaToken);
    busdToken = IFOTAToken(_busdToken);
    usdtToken = IFOTAToken(_usdtToken);
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

// SPDX-License-Identifier: GPL

pragma solidity 0.8.0;

import "./Auth.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

abstract contract RewardAuth is Auth, ContextUpgradeable {
  mapping(address => bool) public gameContracts;

  function initialize(address _mainAdmin) virtual override public {
    Auth.initialize(_mainAdmin);
  }

  modifier onlyGameContract() {
    require(_isGameContracts() || _isMainAdmin(), "NFTAuth: Only game contract");
    _;
  }

  function _isGameContracts() internal view returns (bool) {
    return gameContracts[_msgSender()];
  }

  function updateGameContract(address _contract, bool _status) onlyMainAdmin external {
    require(_contract != address(0), "NFTAuth: Address invalid");
    gameContracts[_contract] = _status;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

library Math {

  function add(uint a, uint b) internal pure returns (uint) {
    unchecked {
      uint256 c = a + b;
      require(c >= a, "SafeMath: addition overflow");

      return c;
    }
  }

  function sub(uint a, uint b) internal pure returns (uint) {
    unchecked {
      require(b <= a, "Math: sub underflow");
      uint256 c = a - b;

      return c;
    }
  }

  function mul(uint a, uint b) internal pure returns (uint) {
    unchecked {
      if (a == 0) {
        return 0;
      }

      uint256 c = a * b;
      require(c / a == b, "SafeMath: multiplication overflow");

      return c;
    }
  }

  function div(uint a, uint b) internal pure returns (uint) {
    unchecked {
      require(b > 0, "SafeMath: division by zero");
      uint256 c = a / b;

      return c;
    }
  }

  function genRandomNumber(string memory _seed, uint _dexRandomSeed) internal view returns (uint8) {
    return genRandomNumberInRange(_seed, _dexRandomSeed, 0, 99);
  }

  function genRandomNumberInRange(string memory _seed, uint _dexRandomSeed, uint _from, uint _to) internal view returns (uint8) {
    require(_to > _from, 'Math: Invalid range');
    uint randomNumber = uint(
      keccak256(
        abi.encodePacked(
          keccak256(
            abi.encodePacked(
              block.number,
              block.difficulty,
              block.timestamp,
              msg.sender,
              _seed,
              _dexRandomSeed
            )
          )
        )
      )
    ) % (_to - _from + 1);
    return uint8(randomNumber + _from);
  }

  function genRandomNumberInRangeUint(string memory _seed, uint _dexRandomSeed, uint _from, uint _to) internal view returns (uint) {
    require(_to > _from, 'Math: Invalid range');
    uint randomNumber = uint(
      keccak256(
        abi.encodePacked(
          keccak256(
            abi.encodePacked(
              block.number,
              block.difficulty,
              block.timestamp,
              msg.sender,
              _seed,
              _dexRandomSeed
            )
          )
        )
      )
    ) % (_to - _from + 1);
    return uint(randomNumber + _from);
  }
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

interface ILandLordManager {
  function giveReward(uint _mission, uint _amount) external;
  function syncLandLord(uint _mission) external;
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
  function increaseTotalProfited(uint _tokenId, uint _amount) external returns (uint);
  function lockedFromMKP(uint _tokenId) external view returns (bool);
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
  function updateLockedFromMKPStatus(uint[] calldata _tokenIds, bool _status) external;
}

// SPDX-License-Identifier: GPL

pragma solidity 0.8.0;

interface IGameMiningPool {
  function releaseGameAllocation(address _gamerAddress, uint _amount) external returns (bool);
}

// SPDX-License-Identifier: GPL

pragma solidity 0.8.0;

interface IFarm {
  function fundFOTA(uint _amount) external;
  function farmers(address _farmer) external view returns (uint, uint, uint, uint, uint, uint);
}

// SPDX-License-Identifier: GPL

pragma solidity 0.8.0;

import "../libs/zeppelin/token/BEP20/IBEP20.sol";

interface IFOTAToken is IBEP20 {
  function releaseGameAllocation(address _gamerAddress, uint _amount) external returns (bool);
  function releasePrivateSaleAllocation(address _buyerAddress, uint _amount) external returns (bool);
  function releaseSeedSaleAllocation(address _buyerAddress, uint _amount) external returns (bool);
  function releaseStrategicSaleAllocation(address _buyerAddress, uint _amount) external returns (bool);
  function burn(uint _amount) external;
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