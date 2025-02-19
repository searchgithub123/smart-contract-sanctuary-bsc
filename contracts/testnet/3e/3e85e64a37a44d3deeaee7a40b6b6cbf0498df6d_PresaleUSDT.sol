/**
 *Submitted for verification at BscScan.com on 2022-10-12
*/

/**
 *Submitted for verification at BscScan.com on 2022-10-12
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// File: Presale.sol





contract PresaleUSDT{
    address public admin;
    IERC20 public immutable USDT;

    event AdminWithdrawal(uint bnbAmount, uint tokenAmount);

    //Presale
    uint256 public busdRate;
    uint256 public maxPerWallet;
    uint256 public hardCap;
    uint256 public raisedBUSD;
    uint256 public buyers;

    mapping(uint256 => address) public buyerstoAddress;
    mapping(address => uint) public spentBNB;   
    mapping(address => uint) public boughtTokens;

    bool public presaleStart;
    bool public presaleEnd;

    event presaleStarted(uint starttime, uint _hardcap);
    event Bought(address indexed buyer, uint tokenAmouunt, uint bnbAmount);
    event Withdraw(address indexed withdrawer, uint tokenAmount, uint bnbAmount);
    event PresaleEnded(uint endTime, uint _raisedBUSD);


    mapping(address => uint) private TotalBalance;
    mapping(address => uint) private claimCount;
    mapping(address => uint) private claimedAmount;
    mapping(address => uint) private claimmable;
    mapping(address => bool) private bought;



    constructor() {
        admin = payable(msg.sender);
         USDT = IERC20(0xECfC68bc25E3F379E8E39370350B0e8Cad1C9882);
         //0xeD24FC36d5Ee211Ea25A80239Fb8C4Cfd80f12Ee
    } 

    //Presale

    function initialize(uint buyUnit, uint hardcap, uint maxperwallet) external {
        require(msg.sender == admin);
        hardCap = hardcap;
        busdRate = buyUnit;       
        maxPerWallet = maxperwallet;
    }

    function changeAdmin(address newAdmin) external{
        admin = newAdmin;
    }


    function startPresale() external {
        require(msg.sender == admin);
        
        presaleStart = true; 

       emit  presaleStarted(block.timestamp, hardCap);
    }


    function buy(uint amount) public{
        require(presaleStart, "PO"); //Presale Off
        require(raisedBUSD + amount <= hardCap, "TM");//Too much, gone over hard cap
        require(amount <= maxPerWallet, "EMPW");//Exceeding max per wallet

        require(boughtTokens[msg.sender] + amount < maxPerWallet);

        uint256 tokenAmount = amount * busdRate;

        require(boughtTokens[msg.sender] + tokenAmount < maxPerWallet);


        USDT.approve(address(this), amount);
        USDT.transferFrom(msg.sender, address(this), amount);

        buyers++;

        if(boughtTokens[msg.sender] == 0){
           
            buyerstoAddress[buyers] = msg.sender;
        
        }


        spentBNB[msg.sender]+=amount;
        boughtTokens[msg.sender]+=tokenAmount;
        TotalBalance[msg.sender] +=tokenAmount;
        raisedBUSD += amount;


        
        emit Bought(msg.sender, amount, tokenAmount);


    }



    function emergencyWithdrawal(uint amount) external{
        require(presaleStart, "PO");
        require(spentBNB[msg.sender] >= amount);

        uint tokenDebit = amount * busdRate;

        boughtTokens[msg.sender] -= tokenDebit;
        spentBNB[msg.sender] -= amount;

        USDT.transfer(msg.sender, amount);

        emit Withdraw(msg.sender, amount, tokenDebit);

    }

    function endPresale() external{
        require(msg.sender == admin, "NA");//Not admin
        require(presaleStart, "PO");//Presale Off

        presaleStart = false;
        presaleEnd = true;

        emit PresaleEnded(block.timestamp, raisedBUSD);
    }
    

    //Admin Withdrawal

    function AdminWIthdrawal(uint amount) external{
        require(msg.sender==admin, "NA");
        require(amount <= raisedBUSD);

        //  (bool sent,) = admin.call{value: raisedBUSD}("");
        // require(sent, "Fail");

        raisedBUSD -= amount;

        USDT.transfer(admin, amount);

    }

    
}