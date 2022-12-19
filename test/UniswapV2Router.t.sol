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

    MintableERC20 token0;
    MintableERC20 token1;

    function setUp() public {
        factory = new UniswapV2Factory();
        router = new UniswapV2Router(address(factory));

        token0 = new MintableERC20("Token A", "TKNA");
        token1 = new MintableERC20("Token B", "TKNB");

        // pair = new UniswapV2Pair();

        token0.mint(address(this), 10 ether);
        token1.mint(address(this), 10 ether);
    }

    function encodeError(string memory error) internal pure returns (bytes memory encoded) {
        encoded = abi.encodeWithSignature(error);
    }

    function testAddLiquidityCreatesPair() public {
        token0.approve(address(router), 1 ether);
        token1.approve(address(router), 1 ether);

        router.addLiquidity(
            address(token0),
            address(token1),
            1 ether,
            1 ether,
            1 ether,
            1 ether,
            address(this)
        );

        address pair = factory.pairs(address(token0), address(token1));
        console.log(address(pair));
        assertEq(pair, 0x978fd176AAc63c1Bd990D4ec34481Dc5bfAFbBD0);
    }

}