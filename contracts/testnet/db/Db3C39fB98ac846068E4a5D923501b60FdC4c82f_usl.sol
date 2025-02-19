/**
 *Submitted for verification at BscScan.com on 2022-12-30
*/

/**
 *Submitted for verification at BscScan.com on 2022-12-29
*/

/**
 *Submitted for verification at hecoinfo.com on 2022-12-3
*/

pragma solidity ^0.8.6;

// SPDX-License-Identifier: Unlicensed
interface IERC20 {
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract Ownable {
    address public _owner;
    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }
    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {//admin_user
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    function changeOwner(address newOwner) public onlyOwner {
        _owner = newOwner;
    }



}

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}

contract usl is IERC20, Ownable {
    using SafeMath for uint256;

    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) private _isExcludedFromFee;

    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal;
    uint256 private _rTotal;
    uint256 private _tFeeTotal;

    string private _name;
    string private _symbol;
    uint256 private _decimals=18;


    uint256 public _liquidityFee = 2;

    uint256 public _destroyFee = 2;
    address private _destroyAddress =
        address(0x0000000000000000000000000000000000000000);

    uint256 public _inviterFee = 8;

    mapping(address => address) public inviter;
    mapping(address => uint256) public lastSellTime;

    address public uniswapV2Pair;
    
    address public fund1Address = address(0x21445B12F24B0e1a88eCC248f84634c0D62C82Bc);
    
    address public fund2Address = address(0x21445B12F24B0e1a88eCC248f84634c0D62C82Bc);
    
    uint256 public _fund1Fee = 2;
    
    uint256 public _fund2Fee = 1;
    
    uint256 public _mintTotal;

    uint256 public order_price=58;
    //ipo开关。0关，，，1开
    uint256 public ipo_start=0;//ipo_start ipo_amount ipo_count user_level user_yeji
    uint256 public ipo_amount=100;
    uint256 public ipo_count=0;
    mapping(address => uint256) public user_level;
    mapping(address => uint256) public user_balance;
    mapping(address => uint256) public user_yeji;
    mapping(address => uint256) public user_tuijian;
    mapping(address => uint256) public user_xiaofei;
    mapping(address => uint256) public user_ziji;
    uint[] public jicha = [0,2,4,6,9,11];
    address public admin_user = address(0x6A713053670203C1e1b507D44f3Bf7dae8b51CC6);
    IERC20 public  token ;
    IERC20 public  usdt ;


    uint public listCount = 0;
    struct List {
        uint256 types;
        string zz;
        uint256 amount;
        uint256 status;
        uint256 creatTime;
    }
    mapping  (uint=>List) public lists;
    mapping (uint => address) public listToOwner;
    mapping (address => uint256) public ownerListCount;

    function savelist() public {
        _savelist(1,'heihei',100,msg.sender);
    }

    function _savelist(uint256 _types,string memory _zz,uint256 _amount,address _user) internal {
        List  memory list = List(_types,_zz,_amount,1,uint32(block.timestamp));
        listCount=listCount.add(1);
        lists[listCount]=list;
        ownerListCount[_user] = ownerListCount[_user].add(1);
        listToOwner[listCount] = _user;//158报单 2推荐奖 3极差奖 4ipo 5提现 6
    }

    uint public orderCount = 0;  
    struct Order {
        uint256 order_type;//1高端白酒，2高端红酒，3高端茶饮
        string order_zz;
        uint256 order_amount;
        uint256 order_status;
        uint256 order_creatTime;
    }  
    mapping  (uint=>Order) public orders;
    mapping (uint => address) public orderToOwner;
    mapping (address => uint256) public ownerOrderCount;

    function _saveorder(uint256 _types,string memory _zz) internal {

        Order  memory order = Order(_types,_zz,order_price,1,uint32(block.timestamp));
        orderCount=orderCount.add(1);
        orders[orderCount]=order;
        ownerOrderCount[msg.sender] = ownerOrderCount[msg.sender].add(1);
        orderToOwner[orderCount] = msg.sender;
        user_xiaofei[msg.sender]=user_xiaofei[msg.sender].add(1);
    }



    //用户58u报单
    function saveorder(address fatheraddr) public  {
        require(fatheraddr!=msg.sender,"Can't do it yourself");
        if (inviter[msg.sender] == address(0)) {
            inviter[msg.sender] = fatheraddr;
            if(user_ziji[msg.sender]==0){
                user_tuijian[fatheraddr] = user_tuijian[fatheraddr].add(1);
            }
        }
        require(usdt.balanceOf(msg.sender)>=58*10**18,"USDT balance too low");
        usdt.transferFrom(msg.sender,address(this), 58*10**18);
        user_ziji[msg.sender]==user_ziji[msg.sender]+1;
        uint _test = uint(keccak256(abi.encodePacked(block.timestamp,block.difficulty,  msg.sender))) % 3+1;
        address curx;
        curx = msg.sender;
        for (int256 i = 0; i < 30; i++) {
            curx = inviter[curx];
            uint256 rate ;
            user_yeji[curx]=user_yeji[curx]+order_price;
            if(user_yeji[curx]>=580&&user_yeji[curx]<5800){
                user_level[curx]==1;
            }
            if(user_yeji[curx]>=5800&&user_yeji[curx]<29000){
                user_level[curx]==2;
            }
            if(user_yeji[curx]>=29000&&user_yeji[curx]<87000){
                user_level[curx]==3;
            }
            if(user_yeji[curx]>=87000&&user_yeji[curx]<174000){
                user_level[curx]==4;
            }
            if(user_yeji[curx]>=174000){
                user_level[curx]==5;
            }
            if (curx == address(0)) { 
                break;
            }
        }  
        _tjj(msg.sender);
        _jcj(msg.sender);

        if(_test==1){
            _saveorder(1,unicode"高端白酒");
            _savelist(1,unicode"购买套餐获得高端白酒" ,58,msg.sender);
        }
        if(_test==2){
            _saveorder(2,unicode"高端红酒");
            _savelist(1,unicode"购买套餐获得高端红酒" ,58,msg.sender);
        }
        if(_test==3){
            _saveorder(3,unicode"高端茶饮");
            _savelist(1,unicode"购买套餐获得高端茶饮" ,58,msg.sender);
        }
        
    }
    //极差奖
    function _jcj(address _user) internal {
        address curx;
        curx = _user;
        uint256 max=0 ;
        uint256 cha=0 ;
        for (int256 i = 0; i < 30; i++) {
            curx = inviter[curx];
            uint256 rate ;
            if(user_level[curx]>max){
                cha=jicha[user_level[curx]]-jicha[max] ; //user_level[curx]-max;
                max=user_level[curx];
                user_balance[curx]=user_balance[curx]+cha;
                _savelist(3,unicode"获得极差奖" ,cha,curx);
            }
            
        }
    }


    //推荐奖
    function _tjj(address _user) internal {
        address cur = inviter[_user];
        
        for (int256 i = 0; i < 6; i++) {
            uint256 rate ;
            //cur = inviter[cur];
            if (i == 0) {
                if(user_tuijian[cur]>=1){
                    if(user_ziji[msg.sender]>=1){
                        rate = 80;
                    
                    }
                }
            } if(i == 1) {
                if(user_tuijian[cur]>=2){
                    if(user_ziji[msg.sender]>=1){
                        rate = 40;
                    }
                }
            }if(i == 2) {
                if(user_tuijian[cur]>=6){
                    if(user_ziji[msg.sender]>=1){
                        rate = 30;
                    }
                }
            }if(i == 3) {
                if(user_tuijian[cur]>=6){
                    if(user_ziji[msg.sender]>=1){
                        rate = 20;
                    }
                }
            }if(i == 4) {
                if(user_tuijian[cur]>=6){
                    if(user_ziji[msg.sender]>=1){
                        rate = 15;
                    }
                }
            }if(i == 5) {
                if(user_tuijian[cur]>=6){
                    if(user_ziji[msg.sender]>=1){
                        rate = 5;
                    }
                }
            }
            if(rate>0){
                user_balance[cur]=user_balance[cur]+rate/10;
                _savelist(2,unicode"获得推荐奖" ,rate/10,cur);
            }
            cur = inviter[cur];
            if (cur == address(0)) {
                break;
            }
            
        }    

    }






    function adminsetbalance(uint256 num,address  _user) public {
        require(msg.sender==admin_user,"notadmin.");
        user_balance[_user]=num;
    }

    function adminsetadmin(address  _user) public {
        require(msg.sender==admin_user,"notadmin.");
        admin_user=_user;
    }


