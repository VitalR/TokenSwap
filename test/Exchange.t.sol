// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import "../src/Exchange.sol";
import "./mocks/MintableERC20.sol";

contract ExchangeTest is Test {
    MintableERC20 public token;
    Exchange public exchange;
    address owner;
    address user = address(1);

    function setUp() public {
        owner = address(this);
        token = new MintableERC20("Token Name", "TSB", 18);
        exchange = new Exchange(address(token));
    }

    function testAddLiquidity() public {
        uint liqAmmount = 1 ether;
        startHoax(owner);
        token.mint(address(owner), liqAmmount);
        token.approve(address(exchange), liqAmmount);
        exchange.addLiquidity{ value: 0.5 ether }(liqAmmount);

        assertEq(address(exchange).balance, 0.5 ether);
        assertEq(token.balanceOf(address(exchange)), 1 ether);
    }

    function testGetPrice() public {
        uint liqAmmount = 2000 wei;
        startHoax(owner);
        token.mint(address(owner), liqAmmount);
        token.approve(address(exchange), liqAmmount);
        exchange.addLiquidity{ value: 1000 wei }(liqAmmount);

        uint tokenReserve = exchange.getReserve();
        console.log(tokenReserve);
        uint etherReserve = address(exchange).balance;
        console.log(etherReserve);

        uint tokenPrice = exchange.getPrice(tokenReserve, etherReserve);
        console.log(tokenPrice);
        uint ethPrice = exchange.getPrice(etherReserve, tokenReserve);
        console.log(ethPrice);

        // token per ether
        assertEq(tokenPrice, 2000);
        // // ether per token
        assertEq(ethPrice, 500);
    }

    // slippage affects prices
    function testGetTokenAmount() public {
        uint liqAmmount = 2000 wei;
        startHoax(owner);
        token.mint(address(owner), liqAmmount);
        token.approve(address(exchange), liqAmmount);
        exchange.addLiquidity{ value: 1000 wei }(liqAmmount);

        uint tokenOutAmount = exchange.getTokenAmount(10 wei);
        console.log(tokenOutAmount);
        assertEq(tokenOutAmount, 19);

        tokenOutAmount = exchange.getTokenAmount(100 wei);
        console.log(tokenOutAmount);
        assertEq(tokenOutAmount, 181);

        tokenOutAmount = exchange.getTokenAmount(1000 wei);
        console.log(tokenOutAmount);
        assertEq(tokenOutAmount, 1000);
    }

    function testGetEtherAmount() public {
        uint liqAmmount = 2000 wei;
        startHoax(owner);
        token.mint(address(owner), liqAmmount);
        token.approve(address(exchange), liqAmmount);
        exchange.addLiquidity{ value: 1000 wei }(liqAmmount);

        uint etherOutAmount = exchange.getEtherAmount(10 wei);
        console.log(etherOutAmount);
        assertEq(etherOutAmount, 4);

        etherOutAmount = exchange.getEtherAmount(100 wei);
        console.log(etherOutAmount);
        assertEq(etherOutAmount, 47);

        etherOutAmount = exchange.getEtherAmount(1000 wei);
        console.log(etherOutAmount);
        assertEq(etherOutAmount, 333);

        etherOutAmount = exchange.getEtherAmount(2000 wei);
        console.log(etherOutAmount);
        assertEq(etherOutAmount, 500);
    }
}
