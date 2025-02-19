// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "./interfaces/IBuyAndBurn.sol";
import "./interfaces/IGymLevelPool.sol";
import "./interfaces/IGymMLM.sol";
import "./interfaces/IGymMLMQualifications.sol";
import "./interfaces/IGymNetwork.sol";
import "./interfaces/IGymSinglePool.sol";
import "./interfaces/IPancakeRouter02.sol";
import "./interfaces/IPancakeswapPair.sol";
import "./interfaces/IStrategy.sol";
import "./interfaces/IWETH.sol";
import "./RewardRateConfigurable.sol";
import "./interfaces/IERC20Burnable.sol";
import "./interfaces/IPancakePair.sol";

/* solhint-disable max-states-count, not-rely-on-time */
contract GymFarming is OwnableUpgradeable, ReentrancyGuardUpgradeable, RewardRateConfigurable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /**
     * @notice Info of each user
     * @param totalDepositTokens total amount of deposits in tokens
     * @param totalDepositDollarValue total amount of tokens converted to USD
     * @param lpTokensAmount: How many LP tokens the user has provided
     * @param rewardDebt: Reward debt. See explanation below
     * @param totalClaims: total amount of claimed tokens
     */
    struct UserInfo {
        uint256 totalDepositTokens;
        uint256 totalDepositDollarValue;
        uint256 lpTokensAmount;
        uint256 rewardDebt;
        uint256 totalClaims;
    }

    /**
     * @notice Info of each pool
     * @param lpToken: Address of LP token contract
     * @param allocPoint: How many allocation points assigned to this pool. rewards to distribute per block
     * @param lastRewardBlock: Last block number that rewards distribution occurs
     * @param accRewardPerShare: Accumulated rewards per share, times 1e18. See below
     */
    struct PoolInfo {
        address lpToken;
        uint256 allocPoint;
        uint256 lastRewardBlock;
        uint256 accRewardPerShare;
    }

    /**
     * Deprecated, use AddLiquidityResult instead
     *
     * @notice Internal struct to transfer data between function calls
     * @param totalAddedInBaseToken total amount of tokens added to pool represented in base token
     * @param baseTokensAdded amount of base tokens added
     * @param gymnetTokensAdded amount of GYMNET tokens added
     * @param lpTokens total LP tokens
     */
    struct UserLiquidityData {
        uint256 totalAddedInBaseToken;
        uint256 baseTokensAdded;
        uint256 gymnetTokensAdded;
        uint256 lpTokens;
    }

    uint256 public constant MAX_COMISSION_PERCENT = 80;
    uint256 public constant BUY_BACK_COMMISION = 4;

    /// The reward token
    address public rewardToken;
    /// Info of each pool.
    PoolInfo[] public poolInfo;
    /// Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    mapping(address => bool) public isPoolExist;
    /// Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint;
    /// The block number when reward mining starts.
    uint256 public startBlock;
    address public routerAddress;
    address public wbnbAddress;
    address public treasury;
    address public buyAndBurnAddress;
    address[] public rewardTokenToWBNB;
    uint256 public affilateComission;
    uint256 public poolComission;
    address public relationship;
    address public levelPool;
    address public mlmQualificationsAddress;
    address public busdAddress;

    mapping(address => bool) private whitelist;

    bool public isDepositsOn;

    struct AddLiquidityResult {
        uint256 baseTokensStaked;
        uint256 gymnetTokensStaked;
        uint256 lpTokensReceived;
        uint256 baseTokensRemainder;
        uint256 gymnetTokensRemainder;
    }

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Harvest(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);

    event NewPoolAdded(uint256 indexed pid, address indexed lpToken, uint256 allocPoint);
    event PoolAllocPointUpdated(uint256 indexed pid, uint256 allocPoint);
    event StartBlockUpdated(uint256 newValue);
    event PoolCommissionUpdated(uint256 newValue);
    event AffilateCommissionUpdated(uint256 newValue);

    event WhitelistWallet(address indexed _wallet, bool whitelist);
    event SetTreasuryAddress(address indexed _address);
    event SetBuyAndBurnAddress(address indexed _address);
    event SetRewardTokenAddress(address indexed _address);
    event SetGymMLMAddress(address indexed _address);
    event SetGymMLMQualificationsAddress(address indexed _address);
    event SetGymLevelPoolAddress(address indexed _address);
    event SetWBNBAddress(address indexed _address);
    event SetBUSDAddress(address indexed _address);
    event SetPancakeRouterAddress(address indexed _address);

    event SwapBNBForBUSD(address indexed user, uint256 spent, uint256 received);

    function initialize(
        address _buyAndBurnAddress,
        address _rewardToken,
        address _mlmAddress,
        address _mlmQualificationsAddress,
        address _levelPoolAddress,
        address _treasury,
        address _wbnbAddress,
        address _busdAddress,
        address _routerAddress,
        uint256 _rewardPerBlock,
        uint256 _startBlock
    ) public initializer {
        buyAndBurnAddress = _buyAndBurnAddress;
        rewardToken = _rewardToken;
        relationship = _mlmAddress;
        mlmQualificationsAddress = _mlmQualificationsAddress;
        levelPool = _levelPoolAddress;
        treasury = _treasury;
        wbnbAddress = _wbnbAddress;
        busdAddress = _busdAddress;
        routerAddress = _routerAddress;
        startBlock = _startBlock;
        poolComission = 6;
        rewardTokenToWBNB = [_rewardToken, wbnbAddress];

        __Ownable_init();
        __ReentrancyGuard_init();
        __RewardRateConfigurable_init(_rewardPerBlock, 864000);
    }

    modifier validAddress(address _address) {
        require(_address != address(0), "GymFarming: Zero address");
        _;
    }

    modifier poolExists(uint256 _pid) {
        require(_pid < poolInfo.length, "GymFarming: Unknown pool");
        _;
    }

    modifier validComission(uint256 commission) {
        require(commission < MAX_COMISSION_PERCENT, "GymFarming: Max comission 80%");
        _;
    }

    modifier hasInvestment(address _user) {
        require(
            IGymMLM(relationship).hasInvestment(_user),
            "GymFarming: only user with investment"
        );
        _;
    }

    modifier onlyMlmParticipant() {
        require(
            IGymMLM(relationship).addressToId(msg.sender) > 0,
            "GymFarming: You are not part of MLM"
        );
        _;
    }

    modifier onlyWhitelisted() {
        require(
            whitelist[msg.sender] || msg.sender == owner(),
            "GymFarming: not whitelisted or owner"
        );
        _;
    }

    receive() external payable {}

    fallback() external payable {}

    /**
     * @notice Function to set reward token
     * @param _address: address of reward token
     */
    function setRewardToken(address _address) external onlyOwner validAddress(_address) {
        rewardToken = _address;
        rewardTokenToWBNB = [_address, wbnbAddress];

        emit SetRewardTokenAddress(_address);
    }

    function setMLMAddress(address _address) external onlyOwner validAddress(_address) {
        relationship = _address;

        emit SetGymMLMAddress(_address);
    }

    function setIsDepositsOn(bool _isDepositsOn) external onlyOwner {
        isDepositsOn = _isDepositsOn;
    }

    function setLevelPoolAddress(address _address) external onlyOwner validAddress(_address) {
        levelPool = _address;

        emit SetGymLevelPoolAddress(_address);
    }

    /**
     * @notice Function to set treasury
     * @param _address: new treasury address
     */
    function setTreasuryAddress(address _address) external onlyOwner validAddress(_address) {
        treasury = _address;

        emit SetTreasuryAddress(_address);
    }

    function setMLMQualificationsAddress(address _address)
        external
        onlyOwner
        validAddress(_address)
    {
        mlmQualificationsAddress = _address;

        emit SetGymMLMQualificationsAddress(_address);
    }

    function setBUSDAddress(address _address) external onlyOwner validAddress(_address) {
        busdAddress = _address;

        emit SetBUSDAddress(_address);
    }

    function setStartBlock(uint256 _startBlock) external onlyOwner {
        startBlock = _startBlock;

        emit StartBlockUpdated(_startBlock);
    }

    function setWBNBAddress(address _address) external onlyOwner validAddress(_address) {
        wbnbAddress = _address;
        rewardTokenToWBNB[1] = _address;

        emit SetWBNBAddress(_address);
    }

    function setRouterAddress(address _address) external onlyOwner validAddress(_address) {
        routerAddress = _address;

        emit SetPancakeRouterAddress(_address);
    }

    function setBuyAndBurnAddress(address _address) external onlyOwner validAddress(_address) {
        buyAndBurnAddress = _address;

        emit SetBuyAndBurnAddress(_address);
    }

    /**
     * @notice Function to set comission on claim
     * @param _comission: value between 0 and 80
     */
    function setAffilateComission(uint256 _comission)
        external
        onlyOwner
        validComission(_comission)
    {
        affilateComission = _comission;

        emit AffilateCommissionUpdated(_comission);
    }

    /**
     * @notice Function to set comission on claim
     * @param _comission: value between 0 and 80
     */
    function setPoolComission(uint256 _comission) external onlyOwner validComission(_comission) {
        poolComission = _comission;

        emit PoolCommissionUpdated(_comission);
    }

    /**
     * @notice Function to set amount of reward per block
     */
    function setRewardConfiguration(uint256 _rewardPerBlock, uint256 _rewardUpdateBlocksInterval)
        external
        onlyOwner
    {
        massUpdatePools();

        _setRewardConfiguration(_rewardPerBlock, _rewardUpdateBlocksInterval);
    }

    /**
     * @notice Add or remove wallet to/from whitelist, callable only by contract owner
     *         whitelisted wallet will be able to call functions
     *         marked with onlyWhitelisted modifier
     * @param _wallet wallet to whitelist
     * @param _whitelist boolean flag, add or remove to/from whitelist
     */
    function whitelistAddress(address _wallet, bool _whitelist) external onlyOwner {
        whitelist[_wallet] = _whitelist;

        emit WhitelistWallet(_wallet, _whitelist);
    }

    function setlastRewardBlock(
        uint256 _pid,
        uint256 _lastRewardBlock,
        uint256 _accRewardPerShare
    ) external onlyOwner {
        poolInfo[_pid].lastRewardBlock = _lastRewardBlock;
        poolInfo[_pid].accRewardPerShare = _accRewardPerShare;
    }

    function isWhitelisted(address wallet) external view returns (bool) {
        return whitelist[wallet];
    }

    /**
     * @notice Add a new lp to the pool. Can only be called by the owner
     * @param _allocPoint: allocPoint for new pool
     * @param _lpToken: address of lpToken for new pool
     */
    function add(uint256 _allocPoint, address _lpToken) external onlyOwner {
        require(!isPoolExist[address(_lpToken)], "GymFarming: Duplicate pool");
        require(_isSupportedLP(_lpToken), "GymFarming: Unsupported liquidity pool");

        massUpdatePools();

        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint += _allocPoint;

        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accRewardPerShare: 0
            })
        );

        isPoolExist[address(_lpToken)] = true;

        uint256 pid = poolInfo.length - 1;

        emit NewPoolAdded(pid, _lpToken, _allocPoint);
    }

    /**
     * @notice Update the given pool's reward allocation point. Can only be called by the owner
     */
    function set(uint256 _pid, uint256 _allocPoint) external onlyOwner poolExists(_pid) {
        massUpdatePools();

        totalAllocPoint = totalAllocPoint - poolInfo[_pid].allocPoint + _allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;

        emit PoolAllocPointUpdated(_pid, _allocPoint);
    }

    /**
     * @notice Swap BNB for BUSD using full msg.value amount
     */
    function swapToBUSD(uint256 _deadline) external payable nonReentrant {
        uint256 inputAmount = msg.value;

        require(inputAmount > 0, "GymFarming: Nothing to swap");

        uint256 busdReceived = _swapTokens(
            wbnbAddress,
            busdAddress,
            inputAmount,
            0,
            msg.sender,
            _deadline
        );

        emit SwapBNBForBUSD(msg.sender, inputAmount, busdReceived);
    }

    /**
     * @notice Deposit LP tokens to GymFarming for reward allocation
     * @param _pid: pool ID on which LP tokens should be deposited
     * @param _amount: the amount of LP tokens that should be deposited
     */
    function deposit(uint256 _pid, uint256 _amount)
        external
        nonReentrant
        poolExists(_pid)
        onlyMlmParticipant
    {
        updatePool(_pid);

        require(
            IERC20Upgradeable(poolInfo[_pid].lpToken).balanceOf(msg.sender) >= _amount,
            "GymFarming: Insufficient LP balance"
        );

        IERC20Upgradeable(poolInfo[_pid].lpToken).safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );

        IPancakePair pair = IPancakePair(poolInfo[_pid].lpToken);

        uint256 totalSupply = pair.totalSupply();

        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
        (uint256 reserveGymnet, uint256 reserveBaseToken) = pair.token0() == rewardToken
            ? (reserve0, reserve1)
            : (reserve1, reserve0);

        AddLiquidityResult memory liquidityData;

        liquidityData.lpTokensReceived = _amount;
        liquidityData.baseTokensStaked = (_amount * reserveBaseToken) / totalSupply;
        liquidityData.gymnetTokensStaked = (_amount * reserveGymnet) / totalSupply;

        _updateUserInfo(_pid, msg.sender, liquidityData);

        emit Deposit(msg.sender, _pid, liquidityData.lpTokensReceived);
    }

    /**
     * @notice Function which take ETH & tokens or tokens & tokens, add liquidity with provider and deposit given LP's
     * @param _pid: pool ID where we want deposit
     * @param _baseTokenAmount: amount of token pool base token for staking (used for BUSD, use 0 for BNB pool)
     * @param _gymnetTokenAmount: amount of GYMNET token for staking
     * @param _amountAMin: bounds the extent to which the B/A price can go up before the transaction reverts.
        Must be <= amountADesired.
     * @param _amountBMin: bounds the extent to which the A/B price can go up before the transaction reverts.
        Must be <= amountBDesired
     * @param _minAmountOutA: the minimum amount of output A tokens that must be received
        for the transaction not to revert
     * @param _deadline transaction deadline timestamp
     * @param _minBurnAmt minimum amount of tokens to be burnt
     */
    function speedStake(
        uint256 _pid,
        uint256 _baseTokenAmount,
        uint256 _gymnetTokenAmount,
        uint256 _amountAMin,
        uint256 _amountBMin,
        uint256 _minAmountOutA,
        uint256 _deadline,
        uint256 _minBurnAmt
    ) external payable nonReentrant poolExists(_pid) hasInvestment(msg.sender) onlyMlmParticipant {
        require(isDepositsOn, "Deposits are temporary disabled");
        require(
            _baseTokenAmount == 0 || msg.value == 0,
            "GymFarming: Cannot pass both BNB and BEP-20 assets"
        );

        updatePool(_pid);

        if (_gymnetTokenAmount > 0) {
            IERC20Upgradeable(rewardToken).safeTransferFrom(
                msg.sender,
                address(this),
                _gymnetTokenAmount
            );
        }

        _deposit(
            _pid,
            _baseTokenAmount,
            _gymnetTokenAmount,
            _amountAMin,
            _amountBMin,
            _minAmountOutA,
            _deadline,
            _minBurnAmt
        );
    }

    /**
     * @notice Deposit LP tokens to GymFarming from GymVaultsBank
     * @param _pid: pool ID on which LP tokens should be deposited
     * @param _gymnetTokenAmount: the amount of reward tokens that should be converted to LP tokens
        and deposits to GymFarming contract
     * @param _from: Address of user that called function from GymVaultsBank
     */
    function depositFromOtherContract(
        uint256 _pid,
        uint256 _gymnetTokenAmount,
        address _from
    ) external nonReentrant poolExists(_pid) onlyWhitelisted {
        IPancakeswapPair lpToken = IPancakeswapPair(poolInfo[_pid].lpToken);
        bool isBnbPool = _isBnbPool(lpToken);
        address poolBaseToken = _getPoolBaseTokenFromPair(lpToken);
        uint256 poolBaseTokenAmount = 0;
        uint256 deadline = block.timestamp + 100;

        updatePool(_pid);

        if (_gymnetTokenAmount == 0) {
            return;
        }

        IERC20Upgradeable(rewardToken).safeTransferFrom(
            msg.sender,
            address(this),
            _gymnetTokenAmount
        );

        IERC20Upgradeable(rewardToken).safeApprove(routerAddress, 0);
        IERC20Upgradeable(rewardToken).safeApprove(routerAddress, _gymnetTokenAmount);

        if (isBnbPool) {
            uint256 contractBalance = address(this).balance;

            IPancakeRouter02(routerAddress).swapExactTokensForETHSupportingFeeOnTransferTokens(
                _gymnetTokenAmount,
                0,
                rewardTokenToWBNB,
                address(this),
                deadline
            );

            poolBaseTokenAmount = address(this).balance - contractBalance;
        } else {
            uint256 contractBalance = IERC20Upgradeable(poolBaseToken).balanceOf(address(this));

            address[] memory path = new address[](2);

            path[0] = rewardToken;
            path[1] = poolBaseToken;

            IPancakeRouter02(routerAddress).swapExactTokensForTokensSupportingFeeOnTransferTokens(
                _gymnetTokenAmount,
                0,
                path,
                address(this),
                deadline
            );

            poolBaseTokenAmount =
                IERC20Upgradeable(poolBaseToken).balanceOf(address(this)) -
                contractBalance;
        }

        AddLiquidityResult memory result = _addLiquidity(
            poolBaseToken,
            poolBaseTokenAmount, // pool base token amount
            0, // gymnet token amount
            0, // amount A min
            0, // amount B min
            0,
            deadline,
            true // split poolBaseTokenAmount in half and swap one half for gymnet
        );

        _updateUserInfo(_pid, _from, result);
        _refundRemainderTokens(_from, poolBaseToken, result);

        emit Deposit(_from, _pid, result.lpTokensReceived);
    }

    /**
     * @notice Function which send accumulated reward tokens to messege sender
     * @param _pid: pool ID from which the accumulated reward tokens should be received
     */
    function harvest(uint256 _pid) external nonReentrant poolExists(_pid) onlyMlmParticipant {
        _harvest(_pid, msg.sender);
    }

    /**
     * @notice Function which send accumulated reward tokens to messege sender from all pools
     */
    function harvestAll() external nonReentrant onlyMlmParticipant {
        uint256 length = poolInfo.length;

        for (uint256 pid = 0; pid < length; ++pid) {
            if (poolInfo[pid].allocPoint > 0) {
                _harvest(pid, msg.sender);
            }
        }
    }

    /**
     * @notice Function which withdraw LP tokens to messege sender with the given amount
     * @param _pid: pool ID from which the LP tokens should be withdrawn
     */
    function withdraw(uint256 _pid) external nonReentrant poolExists(_pid) onlyMlmParticipant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        uint256 withdrawAmount = user.lpTokensAmount;

        updatePool(_pid);

        uint256 pending = (withdrawAmount * pool.accRewardPerShare) / 1e18 - user.rewardDebt;

        safeRewardTransfer(user, msg.sender, pending);

        emit Harvest(msg.sender, _pid, pending);

        user.lpTokensAmount = 0;
        user.rewardDebt = 0;
        user.totalDepositTokens = 0;
        user.totalDepositDollarValue = 0;

        IERC20Upgradeable(pool.lpToken).safeTransfer(msg.sender, withdrawAmount);

        _updateLevelPoolQualification(msg.sender);

        emit Withdraw(msg.sender, _pid, withdrawAmount);
    }

    /// @return All pools amount
    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    /**
     * @notice View function to see total pending rewards on frontend
     * @param _user: user address for which reward must be calculated
     * @return total Return reward for user
     */
    function pendingRewardTotal(address _user) external view returns (uint256 total) {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            total += pendingReward(pid, _user);
        }
    }

    function getUserInfo(uint256 _pid, address _user)
        external
        view
        poolExists(_pid)
        returns (UserInfo memory)
    {
        return userInfo[_pid][_user];
    }

    /**
     * @notice Get USD amount of user deposits in all farming pools
     * @param _user user address
     * @return uint256 total amount in USD
     */
    function getUserUsdDepositAllPools(address _user) external view returns (uint256) {
        uint256 usdDepositAllPools = 0;

        for (uint256 pid = 0; pid < poolInfo.length; ++pid) {
            usdDepositAllPools += userInfo[pid][_user].totalDepositDollarValue;
        }

        return usdDepositAllPools;
    }

    /**
     * @notice Update reward vairables for all pools
     */
    function massUpdatePools() public {
        uint256 length = poolInfo.length;

        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    /**
     * @notice Update reward variables of the given pool to be up-to-date
     * @param _pid: pool ID for which the reward variables should be updated
     */
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];

        if (block.number <= pool.lastRewardBlock) {
            return;
        }

        uint256 lpSupply = IERC20Upgradeable(pool.lpToken).balanceOf(address(this));

        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }

        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 reward = (multiplier * pool.allocPoint) / totalAllocPoint;

        pool.accRewardPerShare = pool.accRewardPerShare + ((reward * 1e18) / lpSupply);
        pool.lastRewardBlock = block.number;

        // Update rewardPerBlock AFTER pool was updated
        _updateRewardPerBlock();
    }

    /**
     * @param _from: block block from which the reward is calculated
     * @param _to: block block before which the reward is calculated
     * @return Return reward multiplier over the given _from to _to block
     */
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        return (getRewardPerBlock() * (_to - _from));
    }

    /**
     * @notice View function to see pending rewards on frontend
     * @param _pid: pool ID for which reward must be calculated
     * @param _user: user address for which reward must be calculated
     * @return Return reward for user
     */
    function pendingReward(uint256 _pid, address _user)
        public
        view
        poolExists(_pid)
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];

        uint256 accRewardPerShare = pool.accRewardPerShare;
        uint256 lpSupply = IERC20Upgradeable(pool.lpToken).balanceOf(address(this));

        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 reward = (multiplier * pool.allocPoint) / totalAllocPoint;
            accRewardPerShare = accRewardPerShare + ((reward * 1e18) / lpSupply);
        }

        return (user.lpTokensAmount * accRewardPerShare) / 1e18 - user.rewardDebt;
    }

    /**
     * @notice Contract private function to process user deposit.
        1. Transfer pool base tokens to this contract if _baseTokenAmount > 0
        2. Swap gymnet tokens for pool base token
        3. Buy and burn GYMNET using pool base token
        4. Provide liquidity using 50/50 split of pool base tokens:
            a. 50% of pool base tokens used as is
            b. 50% used to buy GYMNET tokens
            c. Add both amounts to liquidity pool
        5. Update user deposit information
     * @param _pid pool id
     * @param _baseTokenAmount amount of pool base tokens provided by user
     * @param _gymnetTokenAmount amount if GYMNET tokens provided by user
     * @param _amountAMin: bounds the extent to which the B/A price can go up before the transaction reverts.
        Must be <= amountADesired.
     * @param _amountBMin: bounds the extent to which the A/B price can go up before the transaction reverts.
        Must be <= amountBDesired
     * @param _minAmountOutA: the minimum amount of output A tokens that must be received
        for the transaction not to revert
     * @param _deadline transaction deadline timestamp
     * @param _minBurnAmt minimum amount of tokens to be burnt
     */
    function _deposit(
        uint256 _pid,
        uint256 _baseTokenAmount,
        uint256 _gymnetTokenAmount,
        uint256 _amountAMin,
        uint256 _amountBMin,
        uint256 _minAmountOutA,
        uint256 _deadline,
        uint256 _minBurnAmt
    ) private {
        IPancakeswapPair lpToken = IPancakeswapPair(address(poolInfo[_pid].lpToken));
        address poolBaseToken = _getPoolBaseTokenFromPair(lpToken);
        uint256 poolBaseTokenAmount = _isBnbPool(lpToken) ? msg.value : _baseTokenAmount;
        uint256 gymnetTokenAmount = _gymnetTokenAmount;

        bool splitAndSwap = gymnetTokenAmount == 0 ? true : false;

        if (_isBnbPool(lpToken)) {
            require(_baseTokenAmount == 0, "GymFarming: only BNB tokens expected");
        } else {
            require(msg.value == 0, "GymFarming: only BEP-20 tokens expected");
        }

        if (_baseTokenAmount > 0) {
            IERC20Upgradeable(poolBaseToken).safeTransferFrom(
                msg.sender,
                address(this),
                _baseTokenAmount
            );
        }

        if (gymnetTokenAmount > 0 && poolBaseTokenAmount == 0) {
            IERC20Upgradeable(rewardToken).safeApprove(routerAddress, 0);
            IERC20Upgradeable(rewardToken).safeApprove(routerAddress, gymnetTokenAmount);

            poolBaseTokenAmount = _swapTokens(
                rewardToken,
                poolBaseToken,
                gymnetTokenAmount,
                0,
                address(this),
                _deadline
            );

            gymnetTokenAmount = 0;
            splitAndSwap = true;
        }

        {
            // scope to avoid stack too deep errors
            uint256 baseTokenToBurn = _percentage(poolBaseTokenAmount, BUY_BACK_COMMISION);
            _buyAndBurnTokens(poolBaseToken, baseTokenToBurn, _minBurnAmt, _deadline);
            poolBaseTokenAmount -= baseTokenToBurn;

            if (gymnetTokenAmount > 0 && !splitAndSwap) {
                uint256 gymnetToBurn = _percentage(gymnetTokenAmount, BUY_BACK_COMMISION);
                _burnGymnet(gymnetToBurn);

                gymnetTokenAmount -= gymnetToBurn;
            }
        }

        AddLiquidityResult memory result = _addLiquidity(
            poolBaseToken,
            poolBaseTokenAmount,
            gymnetTokenAmount,
            _amountAMin,
            _amountBMin,
            _minAmountOutA,
            _deadline,
            splitAndSwap
        );

        _updateUserInfo(_pid, msg.sender, result);
        _refundRemainderTokens(msg.sender, poolBaseToken, result);

        emit Deposit(msg.sender, _pid, result.lpTokensReceived);
    }

    /**
     * @notice Function to swap exact amount of tokens A for tokens B
     * @param inputToken have token address
     * @param outputToken want token address
     * @param inputAmount have token amount
     * @param amountOutMin the minimum amount of output tokens that must be
        received for the transaction not to revert.
     * @param receiver want tokens receiver address
     * @param deadline swap transaction deadline
     * @return uint256 amount of want tokens received
     */
    function _swapTokens(
        address inputToken,
        address outputToken,
        uint256 inputAmount,
        uint256 amountOutMin,
        address receiver,
        uint256 deadline
    ) private returns (uint256) {
        require(inputToken != outputToken, "GymFarming: Invalid swap path");

        address[] memory path = new address[](2);

        path[0] = inputToken;
        path[1] = outputToken;

        uint256[] memory swapResult;

        if (inputToken == wbnbAddress) {
            swapResult = IPancakeRouter02(routerAddress).swapExactETHForTokens{value: inputAmount}(
                amountOutMin,
                path,
                receiver,
                deadline
            );
        } else if (outputToken == wbnbAddress) {
            swapResult = IPancakeRouter02(routerAddress).swapExactTokensForETH(
                inputAmount,
                amountOutMin,
                path,
                receiver,
                deadline
            );
        } else {
            swapResult = IPancakeRouter02(routerAddress).swapExactTokensForTokens(
                inputAmount,
                amountOutMin,
                path,
                receiver,
                deadline
            );
        }

        return swapResult[1];
    }

    /**
     * @notice Buy tokens from exchange and burn them
     * @param paymentToken token to pay with
     * @param spentAmount amount of tokens to spent on buy
     * @param minBurnAmount minimum amount of tokens to burn
     * @return burntAmount amount of burnt tokens
     */
    function _buyAndBurnTokens(
        address paymentToken,
        uint256 spentAmount,
        uint256 minBurnAmount,
        uint256 deadline
    ) private returns (uint256 burntAmount) {
        if (paymentToken == wbnbAddress) {
            IWETH(paymentToken).deposit{value: spentAmount}();
        }

        IERC20Upgradeable(paymentToken).safeTransfer(buyAndBurnAddress, spentAmount);

        if (paymentToken == wbnbAddress) {
            burntAmount = IBuyAndBurn(buyAndBurnAddress).buyAndBurnGymWithBNB(
                spentAmount,
                minBurnAmount,
                deadline
            );
        } else if (paymentToken == busdAddress) {
            burntAmount = IBuyAndBurn(buyAndBurnAddress).buyAndBurnGymWithBUSD(
                spentAmount,
                minBurnAmount,
                deadline
            );
        } else {
            revert("GymFarming: Unsupported payment token");
        }
    }

    function _addLiquidity(
        address _basePoolToken,
        uint256 _baseTokenAmount,
        uint256 _gymnetTokenAmount,
        uint256 _amountAMin,
        uint256 _amountBMin,
        uint256 _minAmountOut,
        uint256 _deadline,
        bool splitAndSwap
    ) private returns (AddLiquidityResult memory result) {
        uint256 baseTokensToLpAmount = _baseTokenAmount;
        uint256 gymnetToLpAmount = _gymnetTokenAmount;

        if (_basePoolToken == wbnbAddress) {
            if (splitAndSwap) {
                uint256 swapAmount = baseTokensToLpAmount / 2;

                gymnetToLpAmount = _swapTokens(
                    _basePoolToken,
                    rewardToken,
                    swapAmount,
                    _minAmountOut,
                    address(this),
                    _deadline
                );

                baseTokensToLpAmount -= swapAmount;
            }
            require(
                baseTokensToLpAmount >= _amountAMin,
                "GymFarming: insufficient pool base tokens"
            );
            require(gymnetToLpAmount >= _amountBMin, "GymFarming: insufficient GYMNET tokens");
            IERC20Upgradeable(rewardToken).safeApprove(routerAddress, 0);
            IERC20Upgradeable(rewardToken).safeApprove(routerAddress, gymnetToLpAmount);

            (
                result.gymnetTokensStaked,
                result.baseTokensStaked,
                result.lpTokensReceived
            ) = IPancakeRouter02(routerAddress).addLiquidityETH{value: baseTokensToLpAmount}(
                rewardToken,
                gymnetToLpAmount,
                _amountBMin,
                _amountAMin,
                address(this),
                _deadline
            );
        } else {
            if (splitAndSwap) {
                uint256 swapAmount = baseTokensToLpAmount / 2;

                IERC20Upgradeable(_basePoolToken).safeApprove(routerAddress, 0);
                IERC20Upgradeable(_basePoolToken).safeApprove(routerAddress, swapAmount);

                gymnetToLpAmount = _swapTokens(
                    _basePoolToken,
                    rewardToken,
                    swapAmount,
                    _minAmountOut,
                    address(this),
                    _deadline
                );

                baseTokensToLpAmount -= swapAmount;
            }

            IERC20Upgradeable(_basePoolToken).safeApprove(routerAddress, 0);
            IERC20Upgradeable(rewardToken).safeApprove(routerAddress, 0);

            IERC20Upgradeable(_basePoolToken).safeApprove(routerAddress, baseTokensToLpAmount);
            IERC20Upgradeable(rewardToken).safeApprove(routerAddress, gymnetToLpAmount);

            (
                result.baseTokensStaked,
                result.gymnetTokensStaked,
                result.lpTokensReceived
            ) = IPancakeRouter02(routerAddress).addLiquidity(
                _basePoolToken,
                rewardToken,
                baseTokensToLpAmount,
                gymnetToLpAmount,
                _amountAMin,
                _amountBMin,
                address(this),
                _deadline
            );
        }

        if (baseTokensToLpAmount > result.baseTokensStaked) {
            result.baseTokensRemainder = baseTokensToLpAmount - result.baseTokensStaked;
        }

        if (gymnetToLpAmount > result.gymnetTokensStaked) {
            result.gymnetTokensRemainder = gymnetToLpAmount - result.gymnetTokensStaked;
        }
    }

    /**
     * @notice Function which transfer reward tokens to _to with the given amount
     * @param _to: transfer reciver address
     * @param _amount: amount of reward token which should be transfer
     */
    function safeRewardTransfer(
        UserInfo storage user,
        address _to,
        uint256 _amount
    ) private {
        if (_amount > 0) {
            uint256 rewardTokenBal = IERC20Upgradeable(rewardToken).balanceOf(address(this));

            require(_amount < rewardTokenBal, "GymFarming: No sufficient rewards");
            uint256 comission = (_amount * affilateComission) / 100;

            IERC20Upgradeable(rewardToken).safeTransfer(relationship, comission);
            IGymMLM(relationship).distributeRewards(_amount, address(rewardToken), msg.sender, 2);

            uint256 poolComissionAmount = (_amount * poolComission) / 100;
            //Don't uncomment line below
            //IERC20Upgradeable(rewardToken).safeTransfer(treasury, poolComissionAmount);
            IERC20Upgradeable(rewardToken).safeTransfer(
                _to,
                (_amount - comission - poolComissionAmount)
            );
            user.totalClaims += (_amount - comission - poolComissionAmount);
        }
    }

    /**
     * @notice Function for updating user info
     */
    function _updateUserInfo(
        uint256 _pid,
        address _from,
        AddLiquidityResult memory liquidityData
    ) private {
        UserInfo storage user = userInfo[_pid][_from];
        address poolBaseToken = _getPoolBaseTokenFromPair(
            IPancakeswapPair(address(poolInfo[_pid].lpToken))
        );

        uint256 dollarValue = 0;

        _harvest(_pid, _from);

        user.totalDepositTokens += liquidityData.baseTokensStaked;
        user.totalDepositTokens += _getGymnetInBaseTokensAmount(
            liquidityData.gymnetTokensStaked,
            poolBaseToken
        );

        user.lpTokensAmount += liquidityData.lpTokensReceived;
        user.rewardDebt = (user.lpTokensAmount * poolInfo[_pid].accRewardPerShare) / 1e18;

        if (poolBaseToken == wbnbAddress) {
            dollarValue +=
                (liquidityData.baseTokensStaked * IGYMNETWORK(rewardToken).getBNBPrice()) /
                1e18;
        } else {
            dollarValue += liquidityData.baseTokensStaked / 1e18;
        }

        if (liquidityData.gymnetTokensStaked > 0) {
            dollarValue +=
                ((liquidityData.gymnetTokensStaked * IGYMNETWORK(rewardToken).getGYMNETPrice()) /
                    1e18) /
                1e18;
        }

        user.totalDepositDollarValue += dollarValue;

        _updateLevelPoolQualification(_from);
    }

    /**
     * @notice Private function which send accumulated reward tokens to givn address
     * @param _pid: pool ID from which the accumulated reward tokens should be received
     * @param _from: Recievers address
     */
    function _harvest(uint256 _pid, address _from) private poolExists(_pid) {
        UserInfo storage user = userInfo[_pid][_from];

        if (user.lpTokensAmount > 0) {
            updatePool(_pid);

            uint256 accRewardPerShare = poolInfo[_pid].accRewardPerShare;
            uint256 pending = (user.lpTokensAmount * accRewardPerShare) / 1e18 - user.rewardDebt;

            safeRewardTransfer(user, _from, pending);
            user.rewardDebt = (user.lpTokensAmount * accRewardPerShare) / 1e18;

            emit Harvest(_from, _pid, pending);
        }
    }

    function _updateLevelPoolQualification(address wallet) private {
        uint256 userLevel = IGymMLMQualifications(mlmQualificationsAddress).getUserCurrentLevel(
            wallet
        );

        IGymLevelPool(levelPool).updateUserQualification(wallet, userLevel);
    }

    /**
     * @notice Check if provided Pancakeswap Pair contains WNBN token
     * @param pair Pancakeswap pair contract
     * @return bool true if provided pair is WBNB/<Token> or <Token>/WBNB pair
                    false otherwise
     */
    function _isBnbPool(IPancakeswapPair pair) private view returns (bool) {
        IPancakeRouter02 router = IPancakeRouter02(routerAddress);

        return pair.token0() == router.WETH() || pair.token1() == router.WETH();
    }

    function _isSupportedLP(address pairAddress) private view returns (bool) {
        IPancakeswapPair pair = IPancakeswapPair(pairAddress);

        require(
            rewardToken == pair.token0() || rewardToken == pair.token1(),
            "GymFarming: not a GYMNET pair"
        );

        address baseToken = _getPoolBaseTokenFromPair(pair);

        return baseToken == wbnbAddress || baseToken == busdAddress || baseToken == rewardToken;
    }

    /**
     * @notice Get pool base token from Pancakeswap Pair. Base token - BUSD or WBNB
               Reverts for unsupported pool (not WBNB or BUSD)
     * @param pair Pancakeswap pair contract
     * @return address pool base token address
     */
    function _getPoolBaseTokenFromPair(IPancakeswapPair pair) private view returns (address) {
        return pair.token0() == rewardToken ? pair.token1() : pair.token0();
    }

    function _percentage(uint256 amount, uint256 percent) private pure returns (uint256) {
        return (amount * percent) / 100;
    }

    function _burnGymnet(uint256 amount) private {
        IERC20Burnable(rewardToken).burn(amount);
    }

    function _refundRemainderTokens(
        address user,
        address poolBaseToken,
        AddLiquidityResult memory liquidityData
    ) private {
        if (liquidityData.baseTokensRemainder > 0) {
            if (poolBaseToken == wbnbAddress) {
                payable(user).transfer(liquidityData.baseTokensRemainder);
            } else {
                IERC20Upgradeable(poolBaseToken).safeTransfer(
                    user,
                    liquidityData.baseTokensRemainder
                );
            }
        }

        if (liquidityData.gymnetTokensRemainder > 0) {
            IERC20Upgradeable(rewardToken).safeTransfer(user, liquidityData.gymnetTokensRemainder);
        }
    }

    function _getGymnetInBaseTokensAmount(uint256 gymnetAmount, address poolBaseToken)
        private
        view
        returns (uint256)
    {
        if (poolBaseToken == wbnbAddress) {
            return
                IPancakeRouter02(routerAddress).getAmountsOut(gymnetAmount, rewardTokenToWBNB)[1];
        } else {
            address[] memory path = new address[](2);

            path[0] = rewardToken;
            path[1] = poolBaseToken;

            return IPancakeRouter02(routerAddress).getAmountsOut(gymnetAmount, path)[1];
        }
    }

    function seedUsers(address[] calldata users, uint256[] calldata lpAmounts)
        external
        nonReentrant
        onlyOwner
    {
        require(users.length == lpAmounts.length, "GymFarming: length mismatch");

        uint256 gymnetPrice = IGYMNETWORK(rewardToken).getGYMNETPrice();
        uint256 bnbPrice = IGYMNETWORK(rewardToken).getBNBPrice();

        IPancakePair pair = IPancakePair(poolInfo[0].lpToken);
        uint256 lpTotalSupply = pair.totalSupply();
        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
        (uint256 reserveGymnet, uint256 reserveBaseToken) = pair.token0() == rewardToken
            ? (reserve0, reserve1)
            : (reserve1, reserve0);

        for (uint256 i = 0; i < users.length; ) {
            UserInfo storage user = userInfo[0][users[i]];

            uint256 bnbStaked = 0;
            uint256 gymnetStaked = 0;

            unchecked {
                bnbStaked = (lpAmounts[i] * reserveBaseToken) / lpTotalSupply;
                gymnetStaked = (lpAmounts[i] * reserveGymnet) / lpTotalSupply;
            }

            uint256 depositDollarValue = (bnbStaked * bnbPrice) /
                1e18 +
                (gymnetStaked * gymnetPrice) /
                1e36;

            unchecked {
                user.lpTokensAmount += lpAmounts[i];
                user.totalDepositDollarValue += depositDollarValue;
                user.rewardDebt = (user.lpTokensAmount * poolInfo[0].accRewardPerShare) / 1e18;

                i += 1;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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

interface IBuyAndBurn {
    function buyAndBurnGymWithBNB(
        uint256,
        uint256,
        uint256
    ) external returns (uint256);

    function buyAndBurnGymWithBUSD(
        uint256,
        uint256,
        uint256
    ) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IGymLevelPool {
    function updateUserQualification(address _wallet, uint256 _level) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

interface IGymMLM {
    function addGymMLM(address, uint256) external;

    function addGymMLMNFT(address, uint256) external;

    function distributeRewards(
        uint256,
        address,
        address,
        uint32
    ) external;

    function updateInvestment(address _user, bool _isInvesting) external;

    function getPendingRewards(address, uint32) external view returns (uint256);

    function hasInvestment(address) external view returns (bool);

    function addressToId(address) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

interface IGymMLMQualifications {
    struct RockstarLevel {
        uint64 qualificationLevel;
        uint64 usdAmountVault;
        uint64 usdAmountFarm;
        uint64 usdAmountPool;
    }

    function addDirectPartner(address, address) external;

    function getUserCurrentLevel(address) external view returns (uint32);

    function directPartners(address) external view returns (address[] memory);

    function getRockstarAmount(uint32 _rank) external view returns (RockstarLevel memory);

    function updateRockstarRank(
        address,
        uint8,
        bool
    ) external;

    function getDirectPartners(address) external view returns (address[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

interface IGYMNETWORK {
    function getGYMNETPrice() external view returns (uint256);

    function getBNBPrice() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IGymSinglePool {
    struct UserInfo {
        uint256 totalDepositTokens;
        uint256 totalDepositDollarValue;
        uint256 totalGGYMNET;
        uint256 level;
        uint256 depositId;
        uint256 totalClaimt;
    }

    function getUserInfo(address) external view returns (UserInfo memory);

    function pendingRewardTotal(address) external view returns (uint256);

    function getUserLevelInSinglePool(address) external view returns (uint32);

    function totalGGymnetInPoolLocked() external view returns (uint256);

    function depositFromOtherContract(
        uint256,
        uint8,
        bool,
        address
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "./IPancakeRouter01.sol";

interface IPancakeRouter02 is IPancakeRouter01 {
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

interface IPancakeswapPair {
    function balanceOf(address owner) external view returns (uint256);

    function token0() external view returns (address);

    function token1() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

interface IStrategy {
    // Total want tokens managed by strategy
    function wantLockedTotal() external view returns (uint256);

    // Sum of all shares of users to wantLockedTotal
    function sharesTotal() external view returns (uint256);

    function wantAddress() external view returns (address);

    function token0Address() external view returns (address);

    function token1Address() external view returns (address);

    function earnedAddress() external view returns (address);

    function ratio0() external view returns (uint256);

    function ratio1() external view returns (uint256);

    function getPricePerFullShare() external view returns (uint256);

    // Main want token compounding function
    function earn(uint256 _amountOutAmt, uint256 _deadline) external;

    // Transfer want tokens autoFarm -> strategy
    function deposit(address _userAddress, uint256 _wantAmt) external returns (uint256);

    // Transfer want tokens strategy -> autoFarm
    function withdraw(address _userAddress, uint256 _wantAmt) external returns (uint256);

    /// Buy burn alpaca reward tokens
    function buyAndBurn() external;

    function migrateFrom(
        address _oldStrategy,
        uint256 _oldWantLockedTotal,
        uint256 _oldSharesTotal
    ) external;

    function inCaseTokensGetStuck(
        address _token,
        uint256 _amount,
        address _to
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256 wad) external;

    function transfer(address dst, uint256 wad) external;

    function balanceOf(address dst) external view returns (uint256);

    event Deposit(address indexed dst, uint256 wad);
    event Withdrawal(address indexed src, uint256 wad);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract RewardRateConfigurable is Initializable {
    struct RewardsConfiguration {
        uint256 rewardPerBlock;
        uint256 lastUpdateBlockNum;
        uint256 updateBlocksInterval;
    }

    uint256 public constant REWARD_PER_BLOCK_MULTIPLIER = 967742;
    uint256 public constant DIVIDER = 1e6;

    RewardsConfiguration private rewardsConfiguration;

    event RewardPerBlockUpdated(uint256 oldValue, uint256 newValue);

    function __RewardRateConfigurable_init(
        uint256 _rewardPerBlock,
        uint256 _rewardUpdateBlocksInterval
    ) internal onlyInitializing {
        __RewardRateConfigurable_init_unchained(_rewardPerBlock, _rewardUpdateBlocksInterval);
    }

    function __RewardRateConfigurable_init_unchained(
        uint256 _rewardPerBlock,
        uint256 _rewardUpdateBlocksInterval
    ) internal onlyInitializing {
        rewardsConfiguration.rewardPerBlock = _rewardPerBlock;
        rewardsConfiguration.lastUpdateBlockNum = block.number;
        rewardsConfiguration.updateBlocksInterval = _rewardUpdateBlocksInterval;
    }

    function getRewardsConfiguration() public view returns (RewardsConfiguration memory) {
        return rewardsConfiguration;
    }

    function getRewardPerBlock() public view returns (uint256) {
        return rewardsConfiguration.rewardPerBlock;
    }

    function _setRewardConfiguration(uint256 rewardPerBlock, uint256 updateBlocksInterval)
        internal
    {
        uint256 oldRewardValue = rewardsConfiguration.rewardPerBlock;

        rewardsConfiguration.rewardPerBlock = rewardPerBlock;
        rewardsConfiguration.lastUpdateBlockNum = block.number;
        rewardsConfiguration.updateBlocksInterval = updateBlocksInterval;

        emit RewardPerBlockUpdated(oldRewardValue, rewardPerBlock);
    }

    function _updateRewardPerBlock() internal {
        if (
            (block.number - rewardsConfiguration.lastUpdateBlockNum) <
            rewardsConfiguration.updateBlocksInterval
        ) {
            return;
        }

        uint256 rewardPerBlockOldValue = rewardsConfiguration.rewardPerBlock;

        rewardsConfiguration.rewardPerBlock =
            (rewardPerBlockOldValue * REWARD_PER_BLOCK_MULTIPLIER) / DIVIDER;

        rewardsConfiguration.lastUpdateBlockNum = block.number;

        emit RewardPerBlockUpdated(rewardPerBlockOldValue, rewardsConfiguration.rewardPerBlock);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IERC20Burnable is IERC20Upgradeable {
    function burn(uint256 _amount) external;

    function burnFrom(address _account, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IPancakePair {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
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
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

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
        bool isTopLevelCall = _setInitializedVersion(1);
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
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
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
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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

pragma solidity 0.8.15;

interface IPancakeRouter01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}