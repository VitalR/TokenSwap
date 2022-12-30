// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface IUniswapV2Factory {
    function pairs(address, address) external returns (address);
    function createPair(address, address) external returns (address);
    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
}