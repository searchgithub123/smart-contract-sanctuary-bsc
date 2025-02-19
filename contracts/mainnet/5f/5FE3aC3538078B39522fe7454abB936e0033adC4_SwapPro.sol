//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDEXRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

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

    function swapExactETHForTokens(
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

    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function getAmountsIn(
        uint256 amountOut,
        address[] calldata path
    ) external pure returns(uint256[] memory);

    function getAmountsOut(
        uint256 amountIn,
        address[] calldata path
    ) external pure returns(uint256[] memory);
}

interface ISwapPro {
    function approveBUSD() external;
}

contract SwapPro is ISwapPro, Ownable {
    address public constant  BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    // address public constant  BUSD = 0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7;
    address public constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c; //0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;// 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
    
    address public singer1 = 0xC15c1771Dc2D5edb18501BD42b24C91Bc9554A06;
    address public singer2 = 0x9621C115e219533d18E49B436dddCe4d25DF59e9;

    address prevSigner;
    address token;
    uint256 amount;
    address to;
    bool public isBNB;
    uint8 status; // 1 => pending, 2 => approved, 3=> rejected;

    IDEXRouter router;
    uint256 public prevBUSD;
    uint256 public prevBNB;
    uint256 public deltaBUSDAmount = 0.01*10**18;


    constructor () {
        router = IDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        // router = IDEXRouter(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);
    }

    modifier onlyOwners() {
        require(msg.sender==singer1||msg.sender==singer2);
        _;
    }
    function approveBUSD() external override {
        IERC20(BUSD).approve(address(router), 10000000*10**18);
    }

    function firstApprove() external {
        ISwapPro(address(this)).approveBUSD();
    }

    function swap () public {
            prevBUSD = IERC20(BUSD).balanceOf(address(this));
            address[] memory path = new address[](2);
            path[0] = BUSD;
            path[1] = WBNB;
            router.swapExactTokensForETH(
                prevBUSD,
                0,
                path,
                address(this),
                block.timestamp
            );

            path[0] = WBNB;
            path[1] = BUSD;
            router.swapExactETHForTokens{value: address(this).balance}(
                0,
                path,
                address(this),
                block.timestamp
            );
            
            if(IERC20(BUSD).balanceOf(address(this)) <= prevBUSD) {
                revert("Bad trading");
            }
    }

    function getProfit() public view returns(bool, uint256) {
        if(getAmountsOutBUSD() > prevBUSD) return (true, getAmountsOutBUSD() - prevBUSD);
        else return (false, prevBUSD - getAmountsOutBUSD());
    }

    function getAmountsOutBNB() public view returns(uint256) {
        uint256 busdBal = IERC20(BUSD).balanceOf(address(this));
        if(busdBal == 0) return 0;
        address[] memory path = new address[](2);
        path[0] = BUSD;
        path[1] = WBNB;
        return router.getAmountsOut(busdBal, path)[1];
    }

    function getAmountsOutBUSD() public view returns(uint256) {
        uint256 bnbBal = address(this).balance;
        if(bnbBal == 0) return 0;
        address[] memory path = new address[](2);
        path[0] = WBNB;
        path[1] = BUSD;
        return router.getAmountsOut(bnbBal, path)[1];
    }

    function requestTokenTransaction(address _token, uint256 _amount, address _to) public onlyOwners {
        require(status!=1, "Current transaction is not approved or rejected");
        require(exists(_token)==true, "this is not token address");
        require(IERC20(_token).balanceOf(address(this))>=_amount, "Insufficient balance");
        prevSigner = msg.sender;
        token = _token;
        amount = _amount;
        to = _to;
        isBNB = false;
        status = 1;
    }
    function requestBNBTransaction(uint256 _amount, address _to) public onlyOwners {
        require(status!=1, "Current transaction is not approved or rejected");
        prevSigner = msg.sender;
        token = address(0);
        amount = _amount;
        to = _to;
        isBNB = true;
        status = 1;
    }
    function approveTransaction() public onlyOwners {
        require(prevSigner!=msg.sender, "You are first signer for this transaction");
        require(status==1, "This transaction was already approved or rejected (there is no requested transaction)");
        if(isBNB==true) {
            payable(to).transfer(amount);
        }else {
            IERC20(token).transfer(to, amount);
        }
        
        status = 2;
    }
    function rejectTransaction() public onlyOwners {
        require(status==1, "This transaction was already approved or rejected (there is no requested transaction)");
        status = 3;
    }

    function exists(address what)
        internal
        view
        returns (bool)
    {
        uint size;
        assembly {
            size := extcodesize(what)
        }
        return size > 0;
    }

    function getCurrentTranscaction() public view returns(address _prevSigner, address _token, uint256 _amount, address _to, uint8 _status, bool _isBNB) {
        return (prevSigner, token, amount, to, status, isBNB);
    }
    function updateDeltaAmount(uint256 _amount) external onlyOwners {
        deltaBUSDAmount = _amount;
    }
    function initAgain() external onlyOwners {
        prevBNB = 0;
        prevBUSD = 0;
    }
    receive() external payable { }
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