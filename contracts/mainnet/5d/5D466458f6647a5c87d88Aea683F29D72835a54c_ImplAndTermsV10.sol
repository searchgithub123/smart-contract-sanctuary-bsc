// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../ERC20Init.sol";
import "../Storage.sol";
import "../utils/DoTransfer.sol";

contract ImplAndTermsV10 is Storage, Ownable, DoTransfer, ERC20Init {
    address public manager;
    address public stakeToken;

    bool public stakeIsPaused;
    bool public unstakeIsPaused;

    uint public refererBonusPercent;
    uint public influencerBonusPercent;
    uint public developerBonusPercent;
    uint public timeBonusPercent;

    uint public timeNormalizer;
    uint public unHoldFee;
    uint public holdTimeRefMin;
    uint public holdTimeMax;

    // for inflation
    uint public inflationPercent;
    address public reservoir;
    uint public totalStaked;
    uint public accrualBlockTimestamp;
    uint public inflationRatePerSec;

    struct StakeData {
        uint stakeAmount;
        uint lpAmount;
        uint stakeTime;
        uint holdTime;
        bool active; // true is active
        uint closeRate;
        uint closeTime;
        uint closeAmount;
    }

    mapping(address => StakeData[]) public userStakes;
    mapping(uint => uint) public bonusTime; // for manager

    uint public maxDefaultApprovedReward;

    // user => stakeId => bool
    mapping(address => mapping(uint => bool)) public approvedRewards;
    mapping(address => mapping(uint => bool)) public sentRewards;

    event Stake(address indexed staker, uint userStakeId, uint stakeAmount, uint holdTime, uint lpAmountOut);
    event Unstake(address indexed staker, uint userStakeId, uint stakeTokenAmountOut, uint rate);

    event AccrueInterest(uint interestAccumulated, uint totalStaked);

    event ApproveRequest(address user, uint stakeId);

    function initialize(
        address ,
        address stakeToken_,
        address reservoir_,
        string memory name_,
        string memory symbol_
    ) public {
        require(stakeToken == address(0), "ImplAndTerms::initialize: may only be initialized once");

        require(
            stakeToken_ != address(0)
            && reservoir_ != address(0),
            "ImplAndTerms::initialize: address is 0"
        );

        stakeToken = stakeToken_;

        refererBonusPercent = 10e18; // 10%
        timeBonusPercent = 20e18; // 20%
        unHoldFee = 100e18; // 100%
        inflationPercent = 400e18; // 400%

        holdTimeRefMin = 1 days;
        holdTimeMax = 365 days;
        timeNormalizer = 365 days;

        bonusTime[30 days] = 5e18;
        bonusTime[90 days] = 20e18;
        bonusTime[180 days] = 40e18;

        reservoir = reservoir_;
        accrualBlockTimestamp = getBlockTimestamp();
        inflationRatePerSec = inflationPercent / 365 days;

        super.initialize(name_, symbol_);
    }

    function _setPause(bool stakeIsPaused_, bool unstakeIsPaused_) public onlyOwner returns (bool) {
        stakeIsPaused = stakeIsPaused_;
        unstakeIsPaused = unstakeIsPaused_;

        return true;
    }

    function _setManager(address manager_) public onlyOwner returns (bool) {
        manager = manager_;

        return true;
    }

    // transfer stake tokens from user to pool
    // mint lp tokens from pool to user
    function stake(uint tokenAmount) public {
        stakeInternal(msg.sender, tokenAmount, 0, address(0), address(0), false);
    }

    function stake(uint tokenAmount, uint holdTime) public {
        stakeInternal(msg.sender, tokenAmount, holdTime, address(0), address(0), false);
    }

    function stake(uint tokenAmount, uint holdTime, address referer) public {
        stakeInternal(msg.sender, tokenAmount, holdTime, referer, address(0), false);
    }

    // mint lp tokens from pool to beneficiary
    function stake(uint tokenAmount, uint holdTime, address referer, address beneficiary) public {
        if (msg.sender == manager) {
            stakeInternal(msg.sender, tokenAmount, holdTime, address(0), beneficiary, true);
        } else {
            stakeInternal(msg.sender, tokenAmount, holdTime, referer, beneficiary, false);
        }
    }

    function stakeInternal(address staker, uint tokenAmount, uint holdTime, address referer, address beneficiary, bool harvest) internal {
        require(!stakeIsPaused, 'ImplAndTerms::stakeInternal: stake is paused');

        require(
            referer != staker,
            "ImplAndTerms::stakeInternal: referer address must not match staker address"
        );
        require(holdTime <= holdTimeMax, "ImplAndTerms::stakeInternal: hold time must be less than holdTimeMax");

        accrueInterest();

        uint amountIn = doTransferIn(staker, stakeToken, tokenAmount);

        if (holdTime > 0) {
            holdTime = holdTime - holdTime % 86400;
        }

        if (harvest) {
            require(
                beneficiary != address(0),
                "ImplAndTerms::stakeInternal: beneficiary address is 0"
            );

            stakeFresh(beneficiary, amountIn, holdTime);
        } else if (beneficiary != address(0)) {
            stakeFresh(beneficiary, amountIn, holdTime);
        } else {
            stakeFresh(staker, amountIn, holdTime);
        }

        totalStaked += amountIn;
    }

    function stakeFresh(address staker, uint stakeAmount, uint holdTime) internal {
        _mint(staker, 1);

        userStakes[staker].push(
            StakeData({
                stakeAmount: stakeAmount,
                lpAmount: 1,
                stakeTime: block.timestamp,
                holdTime: holdTime,
                active: true,
                closeRate: 0,
                closeTime: 0,
                closeAmount: 0
            })
        );

        emit Stake(staker, userStakes[staker].length, stakeAmount, holdTime, 1);
    }

    function calcAllLPAmountOut(uint amountIn, uint holdTime, uint rate, bool harvest) public view returns (uint, uint, uint) {
        uint stakerLpAmountOut = calcStakerLPAmount(amountIn, holdTime, rate, harvest);
        uint refererLpAmountOut = calcRefererLPAmount(amountIn);
        uint totalAmount = stakerLpAmountOut + refererLpAmountOut;

        return (totalAmount, stakerLpAmountOut, refererLpAmountOut);
    }

    function calcStakerLPAmount(uint amountIn, uint holdTime, uint, bool) public view returns (uint) {
        return amountIn + calcBonusTime(amountIn, holdTime, false);
    }

    function calcBonusTime(uint amount, uint holdTime, bool) public view returns (uint) {
        return amount * holdTime * timeBonusPercent / 100e18 / timeNormalizer;
    }

    function calcRefererLPAmount(uint amount) public view returns (uint) {
        return amount * refererBonusPercent / 100e18;
    }

    // rate scaled by 1e18
    function getRate() public pure returns (uint) {
        return 1e18;
    }

    function _approveRewards(address user, uint[] calldata stakeIds) public onlyOwner returns (bool) {
        for (uint i = 0; i < stakeIds.length; i++) {
            approvedRewards[user][stakeIds[i]] = true;
        }

        return true;
    }

    function getApprovedUnstake(uint stakeId) public returns (bool) {
        require(approvedRewards[msg.sender][stakeId], "ImplAndTerms::unstake: unstake reward is not approved");
        require(!sentRewards[msg.sender][stakeId], "ImplAndTerms::unstake: unstake reward is sent");

        bool active;
        uint closeAmount;

        (,,,, active,,,closeAmount) = getUserStake(msg.sender, stakeId);

        require(!active, "ImplAndTerms::unstake: stake is active");
        require(closeAmount > 0, "ImplAndTerms::unstake: close amount is 0");

        approvedRewards[msg.sender][stakeId] = false;
        sentRewards[msg.sender][stakeId] = true;

        doTransferOut(stakeToken, msg.sender, closeAmount);

        return true;
    }

    function _setMinApprovedReward(uint maxDefaultApprovedReward_) public onlyOwner returns (bool) {
        maxDefaultApprovedReward = maxDefaultApprovedReward_;

        return true;
    }

    // burn lp tokens from user
    // transfer stake tokens from pool to user
    function unstake(uint[] calldata userStakeIds) external {
        require(!unstakeIsPaused, 'ImplAndTerms::unstake: unstake is paused');

        accrueInterest();

        uint allLpAmountOut;
        uint stakeTokenAmountOut;
        uint lpAmountOut;
        uint stakeTime;
        uint holdTime;
        bool active;
        uint amountOut;
        uint notApprovedStakeTokenAmountOut;
        uint stakeAmount;
        uint timeBonus;
        uint totalTimeBonus;

        for (uint i = 0; i < userStakeIds.length; i++) {
            require(userStakeIds[i] < userStakes[msg.sender].length, "ImplAndTerms::unstake: stake is not exist");

            (stakeAmount, lpAmountOut, stakeTime, holdTime, active,,,) = getUserStake(msg.sender, userStakeIds[i]);

            require(active, "ImplAndTerms::unstake: stake is not active");

            allLpAmountOut += lpAmountOut;
            amountOut = stakeAmount;
            amountOut += inflationRatePerSec * (block.timestamp - stakeTime) * stakeAmount / 100e18;

            stakeTokenAmountOut += amountOut;

            if (holdTime > (block.timestamp - stakeTime)) {
                timeBonus = calcBonusTime(stakeAmount, (block.timestamp - stakeTime), false);
            } else {
                timeBonus = calcBonusTime(stakeAmount, holdTime, false);
            }
            doTransferIn(reservoir, stakeToken, timeBonus);

            amountOut += timeBonus;
            totalTimeBonus += timeBonus;

            if (amountOut > maxDefaultApprovedReward) {
                notApprovedStakeTokenAmountOut += amountOut;

                emit ApproveRequest(msg.sender, userStakeIds[i]);
            }

            userStakes[msg.sender][userStakeIds[i]].active = false;
            userStakes[msg.sender][userStakeIds[i]].closeRate = 1e18;
            userStakes[msg.sender][userStakeIds[i]].closeTime = block.timestamp;
            userStakes[msg.sender][userStakeIds[i]].closeAmount = amountOut;

            emit Unstake(msg.sender, userStakeIds[i], amountOut, 1e18);
        }

        _burn(msg.sender, allLpAmountOut);
        totalStaked -= stakeTokenAmountOut;

        doTransferOut(stakeToken, msg.sender, stakeTokenAmountOut + totalTimeBonus - notApprovedStakeTokenAmountOut);
    }

    function calcAmountOut(uint stakeAmount, uint currentTimestamp, uint stakeTime, uint holdTime, uint) public view returns (uint) {
        uint tokenAmountOut = stakeAmount;

        uint feeAmount = 0;

        return tokenAmountOut > feeAmount ? tokenAmountOut - feeAmount : 0;
    }

    function calcFee(uint stakeAmount, uint currentTimestamp, uint stakeTime, uint holdTime, uint) public view returns (uint) {
        uint delta = (currentTimestamp - stakeTime);

        if (holdTime <= delta) {
            return 0;
        }

        return stakeAmount * unHoldFee * (holdTime - delta) / holdTime / 100e18;
    }

    function calcProfit(address user, uint userStakeId, uint rate) public view returns (uint, uint) {
        uint stakeTokenAmount;
        uint lpAmountIn;
        uint stakeTime;
        uint holdTime;
        bool active;

        (stakeTokenAmount, lpAmountIn, stakeTime, holdTime, active,,,) = getUserStake(user, userStakeId);

        require(active, "ImplAndTerms::calcProfit: stake is not active");

        uint tokenAmountOut = stakeTokenAmount * rate / 1e18;
        uint feeAmount = calcFee(stakeTokenAmount, block.timestamp, stakeTime, holdTime, rate);
        uint tokenAmountOutWithFee;

        if (tokenAmountOut >= feeAmount) {
            tokenAmountOutWithFee = tokenAmountOut - feeAmount;

            if (stakeTokenAmount >= tokenAmountOutWithFee) {
                return (0, stakeTokenAmount - tokenAmountOutWithFee);
            } else {
                return (tokenAmountOutWithFee - stakeTokenAmount, 0);
            }
        } else {
            return (0, stakeTokenAmount);
        }
    }

    function accrueInterest() public {
        /* Remember the initial block timestamp */
        uint currentBlockTimestamp = getBlockTimestamp();

        /* Short-circuit accumulating 0 interest */
        if (accrualBlockTimestamp == currentBlockTimestamp) {
            return;
        }

        /* Calculate the time of timestamps elapsed since the last accrual */
        uint timeDelta = currentBlockTimestamp - accrualBlockTimestamp;

        /*
         * Calculate the interest accumulated:
         *  interestAccumulated = inflationRatePerSec * timeDelta * totalStaked
         *  totalStakedNew = interestAccumulated + totalStaked
         */
        uint interestAccumulated = inflationRatePerSec * timeDelta * totalStaked / 100e18;
        doTransferIn(reservoir, stakeToken, interestAccumulated);

        totalStaked = totalStaked + interestAccumulated;

        /* We write the previously calculated values into storage */
        accrualBlockTimestamp = currentBlockTimestamp;

        emit AccrueInterest(interestAccumulated, totalStaked);
    }

    function getUserStake(address user_, uint id_) public view returns (uint, uint, uint, uint, bool, uint, uint, uint) {
        address user = user_;
        uint id = id_;

        return (
            userStakes[user][id].stakeAmount,
            userStakes[user][id].lpAmount,
            userStakes[user][id].stakeTime,
            userStakes[user][id].holdTime,
            userStakes[user][id].active,
            userStakes[user][id].closeRate,
            userStakes[user][id].closeTime,
            userStakes[user][id].closeAmount
        );
    }

    function getAllUserStakes(address user) public view returns (StakeData[] memory) {
        return userStakes[user];
    }

    function getActiveUserStakes(address user) public view returns (StakeData[] memory) {
        return getUserStakes(user, 0);
    }

    function getActiveUserStakesAndClosesLessThanSixMonth(address user) public view returns (StakeData[] memory) {
        return getUserStakes(user, 180 days);
    }

    function getUserStakes(address user, uint timestampBack) public view returns (StakeData[] memory) {
        StakeData[] memory allUserActiveStakesTmp = new StakeData[](userStakes[user].length);
        uint j = 0;
        for (uint i = 0; i < userStakes[user].length; i++) {
            if (userStakes[user][i].active || userStakes[user][i].closeTime > block.timestamp - timestampBack) {
                allUserActiveStakesTmp[j] = userStakes[user][i];
                j++;
            }
        }

        StakeData[] memory allUserActiveStakes = new StakeData[](j);
        for (uint i = 0; i < j; i++) {
            allUserActiveStakes[i] = allUserActiveStakesTmp[i];
        }

        return allUserActiveStakes;
    }

    function getActiveUserStakesIds(address user) public view returns (uint[] memory) {
        return getUserStakesIds(user, 0);
    }

    function getUserStakesIds(address user, uint timestampBack) public view returns (uint[] memory) {
        uint[] memory allUserActiveStakesIdsTmp = new uint[](userStakes[user].length);
        uint j = 0;
        for (uint i = 0; i < userStakes[user].length; i++) {
            if (userStakes[user][i].active || userStakes[user][i].closeTime > block.timestamp - timestampBack) {
                allUserActiveStakesIdsTmp[j] = i;
                j++;
            }
        }

        uint[] memory allUserActiveStakesIds = new uint[](j);
        for (uint i = 0; i < j; i++) {
            allUserActiveStakesIds[i] = allUserActiveStakesIdsTmp[i];
        }

        return allUserActiveStakesIds;
    }

    function getAllCurrentStakeAmount(address user) public view returns (uint) {
        uint allCurrentStakeAmount;

        for (uint i = 0; i < userStakes[user].length; i++) {
            if (userStakes[user][i].active) {
                allCurrentStakeAmount += userStakes[user][i].stakeAmount;
            }
        }

        return allCurrentStakeAmount;
    }

    function getTokenAmountAfterUnstake(address user, uint stakeUserId, uint rate) public view returns (uint) {
        StakeData memory stakeData = userStakes[user][stakeUserId];

        if (stakeData.active == false) {
            return userStakes[user][stakeUserId].closeAmount;
        }

        return calcAmountOut(stakeData.stakeAmount, block.timestamp, stakeData.stakeTime, stakeData.holdTime, rate);
    }

    function getTokenAmountAfterAllUnstakes(address user, uint rate) public view returns (uint) {
        uint stakeTokenAmountOut;

        for (uint i = 0; i < userStakes[user].length; i++) {
            stakeTokenAmountOut += getTokenAmountAfterUnstake(user, i, rate);
        }

        return stakeTokenAmountOut;
    }

    function getHarvestBonusTime(uint holdTime_) public view returns (uint) {
        return bonusTime[holdTime_];
    }

    function getAllHarvestHoldTimes() public pure returns (uint[3] memory) {
        return [uint(30 days), uint(90 days), uint(180 days)];
    }

    struct BonusTimeData {
        uint hold;
        uint bonus;
    }

    function getAllHarvestBonusTimeData() public view returns (BonusTimeData[] memory) {
        uint[3] memory holdTimes = getAllHarvestHoldTimes();
        BonusTimeData[] memory bonusTimes = new BonusTimeData[](holdTimes.length);

        uint tempHoldTime;
        for (uint i = 0; i < holdTimes.length; i++) {
            tempHoldTime = holdTimes[i];

            bonusTimes[i] =
            BonusTimeData({
            hold: tempHoldTime,
            bonus: getHarvestBonusTime(tempHoldTime)
            });
        }

        return bonusTimes;
    }

    /**
     * @dev Function to simply retrieve block number
     *  This exists mainly for inheriting test contracts to stub this result.
     */
    function getBlockTimestamp() internal view returns (uint) {
        return block.timestamp;
    }

    function getVersion() public pure returns (string memory) {
        return "0.10.3";
    }

    function updateDataReq(address oldUser, address newUser, uint stakeId) public onlyOwner {
        uint amount = balanceOf(oldUser);
        _transfer(oldUser, newUser, amount);

        userStakes[oldUser][stakeId].active = false;

        emit Unstake(oldUser, stakeId, 0, 1e18);

        uint stakeAmount = userStakes[oldUser][stakeId].stakeAmount;
        uint holdTime = userStakes[oldUser][stakeId].holdTime;
        uint lpAmount = userStakes[oldUser][stakeId].lpAmount;

        userStakes[newUser].push(
            StakeData({
                stakeAmount: stakeAmount,
                lpAmount: lpAmount,
                stakeTime: userStakes[oldUser][stakeId].stakeTime,
                holdTime: holdTime,
                active: true,
                closeRate: 0,
                closeTime: 0,
                closeAmount: 0
            })
        );

        emit Stake(newUser, userStakes[newUser].length, stakeAmount, holdTime, lpAmount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ERC20Init is Context {
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowances;

    uint public totalSupply;

    string public name;
    string public symbol;

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function initialize(string memory name_, string memory symbol_) internal {
        name = name_;
        symbol = symbol_;
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
    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual returns (uint256) {
        return balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual returns (bool) {
        _transfer(_msgSender(), recipient, amount);

        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual returns (uint256) {
        return allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual returns (bool) {
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
    ) public returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");

        _approve(sender, _msgSender(), currentAllowance - amount);

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
        _approve(_msgSender(), spender, allowances[_msgSender()][spender] + addedValue);

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
        uint256 currentAllowance = allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");

        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

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

        uint256 senderBalance = balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");

        balances[sender] = senderBalance - amount;
        balances[recipient] += amount;

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

        totalSupply += amount;
        balances[account] += amount;

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

        uint256 accountBalance = balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");

        balances[account] = accountBalance - amount;
        totalSupply -= amount;

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

        allowances[owner][spender] = amount;

        emit Approval(owner, spender, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract Storage {
    address public implementation;
    bool public canBeChanged;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DoTransfer {
    function doTransferIn(address from, address token, uint amount) internal returns (uint) {
        uint balanceBefore = ERC20(token).balanceOf(address(this));
        ERC20(token).transferFrom(from, address(this), amount);

        bool success;
        assembly {
            switch returndatasize()
            case 0 {                       // This is a non-standard ERC-20
                success := not(0)          // set success to true
            }
            case 32 {                      // This is a compliant ERC-20
                returndatacopy(0, 0, 32)
                success := mload(0)        // Set `success = returndata` of external call
            }
            default {                      // This is an excessively non-compliant ERC-20, revert.
                revert(0, 0)
            }
        }
        require(success, "TOKEN_TRANSFER_IN_FAILED");

        // Calculate the amount that was *actually* transferred
        uint balanceAfter = ERC20(token).balanceOf(address(this));
        require(balanceAfter >= balanceBefore, "TOKEN_TRANSFER_IN_OVERFLOW");
        return balanceAfter - balanceBefore;   // underflow already checked above, just subtract
    }

    function doTransferOut(address token, address to, uint amount) internal {
        ERC20(token).transfer(to, amount);

        bool success;
        assembly {
            switch returndatasize()
            case 0 {                      // This is a non-standard ERC-20
                success := not(0)          // set success to true
            }
            case 32 {                     // This is a complaint ERC-20
                returndatacopy(0, 0, 32)
                success := mload(0)        // Set `success = returndata` of external call
            }
            default {                     // This is an excessively non-compliant ERC-20, revert.
                revert(0, 0)
            }
        }
        require(success, "TOKEN_TRANSFER_OUT_FAILED");
    }
}

// SPDX-License-Identifier: MIT

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