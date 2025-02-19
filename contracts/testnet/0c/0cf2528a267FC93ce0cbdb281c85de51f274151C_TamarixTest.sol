/**
 *Submitted for verification at BscScan.com on 2023-01-12
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IBEP20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    // function decimals() external view returns (uint8);
    // function symbol() external view returns (string memory);
    // function name() external view returns (string memory);

    // function getOwner() external view returns (address);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    //event Burn(address indexed burner, uint256 value);

}


contract TamarixTest is IBEP20 {

    using SafeMath for uint256;

    mapping (address => uint256) private balances;
    mapping (address => mapping (address => uint256)) private allowances;
    mapping (address => uint256) private lockedAmounts;
    mapping (address => uint256) private registerDate;

    address public contractOwner;
    uint256 public endDate;
    uint256 public totalSupply_;
    uint8 public decimals;
    string public symbol;
    string public name;

    constructor() {
        
        contractOwner = msg.sender;
        name = "Tamarix Test 1";
        symbol = "TMXT1";
        decimals = 10;
        totalSupply_ = 10000000000; // if you want 100 put 00 at the end
        balances[msg.sender] = totalSupply_;
        endDate = block.timestamp + 20 minutes;

        emit Transfer(address(0), msg.sender, totalSupply_);
  }
    
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }

    function transfer(address receiver, uint256 amount) public returns (bool){
        require(amount <= balances[msg.sender],"Insufficient Funds.");
        require(receiver != address(0), "Transfer to the zero address.");
        require(
            (amount <= balances[msg.sender].sub(lockedAmounts[msg.sender]) 
            || 
            (registerDate[msg.sender] + 10 minutes > block.timestamp))
             ,"Insufficient Unlocked Funds.");

        balances[msg.sender] = balances[msg.sender].sub(amount);
        balances[receiver] = balances[receiver].add(amount);
        if(msg.sender == contractOwner){
            if(block.timestamp < endDate){
               lockedAmounts[receiver] = lockedAmounts[receiver].add(amount);
               registerDate[receiver] = block.timestamp;
            }
        }
        
        emit Transfer(msg.sender, receiver, amount);
        return true;
    }

    function approve(address delegate, uint256 amount) public returns (bool){
        allowances[msg.sender][delegate] = amount;
        emit Approval(msg.sender, delegate, amount);
        return true;
    }

    function allowance(address owner, address delegate) public view returns (uint256){
        return allowances[owner][delegate];
    }

    function transferFrom(address owner, address receiver, uint256 amount) public returns (bool){
        require(owner != address(0), "Transfer from the zero address.");
        require(receiver != address(0), "Transfer to the zero address.");
        require(amount <= balances[owner]);
        require(amount <= allowances[owner][msg.sender]);
        require(
            (amount <= balances[msg.sender].sub(lockedAmounts[msg.sender]) 
            || 
            (registerDate[msg.sender] + 100 days > block.timestamp))
             ,"Insufficient Unlocked Funds.");

        balances[owner] = balances[owner].sub(amount);
        allowances[owner][msg.sender] = allowances[owner][msg.sender].sub(amount);
        balances[receiver] = balances[receiver].add(amount);
        if(msg.sender == contractOwner){
            if(block.timestamp < endDate){
               lockedAmounts[receiver] = lockedAmounts[receiver].add(amount);
               registerDate[receiver] = block.timestamp;
            }
        }
        
        emit Transfer(owner,receiver,amount);
        return true;

    }

    function updateEndDate(uint256 newDate) public returns (bool){
        {
            require(msg.sender == contractOwner);
            endDate = newDate;
            return true;
        }
    }

    function burn(uint256 amount) public returns (bool){
        require(msg.sender == contractOwner);
        require(balances[msg.sender] >= amount);
        balances[msg.sender] = balances[msg.sender].sub(amount);
        totalSupply_ = totalSupply_.sub(amount);

        //emit Burn(msg.sender, amount);
        emit Transfer(msg.sender, address(0), amount);

        return true;
    }

}


library SafeMath {
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, "SafeMath: subtraction overflow");
  }

  function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;

    return c;
  }

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, "SafeMath: division by zero");
  }

  function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b > 0, errorMessage);
    uint256 c = a / b;

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