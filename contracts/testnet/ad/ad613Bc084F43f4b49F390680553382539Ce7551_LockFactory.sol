// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./TokenLockForDividendsAndReflections.sol";
import "./VestingLockForDividendsAndReflections.sol";
import "./LiquidityLock.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./ArborSwapDeps/IUniswapV2Pair.sol";
import "./ArborSwapDeps/IUniswapV2Factory.sol";

interface IAdmin {
  function isAdmin(address user) external view returns (bool);
}

contract LockFactory is Ownable {
  using SafeERC20 for IERC20;
  struct FeeInfo {
    uint256 liquidityFee;
    uint256 normalFee;
    uint256 vestingFee;
    uint256 rewardFee;
    uint256 rewardVestingFee;
    address payable feeReceiver;
  }

  IAdmin public admin;
  FeeInfo public fee;

  address[] public tokenLock;
  address[] public liquidityLock;

  mapping(address => address[]) public tokenLockOwner;
  mapping(address => address[]) public liquidityLockOwner;
  mapping(uint256 => address) public liquidityLockIdToAddress;
  mapping(uint256 => address) public tokenLockIdToAddress;

  event LogSetFee(string feeType, uint256 newFee);
  event LogSetFeeReceiver(address newFeeReceiver);
  event LogCreateTokenLock(address lock, address owner);
  event LogCreateLiquidityLock(address lock, address owner);

  constructor(address _adminContract) {
    require(_adminContract != address(0), "ADDRESS_ZERO");
    admin = IAdmin(_adminContract);
  }

  modifier onlyAdmin() {
    require(admin.isAdmin(msg.sender), "NOT_ADMIN");
    _;
  }

  function createTokenLock(
    address _owner,
    address _token,
    uint256 _amount,
    uint256 _unlockDate,
    string memory _logoImage
  ) external payable {
    require(_owner != address(0), "ADDRESS_ZERO");
    require(msg.value >= fee.normalFee, "BAD_FEE");
    require(IERC20(_token).balanceOf(msg.sender) >= _amount, "NOT_ENOUGH_TOKEN");
    require(IERC20(_token).allowance(msg.sender, address(this)) >= _amount, "BAD_ALLOWANCE");

    TokenLockDividendsAndReflections lock = new TokenLockDividendsAndReflections(_owner, _unlockDate, _amount, _token, _logoImage, false);
    address createdLock = address(lock);

    uint256 id = tokenLock.length;
    tokenLockIdToAddress[id] = createdLock;
    tokenLockOwner[_owner].push(createdLock);
    tokenLock.push(createdLock);
    _safeTransferExactAmount(_token, msg.sender, createdLock, _amount);
    fee.feeReceiver.transfer(msg.value);
    emit LogCreateTokenLock(createdLock, _owner);
  }

  function createRewardTokenLock(
    address _owner,
    address _token,
    uint256 _amount,
    uint256 _unlockDate,
    string memory _logoImage
  ) external payable {
    require(_owner != address(0), "ADDRESS_ZERO");
    require(msg.value >= fee.rewardFee, "BAD_FEE");
    require(IERC20(_token).balanceOf(msg.sender) >= _amount, "NOT_ENOUGH_TOKEN");
    require(IERC20(_token).allowance(msg.sender, address(this)) >= _amount, "BAD_ALLOWANCE");

    TokenLockDividendsAndReflections lock = new TokenLockDividendsAndReflections(_owner, _unlockDate, _amount, _token, _logoImage, true);
    address createdLock = address(lock);

    uint256 id = tokenLock.length;
    tokenLockIdToAddress[id] = createdLock;
    tokenLockOwner[_owner].push(createdLock);
    tokenLock.push(createdLock);
    _safeTransferExactAmount(_token, msg.sender, createdLock, _amount);
    fee.feeReceiver.transfer(msg.value);
    emit LogCreateTokenLock(createdLock, _owner);
  }

  function createVestingLock(
    address _owner,
    address _token,
    uint256 _amount,
    uint256 _unlockDate,
    uint256 _tgePercent,
    uint256 _cycle,
    uint256 _cyclePercent,
    string memory _logoImage
  ) external payable {
    require(_owner != address(0), "ADDRESS_ZERO");
    require(msg.value >= fee.vestingFee, "BAD_FEE");
    require(IERC20(_token).balanceOf(msg.sender) >= _amount, "NOT_ENOUGH_TOKEN");
    require(IERC20(_token).allowance(msg.sender, address(this)) >= _amount, "BAD_ALLOWANCE");
    require(_isValidVested(_tgePercent, _cyclePercent), "NOT_VALID_VESTED");

    VestingLockDividendsAndReflections lock = new VestingLockDividendsAndReflections(
      _owner,
      _unlockDate,
      _amount,
      _token,
      _tgePercent,
      _cycle,
      _cyclePercent,
      _logoImage,
      false
    );
    address createdLock = address(lock);

    uint256 id = tokenLock.length;
    tokenLockIdToAddress[id] = createdLock;
    tokenLockOwner[_owner].push(createdLock);
    tokenLock.push(createdLock);
    _safeTransferExactAmount(_token, msg.sender, createdLock, _amount);
    fee.feeReceiver.transfer(msg.value);
    emit LogCreateTokenLock(createdLock, _owner);
  }

  function createRewardVestingLock(
    address _owner,
    address _token,
    uint256 _amount,
    uint256 _unlockDate,
    uint256 _tgePercent,
    uint256 _cycle,
    uint256 _cyclePercent,
    string memory _logoImage
  ) external payable {
    require(_owner != address(0), "ADDRESS_ZERO");
    require(msg.value >= fee.rewardVestingFee, "BAD_FEE");
    require(IERC20(_token).balanceOf(msg.sender) >= _amount, "NOT_ENOUGH_TOKEN");
    require(IERC20(_token).allowance(msg.sender, address(this)) >= _amount, "BAD_ALLOWANCE");
    require(_isValidVested(_tgePercent, _cyclePercent), "NOT_VALID_VESTED");

    VestingLockDividendsAndReflections lock = new VestingLockDividendsAndReflections(
      _owner,
      _unlockDate,
      _amount,
      _token,
      _tgePercent,
      _cycle,
      _cyclePercent,
      _logoImage,
      true
    );
    address createdLock = address(lock);

    uint256 id = tokenLock.length;
    tokenLockIdToAddress[id] = createdLock;
    tokenLockOwner[_owner].push(createdLock);
    tokenLock.push(createdLock);
    _safeTransferExactAmount(_token, msg.sender, createdLock, _amount);
    fee.feeReceiver.transfer(msg.value);
    emit LogCreateTokenLock(createdLock, _owner);
  }

  function createLiquidityLock(
    address _owner,
    address _token,
    uint256 _amount,
    uint256 _unlockDate,
    string memory _logoImage
  ) external payable {
    require(_owner != address(0), "ADDRESS_ZERO");
    address lpFactory = _parseFactoryAddress(_token);
    require(_isValidLpToken(_token, lpFactory), "NOT_VALID_LP_TOKEN");
    require(msg.value >= fee.liquidityFee, "BAD_FEE");
    require(IERC20(_token).balanceOf(msg.sender) >= _amount, "NOT_ENOUGH_TOKEN");
    require(IERC20(_token).allowance(msg.sender, address(this)) >= _amount, "BAD_ALLOWANCE");

    LiquidityLock lock = new LiquidityLock(_owner, _unlockDate, _amount, _token, _logoImage);
    address createdLock = address(lock);

    uint256 id = liquidityLock.length;
    liquidityLockIdToAddress[id] = createdLock;
    liquidityLockOwner[_owner].push(createdLock);
    liquidityLock.push(createdLock);
    _safeTransferExactAmount(_token, msg.sender, createdLock, _amount);
    fee.feeReceiver.transfer(msg.value);
    emit LogCreateLiquidityLock(createdLock, _owner);
  }

  function setNormalFee(uint256 _fee) public onlyAdmin {
    require(fee.normalFee != _fee, "BAD_INPUT");
    fee.normalFee = _fee;
    emit LogSetFee("Normal Fee", _fee);
  }

  function setLiquidityFee(uint256 _fee) public onlyAdmin {
    require(fee.liquidityFee != _fee, "BAD_INPUT");
    fee.liquidityFee = _fee;
    emit LogSetFee("Liquidity Fee", _fee);
  }

  function setVestingFee(uint256 _fee) public onlyAdmin {
    require(fee.vestingFee != _fee, "BAD_INPUT");
    fee.vestingFee = _fee;
    emit LogSetFee("Vesting Fee", _fee);
  }

  function setRewardFee(uint256 _fee) public onlyAdmin {
    require(fee.rewardFee != _fee, "BAD_INPUT");
    fee.rewardFee = _fee;
    emit LogSetFee("Reward Fee", _fee);
  }

  function setRewardVestingFee(uint256 _fee) public onlyAdmin {
    require(fee.rewardVestingFee != _fee, "BAD_INPUT");
    fee.rewardVestingFee = _fee;
    emit LogSetFee("Reward Vesting Fee", _fee);
  }

  function setFeeReceiver(address payable _receiver) public onlyAdmin {
    require(_receiver != address(0), "ADDRESS_ZERO");
    require(fee.feeReceiver != _receiver, "BAD_INPUT");
    fee.feeReceiver = _receiver;
    emit LogSetFeeReceiver(_receiver);
  }

  // GETTER FUNCTION

  function getTokenLock(uint256 startIndex, uint256 endIndex) external view returns (address[] memory) {
    require(endIndex > startIndex, "BAD_INPUT");
    require(endIndex <= tokenLock.length, "OUT_OF_RANGE");

    address[] memory tempLock = new address[](endIndex - startIndex);
    uint256 index = 0;

    for (uint256 i = startIndex; i < endIndex; i++) {
      tempLock[index] = tokenLock[i];
      index++;
    }

    return tempLock;
  }

  function getLiquidityLock(uint256 startIndex, uint256 endIndex) external view returns (address[] memory) {
    require(endIndex > startIndex, "BAD_INPUT");
    require(endIndex <= liquidityLock.length, "OUT_OF_RANGE");

    address[] memory tempLock = new address[](endIndex - startIndex);
    uint256 index = 0;

    for (uint256 i = startIndex; i < endIndex; i++) {
      tempLock[index] = liquidityLock[i];
      index++;
    }

    return tempLock;
  }

  function getTotalTokenLock() external view returns (uint256) {
    return tokenLock.length;
  }

  function getTotalLiquidityLock() external view returns (uint256) {
    return liquidityLock.length;
  }

  function getTokenLockAddress(uint256 id) external view returns (address) {
    return tokenLockIdToAddress[id];
  }

  function getLiquidityLockAddress(uint256 id) external view returns (address) {
    return liquidityLockIdToAddress[id];
  }

  function getLastTokenLock() external view returns (address) {
    if (tokenLock.length > 0) {
      return tokenLock[tokenLock.length - 1];
    }
    return address(0);
  }

  function getLastLiquidityLock() external view returns (address) {
    if (liquidityLock.length > 0) {
      return liquidityLock[liquidityLock.length - 1];
    }
    return address(0);
  }

  // UTILITY

  function _safeTransferExactAmount(
    address token,
    address sender,
    address recipient,
    uint256 amount
  ) internal {
    uint256 oldRecipientBalance = IERC20(token).balanceOf(recipient);
    IERC20(token).safeTransferFrom(sender, recipient, amount);
    uint256 newRecipientBalance = IERC20(token).balanceOf(recipient);
    require(newRecipientBalance - oldRecipientBalance == amount, "NOT_EQUAL_TRANFER");
  }

  function _parseFactoryAddress(address token) internal view returns (address) {
    address possibleFactoryAddress;
    try IUniswapV2Pair(token).factory() returns (address factory) {
      possibleFactoryAddress = factory;
    } catch {
      revert("NOT_LP_TOKEN");
    }
    require(possibleFactoryAddress != address(0) && _isValidLpToken(token, possibleFactoryAddress), "NOT_LP_TOKEN.");
    return possibleFactoryAddress;
  }

  function _isValidLpToken(address token, address factory) private view returns (bool) {
    IUniswapV2Pair pair = IUniswapV2Pair(token);
    address factoryPair = IUniswapV2Factory(factory).getPair(pair.token0(), pair.token1());
    return factoryPair == token;
  }

  function _isValidVested(uint256 tgePercent, uint256 cyclePercent) internal pure returns (bool) {
    return tgePercent + cyclePercent <= 100;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

contract TokenLockDividendsAndReflections {
  using SafeMath for uint256;

  bool public isReward;

  struct LockInfo {
    IERC20 token;
    uint256 amount;
    uint256 lockDate;
    uint256 unlockDate;
    string logoImage;
    bool isWithdrawn;
    bool isVesting;
  }

  LockInfo public lockInfo;

  address public owner;
  address public lockFactory;

  modifier onlyOwner() {
    require(msg.sender == owner, "ONLY_OWNER");
    _;
  }
  modifier onlyRewardLock() {
    require(isReward == true, "ONLY_REWARDLOCK");
    _;
  }
  modifier onlyOwnerOrFactory() {
    require(msg.sender == owner || msg.sender == lockFactory, "ONLY_OWNER_OR_FACTORY");
    _;
  }

  event LogExtendLockTime(uint256 oldUnlockTime, uint256 newUnlockTime);
  event LogWithdraw(address to, uint256 lockedAmount);
  event LogWithdrawReflections(address to, uint256 amount);
  event LogWithdrawDividends(address to, uint256 dividends);
  event LogWithdrawNative(address to, uint256 dividends);
  event LogReceive(address from, uint256 value);

  constructor(
    address _owner,
    uint256 _unlockDate,
    uint256 _amount,
    address _token,
    string memory _logoImage,
    bool _isReward
  ) {
    require(_owner != address(0), "ADDRESS_ZERO");
    owner = _owner;
    // solhint-disable-next-line not-rely-on-time
    lockInfo.lockDate = block.timestamp;
    lockInfo.unlockDate = _unlockDate;
    lockInfo.amount = _amount;
    lockInfo.token = IERC20(_token);
    lockInfo.logoImage = _logoImage;
    lockInfo.isVesting = false;
    isReward = _isReward;
    lockFactory = msg.sender;
  }

  function extendLockTime(uint256 newUnlockDate) external onlyOwner {
    require(lockInfo.isWithdrawn == false, "ALREADY_UNLOCKED");
    uint256 oldDate = lockInfo.unlockDate;

    // solhint-disable-next-line not-rely-on-time,
    require(newUnlockDate >= lockInfo.unlockDate && newUnlockDate > block.timestamp, "BAD_TIME_INPUT");
    lockInfo.unlockDate = newUnlockDate;

    emit LogExtendLockTime(oldDate, newUnlockDate);
  }

  function updateLogo(string memory newLogoImage) external onlyOwner {
    require(lockInfo.isWithdrawn == false, "ALREADY_UNLOCKED");
    lockInfo.logoImage = newLogoImage;
  }

  function unlock() external onlyOwner {
    // solhint-disable-next-line not-rely-on-time,
    require(block.timestamp >= lockInfo.unlockDate, "WRONG_TIME");
    require(lockInfo.isWithdrawn == false, "ALREADY_UNLOCKED");

    lockInfo.isWithdrawn = true;

    lockInfo.token.transfer(owner, lockInfo.amount);

    emit LogWithdraw(owner, lockInfo.amount);
  }

  function withdrawReflections() external onlyRewardLock onlyOwner {
    if (lockInfo.isWithdrawn) {
      uint256 reflections = lockInfo.token.balanceOf(address(this));
      if (reflections > 0) {
        lockInfo.token.transfer(owner, reflections);
      }
      emit LogWithdrawReflections(owner, reflections);
    } else {
      uint256 contractBalanceWReflections = lockInfo.token.balanceOf(address(this));
      uint256 reflections = contractBalanceWReflections - lockInfo.amount;
      if (reflections > 0) {
        lockInfo.token.transfer(owner, reflections);
      }
      emit LogWithdrawReflections(owner, reflections);
    }
  }

  function withdrawDividends(address _token) external onlyRewardLock onlyOwner {
    require(_token != address(lockInfo.token), "CANT_WITHDRAW_LOCKED_ASSETS");
    uint256 dividends = IERC20(_token).balanceOf(address(this));
    if (dividends > 0) {
      IERC20(_token).transfer(owner, dividends);
    }
    emit LogWithdrawDividends(owner, dividends);
  }

  function withdrawBNB() external onlyOwner {
    uint256 amount = address(this).balance;
    payable(owner).transfer(amount);
    emit LogWithdrawNative(owner, amount);
  }

  /**
   * for receive dividend
   */
  receive() external payable {
    emit LogReceive(msg.sender, msg.value);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "./ArborSwapDeps/IUniswapV2Pair.sol";
import "./ArborSwapDeps/IUniswapV2Factory.sol";

contract LiquidityLock {
  using SafeMath for uint256;

  struct LockInfo {
    IUniswapV2Pair token;
    uint256 amount;
    uint256 lockDate;
    uint256 unlockDate;
    string logoImage;
    bool isWithdrawn;
  }

  LockInfo public lockInfo;

  address public owner;
  address public lockFactory;

  modifier onlyOwner() {
    require(msg.sender == owner, "ONLY_OWNER");
    _;
  }
  modifier onlyOwnerOrFactory() {
    require(msg.sender == owner || msg.sender == lockFactory, "ONLY_OWNER_OR_FACTORY");
    _;
  }

  event LogExtendLockTime(uint256 oldUnlockTime, uint256 newUnlockTime);
  event LogWithdraw(address to, uint256 lockedAmount);
  event LogWithdrawNative(address to, uint256 dividends);
  event LogReceive(address from, uint256 value);

  constructor(
    address _owner,
    uint256 _unlockDate,
    uint256 _amount,
    address _token,
    string memory _logoImage
  ) {
    require(_owner != address(0), "ADDRESS_ZERO");
    owner = _owner;
    // solhint-disable-next-line not-rely-on-time
    lockInfo.lockDate = block.timestamp;
    lockInfo.unlockDate = _unlockDate;
    lockInfo.amount = _amount;
    lockInfo.token = IUniswapV2Pair(_token);
    lockInfo.logoImage = _logoImage;
    lockFactory = msg.sender;
  }

  function extendLockTime(uint256 newUnlockDate) external onlyOwner {
    require(lockInfo.isWithdrawn == false, "ALREADY_UNLOCKED");
    uint256 oldDate = lockInfo.unlockDate;

    // solhint-disable-next-line not-rely-on-time,
    require(newUnlockDate >= lockInfo.unlockDate && newUnlockDate > block.timestamp, "BAD_TIME_INPUT");
    lockInfo.unlockDate = newUnlockDate;

    emit LogExtendLockTime(oldDate, newUnlockDate);
  }

  function updateLogo(string memory newLogoImage) external onlyOwner {
    require(lockInfo.isWithdrawn == false, "ALREADY_UNLOCKED");
    lockInfo.logoImage = newLogoImage;
  }

  function unlock() external onlyOwner {
    // solhint-disable-next-line not-rely-on-time,
    require(block.timestamp >= lockInfo.unlockDate, "WRONG_TIME");
    require(lockInfo.isWithdrawn == false, "ALREADY_UNLOCKED");

    lockInfo.isWithdrawn = true;

    lockInfo.token.transfer(owner, lockInfo.amount);

    emit LogWithdraw(owner, lockInfo.amount);
  }

  function withdrawBNB() external onlyOwner {
    uint256 amount = address(this).balance;
    payable(owner).transfer(amount);
    emit LogWithdrawNative(owner, amount);
  }

  /**
   * for receive dividend
   */
  receive() external payable {
    emit LogReceive(msg.sender, msg.value);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

contract VestingLockDividendsAndReflections{
  using SafeMath for uint256;

  bool public isReward;

  struct LockInfo {
    IERC20 token;
    uint256 amount;
    uint256 lockDate;
    uint256 unlockDate;
    string logoImage;
    bool isWithdrawn;
    bool isVesting;
  }

  struct VestingInfo {
    uint256 amount;
    uint256 unlockDate;
    bool isWithdrawn;
  }

  LockInfo public lockInfo;
  VestingInfo[] public vestingInfo;

  address public owner;
  address public lockFactory;

  modifier onlyOwner() {
    require(msg.sender == owner, "ONLY_OWNER");
    _;
  }
  modifier onlyRewardLock() {
    require(isReward == true, "ONLY_REWARDLOCK");
    _;
  }
  modifier onlyOwnerOrFactory() {
    require(msg.sender == owner || msg.sender == lockFactory, "ONLY_OWNER_OR_FACTORY");
    _;
  }
  event LogWithdraw(address to, uint256 lockedAmount);
  event LogWithdrawReflections(address to, uint256 amount);
  event LogWithdrawDividends(address to, uint256 dividends);
  event LogWithdrawNative(address to, uint256 dividends);
  event LogReceive(address from, uint256 value);

  constructor(
    address _owner,
    uint256 _unlockDate,
    uint256 _amount,
    address _token,
    uint256 _tgePercent,
    uint256 _cycle,
    uint256 _cyclePercent,
    string memory _logoImage,
    bool _isReward
  ) {
    require(_owner != address(0), "ADDRESS_ZERO");
    require(_isValidVested(_tgePercent, _cyclePercent), "NOT_VALID_VESTED");
    owner = _owner;
    // solhint-disable-next-line not-rely-on-time
    lockInfo.lockDate = block.timestamp;
    lockInfo.unlockDate = _unlockDate;
    lockInfo.amount = _amount;
    lockInfo.token = IERC20(_token);
    lockInfo.logoImage = _logoImage;
    lockInfo.isVesting = true;
    lockFactory = msg.sender;
    isReward = _isReward;

    //_initializeVested(_amount, _unlockDate, _tgePercent, _cycle, _cyclePercent);
  }

  function _isValidVested(uint256 tgePercent, uint256 cyclePercent) internal pure returns (bool) {
    return tgePercent + cyclePercent <= 100;
  }

  function _initializeVested(
    uint256 amount,
    uint256 unlockDate,
    uint256 tgePercent,
    uint256 cycle,
    uint256 cyclePercent
  ) internal {
    uint256 tgeValue = (amount * tgePercent) / 100;
    uint256 cycleValue = (amount * cyclePercent) / 100;
    uint256 tempAmount = amount - tgeValue;
    uint256 tempUnlock = unlockDate;

    VestingInfo memory vestInfo;

    vestInfo.amount = tgeValue;
    vestInfo.unlockDate = unlockDate;
    vestInfo.isWithdrawn = false;
    vestingInfo.push(vestInfo);

    while (tempAmount > 0) {
      uint256 vestCycleValue = tempAmount > cycleValue ? cycleValue : tempAmount;
      tempUnlock = tempUnlock + cycle;
      vestInfo.amount = vestCycleValue;
      vestInfo.unlockDate = tempUnlock;
      vestInfo.isWithdrawn = false;
      vestingInfo.push(vestInfo);
      tempAmount = tempAmount - vestCycleValue;
    }
  }

  function updateLogo(string memory newLogoImage) external onlyOwner {
    require(lockInfo.isWithdrawn == false, "ALREADY_UNLOCKED");
    lockInfo.logoImage = newLogoImage;
  }

  function unlock() external onlyOwner {
    // solhint-disable-next-line not-rely-on-time,
    require(block.timestamp >= lockInfo.unlockDate, "WRONG_TIME");
    require(lockInfo.isWithdrawn == false, "ALREADY_UNLOCKED");

    uint256 unlocked = 0;
    for (uint256 i = 0; i < vestingInfo.length; i++) {
      // solhint-disable-next-line not-rely-on-time,
      if (!vestingInfo[i].isWithdrawn && vestingInfo[i].unlockDate < block.timestamp) {
        unlocked = unlocked + vestingInfo[i].amount;
        vestingInfo[i].isWithdrawn = true;
      }
    }
    if (unlocked == lockInfo.amount) {
      lockInfo.isWithdrawn = true;
    }

    lockInfo.token.transfer(owner, unlocked);

    emit LogWithdraw(owner, unlocked);
  }

  function getLockedValue() public view returns (uint256) {
    uint256 locked = 0;
    for (uint256 i = 0; i < vestingInfo.length; i++) {
      if (!vestingInfo[i].isWithdrawn) {
        locked = locked + vestingInfo[i].amount;
      }
    }
    return locked;
  }

  function withdrawReflections() external onlyRewardLock onlyOwner {
    if (lockInfo.isWithdrawn) {
      uint256 reflections = lockInfo.token.balanceOf(address(this));
      if (reflections > 0) {
        lockInfo.token.transfer(owner, reflections);
      }
      emit LogWithdrawReflections(owner, reflections);
    } else {
      uint256 contractBalanceWReflections = lockInfo.token.balanceOf(address(this));
      uint256 lockedValue = getLockedValue();
      uint256 reflections = contractBalanceWReflections - lockedValue;
      if (reflections > 0) {
        lockInfo.token.transfer(owner, reflections);
      }
      emit LogWithdrawReflections(owner, reflections);
    }
  }

  function withdrawDividends(address _token) external onlyRewardLock onlyOwner {
    require(_token != address(lockInfo.token), "CANT_WITHDRAW_LOCKED_ASSETS");
    uint256 dividends = IERC20(_token).balanceOf(address(this));
    if (dividends > 0) {
      IERC20(_token).transfer(owner, dividends);
    }
    emit LogWithdrawDividends(owner, dividends);
  }

  function withdrawBNB() external onlyOwner {
    uint256 amount = address(this).balance;
    payable(owner).transfer(amount);
    emit LogWithdrawNative(owner, amount);
  }

  /**
   * for receive dividend
   */
  receive() external payable {
    emit LogReceive(msg.sender, msg.value);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}