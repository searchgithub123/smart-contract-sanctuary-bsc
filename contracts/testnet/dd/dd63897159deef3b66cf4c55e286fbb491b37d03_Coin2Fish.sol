// SPDX-License-Identifier: MIT
// Coin2Fish Contract (Coin2FishToken.sol)

pragma solidity 0.8.15;

import "./contracts/ERC20.sol";
import "./access/Ownable.sol";
import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IUniswapV2Router02.sol";

/**
 * @title Coin2Fish Contract for Coin2Fish Reborn Token
 * @author HeisenDev
 */
contract Coin2Fish is ERC20, Ownable {
    using SafeMath for uint256;
    IUniswapV2Router02 public uniswapV2Router;

    /**
     * Definition of the token parameters
     */
    string private _tokenName = "Coin2Fish Reborn";
    string private _tokenSymbol = "C2FR";
    uint private _tokenTotalSupply = 100000000 * 10 ** 18;
    uint private _tokenDecimals = 18;

    /**
     * Price definitions
     */
    uint private eggCommonPresalePrice = 0.1 ether;
    uint private eggCommonPrice = 0.14 ether;
    uint private eggCommonPriceC2FR = 3500 ether;
    uint private eggRarePricePresale = 0.22 ether;
    uint private eggRarePrice = 0.31 ether;
    uint private eggRarePriceC2FR = 7500 ether;
    uint private eggCommonSells = 0;
    uint private eggRareSells = 0;
    bool public eggSalesStatus = false;

    mapping(address => uint256) private _authorizedWithdraws;
    mapping(address => uint256) private _accountTransactionLast;
    mapping(address => uint256) private _accountTransactionCount;
    mapping(address => uint256) private _accountWithdrawalLast;
    mapping(address => uint256) private _accountWithdrawalCount;


    uint public withdrawPrice = 0.004 ether;

    /**
     * Limits Definitions
     * `_maxWalletAmount` Represents the maximum value to store in a Wallet
     * It is initialized with the 0.5% of total supply (500.000 C2FR Tokens)
     *
     * `_maxTransactionAmount` Represents the maximum value to make a transfer
     * It is initialized with the 0.5% of total supply (500.000 C2FR Tokens)
     *
     * These limitations can be modified by the methods
     * {setMaxTransactionAmount} and {setMaxWalletAmount}.
     */

    uint256 public _maxWalletAmount = _tokenTotalSupply.div(200);
    uint256 public _maxTransactionAmount = _tokenTotalSupply.div(200);
    uint256 public _maxTransactionCount = 10;
    uint256 public _maxWithdrawalCount = 1;
    uint256 public _maxTransactionWithdrawAmount = 100000 ether;

    /**
     * Definition of the Project Wallets
     * `addressHeisenDev` Corresponds to the wallet address where the development
     * team will receive their payments
     * `addressMarketing` Corresponds to the wallet address where the funds
     * for marketing will be received
     * `addressTeam` Represents the wallet where teams and other
     * collaborators will receive their payments
     */
    address payable public addressHeisenDev = payable(0xEDa73409d4bBD147f4E1295A73a2Ca243a529338);
    address payable public addressMarketing = payable(0x3c1Cd83D8850803C9c42fF5083F56b66b00FBD61);
    address payable public addressTeam = payable(0x63024aC73FE77427F20e8247FA26F470C0D9700B);

    /**
     * Definition of the taxes fees for swaps
     * `taxFeeHeisenDev` 0%  Initial tax fee during presale
     * `taxFeeMarketing` 0%  Initial tax fee during presale
     * `taxFeeTeam` 0%  Initial tax fee during presale
     * `taxFeeLiquidity` 0%  Initial tax fee during presale
     * This value can be modified by the method {updateTaxesFees}
     */
    uint public taxFeeHeisenDev = 0;
    uint public taxFeeMarketing = 0;
    uint public taxFeeTeam = 0;
    uint public taxFeeLiquidity = 0;

    /**
     * Definition of pools
     * `_poolHeisenDev`
     * `_poolMarketing`
     * `_poolTeam`
     * `_poolLiquidity`
     */
    uint public _poolHeisenDev = 0;
    uint public _poolMarketing = 0;
    uint public _poolTeam = 0;
    uint public _poolLiquidity = 0;

    /**
     * Store the last configuration of tax fees
     * `previousHeisenDevTaxFee` store the previous value of `taxFeeHeisenDev`
     * `previousMarketingTaxFee` store the previous value of `taxFeeMarketing`
     * `previousTeamTaxFee` store the previous value of `taxFeeLiquidity`
     * `previousLiquidityTaxFee` store the previous value of `taxFeeTeam`
     */
    uint public previousHeisenDevTaxFee = taxFeeHeisenDev;
    uint public previousMarketingTaxFee = taxFeeMarketing;
    uint public previousTeamTaxFee = taxFeeTeam;
    uint public previousLiquidityTaxFee = taxFeeLiquidity;


    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) private _isExcludedFromLimits;
    mapping(address => bool) public automatedMarketMakerPairs;

    event Deposit(address indexed sender, uint amount);
    event BuyCommonEgg(uint amount);
    event BuyRareEgg(uint amount);
    event EggSalesStatus(bool status);
    event Withdraw(uint amount);
    event TeamPayment(uint amount);
    event SwapAndAddLiquidity(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
    event UpdateTaxesFees(
        uint256 taxFeeHeisenDev,
        uint256 taxFeeMarketing,
        uint256 taxFeeTeam,
        uint256 taxFeeLiquidity
    );
    event UpdateWithdrawOptions(
        uint256 withdrawPrice
    );
    constructor(address[] memory _constructorOwners, address _constructorBackend) ERC20(_tokenName, _tokenSymbol) {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
        .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;

        automatedMarketMakerPairs[_uniswapV2Pair] = true;
        _isExcludedFromFees[address(this)] = true;
        _isExcludedFromFees[addressHeisenDev] = true;
        _isExcludedFromFees[addressMarketing] = true;
        _isExcludedFromFees[addressTeam] = true;

        _isExcludedFromLimits[address(this)] = true;
        _isExcludedFromLimits[_uniswapV2Pair] = true;
        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(address(this), _tokenTotalSupply);
        /*
            _setOwners is an internal function in Ownable.sol that is only called here,
            and CANNOT be called ever again
        */
        _setOwners(_constructorOwners);
        /*
            _transferBackend is an internal function in Ownable.sol
        */
        _transferBackend(_constructorBackend);
    }

    /// @dev Fallback function allows to deposit ether.
    receive() external payable {
        if (msg.value > 0) {
            emit Deposit(_msgSender(), msg.value);
        }
    }

    function buyCommonEgg(uint amount) public payable {
        require(eggSalesStatus, "Presale isn't enabled");
        require(amount >= 0, "Amount must be greater than 0");
        require(msg.value >= (eggCommonPresalePrice.mul(amount)), "The amount sent is not equal to the amount required");
        eggCommonSells = eggCommonSells.add(amount);
        addLiquidity(msg.value);
        emit BuyCommonEgg(amount);
    }

    function buyRareEgg(uint256 amount) public payable {
        require(eggSalesStatus, "Presale isn't enabled");
        require(amount >= 0, "Amount must be greater than 0");
        require(msg.value >= (eggRarePricePresale.mul(amount)), "The amount sent is not equal to the amount required");
        eggRareSells = eggRareSells.add(amount);
        addLiquidity(msg.value);
        emit BuyRareEgg(amount);
    }

    function teamPayment() external onlyOwner {
        super._transfer(address(this), addressHeisenDev, _poolHeisenDev);
        super._transfer(address(this), addressMarketing, _poolMarketing);
        super._transfer(address(this), addressTeam, _poolTeam);
        uint256 amount = _poolHeisenDev + _poolMarketing + _poolTeam;
        _poolHeisenDev = 0;
        _poolMarketing = 0;
        _poolTeam = 0;
        emit TeamPayment(amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        if (_isExcludedFromLimits[from] == false) {
            require(amount <= _maxTransactionAmount, "Transfer amount exceeds the max transaction amount.");
        }
        if (_isExcludedFromLimits[to] == false) {
            require(balanceOf(to) + amount <= _maxWalletAmount, 'Transfer amount exceeds the max Wallet Amount.');
        }

        // if any account belongs to _isExcludedFromFee account then remove the fee
        bool takeFee = !(_isExcludedFromFees[from] || _isExcludedFromFees[to]);

        if (takeFee && automatedMarketMakerPairs[from]) {
            uint256 heisenDevAmount = amount.mul(taxFeeHeisenDev).div(100);
            uint256 marketingAmount = amount.mul(taxFeeMarketing).div(100);
            uint256 teamAmount = amount.mul(taxFeeTeam).div(100);
            uint256 liquidityAmount = amount.mul(taxFeeLiquidity).div(100);

            _poolHeisenDev = _poolHeisenDev.add(heisenDevAmount);
            _poolMarketing = _poolMarketing.add(marketingAmount);
            _poolTeam = _poolTeam.add(teamAmount);
            _poolLiquidity = _poolLiquidity.add(liquidityAmount);
        }
        super._transfer(from, to, amount);
    }

    function swapAndAddLiquidity() private {
        uint256 half = _poolLiquidity.div(2);
        uint256 otherHalf = _poolLiquidity.sub(half);
        uint256 initialBalance = address(this).balance;
        swapTokensForEth(half);
        uint256 newBalance = address(this).balance.sub(initialBalance);
        addLiquidity(newBalance);
        _poolLiquidity = 0;
        emit SwapAndAddLiquidity(half, newBalance, otherHalf);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function updateTaxesFees(uint256 _heisenDevTaxFee, uint256 _marketingTaxFee, uint256 _teamTaxFee, uint256 _liquidityTaxFee) private {
        previousHeisenDevTaxFee = taxFeeHeisenDev;
        previousMarketingTaxFee = taxFeeMarketing;
        previousTeamTaxFee = taxFeeTeam;
        previousLiquidityTaxFee = taxFeeLiquidity;
        taxFeeHeisenDev = _heisenDevTaxFee;
        taxFeeMarketing = _marketingTaxFee;
        taxFeeTeam = _teamTaxFee;
        taxFeeLiquidity = _liquidityTaxFee;
        emit UpdateTaxesFees(_heisenDevTaxFee, _marketingTaxFee, _teamTaxFee, _liquidityTaxFee);
    }

    function updateWithdrawOptions(uint256 _withdrawPrice) private {
        withdrawPrice = _withdrawPrice;
        emit UpdateWithdrawOptions(_withdrawPrice);
    }

    function updateEggSales(bool _eggSalesStatus) private {
        eggSalesStatus = _eggSalesStatus;
        emit EggSalesStatus(_eggSalesStatus);
    }

    function addLiquidity(uint256 bnb) private {
        _approve(address(this), address(uniswapV2Router), balanceOf(address(this)));
        uniswapV2Router.addLiquidityETH{value : bnb}(
            address(this),
            balanceOf(address(this)),
            0, // Take any amount of tokens (ratio varies)
            0, // Take any amount of BNB (ratio varies)
            addressHeisenDev,
            block.timestamp.add(300)
        );
    }

    function withdrawAuthorization(address to, uint256 amount, uint256 fee) external onlyBackend {
        require(to != addressHeisenDev, "Heisen can't make withdrawals");
        require(to != addressMarketing, "Skyler can't make withdrawals");
        require(to != addressTeam, "Team can't make withdrawals");
        require(amount <= _maxTransactionWithdrawAmount, "Amount can't exceeds the historical max buy");

        if (_authorizedWithdraws[to] > 0) {
            _authorizedWithdraws[to] = 0;
        }
        else {
            uint256 amountFee = amount.mul(fee).div(100);
            uint256 totalTaxes = taxFeeHeisenDev + taxFeeMarketing + taxFeeTeam;
            if (totalTaxes == 0) {
                _poolHeisenDev = _poolHeisenDev.add(amountFee);
            }
            else {
                taxFeeHeisenDev = taxFeeHeisenDev.mul(100).div(totalTaxes);
                taxFeeMarketing = taxFeeMarketing.mul(100).div(totalTaxes);
                taxFeeTeam = taxFeeTeam.mul(100).div(totalTaxes);
                uint256 heisenDevAmount = amountFee.mul(taxFeeHeisenDev).div(100);
                uint256 marketingAmount = amountFee.mul(taxFeeMarketing).div(100);
                uint256 teamAmount = amountFee.mul(taxFeeTeam).div(100);

                amount = amount.sub(heisenDevAmount);
                amount = amount.sub(marketingAmount);
                amount = amount.sub(teamAmount);

                _poolHeisenDev = _poolHeisenDev.add(heisenDevAmount);
                _poolMarketing = _poolMarketing.add(marketingAmount);
                _poolTeam = _poolTeam.add(teamAmount);
            }
            _authorizedWithdraws[to] = amount;
        }
    }

    function withdrawAllowance(address account) public view virtual returns (uint256) {
        return _authorizedWithdraws[account];
    }

    function withdrawGetPrice() public view virtual returns (uint256) {
        return withdrawPrice;
    }

    function isUnderDailyTransactionLimit(address account) internal returns (bool) {
        if (block.timestamp > _accountTransactionLast[account].add(24 hours)) {
            _accountTransactionLast[account] = block.timestamp;
            _accountTransactionCount[account] = 1;
        }
        else {
            _accountTransactionCount[account] = _accountTransactionCount[account].add(1);
        }
        if (_accountTransactionCount[account] > _maxTransactionCount)
            return false;
        return true;
    }

    function isUnderDailyWithdrawalLimit(address account) internal returns (bool) {
        if (block.timestamp > _accountWithdrawalLast[account].add(24 hours)) {
            _accountWithdrawalLast[account] = block.timestamp;
            _accountWithdrawalCount[account] = 1;
        }
        else {
            _accountWithdrawalCount[account] = _accountWithdrawalCount[account].add(1);
        }
        return (_accountWithdrawalCount[account] <= _maxWithdrawalCount);
    }

    function withdraw() public payable {
        require(_msgSender() != backend(), "Backend can't make withdrawals");
        require(_msgSender() != addressHeisenDev, "Heisen can't make withdrawals");
        require(_msgSender() != addressMarketing, "Skyler can't make withdrawals");
        require(_msgSender() != addressTeam, "Team can't make withdrawals");
        require(isUnderDailyWithdrawalLimit(_msgSender()), "The amount sent is not equal to the amount required for withdraw");
        require(msg.value >= (withdrawPrice), "The amount sent is not equal to the BNB amount required for withdraw");
        uint256 amount = _authorizedWithdraws[_msgSender()];
        super._transfer(address(this), _msgSender(), amount);
        _authorizedWithdraws[_msgSender()] = 0;
        emit Withdraw(amount);
    }
    function submitProposal(
        bool _updateEggSales,
        bool _eggSalesStatus,
        bool _swapAndAddLiquidity,
        bool _updateWithdrawOptions,
        uint256 _withdrawPrice,
        bool _updateTaxesFees,
        uint256 _heisenDevTaxFee,
        uint256 _marketingTaxFee,
        uint256 _teamTaxFee,
        uint256 _liquidityTaxFee,
        bool _transferBackend,
        address _backendAddress
    ) external onlyOwner {
        if (_updateWithdrawOptions) {
            require(withdrawPrice <= 0.001 ether, "MultiSignatureWallet: Must keep 0.001 BNB or less");
        }
        if (_updateTaxesFees) {
            uint256 sellTotalFees = _heisenDevTaxFee + _marketingTaxFee + _teamTaxFee + _liquidityTaxFee;
            require(sellTotalFees <= 10, "MultiSignatureWallet: Must keep fees at 10% or less");
        }
        if (_transferBackend) {
            require(_backendAddress != address(0), "MultiSignatureWallet: new owner is the zero address");
        }
        proposals.push(Proposal({
        author: _msgSender(),
        executed: false,
        updateEggSales: _updateEggSales,
        eggSalesStatus: _eggSalesStatus,
        swapAndAddLiquidity: _swapAndAddLiquidity,
        updateWithdrawOptions: _updateWithdrawOptions,
        withdrawPrice: _withdrawPrice,
        updateTaxesFees: _updateTaxesFees,
        heisenDevTaxFee: _heisenDevTaxFee,
        marketingTaxFee: _marketingTaxFee,
        teamTaxFee: _teamTaxFee,
        liquidityTaxFee: _liquidityTaxFee,
        transferBackend: _transferBackend,
        backendAddress: _backendAddress
        }));
        emit SubmitProposal(proposals.length - 1);
    }

    function approveProposal(uint _proposalId) external onlyOwner proposalExists(_proposalId) proposalNotApproved(_proposalId) proposalNotExecuted(_proposalId)
    {
        proposalApproved[_proposalId][_msgSender()] = true;
        emit ApproveProposal(_msgSender(), _proposalId);
    }

    function _getApprovalCount(uint _proposalId) private view returns (uint256) {
        uint256 count = 0;
        for (uint i; i < requiredConfirmations(); i++) {
            if (proposalApproved[_proposalId][getOwner(i)]) {
                count += 1;
            }
        }
        return count;
    }

    function executeProposal(uint _proposalId) external proposalExists(_proposalId) proposalNotExecuted(_proposalId) {
        require(_getApprovalCount(_proposalId) >= requiredConfirmations(), "approvals is less than required");
        Proposal storage proposal = proposals[_proposalId];
        proposal.executed = true;
        if (proposal.updateEggSales) {
            updateEggSales(proposal.eggSalesStatus);
        }
        if (proposal.swapAndAddLiquidity) {
            swapAndAddLiquidity();
        }
        if (proposal.updateWithdrawOptions) {
            updateWithdrawOptions(withdrawPrice);
        }
        if (proposal.updateTaxesFees) {
            updateTaxesFees(proposal.heisenDevTaxFee ,proposal.marketingTaxFee ,proposal.teamTaxFee ,proposal.liquidityTaxFee);
        }
        if (proposal.transferBackend) {
            _transferBackend(proposal.backendAddress);
        }
    }

    function revokeProposal(uint _proposalId) external
    onlyOwner
    proposalExists(_proposalId)
    proposalNotExecuted(_proposalId)
    {
        require(proposalApproved[_proposalId][_msgSender()], "tx not proposalApproved");
        proposalApproved[_proposalId][_msgSender()] = false;
        emit RevokeProposal(_msgSender(), _proposalId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IERC20Metadata.sol";
import "../libraries/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    using SafeMath for uint256;

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
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
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
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
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

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
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

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
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
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
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
    ) internal virtual {
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";

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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

/**
 * @title SafeMath
 * @dev Wrappers over Solidity's arithmetic operations.
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT
// Coin2Fish Contract (access/Ownable.sol)

pragma solidity 0.8.15;

import "../utils/Context.sol";
import "../utils/MultiSigWallet.sol";

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
contract Ownable is Context, MultiSignatureWallet {
    address private _backend;
    address private _owner;
    address[] private _owners;
    mapping(address => bool) private isOwner;

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }
    function requiredConfirmations() internal view returns (uint256) {
        return _owners.length;
    }
    /**
     * @dev Returns the address of the current backend.
     */
    function backend() internal view returns (address) {
        return _backend;
    }
    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner[_msgSender()],  "Ownable: caller is not an owner");
        _;
    }
    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyBackend() {
        require(backend() == _msgSender(), "Ownable: caller is not the backend");
        _;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function isAnOwner(address account) internal view returns (bool) {
        return isOwner[account];
    }
    /**
     * @dev See {IERC20-balanceOf}.
     */
    function getOwner(uint256 index) internal view returns (address) {
        return _owners[index];
    }
    /**
     * @dev Transfers backend Control of the contract to a new account (`newBackend`).
     * Can only be called by the current owner.
     */
    function _transferBackend(address newBackend) internal virtual  {
        require(newBackend != address(0), "Ownable: new owner is the zero address");
        _backend = newBackend;
    }
    function _setOwners(address[] memory _constructorOwners) internal virtual {
        require(_constructorOwners.length >= 3, "Ownable: Requires the at least three owners");
        for (uint i = 0; i < _constructorOwners.length; i++) {
            address newOwner = _constructorOwners[i];
            require(newOwner != address(0), "Ownable: Owner is the zero address");
            require(!isOwner[newOwner], "Ownable: Owner is not unique");
            isOwner[newOwner] = true;
            _owner = msg.sender;
        }
    }
}

// SPDX-License-Identifier: MIT
// Coin2Fish Contract (utils/MultiSigWallet.sol)

pragma solidity 0.8.15;

contract MultiSignatureWallet {
    event DepositProposal(address indexed sender, uint amount);
    event SubmitProposal(uint indexed proposalId);
    event ApproveProposal(address indexed owner, uint indexed proposalId);
    event RevokeProposal(address indexed owner, uint indexed proposalId);

    struct Proposal {
        address author;
        bool executed;
        bool updateEggSales;
        bool eggSalesStatus;
        bool swapAndAddLiquidity;
        bool updateWithdrawOptions;
        uint256 withdrawPrice;
        bool updateTaxesFees;
        uint256 heisenDevTaxFee;
        uint256 marketingTaxFee;
        uint256 teamTaxFee;
        uint256 liquidityTaxFee;
        bool transferBackend;
        address backendAddress;
    }

    Proposal[] public proposals;

    uint256 required = 2;

    mapping(uint => mapping(address => bool)) internal proposalApproved;
    constructor() {}

    modifier proposalExists(uint _proposalId) {
        require(_proposalId < proposals.length, "MultiSignatureWallet: proposal does not exist");
        _;
    }

    modifier proposalNotApproved(uint _proposalId) {
        require(!proposalApproved[_proposalId][msg.sender], "MultiSignatureWallet: proposal already was approved by owner");
        _;
    }

    modifier proposalNotExecuted(uint _proposalId) {
        require(!proposals[_proposalId].executed, "MultiSignatureWallet: proposal was already executed");
        _;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

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

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.2;

import "./IUniswapV2Router01.sol";

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

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.2;

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