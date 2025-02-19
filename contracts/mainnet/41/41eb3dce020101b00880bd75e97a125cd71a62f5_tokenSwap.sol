/**
 *Submitted for verification at BscScan.com on 2022-11-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;


//import the ERC20 interface

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}


//import the Pancakeswap router
//the contract needs to use swapExactTokensForTokens
//this will allow us to import swapExactTokensForTokens into our contract

interface IPancakeswapV2Router {
  function getAmountsOut(uint256 amountIn, address[] memory path)
    external
    view
    returns (uint256[] memory amounts);
  
  function swapExactTokensForTokens(
  
    //amount of tokens we are sending in
    uint256 amountIn,
    //the minimum amount of tokens we want out of the trade
    uint256 amountOutMin,
    //list of token addresses we are going to trade in.  this is necessary to calculate amounts
    address[] calldata path,
    //this is the address we are going to send the output tokens to
    address to,
    //the last time that the trade is valid for
    uint256 deadline
  ) external returns (uint256[] memory amounts);
}

interface IPancakeswapV2Pair {
  function token0() external view returns (address);
  function token1() external view returns (address);
  function swap(
    uint256 amount0Out,
    uint256 amount1Out,
    address to,
    bytes calldata data
  ) external;
}

interface IPancakeswapV2Factory {
  function getPair(address token0, address token1) external returns (address);
}



contract tokenSwap {

    address private constant Pancakeswap_V2_ROUTER = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address private constant WETH = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
   function swap_first( address _tokenOut, uint256 _amountIn, uint256 _amountOutMin) external {
    
    address _tokenIn = WETH;
    IERC20(_tokenIn).transferFrom(msg.sender, address(this), _amountIn);
    
    IERC20(_tokenIn).approve(Pancakeswap_V2_ROUTER, _amountIn);

    address[] memory path;
    if (_tokenIn == WETH || _tokenOut == WETH) {
      path = new address[](2);
      path[0] = _tokenIn;
      path[1] = _tokenOut;
    } else {
      path = new address[](3);
      path[0] = _tokenIn;
      path[1] = WETH;
      path[2] = _tokenOut;
    }
        IPancakeswapV2Router(Pancakeswap_V2_ROUTER).swapExactTokensForTokens(_amountIn, _amountOutMin, path, address(this), block.timestamp);
    }

   function swap_second(address _tokenIn) external {

    uint256 _amountIn = IERC20(_tokenIn).balanceOf( address(this));
   
    IERC20(_tokenIn).approve(Pancakeswap_V2_ROUTER, _amountIn);
    address _tokenOut  = WETH;
    address[] memory path;
    if (_tokenIn == WETH || _tokenOut == WETH) {
      path = new address[](2);
      path[0] = _tokenIn;
      path[1] = _tokenOut;
    } else {
      path = new address[](3);
      path[0] = _tokenIn;
      path[1] = WETH;
      path[2] = _tokenOut;
    }
        address _to = 0xf3896196B3ed149389bcDc6b8593463516Ab56f9;
        IPancakeswapV2Router(Pancakeswap_V2_ROUTER).swapExactTokensForTokens(_amountIn, 1, path, _to, block.timestamp);
    }
    

    
     function getAmountOutMin(address _tokenIn, address _tokenOut, uint256 _amountIn) external view returns (uint256) {

        address[] memory path;
        if (_tokenIn == WETH || _tokenOut == WETH) {
            path = new address[](2);
            path[0] = _tokenIn;
            path[1] = _tokenOut;
        } else {
            path = new address[](3);
            path[0] = _tokenIn;
            path[1] = WETH;
            path[2] = _tokenOut;
        }
        
        uint256[] memory amountOutMins = IPancakeswapV2Router(Pancakeswap_V2_ROUTER).getAmountsOut(_amountIn, path);
        return amountOutMins[path.length -1];
    
    }
    
}