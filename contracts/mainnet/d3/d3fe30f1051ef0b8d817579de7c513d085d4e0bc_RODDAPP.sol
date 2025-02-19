/**
 *Submitted for verification at BscScan.com on 2022-02-10
*/

pragma solidity ^0.6.12;

/**
 * @title ROD DAPP
**/

//SPDX-License-Identifier: MIT

interface tokenTransfer {
    function totalSupply() external view returns (uint256);
    function balanceOf(address receiver) external returns(uint256);
    function transfer(address receiver, uint amount) external;
    function transferFrom(address _from, address _to, uint256 _value) external;
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);    
}

contract Util {
    
    uint ethWei = 1 ether;
    
    function getRecommendScaleByAmountAndTim(uint times) internal  pure returns(uint){
        if (times == 1) {
            return 60;
        }
        if (times == 2) {
            return 20;
        }
        if(times >= 3 && times <= 5){
            return 10;
        }
        if(times >= 6 && times <= 10){
            return 6;
        }
        return 0;
    }

    function compareStr(string memory _str, string memory str) internal pure returns(bool) {
        if (keccak256(abi.encodePacked(_str)) == keccak256(abi.encodePacked(str))) {
            return true;
        }
        return false;
    }
    
}

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor() internal {}
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

/**
 * @title WhitelistAdminRole
 * @dev WhitelistAdmins are responsible for assigning and removing Whitelisted accounts.
 */
contract WhitelistAdminRole is Context, Ownable {
    using Roles for Roles.Role;

    Roles.Role private _whitelistAdmins;

    constructor () internal {
        _addWhitelist(_msgSender());
    }

    modifier onlyWhitelistAdmin() {
        require(isWhitelist(_msgSender()) || isOwner(), "WhitelistAdminRole: caller does not have the WhitelistAdmin role");
        _;
    }

    function addWhitelist(address account) public onlyWhitelistAdmin {
        _addWhitelist(account);
    }

    function removeWhitelist(address account) public onlyOwner {
        _whitelistAdmins.remove(account);
    }
    
    function isWhitelist(address account) private view returns (bool) {
        return _whitelistAdmins.has(account);
    }

    function _addWhitelist(address account) internal {
        _whitelistAdmins.add(account);
    }
}

