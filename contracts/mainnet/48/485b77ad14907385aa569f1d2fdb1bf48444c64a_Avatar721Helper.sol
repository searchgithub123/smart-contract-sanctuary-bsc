/**
 *Submitted for verification at BscScan.com on 2022-12-01
*/

pragma solidity 0.8.16;

interface IAvatar721  {
     struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Keeps track of the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
    }

    function getOwnershipOf(uint256 tokenId) external view returns (TokenOwnership  memory);
}


contract Avatar721Helper {
    address avatar721 = address(0xa2b2a7774e29f13E17F95b0fc9c0722e7Be36E49); 

   



    function listMyNFT(uint256 start,uint256 end,address owner) public view returns (uint256[] memory tokens) {
        tokens = new uint256[](end -start);
        uint256 start = 0;
        for (uint i=start; i<end; i++) {
        IAvatar721.TokenOwnership memory ownerships = IAvatar721(avatar721).getOwnershipOf(i);
            if(ownerships.addr == owner && !ownerships.burned){
                tokens[start] = i;
                start++;
            }
        }
    }

}