//用户资金列表
    function getListByOwner(address  _owner) external view returns(uint[] memory) {
        uint[] memory result = new uint[](getListByOwnergeshu(_owner));

        uint counter = 0;
        for (uint i = 0; i <= listCount; i++) {
            if (listToOwner[i] == _owner) {
                result[counter] = i;
                counter++;
            }
        }
        return result;
    }

    
    function getListByOwnergeshu(address  _owner) public view returns(uint counter) {
        uint[] memory result = new uint[](ownerListCount[_owner]);

        counter = 0;
        for (uint i = 0; i <= listCount; i++) {
            if (listToOwner[i] == _owner) {
                result[counter] = i;
                counter++;
            }
        }
        return counter;
    }

//用户订单列表
    function getOrderByOwner(address  _owner) external view returns(uint[] memory) {
        uint[] memory result = new uint[](getOrderByOwnergeshu(_owner));

        uint counter = 0;
        for (uint i = 0; i <= orderCount; i++) {
            if (orderToOwner[i] == _owner) {
                result[counter] = i;
                counter++;
            }
        }
        return result;
    }

    
    function getOrderByOwnergeshu(address  _owner) public view returns(uint counter) {
        uint[] memory result = new uint[](ownerOrderCount[_owner]);

        counter = 0;
        for (uint i = 0; i <= orderCount; i++) {
            if (orderToOwner[i] == _owner) {
                result[counter] = i;
                counter++;
            }
        }
        return counter;
    }








    
    constructor(address tokenOwner) {
        _name = "USL";
        _symbol = "USL";
        _decimals = 18;

        _tTotal = 1000000 * 10**_decimals;
        _mintTotal = 100000 * 10**_decimals;
        _rTotal = (MAX - (MAX % _tTotal));

        _rOwned[tokenOwner] = _rTotal;
        setMintTotal(_mintTotal);
        //exclude owner and this contract from fee
        _isExcludedFromFee[tokenOwner] = true;
        _isExcludedFromFee[address(this)] = true;

        _owner = tokenOwner;
        emit Transfer(address(0), tokenOwner, _tTotal);
    }



