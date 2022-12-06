// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import "../src/Exchange.sol";
import "./mocks/MintableERC20.sol";

contract ExchangeTest is Test {
    MintableERC20 public token;
    Exchange public exchange;
    address owner;
    address user = address(12);

    function setUp() public {
        owner = address(11);
        token = new MintableERC20("Token Name", "TSB");
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
        // assertEq(exchange.balanceOf(address(owner)), 0.5 ether);
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
        assertEq(tokenOutAmount, 994);

        // tokenOutAmount = exchange.getTokenAmount(100 wei);
        // console.log(tokenOutAmount);
        // assertEq(tokenOutAmount, 181);

        // tokenOutAmount = exchange.getTokenAmount(1000 wei);
        // console.log(tokenOutAmount);
        // assertEq(tokenOutAmount, 1000);
    }

    function testGetEtherAmount() public {
        uint liqAmmount = 2000 wei;
        startHoax(owner);
        token.mint(address(owner), liqAmmount);
        token.approve(address(exchange), liqAmmount);
        exchange.addLiquidity{ value: 1000 wei }(liqAmmount);

        uint etherOutAmount = exchange.getEtherAmount(10 wei);
        console.log(etherOutAmount);
        assertEq(etherOutAmount, 497);

        // etherOutAmount = exchange.getEtherAmount(100 wei);
        // console.log(etherOutAmount);
        // assertEq(etherOutAmount, 47);

        // etherOutAmount = exchange.getEtherAmount(1000 wei);
        // console.log(etherOutAmount);
        // assertEq(etherOutAmount, 333);

        // etherOutAmount = exchange.getEtherAmount(2000 wei);
        // console.log(etherOutAmount);
        // assertEq(etherOutAmount, 500);
    }

    function testRemoveAllLiquidity() public {
        uint liqAmmount = 2000 wei;
        // startHoax(owner);
        vm.deal(address(owner), 1 ether);
        vm.startPrank(address(owner));

        console.log("owner eth balance ", address(owner).balance);
        token.mint(address(owner), liqAmmount);
        assertEq(token.balanceOf(address(owner)), liqAmmount);
        token.approve(address(exchange), liqAmmount);

        exchange.addLiquidity{ value: 1000 wei }(liqAmmount);

        assertEq(exchange.balanceOf(address(owner)), 1000 wei);
        assertEq(token.balanceOf(address(owner)), 0);

        console.log("owner eth balance ", address(owner).balance);

        exchange.removeLiquidity(1000 wei);
    }

   function testRemoveSomeLiquidity() public {
        uint liqAmmount = 2000 wei;
        // startHoax(owner);
        vm.deal(address(owner), 1 ether);
        vm.startPrank(address(owner));

        console.log("owner eth balance ", address(owner).balance);
        token.mint(address(owner), liqAmmount);
        assertEq(token.balanceOf(address(owner)), liqAmmount);
        token.approve(address(exchange), liqAmmount);

        exchange.addLiquidity{ value: 1000 wei }(liqAmmount);

        assertEq(exchange.balanceOf(address(owner)), 1000 wei);
        assertEq(token.balanceOf(address(owner)), 0);
        // assertEq(address(owner).balance, 1 ether - 1000 wei);
        // vm.stopPrank();

        console.log("owner eth balance ", address(owner).balance);

        uint balanceBefore = address(owner).balance;
        exchange.removeLiquidity(500 wei);

        assertEq(exchange.balanceOf(address(owner)), 500 wei);
        assertEq(token.balanceOf(address(owner)), 1000 wei);
        assertEq(address(owner).balance, balanceBefore + 500 wei);
    }
}
