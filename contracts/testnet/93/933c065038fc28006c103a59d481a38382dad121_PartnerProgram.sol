// SPDX-License-Identifier: GPL-3.0
import "./interfaces/IERC20.sol";
import "./libraries/SafeMath.sol";
import "./utils/Context.sol";

pragma solidity 0.8.16;

/**
 * @title Partner Program's Contract
 * @author HeisenDev
 */
contract PartnerProgram is Context {
    using SafeMath for uint256;
    uint256 partnerProgramTax = 1;
    struct Contract {
        address contractAddress;
        address payable paymentsWallet;
        uint256 partnerCommission;
        address author;
        string coinName;
        string coinSymbol;
        string website;
        string twitter;
        string telegram;
        string discord;
        bool isValue;
    }

    struct Partner {
        string name;
        string code;
        address payable partnerAddress;
        address payable managerAddress;
        uint256 taxFeePartner;
        uint256 taxFeeManager;
        bool isValue;
    }

    mapping(string => Partner) public partners;
    mapping(address => Contract) private contracts;
    mapping(address => bool) private _isPartner;

    event Deposit(address indexed sender, uint amount);
    event NewPartner(string indexed code);
    event NewProject(address indexed contractAddress, string indexed_coinName, string indexed _coinSymbol);
    event PartnerProgramBUY(address indexed sender, address indexed _contract, string indexed _code, uint amount);


    constructor() {}


    /// @dev Fallback function allows to deposit ether.
    receive() external payable {
        if (msg.value > 0) {
            emit Deposit(_msgSender(), msg.value);
        }
    }

    function executePaymentsETH(address _contractAddress, string memory _code) internal {
        uint256 amount = msg.value;
        Contract storage _token = contracts[_contractAddress];
        Partner storage _partner = partners[_code];
        uint commissionContract = _token.partnerCommission;
        uint taxPartner = _partner.taxFeePartner;
        uint taxPartnerManager = _partner.taxFeeManager;
        uint partnerTaxesAmount = amount.mul(commissionContract).div(100);
        uint256 partnerAmount = partnerTaxesAmount.mul(taxPartner).div(100);
        uint256 managerAmount = partnerTaxesAmount.mul(taxPartnerManager).div(100);
        uint256 partnerProgram = partnerTaxesAmount.mul(partnerProgramTax).div(100);
        amount = amount.sub(partnerAmount);
        amount = amount.sub(managerAmount);
        amount = amount.sub(partnerProgram);
        bool sent;
        (sent, ) = _partner.partnerAddress.call{value: partnerAmount}("");
        require(sent, "Deposit ETH: failed to send ETH");
        (sent, ) = _partner.managerAddress.call{value: managerAmount}("");
        require(sent, "Deposit ETH: Failed to send ETH");
        (sent, ) = _token.paymentsWallet.call{value: amount}("");
        require(sent, "Deposit ETH: Failed to send ETH");
    }
    modifier checkAllowance(uint amount, address _contractAddress) {
        IERC20 _token = IERC20(_contractAddress);
        require(_token.allowance(msg.sender, address(this)) >= amount, "Check the token allowance");
        _;
    }
    modifier isPartnerProgramContract(address _contractAddress) {
        require(contracts[_contractAddress].isValue, "Contracts: contract not exist");
        _;
    }

    modifier isPartnerProgramMember(string memory _code) {
        require(partners[_code].isValue, "Partners: code not exist");
        _;
    }

    function depositTokens(uint _amount, string memory _code, address _contractAddress) external payable checkAllowance(_amount, _contractAddress) {
        IERC20 _token = IERC20(_contractAddress);
        _token.transferFrom(msg.sender, address(this), _amount);
        emit PartnerProgramBUY(_msgSender(), _contractAddress, _code, _amount);
    }

    function depositETH(string memory _code, address _contractAddress) external payable isPartnerProgramMember(_code) isPartnerProgramContract(_contractAddress) {
        require(msg.value > 0, "You need to send some ether");
        executePaymentsETH(_contractAddress, _code);
        emit PartnerProgramBUY(_msgSender(), _contractAddress, _code, msg.value);
    }

    function joinAsProject(
        address _contractAddress,
        address payable _paymentsWallet,
        uint256 _partnerCommission,
        string memory _coinName,
        string memory _coinSymbol,
        string memory _website,
        string memory _twitter,
        string memory _telegram,
        string memory _discord) external {
        require(msg.sender == tx.origin, "New Contract: contracts not allowed here");
        require(_partnerCommission > 0, "New Contract: commission must be greater than zero");
        require(_partnerCommission <= 30, "New Contract: partner commission must keep 30% or less");
        IERC20 _token = IERC20(_contractAddress);
        require(_token.owner() == _msgSender(), "New Contract: caller is not the owner");
        contracts[_contractAddress] = Contract({
        contractAddress : _contractAddress,
        paymentsWallet: _paymentsWallet,
        partnerCommission : _partnerCommission,
        author : _msgSender(),
        coinName : _coinName,
        coinSymbol : _coinSymbol,
        website : _website,
        twitter : _twitter,
        telegram : _telegram,
        discord : _discord,
        isValue: true
        });
        emit NewProject(_contractAddress, _coinName, _coinSymbol);
    }
    function joinAsPartner (
        string memory _name,
        string memory _code,
        address payable _partnerAddress,
        address payable _managerAddress,
        uint256 _taxFeePartner,
        uint256 _taxFeeManager) external {
        require(!partners[_code].isValue, "Partners: code already exists");
        require(_taxFeePartner +  _taxFeeManager == 100, "The sum of the taxes must be 100");
        partners[_code] = Partner({
        name: _name,
        code: _code,
        partnerAddress: _partnerAddress,
        managerAddress: _managerAddress,
        taxFeePartner: _taxFeePartner,
        taxFeeManager: _taxFeeManager,
        isValue: true
        });
        emit NewPartner(_code);
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

    function owner() external view returns (address);
    function name() external view returns (string calldata);
    function ownerOf(uint256 tokenId) external view returns (address);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
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