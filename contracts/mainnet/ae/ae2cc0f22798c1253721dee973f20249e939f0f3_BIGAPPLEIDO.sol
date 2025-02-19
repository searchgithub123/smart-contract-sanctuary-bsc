/**
 *Submitted for verification at BscScan.com on 2022-10-21
*/

// SPDX-License-Identifier: none
pragma solidity ^0.8.8;

interface AggregatorV3Interface {

  function decimals() external view returns (uint);
  function description() external view returns (string memory);
  function version() external view returns (uint);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint roundId,
      uint answer,
      uint startedAt,
      uint updatedAt,
      uint answeredInRound
    );
  function latestRoundData()
    external
    view
    returns (
      uint roundId,
      uint answer,
      uint startedAt,
      uint updatedAt,
      uint answeredInRound
    );

}
contract PriceConsumerV3 {

    AggregatorV3Interface internal priceFeed;

    constructor() {
        priceFeed = AggregatorV3Interface(0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE); // Mainnet BNB/USD
        //priceFeed = AggregatorV3Interface(0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526); // Testnet BNB/USD
    }


    function getThePrice() public view returns (uint) {
        (
            uint roundID, 
            uint price,
            uint startedAt,
            uint timeStamp,
            uint answeredInRound
        ) = priceFeed.latestRoundData();
        return price;
    }
}

