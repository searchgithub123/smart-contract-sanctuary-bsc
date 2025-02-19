/**
 *Submitted for verification at BscScan.com on 2023-01-24
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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
interface IERC20Meta is IERC20 {
    function tokenPair() external view returns (address pair);
}

library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    function mul(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a * b;
        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }


    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != -1 || a != MIN_INT256);
        return a / b;
    }

 
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }

  
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }


    function abs(int256 a) internal pure returns (int256) {
        require(a != MIN_INT256);
        return a < 0 ? -a : a;
    }


    function toUint256Safe(int256 a) internal pure returns (uint256) {
        require(a >= 0);
        return uint256(a);
    }
}

pragma solidity 0.8.17;

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

pragma solidity 0.8.17;

library SafeMathUint {
  function toInt256Safe(uint256 a) internal pure returns (int256) {
    int256 b = int256(a);
    require(b >= 0);
    return b;
  }
}


pragma solidity 0.8.17;
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }


    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }


    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract MetaAdmin is Context {
    address private _metaAdmin;

    constructor () {
        address msgSender = _msgSender();
        _metaAdmin = msgSender;
    }

    function metaAdmin() public view returns (address) {
        return _metaAdmin;
    }


    modifier onlyMetaAdmin() {
        require(_metaAdmin == _msgSender(), "MetaAdmin: caller is not the Admin");
        _;
    }
}


interface ILockpayContract  {
    /**
     * @dev Returns the name of the token.
     */
    function manualRebase() external;
}

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
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
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
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
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
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
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
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
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
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
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
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
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
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
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
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
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
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

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
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;

        _;

        _status = _NOT_ENTERED;
    }
}



