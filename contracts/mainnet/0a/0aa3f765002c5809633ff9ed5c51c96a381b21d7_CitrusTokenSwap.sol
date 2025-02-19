/**
 *Submitted for verification at BscScan.com on 2023-01-05
*/

// SPDX-License-Identifier: MIT



pragma solidity 0.8.16;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

contract CitrusTokenSwap {
    address payable public owner;
    uint256 ratio;
    uint256 times;
    mapping (address => uint256) public lockTime;
    mapping (address => uint256) public convertedToken;
    mapping (address => uint256) public totalConvertedToken;
    IERC20 public constant CITRUS = IERC20(0xAe67Cf598a349aFff89f6045108c6C1850f82839);  //citrus address
    IERC20 public constant CITRUS2 = IERC20(0x6D445f44fa904C21981DF8a9f2E80a22dD28465C); //citrus2 address
    event SetTime(address owner, uint256 time);
    event SetRatio(address owner, uint256 ratio);

    constructor(){
        owner = payable(msg.sender);
        times = 1675621799;
        ratio = 1 ether;
    }

    modifier onlyOwner() {
        payable(msg.sender) == owner;
        _;
    }

    function setRatio(uint256 paraRatio)
        public
        onlyOwner
    {
        ratio = paraRatio;
        emit SetRatio(msg.sender, ratio);
    }

    function getRatio()
        public
        view
        onlyOwner
        returns (uint256)
    {
        return ratio;
    }

    function setTime(uint256 paraTime)
        external
        onlyOwner
    {
        times = block.timestamp +  paraTime * 86400;
        emit SetTime(msg.sender, times);
    }

    function getTime()
        external
        view
        onlyOwner
        returns(uint256)
    {
        return times;
    }

    function swapCitrus(address walletAddress, uint256 amounts)
        public
        returns (uint256)
    {
        uint256 amount = amounts * 1 ether;
        require(block.timestamp <= times, "time over");
        require(amount > 0, "amount must be greater then zero");
        require(
            CITRUS.balanceOf(walletAddress) >= amount,
            "sender doesn't have enough Tokens"
        );

        uint256 exchange = (amount * ratio) / 10**18;
        lockTime[walletAddress] = 0;
        convertedToken[walletAddress] = exchange;
        totalConvertedToken[walletAddress] = 0;

        require(
            exchange > 0,
            "exchange Amount must be greater then zero"
        );

        require(
            CITRUS2.balanceOf(address(this)) >= exchange,
            "currently the exchange doesnt have enough TestToken Tokens, please retry later :=("
        );

        require(
            CITRUS.transferFrom(walletAddress, address(this), amount),
            "failed transfer to the contract"
            );

        require(CITRUS2.approve(address(this), exchange), "fail to approve");

        require(CITRUS2.transferFrom(
            address(this),
            address(walletAddress),
            exchange
        ), "failed transfer to the user");

        return exchange;
    }

    function withdrawCTS(address paraTo, uint paraAmount)
        external
        onlyOwner
    {
        require(paraTo == owner, "address must be owner Address");
        require(CITRUS.transfer(paraTo, paraAmount), "failed withdrawal of Citrus");
    }

    function withdrawCTS2(address paraTo, uint paraAmount)
        external
        onlyOwner
    {
        require(paraTo == owner, "address must be owner Address");
        require(CITRUS2.transfer(paraTo, paraAmount), "failed withdrawal");
    }
}