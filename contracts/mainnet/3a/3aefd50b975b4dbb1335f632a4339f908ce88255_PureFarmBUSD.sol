/**
 *Submitted for verification at BscScan.com on 2022-09-08
*/

// SPDX-License-Identifier: UNLICENSED

/*
██████╗░██╗░░░██╗██████╗░███████╗███████╗░█████╗░██████╗░███╗░░░███╗  ██████╗░██╗░░░██╗░██████╗██████╗░
██╔══██╗██║░░░██║██╔══██╗██╔════╝██╔════╝██╔══██╗██╔══██╗████╗░████║  ██╔══██╗██║░░░██║██╔════╝██╔══██╗
██████╔╝██║░░░██║██████╔╝█████╗░░█████╗░░███████║██████╔╝██╔████╔██║  ██████╦╝██║░░░██║╚█████╗░██║░░██║
██╔═══╝░██║░░░██║██╔══██╗██╔══╝░░██╔══╝░░██╔══██║██╔══██╗██║╚██╔╝██║  ██╔══██╗██║░░░██║░╚═══██╗██║░░██║
██║░░░░░╚██████╔╝██║░░██║███████╗██║░░░░░██║░░██║██║░░██║██║░╚═╝░██║  ██████╦╝╚██████╔╝██████╔╝██████╔╝
╚═╝░░░░░░╚═════╝░╚═╝░░╚═╝╚══════╝╚═╝░░░░░╚═╝░░╚═╝╚═╝░░╚═╝╚═╝░░░░░╚═╝  ╚═════╝░░╚═════╝░╚═════╝░╚═════╝░

Website: https://busd.purefarm.app/
Telegram: https://t.me/PureMiner

| CHANGES |
- The fee when compounding was removed.
*/

pragma solidity 0.8.14;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}

abstract contract ReentrancyGuard {
    bool internal locked;

    modifier noReentrant() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }
}

