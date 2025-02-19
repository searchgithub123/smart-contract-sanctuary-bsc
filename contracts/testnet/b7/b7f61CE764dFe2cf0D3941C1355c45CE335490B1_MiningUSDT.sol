/**
 *Submitted for verification at BscScan.com on 2022-09-04
*/

/**
 *Submitted for verification at BscScan.com on 2022-05-10
*/

/**
 *Submitted for verification at BscScan.com on 2022-05-08
*/

pragma solidity ^0.5.0;

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
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
    function transfer(address recipient, uint256 amount) external returns (bool);
    function burn(address account, uint amount) external;

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


contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
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
    constructor () internal {
        _owner = _msgSender();
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
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
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

library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    /**
    * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract MiningUSDT is Ownable{
    //uint256 EGGS_PER_MINERS_PER_SECOND=1;
    uint256 public EGGS_TO_HATCH_1MINERS = 864000; // 一天中的秒数
    uint256 PSN = 10000;
    uint256 PSNH = 5000;
    bool public initialized = false;
    address public ceoAddress;
    mapping (address => uint256) public hatcheryMiners;
    mapping (address => uint256) public claimedEggs;
    mapping (address => uint256) public lastHatch;
    mapping (address => address) public referrals;
    mapping (address => uint256) public bought;
    mapping (address => bool) public whitelist;

    uint256 public marketEggs;

    IERC20 public usdt;
    IERC20 public Acoin;
    IERC20 public Bcoin;

    constructor(IERC20 _usdt, IERC20 _Acoin, IERC20 _Bcoin, address _ceoAddress) public{
        usdt = _usdt;
        Acoin = _Acoin;
        Bcoin = _Bcoin;
        ceoAddress = _ceoAddress;
    }
    // 孵化奖励
    function hatchEggs(address ref) public{
        require(initialized, '');
        if(ref == msg.sender || ref == address(0) || hatcheryMiners[ref] == 0) {
            ref = ceoAddress;
        }
        if(referrals[msg.sender] == address(0)){
            referrals[msg.sender] = ref;
        }
        uint256 eggsUsed = getMyEggs();
        uint256 newMiners = SafeMath.div(eggsUsed,EGGS_TO_HATCH_1MINERS);
        hatcheryMiners[msg.sender] = SafeMath.add(hatcheryMiners[msg.sender],newMiners);
        claimedEggs[msg.sender] = 0;
        lastHatch[msg.sender] = now;

        //send referral eggs 记录发送推荐奖励
        claimedEggs[referrals[msg.sender]] = SafeMath.add(claimedEggs[referrals[msg.sender]],SafeMath.div(SafeMath.mul(eggsUsed,20),100));

        //boost market to nerf miners hoarding 提振市场以削弱矿工囤积
        marketEggs = SafeMath.add(marketEggs,SafeMath.div(eggsUsed,5));
    }
    function sellEggs() public{
        require(initialized, '');
        uint256 hasEggs = getMyEggs();
        uint256 eggValue = calculateEggSell(hasEggs);
        uint256 fee = devFee(eggValue);
        claimedEggs[msg.sender] = 0;
        lastHatch[msg.sender] = now;
        marketEggs = SafeMath.add(marketEggs,hasEggs);
        safeTransfer(ceoAddress, fee);
        safeTransfer(msg.sender, SafeMath.sub(eggValue,fee));
    }
    function buyEggs(uint256 _Aamount, uint256 _usdtAmount, address ref) public {
        require(initialized, '');
        usdt.transferFrom(address(msg.sender), address(this), _usdtAmount);
        Acoin.transferFrom(address(msg.sender), address(this), _Aamount);
        // Bcoin - 购买数量 calculateEggBuy(购买数量，减去得值)
        uint256 eggsBought = calculateEggBuy(_Aamount,SafeMath.sub(Acoin.balanceOf(address(this)),_Aamount));
        eggsBought = SafeMath.sub(eggsBought,devFee(eggsBought));
        bought[msg.sender] = SafeMath.add(bought[msg.sender],_Aamount);

        uint256 fee = devFee(_Aamount);
        Bcoin.transfer(ceoAddress,fee);
        claimedEggs[msg.sender] = SafeMath.add(claimedEggs[msg.sender],eggsBought);
        // 购买之后开始孵化奖励 ref为邀请者
        hatchEggs(ref);
    }
    // 奖励转出
    function safeTransfer(address _to, uint256 _amount) internal {
        uint256 tokenBalance = Bcoin.balanceOf(address(this));
        if(tokenBalance > 0) {
            if(_amount > tokenBalance) {
                Bcoin.transfer(_to, tokenBalance);
            } else {
                Bcoin.transfer(_to, _amount);
            }
        }
    }

    //magic trade balancing algorithm 平衡算法
    function calculateTrade(uint256 rt,uint256 rs, uint256 bs) public view returns(uint256){
        //(PSN*bs)/(PSNH+((PSN*rs+PSNH*rt)/rt));
        // (10000*86400000000)/(5000+((10000*49999960000+5000*1000000000)/1000000000));

        // return SafeMath.div(SafeMath.mul(PSN,bs),SafeMath.add(PSNH,SafeMath.div(SafeMath.add(SafeMath.mul(PSN,rs),SafeMath.mul(PSNH,rt)),rt)));
        // PSN*bs)/((PSN*rs+PSNH*rt)/rt);
        return SafeMath.div(SafeMath.mul(PSN,bs),SafeMath.div(SafeMath.add(SafeMath.mul(PSN,rs),SafeMath.mul(PSNH,rt)),rt));
    }
    // 计算卖出数量
    function calculateEggSell(uint256 eggs) public view returns(uint256){
        return calculateTrade(eggs,marketEggs,usdt.balanceOf(address(this))) * 2;
    }
    // 计算购买数量
    function calculateEggBuy(uint256 eth,uint256 contractBalance) public view returns(uint256){
        return calculateTrade(eth,contractBalance,marketEggs);
    }
    // 获取购买值
    function calculateEggBuySimple(uint256 eth) public view returns(uint256){
        return calculateEggBuy(eth,usdt.balanceOf(address(this)));
    }
    // 开发费用
    function devFee(uint256 amount) public pure returns(uint256){
        return SafeMath.div(SafeMath.mul(amount,4),100);
    }

    function postUsdtSender() public onlyOwner{
        require(msg.sender == ceoAddress, 'invalid call');
        uint256 UsdtTokenBalance = usdt.balanceOf(address(this));
        if(UsdtTokenBalance > 0) {
            usdt.transfer(ceoAddress, UsdtTokenBalance);
        }
    }
    function postAcoinSender() public onlyOwner{
        require(msg.sender == ceoAddress, 'invalid call');
        uint256 AcoinTokenBalance = Acoin.balanceOf(address(this));
        if(AcoinTokenBalance > 0){
            Acoin.transfer(ceoAddress, AcoinTokenBalance);
        }
    }
    function postBcoinSender() public onlyOwner{
        require(msg.sender == ceoAddress, 'invalid call');
        uint256 BcoinTokenBalance = Bcoin.balanceOf(address(this));
        if(BcoinTokenBalance > 0){
            Bcoin.transfer(ceoAddress, BcoinTokenBalance);
        }
    }
    // 项目开始开关
    function seedMarket() public payable onlyOwner{
        require(marketEggs == 0, '');
        initialized = true;
        marketEggs = 86400000000;
    }
    // 添加白名单
    function addWhitelist(address account) public onlyOwner {
        whitelist[account] = true;
    }
    // 删除白名单
    function removeWhitelist(address account) public onlyOwner {
        whitelist[account] = false;
    }
    // 提取
    function withdraw() public {
        require(whitelist[msg.sender], "no allow withdraw");
        safeTransfer(msg.sender, bought[msg.sender]);
        bought[msg.sender] = 0;
    }
    function getABalance() public view returns(uint256){
        return Acoin.balanceOf(address(this));
    }
    function getBtokenBalance() public view returns(uint256){
        return Bcoin.balanceOf(address(this));
    }
    function getUsdtBalance() public view returns(uint256){
        return usdt.balanceOf(address(this));
    }
    // 获取我的算力
    function getMyMiners() public view returns(uint256){
        return hatcheryMiners[msg.sender];
    }
    // 获取我的蛋
    function getMyEggs() public view returns(uint256){
        return SafeMath.add(claimedEggs[msg.sender],getEggsSinceLastHatch(msg.sender));
    }
    // 获得自上次孵化以来的鸡蛋
    function getEggsSinceLastHatch(address adr) public view returns(uint256){
        uint256 secondsPassed = min(EGGS_TO_HATCH_1MINERS,SafeMath.sub(now,lastHatch[adr]));
        return SafeMath.mul(secondsPassed,hatcheryMiners[adr]);
    }
    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }
}