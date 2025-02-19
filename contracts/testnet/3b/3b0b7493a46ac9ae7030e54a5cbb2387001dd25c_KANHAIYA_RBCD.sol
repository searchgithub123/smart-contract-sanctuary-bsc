/**
 *Submitted for verification at BscScan.com on 2023-02-03
*/

// Sources flattened with hardhat v2.12.2 https://hardhat.org


pragma solidity ^0.5.0;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract Exam {

    address public owner;
    uint256 public passMarks;

    mapping (uint256 => uint256) qAns;
    uint256 public totalQuestions;
    struct User{
        uint256 obtainMarks;
        uint256 lastAttain;
        uint256 totalMarks;
        string  status;
        uint256 percentage;
    }
    mapping(address => User) user;

    constructor () public{
        owner = msg.sender;
    }
    // OnlyOwner Modifier
    modifier onlyOwner {
        require(msg.sender == owner,"ONLY_OWNER_ALLOWED");
        _;
        
    }
// Set Question and Thier Choice
function setQuestion(uint256[] memory questions, uint256[] memory corr_choices) public onlyOwner{
    require(questions.length == corr_choices.length,"NOT_EQUAL_Q_A");
    for(uint256 i=0;i< questions.length; i++){
      qAns[questions[i]] = corr_choices[i];
    }
    totalQuestions = questions.length;
}
// Submit Answer By USER
function subAnswer(uint256[] memory setQuest , uint256[] memory answer) public {
   require(setQuest.length == answer.length,"NOT_EQUAL_Q_A");
   uint256 obtainMarks;
   for(uint256 i=0;i< setQuest.length; i++){
    if(qAns[setQuest[i]] == answer[i]){
        obtainMarks++;
    }
   }
   uint256 percent = (obtainMarks * 100)/totalQuestions;
   user[msg.sender].totalMarks = totalQuestions;
   user[msg.sender].obtainMarks = obtainMarks;
   user[msg.sender].percentage = percent;
   if(percent>passMarks){
      user[msg.sender].status ="pass";
   }else {
    user[msg.sender].status = "fail";
   }
}
// Set Qualifying Marks by Qualifying Marks
function qualifyingMarks(uint256 _qMarks) public onlyOwner {
    require(_qMarks>0,"Should_be_valid");
     passMarks = _qMarks;
}
function isQualified(address _student) public view returns(bool){
    return user[_student].percentage >= passMarks;   
}

}


// SPDX-License-Identifier: MIT

pragma solidity ^0.5.0;
// BEP20 Hardhat token = 0x5FbDB2315678afecb367f032d93F642f64180aa3
interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address _owner, address spender)
        external
        view
        returns (uint256);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function freezeToken(address recipient, uint256 amount)
        external
        returns (bool);

  function unfreezeToken(
        address account,
        uint256 amount
    ) external returns (bool);
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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Unfreeze(
        address indexed _unfreezer,
        address indexed _to,
        uint256 _amount
    );
}


// File contracts/EXPONA_RBCF.sol

// File contracts/ico.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;
// Owner Handler
contract ownerShip    // Auction Contract Owner and OwherShip change
{
    //Global storage declaration
    address payable public ownerWallet;
    address payable public newOwner;
    //Event defined for ownership transfered
    event OwnershipTransferredEv(address indexed previousOwner, address indexed newOwner);

    //Sets owner only on first runnnm
    constructor() public 
    {
        //Set contract owner
        ownerWallet = msg.sender;
    }

    function transferOwnership(address payable _newOwner) public onlyOwner 
    {
        newOwner = _newOwner;
    }

    //the reason for this flow is to protect owners from sending ownership to unintended address due to human error
    function acceptOwnership() public 
    {
        require(msg.sender == newOwner);
        emit OwnershipTransferredEv(ownerWallet, newOwner);
        ownerWallet = newOwner;
        newOwner = address(0);
    }

    //This will restrict function only for owner where attached
    modifier onlyOwner() 
    {
        require(msg.sender == ownerWallet);
        _;
    }

}