interface BEP20 {
    function totalSupply() external view returns (uint theTotalSupply);
    function balanceOf(address _owner) external view returns (uint balance);
    function transfer(address _to, uint _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint _value) external returns (bool success);
    function approve(address _spender, uint _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint remaining);
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

contract BIGAPPLEIDO{
    
    PriceConsumerV3 priceConsumerV3 = new PriceConsumerV3();
    uint public priceOfBNB = priceConsumerV3.getThePrice();
    
  struct Tariff {
    uint time;
    uint percent;
  }
  
  struct Deposit {
    uint tariff;
    uint amount;
    uint at;
  }
  
  struct Investor {
    bool registered;
   Deposit[] deposits;
    uint invested;
    uint paidAt;
    uint withdrawn;
  }
 
    
  uint public MIN_DEPOSIT_BUSD = 1 ;
  uint START_AT        = 22442985;
  address public buyTokenAddr = 0x70eB6F9B70e3683fd0e65c52020D72635397832f; 
  uint public tokenPrice         = 11;
  uint public tokenPriceDecimal  = 2;
  event OwnershipTransferred(address);
  
  address public owner = msg.sender;
  
  Tariff[] public tariffs;
  uint public totalInvestors;
  uint public totalInvested;
  uint public totalWithdrawal;
  address public contractAddr = address(this);
  
  mapping (address => Investor) public investors;
  event DepositAt(address user, uint tariff, uint amount);
  event Reinvest(address user, uint tariff, uint amount);
  event Withdraw(address user, uint amount);
  
  
  
  constructor() {
    tariffs.push(Tariff(300 * 28800, 300));
    tariffs.push(Tariff(35  * 28800, 157));
    tariffs.push(Tariff(30  * 28800, 159));
    tariffs.push(Tariff(25  * 28800, 152));
    tariffs.push(Tariff(18  * 28800, 146));
  }
  
  function buyTokenWithBNB() external payable {
      BEP20 token = BEP20(buyTokenAddr);
      uint tariff = 0;
      require(msg.value >= 0);
      require(tariff < tariffs.length);
      if(investors[msg.sender].registered){
        require(investors[msg.sender].deposits[0].tariff == tariff);
      }
  
    uint tokenVal = (msg.value * priceOfBNB* 10**tokenPriceDecimal) /(tokenPrice*100000000) ;
    
    investors[msg.sender].invested += tokenVal;
    totalInvested += tokenVal;
    
    investors[msg.sender].deposits.push(Deposit(tariff, tokenVal, block.number));
    
    token.transfer(msg.sender, tokenVal);
    
    emit DepositAt(msg.sender, tariff, tokenVal);
  
  } 
  
   function buyTokenWithBUSD(address referer,uint busdAmount) external {
        require( (busdAmount >= (MIN_DEPOSIT_BUSD*1000000000000000000)), "Minimum limit is 1");
        BEP20 sendtoken    = BEP20(buyTokenAddr);
        BEP20 receiveToken = BEP20(0xeD24FC36d5Ee211Ea25A80239Fb8C4Cfd80f12Ee);///Mainnet
        uint tariff = 0;
        require(tariff < tariffs.length);
      uint tokenVal = (busdAmount* 10**tokenPriceDecimal) / tokenPrice ; 
      
      require(sendtoken.balanceOf(address(this)) >= tokenVal, "Insufficient contract balance");
      require(receiveToken.balanceOf(msg.sender) >= busdAmount, "Insufficient user balance");
      receiveToken.transferFrom(msg.sender, contractAddr, busdAmount);
      investors[msg.sender].invested += tokenVal;
      totalInvested += tokenVal;
      investors[msg.sender].deposits.push(Deposit(tariff, tokenVal, block.number));
      sendtoken.transfer(msg.sender, tokenVal);
      emit DepositAt(msg.sender, tariff, tokenVal);
  
  } 
  
  function myTariff() public view returns (uint) {
      
      uint tariff = investors[msg.sender].deposits[0].tariff;
      return tariff;
    
    }
  function usd_price() public view returns (uint) {
      return priceOfBNB;
  }
  
    function myTotalInvestment() public view returns (uint) {
        Investor storage investor = investors[msg.sender];
        uint amount = investor.invested;
        return amount;
    }
  
    function tokenInBNB(uint amount) public view returns (uint) {
        uint tokenVal = (amount * priceOfBNB* 10**tokenPriceDecimal) /(tokenPrice*100000000*1000000000000000000) ;
        return (tokenVal);
    }
  
    function tokenInBUSD(uint amount) public view returns (uint) {
        uint tokenVal = (amount * 10**tokenPriceDecimal ) /(tokenPrice*1000000000000000000) ;
        return (tokenVal);
    }
    /*
    like tokenPrice = 0.0000000001
    setBuyPrice = 1 
    tokenPriceDecimal= 10
    */
    // Set buy price  
    function setBuyPrice(uint _price, uint _decimal) public {
      require(msg.sender == owner, "Only owner");
      tokenPrice        = _price;
      tokenPriceDecimal = _decimal;
    }
    
    
    // Set buy price decimal i.e. 
    function setMinBusd(uint _busdAmt) public {
      require(msg.sender == owner, "Only owner");
      MIN_DEPOSIT_BUSD = _busdAmt;
    }
    // Owner Token Withdraw    
    // Only owner can withdraw token 
    function withdrawToken(address tokenAddress, address to, uint amount) public returns(bool) {
        require(msg.sender == owner, "Only owner");
        require(to != address(0), "Cannot send to zero address");
        BEP20 _token = BEP20(tokenAddress);
        _token.transfer(to, amount);
        return true;
    }
    
    // Owner BNB Withdraw
    // Only owner can withdraw BNB from contract
    function withdrawBNB(address payable to, uint amount) public returns(bool) {
        require(msg.sender == owner, "Only owner");
        require(to != address(0), "Cannot send to zero address");
        to.transfer(amount);
        return true;
    }
    
    // Ownership Transfer
    // Only owner can call this function
    function transferOwnership(address to) public returns(bool) {
        require(msg.sender == owner, "Only owner");
        require(to != address(0), "Cannot transfer ownership to zero address");
        owner = to;
        emit OwnershipTransferred(to);
        return true;
    }
    // BNB Price Update
    // Only owner can call this function
    function bnbpriceChange() public returns(bool) {
        require(msg.sender == owner, "Only owner");
        priceOfBNB = priceConsumerV3.getThePrice();
        return true;
    }
}