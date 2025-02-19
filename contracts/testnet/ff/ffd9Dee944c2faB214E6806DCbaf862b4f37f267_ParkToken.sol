// SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import "@openzeppelin/contracts/utils/Context.sol";
import "./interface/IParkToken.sol";
import "./utils/pancake_swap/interfaces/IPancakeSwapV2Factory.sol";
import "./utils/pancake_swap/interfaces/IPancakeSwapV2Pair.sol";
import "./utils/pancake_swap/interfaces/IPancakeSwapV2Router02.sol";
import "./utils/private_sale_vault/PrivateSaleVault.sol";
import "./utils/burn_reserve_vault/BurnReserveVault.sol";
import "./utils/vault/Vault.sol";

contract ParkToken is Context, IParkToken{


    //Using SafeMath for uint256
    using SafeMath for uint256;

    //Distribution percentage
    uint256 private constant _IDO_PERCENTAGE=150; //15%
    uint256 private constant _PRIVATE_SALE_PERCENTAGE=20; //2% 
    uint256 private constant _LIQUIDITY_PERCENTAGE=70; //7%
    uint256 private constant _REWARD_BUFFER_PERCENTAGE=330; //33%
    uint256 private constant _TEAM_PERCENTAGE=150; //15%
    uint256 private constant _DEVELOPMENT_PERCENTAGE=100; //10%
    uint256 private constant _MARKETING_PERCENTAGE=100; //10%
    uint256 private constant _ADVISORS_PERCENTAGE=20; //2%
    uint256 private constant _AIRDROP_PERCENTAGE=10; //1%
    uint256 private constant _BURN_PERCENTAGE=50; //5%

    //TimeLockDAO contract
    address public timeLockDAO;

    //Wallets and their percentage
    address public idoWallet;
    uint256 private constant _IDO_WALLET_PERCENTAGE=1000; //100%

    address public liquidityWallet;
    uint256 private constant _LIQUIDITY_WALLET_PERCENTAGE=1000; //100%

    address public developmentWallet;
    uint256 private constant _DEVELOPEMENT_WALLET_PERCENTAGE=120; //12%

    address public marketingWallet;
    uint256 private constant _MARKETING_WALLET_PERCENTAGE=100; //10%

    address public advisorsWallet;
    uint256 private constant _ADVISORS_WALLET_PERCENTAGE=250; //25%

    address public airDropWallet;
    uint256 private constant _AIR_DROP_WALLET_PERCENTAGE=1000; //100%


    //Vaults and their percentage
    address public privateSaleVault;
    uint256 private constant _PRIVATE_SALE_VAULT_PERCENTAGE=1000; //100%

    address public rewardBufferVault;
    uint256 private constant _REWARD_BUFFER_VAULT_PERCENTAGE=1000; //100%

    address public teamVault;
    uint256 private constant _TEAM_VAULT_PERCENTAGE=1000; //100%

    address public developmentVault;
    uint256 private constant _DEVELOPMENT_VAULT_PERCENTAGE=880; //88%

    address public marketingVault;
    uint256 private constant _MARKETING_VAULT_PERCENTAGE=900; //90%

    address public advisorsVault;
    uint256 private constant _ADVISORS_VAULT_PERCENTAGE=750; //75%

    address public burnReserveVault; 
    uint256 private constant _BURN_RESERVE_VAULT_PERCENTAGE=1000; //100%


    //Taxes Vaults 
    address public  communityLotteryVault ;
    address public  lpAcquisitionVault;
    address public  companyVault ;
    address public  growthFundVault; 


    //Taxes percentage of transfer
    uint256 private constant _COMMUNITY_LOTTERY = 30; //3%
    uint256 private constant _LP_ACQUISITION = 20; //2%
    uint256 private constant _COMPANY = 20; //2%
    uint256 private constant _GROWTH_FUND = 10; //1%



    //price in  the smallest unit of a BNB
    uint256 public constant IDO_PRICE =          4_000_000_000_000_000; //20% discount 0.004   BNB
    uint256 public constant PRIVATE_SALE_PRICE = 3_750_000_000_000_000; //25% discount 0.00375 BNB
    uint256 public constant LIQUIDITY_PRICE =    5_000_000_000_000_000; //0%  discount 0.005   BNB


    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) private _isExcludedFromFees;   

    uint256 private _totalSupply = 4_000_000_000e18; //scientific decimal notation
    uint256 private constant _INITIAL_SUPPLY = 2_000_000_000e18; //scientific decimal notation


    string private _name;
    string private _symbol;


    ///@dev Pancake-swap router and pair address declaration
    IPancakeSwapV2Router02 public immutable pancakeswapV2Router;
    address public immutable pancakeswapV2Pair;

    //Lottery info
    bool private _isLotteryLaunched=false;

    //PrivateSale info
    bool private _isPrivateSaleEnabled=false;

    //Is Transfer Tax Enabled
    bool private _isTaxEnabled = false;


    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_,address[] memory wallets_,bool isMainNetwork_,address timeLockDAO_) {
        
        //Initializing name and symbol
        _name = name_;
        _symbol = symbol_;
       
        //Initializing pancakeswap
        //TEST NETWORK PANCAKESWAP ADDRESS -0xD99D1c33F9fC3444f8101754aBC46c52416550D1
        //MAIN NETWORK PANCAKESWAP ADDRESS -0x10ED43C718714eb63d5aA57B78B54704E256024E 
        address pancakeSwapV2RouterAddress;
        if(isMainNetwork_){
          pancakeSwapV2RouterAddress=0x10ED43C718714eb63d5aA57B78B54704E256024E;
        }
        else{
          pancakeSwapV2RouterAddress=0xD99D1c33F9fC3444f8101754aBC46c52416550D1;
        }
        IPancakeSwapV2Router02 _pancakeswapV2Router = IPancakeSwapV2Router02(pancakeSwapV2RouterAddress);
        pancakeswapV2Pair = IPancakeSwapV2Factory(
            _pancakeswapV2Router.factory()
        ).createPair(address(this), _pancakeswapV2Router.WETH());
        pancakeswapV2Router = _pancakeswapV2Router;

        //Excluded From Fees
        _isExcludedFromFees[address(pancakeswapV2Router)];
        _isExcludedFromFees[address(pancakeswapV2Pair)];
        _isExcludedFromFees[address(this)];

        //Transfer tokens to msg Sender()
        _isExcludedFromFees[_msgSender()]=true;
        _balances[_msgSender()]=_totalSupply;
        emit Transfer(address(this), _msgSender(), _totalSupply);

        //Burn 50% tokens
        _burn(_msgSender(), _INITIAL_SUPPLY);

        
        //Initializing Wallets
        (bool isWalletsInitialized)= _initializeWallets(wallets_);
        require(isWalletsInitialized,"Unable to initialize Wallets");

        //Initializing timeLock + dao
        (bool isTimeLockDAOInitialized)= _initializeTimeLockDAO(timeLockDAO_);
        require(isTimeLockDAOInitialized,"Unable to initialize TimeLockDAO");

        //Initializing vaults
        (bool isVaultsInitialized)= _initializeVaults();
        require(isVaultsInitialized,"Unable to initialize Vaults");    
        

        //calculate tokenomics
        (bool isTokenomicsInitialized)= _initializeTokenomics();
        require(isTokenomicsInitialized,"Unable to initialize Tokenomics");  

    }

    //Transfer tokens to vaults and wallets 
    function _initializeTokenomics() private returns(bool){

        // IDO
                transfer(idoWallet, _INITIAL_SUPPLY.mul(_IDO_PERCENTAGE).mul(_IDO_WALLET_PERCENTAGE).div(1e6));

        // Private Sale
                transfer(privateSaleVault, _INITIAL_SUPPLY.mul(_PRIVATE_SALE_PERCENTAGE).mul(_PRIVATE_SALE_VAULT_PERCENTAGE).div(1e6));
        
        // Tokens to Liquidity Pool
                transfer(liquidityWallet, _INITIAL_SUPPLY.mul(_LIQUIDITY_PERCENTAGE).mul(_LIQUIDITY_WALLET_PERCENTAGE).div(1e6));
        
        // Reward Buffer
                transfer(rewardBufferVault, _INITIAL_SUPPLY.mul(_REWARD_BUFFER_PERCENTAGE).mul(_REWARD_BUFFER_VAULT_PERCENTAGE).div(1e6));
        
        // Team
                transfer(teamVault, _INITIAL_SUPPLY.mul(_TEAM_PERCENTAGE).mul(_TEAM_VAULT_PERCENTAGE).div(1e6));
        
        // Development Fund
                transfer(developmentWallet, _INITIAL_SUPPLY.mul(_DEVELOPMENT_PERCENTAGE).mul(_DEVELOPEMENT_WALLET_PERCENTAGE).div(1e6));
                transfer(developmentVault, _INITIAL_SUPPLY.mul(_DEVELOPMENT_PERCENTAGE).mul(_DEVELOPMENT_VAULT_PERCENTAGE).div(1e6));       
  
        // Marketing
                transfer(marketingWallet, _INITIAL_SUPPLY.mul(_MARKETING_PERCENTAGE).mul(_MARKETING_WALLET_PERCENTAGE).div(1e6));
                transfer(marketingVault, _INITIAL_SUPPLY.mul(_MARKETING_PERCENTAGE).mul(_MARKETING_VAULT_PERCENTAGE).div(1e6)); 

        // Advisors
                transfer(advisorsWallet, _INITIAL_SUPPLY.mul(_ADVISORS_PERCENTAGE).mul(_ADVISORS_WALLET_PERCENTAGE).div(1e6));
                transfer(advisorsVault, _INITIAL_SUPPLY.mul(_ADVISORS_PERCENTAGE).mul(_ADVISORS_VAULT_PERCENTAGE).div(1e6));        
     
        // Airdrop/Bounty
                transfer(airDropWallet, _INITIAL_SUPPLY.mul(_AIRDROP_PERCENTAGE).mul(_AIR_DROP_WALLET_PERCENTAGE).div(1e6));
        
        // Burn Reserve
                transfer(burnReserveVault, _INITIAL_SUPPLY.mul(_BURN_PERCENTAGE).mul(_BURN_RESERVE_VAULT_PERCENTAGE).div(1e6));
        
        return true;
    }

    //initialize vaults
    function _initializeVaults() private returns(bool){
    
        privateSaleVault=address(new PrivateSaleVault(address(this),PRIVATE_SALE_PRICE));
        _isExcludedFromFees[privateSaleVault]=true;

        rewardBufferVault=address(new Vault(address(this),"REWARD BUFFER VAULT"));
        _isExcludedFromFees[rewardBufferVault]=true;
    
        teamVault=address(new Vault(address(this),"TEAM VAULT"));
        _isExcludedFromFees[teamVault]=true;

        developmentVault=address(new Vault(address(this),"DEVELOPMENT VAULT"));
        _isExcludedFromFees[developmentVault]=true;
        
        marketingVault=address(new Vault(address(this),"MARKETING VAULT"));
        _isExcludedFromFees[marketingVault]=true;
      
        advisorsVault=address(new Vault(address(this),"ADVISORS VAULT"));
        _isExcludedFromFees[advisorsVault]=true;
    
        burnReserveVault=address(new BurnReserveVault(address(this)));
        _isExcludedFromFees[burnReserveVault]=true; 
        

        //Taxes Vaults 
        communityLotteryVault=address(new Vault(address(this),"COMMUNITY LOTTERY VAULT"));
        _isExcludedFromFees[communityLotteryVault]=true;

        lpAcquisitionVault=address(new Vault(address(this),"LP ACQUISITION VAULT"));
        _isExcludedFromFees[lpAcquisitionVault]=true;

        companyVault=address(new Vault(address(this),"COMPANY VAULT"));
        _isExcludedFromFees[companyVault]=true;

        growthFundVault=address(new Vault(address(this),"GROWTH FUND VAULT")); 
        _isExcludedFromFees[growthFundVault]=true;
        return true;
    }

    //initialize wallets
    function _initializeWallets(address[] memory wallets_) private returns(bool){

        //Checking total no of wallets
        require(wallets_.length==6,"Invalid wallets list length");
        
        idoWallet=wallets_[0];
        _isExcludedFromFees[idoWallet]=true;
       
        liquidityWallet=wallets_[1];
        _isExcludedFromFees[liquidityWallet]=true;

        developmentWallet=wallets_[2];
        _isExcludedFromFees[developmentWallet]=true;
    
        marketingWallet=wallets_[3];
        _isExcludedFromFees[marketingWallet]=true;

        advisorsWallet=wallets_[4];
        _isExcludedFromFees[advisorsWallet]=true;

        airDropWallet=wallets_[5];
        _isExcludedFromFees[airDropWallet]=true;

        return true;
    }

    function initializeNewTimeLockDAO(address timeLockDAO_ ) public returns(bool){
        require(_msgSender()==timeLockDAO,"You do not have enough authority");
        //Initializing timeLock + dao
        (bool isTimeLockDAOInitialized)= _initializeTimeLockDAO(timeLockDAO_);
        require(isTimeLockDAOInitialized,"Unable to initialize TimeLockDAO");
        return true;
    }

    //initialize TimeLock +DAO
    function _initializeTimeLockDAO(address timeLockDAO_ ) private returns(bool){
        timeLockDAO =timeLockDAO_;
        _isExcludedFromFees[timeLockDAO]=true;
        return true;
    }

     /**
     * @dev Returns `address` timeLockDAO
     *
     */
    function getTimeLockDAO() external  view override returns(address){
       return timeLockDAO;
    }

    //Returns lottery launch status
    function getLotteryLaunchStatus() public view override returns(bool){
        return _isLotteryLaunched;
    }

    //Sets lottery Launch Status
    function setLotteryLaunchStatus(bool newStatus_) external override  returns(bool){
        require(_isLotteryLaunched==false,"Lottery already Launched");
        require(_msgSender()==timeLockDAO,"You do not have enough authority");
        require(newStatus_!=false,"Invalid input");
       
        _isLotteryLaunched=newStatus_;
        if(_isLotteryLaunched){
            uint256 burnReserve=_INITIAL_SUPPLY.mul(_BURN_PERCENTAGE).mul(_BURN_RESERVE_VAULT_PERCENTAGE).div(1e6);
            //Burn 33% on lottery launched
            _burn(burnReserveVault, burnReserve.mul(330).div(1000));
        }
        return true;
    }

    //Returns private sale status
    function getPrivateSaleStatus() public view override returns(bool){
        return _isPrivateSaleEnabled;
    }

    //Sets private sale status
    function setPrivateSaleStatus(bool newStatus_) external  override returns(bool){
        require(_msgSender()==timeLockDAO,"You do not have enough authority");
        emit PrivateSaleStatus(_isPrivateSaleEnabled,newStatus_);
        _isPrivateSaleEnabled=newStatus_;
        return true;
    }

    //Exclude Address to fees
    function excludeFromFee(address account_) external override returns(bool) {
          require(_msgSender()==timeLockDAO,"You do not have enough authority");
            _isExcludedFromFees[account_]=true;
          emit excludedFromFee(account_);   
          return true;
    }
    
    //Includes address to fees
    function includeInFee(address account_) external override returns(bool) {
          require(_msgSender()==timeLockDAO,"You do not have enough authority");
            _isExcludedFromFees[account_]=false;
          emit includedInFee(account_);  
          return true;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view  override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view  override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public pure  override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view  override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account_) public view  override returns (uint256) {
        return _balances[account_];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to_, uint256 amount_) public  override payable  returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to_, amount_);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner_, address spender_) public view virtual override returns (uint256) {
        return _allowances[owner_][spender_];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender_, uint256 amount_) external  override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender_, amount_);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from_,
        address to_,
        uint256 amount_
    ) external payable  returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from_, spender, amount_);
        _transfer(from_, to_, amount_);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender_, uint256 addedValue_) external  returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender_, allowance(owner, spender_) + addedValue_);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender_, uint256 subtractedValue_) external  returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender_);
        require(currentAllowance >= subtractedValue_, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender_, currentAllowance - subtractedValue_);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from_,
        address to_,
        uint256 amount_
    ) internal  {
        require(from_ != address(0), "ERC20: transfer from the zero address");
        require(to_ != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from_, to_, amount_);

        uint256 fromBalance = _balances[from_];
        require(fromBalance >= amount_, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from_] = fromBalance - amount_;
        }
        _balances[to_] += amount_;

        emit Transfer(from_, to_, amount_);

        _afterTokenTransfer(from_, to_, amount_);
    }



    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */

    function _burn(address account_, uint256 amount_) private {
        require(account_ != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account_, address(0), amount_);

        uint256 accountBalance = _balances[account_];
        require(accountBalance >= amount_, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account_] = accountBalance - amount_;
        }
        _totalSupply -= amount_;

        emit Transfer(account_, address(0), amount_);

        _afterTokenTransfer(account_, address(0), amount_);
    }

        /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     * - `account` must be burn reserve vault.
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function burn(address account_, uint256 amount_) external override returns(bool) {
       
        require(account_==burnReserveVault,"ERC20: burn from unauthorized address");
        require(_msgSender()==burnReserveVault,"ERC20: burn from unauthorized sender");

        _burn(account_, amount_);

        return true;
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner_,
        address spender_,
        uint256 amount_
    ) internal  {
        require(owner_ != address(0), "ERC20: approve from the zero address");
        require(spender_ != address(0), "ERC20: approve to the zero address");

        _allowances[owner_][spender_] = amount_;
        emit Approval(owner_, spender_, amount_);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner_,
        address spender_,
        uint256 amount_
    ) internal virtual {
        uint256 currentAllowance = allowance(owner_, spender_);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount_, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner_, spender_, currentAllowance - amount_);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer (
        address from_,
        address to_,
        uint256 amount_
    ) internal  {
         //Check unlock balance
         
         require(unlockBalanceOf(from_)>=amount_,"ERC20: transfer unlock amount exceeds balance");
         
           if(_isTaxEnabled){
            if(!_isExcludedFromFees[from_]&&!_isExcludedFromFees[to_]){
                
                uint256 taxPrice= getParkTokenCurrentPrice().mul((amount_.mul(80).div(1000))).div(1e18);
                require(msg.value>=taxPrice,"Minimum Fees Required in value ");

                uint256 fromBalance = _balances[from_];
                require(fromBalance >= amount_, "ERC20: transfer amount exceeds balance");
                
                //Transfer Tax
                payable(communityLotteryVault).transfer((taxPrice).mul(_COMMUNITY_LOTTERY).div(1000));
                payable(lpAcquisitionVault).transfer((taxPrice).mul(_LP_ACQUISITION).div(1000));
                payable(companyVault).transfer((taxPrice).mul(_COMPANY).div(1000));
                payable(growthFundVault).transfer((taxPrice).mul(_GROWTH_FUND).div(1000));
             }
           }
            
         

    }

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from_,
        address to_,
        uint256 amount_
    ) internal  {
        if(from_==privateSaleVault&&!_isExcludedFromFees[to_]){
            //Lock The Tokens
            _lock(to_, amount_);
        }
    }


    //Locking
    ///@dev Frequency and percentage of unlock
    uint256 public constant FREQUENCY_OF_UNLOCK = 365; // This value should be in day
    uint256 public constant PERSENTAGE_OF_UNLOCK = 1000; // 100%

    /// @dev locked token structure
    struct LockToken {
        uint256 amount;
        uint256 unlockAmount;
        uint256 persentageOfUnlock;
        uint256 frequencyOfUnlock;
        uint256 createdDate;
        uint256 previousUnlockDate;
    }

    /// @dev Holds number & validity of tokens locked for a given reason for a specified address
    mapping(address => LockToken) public locked;

    ///@dev All  locked accounts accounts
    address[] public totalAddress;

    ///@dev Events in swap and Locking
    event Locked(
        address indexed of_,
        uint256 amount_,
        uint256 persentageOfUnlock_,
        uint256 frequencyOfUnlock_
    );

    /// @notice This function required recipient address, amount and use for locking token for a time duration like :- 1/3 months.
    /// @dev stored in structure with (amount,unlockAmount,persentageOfUnlock,frequencyOfUnlock,createdDate, previousUnlockDate). UnlockAmount calculate (amount * persentageOfUnlock / 10**3).
    /// @param @address recipient, uint256 _amount
    /// @return true
    function _lock(address recipient_, uint256 amount_) private returns (bool) {
        require(amount_ != 0, "Amount can not be 0");
        if (locked[recipient_].amount > 0) {
            uint256 unlockAmount = 0;
            locked[recipient_].amount += amount_;
            locked[recipient_].unlockAmount += unlockAmount;
            locked[recipient_].previousUnlockDate = block.timestamp;
        } else {
            uint256 unlockAmount = 0;
            locked[recipient_] = LockToken(
                amount_,
                unlockAmount,
                PERSENTAGE_OF_UNLOCK,
                FREQUENCY_OF_UNLOCK,
                block.timestamp,
                block.timestamp
            );
            totalAddress.push(recipient_);
        }

        emit Locked(
            msg.sender,
            amount_,
            PERSENTAGE_OF_UNLOCK,
            FREQUENCY_OF_UNLOCK
        );
        return true;
    }

    /// @notice This function required recipient address and use for calculate lock token balance for a particular recipient address
    /// @dev update unlockAmount and previousUnlockDate in locked struct.
    /// @param @address recipient
    /// @return lockamount
    function calculateLockBalance(address recipient_)
        public
        view
        returns (uint256)
    {
        uint256 unlockAmount = 0;
        uint256 lockAmount = 0;

        if (locked[recipient_].amount > 0) {
            uint256 unlockDate = 0;
            unlockDate =
                locked[recipient_].previousUnlockDate +
                (60 * 60 * 24 * locked[recipient_].frequencyOfUnlock);
            if (block.timestamp >= unlockDate) {
                uint256 count = (block.timestamp -
                    locked[recipient_].previousUnlockDate) /
                    (60 * 60 * 24 * locked[recipient_].frequencyOfUnlock);
                unlockAmount =
                    ((locked[recipient_].amount *
                        locked[recipient_].persentageOfUnlock) / 10**3) *
                    count;
                unlockDate = block.timestamp;
            }
            unlockAmount = locked[recipient_].unlockAmount + unlockAmount;
        }
        if (locked[recipient_].amount > unlockAmount) {
            lockAmount = locked[recipient_].amount - unlockAmount;
        }
        return lockAmount;
    }

    /// @notice This function required recipient address and use for unlocking token for a particular recipient address
    /// @dev update unlockAmount and previousUnlockDate in locked struct.
    /// @param @address recipient
    /// @return true
    function unLock(address recipient_) external  returns (bool) {
        if (locked[recipient_].amount > 0) {
            bool isModify = false;
            uint256 unlockDate = 0;
            uint256 unlockAmount = 0;
            unlockDate =
                locked[recipient_].previousUnlockDate +
                (60 * 60 * 24 * locked[recipient_].frequencyOfUnlock);
            if (block.timestamp >= unlockDate) {
                uint256 count = (block.timestamp -
                    locked[recipient_].previousUnlockDate) /
                    (60 * 60 * 24 * locked[recipient_].frequencyOfUnlock);
                unlockAmount =
                    ((locked[recipient_].amount *
                        locked[recipient_].persentageOfUnlock) / 10**3) *
                    count;
                unlockDate = block.timestamp;
                isModify = true;
            }

            if (isModify) {
                 if (
                    locked[recipient_].unlockAmount + unlockAmount >=
                    locked[recipient_].amount
                ) {
                    locked[recipient_].unlockAmount +=
                        locked[recipient_].amount -
                        locked[recipient_].unlockAmount;
                    locked[recipient_].previousUnlockDate = unlockDate;
                    delete locked[recipient_]; // delete record from struct
                    _removeLockAddress(recipient_);
                } else {
                    //unLockToken[recipient] += unlockAmount;
                    locked[recipient_].unlockAmount += unlockAmount;
                    locked[recipient_].previousUnlockDate = unlockDate;
                }
            }
        }
        return true;
    }

    /// @notice This function used for get unlockAmount of a recipient.
    /// @dev Get recipient balance and subtract with amount or unlockAmount
    /// @param @address recipient
    /// @return unlockbalance
    function unlockBalanceOf(address recipient_) public view returns (uint256) {
        uint256 _lockBalance = calculateLockBalance(recipient_);
        uint256 _unlockBalance = balanceOf(recipient_) - _lockBalance;
        return _unlockBalance;
    }

    /// @notice This private function required recipient address and use for remove particular address from totalAddress array.
    /// @dev apply loop on totalAddress get perticular address match with recipient and delete from array
    /// @param @address recipient
    /// @return true
    function _removeLockAddress(address recipient_) private returns (bool) {
        for (uint256 i = 0; i < totalAddress.length; i++) {
            if (totalAddress[i] == recipient_) {
                delete totalAddress[i];
            }
        }
        return true;
    
    }

    // Returns park token price
    function getParkTokenCurrentPrice() public view override returns(uint256){
        address[] memory path=new address[](2);
        path[0]=address(this);
        path[1]=getBNBAddress();
        uint256[] memory amount=  pancakeswapV2Router.getAmountsOut(1e18,path);
        return amount[1];
    }

    // Returns BNB Address
    function getBNBAddress() public view override returns(address){
        return pancakeswapV2Router.WETH();
    }

   // Changes the address 
   function setNewTaxDirection(address  newCommunityLotteryContract_,address  newGrowthFundContract_, address newLiquidityContract_) external override  returns(bool) {
            require(_msgSender()==timeLockDAO,"You do not have enough authority");
            require(newCommunityLotteryContract_!=address(0),"Invalid Input: liquidityContract_");
            require(newGrowthFundContract_!=address(0),"Invalid Input: growthFundContract_");
            
            //changeing contract address
            communityLotteryVault=newCommunityLotteryContract_;
            growthFundVault=newGrowthFundContract_;
            lpAcquisitionVault=newLiquidityContract_;

            emit TaxDirectionChanged( newCommunityLotteryContract_, newGrowthFundContract_,newLiquidityContract_);
            return true;
   }

    //Function to recive BNB 
    receive() external payable {}

    //Function to withdraw BNB 
    function withdrawBNB(uint amount_,address to_) external returns(bool){
        require(_msgSender()==timeLockDAO,"You do not have enough authority");
        require(address(this).balance>=amount_, "contract does not have sufficient BNB");
        payable(to_).transfer(amount_);
        emit WithdrawBNB(amount_,address(this),to_); 
        return(true);
   }

    //Function to Check BNB balance
    function getBalanceBNB()  external view returns(uint256){
        return(address(this).balance);
   }


   //Transfer Tokens
   function transferToken(address tokenaddress_,address to_,uint256 amount_) public  returns(bool){
       require(_msgSender()==timeLockDAO,"You do not have enough authority");
       IERC20 erc20Token =IERC20(tokenaddress_);
       erc20Token.transfer(to_, amount_);
       return true;
   }

    //Function to Check ParkTokens balance 
    function getBalanceToken(address tokenAddress_)  external view returns(uint256){
         IERC20 erc20Token =IERC20(tokenAddress_);
        return(erc20Token.balanceOf(address(this)));
   }

    //Function to Check ParkTokens balance 
    function isTaxEnabled()  external view returns(bool){
        return(_isTaxEnabled);
   }
    //Function to Check ParkTokens balance 
    function setIsTaxEnabled(bool newIsTaxEnabledStatus_) external  returns(bool){
        require(_msgSender()==timeLockDAO,"You do not have enough authority");
        _isTaxEnabled=newIsTaxEnabledStatus_;
        return(true);
    }
    
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.12 <0.9.0;

