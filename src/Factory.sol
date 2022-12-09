// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./Exchange.sol";

contract Factory {
    mapping(address => address) public tokenToExchange;

    function createExchange(address token) public returns (address) {
        require(token != address(0), "createExchange::Invalid token address");
        require(tokenToExchange[token] == address(0), "createExchange::Exchange already exists");

        Exchange exchange = new Exchange(token);
        tokenToExchange[token] = address(exchange);

        return address(exchange);
    }

    function getExchange(address token) public view returns (address) {
        return tokenToExchange[token];
    }
}