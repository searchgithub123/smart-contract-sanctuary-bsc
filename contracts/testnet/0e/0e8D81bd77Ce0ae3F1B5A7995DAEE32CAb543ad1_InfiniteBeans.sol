/**
 *Submitted for verification at BscScan.com on 2023-01-04
*/

/**

   ___               __     _               _      _             
  |_ _|   _ _       / _|   (_)    _ _      (_)    | |_     ___   
   | |   | ' \     |  _|   | |   | ' \     | |    |  _|   / -_)  
  |___|  |_||_|   _|_|_   _|_|_  |_||_|   _|_|_   _\__|   \___|  
_|"""""|_|"""""|_|"""""|_|"""""|_|"""""|_|"""""|_|"""""|_|"""""| 
"`=0-0-'"`-0-0-'"`-0-0-'"`-0-0-'"`-0-0-'"`-0-0-'"`-0-0-'"`-0-0-' 


 | |__     ___    __ _    _ _      ___                           
 | '_ \   / -_)  / _` |  | ' \    (_-<                           
 |_.__/   \___|  \__,_|  |_||_|   /__/_                          
_|"""""|_|"""""|_|"""""|_|"""""|_|"""""|                         
"`-0-0-'"`-0-0-'"`-0-0-'"`-0-0-'"`-0-0-'                         


*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IERC721 {
    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function safeMint(address to, uint8 index) external returns (uint256);
}

library SafeMath {
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract InfiniteBeans is Ownable {
    using SafeMath for uint256;
    address payable public feeReceiver;
    address public silverNft;
    address public goldNft;
    address public platinumNft;

    uint256 public totalUsers;
    uint256 public totalMiners;
    uint256 public totalInvested;
    uint256 public totalRefRewards;

    uint256 private marketValue;
    uint256 private creditsToHire1Miner = 1080000; 
    uint256 private silverToHire1Miner = 864000;
    uint256 private goldToHire1Miner = 720000;
    uint256 private platinumToHire1Miner = 575424;
    uint256 private PSN = 10000;
    uint256 private PSNH = 5000;
    uint256 public depositFee = 50;
    uint256 public withdrawFee = 50;
    uint256 public refPercent = 100;
    uint256 public percentDivider = 1000;
    uint256 public minBuy = 0.0000000005 ether;
    uint256[2] public maxWallet = [5 ether, 10 ether];
    uint256[2] public buyLimit = [100 ether, 200 ether];

    bool private initialized;
    bool public whitelistEnable;
    bool public publicEnable;

    struct RefData {
        address referrer;
        uint256 referals;
        uint256 amount;
    }

    mapping(address => uint256) public investedBnb;
    mapping(address => uint256) public hiredMiners;
    mapping(address => RefData) private userRefData;
    mapping(address => uint256) public claimedProfit;
    mapping(address => uint256) public lastHireAt;
    mapping(address => bool) public whitelistedUsers;
    mapping(address => uint256) public userCurrentTier;
 
    constructor() {
        feeReceiver = payable(msg.sender);
    }

    receive() external payable{}

    function startMining() public payable onlyOwner {
        require(marketValue == 0);
        initialized = true;
        marketValue = 108000000000;
    }

    function hireMiners(address ref) public payable {
        require(initialized,"Not started yet");
        if(whitelistEnable){
            require(whitelistedUsers[msg.sender],"User not whitelisted");
        } else {
            require(publicEnable,"Public round not started");
        }
        require(msg.value >= minBuy, "Less than min amount");
        if (getBalance() < buyLimit[0]) {
            require(
                investedBnb[msg.sender] + msg.value <= maxWallet[0],
                "Exceeds max wallet limit"
            );
        } else if (getBalance() >= buyLimit[0] && getBalance() < buyLimit[1]) {
            require(
                investedBnb[msg.sender] + msg.value <= maxWallet[1],
                "Exceeds max wallet limit"
            );
        }

        if(investedBnb[msg.sender] == 0){
            totalUsers++;
        }
        investedBnb[msg.sender] = investedBnb[msg.sender].add(msg.value);
        totalInvested = totalInvested.add(msg.value);

        if (ref == msg.sender || ref == address(0)) {
            ref = feeReceiver;
        }
        if (
            userRefData[msg.sender].referrer == address(0) &&
            userRefData[msg.sender].referrer != msg.sender
        ) {
            userRefData[msg.sender].referrer = ref;
            userRefData[ref].referals++;
        }
        uint256 refReawrd = msg.value * refPercent / percentDivider;
        payable(ref).transfer(refReawrd);
        userRefData[msg.sender].amount = userRefData[msg.sender].amount.add(refReawrd);
        totalRefRewards = totalRefRewards.add(refReawrd);

        uint256 profit = calculateProfit(
            msg.value,
            SafeMath.sub(address(this).balance, msg.value)
        );
        profit = profit.sub(
            profit.mul(depositFee).div(percentDivider)
        );

        uint256 fee = msg.value.mul(depositFee).div(percentDivider);
        feeReceiver.transfer(fee);

        claimedProfit[msg.sender] = claimedProfit[msg.sender].add(profit);
        rehireMiners();
    }

    function rehireMiners() public {
        require(initialized,"Not started yet");

        if(IERC721(platinumNft).balanceOf(msg.sender) > 0){
            userCurrentTier[msg.sender] = platinumToHire1Miner;
        } else if(IERC721(platinumNft).balanceOf(msg.sender) > 0){
            userCurrentTier[msg.sender] = goldToHire1Miner;
        } else if(IERC721(platinumNft).balanceOf(msg.sender) > 0){
            userCurrentTier[msg.sender] = silverToHire1Miner;
        } else {
            userCurrentTier[msg.sender] = creditsToHire1Miner;
        }

        uint256 profitGenrated = getMyProfit(msg.sender);
        uint256 newMiners = calculateMiners(msg.sender, profitGenrated);
        hiredMiners[msg.sender] = hiredMiners[msg.sender].add(newMiners);
        totalMiners = totalMiners.add(newMiners);
        claimedProfit[msg.sender] = 0;
        lastHireAt[msg.sender] = block.timestamp;

        //boost market to nerf miners hoarding
        marketValue = marketValue.add(profitGenrated.div(5));
    }

    function takeProfit() public {
        require(initialized,"Not started yet");
        uint256 hasProfit = getMyProfit(msg.sender);
        uint256 profit = calculateSellProfit(hasProfit);
        require(profit > 0,"0 profit");
        uint256 fee = profit.mul(withdrawFee).div(percentDivider);
        claimedProfit[msg.sender] = 0;
        lastHireAt[msg.sender] = block.timestamp;
        marketValue = SafeMath.add(marketValue, hasProfit);
        feeReceiver.transfer(fee);
        payable(msg.sender).transfer(SafeMath.sub(profit, fee));
    }

    function calculateTrade(
        uint256 rt,
        uint256 rs,
        uint256 bs
    ) private view returns (uint256) {
        return
            SafeMath.div(
                SafeMath.mul(PSN, bs),
                SafeMath.add(
                    PSNH,
                    SafeMath.div(
                        SafeMath.add(
                            SafeMath.mul(PSN, rs),
                            SafeMath.mul(PSNH, rt)
                        ),
                        rt
                    )
                )
            );
    }

    function calculateSellProfit(uint256 profit) public view returns (uint256) {
        return calculateTrade(profit, marketValue, address(this).balance);
    }

    function calculateProfit(uint256 bnb, uint256 contractBalance)
        public
        view
        returns (uint256)
    {
        return calculateTrade(bnb, contractBalance, marketValue);
    }

    function calculateProfitSimple(uint256 bnb) public view returns (uint256) {
        return calculateProfit(bnb, address(this).balance);
    }

    function getProfit(address adr) public view returns (uint256) {
        uint256 hasProfit = getMyProfit(adr);
        uint256 profit = calculateSellProfit(hasProfit);
        return profit;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function bnbToMiners(address user, uint256 bnb) public view returns (uint256 newMiners) {
        uint256 profitGenrated = calculateProfitSimple(bnb);
        newMiners = calculateMiners(user, profitGenrated);
    }

    function calculateMiners(address user, uint256 profit) public view returns (uint256 miners) {
        miners = profit.div(userCurrentTier[user] != 0 ? userCurrentTier[user] : creditsToHire1Miner);
    }

    function getMyMiners(address adr) public view returns (uint256) {
        return hiredMiners[adr];
    }

    function getMyProfit(address adr) public view returns (uint256) {
        return SafeMath.add(claimedProfit[adr], getProfitSinceLastHire(adr));
    }

    function getUserRefData(address adr) public view returns (address referrer, uint256 referals, uint256 amount) {
        referrer = userRefData[adr].referrer;
        referals = userRefData[adr].referals;
        amount = userRefData[adr].amount;
    }

    function getProfitSinceLastHire(address adr) public view returns (uint256) {
        uint256 secondsPassed = calculateMin(
            userCurrentTier[adr] != 0 ? userCurrentTier[adr] : creditsToHire1Miner,
            SafeMath.sub(block.timestamp, lastHireAt[adr])
        );
        return SafeMath.mul(secondsPassed, hiredMiners[adr]);
    }

    function calculateMin(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }

    function startWhitelistRound() external onlyOwner {
        whitelistEnable = true;
    }

    function startPublicRound() external onlyOwner {
        whitelistEnable = false;
        publicEnable = true;
    }

    function setWhitelistedUsers(address[] memory _users, bool _value) external onlyOwner {
        for(uint32 i=0 ; i < _users.length ; i++){
            whitelistedUsers[_users[i]] = _value;
        }
    }

    function changeFeeReceiver(address adr) external onlyOwner {
        feeReceiver = payable(adr);
    }

    function setNftAddresses(address adr1, address adr2, address adr3) external onlyOwner {
        silverNft = adr1;
        goldNft = adr2;
        platinumNft = adr3;
    }

    function setDepositFeePercent(uint256 percent) external onlyOwner {
        require(percent > 0 && percent <= 50);
        depositFee = percent;
    }

    function setWithdrawFeePercent(uint256 percent) external onlyOwner {
        require(percent > 0 && percent <= 50);
        withdrawFee = percent;
    }

    function setRefPercent(uint256 percent) external onlyOwner {
        require(percent >= 10 && percent <= 100);
        refPercent = percent;
    }

    function setMinAndMaxBuy(uint256 min) external onlyOwner {
        require(min <= 1 ether);
        minBuy = min;
    }

    function setMaxWallet(uint256 l1, uint256 l2) external onlyOwner {
        require(l1 >= 1 ether && l2 >= 5 ether);
        maxWallet[0] = l1;
        maxWallet[1] = l2;
    }

    function setBuyLimit(uint256 l1, uint256 l2) external onlyOwner {
        require(l1 >= 50 ether && l2 >= 100 ether);
        buyLimit[0] = l1;
        buyLimit[1] = l2;
    }
}