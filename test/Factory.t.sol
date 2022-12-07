// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import "../src/Factory.sol";
import "../src/Exchange.sol";
import "./mocks/MintableERC20.sol";

contract FactoryTest is Test {
    address exchange;
    Factory factory;
    MintableERC20 token;

    function setUp() public {
        factory = new Factory();
        token = new MintableERC20("Token Name", "TSB");
    }

    function testCreateExchange() public {
        exchange = factory.createExchange(address(token));

        assertEq(factory.getExchange(address(token)), address(exchange));
    }

    function testCreateExchangeWithZeroAddressFails() public {
        vm.expectRevert("Invalid token address");
        exchange = factory.createExchange(address(0));
    }

    function testCreateExchangeWithExistingExchangeFails() public {
        exchange = factory.createExchange(address(token));
        assertEq(factory.getExchange(address(token)), address(exchange));

        vm.expectRevert("Exchange already exists");
        exchange = factory.createExchange(address(token));
    }
}