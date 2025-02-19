/**
 *Submitted for verification at BscScan.com on 2023-01-05
*/

/**
 *Submitted for verification at BscScan.com on 2022-12-28
*/

pragma solidity ^0.8.6;

//SPDX-License-Identifier: MIT Licensed

interface IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external;

    function transfer(address to, uint256 value) external;

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external;

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract PROsale {
    IERC20 public PRO = IERC20(0x2d6b4A211d91006357963e4FaD397Cdd0fA1c56A);

    address payable public owner;

    uint256 public tokenPerBNB = 1_000_000_000_000 ether;
    uint256 public preSaleEndDate;
    uint256 public startDate;
    uint256 public soldToken;
    uint256 public amountRaisedBNB;
    uint256 public totalSupply = 600_000_000_000_000 ether;
    uint256 public constant divider = 100;
    struct user {
        uint256 BNB_balance;
        uint256 token_balance;
    }

    mapping(address => user) public users;

    modifier onlyOwner() {
        require(msg.sender == owner, "PRESALE: Not an owner");
        _;
    }

    event BuyToken(address indexed _user, uint256 indexed _amount);

    constructor(uint256 _startdate) {
        owner = payable(0xaD7f4232371416FdFD8f7E5D1C43E2B90CdB50cA);
        startDate = _startdate;
        preSaleEndDate = _startdate + 30 days;
    }

    receive() external payable {}

    // to buy token during preSale time with BNB => for web3 use

    function buyToken() public payable {
        require(soldToken <= totalSupply, "All Sold");
        require(block.timestamp >= startDate, "SALE: not started yet");
        require(block.timestamp <= preSaleEndDate, "SALE: sale ended");

        uint256 numberOfTokens;
        numberOfTokens = BNBToToken(msg.value);
        PRO.transferFrom(owner, msg.sender, numberOfTokens);
        soldToken = soldToken + (numberOfTokens);
        amountRaisedBNB = amountRaisedBNB + (msg.value);
        users[msg.sender].BNB_balance =
            users[msg.sender].BNB_balance +
            (msg.value);
        users[msg.sender].token_balance =
            users[msg.sender].token_balance +
            (numberOfTokens);
    }

    // to check number of token for given bnb
    function BNBToToken(uint256 _amount) public view returns (uint256) {
        uint256 numberOfTokens = (_amount * tokenPerBNB) / (1 ether);
        return numberOfTokens;
    }

    // to change preSale time duration
    function setPreSaleTime(uint256 _startDate, uint256 _endTime)
        external
        onlyOwner
    {
        startDate = _startDate;
        preSaleEndDate = _endTime;
    }

    // transfer ownership
    function changeOwner(address payable _newOwner) external onlyOwner {
        owner = _newOwner;
    }

    // to draw funds for liquidity
    function transferFundsBNB(uint256 _value) external onlyOwner {
        owner.transfer(_value);
    }

    // to draw out tokens
    function transferStuckTokens(IERC20 token, uint256 _value)
        external
        onlyOwner
    {
        token.transfer(msg.sender, _value);
    }

    // to get contract BNB balance
    function contractBalanceBNB() external view returns (uint256) {
        return address(this).balance;
    }
}