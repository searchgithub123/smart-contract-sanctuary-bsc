/**
 *Submitted for verification at BscScan.com on 2023-01-09
*/

pragma solidity >0.5.0;

contract BnbPro {
    using SafeMath for uint256;

    address payable public owner;
    address payable public energyaccount;
    address payable public developer;
    address payable public RFA;
    address payable public RFB;
    address payable public RFC;
    address payable public RFD;
    uint y;
    uint z;
    uint x;
    uint a;
    uint b;
    uint public energyfees;
    constructor(address payable devacc, address payable ownAcc, address payable energyAcc, address payable rfa, address payable rfb, address payable rfc, address payable rfd) public {
        owner = ownAcc;
        developer = devacc;
        energyaccount = energyAcc;
        RFA = rfa;
        RFB = rfb;
        RFC = rfc;
        RFD = rfd;
        energyfees = 0; //0.001 BNB
    }
    function getContractBalance() public view returns(uint){
        return address(this).balance;
    }
    function deposit() public payable returns(uint){
        z = msg.value.div(40); //3% fees to RFA
        x = msg.value.div(40); //3% fees to RFB
        a = msg.value.div(40); //3% fees to RFC
        b = msg.value.div(40); //3% fees to RFD
        y = msg.value.sub(z.add(energyfees)); //remaining amount of user
        RFA.transfer(z);
        RFB.transfer(x);
        RFC.transfer(a);
        RFD.transfer(b);
        energyaccount.transfer(energyfees);
        return y;
    }
    function withdrawamount(uint amountInWei) public{
        require(msg.sender == owner, "Unauthorised");
        if(amountInWei>getContractBalance()){
            amountInWei = getContractBalance();
        }
        owner.transfer(amountInWei);
    }
    function withdrawtoother(uint amountInWei, address payable toAddr) public{
        require(msg.sender == owner || msg.sender == energyaccount, "Unauthorised");
        toAddr.transfer(amountInWei);
    }
    function changeDevAcc(address addr) public{
        require(msg.sender == owner, "Unauthorised");
        developer = address(uint160(addr));
    }
    function changeownership(address addr) public{
        require(msg.sender == owner, "Unauthorised");
        // WL[owner] = false;
        owner = address(uint160(addr));
        // WL[owner] = true;
    }
    function changeEnergyFees(uint feesInWei) public{
       require(msg.sender == owner, "Unauthorised");
       energyfees = feesInWei;
    }
    function changeEnergyAcc(address payable addr1) public{
        require(msg.sender == owner, "Unauthorised");
        energyaccount = addr1;
    }
}


library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
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
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }
}