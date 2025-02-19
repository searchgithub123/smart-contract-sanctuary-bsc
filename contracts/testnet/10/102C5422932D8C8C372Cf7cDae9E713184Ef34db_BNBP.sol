// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import './interfaces/IPancakeFactory.sol';
import './interfaces/IPotContract.sol';

contract BNBP is ERC20, Ownable {
    using SafeMath for uint256;

    // FIXME: This is for bnb test Network, change to Mainnet before launch
    address public constant wbnbAddr = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
    address public constant pancakeswapV2FactoryAddr = 0x6725F303b657a9451d8BA641348b6761A6CC7a17;

    address public potContractAddr;
    address[] public tokenHolders;
    mapping(address => bool) public isTokenHolder;

    // Tokenomics Variable
    uint256 public lastAirdropTime;
    uint256 public lastBurnTime;
    uint256 public lastLotteryTime;

    // Airdrop Context - all the variables respresent state at the moment of airdrop
    uint256 public totalAirdropAmount;
    uint256 public currentAirdropUserIndex;
    uint256 public totalAirdropUserCount;
    uint256 public totalTokenStaking;
    uint256 public currentAirdropMinimum;
    bool public isAirdropping;

    uint256 public stakingMinimum;
    uint256 public minimumStakingTime;

    //Staking Context
    Staking[] public stakingList;
    mapping(address => uint256) public userStakingAmount;
    mapping(address => uint256) public userStakingCount;

    struct Staking {
        address user;
        uint256 balance;
        uint256 timestamp;
    }

    struct StakingWithId {
        address user;
        uint256 id;
        uint256 balance;
        uint256 timestamp;
    }

    error AirdropTimeError();

    event StakedBNBP(uint256 stakingId, address user, uint256 amount);
    event UnStakedBNBP(uint256 stakingId, address user);

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _mint(msg.sender, 100000 * 10**18);

        lastAirdropTime = block.timestamp;
        lastBurnTime = block.timestamp;
        lastLotteryTime = block.timestamp;

        stakingMinimum = 5 * 10**18; // 5 BNBP
        minimumStakingTime = 1 * 1 * 3600;

        isAirdropping = false;
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        _checkStaking(from, amount);
        _addToTokenHolders(to);
    }

    modifier validPotLottery() {
        require(potContractAddr != address(0), 'PotLottery Contract Address is not valid');
        _;
    }

    /**
     * @dev check if the given address is valid user - not one of owner,
     * liquidity pool, or PotLottery contract
     *
     * @param addr address to be checked
     */
    function isUserAddress(address addr) public view returns (bool) {
        address pairAddr = calculatePairAddress();

        if (addr != owner() && addr != potContractAddr && addr != pairAddr && addr != address(0)) {
            return true;
        }
        return false;
    }

    /**
     * @dev add address {to} to token holder list
     *
     * @param to token receiver - this should be user address
     */
    function _addToTokenHolders(address to) internal {
        if (isUserAddress(to) && !isTokenHolder[to]) {
            isTokenHolder[to] = true;
            tokenHolders.push(to);
        }
    }

    /**
     * @dev Check balance if transfer doesn't occupy staking pool
     */
    function _checkStaking(address from, uint256 amount) internal view {
        if (userStakingAmount[from] > 0) {
            require(userStakingAmount[from] + amount <= balanceOf(from), 'Cannot occupy staking pool');
        }
    }

    /**
     * @dev get uniswap pair address between BNBP and BNB
     */
    function calculatePairAddress() public view returns (address) {
        IPancakeFactory pancakeFactory = IPancakeFactory(pancakeswapV2FactoryAddr);
        address realPair = pancakeFactory.getPair(address(this), wbnbAddr);
        return realPair;
    }

    /**
     * @dev returns total balance of users
     */
    function totalUserBalance() public view returns (uint256) {
        address pairAddr = calculatePairAddress();
        uint256 tokenAmount = balanceOf(owner()) + balanceOf(potContractAddr) + balanceOf(pairAddr);
        uint256 totalBalance = totalSupply() - tokenAmount;

        return totalBalance;
    }

    /**
     * @dev airdrops BNBP to token holders depending on the amount of holding
     * tokens in their wallet
     *
     * @return airdropped amount
     *
     * NOTE: The caller of this fuction will pay the airdrop fees, so it is
     * recommended to be called by PotLottery Contract
     */
    function performAirdrop() external validPotLottery returns (uint256) {
        IPotLottery potLottery = IPotLottery(potContractAddr);
        uint256 airdropInterval = potLottery.airdropInterval();
        uint256 nextAirdropTime = lastAirdropTime + airdropInterval;

        require(nextAirdropTime <= block.timestamp || isAirdropping, "Can't airdrop yet. Should wait more");
        require(balanceOf(potContractAddr) > 0, 'No Balance for Airdrop');

        if (!isAirdropping) {
            uint256 airdropPool = potLottery.airdropPool();
            require(airdropPool > 0, 'Airdrop Pool Empty');

            if (getTotalStakingAmount() == 0) {
                _burn(msg.sender, airdropPool);
            }
            // Start a new airdrop
            currentAirdropMinimum = stakingMinimum;
            totalTokenStaking = getTotalStakingAmount();
            lastAirdropTime = block.timestamp;
            totalAirdropAmount = airdropPool;
            totalAirdropUserCount = tokenHolders.length;
            currentAirdropUserIndex = 0;
            isAirdropping = true;
        }
        return _continueAirdrop();
    }

    /**
     * @dev continue the previous airdrop
     *
     * @return airdropped amount
     */
    function _continueAirdrop() internal returns (uint256 airdropped) {
        uint256 i = currentAirdropUserIndex;
        for (uint8 count = 0; count < 150 && i < totalAirdropUserCount; i++) {
            address user = tokenHolders[i];
            uint256 balance = userStakingAmount[user];

            if (balance > 0) {
                uint256 amount = (balance * totalAirdropAmount) / totalTokenStaking;

                transfer(user, amount);
                airdropped += amount;
                count++;
            }
        }

        currentAirdropUserIndex = i;
        if (currentAirdropUserIndex >= totalAirdropUserCount) {
            isAirdropping = false;
        }
    }

    /**
     * @dev burns BNBP token accumulated in the burn pool on the PotLottery
     * Contract
     *
     * @return burnt amount
     *
     * NOTE: The caller of this fuction will burn his BNBP tokens, so it is
     * recommended to be called by PotLottery Contract
     */
    function performBurn() external validPotLottery returns (uint256) {
        IPotLottery potLottery = IPotLottery(potContractAddr);
        uint256 burnPool = potLottery.burnPool();
        uint256 burnInterval = potLottery.burnInterval();
        uint256 nextBurnTime = lastBurnTime + burnInterval;

        require(nextBurnTime <= block.timestamp, "Can't burn yet. Should wait more");
        require(balanceOf(potContractAddr) > 0, 'No Balance for burn');

        _burn(msg.sender, burnPool);

        lastBurnTime = block.timestamp;
        return burnPool;
    }

    /**
     * @dev gives BNBP token accumulated in the lottery pool to the selected
     * winnner
     *
     * @return given lottery amount
     *
     * NOTE: The caller of this fuction will pay the lottery fee, so it is
     * recommended to be called by PotLottery Contract
     */
    function performLottery() external validPotLottery returns (address) {
        IPotLottery potLottery = IPotLottery(potContractAddr);
        uint256 lotteryPool = potLottery.lotteryPool();
        uint256 lotteryInterval = potLottery.lotteryInterval();
        uint256 nextLotteryTime = lastLotteryTime + lotteryInterval;

        require(nextLotteryTime <= block.timestamp, "Can't lottery yet. Should wait more");
        require(balanceOf(potContractAddr) > 0, 'No Balance for Lottery');

        address winner = _determineLotteryWinner();
        transfer(winner, lotteryPool);

        return winner;
    }

    /**
     * @dev generates a random number
     */
    function getRandomNumber() public view returns (uint256) {
        return uint256(uint128(bytes16(keccak256(abi.encodePacked(block.difficulty, block.timestamp)))));
    }

    /**
     * @dev gets the winner for the lottery
     *
     */
    function _determineLotteryWinner() internal view returns (address) {
        uint256 randomNumber = getRandomNumber();
        uint256 winnerValue = randomNumber % getTotalStakingAmount();
        uint256 length = tokenHolders.length;
        address winner;

        for (uint256 i = 0; i < length; i++) {
            uint256 balance = userStakingAmount[tokenHolders[i]];

            if (winnerValue <= balance) {
                winner = tokenHolders[i];
                break;
            }

            winnerValue -= balance;
        }
        return winner;
    }

    /**
     * @dev gets the total staking BNBP balance
     */
    function getTotalStakingAmount() public view returns (uint256) {
        uint256 total;
        uint256 length = stakingList.length;

        for (uint256 i = 0; i < length; i++) {
            total += stakingList[i].balance;
        }

        return total;
    }

    /**
     * @dev stakes given value of BNBP from user address, this is for
     * being eligible to get airdrop and lottery
     */
    function stakeBNBP(uint256 value) external validPotLottery returns (uint256) {
        uint256 lockMinimum = stakingMinimum;
        uint256 currentLockedAmount = userStakingAmount[msg.sender];
        uint256 userBalance = balanceOf(msg.sender);

        require(value >= lockMinimum, 'Should be bigger than minimum amount.');
        require(userBalance >= currentLockedAmount + value, 'Not enough balance');

        stakingList.push(Staking(msg.sender, value, block.timestamp));
        userStakingAmount[msg.sender] = currentLockedAmount + value;
        userStakingCount[msg.sender]++;

        uint256 stakingId = stakingList.length - 1;
        emit StakedBNBP(stakingId, msg.sender, value);
        return stakingId;
    }

    /**
     * @dev unstakes BNBP if possible
     */
    function unStakeBNBP(uint256 stakingIndex) external validPotLottery {
        Staking storage staking = stakingList[stakingIndex];
        uint256 unStakeTime = staking.timestamp + minimumStakingTime;

        require(staking.user == msg.sender, 'User Address not correct');
        require(unStakeTime <= block.timestamp, 'Not available to unstake');
        require(staking.balance > 0, 'Already Unstaked');

        userStakingAmount[msg.sender] -= staking.balance;
        userStakingCount[msg.sender]--;
        staking.balance = 0;

        emit UnStakedBNBP(stakingIndex, msg.sender);
    }

    /**
     * @dev returns staking list of user
     */
    function getUserStakingInfo(address user) public view returns (StakingWithId[] memory) {
        uint256 count = userStakingCount[user];
        uint256 sIndex;
        StakingWithId[] memory res;

        if (count == 0) {
            return res;
        }
        res = new StakingWithId[](userStakingCount[user]);

        for (uint256 i = 0; i < stakingList.length; i++) {
            Staking storage staking = stakingList[i];

            if (staking.user == user && staking.balance > 0) {
                res[sIndex++] = StakingWithId(user, i, staking.balance, staking.timestamp);
            }
        }
        return res;
    }

    /**
     * @dev Sets minimum BNBP value to get airdrop and lottery
     *
     */
    function setStakingMinimum(uint256 value) external onlyOwner {
        stakingMinimum = value;
    }

    /**
     * @dev Sets minimum BNBP value to get airdrop and lottery
     *
     */
    function setMinimumStakingTime(uint256 value) external onlyOwner {
        minimumStakingTime = value;
    }

    /**
     * @dev sets the PotLottery Contract address
     *
     */
    function setPotContractAddress(address addr) external onlyOwner {
        potContractAddr = addr;
    }

    function bulkTransfer(address[] calldata accounts, uint256[] calldata amounts) external {
        for (uint256 i = 0; i < accounts.length; i++) {
            transfer(accounts[i], amounts[i]);
        }
    }
}

