/**
 *Submitted for verification at BscScan.com on 2022-12-12
*/

/**
 *Submitted for verification at BscScan.com on 2022-05-12
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IUSDP {
    function owner() external view returns (address);
}

contract USDPRoyaltyContract {

    address public USDP = 0x324E8E649A6A3dF817F97CdDBED2b746b62553dD;
    uint256 private fee;
    address private feeRecipient;
    address public owner;

    modifier onlyOwner(){
        require(msg.sender == owner, 'Only Owner');
        _;
    }

    constructor(address USDPAddr,uint fee_, address recipient_) {
        fee = fee_;
        feeRecipient = recipient_;
        USDP = USDPAddr;
        owner = IUSDP(USDP).owner();

    }

    function setFee(uint newFee) external onlyOwner {
        require(
            newFee <= 50,
            'Fee Too High'
        );
        fee = newFee;
    }

    function setFeeRecipient(address recipient) external onlyOwner {
        require(
            recipient != address(0),
            'Zero Address'
        );
        feeRecipient = recipient;
    }

    function getFee() external view returns (uint256) {
        return fee;
    }

    function getFeeRecipient() external view returns (address) {
        return feeRecipient;
    }


}