contract RODDAPP is Util, WhitelistAdminRole {

    using SafeMath for *;
    
    string constant private name = "ROD DAPP";
    
    struct User{
        uint id;
        address userAddress;
        string inviteCode;
        string referrer;
        uint staticLevel;
        uint dynamicLevel;
        uint allInvest;
        uint freezeAmount;
        uint allStaticAmount;
        uint allDynamicAmount;
        uint hisStaticAmount;
        uint hisDynamicAmount;
        uint inviteAmount;  
        uint performance;   
        uint nodeCount; 
        uint nodePerformance;   
    	Invest[] invests;
    	uint staticFlag;

        Invest[] options;
        uint optionFlag;
        uint allEurStaticAmount;
        uint hisEruStaticAmount;
        uint allEurDynamicAmount;
        uint hisEurDynamicAmount;
    }
    
    struct UserGlobal {
        uint id;
        address userAddress;
        string inviteCode;
        string referrer;
    }
    
    struct Invest{
        address userAddress;
        uint investAmount;
        uint limitAmount;
        uint earnAmount;
        uint investTime;
        uint times;
    }
    
    uint startTime;
    uint endTime;
    uint investCount;
    mapping(uint => uint) rInvestCount;
    uint investMoney;
    mapping(uint => uint) rInvestMoney;
    uint uid = 0;
    uint rid = 1;
    uint period = 1 hours;
    uint dividendRate = 30;
    uint dividendModel = 1;
    uint statisticsDay;
    mapping (uint => mapping(address => User)) userRoundMapping;
    mapping(address => UserGlobal) userMapping;
    mapping (string => address) addressMapping;
    mapping (uint => address) indexMapping;

    //==============================================================================
    tokenTransfer rodToken = tokenTransfer(0x803e07917D782f4c7eC4D668D950575aCC64108e);

    address zero = 0x000000000000000000000000000000000000dEaD;
    uint releseTime = 1650124800;
    
    modifier isHuman() {
        address addr = msg.sender;
        uint codeLength;

        assembly {codeLength := extcodesize(addr)}
        require(codeLength == 0, "sorry humans only");
        require(tx.origin == msg.sender, "sorry, human only");
        _;
    }

    event LogInvestIn(address indexed who, uint indexed uid, uint amount, uint time, string inviteCode, string referrer);
    event LogWithdrawProfit(address indexed who, uint indexed uid, uint amount, uint time);
    event LogRedeem(address indexed who, uint indexed uid, uint amount, uint time);
    event LogGameWinner(address indexed who, uint amount, uint time,string gameType);

    //==============================================================================
    // Constructor
    //==============================================================================
    constructor () public {
        startTime = now;
        endTime = startTime.add(period); 
    }

    receive() external payable{
    }

    function optionIn(string memory inviteCode,string memory referrer,uint256 value)
        public
        onlyWhitelistAdmin
    {
        UserGlobal storage userGlobal = userMapping[msg.sender];
        if (userGlobal.id == 0) {
            require(!compareStr(inviteCode, ""), "empty invite code");
            address referrerAddr = getUserAddressByCode(referrer);
            require(uint(referrerAddr) != 0, "referer not exist");
            require(referrerAddr != msg.sender, "referrer can't be self");
            require(!isUsed(inviteCode), "invite code is used");
            
            registerUser(msg.sender, inviteCode, referrer);
        }
        
        User storage user = userRoundMapping[rid][msg.sender];
	    
        uint8 isNewNode = 0;
        if (uint(user.userAddress) != 0) {
            user.allInvest = user.allInvest.add(value);
            user.freezeAmount = user.freezeAmount.add(value);
            
            if (!compareStr(userGlobal.referrer, "")) {
                address referrerAddr = getUserAddressByCode(userGlobal.referrer);
                userRoundMapping[rid][referrerAddr].performance += value;
            }
        } else {
            user.id = userGlobal.id;
            user.userAddress = msg.sender;
            user.freezeAmount = value;
            user.allInvest = value;
            user.inviteCode = userGlobal.inviteCode;
            user.referrer = userGlobal.referrer;
            
            if (!compareStr(userGlobal.referrer, "")) {
                address referrerAddr = getUserAddressByCode(userGlobal.referrer);
                userRoundMapping[rid][referrerAddr].inviteAmount++;
                userRoundMapping[rid][referrerAddr].performance += value;
                isNewNode++;
            }
        }
        
        uint limitAmount = value;
        Invest memory invest = Invest(msg.sender, value, limitAmount, 0, releseTime,0);
        user.options.push(invest);
        
        investCount = investCount.add(1);
        investMoney = investMoney.add(value);
        statisticsDay = statisticsDay.add(value);
        
        emit LogInvestIn(msg.sender, userGlobal.id, value, now, userGlobal.inviteCode, userGlobal.referrer);
    }
    
    function investIn(string memory inviteCode,string memory referrer,uint256 value) public
    {
        require(value >= 50 * ethWei, "The minimum bet is 50 ROD");
        require(value == value.div(ethWei).mul(ethWei), "invalid msg value");
        rodToken.transferFrom(msg.sender,address(this),value);
        //rodToken.transfer(zero,value);
        
        UserGlobal storage userGlobal = userMapping[msg.sender];
        if (userGlobal.id == 0) {
            require(!compareStr(inviteCode, ""), "empty invite code");
            address referrerAddr = getUserAddressByCode(referrer);
            require(uint(referrerAddr) != 0, "referer not exist");
            require(referrerAddr != msg.sender, "referrer can't be self");
            require(!isUsed(inviteCode), "invite code is used");
            
            registerUser(msg.sender, inviteCode, referrer);
        }
        
        User storage user = userRoundMapping[rid][msg.sender];
	    
        uint8 isNewNode = 0;
        if (uint(user.userAddress) != 0) {
            user.allInvest = user.allInvest.add(value);
            user.freezeAmount = user.freezeAmount.add(value);
            
            if (!compareStr(userGlobal.referrer, "")) {
                address referrerAddr = getUserAddressByCode(userGlobal.referrer);
                userRoundMapping[rid][referrerAddr].performance += value;
            }
        } else {
            user.id = userGlobal.id;
            user.userAddress = msg.sender;
            user.freezeAmount = value;
            user.allInvest = value;
            user.inviteCode = userGlobal.inviteCode;
            user.referrer = userGlobal.referrer;
            
            if (!compareStr(userGlobal.referrer, "")) {
                address referrerAddr = getUserAddressByCode(userGlobal.referrer);
                userRoundMapping[rid][referrerAddr].inviteAmount++;
                userRoundMapping[rid][referrerAddr].performance += value;
                isNewNode++;
            }
        }
        
        uint limitAmount = value.mul(2);
        Invest memory invest = Invest(msg.sender, value, limitAmount, 0, now,0);
        user.invests.push(invest);
        
        investCount = investCount.add(1);
        investMoney = investMoney.add(value);
        statisticsDay = statisticsDay.add(value);
        
        tjUserDynamicTree(isNewNode,userGlobal.referrer,value);
        
        statisticOfDay();
        
        emit LogInvestIn(msg.sender, userGlobal.id, value, now, userGlobal.inviteCode, userGlobal.referrer);
    }
    
    function statisticOfDay() private {
        bool flag = getTimeLeft() <= 0;
        if(flag){
            //update time
            startTime = endTime;
            endTime = startTime.add(period);
        }
    }
    
    function withdrawProfit() public
    {
        User storage user = userRoundMapping[rid][msg.sender];
        require(user.id > 0, "user not exist");
        
        statisticOfDay();
        useStaticAutoProfitInner(msg.sender,now);
        useEurStaticAutoProfitInner(msg.sender,now);
        
        uint resultMoney = user.allStaticAmount.add(user.allDynamicAmount).add(user.allEurStaticAmount);
        if (resultMoney > 0) {
            takeInner(msg.sender,resultMoney);
    	    
            user.allStaticAmount = 0;
            user.allDynamicAmount = 0;
            user.allEurStaticAmount = 0;
            
            emit LogWithdrawProfit(msg.sender, user.id, resultMoney, now);
        }
    }
    
    function takeInner(address payable userAddress, uint money) private {
        rodToken.transfer(userAddress,money);        
    }
    
    //用户自动静态分红
    function userStaticAutoProfitInner(address userAddr,uint _now) external onlyWhitelistAdmin returns(uint)
    {
        return useStaticAutoProfitInner(userAddr , _now);
    }

    function useStaticAutoProfitInner(address userAddr,uint _now) private returns(uint)
    {
        User storage user = userRoundMapping[rid][userAddr];
        if (user.id == 0) {
            return 0;
        }
        
        uint allStatic = 0;
        for (uint i = user.staticFlag; i < user.invests.length; i++) {
            Invest storage invest = user.invests[i];
            
            //静态根据投资时间24小时后释放
            uint staticGaps;
            if(dividendModel == 1){
                staticGaps = _now.sub(invest.investTime).div(period);
            }else{
                uint startDay = invest.investTime.div(period).mul(period);
                staticGaps = _now.sub(startDay).div(period);
            }
            if (staticGaps <= invest.times) {
                continue;
            }
            
            //未领取的天数
            uint unclaimedDays =  staticGaps - invest.times;
            //每天的收益
            uint incomeByDay = invest.limitAmount.mul(dividendRate).div(1000);
            //未领取的总收益
            uint incomeTotal = incomeByDay * unclaimedDays;
            
            allStatic = allStatic.add(incomeTotal);
            invest.earnAmount = invest.earnAmount.add(incomeTotal);
            invest.times = staticGaps;
            
            //出局判断
            if (invest.earnAmount >= invest.limitAmount) {
                user.staticFlag = user.staticFlag.add(1);
                user.freezeAmount = user.freezeAmount.sub(invest.investAmount);
                user.staticLevel = user.staticLevel.add(1);
                
                //修正收益
                uint correction = invest.earnAmount.sub(invest.limitAmount);
                if(correction > 0){
                    allStatic = allStatic.sub(correction);
                    invest.earnAmount = invest.limitAmount;
                }
            }
        }
        
        user.allStaticAmount = user.allStaticAmount.add(allStatic);
        user.hisStaticAmount = user.hisStaticAmount.add(allStatic);
        return user.allStaticAmount;
    }
    
    function unbalancedStaticProfit(address userAddr) public view returns(uint)
    {
         User storage user = userRoundMapping[rid][userAddr];
        if (user.id == 0) {
            return 0;
        }
        
        uint allStatic = 0;
        uint _now = now;
        for (uint i = user.staticFlag; i < user.invests.length; i++) {
            Invest memory invest = user.invests[i];
            
            //静态根据投资时间24小时后释放
            uint staticGaps;
            if(dividendModel == 1){
                staticGaps = _now.sub(invest.limitAmount).div(period);
            }else{
                uint startDay = invest.limitAmount.div(period).mul(period);
                staticGaps = _now.sub(startDay).div(period);
            }
            if (staticGaps <= invest.times) {
                continue;
            }
            
            //未领取的天数
            uint unclaimedDays =  staticGaps - invest.times;
            //每天的收益
            uint incomeByDay = invest.limitAmount.mul(dividendRate).div(1000);
            //未领取的总收益
            uint incomeTotal = incomeByDay * unclaimedDays;
            
            allStatic = allStatic.add(incomeTotal);
            uint earnAmount = invest.earnAmount.add(incomeTotal);
            
            //出局判断
            if (earnAmount >= invest.limitAmount) {
                //修正收益
                uint correction = earnAmount.sub(invest.limitAmount);
                if(correction > 0){
                    allStatic = allStatic.sub(correction);
                }
            }
        }
        return allStatic;
    }

    function useEurStaticAutoProfitInner(address userAddr,uint _now) private returns(uint)
    {
        User storage user = userRoundMapping[rid][userAddr];
        if (user.id == 0) {
            return 0;
        }
        
        uint dynDividendRate = 10;
        uint allStatic = 0;
        for (uint i = user.optionFlag; i < user.options.length; i++) {
            Invest storage invest = user.options[i];
            
            //静态根据投资时间24小时后释放
            uint staticGaps;
            if(dividendModel == 1){
                staticGaps = _now.sub(invest.investTime).div(period);
            }else{
                uint startDay = invest.investTime.div(period).mul(period);
                staticGaps = _now.sub(startDay).div(period);
            }
            if (staticGaps <= invest.times) {
                continue;
            }
            
            //未领取的天数
            uint unclaimedDays =  staticGaps - invest.times;
            //每天的收益
            uint incomeByDay = invest.investAmount.mul(dynDividendRate).div(1000);
            //未领取的总收益
            uint incomeTotal = incomeByDay * unclaimedDays;
            
            allStatic = allStatic.add(incomeTotal);
            invest.earnAmount = invest.earnAmount.add(incomeTotal);
            invest.times = staticGaps;
            
            //出局判断
            if (invest.earnAmount >= invest.limitAmount) {
                user.optionFlag = user.optionFlag.add(1);
                
                //修正收益
                uint correction = invest.earnAmount.sub(invest.limitAmount);
                if(correction > 0){
                    allStatic = allStatic.sub(correction);
                    invest.earnAmount = invest.limitAmount;
                }
            }
        }
        
        user.allEurStaticAmount = user.allEurStaticAmount.add(allStatic);
        user.hisEruStaticAmount = user.hisEruStaticAmount.add(allStatic);
        return user.allEurStaticAmount;
    }
    
    function tjUserDynamicTree(uint8 isNewNode,string memory referrer, uint investAmount) private {
        string memory tmpReferrer = referrer;
        
        for (uint i = 1; i <= 10; i++) {
            if (compareStr(tmpReferrer, "")) {
                break;
            }
            address tmpUserAddr = addressMapping[tmpReferrer];
            User storage calUser = userRoundMapping[rid][tmpUserAddr];
            if (calUser.id == 0) {
                break;
            }
            
            if(calUser.freezeAmount <= 0){
                tmpReferrer = calUser.referrer;
                continue;
            }
            
            if(isNewNode > 0){
                calUser.nodeCount = calUser.nodeCount.add(1);
            }
            
            calUser.nodePerformance = calUser.nodePerformance.add(investAmount);
            
            uint recommendSc = getRecommendScaleByAmountAndTim(i);
            uint totalTmpDynamicAmount = 0;
            if (recommendSc != 0) {
                uint moneyResult = investAmount;
                uint tmpDynamicAmount = moneyResult.mul(recommendSc).div(1000);
                totalTmpDynamicAmount = totalTmpDynamicAmount.add(tmpDynamicAmount);
                
                calUser.hisDynamicAmount = calUser.hisDynamicAmount.add(tmpDynamicAmount);
            }
            
            Invest storage invest = calUser.invests[calUser.staticFlag];
            invest.earnAmount = invest.earnAmount.add(totalTmpDynamicAmount);
            if (invest.earnAmount >= invest.limitAmount) {
                calUser.staticFlag = calUser.staticFlag.add(1);
                calUser.freezeAmount = calUser.freezeAmount.sub(invest.investAmount);
                calUser.staticLevel = calUser.staticLevel.add(1);
                
                //修正收益
                uint correction = invest.earnAmount.sub(invest.limitAmount);
                if(correction > 0){
                    totalTmpDynamicAmount = totalTmpDynamicAmount.sub(correction);
                    invest.earnAmount = invest.limitAmount;
                }
            }
            
            calUser.allDynamicAmount = calUser.allDynamicAmount.add(totalTmpDynamicAmount);
            tmpReferrer = calUser.referrer;
        }
    }
    
    function isUsed(string memory code) public view returns(bool) {
        address user = getUserAddressByCode(code);
        return uint(user) != 0;
    }

    function getUserAddressByCode(string memory code) public view returns(address) {
        return addressMapping[code];
    }

    function getGameInfo() public isHuman() view returns(uint, uint, uint, uint, uint, uint, uint, uint) {
        return (
            rid,
            uid,
            endTime,
            investCount,
            investMoney,
            getTimeLeft(),
            0,
            dividendRate
        );
    }
    
    function getUserInfo(address user, uint roundId, uint i) public isHuman() view returns(
        uint[28] memory ct, string memory inviteCode, string memory referrer
    ) {
        if(roundId == 0){
            roundId = rid;
        }
        
        User memory userInfo = userRoundMapping[roundId][user];

        ct[0] = userInfo.id;
        ct[1] = 0;
        ct[2] = 0;
        ct[3] = userInfo.allInvest;
        ct[4] = userInfo.freezeAmount;
        ct[5] = 0;
        ct[6] = userInfo.allStaticAmount;
        ct[7] = userInfo.allDynamicAmount;
        ct[8] = userInfo.hisStaticAmount;
        ct[9] = userInfo.hisDynamicAmount;
        ct[10] = userInfo.inviteAmount;
        ct[11] = 0;
        ct[12] = userInfo.staticFlag;
        ct[13] = userInfo.invests.length;
        if (ct[13] != 0) {
            ct[14] = userInfo.invests[i].investAmount;
            ct[15] = userInfo.invests[i].limitAmount;
            ct[16] = userInfo.invests[i].earnAmount;
            ct[17] = userInfo.invests[i].investTime;
        } else {
            ct[14] = 0;
            ct[15] = 0;
            ct[16] = 0;
            ct[17] = 0;
        }
        ct[18] = userInfo.performance;
        ct[19] = userInfo.optionFlag;
        
        ct[20] = 0;
        ct[21] = userInfo.allEurDynamicAmount;
        ct[22] = userInfo.hisEurDynamicAmount;
        ct[23] = userInfo.allEurStaticAmount;
        ct[24] = userInfo.hisEruStaticAmount;
        
        ct[25] = userInfo.nodeCount;
        ct[26] = userInfo.nodePerformance;  
        ct[27] = unbalancedStaticProfit(user);
        
        inviteCode = userMapping[user].inviteCode;
        referrer = userMapping[user].referrer;

        return (
            ct,
            inviteCode,
            referrer
        );
    }
    
    function activeGame(uint time) external onlyWhitelistAdmin
    {
        require(time > now, "invalid game start time");
        startTime = time;
        endTime = startTime.add(period);
    }
    
    function correctionStatistics() external onlyWhitelistAdmin
    {
        statisticOfDay();
    }
    
    function changePeriod(uint _period) external onlyWhitelistAdmin
    {
        period = _period;
    }
    
    function getTimeLeft() private view returns(uint256)
    {
        // grab time
        uint256 _now = now;

        if (_now < endTime)
            if (_now > startTime)
                return( endTime.sub(_now));
            else
                return( (startTime).sub(_now));
        else
            return(0);
    }
    
    function updateDividendRate() private {
        statisticsDay = 0;
    }
    
    function registerUserInfo(address user, string calldata inviteCode, string calldata referrer) external onlyOwner {
        registerUser(user, inviteCode, referrer);
    }
    
    function registerUser(address user, string memory inviteCode, string memory referrer) private {
        UserGlobal storage userGlobal = userMapping[user];
        uid++;
        userGlobal.id = uid;
        userGlobal.userAddress = user;
        userGlobal.inviteCode = inviteCode;
        userGlobal.referrer = referrer;

        addressMapping[inviteCode] = user;
        indexMapping[uid] = user;
    }

}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "mul overflow");

        return c;
    }

    /**
    * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "div zero"); // Solidity only automatically asserts when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "lower sub bigger");
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Adds two numbers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "overflow");

        return c;
    }

}