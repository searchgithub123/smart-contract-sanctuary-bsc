/**
 *Submitted for verification at BscScan.com on 2022-08-30
*/

/**
 *Submitted for verification at BscScan.com on 2022-05-21
*/

/**

######   #######  ######   #######            ######  ##  ###           ### ###   #####   ##  ###  ######   #######  ######   ###       #####   ##  ###  ######   
### ###  ### ###  ### ###  ### ###              ##    ### ###           ### ###  ### ###  ### ###  ### ###  ### ###  ### ###  ###      ### ###  ### ###  ### ###  
### ###  ###      ### ###  ###                  ##    #######           ### ###  ### ###  #######  ### ###  ###      ### ###  ###      ### ###  #######  ### ###  
######   #####    ######   #####                ##    #######           ### ###  ### ###  #######  ### ###  #####    ######   ###      #######  #######  ### ###  
###      ###      ###      ###                  ##    ### ###           #######  ### ###  ### ###  ### ###  ###      ### ##   ###      ### ###  ### ###  ### ###  
###      ### ###  ###      ### ###              ##    ### ###           ### ###  ### ###  ### ###  ### ###  ### ###  ### ###  ###  ##  ### ###  ### ###  ### ###  
###      #######  ###      #######            ######  ### ###           ##   ##   #####   ### ###  ######   #######  ### ###  #######  ### ###  ### ###  ######   
                                                                                                                                                                  
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

interface IToken {
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

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
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

    /**
    * @dev Initializes the contract setting the deployer as the initial owner.
    */
    constructor () {
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

contract Pepe_in_Wonderland is Context, Ownable, ReentrancyGuard{
    using SafeMath for uint256;

    IToken public token_BUSD;
	// address erctoken = 0xeD24FC36d5Ee211Ea25A80239Fb8C4Cfd80f12Ee; /** BUSD Testnet **/
    address erctoken = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56; /** BUSD Mainnet **/
    
    uint256 public QUBIC_TO_HIRE_1MINERS = 2592000;
    uint256 public PERCENTS_DIVIDER = 1000;
    uint256 public REFERRAL = 100;
    uint256 public TAX = 10; // 1%
    // uint256 public BBTAX = 30;
    // uint256 public DEVTAX = 30;
    // uint256 public MKTTAX = 20;
    uint256 public AUTOTAX = 10;
    uint256 public MARKET_QUBIC_DIVISOR = 2; // 50%
    uint256 public MARKET_QUBIC_DIVISOR_SELL = 1; // 100%

    uint256 public MIN_INVEST_LIMIT = 10 * 1e18; /** 10 BUSD  **/
    uint256 public WALLET_DEPOSIT_LIMIT = 20000 * 1e18; /** 20000 BUSD  **/

	uint256 public COMPOUND_BONUS = 30; /** 3% **/
	uint256 public COMPOUND_BONUS_MAX_TIMES = 10; /** 10 times / 5 days. **/
    uint256 public COMPOUND_STEP = 12 * 60 * 60; /** every 12 hours. **/

    uint256 public WITHDRAWAL_TAX = 800; //800 = 80%, 600 = 60%, 400 = 40%
    uint256 public COMPOUND_FOR_NO_TAX_WITHDRAWAL = 10; // compound for no tax withdrawal.

    uint256 public totalStaked;
    uint256 public totalDeposits;
    uint256 public totalCompound;
    uint256 public totalRefBonus;
    uint256 public totalWithdrawn;

    uint256 public marketQubic;
    uint256 PSN = 10000;
    uint256 PSNH = 5000;
    bool public contractStarted;

	uint256 public CUTOFF_STEP = 48 * 60 * 60; /** 48 hours  **/
	uint256 public WITHDRAW_COOLDOWN = 4 * 60 * 60; /** 4 hours  **/

    address payable private owneradd;
    address public bbadr;
    address public devadr;
    address public mktadr;
    address public autoadr; /** automation  **/

    struct User {
        uint256 initialDeposit;
        uint256 userDeposit;
        uint256 miners;
        uint256 claimedQubic;
        uint256 lastCompound;
        address referrer;
        uint256 referralsCount;
        uint256 referralQubicRewards;
        uint256 totalWithdrawn;
        uint256 dailyCompoundBonus;
        uint256 lastWithdrawTime;
    }

    mapping(address => User) public users;

    address[] automate;
    mapping (address => uint256) automateIndexes;

    struct Automation {
        uint256 day;
        uint256 runhours;
        uint256 dayrun;
        uint256 lastrun;
    }

    mapping(address => Automation) public automations;


    constructor(address _bbadr, address _devadr, address _mktadr, address _autoadr) {
		require(!isContract(_bbadr) && !isContract(_devadr) && !isContract(_mktadr) && !isContract(_autoadr));
        owneradd = payable(msg.sender);
        bbadr = _bbadr;
        devadr = _devadr;
        mktadr = _mktadr;
        autoadr = _autoadr;
        token_BUSD = IToken(erctoken);
    }

	function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

    function compoundQubic(bool isCompound) public {
        User storage user = users[msg.sender];
        require(contractStarted, "Contract not yet Started.");
        require(automations[msg.sender].day < 1, "Holder is automated!");

        uint256 qubicUsed = getMyQubic();
        uint256 qubicForCompound = qubicUsed;

        if(isCompound) {
            uint256 dailyCompoundBonus = getDailyCompoundBonus(msg.sender, qubicForCompound);
            qubicForCompound = qubicForCompound.add(dailyCompoundBonus);
            uint256 qubicUsedValue = calculateQubicSell(qubicForCompound);
            user.userDeposit = user.userDeposit.add(qubicUsedValue);
            totalCompound = totalCompound.add(qubicUsedValue);
        } 

        if(block.timestamp.sub(user.lastCompound) >= COMPOUND_STEP) {
            if(user.dailyCompoundBonus < COMPOUND_BONUS_MAX_TIMES) {
                user.dailyCompoundBonus = user.dailyCompoundBonus.add(1);
            }
        }
        
        user.miners = user.miners.add(qubicForCompound.div(QUBIC_TO_HIRE_1MINERS));
        user.claimedQubic = 0;
        user.lastCompound = block.timestamp;

        marketQubic = marketQubic.add(qubicUsed.div(MARKET_QUBIC_DIVISOR));
    }

    function compoundAutoQubic(address adr, bool isCompound) internal {
        User storage user = users[adr];
         
        uint256 qubicUsed = users[adr].claimedQubic.add(getQubicSinceLastCompound(adr));
        uint256 qubicForCompound = qubicUsed;

        if(isCompound) {
            uint256 dailyCompoundBonus = getDailyCompoundBonus(adr, qubicForCompound);
            qubicForCompound = qubicForCompound.add(dailyCompoundBonus);
            uint256 qubicUsedValue = calculateQubicSell(qubicForCompound);
            qubicUsedValue = qubicUsedValue - payAuto(qubicUsedValue);
            qubicForCompound = qubicForCompound - qubicForCompound.mul(AUTOTAX).div(PERCENTS_DIVIDER);
            user.userDeposit = user.userDeposit.add(qubicUsedValue);
            totalCompound = totalCompound.add(qubicUsedValue);
        } 

        if(block.timestamp.sub(user.lastCompound) >= COMPOUND_STEP) {
            if(user.dailyCompoundBonus < COMPOUND_BONUS_MAX_TIMES) {
                user.dailyCompoundBonus = user.dailyCompoundBonus.add(1);
            }
        }
        
        user.miners = user.miners.add(qubicForCompound.div(QUBIC_TO_HIRE_1MINERS));
        user.claimedQubic = 0;
        user.lastCompound = block.timestamp;

        marketQubic = marketQubic.add(qubicUsed.div(MARKET_QUBIC_DIVISOR));
    }

      function CHANGE_OWNERSHIP(address payable value) external {
        require(msg.sender == owneradd, "Admin use only.");
        owneradd = value;
    }

    function CHANGE_BB_WALLET(address value) external {
        require(msg.sender == owneradd, "Admin use only.");
        bbadr = value;
    }

    function CHANGE_DEV_WALLET(address value) external {
        require(msg.sender == owneradd, "Admin use only.");
        devadr = value;
    }

    function CHANGE_MKT_WALLET(address value) external {
        require(msg.sender == owneradd, "Admin use only.");
        mktadr = value;
    }

    function CHANGE_AUTO_WALLET(address value) external {
        require(msg.sender == owneradd, "Admin use only.");
        autoadr = value;
    }

    function sellQubic() public{
        require(contractStarted);
        require(automations[msg.sender].day < 1, "Holder is automated!");
        User storage user = users[msg.sender];
        uint256 hasQubic = getMyQubic();
        uint256 qubicValue = calculateQubicSell(hasQubic);
        
        
            //if user compound < to mandatory compound days
        if(user.dailyCompoundBonus < COMPOUND_FOR_NO_TAX_WITHDRAWAL){
            //daily compound bonus count will not reset and qubicValue will be deducted with 80% feedback fee.
            qubicValue = qubicValue.sub(qubicValue.mul(WITHDRAWAL_TAX).div(PERCENTS_DIVIDER));
        }else{
            //set daily compound bonus count to 0 and qubicValue will remain without deductions
             user.dailyCompoundBonus = 0;   
        }
        
        user.lastWithdrawTime = block.timestamp;
        user.claimedQubic = 0;  
        user.lastCompound = block.timestamp;
        marketQubic = marketQubic.add(hasQubic.div(MARKET_QUBIC_DIVISOR_SELL));
        
        if(getBalance() < qubicValue) {
            qubicValue = getBalance();
        }

        uint256 qubicPayout = qubicValue.sub(payFees(qubicValue));
        token_BUSD.transfer(msg.sender, qubicPayout);
        user.totalWithdrawn = user.totalWithdrawn.add(qubicPayout);
        totalWithdrawn = totalWithdrawn.add(qubicPayout);
    }

    function sellAutoQubic(address adr) internal {
        User storage user = users[adr];
        uint256 hasQubic = users[adr].claimedQubic.add(getQubicSinceLastCompound(adr));
        uint256 qubicValue = calculateQubicSell(hasQubic);

        user.dailyCompoundBonus = 0;  
        user.lastWithdrawTime = block.timestamp;
        user.claimedQubic = 0;  
        user.lastCompound = block.timestamp;
        marketQubic = marketQubic.add(hasQubic.div(MARKET_QUBIC_DIVISOR_SELL));
        
        if(getBalance() < qubicValue) {
            qubicValue = getBalance();
        }

        uint256 qubicPayout = qubicValue.sub(payFees(qubicValue));
        qubicPayout = qubicPayout.sub(payAuto(qubicValue));
        token_BUSD.transfer(adr, qubicPayout);
        user.totalWithdrawn = user.totalWithdrawn.add(qubicPayout);
        totalWithdrawn = totalWithdrawn.add(qubicPayout);
    }

    function buyQubic(address ref, uint256 amount) public payable{
        require(contractStarted);
        User storage user = users[msg.sender];
        require(automations[msg.sender].day < 1, "Holder is automated!");

        require(amount >= MIN_INVEST_LIMIT, "Mininum investment not met.");
        require(user.initialDeposit.add(amount) <= WALLET_DEPOSIT_LIMIT, "Max deposit limit reached.");
        
        token_BUSD.transferFrom(address(msg.sender), address(this), amount);
        uint256 qubicBought = calculateQubicBuy(amount, getBalance().sub(amount));
        user.userDeposit = user.userDeposit.add(amount);
        user.initialDeposit = user.initialDeposit.add(amount);
        user.claimedQubic = user.claimedQubic.add(qubicBought);

        if (user.referrer == address(0)) {
            if (ref != msg.sender) {
                user.referrer = ref;
            }

            address upline1 = user.referrer;
            if (upline1 != address(0)) {
                users[upline1].referralsCount = users[upline1].referralsCount.add(1);
            }
        }
                
        if (user.referrer != address(0)) {
            address upline = user.referrer;
            if (upline != address(0)) {
                uint256 refRewards = amount.mul(REFERRAL).div(PERCENTS_DIVIDER);
                token_BUSD.transfer(upline, refRewards);
                users[upline].referralQubicRewards = users[upline].referralQubicRewards.add(refRewards);
                totalRefBonus = totalRefBonus.add(refRewards);
            }
        }

        uint256 qubicPayout = 0; /** set to 0 for 0 Buy Fees **/
        /** less the fee on total Staked to give more transparency of data. **/
        totalStaked = totalStaked.add(amount.sub(qubicPayout));
        totalDeposits = totalDeposits.add(1);
        compoundQubic(false);
    }

    function payFees(uint256 qubicValue) internal returns(uint256){
        uint256 tax = qubicValue.mul(TAX).div(PERCENTS_DIVIDER);
        token_BUSD.transfer(bbadr, tax);
        token_BUSD.transfer(devadr, tax);
        token_BUSD.transfer(mktadr, tax);
        return tax.mul(3);
    }

    function payAuto(uint256 qubicValue) internal returns(uint256){
        uint256 tax = qubicValue.mul(AUTOTAX).div(PERCENTS_DIVIDER);
         token_BUSD.transfer(autoadr, qubicValue.mul(AUTOTAX).div(PERCENTS_DIVIDER));
         return tax.mul(1);
    }

    function getDailyCompoundBonus(address _adr, uint256 amount) public view returns(uint256){
        if(users[_adr].dailyCompoundBonus == 0) {
            return 0;
        } else {
            uint256 totalBonus = users[_adr].dailyCompoundBonus.mul(COMPOUND_BONUS); 
            uint256 result = amount.mul(totalBonus).div(PERCENTS_DIVIDER);
            return result;
        }
    }

    function getUserInfo(address _adr) public view returns(uint256 _initialDeposit, uint256 _userDeposit, uint256 _miners,
     uint256 _claimedQubic, uint256 _lastCompound, address _referrer, uint256 _referrals,
	 uint256 _totalWithdrawn, uint256 _referralQubicRewards, uint256 _dailyCompoundBonus, uint256 _lastWithdrawTime) {
         _initialDeposit = users[_adr].initialDeposit;
         _userDeposit = users[_adr].userDeposit;
         _miners = users[_adr].miners;
         _claimedQubic = users[_adr].claimedQubic;
         _lastCompound = users[_adr].lastCompound;
         _referrer = users[_adr].referrer;
         _referrals = users[_adr].referralsCount;
         _totalWithdrawn = users[_adr].totalWithdrawn;
         _referralQubicRewards = users[_adr].referralQubicRewards;
         _dailyCompoundBonus = users[_adr].dailyCompoundBonus;
         _lastWithdrawTime = users[_adr].lastWithdrawTime;
	}

    function initialize(uint256 amount) public payable{
        if (!contractStarted) {
    		if (msg.sender == owneradd) {
    		    require(marketQubic == 0);
    			contractStarted = true;
                marketQubic = 86400000000;
                buyQubic(msg.sender, amount);
    		} else revert("Contract not yet started.");
    	}
    }

    function getBalance() public view returns (uint256) {
        return token_BUSD.balanceOf(address(this));
	}

    function getTimeStamp() public view returns (uint256) {
        return block.timestamp;
    }

    function getAvailableEarnings(address _adr) public view returns(uint256) {
        uint256 userQubic = users[_adr].claimedQubic.add(getQubicSinceLastCompound(_adr));
        return calculateQubicSell(userQubic);
    }

    function calculateTrade(uint256 rt,uint256 rs, uint256 bs) public view returns(uint256){
        return SafeMath.div(SafeMath.mul(PSN, bs), SafeMath.add(PSNH, SafeMath.div(SafeMath.add(SafeMath.mul(PSN, rs), SafeMath.mul(PSNH, rt)), rt)));
    }

    function calculateQubicSell(uint256 qubic) public view returns(uint256){
        return calculateTrade(qubic, marketQubic, getBalance());
    }

    function calculateQubicBuy(uint256 eth,uint256 contractBalance) public view returns(uint256){
        return calculateTrade(eth, contractBalance, marketQubic);
    }

    function calculateQubicBuySimple(uint256 eth) public view returns(uint256){
        return calculateQubicBuy(eth, getBalance());
    }

    function getQubicYield(uint256 amount) public view returns(uint256,uint256) {
        uint256 qubicAmount = calculateQubicBuy(amount , getBalance().add(amount).sub(amount));
        uint256 miners = qubicAmount.div(QUBIC_TO_HIRE_1MINERS);
        uint256 day = 1 days;
        uint256 qubicPerDay = day.mul(miners);
        uint256 earningsPerDay = calculateQubicSellForYield(qubicPerDay, amount);
        return(miners, earningsPerDay);
    }

    function calculateQubicSellForYield(uint256 qubic,uint256 amount) public view returns(uint256){
        return calculateTrade(qubic,marketQubic, getBalance().add(amount));
    }

    function getSiteInfo() public view returns (uint256 _totalStaked, uint256 _totalDeposits, uint256 _totalCompound, uint256 _totalRefBonus) {
        return (totalStaked, totalDeposits, totalCompound, totalRefBonus);
    }

    function getMyMiners() public view returns(uint256){
        return users[msg.sender].miners;
    }

    function getMyQubic() public view returns(uint256){
        return users[msg.sender].claimedQubic.add(getQubicSinceLastCompound(msg.sender));
    }

    function getQubicSinceLastCompound(address adr) public view returns(uint256){
        uint256 secondsSinceLastCompound = block.timestamp.sub(users[adr].lastCompound);
                            /** get min time. **/
        uint256 cutoffTime = min(secondsSinceLastCompound, CUTOFF_STEP);
        uint256 secondsPassed = min(QUBIC_TO_HIRE_1MINERS, cutoffTime);
        return secondsPassed.mul(users[adr].miners);
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }

    function ADD_AUTOMATE(uint256 hrs) external {
        require(contractStarted);
        require(automations[msg.sender].day == 0, "Address already exists!");
        require(hrs >= 4 && hrs <= 24, "Hours are not correct!");

        automateIndexes[msg.sender] = automate.length;
        automate.push(msg.sender);

        automations[msg.sender].day = 1;
        automations[msg.sender].runhours = hrs;
        automations[msg.sender].lastrun = block.timestamp;
        automations[msg.sender].dayrun = block.timestamp;
    }

    function REMOVE_AUTOMATE() external {
        require(contractStarted);
        require(automations[msg.sender].day >= 1, "Address doesn't exists!");
        automate[automateIndexes[msg.sender]] = automate[automate.length-1];
        automateIndexes[automate[automate.length-1]] = automateIndexes[msg.sender];
        automate.pop();
        delete automations[msg.sender];
    }

    function getAutomateCounts() public view returns(uint256) {
        return automate.length;
    }

    function runAutomate() external {
        require(msg.sender == owneradd, "Admin use only.");
        require(contractStarted);
        uint256 automateCount = automate.length;

        uint256 iterations = 0;
        while(iterations < automateCount) {
            address adr = automate[iterations];
            uint256 hasQubic = users[adr].claimedQubic.add(getQubicSinceLastCompound(adr));
            if(hasQubic > 0){
                if ((block.timestamp - automations[adr].lastrun) >= (automations[adr].runhours*3600)) {  //86400=24hrs, 3600=1hr, 7200=2hr, 10800=3rs, 14400=4hrs 21600=6hrs, 43200=12hrs, 64800=18
                    if(automations[adr].day == 7 && ((block.timestamp - automations[adr].dayrun) >= (24*3600))) {
                        automations[adr].day = 1;
                        automations[adr].lastrun = automations[adr].lastrun + (automations[adr].runhours*3600);
                        automations[adr].dayrun = automations[adr].dayrun + (24*3600);
                        sellAutoQubic(adr);
                    }
                    else {
                        if(automations[adr].day<7) {
                            compoundAutoQubic(adr,true);
                        }
                        if((block.timestamp - automations[adr].dayrun) >= (24*3600)) {
                            automations[adr].day++;
                            automations[adr].dayrun = automations[adr].dayrun + (24*3600);
                        }
                        automations[adr].lastrun = automations[adr].lastrun + (automations[adr].runhours*3600);
                    }
                }
            }
            iterations++;
        }
    }    

}