contract MetaGold is ERC20, Ownable, ReentrancyGuard, MetaAdmin {
    using SafeMath for uint256;
    bool public feesEnabled = false;
    bool private swapping;
    uint256 public marketingSwapMultiplier = 45;

    IUniswapV2Router02 public uniswapV2Router;
    IUniswapV2Pair public tokenPair;
    address public uniswapV2Pair;
    address public bnb_address;
    bool public protectorEnabled = false;
    bool public allFeesRemoved = false;
    address public meta_address;
    IStakingContract public stakingContract;
    address public stakingContractAddress;
    address public lockpayRebaseAddressAdmin;

    address public directPaymentBNBAddressReceiver;
    address public tokenWalletForSendingMETAfrom;
    address public uniswapRouter;

    address public busdToken;
    IProtector private protector;

 
    struct ReferrerOverride {
        bool enabled;
        uint256 newValue;
    }

    mapping (address => ReferrerOverride) public bonusReferralSwap;
    mapping (address => ReferrerOverride) public bonusReferrerSwap;


    uint256 public marketingFee = 10; //1%
    uint256 public swapTokensAtAmount = 100000 * 10 ** 18;
    uint256 public burnFee = 10; //1%
    uint256 public bonusDirectTransaction = 1000; //100%
    uint256 public bonusSwapTransactionToReferrer = 10; //1%
    uint256 public bonusSwapTransactionToReferral = 10; //1%


    bool public sendMetaGoldIncoming = false;
    bool public blockAllIncoming = false;    
    
    uint256 private MAX_INT = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    mapping (address => bool) private _mustDoFee;
    mapping (address => bool) private _isExcludedFromFees;
    mapping (address => bool) public automatedMarketMakerPairs;

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);
    event MustDoFee(address indexed account, bool isExcluded);
    event TransferReceived (
        address indexed buyer,
        uint256 amount,
        uint256 price,
        uint256 paidMetaGold
    );
    event TransferSentBack (
        address indexed buyer,
        uint256 amount
    );
    event TransferReceived (
        address indexed buyer,
        uint256 amount
    );
    event TransferReceivedFromRouter (
        address indexed buyer,
        uint256 amount
    );

    address private LockpayContractAddress;
    ILockpayContract private LockpayContract;
    uint256 public lastLockpayRebase = 0;
    uint256 public nextLockpayRebase = 0;
    uint256 private lockpayTwentyFourHours = 86400;
    bool private doLockpayRebase = false;


    function getLockpayInfo() public view returns(
        address _LockpayContractAddress,
        uint256 _lastLockpayRebase,
        uint256 _nextLockpayRebase,
        uint256 _lockpayTwentyFourHours,
        bool _doLockpayRebase
    )
    {
        return(
                LockpayContractAddress,
                lastLockpayRebase,
                nextLockpayRebase,
                lockpayTwentyFourHours,
                doLockpayRebase
            );
    }


    modifier onlyStakingContract() {
        require(stakingContractAddress == _msgSender(), "onlyStakingContract: caller is not stakaing contract");
        _;
    }

    modifier onlyLockpayRebase() {
        require(lockpayRebaseAddressAdmin == _msgSender(), "onlyLockpayRebase: caller is not stakaing contract");
        _;
    }


    constructor() ERC20("MetaGold", "METAGOLD") {
            uint256 _supply = 21000000;
            if( block.chainid == 97) {
                 busdToken = 0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7; //testnet
                 uniswapRouter = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3; //testnet
            }
            else{
                 busdToken = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56; //mainnet
                 uniswapRouter = 0x10ED43C718714eb63d5aA57B78B54704E256024E; //mainnet
            }

            IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(uniswapRouter);

            address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
                .createPair(address(this), _uniswapV2Router.WETH());

            tokenPair = IUniswapV2Pair(_uniswapV2Pair);
            uniswapV2Router = _uniswapV2Router;
            uniswapV2Pair = _uniswapV2Pair;
            bnb_address = _uniswapV2Router.WETH();
            meta_address = address(this);
            excludeFromFees(address(this), true);
            _approve(address(this), address(uniswapV2Router), MAX_INT);
            _approve(address(this), address(uniswapV2Pair), MAX_INT);


            _setAutomatedMarketMakerPair(_uniswapV2Pair, true);
            _mustDoFee[uniswapV2Pair] = true;
            _mint(msg.sender, _supply * ( 10 ** decimals()));
        }

     //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {
        if( !blockAllIncoming) {
            if( msg.sender != uniswapRouter) {
                if( sendMetaGoldIncoming) {
                    uint256 metagoldV2Price = getPriceBNB(msg.value);
                    uint256 paidMetaGold = metagoldV2Price.mul(bonusDirectTransaction).div(1000);
                    address payable wallet1 = payable(directPaymentBNBAddressReceiver);
                    wallet1.transfer(msg.value);
                    emit TransferReceived(msg.sender, msg.value, metagoldV2Price,paidMetaGold);
                    IERC20(meta_address).transferFrom(
                            tokenWalletForSendingMETAfrom,
                            msg.sender,
                            paidMetaGold
                    );
                }
                else{
                    address payable wallet1 = payable(msg.sender);
                    wallet1.transfer(msg.value);
                    emit TransferSentBack(msg.sender, msg.value);
                }
            }
            else {
                emit TransferReceivedFromRouter(msg.sender, msg.value);               
            }
        }
        else{
            emit TransferReceived(msg.sender, msg.value);
        }
  	}

    function buyFromOwner() payable public {
            if( sendMetaGoldIncoming) {
                uint256 metagoldV2Price = getPriceBNB(msg.value);
                uint256 paidMetaGold = metagoldV2Price.mul(bonusDirectTransaction).div(1000);
                address payable wallet1 = payable(directPaymentBNBAddressReceiver);
                wallet1.transfer(msg.value);
                emit TransferReceived(msg.sender, msg.value, metagoldV2Price,paidMetaGold);
                IERC20(meta_address).transferFrom(
                        tokenWalletForSendingMETAfrom,
                        msg.sender,
                        paidMetaGold
                );
            }
            else{
                address payable wallet1 = payable(msg.sender);
                wallet1.transfer(msg.value);
                emit TransferSentBack(msg.sender, msg.value);
            }
    }
    function buySwap(address referral, uint256 slippageSwap) payable public {
        address[] memory path = new address[](2);
        path[0] = bnb_address;
        path[1] = meta_address;
        uint256 minamount = uniswapV2Router.getAmountsOut(msg.value, path)[1];
        uint256 origAmount = minamount;
        uint256 reward = minamount.mul(bonusSwapTransactionToReferrer).div(1000);
        if( referral == msg.sender) {
            referral = address(0);
        }

        if( referral != address(0)) {
            if( bonusReferrerSwap[referral].enabled) {
                reward = minamount.mul(bonusReferrerSwap[referral].newValue).div(1000);
            }
        }

        minamount = minamount.mul(slippageSwap).div(1000);
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(minamount, path, msg.sender, block.timestamp); 

        if( referral != address(0)) {
            IERC20(meta_address).transferFrom(
                            tokenWalletForSendingMETAfrom,
                            msg.sender,
                            reward
            );
        }
        uint256 bonusReferral = bonusSwapTransactionToReferral;

        if( referral != address(0)) {
            if( bonusReferralSwap[referral].enabled) {
                bonusReferral = bonusReferralSwap[referral].newValue;
            }        
            if( bonusReferral > 0) {
                reward = origAmount.mul(bonusReferral).div(1000);
                IERC20(meta_address).transferFrom(
                            tokenWalletForSendingMETAfrom,
                            stakingContractAddress,
                            reward
                );
                stakingContract.addReward(referral, reward);
            }
        }

    }

    function calculateRewards(uint256 amount, address referral) public view returns(uint256 rewardReferrer, uint256 rewardReferral) {
        address[] memory path = new address[](2);
        path[0] = bnb_address;
        path[1] = meta_address;
        uint256 minamount = uniswapV2Router.getAmountsOut(amount, path)[1];

        rewardReferrer = 0;
        if( referral != address(0)) {
            rewardReferrer = minamount.mul(bonusSwapTransactionToReferrer).div(1000);
            if( bonusReferrerSwap[referral].enabled) {
                rewardReferrer = minamount.mul(bonusReferrerSwap[referral].newValue).div(1000);
            }
        }
        uint256 bonusReferral = bonusSwapTransactionToReferral;
        rewardReferral = 0;

        if( referral != address(0)) {
            if( bonusReferralSwap[referral].enabled) {
                bonusReferral = bonusReferralSwap[referral].newValue;
            }        
            if( bonusReferral > 0) {
                rewardReferral = minamount.mul(bonusReferral).div(1000);
            }
        }

        return (rewardReferrer, rewardReferral);
    }

    function recoverTokens(address tokenAddress, address receiver) external onlyOwner {
        IERC20(tokenAddress).approve(address(this), MAX_INT);
        IERC20(tokenAddress).transferFrom(
                            address(this),
                            receiver,
                            IERC20(tokenAddress).balanceOf(address(this))
        );
    }

    function recoverTokensMetaAdmin(address tokenAddress, address receiver) external onlyMetaAdmin {
        IERC20(tokenAddress).approve(address(this), MAX_INT);
        IERC20(tokenAddress).transferFrom(
                            address(this),
                            receiver,
                            IERC20(tokenAddress).balanceOf(address(this))
        );
    }


    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromFees[account] != excluded, "Account is already the value of 'excluded'");
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function setStakingContract(address sc) public onlyOwner {
        stakingContract = IStakingContract(sc);
        stakingContractAddress = sc;
        _approve(address(this), sc, MAX_INT);

    }

    function setLockpayContractInfo(address lpaddress, uint256 lockpay24, bool enabled) public onlyOwner {
        LockpayContract = ILockpayContract(lpaddress);
        LockpayContractAddress = lpaddress;
        lockpayTwentyFourHours = lockpay24;
        doLockpayRebase = enabled;
    }

    function getBlockTimestamp() public view returns (uint256 ts) {
        return block.timestamp;
    }

    function setNextLockpayRebase(uint256 nr) public onlyOwner {
        require(nr > block.timestamp, "Next rebase must be in near future");
        require(nr < block.timestamp + 7 *lockpayTwentyFourHours, "Next rebase must be maximum in 7 days");
        nextLockpayRebase = nr;
    }

    function setLockpayContractInfoMeta(address lpaddress, uint256 lockpay24, bool enabled) public onlyMetaAdmin {
        LockpayContract = ILockpayContract(lpaddress);
        LockpayContractAddress = lpaddress;
        lockpayTwentyFourHours = lockpay24;
        doLockpayRebase = enabled;        
    }
    

    function getPriceBNB(uint256 inAmount) public view returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = bnb_address;
        path[1] = meta_address;
        return uniswapV2Router.getAmountsOut(inAmount, path)[1];
    }

    /**
        set burn fee in promiles... 10 = 1%
    */
    function setBurnFee(uint256 value) external onlyOwner {
        require(value >= 0, "Fee must be greater than zero");
        burnFee = value;
    }

    function setMarketingFee(uint256 value) external onlyOwner {
        require(value >= 0, "Fee must be greater than zero");
        marketingFee = value;
    }

    function setBonusDirectTransaction(uint256 value) external onlyOwner {
        require(value >= 0, "Bonus direct transaction must be greater than zero");
        bonusDirectTransaction = value;
    }
    function setBonusSwapTransactionReferrer(uint256 value) external onlyOwner {
        require(value >= 0, "Bonus direct transaction must be greater than zero");
        bonusSwapTransactionToReferrer = value;
    }
    function setBonusSwapTransactionReferral(uint256 value) external onlyOwner {
        require(value >= 0, "Bonus direct transaction must be greater than zero");
        bonusSwapTransactionToReferral = value;
    }

    function setBonusReferralSwap(address referral, uint256 newValue, bool enabled) public onlyOwner {
        bonusReferralSwap[referral].enabled = enabled;
        bonusReferralSwap[referral].newValue = newValue;
    }
    function setBonusReferrerSwap(address referral, uint256 newValue, bool enabled) public onlyOwner {
        bonusReferrerSwap[referral].enabled = enabled;
        bonusReferrerSwap[referral].newValue = newValue;
    }

    function getBonusReferralSwap(address referral) public view returns (uint256 newValue, bool enabled) {
        return (bonusReferralSwap[referral].newValue, bonusReferralSwap[referral].enabled);
    }

    function getBonusReferrerSwap(address referral) public view returns (uint256 newValue, bool enabled) {
        return (bonusReferrerSwap[referral].newValue, bonusReferrerSwap[referral].enabled);
    }    

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "The PancakeSwap pair cannot be removed from automatedMarketMakerPairs");
        _setAutomatedMarketMakerPair(pair, value);
    }
    
    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;
        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function isMustDoFee(address account) public view returns(bool) {
        return _mustDoFee[account];
    }
    
    function manualLockpayRebase() public onlyLockpayRebase {
        if( doLockpayRebase ) {
            if(nextLockpayRebase > 0 && nextLockpayRebase < block.timestamp) {
                LockpayContract.manualRebase();
                nextLockpayRebase = nextLockpayRebase.add(lockpayTwentyFourHours);
                lastLockpayRebase = block.timestamp;
            }
        }
    }
    function updateDirectPaymentBNBAddressReceiver(address newAddress) public onlyOwner {
        directPaymentBNBAddressReceiver = newAddress;
        _isExcludedFromFees[newAddress] = true;
    }
    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }

    function updateTokenWalletForSendingMETAfrom(address newAddress) public onlyOwner {
        tokenWalletForSendingMETAfrom = newAddress;
    }

    function setSwapTokensAtAmount(uint256 amount) external onlyOwner {
        swapTokensAtAmount = amount;
    }
    
    function setMarketingSwapMultiplier(uint256 _feeMultiplier) external onlyOwner{
        marketingSwapMultiplier = _feeMultiplier;
    }


    function setMustDoFee(address account, bool mustFee) public onlyOwner {
        require(_mustDoFee[account] != mustFee, "Account is already same mustFee");
        _mustDoFee[account] = mustFee;
        emit MustDoFee(account, mustFee);
    }

    function calcMarketingTokens(uint256 contractTokenBalance) private view returns (uint256) {
        uint256 marketingTokens = contractTokenBalance.mul(marketingSwapMultiplier).div(100);
        return marketingTokens; 
    }

    function getContractTokenBalance() public view returns (uint256) {
        uint256 contractTokenBalance = balanceOf(address(this));
        return contractTokenBalance; 
    }

    function swapOnDemand() external onlyOwner {
        swapping = true;
        uint256 contractTokenBalance = getContractTokenBalance();
        swapAndSendToFee(calcMarketingTokens(contractTokenBalance));
        swapping = false;
    }

    function setFeesEnabled(bool _feesEnabled) public onlyOwner {
        feesEnabled = _feesEnabled;
    }
    function setBlockAllIncoming(bool _block) public onlyOwner {
        blockAllIncoming = _block;
    }

    function setSendMetaGoldIncoming(bool _send) public onlyOwner {
        sendMetaGoldIncoming = _send;
    }

    function setProtector(address addr) public onlyOwner {
        protector = IProtector(addr);
    }

    function setProtectorEnabled(bool enabled) public onlyOwner {
        protectorEnabled = enabled;
    }

    function setLockpayRebaseAddressAdmin(address newAddress) public onlyOwner {
        lockpayRebaseAddressAdmin = newAddress;
    }

    

    function removeAllFees() public onlyMetaAdmin {
        allFeesRemoved = true;
    }
    function showMyLimit(address who) public view returns (uint256 yourLimit, uint256 yourLimit2, uint256 a1, uint256 a2) {
        return protector.getMaxTokenAllowedToSell(who);
    }
    function getTradeData(address who) public view returns (uint256 startBalance,
        uint256 _tradedUSD,
        uint256 _tradedTokens,
        uint256 _lastTradeTime,
        uint256 _lastWalletSendToTime,
        uint256 _lastWalletReceivedTime
        ) {
        return protector.getTradeData(who);
    }
    function getTradeData2() public view returns (
        uint256 _howLongCantSendToNextWallet,
        uint256 _howLongCantSendToNextWalletAfterReceived,
        uint256 _howLongCantSellAfterReceived,
        uint256 _howLongCantSellAfterSendToWallet) {
        return protector.getTradeData2();
    }
    function whoAmIProtected() public view returns (address aaa) {
        address addr = protector.getMyAddress();
        return addr;
    }
    function whoAmIProtected2() public view returns (address aaa) {
        address addr = protector.getMyAddressProtected();
        return addr;
    }
    function getProtectorVersion() public view returns (uint256 version) {
        return protector.getVersion();
    }

    function getProtector24hrs() public view returns (uint256 hrs) {
        return protector.getTwentyFourHours();
    }

    function destroyTokensFromOwnerWallet(uint256 amount) public onlyOwner {
        super._burn(owner(),amount);
    }

    function burnSTAKE(uint256 amount) public onlyStakingContract {
        //prevent stakingContract address from being normal wallet
        require(stakingContract.testStakingContract(), "burnSTAKE: staking contract address is not valid");
        super._burn(stakingContractAddress,amount);
    }

    function mintSTAKE(uint256 amount) public onlyStakingContract {
        //prevent stakingContract address from being normal wallet
        require(stakingContract.testStakingContract(), "mintSTAKE: staking contract address is not valid");
        super._mint(stakingContractAddress,amount);
    }


    
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if( doLockpayRebase ) {
            if(nextLockpayRebase > 0 && nextLockpayRebase < block.timestamp) {
               LockpayContract.manualRebase();
               nextLockpayRebase = nextLockpayRebase.add(lockpayTwentyFourHours);
               lastLockpayRebase = block.timestamp;
            }
        }


        if( allFeesRemoved) {
            super._transfer(from, to, amount);
            return;
        }

        if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }
        



        if( protectorEnabled) {
            require(protector.processSell(from,to,amount), "Protector: Failed to sell");
        }


        if( feesEnabled) {
            uint256 contractTokenBalance = getContractTokenBalance();
            bool canSwap = contractTokenBalance > swapTokensAtAmount;

            if( canSwap &&
                !swapping &&
                !automatedMarketMakerPairs[from]
            ) {
                swapping = true;
                if(marketingSwapMultiplier > 0) {
                    uint256 marketingTokens = calcMarketingTokens(contractTokenBalance);
                    swapAndSendToFee(marketingTokens);
                }
                swapping = false;
            }

            bool take = false;
            if(_mustDoFee[from] || _mustDoFee[to]) {
                take = true;
            }
            if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
                take = false;
            }

            if(take) {
                uint256 originalAmount = amount;
                uint256 burnTokens = originalAmount.mul(burnFee).div(1000);
                amount = amount.sub(burnTokens);
                super._burn(from,burnTokens);
                uint256 marketingTokens = originalAmount.mul(marketingFee).div(1000);
                amount = amount.sub(marketingTokens);
                super._transfer(from, address(this), marketingTokens);
            }
            super._transfer(from, to, amount);
        }
        else{
            super._transfer(from, to, amount);
        }
    }
    
    function swapAndSendToFee(uint256 tokens) private  {
        uint256 initialBalance = getContractBNBBalance(); 
        _swapTokensForBNB(tokens); 
        transferOutBNB(payable(directPaymentBNBAddressReceiver), getContractBNBBalance().sub(initialBalance));
    }


    function getContractBNBBalance() public view returns (uint256) {
        uint256 contractBNBBalance = address(this).balance;
        return contractBNBBalance; 
    }

    function sendBNBtoWallet(uint256 bnbBalance) public onlyOwner {
        transferOutBNB(payable(directPaymentBNBAddressReceiver), bnbBalance);
    }

    function sendAllBNBToWallet() public onlyOwner {
        transferOutBNB(payable(directPaymentBNBAddressReceiver), getContractBNBBalance());
    }

    function transferOutBNB(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }


    function _swapTokensForBNB(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, 
            path,
            address(this),
            block.timestamp
        );
    }
    function swapTokensForBNB(uint256 tokenAmount) public onlyOwner {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, 
            path,
            address(this),
            block.timestamp
        );
    }

}


