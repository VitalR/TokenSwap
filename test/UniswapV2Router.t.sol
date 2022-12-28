// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import "src/UniswapV2Library.sol";
import "src/UniswapV2Pair.sol";
import "src/UniswapV2Router.sol";
import "src/UniswapV2Factory.sol";
import "./mocks/MintableERC20.sol";

contract UniswapV2RouterTest is Test {

    UniswapV2Factory factory;
    UniswapV2Router router;

    MintableERC20 tokenA;
    MintableERC20 tokenB;
    MintableERC20 tokenC;

    function setUp() public {
        factory = new UniswapV2Factory();
        router = new UniswapV2Router(address(factory));

        tokenA = new MintableERC20("Token A", "TKNA");
        tokenB = new MintableERC20("Token B", "TKNB");
        tokenC = new MintableERC20("Token C", "TKNC");

        tokenA.mint(address(this), 10 ether);
        tokenB.mint(address(this), 10 ether);
        tokenC.mint(address(this), 10 ether);
    }

    function encodeError(string memory error) internal pure returns (bytes memory encoded) {
        encoded = abi.encodeWithSignature(error);
    }

    function testAddLiquidityCreatesPair() public {
        tokenA.approve(address(router), 1 ether);
        tokenB.approve(address(router), 1 ether);

        router.addLiquidity(
            address(tokenA),
            address(tokenB),
            1 ether,
            1 ether,
            1 ether,
            1 ether,
            address(this)
        );

        address pair = factory.pairs(address(tokenA), address(tokenB));
        // console.log(address(pair));
        assertEq(pair, 0x0cCFa00b47021Bf92790A6195001d83468115776);
    }

    function testAddLiquidityNoPair() public {
        tokenA.approve(address(router), 1 ether);
        tokenB.approve(address(router), 1 ether);

        (uint amountA, uint amountB, uint liquidity) = router
            .addLiquidity(
                address(tokenA),
                address(tokenB),
                1 ether,
                1 ether,
                1 ether,
                1 ether,
                address(this)
            );

        assertEq(amountA, 1 ether);
        assertEq(amountB, 1 ether);
        assertEq(liquidity, 1 ether - 1000 wei);

        address pairAddress = factory.pairs(address(tokenA), address(tokenB));

        UniswapV2Pair pair = UniswapV2Pair(pairAddress);

        assertEq(pair.token0(), address(tokenB));
        assertEq(pair.token1(), address(tokenA));
        assertEq(pair.totalSupply(), 1 ether);
        assertEq(pair.balanceOf(address(this)), 1 ether - 1000 wei);

        assertEq(tokenA.balanceOf(address(this)), 9 ether);
        assertEq(tokenB.balanceOf(address(this)), 9 ether);
    }

    function testAddLiquidityAmountBOptimalIsOk() public {
        address pairAddress = factory.createPair(address(tokenA), address(tokenB));

        UniswapV2Pair pair = UniswapV2Pair(pairAddress);

        assertEq(pair.token0(), address(tokenB));
        assertEq(pair.token1(), address(tokenA));

        tokenA.transfer(address(pair), 1 ether);
        tokenB.transfer(address(pair), 2 ether);
        pair.mint(address(this));

        tokenA.approve(address(router), 1 ether);
        tokenB.approve(address(router), 2 ether);

        (uint amountA, uint amountB, uint liquidity) = router
            .addLiquidity(
                address(tokenA),
                address(tokenB),
                1 ether,
                2 ether,
                1 ether,
                1.9 ether,
                address(this)
            );

        assertEq(amountA, 1 ether);
        assertEq(amountB, 2 ether);
        assertEq(liquidity, 1414213562373095048);
    }

    function testAddLiquidityAmountBOptimalIsTooLow() public {
        address pairAddress = factory.createPair(address(tokenA), address(tokenB));

        UniswapV2Pair pair = UniswapV2Pair(pairAddress);

        assertEq(pair.token0(), address(tokenB));
        assertEq(pair.token1(), address(tokenA));

        tokenA.transfer(address(pair), 3 ether);
        tokenB.transfer(address(pair), 6 ether);
        pair.mint(address(this));

        tokenA.approve(address(router), 1 ether);
        tokenB.approve(address(router), 2 ether);

        vm.expectRevert(encodeError("InsufficientBAmount()"));
        router.addLiquidity(
            address(tokenA),
            address(tokenB),
            1 ether,
            2 ether,
            1 ether,
            2 ether,
            address(this)
        );
    }

    function testAddLiquidityAmountBOptimalTooHighAmountATooLow() public {
        address pairAddress = factory.createPair(address(tokenA), address(tokenB));

        UniswapV2Pair pair = UniswapV2Pair(pairAddress);

        assertEq(pair.token0(), address(tokenB));
        assertEq(pair.token1(), address(tokenA));

        tokenA.transfer(address(pair), 6 ether);
        tokenB.transfer(address(pair), 3 ether);
        pair.mint(address(this));

        tokenA.approve(address(router), 2 ether);
        tokenB.approve(address(router), 1 ether);

        vm.expectRevert(encodeError("InsufficientAAmount()"));
        router.addLiquidity(
            address(tokenA),
            address(tokenB),
            2 ether,
            0.9 ether,
            2 ether,
            1 ether,
            address(this)
        );
    }

    function testAddLiquidityAmountBOptimalIsTooHightAmountAOk() public {
        address pairAddress = factory.createPair(address(tokenA), address(tokenB));

        UniswapV2Pair pair = UniswapV2Pair(pairAddress);

        assertEq(pair.token0(), address(tokenB));
        assertEq(pair.token1(), address(tokenA));

        tokenA.transfer(address(pair), 6 ether);
        tokenB.transfer(address(pair), 3 ether);
        pair.mint(address(this));

        tokenA.approve(address(router), 2 ether);
        tokenB.approve(address(router), 1 ether);

        (uint amountA, uint amountB, uint liquidity) = router
            .addLiquidity(
                address(tokenA),
                address(tokenB),
                2 ether,
                0.9 ether,
                1.7 ether,
                1 ether,
                address(this)
            );

        assertEq(amountA, 1.8 ether);
        assertEq(amountB, 0.9 ether);
        assertEq(liquidity, 1272792206135785543);
    }

    function testRemoveLiquidity() public {
        tokenA.approve(address(router), 1 ether);
        tokenB.approve(address(router), 1 ether);

        router.addLiquidity(
            address(tokenA), 
            address(tokenB), 
            1 ether,
            1 ether,
            1 ether,
            1 ether,
            address(this)
        );

        address pair = factory.pairs(address(tokenA), address(tokenB));
        UniswapV2Pair lpToken = UniswapV2Pair(pair);
        uint liquidity = lpToken.balanceOf(address(this));

        lpToken.approve(address(router), liquidity);

        router.removeLiquidity(
            address(tokenA), 
            address(tokenB),
            liquidity,
            1 ether - 1000 wei,
            1 ether - 1000 wei,
            address(this)
        );

        (uint reserve0, uint reserve1, ) = lpToken.getReserves();
        assertEq(reserve0, 1000);
        assertEq(reserve1, 1000);
        assertEq(lpToken.balanceOf(address(this)), 0);
        assertEq(lpToken.totalSupply(), 1000);
        assertEq(tokenA.balanceOf(address(this)), 10 ether - 1000 wei);
        assertEq(tokenB.balanceOf(address(this)), 10 ether - 1000 wei);
    }

    function testSwapExactTokensForTokens() public {
        tokenA.approve(address(router), 1 ether);
        tokenB.approve(address(router), 2 ether);
        tokenC.approve(address(router), 1 ether);

        router.addLiquidity(
            address(tokenA),
            address(tokenB),
            1 ether,
            1 ether,
            1 ether,
            1 ether,
            address(this)
        );

        router.addLiquidity(
            address(tokenB), 
            address(tokenC),
            1 ether,
            1 ether,
            1 ether,
            1 ether,
            address(this)
        );

        address[] memory path = new address[](3);
        path[0] = address(tokenA);
        path[1] = address(tokenB);
        path[2] = address(tokenC);

        tokenA.approve(address(router), 0.3 ether);
        router.swapExactTokensForTokens(
            0.3 ether,
            0.1 ether,
            path, 
            address(this)
        );

        assertEq(tokenA.balanceOf(address(this)), 10 ether - 1 ether - 0.3 ether);
        assertEq(tokenB.balanceOf(address(this)), 10 ether - 2 ether);
        assertEq(tokenC.balanceOf(address(this)), 
            10 ether - 1 ether + 0.186691414219734305 ether);
    }

    function testSwapTokensForExactTokens() public {
        tokenA.approve(address(router), 1 ether);
        tokenB.approve(address(router), 2 ether);
        tokenC.approve(address(router), 1 ether);

        router.addLiquidity(
            address(tokenA),
            address(tokenB),
            1 ether,
            1 ether,
            1 ether,
            1 ether,
            address(this)
        );

        router.addLiquidity(
            address(tokenB), 
            address(tokenC),
            1 ether,
            1 ether,
            1 ether,
            1 ether,
            address(this)
        );

        address[] memory path = new address[](3);
        path[0] = address(tokenA);
        path[1] = address(tokenB);
        path[2] = address(tokenC);

        tokenA.approve(address(router), 0.3 ether);
        router.swapTokensForExactTokens(
            0.186691414219734305 ether,
            0.3 ether,
            path, 
            address(this)
        );

        assertEq(tokenA.balanceOf(address(this)), 10 ether - 1 ether - 0.3 ether);
        assertEq(tokenB.balanceOf(address(this)), 10 ether - 2 ether);
        assertEq(tokenC.balanceOf(address(this)), 
            10 ether - 1 ether + 0.186691414219734305 ether);
    }

}