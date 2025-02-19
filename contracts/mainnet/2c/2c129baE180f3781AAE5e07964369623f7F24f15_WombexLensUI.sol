// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts-0.8/token/ERC20/ERC20.sol";
import "./Interfaces.sol";

interface IUniswapV2Router01 {
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IWmx {
    function getFactAmounMint(uint256) external view returns (uint256);
}

interface IWomAsset {
    function pool() external view returns (address);
    function underlyingToken() external view returns (address);
}

interface IWomPool {
    function quotePotentialWithdraw(address _token, uint256 _liquidity) external view returns (uint256);
    function quotePotentialSwap(
        address fromToken,
        address toToken,
        int256 fromAmount
    ) external view returns (uint256 potentialOutcome, uint256 haircut);
}

interface IBaseRewardPool4626 {
    struct RewardState {
        address token;
        uint256 periodFinish;
        uint256 rewardRate;
        uint256 lastUpdateTime;
        uint256 rewardPerTokenStored;
        uint256 queuedRewards;
        uint256 currentRewards;
        uint256 historicalRewards;
        bool paused;
    }
    function rewardTokensList() external view returns (address[] memory);
    function tokenRewards(address _token) external view returns (RewardState memory);
    function claimableRewards(address _account)
        external view returns (address[] memory tokens, uint256[] memory amounts);
}

contract WombexLensUI {
    // STABLECOIN POOLS
    address internal constant WOM_STABLE_MAIN_POOL = 0x312Bc7eAAF93f1C60Dc5AfC115FcCDE161055fb0;
    address internal constant WOM_STABLE_SIDE_POOL = 0x0520451B19AD0bb00eD35ef391086A692CFC74B2;
    address internal constant WOM_INNOVATION_POOL = 0x48f6A8a0158031BaF8ce3e45344518f1e69f2A14;
    address internal constant WOM_IUSD_POOL = 0x277E777F7687239B092c8845D4d2cd083a33C903;
    address internal constant WOM_CUSD_POOL = 0x4dFa92842d05a790252A7f374323b9C86D7b7E12;
    address internal constant WOM_AXLUSDC_POOL = 0x8ad47d7ab304272322513eE63665906b64a49dA2;
    address internal constant WOM_USDD_POOL = 0x05f727876d7C123B9Bb41507251E2Afd81EAD09A;

    // BNB POOLS
    address internal constant WOM_BNB_POOL = 0x0029b7e8e9eD8001c868AA09c74A1ac6269D4183;
    address internal constant WOM_BNBx_POOL = 0x8df1126de13bcfef999556899F469d64021adBae;
    address internal constant WOM_STKBNB_POOL = 0xB0219A90EF6A24a237bC038f7B7a6eAc5e01edB0;

    // OTHER POOLS
    address internal constant WOM_WMX_POOL = 0xeEB5a751E0F5231Fc21c7415c4A4c6764f67ce2e;

    // STABLE TOKENS
    address internal constant BUSD_TOKEN = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    address internal constant USDT_TOKEN = 0x55d398326f99059fF775485246999027B3197955;
    address internal constant USDC_TOKEN = 0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d;
    address internal constant DAI_TOKEN = 0x1AF3F329e8BE154074D8769D1FFa4eE058B1DBc3;
    address internal constant HAY_TOKEN = 0x0782b6d8c4551B9760e74c0545a9bCD90bdc41E5;
    address internal constant FRAX_TOKEN = 0x90C97F71E18723b0Cf0dfa30ee176Ab653E89F40;
    address internal constant TUSD_TOKEN = 0x14016E85a25aeb13065688cAFB43044C2ef86784;
    address internal constant axlUSDC_TOKEN = 0x4268B8F0B87b6Eae5d897996E6b845ddbD99Adf3;
    address internal constant CUSD_TOKEN = 0xFa4BA88Cf97e282c505BEa095297786c16070129;
    address internal constant iUSD_TOKEN = 0x0A3BB08b3a15A19b4De82F8AcFc862606FB69A2D;
    address internal constant USDD_TOKEN = 0xd17479997F34dd9156Deef8F95A52D81D265be9c;

    // OTHER UNDERLYING TOKENS
    address internal constant WOM_TOKEN = 0xAD6742A35fB341A9Cc6ad674738Dd8da98b94Fb1;
    address internal constant WMX_TOKEN = 0xa75d9ca2a0a1D547409D82e1B06618EC284A2CeD;
    address internal constant WBNB_TOKEN = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address internal constant WMX_WOM_TOKEN = 0x0415023846Ff1C6016c4d9621de12b24B2402979;

    // REWARD TOKENS TOKENS
    address internal constant SD_TOKEN = 0x3BC5AC0dFdC871B365d159f728dd1B9A0B5481E8;
    address internal constant PSTAKE_TOKEN = 0x4C882ec256823eE773B25b414d36F92ef58a7c0C;
    address internal constant ANKR_TOKEN = 0xf307910A4c7bbc79691fD374889b36d8531B08e3;

    // ROUTERS
    address internal constant PANCAKE_ROUTER = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address internal constant APE_ROUTER = 0xcF0feBd3f17CEf5b47b0cD257aCf6025c5BFf3b7;

    struct PoolValues {
        string symbol;
        uint256 pid;
        uint256 lpTokenPrice;
        uint256 lpTokenBalance;
        uint256 tvl;
        uint256 wmxApr;
        uint256 totalApr;
        address rewardPool;
        PoolValuesTokenApr[] tokenAprs;
    }

    struct PoolValuesTokenApr {
        address token;
        uint256 apr;
    }

    struct PoolRewardRate {
        address[] rewardTokens;
        uint256[] rewardRates;
    }

    struct RewardContractData {
        uint256 balance;
        uint256 usdOut;
        address[] rewardTokens;
        uint256[] rewards;
    }

    function _isUsdStableToken(address _token) internal pure returns (bool) {
        if (_token == BUSD_TOKEN || _token == USDT_TOKEN || _token == USDC_TOKEN || _token == DAI_TOKEN ||
        _token == HAY_TOKEN || _token == FRAX_TOKEN || _token == TUSD_TOKEN || _token == axlUSDC_TOKEN ||
        _token == CUSD_TOKEN || _token == iUSD_TOKEN || _token == USDD_TOKEN) {
            return true;
        }
        return false;
    }

    function _isUsdStablePoolWithBUSD(address _womPool) internal pure returns (bool) {
        if (_womPool == WOM_STABLE_MAIN_POOL || _womPool == WOM_STABLE_SIDE_POOL || _womPool == WOM_INNOVATION_POOL ||
        _womPool == WOM_AXLUSDC_POOL || _womPool == WOM_IUSD_POOL) {
            return true;
        }
        return false;
    }

    function _isUsdStablePool(address _womPool) internal pure returns (bool) {
        if (_isUsdStablePoolWithBUSD(_womPool) || _womPool == WOM_USDD_POOL || _womPool == WOM_CUSD_POOL) {
            return true;
        }
        return false;
    }

    function getRewardRates(
        IBooster _booster
    ) public view returns(PoolRewardRate[] memory result, uint256 mintRatio) {
        uint256 len = _booster.poolLength();

        result = new PoolRewardRate[](len);
        mintRatio = _booster.mintRatio();

        for (uint256 i = 0; i < len; i++) {
            IBooster.PoolInfo memory poolInfo = _booster.poolInfo(i);
            IBaseRewardPool4626 crvRewards = IBaseRewardPool4626(poolInfo.crvRewards);
            address[] memory rewardTokens = crvRewards.rewardTokensList();
            uint256[] memory rewardRates = new uint256[](rewardTokens.length);
            for (uint256 j = 0; j < rewardTokens.length; j++) {
                address token = rewardTokens[j];
                rewardRates[j] = crvRewards.tokenRewards(token).rewardRate;
            }
            result[i].rewardTokens = rewardTokens;
            result[i].rewardRates = rewardRates;
        }
    }

    function getApys1(
        IBooster _booster
    ) public view returns(PoolValues[] memory) {
        uint256 mintRatio = _booster.mintRatio();
        uint256 len = _booster.poolLength();
        PoolValues[] memory result = new PoolValues[](len);
        uint256 wmxUsdPrice = estimateInBUSD(WMX_TOKEN, 1 ether);

        for (uint256 i = 0; i < len; i++) {
            IBooster.PoolInfo memory poolInfo = _booster.poolInfo(i);
            IBaseRewardPool4626 crvRewards = IBaseRewardPool4626(poolInfo.crvRewards);
            address pool = IWomAsset(poolInfo.lptoken).pool();

            PoolValues memory pValues;

            pValues.pid = i;
            pValues.symbol = ERC20(poolInfo.lptoken).symbol();
            pValues.rewardPool = poolInfo.crvRewards;

            // 1. Calculate Tvl
            pValues.lpTokenPrice = getLpUsdOut(pool, 1 ether);
            pValues.lpTokenBalance = ERC20(poolInfo.crvRewards).totalSupply();
            pValues.tvl = pValues.lpTokenBalance * pValues.lpTokenPrice / 1 ether;

            // 2. Calculate APYs
            if (pValues.tvl > 10) {
                _setApys(crvRewards, wmxUsdPrice, mintRatio, pValues.tvl, pValues);
            }

            result[i] = pValues;
        }

        return result;
    }

    function _setApys(IBaseRewardPool4626 crvRewards, uint256 wmxUsdPrice, uint256 mintRatio, uint256 poolTvl, PoolValues memory pValues) internal view {
        address[] memory rewardTokens = crvRewards.rewardTokensList();
        uint256 len = rewardTokens.length;
        PoolValuesTokenApr[] memory aprs = new PoolValuesTokenApr[](len);
        uint256 aprTotal;
        uint256 wmxApr;

        for (uint256 i = 0; i < len; i++) {
            address token = rewardTokens[i];
            IBaseRewardPool4626.RewardState memory rewardState = crvRewards.tokenRewards(token);

            if (token == WOM_TOKEN) {
                uint256 factAmountMint = IWmx(WMX_TOKEN).getFactAmounMint(rewardState.rewardRate * 365 days);
                uint256 wmxRate = factAmountMint;
                if (mintRatio > 0) {
                    wmxRate = factAmountMint * mintRatio / 10_000;
                }

                wmxApr = wmxRate * wmxUsdPrice * 100 / poolTvl / 1e16;
            }

            uint256 usdPrice = estimateInBUSD(token, 1 ether);
            uint256 apr = rewardState.rewardRate * 365 days * usdPrice * 100 / poolTvl / 1e16;
            aprTotal += apr;

            aprs[i].token = token;
            aprs[i].apr = apr;
        }

        aprTotal += wmxApr;

        pValues.tokenAprs = aprs;
        pValues.totalApr = aprTotal;
        pValues.wmxApr = wmxApr;
    }

    function getLpUsdOut(
        address _womPool,
        uint256 _lpTokenAmountIn
    ) public view returns (uint256) {
        if (_isUsdStablePoolWithBUSD(_womPool)) {
            return _quotePotentialWithdrawalTokenToBUSD(_womPool, BUSD_TOKEN, _lpTokenAmountIn);
        } else if (_womPool == WOM_WMX_POOL) {
            return _quotePotentialWithdrawalTokenToBUSD(_womPool, WOM_TOKEN, _lpTokenAmountIn);
        } else if (_womPool == WOM_CUSD_POOL) {
            return _quotePotentialWithdrawalTokenToBUSD(_womPool, HAY_TOKEN, _lpTokenAmountIn);
        } else if (_womPool == WOM_USDD_POOL) {
            return _quotePotentialWithdrawalTokenToBUSD(_womPool, USDC_TOKEN, _lpTokenAmountIn);
        } else if (_womPool == WOM_BNBx_POOL || _womPool == WOM_STKBNB_POOL) {
            return _quotePotentialWithdrawalTokenToBUSD(_womPool, WBNB_TOKEN, _lpTokenAmountIn);
        } else {
            revert("unsupported pool");
        }
    }

    function _quotePotentialWithdrawalTokenToBUSD(address _womPool, address _tokenOut, uint256 _lpTokenAmountIn) internal view returns (uint256) {
        try IWomPool(_womPool).quotePotentialWithdraw(_tokenOut, _lpTokenAmountIn) returns (uint256 tokenAmountOut) {
            return estimateInBUSD(_tokenOut, tokenAmountOut);
        } catch {
        }
        return 0;
    }

    // Estimates a token equivalent in USD (BUSD) using a Uniswap-compatible router
    function estimateInBUSD(address _token, uint256 _amountIn) public view returns (uint256) {
        // 1. All the USD stable tokens are roughly estimated as $1.
        if (_isUsdStableToken(_token)) {
            return _amountIn;
        }

        address router = PANCAKE_ROUTER;
        bool throughBnb = false;

        if (_token == SD_TOKEN) {
            router = APE_ROUTER;
        }
        if (_token == ANKR_TOKEN) {
            throughBnb = true;
        }

        address[] memory path;
        if (throughBnb) {
            path = new address[](3);
            path[0] = _token;
            path[1] = WBNB_TOKEN;
            path[2] = BUSD_TOKEN;
        } else {
            path = new address[](2);
            path[0] = _token;
            path[1] = BUSD_TOKEN;
        }
        uint256[] memory amountsOut = IUniswapV2Router01(router).getAmountsOut(_amountIn, path);
        return amountsOut[amountsOut.length - 1];
    }

    /*** USER DETAILS ***/

    function getUserBalancesDefault(
        IBooster _booster,
        address _user
    ) public view returns(
        uint256[] memory lpTokenBalances,
        uint256[] memory underlyingBalances,
        uint256[] memory usdOuts,
        address[][] memory rewardTokens,
        uint256[][] memory earnedRewardsUSD,
        RewardContractData memory wmxWom,
        RewardContractData memory locker
    ) {
        (lpTokenBalances, underlyingBalances, usdOuts, rewardTokens, earnedRewardsUSD) = getUserBalances(
            _booster, _user, allBoosterPoolIds(_booster)
        );
        wmxWom = getUserWmxWom(IBooster(_booster).crvLockRewards(), _user);
        locker = getUserLocker(IBooster(_booster).cvxLocker(), _user);
    }

    function allBoosterPoolIds(IBooster _booster) public view returns (uint256[] memory) {
        uint256 len = _booster.poolLength();
        uint256[] memory poolIds = new uint256[](len);
        for (uint256 i = 0; i < len; i++) {
            poolIds[i] = i;
        }
        return poolIds;
    }

    function getUserWmxWom(
        address _crvLockRewards,
        address _user
    ) public view returns (RewardContractData memory data) {
        (address[] memory wmxWomRewardTokens, , uint256[] memory wmxWomRewardsUSD) = getUserPendingRewards(_crvLockRewards, _user);
        data = RewardContractData(ERC20(_crvLockRewards).balanceOf(_user), 0, wmxWomRewardTokens, wmxWomRewardsUSD);
        if (data.balance > 0) {
            (uint256 womAmountOut,) = IWomPool(WOM_WMX_POOL)
                .quotePotentialSwap(WMX_WOM_TOKEN, WOM_TOKEN, int256(data.balance));

            if (womAmountOut > 0) {
                address[] memory path = new address[](2);

                path[0] = WOM_TOKEN;
                path[1] = BUSD_TOKEN;
                uint256[] memory amountsOut = IUniswapV2Router01(PANCAKE_ROUTER).getAmountsOut(womAmountOut, path);
                data.usdOut = amountsOut[1];
            }
        }
    }

    function getUserLocker(
        address _locker,
        address _user
    ) public view returns (RewardContractData memory data) {
        (address[] memory rewardTokens, , uint256[] memory rewardsUSD) = getUserLockerPendingRewards(_locker, _user);
        (uint256 balance, , , ) = IWmxLocker(_locker).lockedBalances(_user);
        data = RewardContractData(balance, 0, rewardTokens, rewardsUSD);
        if (data.balance > 0) {
            address[] memory path = new address[](2);
            path[0] = WMX_TOKEN;
            path[1] = BUSD_TOKEN;
            uint256[] memory amountsOut = IUniswapV2Router01(PANCAKE_ROUTER).getAmountsOut(data.balance, path);
            data.usdOut = amountsOut[1];
        }
    }

    function getUserBalances(
        IBooster _booster,
        address _user,
        uint256[] memory _poolIds
    ) public view returns(
        uint256[] memory lpTokenBalances,
        uint256[] memory underlyingBalances,
        uint256[] memory usdOuts,
        address[][] memory rewardTokens,
        uint256[][] memory earnedRewardsUSD
    ) {
        uint256 len = _poolIds.length;
        lpTokenBalances = new uint256[](len);
        underlyingBalances = new uint256[](len);
        usdOuts = new uint256[](len);
        rewardTokens = new address[][](len);
        earnedRewardsUSD = new uint256[][](len);

        for (uint256 i = 0; i < len; i++) {
            IBooster.PoolInfo memory poolInfo = _booster.poolInfo(_poolIds[i]);

            // 1. Earned rewards
            (rewardTokens[i],,earnedRewardsUSD[i]) = getUserPendingRewards(poolInfo.crvRewards, _user);

            // 2. LP token balance
            uint256 womLpTokenBalance = ERC20(poolInfo.crvRewards).balanceOf(_user);
            lpTokenBalances[i] = womLpTokenBalance;

            // 3. Underlying balance
            address womPool = IWomAsset(poolInfo.lptoken).pool();
            address underlyingToken = IWomAsset(poolInfo.lptoken).underlyingToken();
            try IWomPool(womPool).quotePotentialWithdraw(underlyingToken, womLpTokenBalance) returns (uint256 underlyingBalance) {
                underlyingBalances[i] = underlyingBalance;

                // 4. Usd outs
                if (_isUsdStablePool(womPool)) {
                    usdOuts[i] = underlyingBalance;
                } else {
                    usdOuts[i] = getLpUsdOut(womPool, womLpTokenBalance);
                }
            } catch {}
        }
    }

    function getUserPendingRewards(address _rewardsPool, address _user)
        public view returns (
            address[] memory rewardTokens,
            uint256[] memory earnedRewards,
            uint256[] memory earnedRewardsUSD
    ) {
        (rewardTokens, earnedRewards) = IBaseRewardPool4626(_rewardsPool)
            .claimableRewards(_user);

        earnedRewardsUSD = new uint256[](rewardTokens.length);
        for (uint256 i = 0; i < earnedRewards.length; i++) {
            if (earnedRewards[i] > 0) {
                earnedRewardsUSD[i] = estimateInBUSD(rewardTokens[i], earnedRewards[i]);
            }
        }
    }

    function getUserLockerPendingRewards(address _locker, address _user) public view
        returns (
            address[] memory rewardTokens,
            uint256[] memory earnedRewards,
            uint256[] memory earnedRewardsUSD
        )
    {
        IWmxLocker.EarnedData[] memory userRewards = IWmxLocker(_locker).claimableRewards(_user);

        rewardTokens = new address[](userRewards.length);
        earnedRewards = new uint256[](userRewards.length);
        earnedRewardsUSD = new uint256[](userRewards.length);
        for (uint256 i = 0; i < earnedRewards.length; i++) {
            rewardTokens[i] = userRewards[i].token;
            earnedRewards[i] = userRewards[i].amount;
            if (earnedRewards[i] > 0) {
                earnedRewardsUSD[i] = estimateInBUSD(rewardTokens[i], earnedRewards[i]);
            }
        }
    }

    function getWomLpBalances(
        IBooster _booster,
        address _user,
        uint256[] memory _poolIds
    ) public view returns(uint256[] memory balances) {
        uint256 len = _poolIds.length;
        balances = new uint256[](len);

        for (uint256 i = 0; i < len; i++) {
            IBooster.PoolInfo memory poolInfo = _booster.poolInfo(i);
            balances[i] = ERC20(poolInfo.crvRewards).balanceOf(_user);
        }
    }

    /*** ESTIMATIONS ***/

    function quoteUnderlyingAmountOut(
        address _lpToken,
        uint256 _lpTokenAmountIn
    ) public view returns(uint256) {
        address pool = IWomAsset(_lpToken).pool();
        address underlyingToken = IWomAsset(_lpToken).underlyingToken();
        return IWomPool(pool).quotePotentialWithdraw(underlyingToken, _lpTokenAmountIn);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

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
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
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

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
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

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
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
        _balances[account] += amount;
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
        }
        _totalSupply -= amount;

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts-0.8/token/ERC20/IERC20.sol";

interface IWomDepositor {
    function deposit(uint256 _amount, address _stakeAddress) external returns (bool);
}

interface IWETH {
    function deposit() external payable;
    function withdraw(uint wad) external;
}

interface IAsset is IERC20 {
    function underlyingToken() external view returns (address);

    function pool() external view returns (address);

    function cash() external view returns (uint120);

    function liability() external view returns (uint120);

    function decimals() external view returns (uint8);

    function underlyingTokenDecimals() external view returns (uint8);

    function setPool(address pool_) external;

    function underlyingTokenBalance() external view returns (uint256);

    function transferUnderlyingToken(address to, uint256 amount) external;

    function mint(address to, uint256 amount) external;

    function burn(address to, uint256 amount) external;

    function addCash(uint256 amount) external;

    function removeCash(uint256 amount) external;

    function addLiability(uint256 amount) external;

    function removeLiability(uint256 amount) external;
}

interface IWmxLocker {
    struct EarnedData {
        address token;
        uint256 amount;
    }
    struct LockedBalance {
        uint112 amount;
        uint32 unlockTime;
    }

    function lock(address _account, uint256 _amount) external;

    function checkpointEpoch() external;

    function epochCount() external view returns (uint256);

    function balanceAtEpochOf(uint256 _epoch, address _user) external view returns (uint256 amount);

    function totalSupplyAtEpoch(uint256 _epoch) external view returns (uint256 supply);

    function queueNewRewards(address _rewardsToken, uint256 reward) external;

    function getReward(address _account, bool _stake) external;

    function getReward(address _account) external;

    function balanceOf(address _account) external view returns (uint256 amount);

    function claimableRewards(address _account) external view returns (EarnedData[] memory userRewards);

    function lockedBalances(address _user) external view
        returns (
            uint256 total,
            uint256 unlockable,
            uint256 locked,
            LockedBalance[] memory lockData
        );
}

interface IExtraRewardsDistributor {
    function addReward(address _token, uint256 _amount) external;
}

interface IWomDepositorWrapper {
    function getMinOut(uint256, uint256) external view returns (uint256);

    function deposit(
        uint256,
        uint256,
        bool,
        address _stakeAddress
    ) external;
}

interface IRewards{
    function stake(address, uint256) external;
    function stakeFor(address, uint256) external;
    function withdraw(address, uint256) external;
    function withdraw(uint256 assets, address receiver, address owner) external;
    function exit(address) external;
    function getReward(address) external;
    function queueNewRewards(address, uint256) external;
    function notifyRewardAmount(uint256) external;
    function addExtraReward(address) external;
    function extraRewardsLength() external view returns (uint256);
    function stakingToken() external view returns (address);
    function rewardToken() external view returns(address);
    function earned(address account) external view returns (uint256);
}

interface ITokenMinter{
    function mint(address,uint256) external;
    function burn(address,uint256) external;
    function setOperator(address) external;
}

interface IStaker{
    function deposit(address, address) external returns (bool);
    function withdraw(address) external returns (uint256);
    function withdrawLp(address, address, uint256) external returns (bool);
    function withdrawAllLp(address, address) external returns (bool);
    function lock(uint256 _lockDays) external;
    function releaseLock(uint256 _slot) external returns(uint256);
    function getGaugeRewardTokens(address _lptoken, address _gauge) external returns (address[] memory tokens);
    function claimCrv(address, uint256) external returns (address[] memory tokens, uint256[] memory balances);
    function balanceOfPool(address, address) external view returns (uint256);
    function operator() external view returns (address);
    function depositor() external view returns (address);
    function execute(address _to, uint256 _value, bytes calldata _data) external returns (bool, bytes memory);
    function setVote(bytes32 hash, bool valid) external;
    function setDepositor(address _depositor) external;
    function setOwner(address _owner) external;
}

interface IPool {
    function deposit(
        address token,
        uint256 amount,
        uint256 minimumLiquidity,
        address to,
        uint256 deadline,
        bool shouldStake
    ) external returns (uint256);

    function withdraw(
        address token,
        uint256 liquidity,
        uint256 minimumAmount,
        address to,
        uint256 deadline
    ) external returns (uint256 amount);

    function quotePotentialSwap(
        address fromToken,
        address toToken,
        int256 fromAmount
    ) external view returns (uint256 potentialOutcome, uint256 haircut);

    function quotePotentialDeposit(
        address token,
        uint256 amount
    ) external view returns (uint256 liquidity, uint256 reward);

    function quotePotentialWithdraw(
        address token,
        uint256 liquidity
    ) external view returns (uint256 amount, uint256 fee);

    function withdrawFromOtherAsset(
        address fromToken,
        address toToken,
        uint256 liquidity,
        uint256 minimumAmount,
        address to,
        uint256 deadline
    ) external returns (uint256 amount);

    function swap(
        address fromToken,
        address toToken,
        uint256 fromAmount,
        uint256 minimumToAmount,
        address to,
        uint256 deadline
    ) external returns (uint256 actualToAmount, uint256 haircut);

    function quoteAmountIn(
        address fromToken,
        address toToken,
        int256 toAmount
    ) external view returns (uint256 amountIn, uint256 haircut);

    function addressOfAsset(address token) external view returns (address);
}

interface IWombatRouter {
    function getAmountOut(
        address[] calldata tokenPath,
        address[] calldata poolPath,
        int256 amountIn
    ) external view returns (uint256 amountOut, uint256[] memory haircuts);

    /**
     * @notice Returns the minimum input asset amount required to buy the given output asset amount
     * (accounting for fees and slippage)
     * Note: This function should be used as estimation only. The actual swap amount might
     * be different due to precision error (the error is typically under 1e-6)
     */
    function getAmountIn(
        address[] calldata tokenPath,
        address[] calldata poolPath,
        uint256 amountOut
    ) external view returns (uint256 amountIn, uint256[] memory haircuts);

    function swapExactTokensForTokens(
        address[] calldata tokenPath,
        address[] calldata poolPath,
        uint256 fromAmount,
        uint256 minimumToAmount,
        address to,
        uint256 deadline
    ) external returns (uint256 amountOut);

    function swapExactNativeForTokens(
        address[] calldata tokenPath, // the first address should be WBNB
        address[] calldata poolPath,
        uint256 minimumamountOut,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountOut);

    function swapExactTokensForNative(
        address[] calldata tokenPath, // the last address should be WBNB
        address[] calldata poolPath,
        uint256 amountIn,
        uint256 minimumamountOut,
        address to,
        uint256 deadline
    ) external returns (uint256 amountOut);

    function addLiquidityNative(
        IPool pool,
        uint256 minimumLiquidity,
        address to,
        uint256 deadline,
        bool shouldStake
    ) external payable returns (uint256 liquidity);

    function removeLiquidityNative(
        IPool pool,
        uint256 liquidity,
        uint256 minimumAmount,
        address to,
        uint256 deadline
    ) external returns (uint256 amount);

    function removeLiquidityFromOtherAssetAsNative(
        IPool pool,
        address fromToken,
        uint256 liquidity,
        uint256 minimumAmount,
        address to,
        uint256 deadline
    ) external returns (uint256 amount);
}

interface IBooster {
    struct PoolInfo {
        address lptoken;
        address token;
        address gauge;
        address crvRewards;
        bool shutdown;
    }

    function crv() external view returns (address);
    function owner() external view returns (address);
    function voterProxy() external view returns (address);
    function poolLength() external view returns (uint256);
    function poolInfo(uint256 _pid) external view returns (PoolInfo memory);
    function depositFor(uint256 _pid, uint256 _amount, bool _stake, address _receiver) external returns (bool);
    function setOwner(address _owner) external;
    function setPoolManager(address _poolManager) external;
    function voterProxyClaimRewards(uint256 _pid, address[] memory pendingTokens) external returns (uint256[] memory pendingRewards);
    function addPool(address _lptoken, address _gauge) external returns (uint256);
    function addCreatedPool(address _lptoken, address _gauge, address _token, address _crvRewards) external returns (uint256);
    function approveDistribution(address _distro, address[] memory _distributionTokens, uint256 _amount) external;
    function approvePoolsCrvRewardsDistribution(address _token) external;
    function distributeRewards(uint256 _pid, address _lpToken, address _rewardToken, address[] memory _transferTo, uint256[] memory _transferAmount, bool[] memory _callQueue) external;
    function lpPendingRewards(address _lptoken, address _token) external returns (uint256);
    function earmarkRewards(uint256 _pid) external;
    function shutdownPool(uint256 _pid) external returns (bool);
    function forceShutdownPool(uint256 _pid) external returns (bool);
    function gaugeMigrate(address _newGauge, uint256[] memory migratePids) external;
    function voteExecute(address _voting, uint256 _value, bytes calldata _data) external;
    function mintRatio() external view returns (uint256);
    function crvLockRewards() external view returns (address);
    function cvxLocker() external view returns (address);
}

interface IBoosterEarmark {
    function earmarkIncentive() external view returns (uint256);
    function distributionByTokenLength(address _token) external view returns (uint256);
    function distributionByTokens(address, uint256) external view returns (address, uint256, bool);
    function distributionTokenList() external view returns (address[] memory);
    function addPool(address _lptoken, address _gauge) external returns (uint256);
    function addCreatedPool(address _lptoken, address _gauge, address _token, address _crvRewards) external returns (uint256);
}

interface ISwapRouter {
    function swapExactTokensForTokens(
        address[] calldata tokenPath,
        address[] calldata poolPath,
        uint256 amountIn,
        uint256 minimumamountOut,
        address to,
        uint256 deadline
    ) external returns (uint256 amountOut);

    function getAmountOut(
        address[] calldata tokenPath,
        address[] calldata poolPath,
        int256 amountIn
    ) external view returns (uint256 amountOut, uint256[] memory haircuts);
}

interface IWomSwapDepositor {
    function pool() external view returns (address);
    function deposit(uint256 _amount, address _stakeAddress, uint256 _minAmountOut, uint256 _deadline) external returns (bool);
}

/**
 * @dev Interface of the MasterWombatV2
 */
interface IMasterWombatV2 {
    function getAssetPid(address asset) external view returns (uint256 pid);

    function poolLength() external view returns (uint256);

    function pendingTokens(uint256 _pid, address _user)
    external
    view
    returns (
        uint256 pendingRewards,
        IERC20[] memory bonusTokenAddresses,
        string[] memory bonusTokenSymbols,
        uint256[] memory pendingBonusRewards
    );

    function rewarderBonusTokenInfo(uint256 _pid)
    external
    view
    returns (IERC20[] memory bonusTokenAddresses, string[] memory bonusTokenSymbols);

    function massUpdatePools() external;

    function updatePool(uint256 _pid) external;

    function deposit(uint256 _pid, uint256 _amount) external returns (uint256, uint256[] memory);

    function multiClaim(uint256[] memory _pids)
    external
    returns (
        uint256 transfered,
        uint256[] memory rewards,
        uint256[][] memory additionalRewards
    );

    function withdraw(uint256 _pid, uint256 _amount) external returns (uint256, uint256[] memory);

    function emergencyWithdraw(uint256 _pid) external;

    function migrate(uint256[] calldata _pids) external;

    function depositFor(
        uint256 _pid,
        uint256 _amount,
        address _user
    ) external;

    function updateFactor(address _user, uint256 _newVeWomBalance) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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