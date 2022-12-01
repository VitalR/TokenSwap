// SPDX-License-Identifier: UNLICENSED
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
}