contract PureFarmBUSD is Context, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    uint256 public constant min = 10 ether;
    uint256 public constant max = 10000 ether;
    uint256 public constant deposit_fee = 5;
    uint256 public constant withdraw_fee = 5;
    uint256 public constant ref_fee = 15;
    uint256 public constant roi_limit = 100;
    uint256 public withdraw_penalty = 10;
    uint256 public compound_penalty = 1;
    uint256 public withdraw_limit = 2;
    address public fee = 0xfD593572F41721c02942DfaA94e04De914BF029a;
    IERC20 private BusdInterface;
    address public tokenAdress;
    bool public init = false;
    bool public alreadyInvested = false;

    constructor() {
        tokenAdress = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
        BusdInterface = IERC20(tokenAdress);
    }

    struct referral_system {
        address ref_address;
        uint256 reward;
    }

    struct referral_withdraw {
        address ref_address;
        uint256 totalWithdraw;
    }

    struct user_investment_details {
        address user_address;
        uint256 invested;
    }

    struct claimDaily {
        address user_address;
        uint256 startTime;
        uint256 deadline;
    }

    struct userTotalWithdraw {
        address user_address;
        uint256 amount;
    }

    mapping(address => uint256) public roi;
    mapping(address => referral_system) public referral;
    mapping(address => user_investment_details) public investments;
    mapping(address => claimDaily) public claimTime;
    mapping(address => userTotalWithdraw) public totalWithdraw;
    mapping(address => referral_withdraw) public refTotalWithdraw;

    function deposit(address _ref, uint256 _amount) public noReentrant {
        require(init, "Not Started Yet");
        require(_amount >= min && _amount <= max, "Cannot Deposit");

        if (!checkAlready()) {
            uint256 ref_fee_add = refFee(_amount);
            roi[msg.sender] = roi_limit;
        if(_ref != address(0) && _ref != msg.sender) {
         uint256 ref_last_balance = referral[_ref].reward;
         uint256 totalRefFee = SafeMath.add(ref_fee_add, ref_last_balance);   
         referral[_ref] = referral_system(_ref, totalRefFee);
        }
        else {
            uint256 ref_last_balance = referral[fee].reward;
            uint256 totalRefFee = SafeMath.add(ref_fee_add, ref_last_balance);  
            referral[fee] = referral_system(fee, totalRefFee);
        }

            uint256 userLastInvestment = investments[msg.sender].invested;
            uint256 userCurrentInvestment = _amount;
            uint256 totalInvestment = SafeMath.add(
                userLastInvestment,
                userCurrentInvestment
            );
            investments[msg.sender] = user_investment_details(
                msg.sender,
                totalInvestment
            );

            uint256 claimTimeStart = block.timestamp;
            uint256 claimTimeEnd = block.timestamp + 1 days;

            claimTime[msg.sender] = claimDaily(
                msg.sender,
                claimTimeStart,
                claimTimeEnd
            );

            uint256 total_fee = depositFee(_amount);
            uint256 total_contract = SafeMath.sub(_amount, total_fee);
            BusdInterface.transferFrom(msg.sender, fee, total_fee);
            BusdInterface.transferFrom(
                msg.sender,
                address(this),
                total_contract
            );
        } else {
            uint256 ref_fee_add = refFee(_amount);

            if (_ref != address(0) && _ref != msg.sender) {
                uint256 ref_last_balance = referral[_ref].reward;
                uint256 totalRefFee = SafeMath.add(
                    ref_fee_add,
                    ref_last_balance
                );
                referral[_ref] = referral_system(_ref, totalRefFee);
            } else {
                uint256 ref_last_balance = referral[fee].reward;
                uint256 totalRefFee = SafeMath.add(
                    ref_fee_add,
                    ref_last_balance
                );
                referral[fee] = referral_system(
                    fee,
                    totalRefFee
                );
            }

            uint256 userLastInvestment = investments[msg.sender].invested;
            uint256 userCurrentInvestment = _amount;
            uint256 totalInvestment = SafeMath.add(
                userLastInvestment,
                userCurrentInvestment
            );
            investments[msg.sender] = user_investment_details(
                msg.sender,
                totalInvestment
            );

            uint256 total_fee = depositFee(_amount);
            uint256 total_contract = SafeMath.sub(_amount, total_fee);
            BusdInterface.transferFrom(msg.sender, fee, total_fee);
            BusdInterface.transferFrom(
                msg.sender,
                address(this),
                total_contract
            );
        }
    }

    function compound() public noReentrant {
        require(init, "Not Started Yet");
        uint256 rewards = userReward(msg.sender);
        require(rewards > 0, "Rewards amount is zero");
        if (
            rewards >= getDailyRoi(investments[msg.sender].invested, msg.sender)
        ) {
            roi[msg.sender] = SafeMath.add(roi[msg.sender], compound_penalty);
            if (roi[msg.sender] >= roi_limit) {
                withdraw_penalty = 10;
                roi[msg.sender] = roi_limit;
            }
        }
        uint256 claimTimeStart = block.timestamp;
        uint256 claimTimeEnd = block.timestamp + 1 days;

        claimTime[msg.sender] = claimDaily(
            msg.sender,
            claimTimeStart,
            claimTimeEnd
        );
        uint256 userLastInvestment = investments[msg.sender].invested;
        uint256 userCurrentInvestment = rewards;
        uint256 totalInvestment = SafeMath.add(
            userLastInvestment,
            userCurrentInvestment
        );
        investments[msg.sender] = user_investment_details(
            msg.sender,
            totalInvestment
        );
    }

    function withdrawal() public noReentrant {
        require(init, "Not Started Yet");
        require(
            totalWithdraw[msg.sender].amount <
                SafeMath.mul(investments[msg.sender].invested, withdraw_limit),
            "Exceed withdral amount"
        );
        uint256 rewards = userReward(msg.sender);

        uint256 claimTimeStart = block.timestamp;
        uint256 claimTimeEnd = block.timestamp + 1 days;

        claimTime[msg.sender] = claimDaily(
            msg.sender,
            claimTimeStart,
            claimTimeEnd
        );

        roi[msg.sender] = SafeMath.sub(roi[msg.sender], withdraw_penalty);

        if (roi[msg.sender] < 0) roi[msg.sender] = 0;
        withdraw_penalty = SafeMath.mul(withdraw_penalty, 2);
        uint256 wFee = withdrawFee(rewards);
        uint256 totalAmountToWithdraw = SafeMath.sub(rewards, wFee);
        uint256 amount = totalWithdraw[msg.sender].amount;
        uint256 totalAmount = SafeMath.add(amount, totalAmountToWithdraw);
        uint256 limitAmount = SafeMath.mul(
            investments[msg.sender].invested,
            withdraw_limit
        );
        if (totalAmount >= limitAmount) {
            totalAmountToWithdraw = SafeMath.sub(limitAmount, amount);
            wFee = SafeMath.div(
                SafeMath.mul(investments[msg.sender].invested, 8),
                100
            );
            investments[msg.sender] = user_investment_details(msg.sender, 0);
            BusdInterface.transfer(msg.sender, totalAmountToWithdraw);
            BusdInterface.transfer(fee, wFee);
            totalWithdraw[msg.sender] = userTotalWithdraw(
                msg.sender,
                limitAmount
            );
            totalWithdraw[msg.sender] = userTotalWithdraw(msg.sender, 0);
            roi[msg.sender] = roi_limit;
        } else {
            BusdInterface.transfer(msg.sender, totalAmountToWithdraw);
            BusdInterface.transfer(fee, wFee);
            totalWithdraw[msg.sender] = userTotalWithdraw(
                msg.sender,
                totalAmount
            );
        }
    }

    function Ref_Withdraw() external noReentrant {
        require(init, "Not Started Yet");
        uint256 value = (msg.sender==fee)?getBalance():referral[msg.sender].reward;
        BusdInterface.transfer(msg.sender, value);
        referral[msg.sender] = referral_system(msg.sender, 0);

        uint256 lastWithdraw = refTotalWithdraw[msg.sender].totalWithdraw;

        uint256 totalValue = SafeMath.add(value, lastWithdraw);

        refTotalWithdraw[msg.sender] = referral_withdraw(
            msg.sender,
            totalValue
        );
    }

    function start_signal() public onlyOwner {
        init = true;
    }

    function userReward(address _userAddress) public view returns (uint256) {
        uint256 userInvestment = investments[_userAddress].invested;
        uint256 userDailyReturn = getDailyRoi(userInvestment, _userAddress);

        uint256 claimInvestTime = claimTime[_userAddress].startTime;

        uint256 nowTime = block.timestamp;

        uint256 value = SafeMath.div(userDailyReturn, 1 days);

        uint256 earned = SafeMath.sub(nowTime, claimInvestTime);

        uint256 totalEarned = SafeMath.mul(earned, value);
        if (
            totalEarned >
            getDailyRoi(investments[_userAddress].invested, _userAddress)
        ) {
            totalEarned = getDailyRoi(
                investments[_userAddress].invested,
                _userAddress
            );
        }
        return totalEarned;
    }

    function getDailyRoi(uint256 _amount, address _user)
        public
        view
        returns (uint256)
    {
        return SafeMath.div(SafeMath.mul(_amount, roi[_user]), 1000);
    }

    function getUserRoi(address _user) public view returns (uint256) {
        if (roi[_user] == 0) {
            return roi_limit;
        } else {
            return roi[_user];
        }
    }

    function checkAlready() public view returns (bool) {
        address _address = msg.sender;
        if (investments[_address].user_address == _address) {
            return true;
        } else {
            return false;
        }
    }

    function depositFee(uint256 _amount) public pure returns (uint256) {
        return SafeMath.div(SafeMath.mul(_amount, deposit_fee), 100);
    }

    function refFee(uint256 _amount) public pure returns (uint256) {
        return SafeMath.div(SafeMath.mul(_amount, ref_fee),100);
    }

    function withdrawFee(uint256 _amount) public pure returns (uint256) {
        return SafeMath.div(SafeMath.mul(_amount, withdraw_fee), 100);
    }

    function getBalance() public view returns (uint256) {
        return BusdInterface.balanceOf(address(this));
    }
}