/**
 *Submitted for verification at BscScan.com on 2023-02-02
*/

//SPDX-License-Identifier:UNLICENSE
pragma solidity ^0.8.17;


contract LPFlexibleStaking{
    //Variable and other Declarations
    address public PAW;
    address public PairContract;
    uint256 public TotalDeposits;
    uint256 public RewardMultiplier = 69444444480; //Default set at 1%
    address public Operator;

    //Add Total Staked (for projections)

    mapping(address => uint256) public Deposits;
    mapping(address => uint256) public LastUpdateUnix;

    //Events
    event Deposited(uint256 NewBalance, address user);
    event Withdrawn(uint256 NewBalance, address user);
    event Claimed(uint256 Amount, address user);
    event ReInvested(uint256 NewBalance, address user);


    constructor(address _PAW, address _Pair){
        PAW = _PAW;
        PairContract = _Pair;
        Operator = msg.sender;
    }


    //Public Functions
    function Deposit(uint256 amount) public returns(bool success){  
        require(amount >= 100000000000, "The minimum deposit for staking is 0.0000001 LP");
        require(ERC20(PairContract).balanceOf(msg.sender) >= amount, "You do not have enough LP to stake this amount");
        require(ERC20(PairContract).allowance(msg.sender, address(this)) >= amount, "You have not given the staking contract enough allowance");

        if(Deposits[msg.sender] > 0){
            Claim();
        }

        Update(msg.sender);
        ERC20(PairContract).transferFrom(msg.sender, address(this), amount);
        TotalDeposits = TotalDeposits + amount;
        Deposits[msg.sender] = (Deposits[msg.sender] + amount);

        emit Deposited(Deposits[msg.sender], msg.sender);
        return(success);
    }

    function Withdraw(uint256 amount) public returns(bool success){
        require(Deposits[msg.sender] >= amount);
        
        if((ERC20(PAW).balanceOf(address(this)) >= (GetUnclaimed(msg.sender)))){
            Claim();
        }

        Deposits[msg.sender] = Deposits[msg.sender] - amount;
        TotalDeposits = TotalDeposits - amount;
        ERC20(PairContract).transfer(msg.sender, amount);
        
        emit Withdrawn(Deposits[msg.sender], msg.sender);
        return(success);
    }


    function Claim() public returns(bool success){
        uint256 Unclaimed = GetUnclaimed(msg.sender);
        require(Unclaimed > 0);

        Update(msg.sender);

        ERC20(PAW).transfer(msg.sender, Unclaimed);
        
        emit Claimed(Unclaimed, msg.sender);
        return(success);
    }

    //OwnerOnly Functions

    function ChangeMultiplier(uint256 NewMultiplier) public returns(bool success){
        require(msg.sender == Operator);

        RewardMultiplier = NewMultiplier;

        return(success);
    }

    function ChangePairAddress(address NewPair) public returns(bool success){
        require(msg.sender == Operator);

        PairContract = NewPair;

        return(success);
    }

    //Internal Functions
    function Update(address user) internal{
        LastUpdateUnix[user] = block.timestamp;
    }

    //Functional view functions

    function GetUnclaimed(address user) public view returns(uint256){
        uint256 Time = (block.timestamp - LastUpdateUnix[user]);
        uint256 Unclaimed;
        
        Unclaimed = (((RewardMultiplier * Time) * CalculatePAWequivalent(Deposits[user])) / 1000000000000000); // 7927448 per %

        return(Unclaimed);
    }

    function CalculatePAWequivalent(uint256 amount) public view returns(uint256){
        return (((ERC20(PAW).balanceOf(PairContract)*((((1000000000000000000 * amount) / (ERC20(PairContract).totalSupply())))) / 1000000000000000000))*2);
    }

}

interface ERC20 {
  function balanceOf(address owner) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  function approve(address spender, uint value) external returns (bool);
  function Mint(address _MintTo, uint256 _MintAmount) external;
  function transfer(address to, uint value) external returns (bool);
  function transferFrom(address from, address to, uint256 value) external returns (bool); 
  function totalSupply() external view returns (uint);
}