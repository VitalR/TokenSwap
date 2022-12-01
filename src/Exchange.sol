// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "openzeppelin-contracts/token/ERC20/IERC20.sol";

contract Exchange {
    address public token;

    constructor(address _token) {
        require(_token != address(0), "Invalid token address");

        token = _token;
    }

    function addLiquidity(uint _amount) public payable {
        IERC20(token).transferFrom(msg.sender, address(this), _amount);
    }

    function getReserve() public view returns (uint) {
        return IERC20(token).balanceOf(address(this));
    }

    function getPrice(uint inputReserve, uint outputReserve) public view returns (uint) {
        require(inputReserve > 0 && outputReserve > 0, "Invalid reserves");

        return (inputReserve * 1000) / outputReserve;
    }
}