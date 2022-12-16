// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import "src/UniswapV2Pair.sol";
import "src/UniswapV2Factory.sol";
import "./mocks/MintableERC20.sol";

import "forge-std/console.sol";

contract UniswapV2FactoryTest is Test {
    UniswapV2Factory factory;

    MintableERC20 token0;
    MintableERC20 token1;
    MintableERC20 token2;
    MintableERC20 token3;

    function setUp() public {
        factory = new UniswapV2Factory();

        token0 = new MintableERC20("Token A", "TKNA");
        token1 = new MintableERC20("Token B", "TKNB");
        token2 = new MintableERC20("Token C", "TKNC");
        token3 = new MintableERC20("Token D", "TKND");
    }

    function encodeError(string memory error) internal pure returns (bytes memory encoded) {
        encoded = abi.encodeWithSignature(error);
    }

    function testCreatePair() public {
        address pairAddress = factory.createPair(address(token1), address(token0));

        UniswapV2Pair pair = UniswapV2Pair(pairAddress);

        assertEq(pair.token0(), address(token0));
        assertEq(pair.token1(), address(token1));
    }

    function testCreatePairWithIdenticalTokens() public {
        vm.expectRevert(encodeError("IdenticalAddresses()"));
        factory.createPair(address(token0), address(token0));
    }

    function testCreatePairWithZeroAddresses() public {
        vm.expectRevert(encodeError("ZeroAddress()"));
        factory.createPair(address(0), address(token1));

        vm.expectRevert(encodeError("ZeroAddress()"));
        factory.createPair(address(token0), address(0));
    }

    function testCreatePairIdenticalAddresses() public {
        factory.createPair(address(token0), address(token1));

        vm.expectRevert(encodeError("PairExists()"));
        factory.createPair(address(token0), address(token1));
    }

}