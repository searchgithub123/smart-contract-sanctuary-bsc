/**
 *Submitted for verification at BscScan.com on 2022-08-07
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
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

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
    * @dev Initializes the contract setting the deployer as the initial owner.
    */
    constructor () {
      address msgSender = _msgSender();
      _owner = msgSender;
      emit OwnershipTransferred(address(0), msgSender);
    }

    /**
    * @dev Returns the address of the current owner.
    */
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
}

interface ERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract SmartPaycheck is Context, Ownable {
    address busd = 0x269df75431D46765AB3FCF33Ed09dDe31b7E9515;
    address private feeAddress = 0x6fACD5726baCC409E409cF6eCA8915f8580551Ce;
    uint256 private feePercent = 3;
    bool private initialized = false;

    struct User {
		uint256 deposit;
        uint256 withdraw;
		uint256 lastTime;
		address referrer;
		uint256 bonus;
		uint256 totalBonus;
	}

    mapping (address => User) private users;

    constructor() {
    }
    
    function withdraw() public {
        checkState();

        require(users[msg.sender].withdraw <= users[msg.sender].deposit * 365 / 100, "err: can't withdraw more than 365%");

        uint256 amount = getRewardsSinceLastDeposit(msg.sender);
        uint256 fee = calculateFee(amount);
        users[msg.sender].lastTime = block.timestamp;
        users[msg.sender].withdraw += amount - fee;
        ERC20(busd).transfer(feeAddress, fee);

        uint256 fundingFee = amount * 2 / 100;
        ERC20(busd).transfer(address(msg.sender), amount - fee - fundingFee);
    }
    
    function deposit(address ref, uint256 amount) public {
        require(initialized, "err: not started");
        if (users[msg.sender].lastTime != 0) {
            require(users[msg.sender].lastTime + 3600 * 24 * 7 < block.timestamp, "err: not in time");
        }
        require(amount >= 1 , "err: has to be greater than 1");

        ERC20(busd).transferFrom(address(msg.sender), address(this), amount);
        uint256 fee = calculateFee(amount);
        ERC20(busd).transfer(feeAddress, fee);

        users[msg.sender].deposit += amount - fee;

        require(users[msg.sender].deposit <= 5000 , "err: can't be greater than 5000");

        users[msg.sender].lastTime = block.timestamp;
        
        if(ref == msg.sender) {
            ref = address(0);
        }
        
        if(users[msg.sender].referrer == address(0) && users[msg.sender].referrer != msg.sender) {
            users[msg.sender].referrer = ref;
        }

        if (users[msg.sender].referrer != address(0))
        {
            uint256 referralFee = amount * 5 / 100;
            users[users[msg.sender].referrer].bonus += referralFee;
            users[users[msg.sender].referrer].totalBonus += referralFee;
        }
    }
    
    function compoundRef() public {
        require(initialized, "err: not started");
        require(users[msg.sender].bonus > 0, "err: zero amount");

        users[msg.sender].deposit += users[msg.sender].bonus;
        users[msg.sender].bonus = 0;
        users[msg.sender].lastTime = block.timestamp;
    }

    function withdrawRef() public {
        require(initialized, "err: not started");
        require(users[msg.sender].bonus > 0, "err: zero amount");

        ERC20(busd).transfer(address(msg.sender), users[msg.sender].bonus);
        users[msg.sender].bonus = 0;
    }

    function checkState() internal view {
        require(initialized, "err: not started");
        require(users[msg.sender].lastTime > 0, "err: no deposit");
        require(users[msg.sender].lastTime + 3600 * 24 * 7 < block.timestamp, "err: not in time");
    }
    
    function calculateFee(uint256 amount) private view returns(uint256) {
        return amount * feePercent / 100;
    }
    
    function start() public onlyOwner {
        require(initialized == false, "err: already started");
        initialized=true;
    }
    
    function getBalance() public view returns(uint256) {
        return ERC20(busd).balanceOf(address(this));
    }
    
	function getUserReferralBonus(address addr) public view returns(uint256) {
		return users[addr].bonus;
	}

	function getUserReferralTotalBonus(address addr) public view returns(uint256) {
		return users[addr].totalBonus;
	}

	function getUserReferralWithdrawn(address addr) public view returns(uint256) {
		return users[addr].totalBonus - users[addr].bonus;
	}

	function getUserDepositAmount(address addr) public view returns(uint256) {
		return users[addr].deposit;
	}

	function getUserWithdrawAmount(address addr) public view returns(uint256) {
		return users[addr].withdraw;
	}

	function getUserCheckPoint(address addr) public view returns(uint256) {
		return users[addr].lastTime;
	}

    function getRewardsSinceLastDeposit(address adr) public view returns(uint256) {
        uint256 secondsPassed=min(604800, block.timestamp - users[adr].lastTime);
        return secondsPassed * users[adr].deposit / 4762204;
    }
    
    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }
}