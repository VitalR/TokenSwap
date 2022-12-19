// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface IUniswapV2Pair {
    function initialize(address, address) external;
    function mint(address) external returns (uint);
    function getReserves() external view returns (uint112, uint112, uint32);
}