// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "../Libraries/LibraryListAddress.sol";
import "../Interfaces/IERC20.sol";
import "../Interfaces/IUniswap.sol";
import "../Interfaces/IAgent.sol";

contract MORE is IERC20 {
    using ListAddress for ListAddress.ListStruct;

    string public constant symbol = "MORE";
    string public constant name = "Mythic Ore";
    uint256 private constant __decimals = 18;

    uint256 private __totalSupply = MAX_SUPPLY;

    mapping(address => uint256) private __balanceOf;
    mapping(address => mapping(address => uint256)) private __allowances;

    uint256 private constant ONE = 10**__decimals;

    // used to pack mulitple pots into 256 bits, thus lowering gas fees
    uint256 private constant TOKEN_POTS_DIVISOR = 10**(__decimals - 3);

    // max supply can be safely stored in uint96+, it will be used for gas optimizations
    uint256 public constant MAX_SUPPLY = 100000000 * ONE;

    // max possible total tax is 10% on any transfer
    uint256 public constant TAX_MAX = 1000;
    uint256 private constant DENOMINATOR = 10000;

    address private constant BURN_ADDRESS =
        0x000000000000000000000000000000000000dEaD;
    // @@@ TESTNET 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd MAINNET 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c
    address private constant WBNB = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
    // @@@ TESTNET 0xD99D1c33F9fC3444f8101754aBC46c52416550D1 MAINNET 0x10ED43C718714eb63d5aA57B78B54704E256024E
    address private constant ROUTER_ADDRESS =
        0xD99D1c33F9fC3444f8101754aBC46c52416550D1;

    struct ModifiersData {
        uint32 isSellAddress;
        uint32 isExcludedFromTax;
        uint32 isExcludedFromMaxAccountRule;
        uint32 buyTaxReduction;
        uint32 sellTaxReduction;
        uint32 reflectionsMultiplier;
        uint64 oldMultiplierBalance;
    }
    mapping(address => ModifiersData) public Modifiers;

    struct ReflectionsData {
        uint32 currentCompoundingIndex;
        uint32 potPartToDistribute;
        uint32 prevDelay;
        uint32 delay;
        uint32 periodEnd;
        uint32 lastUpdateTime;
        uint64 maxMultiplier;
        uint64 totalBalances;
        uint96 rate;
        uint96 pot;
        uint256 perShareStored;
    }
    ReflectionsData public reflections;

    mapping(address => uint256) private ReflectionsPerSharePaid;
    mapping(address => uint256) public TotalReflected;

    ListAddress.ListStruct private Shareholders;
    ListAddress.ListStruct private AuthorizedContracts;

    mapping(uint256 => uint256) public MaxCompoundingIterations;

    uint256 public minGasForWorkOnSale;
    uint256 public minGasForWorkOnBuy;

    struct TaxData {
        uint32 total;
        uint32 reflections;
        uint32 liquidity;
        uint32 team;
        uint32 referrer;
    }
    mapping(uint256 => TaxData) private Taxes;

    // it is safe to make token pots in 40 bits as only 3 decimals are counted
    // (2**40 - 1) / 10 ** 3 is more than MAX_SUPPLY
    // amount that is left is going to uint128 reflections pot
    struct PotsDataToken {
        uint40 liquidity;
        uint40 buy;
        uint40 sell;
        uint40 transfer;
        uint40 referrer;
        uint56 team;
    }
    PotsDataToken public tokenPots;

    uint256 public tokenLiquidityReserves;
    uint256 public liquidityFromFeesUnlockTime;

    // uint80 pot can hold 1208925 BNB, it is reasonable to assume that overflow is impossible
    // even if it happens (in my dreams), overflowed amount is recoverable
    struct PotsDataBNB {
        uint80 liquidity;
        uint80 buy;
        uint96 sell;
        uint80 transfer;
        uint80 referrer;
        uint96 team;
    }
    PotsDataBNB public potsBNB;

    struct ReferrerSystemData {
        uint16 isDefaultReferrer;
        uint16 currentRefferalTaxReduction;
        uint16 referralTaxReduction;
        uint16 nextSellTaxReduction;
        uint96 lastReferrerTokensAmount;
        uint96 tokensUsedForReferrersPot;
    }
    ReferrerSystemData public referrerSystemData;

    // first 4 amounts here are stored with only 3 decimals
    struct WorkAmountsData {
        uint32 agentBNB; // min amount of BNB for sending to an Agent
        uint32 liquidityBNB; // min amount of BNB to add to liquidity
        uint32 tokensMin; // min tokens for liquidity or to be swapped for BNB
        uint32 tokensMax; // max tokens amount to swap for BNB in one tx
        uint32 launchedTime; // stored here to pack all in one storage slot
        uint96 maxAccount; // untaxed transactions ignore max account rule
    }
    WorkAmountsData public workAmounts;

    IUniswapV2Router02 private SwapRouter;

    address public SwapAgent;
    address public MainAccount;
    IAgent public Agent;

    ///////////////////////////////////////////////////////////////

    modifier onlyMain() {
        _onlyMain();
        _;
    }

    modifier onlyAuthorized() {
        _onlyAuthorized();
        _;
    }

    modifier onlySwap() {
        _onlySwap();
        _;
    }

    modifier flagCheck(uint256 flag) {
        _flagCheck(flag);
        _;
    }

    function _onlyMain() private view {
        require(msg.sender == MainAccount, "onlyMain");
    }

    function _onlyAuthorized() private view {
        require(
            AuthorizedContracts.ItemToIndex[msg.sender] > 0,
            "onlyAuthorized"
        );
    }

    function _onlySwap() private view {
        require(msg.sender == SwapAgent, "onlySwap");
    }

    function _flagCheck(uint256 flag) private pure {
        require(flag < 2, "flagCheck");
    }

    ///////////////////////////////////////////////////////////////

    // some initialization needs to be made via external calls
    // this helps to reduce contract's bytecode and compile with more optimizer runs
    constructor() {
        MainAccount = msg.sender;

        __balanceOf[MainAccount] = __totalSupply;
        emit Transfer(address(0), MainAccount, __totalSupply);

        SwapRouter = IUniswapV2Router02(ROUTER_ADDRESS);
        Modifiers[ROUTER_ADDRESS].isExcludedFromMaxAccountRule = 1;

        address swapPairAddress = IUniswapV2Factory(SwapRouter.factory())
            .createPair(address(this), WBNB);
        Modifiers[swapPairAddress].isSellAddress = 1;

        __allowances[address(this)][ROUTER_ADDRESS] = MAX_SUPPLY;

        Modifiers[MainAccount].isExcludedFromTax = 1;
        Modifiers[address(this)].isExcludedFromTax = 1;
        Modifiers[BURN_ADDRESS].isExcludedFromTax = 1;

        // initially locked for two weeks, and will be extended right after launch if there are no issues
        // this does not affect main liquidity and only works on additional liquidity from tax
        liquidityFromFeesUnlockTime = block.timestamp + 86400 * 14;

        // setting initial values to 1 and keeping them non-zero to make gas usage more stable
        // so when pots are emptied, 1 is always left, and when pot value is used, 1 is always substracted
        tokenPots.liquidity = 1;

        potsBNB.buy = 1;
        potsBNB.transfer = 1;

        workAmounts.maxAccount = uint96(750000 * ONE);
    }

    ///////////////////////////////////////////////////////////////

    receive() external payable {}

    ///////////////////////////////////////////////////////////////

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external override returns (bool) {
        require(
            value > 0 && __allowances[from][msg.sender] >= value,
            "transferFrom0"
        );

        return handleTransfer(from, to, value);
    }

    function transfer(address to, uint256 value)
        external
        override
        returns (bool)
    {
        require(value > 0, "transfer0");

        return handleTransfer(msg.sender, to, value);
    }

    // cheaper transferFrom implementation only for authorized addresses
    // still checks allowance, but skips reflections updates for receiver
    // also no tax applied and no modifiers checked
    function lightningTransfer(address sender, uint256 amount)
        external
        onlyAuthorized
    {
        uint32 senderReflectionsMultiplier = Modifiers[sender]
            .reflectionsMultiplier;
        if (senderReflectionsMultiplier > 0) {
            updateReflections(sender);
        }

        require(
            __allowances[sender][msg.sender] >= amount &&
                __balanceOf[sender] >= amount,
            "shock"
        );

        unchecked {
            __balanceOf[sender] -= amount;
            __balanceOf[msg.sender] += amount;

            emit Transfer(sender, msg.sender, amount);
        }

        if (senderReflectionsMultiplier > 0) {
            updateMultiplierBalances(sender);
        }
    }

    function prepareReferralSwap(
        address initiator,
        uint32 isSell,
        uint16 isDefaultReferrer
    ) external onlySwap returns (uint32, uint16) {
        if (isSell == 1) {
            referrerSystemData.nextSellTaxReduction = uint16(
                Modifiers[initiator].sellTaxReduction
            );
        }

        uint16 _currentRefferalTaxReduction = referrerSystemData
            .currentRefferalTaxReduction;

        referrerSystemData.currentRefferalTaxReduction = referrerSystemData
            .referralTaxReduction;
        referrerSystemData.isDefaultReferrer = isDefaultReferrer;

        return (
            Modifiers[initiator].isExcludedFromTax,
            _currentRefferalTaxReduction
        );
    }

    function approve(address spender, uint256 value)
        external
        override
        returns (bool success)
    {
        __allowances[msg.sender][spender] = value;

        emit Approval(msg.sender, spender, value);

        return true;
    }

    function setModifiers(
        address account1,
        address account2,
        uint32 reflectionsMultiplier,
        uint32 buyDiscount1,
        uint32 sellDiscount1,
        uint32 buyDiscount2,
        uint32 sellDiscount2
    ) external onlyAuthorized {
        if (reflectionsMultiplier > 0) {
            _addMultiplier(account1, reflectionsMultiplier, 0);
            _addMultiplier(account2, reflectionsMultiplier, 1);
        }

        _setBuyTaxReduction(account1, buyDiscount1);
        _setBuyTaxReduction(account2, buyDiscount2);

        _setSellTaxReduction(account1, sellDiscount1);
        _setSellTaxReduction(account2, sellDiscount2);
    }

    function setModifiers(
        address account,
        uint32 reflectionsMultiplier,
        uint32 isAddition,
        uint32 buyDiscount,
        uint32 sellDiscount
    ) external onlyAuthorized {
        if (reflectionsMultiplier > 0) {
            _addMultiplier(account, reflectionsMultiplier, isAddition);
        }

        _setBuyTaxReduction(account, buyDiscount);

        _setSellTaxReduction(account, sellDiscount);
    }

    function addMultiplier(
        address account,
        uint32 difference,
        uint32 isAddition
    ) external onlyAuthorized {
        _addMultiplier(account, difference, isAddition);
    }

    function setBuyTaxReduction(address account, uint32 value)
        external
        onlyAuthorized
    {
        _setBuyTaxReduction(account, value);
    }

    function setSellTaxReduction(address account, uint32 value)
        external
        onlyAuthorized
    {
        _setSellTaxReduction(account, value);
    }

    function addTokensToLiquidityReservesFromContract(uint256 amount)
        external
        onlyAuthorized
    {
        require(getFreeTokens() >= amount);

        tokenLiquidityReserves += amount;
    }

    function addBNBToLiquidityPot() external payable {
        potsBNB.liquidity += uint80(msg.value);
    }

    function buybackAndBurn() external payable {
        _transfer(
            address(this),
            BURN_ADDRESS,
            swapBNBForTokens(msg.value),
            0,
            999
        );
    }

    function buybackAndLockToLiquidity() external payable {
        potsBNB.liquidity += uint80(msg.value - msg.value / 2);
        tokenLiquidityReserves += swapBNBForTokens(msg.value / 2);

        addLiquidityFromTokenReserves();
    }

    function addAuthorized(address contractAddress) external onlyMain {
        AuthorizedContracts.add(contractAddress);
    }

    function removeAuthorized(address contractAddress) external onlyMain {
        AuthorizedContracts.remove(contractAddress);
    }

    function lockLiquidityFromFees(uint256 additionalTime) external onlyMain {
        liquidityFromFeesUnlockTime += additionalTime;
    }

    // when liquidity gathered from tax and other fees is unlocked, it can be collected
    // might be helpful in case of liquidity migration
    // this function cannot remove initial liquidity
    function withdrawLiquidityFromFees(address liquidityPairAddress)
        external
        onlyMain
    {
        require(block.timestamp > liquidityFromFeesUnlockTime);

        IERC20(liquidityPairAddress).approve(ROUTER_ADDRESS, MAX_SUPPLY);
        Modifiers[ROUTER_ADDRESS].isExcludedFromTax = 1;

        SwapRouter.removeLiquidityETH(
            address(this),
            IERC20(liquidityPairAddress).balanceOf(address(this)),
            0,
            0,
            msg.sender,
            block.timestamp
        );

        Modifiers[ROUTER_ADDRESS].isExcludedFromTax = 0;
    }

    function toggleSellAddress(address account, uint32 flag)
        external
        onlyMain
        flagCheck(flag)
    {
        Modifiers[account].isSellAddress = flag;
    }

    // 0 - not exclueded, 1 - excluded
    // 2 - excluded when sender, 3 - excluded when receiver
    function toggleAccountTaxExclusion(address account, uint32 exclusionType)
        external
        onlyMain
    {
        require(account != MainAccount && exclusionType < 4);
        Modifiers[account].isExcludedFromTax = exclusionType;
    }

    function toggleAccountMaxAccountRuleExclusion(address account, uint32 flag)
        external
        onlyMain
        flagCheck(flag)
    {
        Modifiers[account].isExcludedFromMaxAccountRule = flag;
    }

    function setReferralTaxReduction(uint16 newReferralTaxReduction)
        external
        onlyMain
    {
        require(newReferralTaxReduction < 101);

        referrerSystemData.referralTaxReduction = newReferralTaxReduction;
    }

    function setMaxAccountAndMaxMultiplier(
        uint96 newMaxAccount,
        uint64 newMaxMultiplier
    ) external onlyMain {
        require(
            newMaxAccount >= MAX_SUPPLY / 1000 &&
                newMaxMultiplier >= 300 &&
                newMaxMultiplier <= 999999
        );

        workAmounts.maxAccount = newMaxAccount;
        reflections.maxMultiplier = newMaxMultiplier;
    }

    function setReflectionsDelayAndDistributingPart(
        uint32 newDelayInSeconds,
        uint32 newPotPartToDistribute
    ) external onlyMain {
        require(
            newDelayInSeconds > 0 &&
                newDelayInSeconds < 604801 &&
                newPotPartToDistribute > 0 &&
                newPotPartToDistribute < DENOMINATOR
        );

        reflections.delay = newDelayInSeconds;
        reflections.potPartToDistribute = newPotPartToDistribute;
    }

    function setMaxCompoundingIterations(uint256 index, uint256 newValue)
        external
        onlyMain
    {
        require(newValue < 9);

        MaxCompoundingIterations[index] = newValue;
    }

    function setMinGasForWork(uint256 newValueOnSale, uint256 newValueOnBuy)
        external
        onlyMain
    {
        require(newValueOnSale < 600001 && newValueOnBuy < 600001);

        minGasForWorkOnSale = newValueOnSale;
        minGasForWorkOnBuy = newValueOnBuy;
    }

    function setTax(
        uint256 txType,
        uint32 newTotalTax,
        uint32 newTaxReflections,
        uint32 newTaxLiquidity,
        uint32 newTeamTax,
        uint32 newReferrerTax
    ) external onlyMain {
        require(
            (newTotalTax <= TAX_MAX &&
                newTaxReflections + newTaxLiquidity <= newTotalTax) &&
                (newTeamTax + newReferrerTax <=
                    newTotalTax - newTaxReflections - newTaxLiquidity)
        );

        Taxes[txType].total = newTotalTax;
        Taxes[txType].reflections = newTaxReflections;
        Taxes[txType].liquidity = newTaxLiquidity;

        // these taxes are not adding up to the total directly and are a part of an Agent tax
        Taxes[txType].team = newTeamTax;
        Taxes[txType].referrer = newReferrerTax;
    }

    // only 3 decimals are counted
    function setWorkAmounts(
        uint32 agentBNB,
        uint32 liquidityBNB,
        uint32 tokensMin,
        uint32 tokensMax
    ) external onlyMain {
        require(
            liquidityBNB < 10 * 1000 &&
                tokensMin < 100000 * 1000 &&
                tokensMin <= tokensMax &&
                tokensMax > 100000 &&
                tokensMax >= tokensMin
        );

        workAmounts.agentBNB = agentBNB;
        workAmounts.liquidityBNB = liquidityBNB;
        workAmounts.tokensMin = tokensMin;
        workAmounts.tokensMax = tokensMax;
    }

    function setMainAccount(address newAccount, uint256 safetyCode)
        external
        onlyMain
    {
        // safety check so this function won't be called accidentely
        require(safetyCode == 9753124680864213579);

        MainAccount = newAccount;
    }

    function setAgents(address newAgent, address newSwapAgent)
        external
        onlyMain
    {
        AuthorizedContracts.remove(address(Agent));
        AuthorizedContracts.remove(address(SwapAgent));

        AuthorizedContracts.add(address(newAgent));
        AuthorizedContracts.add(address(newSwapAgent));

        __allowances[SwapAgent][ROUTER_ADDRESS] = 0;
        __allowances[newSwapAgent][ROUTER_ADDRESS] = MAX_SUPPLY;

        Agent = IAgent(newAgent);
        SwapAgent = newSwapAgent;
    }

    function setAgents1(address newAgent, address newSwapAgent)
        external
        onlyMain
    {
        AuthorizedContracts.remove(address(Agent));
    }

    function setAgents2(address newAgent, address newSwapAgent)
        external
        onlyMain
    {
        AuthorizedContracts.remove(address(Agent));
        AuthorizedContracts.remove(address(SwapAgent));
    }

    function setAgents3(address newAgent, address newSwapAgent)
        external
        onlyMain
    {
        AuthorizedContracts.remove(address(Agent));
        AuthorizedContracts.remove(address(SwapAgent));

        AuthorizedContracts.add(address(newAgent));
    }

    function setAgents4(address newAgent, address newSwapAgent)
        external
        onlyMain
    {
        AuthorizedContracts.remove(address(Agent));
        AuthorizedContracts.remove(address(SwapAgent));

        AuthorizedContracts.add(address(newAgent));
        AuthorizedContracts.add(address(newSwapAgent));

        __allowances[SwapAgent][ROUTER_ADDRESS] = 0;
        __allowances[newSwapAgent][ROUTER_ADDRESS] = MAX_SUPPLY;
    }

    function setAgents5(address newAgent, address newSwapAgent)
        external
        onlyMain
    {
        AuthorizedContracts.remove(address(Agent));
        AuthorizedContracts.remove(address(SwapAgent));

        AuthorizedContracts.add(address(newAgent));
        AuthorizedContracts.add(address(newSwapAgent));

        __allowances[SwapAgent][ROUTER_ADDRESS] = 0;
        __allowances[newSwapAgent][ROUTER_ADDRESS] = MAX_SUPPLY;

        Agent = IAgent(newAgent);
        SwapAgent = newSwapAgent;
    }

    function addToReflectionsFromContract(uint256 amount)
        external
        onlyAuthorized
    {
        require(getFreeTokens() >= amount);

        unchecked {
            __balanceOf[address(this)] -= amount;
        }

        calculateReflections(amount);
    }

    function withdrawFreeBNB() external onlyMain {
        (bool success, ) = msg.sender.call{value: getFreeBNB()}("");

        require(success);
    }

    function withdrawFreeTokens(address tokenContract) external onlyMain {
        if (tokenContract != address(this)) {
            uint256 balance = IERC20(tokenContract).balanceOf(address(this));

            require(balance > 0, "WFT0");

            IERC20(tokenContract).transfer(msg.sender, balance);
        } else {
            uint256 freeTokens = getFreeTokens();

            require(freeTokens > 0, "WFT1");

            _transfer(address(this), msg.sender, freeTokens, 0, 999);
        }
    }

    function launchToken() external onlyMain {
        require(
            workAmounts.launchedTime == 0 &&
                address(Agent) != address(0) &&
                address(SwapAgent) != address(0)
        );

        workAmounts.launchedTime = uint32(block.timestamp);
    }

    function balanceOf(address account)
        external
        view
        override
        returns (uint256)
    {
        return __balanceOf[account] + reflected(account);
    }

    function rawBalanceOf(address account) external view returns (uint256) {
        return __balanceOf[account];
    }

    function lastReferrerTokensAmount() external view returns (uint96) {
        return referrerSystemData.lastReferrerTokensAmount;
    }

    function getModifiers(address account1, address account2)
        external
        view
        returns (
            uint32,
            uint32,
            uint32,
            uint32
        )
    {
        return (
            Modifiers[account1].buyTaxReduction,
            Modifiers[account1].sellTaxReduction,
            Modifiers[account2].buyTaxReduction,
            Modifiers[account2].sellTaxReduction
        );
    }

    function getModifiers(address account)
        external
        view
        returns (uint32, uint32)
    {
        return (
            Modifiers[account].buyTaxReduction,
            Modifiers[account].sellTaxReduction
        );
    }

    function isAuthorized(address account) external view returns (uint256) {
        return AuthorizedContracts.ItemToIndex[account];
    }

    function allowance(address owner, address spender)
        external
        view
        override
        returns (uint256 remaining)
    {
        return __allowances[owner][spender];
    }

    function totalSupply() external view override returns (uint256) {
        return __totalSupply;
    }

    function circulatingSupply() external view returns (uint256) {
        return __totalSupply - __balanceOf[BURN_ADDRESS];
    }

    function viewTaxes()
        external
        view
        returns (
            TaxData memory,
            TaxData memory,
            TaxData memory
        )
    {
        return (Taxes[0], Taxes[1], Taxes[2]);
    }

    function viewShareholders() external view returns (address[] memory) {
        return Shareholders.Array;
    }

    function viewAuthorized() external view returns (address[] memory) {
        return AuthorizedContracts.Array;
    }

    function decimals() external pure override returns (uint8) {
        return uint8(__decimals);
    }

    ///////////////////////////////////////////////////////////////

    // amount of work that can be performed is restricted
    // roughly 500000 gas is enough to sell, but in practice the amount will be lower
    function doWork() public {
        WorkAmountsData storage _workAmounts = workAmounts;
        if (Modifiers[msg.sender].isSellAddress == 0) {
            unchecked {
                uint256 agentPotToSend = getBNBPotsSumWithoutLiquidity();
                if (gasleft() > minGasForWorkOnSale) {
                    if (
                        agentPotToSend >
                        _workAmounts.agentBNB * TOKEN_POTS_DIVISOR
                    ) {
                        deliverBNBToAgent(agentPotToSend);
                        autoCompound(MaxCompoundingIterations[0]);
                    } else {
                        if (
                            potsBNB.liquidity >
                            _workAmounts.liquidityBNB * TOKEN_POTS_DIVISOR
                        ) {
                            if (
                                tokenLiquidityReserves >
                                _workAmounts.tokensMin * TOKEN_POTS_DIVISOR
                            ) {
                                addLiquidityFromTokenReserves();
                            } else {
                                refillLiquidityTokenReserves();
                                autoCompound(MaxCompoundingIterations[1]);
                            }
                        } else {
                            uint256 totalTokens = getCompressedTokenPotsSum();
                            if (totalTokens > _workAmounts.tokensMin) {
                                swapTaxTokensForBNB(totalTokens);
                            } else {
                                autoCompound(MaxCompoundingIterations[2]);
                            }
                        }
                    }
                } else {
                    doExcessiveWork(minGasForWorkOnSale);
                }
            }
        } else {
            if (gasleft() > minGasForWorkOnBuy) {
                if (referrerSystemData.currentRefferalTaxReduction > 0) {
                    autoCompound(MaxCompoundingIterations[3]);
                } else {
                    autoCompound(MaxCompoundingIterations[4]);
                }
            } else {
                doExcessiveWork(minGasForWorkOnBuy);
            }
        }
    }

    // used to overestimate gas needed for the transaction to complete
    // this function always uses the same amount of gas with the same input given
    // so wallet estimates the amount needed to complete this function first
    // but then in doWork() actual work is going be done cause there would be enough gas for it
    // this way its not necessary to use require() or perform a gas check in each iteration of autoCompound()
    function doExcessiveWork(uint256 gas) private pure returns (uint256) {
        gas += 10000;
        unchecked {
            while (gas > 51) {
                gas -= 51;
            }
        }

        return gas;
    }

    function autoCompound(uint256 maxIterations) public {
        uint256 length = Shareholders.Array.length;
        if (length < 2) {
            return;
        }

        uint256 currentIndex = reflections.currentCompoundingIndex;
        uint256 iterations = 0;

        reflections.perShareStored = reflectionsPerShare();
        reflections.lastUpdateTime = lastTimeReflectionsApplicable();

        while (iterations < maxIterations) {
            address account = Shareholders.Array[currentIndex];

            payReflections(account, reflections.perShareStored);
            updateMultiplierBalances(account);

            unchecked {
                ++currentIndex;
                ++iterations;

                if (currentIndex == length) {
                    currentIndex = 1;
                }
            }
        }

        reflections.currentCompoundingIndex = uint32(currentIndex);
    }

    function compoundReflections(address account) public {
        updateReflections(account);
        updateMultiplierBalances(account);
    }

    function reflected(address account) public view returns (uint256) {
        unchecked {
            return
                (Modifiers[account].oldMultiplierBalance *
                    (reflectionsPerShare() -
                        ReflectionsPerSharePaid[account])) / ONE;
        }
    }

    function reflected(address account, uint256 perShareStored)
        private
        view
        returns (uint256)
    {
        unchecked {
            return
                (Modifiers[account].oldMultiplierBalance *
                    (perShareStored - ReflectionsPerSharePaid[account])) / ONE;
        }
    }

    function getFreeTokens() public view returns (uint256) {
        unchecked {
            return
                __balanceOf[address(this)] -
                getCompressedTokenPotsSum() *
                TOKEN_POTS_DIVISOR -
                tokenLiquidityReserves;
        }
    }

    function getFreeBNB() public view returns (uint256) {
        return address(this).balance - getBNBPotsSum();
    }

    ///////////////////////////////////////////////////////////////

    function _transfer(
        address sender,
        address recipient,
        uint256 amount,
        uint256 taxAmount,
        uint256 txType
    ) internal virtual {
        uint32 senderReflectionsMultiplier = txType == 0
            ? 0
            : Modifiers[sender].reflectionsMultiplier;
        uint32 recipientReflectionsMultiplier = txType == 1
            ? 0
            : Modifiers[recipient].reflectionsMultiplier;

        // most likely only one of these will be called, unless its a transfer between shareholders
        if (senderReflectionsMultiplier > 0) {
            updateReflections(sender);
        }
        if (recipientReflectionsMultiplier > 0) {
            updateReflections(recipient);
        }

        unchecked {
            require(
                (workAmounts.launchedTime > 0 ||
                    Modifiers[sender].isExcludedFromTax == 1) &&
                    (__balanceOf[recipient] + amount - taxAmount <=
                        workAmounts.maxAccount ||
                        Modifiers[recipient].isSellAddress == 1 ||
                        Modifiers[recipient].isExcludedFromMaxAccountRule ==
                        1 ||
                        taxAmount == 0),
                "_transfer0"
            );
        }

        unchecked {
            __balanceOf[sender] -= amount;
            __balanceOf[recipient] += amount - taxAmount;

            emit Transfer(sender, recipient, amount - taxAmount);
        }

        if (senderReflectionsMultiplier > 0) {
            updateMultiplierBalances(sender);
        }
        if (recipientReflectionsMultiplier > 0) {
            updateMultiplierBalances(recipient);
        }

        // here failed external call does not result in a reverted transaction
        // so even if execution of notifyTransferListener reverts, _transfer will not revert
        // that makes it impossible to sabotage trading by setting a wrong Agent
        if (txType == 0) {
            try Agent.notifyTransferListener(recipient) {} catch {}
        }
        if (txType == 1) {
            try Agent.notifyTransferListener(sender) {} catch {}
        } else {
            try Agent.notifyTransferListener(sender, recipient) {} catch {}
        }
    }

    ///////////////////////////////////////////////////////////////

    function handleTransfer(
        address from,
        address to,
        uint256 value
    ) private returns (bool) {
        if (
            Modifiers[from].isExcludedFromTax == 1 ||
            Modifiers[to].isExcludedFromTax == 1 ||
            Modifiers[from].isExcludedFromTax == 2 ||
            Modifiers[to].isExcludedFromTax == 3
        ) {
            transferWithoutTax(from, to, value);
        } else {
            uint256 txType;
            if (Modifiers[from].isSellAddress == 0) {
                if (Modifiers[to].isSellAddress == 1) {
                    txType = 1;
                } else {
                    txType = 2;
                }
            }

            transferWithTax(from, to, value, txType);
        }

        referrerSystemData.currentRefferalTaxReduction = 0;
        referrerSystemData.nextSellTaxReduction = 0;

        return true;
    }

    function transferWithTax(
        address sender,
        address recipient,
        uint256 amount,
        uint256 txType
    ) private {
        uint256 taxTokens;
        uint256 taxReduction = referrerSystemData.currentRefferalTaxReduction;

        unchecked {
            if (txType == 0) {
                taxReduction += Modifiers[recipient].buyTaxReduction;
            } else if (Modifiers[recipient].isSellAddress == 1) {
                if (referrerSystemData.nextSellTaxReduction > 0) {
                    taxReduction += referrerSystemData.nextSellTaxReduction;
                } else {
                    taxReduction += Modifiers[recipient].sellTaxReduction;
                }
            }

            uint256 tax;
            if (taxReduction < Taxes[txType].total) {
                tax = Taxes[txType].total - taxReduction;
            }

            taxTokens = (amount * tax) / DENOMINATOR;
        }

        doWork();

        _transfer(sender, recipient, amount, taxTokens, txType);

        notifyTaxSystem(sender, amount, taxTokens, txType);
    }

    function transferWithoutTax(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        _transfer(sender, recipient, amount, 0, 999);
    }

    function deliverBNBToAgent(uint256 agentPotToSend) private {
        uint256 buyPot = potsBNB.buy - 1;
        uint256 sellPot = potsBNB.sell;
        uint256 transferPot = potsBNB.transfer - 1;
        uint256 referrerPot = potsBNB.referrer;
        uint256 teamPot = potsBNB.team;

        uint256 tokensUsedForReferrersPot = referrerSystemData
            .tokensUsedForReferrersPot;

        // reentrancy is impossible, cause WorkAmounts[0] will have a huge value
        // therefore this function cannot be called in doWork
        uint32 savedAgentWorkAmount = workAmounts.agentBNB;
        workAmounts.agentBNB = 2**32 - 1;

        try
            Agent.delegate{value: agentPotToSend}(
                buyPot,
                sellPot,
                transferPot,
                teamPot,
                referrerPot,
                tokensUsedForReferrersPot
            )
        {
            potsBNB.buy = 1;
            potsBNB.sell = 0;
            potsBNB.transfer = 1;
            potsBNB.referrer = 0;
            potsBNB.team = 0;

            referrerSystemData.tokensUsedForReferrersPot = 0;
        } catch {}

        workAmounts.agentBNB = savedAgentWorkAmount;
    }

    function notifyTaxSystem(
        address sender,
        uint256 amount,
        uint256 taxAmount,
        uint256 txType
    ) private {
        TaxData storage taxData = Taxes[txType];
        uint256 totalTax = taxData.total;
        if (totalTax == 0) {
            return;
        }

        unchecked {
            uint256 taxAmountScaled = taxAmount / TOKEN_POTS_DIVISOR;

            uint256 reflectionsAmount = (taxAmountScaled *
                taxData.reflections) / totalTax;

            uint256 liquidityAmount = (taxAmountScaled * taxData.liquidity) /
                totalTax;
            tokenPots.liquidity += uint40(liquidityAmount);

            uint256 referrerAmount;
            if (
                referrerSystemData.isDefaultReferrer == 0 &&
                referrerSystemData.currentRefferalTaxReduction > 0
            ) {
                referrerAmount =
                    (taxAmountScaled * taxData.referrer) /
                    totalTax;
                tokenPots.referrer += uint40(referrerAmount);

                referrerSystemData.lastReferrerTokensAmount = uint96(
                    referrerAmount * TOKEN_POTS_DIVISOR
                );
            }

            uint256 teamAmount = (amount * taxData.team) /
                DENOMINATOR /
                TOKEN_POTS_DIVISOR;
            if (
                taxAmountScaled <
                teamAmount +
                    referrerAmount +
                    liquidityAmount +
                    reflectionsAmount
            ) {
                teamAmount = (taxAmountScaled * taxData.team) / totalTax;
            }
            tokenPots.team += uint56(teamAmount);

            uint40 taxAmountPure = uint40(
                taxAmountScaled -
                    reflectionsAmount -
                    liquidityAmount -
                    referrerAmount -
                    teamAmount
            );
            if (txType == 0) {
                tokenPots.buy += taxAmountPure;
            } else if (txType == 1) {
                tokenPots.sell += taxAmountPure;
            } else {
                tokenPots.transfer += taxAmountPure;
            }

            reflectionsAmount =
                reflectionsAmount *
                TOKEN_POTS_DIVISOR +
                taxAmount -
                taxAmountScaled *
                TOKEN_POTS_DIVISOR;

            __balanceOf[address(this)] += taxAmount - reflectionsAmount;

            emit Transfer(sender, address(this), taxAmount - reflectionsAmount);

            calculateReflections(reflectionsAmount);
        }
    }

    function calculateReflections(uint256 reflectionsAmount) private {
        unchecked {
            ReflectionsData storage _reflections = reflections;

            _reflections.pot += uint96(reflectionsAmount);
            _reflections.perShareStored = reflectionsPerShare();

            uint256 takeFromPot;
            if (block.timestamp >= _reflections.periodEnd) {
                takeFromPot =
                    (_reflections.pot * _reflections.potPartToDistribute) /
                    DENOMINATOR;

                _reflections.rate = uint96(takeFromPot / _reflections.delay);
            } else {
                uint256 timeDifference = _reflections.periodEnd -
                    block.timestamp;

                takeFromPot =
                    (_reflections.pot *
                        _reflections.potPartToDistribute *
                        (_reflections.prevDelay - timeDifference)) /
                    _reflections.prevDelay /
                    DENOMINATOR;

                uint256 toDistribute = takeFromPot +
                    _reflections.rate *
                    timeDifference;

                _reflections.rate = uint96(toDistribute / _reflections.delay);
            }

            _reflections.pot -= uint96(takeFromPot);
            _reflections.lastUpdateTime = uint32(block.timestamp);
            _reflections.periodEnd = uint32(
                block.timestamp + _reflections.delay
            );
            _reflections.prevDelay = _reflections.delay;
        }
    }

    function updateMultiplierBalances(address account) private {
        unchecked {
            uint256 usingMultiplier = getReflectionsMultiplier(account);

            uint256 newBalance = (__balanceOf[account] * usingMultiplier) /
                ONE /
                100;
            reflections.totalBalances = uint64(
                reflections.totalBalances -
                    Modifiers[account].oldMultiplierBalance +
                    newBalance
            );

            Modifiers[account].oldMultiplierBalance = uint64(newBalance);
        }
    }

    function updateReflections(address account) private {
        reflections.perShareStored = reflectionsPerShare();
        reflections.lastUpdateTime = lastTimeReflectionsApplicable();

        payReflections(account, reflections.perShareStored);
    }

    function payReflections(address account, uint256 perShareStored) private {
        unchecked {
            uint256 _reflected = reflected(account, perShareStored);

            __balanceOf[account] += _reflected;
            TotalReflected[account] += _reflected;
        }

        ReflectionsPerSharePaid[account] = perShareStored;
    }

    function lastTimeReflectionsApplicable() private view returns (uint32) {
        if (block.timestamp < reflections.periodEnd) {
            return uint32(block.timestamp);
        }

        return reflections.periodEnd;
    }

    function reflectionsPerShare() private view returns (uint256) {
        if (reflections.totalBalances == 0) {
            return reflections.perShareStored;
        }

        unchecked {
            return
                reflections.perShareStored +
                (lastTimeReflectionsApplicable() - reflections.lastUpdateTime) *
                ((reflections.rate * ONE) / reflections.totalBalances);
        }
    }

    function getReflectionsMultiplier(address account)
        private
        view
        returns (uint256)
    {
        if (
            Modifiers[account].reflectionsMultiplier > reflections.maxMultiplier
        ) {
            return reflections.maxMultiplier;
        }

        return Modifiers[account].reflectionsMultiplier;
    }

    function swapTaxTokensForBNB(uint256 totalTokens) private {
        unchecked {
            PotsDataToken storage _tokenPots = tokenPots;

            uint256 toSwap;
            uint256 liquidityTokens;
            uint256 buyTokens;
            uint256 sellTokens;
            uint256 transferTokens;
            uint256 referrerTokens;
            uint256 teamTokens;
            if (totalTokens > workAmounts.tokensMax) {
                toSwap = workAmounts.tokensMax;

                liquidityTokens =
                    ((_tokenPots.liquidity - 1) * toSwap) /
                    totalTokens;
                buyTokens = ((_tokenPots.buy) * toSwap) / totalTokens;
                sellTokens = ((_tokenPots.sell) * toSwap) / totalTokens;
                transferTokens = ((_tokenPots.transfer) * toSwap) / totalTokens;
                referrerTokens = ((_tokenPots.referrer) * toSwap) / totalTokens;
                teamTokens =
                    toSwap -
                    liquidityTokens -
                    buyTokens -
                    sellTokens -
                    transferTokens -
                    referrerTokens;
            } else {
                toSwap = totalTokens;

                liquidityTokens = _tokenPots.liquidity - 1;
                buyTokens = _tokenPots.buy;
                sellTokens = _tokenPots.sell;
                transferTokens = _tokenPots.transfer;
                referrerTokens = _tokenPots.referrer;
                teamTokens = _tokenPots.team;
            }

            _tokenPots.liquidity -= uint40(liquidityTokens);
            _tokenPots.buy -= uint40(buyTokens);
            _tokenPots.sell -= uint40(sellTokens);
            _tokenPots.transfer -= uint40(transferTokens);
            _tokenPots.referrer -= uint40(referrerTokens);
            _tokenPots.team -= uint56(teamTokens);

            uint256 receivedBNB = swapTokensForBNB(toSwap * TOKEN_POTS_DIVISOR);

            PotsDataBNB storage _potsBNB = potsBNB;

            _potsBNB.liquidity += uint80(
                (receivedBNB * liquidityTokens) / toSwap
            );
            _potsBNB.buy += uint80((receivedBNB * buyTokens) / toSwap);
            _potsBNB.sell += uint96((receivedBNB * sellTokens) / toSwap);
            _potsBNB.transfer += uint80(
                (receivedBNB * transferTokens) / toSwap
            );
            _potsBNB.referrer += uint80(
                (receivedBNB * referrerTokens) / toSwap
            );
            _potsBNB.team += uint96((receivedBNB * teamTokens) / toSwap);

            referrerSystemData.tokensUsedForReferrersPot += uint96(
                referrerTokens * TOKEN_POTS_DIVISOR
            );
        }
    }

    function swapTokensForBNB(uint256 tokensAmount) private returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WBNB;

        uint256[] memory amountsOut = SwapRouter.swapExactTokensForETH(
            tokensAmount,
            0,
            path,
            address(this),
            block.timestamp
        );

        return amountsOut[1];
    }

    function swapBNBForTokens(uint256 amountBNB) private returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = WBNB;
        path[1] = address(this);

        // to save gas it sends tokens to BURN_ADDRESS, which is a constant
        // you cannot swap a token with this same token contract as a recipient, so this trick is used
        uint256[] memory amountsOut = SwapRouter.swapExactETHForTokens{
            value: amountBNB
        }(0, path, BURN_ADDRESS, block.timestamp);

        unchecked {
            uint256 amount = amountsOut[1];

            __balanceOf[BURN_ADDRESS] -= amount;
            __balanceOf[address(this)] += amount;

            emit Transfer(BURN_ADDRESS, address(this), amount);

            return amount;
        }
    }

    function addLiquidityFromTokenReserves() private {
        uint80 liquidityPotBefore = potsBNB.liquidity;
        potsBNB.liquidity = 0;

        (uint256 addedTokens, uint256 addedBNB, ) = SwapRouter.addLiquidityETH{
            value: liquidityPotBefore - 1
        }(
            address(this),
            tokenLiquidityReserves,
            0,
            0,
            address(this),
            block.timestamp
        );

        unchecked {
            potsBNB.liquidity = liquidityPotBefore - uint80(addedBNB);
            tokenLiquidityReserves -= addedTokens;
        }
    }

    function refillLiquidityTokenReserves() private {
        unchecked {
            uint256 amountBNBtoBeSwapped = potsBNB.liquidity / 2;
            potsBNB.liquidity -= uint80(amountBNBtoBeSwapped);

            uint256 swappedTokens = swapBNBForTokens(amountBNBtoBeSwapped);
            tokenLiquidityReserves += swappedTokens;
        }
    }

    function _addMultiplier(
        address account,
        uint32 difference,
        uint32 isAddition
    ) private {
        require(account != address(this), "_AM0");

        updateReflections(account);

        unchecked {
            if (isAddition == 1) {
                uint32 newMultiplier = Modifiers[account]
                    .reflectionsMultiplier + difference;

                // more of a sanity check, considering mulitplier is limited in calculations to a reflections.maxMultiplier
                if (newMultiplier > 999999) {
                    newMultiplier = 999999;
                }

                Modifiers[account].reflectionsMultiplier = newMultiplier;

                if (Shareholders.ItemToIndex[account] == 0) {
                    Shareholders.add(account);
                }
            } else {
                uint32 newMultiplier = Modifiers[account]
                    .reflectionsMultiplier - difference;

                if (newMultiplier > 999999) {
                    newMultiplier = 0;
                }

                Modifiers[account].reflectionsMultiplier = newMultiplier;

                if (newMultiplier == 0) {
                    Shareholders.remove(account);
                }
            }
        }

        updateMultiplierBalances(account);
    }

    function _setBuyTaxReduction(address account, uint32 value) private {
        Modifiers[account].buyTaxReduction = value;
    }

    function _setSellTaxReduction(address account, uint32 value) private {
        Modifiers[account].sellTaxReduction = value;
    }

    function getCompressedTokenPotsSum() private view returns (uint256) {
        return
            tokenPots.liquidity +
            tokenPots.buy +
            tokenPots.sell +
            tokenPots.transfer +
            tokenPots.referrer +
            tokenPots.team -
            1;
    }

    function getBNBPotsSumWithoutLiquidity() private view returns (uint256) {
        return
            potsBNB.buy +
            potsBNB.sell +
            potsBNB.transfer +
            potsBNB.referrer +
            potsBNB.team -
            2;
    }

    function getBNBPotsSum() private view returns (uint256) {
        return
            potsBNB.liquidity +
            potsBNB.buy +
            potsBNB.sell +
            potsBNB.transfer +
            potsBNB.referrer +
            potsBNB.team -
            2;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;


interface IAgent {
    function delegate(
        uint256 buyPot, uint256 sellPot, uint256 transferPot, uint256 teamPot, uint256 referrerPot, uint256 tokensUsedForReferrerPot
    ) external payable;
    function marketplaceDelegate(uint256 toBuyback, uint256 toMarketing, uint256 toTeam) external payable;
    function notifyTransferListener(address from, address to) external;
    function notifyTransferListener(address from) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

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

    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function sync() external;

    function initialize(address, address) external;
}

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

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

library ListAddress
{
    struct ListStruct
    {
        address[] Array;
        mapping(address => uint32) ItemToIndex;
    }

    function add(ListStruct storage self, address account) external
    {
        if (self.Array.length == 0)
        {
            self.Array.push(address(0));
        }

        require(self.ItemToIndex[account] == 0, "LA:A0");

        self.Array.push(account);
        self.ItemToIndex[account] = uint32(self.Array.length - 1);
    }

    function remove(ListStruct storage self, address account) external
    {
        uint256 itemIndex = self.ItemToIndex[account];
        uint256 lastIndex = self.Array.length - 1;

        if (itemIndex > 0)
        {
            if (itemIndex < lastIndex)
            {
                self.Array[itemIndex] = self.Array[lastIndex];
            }

            self.Array.pop();
            self.ItemToIndex[account] = 0;
        }
    }
}