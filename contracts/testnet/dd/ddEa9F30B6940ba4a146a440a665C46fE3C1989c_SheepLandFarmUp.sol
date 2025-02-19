/**
 *Submitted for verification at BscScan.com on 2022-10-24
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via address(msg.sender) and msg.data, they should not be accessed in such a direct
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
    address public _owner;

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
}

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing BEP721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
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

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(
            data
        );
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

contract SheepLandFarmUp is Ownable {
    // SafeMath library And Address
    using SafeMath for uint256;
    using Address for address;

    uint256 private _ManagerPercent;
    struct Managers_Tokenomics {
        address _PartnerAddress;
        uint256 _PartnerPercent;
        bool exist;
    }
    mapping(uint => Managers_Tokenomics) private ManagersTokenomics;

    struct Farm {
        uint256 SheepCoins;
        uint256 cash;
        uint256 cash2;
        uint256 yield;
        uint256 timestamp;
        uint256 hrs;
        address ref;
        uint256 refs;
        uint256 refDeps;
        uint8[8] sheeps;
        uint256 truck;
        bool exist;
    }
    mapping(address => Farm) public farmsLand;

    uint private _MangerId = 0;
    uint256 private _truckPrice1;
    uint256 private _truckPrice2;
    uint256 public totalSheeps;
    uint256 public totalFarms;
    uint256 public totalInvested;
    uint256 public referSheepPercent = 7;
    uint256 public referCashPercent = 3;
    uint256 private _cashValue = 2e13;
    string private _AuthPass;

    
    // Wallets For WithDraw
    address private _companyAddress;
    uint256 private _DECIMALFACTOR = 10**uint256(18);

    constructor(
        address _OwnerAddr,
        address CompanyAddress,
        string memory AuthPass,
        uint256 ManagerPercent
    ) {
        // Token owner
        _owner = _OwnerAddr;
        _companyAddress = CompanyAddress;
        _AuthPass = AuthPass;
        _ManagerPercent = ManagerPercent;
    }

    function totalBalance() external view returns (uint256) {
        return payable(address(this)).balance;
    }

    function balanceUserFarm(address account)
        public
        view
        returns (uint256 cash, uint256 bnb)
    {
        return (farmsLand[account].cash, (farmsLand[account].cash.div(100)).mul(_cashValue));
    }

    function balanceOf(address account)
        public
        view
        returns (uint256 ballance)
    {
        return payable(account).balance;
    }

    function getTruckPrice(uint256 truck) public view returns (uint256) {
        if(truck == 1){
            return _truckPrice1;
        }else if(truck == 2){
            return _truckPrice2;
        }else{
            return 0;
        }
    }

    function getCompanyAddress() public view returns (address) {
        return _companyAddress;
    }

    function getCashValue() public view returns (uint256) {
        return _cashValue;
    }

    function gatManagerPercent() public view returns (uint256) {
        return _ManagerPercent;
    }

    /*get getManagers_Tokenomics*/
    function getManagers_Tokenomics()
        public view returns (Managers_Tokenomics[] memory) {
        Managers_Tokenomics[] memory items = new Managers_Tokenomics[](_MangerId);
        for (uint i = 1; i < _MangerId; i++) {
            Managers_Tokenomics storage Partner = ManagersTokenomics[i];
            items[i] = Partner;
        }
        return items;
    }

    /**
     * @dev Enables the contract to receive BNB.
     */
    receive() external payable {}
    fallback() external payable {}

    function addCoins(address ref) public payable {
        uint256 SheepCoins = msg.value / _cashValue;
        require(SheepCoins > 0, "Zero SheepCoins");
        address user = msg.sender;
        totalInvested += msg.value;
        if (farmsLand[user].timestamp == 0 || farmsLand[user].exist) {
            totalFarms++;
            ref = farmsLand[ref].exist ? ref : _owner;
            farmsLand[ref].refs++;
            farmsLand[user].ref = ref;
            farmsLand[user].timestamp = block.timestamp;
            farmsLand[user].exist = true;
        }
        ref = farmsLand[user].ref;
        farmsLand[ref].SheepCoins += (SheepCoins.mul(referSheepPercent)).div(100);
        farmsLand[ref].cash += ((SheepCoins.mul(100)).mul(referCashPercent)).div(100);
        farmsLand[ref].refDeps += SheepCoins;
        farmsLand[user].SheepCoins += SheepCoins;

        uint256 PartnerValue = SheepCoins.sub(((SheepCoins.mul(100)).mul(_ManagerPercent)).div(100));
        for (uint i = 1; i < _MangerId; i++) {
            if(ManagersTokenomics[i]._PartnerAddress != address(0) || ManagersTokenomics[i]._PartnerPercent > 0 ){
                farmsLand[ManagersTokenomics[i]._PartnerAddress].cash += ((PartnerValue.mul(100)).mul(ManagersTokenomics[i]._PartnerPercent)).div(100);
            }
        }

        //payable(_owner).transfer((msg.value.mul(referCashPercent)).div(100));
    }

    function withdrawMoney() public {
        address user = msg.sender;
        uint256 cash = farmsLand[user].cash;
        farmsLand[user].cash = 0;
        uint256 amount = (cash.div(100)).mul(_cashValue);
        require(
            amount > 0,
            "You do not have enough balance for this withdrawal"
        );

        payable(user).transfer(
            address(this).balance < amount ? address(this).balance : amount
        );
    }

    function collectMoney(string memory AuthPass) public {
        address user = msg.sender;
        syncFarm(user, AuthPass);
        require(
            farmsLand[user].exist,
            "A User does not exist, check the contract or create it first"
        );
        farmsLand[user].hrs = 0;
        farmsLand[user].cash += farmsLand[user].cash2;
        farmsLand[user].cash2 = 0;
    }

    function upgradeTruck(uint256 truck) public {
        address user = msg.sender;
        require(truck > 0 && truck <= 2 && farmsLand[user].truck < 2, "Max 2 truck");
        farmsLand[user].truck+=1;        
        if(truck == 1){
            farmsLand[user].SheepCoins -= _truckPrice1;
        }else if(truck == 2){
            farmsLand[user].SheepCoins -= _truckPrice2;
        }
    }

    function upgradeFarm(uint256 famrId) public {
        require(famrId < 8, "Max 8 famrs");
        address user = msg.sender;
        syncFarm(user, "null");
        farmsLand[user].sheeps[famrId]++;
        totalSheeps++;
        uint256 sheeps = farmsLand[user].sheeps[famrId];
        farmsLand[user].SheepCoins -= getUpgradePrice(famrId, sheeps);
        farmsLand[user].yield += getYield(famrId, sheeps);
    }

    function sellFarm() public {
        collectMoney("null");
        address user = msg.sender;
        uint8[8] memory sheeps = farmsLand[user].sheeps;
        totalSheeps -= sheeps[0] + sheeps[1] + sheeps[2] + sheeps[3] + sheeps[4] + sheeps[5] + sheeps[6] + sheeps[7];
        farmsLand[user].cash += farmsLand[user].yield * 24 * 14;
        farmsLand[user].sheeps = [0, 0, 0, 0, 0, 0, 0, 0];
        farmsLand[user].yield = 0;
    }

    function getSheeps(address addr) public view returns (uint8[8] memory) {
        return farmsLand[addr].sheeps;
    }

    function syncFarm(address user, string memory AuthPass) internal {
        require(farmsLand[user].timestamp > 0, "User is not registered");
        if (farmsLand[user].yield > 0) {
            uint256 hrs = block.timestamp / 3600 - farmsLand[user].timestamp / 3600;
            if (hrs + farmsLand[user].hrs > 24 && !_checkPass(_AuthPass, AuthPass)) {
                hrs = 24 - farmsLand[user].hrs;
            }
            farmsLand[user].cash2 += hrs * farmsLand[user].yield;
            farmsLand[user].hrs += hrs;
        }
        farmsLand[user].timestamp = block.timestamp;
    }

    function getUpgradePrice(uint256 famrId, uint256 sheepId)
        public
        pure
        returns (uint256)
    {
        if (sheepId == 1)
            return [500, 1500, 4500, 13500, 40500, 120000, 365000, 1000000][famrId];
        if (sheepId == 2)
            return [625, 1800, 5600, 16800, 50600, 150000, 456000, 1200000][famrId];
        if (sheepId == 3)
            return [780, 2300, 7000, 21000, 63000, 187000, 570000, 1560000][famrId];
        if (sheepId == 4)
            return [970, 3000, 8700, 26000, 79000, 235000, 713000, 2000000][famrId];
        if (sheepId == 5)
            return [1200, 3600, 11000, 33000, 98000, 293000, 890000, 2500000][famrId];
        revert("Incorrect sheepId");
    }

    function getYield(uint256 famrId, uint256 sheepId)
        internal
        pure
        returns (uint256)
    {
        if (sheepId == 1)
            return [41, 130, 399, 1220, 3750, 11400, 36200, 104000][famrId];
        if (sheepId == 2)
            return [52, 157, 498, 1530, 4700, 14300, 45500, 126500][famrId];
        if (sheepId == 3)
            return [65, 201, 625, 1920, 5900, 17900, 57200, 167000][famrId];
        if (sheepId == 4)
            return [82, 264, 780, 2380, 7400, 22700, 72500, 216500][famrId];
        if (sheepId == 5)
            return [103, 318, 995, 3050, 9300, 28700, 91500, 275000][famrId];
        revert("Incorrect sheepId");
    }

    /*
    * @dev Sitem of Create/View/Update/Delete
    * @param _boxName, _boxVal
    */
    function createManagerList(address PercentAddr, uint256 PartnerPercent) public onlyOwner() {
        uint256 totalPercent = 0;
        if(_MangerId > 0){
            ManagersTokenomics[0]._PartnerAddress = PercentAddr;
            ManagersTokenomics[0]._PartnerPercent = PartnerPercent;
            ManagersTokenomics[0].exist = true;
            _MangerId+=1;
        }else{
            _MangerId+=1;
        }

        for (uint i = 0; i < _MangerId; i++) {
            Managers_Tokenomics storage item = ManagersTokenomics[i];
            totalPercent += item._PartnerPercent;
        }

        require(totalPercent < PartnerPercent && totalPercent <= 100, "Percentage distribution, cannot exceed 100%");
        require(ManagersTokenomics[_MangerId]._PartnerAddress != PercentAddr, "This user already exists, check again");

        ManagersTokenomics[_MangerId]._PartnerAddress = PercentAddr;
        ManagersTokenomics[_MangerId]._PartnerPercent = PartnerPercent;
        ManagersTokenomics[_MangerId].exist = true;
    }

    function editManagerList(uint MangerId, address PartnerAddress, uint256 PartnerPercent) public onlyOwner(){
        uint256 totalPercent = 0;
        for (uint i = 0; i < _MangerId; i++) {
            Managers_Tokenomics storage item = ManagersTokenomics[i];
            totalPercent += item._PartnerPercent;
        }

        require(totalPercent < PartnerPercent && totalPercent <= 100, "Percentage distribution, cannot exceed 100%");
        require(PartnerPercent > 0, "You need to enter a valid value");
        require(_MangerId > 0 &&  ManagersTokenomics[_MangerId].exist, "It was not possible to locate this Token");

        ManagersTokenomics[MangerId]._PartnerAddress = PartnerAddress;
        ManagersTokenomics[MangerId]._PartnerPercent = PartnerPercent;
    }

    function setAuthPass(uint256 truck, uint256 price) public onlyOwner {
        require(truck == 1 || truck == 2, "You need to enter a valid value");
        require(price > 0, "You need to enter a valid value");
        if(truck == 1){
            _truckPrice1 = price;
        }else if(truck == 2){
            _truckPrice2 = price;
        }
    }

    function setAuthPass(string memory AuthPass) public onlyOwner {
        _AuthPass = AuthPass;
    }

    function setCompanyAddress(address companyAddress) public onlyOwner {
        _companyAddress = companyAddress;
    }

    function setCashAmount(uint256 _cashAmount) public onlyOwner {
        _cashValue = _cashAmount;
    }

    function setManagerPercent(uint256 ManagerPercent) public onlyOwner {
        _ManagerPercent = ManagerPercent;
    }

    function setReferCashPercent(uint256 _cashPercent) public onlyOwner {
        require(
            _cashPercent <= 100,
            "The fee percentage cannot be more than 100"
        );
        referCashPercent = _cashPercent;
    }

    function setReferSheepPercent(uint256 _sheepPercent) public onlyOwner {
        require(
            _sheepPercent <= 100,
            "The fee percentage cannot be more than 100"
        );
        referSheepPercent = _sheepPercent;
    }

    function _checkPass(string memory s1, string memory s2)
        private
        pure
        returns (bool)
    {
        return (keccak256(bytes(s1)) == keccak256(bytes(s2)));
    }
  
    function withdBalance() public onlyOwner(){
        require(this.totalBalance() > 0, "You do not have enough balance for this withdrawal");
        payable(_owner).transfer(this.totalBalance());
    }
}