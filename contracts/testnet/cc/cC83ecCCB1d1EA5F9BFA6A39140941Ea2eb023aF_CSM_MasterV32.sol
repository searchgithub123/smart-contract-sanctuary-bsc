// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;


interface IBEP20Token
{
    function mintTokens(address receipient, uint256 tokenAmount) external returns(bool);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function balanceOf(address user) external view returns(uint256);
    function totalSupply() external view returns (uint256);
    function maxsupply() external view returns (uint256);
    function repurches(address _from, address _to, uint256 _value) external returns(bool);
    function burn_internal(uint256 _value, address _to) external returns (bool);
}


contract CSM_MasterV32{
    
    IBEP20Token public rewardToken;

    AggregatorV3Interface internal priceFeed;
    /*===============================
    =         DATA STORAGE          =
    ===============================*/

    // Public variables of the token
    using SafeMath for uint256;
    using SafeMath for uint;



    struct Deposit {
		uint256 amount;
		uint256 start;
        uint256 lastdate;
	}


    struct User {
		Deposit[] deposits;
		address referrer;
        uint256 bonus;
        uint256 totalBonus;
        uint256 totalWithdrwan;
        uint256 totalDownLineBusiness;
        uint256 totalDownLineBusinessInBnb;
        uint256 directBonusEligibility;
        uint256[15] refStageBusiness; //total business of referrer each stage
        uint256[2] refStageBonus; //bonus of referrer each stage
		uint[15] refs;  // number of referrer each stage
        uint totalDepositInUSD;
	}

    struct ScheduleTokenWithdrawal {
        uint256 withdrawToken;
        uint256 maturitydate;
        bool ispaid;
        uint256 startTime;
    }

    struct TokenStaked {
        uint256 amountOfToken;
        uint256 rewardToken;
        uint package;
    }

    struct FlushBusiness {
		uint256 groupA;
		uint256 groupB;
        uint256 groupC;
        uint256 startDate;
        uint256 endDate;
        uint cycle;
	}

    

    
    
    
    mapping (address => TokenStaked[]) public tokenStakes;
    mapping (address => mapping(uint => ScheduleTokenWithdrawal[])) public scheduleWithdrawals;
    mapping (address => User) public users;
    mapping (address => FlushBusiness) public flushBusiness;
    mapping (address => uint256) public principalToken;
    mapping (address => uint256) public numberOfFarming;
    mapping (address => mapping(uint => uint)) public numberOfstakeAgainstFarming;
    mapping (address => mapping(uint256 => address)) public directs;
    bool public started;
    address payable public ownerWallet;
	address payable public supportWallet;
    bool private IsInitinalized;
    uint public totalUsers;
   

    uint[2] public ref_bonuses; // first level bonus calculate as per the package amount.
    uint[4] public plan ; //usd
    uint[4] public plan_ref_bonuses; // Direct Bonus
    uint256 csmTokenPrice;

    uint[5] public farmingRewardPercentage; // farming percentage
    uint[5] public farmingLockPeriod; // farming locked days

    uint[7] public farmingTokenAchive; // farming locked days

    //uint[6] public Group_Rewards_Program = [10000,50000,100000,200000,500000,1000000];
    uint[6] public Group_Rewards_Program;

    //uint[3] public flushCycleDays = [90 days, 60 days, 30 days];
    uint[3] public flushCycleDays;

    uint256 public TotalInvestment;

    
    uint256[12] public profit_sharing_bonus;

    struct BusinessLog {

		uint256 matching;
        uint256 received;
		uint256 groupA;
        uint256 groupB;
        uint256 groupC;
        bool ispaid;
        bool isclaim;
	}

    mapping (address => BusinessLog[]) public businessLogs;
    mapping (address => uint) public businessLogsCount;
    /////////////////////////////

    function initialize(address payable _ownerWallet) public {
        require (IsInitinalized == false,"Already Started");
        ref_bonuses = [0,5];
        plan = [1,5,10,50];
        plan_ref_bonuses = [10,15,20,25];
        csmTokenPrice = 0.001 ether;
        farmingRewardPercentage = [20,50,75,100,100];
        farmingLockPeriod = [180,365,545,730,365];
        farmingTokenAchive = [180,270,360,450,545,630,720];
        Group_Rewards_Program = [10*1e8,50*1e8,100*1e8,200*1e8,500*1e8,1000*1e8];
        profit_sharing_bonus = [100,120,200,350,610,1140,2280,6840,19000,85600,371800,612000];
        flushCycleDays = [60 minutes, 40 minutes, 20 minutes];
        priceFeed = AggregatorV3Interface(0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526);
        ownerWallet = _ownerWallet;
        IsInitinalized = true;

	}

   


    function invest(address _referrer, uint256 _package_index) public payable {

       require(uint256(TotalusdPrice(int(msg.value))) > 1*1e8, 'required min 50 USD!');
       User storage user = users[msg.sender];

       require((users[_referrer].deposits.length > 0 && _referrer != msg.sender) || ownerWallet == msg.sender,  "No upline found");
         
        if (user.referrer == address(0) && ownerWallet != msg.sender) {
			user.referrer = _referrer;
        }


        uint256 geteligibleForDirectBonus = eligibleForDirectBonus(msg.value);
        user.directBonusEligibility = geteligibleForDirectBonus;

         user.totalDepositInUSD += uint256(TotalusdPrice(int(msg.value)));

        address upline = user.referrer;
        for(uint i=0; i < 15; i++){
            if (upline != address(0)) {
                users[upline].refs[i] += 1;
                //  if(block.timestamp >= flushBusiness[upline].endDate){
                //      claim(upline);
                //  }
                 users[upline].refStageBusiness[i] = users[upline].refStageBusiness[i].add(msg.value);
                 users[upline].totalDownLineBusinessInBnb += msg.value;
                 users[upline].totalDownLineBusiness += uint256(TotalusdPrice(int(msg.value)));

                if(i < 2){ 
                uint256 bonus_percentage = (i==0)? users[upline].directBonusEligibility : ref_bonuses[i];
                uint256 bonus = msg.value.mul(bonus_percentage).div(100);
                users[upline].bonus += bonus;
                }
            }else break; 
          upline = users[upline].referrer;
        }

           if(user.referrer != address(0)){
         directs[user.referrer][users[user.referrer].refs[0]-1] = msg.sender;
         }

        if(user.deposits.length == 0){
            flushBusiness[msg.sender].startDate = block.timestamp;
            flushBusiness[msg.sender].endDate = block.timestamp.add(flushCycleDays[0]);
            flushBusiness[msg.sender].cycle = 1;
            totalUsers = totalUsers.add(1);
        }
        
       

        TotalInvestment += msg.value;
        uint256 tokenReceivedPrincipal = msg.value.div(csmTokenPrice)*1e18;
        principalToken[msg.sender] += tokenReceivedPrincipal;
        stake(_package_index);
        user.deposits.push(Deposit(msg.value, block.timestamp, 0));

    }

    function groupAIncome(address _userAddress) public view returns(uint256 _income, address _address){
        User storage user = users[_userAddress];
        uint256 maxBusiness;
        address _addressa;
        for(uint i=0; i <= user.refs[0]; i++){
             address groupAuser =  directs[_userAddress][i];
             if(users[groupAuser].totalDownLineBusiness.add(users[groupAuser].totalDepositInUSD) > maxBusiness){
                 maxBusiness =  users[groupAuser].totalDownLineBusiness.add(users[groupAuser].totalDepositInUSD);
                 _addressa = groupAuser;
             }
         }

         _income = maxBusiness.sub(flushBusiness[_userAddress].groupA);
         _address = _addressa;
    }

    function groupBIncome(address _userAddress) public view returns(uint256 _income, address _address){
        User storage user = users[_userAddress];
        (, address address_) = groupAIncome(_userAddress);
        uint256 maxBusiness;
        address _addressb;
        for(uint i=0; i <= user.refs[0]; i++){
             address groupBuser =  directs[_userAddress][i];
             if(address_ != groupBuser && users[groupBuser].totalDownLineBusiness.add(users[groupBuser].totalDepositInUSD) > maxBusiness){
                 maxBusiness =  users[groupBuser].totalDownLineBusiness.add(users[groupBuser].totalDepositInUSD);
                 _addressb = groupBuser;
             }
         }

         _income = maxBusiness.sub(flushBusiness[_userAddress].groupB);
         _address = _addressb;
    }

    function groupCIncome(address _userAddress) public view returns(uint256 _income){
         User storage user = users[_userAddress];
         (, address addressA_) = groupAIncome(_userAddress);
         (, address addressB_) = groupBIncome(_userAddress);
         for(uint i=0; i <= user.refs[0]; i++){
            address groupCuser =  directs[_userAddress][i];
            if(addressA_ != groupCuser && addressB_ != groupCuser){
            _income += users[groupCuser].totalDownLineBusiness.add(users[groupCuser].totalDepositInUSD);
           
            }
         }
         _income = _income.sub(flushBusiness[_userAddress].groupC);

    }


    

    function claimBonus() public returns(uint256){
        require(block.timestamp >= flushBusiness[msg.sender].endDate, 'not eligibile to claim');
        claim(msg.sender);
         return 1;
    }

    function claim(address _useraddress) internal returns(uint){

            

            (uint256 incomeA_,) = groupAIncome(_useraddress); 
            (uint256 incomeB_,) = groupBIncome(_useraddress);
            uint256 groupRewardIncome = groupEligibilityIncome(_useraddress);
            uint256 groupRewardReceived = getReInvestmentAmount(_useraddress);

            if(businessLogsCount[_useraddress] ==0){
                businessLogsCount[_useraddress] +=1;

                businessLogs[_useraddress].push(BusinessLog(groupRewardIncome, groupRewardReceived, incomeA_, incomeB_, groupCIncome(_useraddress),false,true));

                
            }
            if((businessLogsCount[_useraddress] >0) && (businessLogs[_useraddress][businessLogsCount[_useraddress]-1].ispaid)){
                businessLogsCount[_useraddress] +=1;
                businessLogs[_useraddress].push(BusinessLog(groupRewardIncome, groupRewardReceived, incomeA_, incomeB_, groupCIncome(_useraddress),false,true));
             
            }

            return 1;
    }

    function receiveGroupIncome(uint _index) public payable {

        if(businessLogs[msg.sender][_index].isclaim == true && businessLogs[msg.sender][_index].ispaid == false){
            if( businessLogs[msg.sender][_index].matching > 0){
            uint256 amountToBepay =  businessLogs[msg.sender][_index].received;

            uint bnb =  getCalculatedBnbRecieved(amountToBepay);

            if(businessLogs[msg.sender][_index].received > 0){
            require(msg.value >= bnb, 'not enough fund!');
            }
        
            businessLogs[msg.sender][_index].ispaid = true;
            users[msg.sender].totalDepositInUSD += uint256(TotalusdPrice(int(bnb)));
            users[msg.sender].deposits.push(Deposit(bnb, block.timestamp, 0));
            flushBusiness[msg.sender].cycle +=1;
            uint nextcycledate = (flushBusiness[msg.sender].cycle >= 3) ? flushCycleDays[2] : flushCycleDays[1]; 
            flushBusiness[msg.sender].startDate = block.timestamp;
            flushBusiness[msg.sender].endDate = block.timestamp.add(nextcycledate);
            (uint256 incomeA_,) = groupAIncome(msg.sender); 
            (uint256 incomeB_,) = groupBIncome(msg.sender);
            flushBusiness[msg.sender].groupA += incomeA_;
            flushBusiness[msg.sender].groupB += incomeB_;
            flushBusiness[msg.sender].groupC += groupCIncome(msg.sender);

            uint bnbtosend = getCalculatedBnbRecieved(businessLogs[msg.sender][_index].matching);



            payable(msg.sender).transfer(bnbtosend.mul(75).div(100));
           
            }else{

                uint nextcycledate;
                if(flushBusiness[msg.sender].cycle == 1){
                    nextcycledate = flushCycleDays[0];
                }else if(flushBusiness[msg.sender].cycle == 2){
                    nextcycledate = flushCycleDays[1];
                }else if(flushBusiness[msg.sender].cycle == 3){
                    nextcycledate = flushCycleDays[2];
                } 
                flushBusiness[msg.sender].startDate = block.timestamp;
                flushBusiness[msg.sender].endDate = block.timestamp.add(nextcycledate);

                (uint256 incomeA_,) = groupAIncome(msg.sender); 
                (uint256 incomeB_,) = groupBIncome(msg.sender);

                flushBusiness[msg.sender].groupA += incomeA_;
                flushBusiness[msg.sender].groupB += incomeB_;
                flushBusiness[msg.sender].groupC += groupCIncome(msg.sender);

            }
           


        }

    }



    function getReInvestmentAmount(address _useraddress) public view returns(uint _reInvestmentAmount){
        User storage user = users[_useraddress];
        uint256 groupRewardIncome = groupEligibilityIncome(_useraddress);
        if (groupRewardIncome > 0){
            uint256 reInvestmentAmount = groupRewardIncome.mul(25).div(100);

        if(user.totalDepositInUSD >=reInvestmentAmount){
            _reInvestmentAmount = 0;
            
        }else {
         _reInvestmentAmount  =  reInvestmentAmount.sub(user.totalDepositInUSD);
        }

        }
        
    }



    function groupEligibilityIncome(address _userAddress) public view returns(uint256){

        uint256[] memory arrayIncome = new uint[](3);

        (uint256 incomeA_,) = groupAIncome(_userAddress); 
        (uint256 incomeB_,) = groupBIncome(_userAddress);
        arrayIncome[0] = incomeA_;
        arrayIncome[1] = incomeB_;
        arrayIncome[2] = groupCIncome(_userAddress);

        uint256 minimumBusinessFromGroup = min(arrayIncome);
        uint256 groupReward;
        if(minimumBusinessFromGroup >= Group_Rewards_Program[0] && minimumBusinessFromGroup < Group_Rewards_Program[1]){
            groupReward = Group_Rewards_Program[0];
        }else if(minimumBusinessFromGroup >= Group_Rewards_Program[1] && minimumBusinessFromGroup < Group_Rewards_Program[2]){
            groupReward = Group_Rewards_Program[1];
        }else if(minimumBusinessFromGroup >= Group_Rewards_Program[2] && minimumBusinessFromGroup < Group_Rewards_Program[3]){
            groupReward = Group_Rewards_Program[2];
        }else if(minimumBusinessFromGroup >= Group_Rewards_Program[3] && minimumBusinessFromGroup < Group_Rewards_Program[4]){
            groupReward = Group_Rewards_Program[3];
        }else if(minimumBusinessFromGroup >= Group_Rewards_Program[4] && minimumBusinessFromGroup < Group_Rewards_Program[5]){
            groupReward = Group_Rewards_Program[4];
        }else if(minimumBusinessFromGroup >= Group_Rewards_Program[5]){
            groupReward = Group_Rewards_Program[5];
        }
        return groupReward;

    }

    function min(uint256[] memory numbers) public pure returns (uint256) {
     require(numbers.length > 0); // throw an exception if the condition is not met
        uint256 minNumber; // default 0, the lowest value of `uint256`

        for (uint256 i = 0; i < numbers.length; i++) {
           if(i==0){
                if (minNumber <= numbers[i]) {
                    minNumber = numbers[i];
                }
           }else if (minNumber > numbers[i]){
                    minNumber = numbers[i]; 
                } 
        }

        return minNumber;
    }


    function stake(uint256 _package) private returns(bool){
        
        // require(principalToken[msg.sender] >= 100*1e18, "Minimum Stake 100");
        uint256 calRewardToken = principalToken[msg.sender].mul(farmingRewardPercentage[_package]).div(100);
        tokenStakes[msg.sender].push(TokenStaked(principalToken[msg.sender], principalToken[msg.sender].add(calRewardToken),_package));
        numberOfFarming[msg.sender] += 1;

        //Basic
        if(farmingLockPeriod[_package]==180){

            uint256 receivable = principalToken[msg.sender].add(calRewardToken).div(2); 
            scheduleWithdrawals[msg.sender][numberOfFarming[msg.sender]].push(ScheduleTokenWithdrawal(receivable,180,false,block.timestamp));
            scheduleWithdrawals[msg.sender][numberOfFarming[msg.sender]].push(ScheduleTokenWithdrawal(receivable,270,false,block.timestamp));
            numberOfstakeAgainstFarming[msg.sender][numberOfFarming[msg.sender]] = 2;
        }
        //Premium
        if(_package == 1 && farmingLockPeriod[_package]==365){

            uint256 receivable = principalToken[msg.sender].add(calRewardToken); 
            scheduleWithdrawals[msg.sender][numberOfFarming[msg.sender]].push(ScheduleTokenWithdrawal(receivable.mul(333).div(1000),180,false,block.timestamp));
            scheduleWithdrawals[msg.sender][numberOfFarming[msg.sender]].push(ScheduleTokenWithdrawal(receivable.mul(333).div(1000),270,false,block.timestamp));
            scheduleWithdrawals[msg.sender][numberOfFarming[msg.sender]].push(ScheduleTokenWithdrawal(receivable.mul(333).div(1000),365,false,block.timestamp));
            numberOfstakeAgainstFarming[msg.sender][numberOfFarming[msg.sender]] = 3;
        }


        //Glod
        if(farmingLockPeriod[_package]==545){

            uint256 receivable = principalToken[msg.sender].add(calRewardToken); 
            scheduleWithdrawals[msg.sender][numberOfFarming[msg.sender]].push(ScheduleTokenWithdrawal(receivable.mul(200).div(1000),180,false,block.timestamp));
            scheduleWithdrawals[msg.sender][numberOfFarming[msg.sender]].push(ScheduleTokenWithdrawal(receivable.mul(200).div(1000),270,false,block.timestamp));
            scheduleWithdrawals[msg.sender][numberOfFarming[msg.sender]].push(ScheduleTokenWithdrawal(receivable.mul(200).div(1000),360,false,block.timestamp));
            scheduleWithdrawals[msg.sender][numberOfFarming[msg.sender]].push(ScheduleTokenWithdrawal(receivable.mul(200).div(1000),450,false,block.timestamp));
            scheduleWithdrawals[msg.sender][numberOfFarming[msg.sender]].push(ScheduleTokenWithdrawal(receivable.mul(200).div(1000),545,false,block.timestamp));
            numberOfstakeAgainstFarming[msg.sender][numberOfFarming[msg.sender]] = 5;
        }

        // platinum
        if(farmingLockPeriod[_package]==720){

            uint256 receivable = principalToken[msg.sender].add(calRewardToken); 
            scheduleWithdrawals[msg.sender][numberOfFarming[msg.sender]].push(ScheduleTokenWithdrawal(receivable.mul(150).div(1000),180,false,block.timestamp));
            scheduleWithdrawals[msg.sender][numberOfFarming[msg.sender]].push(ScheduleTokenWithdrawal(receivable.mul(150).div(1000),270,false,block.timestamp));
            scheduleWithdrawals[msg.sender][numberOfFarming[msg.sender]].push(ScheduleTokenWithdrawal(receivable.mul(150).div(1000),360,false,block.timestamp));
            scheduleWithdrawals[msg.sender][numberOfFarming[msg.sender]].push(ScheduleTokenWithdrawal(receivable.mul(150).div(1000),450,false,block.timestamp));
            scheduleWithdrawals[msg.sender][numberOfFarming[msg.sender]].push(ScheduleTokenWithdrawal(receivable.mul(150).div(1000),545,false,block.timestamp));
            scheduleWithdrawals[msg.sender][numberOfFarming[msg.sender]].push(ScheduleTokenWithdrawal(receivable.mul(150).div(1000),630,false,block.timestamp));
            scheduleWithdrawals[msg.sender][numberOfFarming[msg.sender]].push(ScheduleTokenWithdrawal(receivable.mul(100).div(1000),720,false,block.timestamp));
            numberOfstakeAgainstFarming[msg.sender][numberOfFarming[msg.sender]] = 7;
            
        }

        // VIP platinum
        if(_package == 4 && farmingLockPeriod[_package]==365){

            uint256 receivable = principalToken[msg.sender].add(calRewardToken); 
            scheduleWithdrawals[msg.sender][numberOfFarming[msg.sender]].push(ScheduleTokenWithdrawal(receivable.mul(350).div(1000),180,false,block.timestamp));
            scheduleWithdrawals[msg.sender][numberOfFarming[msg.sender]].push(ScheduleTokenWithdrawal(receivable.mul(325).div(1000),270,false,block.timestamp));
            scheduleWithdrawals[msg.sender][numberOfFarming[msg.sender]].push(ScheduleTokenWithdrawal(receivable.mul(325).div(1000),365,false,block.timestamp));
            numberOfstakeAgainstFarming[msg.sender][numberOfFarming[msg.sender]] = 3;
            
        }

        return true;

    }

    function WithdrawalToken(uint _fno, uint _sno) public {
        if( scheduleWithdrawals[msg.sender][_fno][_sno].maturitydate > 0 && block.timestamp >=(scheduleWithdrawals[msg.sender][_fno][_sno].maturitydate.mul(1 days)+scheduleWithdrawals[msg.sender][_fno][_sno].startTime)){
            scheduleWithdrawals[msg.sender][_fno][_sno].ispaid = true;

            // Token To transfer has remainning.
        } else{
            revert ("You are not Eligibile for Widhdrwan Right now");
        }
    }

    function WithdrawalDirectIncome() public {
        
       uint256 bonus =  users[msg.sender].bonus;
       users[msg.sender].bonus = 0;
       users[msg.sender].totalBonus += bonus;

       payable(msg.sender).transfer(bonus);
    }



    

    function getNumberOfFrearminig(address _userAddress) public view returns(uint){
        return numberOfFarming[_userAddress];
    }

    function getNumberOfStakeAgainstFrearminig(address _userAddress,uint _index) public view returns( uint _NoOfStakes){
        _NoOfStakes = numberOfstakeAgainstFarming[_userAddress][_index];
    }


        
    function getUserDetails(address _address) public view returns(address _referrer, uint256 _bonus, uint256 _totalBonus, uint256 _totalWithdrwan, uint256 _totalDownLineBusiness ){
        User storage user = users[_address];
        return(user.referrer,user.bonus, user.totalBonus, user.totalWithdrwan, user.totalDownLineBusiness);
    }

    function eligibleForDirectBonus(uint256 amount) public view returns(uint256){

        uint256 _percent;
		uint _amount = uint(TotalusdPrice(int(amount)));

        if(_amount >= (plan[0]*1e8) && _amount < (plan[1]*1e8)){
			_percent = plan_ref_bonuses[0];
		}else if(_amount >= (plan[1]*1e8) && _amount < (plan[2]*1e8)){
			_percent = plan_ref_bonuses[1];
		}else if(_amount >= (plan[2]*1e8) && _amount < (plan[3]*1e8)){
			_percent = plan_ref_bonuses[2];
		}else if(_amount >= (plan[3]*1e8)){
			_percent = plan_ref_bonuses[3];
		}

		return (_percent);
		
	}

    function revertBack() external{
        require(ownerWallet == msg.sender);
        payable(ownerWallet).transfer(address(this).balance);
    }


    function getLatestPrice() public view returns (int) {
        (
            /* uint80 roundID */,
            int price,
            /*uint startedAt */,
            /*uint timeStamp*/,
           /* uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();
        return price;
    }

    function TotalusdPrice(int _amount) public view returns (int) {
        int usdt = getLatestPrice();
        //  int usdt = 28318079943;
        return (usdt * _amount)/1e18;
    }

    function getCalculatedBnbRecieved(uint256 _amount) public view returns(uint256) {
		uint256 usdt = uint256(getLatestPrice());
        // uint256 usdt = 28318079943 ;
		uint256 recieved_bnb = (_amount*1e18/usdt*1e18)/1e18;
		return recieved_bnb;
	  }
    function getSystemInfo() public view returns( uint _TotalInvestment, uint _totalUsers){
        return (TotalInvestment,totalUsers);
        
    }
    function getDepositLength(address _useraddress) public view returns(uint){
        User storage u = users[_useraddress] ;
        return u.deposits.length;
    }   
    function getDepositInfo(uint _index ,address _useraddress) public view returns(uint _amount  , uint _start, uint _lastdate){
        User storage u = users[_useraddress] ;
        return (u.deposits[_index].amount , u.deposits[_index].start,u.deposits[_index].lastdate);
    }
    
    function getUserRef(address _useraddress , uint _index) public view returns(uint _refcount, uint _refStageBusiness) {
        User storage user = users[_useraddress];
        return(
            user.refs[_index],
            user.refStageBusiness[_index]
        );
    }
    function updateFlushEndDateByuser(address _useraddress, uint _second) public {
         
            flushBusiness[_useraddress].endDate = block.timestamp.add(_second);
    }
    function reward() external payable{
       
    }


}







//*******************************************************************//
//------------------------ SafeMath Library -------------------------//
//*******************************************************************//

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
        return 0;
    }
    uint256 c = a * b;
    require(c / a == b, 'SafeMath mul failed');
    return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, 'SafeMath sub failed');
    return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, 'SafeMath add failed');
    return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b == 0, 'SafeMath add failed');
        return (a % b);
    }
}

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}