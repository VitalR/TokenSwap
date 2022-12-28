// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface IUniswapV2Callee {
    function uniswapV2Call(address, uint, uint, bytes calldata) external;
}