/**
 *Submitted for verification at BscScan.com on 2022-07-11
*/

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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
        return a + b;
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
        return a - b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
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
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
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

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: UberTaxiDate.sol

//SPDX-License-Identifier: MIT 

pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/access/Ownable.sol";

// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// import "./UberTaxiNFT.sol";

// import "./TaxiToken2.sol";




contract UberTaxiDate is Ownable {

    using SafeMath for uint256;

    struct User {

        uint256[6] vehicleTypeNum;

        uint256 vehicleNum;

        address welMember;

        uint256 bindNum;

        uint256 UTAXINum;

        uint256 totalDeposit;

        uint256 UTAXIReward;

        bool isEffectiveUser;
    }

    struct Vehicle {

        string name;

        uint256 types;

        uint256 price;

        uint256 uPrice;

        uint256 rate;

        uint256 purchaseLimit;

        bool isSell;
    }

    struct MyVehicle {

        uint256 types;

        uint256 buyDays;

        uint256 vehicleState;

        uint256 expireTime;

        uint256 durability;

        uint256 tokenId;

        address hold;

        uint256 buyPrice;

        uint256 profit;

        uint256 totalProfit;

        uint256 sellPrice;
    }

    struct Sell{

        address onwerAddr;

        uint256 myHeroId;

        uint256 price;

        bool sold;
    }

    struct Commission {

        address addr;

        uint256 buyTime;

        uint256 vehicleTypes;

        uint256 reward;
    }

    struct UtaxiDetail {

        uint256 types;

        // string sourceAddress;

        string source;

        uint256 amount;

        uint256 tranferTime;
    }

    mapping(uint256 => uint256) public utaxiProduceTotal;

    uint256 public uExchangeTotal;

    mapping(uint256 => uint256) public vehicleTotals;

    uint256 public marketTransactionTotal;

    uint256 public marketDealTotal;

    // uint256 ids;


    address public deadWallet = 0x000000000000000000000000000000000000dEaD;

    uint256 public serviceCharge = 10;

    uint256 public transferCharge = 0;

    uint256 public sellFee = 10;

    uint256 public commissionFee = 0;

    uint256 public recommenderFee = 5;

    address public depositAddress;

    address public withDrawAddress;

    uint256 public totalSales;

    mapping(uint256 => Sell) public mallNFTs;

    mapping(address => User) public users;

    mapping(address => address[]) public bindingUsers;

    mapping(address => uint256[]) public bindingTimes;

    mapping(uint256 => Vehicle) public vehicles;

    mapping(uint256 => uint256) public idtoIndex;

    mapping(address => uint256[]) public myVehiclesIds;

    mapping(uint256 => MyVehicle) public allVehicles;

    mapping(address => bool) public contractUsers;

    mapping(address => uint256[]) public myCommissionsIds;

    mapping(uint256 => Commission) public commissions;

    mapping(uint256 => uint256[]) public vehiclesTypeSells;

    mapping(uint256 => uint) public idToIndexByTypeSells;

    mapping(uint256 => address) public effectiveUsers;

    uint256 public effectiveUserNum;

    uint256[] public vehicleSells;

    mapping(uint256 => uint256) idToIndexBySells;

    


    //增加需求参数
    uint256 public rentAmountLimit = 3;

    uint256 public drawTimeLimit = 3;

    uint256 public licensePrice = 1 * 10 ** 18;

    uint256 public insurancePrice = 1 * 10 ** 18;
    
    mapping(uint256 => bool) public isBuyLicense;

    mapping(uint256 => bool) public isBuyInsurance;

    bool public openLicense;

    bool public openInsurance;

    bool public openVehicleTransfer;




    mapping(address => UtaxiDetail[]) public userUtaxiDetails;

    uint256[6] public activeVehiclePrice = [3600,3600,3600,3600,3600,3600];

    uint256 public blindBoxPrice = 30 * 10 ** 18;

    uint256[9] public blindBoxRate = [10,20,30,40,50,60,70,80,90];

    uint256[7] public blindBoxAward = [5,10,20,50,200,500,1000];

    uint256 private randNum;


    mapping(address => bool) public isController;


    event BuyVehicle(address addr, uint256 types);

    event VehicleRent(address user, uint256 index);

    event VehicleGetReward(address user, uint256 index, uint256 reward);

    event buyNFTFromMaket(address from, address to, uint256 price);

    constructor() {

        // ids = 10000;

        withDrawAddress = 0x45CbCBf16E1251d2019bEdb940f70Cb6F12068b0;

        depositAddress = 0x45CbCBf16E1251d2019bEdb940f70Cb6F12068b0;

        contractUsers[0xEd703D611df2fef3D0c626B1f688edFeeA8CfcF7] = true;

        vehicles[1] = Vehicle("Volkswagen",   1, 1000*10**18, 900*10**18, 3.8*10, 1000, true);
        vehicles[2] = Vehicle("Tesla",        2, 2000*10**18, 1800*10**18, 4*10, 1000, true);
        vehicles[3] = Vehicle("Audi",         3, 4000*10**18, 3600*10**18, 4.2*10, 1000, true);
        vehicles[4] = Vehicle("BMW",          4, 6000*10**18, 5400*10**18, 4.4*10, 1000, false);
        vehicles[5] = Vehicle("MercedesBenz", 5, 8000*10**18, 7200*10**18, 4.6*10, 1000, false);
        vehicles[6] = Vehicle("RollsRoyce",   6, 10000*10**18, 9000*10**18, 4.8*10, 1000, false);
    }

    function addController(address controllerAddr) public onlyOwner {
        isController[controllerAddr] = true;
    }

    function removeController(address controllerAddr) public onlyOwner {
        isController[controllerAddr] = false;
    }

    modifier onlyController {
         require(isController[msg.sender],"Must be controller");
         _;
    }

    function updateVehicle(uint256 index, uint256 price, uint256 UPirce, uint256 rate) public onlyOwner {
        vehicles[index].price = price == 0 ? vehicles[index].price : price;
        vehicles[index].uPrice = UPirce == 0 ? vehicles[index].uPrice : UPirce;
        vehicles[index].rate = rate == 0 ? vehicles[index].rate : rate;
    }

    function openToPurchase(uint256 index, bool isSell) public onlyOwner {
        vehicles[index].isSell = isSell;
    }

    function setVehicleNums(uint256 index, uint256 purchaseLimit) public onlyOwner {
        vehicles[index].purchaseLimit = purchaseLimit == 0 ? vehicles[index].purchaseLimit : purchaseLimit;
    }

    function setServiceCharge(uint256 serviceChargeNum) public onlyOwner{
        serviceCharge = serviceChargeNum;
    }

    function setTransferCharge(uint256 transferChargeNum) public onlyOwner{
        transferCharge = transferChargeNum;
    }

    function setSellFee(uint256 sellFeeNum) public onlyOwner{
        sellFee = sellFeeNum;
    }

    function setCommissionFee(uint256 commissionFeeNum) public onlyOwner{
        commissionFee = commissionFeeNum;
    }

    function setRecommenderFee(uint256 recommenderFeeNum) public onlyOwner{
        recommenderFee = recommenderFeeNum;
    }

    function setDepositAddress(address NewDepositAddress) public onlyOwner{
        depositAddress = NewDepositAddress;
    }

    function setWithDrawAddress(address NewWithDrawAddress) public onlyOwner{
        withDrawAddress = NewWithDrawAddress;
    }

    function setRentAmountLimit(uint256 amount) public onlyOwner{
        rentAmountLimit = amount;
    }

    function setDrawTimeLimit(uint256 times) public onlyOwner{
        drawTimeLimit = times;
    }

    function setLicensePrice(uint256 price) public onlyOwner{
        licensePrice = price;
    }

    function setInsurancePrice(uint256 price) public onlyOwner{
        insurancePrice = price;
    }

    function setActiveVehiclePrice(uint256 index, uint256 price) public onlyOwner {
        activeVehiclePrice[index - 1] = price;
    }

    function setVehiclePurchaseLimit(uint256 index, uint256 purchaseLimit) public onlyOwner {
        vehicles[index].purchaseLimit = purchaseLimit;
    }

    function setBlindBoxPrice(uint256 price) public onlyOwner {
        blindBoxPrice = price;
    }

    function setBlindBoxRate(uint256 index, uint256 rate) public onlyOwner {
        blindBoxRate[index - 1] = rate;
    }

    function setBlindBoxAward(uint256 index, uint256 award) public onlyOwner {
        blindBoxAward[index - 1] = award;
    }



    function toOpenLicense() public onlyOwner{
        require(!openLicense, "Purchase of license has been opened");
        openLicense = true;
    }

    function toOpenInsurance() public onlyOwner{
        require(!openInsurance, "Purchase of insurance has been opened");
        openInsurance = true;
    }

    function setOpenVehicleTransfer(bool open) public onlyOwner{
        openVehicleTransfer = open;
    }



    function addUserUTAXINum(address addr, uint256 inputNum) public onlyController {
        users[addr].UTAXINum = users[addr].UTAXINum.add(inputNum);
    }

    function subUserUTAXINum(address addr, uint256 inputNum) public onlyController {
        require(users[addr].UTAXINum >= inputNum, "Your UTaxiNum is insufficient");
        users[addr].UTAXINum = users[addr].UTAXINum.sub(inputNum);
    }

    function setAllVehicles(uint256 ids, uint256 types, uint256 buyDays, uint256 vehicleState, uint256 expireTime, 
    uint256 durability, uint256 tokenId, address hold, uint256 buyPrice, uint256 profit, uint256 totalProfit, uint256 sellPrice) public onlyController {
        allVehicles[ids] = MyVehicle(types, buyDays, vehicleState, expireTime, durability, tokenId, hold, buyPrice, profit, totalProfit, sellPrice);
    }

    function setVehicleDurability(uint256 ids, uint256 durability) public onlyController {
        allVehicles[ids].durability = durability;
    }

    function setVehicleExpireTime(uint256 ids, uint256 expireTime) public onlyController {
        allVehicles[ids].expireTime = expireTime;
    }

    function setVehicleState(uint256 ids, uint256 vehicleState) public onlyController {
        allVehicles[ids].vehicleState = vehicleState;
    }
    
    function setVehicleTotals(uint256 index) public onlyController {
        vehicleTotals[index]++;
    }

    function setUtaxiDetails(address user, uint256 types, string memory source, uint256 amount, uint256 tranferTime) public onlyController {
        userUtaxiDetails[user].push(UtaxiDetail(types,source,amount,tranferTime));
    }

    function addUserVehicleNum(address user, uint256 index) public onlyController {
        users[user].vehicleTypeNum[index - 1] = users[msg.sender].vehicleTypeNum[index - 1].add(1);
        users[user].vehicleNum = users[user].vehicleNum.add(1);
    }

    function subUserVehicleNum(address user, uint256 index) public onlyController {
        users[user].vehicleTypeNum[index - 1] = users[msg.sender].vehicleTypeNum[index - 1].sub(1);
        users[user].vehicleNum = users[user].vehicleNum.sub(1);
    }

    function addUserTotalDeposit(address user, uint256 deposit) public onlyController {
        users[user].totalDeposit = users[user].totalDeposit.add(deposit);
    }

    function addUserUTAXIReward(address user, uint256 UTAXIReward) public onlyController {
        users[user].UTAXIReward = users[user].UTAXIReward.add(UTAXIReward);
    }

    // function subUserTotalDeposit(address user, uint256 deposit) public onlyOwner {
    //     users[user].totalDeposit = deposit;
    // }

    function setCommissions(uint256 cIds, address user, uint256 buyTime, uint256 vehicleTypes, uint256 reward) public onlyOwner {
        commissions[cIds] = Commission(user, buyTime, vehicleTypes, reward);
        myCommissionsIds[users[user].welMember].push(cIds);
    }

    function setUserVehicleIds(uint256 ids, address user) public onlyOwner {
        idtoIndex[ids] = myVehiclesIds[user].length;
        myVehiclesIds[user].push(ids);
        if (!contractUsers[msg.sender]) contractUsers[msg.sender] = true;
    }

    function setEffectiveUser(address user, bool isEffect) public onlyOwner {
        users[user].isEffectiveUser = isEffect;
    }

    function addEffectiveUserNum() public onlyOwner {
        effectiveUserNum++;
        effectiveUsers[effectiveUserNum] = msg.sender;
    }

    function addToBuyLicense(uint256 index) public onlyOwner {
        isBuyLicense[index] = true;
    }

    function addToBuyInsurance(uint256 index) public onlyOwner {
        isBuyInsurance[index] = true;
    }

    function setVehicleRentProfit(uint256 index) public onlyOwner {
        allVehicles[index].profit = allVehicles[index].buyPrice.mul(vehicles[allVehicles[index].types].rate).mul(allVehicles[index].durability).div(100000);
    }

    function setVehicleRentProfitTo0(uint256 index) public onlyOwner {
        allVehicles[index].profit = 0;
    }

    function addVehicleRentProfit(uint256 index, uint256 profit) public onlyOwner {
        allVehicles[index].totalProfit = allVehicles[index].totalProfit.add(profit);
    }

    function addUtaxiProduceTotal(uint256 types, uint256 profit) public onlyOwner {
        utaxiProduceTotal[types] += utaxiProduceTotal[types].add(profit);
    }

    function addUExchangeTotal(uint256 exchangeNum) public onlyOwner {
        uExchangeTotal = uExchangeTotal.add(exchangeNum);
    }

    function addMarketTransactionTotal(uint256 sellPrice) public onlyOwner {
        marketTransactionTotal++;
        marketDealTotal = marketDealTotal.add(sellPrice);
    }

    function setUserWelMember(address user, address welMember) public onlyOwner {
        users[user].welMember = welMember;
        
        users[welMember].bindNum += 1;

        bindingUsers[welMember].push(msg.sender);

        bindingTimes[welMember].push(block.timestamp);
    }

    function vehicleOnShelf(uint256 index, uint256 sellPrice) public onlyOwner {
        allVehicles[index].sellPrice = sellPrice;

        idToIndexByTypeSells[index] = vehiclesTypeSells[allVehicles[index].types].length;

        vehiclesTypeSells[allVehicles[index].types].push(index);

        idToIndexBySells[index] = vehicleSells.length;

        vehicleSells.push(index);
    }

    function vehicleOffShelf(uint256 index) public onlyOwner {
        allVehicles[index].sellPrice = 0;

        delete vehiclesTypeSells[allVehicles[index].types][idToIndexByTypeSells[index]];

        delete idToIndexByTypeSells[index];

        delete vehicleSells[idToIndexBySells[index]];

        delete idToIndexBySells[index];
    }

    function vehicleTransfer(address from, address to, uint256 index) public onlyOwner {

        delete myVehiclesIds[from][idtoIndex[index]];

        allVehicles[index].hold = to;

        idtoIndex[index] = myVehiclesIds[to].length;

        myVehiclesIds[to].push(index);
    }






    function querymyVehiclesIds(address addr) public view returns(uint256[] memory){
        return myVehiclesIds[addr];
    }

    function queryMyCommissionsIds(address addr) public view returns(uint256[] memory){
        return myCommissionsIds[addr];
    }

    function queryVehicleSells() public view returns(uint256[] memory){
        return vehicleSells;
    }

    function queryVehiclesTypeSells(uint256 index) public view returns(uint256[] memory){
        return vehiclesTypeSells[index];
    }

    function queryVehicleTypeNum(address addr) public view returns(uint256[6] memory){
        return users[addr].vehicleTypeNum;
    }

    function queryBindingUsersAndTime(address addr) public view returns(address[] memory, uint256[] memory){
        return (bindingUsers[addr], bindingTimes[addr]);
    }

    function querryEffectiveUserUTXITotals() public view returns(uint256 totalUtaxiOfEffectiveUser){

        for(uint256 i = 1; i <= effectiveUserNum; i++){
            totalUtaxiOfEffectiveUser += users[effectiveUsers[i]].UTAXINum;
        }
    }

    function queryUserDrawTimeIsToLimit(address addr) public view returns(bool){

        uint256 drawTime;

        for(uint256 i = 0; i < myVehiclesIds[addr].length; i++){
            uint256 index = myVehiclesIds[addr][i];

            if(index != 0 && allVehicles[index].vehicleState == 1 && allVehicles[index].durability > 0){

                uint256 interval = allVehicles[index].expireTime.div(24 hours) - block.timestamp.div(24 hours);
                if(interval > 0){
                    drawTime++;
                }
            }
        }

        if(drawTime < drawTimeLimit){
            return true;
        }else{
            return false;
        }
    }

    function queryUserRentVehicleAmount(address addr) public view returns(uint256 rentAmount){

        for(uint256 i = 0; i < myVehiclesIds[addr].length; i++){
            uint256 index = myVehiclesIds[addr][i];

            if(index != 0 && allVehicles[index].vehicleState == 1 && allVehicles[index].durability > 0){
                rentAmount++;
            }
        }
        return rentAmount;
    }

    function queryUserScrapVehicleLists(address addr) public view returns(MyVehicle[] memory lists,uint256[] memory price, uint256[] memory indexs){

        uint256[] memory lists0 = new uint256[](uint256(myVehiclesIds[addr].length));

        uint256 count;

        for(uint256 i = 0; i < myVehiclesIds[addr].length; i++){
            uint256 index = myVehiclesIds[addr][i];

            if(index != 0 && allVehicles[index].durability == 0){
                lists0[count] = index;
                count++;
            }
        }

        lists = new MyVehicle[](uint256(count));
        price = new uint256[](uint256(count));
        indexs = new uint256[](uint256(count));

        for(uint256 i = 0; i < count; i++){
            lists[i] = allVehicles[lists0[i]];
            price[i] = activeVehiclePrice[allVehicles[lists0[i]].types - 1];
            indexs[i] = lists0[i];
        }

        return (lists,price,indexs);
    }

    function checkUserRentLimit(address addr) public view returns(bool){

        uint256 rentAmount = queryUserRentVehicleAmount(addr);

        if(rentAmount < rentAmountLimit){
            return true;
        }else{
            return false;
        }
    }

    function checkIsNeedBuyLicenseOrInsurance(uint256 index, uint256 types) public view returns(bool){

        if(types == 1){

            if(!openLicense || isBuyLicense[index]) return false;

            if(openLicense  && !isBuyLicense[index]) return true;
        }

        if(types == 2){
            
            if(!openInsurance || isBuyInsurance[index]) return false;

            if(openInsurance  && !isBuyInsurance[index]) return true;
        }

        return false;
    }

    function checkBindingInput(address user, address addr) public view returns(bool){

        if(users[user].welMember != address(0)){
            return false;
        }

        if(addr == user){
            return false;
        }

        if(users[addr].welMember == user){
            return false;
        }

        address reAddress = users[addr].welMember;

        while(reAddress != address(0)) {

            if(users[reAddress].welMember == msg.sender){
                return false;
            }else{
                reAddress = users[reAddress].welMember;
            }
        }

        return true;
    }

    
    

}