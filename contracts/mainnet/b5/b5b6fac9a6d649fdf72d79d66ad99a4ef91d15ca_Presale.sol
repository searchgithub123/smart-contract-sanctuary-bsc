/**
 *Submitted for verification at BscScan.com on 2022-08-11
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {
    
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}




library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
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
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }

}


contract Ownable   {
    address public _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**

     * @dev Initializes the contract setting the deployer as the initial owner.

     */

    constructor()  {
        _owner = msg.sender;

        emit OwnershipTransferred(address(0), _owner);
    }

    /**

     * @dev Returns the address of the current owner.

     */

    function owner() public view returns (address) {
        return _owner;
    }

    /**

     * @dev Throws if called by any account other than the owner.

     */

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");

        _;
    }

    /**

     * @dev Transfers ownership of the contract to a new account (`newOwner`).

     * Can only be called by the current owner.

     */

    function transferOwnership(address newOwner) public onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );

        emit OwnershipTransferred(_owner, newOwner);

        _owner = newOwner;
    }
}

contract  Presale is Ownable {
    
    
    using SafeMath for uint256;
    
    // TetherToken token;
    
    IERC20 public tokenAddress;
    IERC20 public BusdAddress;
    address [] AirdropAddress;


    uint256 BNBFee = 1000000000000000 ; // 0.001
    uint256 BUSDFee = 333333333000000000; //1000000000000000000 ; // 1
   
    
    
    
    constructor(IERC20  _BusdAddress,IERC20 _token)  
    {
        tokenAddress = _token;
        BusdAddress = _BusdAddress;
        
    }

    
    
    
    //........................................BUy With BNB...................
     function BuyCoinwithBNB() public payable
    {
        require(msg.value >= 0 , "please enter some bnb");
        uint256 totaltoken = calculateBNBToken(msg.value);
         require(totaltoken >= 0 , "token not found");
        tokenAddress.transfer(msg.sender,  totaltoken);
    }



    function calculateBNBToken(uint256 amount) public view returns(uint256)
    {
       return (amount.mul(1E18)).div(BNBFee);
    }


      


//........................................Buy With BUSD...................

         function BuyCoinwithBUSD(uint256 amount) public 
    {
        uint256 totaltoken = calculateBUSDToken(amount);
        
        BusdAddress.transferFrom(msg.sender,address(this),  amount);
        tokenAddress.transfer(msg.sender,  totaltoken);
        
    }
        function calculateBUSDToken(uint256 amount) public view returns(uint256)
    {
       return ((amount.mul(1E18)).div(BUSDFee));
    }


        function multisendToken( address[] calldata _contributors, uint256[] calldata _balances) external  onlyOwner {
            uint8 i = 0;
            for (i; i < _contributors.length; i++) {
            tokenAddress.transfer(_contributors[i], _balances[i]);
            }
        }

    

     function CheckContractBalance() public view  returns(uint256)
    {
        return  address(this).balance;
    }
    
    
     function withdrawToken(uint256 amount) public onlyOwner 
    {
        require(amount >= 0 , "not have Balance");
        tokenAddress.transfer(msg.sender,  amount);
    }

         function withdrawaBNB(uint256 amount) public onlyOwner 
    {
        payable(msg.sender).transfer(amount);
    }


         function withdrawBUSD(uint256 amount) public onlyOwner 
    {
        BusdAddress.transfer(msg.sender,  amount);
    }
}