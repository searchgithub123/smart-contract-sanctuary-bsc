// SPDX-License-Identifier: MIT


pragma solidity ^0.8.16;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./ICampaignFactory.sol";
import "./SafeERC20.sol";

contract Campaign{

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    enum Status{
        notVerifiedByManager,
        verifiedByManager,
        fundRaising,
        fundRaisingFailed,
        projectInProgress,
        paymentRequestWaiting,
        projectFinished,
        paused
    }

    struct PaymentRequest {
	        string description;
	        uint256 value;
	        bool complete;
	        uint approvalCount;
            bool active;
	    }

    struct ReplaceRequest {
        uint256 price;
        uint256 _investingAmount;
        address currentInvestor;
        bool replaced;
        bool active;
    }

    address payable public creator;
    address payable public buyer;
    address payable[] public investors;
    address public befunderManager; 
    address public befunderRep;
    address[] public approvers;
    IERC20 public Token;
    ICampaignFactory public campaignFactoryContract;
    uint256 public fundingPeriod;
    uint256 public goalAmount;
    uint256 public interestRate;
    string public title;
    string public description;
    string public fileName;
    uint256 public totalFund = 0;
    uint256 public numRequest = 0;
    uint256 public numReplaceRequest = 0;
    mapping(address => uint256) public investorsAmount;
    mapping(address => bool) public investorsList; // should be private
    mapping(address => uint256) public investorsInterest;
    mapping(uint256 => mapping(address => bool)) public requestsApproversLists;
    mapping(address => uint256[]) investorsReplaceRequest;
    uint256 public investorsCount = 0;
    uint256 public platformFee; 
    uint256 public prepaymentPercentage;
    uint256 public currentBalance;
    uint256 public fullFund;
    uint256 public milestoneNum;
    uint256 public projectEndTimeStamp = 0;
    uint256 public projectStartTimeStamp = 0;
    uint256 public fundingStartPoint;
    uint256 public fundingEndPoint;
    uint256 public totalInterest = 0;
    uint256 public confirmedRequests = 0;
    uint256 public withdrawCount = 0;
    uint256 public feeMax = 1000; // maximum 10 * 100 (for fraction) 
    bool public buyerApproved = false;
    bool public managerApproved = false;
    bool public projectComplete = false;
    bool public prepaymentPaid = false;
    bool public pause = false;
    bool public finishCheck = false;
    bool public lastRequest;
    bool public campaignTerminated = false;

    PaymentRequest[] public requests;
    ReplaceRequest[] public replaceRequests;
    bool internal locked;
    
    modifier nonReentrant() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }

    modifier isCreator() {
	        require(creator == msg.sender, "you are not the project creator.");
	        _;
	    }

    modifier isInvestor(){
        require(investorsList[msg.sender] == true, "You are not investor.");
        _;
    }

    modifier isBuyer(){
        require(buyer == msg.sender, "you are not the buyer.");
        _;
    }

    modifier isPaused(){
        require(pause == false, "project paused.");
        _;
    }

    modifier isManager(){
        require(befunderManager == msg.sender, "you are not the manager.");
        _;
    }

    // event milestonePaymentRequest(string titleOfProject, address addressOfCampaign, address addressOfCreator,
    //  uint256 paymentValue);
    // event replaceRerquest(string titleOfProject, address addressOfCampaign, address addressOfIvestor,
    //      uint256 priceForSell, uint256 investedValue);
    // event approvedByManager(address addressOfCampaign, address addressOfBuyer, address addressOfCeator,
    //     string titleOfProject, uint256 projectTotalFund );

    constructor (address payable projectCreator, address payable projectBuyer, uint256 _fundingPeriod, 
                uint256 projectTotalFund, string memory projecTitle, string memory projectDescription,
                string memory _fileName, uint256 prepaymentPerc, 
                uint256 milestones, address manager, address ERC20Token) {
        creator = projectCreator;
        buyer = projectBuyer;
        fundingPeriod = _fundingPeriod; // in hours
        fullFund = projectTotalFund;
        goalAmount = (fullFund * 80)/100;
        title = projecTitle;
        prepaymentPercentage = prepaymentPerc;
        currentBalance = 0;
        Token = IERC20(ERC20Token);
        campaignFactoryContract = ICampaignFactory(msg.sender);
        milestoneNum = milestones;
        befunderManager = manager;
        description = projectDescription;
        fileName = _fileName;
        if (milestoneNum == 1){
            lastRequest = true;
        } else {
            lastRequest = false;
        }
    }

    function isFundingFinished() public view returns (bool){
		bool Finished = false;

        if (buyerApproved) {
            if (block.timestamp > fundingEndPoint){
                Finished = true;
            }
            if (totalFund >= goalAmount){
                Finished = true;
            }
        }
			
        return Finished;
	}
        
    function isFundingSuccessful() public view returns (bool){
        bool successful = false;
        if (isFundingFinished()) {
            if (totalFund >= goalAmount){
                successful = true;
            } 
        }
        return successful;
    }

    function getPaymentRequests() public view returns(PaymentRequest[] memory) {
        return requests;
    }

    function managerApprove(address repWallet, uint256 fee) external isManager isPaused {
        require(!managerApproved, "the campaign already approved.");
        managerApproved = true;
        befunderRep = repWallet;
        require(fee <= feeMax, "platform fee exceeds the maximum allowed");
        platformFee = fee;
        campaignFactoryContract.updatePendingList(address(this));
    }

    function managerTransfer(address newManager) public isManager{
        befunderManager = newManager;
    }

    function projectPause() external isManager{
        if (pause){
            pause = false;
        } else {
            pause = true;
        }
    }

    function changeRepWallet(address newWallet) external isManager isPaused {
        befunderRep = newWallet;
    }
    
    function buyerApprove() external isBuyer isPaused{
        require(managerApproved, "the project is not approved by the manager yet.");
        buyerApproved = true;
        fundingStartPoint = block.timestamp;
        fundingEndPoint = fundingStartPoint + fundingPeriod * 1 hours;
    }

    function maxInvest() public view returns(uint256){
        uint256 maximumInvestment = (goalAmount - totalFund);
        return maximumInvestment;
    }

    function contribute(uint256 amount) external nonReentrant isPaused{
        require(buyerApproved, "the project is not approved by the buyer");
        require(!isFundingFinished(), "Funding closed");
        require(amount > 0, "the investment amount must be bigger than zero");
        require(amount <= maxInvest(), "the money is beyond the maximum possible evalue.");
        Token.safeTransferFrom(msg.sender, address(this), amount);
        investorsAmount[msg.sender] += amount;
        totalFund += amount;
        currentBalance = totalFund;
        if (!investorsList[msg.sender]){
            investors.push(payable(msg.sender));
            investorsList[msg.sender] = true;
            investorsCount++;
            campaignFactoryContract.updateInvestorInfo(msg.sender, address(this), 1);
        }
           
    }


    function createRequest(string memory requestDesc, uint256 value) internal {
        PaymentRequest memory newRequest = PaymentRequest({
            description: requestDesc,
            value: value,
            complete: false,
            approvalCount: 0,
            active: true
        });
        
        requests.push(newRequest);
        numRequest ++;
        if (numRequest > 1){
            for (uint256 i = 0; i < (numRequest - 1); i++){
                PaymentRequest storage previousRequest = requests[i];
                previousRequest.active = false;
            }
        }
    }

    function createReplaceRequest(uint256 value, uint256 principal, address investor) internal {
        ReplaceRequest memory new_ReplaceRequest = ReplaceRequest({
            price: value,
            _investingAmount: principal,
            currentInvestor: investor,
            replaced: false,
            active: true
        });
        replaceRequests.push(new_ReplaceRequest);
        investorsReplaceRequest[investor].push(numReplaceRequest);
        numReplaceRequest ++;
    }

    function investorReplaceRequestIndex(address investorAddress) public view returns(uint256[] memory){
        require(investorsList[investorAddress], "not investor!");
        return investorsReplaceRequest[investorAddress];
    }

    function removeReplaceRequest(uint256 index) external isInvestor isPaused{
        ReplaceRequest storage _replaceRequest = replaceRequests[index];
        require(_replaceRequest.currentInvestor == msg.sender, "you can not remove this request.");
        _replaceRequest.active = false;
    }

    function paymentRequestForMilestone(string memory desc, uint256 value) external isCreator isPaused{
        require(prepaymentPaid, "prepayment should be paid first.");
        if (!lastRequest){
            require(value < currentBalance, "The amount should be less that the contract balance.");
        }else {
            require(value == currentBalance, "The amount should be equal to the contract balance.");
        }
        require(buyerApproved, "the project is not approved by the buyer");
        require(confirmedRequests < milestoneNum, "you can not request more.");
        if (confirmedRequests == (milestoneNum - 1)){
            uint256 payValue = currentBalance;
            createRequest(desc, payValue);
        } else{
            createRequest(desc, value);
        }
        
    }


    function replaceRequest(uint256 sellPrice) external isInvestor isPaused{
        require(isFundingFinished(), "Funding is not finished yet.");
        require(isFundingSuccessful(), "Funding was not finished successfully.");
        require(!projectComplete, "project is finished.");
        uint256 investedAmount = investorsAmount[msg.sender];
        createReplaceRequest(sellPrice, investedAmount, msg.sender);
    }


    function getReplaceRequestsList() external view returns(ReplaceRequest[] memory){
        return replaceRequests;
    }

    function getReplaceRequestsflag() public view returns(bool check){
        check = false;
        if (isFundingFinished() && isFundingSuccessful() && !projectComplete){
            if (replaceRequests.length > 0){
                for (uint256 i=0; i < replaceRequests.length; i++){
                    if (replaceRequests[i].active && !replaceRequests[i].replaced){
                        check = true;    
                    }
                }
            }
            
        }
    }


    function approveRequest(uint256 index) external isInvestor isPaused{
        PaymentRequest storage request = requests[index];
        require(request.active, "inactive request");
        require(!requestsApproversLists[index][msg.sender], "you already approved the request.");
        requestsApproversLists[index][msg.sender] = true;
        request.approvalCount++;
    }

    function userApproveRequestCheck(uint256 index, address userAddress) external view returns(bool){
        return requestsApproversLists[index][userAddress];
    }

    function finalizeRequest(uint256 index) external isBuyer nonReentrant isPaused{
        //finalizing request
        PaymentRequest storage request = requests[index];
        require(request.active, "inactive request");
        require(!request.complete, "the request already completed.");
        require(request.approvalCount > (investorsCount / 2));
        require(currentBalance >= request.value, "not enough fund.");
        currentBalance -= request.value;
        Token.safeTransfer(creator, request.value);
        request.active = false;
        request.complete = true;
        confirmedRequests ++;
        if (confirmedRequests == (milestoneNum - 1)){
            lastRequest = true;
        }

        if (confirmedRequests == milestoneNum) {
            finishCheck = true;
        }
    }

    function prepayment() external isCreator nonReentrant isPaused{
        require(!prepaymentPaid, "Prepayment is paid already");    
        require(isFundingFinished(), "Funding is not closed.");
        require(isFundingSuccessful(), "Funding failed.");
        require(buyerApproved, "the project is not approved by the buyer");
        uint256 platformTokenBalance = (fullFund * platformFee)/(10000);
        Token.safeTransfer(befunderRep, platformTokenBalance);
        currentBalance  = totalFund - platformTokenBalance;
        uint256 prepaymentValue = (currentBalance * prepaymentPercentage)/(10000);
        require(currentBalance >= prepaymentValue, "not enough fund.");
        currentBalance -= prepaymentValue;
        Token.safeTransfer(creator, prepaymentValue);
        prepaymentPaid = true;
        projectStartTimeStamp = block.timestamp;
    }

    function projectCompleted() external isBuyer nonReentrant isPaused{
        require(isFundingFinished(), "Funding is not finished.");
        require(isFundingSuccessful(), "Funding failed.");
        require(!projectComplete, "Project already completed");
        require(finishCheck, "project not finished!");
        projectComplete = true;
        Token.safeTransferFrom(msg.sender, address(this), fullFund);
        projectEndTimeStamp = block.timestamp; 
        uint256 numDays = (projectEndTimeStamp - projectStartTimeStamp)/86400;
        if (numDays <= 150){
            interestRate = 5;
        } else if ((numDays > 150) && (numDays <= 180)){
            interestRate = 6;
        } else if ((numDays > 180) && (numDays <= 240)){
            interestRate = 7;
        } else if ((numDays > 240) && (numDays <= 300)){
            interestRate = 9;
        } else if ((numDays > 300) && (numDays <= 365)){
            interestRate = 10;
        } else if ((numDays > 365) && (numDays <= 540)){
            interestRate = 12;
        } else if ((numDays > 540) && (numDays <= 720)){
            interestRate = 20;
        }
       
        for (uint256 i=0; i < investors.length; i++){
            if (investorsList[investors[i]]){
                uint256 principalMoney = investorsAmount[investors[i]];
                uint256 interestedMoney = (interestRate * numDays * principalMoney)/(100 * 360);
                uint256 maxIinterestedMoney = (interestRate * 720 * principalMoney)/(100 * 360);
                if (interestedMoney > maxIinterestedMoney){
                    interestedMoney = maxIinterestedMoney;
                }
                totalInterest += interestedMoney;
                investorsInterest[investors[i]] = (interestedMoney);
            }
        }

        uint256 remainedFund = fullFund - (totalInterest + goalAmount);
        if (remainedFund > 0) {
            Token.safeTransfer(creator, remainedFund);
        }            
    }


    function replace(uint256 index_2) external nonReentrant isPaused{
        require(isFundingFinished(), "Funding is not finished.");
        require(isFundingSuccessful(), "funding is not finished successfully.");
        require(!projectComplete, "project is finished.");
        require(!pause, "project is paused.");
        ReplaceRequest storage _replaceRequest = replaceRequests[index_2];
        require(_replaceRequest.active, "the request is no longer available.");
        address currentInvestorAddress = _replaceRequest.currentInvestor;
        require(investorsList[currentInvestorAddress], "not an investor");
        uint256 price = _replaceRequest.price;
        uint256 investedMoney = investorsAmount[currentInvestorAddress];
        require(Token.balanceOf(msg.sender) >= (investedMoney + price), "not enough fund.");
        Token.safeTransferFrom(msg.sender, currentInvestorAddress, price);
        Token.safeTransferFrom(msg.sender, address(this), investedMoney);
        investorsAmount[msg.sender] += investedMoney;
        if (!investorsList[msg.sender]){
            investorsList[msg.sender] = true;    
            investors.push(payable(msg.sender));
            investorsCount++;
            campaignFactoryContract.updateInvestorInfo(msg.sender, address(this), 1);
        } 
        
        totalFund += investedMoney;
        Token.safeTransfer(currentInvestorAddress, investedMoney);
        investorsAmount[currentInvestorAddress] = 0;
        investorsList[currentInvestorAddress] = false;
        totalFund -= investedMoney;
        investorsCount--;
        _replaceRequest.replaced = true;
        _replaceRequest.active = false;
        uint256[] memory investorAllRequestsindex = investorsReplaceRequest[currentInvestorAddress];
        for (uint256 i=0; i < investorAllRequestsindex.length; i++){
            ReplaceRequest storage otherReplaceRequest = replaceRequests[investorAllRequestsindex[i]];
            if (otherReplaceRequest.active){
                otherReplaceRequest.active = false;
            }
        }

        removeReplaceInvestor(currentInvestorAddress); 
        campaignFactoryContract.updateInvestorInfo(currentInvestorAddress, address(this), 0);
    }

    function removeReplaceInvestor(address investor) internal {
        for (uint256 i=0; i < investors.length; i ++){
            if(investors[i] == investor){
                delete investors[i];
            }
        }
    }

    function getInvestors() external view returns(address payable[] memory){
        return investors;
    }

    function withdraw() external isInvestor nonReentrant isPaused{
        if (isFundingFinished() && !isFundingSuccessful()){
            if (investorsList[msg.sender]){
                uint256 investedMoney = investorsAmount[msg.sender];
                require(investedMoney > 0, "you have no token in the contract.");
                Token.safeTransfer(msg.sender, investedMoney);
                investorsList[msg.sender] = false;
                withdrawCount ++;
                if (withdrawCount == investorsCount){
                    campaignTerminated = true;
                }
            }    
        }

        if (isFundingFinished() && isFundingSuccessful() && projectComplete){
            if (investorsList[msg.sender]){
                uint256 investedMoney = investorsAmount[msg.sender];
                uint256 interestedMoney = investorsInterest[msg.sender];
                uint256 repayAmount = investedMoney + interestedMoney;
                Token.safeTransfer(msg.sender, repayAmount);
                investorsList[msg.sender] = false;
                withdrawCount ++;
                if (withdrawCount == investorsCount){
                    campaignTerminated = true;
                }
            }
        }
    }

    function getWithdrawCheck(address userAddress) external view returns(bool){
        bool check = true;
        if(!investorsList[userAddress]){
            check = false;
        }

        if ((investorsList[userAddress]) && (investorsAmount[userAddress] == 0)){
            check = false;
        }

        return check;
    }

    function getCampaignInfo() external view returns(string memory, string memory, string memory,
    uint256, uint256, uint256, uint256, uint256, uint256, address, address){
        uint256 projectState = uint256(getProjectStatus());
        return (title, description, fileName, fullFund, fundingPeriod, totalFund, milestoneNum,
        platformFee, projectState, creator, buyer);
    }

    

    function getProjectStatus() public view returns(Status projectStatus){
        if (pause){
            projectStatus = Status.paused;
        }

        if (!pause && !managerApproved){
            projectStatus = Status.notVerifiedByManager;
        }

        if (!pause && !buyerApproved && managerApproved){
            projectStatus = Status.verifiedByManager;
        }

        if (!pause && buyerApproved && !isFundingFinished()){
            projectStatus = Status.fundRaising;
        }

        if (!pause && buyerApproved && isFundingFinished() && !isFundingSuccessful()){
            projectStatus = Status.fundRaisingFailed;
        }

        if (!pause && buyerApproved && isFundingFinished() && isFundingSuccessful()){
            if (numRequest > 0) {
                if (requests[numRequest-1].active){
                    projectStatus = Status.paymentRequestWaiting;
                } else{
                    projectStatus = Status.projectInProgress;
                }
            } else {
                projectStatus = Status.projectInProgress;
            }
            
        }

        if (!pause && buyerApproved && isFundingFinished() && isFundingSuccessful() && projectComplete){
            projectStatus = Status.projectFinished;
        }
    }


    function withdrawStuckTokens(address ERC20Token) public isManager{
        require(campaignTerminated, "campaign is not terminated.");
        IERC20 otherToken = IERC20(ERC20Token);
        uint256 remainedToken = otherToken.balanceOf(address(this));
        require(remainedToken > 0, "no token in the contract.");
        otherToken.safeTransfer(befunderManager, remainedToken);
    }

    function prepayValue() external view returns(uint256 value){
        value = ((totalFund - ((fullFund * platformFee)/10000)) * prepaymentPercentage)/10000;
    }


}