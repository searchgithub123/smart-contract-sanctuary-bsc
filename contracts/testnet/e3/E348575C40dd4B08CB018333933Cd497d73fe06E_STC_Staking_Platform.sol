/**
 *Submitted for verification at BscScan.com on 2022-12-14
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IBEP20{
    function name() external view returns(string memory);

    function symbol() external view returns(string memory);

    function totalSupply() external view returns (uint );

    function decimals() external view returns(uint);

    function balanceOf(address account) external view returns(uint);

    function approve(address sender , uint value)external returns(bool);

    function allowance(address sender, address spender) external view returns (uint256);

    function transfer(address recepient , uint value) external returns(bool);

    function transferFrom(address sender,address recepient, uint value) external returns(bool);

    event Transfer(address indexed from , address indexed to , uint value);

    event Approval(address indexed sender , address indexed  spender , uint value);
}


contract Context{
    constructor () {}
   function _msgsender() internal view returns (address) {
    return msg.sender;
  }
}

contract Ownable is Context{
    address internal  _Owner;

    event transferOwnerShip(address indexed _previousOwner , address indexed _newOwner);

    constructor(){
        address msgsender = _msgsender();
        _Owner = msgsender;
        emit transferOwnerShip(address(0),msgsender);
    }

    function checkOwner() public view returns(address){
        return _Owner;
    }

    modifier OnlyOwner(){
       require(_Owner == _msgsender(),"Only owner can change the Ownership");
       _; 
    }
   
    function transferOwnership(address _newOwner) public OnlyOwner {
      _transferOwnership(_newOwner);
    }

    function _transferOwnership(address _newOwner) internal {
      require(_newOwner != address(0),"Owner should not be 0 address");
      emit transferOwnerShip(_Owner,_newOwner);
      _Owner = _newOwner;
    }
}

contract STC_Staking_Platform is Ownable {
    address public signerAddress;

    IBEP20 public STC_Addr;
    IBEP20 public BUSD;

    uint public rewardClaimingTime = 1 days;  //1 hour
    uint public rewardUpdatePerHour = 1 hours; // 10 mnts
    uint diviser = 100e18;
    uint public claimTimes = 24; // 6
    uint public affiliateRewardPercentage = 2e18;
    uint public maxRefferelCountPerUser = 156;

    bool public rewardClaiming;

    mapping (Pack => Packages) public packages;
    mapping (address => userDetails) public UserDetails;
    mapping (Pack => mapping(uint => uint)) public rewards; //EG := TRIAL => LEVEL => REWARD
    mapping (uint => uint) public levels;
    mapping (bytes32 => bool) public hashStatus;

    enum Pack{
        TRIAL,
        STARTER,
        GROWTH
    }

    struct Packages {
        uint lifeSpan;
        uint busdPrice;
        uint busdCapacity;
        uint poolSTCamount;
    }

    struct userDetails{
        address reffererAddr;
        mapping(Pack => UserPack) packages;
    }

    struct UserPack {
        uint stakedAmount;
        uint affiliateRewardAmount;
        uint totalRewardClaimed;
        mapping(uint => address[]) levelRefferredUsers;
        uint level;
        uint packageBoughtTime;
        uint stakedTime;
        uint lastRewardClaimedTime;
        bool isActive;
        address[] refferred;
    }

    modifier isDisabled() {
        require(!rewardClaiming, "Reward claiming is disabled!");
        _;
    }

    event Staked(address indexed userAddr, uint level, address refAddr);
    event RewardUpdated(Pack pack, uint level, uint percentage);
    event updatedPackage(Pack pack,uint span,uint price,uint capacity);
    event packageBought(Pack pack, uint busdAmount);
    event Claimed(Pack pack, uint level, uint busdAmount);
    event ClaimedCapital(address indexed user, Pack pack, uint amount);
    event LevelBought(address indexed reffererAddr, address indexed refferingAddr , uint indexed affReward, Pack pack, uint level);
    event TopUp(address indexed userAddr, uint amount);
    event ClaimedAffiliate(address indexed userAddr, uint amount);
    event SwapBusdToStc(address indexed userAddr, uint busdAmount, uint busdPrice);

    constructor(address stc_addr,address busd,address signer) {
        assembly{
            sstore(signerAddress.slot, signer)
            sstore(STC_Addr.slot,stc_addr)
            sstore(BUSD.slot,busd)
        }
        initPackages();
        initRewards();
        initLevels();
        initAdminActiveInAllPacks();
    }

    function buyPackage(Pack pack) public {                                                                                                                                                                                                                                                                                                                                                                                                    
        userDetails storage userdetails = UserDetails[msg.sender];
        Packages memory package = packages[pack];

        //require(userdetails.packages[pack].isActive, "Already active!");
        address reffererAddr = userdetails.reffererAddr;

        require(reffererAddr != address(0), "0 ref!");
        require(!validateUserPack(msg.sender), "User already existed, claim capital or pack not expired");

        userDetails storage userRefererDetails = UserDetails[reffererAddr];

        uint affiliateRewardAmount = ((package.busdPrice * affiliateRewardPercentage) / diviser);
        uint8 reffererPack = viewUserActivePack(reffererAddr);
        bool isLimitReached;

        if (userRefererDetails.packages[Pack(reffererPack)].refferred.length > 156) isLimitReached = true;

        if (reffererAddr != _Owner && !isLimitReached) {
           userRefererDetails.packages[Pack(reffererPack)].affiliateRewardAmount += affiliateRewardAmount;
           require(BUSD.transferFrom(msg.sender, address(this), package.busdPrice), "Tx_1 failed");
        }else{
           require(BUSD.transferFrom(msg.sender, _Owner, affiliateRewardAmount), "Tx_1 failed");
           require(BUSD.transferFrom(msg.sender, address(this), (package.busdPrice - affiliateRewardAmount)), "Tx_2 failed");
        }

        userdetails.packages[pack].lastRewardClaimedTime =  userdetails.packages[pack].packageBoughtTime = block.timestamp;
        
        if(userdetails.packages[pack].level == 0)  userdetails.packages[pack].level = 1;

        if(!userdetails.packages[pack].isActive) 
            userdetails.packages[pack].isActive = true; 
        
        emit packageBought(pack, package.busdPrice);
    }
   
    function buyLevel(Pack pack, address reffererAddr, uint expiry,uint8 v, bytes32 r, bytes32 s) public {
        require(expiry > block.timestamp, "Expired!");
        require(validateBuyLevelHash(reffererAddr, msg.sender, pack, expiry,v,r,s),"Invalid sig");
        Packages memory package = packages[pack];
        reffererAddr = reffererAddr == address(0) ? _Owner : reffererAddr;
        userDetails storage userReferringdetails = UserDetails[msg.sender];
        userDetails storage userRefererdetails = UserDetails[reffererAddr];
        require(userReferringdetails.reffererAddr == address(0),"User is already reffered in another pack!");
        require(userReferringdetails.packages[pack].level == 0,"Already refferal bought this package!");
        require(!userReferringdetails.packages[pack].isActive, "refferer already bought the package!");    

        require(reffererAddr == _Owner || checkRefBoughtAnyPack(reffererAddr) , "Refferer must buy atleast one pack!");        

        uint8 reffererPack = viewUserActivePack(reffererAddr);

        if (reffererAddr != _Owner) {
            userRefererdetails.packages[Pack(reffererPack)].refferred.push(msg.sender);
            userRefererdetails.packages[Pack(reffererPack)].levelRefferredUsers[userRefererdetails.packages[Pack(reffererPack)].level].push(msg.sender);
        }else{
            userRefererdetails.packages[pack].refferred.push(msg.sender);
        }

        if ((reffererAddr != _Owner) && (userRefererdetails.packages[Pack(reffererPack)].levelRefferredUsers[userRefererdetails.packages[Pack(reffererPack)].level].length == levels[userRefererdetails.packages[Pack(reffererPack)].level])){   
            userRefererdetails.packages[Pack(reffererPack)].level++;
        }

        bool isLimitReached;
        uint affReward = ((package.busdPrice * affiliateRewardPercentage) / diviser);

        if (userRefererdetails.packages[Pack(reffererPack)].refferred.length > maxRefferelCountPerUser) isLimitReached = true;

        if (reffererAddr != _Owner && !isLimitReached) {
            userRefererdetails.packages[Pack(reffererPack)].affiliateRewardAmount += affReward;    
            require(BUSD.transferFrom(msg.sender, address(this), package.busdPrice), "Tx failed");
        } else {
            require(BUSD.transferFrom(msg.sender, _Owner, affReward), "Tx_ failed");
            require(BUSD.transferFrom(msg.sender, address(this), (package.busdPrice - affReward)), "Tx failed");
        }

        userReferringdetails.packages[pack].level = 1;
        userReferringdetails.reffererAddr = reffererAddr;
        userReferringdetails.packages[pack].packageBoughtTime = block.timestamp;
        userReferringdetails.packages[pack].isActive = true;
        setHashCompleted(prepareBuyLevelHash(reffererAddr, msg.sender, pack, expiry), true);
        emit LevelBought(reffererAddr,msg.sender,affReward, pack, 1);
    }

    function stake(Pack pack, uint stcPrice, uint expiry, uint8 v, bytes32 r, bytes32 s) public {
        require(expiry > block.timestamp, "Expired!");
        require(validateHash(msg.sender, pack, stcPrice, expiry,v,r,s),"Invalid signature");
        userDetails storage userdetails = UserDetails[msg.sender];
        Packages storage package = packages[pack];
        require(userdetails.reffererAddr != address(0), "User not found!");
        require(userdetails.packages[pack].isActive,"User doesn't bought the mentioned package!");
        require(userdetails.packages[pack].stakedAmount == 0, "Already staked!");
        if (userdetails.packages[pack].packageBoughtTime + package.lifeSpan <= block.timestamp) {
            revert("user pack expired, claim capital!");    
        }

        uint stcAmount = viewStcForStake(pack, stcPrice);
        require(STC_Addr.transferFrom(msg.sender, address(this), stcAmount), "Tx_2 failed");
    
        package.poolSTCamount += stcAmount;
        userdetails.packages[pack].stakedAmount += stcAmount;
        userdetails.packages[pack].stakedTime = block.timestamp;
        setHashCompleted(prepareHash(msg.sender, stcPrice, pack, expiry), true);
        emit Staked(msg.sender, userdetails.packages[pack].level, userdetails.reffererAddr);
    }

    function viewStcForStake(Pack pack , uint stcPrice) public view returns(uint r){
        Packages memory packk = packages[pack];
        r = ((packk.busdCapacity * 1e18) / stcPrice);
    }

    function topUp(Pack pack,uint stcPrice,uint expiry ,uint8 v, bytes32 r, bytes32 s) public {
        require(expiry > block.timestamp, "Expired!");
        require(validateHash(msg.sender, pack, stcPrice, expiry, v, r, s),"Invalid sig");
        require(stcPrice > 0,"0 stcPrice");
        userDetails storage userdetails = UserDetails[msg.sender];
        require(userdetails.packages[pack].isActive,"User not found!");
        require(userdetails.packages[pack].stakedAmount > 0, "User must stake 1st!");
        Packages storage package = packages[pack];
        uint topUpAmount = viewStcForStake(pack, stcPrice);
        uint totalStakedAmount = userdetails.packages[pack].stakedAmount;
        if (topUpAmount > totalStakedAmount) {
            uint fAmount = topUpAmount - totalStakedAmount;
            (bool ress, ) = address(STC_Addr).call(abi.encodeWithSelector(IBEP20.transferFrom.selector, msg.sender, address(this), fAmount)); 
            require(ress,"Trx f");
            package.poolSTCamount += fAmount;
            userdetails.packages[pack].stakedAmount += fAmount;
            setHashCompleted(prepareHash(msg.sender, stcPrice, pack, expiry), true);
            emit TopUp(msg.sender, fAmount);
        }else{
            revert("Nothing to topUp");
        }
    }

    function setRewardClaiming(bool isOpen) public OnlyOwner {
        rewardClaiming = isOpen;
    }

    function claimAffiliate(Pack pack) public isDisabled {
        userDetails storage userdetails = UserDetails[msg.sender];
        require(userdetails.packages[pack].affiliateRewardAmount > 0, "Aff r0");
        uint afRewAmnt = userdetails.packages[pack].affiliateRewardAmount;
        userdetails.packages[pack].affiliateRewardAmount = 0;
        bool res = BUSD.transfer(msg.sender, afRewAmnt);
        require(res, "Tx f");
        emit ClaimedAffiliate(msg.sender, afRewAmnt);
    }

    function claimRewardAmount(Pack pack,uint busdPrice,uint expiry, uint8 v, bytes32 r, bytes32 s) public isDisabled {
        require(expiry >= block.timestamp, "claimRewardAmount: Expired!");
        require(validateClaimHash(pack, msg.sender, busdPrice, expiry, v, r, s), "Invalid sig4 claim!");
        userDetails storage userdetails = UserDetails[msg.sender];
        require(userdetails.packages[pack].stakedAmount > 0,"No staked amount!");
        require(userdetails.packages[pack].isActive,"not found in this package!");
        require(userdetails.packages[pack].lastRewardClaimedTime < (userdetails.packages[pack].packageBoughtTime + packages[pack].lifeSpan),"No available claims");
        uint _lastRewardTime = ((userdetails.packages[pack].lastRewardClaimedTime == 0) ? userdetails.packages[pack].stakedTime : userdetails.packages[pack].lastRewardClaimedTime);
        require(_lastRewardTime + rewardClaimingTime <= block.timestamp,"1ce 24s");
        uint totalRewardAmount = getRewards(pack ,msg.sender,busdPrice); // uint totalRewardAmount 
        require(totalRewardAmount > 0,"No reward amount to claim!");
        require(BUSD.transfer(msg.sender, totalRewardAmount),"Tx failed");
        userdetails.packages[pack].lastRewardClaimedTime = block.timestamp;
        userdetails.packages[pack].totalRewardClaimed +=  totalRewardAmount;
        setHashCompleted(prepareClaimHash(pack, msg.sender, busdPrice, expiry),true);
        emit Claimed(pack, userdetails.packages[pack].level, totalRewardAmount);
    }

    function getRewards(Pack pack,address userAddr, uint busdPrice) public view returns (uint rCalculate) {
        uint currentTime = block.timestamp;
        userDetails storage userdetails = UserDetails[userAddr];
        Packages memory packk = packages[pack];
        uint rewardPercentage = rewards[pack][userdetails.packages[pack].level];
        uint reward = ((userdetails.packages[pack].stakedAmount * rewardPercentage) / diviser);
        uint lcReward = ((userdetails.packages[pack].lastRewardClaimedTime == 0) ? userdetails.packages[pack].stakedTime : userdetails.packages[pack].lastRewardClaimedTime);

        if(lcReward >= (userdetails.packages[pack].packageBoughtTime + packk.lifeSpan)) {
            return 0;
        }

        if (currentTime > (userdetails.packages[pack].packageBoughtTime + packk.lifeSpan)){
            currentTime = (userdetails.packages[pack].packageBoughtTime + packk.lifeSpan);
        }

        uint rhrs = (currentTime - lcReward) / rewardUpdatePerHour;
        uint tAmnt = rhrs * reward;
        rCalculate = tAmnt * busdPrice / 1e18;
    }

    function claimCapital(Pack pack) public {
        userDetails storage userdetails = UserDetails[msg.sender];
        Packages storage package = packages[pack];
        require(block.timestamp > userdetails.packages[pack].packageBoughtTime + package.lifeSpan, "Pack not yet expired!");
        require(userdetails.packages[pack].isActive, "User not found");
        uint stkAmnt = userdetails.packages[pack].stakedAmount;
        userdetails.packages[pack].stakedAmount = 0;
        userdetails.packages[pack].isActive = false;
        userdetails.packages[pack].level = 0;
        bool res = STC_Addr.transfer(msg.sender, stkAmnt);
        require(res, "TRX c failed");
        package.poolSTCamount -= stkAmnt;
        emit ClaimedCapital(msg.sender, pack, stkAmnt);
    }

    function swapBusdToStc(uint busdAmount, uint busdPrice, uint expiry, uint8 v, bytes32 r, bytes32 s) public {
        require(busdAmount > 0 && busdPrice > 0 ,"0 busd");
        require(validateSwapHash(msg.sender, busdAmount, busdPrice, expiry, v, r, s),"Invalid sig");
        require(BUSD.transferFrom(msg.sender, address(this), busdAmount),"Tx_failed");
        uint stcAmount = busdAmount * busdPrice / 1e18;
        require(STC_Addr.transfer(msg.sender, stcAmount),"Tx_2 failed");
        emit SwapBusdToStc(msg.sender, busdAmount, busdPrice);
    }

    function viewIsPackExpired(address userAddr, Pack pack) public view returns(bool r, string memory res){
        userDetails storage userdetails = UserDetails[userAddr];
        if (!userdetails.packages[pack].isActive) {
            return (false, "not found in this pack!");
        }
        Packages memory package = packages[pack];
        r = userdetails.packages[pack].packageBoughtTime + package.lifeSpan < block.timestamp;
        res = r ? "Expired!" : "Not yet Expired";
    }

    function showRefferredAddressess(Pack pack, address user) public view returns(address[] memory) {
        userDetails storage userdetails = UserDetails[user];
        return userdetails.packages[pack].refferred;
    }

    function viewUserDetails(Pack pack, address userAddress) public view returns(address reffererAddress, uint stakedAmount, uint affilliateReward, uint totalRewardClaimed, uint level, uint packageBoughtTime, uint lastRewardClaimedTime, bool isActive, address[] memory refferdAddress){
        userDetails storage userdetails = UserDetails[userAddress];
        reffererAddress = userdetails.reffererAddr;
        stakedAmount = userdetails.packages[pack].stakedAmount;
        affilliateReward = userdetails.packages[pack].affiliateRewardAmount;
        totalRewardClaimed = userdetails.packages[pack].totalRewardClaimed;
        level = userdetails.packages[pack].level;
        packageBoughtTime = userdetails.packages[pack].packageBoughtTime;
        lastRewardClaimedTime = userdetails.packages[pack].lastRewardClaimedTime;
        isActive = userdetails.packages[pack].isActive;
        refferdAddress = userdetails.packages[pack].refferred;
    }

    function viewUserRefferedUsersInLevel(address userAddress, Pack pack, uint level) public view returns (address[] memory) {
        userDetails storage userdetails = UserDetails[userAddress];
        return userdetails.packages[pack].levelRefferredUsers[level];
    }

    function getStakedAmount(Pack pack, address user) public view returns(uint) {
        return UserDetails[user].packages[pack].stakedAmount;
    }

    function calculateReward(Pack pack,uint level, uint stcPrice, uint amount) public view returns(uint rAmnt) {
        uint rPrcnt = rewards[pack][level];
        rAmnt  = (((amount * rPrcnt) / diviser)* stcPrice) /1e18;
    }

    function updateReward(Pack pack, uint level, uint percentage) public OnlyOwner {
        require(level != 0 && percentage != 0,"0 lev 0 per");
        require(pack <= Pack.GROWTH,"Invalid pack");
        rewards[pack][level] = percentage;
        emit RewardUpdated(pack, level, percentage);
    }

    function updatePackage(Pack pack,  uint span,uint price, uint capacity) public  OnlyOwner {
        require(span != 0 && price != 0 && capacity != 0,"0 pack");
        require(pack <= Pack.GROWTH,"Invalid pack");
        packages[pack] = Packages({
                lifeSpan : span,
                busdPrice : price,
                busdCapacity : capacity,
                poolSTCamount : 0
        });
        emit updatedPackage(pack, span, price, capacity);
    }

    function updateSigner(address signer) public OnlyOwner {
        require(signer != address(0), "0 Signer");
        signerAddress = signer;
    }

    function updateClaimTimes(uint cHrs) public OnlyOwner {
        require(cHrs != 0, "0 cHrs");
        claimTimes = cHrs;
    }

    function updateAffiliateRewardPercentage(uint rPrcnt) public OnlyOwner {
        require(rPrcnt != 0, "0 R");
        affiliateRewardPercentage = rPrcnt;
    }

    function updateRewardClaimingTime(uint newRewClTime) public OnlyOwner {
        require(newRewClTime != 0, "0 NR");
        rewardClaimingTime = newRewClTime;
    }

    function updateRewardPerHour(uint newRewPerHour) public OnlyOwner {
        require(newRewPerHour != 0, "0 NR");
        rewardUpdatePerHour = newRewPerHour;
    }

    function updatemaxRefferelCountPerUser(uint maxRef) public OnlyOwner {
        require(maxRef >= 156, "maxRef > 156");
        maxRefferelCountPerUser = maxRef;
    }

    function updateToken(address tokenAddress, uint flag) public OnlyOwner {
        require(tokenAddress != address(0) && flag != 0, "0");
        if (flag == 1) {
            BUSD = IBEP20(tokenAddress);
        } else if(flag == 2) {
            STC_Addr = IBEP20(tokenAddress);
        }else {
            revert("Invalid flag");
        }
    }

    function validateHash(address to, Pack pack, uint stcPrice, uint expiry, uint8 v, bytes32 r, bytes32 s)internal view returns(bool result){
        bytes32 hash = prepareHash(to, stcPrice, pack, expiry);
        require(!hashStatus[hash], "Hash already exist!");
        bytes32 fullMessage = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
        );
        address signatoryAddress = ecrecover(fullMessage,v,r,s);
        result = signatoryAddress == signerAddress;
    }

    function validateSwapHash(address to, uint busdAmount, uint busdPrice, uint expiry, uint8 v, bytes32 r, bytes32 s) internal view returns(bool result) {
        bytes32 hash = prepareSwapHash(to, busdAmount, busdPrice, expiry);
        require(!hashStatus[hash], "Hash already exist!");
        bytes32 fullMessage = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
        );
        address signatoryAddress = ecrecover(fullMessage,v,r,s);
        result = signatoryAddress == signerAddress;
    }

    function validateClaimHash( Pack pack,address to, uint busdPrice,uint expiry, uint8 v, bytes32 r, bytes32 s)internal view returns(bool result){
        bytes32 hash = prepareClaimHash( pack, to, busdPrice, expiry);
        require(!hashStatus[hash], "Hash already exist!");
        bytes32 fullMessage = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
        );
        address signatoryAddress = ecrecover(fullMessage,v,r,s);
        result = signatoryAddress == signerAddress;
    }

    function validateBuyLevelHash(address refferAddr, address referrerdAddr ,Pack pack,uint expiry ,uint8 v, bytes32 r, bytes32 s) internal view returns(bool result) {
        bytes32 hash = prepareBuyLevelHash(refferAddr, referrerdAddr, pack, expiry);
        require(!hashStatus[hash], "Hash already exist!");
        bytes32 fullMessage = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
        );
        address referrerAddr = ecrecover(fullMessage,v,r,s);
        result = referrerAddr == referrerdAddr;
    }

    function prepareHash(address to, uint stcPrice, Pack pack, uint blockExpiry)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(to, stcPrice, pack, blockExpiry));
    }

    function prepareSwapHash(address to,uint busdAmount, uint busdPrice, uint blockExpiry)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(to, busdAmount, busdPrice, blockExpiry));
    }


    function prepareClaimHash(Pack pack, address to, uint busdPrice, uint blockExpiry)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(pack, to, busdPrice, blockExpiry));
    }

    function prepareBuyLevelHash(address refferrer,address referringAddr, Pack pack, uint expiry)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(refferrer,referringAddr,pack, expiry));
    }

    function setHashCompleted(bytes32 hash, bool status) private {
        hashStatus[hash] = status;
    }

    function validateUserPack(address user) public view returns (bool r) {
        for(uint8 i = 0; i <= 2; i++) {
            if(UserDetails[user].packages[Pack(i)].packageBoughtTime + packages[Pack(i)].lifeSpan > block.timestamp || UserDetails[user].packages[Pack(i)].stakedAmount != 0) {
                return true;
            }
        }
        return false;
    }
 
    function checkRefBoughtAnyPack(address userAddress) public view returns(bool) {
        for (uint i = 0; i <= 2; i++) {
            if (UserDetails[userAddress].packages[Pack(i)].isActive) {
                return true;
            }
        }
        return false;
    }

    function viewUserActivePack(address userAddress) public view returns(uint8) {
        for (uint8 i = 0; i <= 2; i++) {
            if (UserDetails[userAddress].packages[Pack(i)].isActive) {
                return i;
            }
        }
        return 3;
    }

    function initAdminActiveInAllPacks() private OnlyOwner {
        for (uint i = 0; i <= 2; i++) {
            userDetails storage userdetails = UserDetails[msg.sender];
            userdetails.packages[Pack(i)].isActive = true;
            userdetails.packages[Pack(i)].level = 1;
            userdetails.reffererAddr= msg.sender;
        }
    }

    function initPackages() private OnlyOwner {
        uint span = 60 days;
        uint price = 100e18;
        uint capacity = 200e18;
        for (uint8 i = 0; i < 3; i++){
            packages[Pack(i)] = Packages({
                lifeSpan : span,
                busdPrice : price,
                busdCapacity : capacity,
                poolSTCamount : 0
            });
            i == 0 ? span += 305 days : 0;
            i == 0 || i > 0 ? (i == 1 ? (price = price * 5) : (price = price * 5)) : price;
            i == 0 || i > 0 ?  (i == 1 ? (capacity = 5000e18) : (capacity = 1000e18)) : capacity;
        }
    }

    function initRewards() private OnlyOwner {
        rewards[Pack(0)][1] = 10e18; 
        rewards[Pack(0)][2] = 5e18; 
        rewards[Pack(0)][3] = 2.5e18; 
        rewards[Pack(0)][4] = 2.5e18; 
        rewards[Pack(0)][5] = 2.5e18; 
        rewards[Pack(0)][6] = 2.5e18; 
        rewards[Pack(0)][7] = 2.5e18; 
        rewards[Pack(0)][8] = 2.5e18; 
        rewards[Pack(0)][9] = 1.25e18; 
        rewards[Pack(0)][10] = 1.25e18; 
        rewards[Pack(0)][11] = 1.25e18; 
        rewards[Pack(0)][12] = 1.25e18; 
        rewards[Pack(0)][13] = 1.25e18; 

        for(uint i=1;i<=13;i++) {
            rewards[Pack(1)][i] = rewards[Pack(0)][i] * 2; 
            rewards[Pack(2)][i] = rewards[Pack(0)][i] * 2; 
        }
    }

    function initLevels() private OnlyOwner{
        for(uint i=1;i<=12;i++) {
            levels[i] = 2*i;
        }
    }


    function withdraw(address tokenAddress,address _toUser,uint amount)public OnlyOwner returns(bool status){
        require(_toUser != address(0), "Invalid Address");
        if (tokenAddress == address(0)) {
            require(address(this).balance >= amount, "Insufficient balance");
            require(payable(_toUser).send(amount), "Transaction failed");
            return true;
        }
        else {
            require(IBEP20(tokenAddress).balanceOf(address(this)) >= amount);
            IBEP20(tokenAddress).transfer(_toUser,amount);
            return true;
        }
    }
}