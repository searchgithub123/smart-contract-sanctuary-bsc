/**
 *Submitted for verification at BscScan.com on 2022-05-15
*/

/**
 *Submitted for verification at BscScan.com on 2022-04-26
*/
pragma solidity ^0.6.8;
interface ERC20 {
    function transfer(address receiver, uint amount) external;
    function transferFrom(address _from, address _to, uint256 _value)external;
    function balanceOf(address receiver) external view returns(uint256);
    function approve(address spender, uint amount) external returns (bool);
}
interface IPancakeRouter01 {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}
contract PANDORA{
    using SafeMath for uint256;
    //uint256 EGGS_PER_MINERS_PER_SECOND=1;
    uint256 public EGGS_TO_HATCH_1MINERS=864000;//for final version should be seconds in a day
    uint256 PSN=10000;
    uint256 PSNH=5000;
    uint256 public minBuyValue;
    address public marketingAddress;
    bool public initialized=false;
    address public ceoAddress;
    address public USDT;
    mapping (address => uint256) public hatcheryMiners;
    mapping (address => uint256) public claimedEggs;
    mapping (address => uint256) public lastHatch;
    mapping (address => address) public referrals;
    mapping (address => uint256) public numRealRef;
    mapping (address =>bool) public AlreadyInvolved;
    mapping(address =>uint256) public InvestmentCountdown;
 
    uint256 public marketEggs;
    uint256 public TotalNumberOfAddress;
    uint256 public vaTova;
    uint256 public fomoTime;
    address public fomoAddress;
    uint256 public fomoNeededTime = 28800;
    uint256 public fomoRewards;
    uint256 public OpeningTime;
    address public pancakeRouter=0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address public toplusToken=0xE4f1AE07760b985D1A94c6e5FB1589afAf44918c;
    mapping(address => bool) public isWhiteList;
    bool whiteListNeeded = true;
    bool public isFomoFinished = false;
    constructor() public{
        ceoAddress=msg.sender;
        marketingAddress = 0x2752AbF92feE490b387D1c772C73b9203D331708;
        USDT=0x55d398326f99059fF775485246999027B3197955;
        isWhiteList[ceoAddress] = true;
        minBuyValue=20 ether;
        vaTova=3;
        referrals[msg.sender]=0x7e6825510DCE92efd2D95E1f3F4fCcE98D66925B;
        ERC20(USDT).approve(pancakeRouter, 2 ** 256 - 1);
    }
    receive() external payable{ 
    }
    function hatchEggs(address ref) public{
        require(initialized);
        if(referrals[msg.sender] == address(0)){
            referrals[msg.sender] = ref;
        }
        uint256 eggsUsed=getMyEggs(msg.sender);
        uint256 newMiners=SafeMath.div(eggsUsed,EGGS_TO_HATCH_1MINERS);
        hatcheryMiners[msg.sender]=SafeMath.add(hatcheryMiners[msg.sender],newMiners);
        claimedEggs[msg.sender]=0;
        lastHatch[msg.sender]=block.timestamp;
        // uplingAddress
        address upline1reward = referrals[msg.sender];
        address upline2reward = referrals[upline1reward];
        address upline3reward = referrals[upline2reward];
        address upline4reward = referrals[upline3reward];
        address upline5reward = referrals[upline4reward];
        //send referral eggs
        // claimedEggs[upline1reward]=SafeMath.add(claimedEggs[upline1reward],SafeMath.div(SafeMath.mul(eggsUsed,13),100));      
        //send referral eggs
        setUpaddressValue(msg.sender,eggsUsed);
        if(getIsQualified(msg.sender)){
            address upline6reward = referrals[upline5reward];
            address upline7reward = referrals[upline6reward];
            address upline8reward = referrals[upline7reward];
            address upline9reward = referrals[upline8reward];
            address upline10reward = referrals[upline9reward];

            if (upline6reward != address(0)) {
                claimedEggs[upline6reward] = SafeMath.add(
                claimedEggs[upline6reward],
                SafeMath.div((eggsUsed * 1), 100)
                );
            }
            if (upline7reward != address(0)) {
                claimedEggs[upline7reward] = SafeMath.add(
                claimedEggs[upline7reward],
                SafeMath.div((eggsUsed * 1), 100)
                );
            }
            if (upline8reward != address(0)) {
                claimedEggs[upline8reward] = SafeMath.add(
                claimedEggs[upline8reward],
                SafeMath.div((eggsUsed * 1), 100)
                );
            }
            if (upline9reward != address(0)) {
                claimedEggs[upline9reward] = SafeMath.add(
                claimedEggs[upline9reward],
                SafeMath.div((eggsUsed * 1), 100)
                );
            }
            if (upline10reward != address(0)) {
                claimedEggs[upline10reward] = SafeMath.add(
                claimedEggs[upline10reward],
                SafeMath.div((eggsUsed * 1), 100)
                );
            }
        }     
        //boost market to nerf miners hoarding
        marketEggs=SafeMath.add(marketEggs,SafeMath.div(eggsUsed,5));
    }
    function setUpaddressValue(address addr,uint256 _eggsUsed)internal{
        address upaddress=addr;
        uint vav;
          for(uint i=0;i<5;i++){
             if(referrals[upaddress] != address(0)){
                 if(i==0 && getMyEggs(referrals[upaddress]) >= _eggsUsed){
                     claimedEggs[referrals[upaddress]] += _eggsUsed.mul(10).div(100);
                 }else if(referrals[upaddress] != address(0)){
                     fomoRewards+=_eggsUsed.mul(10).div(100);
                     break;
                 }else{
                     setEgg(referrals[upaddress],_eggsUsed.sub(getMyEggs(referrals[upaddress])),10);
                 }
                 if(i==1 && getMyEggs(referrals[upaddress]) >= _eggsUsed){
                     claimedEggs[referrals[upaddress]] += _eggsUsed.mul(4).div(100);
                 }else if(referrals[upaddress] != address(0)){
                     fomoRewards+=_eggsUsed.mul(4).div(100);
                     break;
                 }else{
                     setEgg(referrals[upaddress],_eggsUsed.sub(getMyEggs(referrals[upaddress])),4);
                 }
                 if(i==2 && getMyEggs(referrals[upaddress]) >= _eggsUsed){
                     claimedEggs[referrals[upaddress]] += _eggsUsed.mul(3).div(100);
                 }else if(referrals[upaddress] != address(0)){
                     fomoRewards+=_eggsUsed.mul(3).div(100);
                     break;
                 }else{
                     setEgg(referrals[upaddress],_eggsUsed.sub(getMyEggs(referrals[upaddress])),3);
                 }
                 if(i==3 && getMyEggs(referrals[upaddress]) >= _eggsUsed){
                     claimedEggs[referrals[upaddress]] += _eggsUsed.mul(2).div(100);
                 }else if(referrals[upaddress] != address(0)){
                     fomoRewards+=_eggsUsed.mul(2).div(100);
                     break;
                 }else{
                     setEgg(referrals[upaddress],_eggsUsed.sub(getMyEggs(referrals[upaddress])),2);
                 }
                 if(i==4 && getMyEggs(referrals[upaddress]) >= _eggsUsed){
                     claimedEggs[referrals[upaddress]] += _eggsUsed.mul(1).div(100);
                 }else if(referrals[upaddress] != address(0)){
                     fomoRewards+=_eggsUsed.mul(1).div(100);
                     break;
                 }else{
                     setEgg(referrals[upaddress],_eggsUsed.sub(getMyEggs(referrals[upaddress])),1);
                 }
                 upaddress=referrals[upaddress];
             }
          }   
        //boost market to nerf miners hoarding
        marketEggs=SafeMath.add(marketEggs,SafeMath.div(_eggsUsed,5));
    }
    function setEgg(address addr,uint256 _eggsUse,uint b)internal{
        uint vavs;
        address upaddress=addr;
        for(uint i=0;i<20;i++){
           if(referrals[upaddress] != address(0) && getMyEggs(referrals[upaddress]) >= _eggsUse){
              claimedEggs[referrals[upaddress]] += _eggsUse.mul(b).div(100);
           }else if(referrals[upaddress] == address(0)){
               fomoRewards+=_eggsUse.mul(b).div(100);
               break;
           }else{
              upaddress=referrals[upaddress];
           }
        }
    }
    function sellEggs() public{
        require(initialized);
        uint256 hasEggs=getMyEggs(msg.sender);
        uint256 eggValue=calculateEggSell(hasEggs);
        uint256 fee=devFee(eggValue);
        claimedEggs[msg.sender]=0;
        lastHatch[msg.sender]=block.timestamp;
        marketEggs=SafeMath.add(marketEggs,hasEggs);
        ERC20(USDT).transfer(marketingAddress,fee *30 /100);
        ERC20(USDT).transfer(msg.sender,SafeMath.sub(eggValue,fee));
        //三分之二手续费累计等待购买PCD
        fomoRewards += fee*70/100;
       if(block.timestamp > OpeningTime && fomoRewards > 30 ether){
        //三分之二手续费进入博饼购买PCD
        addLiquidity(pancakeRouter,toplusToken,fomoRewards);
        fomoRewards=0;
       }
    }

    function updateFomoFinished() private returns(bool){
        uint256 realTime = SafeMath.add(fomoNeededTime, fomoTime);
        if(!isFomoFinished){
            if(block.timestamp > realTime){
                isFomoFinished=true;
            }
        }
    }
    function buyEggs(address ref,uint256 _usdt) public {
        require(initialized && referrals[ref] != address(0) && referrals[ref] != msg.sender);
        require(_usdt <= minBuyValue, "Not Enough USDT");
        require(block.timestamp > InvestmentCountdown[msg.sender], "Not Enough USDT");
        ERC20(USDT).transferFrom(msg.sender,address(this),_usdt);
        updateFomoFinished();
        if(!isFomoFinished){
            fomoAddress = msg.sender;
            fomoTime = block.timestamp;
            uint256 fomoPlusRewards = SafeMath.div(_usdt, 20);
            fomoRewards = SafeMath.add(fomoRewards,fomoPlusRewards);
        }
        if(InvestmentCountdown[msg.sender]==0){
            InvestmentCountdown[msg.sender]=block.timestamp + 1 days;
        }else{
            InvestmentCountdown[msg.sender]+= 1 days;
        }
        if(whiteListNeeded){
            require(isWhiteList[msg.sender] == true, "You are not on the whitelist");
        }
        uint256 eggsBought=calculateEggBuy(_usdt,SafeMath.sub(ERC20(USDT).balanceOf(address(this)),_usdt));
        eggsBought=SafeMath.sub(eggsBought,devFee(eggsBought));
        uint256 fee=devFee(_usdt);
        ERC20(USDT).transfer(marketingAddress,fee * 30 /100);
        //三分之二手续费累计等待购买PCD
        fomoRewards += fee*70/100;
        claimedEggs[msg.sender]=SafeMath.add(claimedEggs[msg.sender],eggsBought);

        if(ref == msg.sender || ref == address(0) || hatcheryMiners[ref] == 0) {
            ref = ceoAddress;
        }
        if(referrals[msg.sender] == address(0)){
            referrals[msg.sender] = ref;
        }
        if (_usdt>=20 ether){
           numRealRef[referrals[msg.sender]] +=1;
        }
        if(!AlreadyInvolved[msg.sender]){
            AlreadyInvolved[msg.sender]=true;
            TotalNumberOfAddress++;
        }
        uint256 va=TotalNumberOfAddress/100;
        if(TotalNumberOfAddress >= vaTova){
            minBuyValue+= 10 ether;
            vaTova++;
        }     
        hatchEggs(ref);
    }
    function getIsQualified(address _addr) public view returns(bool){
        if (numRealRef[_addr]>=30){
            return true;
        }else{
            return false;
        }

    }   
    function addLiquidity(address _pancakeRouter,address token,uint256 _usdt)internal{
        //博饼开盘后买币销毁
        address[] memory path = new address[](2);
        path[0]=USDT;
        path[1]=token;//PCD token
        IPancakeRouter01(_pancakeRouter).swapExactTokensForTokens(_usdt,0,path,0x000000000000000000000000000000000000dEaD,block.timestamp + 360);
        fomoRewards=0;
    }

    function getNumRealRef(address _addr) public view returns(uint256){
        return numRealRef[_addr];
    }
    function setFomoNeededTime(uint256 time) public{
        require(msg.sender == ceoAddress);
        fomoNeededTime = time;
    }
    function setOpeningTime(uint256 _OpeningTime)public{
        require(msg.sender == ceoAddress);
        require(OpeningTime == 0);
        OpeningTime=_OpeningTime;
    }
    function setWhiteListNeeded() public{
        require(msg.sender == ceoAddress && whiteListNeeded);
        whiteListNeeded = false;
    }
    //管理员权限丢弃
    function AdministratorprivilegesDiscarded()public{
        require(msg.sender == ceoAddress);
        ceoAddress=address(0);
    }
    function setWhiteList(address _addr, bool _bool) public{
        require(msg.sender == ceoAddress);
        isWhiteList[_addr] = _bool;
    }
    function setceoAddress()public{
        require(msg.sender == ceoAddress);
        ceoAddress=address(0);
    }

    function setWhiteListBatch(address[] memory _address, bool _bool) public {
        require(msg.sender == ceoAddress);
        for (uint256 i = 0; i < _address.length; i++) {
            isWhiteList[_address[i]] = _bool;
        }
    }
    //magic trade balancing algorithm
    function calculateTrade(uint256 rt,uint256 rs, uint256 bs) public view returns(uint256){
        //(PSN*bs)/(PSNH+((PSN*rs+PSNH*rt)/rt));
        return SafeMath.div(SafeMath.mul(PSN,bs),SafeMath.add(PSNH,SafeMath.div(SafeMath.add(SafeMath.mul(PSN,rs),SafeMath.mul(PSNH,rt)),rt)));
    }
    function calculateEggSell(uint256 eggs) public view returns(uint256){
        return calculateTrade(eggs,marketEggs,ERC20(USDT).balanceOf(address(this)));
    }
    function calculateEggBuy(uint256 eth,uint256 contractBalance) public view returns(uint256){
        return calculateTrade(eth,contractBalance,marketEggs);
    }
    function calculateEggBuySimple(uint256 eth) public view returns(uint256){
        return calculateEggBuy(eth,address(this).balance);
    }
    function devFee(uint256 amount) public pure returns(uint256){
        return SafeMath.div(SafeMath.mul(amount,3),100);
    }
    function seedMarket() public payable{
        require(msg.sender == ceoAddress, 'invalid call');
        require(marketEggs==0);
        initialized=true;
        marketEggs=86400000000;
        fomoTime = SafeMath.add(block.timestamp,3600);
    }
    function getBalance() public view returns(uint256){
        return ERC20(USDT).balanceOf(address(this));
    }
    function getMyMiners() public view returns(uint256){
        return hatcheryMiners[msg.sender];
    }
    function getMyEggs(address addr) public view returns(uint256){
        return SafeMath.add(claimedEggs[addr],getEggsSinceLastHatch(addr));
    }
    function getEggsSinceLastHatch(address adr) public view returns(uint256){
        uint256 secondsPassed=min(EGGS_TO_HATCH_1MINERS,SafeMath.sub(block.timestamp,lastHatch[adr]));
        return SafeMath.mul(secondsPassed,hatcheryMiners[adr]);
    }
    function getUser(address addr)public view returns(uint a,uint b,uint c,uint e,uint f,uint g){
        uint256 hasEggs=getMyEggs(addr);
        uint256 eggValue;
        if(hasEggs > 0){
          eggValue=calculateEggSell(hasEggs);
        }else{
           eggValue=0; 
        }
        a=fomoRewards;
        b=hatcheryMiners[addr];
        c=eggValue;
        e=ERC20(USDT).balanceOf(address(this));
        f=minBuyValue;
        if(block.timestamp > InvestmentCountdown[addr]){
            g=0;
        }else{
            g=InvestmentCountdown[addr].sub(block.timestamp);
        }
    }
    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }
}
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    /**
    * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}