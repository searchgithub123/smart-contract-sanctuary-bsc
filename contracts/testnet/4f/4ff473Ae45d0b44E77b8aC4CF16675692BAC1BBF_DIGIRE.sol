// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "./lib/BEP20Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./DigireAdmin.sol";

contract DIGIRE is BEP20Upgradeable {

    DigireAdmin public admin;

    // Digire Swap
    IERC20 public BUSD; // = IERC20(0xa51BcDc792285598Ba7443c71D557e0B7Df6f991);
    IERC20 public JAXRE; // = IERC20(0xEc7D5848F88246cA6984b8019d08B8524793b062);

    uint public max_jaxre_digire_ratio; // 1e8

    enum requeststatus { Init, Requested, Processed }
    
    struct Request {
        uint amountIn;
        uint amountJaxre;
        uint amountOut;
        uint request_timestamp;
        uint process_timestamp;
        address account;
        requeststatus status;
    }

    uint public requestCount;
    
    mapping(uint => Request) public swap_requests;

    event Create_Digire_Busd_Swap_Request(uint requestId, Request request);
    event Set_Max_Jaxre_Digire_Ratio(uint ratio);
    event Complete_Request(uint requestId);

    modifier onlyGatekeeper() {
        require(msg.sender == admin.gate_keeper(), "Only Gatekeeper");
        _;
    }

    modifier onlyExchanger() {
        require(msg.sender == admin.exchanger(), "Only Exchanger");
        _;
    }

    function init() public initializer
    {
        _setup("Digital Rupee", "DIGIRE", 18);
        max_jaxre_digire_ratio = 1e8;
        BUSD = IERC20(0xa51BcDc792285598Ba7443c71D557e0B7Df6f991);
        JAXRE = IERC20(0xEc7D5848F88246cA6984b8019d08B8524793b062);
    }
    
    /**
     * @dev minter or admin.gate_keeper() mints gamerupee to merchant
     *      minter is assigned to one merchant and has minting_limits
     */
    function _mint(address account, uint256 amount) internal override {
        require(msg.sender == owner() || (msg.sender == admin.gate_keeper() && account == admin.gate_keeper()), "Only admin.gate_keeper()");
        super._mint(account, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) internal override {
        require(sender == admin.gate_keeper() && admin.isWhitelisted(recipient), "Invalid transfer");
        super._transfer(sender, recipient, amount);
    }
   
    function withdrawByAdmin(address token, uint amount) external onlyOwner {
        IERC20(token).transfer(msg.sender, amount);
    }

    function swap_jaxre_digire(uint amountIn, address to) external onlyGatekeeper returns (uint amountOut) {
        JAXRE.transferFrom(msg.sender, address(this), amountIn);
        amountOut = amountIn * get_jaxre_digire_ratio() / 1e8;
        super._mint(to, amountOut);
    }

    function swap_digire_jaxre(uint amountIn, address to) internal returns (uint amountOut){
        super._burn(msg.sender, amountIn);
        amountOut = amountIn * 1e8 / get_jaxre_digire_ratio();
        require(amountOut <= JAXRE.balanceOf(address(this)));
        JAXRE.transfer(to, amountOut);
    }

    function create_digire_busd_swap_request(uint amountIn) external returns (uint requestId){
        uint jaxreAmount = swap_digire_jaxre(amountIn, admin.exchanger());
        Request storage request = swap_requests[requestCount];
        request.amountIn = amountIn;
        request.amountJaxre = jaxreAmount;
        request.account = msg.sender;
        request.request_timestamp = block.timestamp;
        request.status = requeststatus.Requested;
        requestId = requestCount ++;
        emit Create_Digire_Busd_Swap_Request(requestId, request);
    }

    function process_request(uint requestId, uint amountOut) external onlyExchanger {
        Request storage request = swap_requests[requestId];
        require(request.status == requeststatus.Requested, "Invalid status");
        BUSD.transferFrom(msg.sender, request.account, amountOut);
        request.amountOut = amountOut;
        request.process_timestamp = block.timestamp;
        request.status = requeststatus.Processed;        
        emit Complete_Request(requestId);
    }


    function set_max_jaxre_digire_ratio(uint _ratio) public onlyOwner {
        max_jaxre_digire_ratio = _ratio;
        emit Set_Max_Jaxre_Digire_Ratio(_ratio);
    }

    function get_jaxre_digire_ratio() public view returns (uint jaxre_digire_ratio) {
        if(JAXRE.balanceOf(address(this)) == 0) 
            return max_jaxre_digire_ratio;
        jaxre_digire_ratio = 1e8 * totalSupply / JAXRE.balanceOf(address(this));
        if(jaxre_digire_ratio > max_jaxre_digire_ratio)
            jaxre_digire_ratio = max_jaxre_digire_ratio;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract BEP20Upgradeable is OwnableUpgradeable {
    mapping (address => uint256) _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 public totalSupply;

    string public name;
    string public symbol;
    uint8 public decimals;


    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

   function _setup(string memory name_, string memory symbol_, uint8 decimals_) internal onlyInitializing {
        name = name_;
        symbol = symbol_;
        decimals = decimals_;
        __Ownable_init();
    }

   function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

   function transfer(address recipient, uint256 amount) public virtual returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "BEP20: transfer amount exceeds allowance");
        _approve(sender, msg.sender, currentAllowance - amount);

        return true;
    }

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual returns (uint256) {
        return _allowances[owner][spender];
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "BEP20: decreased allowance below zero");
        _approve(msg.sender, spender, currentAllowance - subtractedValue);

        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "BEP20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "BEP20: mint to the zero address");

        totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function burn(uint256 amount) public virtual {
        _burn(msg.sender, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "BEP20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract DigireAdmin is OwnableUpgradeable{

    address public gate_keeper;
    address public exchanger;

    // Digire Swap
    IERC20 public DIGIRE;
    IERC20 public BUSD; // = IERC20(0xa51BcDc792285598Ba7443c71D557e0B7Df6f991);
    IERC20 public JAXRE; // = IERC20(0xEc7D5848F88246cA6984b8019d08B8524793b062);

    enum requeststatus { Init, Requested, Processed }
    enum BrokerStatus { Init, Active, InActive }
    enum AgentStatus { Init, Active, InActive }
    enum TraderStatus { Init, Active, InActive, Suspended }

    struct Broker {
        uint credit_rating;
        bytes32 email_hash;
        bytes32 mobile_hash;
        BrokerStatus status;
    }

    struct Agent {
        uint broker_debt;
        uint credit_rating;
        bytes32 email_hash;
        bytes32 mobile_hash;
        address broker_address;
        bool is_settle_debt;
        AgentStatus status;
    }

    struct Trader {
        uint debt_to_agent;
        uint credit_rating;
        uint account_type;
        bytes32 email_hash;
        bytes32 mobile_hash;
        address agent_address;
        TraderStatus status;
    }

    address public operator;
    uint public max_trader_debt_to_agent;
    uint public min_auto_settlement_amount;
    uint public debt_settlement_ratio;

    mapping(address => Broker) public brokers;
    mapping(address => Agent) public agents;
    
    Trader[] public traders;
    uint public traderCount;

    mapping(address => bool) public other_whitelist;
    mapping(address => uint) public autosettlement_amounts;
    mapping(address => AgentStatus) public requested_agent_status;
    mapping(uint => TraderStatus) public requested_trader_status;

    enum LoanRequestStatus { Init, Approved, Rejected }

    struct LoanRequest {
        uint amount;
        address to;
        LoanRequestStatus status;
    }

    uint public loanRequestCount;
    LoanRequest[] public loanRequests;

    event Set_Gate_Keeper(address _gate_keeper);
    event Set_Other_Whitelisted(address account, bool flag);
    event Set_Exchanger(address exchanger);

    event Add_Trader(uint traderId, address agent);
    event Add_Trader_Request(uint traderId, Trader trader);
    event Approve_Trader(uint traderId);
    event Set_Operator(address operator);
    event Set_Max_Trader_Debt_To_Agent(uint debt);
    event Set_Min_Auto_Settlement_Amount(uint amount);
    event Set_Broker_Status(BrokerStatus status);
    event Loan_To_Agent(address broker, address agent, uint debt);
    event Set_Debt_Settlement_Ratio(uint ratio);
    event Set_My_Autosettlement_Amount(uint amount);
    event Add_Agent(address broker, Agent agent);
    event Set_Agent(address broker, Agent agent);
    event Set_Agent_Status(address agent, AgentStatus status);
    event Set_Trader_Status(uint traderId, TraderStatus status);
    event Generate_Trader_Id(uint trader_id, address agent);
    event Request_Loan_For_Broker(uint requestId, address broker, uint amount);
    event Request_Loan_For_Opex(uint requestId, uint amount);
    event Approve_Loan(uint requestId);
    event Reject_Loan(uint requestId);

    modifier onlyGatekeeper() {
        require(msg.sender == gate_keeper, "Only Gatekeeper");
        _;
    }

    modifier onlyOperator() {
        require(msg.sender == operator, "Only operator");
        _;
    }

    function init(address _digire) public initializer
    {
        __Ownable_init();
        DIGIRE = IERC20(_digire);
        BUSD = IERC20(0xa51BcDc792285598Ba7443c71D557e0B7Df6f991);
        JAXRE = IERC20(0xEc7D5848F88246cA6984b8019d08B8524793b062);
    }

    function set_gate_keeper(address _gate_keeper) external onlyOwner {
        gate_keeper = _gate_keeper;
        emit Set_Gate_Keeper(_gate_keeper);
    }
    
    function isWhitelisted(address account) external view returns(bool) {
        return  agents[account].status == AgentStatus.Active ||
                brokers[account].status == BrokerStatus.Active ||
                other_whitelist[account];
    }

    function set_other_whitelisted(address account, bool flag) external onlyOwner {
        other_whitelist[account] = flag;
        emit Set_Other_Whitelisted(account, flag);
    }

    function set_exchanger(address _exchanger) external onlyOwner {
        exchanger = _exchanger;
        emit Set_Exchanger(_exchanger);
    }

    function add_broker(bytes32 email_hash, bytes32 mobile_hash, address broker_address, uint credit_rating) external onlyOwner {
        Broker storage broker = brokers[broker_address];
        require(broker.status == BrokerStatus.Init, "Invalid status");
        broker.credit_rating = credit_rating;
        broker.email_hash = email_hash;
        broker.mobile_hash = mobile_hash;
        broker.status = BrokerStatus.Active;
    }

    function add_agent(bytes32 email_hash, bytes32 mobile_hash, address agent_address, uint credit_rating, bool is_settle_debt) external {
        Broker storage broker = brokers[msg.sender];
        require(broker.status == BrokerStatus.Active, "Only broker");
        Agent storage agent = agents[agent_address];
        require(agent.status == AgentStatus.Init, "Agent already exists");
        agent.credit_rating = credit_rating;
        agent.is_settle_debt = is_settle_debt;
        agent.broker_address = msg.sender;
        agent.email_hash = email_hash;
        agent.mobile_hash = mobile_hash;
        agent.status = AgentStatus.Active;
        emit Add_Agent(msg.sender, agent);
    }

    function set_agent_status(bytes32 email_hash, bytes32 mobile_hash, address agent_address, AgentStatus status) external {
        Agent storage agent = agents[agent_address];
        require(agent.broker_address == msg.sender, "Not a valid broker");
        require(agent.email_hash == email_hash && agent.mobile_hash == mobile_hash, "Invalid hash");
        require(status != AgentStatus.Init, "Invalid status");
        if(status != AgentStatus.Active)
            requested_agent_status[agent_address] = status;
        else
            agent.status = status;
        emit Set_Agent_Status(agent_address, status);
    }

    function approve_agent_status(address agent) external onlyOwner {
        require(requested_agent_status[agent] != AgentStatus.Init, "Invalid status");
        agents[agent].status = requested_agent_status[agent];
        requested_agent_status[agent] = AgentStatus.Init;
    }

    function set_agent(address agent_address, uint credit_rating, bool is_settle_debt) external {
        Agent storage agent = agents[agent_address];
        require(agent.broker_address == msg.sender && agent.status == AgentStatus.Active, "Invalid agent");
        agent.credit_rating = credit_rating;
        agent.is_settle_debt = is_settle_debt;
        emit Set_Agent(msg.sender, agent);
    }

    function generate_trader_id() external {
        require(agents[msg.sender].status == AgentStatus.Active, "Only agent");
        Trader memory trader;
        trader.agent_address = msg.sender;
        traders.push(trader);
        emit Generate_Trader_Id(traderCount++, msg.sender);
    }

    function add_trader_request(bytes32 email_hash, bytes32 mobile_hash, uint trader_id, uint trader_debt_to_agent, uint trader_credit_rating, uint account_type) external { 
        require(agents[msg.sender].status == AgentStatus.Active, "Only agent");
        Trader storage trader = traders[trader_id];
        require(trader.status == TraderStatus.Init);
        if(trader_debt_to_agent > max_trader_debt_to_agent)
            trader_debt_to_agent = max_trader_debt_to_agent;
        trader.debt_to_agent = trader_debt_to_agent;
        trader.credit_rating = trader_credit_rating;
        trader.agent_address = msg.sender;
        trader.email_hash = email_hash;
        trader.mobile_hash = mobile_hash;
        trader.account_type = account_type;
        emit Add_Trader_Request(trader_id, trader);
    }
    
    function set_trader_status(uint traderId, TraderStatus status) external onlyOwner {
        require(traders[traderId].agent_address == msg.sender, "Invalid agent");
        require(traders[traderId].status != TraderStatus.Init && status != TraderStatus.Init, "Invalid status");
        if(status != TraderStatus.Active)
            requested_trader_status[traderId] = status;
        else
            traders[traderId].status = status;
        emit Set_Trader_Status(traderId, status);
    }

    function approve_trader_status(uint traderId) external onlyOperator {
        require(requested_trader_status[traderId] != TraderStatus.Init, "Invalid status");
        traders[traderId].status = requested_trader_status[traderId];
        requested_trader_status[traderId] = TraderStatus.Init;
    }

    function approve_trader(uint traderId) external onlyOperator {
        Trader storage trader = traders[traderId];
        require(trader.status == TraderStatus.Init, "Invalid status");
        trader.status = TraderStatus.Active;
        emit Approve_Trader(traderId);
    }

    function setOperator(address _operator) external onlyOwner {
        require(_operator != address(0), "Zero address");
        operator = _operator;
        emit Set_Operator(_operator);
    }

    function set_max_trader_debt_to_agent(uint _debt) external onlyOwner {
        max_trader_debt_to_agent = _debt;
        emit Set_Max_Trader_Debt_To_Agent(_debt);
    }

    function set_broker_status(address broker_address, BrokerStatus status) external onlyOwner {
        Broker storage broker = brokers[broker_address];
        require(broker.status != BrokerStatus.Init && status != BrokerStatus.Init, "Invalid status");
        broker.status = status;
        emit Set_Broker_Status(status);
    }

    function set_min_auto_settlement_amount(uint amount) external onlyOwner {
        min_auto_settlement_amount = amount;
        emit Set_Min_Auto_Settlement_Amount(amount);
    }

    function loan_to_agent(address agent_address, uint debt) external {
        Agent storage agent = agents[agent_address];
        require(agent.broker_address == msg.sender && agent.status == AgentStatus.Active, "Invalid agent");
        DIGIRE.transferFrom(msg.sender, agent_address, debt);
        agent.broker_debt += debt;
        emit Loan_To_Agent(msg.sender, agent_address, debt);
    }

    function auto_settlement_transfer(address to, uint amount) external onlyGatekeeper {
        require(amount >= min_auto_settlement_amount && amount >= autosettlement_amounts[to], "Smaller than auto settlement amount");
        if(agents[to].is_settle_debt) {
            uint debt_settlement_amount = amount * debt_settlement_ratio / 100;
            if(agents[to].broker_debt < debt_settlement_amount)
                debt_settlement_amount = agents[to].broker_debt;
            if(agents[to].broker_debt > 0) {
                DIGIRE.transferFrom(gate_keeper, agents[to].broker_address, debt_settlement_amount);
                agents[to].broker_debt -= debt_settlement_amount;
            }
            DIGIRE.transferFrom(gate_keeper, to, amount - debt_settlement_amount);
        }
        else {
            DIGIRE.transferFrom(gate_keeper, to, amount);
        }
    }

    function set_debt_settlement_ratio(uint ratio) external onlyOwner {
        debt_settlement_ratio = ratio;
        emit Set_Debt_Settlement_Ratio(ratio);
    }

    function set_my_autosettlement_amount(uint amount) external {
        autosettlement_amounts[msg.sender] = amount;
        emit Set_My_Autosettlement_Amount(amount);
    }

    function repay_broker_debt() external {
        Agent storage agent = agents[msg.sender];
        require(agent.status == AgentStatus.Active, "Only agent");
        DIGIRE.transferFrom(msg.sender, agent.broker_address, agent.broker_debt);
        agent.broker_debt = 0;
    }

    function request_loan(address brokerOrOpex, uint amount) external onlyOperator {
        LoanRequest memory loanRequest;
        loanRequest.to = brokerOrOpex;
        loanRequest.amount = amount;
        loanRequests.push(loanRequest);
        if(brokerOrOpex == operator) {
            emit Request_Loan_For_Opex(loanRequestCount++, amount);
        }
        else {
            require(brokers[brokerOrOpex].status == BrokerStatus.Active, "Invalid broker");
            emit Request_Loan_For_Broker(loanRequestCount++, brokerOrOpex, amount);
        }
        
    }

    function approve_loan(uint requestId) external onlyOwner {
        require(loanRequests[requestId].status == LoanRequestStatus.Init, "Invalid status");
        loanRequests[requestId].status = LoanRequestStatus.Approved;
        emit Approve_Loan(requestId);
    }

    function reject_loan(uint requestId) external onlyOwner {
        require(loanRequests[requestId].status == LoanRequestStatus.Init, "Invalid status");
        loanRequests[requestId].status = LoanRequestStatus.Rejected;
        emit Reject_Loan(requestId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
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
        return functionCallWithValue(target, data, 0, errorMessage);
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
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
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
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
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
        return functionCallWithValue(target, data, 0, errorMessage);
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
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
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
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
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