/**
 *Submitted for verification at BscScan.com on 2022-09-29
*/

/**
 *Submitted for verification at BscScan.com on 2022-09-08
*/

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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

contract BridgePayV2 is Ownable, ReentrancyGuard, Pausable {
    using SafeMath for uint256;

    uint256 public bridgePartnerTax = 1;
    uint256 public bridgePartnerDenom = 100;

    address public taxAddress = 0x20fF22dC2E8513E4A2A7a478d9ff201b20347A81;
    address public tokenAddress = 0xEfA6Bf9bdca29A786f564ff1DBfBAc966e46A6C0;

    struct bridgePayPartner {
        address partnerWallet;
        string partnerName;
        string partnerShortNAme;
        bool partnerEnabled;
        uint256 iPartner;
        uint256 partnerOwed;
    }

    mapping(uint256 => bridgePayPartner) public bridgePayPartners;
    uint256 public partnerCount = 0;

    event DistributeToPartners(address indexed partnerWallet, uint256 owedAmount, uint256 timeStamp);

    constructor() {
        bridgePayPartners[partnerCount] = bridgePayPartner(
            0xcAd353E6c641BD42d17Dea2898892BC177ee96a3,
            "Morty Mart",
            "Morty",
            true,
            partnerCount,
            0
        );
        partnerCount++;

        bridgePayPartners[partnerCount] = bridgePayPartner(
            0xcAd353E6c641BD42d17Dea2898892BC177ee96a3,
            "Rick's Sanitarium",
            "Rick",
            true,
            partnerCount,
            0
        );
        partnerCount++;

        bridgePayPartners[partnerCount] = bridgePayPartner(
            0xcAd353E6c641BD42d17Dea2898892BC177ee96a3,
            "Beth's Heart Surgery (Animals Only)",
            "Beth",
            true,
            partnerCount,
            0
        );
        partnerCount++;



    }

    function addBridgePartners(
        address _partnerWallet,
        string memory _partnerName,
        string memory _partnerShortNAme,
        bool _partnerEnabled
    ) external onlyOwner {
        bridgePayPartners[partnerCount] = bridgePayPartner(
            _partnerWallet,
            _partnerName,
            _partnerShortNAme,
            _partnerEnabled,
            partnerCount,
            0
        );
        partnerCount++;
    }

    function updateBridgePartners(
        address _partnerWallet,
        string memory _partnerName,
        string memory _partnerShortNAme,
        bool _partnerEnabled,
        uint32 _iPartner
    ) external onlyOwner {
        require(_iPartner != 0 && bridgePayPartners[_iPartner].partnerWallet != address(0),
            "Please specify partner number");

        bridgePayPartners[_iPartner].partnerWallet = _partnerWallet;
        bridgePayPartners[_iPartner].partnerName = _partnerName;
        bridgePayPartners[_iPartner].partnerShortNAme = _partnerShortNAme;
        bridgePayPartners[_iPartner].partnerEnabled = _partnerEnabled;
    }

    //return Array of BRG partners
    function getBridgePartnersTup()
        public
        view
        returns (bridgePayPartner[] memory)
    {
        bridgePayPartner[]
            memory _bridgePayPartnersTup = new bridgePayPartner[](partnerCount);
        for (uint256 i = 0; i < partnerCount; i++) {
            bridgePayPartner storage _bridgePayPartner = bridgePayPartners[i];
            _bridgePayPartnersTup[i] = _bridgePayPartner;
        }
        return _bridgePayPartnersTup;
    }

    function getBridgePartner(uint256 _iPartner)
        public
        view
        returns (
            address,
            string memory,
            string memory,
            bool,
            uint256,
            uint256
        ) {
        return (
            bridgePayPartners[_iPartner].partnerWallet,
            bridgePayPartners[_iPartner].partnerName,
            bridgePayPartners[_iPartner].partnerShortNAme,
            bridgePayPartners[_iPartner].partnerEnabled,
            bridgePayPartners[_iPartner].iPartner,
            bridgePayPartners[_iPartner].partnerOwed
        );
    }



    function holdForPartner(uint256 _amount, uint256 _iPartner) public {
        require(bridgePayPartners[_iPartner].partnerWallet != address(0),
            "No partner wallet set");

        require(_amount > 0, 
            "Value must be greater than zero");

        require(IERC20(tokenAddress).balanceOf(msg.sender) > _amount, 
            "More BRG Needed For Transfer");

        try
            IERC20(tokenAddress).transferFrom(
                msg.sender, 
                address(this), 
                _amount
                )
        {
            uint256 tax = _amount.mul(bridgePartnerTax).div(bridgePartnerDenom);
            uint256 payment = _amount - tax;
            bridgePayPartners[_iPartner].partnerOwed += payment;
        } catch {}
        
    }

    function sendToPartner()  external onlyOwner  {
        require(IERC20(tokenAddress).balanceOf(address(this)) > 0, "No BRG to send.");

        for (uint256 i = 0; i < partnerCount; i++) {
            if (bridgePayPartners[i].partnerEnabled == true) {
                try
                    IERC20(tokenAddress).transfer(
                        bridgePayPartners[i].partnerWallet,
                        bridgePayPartners[i].partnerOwed
                    )
                {
                    emit DistributeToPartners(bridgePayPartners[i].partnerWallet, bridgePayPartners[i].partnerOwed, block.timestamp);
                    bridgePayPartners[i].partnerOwed = 0;
                } catch {}
            }
        }

        try
            IERC20(tokenAddress).transfer(
                taxAddress,
                IERC20(tokenAddress).balanceOf(address(this))
            )
        {} catch {}
    }

    function updateTaxInfo(uint256 _tax, uint256 _taxDenom) external onlyOwner {
        require(
            _tax/ _taxDenom <= 10, 
            "Bridge partner tax cannot be more than 10%"
        );
        bridgePartnerTax = _tax;
        bridgePartnerDenom = _taxDenom;
    }

    function updateTaxAddress(address _address) external onlyOwner {
        taxAddress = _address;
    }

    function updateTokenAddress(address _address) external onlyOwner {
        tokenAddress = _address;
    }

    function claimTaxTokens() external onlyOwner {
        require(
            IERC20(tokenAddress).balanceOf(address(this)) > 0,
            "Insufficient Balance"
        );
        IERC20(tokenAddress).transfer(
            taxAddress,
            IERC20(tokenAddress).balanceOf(address(this))
        );
    }

    function claimBEP20(address _token, address _to) external onlyOwner {
        require(
            IERC20(_token).balanceOf(address(this)) > 0,
            "Insufficient Balance"
        );
        IERC20(_token).transfer(_to, IERC20(_token).balanceOf(address(this)));
    }

    function claimBNB(address _to) external onlyOwner {
        require(
            address(this).balance > 0, 
            "Insufficient BNB"
        );
        payable(_to).transfer(address(this).balance);
    }
}