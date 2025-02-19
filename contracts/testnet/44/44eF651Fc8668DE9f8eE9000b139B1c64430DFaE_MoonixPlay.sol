//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract MoonixPlay is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address private DeadAddress = address(0x000000000000000000000000000000000000dEaD);
    address public tokenAddress;

    struct PlayedInfo {
        uint256 timesPlayed;
        uint256 paidOut;
        uint256 burnt;
    }

    struct UserPlayedInfo{
		uint256 timesPlayed;		
        uint256 totalBetAmount;
        uint256 totalReturned;
		uint256 wins;
        uint256 returningAmount;
	}
    
	mapping(address => UserPlayedInfo) public userDiceInfo;
    mapping(address => UserPlayedInfo) public userCoinFlipInfo;
    mapping(address => UserPlayedInfo) public userSpinInfo;
    mapping(address => UserPlayedInfo) public userRoshamboInfo;

    PlayedInfo public playInfo;
    PlayedInfo public diceInfo;
    PlayedInfo public coinFlipInfo;
    PlayedInfo public spinInfo;
    PlayedInfo public roshamboInfo;

    bool public dicePlayable = true;
    uint256 public diceReturnsPercentage = 60000;
    uint256 public diceBurnOnLossPercentage = 1000;
    uint randDiceNonce = 0;

    bool public coinFlipPlayable = true;
    uint256 public coinFlipReturnsPercentage = 20000;
    uint256 public coinFlipBurnOnLossPercentage = 1000;
    uint randCoinFlipNonce = 0;

    bool public spinPlayable = true;
    uint256 public spinReturnsPercentage = 40000;
    uint256 public spinBurnOnLossPercentage = 1000;
    uint randSpinNonce = 0;

    bool public roshamboPlayable = true;
    uint256 public roshamboReturnsPercentage = 30000;
    uint256 public roshamboBurnOnLossPercentage = 1000;
    uint randRoshamboNonce = 0;

    uint256 maxBetAmount = 1250 ether;
    uint256 minBetAmount = 250 ether;

    event DiceRollResult(address bidder, uint256 betAmount, uint256 betNumber, uint256 result, uint256 returned, uint256 burnt);
    event CoinFlipResult(address bidder, uint256 betAmount, string betSide, string result, uint256 returned, uint256 burnt);
    event SpinWheelResult(address bidder, uint256 betAmount, string betPlace, string result, uint256 returned, uint256 burnt);
    event RoshamboResult(address bidder, uint256 betAmount, string betGesture, string result, uint256 returned, uint256 burnt);

    constructor(address _tokenAddress) {
        tokenAddress = _tokenAddress;        
    }

    function placeDiceRollBet(uint256 amount, uint256 betNumber) public {
		require(
            dicePlayable,
            "MoonixPlay: DiceRoll can not be played!"
        );
        require(
            amount >= minBetAmount,
            "MoonixPlay: Your amount should be equal or greater than min bet!"
        );
        require(
            amount <= maxBetAmount,
            "MoonixPlay: Your amount should be equal or less than max bet!"
        );

		uint256 destiny = diceRandom();		
		
        IERC20(tokenAddress).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );

        uint256 burnAmount = 0;

        UserPlayedInfo storage userInfo = userDiceInfo[msg.sender];
        userInfo.timesPlayed += 1;          
        userInfo.totalBetAmount += amount;
        randDiceNonce++;
        // randDiceNonce += destiny;
        if (userInfo.returningAmount > 0) { // user didnt claim his previous winning
            IERC20(tokenAddress).safeTransfer(msg.sender, userInfo.returningAmount);
            userInfo.returningAmount = 0;  
        }

		if(destiny == betNumber){ //win
            userInfo.returningAmount = amount.mul(diceReturnsPercentage).div(10000);
            userInfo.wins += 1;           
            userInfo.totalReturned += userInfo.returningAmount;
            updateDiceInfo(userInfo.returningAmount, 0);
		}else{ //lost
			userInfo.returningAmount = 0;
            burnAmount = amount.mul(diceBurnOnLossPercentage).div(10000);
            IERC20(tokenAddress).safeTransfer(DeadAddress, burnAmount);
            updateDiceInfo(0, burnAmount);
		}        
        
        emit DiceRollResult(msg.sender, amount, betNumber, destiny, userInfo.returningAmount, burnAmount);
	}

    function placeCoinFlipBet(uint256 amount, uint256 betSide) public { //betSide 1: heads 2: tails
		require(
            coinFlipPlayable,
            "MoonixPlay: CoinFlip can not be played!"
        );
        require(
            amount >= minBetAmount,
            "MoonixPlay: Your amount should be equal or greater than min bet!"
        );
        require(
            amount <= maxBetAmount,
            "MoonixPlay: Your amount should be equal or less than max bet!"
        );

		uint256 destiny = coinFlipRandom();		
		
        IERC20(tokenAddress).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );

        uint256 burnAmount = 0;

        UserPlayedInfo storage userInfo = userCoinFlipInfo[msg.sender];
        userInfo.timesPlayed += 1;          
        userInfo.totalBetAmount += amount;
        randCoinFlipNonce++;
        // randCoinFlipNonce += destiny;
        if (userInfo.returningAmount > 0) { // user didnt claim his previous winning
            IERC20(tokenAddress).safeTransfer(msg.sender, userInfo.returningAmount);
            userInfo.returningAmount = 0;  
        }

		if(destiny == betSide){ //win (1: heads 2: tails)
            userInfo.returningAmount = amount.mul(coinFlipReturnsPercentage).div(10000);
            userInfo.wins += 1;           
            userInfo.totalReturned += userInfo.returningAmount;
            updateCoinFlipInfo(userInfo.returningAmount, 0);
		}else{ //lost
			userInfo.returningAmount = 0;
            burnAmount = amount.mul(coinFlipBurnOnLossPercentage).div(10000);
            IERC20(tokenAddress).safeTransfer(DeadAddress, burnAmount);
            updateCoinFlipInfo(0, burnAmount);
		}        
        
        emit CoinFlipResult(msg.sender, amount, getSideFromNo(betSide), getSideFromNo(destiny), userInfo.returningAmount, burnAmount);
	}

    function placeSpinBet(uint256 amount, uint256 betPlace) public { //betPlace 1: Red 2: Yellow: Red 3: Green: Red 4: Blue
		require(
            spinPlayable,
            "MoonixPlay: Spin the wheel can not be played!"
        );
        require(
            amount >= minBetAmount,
            "MoonixPlay: Your amount should be equal or greater than min bet!"
        );
        require(
            amount <= maxBetAmount,
            "MoonixPlay: Your amount should be equal or less than max bet!"
        );

		uint256 destiny = spinRandom();		
		
        IERC20(tokenAddress).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );

        uint256 burnAmount = 0;

        UserPlayedInfo storage userInfo = userSpinInfo[msg.sender];
        userInfo.timesPlayed += 1;          
        userInfo.totalBetAmount += amount;
        randSpinNonce++;
        // randSpinNonce += destiny;
        if (userInfo.returningAmount > 0) { // user didnt claim his previous winning
            IERC20(tokenAddress).safeTransfer(msg.sender, userInfo.returningAmount);
            userInfo.returningAmount = 0;  
        }

		if(destiny == betPlace){ //win
            userInfo.returningAmount = amount.mul(spinReturnsPercentage).div(10000);
            userInfo.wins += 1;           
            userInfo.totalReturned += userInfo.returningAmount;
            updateSpinInfo(userInfo.returningAmount, 0);
		}else{ //lost
			userInfo.returningAmount = 0;
            burnAmount = amount.mul(spinBurnOnLossPercentage).div(10000);
            IERC20(tokenAddress).safeTransfer(DeadAddress, burnAmount);
            updateSpinInfo(0, burnAmount);
		}        
        
        emit SpinWheelResult(msg.sender, amount, getSpinPlaceFromNo(betPlace), getSpinPlaceFromNo(destiny), userInfo.returningAmount, burnAmount);        
	}

    function placeRoshamboBet(uint256 amount, uint256 betGesture) public { // 1: Rock 2: Paper 3: Scissors
		require(
            roshamboPlayable,
            "MoonixPlay: Rock, Paper, Scissors can not be played!"
        );
        require(
            amount >= minBetAmount,
            "MoonixPlay: Your amount should be equal or greater than min bet!"
        );
        require(
            amount <= maxBetAmount,
            "MoonixPlay: Your amount should be equal or less than max bet!"
        );

		uint256 destiny = roshamboRandom();		
		
        IERC20(tokenAddress).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );

        uint256 burnAmount = 0;

        UserPlayedInfo storage userInfo = userRoshamboInfo[msg.sender];
        userInfo.timesPlayed += 1;          
        userInfo.totalBetAmount += amount;
        randRoshamboNonce++;
        // randRoshamboNonce += destiny;
        if (userInfo.returningAmount > 0) { // user didnt claim his previous winning
            IERC20(tokenAddress).safeTransfer(msg.sender, userInfo.returningAmount);
            userInfo.returningAmount = 0;  
        }

		if(destiny == 1 && betGesture == 2 || destiny == 2 && betGesture == 3 || destiny == 3 && betGesture == 1){ //win (1: rock 2: paper 3: scissors)
            userInfo.returningAmount = amount.mul(roshamboReturnsPercentage).div(10000);
            userInfo.wins += 1;           
            userInfo.totalReturned += userInfo.returningAmount;
            updateRoshamboInfo(userInfo.returningAmount, 0);
		}else{ //lost
			userInfo.returningAmount = 0;
            burnAmount = amount.mul(roshamboBurnOnLossPercentage).div(10000);
            IERC20(tokenAddress).safeTransfer(DeadAddress, burnAmount);
            updateRoshamboInfo(0, burnAmount);
		}        
        
        emit RoshamboResult(msg.sender, amount, getRoshamboGestureFromNo(betGesture), getRoshamboGestureFromNo(destiny), userInfo.returningAmount, burnAmount);        
	}
    
    function getSideFromNo(uint256 num) internal pure returns(string memory) {
        if (num == 1) return "Heads";
        else return "Tails";
    }

    function getSpinPlaceFromNo(uint256 num) internal pure returns(string memory) {
        if (num == 1) return "Red";
        if (num == 2) return "Yellow";
        if (num == 3) return "Green";
        if (num == 4) return "Blue";
        return "Red";
    }

    function getRoshamboGestureFromNo(uint256 num) internal pure returns(string memory) {
        if (num == 1) return "Rock";
        if (num == 2) return "Paper";
        if (num == 3) return "Scissors";        
        return "Rock";
    }

    function claimDiceRollWin() external nonReentrant {
        UserPlayedInfo memory userInfo = userDiceInfo[msg.sender];

        require(
            userInfo.returningAmount > 0,
            "MoonixPlay: You don't have claimable tokens!"
        );        
        
        IERC20(tokenAddress).safeTransfer(msg.sender, userInfo.returningAmount);

        userInfo.returningAmount = 0;       
        userDiceInfo[msg.sender] = userInfo;
    }

    function claimCoinFlipWin() external nonReentrant {
        UserPlayedInfo memory userInfo = userCoinFlipInfo[msg.sender];

        require(
            userInfo.returningAmount > 0,
            "MoonixPlay: You don't have claimable tokens!"
        );        
        
        IERC20(tokenAddress).safeTransfer(msg.sender, userInfo.returningAmount);

        userInfo.returningAmount = 0;       
        userCoinFlipInfo[msg.sender] = userInfo;
    }

    function claimSpinWin() external nonReentrant {
        UserPlayedInfo memory userInfo = userSpinInfo[msg.sender];

        require(
            userInfo.returningAmount > 0,
            "MoonixPlay: You don't have claimable tokens!"
        );        
        
        IERC20(tokenAddress).safeTransfer(msg.sender, userInfo.returningAmount);

        userInfo.returningAmount = 0;       
        userSpinInfo[msg.sender] = userInfo;
    }

    function claimRoshamboWin() external nonReentrant {
        UserPlayedInfo memory userInfo = userRoshamboInfo[msg.sender];

        require(
            userInfo.returningAmount > 0,
            "MoonixPlay: You don't have claimable tokens!"
        );        
        
        IERC20(tokenAddress).safeTransfer(msg.sender, userInfo.returningAmount);

        userInfo.returningAmount = 0;       
        userRoshamboInfo[msg.sender] = userInfo;
    }

    function diceRandom() private view returns (uint) {       	        
        uint rnd = 0;        
        rnd = uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, randDiceNonce))) % 6;                
        // rnd = rnd / 43;
        // uint256 blockValue = uint256(blockhash(block.number-1 +    block.timestamp));
        // blockValue = blockValue + uint256(randDiceNonce);
        // rnd = uint(blockValue % 6);
        return rnd + 1;
    }

    function coinFlipRandom() private view returns (uint) {       	        
        uint rnd = 0;        
        rnd = uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, randCoinFlipNonce))) % 2;
        // rnd = rnd / 128;
        // uint256 blockValue = uint256(blockhash(block.number-1 +    block.timestamp));
        // blockValue = blockValue + uint256(randCoinFlipNonce);
        // rnd = uint(blockValue % 2);
        return rnd + 1;
    }

    function spinRandom() private view returns (uint) {       	        
        uint rnd = 0;        
        rnd = uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, randSpinNonce))) % 4;
        // rnd = rnd / 64;
        // uint256 blockValue = uint256(blockhash(block.number-1 +    block.timestamp));
        // blockValue = blockValue + uint256(randSpinNonce);
        // rnd = uint(blockValue % 4);
        return rnd + 1;
    }

    function roshamboRandom() private view returns (uint) {       	        
        uint rnd = 0;        
        rnd = uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, randRoshamboNonce))) % 3;
        // rnd = rnd / 86;
        // uint256 blockValue = uint256(blockhash(block.number-1 +    block.timestamp));
        // blockValue = blockValue + uint256(randRoshamboNonce);
        // rnd = uint(blockValue % 3);
        return rnd + 1;
    }

    function updatePlayedInfo(uint256 paidOut, uint256 burnt) private {
        playInfo.burnt += burnt;
        playInfo.timesPlayed += 1;
        playInfo.paidOut += paidOut;
    }

    function updateDiceInfo(uint256 paidOut, uint256 burnt) private {
        diceInfo.burnt += burnt;
        diceInfo.timesPlayed += 1;
        diceInfo.paidOut += paidOut;
        updatePlayedInfo(paidOut, burnt);
    }

    function updateCoinFlipInfo(uint256 paidOut, uint256 burnt) private {
        coinFlipInfo.burnt += burnt;
        coinFlipInfo.timesPlayed += 1;
        coinFlipInfo.paidOut += paidOut;
        updatePlayedInfo(paidOut, burnt);
    }

    function updateSpinInfo(uint256 paidOut, uint256 burnt) private {
        spinInfo.burnt += burnt;
        spinInfo.timesPlayed += 1;
        spinInfo.paidOut += paidOut;
        updatePlayedInfo(paidOut, burnt);
    }

    function updateRoshamboInfo(uint256 paidOut, uint256 burnt) private {
        roshamboInfo.burnt += burnt;
        roshamboInfo.timesPlayed += 1;
        roshamboInfo.paidOut += paidOut;
        updatePlayedInfo(paidOut, burnt);
    }

    function setDicePlayable(bool _playable) external onlyOwner {
        dicePlayable = _playable;
    }

    function setCoinFlipPlayable(bool _playable) external onlyOwner {
        coinFlipPlayable = _playable;
    }

    function setSpinPlayable(bool _playable) external onlyOwner {
        spinPlayable = _playable;
    }

    function setRoshamboPlayable(bool _playable) external onlyOwner {
        roshamboPlayable = _playable;
    }

    function withdrawToken(address _recipient)
        public
        onlyOwner
    {
        IERC20 token = IERC20(tokenAddress);
        uint256 tokenBalance = token.balanceOf(address(this));
        token.safeTransfer(_recipient, tokenBalance);
    }

    function setBetsAcceptedToken(address _tokenAddress)
        external
        onlyOwner
    {
        tokenAddress = _tokenAddress;
    }

    function setDiceReturnsPercentage(uint256 _returnsPercentage)
        external
        onlyOwner
    {

        diceReturnsPercentage = _returnsPercentage;
    }

    function setDiceBurnOnLossPercentage(uint256 _burnPercentage)
        external
        onlyOwner
    {

        diceBurnOnLossPercentage = _burnPercentage;
    }

    function setCoinFlipReturnsPercentage(uint256 _returnsPercentage)
        external
        onlyOwner
    {

        coinFlipReturnsPercentage = _returnsPercentage;
    }

    function setCoinFlipBurnOnLossPercentage(uint256 _burnPercentage)
        external
        onlyOwner
    {

        coinFlipBurnOnLossPercentage = _burnPercentage;
    }

    function setSpinReturnsPercentage(uint256 _returnsPercentage)
        external
        onlyOwner
    {

        spinReturnsPercentage = _returnsPercentage;
    }

    function setSpinBurnOnLossPercentage(uint256 _burnPercentage)
        external
        onlyOwner
    {

        spinBurnOnLossPercentage = _burnPercentage;
    }

    function setRoshamboReturnsPercentage(uint256 _returnsPercentage)
        external
        onlyOwner
    {

        roshamboReturnsPercentage = _returnsPercentage;
    }

    function setRoshamboBurnOnLossPercentage(uint256 _burnPercentage)
        external
        onlyOwner
    {

        roshamboBurnOnLossPercentage = _burnPercentage;
    }

    function getDiceTimesPlayed() public view returns (uint256) {
        return diceInfo.timesPlayed;
    }

    function getDicePaidOut() public view returns (uint256) {
        return diceInfo.paidOut;
    }

    function getDiceBurnt() public view returns (uint256) {
        return diceInfo.burnt;
    }

    function getCoinFlipTimesPlayed() public view returns (uint256) {
        return coinFlipInfo.timesPlayed;
    }

    function getCoinFlipPaidOut() public view returns (uint256) {
        return coinFlipInfo.paidOut;
    }

    function getCoinFlipBurnt() public view returns (uint256) {
        return coinFlipInfo.burnt;
    }

    function getSpinTimesPlayed() public view returns (uint256) {
        return spinInfo.timesPlayed;
    }

    function getSpinPaidOut() public view returns (uint256) {
        return spinInfo.paidOut;
    }

    function getSpinBurnt() public view returns (uint256) {
        return spinInfo.burnt;
    }

    function getRoshamboTimesPlayed() public view returns (uint256) {
        return roshamboInfo.timesPlayed;
    }

    function getRoshamboPaidOut() public view returns (uint256) {
        return roshamboInfo.paidOut;
    }

    function getRoshamboBurnt() public view returns (uint256) {
        return roshamboInfo.burnt;
    }

    function getTotalTimesPlayed() public view returns (uint256) {
        return playInfo.timesPlayed;
    }

    function getTotalPaidOut() public view returns (uint256) {
        return playInfo.paidOut;
    }

    function getTotalBurnt() public view returns (uint256) {
        return playInfo.burnt;
    }

    // amount must be in wei    
    function setMinimumBet(uint256 amount) 
        external
        onlyOwner
    {        
        minBetAmount = amount;
    }

    // amount must be in wei    
    function setMaximumBet(uint256 amount) 
        external
        onlyOwner
    {        
        maxBetAmount = amount;
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

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
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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