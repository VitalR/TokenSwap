// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import "src/UniswapV2Pair.sol";
import "./mocks/MintableERC20.sol";

contract UniswapV2PairTest is Test {

    MintableERC20 token0;
    MintableERC20 token1;
    UniswapV2Pair pair;

    function setUp() public {

        token0 = new MintableERC20("Token A", "TKNA");
        token1 = new MintableERC20("Token B", "TKNB");

        pair = new UniswapV2Pair();

        token0.mint(address(this), 10 ether);
        token1.mint(address(this), 10 ether);
    }

    function assertReserves(uint expectedReserve0, uint expectedReserve1) internal {
        (uint reserve0, uint reserve1) = pair.getReserves();
        assertEq(reserve0, expectedReserve0, "Unexpected reserve0");
        assertEq(reserve1, expectedReserve1, "Unexpected reserve1");
    }

    // test for pair bootstrapping - providing initial liquidity
    function testMintBootstrap() public {
        pair.initialize(address(token0), address(token1));
        token0.transfer(address(pair), 1 ether);
        token1.transfer(address(pair), 1 ether);
        
        pair.mint(address(this));

        assertEq(pair.balanceOf(address(this)), 1 ether - 1000 wei);
        assertEq(pair.totalSupply(), 1 ether);
        assertReserves(1 ether, 1 ether);
    }

    function testMintWhenTheresLiquidity() public {
        pair.initialize(address(token0), address(token1));
        token0.transfer(address(pair), 1 ether);
        token1.transfer(address(pair), 1 ether);
        
        pair.mint(address(this)); // + 1 LP

        token0.transfer(address(pair), 2 ether);
        token1.transfer(address(pair), 2 ether);

        pair.mint(address(this)); // + 2 LP

        assertEq(pair.balanceOf(address(this)), 3 ether - 1000 wei);
        assertEq(pair.totalSupply(), 3 ether);
        assertReserves(3 ether, 3 ether);
    }

    function testMintUnbalanced() public {
        pair.initialize(address(token0), address(token1));
        token0.transfer(address(pair), 1 ether);
        token1.transfer(address(pair), 1 ether);
        
        pair.mint(address(this)); // + 1 LP

        token0.transfer(address(pair), 2 ether);
        token1.transfer(address(pair), 1 ether);

        pair.mint(address(this)); // + 1 LP

        assertEq(pair.balanceOf(address(this)), 2 ether - 1000 wei);
        assertEq(pair.totalSupply(), 2 ether);
        assertReserves(3 ether, 2 ether);
    }

    function testBurn() public {
        pair.initialize(address(token0), address(token1));
        token0.transfer(address(pair), 1 ether);
        token1.transfer(address(pair), 1 ether);

        pair.mint(address(this));
        uint lpBalanceBefore = pair.balanceOf(address(this));

        assertEq(pair.balanceOf(address(this)), 1 ether - 1000 wei);
        assertEq(pair.totalSupply(), 1 ether);
        assertReserves(1 ether, 1 ether);

        pair.burn(address(this));

        assertEq(pair.balanceOf(address(this)), 0);
        assertEq(pair.totalSupply(), 1 ether - lpBalanceBefore);
        assertReserves(1000 wei, 1000 wei);

        assertEq(token0.balanceOf(address(this)), 10 ether - 1000 wei);
        assertEq(token1.balanceOf(address(this)), 10 ether - 1000 wei);

        assertEq(token0.balanceOf(address(pair)), 1000 wei);
        assertEq(token1.balanceOf(address(pair)), 1000 wei);
    }

    function testBurnUnbalanced() public {
        pair.initialize(address(token0), address(token1));
        token0.transfer(address(pair), 1 ether);
        token1.transfer(address(pair), 1 ether);

        pair.mint(address(this));

        token0.transfer(address(pair), 2 ether);
        token1.transfer(address(pair), 1 ether);

        pair.mint(address(this)); // + 1 LP
        uint lpBalanceBefore = pair.balanceOf(address(this));

        assertEq(pair.balanceOf(address(this)), 2 ether - 1000 wei);
        assertEq(pair.totalSupply(), 2 ether);
        assertReserves(3 ether, 2 ether);

        pair.burn(address(this));

        assertEq(pair.balanceOf(address(this)), 0);
        assertEq(pair.totalSupply(), 2 ether - (2 ether - 1000 wei)); // - lpBalanceBefore
        assertReserves(1500 wei, 1000 wei);
    }

}