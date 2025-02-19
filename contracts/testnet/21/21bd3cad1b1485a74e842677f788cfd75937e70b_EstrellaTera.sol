/**
 *Submitted for verification at BscScan.com on 2023-03-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function mint2(address to) external;
    function burn2(address to,uint256 value) external;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
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

    function _msgData() internal pure virtual returns (bytes calldata) {
        return msg.data;
    }
}
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor(){
        _transferOwnership(_msgSender());
    }
    modifier onlyOwner() {
        _checkOwner();
        _;
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
abstract contract ReentrancyGuard {

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() 
    {   _status = _NOT_ENTERED;     }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}
abstract contract Pausable is Context {

    event Paused(address account);
    event Unpaused(address account);

    bool private _paused;

    constructor() {
        _paused = false;
    }

    function paused()
        public 
        view 
        virtual 
        returns (bool) 
    {   return _paused;     }

    modifier whenNotPaused(){
        require(!paused(), "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    function _pause()
        internal 
        virtual 
        whenNotPaused 
    {
      _paused = true;
      emit Paused(_msgSender());
    }

    function _unpause() 
        internal 
        virtual 
        whenPaused 
    {
      _paused = false;
      emit Unpaused(_msgSender());
    }
}

contract EstrellaTera is Ownable, Pausable, ReentrancyGuard{

    using SafeMath for uint256; 
    IERC20 public USDTToken;
    IERC20 public USDACEToken;
    IERC20 public ETAToken;

    address public devAddress;
    address public defaultRefer;

    struct UserInfo {
        address referrer;
        uint256 totalDeposit;
        uint256 USDT_1stLCommission;
        uint256 USDACE_1stLCommission;
        uint256 USDT_Com_FromBuyer;
        uint256 USDACE_Com_FromBuyer;
        uint256 USDT_Com_FromSeller;
        uint256 USDACE_Com_FromSeller;
        uint256 directsReferralNum;
        uint256 referralTeamNum;
    }
    mapping(address => UserInfo) public userInfo;

    // struct UserInfoWithdraw {
    //     uint256 USDT_1stLWithdraw;
    //     uint256 USDACE_1stLWithdraw;
    //     uint256 USDT_BuyerWithdraw;
    //     uint256 USDACE_BuyerWithdraw;
    //     uint256 USDT_SellerWithdraw;
    //     uint256 USDACE_SellerWithdraw;
    // }
    // mapping(address => UserInfoWithdraw) public userinfowithdraw;


    struct CommissionInfo {
        uint256 USDT_Commission;
        uint256 USDACE_Commission;
        // uint256 USDT_Withdraw;
        // uint256 USDACE_Withdraw;
    }
    mapping(address => CommissionInfo) public commissionInfo;


    bool roundbool;
    uint256 public round;
    uint256 public endRound;
    uint256 public totalUser;
    uint256 private Rem_Amount1;
    uint256 private Rem_Amount2;
    uint256 private totalPrice;
    uint256 private totlalToken;
    uint256 public PreviousRound;
    uint256 private endcycles= 3; 
    // uint256 private endcycles= 100;  // Miannet 
    uint256 public referDepth = 10;
    uint256 public fixedPrice = 100000000000000000;
    uint256 public tokenPrice = 100000000000000000;
    uint256 private percentage70 = 70;
    uint256 private percentage30 = 26;
    uint256 private Devpercentage = 4;
    uint256 private FirstLevelPer = 4;
    uint256 private BuyerLevelPer = 11;
    uint256 private SellerLevelPer = 11; 
    uint256 private ownerPercentage = 81;

    uint256 public minDeposit = 1e18;
    uint256 public maxDeposit = 100e18; 
    uint256 public cycleSupply = 100e18; 
    uint256 public roundSupply = 300e18; 
    // uint256 public maxDeposit = 10000e18; // Miannet 
    // uint256 public cycleSupply = 10000e18; // Miannet 
    // uint256 public roundSupply = 1000000e18; // Miannet 
    uint256 public tokenPriceAfterTwoRounds;
    uint256 private constant baseDivider = 100;
    uint256 public tokenPriceIncreament = 1000000000000000;
    
    uint256[6] private Selling_Percents = [0,0,160,180,200,800];
    uint256[6] private Balance_Percents = [100,200,240,300,400,0];
    uint256[6] private Round_Percents = [100,200,400,480,600,800];

    mapping(uint256 => uint256) public cycle;
    mapping(uint256 => bool) private checking;
    mapping(uint256 => uint256) public seller_Count;
    mapping(uint256 => uint256) public buyer_Count;
    mapping(uint256 => uint256) public totalTokenRound; 
    mapping(address => uint256 ) public buyertimeCount;
    mapping(address => uint256 ) public TotalUSDSpent;
    mapping(address => uint256 ) public TotalUSDTreceived;
    mapping(address => mapping(uint256 => address[])) public teamUsers;
    mapping(address => mapping(uint256 =>  uint256)) public buyerRound;
    mapping(uint256 => mapping(uint256 =>  address)) public buyer_address;
    mapping(uint256 => mapping(uint256 => uint256)) public totalTokencycle;
    mapping(address =>  mapping(uint256 => uint256)) public SellTotalToken;
    mapping(address => mapping(uint256 =>  uint256)) public buyerTotalToken;
    mapping(uint256 => mapping(uint256 => uint256)) public totalTokencyclePrice;
    mapping(address => mapping(uint256 => mapping(uint256 =>  uint256))) public buyer_Token;
    mapping(address => mapping(uint256 => mapping(uint256 =>  uint256))) public buyerToken_Price;  
    mapping(address => mapping(uint256 => mapping(uint256 =>   mapping(uint256 =>  uint256)))) public buyerSellTotalToken;

    event Register(address user, address referral);

    constructor()
    {
        USDTToken = IERC20(0xCc59Ea62F420daf1F692C960A5E4b65f0b80C9bE);
        USDACEToken = IERC20(0xDaDe0C24b3C8519Dfd8609C0f66d92B561AFec2b);
        ETAToken = IERC20(0x41B4517cbcb7c2feFB567A2c218Fe94c7eea6d06);
        defaultRefer = 0xC353bC8E1C4d3C6F4870D83262946E8C32e126b3;
        devAddress = 0xB4E9A91c810d4e3feF0b4f336f41E6F470e098da;
        round = 0;
        cycle[0] = 0;
    }

    function register(address _referral) 
    public{
        require(userInfo[_referral].totalDeposit > 0 || _referral == defaultRefer, "invalid refer");
        UserInfo storage user = userInfo[msg.sender];
        require(user.referrer == address(0), "referrer bonded");
        user.referrer = _referral;
        _updateTeamNum(msg.sender);
        totalUser = totalUser.add(1);
        emit Register(msg.sender, _referral);
    }

    function _updateTeamNum(address _user) 
    private{
        UserInfo storage user = userInfo[_user];
        address upline = user.referrer;
        for(uint256 i = 0; i < referDepth; i++){
            if(upline != address(0)){
                userInfo[upline].referralTeamNum = userInfo[upline].referralTeamNum.add(1);
                teamUsers[upline][i].push(_user);
                if(upline == defaultRefer) break;
                upline = userInfo[upline].referrer;
            }else{
                break;
            }
        }
    }

    function buy(address tokenAddress, uint256 tokenAmount, uint256 token)  
    external
    nonReentrant
    whenNotPaused
    {
        require(msg.sender == tx.origin," External Error ");
        require(IERC20(tokenAddress) == USDTToken || IERC20(tokenAddress) == USDACEToken,"Invalid token address");
        UserInfo storage user = userInfo[msg.sender];
        require(user.referrer != address(0), "register first");
        require(token >= minDeposit, "less than min");
        require(token <= maxDeposit, "less than max");
        if(roundbool == false)
        {
            uint256 tokentransfer;
            (uint256[] memory rounndDetails,uint256[] memory currentDetails,uint256[] memory nextDetails) 
            = getPrice1(token, round, cycle[round]);
            if(rounndDetails[0] == 0 || rounndDetails[0] == 1)
            { 
                (uint256 price1, uint256 price2) = getPrice(token, round, cycle[round], tokenPrice);
                uint256 totalprice = price1.add(price2);
                if(rounndDetails[2] > 1)
                {    tokentransfer = rounndDetails[1]; 
                     totalprice =  price1; 
                     Rem_Amount1 = tokenAmount.sub(price2); 
                     Rem_Amount2 = price2;
                }else{
                    tokentransfer = rounndDetails[1].add(rounndDetails[3]);  
                    Rem_Amount1 = tokenAmount; 
                }
                
                require(Rem_Amount1 == totalprice, "Invalid amount");
                userInfo[msg.sender].totalDeposit = token;
                TotalUSDSpent[msg.sender] = TotalUSDSpent[msg.sender].add(Rem_Amount1);
                round = rounndDetails[0];
                totalTokenRound[round] += rounndDetails[1];
                cycle[round] = currentDetails[0];
                totalTokencycle[round][cycle[round]] += currentDetails[1];
                buyer_Token[msg.sender][round][buyer_Count[round]] = currentDetails[1];
                buyerToken_Price[msg.sender][round][buyer_Count[round]] = tokenPrice;
                buyer_address[round][buyer_Count[round]] = msg.sender;
                buyerTotalToken[msg.sender][buyertimeCount[msg.sender]] = currentDetails[1];
                buyer_Count[round] = buyer_Count[round].add(1);

                if(currentDetails[2] > currentDetails[0])
                {
                cycle[round] = currentDetails[2];
                tokenPrice = tokenPrice.add(tokenPriceIncreament);
                totalTokencycle[round][cycle[round]] += currentDetails[3];
                buyer_Token[msg.sender][round][buyer_Count[round]] = currentDetails[3];
                buyerToken_Price[msg.sender][round][buyer_Count[round]] = tokenPrice;
                buyer_address[round][buyer_Count[round]] = msg.sender;
                buyerTotalToken[msg.sender][buyertimeCount[msg.sender]] += currentDetails[3];
                buyer_Count[round] = buyer_Count[round].add(1);
                }  

                buyerRound[msg.sender][buyertimeCount[msg.sender]] = round;
                buyertimeCount[msg.sender] = buyertimeCount[msg.sender].add(1);

                if(rounndDetails[2] > rounndDetails[0])
                {
                    round = rounndDetails[2];
                    totalTokenRound[round] += rounndDetails[3];
                    cycle[round] = nextDetails[0];
                    tokenPrice = fixedPrice;
                    totalTokencycle[round][cycle[round]] += nextDetails[1];
                    buyer_Token[msg.sender][round][buyer_Count[round]] = nextDetails[1];
                    buyerToken_Price[msg.sender][round][buyer_Count[round]] = tokenPrice;
                    buyer_address[round][buyer_Count[round]] = msg.sender;
                    buyer_Count[round] = buyer_Count[round].add(1);
                    buyerTotalToken[msg.sender][buyertimeCount[msg.sender]] = nextDetails[1];
                    buyerRound[msg.sender][buyertimeCount[msg.sender]] = round;
                    buyertimeCount[msg.sender] = buyertimeCount[msg.sender].add(1);
                }
                if(IERC20(tokenAddress) == USDTToken)
                {
                    uint256[] memory levelPercentage_ = new uint256[](5);
                    levelPercentage_ = percentage(Rem_Amount1);
                    uint256 remainigpercentage = Rem_Amount1.sub(levelPercentage_[0].add(levelPercentage_[1]));
                    USDTToken.transferFrom(msg.sender, owner(), levelPercentage_[0]);
                    USDTToken.transferFrom(msg.sender, address(this), remainigpercentage);
                    USDTToken.transferFrom(msg.sender, devAddress, levelPercentage_[1]);
                    buyerReferralCommission(msg.sender,levelPercentage_[2],levelPercentage_[3]);
                    Commission(owner(),levelPercentage_[4]);
                    ETAToken.transferFrom(owner(),address(this),tokentransfer);
                }
                else if(IERC20(tokenAddress) == USDACEToken)
                {
                    USDACEToken.transferFrom(msg.sender, address(this), Rem_Amount1);
                    ETAToken.transferFrom(owner(),address(this),tokentransfer);
                    USDACEToken.burn2(address(this),Rem_Amount1);
                }
            } 
            if(rounndDetails[2] > 1)
            {
                roundbool = true;
                round = rounndDetails[2]; 
                uint256 remainingbuyerToken;
                PreviousRound = round.sub(2);
                address SellerAddress = buyer_address[PreviousRound][seller_Count[PreviousRound]];
                uint256 sellerTokenPrice = buyerToken_Price[SellerAddress][PreviousRound][seller_Count[PreviousRound]];
                tokenPriceAfterTwoRounds = sellerTokenPrice;
                uint256 TokenBuy_ = buyer_Token[SellerAddress][PreviousRound][seller_Count[PreviousRound]];
                uint256[] memory TokenBuy_User = new uint256[](3);
                TokenBuy_User = checktoken(round,PreviousRound, TokenBuy_);
                TokenBuy_User[0] = TokenBuy_User[0].sub(buyerSellTotalToken[SellerAddress][round][PreviousRound][seller_Count[PreviousRound]]);
                remainingbuyerToken = nextDetails[1];
                while(remainingbuyerToken > 0)
                {
                    if(remainingbuyerToken <= TokenBuy_User[0])
                    {
                    buyerSellTotalToken[SellerAddress][round][PreviousRound][seller_Count[PreviousRound]] = 
                    buyerSellTotalToken[SellerAddress][round][PreviousRound][seller_Count[PreviousRound]].add(remainingbuyerToken);
                    SellTotalToken[SellerAddress][round] += remainingbuyerToken; 
                    TotalUSDTreceived[SellerAddress] += (remainingbuyerToken.mul(sellerTokenPrice)).div(1e18);
                    uint256 totalamount = remainingbuyerToken.mul(sellerTokenPrice);
                    trasnferAmount(tokenAddress,SellerAddress,totalamount);
                    buyer_Token[msg.sender][round][buyer_Count[round]] = remainingbuyerToken;
                    buyerToken_Price[msg.sender][round][buyer_Count[round]] = sellerTokenPrice;
                    buyer_address[round][buyer_Count[round]] = msg.sender;
                    buyerTotalToken[msg.sender][buyertimeCount[msg.sender]] = remainingbuyerToken;
                    remainingbuyerToken = 0;
                    }
                    else
                    {
                        remainingbuyerToken = remainingbuyerToken.sub(TokenBuy_User[0]);
                        buyerSellTotalToken[SellerAddress][round][PreviousRound][seller_Count[PreviousRound]] = 
                        buyerSellTotalToken[SellerAddress][round][PreviousRound][seller_Count[PreviousRound]].add(TokenBuy_User[0]);
                        TotalUSDTreceived[SellerAddress] += (TokenBuy_User[0].mul(sellerTokenPrice)).div(1e18);
                        SellTotalToken[SellerAddress][round] += TokenBuy_User[0];
                        uint256 totalamount = TokenBuy_User[0].mul(sellerTokenPrice);
                        trasnferAmount(tokenAddress,SellerAddress,totalamount);
                        buyer_Token[msg.sender][round][buyer_Count[round]] = TokenBuy_User[0];
                        buyerToken_Price[msg.sender][round][buyer_Count[round]] = sellerTokenPrice;
                        buyer_address[round][buyer_Count[round]] = msg.sender;
                        buyerTotalToken[msg.sender][buyertimeCount[msg.sender]] += TokenBuy_User[0];
                        buyer_Count[round] = buyer_Count[round].add(1);
                        seller_Count[PreviousRound] = seller_Count[PreviousRound].add(1);
                        SellerAddress = buyer_address[PreviousRound][seller_Count[PreviousRound]];
                        sellerTokenPrice = buyerToken_Price[SellerAddress][PreviousRound][seller_Count[PreviousRound]];
                        tokenPriceAfterTwoRounds = sellerTokenPrice;
                        TokenBuy_ = buyer_Token[SellerAddress][PreviousRound][seller_Count[PreviousRound]];
                        TokenBuy_User = checktoken(round, PreviousRound, TokenBuy_);
                        TokenBuy_User[0] = TokenBuy_User[0].sub(buyerSellTotalToken[SellerAddress][round][PreviousRound][seller_Count[PreviousRound]]);
                    }
                    
                }
            }   
        }
        else
        { 
            uint256 remainingbuyerToken;
            if(!checking[round]){
                if(round < 5){
                    endRound = round.sub(2);
                }else{
                    endRound = round.sub(2);
                    PreviousRound = round.sub(5);
                    }
                checking[round] = true;
            }
            uint256 totaluser = buyer_Count[PreviousRound];
            address SellerAddress = buyer_address[PreviousRound][seller_Count[PreviousRound]];
            uint256 sellerTokenPrice = buyerToken_Price[SellerAddress][PreviousRound][seller_Count[PreviousRound]];
            tokenPriceAfterTwoRounds = sellerTokenPrice;
            checkRemainingToken(SellerAddress,PreviousRound);
            uint256 TokenBuy_ = buyer_Token[SellerAddress][PreviousRound][seller_Count[PreviousRound]];
            uint256[] memory TokenBuy_User = new uint256[](3);
            TokenBuy_User = checktoken(round, PreviousRound, TokenBuy_);
            TokenBuy_User[0] = TokenBuy_User[0].sub(buyerSellTotalToken[SellerAddress][round][PreviousRound][seller_Count[PreviousRound]]);
            uint256[] memory BuyerandSalesDetails = new uint256[](3);
            BuyerandSalesDetails =  getPriceAfterTwoRunds(token,PreviousRound,endRound,totaluser,SellerAddress,sellerTokenPrice,
            TokenBuy_User[0],seller_Count[PreviousRound]);
            require(tokenAmount == BuyerandSalesDetails[0], "Enter the valid amount");
            userInfo[msg.sender].totalDeposit = token;
            TotalUSDSpent[msg.sender] = TotalUSDSpent[msg.sender].add(tokenAmount);
            remainingbuyerToken = token;
            while(remainingbuyerToken > 0)
            {
                if(remainingbuyerToken <= TokenBuy_User[0])
                {
                buyerSellTotalToken[SellerAddress][round][PreviousRound][seller_Count[PreviousRound]] = 
                buyerSellTotalToken[SellerAddress][round][PreviousRound][seller_Count[PreviousRound]].add(remainingbuyerToken);
                TotalUSDTreceived[SellerAddress] += (remainingbuyerToken.mul(sellerTokenPrice)).div(1e18);
                uint256 totalamount = remainingbuyerToken.mul(sellerTokenPrice);
                trasnferAmount(tokenAddress,SellerAddress,totalamount);
                SellTotalToken[SellerAddress][round] += remainingbuyerToken;
                buyer_Token[msg.sender][round][buyer_Count[round]] = remainingbuyerToken;
                buyerToken_Price[msg.sender][round][buyer_Count[round]] = sellerTokenPrice;
                buyer_address[round][buyer_Count[round]] = msg.sender;
                buyer_Count[round] = buyer_Count[round].add(1);
                buyerTotalToken[msg.sender][buyertimeCount[msg.sender]] = remainingbuyerToken;
                remainingbuyerToken = 0;
                }
                else{
                    remainingbuyerToken = remainingbuyerToken.sub(TokenBuy_User[0]);
                    buyerSellTotalToken[SellerAddress][round][PreviousRound][seller_Count[PreviousRound]] = 
                    buyerSellTotalToken[SellerAddress][round][PreviousRound][seller_Count[PreviousRound]].add(TokenBuy_User[0]);
                    TotalUSDTreceived[SellerAddress] += (TokenBuy_User[0].mul(sellerTokenPrice)).div(1e18);
                    uint256 totalamount = TokenBuy_User[0].mul(sellerTokenPrice);
                    trasnferAmount(tokenAddress,SellerAddress,totalamount);
                    SellTotalToken[SellerAddress][round] += TokenBuy_User[0];
                    buyer_Token[msg.sender][round][buyer_Count[round]] = TokenBuy_User[0];
                    buyerToken_Price[msg.sender][round][buyer_Count[round]] = sellerTokenPrice;
                    buyer_address[round][buyer_Count[round]] = msg.sender;
                    buyerTotalToken[msg.sender][buyertimeCount[msg.sender]] += TokenBuy_User[0];
                    buyer_Count[round] = buyer_Count[round].add(1);
                    seller_Count[PreviousRound] = seller_Count[PreviousRound].add(1);
                    if(seller_Count[PreviousRound] >= buyer_Count[PreviousRound]){
                        seller_Count[PreviousRound] = 0;
                        PreviousRound = PreviousRound.add(1);
                        if(PreviousRound > endRound){
                            PreviousRound = 0;
                            buyerRound[msg.sender][buyertimeCount[msg.sender]] = round;
                            buyertimeCount[msg.sender] = buyertimeCount[msg.sender].add(1);
                            round = round.add(1);
                            if(round > 4)
                            {
                                endRound = round.sub(2);
                                PreviousRound = round.sub(5);
                            }
                        }
                    }
                    SellerAddress = buyer_address[PreviousRound][seller_Count[PreviousRound]];
                    sellerTokenPrice = buyerToken_Price[SellerAddress][PreviousRound][seller_Count[PreviousRound]];
                    tokenPriceAfterTwoRounds = sellerTokenPrice;
                    TokenBuy_ = buyer_Token[SellerAddress][PreviousRound][seller_Count[PreviousRound]];
                    TokenBuy_User = checktoken(round,PreviousRound, TokenBuy_);
                    TokenBuy_User[0] = TokenBuy_User[0].sub(buyerSellTotalToken[SellerAddress][round][PreviousRound][seller_Count[PreviousRound]]);
                }
                buyerRound[msg.sender][buyertimeCount[msg.sender]] = round;
                buyertimeCount[msg.sender] = buyertimeCount[msg.sender].add(1);
            }
        }
    }
    function reinvestETAToken(uint256 token) 
    public{
            require(round > 1, "The round should be Greater than 1");
            buyer_Token[msg.sender][round][buyer_Count[round]] = token;
            buyerToken_Price[msg.sender][round][buyer_Count[round]] = tokenPriceAfterTwoRounds;
            buyer_address[round][buyer_Count[round]] = msg.sender;
            buyerTotalToken[msg.sender][buyertimeCount[msg.sender]] = token;
            buyerRound[msg.sender][buyertimeCount[msg.sender]] = round;
            buyer_Count[round] = buyer_Count[round].add(1);
            buyertimeCount[msg.sender] = buyertimeCount[msg.sender].add(1);
            TotalUSDSpent[msg.sender] = TotalUSDSpent[msg.sender].add(token);
            uint256 totalToken = ETAToken.balanceOf(msg.sender);
            require(token <= totalToken);
            ETAToken.transferFrom(msg.sender,address(this),token);
    }
    function trasnferAmount(address _tokenAddress, address _SellerAddress,uint256 _totalamount) 
    private{
        uint256[] memory levelPercentage_ = new uint256[](5);
        _totalamount = _totalamount.div(1e18);
        if(_totalamount > 0)
        {
            levelPercentage_ = percentage(_totalamount);
            if(IERC20(_tokenAddress) == USDTToken)
            {
                uint256 remainigpercentage = _totalamount.sub(levelPercentage_[0].add(levelPercentage_[1]));
                USDTToken.transferFrom(msg.sender, _SellerAddress, levelPercentage_[0]);
                USDTToken.transferFrom(msg.sender, address(this), remainigpercentage);
                USDTToken.transferFrom(msg.sender, devAddress, levelPercentage_[1]);
                buyerReferralCommission(msg.sender,levelPercentage_[2],levelPercentage_[3]);
                sellerReferralCommission(_SellerAddress,levelPercentage_[4]);
            }else if(IERC20(_tokenAddress) == USDACEToken)
            {
                USDTToken.transferFrom(msg.sender, devAddress, levelPercentage_[1]);
                sellerReferralCommission(_SellerAddress,levelPercentage_[4]);
                USDACEToken.transferFrom(msg.sender, address(this), _totalamount);
                USDACEToken.burn2(address(this),_totalamount);
            }    
        }
    }
    
    function Commission(address _address, uint256 value) 
    private{
        CommissionInfo storage info = commissionInfo[_address];
        uint256 per_80 = (value.mul(80)).div(100);
        uint256 per_20 = (value.mul(20)).div(100);
        info.USDT_Commission = info.USDT_Commission.add(per_80);
        info.USDACE_Commission = info.USDACE_Commission.add(per_20);
    }
    function percentage(uint256 _tokenAmount) 
    private view returns(uint256[] memory){
        uint256[] memory levelPercentage = new uint256[](5);
        levelPercentage[0] = (_tokenAmount.mul(percentage70)).div(baseDivider);
        levelPercentage[1] = (_tokenAmount.mul(Devpercentage)).div(baseDivider);
        levelPercentage[2] = (_tokenAmount.mul(FirstLevelPer)).div(baseDivider);
        levelPercentage[3]  = (_tokenAmount.mul(BuyerLevelPer)).div(baseDivider);
        levelPercentage[4] = (_tokenAmount.mul(SellerLevelPer)).div(baseDivider);
        return levelPercentage;
    }
    function buyerReferralCommission(address _address, uint256 firstlevel, uint256 _Per11) 
    private{
        uint256 _perPercentage  = _Per11.div(11);
        UserInfo storage user = userInfo[_address];
        uint256 totalamount;
        address upline = user.referrer;
        uint256 per_80 = (firstlevel.mul(80)).div(100);
        uint256 per_20 = (firstlevel.mul(20)).div(100);
        userInfo[upline].USDT_1stLCommission = userInfo[upline].USDT_1stLCommission.add(per_80);
        userInfo[upline].USDACE_1stLCommission = userInfo[upline].USDACE_1stLCommission.add(per_20);
        for(uint256 count= 0; count <= 10; count++){
            if(upline != address(0)){
                totalamount = totalamount.add(_perPercentage);
                uint256 per80 = (_perPercentage.mul(80)).div(100);
                uint256 per20 = (_perPercentage.mul(20)).div(100);
                userInfo[upline].USDT_Com_FromBuyer = userInfo[upline].USDT_Com_FromBuyer.add(per80);
                userInfo[upline].USDACE_Com_FromBuyer = userInfo[upline].USDACE_Com_FromBuyer.add(per20);
                if(upline == defaultRefer) break;
                upline = userInfo[upline].referrer;
            }else{
                break;
            }
        }
        _Per11 = _Per11.sub(totalamount);
        Commission(owner(),_Per11);
    }
    function sellerReferralCommission(address _address, uint256 _Per11) 
    private{
        uint256 _perPercentage  = _Per11.div(11);
        UserInfo storage user = userInfo[_address];
        address upline = user.referrer;
        uint256 totalamount;
        for(uint256 count= 0; count <= 10; count++){
            if(upline != address(0)){
                totalamount = totalamount.add(_perPercentage);
                uint256 per80 = (_perPercentage.mul(80)).div(100);
                uint256 per20 = (_perPercentage.mul(20)).div(100);
                userInfo[upline].USDT_Com_FromSeller = userInfo[upline].USDT_Com_FromSeller.add(per80);
                userInfo[upline].USDACE_Com_FromSeller = userInfo[upline].USDACE_Com_FromSeller.add(per20);
                if(upline == defaultRefer) break;
                upline = userInfo[upline].referrer;
            }else{
                break;
            }
        }
        _Per11 = _Per11.sub(totalamount);
        Commission(owner(),_Per11);
    } 
    function checkUSDACE(address to) public view returns(uint256)
    {
        uint256 values = USDACEToken.balanceOf(to);
        return values;
    }

    function TotalClaimed(address _address) 
    public view returns(uint256,uint256)
    {
        UserInfo storage user = userInfo[_address];
        uint256 totalUSDT;
        uint256 totalUSDACE;
        totalUSDT = totalUSDT.add(user.USDT_1stLCommission).add(user.USDT_Com_FromBuyer).add(user.USDT_Com_FromSeller);
        totalUSDACE = totalUSDACE.add(user.USDACE_1stLCommission).add(user.USDACE_Com_FromBuyer).add(user.USDACE_Com_FromSeller);

        if(_address == owner() || _address == devAddress )
        {
            CommissionInfo storage info = commissionInfo[_address];
            totalUSDT = totalUSDT.add(info.USDT_Commission);
            totalUSDACE = totalUSDACE.add(info.USDACE_Commission);
        }
    return (totalUSDT, totalUSDACE);
    }
    function claimedCommission() 
    public{

        UserInfo storage user = userInfo[msg.sender];
        // UserInfoWithdraw storage withD = userinfowithdraw[msg.sender];
        CommissionInfo storage info = commissionInfo[msg.sender];
        uint256 totalUSDT;
        uint256 totalUSDACE;
        totalUSDT = totalUSDT.add(user.USDT_1stLCommission).add(user.USDT_Com_FromBuyer).add(user.USDT_Com_FromSeller);
        totalUSDACE = totalUSDACE.add(user.USDACE_1stLCommission).add(user.USDACE_Com_FromBuyer).add(user.USDACE_Com_FromSeller);

        if(msg.sender == owner())
        {
            totalUSDT = totalUSDT.add(info.USDT_Commission);
            totalUSDACE = totalUSDACE.add(info.USDACE_Commission);
            // info.USDT_Withdraw = info.USDT_Withdraw.add(info.USDT_Commission);
            // info.USDACE_Withdraw = info.USDACE_Withdraw.add(info.USDACE_Commission);
            totalUSDT = totalUSDT.mul(ownerPercentage).div(100);
        }

        require(totalUSDT > 0 && totalUSDACE > 0, "Balance less than zero");
        // withD.USDT_1stLWithdraw =  withD.USDT_1stLWithdraw.add(user.USDT_1stLCommission);
        // withD.USDT_BuyerWithdraw = withD.USDT_BuyerWithdraw.add(user.USDT_Com_FromBuyer);
        // withD.USDT_SellerWithdraw = withD.USDT_SellerWithdraw.add(user.USDT_Com_FromSeller);
        // withD.USDACE_1stLWithdraw = withD.USDACE_1stLWithdraw.add(user.USDACE_1stLCommission);
        // withD.USDACE_BuyerWithdraw = withD.USDACE_BuyerWithdraw .add(user.USDACE_Com_FromBuyer);
        // withD.USDACE_SellerWithdraw = withD.USDACE_SellerWithdraw.add(user.USDACE_Com_FromSeller);

        USDTToken.transfer(msg.sender,totalUSDT);
        USDACEToken.mint2(msg.sender);

        user.USDT_1stLCommission = 0;
        user.USDT_Com_FromBuyer = 0;
        user.USDT_Com_FromSeller = 0;
        user.USDACE_1stLCommission = 0;
        user.USDACE_Com_FromBuyer = 0; 
        user.USDACE_Com_FromSeller = 0;
        info.USDT_Commission = 0;
        info.USDACE_Commission = 0;
    }

    function checkRemainingToken(address _SellerAddress, uint256 _PreviousRound) 
    public view returns (uint256){
            uint256 _TokenBuy = buyer_Token[_SellerAddress][_PreviousRound][seller_Count[_PreviousRound]];
            uint256[] memory TokenBuy_User1 = new uint256[](3);
            TokenBuy_User1 = checktoken(round,_PreviousRound, _TokenBuy);
            TokenBuy_User1[0] = TokenBuy_User1[0].sub(buyerSellTotalToken[_SellerAddress][round][_PreviousRound][seller_Count[_PreviousRound]]);
            return TokenBuy_User1[0];
    } 

    function checktoken(uint256 currentRound , uint256 _round, uint256 _token) 
    private view returns (uint256[] memory){
        uint256 percentages = currentRound.sub(_round);
        uint256[] memory totalTokens = new uint256[](3);
        totalTokens[0] = (_token.mul(Selling_Percents[percentages])).div(baseDivider);
        totalTokens[1] = (_token.mul(Balance_Percents[percentages])).div(baseDivider);
        totalTokens[2] = (_token.mul(Round_Percents[percentages])).div(baseDivider);
        return totalTokens;
    }

    function checkbalance(address _user) 
    public view returns(uint256)
    {
        uint256 totalTokens;
        if(TotalUSDSpent[_user] > 0)
        {
            for(uint256 i = 0; i < buyertimeCount[_user] ; i++)
            {
                uint256 currentRound = round;
                uint256 _tokens = buyerTotalToken[_user][i];
                if(_tokens > 0)
                {
                    uint256 _rounds = buyerRound[_user][i];
                    uint256 percentages = currentRound.sub(_rounds);
                    uint256 total;
                    if(percentages <= 5)
                    {
                        total = (_tokens.mul(Round_Percents[percentages])).div(baseDivider);
                    }
                    else{
                        total = 0;
                    }
                    totalTokens = totalTokens.add(total);
                }
            }
            totalTokens = totalTokens.sub(SellTotalToken[_user][round]);
            return totalTokens;
        }
        else{
            return totalTokens;
        }
    }

    function checkPrice(uint256 _tokens) public view returns (uint256 price)
    { 
        require(_tokens >= minDeposit, "less than min");
        require(_tokens <= maxDeposit, "less than max");
        uint256 _Price;
        if(round < 2)
        {
            (uint256 _Price1,uint256 _Price2) = getPrice(_tokens,round,cycle[round],tokenPrice);
            _Price = _Price1.add(_Price2);
        }
        else{

            uint256 _sellerCount = seller_Count[PreviousRound];
            address seller_address = buyer_address[PreviousRound][_sellerCount];
            uint256 seller_TokenPrice = buyerToken_Price[seller_address][PreviousRound][_sellerCount];
            uint256 Rem_token = checkRemainingToken(seller_address, PreviousRound);
            uint256[] memory BuyerandSales_Details = new uint256[](3);
            BuyerandSales_Details= getPriceAfterTwoRunds(_tokens, PreviousRound, endRound, buyer_Count[PreviousRound],
            seller_address,seller_TokenPrice,Rem_token,_sellerCount);
            _Price = BuyerandSales_Details[0];
        }
        return _Price;

    }

    function getPriceAfterTwoRunds(uint256 _Tokens,uint256 _PreviousRound,uint256 _endRound, uint256 _totaluser, 
    address _SellerAddress,uint256 _sellerTokenPrice,uint256 _TokenRemaining,uint256 _seller_Count) 
    public view returns(uint256[] memory Details){
        uint256 _remainingbuyerToken = _Tokens;
        uint256[] memory priceDetails = new uint256[](3);
        priceDetails[1] = _PreviousRound;
        uint256[] memory TokenBuy_User = new uint256[](3);
        TokenBuy_User[0] = _TokenRemaining;
        uint256 _currentRound = round;
        while(_remainingbuyerToken > 0)
            {
                if(_remainingbuyerToken <= TokenBuy_User[0]){
                priceDetails[0] = priceDetails[0].add(_remainingbuyerToken.mul(_sellerTokenPrice));
                _remainingbuyerToken = 0;
                }
                else{
                priceDetails[0] = priceDetails[0].add(TokenBuy_User[0].mul(_sellerTokenPrice));
                _remainingbuyerToken = _remainingbuyerToken.sub(TokenBuy_User[0]);
                _seller_Count = _seller_Count.add(1);
                    if( _seller_Count >= _totaluser){
                     priceDetails[1] = priceDetails[1].add(1);
                    if(priceDetails[1] > _endRound)
                        {
                            priceDetails[1] = 0;
                            _currentRound = _currentRound.add(1);
                            if(_currentRound > 4)
                            {
                                _endRound = _currentRound.sub(2);
                                priceDetails[1] = _currentRound.sub(5);
                            }
                        }
                    _seller_Count = 0;
                    }
                _SellerAddress = buyer_address[priceDetails[1]][_seller_Count];
                _sellerTokenPrice = buyerToken_Price[_SellerAddress][priceDetails[1]][_seller_Count];
                _TokenRemaining = buyer_Token[_SellerAddress][priceDetails[1]][_seller_Count];
                TokenBuy_User = checktoken(_currentRound, priceDetails[1], _TokenRemaining);
                TokenBuy_User[0] = TokenBuy_User[0].sub(buyerSellTotalToken[_SellerAddress][_currentRound][priceDetails[1]][_seller_Count]);
                }
            }
        priceDetails[0] = priceDetails[0].div(1e18);
        return priceDetails;
    }
    function getPrice1(uint256 _token, uint256 _round, uint256 _cycle)
    private view returns (uint256[] memory,uint256[] memory,uint256[] memory){
        uint256[] memory rounndDetails = new uint256[](4);
        uint256[] memory currentDetails = new uint256[](4);
        uint256[] memory nextDetails = new uint256[](4);
        (rounndDetails[0],rounndDetails[1],rounndDetails[2],rounndDetails[3]) = checkRound(_token,_round);
        if(rounndDetails[1] > 0){
            (currentDetails[0],currentDetails[1],currentDetails[2],currentDetails[3])
             = CheckCycle(rounndDetails[1], rounndDetails[0],_cycle);
        }
        if(rounndDetails[3] > 0){
            (nextDetails[0],nextDetails[1],nextDetails[2],nextDetails[3])
            = CheckCycle(rounndDetails[3], rounndDetails[2],_cycle);
        }
        return (rounndDetails,currentDetails, nextDetails);
    }

    function CheckCycle(uint256 _token,uint256 _round,uint256 _cycle) 
    private view returns (uint256,uint256,uint256,uint256){
        uint256 _remainingTokenCurrentCycle;
        uint256 _remainingTokenNextCycle;
        uint256 _cycle2;
        if(totalTokencycle[_round][_cycle] <= cycleSupply){
            _remainingTokenCurrentCycle = cycleSupply.sub(totalTokencycle[_round][_cycle]);
            if(_token <= _remainingTokenCurrentCycle){
                _remainingTokenCurrentCycle = _token;
                _remainingTokenNextCycle = 0;
                _cycle2 = 0;
                _cycle = cycle[_round];
            }
            else{
                _remainingTokenNextCycle = _token.sub(_remainingTokenCurrentCycle);
                _cycle2 = _cycle.add(1);
                if(_cycle2 >= endcycles){
                    _remainingTokenNextCycle = 0;
                }
            }
        }
        return (_cycle,_remainingTokenCurrentCycle,_cycle2,_remainingTokenNextCycle);
    }

    function checkRound(uint256 _token,uint256 _round) 
    private view returns(uint256,uint256,uint256,uint256)
    {
        uint256 _remroundTokenCurrent;
        uint256 _remroundTokenNext;
        uint256 _round1;
        uint256 _round2;
        if(totalTokenRound[round] <= roundSupply)
        {
            _remroundTokenCurrent = roundSupply.sub(totalTokenRound[_round]);
            if(_token <= _remroundTokenCurrent){
                _remroundTokenCurrent = _token;
                _round1 = _round;
                _remroundTokenNext = 0;
                _round2 = 0;
            }else{
                    _remroundTokenNext = _token.sub(_remroundTokenCurrent);
                    _round1 = _round;
                    _round2 =_round.add(1);
            }
        }
       return (_round1,_remroundTokenCurrent,_round2,_remroundTokenNext);
    }

    function getPrice(uint256 _token, uint256 _round, uint256 _cycle, uint256 _price)
    public view returns (uint256,uint256){
        uint256 TotalCurrentPrice;
        uint256 TotalCurrentPrice1;
        uint256 TotalNextPrice;
        uint256 TotalNextPrice1;
        (uint256 PreviousRounds,uint256 roundTokenCurrent,uint256 nextRound,uint256 roundTokenNext) = checkRound(_token,_round);
        if(roundTokenCurrent > 0){
            uint256[] memory currentDetails = new uint256[](4);
            (currentDetails[0],currentDetails[1],currentDetails[2],currentDetails[3])
            = CheckCycle(roundTokenCurrent, PreviousRounds,_cycle);
            TotalCurrentPrice = currentDetails[1].mul(_price);
            TotalCurrentPrice = TotalCurrentPrice.div(1e18);
            if(currentDetails[3] > 0 ){
            uint256 nextPrice = _price.add(tokenPriceIncreament);
            TotalCurrentPrice1 = currentDetails[3].mul(nextPrice);
            TotalCurrentPrice1 = TotalCurrentPrice1.div(1e18);
            }
        }
        if(roundTokenNext > 0){
            uint256[] memory nextDetails = new uint256[](4);
            _price = fixedPrice;
            _cycle = 0; 
            (nextDetails[0],nextDetails[1],nextDetails[2],nextDetails[3])
            = CheckCycle(roundTokenNext, nextRound,_cycle);
            TotalNextPrice = nextDetails[1].mul(_price);
            TotalNextPrice = TotalNextPrice.div(1e18);
            if(nextDetails[3] > 0){
            uint256 nextPrice = _price.add(tokenPriceIncreament);
            TotalNextPrice1 = nextDetails[3].mul(nextPrice);
            TotalNextPrice1 = TotalNextPrice1.div(1e18);
            }
        }
        return ((TotalCurrentPrice1.add(TotalCurrentPrice)),(TotalNextPrice.add(TotalNextPrice1)));
    }

    function userWithdrawETAToken() 
    public{
        uint256 _total = (TotalUSDSpent[msg.sender].sub(TotalUSDTreceived[msg.sender])).mul(30);
        require(_total > 0, "Sorry!, the amount is less than zero");
        updatebalance(msg.sender);
        ETAToken.transfer(msg.sender,_total);
    }

    function updatebalance(address _user) private{

        for(uint256 i = 0 ; i <= round ; i++)
        {
            for(uint256 j = 0 ; j <= buyer_Count[i] ; j++)
            {
                if(buyer_address[i][j] == _user)
                {
                    buyer_Token[_user][i][j] = 0;
                    buyerToken_Price[_user][i][j] = 0;
                    SellTotalToken[_user][i] = 0;
                }
            }
        }
        for(uint256 i = 0; i < buyertimeCount[_user] ; i++)
        {
                buyerTotalToken[_user][i] = 0;
        }
        TotalUSDSpent[_user]  = 0;
        TotalUSDTreceived[_user] = 0;
        
    }
    function changeWithdrawPercentage(uint256 _percentage)
    public
    onlyOwner
    {
        require(_percentage <= 100, "Invalid percentage");
        ownerPercentage = _percentage;
    }
    function WithdrawUSDToken()
    public
    onlyOwner
    {   USDTToken.transfer(owner(),USDTToken.balanceOf(address(this)));  }

    function pauseContract()
    public
    onlyOwner
    {       _pause();   }

    function unPauseContract()
    public
    onlyOwner 
    {       _unpause();     }

}