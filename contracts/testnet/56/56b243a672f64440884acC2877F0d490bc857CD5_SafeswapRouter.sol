/**
 *Submitted for verification at BscScan.com on 2022-08-09
*/

// File: contracts/SafeswapRouter.sol

/**
 *Submitted for verification at BscScan.com on 2022-07-08
*/

// File: contracts/IWETH.sol

pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}
// File: contracts/IERC20.sol

pragma solidity >=0.5.0;

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
// File: contracts/SafeMath.sol

pragma solidity =0.6.6;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }
}
// File: contracts/ISafeswapPair.sol

pragma solidity >=0.5.0;

interface ISafeswapPair {
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

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}
// File: contracts/SafeswapLibrary.sol

pragma solidity >=0.5.0;



library SafeswapLibrary {
    using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'SafeswapLibrary: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'SafeswapLibrary: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'd35c7ec97e43bffd213f56afac1c99a670866b8cb760f3953c376daa65bebf71' // init code hash
            ))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        pairFor(factory, tokenA, tokenB);
        (uint reserve0, uint reserve1,) = ISafeswapPair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'SafeswapLibrary: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'SafeswapLibrary: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'SafeswapLibrary: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'SafeswapLibrary: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(998);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'SafeswapLibrary: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'SafeswapLibrary: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(998);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'SafeswapLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'SafeswapLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}
// File: contracts/ISafeswapRouter01.sol

pragma solidity >=0.6.2;

interface ISafeswapRouter01 {
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
// File: contracts/ISafeswapRouter02.sol

pragma solidity >=0.6.2;


interface ISafeswapRouter02 is ISafeswapRouter01 {
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
// File: contracts/TransferHelper.sol


pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
  function safeApprove(
    address token,
    address to,
    uint256 value
) internal {
    // bytes4(keccak256(bytes('approve(address,uint256)')));
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
    require(
      success && (data.length == 0 || abi.decode(data, (bool))),
      'TransferHelper::safeApprove: approve failed'
    );
  }

  function safeTransfer(
    address token,
    address to,
    uint256 value
) internal {
    // bytes4(keccak256(bytes('transfer(address,uint256)')));
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
    require(
      success && (data.length == 0 || abi.decode(data, (bool))),
      'TransferHelper::safeTransfer: transfer failed'
    );
  }

  function safeTransferFrom(
    address token,
    address from,
    address to,
    uint256 value
) internal {
    // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
    require(
      success && (data.length == 0 || abi.decode(data, (bool))),
      'TransferHelper::transferFrom: transferFrom failed'
    );
  }

  function safeTransferETH(address to, uint256 value) internal {
    (bool success, ) = to.call{value: value}(new bytes(0));
    require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
  }
}
// File: contracts/ISafeswapFactory.sol

pragma solidity >=0.5.0;

interface ISafeswapFactory {
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
// File: contracts/SafeswapRouter.sol

pragma solidity =0.6.6;
pragma experimental ABIEncoderV2;

contract SafeswapRouter is ISafeswapRouter02 {
    using SafeMath for uint;

    address public override factory;
    address public override WETH;
    bool private killSwitch;
    address public admin;
    uint tokensCount;

    mapping (address => bool) public _isBlacklisted;
    mapping (address => bool) public _approvePartner;
    mapping (address => bool) private _lpTokenLockStatus;
    mapping (address => uint256) private _locktime;
    mapping(address => tokenInfo) nameToInfo;
    mapping(uint => address)  public idToAddress;
    event isSwiched (bool newSwitch);

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'SafeswapRouter: EXPIRED');
        _;
    }

    struct tokenInfo {
        bool enabled;
        string tokenName;
        address tokenAddress;
        address feesAddress;
        uint expectedBuy;
        uint expectedSell;
        uint actualBuy;
        uint actualSell;
    }

    constructor(address _factory, address _WETH) public {
        factory = _factory;
        WETH = _WETH;
        admin = msg.sender;
        tokensCount = 0;
        killSwitch = false;
    }

