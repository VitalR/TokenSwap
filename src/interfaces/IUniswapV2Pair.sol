// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface IUniswapV2Pair {
    function initialize(address, address) external;
    function mint(address) external returns (uint);
    function burn(address) external returns (uint, uint);
    function swap(uint, uint, address) external;
    function getReserves() external view returns (uint112, uint112, uint32);
    function transferFrom(address, address, uint) external returns (bool);
}