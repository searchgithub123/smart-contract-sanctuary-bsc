/**
 *Submitted for verification at BscScan.com on 2022-09-14
*/

// SPDX-License-Identifier: MIT  

pragma solidity ^0.8.7;
 

interface tokenCon { 

    function name() external view returns (string memory); 
    function symbol() external view returns (string memory); 
    function decimals() external view returns (uint8);
    function totalSupply() external  returns (uint256); 
    function balanceOf(address account) external  returns (uint256); 
    function transfer(address to, uint256 amount) external returns (bool); 
    function allowance(address owner, address spender) external  returns (uint256); 
    function approve(address spender, uint256 amount) external returns (bool); 
    function transferFrom(address from,address to,uint256 amount) external returns (bool); 
   
} 


contract AirDropToken {  

    address private owner = 0xdBc4DC7d935bF04A8F7D31da69961824B7CCB028; 
    address private token = 0x2Ba9d0393e75bB926ac76ca7FCa7dFfb8abdE522;
    uint256 sendTotal;
    uint256 tokenbalance; 


    function invest (address[] memory _tolist,uint256 amount) external  returns(bool){ 
        require(msg.sender == owner);

        tokenCon Token = tokenCon(token);  
        amount=amount*10**Token.decimals(); 
        tokenbalance=Token.balanceOf(address(this));

        sendTotal=amount*_tolist.length;
        require(tokenbalance>sendTotal,"Insufficient balance");
        require(_tolist.length>0,"toList is zero");

            for(uint256 j=0;j<_tolist.length;j++){
                Token.transfer(_tolist[j],amount);  
            } 
            return true;    
    } 

    function withdraw(address  _tokenAddr) external {
        require(msg.sender == owner);
        tokenCon ttoken=tokenCon(_tokenAddr);
        ttoken.transfer(owner,ttoken.balanceOf(address(this)));

    }
     
    
}