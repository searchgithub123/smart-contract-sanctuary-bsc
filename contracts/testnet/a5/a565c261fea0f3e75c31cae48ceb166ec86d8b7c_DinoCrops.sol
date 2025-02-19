/**
 *Submitted for verification at BscScan.com on 2022-08-19
*/

/** 
    Dino Crops.
    5% Daily Income
    5% Dev Fee Deposit/Withdraw
    5% Ref Bonus -> User should be invested to activate referral bonus.
    Withdrawals, every 7th day. 50% will be withdrawn. 50% will be compounded and added to user total investment.
    Unstake -> 50% goes back to investor 50% stays in the contract.
**/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.14;

interface IERC20 
{

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }
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
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
      address msgSender = _msgSender();
      _owner = msgSender;
      emit OwnershipTransferred(address(0), msgSender);
    }

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
    function transferOwnership(address newOwner) public onlyOwner {
      _transferOwnership(newOwner);
    }
    function _transferOwnership(address newOwner) internal {
      require(newOwner != address(0), "Ownable: new owner is the zero address");
      emit OwnershipTransferred(_owner, newOwner);
      _owner = newOwner;
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

contract DinoCrops is Context, Ownable , ReentrancyGuard {
    using SafeMath for uint256;
    uint256 public constant min = 50 ether;
    uint256 public constant max = 10000 ether;
    uint256 public roi = 5;
    uint256 public constant fee = 1; //x5
    uint256 public constant withdraw_fee = 1; //x5
    uint256 public constant ref_fee = 5;
    uint256 public withdrawDays = 2 * 60 * 60; //168 = 7 days
    uint256 public claimDays = 1 * 60 * 60; //24 = 1 day
    address private dev;
    address private dev1;
    address private partner1;
    address private partner2;
    address private partner3;
    IERC20 private BusdInterface;
    address public tokenAdress;
    bool public init = false;

    constructor(address _dev,address _dev1,address _partner1,address _partner2,address _partner3) {
        tokenAdress = 0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7; //0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56
        BusdInterface = IERC20(tokenAdress);
        dev = _dev;
        dev1 = _dev1;
        partner1 = _partner1;
        partner2 = _partner2;
        partner3 = _partner3;

    }

    struct refferal_system {
        address ref_address;
        uint256 reward;
    }

    struct refferal_withdraw {
        address ref_address;
        uint256 totalWithdraw;
    }

    struct user_investment_details {
        address user_address;
        uint256 invested;
    }

    struct weeklyWithdraw {
        address user_address;
        uint256 startTime;
        uint256 deadline;
    }

    struct claimDaily {
        address user_address;
        uint256 startTime;
        uint256 deadline;
    }

    struct userWithdrawal {
        address user_address;
        uint256 amount;
    }

    struct userTotalWithdraw {
        address user_address;
        uint256 amount;
    }
     struct userTotalRewards {
        address user_address;
        uint256 amount;
    } 

    mapping(address => refferal_system) public refferal;
    mapping(address => user_investment_details) public investments;
    mapping(address => weeklyWithdraw) public weekly;
    mapping(address => claimDaily) public claimTime;
    mapping(address => userWithdrawal) public approvedWithdrawal;
    mapping(address => userTotalWithdraw) public totalWithdraw;
    mapping(address => userTotalRewards) public totalRewards; 
    mapping(address => refferal_withdraw) public refTotalWithdraw;

    // invest function 
    function deposit(address _ref, uint256 _amount) public noReentrant  {
        require(init, "Not Started Yet");
        require(_amount >= min && _amount <= max, "Cannot Deposit");
       
        //user should be invested before they can have referrals.
        if(_ref != address(0) && _ref != msg.sender && investments[_ref].invested > 0) {
            uint256 ref_fee_add = refFee(_amount);
            uint256 ref_last_balance = refferal[_ref].reward;
            uint256 totalRefFee = SafeMath.add(ref_fee_add, ref_last_balance);   
            refferal[_ref] = refferal_system(_ref, totalRefFee);
        }

        // investment details
        uint256 userLastInvestment = investments[msg.sender].invested;
        uint256 userCurrentInvestment = _amount;
        uint256 totalInvestment = SafeMath.add(userLastInvestment, userCurrentInvestment);
        investments[msg.sender] = user_investment_details(msg.sender, totalInvestment);

        //new deposits from existing investors will reset timer.
        //weekly withdraw
        uint256 weeklyStart = block.timestamp;
        uint256 deadline_weekly = block.timestamp + withdrawDays;
        weekly[msg.sender] = weeklyWithdraw(msg.sender, weeklyStart, deadline_weekly);

        // Claim Setting
        uint256 claimTimeStart = block.timestamp;
        uint256 claimTimeEnd = block.timestamp + claimDays;
        claimTime[msg.sender] = claimDaily(msg.sender, claimTimeStart, claimTimeEnd);
        
        // fees 
        uint256 total_fee = depositFee(_amount); //1% x 5
        uint256 total_contract = SafeMath.sub(_amount,total_fee.mul(5)); //5% tax
        BusdInterface.transferFrom(msg.sender, dev, total_fee);
        BusdInterface.transferFrom(msg.sender, dev1, total_fee);
        BusdInterface.transferFrom(msg.sender, partner1, total_fee);
        BusdInterface.transferFrom(msg.sender, partner2, total_fee);
        BusdInterface.transferFrom(msg.sender, partner3, total_fee);
        BusdInterface.transferFrom(msg.sender, address(this), total_contract);
    }

    function userReward(address _userAddress) public view returns(uint256) {
        uint256 userInvestment = investments[_userAddress].invested;
        uint256 userDailyReturn = DailyRoi(userInvestment);
        uint256 claimInvestTime = claimTime[_userAddress].startTime;
        uint256 claimInvestEnd = claimTime[_userAddress].deadline;
        uint256 totalTime = SafeMath.sub(claimInvestEnd, claimInvestTime);
        uint256 value = SafeMath.div(userDailyReturn, totalTime);
        uint256 nowTime = block.timestamp;

        if(claimInvestEnd >= nowTime) {
            uint256 earned = SafeMath.sub(nowTime, claimInvestTime);
            uint256 totalEarned = SafeMath.mul(earned, value);
            return totalEarned;
        }
        else {
            return userDailyReturn;
        }
    }

    function withdrawal() public noReentrant {
        require(init, "Not Started Yet");    
        require(weekly[msg.sender].deadline <= block.timestamp, "You cant withdraw");
        require(totalWithdraw[msg.sender].amount <= SafeMath.mul(investments[msg.sender].invested, 3), "User already has already withdrawn 3x of his investment.");
        uint256 aval_withdraw = approvedWithdrawal[msg.sender].amount;
        //if user total withdrawn + amount withdrawable is greater than x3 his investment,
        // user x3 - total withdrawn = new available amount to withdraw.
        if(totalWithdraw[msg.sender].amount.add(aval_withdraw) >= SafeMath.mul(investments[msg.sender].invested, 3)) {
            aval_withdraw = SafeMath.mul(investments[msg.sender].invested, 3).sub(totalWithdraw[msg.sender].amount);
        }
        uint256 aval_withdraw2 = SafeMath.div(aval_withdraw, 2); //divide current withdrawable.
        uint256 wFee = withdrawFee(aval_withdraw2); //changed from aval_withdraw
        uint256 totalAmountToWithdraw = SafeMath.sub(aval_withdraw2,wFee.mul(5)); //5% tax
        BusdInterface.transfer(msg.sender, totalAmountToWithdraw); //50% will be available to withdraw with tax.
        BusdInterface.transfer(dev, wFee);
        BusdInterface.transfer(dev1, wFee);
        BusdInterface.transfer(partner1, wFee);
        BusdInterface.transfer(partner2, wFee);
        BusdInterface.transfer(partner3, wFee); 
        //changed from 0 since 50% will be auto reinvested. aval_withdraw2
        approvedWithdrawal[msg.sender] = userWithdrawal(msg.sender,0);
        
        //50% goes to investor as added investment with no tax.
        uint256 userLastInvestment = investments[msg.sender].invested;
        uint256 userCurrentInvestment = aval_withdraw2;
        uint256 totalInvestment = SafeMath.add(userLastInvestment, userCurrentInvestment);
        investments[msg.sender] = user_investment_details(msg.sender, totalInvestment);

        uint256 weeklyStart = block.timestamp;
        uint256 deadline_weekly = block.timestamp + withdrawDays;

        weekly[msg.sender] = weeklyWithdraw(msg.sender, weeklyStart, deadline_weekly);

        uint256 amount = totalWithdraw[msg.sender].amount;
        // it will add one of his half to total withdraw
        uint256 totalAmount = SafeMath.add(amount, aval_withdraw2);
        //total amount withdrawn by the user.
        totalWithdraw[msg.sender] = userTotalWithdraw(msg.sender, totalAmount);
    }

    function claimDailyRewards() public noReentrant{
        require(init, "Not Started Yet");
        require(claimTime[msg.sender].deadline <= block.timestamp, "You cant claim.");

        uint256 rewards = userReward(msg.sender);

        uint256 currentApproved = approvedWithdrawal[msg.sender].amount;

        uint256 value = SafeMath.add(rewards,currentApproved);

        approvedWithdrawal[msg.sender] = userWithdrawal(msg.sender, value);
        uint256 amount = totalRewards[msg.sender].amount;
        uint256 totalRewardAmount = SafeMath.add(amount, rewards);
        totalRewards[msg.sender].amount = totalRewardAmount;

        uint256 claimTimeStart = block.timestamp;
        uint256 claimTimeEnd = block.timestamp + claimDays;

        claimTime[msg.sender] = claimDaily(msg.sender, claimTimeStart, claimTimeEnd);  

    }

    function unStake() external noReentrant {
        require(init, "Not Started Yet");
        uint256 I_investment = investments[msg.sender].invested;
        uint256 t_withdraw = totalWithdraw[msg.sender].amount;
        require(I_investment > t_withdraw, "You already withdraw a lot than your investment");
        uint256 lastFee = depositFee(I_investment);
        uint256 currentBalance = SafeMath.sub(I_investment, lastFee);
        uint256 UnstakeValue = SafeMath.sub(currentBalance, t_withdraw);
        uint256 UnstakeValueCore = SafeMath.div(UnstakeValue, 2);
        investments[msg.sender] = user_investment_details(msg.sender, 0);
        approvedWithdrawal[msg.sender] = userWithdrawal(msg.sender, 0);
        BusdInterface.transfer(msg.sender, UnstakeValueCore); //50% will be available for unstake 50% goes back to the contract.
    }

    function Ref_Withdraw() external noReentrant {
        require(init, "Not Started Yet");
        uint256 value = refferal[msg.sender].reward;
        refferal[msg.sender] = refferal_system(msg.sender, 0);
        uint256 lastWithdraw = refTotalWithdraw[msg.sender].totalWithdraw;
        uint256 totalValue = SafeMath.add(value, lastWithdraw);
        refTotalWithdraw[msg.sender] = refferal_withdraw(msg.sender, totalValue);
        BusdInterface.transfer(msg.sender, value);
    }

    // initialized the market
    function signal_market() public onlyOwner {
        init = true;
    }

    // other functions
    function DailyRoi(uint256 _amount) public view returns(uint256) {
        return SafeMath.div(SafeMath.mul(_amount, roi), 100);
    }

    function depositFee(uint256 _amount) public pure returns(uint256){
     return SafeMath.div(SafeMath.mul(_amount, fee), 100);
    }

    function refFee(uint256 _amount) public pure returns(uint256) {
        return SafeMath.div(SafeMath.mul(_amount, ref_fee), 100);
    }

    function withdrawFee(uint256 _amount) public pure returns(uint256) {
        return SafeMath.div(SafeMath.mul(_amount, withdraw_fee), 100);
    }

    function getBalance() public view returns(uint256){
         return BusdInterface.balanceOf(address(this));
    }

    //for testing only remove in mainnet
    function updateWithdrawDays(uint256 value) public onlyOwner {
        withdrawDays = value * 60 * 60;
    }
    //for testing only remove in mainnet
    function updateClaimDays(uint256 value) public onlyOwner {
        claimDays = value * 60 * 60;
    }
    //for testing only remove in mainnet
    function claimTestFunds() public onlyOwner {
        BusdInterface.transfer(msg.sender, BusdInterface.balanceOf(address(this)));
    }
    //for testing only remove in mainnet
    function changeDailyROI(uint256 value) public onlyOwner {
        roi = value;
    }

}