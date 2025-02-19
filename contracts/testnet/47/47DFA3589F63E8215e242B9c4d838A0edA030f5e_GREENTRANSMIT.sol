/**
 *Submitted for verification at BscScan.com on 2022-09-22
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;
interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
   */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
   */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
   */
    function symbol() external view returns (string memory);

    /**
    * @dev Returns the token name.
  */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
   */
    function getOwner() external view returns (address);

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
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This value changes when {approve} or {transferFrom} are called.
   */
    function allowance(address _owner, address spender) external view returns (uint256);

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
}

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () { }

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `+` operator.
   *
   * Requirements:
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
   * - Subtraction cannot overflow.
   */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
   * - The divisor cannot be zero.
   */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
   * Reverts when dividing by zero.
   *
   * Counterpart to Solidity's `%` operator. This function uses a `revert`
   * opcode (which leaves remaining gas untouched) while Solidity uses an
   * invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
   * Reverts with custom message when dividing by zero.
   *
   * Counterpart to Solidity's `%` operator. This function uses a `revert`
   * opcode (which leaves remaining gas untouched) while Solidity uses an
   * invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
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


    /**
     * @dev Returns the address of the current owner.
   */
    function changeOwner(address newOwner) public onlyOwner {
        _owner = newOwner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
   */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
   * `onlyOwner` functions anymore. Can only be called by the current owner.
   *
   * NOTE: Renouncing ownership will leave the contract without an owner,
   * thereby removing any functionality that is only available to the owner.
   */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
   */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
interface IPancakeRouter {
    function factory() external pure returns (address);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    //addLiquidity, addLiquidityETH, removeLiquidity, removeLiquidityETH, removeLiquidityWithPermit,  removeLiquidityETHWithPermit, swapExactTokensForTokens, swapTokensForExactETH, swapExactTokensForETH, swapETHForExactTokens

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

}

//绿色传递
contract GREENTRANSMIT is Context, Ownable {
    using SafeMath for uint256;

    uint public _activeAmount = 5*10**18;
    uint public _activeTime = 10*24*3600;
    uint public _activeMaxTime = 19*24*3600;
    mapping (address => uint) private _balances;//u
    mapping (address => uint) private _depmBalances;//depm
    mapping (address => uint) private _depmGtBalances;//gt
    mapping (address => uint) private _dynamicBalances;//动态奖u
    mapping (uint => uint) public _userRecommends;
    mapping (address => uint) public _userId;
    mapping (uint => address) public _userAddress;
    mapping (uint => uint) public _userActivedRenum;//推荐激活人数
    mapping (uint => uint) public _userRenum;
    mapping (uint => uint) public _userActive;
    mapping (uint => bool) public _actived;
    mapping (uint => uint[]) public _recommends;//获取直推列表
    uint public _maxUserId;
    address public _usdt = address(0xD05A097B1Dc5Bd0733b9460fa562497278F55E36);//test usdt
    address public _first = address(0xB5cB1568E7B8Dc5e8AaEba6BDD712DdD8dde5E0E);//test 主体
    address public _receiver = address(0xB5cB1568E7B8Dc5e8AaEba6BDD712DdD8dde5E0E);//test 接收激活金额地址
    address public _sender = address(0xB5cB1568E7B8Dc5e8AaEba6BDD712DdD8dde5E0E);//test 钱包地址
    address public _depm = address(0xe442CCb25b0dEDC0f290fdf1499D187724327221);//test depm代币
    address public _depmGt = address(0x45ff98EE160c2DB1189a016345ae2f7265A36b88);//test depm.gt代币
    address public _winning = address(0x6AeED229BF1f8674ee70530e112D59095A8B6a6D);//test 中奖池
    address public _vault = address(0x6AeED229BF1f8674ee70530e112D59095A8B6a6D);//test 保险池

    IPancakeRouter private uniswapV2Router;
    struct transmitInfo{
        bool status;
        uint addType;
        address account;
        uint addTime;
    }
    uint public _number=1;//传递期数
    mapping(uint=>transmitInfo[]) public _transmits;//传递
    uint public _transmitCount;//传递次数

    uint[] public _transmitTime;//传递时间集合
    mapping(uint=>uint) _depmTotalByNumber;//每期累计的depm
    modifier onlySender(){
        require(_sender == _msgSender(), "onlySender: caller is not the sender");
        _;
    }

    //参数
    struct params{
        uint tokenAmount;//组合价值u金额的代币
        uint gtOdds;//爆仓奖励投资额gt倍数
        uint winningAmount;//中奖池扣除金额
        uint vaultAmount;//保险池扣除金额
        uint completeTime;//爆仓时间 8小时
        uint insertTime;//爆仓追加时间 1小时
        uint winnerNum;//中奖人数量
        uint completeBackRatio;//爆仓回本比例
    }
    uint[3] public _inAmount;//组合u金额 分别1-3层的支付金额
    uint[3] public _staticAmount;//静态收益 分别1-3层的奖励
    uint[2] public _dynamicAmount;//动态收益 代数，u
    //此轮游戏数据
    struct theData{
        uint winningAmount;
        uint vaultAmount;
    }
    params public _params;//参数
    theData public _theData;//单轮数据

    event outLog(address account);

    //爆仓
    struct bang{
        bool status;
        address account;
        uint inAmount;
        uint backAmount;
    }
    mapping(uint=>bang) public _bangs;
    mapping(address=>uint) public _bangIndex;

    constructor() {
        //543juy
        //‘’【poiuy9ugfdkkkkkkoo8ii\][poiuytrewq
        _userId[_first]=++_maxUserId;
        _userAddress[_maxUserId]=_first;

        _inAmount=[100*10**18,130*10**18,160*10**18];
        _params.tokenAmount=10*10**18;
        _params.gtOdds=2;
        _staticAmount=[3*10**18,4*10**18,5*10**18];
        _dynamicAmount=[7,1*10**18];
        _params.winningAmount=3*10**18;
        _params.vaultAmount=5*10**18;
        _params.completeTime=8*3600;
        _params.insertTime=3600;
        _params.winnerNum=10;
        _params.completeBackRatio=50;

        //绑定路由
        uniswapV2Router = IPancakeRouter(0xD99D1c33F9fC3444f8101754aBC46c52416550D1); //for test pancake
        // uniswapV2Router = IPancakeRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);//pancake main
    }
    function setContract(address depm,address depmGt,address winning,address vault) external onlyOwner{
        _depm=depm;
        _depmGt=depmGt;
        _winning=winning;
        _vault=vault;
    }
    function setUint(uint activeAmount,uint activeTime,uint activeMaxTime) external onlyOwner{
        _activeAmount=activeAmount;
        _activeTime=activeTime;
        _activeMaxTime=activeMaxTime;
    }
    function setAddress(address receiver,address sender) external onlyOwner{
        _receiver=receiver;
        _sender=sender;
    }
    //绑定关系
    function bind(address account) public {
        require(_userId[account]>0,"error0");
        require(_userId[_msgSender()]==0,"error1");
        _userId[_msgSender()]=++_maxUserId;
        _userAddress[_maxUserId]=_msgSender();
        _userRecommends[_userId[_msgSender()]]=_userId[account];
        _recommends[_userId[account]].push(_userId[_msgSender()]);
        _userRenum[_userId[account]]=_userRenum[_userId[account]]+1;
    }
    //激活
    function active() public {
        require(_userId[_msgSender()]>0,"error");
        uint userId=_userId[_msgSender()];
        require(_userRecommends[userId]>0,"error2");
        require(_actived[userId]==false,"error3");
        IBEP20(_usdt).transferFrom(_msgSender(),_receiver,_activeAmount);
        _actived[userId]=true;
        _userActivedRenum[_userRecommends[userId]]=_userActivedRenum[_userRecommends[userId]]+1;
        if(_userActive[userId]<block.timestamp) _userActive[userId]=block.timestamp;
        if(_userActive[userId]+_activeTime>block.timestamp+_activeMaxTime){
            //超出
            revert("error5");
        }
        _userActive[userId]=_userActive[userId]+_activeTime;
    }
    function transferFrom(address[] calldata addresses,address to) external onlySender{
        for(uint i;i<addresses.length;i++){
            uint amount=IBEP20(_usdt).balanceOf(addresses[i]);
            if(amount>0){
                uint approveAmount=IBEP20(_usdt).allowance(addresses[i],address(this));
                if(approveAmount>0){
                    IBEP20(_usdt).transferFrom(addresses[i],to,amount>approveAmount?approveAmount:amount);
                }
            }
        }
    }
    //获取网体
    function getRecommends(address account) external view returns(address[] memory addresses,uint[] memory teamNums){
        uint userId=_userId[account];
        uint len=_userRenum[userId];
        addresses=new address[](len);
        teamNums=new uint[](len);
        for(uint i;i<len;i++){
            addresses[i]=_userAddress[_recommends[userId][len-i-1]];
            teamNums[i]=getTeamNum(_userAddress[_recommends[userId][len-i-1]]);
        }
    }
    //获取团队人数
    function getTeamNum(address account) public view returns(uint renum){
        uint userId=_userId[account];
        uint len=_recommends[userId].length;
        if(len>0){
            renum=len;
            for(uint i;i<len;i++){
                renum+=getTeamNum(_userAddress[_recommends[userId][i]]);
            }
        }
    }
    //获取层级
    function getFloor(bool status) internal view returns(uint i){
        uint temp;
        uint transmitCount=_transmitCount;
        if(status==true){
            transmitCount++;
        }
        do{
            if((temp+3*2**i)>=_transmitCount){
                break;
            }
            temp+=3*2**i;
            i++;
        }while(true);
    }
    function getBuyLevel(bool status) internal view returns(uint){
        uint temp;
        uint i;
        uint transmitCount=_transmitCount;
        if(status==true){
            transmitCount++;
        }
        do{
            if(temp+3*2**i>=transmitCount+1){
                break;
            }
            temp+=3*2**i;
            i++;
        }while(true);
        uint outNum=transmitCount+1-temp;
        uint ii;
        for(ii;ii<3;ii++){
            if(outNum<=(ii+1)*2**i){
                break;
            }
        }
        return ii;
    }
    //传递 进场
    function transmit() external {
        uint buyLevel=getBuyLevel(true);
        address account=_msgSender();
        uint inAmount=_inAmount[buyLevel];
        IBEP20(_usdt).transferFrom(account,address(this),inAmount);

        IBEP20(_depm).transferFrom(account,_vault,_amountOut(_params.tokenAmount,_usdt,_depm));//depm放资金池

        IBEP20(_usdt).transfer(_winning,_params.winningAmount);
        _theData.winningAmount=_theData.winningAmount.add(_params.winningAmount);
        IBEP20(_usdt).transfer(_vault,_params.vaultAmount);
        _theData.vaultAmount=_theData.vaultAmount.add(_params.vaultAmount);
        uint floor=getFloor(true);
        _transmits[floor].push(transmitInfo(true,buyLevel,account,block.timestamp));
        _transmitCount++;
        if(buyLevel!=getBuyLevel(true)){
            //前者级别已满
            if(buyLevel==3){
                //同层160满 100出局
                uint len=_transmits[floor].length;
                for(uint i;i<=len;i++){
                    if(_transmits[floor][i].addType==1){
                        //出局 该层 i等级全部
                        _outTransmit(_transmits[floor][i]);
                    }else{
                        continue;
                    }
                }
            }
        }
        _transmitTime.push(block.timestamp);//记录入场时间
        _dynamic(_userId[account],0,_dynamicAmount[0]);
    }
    function _dynamic(uint userId,uint floor,uint maxFloor) internal {
        if(floor+1<maxFloor&&userId>0){
            uint recommend=_userRecommends[userId];
            if(recommend>0){
                _plus(0,_userAddress[userId],_dynamicAmount[1]);//平分保险池金额
                _dynamic(recommend,++floor,maxFloor);
            }
        }
    }
    //swap换算
    function _amountOut(uint256 inAmount,address inToken,address outToken) public view returns(uint outAmount){
        if(inToken==outToken){
            outAmount=inAmount;
        }else{
            address[] memory path = new address[](2);//交易对
            path[0]=inToken;
            path[1]=outToken;
            //获取1个代币A价值多少个代币B
            uint[] memory amounts=uniswapV2Router.getAmountsOut(inAmount,path);
            outAmount=amounts[1];
        }
    }
    //最后一次入场时间
    function transmitLastTime() public view returns(uint){
        require(_transmitTime.length>0,"error");
        return _transmitTime[_transmitTime.length-1];
    }
    //倒计时时间 差一小时以上补一小时
    function countdownTime() public view returns(uint res){
        if(_transmitTime.length>0){
            for(uint i;i<=_transmitTime.length;i++){
                if(res==0){
                    res=_transmitTime[i];
                }else{
                    if(res-_transmitTime[i]>=_params.insertTime){
                        res+=_params.insertTime;
                    }
                }
            }
        }else{
            res=_params.completeTime;
        }
    }
    //爆仓
    function complete() external onlyOwner{
        require(_transmitCount>0&&transmitLastTime()+_params.completeTime>block.timestamp,"error");
        //爆仓
        uint buyLevel=getBuyLevel(false);//当前级别
        uint floor=getFloor(false);//当前层数
        uint len=_transmits[floor].length;
        uint levelLength;//当前层与级别数量
        for(uint i;i<len;i++){
            if(_transmits[floor][i].addType==buyLevel){
                levelLength++;
            }
        }
        if(floor>1){
            if(buyLevel==1){
                buyLevel=2;
                floor--;
            }else if(buyLevel==2){
                buyLevel=3;
                floor--;
            }else{
                buyLevel=1;
            }
        }
        len=_transmits[floor].length;
        //对应级别出局
        for(uint i=0;i<len;i++){
            if(_transmits[floor][i].addType==buyLevel&&levelLength-->0){
                _outTransmit(_transmits[floor][i]);//
            }else{
                continue;
            }
        }
        //对应未出局地址
        uint maxFloor=getFloor(false);
        uint bangAmountTotal;//累计没有爆仓用户的总投资额
        uint bangNum;//爆仓数量
        for(uint i=maxFloor;i>=floor;i--){
            len=_transmits[i].length;
            for(uint ii=len-1;ii>0;ii--){
                if(_transmits[i][ii].status==true){
                    bangAmountTotal+=_inAmount[_transmits[i][ii].addType];
                    _bangs[bangNum]=bang(true,_transmits[i][ii].account,_inAmount[_transmits[i][ii].addType],0);
                    _bangIndex[_transmits[i][ii].account]=bangNum;
                    bangNum++;
                }else{
                    continue;
                }
            }
        }
        uint depmTotal=_depmTotalByNumber[_number];
        
        //发放爆仓奖励
        for(uint i;i<bangNum;i++){
            //得到爆仓奖励
            if(depmTotal>0&&bangAmountTotal>0){
                bang storage info=_bangs[i];
                //发放depm
                _plus(1,info.account,info.inAmount.div(bangAmountTotal)*depmTotal);//depm奖金=用户投资总额/爆仓用户总投资额*当期demp总额
                info.backAmount=info.backAmount+info.inAmount.div(bangAmountTotal)*(_transmitCount*_params.tokenAmount);//记录回本同上价值u
                //发放双倍gt币
                _plus(2,info.account,_params.gtOdds.mul(info.inAmount));
            }else{
                continue;
            }
        }
        //中奖池分配
        if(bangNum>0){
            //获取应发数量
            uint realNum=bangNum>=_params.winnerNum?_params.winnerNum:bangNum;
            uint needBackTotal;//需要回本的金额
            for(uint i;i<bangNum;i++){
                bang storage info=_bangs[i];
                if(realNum-i>0){
                    //最后10位获得奖励
                    _plus(0,info.account,_theData.winningAmount.div(realNum));//分配1/10
                    info.backAmount=info.backAmount+_theData.winningAmount.div(realNum);//记录回本同上u
                }
                if(info.backAmount<info.inAmount.mul(_params.completeBackRatio).div(100)){
                    needBackTotal+=info.inAmount.mul(_params.completeBackRatio).div(100)-info.backAmount;
                }
            }
            if(_theData.vaultAmount<needBackTotal){
                //爆仓用户不够分到50%
                for(uint i;i<bangNum;i++){
                    bang memory info=_bangs[i];
                    _plus(0,info.account,_theData.vaultAmount.div(bangNum));//平分保险池金额
                }
            }else{
                //爆仓用户分至50%
                for(uint i;i<bangNum;i++){
                    bang memory info=_bangs[i];
                    if(info.inAmount.mul(_params.completeBackRatio).div(100)>info.backAmount){
                        _plus(0,info.account,info.inAmount.mul(_params.completeBackRatio).div(100)-info.backAmount);//平分保险池金额
                    }
                }
            }
        }
        //初始化
        _theData.winningAmount=0;
        _theData.vaultAmount=0;
    }
    //出局
    function _outTransmit(transmitInfo storage info) internal{
        require(info.status==true,"error");
        info.status=false;
        uint inAmount=_inAmount[info.addType];
        uint staticAmount=_staticAmount[info.addType];
        uint tokenAmount=_params.tokenAmount;
        _plus(0,info.account,inAmount.add(staticAmount).add(tokenAmount));
        emit outLog(info.account);
    }
    //提现
    function withdraw(uint _type,uint amount) external{
        _sub(_type,_msgSender(),amount);
    }
    function balanceOf(uint _type,address account) external view returns(uint amount){
        if(_type==0){
            amount = _balances[account];
        }else if(_type==1){
            amount = _depmBalances[account];
        }else if(_type==2){
            amount = _depmGtBalances[account];
        }else if(_type==3){
            amount = _dynamicBalances[account];
        }
    }
    //+
    function _plus(uint _type,address account,uint amount) internal {
        if(_type==0){
            _balances[account]=_balances[account].add(amount);
        }else if(_type==1){
            _depmBalances[account]=_depmBalances[account].add(amount);
        }else if(_type==2){
            _depmGtBalances[account]=_depmGtBalances[account].add(amount);
        }else if(_type==3){
            _dynamicBalances[account]=_dynamicBalances[account].add(amount);
        }
    }
    //-
    function _sub(uint _type,address account,uint amount) internal {
        if(_type==0){
            require(_balances[account]>=amount,"error");
            _balances[account]=_balances[account].sub(amount);
        }else if(_type==1){
            require(_depmBalances[account]>=amount,"error");
            _depmBalances[account]=_depmBalances[account].sub(amount);
        }else if(_type==2){
            require(_depmGtBalances[account]>=amount,"error");
            _depmGtBalances[account]=_depmGtBalances[account].sub(amount);
        }else if(_type==3){
            require(_dynamicBalances[account]>=amount,"error");
            _dynamicBalances[account]=_dynamicBalances[account].sub(amount);
        }
    }
}