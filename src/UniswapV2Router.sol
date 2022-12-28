// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./UniswapV2Library.sol";

contract UniswapV2Router {
    error InsufficientAAmount();
    error InsufficientBAmount();
    error InsufficientOutputAmount();
    error ExcessiveInputAmount();
    error SafeTransferFailed();

    IUniswapV2Factory factory;

    constructor(address factory_) {
        factory = IUniswapV2Factory(factory_);
    }

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBmin,
        address to
    ) public returns (uint amountA, uint amountB, uint liquidity) {

        if (factory.pairs(tokenA, tokenB) == address(0)) {
            factory.createPair(tokenA, tokenB);
        }

        (amountA, amountB) = _calculateLiquidity(
            tokenA,
            tokenB,
            amountADesired,
            amountBDesired,
            amountAMin,
            amountBmin
        );

        address pair = UniswapV2Library.pairFor(
            address(factory),
            tokenA,
            tokenB
        );

        _safeTransferFrom(tokenA, msg.sender, pair, amountA);
        _safeTransferFrom(tokenB, msg.sender, pair, amountB);
        liquidity = IUniswapV2Pair(pair).mint(to);
    }

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to
    ) public returns (uint amountA, uint amountB) {

        address pair = UniswapV2Library.pairFor(address(factory), tokenA, tokenB);

        IUniswapV2Pair(pair).transferFrom(msg.sender, pair, liquidity);
        (amountA, amountB) = IUniswapV2Pair(pair).burn(to);

        if (amountA < amountAMin) revert InsufficientAAmount();
        if (amountB < amountBMin) revert InsufficientBAmount();
    }

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to
    ) public returns (uint[] memory amounts) {

        amounts = UniswapV2Library.getAmountsOut(address(factory), amountIn, path);

        if (amounts[amounts.length - 1] < amountOutMin) 
            revert InsufficientOutputAmount();

        _safeTransferFrom(
            path[0],
            msg.sender,
            UniswapV2Library.pairFor(address(factory), path[0], path[1]),
            amounts[0]
        );

        _swap(amounts, path, to);
    }

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to
    ) public returns (uint[] memory amounts) {

        amounts = UniswapV2Library.getAmountsIn(address(factory), amountOut, path);

        if (amounts[amounts.length - 1] > amountInMax)
            revert ExcessiveInputAmount();

        _safeTransferFrom(
            path[0],
            msg.sender,
            UniswapV2Library.pairFor(address(factory), path[0], path[1]),
            amounts[0]
        );

        _swap(amounts, path, to);
    }

    function _swap(
        uint[] memory amounts,
        address[] memory path,
        address to_
    ) internal {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0, ) = UniswapV2Library.sortTokens(input, output);

            uint amountOut = amounts[i + 1];
            (uint amount0Out, uint amount1Out) = token0 == input
                ? (uint(0), amountOut)
                : (amountOut, uint(0));

            address to = i < path.length - 2
                ? UniswapV2Library.pairFor(
                    address(factory),
                    output,
                    path[i + 2]
                )
                : to_;

            IUniswapV2Pair(
                UniswapV2Library.pairFor(address(factory), input, output)
            ).swap(amount0Out, amount1Out, to, "");
        }
    }

    function _calculateLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin
    ) internal view returns (uint amountA, uint amountB) {
        
        (uint reserveA, uint reserveB) = UniswapV2Library.getReserves(
            address(factory),
            tokenA,
            tokenB
        );

        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint amountBOptimal = UniswapV2Library.quote(
                amountADesired,
                reserveA,
                reserveB
            );
            if (amountBOptimal <= amountBDesired) {
                if (amountBOptimal <= amountBMin) revert InsufficientBAmount();
                (amountA, amountB) = (amountADesired, amountBDesired);
            } else {
                uint amountAOptimal = UniswapV2Library.quote(
                    amountBDesired,
                    reserveB,
                    reserveA
                );
                assert(amountAOptimal <= amountADesired);

                if (amountAOptimal <= amountAMin) revert InsufficientAAmount();
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }

    function _safeTransferFrom(
        address token,
        address from,
        address to,
        uint value
    ) private {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSignature("transferFrom(address,address,uint256)", from, to, value)
        );
        if (!success || (data.length != 0 && !abi.decode(data, (bool))))
            revert SafeTransferFailed();
    }
}