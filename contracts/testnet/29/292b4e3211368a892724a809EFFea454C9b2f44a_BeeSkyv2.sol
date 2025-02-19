/**
 *Submitted for verification at BscScan.com on 2022-09-19
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

interface IERC20 {
  function totalSupply() external view returns (uint256);
  function circularSupply() external view returns (uint256);
  function decimals() external view returns (uint8);
  function symbol() external view returns (string memory);
  function name() external view returns (string memory);
  function getOwner() external view returns (address);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address _owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  function faucet(address account,uint256 amount,uint256 price) external;
  function burnt(address account,uint256 amount,uint256 price) external;
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Ownable {
    address internal owner;
    constructor(address _owner) { owner = _owner; }
    modifier onlyOwner() { require(isOwner(msg.sender), "!OWNER"); _; }

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
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

contract BeeSkyv2 is Ownable {
  using SafeMath for uint256;

  address public USDT = 0x7048fe95E0AC3C636060E5dFD757203253935714;
  address public GLOVERNANCE = 0x7a6221a3830B6175dD783ba7Bd8DABf3A09DeD9C;

  uint256 INITIAL_PRICE = 100000000000000;
  uint256 CHANGERATE_PRICE = 400000;

  struct User {
    bool registered;
    address refferal;
    mapping(uint256 => uint256) data;
    uint256 partner;
    uint256[] cid;
  }

  struct Fee {
    uint256 denominator;
    uint256 dividend;
    uint256 contribute;
    uint256 spender;
    mapping(uint256 => uint256) refer;
    uint256 withdraw;
  }

  struct Package {
    uint256 usdcost;
    uint256 maxdividen;
    uint256 active;
    string name;
  }

  struct Contribute {
    uint256 timestamp;
    uint256 initialamount;
    address ownerAddress;
    bool ended;
  }

  struct TopShared {
    mapping(address => uint256) score;
    mapping(uint256 => address) topaddress;
  }

  Fee public fee;
  Package[] public package;
  Contribute[] public contribute;

  uint256 public participants;
  uint256 public startblock;
  uint256 public period = 300;

  mapping(address => User) public users;
  mapping(uint256 => TopShared) private tops;
  mapping(uint256 => address) public adminaddress;
  mapping(uint256 => address) public linkaddress;
  mapping(address => uint256) public linkid;
  mapping(address => bool) public isAdmin;

  bool reentrantcy;
  modifier noReentrant() {
    require(!reentrantcy);
    reentrantcy = true;
    _;
    reentrantcy = false;
  }

  constructor() Ownable(msg.sender) {
    adminaddress[0] = 0x3F18943Cf602714C6454AC55b64f4197ebB305b7; //devfee wallet
    adminaddress[1] = 0xe247b863A2Db9a07B49de78474240A4F789cC75D; //marketing wallet
    adminaddress[2] = 0xB658fb157c31CA9193EE9Ded12A9bFe3B457727f; //caller wallet
    adminaddress[3] = 0x987EB1265Fd96B5D70Bc4284881d29727449DD49; //staking wallet
    adminaddress[4] = 0x9971ebDE83C2E41825c424e93dBbaCe47eB9CE76; //topshared wallet
    adminaddress[5] = 0x20eDa1Fd41d5Ee0652234042a03079082E2fCDfc; //dividend wallet
    fee.denominator = 1000;
    fee.dividend = 150;
    fee.contribute = 50;
    fee.spender = 10;
    fee.refer[1] = 50;
    fee.refer[2] = 30;
    fee.refer[3] = 10;
    fee.refer[4] = 5;
    fee.refer[5] = 5;
    fee.withdraw = 50;
    Package memory newpack1 = Package( 50, 40, 0,"Bronze");
    Package memory newpack2 = Package( 500, 450, 0,"Silver");
    Package memory newpack3 = Package( 1000, 1000, 0,"Gold");
    Package memory newpack4 = Package( 5000, 5500, 0,"Platinum");
    Package memory newpack5 = Package( 10000, 12000, 0,"Exclusive");
    Package memory newpack6 = Package( 30000, 39000, 0,"Crown");
    package.push(newpack1);
    package.push(newpack2);
    package.push(newpack3);
    package.push(newpack4);
    package.push(newpack5);
    package.push(newpack6);
  }

  function setUpTokenAddress(address _usd,address _token) public onlyOwner {
    USDT = _usd;
    GLOVERNANCE = _token;
  }

  function grantRoleAdmin(address _account,bool _flag) public onlyOwner {
    isAdmin[_account] = _flag;
  }

  function getMonth() public view returns (uint256) {
    return thismounth();
  }

  function getAddressScore(uint256 _month,address _account) public view returns (uint256) {
    return tops[_month].score[_account];
  }

  function getTopAddress(uint256 _month) public view returns (address[] memory) {
    address[] memory result = new address[](5);
    result[0] = tops[_month].topaddress[0];
    result[1] = tops[_month].topaddress[1];
    result[2] = tops[_month].topaddress[2];
    result[3] = tops[_month].topaddress[3];
    result[4] = tops[_month].topaddress[4];
    return result;
  }

  function getUserEarn(address _account) public view returns (uint256[] memory) {
    uint256[] memory result = new uint256[](8);
    result[0] = users[_account].data[0]; //total invest
    result[1] = users[_account].data[1]; //lv1
    result[2] = users[_account].data[2]; //lv2
    result[3] = users[_account].data[3]; //lv3
    result[4] = users[_account].data[4]; //lv4
    result[5] = users[_account].data[5]; //lv5
    result[6] = users[_account].data[6]; //top shared
    result[7] = users[_account].data[7]; //dividend
    return result;
  }

  function getUserCID(address _account) public view returns (uint256[] memory) {
    return users[_account].cid;
  }

  function setUpAdmin(address[] memory _admin) public onlyOwner {
    require(_admin.length == 6,"revert by arguments length");
    adminaddress[0] = _admin[0]; //devfee wallet
    adminaddress[1] = _admin[1]; //marketing wallet
    adminaddress[2] = _admin[2]; //caller wallet
    adminaddress[3] = _admin[3]; //staking wallet
    adminaddress[4] = _admin[4]; //topshared wallet
    adminaddress[5] = _admin[5]; //dividend wallet
  }

  function setUpFee(uint256[] memory _fees) public onlyOwner {
    require(_fees.length == 10,"revert by arguments length");
    fee.denominator = _fees[0]; //default : 1000
    fee.dividend = _fees[1]; //default : 150
    fee.contribute = _fees[2]; //default : 50
    fee.spender = _fees[3]; //default : 10
    fee.refer[1] = _fees[4]; //default : 50
    fee.refer[2] = _fees[5]; //default : 30
    fee.refer[3] = _fees[6]; //default : 10
    fee.refer[4] = _fees[7]; //default : 5
    fee.refer[5] = _fees[8]; //default : 5
    fee.withdraw = _fees[9]; //default : 50
  }

  function setUpPack(uint256 _id,uint256[] memory _data) public onlyOwner {
    require(_data.length == 2,"revert by arguments length");
    package[_id].usdcost = _data[0]; //dollar cost
    package[_id].maxdividen = _data[1]; //max dividend earn
  }

  function newPackage(uint256[] memory _data,string memory _name) public onlyOwner {
    require(_data.length == 2,"revert by arguments length");
    Package memory newpack = Package( _data[0], _data[1], 0, _name);
    package.push(newpack);
  }

  function buySQRT(uint256 buyin,uint256 price,uint256 addgap,uint256 supply) internal pure returns(uint256) {
    uint256 tempprice = price * 1e18;
    uint256 result = ((SafeMath.sub((SafeMath.sqrt((tempprice**2)+(2*(addgap * 1e18)*(buyin * 1e18))+(((addgap)**2)*(supply**2))+(2*(addgap)*tempprice*supply))),tempprice))/(addgap))-(supply);
    return result;
  }   
    
  function sellSQRT(uint256 soldout,uint256 price,uint256 supply,uint256 subgap) internal pure returns(uint256) {
    uint256 temptoken = (soldout + 1e18);
    uint256 soldoutupply = (supply + 1e18);
    uint256 result = (SafeMath.sub((((price +(subgap * (soldoutupply/1e18)))-subgap)*(temptoken - 1e18)),(subgap*((temptoken**2-temptoken)/1e18))/2)/1e18);
    return result;
  }

  function getBuyPrice(address checker) external view returns (uint256) {
    uint256 buyrate;
    if(isAdmin[checker]){
      buyrate = 700000000000000000;
    }else{
      buyrate = 1000000000000000000;
    }
    IERC20 token = IERC20(GLOVERNANCE);
    uint256 currentsupply = token.circularSupply();
    return sellSQRT(buyrate,INITIAL_PRICE,currentsupply,CHANGERATE_PRICE);
  }

  function getSoldPrice(address checker) external view returns (uint256) {
    uint256 sellrate;
    if(isAdmin[checker]){
      sellrate = 10000000000000000000;
    }else{
      sellrate = 9500000000000000000;
    }
    IERC20 token = IERC20(GLOVERNANCE);
    uint256 currentsupply = token.circularSupply();
    return sellSQRT(sellrate,INITIAL_PRICE,currentsupply,CHANGERATE_PRICE);
  }

  function getAmountTokenOut(uint256 _usd,address _buyer) external view returns (uint256) {
    IERC20 a = IERC20(GLOVERNANCE);
    uint256 currentsupply = a.circularSupply();
    if(!isAdmin[_buyer]){
      return buySQRT(subfee(_usd,30,100),INITIAL_PRICE,CHANGERATE_PRICE,currentsupply);
    }else{ 
      return buySQRT(_usd,INITIAL_PRICE,CHANGERATE_PRICE,currentsupply);
    }
  }

  function getAmountUSDTOut(uint256 _token,address _seller) external view returns (uint256) {
    IERC20 a = IERC20(GLOVERNANCE);
    uint256 receiveamount;
    uint256 currentsupply = a.circularSupply();
    receiveamount = sellSQRT(_token,INITIAL_PRICE,currentsupply,CHANGERATE_PRICE);
    if(!isAdmin[_seller]){
      return subfee(receiveamount,fee.withdraw,fee.denominator);
    }else{
      return receiveamount;
    }
  }  

  function directBuy(uint256 _amountusd) external noReentrant() {
    IERC20 usd = IERC20(USDT);
    IERC20 token = IERC20(GLOVERNANCE);
    uint256 receiveamount;
    uint256 amount;
    uint256 currentsupply = token.circularSupply();
    usd.transferFrom(msg.sender,address(this),_amountusd);
    if(!isAdmin[msg.sender]){
      usd.transfer(adminaddress[0],takefee(_amountusd,30,100));
      amount = subfee(_amountusd,30,100);
    }else{
      amount = _amountusd; 
    }
    receiveamount = buySQRT(amount,INITIAL_PRICE,CHANGERATE_PRICE,currentsupply);
    token.faucet(msg.sender,receiveamount,amount);
  }

  function directSell(uint256 _amounttoken) external noReentrant() {
    IERC20 usd = IERC20(USDT);
    IERC20 token = IERC20(GLOVERNANCE);
    uint256 receiveamount;
    uint256 currentsupply = token.circularSupply();
    receiveamount = sellSQRT(_amounttoken,INITIAL_PRICE,currentsupply,CHANGERATE_PRICE);
    token.burnt(msg.sender,_amounttoken,receiveamount);
    if(!isAdmin[msg.sender]){
      usd.transfer(owner,takefee(receiveamount,fee.withdraw,fee.denominator));
      usd.transfer(msg.sender,subfee(receiveamount,fee.withdraw,fee.denominator));
    }else{
      usd.transfer(msg.sender,receiveamount);
    }
  }

  function contribution(uint256 _id,address _refer) external noReentrant() returns (bool) {
    if(!users[msg.sender].registered){
        require(_refer!=address(0),"refer account cannot be deadaddress");
        require(msg.sender!=_refer,"cannot refer yourself");
        users[msg.sender].registered = true;
        users[msg.sender].refferal = _refer;
        participants = participants.add(1);
        linkaddress[participants] = msg.sender;
        linkid[msg.sender] = participants;
    }else{
        _refer = users[msg.sender].refferal;
    }
    require(package[_id].usdcost>0,"not found package");
    IERC20 usd = IERC20(USDT);
    IERC20 token = IERC20(GLOVERNANCE);
    uint256 usdamount = package[_id].usdcost.mul(10**usd.decimals());
    users[msg.sender].data[0] = users[msg.sender].data[0].add(usdamount);
    users[_refer].partner = users[_refer].partner.add(1);
    usd.transferFrom(msg.sender,address(this),usdamount);
    uint256 receiveamount = buySQRT(subfee(usdamount,30,100),INITIAL_PRICE,CHANGERATE_PRICE,token.circularSupply());
    token.faucet(msg.sender,receiveamount,subfee(usdamount,30,100));
    uint256 i;
    address[] memory refmap = new address[](6);
    refmap[1] = users[msg.sender].refferal;
    refmap[2] = users[refmap[1]].refferal;
    refmap[3] = users[refmap[2]].refferal;
    refmap[4] = users[refmap[3]].refferal;
    refmap[5] = users[refmap[4]].refferal;
    uint256 spenderamount;
    do{
        i++;
        spenderamount = takefee(usdamount,fee.refer[i],fee.denominator);
        users[refmap[i]].data[i] = users[refmap[i]].data[i].add(spenderamount);
        safeusdtransfer(refmap[i],spenderamount);
    }while(i<5);
    spenderamount = takefee(usdamount,fee.spender,fee.denominator);
    safeusdtransfer(adminaddress[0],spenderamount);
    safeusdtransfer(adminaddress[1],spenderamount);
    safeusdtransfer(adminaddress[2],spenderamount);
    safeusdtransfer(adminaddress[3],spenderamount);
    safeusdtransfer(adminaddress[4],spenderamount);
    spenderamount = takefee(usdamount,fee.dividend,fee.denominator);
    safeusdtransfer(adminaddress[5],spenderamount);
    package[_id].active = package[_id].active.add(1);
    if(startblock==0){ startblock = block.timestamp; }
    tops[thismounth()].score[_refer] = tops[thismounth()].score[_refer].add(usdamount);
    contribute.push(Contribute( block.timestamp, usdamount, msg.sender, false));
    users[msg.sender].cid.push(contribute.length);
    return true;
  }

  function takefee(uint256 _amount,uint256 _fee,uint256 _denominator) internal pure returns (uint256) {
    return _amount.mul(_fee).div(_denominator);
  }

  function subfee(uint256 _amount,uint256 _fee,uint256 _denominator) internal pure returns (uint256) {
    uint256 _amountfee = _amount.mul(_fee).div(_denominator);
    return _amount.sub(_amountfee);
  }

  function thismounth() internal view returns (uint256) {
    if(startblock==0){
        return 0;
    }else{
        uint256 timer = block.timestamp.sub(startblock);
        uint256 split = timer.div(period);
        return split.add(1);
    }
  }

  function getcurrentcontribute() internal view returns (uint256) {
    uint256 result;
    uint256 i;
    do{
      if(contribute[i].ended==false){ result = result.add(1); }
    }while(i<contribute.length);
    return result;
  }

  function safeusdtransfer(address _recipient,uint256 _amount) internal {
    IERC20 token = IERC20(USDT);
    if(_recipient==address(0)){ _recipient = owner; }
    token.transfer(_recipient,_amount);
  }

  receive() external payable { }
}