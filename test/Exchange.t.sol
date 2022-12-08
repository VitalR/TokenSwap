// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import "./mocks/MintableERC20.sol";
import "../src/Factory.sol";

contract ExchangeTest is Test {
    MintableERC20 token;
    Exchange exchange;
    Factory factory;
    address owner = address(11);
    address user = address(12);

    function setUp() public {
        token = new MintableERC20("Token Name", "TSB");
        exchange = new Exchange(address(token));
    }

    function testInitialState() public {
        assertEq(exchange.name(), "Swap-V1");
        assertEq(exchange.symbol(), "SWP-V1");
        assertEq(exchange.totalSupply(), 0 wei);
        assertEq(exchange.factory(), address(this));
    }

    function testAddLiquidity() public {
        uint liqAmmount = 1 ether;
        startHoax(owner);
        token.mint(address(owner), liqAmmount);
        token.approve(address(exchange), liqAmmount);
        exchange.addLiquidity{ value: 0.5 ether }(liqAmmount);

        assertEq(address(exchange).balance, 0.5 ether);
        assertEq(token.balanceOf(address(exchange)), 1 ether);
        assertEq(exchange.balanceOf(address(owner)), 0.5 ether);
    }

    function testGetPrice() public {
        uint liqAmmount = 2000 wei;
        startHoax(owner);
        token.mint(address(owner), liqAmmount);
        token.approve(address(exchange), liqAmmount);
        exchange.addLiquidity{ value: 1000 wei }(liqAmmount);

        uint tokenReserve = exchange.getReserve();
        uint etherReserve = address(exchange).balance;

        uint tokenPrice = exchange.getPrice(tokenReserve, etherReserve);
        uint ethPrice = exchange.getPrice(etherReserve, tokenReserve);

        // token per ether
        assertEq(tokenPrice, 2000);
        // ether per token
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
        // console.log(tokenOutAmount);
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
        // console.log(etherOutAmount);
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
        vm.deal(address(owner), 1 ether);
        vm.startPrank(address(owner));

        token.mint(address(owner), liqAmmount);
        assertEq(token.balanceOf(address(owner)), liqAmmount);
        token.approve(address(exchange), liqAmmount);

        exchange.addLiquidity{ value: 1000 wei }(liqAmmount);

        assertEq(exchange.balanceOf(address(owner)), 1000 wei);
        assertEq(token.balanceOf(address(owner)), 0);
    
        uint balanceBefore = address(owner).balance;
        exchange.removeLiquidity(1000 wei);

        assertEq(exchange.balanceOf(address(owner)), 0);
        assertEq(token.balanceOf(address(owner)), 2000 wei);
        assertEq(address(owner).balance, balanceBefore + 1000 wei);
    }

   function testRemoveSomeLiquidity() public {
        uint liqAmmount = 2000 wei;
        vm.deal(address(owner), 1 ether);
        vm.startPrank(address(owner));

        token.mint(address(owner), liqAmmount);
        assertEq(token.balanceOf(address(owner)), liqAmmount);
        token.approve(address(exchange), liqAmmount);

        exchange.addLiquidity{ value: 1000 wei }(liqAmmount);

        assertEq(exchange.balanceOf(address(owner)), 1000 wei);
        assertEq(token.balanceOf(address(owner)), 0);

        uint balanceBefore = address(owner).balance;
        exchange.removeLiquidity(500 wei);

        assertEq(exchange.balanceOf(address(owner)), 500 wei);
        assertEq(token.balanceOf(address(owner)), 1000 wei);
        assertEq(address(owner).balance, balanceBefore + 500 wei);
    }

    function testTokenToEtherSwap() public {
        uint liqAmmount = 2000 wei;
        startHoax(owner);
        token.mint(address(owner), liqAmmount);
        token.approve(address(exchange), liqAmmount);
        exchange.addLiquidity{ value: 1000 wei }(liqAmmount);
        vm.stopPrank();

        uint tokenBalanceBefore = token.balanceOf(address(exchange));
        uint etherBalanceBefore = address(exchange).balance;

        vm.startPrank(user);
        token.mint(address(user), 1000 wei);
        token.approve(address(exchange), 1000 wei);
        exchange.tokenToEthSwap(1000 wei, 497 wei);

        assertEq(token.balanceOf(address(user)), 0);
        assertEq(address(user).balance, 497 wei);

        assertEq(tokenBalanceBefore + 1000 wei, token.balanceOf(address(exchange)));
        assertEq(etherBalanceBefore - 497 wei, address(exchange).balance);
    }

    function testAffectsExchangeRate() public {
        uint liqAmmount = 2000 wei;
        startHoax(owner);
        token.mint(address(owner), 4000 wei);
        token.approve(address(exchange), liqAmmount);
        exchange.addLiquidity{ value: 1000 wei }(liqAmmount);

        uint ethOut = exchange.getEtherAmount(liqAmmount);
        // console.log("ethOut ", ethOut);

        assertEq(ethOut, 497 wei);

        token.approve(address(exchange), 1000 wei);
        exchange.tokenToEthSwap(1000 wei, 497 wei);

        ethOut = exchange.getEtherAmount(liqAmmount);
        // console.log("ethOut ", ethOut);

        assertEq(ethOut, 250 wei);

        // console.log(address(exchange).balance);

        token.approve(address(exchange), 1000 wei);
        exchange.tokenToEthSwap(1000 wei, 250 wei);

        ethOut = exchange.getEtherAmount(liqAmmount);
        // console.log("ethOut ", ethOut);

        assertEq(ethOut, 125 wei);

        // console.log(token.balanceOf(address(exchange)));
        // console.log(address(exchange).balance);

        exchange.ethToTokenSwap{ value: 125 }(1989 wei);

        ethOut = exchange.getEtherAmount(liqAmmount);
        // console.log("ethOut ", ethOut);

        // console.log(token.balanceOf(address(exchange)));
        // console.log(address(exchange).balance);
    }

    function testTokenToEtherSwapFails() public {
        uint liqAmmount = 2000 wei;
        startHoax(owner);
        token.mint(address(owner), liqAmmount);
        token.approve(address(exchange), liqAmmount);
        exchange.addLiquidity{ value: 1000 wei }(liqAmmount);
        vm.stopPrank();

        assertEq(token.balanceOf(address(exchange)), 2000 wei);
        assertEq(address(exchange).balance, 1000 wei);

        vm.startPrank(user);
        token.mint(address(user), 1000 wei);
        token.approve(address(exchange), 1000 wei);
        vm.expectRevert("tokenToEthSwap::Insufficient output ether amount");
        exchange.tokenToEthSwap(1000 wei, 500 wei);

        assertEq(token.balanceOf(address(exchange)), 2000 wei);
        assertEq(address(exchange).balance, 1000 wei);
    }

    function testEthToTokenSwap() public {
        uint liqAmmount = 2000 wei;
        startHoax(owner);
        token.mint(address(owner), liqAmmount);
        token.approve(address(exchange), liqAmmount);
        exchange.addLiquidity{ value: 1000 wei }(liqAmmount);

        uint ethOut = exchange.getEtherAmount(liqAmmount);
        // console.log("ethOut ", ethOut);

        assertEq(ethOut, 497 wei);

        assertEq(address(exchange).balance, 1000 wei);
        assertEq(token.balanceOf(address(exchange)), 2000 wei);

        uint ethBalanceBefore = address(owner).balance;
        uint tokenBalanceBefore = token.balanceOf(address(owner));

        exchange.ethToTokenSwap{ value: 497 wei }(994 wei);

        assertEq(address(owner).balance, ethBalanceBefore - 497 wei);
        assertEq(token.balanceOf(address(owner)), tokenBalanceBefore + 994 wei);
    }

    function testTokenToTokenSwap() public {
        factory = new Factory();
        MintableERC20 token1 = new MintableERC20("Token A", "TKA");
        MintableERC20 token2 = new MintableERC20("Token B", "TKB");

        vm.startPrank(owner);
        deal(address(owner), 1 ether);
        address exchange1 = factory.createExchange(address(token1));
        token1.mint(address(owner), 4000 wei);
        token1.approve(address(exchange1), 2000 wei);
        IExchange(exchange1).addLiquidity{ value: 1000 wei }(2000 wei);
        vm.stopPrank();

        vm.startPrank(user);
        deal(address(user), 1 ether);
        address exchange2 = factory.createExchange(address(token2));
        token2.mint(address(user), 4000 wei);
        token2.approve(address(exchange2), 1000 wei);
        IExchange(exchange2).addLiquidity{ value: 1000 wei }(1000 wei);
        vm.stopPrank();

        assertEq(token2.balanceOf(address(owner)), 0);

        uint exchange1BalanceBefore = token1.balanceOf(address(exchange1));

        // function tokenToTokenSwap(uint tokenSold, uint minTokenBought, address tokenBought) external;
        vm.startPrank(owner);
        token1.approve(address(exchange1), 1000 wei);
        IExchange(exchange1).tokenToTokenSwap(1000 wei, 497 wei, address(token2));
        vm.stopPrank();

        assertEq(token1.balanceOf(address(exchange1)), exchange1BalanceBefore + 1000 wei);
        assertEq(token2.balanceOf(address(owner)), 497);
        assertEq(token2.balanceOf(address(exchange2)), 503);

        uint exchange2BalanceBefore = token2.balanceOf(address(exchange2));

        vm.startPrank(user);
        token2.approve(address(exchange2), 1000 wei);
        IExchange(exchange2).tokenToTokenSwap(744 wei, 1492 wei, address(token1));

        assertEq(token2.balanceOf(address(exchange2)), exchange2BalanceBefore + 744 wei);
        assertEq(token1.balanceOf(address(user)), 1492);
    }
}