    modifier onlyOwner() {
        require(admin == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    receive() external payable {
        assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }

    function registerToken
        (
            string memory tokenName,
            address tokenAddress,
            address feesAddress, 
            uint expectedBuy, 
            uint expectedSell,
            uint actualBuy,
            uint actualSell,
            bool isUpdate
        )   
        public
        onlyOwner
        {
            
            if(!isUpdate){
                require(nameToInfo[tokenAddress].tokenAddress == address(0), "token already exists");
                idToAddress[tokensCount] = tokenAddress;
                tokensCount++;
            }else{
                require(nameToInfo[tokenAddress].tokenAddress != address(0), "token does not exist");
            }
            nameToInfo[tokenAddress].enabled = true;
            nameToInfo[tokenAddress].tokenName = tokenName;
            nameToInfo[tokenAddress].tokenAddress = tokenAddress;
            nameToInfo[tokenAddress].feesAddress = feesAddress;
            nameToInfo[tokenAddress].expectedBuy = expectedBuy;
            nameToInfo[tokenAddress].expectedSell = expectedSell;
            nameToInfo[tokenAddress].actualBuy = actualBuy;
            nameToInfo[tokenAddress].actualSell = actualSell;
            
        }

    // function to disable token stp    
    function switchSTPToken (address _tokenAddress) onlyOwner public {
        nameToInfo[_tokenAddress].enabled = !nameToInfo[_tokenAddress].enabled;
    }

    function getKillSwitch() public view returns(bool) {
        return killSwitch;
    }

    function switchSTP () onlyOwner public returns(bool){
        killSwitch = !killSwitch;
        emit isSwiched(killSwitch);
        return killSwitch;
    }

    function getAllStpTokens()public view returns(tokenInfo[] memory) {
        tokenInfo[] memory ret = new tokenInfo[](tokensCount);
        for (uint i = 0; i < tokensCount; i++) {
            ret[i] = nameToInfo[idToAddress[i]];
        }
        return ret;
    }

    function getTokenSTP(address _tokenAddress)
        public
        view
        returns(tokenInfo memory)
    {
        return nameToInfo[_tokenAddress];
    }

    // **** ADD LIQUIDITY ****
    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin
    ) internal virtual returns (uint amountA, uint amountB) {
        // create the pair if it doesn't exist yet
        if (ISafeswapFactory(factory).getPair(tokenA, tokenB) == address(0)) {
            ISafeswapFactory(factory).createPair(tokenA, tokenB);
        }
        (uint reserveA, uint reserveB) = SafeswapLibrary.getReserves(factory, tokenA, tokenB);
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint amountBOptimal = SafeswapLibrary.quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, 'SafeswapRouter: INSUFFICIENT_B_AMOUNT');
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint amountAOptimal = SafeswapLibrary.quote(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                require(amountAOptimal >= amountAMin, 'SafeswapRouter: INSUFFICIENT_A_AMOUNT');
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint amountA, uint amountB, uint liquidity) {
        require(!_isBlacklisted[to],"Address is blacklisted");
        require(_approvePartner[to],"Waiting for partner approval");
        (amountA, amountB) = _addLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin);
        address pair = SafeswapLibrary.pairFor(factory, tokenA, tokenB);
        TransferHelper.safeTransferFrom(tokenA, msg.sender, pair, amountA);
        TransferHelper.safeTransferFrom(tokenB, msg.sender, pair, amountB);
        liquidity = ISafeswapPair(pair).mint(to);
    }
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external virtual override payable ensure(deadline) returns (uint amountToken, uint amountETH, uint liquidity) {
        (amountToken, amountETH) = _addLiquidity(
            token,
            WETH,
            amountTokenDesired,
            msg.value,
            amountTokenMin,
            amountETHMin
        );
         require(_approvePartner[to],"Waiting for partner approval");
        address pair = SafeswapLibrary.pairFor(factory, token, WETH);
        TransferHelper.safeTransferFrom(token, msg.sender, pair, amountToken);
        IWETH(WETH).deposit{value: amountETH}();
        assert(IWETH(WETH).transfer(pair, amountETH));
        liquidity = ISafeswapPair(pair).mint(to);
        // refund dust eth, if any
        if (msg.value > amountETH) TransferHelper.safeTransferETH(msg.sender, msg.value - amountETH);
    }

