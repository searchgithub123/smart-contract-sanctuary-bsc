/**
 *Submitted for verification at BscScan.com on 2022-08-23
*/

/*
    4% fixed yield
    3% referrer bonus, 3% referee cashback 
    unstake -
        investment - profit
        50% allowed to withdraw
        50% tvl
        cannot withdraw anymore if unstaked.
        can only unstake within 7 days.

    automine - 
        user can set what % to comp and what % to Withdraw min 15% compound
        user can set 2 config, 1 default, 1 special
        special compound will be triggered instead of default when number of trigger reached
        automine will be triggered every 24 hrs

    manual compound 100% compound
        compound anytime

    manual withdraw 75% withdraw 25% compound
        withdraw anytime

    lottery - 5% of everydeposit, ticket should be 0.02
        - total pot will be splitted to 2, half is for the next round so that every round has a significant amount of rewards

    last deposit - 5% of everydeposit, 
        - total pot will be splitted to 2, half is for the next round so that every round has a significant amount of rewards

    biggest buy - 5% of everydeposit, 
        - total pot will be splitted to 2, half is for the next round so that every round has a significant amount of rewards
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;
// import "hardhat/console.sol";
contract ryker_bnb_V2 {
    bool private locked;
    bool private contractStarted;

    /** contract percentage **/
    uint256 public referralPrc = 50;
    uint256 public fixedYieldIncomePrc = 40;

    /** taxes **/
    uint256 private marketingTax = 15;
    uint256 private developmentTax = 45;
    uint256 private overIncomeTax300Prc = 800;


    /** limits **/
    uint256 private minDeposit = 0.2 ether;
    uint256 private maxIncentiveBalance = 10 ether;
    uint256 private maxWalletDepositLimit = 20 ether;

    /** time steps **/
    uint256 private cutOffTimeStep = 48 hours;
    uint256 private lotteryTimeStep = 6 hours;
    uint256 private lastDepositTimeStep = 3 hours;
    uint256 private biggestDepositTimeStep = 24 hours;   
    uint256 private unstakeDays = 7 days;

    /** event start time **/
    uint256 public LOTTERY_START_TIME;
    uint256 public LAST_DEPOSIT_START_TIME;
    uint256 public BIGGEST_DEPOSIT_START_TIME;
      
    /** event enabler **/
	bool private LOTTERY_ACTIVATED;
    bool private LAST_DEPOSIT_ACTIVATED;
    bool private BIGGEST_DEPOSIT_ACTIVATED;
    bool private AUTO_COMPOUND_ACTIVATED;
 
    uint256 public  lastDepositTotalPot = 0;
    uint256 public  currentLastDepositPot = 0;

    uint256 public  biggestDepositTotalPot = 0;
    uint256 public  currentBiggestDepositPot = 0;   
    
    uint256 private currentPot = 0;
    uint256 private currentLotteryParticipants = 0;
    uint256 private currentTotalLotteryTickets = 0;

    uint256 private totalStaked;
    uint256 private totalUnStaked;   
    uint256 private totalDeposits;
    uint256 private totalCompound;
    uint256 private totalRefBonus;
    uint256 private totalWithdrawn;
    uint256 private totalLotteryMinerBonus;
    uint256 private totalLastDepositJackpot;

    uint256 public  currentBiggestBuyRound = 1; 
    uint256 public  currentLastBuyRound = 1; 
    uint256 public  currentLotteryRound = 1;
    uint256 public  currentBiggestDepositAmount;
    
    address public  potentialLastDepositWinner;
    address public  potentialBiggestDepositWinner;
    address private owner;
    address private development;
    address private marketing;
    address private executor;

    using SafeMath for uint256;

    struct userCompounded {
        address walletAdress;
        uint256 deposit;
        uint256 timeStamp;
    }

    struct User {
        uint256 initialDeposit;
        uint256 userCompounded;
        address referrer;
        uint256 referralsCount;
        uint256 referralBonus;
        uint256 totalReceived;
        uint256 userDefaultAutoTriggerCount;
        uint256 lastWithdrawTime;
        uint256 lastActionTime;
        uint256 firstInvestmentTime;
    }

    userCompounded[] public usersCompounded;
    mapping(uint256 => address) public poolTop;
    mapping(address => User) public users;
    mapping(address => bool) public isUnstaked;
    mapping(address => bool) public isEarlyProjectSupporter;
    mapping(address => bool) public isEarlySupporterBonusReceived;
    mapping(address => uint256) public userLotteryMinerRewards;
    mapping(address => uint256) public userTopPoolReferrerMinerRewards;
    mapping(uint256 => mapping(uint256 => address)) public participantAdresses;
    mapping(uint256 => mapping(address => uint256)) public totalDepositPool;
    mapping(uint256 => mapping(address => uint256)) public ticketOwners;
    
    //compound events
    event AutoCompoundEvent(address indexed _addr, uint256 drawTime);

    //entry events
    event LastBuyEntryEvent(uint256 indexed round, address indexed userAddress, uint256 amountEntered, uint256 drawTime); 
    event BiggestBuyEntryEvent(uint256 indexed round, address indexed userAddress, uint256 amountEntered, uint256 drawTime); 

    //contest events
    event LastBuyEvent(uint256 indexed round, address indexed winner, uint256 amountRewards, uint256 minerRewards, uint256 drawTime); 
    event BiggestBuyEvent(uint256 indexed round, address indexed winner, uint256 amountRewards, uint256 minerRewards, uint256 drawTime); 
    event LotteryEvent(uint256 indexed round, address indexed investorWinner, uint256 pot, uint256 totalLotteryParticipants, uint256 totalLotteryTickets, uint256 drawTime);
    
    // constructor(address devt, address mkt, address exec) {
    constructor(address devt, address mkt) {
		require(!isContract(devt)  && !isContract(mkt) , "Not a valid user address.");
		// require(isContract(exec) , "Not a valid address.");
        owner             = msg.sender;
        development       = devt;
        marketing         = mkt;
        // executor          = exec;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier contractActivated {
        require(contractStarted, "Contract not yet Started.");
        _;
    }

    modifier nonReentrant {
        require(!locked, "No re-entrancy.");
        locked = true;
        _;
        locked = false;
    }

	function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

	function updateExecutor(address value) external onlyOwner {
        executor = value;
    }
    
    function getUserInitialDeposit(address addr) external view returns(uint256 _initialDeposit, uint256 _lastActionTime, uint256 _userDefaultAutoTriggerCount) {
        _initialDeposit = users[addr].initialDeposit;
        _lastActionTime = users[addr].lastActionTime;
        _userDefaultAutoTriggerCount = users[addr].userDefaultAutoTriggerCount;
    }

    function executeAutoCompound(address _addr, uint256 _compoundPrc,uint256 _withdrawPrc ) external contractActivated {
        require(msg.sender == executor, "Function can only be triggered by the executor.");
        require(AUTO_COMPOUND_ACTIVATED, "Auto Compound not Activated.");
        if(!isUnstaked[_addr]){
              compoundWithdrawAddress( _addr , _compoundPrc , _withdrawPrc);
              emit AutoCompoundEvent(_addr, getCurrentTime());
        }
  
        
    }

    function initializeContract(address addr) public payable onlyOwner {
        require(!contractStarted, "Contract already started.");
        contractStarted = true; 
        LOTTERY_ACTIVATED = true;
        LAST_DEPOSIT_ACTIVATED = true;
        AUTO_COMPOUND_ACTIVATED = true;
        BIGGEST_DEPOSIT_ACTIVATED = true;
        LOTTERY_START_TIME = getCurrentTime();
        LAST_DEPOSIT_START_TIME = getCurrentTime();
        BIGGEST_DEPOSIT_START_TIME = getCurrentTime();
        invest(addr);
    }

    function manualCompound() public contractActivated {
        require(users[msg.sender].initialDeposit>0, "Not a depositor");
        compoundWithdrawAddress(msg.sender, 100, 0); 
    }

    function compoundWithdrawAddress( address _address, uint256 _compoundPrc, uint256 _withdrawPrc) internal {
       uint256 validPrcChk = _compoundPrc +  _withdrawPrc;
        require(validPrcChk == 100, "invalid percentages");
        if(!isUnstaked[_address]){
             User storage user = users[_address];
            uint256 finalCompoundPrc = _compoundPrc;
            uint256 finalWithdrawPrc = _withdrawPrc;
            uint256 totEarnings = getYieldEarnings(_address);
            user.lastActionTime = getCurrentTime();

            if (finalCompoundPrc > 0){
                uint256 totCompoundEarnings = totEarnings.mul(finalCompoundPrc).div(100);
                user.userCompounded = user.userCompounded.add(totCompoundEarnings);
                // user.userDefaultAutoTriggerCount = user.userDefaultAutoTriggerCount.add(1);
                totalCompound = totalCompound.add(totCompoundEarnings);
                if (LOTTERY_ACTIVATED && totCompoundEarnings >= 0.01 ether) {
                    buyLotteryTickets(_address, totCompoundEarnings);
                }
             }

            if (finalWithdrawPrc > 0){
                uint256 totWithdrawEarnings = totEarnings.mul(finalWithdrawPrc).div(100);
                withdrawEarnings(_address,  totWithdrawEarnings);
            }
        }
    }

    function withdrawEarningsManual() public nonReentrant {
        User storage user = users[msg.sender];
        require(contractStarted, "Contract not yet Started.");
        require (user.initialDeposit > 0,"No Deposit Detected.");
        compoundWithdrawAddress(msg.sender, 20, 80); 
    }

    function unstake() public nonReentrant {
        User storage user = users[msg.sender];
        require(contractStarted, "Contract not yet Started.");
        require (user.initialDeposit > 0,"No Deposit Detected.");
        require(block.timestamp.sub(user.firstInvestmentTime) < unstakeDays, "Users cannot unstake after 5 days.");
        require (user.initialDeposit > user.totalReceived,"You already got your ROI.");
        uint256 rawAmounttoUnstake = user.initialDeposit.sub(user.totalReceived);
        uint256 finalAmounttoUnstake = rawAmounttoUnstake.mul(50).div(100);
        withdrawEarnings(msg.sender, finalAmounttoUnstake);
        user.initialDeposit = 0;
        user.referrer = address(0);
        user.referralsCount = 0;
        user.totalReceived = 0;
        user.userDefaultAutoTriggerCount = 0;
        user.lastWithdrawTime = 0;
        user.lastActionTime = 0;
        user.firstInvestmentTime = 0;
        isUnstaked[msg.sender] = true;
        totalUnStaked++;
    }
    
    function withdrawEarnings(address _address, uint256 amount) internal {
        if(!isUnstaked[_address]){
            uint256 totalPayout = amount.sub(payFees(_address,amount,true));
            users[_address].totalReceived =  users[_address].totalReceived.add(totalPayout);

            if(getContractBalance() < totalPayout) {
                totalPayout = getContractBalance();
            }

            totalWithdrawn = totalWithdrawn.add(totalPayout); 
            payable(address(_address)).transfer(totalPayout);  
        }
    }

    function invest(address ref) public payable nonReentrant {
        require(!isContract(msg.sender), "Not a user address.");
        require (!isUnstaked[msg.sender], "already unstaked");
            User storage user = users[msg.sender];
            bool isRedeposit;
            uint256 amount = msg.value;
            if(user.initialDeposit > 0) {
                isRedeposit = true;  
            }
         
            require(amount >= minDeposit, "Mininum investment not met.");
            require(user.initialDeposit.add(amount) <= maxWalletDepositLimit, "Max deposit limit reached.");
         
            if(isRedeposit){
                uint256 totEarnings = getYieldEarnings(msg.sender);
                uint256 totalPayout = totEarnings.sub(payFees(msg.sender,totEarnings, true));
                amount = amount.add(totalPayout);
                totalCompound = totalCompound.add(totalPayout);
            }
            else{
                totalDeposits = totalDeposits.add(1); 
                user.firstInvestmentTime = block.timestamp;
            }

            user.userCompounded = user.userCompounded.add(amount);
            user.initialDeposit = user.initialDeposit.add(amount);

            user.lastActionTime = getCurrentTime();

            uint256 netPayout = payFees(msg.sender,amount, false);
            totalStaked = totalStaked.add(amount.sub(netPayout));

            if(LOTTERY_ACTIVATED) {
                if(getCurrentTime().sub(LOTTERY_START_TIME) >= lotteryTimeStep || currentLotteryParticipants >= 200 || currentPot >= maxIncentiveBalance) {
                    drawLotteryWinner();
                }
                buyLotteryTickets(msg.sender, amount);   
            }

            if(LAST_DEPOSIT_ACTIVATED) {
                if(getCurrentTime().sub(LAST_DEPOSIT_START_TIME) >= lastDepositTimeStep && currentLastDepositPot > 0 && potentialLastDepositWinner != address(0)) {
                    drawLastDepositWinner();
                }
                lastDepositEntry(msg.sender, amount);
            }
            if(BIGGEST_DEPOSIT_ACTIVATED) {
                if(getCurrentTime().sub(BIGGEST_DEPOSIT_START_TIME) >= biggestDepositTimeStep && currentBiggestDepositPot > 0 && potentialBiggestDepositWinner != address(0)) {
                    drawLastDepositWinner();
                }
                biggestDepositEntry(msg.sender, amount);
            }

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
                if (upline != address(0) && users[upline].initialDeposit > 0) {
                    uint256 referralRewards = amount.mul(referralPrc).div(1000).div(2);
             
                    payable(address(upline)).transfer(referralRewards);
                    payable(address(msg.sender)).transfer(referralRewards);

                    users[upline].referralBonus = users[upline].referralBonus.add(referralRewards);
                    user.referralBonus = user.referralBonus.add(referralRewards);

                    totalRefBonus = totalRefBonus.add(referralRewards);
                }
            }
        isDepositBonus();
    }
    
    function isDepositBonus() private contractActivated {    
        if (users[msg.sender].initialDeposit > 0){
            if(isEarlyProjectSupporter[msg.sender] && !isEarlySupporterBonusReceived[msg.sender]){
                users[msg.sender].userCompounded = users[msg.sender].userCompounded.add(0.02 ether);
                isEarlyProjectSupporter[msg.sender] = false;
                isEarlySupporterBonusReceived[msg.sender] = true;
            }
        }
    } 

    function setEarlySupporterAddress(address[] memory addr) public onlyOwner {
        for(uint256 i = 0; i < addr.length; i++){
            isEarlyProjectSupporter[addr[i]] = true;
        }
    }

    function chooseWinners() external {
        require(msg.sender == executor || msg.sender == owner, "Not Executor Address.");
        if(LOTTERY_ACTIVATED && (getCurrentTime().sub(LOTTERY_START_TIME) >= lotteryTimeStep || currentLotteryParticipants >= 200 || currentPot >= maxIncentiveBalance)) {
            drawLotteryWinner();
        }
    
        if(LAST_DEPOSIT_ACTIVATED && getCurrentTime().sub(LAST_DEPOSIT_START_TIME) >= lastDepositTimeStep && currentLastDepositPot > 0 && potentialLastDepositWinner != address(0)) {
            drawLastDepositWinner();
        }

        if(BIGGEST_DEPOSIT_ACTIVATED && getCurrentTime().sub(BIGGEST_DEPOSIT_START_TIME) >= biggestDepositTimeStep && currentBiggestDepositPot > 0 && potentialBiggestDepositWinner != address(0)) {
            drawBiggestDepositWinner();
        }
        
    }   
  
    function checkWinnersTime() external view returns (bool) {
        bool isTimeForWinners;
        if(LOTTERY_ACTIVATED && (getCurrentTime().sub(LOTTERY_START_TIME) >= lotteryTimeStep || currentLotteryParticipants >= 200 || currentPot >= maxIncentiveBalance)) {
           isTimeForWinners = true;
        }
    
        if(LAST_DEPOSIT_ACTIVATED && getCurrentTime().sub(LAST_DEPOSIT_START_TIME) >= lastDepositTimeStep && currentLastDepositPot > 0 && potentialLastDepositWinner != address(0)) {
            isTimeForWinners = true;
        }

        if(BIGGEST_DEPOSIT_ACTIVATED && getCurrentTime().sub(BIGGEST_DEPOSIT_START_TIME) >= biggestDepositTimeStep && currentBiggestDepositPot > 0 && potentialBiggestDepositWinner != address(0)) {
          isTimeForWinners = true;
        }
        return isTimeForWinners;
    }

    function lastDepositEntry(address userAddress, uint256 amount) private {
        if(!LAST_DEPOSIT_ACTIVATED || userAddress == owner) return;

        uint256 share = amount.mul(50).div(1000);

        if(lastDepositTotalPot.add(share) > maxIncentiveBalance){       
            lastDepositTotalPot += maxIncentiveBalance.sub(lastDepositTotalPot);
        }
        else{
            lastDepositTotalPot += share;
        }
      
        currentLastDepositPot = lastDepositTotalPot.div(2);
        LAST_DEPOSIT_START_TIME = getCurrentTime();

        potentialLastDepositWinner = userAddress;
        emit LastBuyEntryEvent(currentLastBuyRound, potentialLastDepositWinner,  amount,  LAST_DEPOSIT_START_TIME); 
    }

    function drawLastDepositWinner() private {
        uint256 reward = currentLastDepositPot;
        withdrawEarnings(potentialLastDepositWinner,reward);

        emit LastBuyEvent(currentLastBuyRound, potentialLastDepositWinner, reward, 0, getCurrentTime());

        totalLastDepositJackpot = totalLastDepositJackpot.add(currentLastDepositPot);
        lastDepositTotalPot = lastDepositTotalPot.sub(currentLastDepositPot);
        currentLastDepositPot = 0;
        potentialLastDepositWinner = address(0);
        LAST_DEPOSIT_START_TIME = getCurrentTime(); 
        currentLastBuyRound++;
    }

    function biggestDepositEntry(address userAddress, uint256 amount) private {
        uint256 share = amount.mul(50).div(1000);

        if(!BIGGEST_DEPOSIT_ACTIVATED || userAddress == owner) return;

        if(biggestDepositTotalPot.add(share) > maxIncentiveBalance){       
            biggestDepositTotalPot += maxIncentiveBalance.sub(biggestDepositTotalPot);
        }
        else{
            biggestDepositTotalPot += share;
        }
      
        currentBiggestDepositPot = biggestDepositTotalPot.div(2);

        if(amount>currentBiggestDepositAmount){
            currentBiggestDepositAmount = amount;
            potentialBiggestDepositWinner = userAddress;
            emit BiggestBuyEntryEvent(currentBiggestBuyRound, potentialBiggestDepositWinner, amount, getCurrentTime()); 
        }
    }

    function drawBiggestDepositWinner() private {

        uint256 reward = currentBiggestDepositPot;
        withdrawEarnings(potentialLastDepositWinner,reward);

        emit BiggestBuyEvent(currentBiggestBuyRound, potentialBiggestDepositWinner, reward, 0, getCurrentTime());

        biggestDepositTotalPot = biggestDepositTotalPot.sub(currentBiggestDepositPot);
        currentBiggestDepositPot = 0;
        potentialBiggestDepositWinner = address(0);

        BIGGEST_DEPOSIT_START_TIME = getCurrentTime(); 
        currentBiggestBuyRound++;
    }    

    function buyLotteryTickets(address userAddress, uint256 amount) private {
        require(amount != 0, "zero purchase amount");
        uint256 userTickets = ticketOwners[currentLotteryRound][userAddress];
        uint256 maxLotteryTicket = 50;
        uint256 numTickets = amount.div(0.01 ether);
        if(userAddress == owner) return;

        if(userTickets == 0) {
            participantAdresses[currentLotteryRound][currentLotteryParticipants] = userAddress;

            if(numTickets > 0){
              currentLotteryParticipants = currentLotteryParticipants.add(1);
            }
        }

        if (userTickets.add(numTickets) > maxLotteryTicket) {
            numTickets = maxLotteryTicket.sub(userTickets);
        }

        ticketOwners[currentLotteryRound][userAddress] = userTickets.add(numTickets);
        uint256 addToPot = amount.mul(5).div(1000);
        
        if(currentPot.add(addToPot) > maxIncentiveBalance) {       
            currentPot += maxIncentiveBalance.sub(currentPot);
        }
        else{
            currentPot += addToPot;
        }

        currentTotalLotteryTickets = currentTotalLotteryTickets.add(numTickets);
    }

    function drawLotteryWinner() private contractActivated {

        if(currentLotteryParticipants > 0){
            uint256[] memory init_range = new uint256[](currentLotteryParticipants);
            uint256[] memory end_range = new uint256[](currentLotteryParticipants);

            uint256 last_range = 0;

            for(uint256 i = 0; i < currentLotteryParticipants; i++){
                uint256 range0 = last_range.add(1);
                uint256 range1 = range0.add(ticketOwners[currentLotteryRound][participantAdresses[currentLotteryRound][i]].div(1e18));

                init_range[i] = range0;
                end_range[i] = range1;
                last_range = range1;
            }

            uint256 random = getRandomValue().mod(last_range).add(1);
 
            for(uint256 i = 0; i < currentLotteryParticipants; i++){
                if((random >= init_range[i]) && (random <= end_range[i])){
                    address winnerAddress = participantAdresses[currentLotteryRound][i];
                    uint256 reward  = currentPot.sub(payFees(winnerAddress,currentPot,false));
                    reward = reward.mul(8).div(10); 
                    
                    userLotteryMinerRewards[winnerAddress] = userLotteryMinerRewards[winnerAddress].add(reward);
                    totalLotteryMinerBonus = totalLotteryMinerBonus.add(reward);
                    withdrawEarnings(winnerAddress, reward);

                    emit LotteryEvent(currentLotteryRound, winnerAddress, reward, currentLotteryParticipants, currentTotalLotteryTickets, getCurrentTime());

                    currentPot = 0;
                    currentLotteryParticipants = 0;
                    currentTotalLotteryTickets = 0;
                    LOTTERY_START_TIME = getCurrentTime();
                    currentLotteryRound++;
                    break;
                }
            }
        }
        else{
            LOTTERY_START_TIME = getCurrentTime();
        }
    }

    function getRandomValue() private view returns(uint256) {
        bytes32 _blockhash = blockhash(block.number - 1);
        return uint256(keccak256(abi.encode(_blockhash, getCurrentTime(), currentPot, block.difficulty, currentLastDepositPot, getContractBalance())));
    }

    function payFees(address _address, uint256 eggValue, bool isSell) internal returns(uint256) {
        uint256 devtTax = eggValue.mul(developmentTax).div(1000);
        uint256 marketTax = eggValue.mul(marketingTax).div(1000);
        payable(address(development)).transfer(devtTax);
        payable(address(marketing)).transfer(marketTax);
        
        uint256 totalTax =  devtTax.add(marketTax);
       
        if(!isSell){
            return totalTax; 
        }
        else{
 
            uint256 overIncomeTax;
            uint256 amountAfterDevTax = eggValue.sub(totalTax);
            User storage user = users[_address];
            // enhancement here fo overincome

            uint256 overIncomeThresHold = user.initialDeposit.mul(30).div(10);
            uint256 amtToBeTaxed;
            uint256 totalReceivedAndforWithdraw = user.totalReceived.add(amountAfterDevTax);
 
            if( totalReceivedAndforWithdraw > overIncomeThresHold ){ 
          
                    if(overIncomeThresHold > user.totalReceived){
                
                        amtToBeTaxed = totalReceivedAndforWithdraw.sub(overIncomeThresHold);
                        overIncomeTax = amtToBeTaxed.mul(overIncomeTax300Prc).div(1000);
                  
                   }else{
                        overIncomeTax = amountAfterDevTax.mul(overIncomeTax300Prc).div(1000);
                   }
            }
            return totalTax.add(overIncomeTax);
        }
    }





    
    function getYieldEarnings(address adr) public view returns(uint256) {
        User storage user = users[adr];
        uint256 totalDeposit = user.userCompounded;
        uint256 lastActionTime = user.lastActionTime;
        uint256 totalYieldEarnings;
        uint256 curTime = getCurrentTime();
        uint256 share = totalDeposit.mul(fixedYieldIncomePrc).div(1000);
        uint256 timeElapsed = curTime.sub(lastActionTime);
        if (timeElapsed > cutOffTimeStep){
            timeElapsed = cutOffTimeStep;
        }
        if(totalDeposit > 0){
            
            totalYieldEarnings = share.mul(timeElapsed).div(24 hours);
        }

        return totalYieldEarnings;
    }
    
    function getLotteryInfo() public view returns (uint256 lotteryStartTime,  uint256 lotteryStep, uint256 lotteryCurrentPot,
	  uint256 lotteryParticipants, uint256 maxLotteryParticipants, uint256 totalLotteryTickets, uint256 lotteryTicketPrice, 
      uint256 maxLotteryTicket, uint256 lotteryPercent, uint256 round) {
		lotteryStartTime = LOTTERY_START_TIME;
		lotteryStep = lotteryTimeStep;
		lotteryTicketPrice = 3 ether;
		maxLotteryParticipants = 200;
		round = currentLotteryRound;
		lotteryCurrentPot = currentPot;
		lotteryParticipants = currentLotteryParticipants;
	    totalLotteryTickets = currentTotalLotteryTickets;
        maxLotteryTicket = 50;
        lotteryPercent = 5;
	}

    function getUserTickets(address _userAddress) public view returns(uint256) {
         return ticketOwners[currentLotteryRound][_userAddress];
    }

    function getLotteryTimer() public view returns(uint256) {
        return LOTTERY_START_TIME.add(lotteryTimeStep);
    }

    function getUserInfo(address _adr) external view returns(uint256 _initialDeposit, uint256 _userCompounded, address _referrer, 
        uint256 _referrals, uint256 _totalReceived, uint256 _referralBonus, uint256 _userDefaultAutoTriggerCount, 
        uint256 _lastWithdrawTime,uint256 _fixedlastActionTime,uint256 _lotteryMinerRewards) {
        _initialDeposit = users[_adr].initialDeposit;
        _userCompounded = users[_adr].userCompounded;
        _referrer = users[_adr].referrer;
        _referrals = users[_adr].referralsCount;
        _totalReceived = users[_adr].totalReceived;
        _referralBonus = users[_adr].referralBonus;
        _userDefaultAutoTriggerCount = users[_adr].userDefaultAutoTriggerCount;
        _lastWithdrawTime = users[_adr].lastWithdrawTime;
        _fixedlastActionTime = users[_adr].lastActionTime;
        _lotteryMinerRewards = userLotteryMinerRewards[_adr];
	}
    
    function getContractBalance() public view returns(uint256) {
       return address(this).balance;
    }

    function getSiteInfo() public view returns (uint256 _totalStaked, uint256 _totalDeposits, uint256 _totalCompound, uint256 _totalRefBonus, uint256 _totalTopPoolReferrerMinerBonus, uint256 _totalLastDepositJackpot) {
        return (totalStaked, totalDeposits, totalCompound, totalRefBonus, totalLotteryMinerBonus, totalLastDepositJackpot);
    }

    function calculateDailyEarningsFromFixedYield(address _adr) public view  returns(uint256 yield) {
        User storage user = users[_adr];
        if(user.initialDeposit > 0){
            return yield = user.userCompounded.mul(fixedYieldIncomePrc).div(1000);
        }
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }


    /** fixed yield earnings 1% to 2% every month. **/
    function SET_FIXED_YIELD_INCOME_PRC(uint256 value) external onlyOwner {
        require(value >= 10 && value <= 20); /** min 1% max 2%**/
        fixedYieldIncomePrc = value;
    }

    /** lottery enabler **/
    function ENABLE_LOTTERY(bool value) external onlyOwner {
        require(contractStarted, "Contract not yet Started.");
        //run existing event regardless of requirement before changing variable value.
        if(LOTTERY_ACTIVATED){
            drawLotteryWinner();
        }

        if(value){
            LOTTERY_ACTIVATED = true;
            LOTTERY_START_TIME = getCurrentTime();
        }
        else{
            drawLotteryWinner();
            LOTTERY_ACTIVATED = false;                 
        }
    }
    function ENABLE_BIGGEST_DEPOSIT(bool value) external onlyOwner {
        require(contractStarted, "Contract not yet Started.");
    

        if(BIGGEST_DEPOSIT_ACTIVATED && getCurrentTime().sub(BIGGEST_DEPOSIT_START_TIME) >= biggestDepositTimeStep && currentBiggestDepositPot > 0 && potentialBiggestDepositWinner != address(0)) {
            drawBiggestDepositWinner();
        }

        if(value){
            BIGGEST_DEPOSIT_ACTIVATED = true;
            BIGGEST_DEPOSIT_START_TIME = getCurrentTime();
        }
        else{
            drawLotteryWinner();
            BIGGEST_DEPOSIT_ACTIVATED = false;                 
        }
    }




    /** last deposit rewards enabler **/
    function ENABLE_LAST_DEPOSIT_REWARDS(bool value) external onlyOwner {
        require(contractStarted, "Contract not yet Started.");
        //run existing event regardless of requirement before changing variable value.
        if(LAST_DEPOSIT_ACTIVATED && getCurrentTime().sub(LAST_DEPOSIT_START_TIME) >= lastDepositTimeStep && currentLastDepositPot > 0 && potentialLastDepositWinner != address(0)) {
            drawLastDepositWinner();
        }

        if(value){
            LAST_DEPOSIT_ACTIVATED = true;
            LAST_DEPOSIT_START_TIME = getCurrentTime();
        }
        else{
            LAST_DEPOSIT_ACTIVATED = false;                 
        }
    }
    
    /** auto compound enabler **/
    function ENABLE_AUTO_COMPOUND(bool value) external onlyOwner {
        require(contractStarted, "Contract not yet Started.");
        AUTO_COMPOUND_ACTIVATED = value;
    }

    /** renounce ownership **/
    function renounceOwnership() public onlyOwner {
        owner = address(0);
    }

    /** transfer ownership **/
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        owner = newOwner;
    }


  

    bool private isTest = false;
    uint256 private currentTestTime;
    function getCurrentTime() public view returns(uint256) {
        if(isTest){
            return block.timestamp.add(currentTestTime);
        }
        else{
            return block.timestamp;
        }
    }
    function setTestTime(uint256 time) public {
        isTest= true;
        currentTestTime += time;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval( address indexed owner, address indexed spender, uint256 value );
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) return 0;

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