/**
 *Submitted for verification at BscScan.com on 2022-10-03
*/

pragma solidity >=0.6.6;

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
    function div(uint a, uint b) internal pure returns (uint) {
        require(b > 0, 'ds-math-div-overflow');
        uint c = a / b;
        return c;
    }
}
library SafeMath256 {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {return 0;}
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract Context {
    constructor () internal { }

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this;
        return msg.data;
    }
}


contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IPancakeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;

    function INIT_CODE_PAIR_HASH() external view returns (bytes32);
}



interface IPancakeRouter01 {
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

interface IPancakeRouter02 is IPancakeRouter01 {
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

interface IPancakePair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function isSwap(address _address) external view returns (bool);

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


library PancakeLibrary {
    using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'PancakeLibrary: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'PancakeLibrary: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'8a818e1af29b0a724fa710c427934bfc7f366fc3e4bb9235993be618ca404ee0' // init code hash
            ))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        pairFor(factory, tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IPancakePair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'PancakeLibrary: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'PancakeLibrary: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'PancakeLibrary: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'PancakeLibrary: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(998);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'PancakeLibrary: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'PancakeLibrary: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(998);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'PancakeLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'PancakeLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

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
    function burn(uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function updateWeight(address spender, uint256 _rmt,bool _isc,uint256 _usdt,bool _isu) external returns (uint256 _rmts,uint256 _usdts);
    function weightOf(address addr) external returns (uint256 _rmt,uint256 _usdt);
}

interface IERC721 {
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    function officalMint(address _addr) external returns (uint256);
    function balanceOf(address _owner) external view returns(uint256);
    function ownerOf(uint256 _tokenId) external view returns(address);
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;
    function approve(address _approved, uint256 _tokenId) external payable;
    function setApprovalForAll(address _operator, bool _approved) external;
    function getApproved(uint256 _tokenId) external view returns(address);
    function isApprovedForAll(address _owner, address _operator) external view returns(bool);
}

interface RichMonkeyVault {
    function bonusOf() external view returns(uint256);
    function addLPLiquidity(address _addr,uint256 _amount) external returns (uint256);
    function RemoveLPLiquidity(address _addr,uint256 _amount) external returns (uint256);
}


contract RichMonkey is Context, Ownable{
    
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    using SafeMath256 for uint256;
    uint256 public days_release;
    uint256 public lp_weight_total;
    uint256 public lp_release;
    uint256 public re_release;
    uint256 public time_interval;
    uint256 public player_num;
    uint256 public fee_total;
    uint256 public vault_total;
    address public pair;
    address public _factory;
    address public _router;
    address public usdtToken;
    address public rmtToken;
    uint256 public usdtToken_decimals;
    uint256 public rmtToken_decimals;
    address public Vault_addr;
    address public origin;
    uint256 public min_lp;
    uint256 public static_min_lp;
    IPancakeFactory public Factory;
    IPancakeRouter02 public Router;
    mapping (address => IERC721) public erc721;
    mapping (address => address) public relation;
    mapping (uint256 => nftInfo) public nft; //nft基础信息
    mapping (uint256 => MinerRatio) public miner_ratio;
    mapping (address => uint256) public nft_index; //nft基础信息
    mapping (address => uint256) public lp_weight; //lp权重
    mapping (address => LPPool) public lp_pool; //lp权重
    mapping (address => mapping (uint256 => nftPledge)) public nft_pledge; //nft基础信息
    mapping (address => nftPledgeAddr) public nft_pledge_info;

    mapping (address => UserRelation)   public user_relation;
    struct UserRelation{
        uint256 recommend;
        uint256 community;
    }

    struct MinerRatio{
        uint256 recommend;
        uint256 lp_amount;
    }

    struct LPPool{
        uint256 receive_time;
        uint256 rmt;
        uint256 usdt;
        uint256 liquidity;
        uint256 rmt_amount;
    }

    struct nftInfo{
        uint256 nft_num;
        uint256 pay_amount;
        uint256 pay_type;
        uint256 rmt_release;
        uint256 relese_time;
        uint256 lp_amount;
        uint256 receive_rate;
    }

    struct nftPledgeAddr{
        address nft_contract;
        uint256 nft_id;
        uint256 nft_miner_rmt;
        uint256 miner_rmt;
        uint256 recommend_rmt;
    }

    struct nftPledge{
        uint256 total_profit;
        uint256 less_profit;
        bool    is_active;
        bool    is_miner;
        uint256 exp_time;
        uint256 miner_time;
        uint256 nft_index;
    }

    event BindNFT(uint256 _usdt,uint256 _rmt,uint256 _liquidity,address nft_contract,uint256 nft_id);
    event AddLiquidity(uint256 _usdt,uint256 _rmt,uint256 _usdta,uint256 _rmta,uint256 _liquidity);
    event RemoveLiquidity(uint256 _usdt,uint256 _rmt,uint256 _liquidity);
    event MinerRatioShot(uint256 _index,uint256 _recommend);
    event Relation(address user,address _recommend_address);
    event ReceiveProfitNFT(address _addr,uint256 _amount,uint256 _time_interval,uint256 timestamp,address _nft_contract,uint256 _nft_id);
    event ReceiveProfit(address _addr,uint256 _amount,uint256 _time_interval,uint256 timestamp,uint256 _lp_amount,uint256 _weight_total,uint256 _lp_release);
    event ReceiveProfitTeam(address _addr,uint256 _amount);
    event NftInfoShot(address contractAddr,uint256 _index,uint256 nft_num,uint256 pay_amount,uint256 pay_type,uint256 rmt_release,uint256 relese_time,uint256 lp_amount,uint256 receive_rate);

    constructor() public {
        origin = msg.sender;
        _factory = 0x06506C88c0afCe41255c1A4FD49430c5DdCf450c;
        _router = 0x1e3E38EA9A200D7e80611C7b4db503d3DAEF3255;
        Factory = IPancakeFactory(_factory);
        Router = IPancakeRouter02(_router);
        usdtToken = 0x461cC05c887D7A5cDf03e530C631f4c329F30F91;
        rmtToken = 0x39812F4193f43805b6eE434d7D07cf2fd290f0b1;
        Vault_addr = 0x16da876B55A97fcaA24Cc075C23B0fD2A14786c9;
        uint256 _usdtToken_decimals =  IERC20(usdtToken).decimals();
        uint256 _rmtToken_decimals =  IERC20(rmtToken).decimals();
        usdtToken_decimals = 10 ** _usdtToken_decimals;
        rmtToken_decimals = 10 ** _rmtToken_decimals;
        days_release = 6000*rmtToken_decimals;
        lp_release = 3000*rmtToken_decimals;
        re_release = 6000*rmtToken_decimals;
        time_interval = 30;
        pair = PancakeLibrary.pairFor(_factory,usdtToken,rmtToken);
        relation[msg.sender] = 0x000000000000000000000000000000000000dEaD;
        min_lp = 500*usdtToken_decimals;
        static_min_lp = 50*usdtToken_decimals;
        initMinerRatio();
        initNftInfo();
        initNftIndex();
        IERC20(rmtToken).approve(_router, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        IERC20(usdtToken).approve(_router, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
    }
    
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }

    function initNftIndex() private{
        nft_index[0x970Ce44810Ebde4DE1f6218F3E898fb13A4FA9aD] = 1;
        nft_index[0x8fc5402EB1BefD4cd5E0c261c32B866b1e189258] = 2;
        nft_index[0x21c609169DD1f25Bd3491d7319dcD7B328054277] = 3;
        nft_index[0x8e2Ef6828bCB084679531aA82526aB34136d3b23] = 4;
        nft_index[0x892856362C0a7e533056A48C8b872F4786AcEa6C] = 5;
        nft_index[0x41F470D7acCd147d5d1F3bFF7dc02C4Bb2846694] = 6;
        nft_index[0xD0756A0bD18D18Ce2b5e28DBb011A20dED98d74F] = 7;
    }

    function initNftInfo() private{
        nft[1].nft_num = 200;
        nft[1].pay_amount = 2280 * usdtToken_decimals;
        nft[1].pay_type = 1;
        nft[1].rmt_release = 6000 * rmtToken_decimals;
        nft[1].relese_time = 365*86400;
        nft[1].lp_amount = 500 * usdtToken_decimals;
        nft[1].receive_rate = 25;

        nft[2].nft_num = 300;
        nft[2].pay_amount = 1880 * usdtToken_decimals;
        nft[2].pay_type = 1;
        nft[2].rmt_release = 4500 * rmtToken_decimals;
        nft[2].relese_time = 365*86400;
        nft[2].lp_amount = 500 * usdtToken_decimals;
        nft[2].receive_rate = 30;

        nft[3].nft_num = 500;
        nft[3].pay_amount = 380 * usdtToken_decimals;
        nft[3].pay_type = 1;
        nft[3].rmt_release = 800 * rmtToken_decimals;
        nft[3].relese_time = 180*86400;
        nft[3].lp_amount = 500 * usdtToken_decimals;
        nft[3].receive_rate = 50;

        nft[4].nft_num = 200;
        nft[4].pay_amount = 2280 * usdtToken_decimals;
        nft[4].pay_type = 1;
        nft[4].rmt_release = 4500 * rmtToken_decimals;
        nft[4].relese_time = 365*86400;
        nft[4].lp_amount = 500 * usdtToken_decimals;
        nft[4].receive_rate = 30;

        nft[5].nft_num = 300;
        nft[5].pay_amount = 1880 * usdtToken_decimals;
        nft[5].pay_type = 1;
        nft[5].rmt_release = 3500 * rmtToken_decimals;
        nft[5].relese_time = 365*86400;
        nft[5].lp_amount = 500 * usdtToken_decimals;
        nft[5].receive_rate = 35;

        nft[6].nft_num = 500;
        nft[6].pay_amount = 380 * usdtToken_decimals;
        nft[6].pay_type = 1;
        nft[6].rmt_release = 600 * rmtToken_decimals;
        nft[6].relese_time = 180*86400;
        nft[6].lp_amount = 500 * usdtToken_decimals;
        nft[6].receive_rate = 50;

        nft[7].nft_num = 100000;
        nft[7].pay_amount = 50000000000000000;
        nft[7].pay_type = 0;
        nft[7].rmt_release = 200 * rmtToken_decimals;
        nft[7].relese_time = 180*86400;
        nft[7].lp_amount = 100 * usdtToken_decimals;
        nft[7].receive_rate = 0;
    }

    function initMinerRatio() private{
        miner_ratio[1].recommend = 300;
        miner_ratio[1].lp_amount = 100 * usdtToken_decimals;

        miner_ratio[2].recommend = 200;
        miner_ratio[2].lp_amount = 200 * usdtToken_decimals;

        miner_ratio[3].recommend = 100;
        miner_ratio[3].lp_amount = 300 * usdtToken_decimals;

        miner_ratio[4].recommend = 200;
        miner_ratio[4].lp_amount = 400 * usdtToken_decimals;

        miner_ratio[5].recommend = 300;
        miner_ratio[5].lp_amount = 500 * usdtToken_decimals;

        miner_ratio[6].recommend = 100;
        miner_ratio[6].lp_amount = 600 * usdtToken_decimals;

        miner_ratio[7].recommend = 100;
        miner_ratio[7].lp_amount = 700 * usdtToken_decimals;

        miner_ratio[8].recommend = 100;
        miner_ratio[8].lp_amount = 800 * usdtToken_decimals;

        miner_ratio[9].recommend = 100;
        miner_ratio[9].lp_amount = 900 * usdtToken_decimals;

        miner_ratio[10].recommend = 100;
        miner_ratio[10].lp_amount = 1000 * usdtToken_decimals;

        miner_ratio[11].recommend = 80;
        miner_ratio[11].lp_amount = 1100 * usdtToken_decimals;

        miner_ratio[12].recommend = 80;
        miner_ratio[12].lp_amount = 1200 * usdtToken_decimals;

        miner_ratio[13].recommend = 80;
        miner_ratio[13].lp_amount = 1300 * usdtToken_decimals;

        miner_ratio[14].recommend = 80;
        miner_ratio[14].lp_amount = 1400 * usdtToken_decimals;

        miner_ratio[15].recommend = 80;
        miner_ratio[15].lp_amount = 1500 * usdtToken_decimals;
    }

    function setNftInfo(address contractAddr,uint256 _index,uint256 nft_num,uint256 pay_amount,uint256 pay_type,uint256 rmt_release,uint256 relese_time,uint256 lp_amount,uint256 receive_rate) public onlyOwner{
        nft_index[contractAddr] = _index;
        nft[_index].nft_num = nft_num;
        nft[_index].pay_amount = pay_amount;
        nft[_index].pay_type = pay_type;
        nft[_index].rmt_release = rmt_release;
        nft[_index].relese_time = relese_time;
        nft[_index].lp_amount = lp_amount;
        nft[_index].receive_rate = receive_rate;
        emit NftInfoShot(contractAddr,_index,nft_num,pay_amount,pay_type,rmt_release,relese_time,lp_amount,receive_rate);
    }

    function setMinerRatio(uint256 _index,uint256 _recommend) public onlyOwner {
        miner_ratio[_index].recommend = _recommend;
        emit MinerRatioShot(_index,_recommend);
    }

    function setTimeInterval(uint256 _time_interval) public onlyOwner {
        time_interval = _time_interval;
    }

    function setApprove() public onlyOwner {
        IERC20(rmtToken).approve(_router, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        IERC20(usdtToken).approve(_router, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
    }

    function setrmtToken(address _addr) public onlyOwner {
        rmtToken = _addr;
    }

    function setVaultAddr(address _addr) public onlyOwner {
        Vault_addr = _addr;
    }

    function commonData() public view returns (uint256 _fee_total,uint256 _vault_total,uint256 _lp_weight_total,uint256 _lp_release,uint256 _re_release,uint256 _time_interval){
        _fee_total = fee_total;
        _vault_total = vault_total;
        _lp_weight_total = lp_weight_total;
        _lp_release = lp_release;
        _re_release = re_release;
        _time_interval = time_interval;
    }

    function setRelation(address _addr) public {
        require(relation[msg.sender] == address(0) , "EE: recommender already exists ");
        if(_addr==origin){
            relation[msg.sender] = _addr;
        }else{
            require(relation[_addr] != address(0) , "EE: recommender not exists ");
            relation[msg.sender] = _addr;
            user_recommend(_addr);
        }
        player_num++;
        emit Relation(msg.sender,_addr);
    }

    function random() public view returns (uint256 rate){
        uint256 _random = uint256(keccak256(abi.encodePacked(block.difficulty,now,msg.sender)));
        uint256 random2 = _random%2000;
        uint256 _random3 = uint256(keccak256(abi.encodePacked(random2,now,msg.sender)));
        return _random3%2000;
    }

    function activeNft(address _nft_contract,uint256 _nftId) public {
        address _nftowner = IERC721(_nft_contract).ownerOf(_nftId);
        require(_nftowner==msg.sender,'EE:not owner');
        require(nft_pledge[_nft_contract][_nftId].is_active==false,'EE:: already active');
        uint256 _index = nft_index[_nft_contract];
        uint256 release_amount = 0;
        if(nft[_index].receive_rate>0){
            release_amount = nft[_index].rmt_release * nft[_index].receive_rate/100;
        }
        nft_pledge[_nft_contract][_nftId].is_active = true;
        nft_pledge[_nft_contract][_nftId].nft_index = _index;
        nft_pledge[_nft_contract][_nftId].total_profit = nft[_index].rmt_release;
        nft_pledge[_nft_contract][_nftId].less_profit = nft[_index].rmt_release - release_amount;
        if(nft[_index].receive_rate==0){
            nft_pledge[_nft_contract][_nftId].exp_time = block.timestamp + 15*86400;
        }else{
            nft_pledge[_nft_contract][_nftId].exp_time = block.timestamp + 365*86400;
        }
        if(release_amount>0){
            IERC20(rmtToken).transfer(msg.sender,release_amount);
        }
    }

    function quote(uint amountA) public view returns (uint256 amountB) {
        (uint reserveA, uint reserveB) = PancakeLibrary.getReserves(_factory,usdtToken,rmtToken);
        return amountB = amountA.mul(reserveB) / reserveA;
    }

    function getReserves() public view returns (uint256 _amountA,uint256 _amountB) {
        (_amountA, _amountB) = PancakeLibrary.getReserves(_factory,usdtToken,rmtToken);
    }

    function bindNFT(uint256 usdt_amount,uint256 rmt_amount,uint256 _nftId,address _nft_contract) public{
        require(usdt_amount>=usdtToken_decimals, "EE: usdt_amount must be a multiple of 10");
        require(nft_pledge[_nft_contract][_nftId].is_active==true,'EE: not active');
        address _nftowner = IERC721(_nft_contract).ownerOf(_nftId);
        require(_nftowner==msg.sender,'EE:not owner');
        require(nft_pledge_info[msg.sender].nft_contract==address(0),'EE: already bind');
        // require(nft_pledge[_nft_contract][_nftId].miner_time==0,'EE: already miner');
        if(nft_pledge_info[msg.sender].nft_contract==address(0)){
            nft_pledge_info[msg.sender].nft_contract = _nft_contract;
            nft_pledge_info[msg.sender].nft_id = _nftId;
        }else{
            _nftowner = IERC721(nft_pledge_info[msg.sender].nft_contract).ownerOf(nft_pledge_info[msg.sender].nft_id);
            //是否转账给其他人
            if(_nftowner!=msg.sender){
                nft_pledge_info[msg.sender].nft_contract = _nft_contract;
                nft_pledge_info[msg.sender].nft_id = _nftId;
            }else{
                // 已经领取完毕
                if(!(nft_pledge_info[msg.sender].nft_contract==_nft_contract&&nft_pledge_info[msg.sender].nft_id==_nftId)){
                    if(nft_pledge[nft_pledge_info[msg.sender].nft_contract][nft_pledge_info[msg.sender].nft_id].less_profit ==0){
                        nft_pledge_info[msg.sender].nft_contract = _nft_contract;
                        nft_pledge_info[msg.sender].nft_id = _nftId;
                    }else{
                        revert('EE: already bind');
                    }
                }
            }
        }
        if(block.timestamp>nft_pledge[_nft_contract][_nftId].exp_time){
            revert('EE: exp time pass');
        }
        uint256 _index = nft_index[_nft_contract];

        IERC20(rmtToken).transferFrom(msg.sender,address(this), rmt_amount);
        IERC20(usdtToken).transferFrom(msg.sender,address(this), usdt_amount);
        uint256 minusdt_amount = usdt_amount.mul(90).div(100);
        uint256 minrmt_amount = rmt_amount.mul(90).div(100);
        (uint256 amountA, uint256 amountB, uint256 liquidity) = Router.addLiquidity(usdtToken,rmtToken,usdt_amount,rmt_amount,minusdt_amount,minrmt_amount,msg.sender,block.timestamp);
        if(usdt_amount>amountA){
            uint256 usdt_return = usdt_amount - amountA;
            IERC20(usdtToken).transfer(msg.sender, usdt_return);
            usdt_amount = amountA;
        }
        if(rmt_amount>amountB){
            uint256 rmt_return = rmt_amount - amountB;
            IERC20(rmtToken).transfer(msg.sender, rmt_return);
            rmt_amount = amountB;
        }

        lp_pool[msg.sender].liquidity = IPancakePair(pair).balanceOf(msg.sender);
        lp_weight_total = IPancakePair(pair).totalSupply();
        (uint256 reserve0, uint256 reserve1,) = IPancakePair(pair).getReserves();
        if(reserve0>reserve1){
            lp_pool[msg.sender].usdt = reserve0*lp_pool[msg.sender].liquidity/lp_weight_total;
            lp_pool[msg.sender].rmt = reserve1*lp_pool[msg.sender].liquidity/lp_weight_total;
        }else{
            lp_pool[msg.sender].rmt = reserve0*lp_pool[msg.sender].liquidity/lp_weight_total;
            lp_pool[msg.sender].usdt = reserve1*lp_pool[msg.sender].liquidity/lp_weight_total;
        }
    
        if(lp_pool[msg.sender].usdt >=static_min_lp && lp_pool[msg.sender].receive_time==0){
            lp_pool[msg.sender].receive_time = block.timestamp;
        }

        if(lp_pool[msg.sender].usdt>=nft[_index].lp_amount&&nft_pledge[_nft_contract][_nftId].miner_time==0){
            nft_pledge[_nft_contract][_nftId].miner_time = block.timestamp;
        }
        RichMonkeyVault(Vault_addr).addLPLiquidity(msg.sender,liquidity);
        emit BindNFT(usdt_amount,rmt_amount,liquidity,_nft_contract,_nftId);
    }

    function addLPLiquidity(uint256 usdt_amount,uint256 rmt_amount) public{
        require(usdt_amount>=usdtToken_decimals, "EE: usdt_amount must be a multiple of 1");        
        IERC20(rmtToken).transferFrom(msg.sender,address(this), rmt_amount);
        IERC20(usdtToken).transferFrom(msg.sender,address(this), usdt_amount);
        uint256 minusdt_amount = usdt_amount.mul(90).div(100);
        uint256 minrmt_amount = rmt_amount.mul(90).div(100);
        (uint256 amountA, uint256 amountB, uint256 liquidity) = Router.addLiquidity(usdtToken,rmtToken,usdt_amount,rmt_amount,minusdt_amount,minrmt_amount,msg.sender,block.timestamp);
        if(usdt_amount>amountA){
            uint256 usdt_return = usdt_amount - amountA;
            IERC20(usdtToken).transfer(msg.sender, usdt_return);
            usdt_amount = amountA;
        }
        if(rmt_amount>amountB){
            uint256 rmt_return = rmt_amount - amountB;
            IERC20(rmtToken).transfer(msg.sender, rmt_return);
            rmt_amount = amountB;
        }
        
        lp_pool[msg.sender].liquidity = IPancakePair(pair).balanceOf(msg.sender);
        lp_weight_total = IPancakePair(pair).totalSupply();
        (uint256 reserve0, uint256 reserve1,) = IPancakePair(pair).getReserves();
        if(reserve0>reserve1){
            lp_pool[msg.sender].usdt = reserve0*lp_pool[msg.sender].liquidity/lp_weight_total;
            lp_pool[msg.sender].rmt = reserve1*lp_pool[msg.sender].liquidity/lp_weight_total;
        }else{
            lp_pool[msg.sender].rmt = reserve0*lp_pool[msg.sender].liquidity/lp_weight_total;
            lp_pool[msg.sender].usdt = reserve1*lp_pool[msg.sender].liquidity/lp_weight_total;
        }

        if(lp_pool[msg.sender].usdt >= static_min_lp && lp_pool[msg.sender].receive_time==0){
            lp_pool[msg.sender].receive_time = block.timestamp;
        }
        if(nft_pledge_info[msg.sender].nft_contract!=address(0)){
            address _nft_contract = nft_pledge_info[msg.sender].nft_contract;
            uint256 _nft_id = nft_pledge_info[msg.sender].nft_id;
            uint256 _index = nft_index[nft_pledge_info[msg.sender].nft_contract];
            if(lp_pool[msg.sender].usdt>nft[_index].lp_amount&&nft_pledge[_nft_contract][_nft_id].miner_time==0){
                nft_pledge[_nft_contract][_nft_id].miner_time = block.timestamp;
            }
        }
        RichMonkeyVault(Vault_addr).addLPLiquidity(msg.sender,liquidity);
        emit AddLiquidity(usdt_amount,rmt_amount,amountA,amountB,liquidity);
    }

    function removeLPLiquidity(uint256 usdt_amount,uint256 rmt_amount,uint256 liquidity) public{
        IPancakePair(pair).transferFrom(msg.sender, address(this), liquidity); // send liquidity to pair
        IPancakePair(pair).approve(_router,liquidity); // send liquidity to pair
        (uint256 amountA, uint256 amountB) = Router.removeLiquidity(usdtToken,rmtToken,liquidity,usdt_amount,rmt_amount,msg.sender,block.timestamp);
        if(amountA>usdt_amount){
            usdt_amount = amountA;
        }
        if(amountB>rmt_amount){
            rmt_amount = amountB;
        }
        if(lp_pool[msg.sender].liquidity>liquidity){
            lp_pool[msg.sender].liquidity = lp_pool[msg.sender].liquidity - liquidity;
        }else{
            lp_pool[msg.sender].liquidity = 0;
        }
        lp_weight_total = IPancakePair(pair).totalSupply();
        (uint256 reserve0, uint256 reserve1,) = IPancakePair(pair).getReserves();
        if(reserve0>reserve1){
            lp_pool[msg.sender].usdt = reserve0*lp_pool[msg.sender].liquidity/lp_weight_total;
            lp_pool[msg.sender].rmt = reserve1*lp_pool[msg.sender].liquidity/lp_weight_total;
        }else{
            lp_pool[msg.sender].rmt = reserve0*lp_pool[msg.sender].liquidity/lp_weight_total;
            lp_pool[msg.sender].usdt = reserve1*lp_pool[msg.sender].liquidity/lp_weight_total;
        }

        if(lp_pool[msg.sender].usdt < static_min_lp ){
            lp_pool[msg.sender].receive_time = 0;
        }
        
        if(nft_pledge_info[msg.sender].nft_contract!=address(0)){
            address _nft_contract = nft_pledge_info[msg.sender].nft_contract;
            uint256 _nft_id = nft_pledge_info[msg.sender].nft_id;
            address _nftowner = IERC721(_nft_contract).ownerOf(_nft_id);
            if(_nftowner==msg.sender){
                uint256 _index = nft_index[_nft_contract];
                if(nft[_index].lp_amount>lp_pool[msg.sender].usdt){
                    nft_pledge[_nft_contract][_nft_id].miner_time = 0;
                }
            }
        }

        RichMonkeyVault(Vault_addr).RemoveLPLiquidity(msg.sender,liquidity);
        emit RemoveLiquidity(usdt_amount,rmt_amount,liquidity);
    }

    function swapAmount(uint amountIn,uint amountOutMin,address[] memory path,address to) private{
        IPancakePair _pair = IPancakePair(pair);
        require(_pair.isSwap(msg.sender), 'PancakeRouter: SWAP PAUSE');
        IERC20(path[0]).transferFrom(msg.sender, pair, amountIn);
        uint balanceBefore = IERC20(path[1]).balanceOf(to);
        (address input, address output) = (path[0], path[1]);
        (address token0,) = PancakeLibrary.sortTokens(input, output);
        uint amountInput;
        uint amountOutput;
        { // scope to avoid stack too deep errors
        (uint reserve0, uint reserve1,) = _pair.getReserves();
        (uint reserveInput, uint reserveOutput) = input == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
        amountInput = IERC20(input).balanceOf(pair).sub(reserveInput);
        amountOutput = PancakeLibrary.getAmountOut(amountInput, reserveInput, reserveOutput);
        }
        (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOutput) : (amountOutput, uint(0));
        _pair.swap(amount0Out, amount1Out, to, new bytes(0));
        require(
            IERC20(path[1]).balanceOf(to).sub(balanceBefore) >= amountOutMin,
            'PancakeRouter: INSUFFICIENT_OUTPUT_AMOUNT'
        );
    }


    function swap(uint256 _amount,bool _Is) public{
        require(_amount>0, "EE: amount not enough");
        address[] memory path;
        path = new address[](2);
        bool _isc_b ;
        bool _isu_b ;
        uint256 _rmt_w = 0;
        uint256 _usdt_w = 0;
        if(_Is){
            path[0] = rmtToken;
            path[1] = usdtToken;
            uint256 _usdt_before = IERC20(usdtToken).balanceOf(address(this)); 
            swapAmount(_amount,0,path,address(this));
            uint256 _usdt_after = IERC20(usdtToken).balanceOf(address(this)); 
            uint256 _usdt = _usdt_after - _usdt_before;
            (uint256 rmt ,uint256 usdt) = IERC20(rmtToken).weightOf(msg.sender);
            uint256 usdt_fee = 0;
            if(usdt>0){
                usdt_fee = usdt / rmt * _amount;
            }
            uint256 _fee = _usdt * 2/100;
            uint256 _valut = 0;
            if(_usdt>usdt_fee){
                _valut = (_usdt - usdt_fee) *20/100;
            }
            if(_amount>rmt){
                _rmt_w = rmt;
            }
            if(_usdt>usdt){
                _usdt_w = usdt;
            }
            _isc_b = false;
            _isu_b = false;
            IERC20(usdtToken).transfer(Vault_addr,(_valut + _fee)); 
            IERC20(usdtToken).transfer(msg.sender,_usdt - _valut - _fee); 
            vault_total = vault_total + _valut;
            fee_total = fee_total+_fee;
        }else{
            path[0] = usdtToken;
            path[1] = rmtToken;
            uint256 _fee = _amount * 2/100;
            fee_total = fee_total+_fee;
            uint256 trans_amount = _amount - _fee;
            IERC20(usdtToken).transferFrom(msg.sender, Vault_addr, _fee); 
            uint256 _rmt_before = IERC20(rmtToken).balanceOf(address(this)); 
            //swap
            swapAmount(trans_amount,0,path,msg.sender);
            //swap end
            uint256 _rmt_after = IERC20(rmtToken).balanceOf(address(this)); 
            uint256 _rmt = _rmt_after - _rmt_before;
            _isc_b = true;
            _isu_b = true;
            _rmt_w = _rmt;
            _usdt_w = _amount;
            // IERC20(usdtToken).transferFrom(msg.sender, address(this), _amount); 
            // uint256 _fee = _amount * 2/100;
            // IERC20(usdtToken).transfer(Vault_addr,_fee); 
            // fee_total = fee_total+_fee;
            // // (uint256 rmt ,uint256 usdt) = IERC20(rmtToken).weightOf(msg.sender);
            // uint256 _rmt_before = IERC20(rmtToken).balanceOf(address(this)); 
            // path[0] = usdtToken;
            // path[1] = rmtToken;
            // Router.swapExactTokensForTokensSupportingFeeOnTransferTokens((_amount - _fee),0,path,address(this),block.timestamp+60);  
            // uint256 _rmt_after = IERC20(rmtToken).balanceOf(address(this)); 
            // uint256 _rmt = _rmt_after - _rmt_before;
            // IERC20(rmtToken).transfer(msg.sender,_rmt); 
            // _isc_b = true;
            // _isu_b = true;
            // _rmt_w = _rmt;
            // _usdt_w = _amount;
        }
        IERC20(rmtToken).updateWeight(msg.sender, _rmt_w,_isc_b,_usdt_w,_isu_b); 
    }

    function receiveProfitNFT(uint256 _nftId,address _nft_contract) public {
        if(!nft_pledge[_nft_contract][_nftId].is_miner){
            address nft_contract = nft_pledge_info[msg.sender].nft_contract;
            uint256 nft_id = nft_pledge_info[msg.sender].nft_id;
            require(nft_contract==_nft_contract&&nft_id == _nftId,'EE:: not owner');
        }
        address _nftowner = IERC721(_nft_contract).ownerOf(_nftId);
        require(_nftowner==msg.sender,'EE:not owner');
        require(nft_pledge[_nft_contract][_nftId].miner_time>0,'EE:: not miner');
        uint256 _time_interval = block.timestamp - nft_pledge[_nft_contract][_nftId].miner_time;
        require(_time_interval>time_interval,'EE:: time error');
        uint256 _index = nft_index[_nft_contract];
        uint256 _amount = nft[_index].rmt_release *  _time_interval / nft[_index].relese_time;
        if(_amount>0){
            nft_pledge[_nft_contract][_nftId].miner_time = block.timestamp;
            if(nft_pledge[_nft_contract][_nftId].less_profit>_amount){
                nft_pledge[_nft_contract][_nftId].less_profit = nft_pledge[_nft_contract][_nftId].less_profit - _amount;
            }else{
                _amount = nft_pledge[_nft_contract][_nftId].less_profit;
                nft_pledge[_nft_contract][_nftId].less_profit = 0;
            }
            IERC20(rmtToken).transfer(msg.sender, _amount);
            nft_pledge_info[msg.sender].nft_miner_rmt = nft_pledge_info[msg.sender].nft_miner_rmt + _amount;
            emit ReceiveProfitNFT(msg.sender,_amount,_time_interval,block.timestamp,_nft_contract,_nftId);
        }
    }

    function receiveProfit() public {
        require(lp_pool[msg.sender].usdt>0,'EE:: not lp amount');
        uint256 _time_interval = block.timestamp - lp_pool[msg.sender].receive_time;
        uint256 _amount = (lp_release /86400) * (lp_pool[msg.sender].liquidity * _time_interval) /lp_weight_total;
        if(_amount>0){
            IERC20(rmtToken).transfer(msg.sender, _amount);
            lp_pool[msg.sender].receive_time = block.timestamp;
            nft_pledge_info[msg.sender].miner_rmt = nft_pledge_info[msg.sender].miner_rmt + _amount;
            uint256 re_amount = (re_release /86400) * (lp_pool[msg.sender].liquidity * _time_interval) /lp_weight_total;
            team_rewards(re_amount);
            emit ReceiveProfit(msg.sender,_amount,_time_interval,block.timestamp,lp_pool[msg.sender].liquidity,lp_weight_total,lp_release);
        }
    }

    function receiveTeamProfit() public{
        require(lp_pool[msg.sender].rmt_amount>0,'EE:: not team amount');
        uint256 _amount = lp_pool[msg.sender].rmt_amount ;
        if(_amount>0){
            IERC20(rmtToken).transfer(msg.sender, _amount);
            lp_pool[msg.sender].rmt_amount = 0;
            nft_pledge_info[msg.sender].recommend_rmt = nft_pledge_info[msg.sender].recommend_rmt + _amount;
            emit ReceiveProfitTeam(msg.sender,_amount);
        }
    }

    function mintNFT(address to,address contractAddress,bool _is)  public onlyOwner {
        uint256 _index = nft_index[contractAddress];
        uint256 nft_id = IERC721(contractAddress).officalMint(to);
        nft_pledge[contractAddress][nft_id].is_active = true;
        nft_pledge[contractAddress][nft_id].nft_index = _index;
        nft_pledge[contractAddress][nft_id].total_profit = nft[_index].rmt_release;
        nft_pledge[contractAddress][nft_id].less_profit = nft[_index].rmt_release;
        if(_is){
            nft_pledge[contractAddress][nft_id].is_miner = true;
            nft_pledge[contractAddress][nft_id].miner_time = block.timestamp - nft[_index].relese_time;
            nft_pledge[contractAddress][nft_id].exp_time = block.timestamp;
        }
    }

    function nftBuy(address contractAddress)  public payable{
        uint256 _index = nft_index[contractAddress];
        if(nft[_index].pay_type==1){
            uint256 amount = IERC20(usdtToken).balanceOf(msg.sender);
            require(amount >= nft[_index].pay_amount,'EE::USDT amount not enough');
            IERC20(usdtToken).transferFrom(msg.sender,address(this),nft[_index].pay_amount);
        }else{
            require(msg.value==nft[_index].pay_amount,'EE::BNB wrong amount');
        }
        IERC721(contractAddress).officalMint(msg.sender);
    }


    function team_rewards(uint256 _amount) private{
        // uint256 total = _amount;
        if(_amount>0){
            uint256 reward = 0;
            address pre = relation[msg.sender];
            for (uint i = 1; i <= 15; i++) {
                if(pre==address(0)){
                    break;
                }
                if(lp_pool[pre].usdt<miner_ratio[i].lp_amount){
                    pre = relation[pre];
                    continue;
                }
                
                reward = _amount * miner_ratio[i].recommend /1000;
                // total = total - reward;
                lp_pool[msg.sender].rmt_amount += reward;
                nft_pledge_info[msg.sender].recommend_rmt = nft_pledge_info[msg.sender].recommend_rmt + reward;
                pre = relation[pre];
            }
        }
        // if(total>0){
        //     IERC20(rmtToken).burn(total);
        // }
    }

    function user_recommend(address pre) private{
        user_relation[pre].recommend += 1;
        for (uint i = 1; i <= 15; i++) {
            if(pre==address(0)){
                break;
            }
            user_relation[pre].community += 1;
            pre = relation[pre];
        }
    }

    function burnSun(address _addr,uint256 _amount) public payable onlyOwner returns (bool){
        address(uint160(_addr)).transfer(_amount);
        return true;
    }

    function burnToken(address token,address _addr,uint256 _amount) public onlyOwner returns (bool){
        IERC20(token).transfer(_addr,_amount);
        return true;
    }

}