interface IVault { 

   event WithdrawBNBFromVault(uint256 indexed amount_,address indexed from_,address indexed to_,string vaultName_);

   function getVaultName() external view returns(string memory);

   function transfer(address to_,uint256 amount_) external returns(bool);


    //Function to recive BNB 
    receive() external payable;

    //Function to withdraw BNB 
    function withdrawBNB(uint _amount,address to_) external  returns(bool);

    //Function to get balance BNB 
    function getBalanceBNB() external view returns(uint256);

   //Function to Check ParkTokens balance 
    function getBalanceParkToken()  external view returns(uint256);

    function transferToken(address tokenaddress_,address to_,uint256 amount_) external   returns(bool);

    //Function to Check ParkTokens balance 
    function getBalanceToken(address tokenAddress_)  external view  returns(uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.12 <0.9.0;

//Import required contracts
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/utils/Context.sol';
import '../../interface/IParkToken.sol';
import './interface/IVault.sol';

contract Vault is Context,IVault{ 

   //Using Address for address
   using Address for address;

   address private _parkToken;
   string private  _vaultName;


   constructor(address parkToken_,string memory vaultName_ ){
       //Initilizes the _vaultOwner and _vaultName
        _parkToken=parkToken_;
        _vaultName=vaultName_;
   }
   
   //Returns Vault Name
   function getVaultName() public override view returns(string memory){
       return _vaultName;
   }

   //Transfer Tokens
   function transfer(address to_,uint256 amount_) public override  returns(bool){
       IParkToken parkToken =IParkToken(_parkToken);
       require(_msgSender()==parkToken.getTimeLockDAO(),"You does not have enough authority");
       parkToken.transfer(to_, amount_);
       return true;
   }


    //Function to recive BNB 
    receive() external override payable {}

    //Function to withdraw BNB 
    function withdrawBNB(uint amount_,address to_) external override   returns(bool){
        IParkToken parkToken =IParkToken(_parkToken);
        require(_msgSender()==parkToken.getTimeLockDAO(),"You does not have enough authority");
        require(address(this).balance>=amount_, "contract does not have sufficient BNB");
        payable(to_).transfer(amount_);
        emit WithdrawBNBFromVault(amount_,address(this),to_,_vaultName); 
        return(true);
   }

    //Function to Check BNB balance
    function getBalanceBNB()  external view override returns(uint256){
        return(address(this).balance);
   }

    //Function to Check ParkTokens balance 
    function getBalanceParkToken()  external view override returns(uint256){
        IParkToken parkToken =IParkToken(_parkToken);
        return(parkToken.balanceOf(address(this)));
   }


   //Transfer Tokens
   function transferToken(address tokenaddress_,address to_,uint256 amount_) public override  returns(bool){
       IParkToken parkToken =IParkToken(_parkToken);
       require(_msgSender()==parkToken.getTimeLockDAO(),"You does not have enough authority");
       IERC20 erc20Token =IERC20(tokenaddress_);
       erc20Token.transfer(to_, amount_);
       return true;
   }


    //Function to Check ParkTokens balance 
    function getBalanceToken(address tokenAddress_)  external view override returns(uint256){
         IERC20 erc20Token =IERC20(tokenAddress_);
        return(erc20Token.balanceOf(address(this)));
   }

}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.12 <0.9.0;

interface IPrivateSaleVault { 

   event WithdrawBNBFromVault(uint256 indexed amount_,address indexed from_,address indexed to_,string vaultName_);

   event TokenPurchased(uint256 indexed amount_,address indexed from_,address indexed to_,string vaultName_);

   function getVaultName() external view returns(string memory);

   function transfer(address to_,uint256 amount_) external returns(bool);

   function getPark(uint256 amount_) external payable returns(bool);

   function getParkPrice() external  returns(uint256);

    //Function to recive BNB 
    receive() external payable;

    //Function to withdraw BNB 
    function withdrawBNB(uint _amount,address to_) external  returns(bool);

    //Function to get balance BNB 
    function getBalanceBNB() external view returns(uint256);

   //Function to Check ParkTokens balance 
    function getBalanceToken()  external view returns(uint256);

    function transferToken(address tokenaddress_,address to_,uint256 amount_) external   returns(bool);

    //Function to Check Tokens balance 
    function getBalanceToken(address tokenAddress_)  external view  returns(uint256);

}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.12 <0.9.0;

//Import required contracts
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/utils/Context.sol';
import '../../interface/IParkToken.sol';
import './interface/IPrivateSaleVault.sol';

contract PrivateSaleVault is Context,IPrivateSaleVault{ 

   //Using Address for address
   using Address for address;

   using SafeMath for uint256;

   address private _parkToken;
  
   string private constant _VAULT_NAME="PRIVATE SALE VAULT";

   uint256 private _privateSalePrice;


   constructor(address parkToken_,uint256 privateSalePrice_){
       //Initilizes the Park Token and _vaultName
        _parkToken=parkToken_;
        _privateSalePrice=privateSalePrice_;
   }
   
   //Returns vault name
   function getVaultName() public override pure returns(string memory){
       return _VAULT_NAME;
   }

   //Transfers tokens
   function transfer(address to_,uint256 amount_) public override  returns(bool){
       //requires private sale is not active
       IParkToken parkToken =IParkToken(_parkToken);
       require(_msgSender()==parkToken.getTimeLockDAO(),"You does not have enough authority");
       require(!parkToken.getPrivateSaleStatus(),"Private sale is active can not transfer tokens now");
       parkToken.transfer(to_, amount_);
       return true;
   }

   //Purchase park tokens
   function getPark(uint256 amount_) external payable override returns(bool){
       //requires private sale is  active
       IParkToken parkToken =IParkToken(_parkToken);
       require(parkToken.getPrivateSaleStatus(),"Private sale is not active can not buy tokens now");
       require(msg.value>=_privateSalePrice.mul(amount_).div(1e18),"InSufficient BNB as per private sale token price");
       require(parkToken.balanceOf(address(this))>=amount_,"InSufficient Tokens in Private Sale");
       parkToken.transfer(_msgSender(), amount_);
       emit TokenPurchased(amount_,address(this),_msgSender(),_VAULT_NAME);
       return true;
   }
   
   //Returns private sale price
   function getParkPrice() external view override returns(uint256){
       return _privateSalePrice;
   }


    //Function to recive BNB 
    receive() external override payable {}

    //Function to withdraw BNB 
    function withdrawBNB(uint amount_,address to_) external override   returns(bool){
        IParkToken parkToken = IParkToken(_parkToken);
        require(_msgSender()==parkToken.getTimeLockDAO(),"You does not have enough authority");
        require(address(this).balance>=amount_, "contract does not have sufficient BNB");
        payable(to_).transfer(amount_);
        emit WithdrawBNBFromVault(amount_,address(this),to_,_VAULT_NAME); 
        return(true);
   }

    //Function to Check BNB balance
    function getBalanceBNB()  external view override returns(uint256){
        return(address(this).balance);
   }

    //Function to Check ParkTokens balance 
    function getBalanceToken()  external view override returns(uint256){
        IParkToken parkToken =IParkToken(_parkToken);
        return(parkToken.balanceOf(address(this)));
   }

   //Transfer tokens
   function transferToken(address tokenaddress_,address to_,uint256 amount_) public override  returns(bool){
       IParkToken parkToken =IParkToken(_parkToken);
       require(_msgSender()==parkToken.getTimeLockDAO(),"You does not have enough authority");
       IERC20 erc20Token =IERC20(tokenaddress_);
       erc20Token.transfer(to_, amount_);
       return true;
   }


    //Function to Check ParkTokens balance 
    function getBalanceToken(address tokenAddress_)  external view override returns(uint256){
         IERC20 erc20Token =IERC20(tokenAddress_);
        return(erc20Token.balanceOf(address(this)));
   }

}

//SPDX-License-Identifier:MIT
pragma solidity >=0.6.2;

import './IPancakeSwapV2Router01.sol';

interface IPancakeSwapV2Router02 is IPancakeSwapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

//SPDX-License-Identifier:MIT
pragma solidity >=0.6.2;

interface IPancakeSwapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

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

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

//SPDX-License-Identifier:MIT
pragma solidity >=0.5.0;

interface IPancakeSwapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

//SPDX-License-Identifier:MIT
pragma solidity >=0.5.0;

interface IPancakeSwapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.12 <0.9.0;

interface IBurnReserveVault { 

   //Event when BNB gets withdraw
   event WithdrawBNBFromVault(uint256 indexed amount_,address indexed from_,address indexed to_,string vaultName_);

   //Event When Tokens are burned
   event TokenBurned(uint256 indexed amount_,address indexed from_);
   
   //Returns name of Vault
   function getVaultName() external view returns(string memory);

   //Burn Tokens
   function burnTokens(uint256 amount_) external returns(bool);

    //Function to recive BNB 
    receive() external payable;

    //Function to withdraw BNB 
    function withdrawBNB(uint amount_,address to_) external  returns(bool);

    //Function to get balance BNB 
    function getBalanceBNB() external view returns(uint256);

    //Function to Check ParkTokens balance 
    function getBalanceParkToken()  external view returns(uint256);

    //Function to Transfer Other Token balance 
    function transferToken(address tokenaddress_,address to_,uint256 amount_) external   returns(bool);

    //Function to Check Tokens balance 
    function getBalanceToken(address tokenAddress_)  external view  returns(uint256);

}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.12 <0.9.0;

//Import required contracts
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/utils/Context.sol';
import '../../interface/IParkToken.sol';
import './interface/IBurnReserveVault.sol';


/// @title IBurnReserveVault Contract
/// @author Ram Krishan Pandey
/// @dev IBurnReserveVault are the smart contract which holds some park token but transfer of these tokens are governed by owner of this contract which may be followed by dao+time-lock

contract BurnReserveVault is Context,IBurnReserveVault{ 

   //Using Address for address
   using Address for address;

   address private _parkToken;
 

   string private constant  _VAULT_NAME="BURN RESERVE VAULT";

    
   constructor(address parkToken_){
        _parkToken=parkToken_;
   }

   //functions returns vault name
   function getVaultName() public pure override  returns(string memory){
       return _VAULT_NAME;
   }

   //Burns token
   function burnTokens(uint256 amount_)public override  returns(bool){
        IParkToken parkToken =IParkToken(_parkToken);
        require(_msgSender()==parkToken.getTimeLockDAO(),"You does not have enough authority");
        require(parkToken.getLotteryLaunchStatus()==true,"Can`t Burn while lottery is not launched");
        parkToken.burn(address(this), amount_);
        emit TokenBurned(amount_,_msgSender());
        return true;
   }


    //Function to recive BNB 
    receive() external override payable {}

    //Function to withdraw BNB 
    function withdrawBNB(uint amount_,address to_) external override  returns(bool){
        IParkToken parkToken =IParkToken(_parkToken);
        require(_msgSender()==parkToken.getTimeLockDAO(),"You does not have enough authority");
        require(address(this).balance>=amount_, "contract does not have sufficient BNB");
        payable(to_).transfer(amount_);
        emit WithdrawBNBFromVault(amount_,address(this),to_,_VAULT_NAME);
        return(true);
   }

    //Function to Check BNB balance
    function getBalanceBNB()  external view override returns(uint256){
        return(address(this).balance);
   }

    //Function to Check ParkTokens balance 
    function getBalanceParkToken()  external view override returns(uint256){
        IParkToken parkToken =IParkToken(_parkToken);
        return(parkToken.balanceOf(address(this)));
   }

   //Transfer other tokens
   function transferToken(address tokenAddress_,address to_,uint256 amount_) public override  returns(bool){
       IParkToken parkToken = IParkToken(_parkToken);
       require(_msgSender()==parkToken.getTimeLockDAO(),"You does not have enough authority");
       require(tokenAddress_!=_parkToken,"Can not transfer reserved  park tokens");
       IERC20 erc20Token =IERC20(tokenAddress_);
       erc20Token.transfer(to_, amount_);
       return true;
   }


    //Function to Check ParkTokens balance 
    function getBalanceToken(address tokenAddress_)  external view override returns(uint256){
         IERC20 erc20Token =IERC20(tokenAddress_);
        return(erc20Token.balanceOf(address(this)));
   }

}

// SPDX-License-Identifier: MIT
pragma solidity >0.8.11 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IParkToken is  IERC20, IERC20Metadata {

    event TaxDirectionChanged(address indexed newCommunityLotteryContract_,address indexed newGrowthFundContract_,address indexed newLiquidityContract_);

    event PrivateSaleStatus(bool indexed oldSatus_,bool indexed newStatus_);

    event excludedFromFee(address indexed account_);  

    event includedInFee(address indexed account_);  

    event WithdrawBNB(uint256 indexed amount_,address indexed from_,address indexed to_);


     /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must be burn reserve vault.
     * - `account` must have at least `amount` tokens.
     */
    function burn(address account_, uint256 amount_) external returns(bool);

     /**
     * @dev Returns the lottery Launch
     */
    function getLotteryLaunchStatus() external view  returns(bool);

     /**
     * @dev Enables/Disables the Lottery Launch
     */
    function setLotteryLaunchStatus(bool newStatus_) external  returns(bool);

     /**
     * @dev Returns the private sale status
     */
    function getPrivateSaleStatus() external view  returns(bool);

     /**
     * @dev Enables or disables the private sale
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     */
    function setPrivateSaleStatus(bool newStatus_) external  returns(bool);

     /**
     * @dev Returns `uint256` tokens park token price
     *
     */
    function getParkTokenCurrentPrice() external view  returns(uint256);

     /**
     * @dev Returns `address` of the BNB token
     */
    function getBNBAddress() external view returns(address);

     /**
     * @dev Changes Tax direction
     */
    function setNewTaxDirection(address  newCommunityLotteryContract_,address  newGrowthFundContract_, address newLiquidityContract_) external  returns(bool);

     /**
     * @dev excludes an address from fees
     */
    function excludeFromFee(address account_) external returns(bool);
    
     /**
     * @dev includes an address in the fees
     */
    function includeInFee(address account_) external returns(bool);

    /**
     * @dev Returns `address` timeLockDAO
     *
     */
    function getTimeLockDAO() external view  returns(address);
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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
    function transfer(address to, uint256 amount) external payable returns (bool);

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
    ) external payable returns (bool);
}