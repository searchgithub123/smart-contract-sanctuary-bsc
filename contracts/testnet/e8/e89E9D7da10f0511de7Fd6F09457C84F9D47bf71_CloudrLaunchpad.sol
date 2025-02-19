// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./common/IBEP20.sol";
import "./common/SafeBEP20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract CloudrLaunchpad is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    event LaunchpadSaleStarted(uint256 timestamp, Presale saleId);
    event LaunchpadSaleStopped(uint256 timestamp, Presale saleId);
    event Released(address beneficiaryAddress, uint256 amount, Presale saleId);
    event LaunchpadSaleBought(address buyer, uint256 amount, Presale saleId);
    event Whitelisted(address user, Presale saleId);
    event WhitelistRemoved(address user, Presale saleId);
    event ResidualBalanceWithdrawn(address to, uint256 amount);
    event GaveAllocation(address user, uint256 allocation, Presale saleId);

    uint256 public vestedTokens;
    struct LaunchpadSale {
        uint256 saleRate;
        bool isActive;
        uint256 saleMin;
        uint256 saleMax;
        uint256 saleCap;
        uint256 sold;
        bool hasWhitelist;
        bool hasAllocation;
        uint256 saleAllocated;
    }
    struct VestingSchedule {
        // total amount of tokens to be released at the end of the vesting
        uint256 totalAmount;
        // start time of the vesting period
        uint256 startTime;
        // duration of the vesting period in seconds
        uint256 duration;
        uint256 releasedAmount;
    }

    struct UserVest {
        address _beneficiaryAddress;
        uint256 _startTime;
        uint256 _vestingScheduleCount;
        uint256 _lastReleasedTime;
    }
    IBEP20 private immutable _token;
    IBEP20 private immutable _paymentMethod;
    LaunchpadSale[] launchpadSales;
    mapping(Presale => mapping(address => bool)) whitelist;
    mapping(Presale => mapping(address => UserVest)) userVestsBySale;
    mapping(Presale => mapping(address => bool)) saleParticipants;
    mapping(address => mapping(Presale => VestingSchedule))
        private _vestingSchedule;
    mapping(Presale => mapping(address => uint256)) public saleAllocation;
    enum Presale {
        Angel,
        Private,
        Public
    }

    constructor(
        uint256 _angelSaleRate,
        uint256 _angelSaleCap,
        uint256 _privateSaleRate,
        uint256 _privateSaleCap,
        uint256 _publicSaleMin,
        uint256 _publicSaleMax,
        uint256 _publicSaleRate,
        uint256 _publicSaleCap,
        address token,
        address paymentMethod
    ) {
        require(
            _publicSaleMin <= _publicSaleMax,
            "Public sale min must be less than or equal to public sale max"
        );
        require(
            _publicSaleCap > _publicSaleMax,
            "Public sale cap must be greater than public sale max"
        );
        require(
            _angelSaleRate > 0 && _privateSaleRate > 0 && _publicSaleRate > 0,
            "Sale rates must be greater than 0"
        );

        // Confirm rate
        require(
            _angelSaleRate >= _privateSaleRate,
            "Angel sale rate must be greater that Private sale rate"
        );
        require(
            _privateSaleRate >= _publicSaleRate,
            "Private sale rate must be greater than or equal to public sale rate"
        );
        _token = IBEP20(token);
        _paymentMethod = IBEP20(paymentMethod);

        LaunchpadSale storage angelSale = launchpadSales.push();
        angelSale.saleRate = _angelSaleRate;
        angelSale.hasAllocation = true;
        angelSale.saleCap = _angelSaleCap;

        LaunchpadSale storage privateSale = launchpadSales.push();
        privateSale.saleRate = _privateSaleRate;
        privateSale.hasAllocation = true;
        privateSale.saleCap = _privateSaleCap;

        LaunchpadSale storage publicSale = launchpadSales.push();
        publicSale.saleRate = _publicSaleRate;
        publicSale.saleMin = _publicSaleMin;
        publicSale.saleMax = _publicSaleMax;
        publicSale.saleCap = _publicSaleCap;
    }

    function startLaunchpadSale(Presale sale) external onlyOwner {
        uint256 _sale = uint256(sale);
        LaunchpadSale storage launchpadSale = launchpadSales[_sale];
        require(launchpadSale.isActive == false, "Sale is already active");
        if (sale == Presale.Angel) {
            require(
                !launchpadSales[uint256(Presale.Private)].isActive,
                "Private sale is active"
            );
            require(
                !launchpadSales[uint256(Presale.Public)].isActive,
                "Public sale is active"
            );
        }
        if (sale == Presale.Private) {
            require(
                !launchpadSales[uint256(Presale.Angel)].isActive,
                "Angel sale is active"
            );
            require(
                !launchpadSales[uint256(Presale.Public)].isActive,
                "Public sale is active"
            );
        }
        if (sale == Presale.Public) {
            require(
                !launchpadSales[uint256(Presale.Angel)].isActive,
                "Angel sale is active"
            );
            require(
                !launchpadSales[uint256(Presale.Private)].isActive,
                "Private sale is active"
            );
        }
        launchpadSale.isActive = true;
        emit LaunchpadSaleStarted(getCurrentTime(), sale);
    }

    function stopLaunchpadSale(Presale sale) external onlyOwner {
        uint256 _sale = uint256(sale);
        LaunchpadSale storage launchpadSale = launchpadSales[_sale];
        require(launchpadSale.isActive == true, "Sale is not active");
        launchpadSale.isActive = false;
        emit LaunchpadSaleStopped(getCurrentTime(), sale);
    }

    function addWhitelist(Presale sale, address addr) external onlyOwner {
        LaunchpadSale storage launchpadSale = launchpadSales[uint256(sale)];
        if (!launchpadSale.hasWhitelist) {
            launchpadSale.hasWhitelist = true;
        }
        require(!whitelist[sale][addr], "User is already whitelisted");
        whitelist[sale][addr] = true;
        emit Whitelisted(addr, sale);
    }

    function removeWhitelist(Presale sale, address addr) external onlyOwner {
        require(whitelist[sale][addr], "User is not whitelisted");
        whitelist[sale][addr] = false;
        emit WhitelistRemoved(addr, sale);
    }

    function _createUserVest(Presale sale, address userAddress)
        internal
        returns (bool)
    {
        userVestsBySale[sale][userAddress] = UserVest(
            userAddress,
            getCurrentTime(),
            0,
            0
        );
        return true;
    }

    function _initializeUserVest(
        uint256 amount,
        Presale sale,
        address _beneficiaryAddress
    ) internal {
        _createUserVest(sale, _beneficiaryAddress);
        _createVestingSchedule(
            block.timestamp,
            amount,
            sale,
            _beneficiaryAddress
        );
    }

    /**
     * @notice Creates a new vesting schedule for a beneficiary.
     * @param amount total amount of tokens to be released at the end of the vesting
     */
    function _createVestingSchedule(
        uint256 _startTime,
        uint256 amount,
        Presale sale,
        address _beneficiaryAddress
    ) internal {
        uint256 cliffPeriod = 0;
        uint256 vestingPeriod = 0;
        if (sale == Presale.Angel) {
            cliffPeriod = 6 * 30 days;
            vestingPeriod = 12 * 30 days;
        }
        if (sale == Presale.Private) {
            cliffPeriod = 120 days;
            vestingPeriod = 12 * 30 days;
        } else {
            cliffPeriod = 0;
            vestingPeriod = 8 * 30 days;
        }

        VestingSchedule storage newSchedule = _vestingSchedule[
            _beneficiaryAddress
        ][sale];
        newSchedule.startTime = _startTime + cliffPeriod;
        newSchedule.duration = vestingPeriod;
        newSchedule.totalAmount = amount;
    }

    function buyLaunchpadSale(Presale sale, uint256 busdAmount)
        external
        nonReentrant
    {
        _buyLaunchpadSale(sale, busdAmount);
    }

    function _buyLaunchpadSale(Presale sale, uint256 busdAmount) internal {
        require(
            !saleParticipants[sale][msg.sender],
            "You have bought this sale"
        );
        LaunchpadSale storage launchpadSale = launchpadSales[uint256(sale)];
        require(launchpadSale.isActive == true, "Sale is not active");
        require(launchpadSale.saleRate > 0, "Sale rate must be greater than 0");
        if (!launchpadSale.hasAllocation) {
            require(
                launchpadSale.saleMin <= busdAmount,
                "Amount must be greater than or equal to sale min"
            );
            require(
                launchpadSale.saleMax >= busdAmount,
                "Amount must be less than or equal to sale max"
            );
        }
        if (launchpadSale.hasAllocation) {
            require(
                busdAmount == allocatedBuy(sale, msg.sender),
                "You can only buy your exact allocation"
            );
        }
        require(
            launchpadSale.saleCap > launchpadSale.sold,
            "Sale cap has been reached"
        );
        if (launchpadSale.hasWhitelist) {
            require(
                whitelist[sale][msg.sender],
                "Buyer is not on the whitelist"
            );
        }
        _paymentMethod.safeTransferFrom(msg.sender, owner(), busdAmount);
        uint256 tokenAmount = busdAmount.mul(launchpadSale.saleRate);
        if (sale == Presale.Private) {
            uint256 tokenAtTge = tokenAmount.mul(5).div(100);
            _token.safeTransfer(msg.sender, tokenAtTge);
            tokenAmount = tokenAmount.sub(tokenAtTge);
        }
        if (sale == Presale.Public) {
            uint256 tokenAtTge = tokenAmount.mul(20).div(100);
            _token.safeTransfer(msg.sender, tokenAtTge);
            tokenAmount = tokenAmount.sub(tokenAtTge);
        }
        _initializeUserVest(tokenAmount, sale, msg.sender);
        vestedTokens = vestedTokens.add(tokenAmount);
        saleParticipants[sale][msg.sender] = true;
        launchpadSale.sold = launchpadSale.sold.add(busdAmount);
        emit LaunchpadSaleBought(msg.sender, busdAmount, sale);
    }

    /**
     * @notice Returns the vesting schedule information for a given user and sale.
     * @param sale launchpadSale index: 0, 1, 2, ...
     * @return the vesting schedule structure information
     */
    function getUserVestingScheduleBySale(Presale sale, address user)
        external
        view
        returns (VestingSchedule memory)
    {
        return _vestingSchedule[user][sale];
    }

    function _getReleasable(
        Presale sale,
        address user,
        uint256 timestamp
    ) internal view virtual returns (uint256) {
        VestingSchedule storage vestingSchedule = _vestingSchedule[user][sale];

        if (timestamp < vestingSchedule.startTime) {
            return 0;
        } else if (
            timestamp > vestingSchedule.startTime + vestingSchedule.duration
        ) {
            return vestingSchedule.totalAmount;
        } else {
            return
                (vestingSchedule.totalAmount *
                    (timestamp - vestingSchedule.startTime)) /
                vestingSchedule.duration;
        }
    }

    /**
     * @notice Release the releasable amount of tokens.
     * @return the success or failure
     */
    function _release(
        Presale sale,
        address user,
        uint256 currentTime
    ) internal returns (bool) {
        VestingSchedule storage vestingSchedule = _vestingSchedule[user][sale];
        uint256 amount = _getReleasable(sale, user, getCurrentTime()).sub(
            vestingSchedule.releasedAmount
        );
        UserVest storage userVest = userVestsBySale[sale][user];
        require(
            currentTime >=
                vestingSchedule.startTime.add(vestingSchedule.duration),
            "Still locked up"
        );
        uint256 claimable = vestingSchedule.totalAmount.sub(
            vestingSchedule.releasedAmount
        );
        require(claimable > 0, "No more tokens to release");
        require(amount <= claimable, "Amount is greater than claimable");
        _token.safeTransfer(userVest._beneficiaryAddress, amount);
        vestedTokens = vestedTokens.sub(amount);
        vestingSchedule.releasedAmount = vestingSchedule.releasedAmount.add(
            amount
        );
        userVest._lastReleasedTime = currentTime;
        emit Released(userVest._beneficiaryAddress, amount, sale);
        return true;
    }

    /**
     * @notice Release the releasable amount of tokens.
     * @return the success or failure
     */
    function release(Presale sale) external nonReentrant returns (bool) {
        require(
            _release(sale, msg.sender, getCurrentTime()),
            "CloudrVesting: release failed"
        );
        return true;
    }

    function _withdrawResidualBalance(address wallet) internal {
        require(!launchpadSales[0].isActive, "private sale still active");
        require(!launchpadSales[1].isActive, "public sale still active");
        uint256 contractBalance = _token.balanceOf(address(this));
        uint256 withdrawable = contractBalance.sub(vestedTokens);
        require(withdrawable > 0, "No Residue");
        _token.safeTransfer(wallet, withdrawable);
        emit ResidualBalanceWithdrawn(wallet, withdrawable);
    }

    function enableAllocation(Presale sale) public onlyOwner {
        LaunchpadSale storage launchpadSale = launchpadSales[uint256(sale)];
        if (!launchpadSale.hasAllocation) {
            launchpadSale.hasAllocation = true;
        }
    }

    function disableAllocation(Presale sale) public onlyOwner {
        LaunchpadSale storage launchpadSale = launchpadSales[uint256(sale)];
        if (launchpadSale.hasAllocation) {
            launchpadSale.hasAllocation = false;
        }
    }

    function disableWhitelist(Presale sale) public onlyOwner {
        LaunchpadSale storage launchpadSale = launchpadSales[uint256(sale)];
        if (launchpadSale.hasWhitelist) {
            launchpadSale.hasWhitelist = false;
        }
    }

    function addAllocation(
        address user,
        uint256 allocation,
        Presale sale
    ) external onlyOwner {
        LaunchpadSale storage launchpadSale = launchpadSales[uint256(sale)];
        if (!launchpadSale.hasAllocation) {
            enableAllocation(sale);
        }
        uint256 newAllocationVolume = launchpadSale.saleAllocated.add(
            allocation
        );
        require(
            newAllocationVolume <= launchpadSale.saleCap,
            "ERR_ALLOCATION_OVERFLOW"
        );
        saleAllocation[sale][user] = allocation;
        launchpadSale.saleAllocated = newAllocationVolume;
        emit GaveAllocation(user, allocation, sale);
    }

    function withdrawResidualBalance(address wallet)
        external
        onlyOwner
        nonReentrant
    {
        _withdrawResidualBalance(wallet);
    }

    /* Functions to enable withdrawal of Ether and tokens */

    function withdrawEther(address recipient, uint256 amount)
        external
        onlyOwner
    {
        require(
            recipient != address(0),
            "SFT: Recipient can't be the zero address"
        );
        uint256 balance = address(this).balance;
        if (amount > balance) {
            amount = balance;
        }
        payable(recipient).transfer(amount);
    }

    function withdrawTokens(
        address tokenAddress,
        address recipient,
        uint256 amount
    ) external onlyOwner {
        require(
            recipient != address(0),
            "SFT: Recipient can't be the zero address"
        );
        IBEP20 token = IBEP20(tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        if (amount > balance) {
            amount = balance;
        }
        token.safeTransfer(recipient, amount);
    }

    /**
     * @notice Returns the current timestamp.
     * @return the block timestamp
     */
    function getCurrentTime() public view virtual returns (uint256) {
        return block.timestamp;
    }

    /**
     * @dev Returns the address of the BEP20 token managed by the launchpad contract.
     */
    function getToken() public view returns (IBEP20) {
        return _token;
    }

    function allocatedBuy(Presale sale, address user)
        public
        view
        returns (uint256)
    {
        return saleAllocation[sale][user];
    }

    function getPaymentMethod() public view returns (IBEP20) {
        return _paymentMethod;
    }

    function getSales() external view returns (LaunchpadSale[] memory) {
        return launchpadSales;
    }

    function getLaunchpadSale(Presale sale)
        external
        view
        returns (LaunchpadSale memory)
    {
        return launchpadSales[uint256(sale)];
    }

    /* TS = Total Supply = 10,000,000,000
    Angel sale = 450,000,000 (4.5% of TS)
        - 6 months Cliff
        - 0 at TGE
        - 100% linear vesting across 12 months
   Private sale = 800,000,000 (8% of TS)
        - 120 days Cliff
        - 40,000,000 (5%) at TGE
        - 760,000,000 (95%) linear vesting across 12 months
   Public sale = 2,000,000,000 (20% of TS)
        - 120 days Cliff
        - 400,000,000 (20%) at TGE
        - 1,600,000,000 (80%) vesting across 8 months
        */

    // Disable transfer because TGE
    // e.g isTrading method on the token
    // if(from != owner() && from != presaleAddress)
    //  require(isTradingEnabled, "Trading is not enabled yet");
    // Or Have a mapping
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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

pragma solidity >=0.8.0;

import "./IBEP20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title SafeBEP20
 * @dev Wrappers around BEP20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeBEP20 for IBEP20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeBEP20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IBEP20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IBEP20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IBEP20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeBEP20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, newAllowance)
        );
    }

    function safeDecreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            "SafeBEP20: decreased allowance below zero"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, newAllowance)
        );
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IBEP20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(
            data,
            "SafeBEP20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeBEP20: BEP20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
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