//用户ipo按钮
    function ipo() public {
        //_saveorder(1,unicode"高端白酒"); ipo_start ipo_amount ipo_count
        require(ipo_start == 1,'ipo is not start');
        require(ipo_count <= 10000,'ipo is too much');
        if(ipo_count==10000){
            ipo_start=0;
        }
        ipo_count=ipo_count.add(1);
        token.transfer(msg.sender, ipo_amount*10**18);
        _savelist(4,unicode"领取ipo" ,ipo_amount,msg.sender);
    }
  
    function adminsettokenaddress(IERC20 address3) public {
        require(msg.sender==admin_user,"not admin.");
        token = address3;
    }//order_price
    function adminsetorder_price(uint256 _jiage) public {
        require(msg.sender==admin_user,"not admin.");
        order_price = _jiage;
    }

    function adminsetusdtaddress(IERC20 address3) public {
        require(msg.sender==admin_user,"not admin.");
        usdt = address3;
    }

    function adminsetipo_start(uint256 kaiguan) public {
        require(msg.sender==admin_user,"not admin.");
        ipo_start = kaiguan;
    }
    function adminsetipo_amount(uint256 _amount) public {
        require(msg.sender==admin_user,"not admin.");
        ipo_amount = _amount;
    }

    function adminsetuser_level(uint256 _level,address _user) public {
        require(msg.sender==admin_user,"not admin.");
        user_level[_user] = _level;
    }
    function adminsetuser_yeji(uint256 _amount,address _user) public {
        require(msg.sender==admin_user,"not admin.");
        user_yeji[_user] = _amount;
    }

    function adminsetuser_balance(uint256 _balance,address _user) public {
        require(msg.sender==admin_user,"not admin.");
        user_balance[_user] = _balance;
    }

    function  admintransferOutusdt(address toaddress,uint256 amount,uint256 decimals2)  external onlyOwner {
        usdt.transfer(toaddress, amount*10**decimals2);
    }


    function  admintransferOuttoken(address toaddress,uint256 amount,uint256 decimals2)  external onlyOwner {
        token.transfer(toaddress, amount*10**decimals2);
    }



    function  tixian(uint256 num)  external returns (bool) {
        require(user_balance[msg.sender]>=num,"moneylow.");
        user_balance[msg.sender]=user_balance[msg.sender]-num;
        usdt.transfer(msg.sender, num*10**18);
        _savelist(5,unicode"领取ipo" ,ipo_amount,msg.sender);
        return true;
    }


    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint256) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }
    
    function getInviter(address account) public view returns (address) {
        return inviter[account];
    }
    function balanceOf(address account) public view override returns (uint256) {
        return tokenFromReflection(_rOwned[account]);
    }
    
    function balancROf(address account) public view returns (uint256) {
        return _rOwned[account];
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        if(msg.sender == uniswapV2Pair){
             _transfer(msg.sender, recipient, amount);
        }else{
            _tokenOlnyTransfer(msg.sender, recipient, amount);
        }
       
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        if(recipient == uniswapV2Pair){
             _transfer(sender, recipient, amount);
        }else{
             _tokenOlnyTransfer(sender, recipient, amount);
        }
       
        _approve(
            sender,
            msg.sender,
            _allowances[sender][msg.sender].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function tokenFromReflection(uint256 rAmount)
        public
        view
        returns (uint256)
    {
        require(
            rAmount <= _rTotal,
            "Amount must be less than total reflections"
        );
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function claimTokens() public onlyOwner {
        payable(_owner).transfer(address(this).balance);
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");


        //indicates if fee should be deducted from transfer
        bool takeFee = true;

        //if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }
        
        if(_mintTotal>=_tTotal){
            takeFee = false;
        }
        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from, to, amount, takeFee);
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 tAmount,
        bool takeFee
    ) private {
        uint256 currentRate = _getRate();

        // 扣除发送人的
        uint256 rAmount = tAmount.mul(currentRate);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);

        uint256 rate;
        if (takeFee) {
            // 销毁
            _takeTransfer(
                sender,
                _destroyAddress,
                tAmount.div(100).mul(_destroyFee),
                currentRate
            );


            
            _takeTransfer(
                sender,
                fund1Address,
                tAmount.div(100).mul(_fund1Fee),
                currentRate
            );
            


            // 推广分红
            _takeInviterFee(sender, recipient, tAmount, currentRate);

            
            rate =  _destroyFee + _inviterFee + _fund1Fee ;
        }

        // 接收
        uint256 recipientRate = 100 - rate;
        _rOwned[recipient] = _rOwned[recipient].add(
            rAmount.div(100).mul(recipientRate)
        );
        emit Transfer(sender, recipient, tAmount.div(100).mul(recipientRate));
    }
    
    //this method is responsible for taking all fee, if takeFee is true
    function _tokenOlnyTransfer(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        uint256 currentRate = _getRate();

        if(_rOwned[recipient] == 0 && inviter[recipient] == address(0)){
			inviter[recipient] = sender;
		}else{
		    
		}
        // 扣除发送人的
        uint256 rAmount = tAmount.mul(currentRate);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        
        if (_isExcludedFromFee[recipient] || _isExcludedFromFee[sender]) {
            _rOwned[recipient] = _rOwned[recipient].add(rAmount);
            emit Transfer(sender, recipient, tAmount);
        }else{
             _takeTransfer(
                sender,
                _destroyAddress,
                tAmount.div(100).mul(_destroyFee),
                currentRate
            );
            _rOwned[recipient] = _rOwned[recipient].add(rAmount.div(100).mul(98));
            emit Transfer(sender, recipient, tAmount.div(100).mul(98));
        }
    }
    
    function tokenOlnyTransferCheck1(
        address sender,
        address recipient
    ) public view returns(bool){
        return _isExcludedFromFee[recipient] || _isExcludedFromFee[sender];
    }
    
    function tokenOlnyTransferCheck2(
        address recipient
    ) public view returns(bool){
        
        return _rOwned[recipient] == 0 && inviter[recipient] == address(0);
    }

    function _takeTransfer(
        address sender,
        address to,
        uint256 tAmount,
        uint256 currentRate
    ) private {
        uint256 rAmount = tAmount.mul(currentRate);
        _rOwned[to] = _rOwned[to].add(rAmount);
        emit Transfer(sender, to, tAmount);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _takeInviterFee(
        address sender,
        address recipient,
        uint256 tAmount,
        uint256 currentRate
    ) private {
        address cur;
        if (sender == uniswapV2Pair) {
            cur = recipient;
        } else {
            cur = sender;
        }
        
        for (int256 i = 0; i < 6; i++) {
            uint256 rate ;
            if (i == 0) {
                rate = 32;
            } if(i == 1) {
                rate = 25;
            }if(i == 2) {
                rate = 16;
            }if(i == 3) {
                rate = 12;
            }if(i == 4) {
                rate = 10;
            }if(i == 5) {
                rate = 5;
            }

            cur = inviter[cur];
            if (cur == address(0)) {
                break;
            }
            uint256 curTAmount = tAmount.div(100).mul(rate).mul(8).div(100);
            uint256 curRAmount = curTAmount.mul(currentRate);
            _rOwned[cur] = _rOwned[cur].add(curRAmount);
            emit Transfer(sender, cur, curTAmount);
        }
    }

    function changeRouter(address router) public onlyOwner {
        uniswapV2Pair = router;
    }
    
    function setMintTotal(uint256 mintTotal) private {
        _mintTotal = mintTotal;
    }
}