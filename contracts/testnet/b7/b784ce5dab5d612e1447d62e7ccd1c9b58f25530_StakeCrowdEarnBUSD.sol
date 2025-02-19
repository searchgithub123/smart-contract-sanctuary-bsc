/**
 *Submitted for verification at BscScan.com on 2022-08-29
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
	
    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;
	
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
	
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
	
    function owner() public view virtual returns (address) {
        return _owner;
    }
	
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
	
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }
	
    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
	function transfer(address recipient, uint256 amount) external returns (bool);
	function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
	function isExcludedFromFees(address account) external view returns (bool);
}

library Address {
    
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
	
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }
  
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }
   
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
	
    function verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

library SafeBEP20 {
    using Address for address;
	
    function safeTransfer(IBEP20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IBEP20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }
	
    function _callOptionalReturn(IBEP20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeBEP20: low-level call failed");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeBEP20: BEP20 operation did not succeed");
        }
    }
}

contract StakeCrowdEarnBUSD is Ownable, ReentrancyGuard{
    using SafeBEP20 for IBEP20;
	
    uint256 public minStaking = 10 * 10**9;
	uint256 public stakingFee = 5 * 10**9;
	uint256 public totalStaked;
	uint256 public fundingStaked;
	
    address public communityWallet = 0x760c5A41b67BE0b8E208Da61c9654d5aad1e92f2;
	
    IBEP20 public stakedToken = IBEP20(0xde065c4cecAa755E02f8b26961Bc89147e47D6A8);
	IBEP20 public rewardToken = IBEP20(0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7);
	
	uint256[4] public stakingPeriod     = [30 days, 90 days, 180 days, 365 days];
	uint256[4] public rewardMultiplier  = [25, 50, 75, 100];
	bool[4] public bonusApplicable      = [false, false, false, true];
	
	uint256[4] public minFundRequest    = [5000 * 10**18, 5000 * 10**18, 5000 * 10**18, 5000 * 10**18];
	uint256[4] public maxFundRequest    = [10000 * 10**18, 25000 * 10**18, 50000 * 10**18, 100000 * 10**18];
	uint256[4] public minStakingFunding = [100 * 10**9, 250 * 10**9, 1000 * 10**9, 5000 * 10**9];
	uint256[4] public stakingFeeFunding = [10 * 10**9, 15 * 10**9, 25 * 10**9, 50 * 10**9];
	
	address[] public fundraiser;
	bool public paused = false;
	
	modifier whenNotPaused() {
		require(!paused, "Contract is paused");
		_;
	}
	
	modifier whenPaused() {
		require(paused, "Contract is unpaused");
		_;
	}
	
    struct StakeToDoMore {
       uint256 amount; 
       uint256 startTime;
	   uint256 endTime;
	   uint256 themselvesShares;
	   uint256 communityShares;
	   uint256 fundraiserShares;
       uint256 package;
	   address fundraiser;
	   uint256 fundraiserStaking;
	   uint256 status;
    }
	
    struct DoMoreInfo {
       StakeToDoMore[] moreStake;
    }
	
	struct StakeToFunding {
       uint256 amount;
	   uint256 startTime;
	   uint256 endTime;
       uint256 fundingRequest;
       uint256 fundRaised; 	   
	   uint256 themselvesShares;
	   uint256 communityShares;
       uint256 package;
	   uint256 status;
    }
	
	struct FundingInfo {
       StakeToFunding[] fundingStake;
    }
	
	mapping (address => bool) public isFundraiser;
	mapping (address => DoMoreInfo) moreAllInfo;
	mapping (address => FundingInfo) fundingInfoInfo;
	mapping (address => mapping(uint256 => StakeToDoMore)) public mapStakeToDoMore;
	mapping (address => mapping(uint256 => StakeToFunding)) public mapStakeToFunding;
	
	event NewStakingFeeForFunding(uint256 P1StakingFee, uint256 P2StakingFee, uint256 P3StakingFee, uint256 P4StakingFee);
	event NewMinStakingForFunding(uint256 P1MinStaking, uint256 P2MinStaking, uint256 P3MinStaking, uint256 P4MinStaking);
	event NewMaxFundRequest(uint256 P1MaxFundRequest, uint256 P2MaxFundRequest, uint256 P3MaxFundRequest, uint256 P4MaxFundRequest);
	event NewMinFundRequest(uint256 P1MinFundRequest, uint256 P2MinFundRequest, uint256 P3MinFundRequest, uint256 P4MinFundRequest);
	event NewStakingPeriod(uint256 P1Period, uint256 P2Period, uint256 P3Period, uint256 P4Period);
	event NewRewardMultiplier(uint256 P1Multiplier, uint256 P2Multiplier, uint256 P3Multiplier, uint256 P4Multiplier);
    event MigrateTokens(address tokenRecovered, uint256 amount);
    event Staked(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
	event Pause();
    event Unpause();
	
    constructor() {}
    
	function StakingForFunding(uint256 amount, uint256 package, uint256 fundRequest, uint256 themselves, uint256 community) external nonReentrant{
		FundingInfo storage User = fundingInfoInfo[msg.sender];
		
		if(!isFundraiser[msg.sender]) {
		    isFundraiser[msg.sender] = true;
			fundraiser.push(msg.sender);
		}
		
		require(fundRequest >= minFundRequest[package] && maxFundRequest[package]  >= fundRequest, "Incorrect range value for fund request"); 
		require(themselves >= 750 && themselves  <= 850, "Incorrect range value for themselves");
		require(community >= 150 && community <= 250, "Incorrect range value for community");
		require(themselves + community == 1000, "Incorrect value value for themselves + community");
		
		require(!paused, "Deposit is paused");
		require(stakedToken.balanceOf(msg.sender) >= amount, "Balance not available for staking");
		require(amount >= minStakingFunding[package] + stakingFeeFunding[package], "Amount is less than minimum staking amount");
		require(package < stakingPeriod.length, "Package not found");
		
		User.fundingStake.push(StakeToFunding(amount - stakingFeeFunding[package], block.timestamp, block.timestamp + stakingPeriod[package], 0, 0, themselves, community, package, 1));
		totalStaked += amount - stakingFeeFunding[package];
		fundingStaked += amount - stakingFeeFunding[package];
		
		stakedToken.safeTransferFrom(address(msg.sender), address(this), amount - stakingFeeFunding[package]);
		stakedToken.safeTransferFrom(address(msg.sender), address(0x000000000000000000000000000000000000dEaD), stakingFeeFunding[package]);
        emit Staked(msg.sender, amount - stakingFeeFunding[package]);
    }
	
	function withdrawForFunding(uint256 id) external nonReentrant{
	    FundingInfo storage user = fundingInfoInfo[msg.sender];
		
		require(user.fundingStake.length > id, "No staking found");
		require(user.fundingStake[id].status == 1, "staking already unstaked");
		require(user.fundingStake[id].endTime > block.timestamp, "Staking time not completed");
		
		uint256 amount   = user.fundingStake[id].amount;
		uint256 reward   = pendingrewardFunding(msg.sender, id);
		uint256 TShares  = reward * user.fundingStake[id].themselvesShares / 1000;
		uint256 CShares  = reward * user.fundingStake[id].communityShares / 1000;
		
		require(rewardToken.balanceOf(address(this)) >= reward, "Reward token balance not available for withdraw");
		require(stakedToken.balanceOf(address(this)) >= amount, "Token balance not available for withdraw");
		
		totalStaked = totalStaked - amount;
		fundingStaked = fundingStaked - amount;
		
		user.fundingStake[id].status = 2; 
		
		rewardToken.safeTransfer(address(msg.sender), TShares);
		rewardToken.safeTransfer(address(communityWallet), CShares);
		stakedToken.safeTransfer(address(msg.sender), amount);
		emit Withdraw(msg.sender, amount);
    }
	
	function StakingForDoMore(uint256 amount, uint256 package, uint256 themselves, uint256 community, uint256 funding, uint256 fundraiserIndex, uint256 fundraiserStaking) external nonReentrant{
	    DoMoreInfo storage User = moreAllInfo[msg.sender];
		FundingInfo storage Fundraiser = fundingInfoInfo[fundraiser[fundraiserIndex]];
		
		require(themselves >= 0 && themselves  <= 800, "Incorrect range value for themselves");
		require(community >= 100 && community <= 900, "Incorrect range value for community");
		require(funding >= 100 && funding   <= 900, "Incorrect range value for funding");
		require(themselves + community + funding == 1000, "Incorrect value value for themselves + community + funding");
		
		require(!paused, "Deposit is paused");
		require(stakedToken.balanceOf(msg.sender) >= amount, "Balance not available for staking");
		require(amount >= minStaking + stakingFee, "Amount is less than minimum staking amount");
		require(package < stakingPeriod.length, "Package not found");
		require(fundraiserIndex < fundraiser.length, "Fundraiser not found");
		require(Fundraiser.fundingStake.length > fundraiserStaking, "No staking found for fundraiser");
		require(Fundraiser.fundingStake[fundraiserStaking].status == 1, "Fund already raised");
		
		User.moreStake.push(StakeToDoMore(amount - stakingFee, block.timestamp, block.timestamp + stakingPeriod[package], themselves, community, funding, package, fundraiser[fundraiserIndex], fundraiserStaking, 1));
		totalStaked = totalStaked + amount - stakingFee;
		
		stakedToken.safeTransferFrom(address(msg.sender), address(this), amount - stakingFee);
		stakedToken.safeTransferFrom(address(msg.sender), address(0x000000000000000000000000000000000000dEaD), stakingFee);
        emit Staked(msg.sender, amount - stakingFee);
    }
	
    function withdraw(uint256 id) external nonReentrant{
	    DoMoreInfo storage user = moreAllInfo[msg.sender];
		
		FundingInfo storage Fundraiser = fundingInfoInfo[user.moreStake[id].fundraiser];
		
		require(user.moreStake.length > id, "No staking found");
		require(user.moreStake[id].status == 1, "staking already unstaked");
		require(user.moreStake[id].endTime > block.timestamp, "Staking time not completed");
		
		uint256 amount   = user.moreStake[id].amount;
		uint256 reward   = pendingreward(msg.sender, id);
		uint256 TShares  = reward * user.moreStake[id].themselvesShares / 1000;
		uint256 CShares  = reward * user.moreStake[id].communityShares / 1000;
		uint256 FShares  = reward * user.moreStake[id].fundraiserShares / 1000;
		
		require(rewardToken.balanceOf(address(this)) >= reward, "Reward token balance not available for withdraw");
		require(stakedToken.balanceOf(address(this)) >= amount, "Token balance not available for withdraw");
		
		totalStaked = totalStaked - amount;
		
		user.moreStake[id].status = 2; 
		if(Fundraiser.fundingStake[user.moreStake[id].fundraiserStaking].status == 1)
		{
		   Fundraiser.fundingStake[user.moreStake[id].fundraiserStaking].fundRaised += FShares;
		   rewardToken.safeTransfer(address(user.moreStake[id].fundraiser), FShares);  
		}
		else
		{
		   CShares += FShares;
		}
		
		rewardToken.safeTransfer(address(msg.sender), TShares);
		rewardToken.safeTransfer(address(communityWallet), CShares);
		stakedToken.safeTransfer(address(msg.sender), amount);
		emit Withdraw(msg.sender, amount);
    }
	
	function pendingreward(address userAddress, uint256 id) public view returns (uint256) {
        DoMoreInfo storage user = moreAllInfo[userAddress];
		if(user.moreStake[id].amount > 0 && user.moreStake[id].status == 1 && user.moreStake[id].endTime >= block.timestamp)
		{
			 uint256 reward = user.moreStake[id].amount * rewardMultiplier[user.moreStake[id].package] * rewardToken.balanceOf(address(this)) / totalStaked * 100;
		     return reward;
        }
		else
		{
		    return 0;
		}
    }
	
	function pendingrewardFunding(address userAddress, uint256 id) public view returns (uint256) {
		FundingInfo storage user = fundingInfoInfo[userAddress];
		if(user.fundingStake[id].amount > 0 && user.fundingStake[id].status == 1 && user.fundingStake[id].endTime >= block.timestamp)
		{
			uint256 reward = user.fundingStake[id].amount * rewardMultiplier[user.fundingStake[id].package] * rewardToken.balanceOf(address(this)) / totalStaked * 100;
		    return reward;
        }
		else
		{
		    return 0;
		}
    }
	
	function migrateTokens(address receiver, address tokenAddress, uint256 tokenAmount) external onlyOwner nonReentrant{
       IBEP20(tokenAddress).safeTransfer(receiver, tokenAmount);
       emit MigrateTokens(tokenAddress, tokenAmount);
    }
	
    function SetRewardMultiplier(uint256 P1Multiplier, uint256 P2Multiplier, uint256 P3Multiplier, uint256 P4Multiplier) external onlyOwner {
	    require(P1Multiplier >= 0, "Incorrect `P1 Reward Multiplier` value");
		require(P2Multiplier >= 0, "Incorrect `P2 Reward Multiplier` value");
		require(P3Multiplier >= 0, "Incorrect `P3 Reward Multiplier` value");
		require(P4Multiplier >= 0, "Incorrect `P4 Reward Multiplier` value");
		
	    rewardMultiplier[0] = P1Multiplier;
        rewardMultiplier[1] = P2Multiplier;
        rewardMultiplier[2] = P3Multiplier;
		rewardMultiplier[3] = P4Multiplier;
		
		emit NewRewardMultiplier(P1Multiplier, P2Multiplier, P3Multiplier, P4Multiplier);
    }
	
	function SetStakingPeriod(uint256 P1Period, uint256 P2Period, uint256 P3Period, uint256 P4Period) external onlyOwner {
	    require(P1Period >= 0, "Incorrect `P1 Staking Period` value");
		require(P2Period >= 0, "Incorrect `P2 Staking Period` value");
		require(P3Period >= 0, "Incorrect `P3 Staking Period` value");
		require(P4Period >= 0, "Incorrect `P4 Staking Period` value");
		
	    stakingPeriod[0] = P1Period;
        stakingPeriod[1] = P2Period;
        stakingPeriod[2] = P3Period;
		stakingPeriod[3] = P4Period;
		
		emit NewStakingPeriod(P1Period, P2Period, P3Period, P4Period);
    }
	
	function SetMinFundRequest(uint256 P1MinFundRequest, uint256 P2MinFundRequest, uint256 P3MinFundRequest, uint256 P4MinFundRequest) external onlyOwner {
	    require(P1MinFundRequest >= 0 && P1MinFundRequest <= maxFundRequest[0], "Incorrect `P1 Min Fund Request` value");
		require(P2MinFundRequest >= 0 && P2MinFundRequest <= maxFundRequest[1], "Incorrect `P2 Min Fund Request` value");
		require(P3MinFundRequest >= 0 && P3MinFundRequest <= maxFundRequest[2], "Incorrect `P3 Min Fund Request` value");
		require(P4MinFundRequest >= 0 && P4MinFundRequest <= maxFundRequest[3], "Incorrect `P4 Min Fund Request` value");
		
	    minFundRequest[0] = P1MinFundRequest;
        minFundRequest[1] = P2MinFundRequest;
        minFundRequest[2] = P3MinFundRequest;
		minFundRequest[3] = P4MinFundRequest;
		
		emit NewMinFundRequest(P1MinFundRequest, P2MinFundRequest, P3MinFundRequest, P4MinFundRequest);
    }
	
	function SetMaxFundRequest(uint256 P1MaxFundRequest, uint256 P2MaxFundRequest, uint256 P3MaxFundRequest, uint256 P4MaxFundRequest) external onlyOwner {
	    require(P1MaxFundRequest >= 0 && P1MaxFundRequest >= minFundRequest[0], "Incorrect `P1 Max Fund Request` value");
		require(P2MaxFundRequest >= 0 && P2MaxFundRequest >= minFundRequest[1], "Incorrect `P2 Max Fund Request` value");
		require(P3MaxFundRequest >= 0 && P3MaxFundRequest >= minFundRequest[2], "Incorrect `P3 Max Fund Request` value");
		require(P4MaxFundRequest >= 0 && P4MaxFundRequest >= minFundRequest[3], "Incorrect `P4 Max Fund Request` value");
		
	    maxFundRequest[0] = P1MaxFundRequest;
        maxFundRequest[1] = P2MaxFundRequest;
        maxFundRequest[2] = P3MaxFundRequest;
		maxFundRequest[3] = P4MaxFundRequest;
		
		emit NewMaxFundRequest(P1MaxFundRequest, P2MaxFundRequest, P3MaxFundRequest, P4MaxFundRequest);
    }
	
	function SetMinStakingForFunding(uint256 P1MinStaking, uint256 P2MinStaking, uint256 P3MinStaking, uint256 P4MinStaking) external onlyOwner {
	    require(P1MinStaking >= 0, "Incorrect `P1 Min Staking` value");
		require(P2MinStaking >= 0, "Incorrect `P2 Min Staking` value");
		require(P3MinStaking >= 0, "Incorrect `P3 Min Staking` value");
		require(P4MinStaking >= 0, "Incorrect `P4 Min Staking` value");
		
	    minStakingFunding[0] = P1MinStaking;
        minStakingFunding[1] = P2MinStaking;
        minStakingFunding[2] = P3MinStaking;
		minStakingFunding[3] = P4MinStaking;
		
		emit NewMinStakingForFunding(P1MinStaking, P2MinStaking, P3MinStaking, P4MinStaking);
    }
	
	function SetStakingFeeForFunding(uint256 P1StakingFee, uint256 P2StakingFee, uint256 P3StakingFee, uint256 P4StakingFee) external onlyOwner {
	    require(P1StakingFee >= 0, "Incorrect `P1 Min Staking` value");
		require(P2StakingFee >= 0, "Incorrect `P2 Min Staking` value");
		require(P3StakingFee >= 0, "Incorrect `P3 Min Staking` value");
		require(P4StakingFee >= 0, "Incorrect `P4 Min Staking` value");
		
	    stakingFeeFunding[0] = P1StakingFee;
        stakingFeeFunding[1] = P2StakingFee;
        stakingFeeFunding[2] = P3StakingFee;
		stakingFeeFunding[3] = P4StakingFee;
		
		emit NewStakingFeeForFunding(P1StakingFee, P2StakingFee, P3StakingFee, P4StakingFee);
    }
	
	function SetMinStakingForDoMore(uint256 newAmount) external onlyOwner {
	   require(newAmount >= 0, "Incorrect `New Amount` value");
	   minStaking = newAmount;
	}
	
	function pause() whenNotPaused external onlyOwner{
		paused = true;
		emit Pause();
	}
	
	function unpause() whenPaused external onlyOwner{
		paused = false;
		emit Unpause();
	}

	function totalFundraiser() public view returns (uint256) {
	   return fundraiser.length;
	}
	
	function totalFundingRequest(address _user) public view returns (uint256) {
	    FundingInfo storage user = fundingInfoInfo[_user];
		return user.fundingStake.length;
	}
	
	function totalStakingRequest(address _user) public view returns (uint256) {
		DoMoreInfo storage user = moreAllInfo[_user];
		return user.moreStake.length;
	}
}