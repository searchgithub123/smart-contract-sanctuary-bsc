/**
 *Submitted for verification at BscScan.com on 2022-11-09
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

contract Ownable {

  address public owner;
  address public ownerWallet;

  modifier onlyOwner() {
    require(msg.sender == owner, "only for owner");
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    owner = newOwner;
  }

}

contract BinancePay is Ownable {

    event regLevelEvent(address indexed _user, address indexed _referrer, uint _time);
    event buyLevelEvent(address indexed _user, uint _level, uint _time);
    //------------------------------

    mapping (uint => uint) public LEVEL_PRICE;
    uint REFERRER_1_LEVEL_LIMIT = 3;
    uint256 public royalityAmount = 0;
    uint256 public globalroyalityAmountA = 0;
    uint256 public globalroyalityAmountB = 0;

    address[] public royalparticipants;
    address[] public globalparticipants1;
    address[] public globalparticipants2;

    address[] public joinedAddress;
    address[] public planBRefAmount;

    mapping (address => uint256) public planBRefAmountuser;


    struct UserStruct {
        bool isExist;
        uint256 id;
        uint256 referrerID;
        uint currentLevel;
        uint256 earnedAmount;
        uint256 totalearnedAmount;
        uint256 royalityincome;
        uint256 globalroyality1income;
        uint256 globalroyality2income;
        address[] referral;
        mapping (uint => uint256) levelEarningmissed;
    }

     struct PlanBStruct {
        bool isExist;
        uint256 id;
        uint256 referrerID;
        address[] referral;
    }

    mapping (address => UserStruct) public users;
    mapping (address => PlanBStruct) public planB;
    mapping (uint => address) public userList;
    mapping (uint => address) public planBuserList;
    mapping (uint => bool) public userRefComplete;
    uint256 public currUserID = 0;
	uint refCompleteDepth = 1;
    bool public isAutodistribute = false;
    uint256 public lastRewardTimestamp;
    uint256 public endRewardTime;
    uint256 public currUserId = 0 ;

    constructor() public {
		owner = msg.sender;
		ownerWallet = msg.sender;

        LEVEL_PRICE[1] = 100000;   // 0.01
        LEVEL_PRICE[2] = LEVEL_PRICE[1] * 3;
        LEVEL_PRICE[3] = LEVEL_PRICE[2] * 3;
        LEVEL_PRICE[4] = LEVEL_PRICE[3] * 3;
        LEVEL_PRICE[5] = LEVEL_PRICE[4] * 3;
        LEVEL_PRICE[6] = LEVEL_PRICE[5] * 3;
        LEVEL_PRICE[7] = LEVEL_PRICE[6] * 3;
        LEVEL_PRICE[8] = LEVEL_PRICE[7] * 3;

        UserStruct memory userStruct;
        PlanBStruct memory planBStruct;
        currUserID = 1000000;
        lastRewardTimestamp = block.timestamp;
        endRewardTime = block.timestamp + 600;

        userStruct = UserStruct({
            isExist : true,
            id : currUserID,
            referrerID : 0,
            currentLevel : 8,
            earnedAmount : 0,
            totalearnedAmount: 0,
            referral : new address[](0),
            royalityincome : 0,
            globalroyality1income : 0,
            globalroyality2income : 0
        });

        planBStruct = PlanBStruct({
            isExist : true,
            referrerID : 0,
            id : currUserID,
            referral : new address[](0)
        });
        users[ownerWallet] = userStruct;
        users[ownerWallet].levelEarningmissed[1] = 0;
        users[ownerWallet].levelEarningmissed[2] = 0;
        users[ownerWallet].levelEarningmissed[3] = 0;
        users[ownerWallet].levelEarningmissed[4] = 0;
        users[ownerWallet].levelEarningmissed[5] = 0;
        users[ownerWallet].levelEarningmissed[6] = 0;
        users[ownerWallet].levelEarningmissed[7] = 0;
        users[ownerWallet].levelEarningmissed[8] = 0;
        planB[ownerWallet] = planBStruct;
        userList[currUserID] = ownerWallet;
        planBuserList[currUserID] = ownerWallet;
    }

    function random(uint number) public view returns(uint){
        return uint(keccak256(abi.encodePacked(block.timestamp,block.difficulty,
        msg.sender))) % number;
    }

     receive() external payable {
        if(block.timestamp > endRewardTime && isAutodistribute){
            distribute();
        }
     }
    function regUser(address _referrer) public payable {
        require(!users[msg.sender].isExist, 'User exist');
		uint _referrerID;
		if (users[_referrer].isExist){
			_referrerID = users[_referrer].id;
		} else if (_referrer == address(0)) {
			_referrerID = findFirstFreeReferrer();
			refCompleteDepth = _referrerID;
		} else {
			revert('Incorrect referrer');
		}

        require(msg.value == (LEVEL_PRICE[1] * 2 * 1e18) / 10000000 , 'Incorrect Value');

        if(users[userList[_referrerID]].referral.length >= REFERRER_1_LEVEL_LIMIT)
        {
            _referrerID = users[findFreeReferrer(userList[_referrerID])].id;
        }

        UserStruct memory userStruct;
        currUserID = random(1000000);

        userStruct = UserStruct({
            isExist : true,
            id : currUserID,
            referrerID : _referrerID,
            earnedAmount : 0,
            totalearnedAmount:0,
            referral : new address[](0),
            currentLevel : 1,
            globalroyality1income:0,
            globalroyality2income:0,
            royalityincome:0
        });

        users[msg.sender] = userStruct;
        users[msg.sender].levelEarningmissed[2] = 0;
        users[msg.sender].levelEarningmissed[3] = 0;
        users[msg.sender].levelEarningmissed[4] = 0;
        users[msg.sender].levelEarningmissed[5] = 0;
        users[msg.sender].levelEarningmissed[6] = 0;
        users[msg.sender].levelEarningmissed[7] = 0;
        users[msg.sender].levelEarningmissed[8] = 0;

        userList[currUserID] = msg.sender;
        users[userList[_referrerID]].referral.push(msg.sender);

		if (users[userList[_referrerID]].referral.length == 3) {
			userRefComplete[_referrerID] = true;
		}
        currUserId++;
        address uplinerAddress = userList[users[msg.sender].referrerID];
        users[uplinerAddress].earnedAmount += LEVEL_PRICE[1];
        users[uplinerAddress].totalearnedAmount+= LEVEL_PRICE[1];
        activatePlanB(_referrer,msg.sender);
        joinedAddress.push(msg.sender);
        emit regLevelEvent(msg.sender, userList[_referrerID], now);
    }

    function activatePlanB(address upliner,address _user) internal {
         PlanBStruct memory planBStruct;
         planBStruct = PlanBStruct({
            isExist : true,
            referrerID : users[upliner].id,
            id : users[_user].id,
            referral : new address[](0)
        });
        planB[_user] = planBStruct;
        planBuserList[planB[_user].id] = _user;
        planB[upliner].referral.push(_user);

         //40% to direct parent

         uint256 directParentIncome = (LEVEL_PRICE[1] * 40) /100;

         users[upliner].earnedAmount +=  directParentIncome;
         users[upliner].totalearnedAmount +=  directParentIncome;

         //30% Level Income
          levelincome(upliner,0);

         //5% Team Royality;
           uint256 _teamRoyalityTotal = (LEVEL_PRICE[1] * 5) /100;

           uint256 _globalRoyalityTotal = (LEVEL_PRICE[1] * 10) /100;
           royalityAmount += _teamRoyalityTotal;
           globalroyalityAmountA += _teamRoyalityTotal;
           globalroyalityAmountB += _globalRoyalityTotal;
    }

    function levelincome(address _parent,uint cnt) internal{
        if(cnt < 10 && _parent != 0x0000000000000000000000000000000000000000){
             uint256 LevelIncome = (LEVEL_PRICE[1] * 30) /100;
             uint256  levelIncomePerLevel = LevelIncome/10;
             users[_parent].earnedAmount +=  levelIncomePerLevel;
             users[_parent].totalearnedAmount +=  levelIncomePerLevel;
             address nextParent = planBuserList[planB[_parent].referrerID];
             cnt++;
             levelincome(nextParent,cnt);
        }
    }


    function buyLevel(uint _level) public payable {
        require(users[msg.sender].isExist, 'User not exist');
        require( _level>1 && _level<=8, 'Incorrect level');

        require(msg.value == LEVEL_PRICE[_level] * 1e18 / 10000000  , 'Incorrect Value');
        require( _level > users[msg.sender].currentLevel, 'Incorrect level');
        require(users[msg.sender].currentLevel == _level-1 , 'Incorrect level');

        if(_level == 2){
          royalparticipants.push(msg.sender);
        }else if(_level == 3){
          globalparticipants1.push(msg.sender);
        }else if(_level == 4){
          globalparticipants2.push(msg.sender);
        }

        users[msg.sender].currentLevel = _level;
        payForLevel(_level, msg.sender);
        emit buyLevelEvent(msg.sender, _level, now);
    }

    function payForLevel(uint _level, address _user) internal {
        address referer;
        address referer1;
        address referer2;
        address referer3;
        if(_level == 1 || _level == 5){
            referer = userList[users[_user].referrerID];
        } else if(_level == 2 || _level == 6){
            referer1 = userList[users[_user].referrerID];
            referer = userList[users[referer1].referrerID];
        } else if(_level == 3 || _level == 7){
            referer1 = userList[users[_user].referrerID];
            referer2 = userList[users[referer1].referrerID];
            referer = userList[users[referer2].referrerID];
        } else if(_level == 4 || _level == 8){
            referer1 = userList[users[_user].referrerID];
            referer2 = userList[users[referer1].referrerID];
            referer3 = userList[users[referer2].referrerID];
            referer = userList[users[referer3].referrerID];
        }

        if(users[_user].levelEarningmissed[_level] > 0){
            users[_user].earnedAmount += users[_user].levelEarningmissed[_level];
            users[_user].totalearnedAmount += users[_user].levelEarningmissed[_level];
            users[_user].levelEarningmissed[_level] = 0;
        }

         bool isSend = true;
         if(!users[referer].isExist){
            isSend = false;
         }
        if(isSend){
            if(users[referer].currentLevel >= _level ){
              users[referer].earnedAmount += LEVEL_PRICE[_level];
              users[referer].totalearnedAmount += LEVEL_PRICE[_level];

            }else{
              users[referer].levelEarningmissed[_level] += LEVEL_PRICE[_level];
            }
        }
    }
    function findParentLevel(address _userAddress) internal {
            address uplineParent = planBuserList[planB[_userAddress].referrerID];
            if(uplineParent != 0x0000000000000000000000000000000000000000){
                if(users[uplineParent].currentLevel >= 2){
                   planBRefAmount.push(uplineParent);
                }
                findParentLevel(uplineParent);
            }
    }

    function rewardtimestamp() public view returns(bool){
         if(block.timestamp > endRewardTime){
            return true;
        }else{
            return false;
        }
    }

     function distribute() internal{
           require(block.timestamp > endRewardTime,"Stil time not reached");
           lastRewardTimestamp = block.timestamp;
           endRewardTime = lastRewardTimestamp + 600;
          if(joinedAddress.length > 0 && royalityAmount > 0){
                for(uint i=0; i < joinedAddress.length;i++){
                    findParentLevel(joinedAddress[i]);
                    if(planBRefAmount.length  > 0) {
                        uint256 shareAmount  = ((LEVEL_PRICE[1] * 5)/100)/planBRefAmount.length  ;
                        for(uint256 j=0; j < planBRefAmount.length;i++) {
                            users[planBRefAmount[i]].earnedAmount += shareAmount;
                            users[planBRefAmount[i]].totalearnedAmount += shareAmount;
                            users[planBRefAmount[i]].royalityincome = shareAmount;
                        }
                        delete planBRefAmount;
                    }
                }
           }
           if(globalparticipants1.length > 0 && globalroyalityAmountA > 0){
               uint256 global1share = (globalroyalityAmountA/globalparticipants1.length);
                for(uint i=0; i < globalparticipants1.length;i++){
                    users[globalparticipants1[i]].earnedAmount += global1share;
                    users[globalparticipants1[i]].totalearnedAmount += global1share;
                    users[globalparticipants1[i]].globalroyality1income = global1share;
                }
           }
           if(globalparticipants2.length > 0  && globalroyalityAmountB > 0){
               uint256 global2share = (globalroyalityAmountB/globalparticipants2.length);
                for(uint i=0; i < globalparticipants2.length;i++){
                    users[globalparticipants2[i]].earnedAmount += global2share;
                    users[globalparticipants2[i]].totalearnedAmount += global2share;
                    users[globalparticipants2[i]].globalroyality2income = global2share;
                }
           }
           royalityAmount = 0;
           globalroyalityAmountA = 0;
           globalroyalityAmountB = 0;
           delete joinedAddress;
    }

    function findFreeReferrer(address _user) public view returns(address) {
        if(users[_user].referral.length < REFERRER_1_LEVEL_LIMIT){
            return _user;
        }
        address[] memory referrals = new address[](600);
        referrals[0] = users[_user].referral[0];
        referrals[1] = users[_user].referral[1];
        referrals[2] = users[_user].referral[2];
        address freeReferrer;
        bool noFreeReferrer = true;

        for(uint i =0; i<600;i++){
            if(users[referrals[i]].referral.length == REFERRER_1_LEVEL_LIMIT){
                if(i<120){
                    referrals[(i+1)*3] = users[referrals[i]].referral[0];
                    referrals[(i+1)*3+1] = users[referrals[i]].referral[1];
                    referrals[(i+1)*3+2] = users[referrals[i]].referral[2];
                }
            }else{
                noFreeReferrer = false;
                freeReferrer = referrals[i];
                break;
            }
        }
		if (noFreeReferrer) {
			freeReferrer = userList[findFirstFreeReferrer()];
			require(freeReferrer != address(0));
		}
        return freeReferrer;

    }

    function getmissedvalue(address _userAddress,uint256 _level) public view returns(uint256) {
        return users[_userAddress].levelEarningmissed[_level];
    }

    function findFirstFreeReferrer() public view returns(uint) {
		for(uint i = refCompleteDepth; i < 500+refCompleteDepth; i++) {
			if (!userRefComplete[i]) {
				return i;
			}
		}
	}
    function safeWithDrawbnb(uint256 _amount, address payable addr) public onlyOwner
    {
        addr.transfer(_amount);
    }

     function distributeByAdmin() public onlyOwner
    {
        distribute();
    }

      function claimRewards() public
    {
        uint256 claimAmount = users[msg.sender].earnedAmount;
        if(claimAmount > 0){
            claimAmount = claimAmount * 1e18 / 10000000 ;
            payable(msg.sender).transfer(claimAmount);
            users[msg.sender].earnedAmount = 0;
        }
    }

    function setAutoDistribute(bool isauto) public onlyOwner
    {
        isAutodistribute = isauto;
    }

    function viewUserReferral(address _user) public view returns(address[] memory) {
        return users[_user].referral;
    }

    function viewplanBUserReferral(address _user) public view returns(address[] memory) {
        return planB[_user].referral;
    }

}