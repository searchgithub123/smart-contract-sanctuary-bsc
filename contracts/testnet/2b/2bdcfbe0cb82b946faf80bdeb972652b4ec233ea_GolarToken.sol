/**
 *Submitted for verification at BscScan.com on 2022-09-09
*/

// SPDX-License-Identifier: NONE
// File: contracts/zeppelin/SafeMath.sol

pragma solidity 0.8.11;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    /**
    * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Adds two numbers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
    * @dev Multiplies two unsigned integers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}

// File: contracts/GolarImplementation.sol

pragma solidity 0.8.11;
//pragma experimental "v0.5.0";



/**
 * @title GolarImplementation
 * @dev this contract is a Pausable ERC20 token with Burn and Mint
 * controlled by a central SupplyController. By implementing GolarImplementation
 * this contract also includes external methods for setting
 * a new implementation contract for the Proxy.
 * NOTE: The storage defined here will actually be held in the Proxy
 * contract and all calls to this contract should be made through
 * the proxy, including admin actions done as owner or supplyController.
 * Any call to transfer against this contract should fail
 * with insufficient funds since no tokens will be issued there.
 */
contract GolarToken {

    /**
     * MATH
     */

    using SafeMath for uint256;

    /**
     * DATA
     */

    // INITIALIZATION DATA
    bool private initialized = false;

    // ERC20 BASIC DATA
    mapping(address => uint256) internal balances;
    uint256 internal totalSupply_;
    string public constant name = "Golar Token"; // solium-disable-line
    string public constant symbol = "Gola"; // solium-disable-line uppercase
    uint8 public constant decimals = 6; // solium-disable-line uppercase

    // ERC20 DATA
    mapping(address => mapping(address => uint256)) internal allowed;

    // OWNER DATA
    address public owner;
    address public proposedOwner;

    // PAUSABILITY DATA
    bool public paused = false;

    // ASSET PROTECTION DATA
    address public assetProtectionRole;
    mapping(address => bool) internal frozen;

    // SUPPLY CONTROL DATA
    address public supplyController;

    // EIP191 header for EIP712 prefix
    string constant internal EIP191_HEADER = "\x19\x01";
    // Hash of the EIP712 Domain Separator Schema
    bytes32 constant internal EIP712_DOMAIN_SEPARATOR_SCHEMA_HASH = keccak256(
        "EIP712Domain(string name,address verifyingContract)"
    );
   
    // Hash of the EIP712 Domain Separator data
    // solhint-disable-next-line var-name-mixedcase
    bytes32 public EIP712_DOMAIN_HASH;

    // FEE CONTROLLER DATA
    // fee decimals is only set for informational purposes.
    // 1 feeRate = .000001 oz of gold
    uint8 public constant feeDecimals = 6;

    // feeRate is measured in 100th of a basis point (parts per 1,000,000)
    // ex: a fee rate of 200 = 0.02% of an oz of gold
    uint256 public constant feeParts = 1000000;
    uint256 public feeRate;
    address public feeController;
    address public feeRecipient;

    /**
     * EVENTS
     */

    // ERC20 BASIC EVENTS
    event Transfer(address indexed from, address indexed to, uint256 value);

    // ERC20 EVENTS
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    // OWNABLE EVENTS
    
    event OwnershipTransferred(
        address indexed oldOwner,
        address indexed newOwner
    );

    // PAUSABLE EVENTS
    event Pause();
    event Unpause();

    // ASSET PROTECTION EVENTS
    event AddressFrozen(address indexed addr);
    event AddressUnfrozen(address indexed addr);
    event FrozenAddressWiped(address indexed addr);
    event AssetProtectionRoleSet (
        address indexed oldAssetProtectionRole,
        address indexed newAssetProtectionRole
    );

    // SUPPLY CONTROL EVENTS
    event SupplyIncreased(address indexed to, uint256 value);
    event SupplyDecreased(address indexed from, uint256 value);
    event SupplyControllerSet(
        address indexed oldSupplyController,
        address indexed newSupplyController
    );


    // FEE CONTROLLER EVENTS
    event FeeCollected(address indexed from, address indexed to, uint256 value);
    event FeeRateSet(
        uint256 indexed oldFeeRate,
        uint256 indexed newFeeRate
    );
    event FeeControllerSet(
        address indexed oldFeeController,
        address indexed newFeeController
    );
    event FeeRecipientSet(
        address indexed oldFeeRecipient,
        address indexed newFeeRecipient
    );

    /**
     * FUNCTIONALITY
     */

    // INITIALIZATION FUNCTIONALITY

    /**
     * @dev sets 0 initial tokens, the owner, the supplyController,
     * the fee controller and fee recipient.
     * this serves as the constructor for the proxy but compiles to the
     * memory model of the Implementation contract.
     */
    function initialize() public {
        require(!initialized, "already initialized");
        owner = msg.sender;
        assetProtectionRole = address(0);
        totalSupply_ = 0;
        supplyController = msg.sender;
        feeRate = 0;
        feeController = msg.sender;
        feeRecipient = msg.sender;
        initializeDomainSeparator();
        initialized = true;
    }

    /**
     * The constructor is used here to ensure that the implementation
     * contract is initialized. An uncontrolled implementation
     * contract might lead to misleading state
     * for users who accidentally interact with it.
     */
    constructor()  {
        initialize();
        pause();
    }

    /**
     * @dev To be called when upgrading the contract using upgradeAndCall to add delegated transfers
     */
    function initializeDomainSeparator() public {
        // hash the name context with the contract address
        EIP712_DOMAIN_HASH = keccak256(abi.encodePacked(// solium-disable-line
                EIP712_DOMAIN_SEPARATOR_SCHEMA_HASH,
                keccak256(bytes(name)),
                bytes32(keccak256(abi.encodePacked(address(this))))     
            ));
    }

    // ERC20 BASIC FUNCTIONALITY

    /**
    * @dev Total number of tokens in existence
    */
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    /**
    * @dev Transfer token to a specified address from msg.sender
    * Transfer additionally sends the fee to the fee controller
    * Note: the use of Safemath ensures that _value is nonnegative.
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
        require(_to != address(0), "cannot transfer to address zero");
        require(!frozen[_to] && !frozen[msg.sender], "address frozen");
        require(_value <= balances[msg.sender], "insufficient funds");

        _transfer(msg.sender, _to, _value);
        return true;
    }

    /**
    * @dev Gets the balance of the specified address.
    * @param _addr The address to query the the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address _addr) public view returns (uint256) {
        return balances[_addr];
    }

    // ERC20 FUNCTIONALITY

    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
    public
    whenNotPaused
    returns (bool)
    {
        require(_to != address(0), "cannot transfer to address zero");
        require(!frozen[_to] && !frozen[_from] && !frozen[msg.sender], "address frozen");
        require(_value <= balances[_from], "insufficient funds");
        require(_value <= allowed[_from][msg.sender], "insufficient allowance");

        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        _transfer(_from, _to, _value);

        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards
     * 
     * @param _spender The address which will spend the funds.
     * @param _value The amount of tokens to be spent.
     */
    function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
        require(!frozen[_spender] && !frozen[msg.sender], "address frozen");
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param _owner address The address which owns the funds.
     * @param _spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(
        address _owner,
        address _spender
    )
    public
    view
    returns (uint256)
    {
        return allowed[_owner][_spender];
    }

    function _transfer(address _from, address _to, uint256 _value) internal returns (uint256) {
        uint256 _fee = getFeeFor(_value);
        uint256 _principle = _value.sub(_fee);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_principle);
        emit Transfer(_from, _to, _principle);
        emit Transfer(_from, feeRecipient, _fee);
        if (_fee > 0) {
            balances[feeRecipient] = balances[feeRecipient].add(_fee);
            emit FeeCollected(_from, feeRecipient, _fee);
        }

        return _principle;
    }

    // OWNER FUNCTIONALITY

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "onlyOwner");
        _;
    }

   

    function changeOwner(address newowner) public onlyOwner returns(bool){
       // require(msg.sender == owner,"Only owner can set new owner");
        address _oldOwner = owner;
         owner = newowner;
        emit OwnershipTransferred(_oldOwner,owner);
        return true;
    }

    /**
     * @dev Reclaim all Golar at the contract address.
     * This sends the Golar tokens that this contract add holding to the owner.
     * Note: this is not affected by freeze constraints.
     */
    function reclaimGolar() external onlyOwner {
        uint256 _balance = balances[address(this)];
        balances[address(this)] = 0;
        balances[owner] = balances[owner].add(_balance);
        emit Transfer(address(this), owner, _balance);
    }

    // PAUSABILITY FUNCTIONALITY

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!paused, "whenNotPaused");
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() public onlyOwner {
        require(!paused, "already paused");
        paused = true;
        emit Pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() public onlyOwner {
        require(paused, "already unpaused");
        paused = false;
        emit Unpause();
    }

    // ASSET PROTECTION FUNCTIONALITY

    /**
     * @dev Sets a new asset protection role address.
     * @param _newAssetProtectionRole The new address allowed to freeze/unfreeze addresses and seize their tokens.
     */
    function setAssetProtectionRole(address _newAssetProtectionRole) public {
        require(msg.sender == assetProtectionRole || msg.sender == owner, "only assetProtectionRole or Owner");
        emit AssetProtectionRoleSet(assetProtectionRole, _newAssetProtectionRole);
        assetProtectionRole = _newAssetProtectionRole;
    }

    modifier onlyAssetProtectionRole() {
        require(msg.sender == assetProtectionRole, "onlyAssetProtectionRole");
        _;
    }

    /**
     * @dev Freezes an address balance from being transferred.
     * @param _addr The new address to freeze.
     */
    function freeze(address _addr) public onlyAssetProtectionRole {
        require(!frozen[_addr], "address already frozen");
        frozen[_addr] = true;
        emit AddressFrozen(_addr);
    }

    /**
     * @dev Unfreezes an address balance allowing transfer.
     * @param _addr The new address to unfreeze.
     */
    function unfreeze(address _addr) public onlyAssetProtectionRole {
        require(frozen[_addr], "address already unfrozen");
        frozen[_addr] = false;
        emit AddressUnfrozen(_addr);
    }

    /**
     * @dev Wipes the balance of a frozen address, burning the tokens
     * and setting the approval to zero.
     * @param _addr The new frozen address to wipe.
     */
    function wipeFrozenAddress(address _addr) public onlyAssetProtectionRole {
        require(frozen[_addr], "address is not frozen");
        uint256 _balance = balances[_addr];
        balances[_addr] = 0;
        totalSupply_ = totalSupply_.sub(_balance);
        emit FrozenAddressWiped(_addr);
        emit SupplyDecreased(_addr, _balance);
        emit Transfer(_addr, address(0), _balance);
    }

    /**
    * @dev Gets whether the address is currently frozen.
    * @param _addr The address to check if frozen.
    * @return A bool representing whether the given address is frozen.
    */
    function isFrozen(address _addr) public view returns (bool) {
        return frozen[_addr];
    }

    // SUPPLY CONTROL FUNCTIONALITY

    /**
     * @dev Sets a new supply controller address.
     * @param _newSupplyController The address allowed to burn/mint tokens to control supply.
     */
    function setSupplyController(address _newSupplyController) public {
        require(msg.sender == supplyController || msg.sender == owner, "only SupplyController or Owner");
        require(_newSupplyController != address(0), "cannot set supply controller to address zero");
        emit SupplyControllerSet(supplyController, _newSupplyController);
        supplyController = _newSupplyController;
    }

    modifier onlySupplyController() {
        require(msg.sender == supplyController, "onlySupplyController");
        _;
    }

    /**
     * @dev Increases the total supply by minting the specified number of tokens to the supply controller account.
     * @param _value The number of tokens to add.
     * @return  success A boolean that indicates if the operation was successful.
     */
    function increaseSupply(uint256 _value) public onlySupplyController returns (bool success) {
        totalSupply_ = totalSupply_.add(_value);
        balances[supplyController] = balances[supplyController].add(_value);
        emit SupplyIncreased(supplyController, _value);
        emit Transfer(address(0), supplyController, _value);
        return true;
    }

    /**
     * @dev Decreases the total supply by burning the specified number of tokens from the supply controller account.
     * @param _value The number of tokens to remove.
     * @return  success A boolean that indicates if the operation was successful.
     */
    function decreaseSupply(uint256 _value) public onlySupplyController returns (bool success) {
        require(_value <= balances[supplyController], "not enough supply");
        balances[supplyController] = balances[supplyController].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        emit SupplyDecreased(supplyController, _value);
        emit Transfer(supplyController, address(0), _value);
        return true;
    }

    // FEE CONTROLLER FUNCTIONALITY

    /**
     * @dev Sets a new fee controller address.
     * @param _newFeeController The address allowed to set the fee rate and the fee recipient.
     */
    function setFeeController(address _newFeeController) public {
        require(msg.sender == feeController || msg.sender == owner, "only FeeController or Owner");
        require(_newFeeController != address(0), "cannot set fee controller to address zero");
        address _oldFeeController = feeController;
        feeController = _newFeeController;
        emit FeeControllerSet(_oldFeeController, feeController);
    }

    modifier onlyFeeController() {
        require(msg.sender == feeController, "only FeeController");
        _;
    }

    /**
     * @dev Sets a new fee recipient address.
     * @param _newFeeRecipient The address allowed to collect transfer fees for transfers.
     */
    function setFeeRecipient(address _newFeeRecipient) public onlyFeeController {
        require(_newFeeRecipient != address(0), "cannot set fee recipient to address zero");
        address _oldFeeRecipient = feeRecipient;
        feeRecipient = _newFeeRecipient;
        emit FeeRecipientSet(_oldFeeRecipient, feeRecipient);
    }

    /**
     * @dev Sets a new fee rate.
     * @param _newFeeRate The new fee rate to collect as transfer fees for transfers.
     */
    function setFeeRate(uint256 _newFeeRate) public onlyFeeController {
        require(_newFeeRate <= feeParts, "cannot set fee rate above 100%");
        uint256 _oldFeeRate = feeRate;
        feeRate = _newFeeRate;
        emit FeeRateSet(_oldFeeRate, feeRate);
    }

    /**
    * @dev Gets a fee for a given value
    * ex: given feeRate = 200 and feeParts = 1,000,000 then getFeeFor(10000) = 2
    * @param _value The amount to get the fee for.
    */
    function getFeeFor(uint256 _value) public view returns (uint256) {
        if (feeRate == 0) {
            return 0;
        }

        return _value.mul(feeRate).div(feeParts);
    }
}