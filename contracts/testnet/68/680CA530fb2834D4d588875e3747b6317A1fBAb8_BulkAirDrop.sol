/**
 *Submitted for verification at BscScan.com on 2022-09-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
}
contract BulkAirDrop {
    constructor(){
    }

    function AirdropERC20(IERC20 _token, address[] calldata _to, uint[] calldata _value) public {
        require(_to.length == _value.length, "Receivers and amounts are different length");
        for(uint256 i=0; i<_to.length; i++){
            require(_token.transferFrom(msg.sender, _to[i], _value[i]));
        }
    }
}