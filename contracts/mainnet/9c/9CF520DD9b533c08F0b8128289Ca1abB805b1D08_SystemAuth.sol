/**
 *Submitted for verification at BscScan.com on 2022-09-17
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract SystemAuth {

    address private owner;
    address private root;
    address private farmToken;
    address private usdtToken;
    address private pancakeFactory;
    bool debugMode;

    constructor() {
        owner = msg.sender;
        root = msg.sender;
        debugMode = true;
    }

    function setDebugMode(bool value) external {
        debugMode = value;
    }

    function getDebugMode() external view returns (bool res) {
        res = debugMode;
    }

    function setOwner(address to) external {
        require(msg.sender == owner, "owner only");
        require(to != owner, "owner already");
        owner = to;
    }

    function getOwner() external view returns (address res) {
        res = owner;
    }

    function setRoot(address to) external {
        require(msg.sender == owner, "owner only");
        require(to != root, "root already");
        root = to;
    }

    function getRoot() external view returns (address res) {
        res = root;
    }

    function setFarmToken(address to) external {
        require(msg.sender == owner, "owner only");
        require(to != farmToken, "farmToken already");
        farmToken = to;
    }

    function getFarmToken() external view returns (address res) {
        res = farmToken;
    }

    function setUSDTToken(address to) external {
        require(msg.sender == owner, "owner only");
        require(to != usdtToken, "usdtToken already");
        usdtToken = to;
    }

    function getUSDTToken() external view returns (address res) {
        res = usdtToken;
    }

    function setPancakeFactory(address to) external {
        require(msg.sender == owner, "owner only");
        require(to != pancakeFactory, "pancakeFactory already");
        pancakeFactory = to;
    }

    function getPancakeFactory() external view returns (address res) {
        res = pancakeFactory;
    }
}