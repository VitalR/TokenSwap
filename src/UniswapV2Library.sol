// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "src/interfaces/IUniswapV2Pair.sol";
import "src/interfaces/IUniswapV2Factory.sol";
import { UniswapV2Pair } from "./UniswapV2Pair.sol";

error InsufficientAmount();
error InsufficientLiquidity();

library UniswapV2Library {

    function getReserves(
        address factory,
        address tokenA,
        address tokenB
    ) public view returns (uint reserveA, uint reserveB) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1, ) = IUniswapV2Pair(
            pairFor(factory, token0, token1)
        ).getReserves();
        (reserveA, reserveB) = tokenA == tokenB
            ? (reserve0, reserve1)
            : (reserve1, reserve0);
    }

    function quote(
        uint amountIn,
        uint reserveIn,
        uint reserveOut
    ) public pure returns (uint amountOut) {
        if (amountIn == 0) revert InsufficientAmount();
        if (reserveIn == 0 || reserveOut == 0) revert InsufficientLiquidity();

        return (amountIn * reserveOut) / reserveIn;
    }

    function sortTokens(address tokenA, address tokenB)
        internal
        pure
        returns (address token0, address token1) 
    {
        return tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    }

    function pairFor(
        address factory,
        address tokenA,
        address tokenB
    ) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(
            uint160(
                uint(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            factory,
                            keccak256(abi.encodePacked(token0, token1)),
                            keccak256(type(UniswapV2Pair).creationCode)
                        )
                    )
                )
            )
        );
    }
}