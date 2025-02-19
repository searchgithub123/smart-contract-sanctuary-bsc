// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

// token
import "./swap/BEB20Token.sol";
import "./swap/TetherUSDToken.sol";
import "./swap/BUSDCoinToken.sol";
import "./helpers/Withdraw.sol";


contract Vendor is
    BEB20Token,
    TetherUSDToken,
    BUSDCoinToken,
    Withdraw
{
    constructor(
        address _TokenAddress,
        address _usdtTokenAddress,
        address _busdTokenAddress
    )
        BEB20Token(_TokenAddress)
        TetherUSDToken(_usdtTokenAddress, _TokenAddress)
        BUSDCoinToken(_busdTokenAddress, _TokenAddress)
    {}

    // This fallback/receive function
    // will keep all the Ether
    fallback() external payable {
        // Do nothing
    }

    receive() external payable {
        // Do nothing
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../helpers/PriceConsumerV3.sol";
import "../helpers/TransactionFee.sol";
import "../helpers/TransferHistory.sol";
import "../security/ReEntrancyGuard.sol";

contract BEB20Token is
    Context,
    PriceConsumerV3,
    ReEntrancyGuard,
    TransferHistory,
    TransactionFee
{
    IERC20 private beb20Token;

    constructor(address _tokenAddress) {
        beb20Token = IERC20(_tokenAddress);
    }

    /// @dev   Allow users to buy tokens for MATIC
    function buy() external payable limitBuy(SentBuy(msg.value)) noReentrant {
        require(msg.value > 0, "Send MATIC to buy some tokens");

        /// @dev  send fee
        uint256 _amountfee = calculateFee(msg.value);
        require(
            payable(_walletFee).send(_amountfee),
            "Failed to transfer token to fee contract Owner"
        );

        uint256 _amountOfTokens = msg.value - _amountfee;

        /// @dev  token  para enviar al sender
        uint256 amountToBuy = SentBuy(_amountOfTokens);

        /// @dev  check if the Vendor Contract has enough amount of tokens for the transaction
        uint256 vendorBalance = beb20Token.balanceOf(address(this));
        require(
            vendorBalance >= amountToBuy,
            "Vendor contract has not enough tokens in its balance"
        );

        /// @dev  Transfer token to the msg.sender
        bool sent = beb20Token.transfer(_msgSender(), amountToBuy);
        require(sent, "Failed to transfer token to user");
    }

    // @dev calculate the tokens to send to the sender
    function SentBuy(uint256 amountOfTokens) internal view returns (uint256) {
        (address _addr, uint256 _decimal) = getOracle(0);

        // Get the amount of tokens that the user will receive
        // convert cop to usd
        uint256 valueBNBinUSD = amountOfTokens *
            getLatestPrice(_addr, _decimal);

        // token para enviar al sender
        uint256 amountToBuy = valueBNBinUSD / getPriceToken();

        return amountToBuy;
    }

    // @dev Allow users to sell tokens for sell  by MATIC
    function sell(uint256 tokenAmountToSell)
        external
        limitSell(tokenAmountToSell)
        noReentrant
    {
        /// @dev Check that the requested amount of tokens to sell is more than 0
        require(
            tokenAmountToSell > 0,
            "sell: Specify an amount of token greater than zero"
        );

        /// @dev Check that the user's token balance is enough to do the swap
        uint256 userBalance = beb20Token.balanceOf(_msgSender());
        require(
            userBalance >= tokenAmountToSell,
            "sell: Your balance is lower than the amount of tokens you want to sell"
        );

        /// @dev  get price token
        (address _addr, uint256 _decimal) = getOracle(0);

        /// @dev send fee
        uint256 _amountfee = calculateFee(tokenAmountToSell);
        require(
            beb20Token.transfer(_walletFee, _amountfee),
            "sell: Failed to transfer token"
        );

        /// @dev  liquids of the contract in matic
        uint256 ownerMATICBalance = address(this).balance;

        /// @dev   token available to send to user
        uint256 tokenSend = tokenAmountToSell - _amountfee;

        /// @dev  Token To Usd
        uint256 tokenToUsd = tokenSend * getPriceToken();

        /// dev get value token
        uint256 lastPriceToken = getLatestPrice(_addr, _decimal);

        /// @dev  token To MAtic
        uint256 amountToTransfer = tokenToUsd / lastPriceToken;

        /// @dev  Check that the Vendor's balance is enough to do the swap
        require(
            ownerMATICBalance >= amountToTransfer,
            "sell: Vendor has not enough funds to accept the sell request"
        );

        /// @dev  Transfer token to the msg.sender
        require(
            beb20Token.transferFrom(
                _msgSender(),
                address(this),
                tokenAmountToSell
            ),
            "sell: Failed to transfer tokens from user to vendor"
        );

        /// @dev   we send matic to the sender
        (bool success, ) = _msgSender().call{value: amountToTransfer}("");
        require(success, "receiver rejected BNB transfer");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./BEB20Token.sol";
import "../security/ReEntrancyGuard.sol";
import "../helpers/PriceConsumerV3.sol";
import "../helpers/TransferHistory.sol";
import "../helpers/TransactionFee.sol";

contract TetherUSDToken is
    PriceConsumerV3,
    ReEntrancyGuard,
    TransferHistory,
    TransactionFee
{
    IERC20 private usdtToken;
    IERC20 private BEB20Token2;

    constructor(address usdtTokenAddress, address _tokenAddress) {
        usdtToken = IERC20(usdtTokenAddress);
        BEB20Token2 = IERC20(_tokenAddress);
    }

    // @dev  Allow users to buy tokens for buy  usdt
    function buyUSDT(uint256 tokenAmountToBuy)
        external
        noReentrant
        limitBuy(USDTSentBuy(tokenAmountToBuy))
    {
        require(
            tokenAmountToBuy > 0,
            "buyUSDT: Specify an amount of token greater than zero"
        );

        //  @dev  Check that the user's token balance is enough to do the swap
        uint256 userBalance = usdtToken.balanceOf(_msgSender());
        require(
            userBalance >= tokenAmountToBuy,
            "buyUSDT: Your balance is lower than the amount of tokens you want to sell"
        );

        // @dev send fee
        uint256 _amountfee = calculateFee(tokenAmountToBuy);
        require(
            usdtToken.transfer(_walletFee, _amountfee),
            "buyUSDT: Failed to transfer token to user"
        );

        // @dev  token available to send to user
        uint256 tokenSend = tokenAmountToBuy - _amountfee;

        //  @dev  Get the amount of tokens that the user will receive
        uint256 amountToBuy = USDTSentBuy(tokenSend);

        //  @dev  check if the Vendor Contract has enough amount of tokens for the transaction
        uint256 vendorBalance = BEB20Token2.balanceOf(address(this));
        require(
            vendorBalance >= amountToBuy,
            "buyUSDT: Vendor contract has not enough tokens in its balance"
        );

        //@dev Transfer token to the SENDER USDT =>  SC
        require(
            usdtToken.transferFrom(
                _msgSender(),
                address(this),
                tokenAmountToBuy
            ),
            "buyUSDT: Failed to transfer tokens from user to vendor"
        );

        //  @dev  Transfer token to the msg.sender SC => SENDER
        require(
            BEB20Token2.transfer(_msgSender(), amountToBuy),
            "buyUSDT: Failed to transfer token to user"
        );
    }

    // @dev calculate the tokens to send to the sender
    function USDTSentBuy(uint256 amountOfTokens)
        internal
        view
        returns (uint256)
    {
        (address _addr, uint256 _decimal) = getOracle(2);

        // Get the amount of tokens that the user will receive
        uint256 valueUSDTinUSD = amountOfTokens *
            getLatestPrice(_addr, _decimal);

        // token para enviar al sender
        uint256 amountToBuy = valueUSDTinUSD / getPriceToken();

        return amountToBuy;
    }

    // @dev Allow users to sell tokens for sell  USDT
    function sellUSDT(uint256 tokenAmountToSell)
        external
        noReentrant
        limitSell(tokenAmountToSell)
    {
        // Check that the requested amount of tokens to sell is more than 0
        require(
            tokenAmountToSell > 0,
            "sellUSDT: Specify an amount of token greater than zero"
        );

        // Check that the user's token balance is enough to do the swap
        uint256 userBalance = BEB20Token2.balanceOf(_msgSender());
        require(
            userBalance >= tokenAmountToSell,
            "sellUSDT: Your balance is lower than the amount of tokens you want to sell"
        );

        // Transfer token to the msg.sender TOKEN =>  SMART CONTRACT
        require(
            BEB20Token2.transferFrom(
                _msgSender(),
                address(this),
                tokenAmountToSell
            ),
            "sellUSDT: Failed to transfer tokens from user to vendor"
        );

        // @dev send fee
        uint256 _amountfee = calculateFee(tokenAmountToSell);
        require(
            BEB20Token2.transfer(_walletFee, _amountfee),
            "sellUSDT: Failed to transfer token"
        );

        // @dev  token available to send to user
        uint256 tokenSend = tokenAmountToSell - _amountfee;

        /// @dev  Token To Usd
        uint256 tokenToUsd = tokenSend * getPriceToken();

        /// @dev  get price token
        (address _addr, uint256 _decimal) = getOracle(2);
        /// @dev  get value token
        uint256 lastPriceToken = getLatestPrice(_addr, _decimal);

        /// @dev  token To MAtic
        uint256 amountToTransfer = tokenToUsd / lastPriceToken;

        require(
            usdtToken.transfer(_msgSender(), amountToTransfer),
            "Failed to transfer token to user"
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./BEB20Token.sol";
import "../security/ReEntrancyGuard.sol";
import "../helpers/PriceConsumerV3.sol";
import "../helpers/TransferHistory.sol";
import "../helpers/TransactionFee.sol";

contract BUSDCoinToken is
    PriceConsumerV3,
    ReEntrancyGuard,
    TransferHistory,
    TransactionFee
{
    IERC20 private BUSDToken;
    IERC20 private BEB20Token3;

    constructor(address _usdCoinToken, address _tokenAddress) {
        BUSDToken = IERC20(_usdCoinToken);
        BEB20Token3 = IERC20(_tokenAddress);
    }

    function buyBUSD(uint256 tokenAmountToBuy)
        external
        noReentrant
        limitBuy(BUSDSentBuy(tokenAmountToBuy))
    {
        require(
            tokenAmountToBuy > 0,
            "buyBUSD: Specify an amount of token greater than zero"
        );

        /// @dev  Check that the user's token balance is enough to do the swap
        uint256 userBalance = BUSDToken.balanceOf(_msgSender());
        require(
            userBalance >= tokenAmountToBuy,
            "buyBUSD: Your balance is lower than the amount of tokens you want to sell"
        );

        /// @dev send fee
        uint256 _amountfee = calculateFee(tokenAmountToBuy);
        require(
            BUSDToken.transfer(_walletFee, _amountfee),
            "buyBUSD: Failed to transfer token to user"
        );

        /// @dev token available to send to user
        uint256 tokenSend = tokenAmountToBuy - _amountfee;

        /// @dev  Get the amount of tokens that the user will receive
        uint256 amountToBuy = BUSDSentBuy(tokenSend);

        /// @dev  check if the Vendor Contract has enough amount of tokens for the transaction
        uint256 vendorBalance = BEB20Token3.balanceOf(address(this));
        require(
            vendorBalance >= amountToBuy,
            "buyBUSD: Vendor contract has not enough tokens in its balance"
        );

        /// @dev  Transfer token to the msg.sender USDT => WALLET CONTRACT
        require(
            BUSDToken.transferFrom(
                _msgSender(),
                address(this),
                tokenAmountToBuy
            ),
            "buyBUSD: Failed to transfer tokens from user to vendor"
        );

        /// @dev  Transfer token to the msg.sender token => SENDER
        require(
            BEB20Token3.transfer(_msgSender(), amountToBuy),
            "buyBUSD: Failed to transfer token to user"
        );
    }

    // @dev calculate the tokens to send to the sender
    function BUSDSentBuy(uint256 amountOfTokens)
        internal
        view
        returns (uint256)
    {
        (address _addr, uint256 _decimal) = getOracle(1);

        // Get the amount of tokens that the user will receive
        uint256 valueUSDTinUSD = amountOfTokens *
            getLatestPrice(_addr, _decimal);

        // token para enviar al sender
        uint256 amountToBuy = valueUSDTinUSD / getPriceToken();

        return amountToBuy;
    }

    // @dev Allow users to sell tokens for sell  by USDT
    function sellBUSD(uint256 tokenAmountToSell)
        external
        noReentrant
        limitSell(tokenAmountToSell)
    {
        /// @dev Check that the requested amount of tokens to sell is more than 0
        require(
            tokenAmountToSell > 0,
            "sellUSDT: Specify an amount of token greater than zero"
        );

        /// @dev  Check that the user's token balance is enough to do the swap
        uint256 userBalance = BEB20Token3.balanceOf(_msgSender());
        require(
            userBalance >= tokenAmountToSell,
            "sellUSDT: Your balance is lower than the amount of tokens you want to sell"
        );

        /// @dev  Transfer token to the msg.sender TOKEN =>  SMART CONTRACT
        require(
            BEB20Token3.transferFrom(
                _msgSender(),
                address(this),
                tokenAmountToSell
            ),
            "sellUSDT: Failed to transfer tokens from user to vendor"
        );

        /// @dev send fee
        uint256 _amountfee = calculateFee(tokenAmountToSell);
        require(
            BEB20Token3.transfer(_walletFee, _amountfee),
            "sellUSDT: Failed to transfer token"
        );

        // @dev  token available to send to user
        uint256 tokenSend = tokenAmountToSell - _amountfee;

        /// @dev  Token To Usd
        uint256 tokenToUsd = tokenSend * getPriceToken();

        /// @dev  get price token
        (address _addr, uint256 _decimal) = getOracle(1);

        /// @dev  get value token
        uint256 lastPriceToken = getLatestPrice(_addr, _decimal);

        /// @dev  token To MAtic
        uint256 amountToTransfer = tokenToUsd / lastPriceToken;

        require(
            BUSDToken.transfer(_msgSender(), amountToTransfer),
            "Failed to transfer token to user"
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../security/Administered.sol";

contract Withdraw is Administered {
    /// @dev Allow the owner of the contract to withdraw
    function withdrawOwner(uint256 amount, address to)
        external
        payable
        onlyAdmin
    {
        require(
            payable(to).send(amount),
            "withdrawOwner: Failed to transfer token to fee contract"
        );
    }

    /// @dev Allow the owner of the contract to withdraw MATIC Owner
    function withdrawTokenOnwer(
        address _token,
        uint256 _amount,
        address to
    ) external onlyAdmin {
        require(
            IERC20(_token).transfer(to, _amount),
            "withdrawTokenOnwer: Failed to transfer token to Onwer"
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
pragma solidity 0.8.9;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "../security/Administered.sol";

contract PriceConsumerV3 is Administered {

    struct StructOracle {
        address _addr;
        uint _decimal;
    }

    StructOracle[] public OracleList;


    /// @dev price tokens
    uint priceTokens = 0.1 ether;



    constructor(){
        
        /// @dev production
        /// OracleList.push(StructOracle(0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE, 10)); /// BNB / USD
        /// OracleList.push(StructOracle(0xcBb98864Ef56E9042e7d2efef76141f15731B82f, 10)); /// BUSD / USD
        /// OracleList.push(StructOracle(0xB97Ad0E74fa7d920791E90258A6E2085088b4320, 10)); /// USDT / USD
        
        /// develoment
        OracleList.push(StructOracle(0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526, 10)); /// BNB / USD
        OracleList.push(StructOracle(0x9331b55D9830EF609A2aBCfAc0FBCE050A52fdEa, 10)); /// BUSD / USD
        OracleList.push(StructOracle(0xEca2605f0BCF2BA5966372C99837b1F182d3D620, 10)); /// USDT / USD
        
    }


    /// set change price tokens
    function  setPriceTokens(uint newValue)  external  onlyAdmin {
        priceTokens =newValue;
    }

    /// @dev get price token
    function getPriceToken() public view returns (uint){
        return priceTokens;
    }


    /// @dev get oracle
    function  getOracle(uint _index) public view returns (address, uint)  {
        StructOracle storage oracle = OracleList[_index];
        return (oracle._addr, oracle._decimal);
    }
    


    /// @dev Returns the latest price
    function getLatestPrice(address _oracle, uint256 _decimal)
        public
        view
        returns (uint256)
    {
        require(
            _oracle != address(0),
            "Get Latest Price: address must be the same as the contract address"
        );

        AggregatorV3Interface priceFeed = AggregatorV3Interface(_oracle);

        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price) * 10**_decimal;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "../security/Administered.sol";

contract TransactionFee is Context, Administered {
    // @dev fee per transaction
    uint256 public fee_fixed = 100; // 1% (Basis Points);
    address _walletFee = address(0);

    constructor() {
        _walletFee = _msgSender();
    }

    /// @dev wallet fee
    function changeWalletFee(address newWalletFee) external onlyAdmin {
        _walletFee = newWalletFee;
    }

    /// @dev fee calculation for
    function calculateFee(uint256 amount) public view returns (uint256 fee) {
        return (amount * fee_fixed) / 10000;
    }

    /// @dev
    function changeFee(uint256 newValue) external onlyAdmin {
        fee_fixed = newValue;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
import "../security/Administered.sol";

contract TransferHistory is Context, Administered {
    // @dev Event

    // @dev struct for sale limit
    struct SoldOnDay {
        uint256 amount;
        uint256 startOfDay;
    }

    // @dev lock time per wallet
    uint256 public lockTime = 24;

    // @dev struct for buy limit
    struct BuyOnDay {
        uint256 amount;
        uint256 startOfDay;
    }

    // @dev
    uint256 public dayBuyLimit = 100 ether;
    mapping(address => BuyOnDay) public buyInADay;

    // @dev
    uint256 public daySellLimit = 100 ether;
    mapping(address => SoldOnDay) public salesInADay;

    // @dev  Throws if you exceed the Sell limit
    modifier limitSell(uint256 sellAmount) {
        SoldOnDay storage soldOnDay = salesInADay[_msgSender()];
        if (block.timestamp >= soldOnDay.startOfDay + getTimeLock()) {
            soldOnDay.amount = sellAmount;
            soldOnDay.startOfDay = block.timestamp;
        } else {
            soldOnDay.amount += sellAmount;
        }

        require(
            soldOnDay.amount <= daySellLimit,
            "Limit Sell: Exceeded token sell limit"
        );
        _;
    }

    // @dev  Throws if you exceed the Buy limit
    modifier limitBuy(uint256 buyAmount) {
        BuyOnDay storage buyOnDay = buyInADay[_msgSender()];

        if (block.timestamp >= buyOnDay.startOfDay + getTimeLock()) {
            buyOnDay.amount = buyAmount;
            buyOnDay.startOfDay = block.timestamp;
        } else {
            buyOnDay.amount += buyAmount;
        }

        require(
            buyOnDay.amount <= dayBuyLimit,
            "Limit Buy: Exceeded token sell limit"
        );
        _;
    }

    // @dev  get Time Lock
    function getTimeLock() public view returns (uint256) {
        return lockTime * 1 hours;
    }

    // @dev changes to the token sale limit
    function setLockTimePerWallet(uint256 newLimit) external onlyUser {
        lockTime = newLimit;
    }

    // @dev changes to the token sale limit
    function setSellLimit(uint256 newLimit) external onlyUser {
        daySellLimit = newLimit;
    }

    // @dev Token purchase limit changes
    function setBuyLimit(uint256 newLimit) external onlyUser {
        dayBuyLimit = newLimit;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

contract ReEntrancyGuard {
    bool internal locked;

    modifier noReentrant() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title Administered
 * @notice Implements Admin and User roles.
 */
contract Administered is AccessControl {
    bytes32 public constant USER_ROLE = keccak256("USER");

    /// @dev Add `root` to the admin role as a member.
    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setRoleAdmin(USER_ROLE, DEFAULT_ADMIN_ROLE);
    }

    /// @dev Restricted to members of the admin role.
    modifier onlyAdmin() {
        require(isAdmin(_msgSender()), "Restricted to admins.");
        _;
    }
    /// @dev Restricted to members of the user role.
    modifier onlyUser() {
        require(isUser(_msgSender()), "Restricted to users.");
        _;
    }

    /// @dev Return `true` if the account belongs to the admin role.
    function isAdmin(address account) public view virtual returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, account);
    }

    /// @dev Return `true` if the account belongs to the user role.
    function isUser(address account) public view virtual returns (bool) {
        return hasRole(USER_ROLE, account);
    }

    /// @dev Add an account to the user role. Restricted to admins.
    function addUser(address account) public virtual onlyAdmin {
        grantRole(USER_ROLE, account);
    }

    /// @dev Add an account to the admin role. Restricted to admins.
    function addAdmin(address account) public virtual onlyAdmin {
        grantRole(DEFAULT_ADMIN_ROLE, account);
    }

    /// @dev Remove an account from the user role. Restricted to admins.
    function removeUser(address account) public virtual onlyAdmin {
        revokeRole(USER_ROLE, account);
    }

    /// @dev Remove oneself from the admin role.
    function renounceAdmin() public virtual {
        renounceRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}