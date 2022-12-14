// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import "src/UniswapV2Pair.sol";
import "./mocks/MintableERC20.sol";

contract UniswapV2PairTest is Test {

    MintableERC20 token0;
    MintableERC20 token1;
    UniswapV2Pair pair;
    address user = address(11);

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
        // uint lpBalanceBefore = pair.balanceOf(address(this));

        assertEq(pair.balanceOf(address(this)), 2 ether - 1000 wei);
        assertEq(pair.totalSupply(), 2 ether);
        assertReserves(3 ether, 2 ether);

        pair.burn(address(this));

        assertEq(pair.balanceOf(address(this)), 0);
        assertEq(pair.totalSupply(), 2 ether - (2 ether - 1000 wei)); // - lpBalanceBefore
        assertReserves(1500 wei, 1000 wei);

        assertEq(token0.balanceOf(address(this)), 10 ether - 1500 wei);
        assertEq(token1.balanceOf(address(this)), 10 ether - 1000 wei);
    }

    function testBurnUnbalancedDifferenceUsers() public {
        startHoax(user);
        token0.mint(address(user), 10 ether);
        token1.mint(address(user), 10 ether);
        pair.initialize(address(token0), address(token1));
        token0.transfer(address(pair), 1 ether);
        token1.transfer(address(pair), 1 ether);

        pair.mint(address(user));
        vm.stopPrank();

        assertEq(pair.balanceOf(address(this)), 0);
        assertEq(pair.balanceOf(address(user)), 1 ether - 1000 wei);
        assertEq(pair.totalSupply(), 1 ether);

        token0.transfer(address(pair), 2 ether);
        token1.transfer(address(pair), 1 ether);
        
        pair.mint(address(this)); // + LP

        assertEq(pair.balanceOf(address(this)), 1 ether);
        assertEq(pair.totalSupply(), 2 ether);

        pair.burn(address(this));

        assertEq(pair.balanceOf(address(this)), 0);
        assertEq(pair.totalSupply(), 1 ether);
        assertReserves(1.5 ether, 1 ether);
        assertEq(token0.balanceOf(address(this)), 10 ether - 0.5 ether);
        assertEq(token1.balanceOf(address(this)), 10 ether);
    }

    function testBurnZeroLiquidity() public {
        pair.initialize(address(token0), address(token1));
        token0.transfer(address(pair), 1 ether);
        token1.transfer(address(pair), 1 ether);
        pair.mint(address(this));

        vm.prank(user);
        vm.expectRevert(bytes(hex"749383ad")); // InsufficientLiquidityBurned()
        pair.burn(address(user));
    }

    function testBurnZeroTotalSupply() public {
        // VM::expectRevert(Division or modulo by 0)
        vm.expectRevert();
        pair.burn(address(this));
    }

    function testSwapBasicScenario() public {
        pair.initialize(address(token0), address(token1));
        token0.transfer(address(pair), 1 ether);
        token1.transfer(address(pair), 2 ether);
        pair.mint(address(this));

        token0.transfer(address(pair), 0.1 ether);
        pair.swap(0, 0.18 ether, address(this));

        assertEq(token0.balanceOf(address(this)), 10 ether - 1 ether - 0.1 ether, 
            "Unexpected token0 balance");
        assertEq(token1.balanceOf(address(this)), 10 ether - 2 ether + 0.18 ether, 
            "Unexpected token1 balance");
        assertReserves(1 ether + 0.1 ether, 2 ether - 0.18 ether);
    }

    function testSwapBacisScenarioReverseDirection() public {
        pair.initialize(address(token0), address(token1));
        token0.transfer(address(pair), 1 ether);
        token1.transfer(address(pair), 2 ether);
        pair.mint(address(this));

        token1.transfer(address(pair), 0.2 ether);
        pair.swap(0.09 ether, 0, address(this));

        assertEq(token0.balanceOf(address(this)), 10 ether - 1 ether + 0.09 ether,
            "Unexpected token0 balance");
        assertEq(token1.balanceOf(address(this)), 10 ether - 2 ether - 0.2 ether,
            "Unexpected token1 balance");
        assertReserves(1 ether - 0.09 ether, 2 ether + 0.2 ether);
    }

    function testSwapBidirectional() public {
        pair.initialize(address(token0), address(token1));
        token0.transfer(address(pair), 1 ether);
        token1.transfer(address(pair), 2 ether);
        pair.mint(address(this));

        token0.transfer(address(pair), 0.1 ether);
        token1.transfer(address(pair), 0.2 ether);
        pair.swap(0.09 ether, 0.18 ether, address(this));

        assertEq(token0.balanceOf(address(this)), 10 ether - 1 ether - 0.01 ether,
            "Unexpected token0 balance");
        assertEq(token1.balanceOf(address(this)), 10 ether - 2 ether - 0.02 ether, 
            "Unexpected token1 balance");
        assertReserves(1 ether + 0.01 ether, 2 ether + 0.02 ether);
    }

    function testSwapZeroOut() public {
        pair.initialize(address(token0), address(token1));
        token0.transfer(address(pair), 1 ether);
        token1.transfer(address(pair), 2 ether);
        pair.mint(address(this));

        vm.expectRevert(bytes(hex"42301c23")); // InsufficientOutputAmount()
        pair.swap(0, 0, address(this));
    }

    function testSwapUnsufficientLiquidity() public {
        pair.initialize(address(token0), address(token1));
        token0.transfer(address(pair), 1 ether);
        token1.transfer(address(pair), 2 ether);
        pair.mint(address(this));

        vm.expectRevert(bytes(hex"bb55fd27")); // InsufficientLiquidity()
        pair.swap(1.1 ether, 0, address(this));

        vm.expectRevert(bytes(hex"bb55fd27")); // InsufficientLiquidity()
        pair.swap(0, 2.1 ether, address(this));
    }

    function testSwapUnderpriced() public {
        pair.initialize(address(token0), address(token1));
        token0.transfer(address(pair), 1 ether);
        token1.transfer(address(pair), 2 ether);
        pair.mint(address(this));

        token0.transfer(address(pair), 0.1 ether);
        pair.swap(0, 0.09 ether, address(this));

        assertEq(token0.balanceOf(address(this)), 10 ether - 1 ether - 0.1 ether, 
            "Unexpected token0 balance");
        assertEq(token1.balanceOf(address(this)), 10 ether - 2 ether + 0.09 ether, 
            "Unexpected token1 balance");
        assertReserves(1 ether + 0.1 ether, 2 ether - 0.09 ether);
    }

    function testSwapOverpriced() public {
        pair.initialize(address(token0), address(token1));
        token0.transfer(address(pair), 1 ether);
        token1.transfer(address(pair), 2 ether);
        pair.mint(address(this));

        token0.transfer(address(pair), 0.1 ether);

        vm.expectRevert(bytes(hex"bd8bc364")); // InsufficientLiquidity()
        pair.swap(0, 0.25 ether, address(this));

        assertEq(token0.balanceOf(address(this)), 10 ether - 1 ether - 0.1 ether, 
            "Unexpected token0 balance");
        assertEq(token1.balanceOf(address(this)), 10 ether - 2 ether, 
            "Unexpected token1 balance");
        assertReserves(1 ether, 2 ether);
    }

}