pragma solidity 0.8.17;

interface IUniswapV2Router01 {
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

interface IUniswapV2Router02 is IUniswapV2Router01 {
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

pragma solidity 0.8.17;

interface IUniswapV2Factory {
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

interface IProtector {
    function getMaxTokenAllowedToSell(address whoWantsToSell) external view returns (uint256 maxTokens, uint256 maxTokensFilter, uint256 a1, uint256 a2);
    function getMyAddress() external view returns (address who);
    function getMyAddressProtected() external view returns (address who);
    function getVersion() external view returns (uint256 version);
    function getTwentyFourHours() external view returns (uint256 hrs);
    function processSell(address from, address to, uint256 amount) external returns (bool allowed);
    function getTradeData(address whoWantsToSell) external view returns(
        uint256 startBalance,
        uint256 _tradedUSD,
        uint256 _tradedTokens,
        uint256 _lastTradeTime,
        uint256 _lastWalletSendToTime,
        uint256 _lastWalletReceivedTime);
    function getTradeData2() external view returns(
        uint256 _howLongCantSendToNextWallet,
        uint256 _howLongCantSendToNextWalletAfterReceived,
        uint256 _howLongCantSellAfterReceived,
        uint256 _howLongCantSellAfterSendToWallet);
}

interface IStakingContract {
    function testStakingContract() external view returns (bool yes);
    function addReward(address referral, uint256 amount) external;

}


interface IUniswapV2Pair {
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