/**
 *Submitted for verification at Etherscan.io on 2022-04-18
 */

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

// File: PotContract.sol

interface IPotLottery {
    struct Token {
        address tokenAddress;
        string tokenSymbol;
        uint256 tokenDecimal;
    }

    enum POT_STATE {
        PAUSED,
        WAITING,
        STARTED,
        LIVE,
        CALCULATING_WINNER
    }

    event EnteredPot(
        string tokenName,
        address indexed userAddress,
        uint256 indexed potRound,
        uint256 usdValue,
        uint256 amount,
        uint256 indexed enteryCount,
        bool hasEntryInCurrentPot
    );
    event CalculateWinner(
        address indexed winner,
        uint256 indexed potRound,
        uint256 potValue,
        uint256 amount,
        uint256 amountWon,
        uint256 participants
    );

    event PotStateChange(uint256 indexed potRound, POT_STATE indexed potState, uint256 indexed time);
    event TokenSwapFailed(string tokenName);

    function getRefund() external;

    function airdropPool() external view returns (uint256);

    function lotteryPool() external view returns (uint256);

    function burnPool() external view returns (uint256);

    function airdropInterval() external view returns (uint256);

    function burnInterval() external view returns (uint256);

    function lotteryInterval() external view returns (uint256);

    function stakingMinimum() external view returns (uint256);

    function minimumStakingTime() external view returns (uint256);

    function fullFillRandomness() external view returns (uint256);

    function getBNBPrice() external view returns (uint256 price);

    function swapAccumulatedFees() external;

    function burnAccumulatedBNBP() external;

    function airdropAccumulatedBNBP() external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.16;


interface IPancakeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

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