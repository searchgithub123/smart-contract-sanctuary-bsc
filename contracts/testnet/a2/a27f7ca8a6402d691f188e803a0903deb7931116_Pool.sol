/**
 *Submitted for verification at BscScan.com on 2022-08-05
*/

//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {

	mapping(address => bool) public manager;

    event OwnershipTransferred(address indexed newOwner, bool isManager);


    constructor() {
        _setOwner(_msgSender(), true);
    }

    modifier onlyOwner() {
        require(manager[_msgSender()], "Ownable: caller is not the owner");
        _;
    }

    function setOwner(address newOwner,bool isManager) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner,isManager);
    }

    function _setOwner(address newOwner, bool isManager) private {
        manager[newOwner] = isManager;
        emit OwnershipTransferred(newOwner, isManager);
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function mint(address account, uint amount) external;
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
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

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


library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {codehash := extcodehash(account)}
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success,) = recipient.call{value : amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }


    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }


    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value : weiValue}(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}


contract Pool is Ownable{
    using SafeMath for uint256;
	using Address for address;
	
	struct PoolInfo{
		bool isEnabled;
		uint256 usdtRate;
		uint256 maxMiningTime;
		uint256 miningRate;
	}
	mapping(uint256 => PoolInfo)public poolMap;
	struct UserPool{
		bool isPledge;
		uint256 usdtAmount;
		uint256 tokenAmount;
		uint256 pledgeTime;
		uint256 lastTime;
	}
	mapping(address => mapping(uint256 => UserPool)) public userMap;
	
	struct LeaderInfo{
		address leader;
		uint256 oneAmount;
		uint256 twoAmount;
		uint256 threeAmount;
	}
	mapping(address => LeaderInfo) public leaderMap;
	mapping(uint256 => uint256) public leaderRate;
	
	
	address public HCB = 0xCCE7C0681b83c1F26E89014c861330181984c0A5;
	address public USDT = 0x5006d1dec5638b543b49DeA8052c3c043C99e70D;
	address public marketAddress;
	address public burnAddress;
	
	uint256 public marketRate;
	uint256 public burnRate;
	

	
	
	event Pledge(address user, uint256 poolId, uint256 tokenAmount, uint256 usdtAmount);
	event WithdrawFit(address user, uint256 poolId, uint256 fit);
	event Withdraw(address user, uint256 poolId, uint256 tokenAmount,uint256 usdtAmount);
	event Leader(address user, address leader);
	
	
	constructor()  {
		_setPoolMap(1,true,100,10 * 86400,10);
		_setPoolMap(2,true,100,30 * 86400,15);
		_setPoolMap(3,true,100,90 * 86400,20);
		_setPoolMap(4,true,100,365 * 86400,30);
		
		_setLeaderRate(1,50);
		_setLeaderRate(2,30);
		_setLeaderRate(3,20);
		
		marketAddress = msg.sender;
		burnAddress = msg.sender;
		marketRate = 50;
		burnRate = 50;	
		

    }
	
	
	function pledge(uint256 _poolId, uint256 _tokenAmount, address _leader)public{
		require(poolMap[_poolId].isEnabled,"Not Enabled");
		require(!userMap[msg.sender][_poolId].isPledge,"exist");
		
		IERC20(HCB).transferFrom(msg.sender,address(this),_tokenAmount);
		uint256 userUsdtAmount = _tokenAmount.mul(poolMap[_poolId].usdtRate).div(1000);
		IERC20(USDT).transferFrom(msg.sender,address(this),userUsdtAmount);
		
		userMap[msg.sender][_poolId].isPledge = true;
		userMap[msg.sender][_poolId].tokenAmount = _tokenAmount;
		userMap[msg.sender][_poolId].usdtAmount = userUsdtAmount;
		userMap[msg.sender][_poolId].pledgeTime = block.timestamp;
		userMap[msg.sender][_poolId].lastTime = block.timestamp;
		emit Pledge(msg.sender,_poolId,_tokenAmount,userUsdtAmount);		
		
	    if(leaderMap[msg.sender].leader == address(0) && _leader != address(0) && _leader != msg.sender){
            leaderMap[msg.sender].leader = _leader;
			address user = _leader;
			leaderMap[user].oneAmount = leaderMap[user].oneAmount.add(1);
			
			if(leaderMap[user].leader != address(0) ){
				user = leaderMap[user].leader;
				leaderMap[user].twoAmount = leaderMap[user].twoAmount.add(1);
				
				if(leaderMap[user].leader != address(0)){
					user = leaderMap[user].leader;
					leaderMap[user].threeAmount = leaderMap[user].threeAmount.add(1);
				}
			}
			
			emit Leader(msg.sender,_leader);
        }
    }

   
	
	function pendingFit(uint256 _poolId, address _user) public view returns(uint256){
		if(userMap[_user][_poolId].isPledge == false){
			return 0;
		}
		uint256 maxTime = poolMap[_poolId].maxMiningTime;
		uint256 trueTime = block.timestamp.sub(userMap[_user][_poolId].lastTime);
		if(trueTime > maxTime){
			trueTime = maxTime;
		}
		uint256 rate = userMap[_user][_poolId].tokenAmount.mul(poolMap[_poolId].miningRate).div(1000);
		uint256 fit = rate.mul(trueTime).div(86400) ;
		return fit;
		
	}
	
	function withdrawFit(uint256 _poolId)public{
		
		uint256 fit = pendingFit(_poolId, msg.sender);
		if (fit > 0 ){
			uint256 marketFee = fit.mul(marketRate).div(1000);
			uint256 burnFee = fit.mul(burnRate).div(1000);
			
			IERC20(HCB).transfer(marketAddress,marketFee);
			IERC20(HCB).transfer(burnAddress,burnFee);
			
			address user = msg.sender;
			uint256 leaderFee ;
			for(uint256 i = 1; i <= 3; i++){
				address userLeader = leaderMap[user].leader;
                if(userLeader == address(0)) break;               
				IERC20(HCB).transfer(userLeader,fit.mul(leaderRate[i]).div(1000));
				leaderFee = leaderFee.add(fit.mul(leaderRate[i]).div(1000));
				user = userLeader;
				
			}
			
			uint256 trueFit = fit.sub(marketFee).sub(burnFee).sub(leaderFee);
			
			IERC20(HCB).transfer(msg.sender,trueFit);
			emit WithdrawFit(msg.sender,_poolId,fit);
			

			userMap[msg.sender][_poolId].lastTime = block.timestamp;
		}

	}
	
	function withdraw(uint256 _poolId)public{
		uint256 maxTime = poolMap[_poolId].maxMiningTime;
		uint256 trueTime = block.timestamp.sub(userMap[msg.sender][_poolId].pledgeTime);
		
		require(trueTime >= maxTime,"time is not up yet");
		withdrawFit(_poolId);
		
		IERC20(HCB).transfer(msg.sender,userMap[msg.sender][_poolId].tokenAmount);
		IERC20(USDT).transfer(msg.sender,userMap[msg.sender][_poolId].usdtAmount);
		
		userMap[msg.sender][_poolId].isPledge = false;
		userMap[msg.sender][_poolId].tokenAmount = 0;
		userMap[msg.sender][_poolId].usdtAmount = 0;
		userMap[msg.sender][_poolId].pledgeTime = 0;		
		userMap[msg.sender][_poolId].lastTime = 0;
	}
	
	function setMarketFee(address _marketAddress, uint256 _marketRate)public onlyOwner {
		marketAddress = _marketAddress;
		marketRate = _marketRate;
	}
	
	function setBurnFee(address _burnAddress, uint256 _burnRate)public onlyOwner {
		burnAddress = _burnAddress;
		burnRate = _burnRate;
	}		
	
	function setLeaderRate(uint256 _level, uint256 _rate)public onlyOwner {
		_setLeaderRate(_level,_rate);
	}
	
	function _setLeaderRate(uint256 _level, uint256 _rate)internal{
		leaderRate[_level] = _rate;
	}
	
	function setPoolMap(uint256 _poolId, bool _isEnabled, uint256 _usdtRate, uint256 _maxMiningTime, uint256 _miningRate)public onlyOwner{
		_setPoolMap(_poolId, _isEnabled, _usdtRate, _maxMiningTime, _miningRate);
	}
	
	function _setPoolMap(uint256 _poolId, bool _isEnabled, uint256 _usdtRate, uint256 _maxMiningTime, uint256 _miningRate)internal{
		poolMap[_poolId].isEnabled = _isEnabled;
		poolMap[_poolId].usdtRate = _usdtRate;
		poolMap[_poolId].maxMiningTime = _maxMiningTime;
		poolMap[_poolId].miningRate = _miningRate;
	}
	
	function withdrawStuckTokens(address _token, uint256 _amount) public onlyOwner {
		IERC20(_token).transfer(msg.sender, _amount);
	}
	
	function withdrawStuckEth(address payable recipient) public onlyOwner {
		recipient.transfer(address(this).balance);
	}
	

	function update(address user, uint256 _poolId, bool _isPledge, uint256 _tokenAmount, uint256 _usdtAmount, uint256 _pledgeTime) public onlyOwner{
		userMap[user][_poolId].isPledge = _isPledge;
		userMap[user][_poolId].tokenAmount = _tokenAmount;
		userMap[user][_poolId].usdtAmount = _usdtAmount;
		userMap[user][_poolId].pledgeTime = _pledgeTime;
	}
   
}