    // **** REMOVE LIQUIDITY ****
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) public virtual override ensure(deadline) returns (uint amountA, uint amountB) {
        require(!_isBlacklisted[to],"Address is blacklisted");
        address pair = SafeswapLibrary.pairFor(factory, tokenA, tokenB);
        ISafeswapPair(pair).transferFrom(msg.sender, pair, liquidity); // send liquidity to pair
        (uint amount0, uint amount1) = ISafeswapPair(pair).burn(to);
        (address token0,) = SafeswapLibrary.sortTokens(tokenA, tokenB);
        (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
        require(amountA >= amountAMin, 'SafeswapRouter: INSUFFICIENT_A_AMOUNT');
        require(amountB >= amountBMin, 'SafeswapRouter: INSUFFICIENT_B_AMOUNT');
    }
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) public virtual override ensure(deadline) returns (uint amountToken, uint amountETH) {
         require(!_isBlacklisted[to],"Address is blacklisted");
        (amountToken, amountETH) = removeLiquidity(
            token,
            WETH,
            liquidity,
            amountTokenMin,
            amountETHMin,
            address(this),
            deadline
        );
        TransferHelper.safeTransfer(token, to, amountToken);
        IWETH(WETH).withdraw(amountETH);
        TransferHelper.safeTransferETH(to, amountETH);
    }
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external virtual override returns (uint amountA, uint amountB) {
        require(!_isBlacklisted[to],"Address is blacklisted");
        address pair = SafeswapLibrary.pairFor(factory, tokenA, tokenB);
        uint value = approveMax ? uint(-1) : liquidity;
        ISafeswapPair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        (amountA, amountB) = removeLiquidity(tokenA, tokenB, liquidity, amountAMin, amountBMin, to, deadline);
    }
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external virtual override returns (uint amountToken, uint amountETH) {
         require(!_isBlacklisted[to],"Address is blacklisted");
        address pair = SafeswapLibrary.pairFor(factory, token, WETH);
        uint value = approveMax ? uint(-1) : liquidity;
        ISafeswapPair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        (amountToken, amountETH) = removeLiquidityETH(token, liquidity, amountTokenMin, amountETHMin, to, deadline);
    }

    // **** REMOVE LIQUIDITY (supporting fee-on-transfer tokens) ****
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) public virtual override ensure(deadline) returns (uint amountETH) {
         require(!_isBlacklisted[to],"Address is blacklisted");
        (, amountETH) = removeLiquidity(
            token,
            WETH,
            liquidity,
            amountTokenMin,
            amountETHMin,
            address(this),
            deadline
        );
        TransferHelper.safeTransfer(token, to, IERC20(token).balanceOf(address(this)));
        IWETH(WETH).withdraw(amountETH);
        TransferHelper.safeTransferETH(to, amountETH);
    }
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external virtual override returns (uint amountETH) {
         require(!_isBlacklisted[to],"Address is blacklisted");
        address pair = SafeswapLibrary.pairFor(factory, token, WETH);
        uint value = approveMax ? uint(-1) : liquidity;
        ISafeswapPair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        amountETH = removeLiquidityETHSupportingFeeOnTransferTokens(
            token, liquidity, amountTokenMin, amountETHMin, to, deadline
        );
    }

    // **** SWAP ****
    // requires the initial amount to have already been sent to the first pair
    function _swap(uint[] memory amounts, address[] memory path, address _to) internal virtual {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = SafeswapLibrary.sortTokens(input, output);
            uint amountOut = amounts[i + 1];
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
            address to = i < path.length - 2 ? SafeswapLibrary.pairFor(factory, output, path[i + 2]) : _to;
            ISafeswapPair(SafeswapLibrary.pairFor(factory, input, output)).swap(
                amount0Out, amount1Out, to, new bytes(0)
            );
        }
    }
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint[] memory amounts) {
        amounts = SafeswapLibrary.getAmountsOut(factory, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'SafeswapRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        // snippet for 'sell' fees !
        if(nameToInfo[path[0]].enabled == true && killSwitch == false && (nameToInfo[path[0]].actualSell != nameToInfo[path[0]].expectedSell)) {
            uint deduction = amountIn.mul(nameToInfo[path[0]].expectedSell.sub(nameToInfo[path[0]].actualSell)).div(100);
            amountIn = amountIn.sub(deduction);
            TransferHelper.safeTransferFrom(
            path[0], msg.sender, nameToInfo[path[0]].feesAddress, deduction
            );
        }
        amounts = SafeswapLibrary.getAmountsOut(factory, amountIn, path);
        // same code snippet for 'buy' fees
        if(nameToInfo[path[1]].enabled == true && killSwitch == false && (nameToInfo[path[1]].actualBuy != nameToInfo[path[1]].expectedBuy)) {
            uint amountOut = amounts[amounts.length - 1];
            uint deduction = amountOut.mul(nameToInfo[path[1]].expectedBuy.sub(nameToInfo[path[1]].actualBuy)).div(100);
            amountOut = amountOut.sub(deduction);
            amounts[amounts.length-1] = amountOut;
        }
        //require(amounts[amounts.length - 1] >= amountOutMin, 'SafeswapRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, SafeswapLibrary.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, to);
    }
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint[] memory amounts) {
        amounts = SafeswapLibrary.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= amountInMax, 'SafeswapRouter: EXCESSIVE_INPUT_AMOUNT');
        if(nameToInfo[path[1]].enabled == true && killSwitch == false &&  (nameToInfo[path[1]].actualBuy != nameToInfo[path[1]].expectedBuy)) {
            uint deduction = amountOut.mul(nameToInfo[path[1]].expectedBuy.sub(nameToInfo[path[1]].actualBuy)).div(100);
            amountOut = amountOut.sub(deduction);
        }
        amounts = SafeswapLibrary.getAmountsIn(factory, amountOut, path);
        if(nameToInfo[path[0]].enabled == true &&  killSwitch == false && (nameToInfo[path[0]].actualSell != nameToInfo[path[0]].expectedSell)) {
            uint amountIn = amounts[0];
            uint deduction = amountIn.mul(nameToInfo[path[0]].expectedSell.sub(nameToInfo[path[0]].actualSell)).div(100);
            amounts[0] = amountIn.sub(deduction);
            TransferHelper.safeTransferFrom(
            path[0], msg.sender, nameToInfo[path[0]].feesAddress, deduction
            );
        }
        amounts = SafeswapLibrary.getAmountsOut(factory, amounts[0], path);

        TransferHelper.safeTransferFrom(
            path[0], msg.sender, SafeswapLibrary.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, to);
    }
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        virtual
        override
        payable
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[0] == WETH, 'SafeswapRouter: INVALID_PATH');
        amounts = SafeswapLibrary.getAmountsOut(factory, msg.value, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'SafeswapRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        if(nameToInfo[path[1]].enabled == true &&  killSwitch == false && (nameToInfo[path[1]].actualBuy != nameToInfo[path[1]].expectedBuy)) {
            uint amountOut = amounts[amounts.length - 1];
            uint deduction = amountOut.mul(nameToInfo[path[1]].expectedBuy.sub(nameToInfo[path[1]].actualBuy)).div(100);
            amounts[amounts.length - 1] = amountOut.sub(deduction);
        }
        IWETH(WETH).deposit{value: amounts[0]}();
        assert(IWETH(WETH).transfer(SafeswapLibrary.pairFor(factory, path[0], path[1]), amounts[0]));
        _swap(amounts, path, to);
    }
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        virtual
        override
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[path.length - 1] == WETH, 'SafeswapRouter: INVALID_PATH');
        amounts = SafeswapLibrary.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= amountInMax, 'SafeswapRouter: EXCESSIVE_INPUT_AMOUNT');
        if(nameToInfo[path[0]].enabled == true &&  killSwitch == false && (nameToInfo[path[0]].actualSell != nameToInfo[path[0]].expectedSell)) {
            uint amountIn = amounts[0];
            uint deduction = amountIn.mul(nameToInfo[path[0]].expectedSell.sub(nameToInfo[path[0]].actualSell)).div(100);
            amounts[0] = amountIn.sub(deduction);
            TransferHelper.safeTransferFrom(
            path[0], msg.sender, nameToInfo[path[0]].feesAddress, deduction
            );
        }
        amounts = SafeswapLibrary.getAmountsOut(factory, amounts[0], path);
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, SafeswapLibrary.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, address(this));
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    }
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        virtual
        override
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[path.length - 1] == WETH, 'SafeswapRouter: INVALID_PATH');
        uint[] memory oldamounts = SafeswapLibrary.getAmountsOut(factory, amountIn, path); // ,amountIn,
        require(oldamounts[oldamounts.length - 1] >= amountOutMin, 'SafeswapRouter: INSUFFICIENT_OUTPUT_AMOUNT');

        if(nameToInfo[path[0]].enabled == true &&  killSwitch == false && (nameToInfo[path[0]].actualSell != nameToInfo[path[0]].expectedSell)) {
            uint deduction = amountIn.mul(nameToInfo[path[0]].expectedSell.sub(nameToInfo[path[0]].actualSell)).div(100);
            amountIn = amountIn.sub(deduction);
            TransferHelper.safeTransferFrom(
            path[0], msg.sender, nameToInfo[path[0]].feesAddress, deduction
            );
        }

        amounts = SafeswapLibrary.getAmountsOut(factory, amountIn, path); // ,amountIn,

        TransferHelper.safeTransferFrom(
            path[0], msg.sender, SafeswapLibrary.pairFor(factory, path[0], path[1]), amounts[0] // amouts[0]
        );
        _swap(amounts, path, address(this));
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    }
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        virtual
        override
        payable
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[0] == WETH, 'SafeswapRouter: INVALID_PATH');
        amounts = SafeswapLibrary.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= msg.value, 'SafeswapRouter: EXCESSIVE_INPUT_AMOUNT');
        if(nameToInfo[path[1]].enabled == true &&  killSwitch == false && (nameToInfo[path[1]].actualBuy != nameToInfo[path[1]].expectedBuy)) {
            uint deduction = amountOut.mul(nameToInfo[path[1]].expectedBuy.sub(nameToInfo[path[1]].actualBuy)).div(100);
            amountOut = amountOut.sub(deduction);
        }
        amounts = SafeswapLibrary.getAmountsIn(factory, amountOut, path);

        IWETH(WETH).deposit{value: amounts[0]}();
        assert(IWETH(WETH).transfer(SafeswapLibrary.pairFor(factory, path[0], path[1]), amounts[0]));
        _swap(amounts, path, to);
        // refund dust eth, if any
        if (msg.value > amounts[0]) TransferHelper.safeTransferETH(msg.sender, msg.value - amounts[0]);
    }

    // **** SWAP (supporting fee-on-transfer tokens) ****
    // requires the initial amount to have already been sent to the first pair
    function _swapSupportingFeeOnTransferTokens(address[] memory path, address _to) internal virtual {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = SafeswapLibrary.sortTokens(input, output);
            ISafeswapPair pair = ISafeswapPair(SafeswapLibrary.pairFor(factory, input, output));
            uint amountInput;
            uint amountOutput;
            { // scope to avoid stack too deep errors
            (uint reserve0, uint reserve1,) = pair.getReserves();
            (uint reserveInput, uint reserveOutput) = input == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
            amountInput = IERC20(input).balanceOf(address(pair)).sub(reserveInput);
            amountOutput = SafeswapLibrary.getAmountOut(amountInput, reserveInput, reserveOutput);
            }
            if(killSwitch == false) {
                uint deduction = amountOutput.mul(nameToInfo[output].expectedBuy.sub(nameToInfo[output].actualBuy)).div(100);
                amountOutput = amountOutput.sub(deduction);
            }
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOutput) : (amountOutput, uint(0));
            address to = i < path.length - 2 ? SafeswapLibrary.pairFor(factory, output, path[i + 2]) : _to;
            pair.swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) {
        
        if(nameToInfo[path[0]].enabled == true && killSwitch == false && (nameToInfo[path[0]].actualSell != nameToInfo[path[0]].expectedSell)) {
            uint deduction = amountIn.mul(nameToInfo[path[0]].expectedSell.sub(nameToInfo[path[0]].actualSell)).div(100);
            amountIn = amountIn.sub(deduction);
            TransferHelper.safeTransferFrom(
            path[0], msg.sender, nameToInfo[path[0]].feesAddress, deduction
            );
        }
        
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, SafeswapLibrary.pairFor(factory, path[0], path[1]), amountIn
        );
        uint balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(path, to);
        /*require(
            IERC20(path[path.length - 1]).balanceOf(to).sub(balanceBefore) >= amountOutMin,
            'SafeswapRouter: INSUFFICIENT_OUTPUT_AMOUNT'
        );*/
    }
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    )
        external
        virtual
        override
        payable
        ensure(deadline)
    {
        require(path[0] == WETH, 'SafeswapRouter: INVALID_PATH');
        uint amountIn = msg.value;
        IWETH(WETH).deposit{value: amountIn}();
        assert(IWETH(WETH).transfer(SafeswapLibrary.pairFor(factory, path[0], path[1]), amountIn));
        uint balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(path, to);
        require(
            IERC20(path[path.length - 1]).balanceOf(to).sub(balanceBefore) >= amountOutMin,
            'SafeswapRouter: INSUFFICIENT_OUTPUT_AMOUNT'
        );
    }
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    )
        external
        virtual
        override
        ensure(deadline)
    {
        require(path[path.length - 1] == WETH, 'SafeswapRouter: INVALID_PATH');

        if(nameToInfo[path[0]].enabled == true && killSwitch == false && (nameToInfo[path[0]].actualSell != nameToInfo[path[0]].expectedSell)) {
            uint deduction = amountIn.mul(nameToInfo[path[0]].expectedSell.sub(nameToInfo[path[0]].actualSell)).div(100);
            amountIn = amountIn.sub(deduction);
            TransferHelper.safeTransferFrom(
            path[0], msg.sender, nameToInfo[path[0]].feesAddress, deduction
            );
        }
        
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, SafeswapLibrary.pairFor(factory, path[0], path[1]), amountIn
        );
        _swapSupportingFeeOnTransferTokens(path, address(this));
        uint amountOut = IERC20(WETH).balanceOf(address(this));
        require(amountOut >= amountOutMin, 'SafeswapRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        IWETH(WETH).withdraw(amountOut);
        TransferHelper.safeTransferETH(to, amountOut);
    }

    // **** LIBRARY FUNCTIONS ****
    function quote(uint amountA, uint reserveA, uint reserveB) public pure virtual override returns (uint amountB) {
        return SafeswapLibrary.quote(amountA, reserveA, reserveB);
    }

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut)
        public
        pure
        virtual
        override
        returns (uint amountOut)
    {
        return SafeswapLibrary.getAmountOut(amountIn, reserveIn, reserveOut);
    }

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut)
        public
        pure
        virtual
        override
        returns (uint amountIn)
    {
        return SafeswapLibrary.getAmountIn(amountOut, reserveIn, reserveOut);
    }

    function getAmountsOut(uint amountIn, address[] memory path)
        public
        view
        virtual
        override
        returns (uint[] memory amounts)
    {
        return SafeswapLibrary.getAmountsOut(factory, amountIn, path);
    }

    function getAmountsIn(uint amountOut, address[] memory path)
        public
        view
        virtual
        override
        returns (uint[] memory amounts)
    {
        return SafeswapLibrary.getAmountsIn(factory, amountOut, path);
    }

    function blacklistAddress(address account) public onlyOwner() {
        _isBlacklisted[account] = true;
    }

    function unBlacklistAddress(address account) public onlyOwner() {
        _isBlacklisted[account] = false;
    }

    function approveLiquidityPartner(address account) public onlyOwner {
        _approvePartner[account] = true;
    }

    function unApproveLiquidityPartner(address account) public onlyOwner {
        _approvePartner[account] = false;
    }

    function lockLP(address LPtoken, uint256 time) public onlyOwner {
        _lpTokenLockStatus[LPtoken] = true;
        _locktime[LPtoken] = block.timestamp + time;
    }

}