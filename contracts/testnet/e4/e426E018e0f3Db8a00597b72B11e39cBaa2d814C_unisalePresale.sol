/**
 *Submitted for verification at BscScan.com on 2022-12-15
*/

// SPDX-License-Identifier: no-license
pragma solidity ^0.8.17;

contract unisalePresale {

   struct Presale {
      string name;
      uint amount;
   }

   Presale[] public presales;
   
   constructor() public {
    _createPresale("test1",1000);
    _createPresale("test2",2000);
  }

   mapping (address => Presale[]) public presaleToOwner;

   function _createPresale(string memory _name, uint _amount) public {
        presales.push(Presale(_name,_amount));
        presaleToOwner[msg.sender].push(presales[presales.length - 1]);
   }

   function _getOwnerPresalesCount() public view returns (uint) {
        uint count = presaleToOwner[msg.sender].length;
        return count;
   }

   function _getOwnerPresales() public view returns (Presale[] memory) {
      Presale[] memory _presales = new Presale[](10);
      
      for (uint num = 0; num < presaleToOwner[msg.sender].length; num++){
         Presale storage presale = presaleToOwner[msg.sender][num];
         _presales[num] = Presale(presale.name,presale.amount);
      }

      return presales;
   }

}