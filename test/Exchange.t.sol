// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "solmate/test/utils/DSTestPlus.sol";
import "forge-std/Test.sol";
import "../src/TokenERC20.sol";
import "../src/Exchange.sol";

import "./mocks/MintableERC20.sol";

import {DSTest} from "ds-test/test.sol";

import {Hevm} from "solmate/test/utils/Hevm.sol";

import "forge-std/StdCheats.sol";
import "forge-std/Test.sol";


// import "lib/forge-std/src/Components.sol";
// import {console, console2, StdAssertions, StdCheats, stdError, stdJson, stdMath, StdStorage, stdStorage, StdUtils, Vm} from "lib/forge-std/src/Components.sol";

contract ExchangeTest is Test/*, DSTestPlus*/ {
    TokenERC20 public token;
    Exchange public exchange;
    address owner;
    address user = address(1);

    function setUp() public {
        owner = address(this);
        token = new TokenERC20("Token Name", "TSB", 18, 1000*18);
        exchange = new Exchange(address(token));
    }

    function testAddLiquidity() public {
        uint liqAmmount = 2 ether;
        startHoax(owner);
        // hevm.startPrank(owner);
        token.approve(address(exchange), liqAmmount);
        exchange.addLiquidity{ value: 1 ether }(liqAmmount);

        assertEq(address(exchange).balance, 1 ether);
        assertEq(token.balanceOf(address(exchange)), 2 ether);
    }
}