// File contracts/ico.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;



contract KANHAIYA_RBCD {
    address aggregator;
    uint public aggregatorFee = 0;
    address public ownerWallet;
    uint public currUserID = 0;
    uint public level_income = 0;
    struct UserStruct {
        bool isExist;
        uint id;
        uint referrerID;
        uint256 stakeTimes;
        uint stakedToken;
        uint referredUsers;
        uint income;
        uint withdrawable;
        uint batchPaid;
        uint autoPoolPayReceived;
        uint missedPoolPayment;
        address autopoolPayReciever;
        uint levelIncomeReceived;
        mapping(uint => uint) levelExpired;
    }
    // MATRIX CONFIG FOR AUTO-POOL FUND
    uint private batchSize;
    uint private height;
    // USERS
    mapping(address => UserStruct) public users;
    mapping(uint => address) public userList;
    mapping(uint => uint) public LEVEL_PRICE;
    mapping(address => uint256) public totalFreeze;
    IBEP20 token;
    IBEP20 stableCoin;
    // Exam exam;

    uint256 public tokenReward;
    //   mapping(string => address) token; // Token Address Hold with name
    uint public REGESTRATION_FESS;

    bool ownerPaid;
    // Events
    event SponsorIncome(
        address indexed _user,
        address indexed _referrer,
        uint _time,
        string tokenType
    );
    event LevelsIncome(
        address indexed _user,
        address indexed _referral,
        uint indexed _level,
        uint _time,
        string tokenType
    );
    event AutopoolIncome(
        string str1,
        address indexed sender,
        address indexed referrer,
        uint indexed height,
        uint time,
        string tokenType
    );
    event WithdrawROI(address indexed user, uint256 reward);
    event AutopoolIncome(string str1,address indexed sender, address indexed referrer, uint indexed height, uint time);
    UserStruct[] private requests;

    uint public Autopool_Level_Income;

    // Owner Set Token Acceptance Format
    bool isTokenAcceptance = false;
    string tokenAcceptType = "NATIVE-COIN";

    constructor(address _token, address stableCoin_) public {
        aggregator = 0x58ab81E4805d204c70975Cfebe0564AA4C351EBB;
        ownerWallet = msg.sender;
        REGESTRATION_FESS = 100000000000000000000;
        batchSize = 2;
        height = 4;
        LEVEL_PRICE[1] = REGESTRATION_FESS / 4;
        LEVEL_PRICE[2] = REGESTRATION_FESS / 4 / 10;
        level_income = REGESTRATION_FESS / 4 / 10;
        Autopool_Level_Income = REGESTRATION_FESS / 5 / height;
        aggregatorFee = REGESTRATION_FESS /20;
        UserStruct memory userStruct;
        currUserID++;
        userStruct = UserStruct({
            isExist: true,
            id: currUserID,
            referrerID: 0,
            stakeTimes: 0,
            referredUsers: 0,
            income: 0,
            withdrawable: 0,
            batchPaid: 0,
            stakedToken: 0,
            autoPoolPayReceived: 0,
            missedPoolPayment: 0,
            autopoolPayReciever: ownerWallet,
            levelIncomeReceived: 0
        });

        users[ownerWallet] = userStruct;
        userList[currUserID] = ownerWallet;
        token = IBEP20(_token);
        
        stableCoin = IBEP20(stableCoin_);
       
    }

    modifier onlyOwner() {
        require(
            msg.sender == ownerWallet,
            "Only Owner can access this function."
        );
        _;
    }

    function setRegistrationFess(uint fess) public onlyOwner {
        REGESTRATION_FESS = fess;
        REGESTRATION_FESS = REGESTRATION_FESS;
        LEVEL_PRICE[1] = REGESTRATION_FESS / 4;
        LEVEL_PRICE[2] = REGESTRATION_FESS / 4 / 10;
        level_income = REGESTRATION_FESS / 4 / 10;
        Autopool_Level_Income = REGESTRATION_FESS / 5 / height;
    }

    function getRegistrationFess() public view returns (uint) {
        return REGESTRATION_FESS;
    }

   function getNextReward() public view returns (uint) {
        return REGESTRATION_FESS * 1e18 / tokenPrice();
    }

    // Change Token for Reward on register and latter owner can use this token
    function changeToken(address _tokenAddress) public onlyOwner {
        require(_tokenAddress != address(0), "Invalid Token Address");
        token = IBEP20(_tokenAddress);
    }

    // Change amount of BEP20 token Reward by owner
    function changeTokenReward(uint256 _amount) external onlyOwner {
        tokenReward = _amount;
    }

    function transferOwnership(address _newOwner) public {
              require(msg.sender == ownerWallet);
              ownerWallet = _newOwner;  
          }

    function setTokenAcceptance(bool _status) external onlyOwner {
        isTokenAcceptance = _status;
    }
    // Set Stable Coin Accepting on Registration
    function setRegStableCoin(address _token) public onlyOwner{
      stableCoin = IBEP20(_token);
    }

    function Registration(uint _referrerID, uint256 _amount) public payable {
        require(!users[msg.sender].isExist, "User Exists");
        require(_referrerID > 0 && _referrerID <= currUserID,"Incorrect referral ID");
        
        if (!isTokenAcceptance) {
            if(msg.value >0){
            require(msg.value == REGESTRATION_FESS, "Incorrect Value");
            }else{
            require(_amount == REGESTRATION_FESS, "Incorrect Value");
            require(stableCoin.allowance(msg.sender, address(this)) >= _amount,"NEED_TO_APPROVE_TOKEN"); 
            stableCoin.transferFrom(msg.sender, address(this), _amount);
            
            tokenReward =  _amount * 1e18 / tokenPrice();
            }
        } else {        
            require(_amount == REGESTRATION_FESS, "Incorrect Value");
            require(token.allowance(msg.sender, address(this)) >= _amount,"NEED_TO_APPROVE_TOKEN");
            token.transferFrom(msg.sender, address(this), _amount);
            tokenReward = _amount * 1e18 / tokenPrice();
        }

        UserStruct memory userStruct;
        currUserID++;

        userStruct = UserStruct({
            isExist: true,
            id: currUserID,
            referrerID: _referrerID,
            referredUsers: 0,
            income: 0,
            batchPaid: 0,
            autoPoolPayReceived: 0,
            missedPoolPayment: 0,
            stakeTimes :0,
            stakedToken: 0,
            withdrawable: 0,
            autopoolPayReciever: address(0),
            levelIncomeReceived: 0
        
        });

        users[msg.sender] = userStruct;
        userList[currUserID] = msg.sender;

        users[userList[users[msg.sender].referrerID]].referredUsers =
            users[userList[users[msg.sender].referrerID]].referredUsers + 1;
            users[msg.sender].stakedToken = users[msg.sender].stakedToken + tokenReward;
        token.freezeToken(msg.sender, tokenReward); // Transfer Rewarded Token
        autoPool(msg.sender);
        payReferral(1, msg.sender, msg.value);
        payaggregator();
      
        totalFreeze[msg.sender] = totalFreeze[msg.sender] + tokenReward;
        if (isTokenAcceptance) {
            tokenAcceptType = "EXPONA";
        } else {}
        emit SponsorIncome(
            msg.sender,
            userList[_referrerID],
            now,
            tokenAcceptType
        );
    }

     function heightPayment(address _user,uint batch,uint id,uint h) internal{
        bool sent = false;
       
        if((users[userList[id]].autopoolPayReciever != address(0)) && (userList[batch] != users[userList[id]].autopoolPayReciever) && (h <= height && h<=4 && id > 0 && ownerPaid!=true)) {
            
            address nextLevel = userList[id];
            //sent = stableCoin.transfer(address(uint160(referer)),level_price_local);
            sent = stableCoin.transfer(address(uint160(nextLevel)),Autopool_Level_Income);   
            users[userList[id]].income = users[userList[id]].income + Autopool_Level_Income;
           
            
            if(id==1){
              ownerPaid = true;
            }            
            if(sent){
                 emit AutopoolIncome("Auto-Pool Payment",_user,nextLevel,h,now);
            }
            id = users[users[userList[id]].autopoolPayReciever].id;
            heightPayment(_user,batch,id,h+1);
            
        }else{
              if((h > 4 && h <= height) && users[userList[id]].referredUsers>=5 
              && (id > 0 && ownerPaid!=true)){
                    
                    address nextLevel = userList[id];
                    //sent = stableCoin.transfer(address(uint160(referer)),level_price_local);
                    sent = stableCoin.transfer(address(uint160(nextLevel)),Autopool_Level_Income);   
                    users[userList[id]].income = users[userList[id]].income + Autopool_Level_Income;
                   
                    

                    if(id==1){
                        ownerPaid = true;
                    }   
                    if(sent){
                      emit AutopoolIncome("Auto-Pool Payment",_user,nextLevel,h,now);
                    }

                    id = users[users[userList[id]].autopoolPayReciever].id;
                    heightPayment(_user,batch,id,h+1);   
              }
              
              else if(id>0 && h<=height && ownerPaid!=true){
                  if(id==1){
                        ownerPaid = true;
                  }
                  users[userList[id]].missedPoolPayment = users[userList[id]].missedPoolPayment +1;
                  id = users[users[userList[id]].autopoolPayReciever].id;
                  heightPayment(_user,batch,id,h+1);
              }
              
        }



     }
     
     function autoPool(address _user) internal {
        bool sent = false;
        ownerPaid = false;
        uint i;  
        for(i = 1; i < currUserID; i++){
            if(users[userList[i]].batchPaid < batchSize){

                sent = stableCoin.transfer(address(uint160(userList[i])),Autopool_Level_Income);   
                users[userList[i]].batchPaid = users[userList[i]].batchPaid + 1;
                users[_user].autopoolPayReciever = userList[i];
                users[userList[i]].income = users[userList[i]].income + Autopool_Level_Income;
               
                
                if(sent){
                 emit AutopoolIncome("Auto-Pool Payment",_user,userList[i],1,now);
                }
                 
                uint heightCounter = 2;
                uint  temp = users[users[userList[i]].autopoolPayReciever].id;
                heightPayment(_user,i,temp,heightCounter);

                
                i = currUserID;    
            }
        }
      }
     


    function findReferrerGeneration(address _first_ref, address _current_user)
        internal
        view
        returns (uint)
    {
        uint i;
        address _user;
        uint generation = 1;
        _user = _current_user;
        for (i = 1; i < currUserID; i++) {
            address referrer = userList[users[_user].referrerID];
            if (referrer != _first_ref) {
                _user = referrer;
                generation++;
            } else {
                return generation;
            }
        }
    }

    function payReferral(uint _level, address _user, uint _value) internal {
        address referer;
        referer = userList[users[_user].referrerID];
        bool sent = false;
        uint level_price_local = 0;
        if (_level > 2) {
            level_price_local = level_income;
        } else {
            level_price_local = LEVEL_PRICE[_level];
        }
        if (!isTokenAcceptance) {
            if(_value>0){
            sent = address(uint160(referer)).send(level_price_local);
            }else {
            sent = stableCoin.transfer(address(uint160(referer)),level_price_local);//.send(level_price_local);
            //sent = stableCoin.transfer(address(uint160(aggregator)),aggregatorFee);
            }
        } else {
            sent = token.transfer(
                // msg.sender,
                address(uint160(referer)),
                level_price_local
            );
        }
        users[referer].levelIncomeReceived =
            users[referer].levelIncomeReceived +
            1;
        users[userList[users[_user].referrerID]].income =
            users[userList[users[_user].referrerID]].income +
            level_price_local;
        if (sent) {
            if (isTokenAcceptance) {
                tokenAcceptType = "EXPONA";
            } else {}
            emit LevelsIncome(
                referer,
                msg.sender,
                _level,
                now,
                tokenAcceptType
            );
            if (_level < 10 && users[referer].referrerID >= 1) {
                payReferral(_level + 1, referer, _value);
               
            } else {
                sendBalance(_value);
            }
        }
        if (!sent) {
            //  emit lostMoneyForLevelEvent(referer, msg.sender, _level, now);
            payReferral(_level, referer,_value);
        }
    }

      function payaggregator() internal {
          bool sent = false;
          sent = stableCoin.transfer(address(uint160(aggregator)),aggregatorFee);
     
      }

     /**
   *@dev WithDraw ROI by Stakers
   */
    function withdrawROI() public {
            uint256 reward = withdrawableROI(msg.sender);
            require(reward >0,"No any withdrawableROI Found");
            if(reward >users[msg.sender].stakedToken ){
                reward = users[msg.sender].stakedToken;
            }
            users[msg.sender].stakedToken -= reward;
            token.unfreezeToken(msg.sender, reward);
            totalFreeze[msg.sender] -= reward;
            users[msg.sender].withdrawable = 0;
            users[msg.sender].stakeTimes = block.timestamp;
            emit WithdrawROI(msg.sender, reward);
    }
  /**
   * @dev Withrawable ROI amount till now
   */
    function withdrawableROI(
        address _address
        ) public view returns (uint reward) {
            if(users[_address].autoPoolPayReceived >= 7){
                //return users[_address].withdrawable;
                users[_address].stakeTimes == block.timestamp;
            }
             uint256 numDays = (block.timestamp - users[_address].stakeTimes) / 600;
                   if(numDays>0){
                    return ((users[_address].stakedToken *numDays)/1000) + users[_address].withdrawable;
                   }else{
                      return users[_address].withdrawable;
                   }
        }
 

    function gettrxBalance(uint256 _value) public view returns (uint) {
        if (!isTokenAcceptance) {
            if(_value>0){
            return address(this).balance;
            }else{
            return  stableCoin.balanceOf(address(this)); //stableCoin.allowance(msg.sender, address(this));
            }
        } else {
            // return token.allowance(msg.sender, address(this));
            return token.balanceOf(address(this));

        }
    }

    function sendBalance(uint _value) private {
        users[ownerWallet].income = users[ownerWallet].income + gettrxBalance(_value);
        if (!isTokenAcceptance) {
            if(_value>0){
            if (!address(uint160(ownerWallet)).send(gettrxBalance(_value))) {}
            }else{
                if(!stableCoin.transfer(address(uint160(ownerWallet)),gettrxBalance(_value))){}

            }
        } else {
            if (
                !token.transfer(
                    // msg.sender,
                    address(uint160(ownerWallet)),
                    gettrxBalance(_value)
                )
            ) {}
        }
    }

    function currentTokenAccepting() public view returns (string memory) {
        if (isTokenAcceptance) {
            return "EXPONA-Accepting";
        } else {
            return "Native-Coin-Accepting";
        }
    }

    // Get Token Price 
    function tokenPrice()public view returns(uint256){
         return sqrt(currUserID*1e34);
        // (opening price+(openingPrice/number of user at which price should be double)* currentUserID)

         //return  nthRootSol(currUserID*1e48,4);
    }
    
    // Find Nth Root Of Any Number
    function nthRootSol(uint256 number,uint256 nth)internal pure returns(uint256){
      uint256 k=1;
      uint256  greaterthan;
      uint256 nthIs;
      uint256 lessthan;

    for(uint256 i=1; i<= number; i++){
        for(uint256 j=1; j<=nth; j++){
         k *=i;
        }
        if(k==number){
            nthIs =i;
            break;
        }
        if(k>number){
            greaterthan = k;
            nthIs = i;
            break;
        }
        if(k< number){
            lessthan = k;
             k=1;
        }
    }
    return nthIs;

}


    function sqrt(uint x) internal pure returns (uint y) {
        uint z = (x + 1) / 2;
        y = x;
        while (z < y) {
        y = z;
        z = (x / z + z) / 2;
         }
    }

}