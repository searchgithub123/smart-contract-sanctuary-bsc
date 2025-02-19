/**
 *Submitted for verification at BscScan.com on 2022-08-04
*/

pragma solidity ^0.8.3;
// SPDX-License-Identifier: GPL-3.0


interface IERC20{ 
    function totalSupply() external view returns(uint);

    function balanceOf(address account) external view returns(uint);

    function transfer(address recipient,uint amount) external returns(bool);

    function allowance(address owner,address spender) external view returns(uint);

    function approve(address spender, uint amount) external returns(bool);

    function transferFrom(address sender,address recipient,uint amount) external returns(bool);

    event Transfer(address indexed from,address indexed to, uint amount);

    event Approval(address indexed owner,address indexed spender,uint amount);
 
    

}

contract ERC20token is IERC20 {
    address public owner;
    event Togiveup(address indexed from,address indexed to);

    constructor(address _Marketing,uint _moneyuser,uint _marketing,uint _ox,uint _utils){
        owner=msg.sender;  
        Marketing = _Marketing;
        // moneyuser = 95000000000000000000;
        // marketing = 3000000000000000000;
        // ox = 2000000000000000000;
        // utils = 100000000000000000000;
        require(_moneyuser+_marketing+_ox == 100000000000000000000,"TRANSACT FALSE");
        moneyuser = _moneyuser;
        marketing = _marketing;
        ox = _ox;
        utils = _utils;
    }

    
    modifier onlyOwner(){
        require(msg.sender == owner,"NOT THE OWNER");
        _;
    }

    uint public totalSupply;
    address public Marketing;
    uint public proportion;
    uint public utils;
    uint public moneyuser;
    uint public marketing;
    uint public ox;

    
    
    mapping(address =>uint) public balanceOf;
    mapping(address =>mapping(address =>uint)) public allowance;

    string public name = 'BallKing';
    string public symbol = 'BallKing';
    uint public decimals = 18; 


    //修改营销地址
    function updateMarketing(address _marketing) external onlyOwner{
        Marketing=_marketing;
    }


    function updateuser(uint _moneyuser,uint _marketing,uint _ox)external onlyOwner{
        require(_moneyuser+_marketing+_ox == 100000000000000000000,"TRANSACT FALSE");
        moneyuser=_moneyuser;
        marketing=_marketing;
        ox=_ox;
    }
 
    function giveUpowner(address _owner)external onlyOwner{
        owner=_owner;
        emit Togiveup(msg.sender,address(0));

    }

    
    
    function transfer(address recipient,uint amount) external returns(bool){
        require(amount <= balanceOf[msg.sender],"NOT SUFFICIENT FUNDS");
        balanceOf[msg.sender] -= amount;
        uint oneamount= amount * moneyuser /utils;
        uint twoamount= amount * marketing /utils;
        uint threeamount= amount * ox /utils;

        balanceOf[recipient]  += oneamount;
        balanceOf[Marketing] += twoamount;
        totalSupply -=  threeamount;
        emit Transfer(msg.sender,recipient,oneamount);
        emit Transfer(msg.sender,Marketing,twoamount);
        emit Transfer(msg.sender,address(0),threeamount);
        return true;
    }

    //修改批准映射
    function approve(address spender, uint amount) external returns(bool){
         allowance[msg.sender][spender] = amount;
         emit Approval(msg.sender,spender,amount);
         return true;
    }

    
      function transferFrom(address sender,address recipient,uint amount) external returns(bool){
        allowance[sender][msg.sender] -= amount;
        balanceOf[sender] -= amount;

        uint oneamount= amount * moneyuser /utils;
        uint twoamount= amount * marketing /utils;
        uint threeamount= amount * ox /utils;

        balanceOf[recipient]  += oneamount;
        balanceOf[Marketing] += twoamount;
        totalSupply -=  threeamount;
        
        emit Transfer(sender,recipient,oneamount);
        emit Transfer(msg.sender,Marketing,twoamount);
        emit Transfer(msg.sender,address(0),threeamount);
        return true;
      }
    //ADD TOKEN
    function mint (uint amount) external onlyOwner{
        balanceOf[msg.sender] +=amount;
        totalSupply +=amount;
        emit Transfer(address(0),msg.sender,amount);
    }

    //THE DESTRUCTION TOKEN
    function burn(uint amount) external onlyOwner{
        balanceOf[msg.sender] -=amount;
        totalSupply -=amount;
        emit Transfer(msg.sender,address(0),amount);
    }

    
}