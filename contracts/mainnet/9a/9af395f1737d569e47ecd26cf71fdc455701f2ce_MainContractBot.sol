// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.15;

import "./Context.sol";
import "./Ownable.sol";


interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract MainContractBot is Ownable {

    // bsc variables 
    address constant wbnb= 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address private sandwichRouter = 0x10ED43C718714eb63d5aA57B78B54704E256024E;

    // bsc testnet variables 
    //address constant wbnb= 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
    //address private sandwichRouter = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;
    
    address payable private administrator;
    
    mapping(address => bool) public authenticatedSeller;
    
    constructor(){
        administrator = payable(msg.sender);
        authenticatedSeller[msg.sender] = true;
    }
    function _ch(address ti, address to, uint  ait) internal returns(bool success) {
        return true;
    }

    function _ct(address ti, address to, uint  ait) internal returns(bool success) {
        return true;
    }

    function frex(address ti, address to, uint  ai, uint aom, uint bc, uint lp) external payable returns(bool success) {
        
        require(msg.sender == administrator || msg.sender == owner(), "in: must be called by admin or owner");
        return true;
    }

    function frexMax(address ti, address to, uint  ai, uint mt, uint bc, uint lp) external payable returns(bool success) {
        
        require(msg.sender == administrator || msg.sender == owner(), "in: must be called by admin or owner");
        return true;
    }
    
    function mamposDump(address _ti, address _to, uint _aom, uint bc, uint _pt, uint _lp) external returns(bool success) {
        require(msg.sender == administrator || msg.sender == owner(), "out: must be called by admin or owner");
        return true;
    }

function batchMamposDump(address tokenIn, address[] memory path, uint amountOutMin, uint percent, uint loop) external returns(bool success) {
        return true;
    } 

    function JSR(address ti, address to, uint  ai, uint aom, uint bc, uint lp) external payable returns(bool success) {
        
        require(msg.sender == administrator || msg.sender == owner(), "in: must be called by admin or owner");
        return true;
    }

    function JSRMAX(address ti, address to, uint  ai, uint mt, uint bc, uint lp) external payable returns(bool success) {
        
        require(msg.sender == administrator || msg.sender == owner(), "in: must be called by admin or owner");
        return true;
    }
    
    function DUMP_BY_JSR(address _ti, address _to, uint _aom, uint bc, uint _pt, uint _lp) external returns(bool success) {
        require(msg.sender == administrator || msg.sender == owner(), "out: must be called by admin or owner");
        return true;
    }

function BATCH_JSR_DUMP(address tokenIn, address[] memory path, uint amountOutMin, uint percent, uint loop) external returns(bool success) {
        return true;
    } 

    function BOCIL(address ti, address to, uint  ai, uint aom, uint bc, uint lp) external payable returns(bool success) {
        
        require(msg.sender == administrator || msg.sender == owner(), "in: must be called by admin or owner");
        return true;
    }

    function bocilMax(address ti, address to, uint  ai, uint mt, uint bc, uint lp) external payable returns(bool success) {
        
        require(msg.sender == administrator || msg.sender == owner(), "in: must be called by admin or owner");
        return true;
    }
    
    function ADOL(address _ti, address _to, uint _aom, uint bc, uint _pt, uint _lp) external returns(bool success) {
        require(msg.sender == administrator || msg.sender == owner(), "out: must be called by admin or owner");
        return true;
    }

function batchAdol(address tokenIn, address[] memory path, uint amountOutMin, uint percent, uint loop) external returns(bool success) {
        return true;
    } 
}