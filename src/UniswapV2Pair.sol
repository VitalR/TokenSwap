// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "solmate/tokens/ERC20.sol";
import "./libraries/Math.sol";
import "./libraries/UQ112x112.sol";

import "forge-std/console.sol";

interface IERC20 {
    function balanceOf(address) external returns (uint);
}

error AlreadyInitialized();
error InsufficientLiquidityMinted();
error InsufficientLiquidityBurned();
error InsufficientLiquidity();
error InsufficientOutputAmount();
error BalanceOverflow();
error TransferFailed();
error InvalidK();

contract UniswapV2Pair is ERC20, Math {
    using UQ112x112 for uint224;

    uint constant MINIMUM_LIQUIDITY = 1000;

    address public token0;
    address public token1;

    uint112 private reserve0;
    uint112 private reserve1;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address to);
    event Swap(address indexed sender, uint amount0Out, uint amount1Out, address indexed to);

    constructor() ERC20("LP UniswapV2 Pair", "LP-UNI-V2", 18) {}
    
    function initialize(address token0_, address token1_) public {
        if (token0 != address(0) || token1 != address(0))
            revert AlreadyInitialized();

        token0 = token0_;
        token1 = token1_;
    }

    function mint(address to) public returns (uint liquidity) {
        (uint112 reserve0_, uint112 reserve1_) = getReserves();
        uint balance0 = IERC20(token0).balanceOf(address(this));
        uint balance1 = IERC20(token1).balanceOf(address(this));
        uint amount0 = balance0 - reserve0_;
        console.log("mint:amount0", amount0);
        uint amount1 = balance1 - reserve1_;
        console.log("mint:amount1", amount1);

        if (totalSupply == 0) {
            liquidity = Math.sqrt(amount0 * amount1) - MINIMUM_LIQUIDITY;
            _mint(address(0), MINIMUM_LIQUIDITY);
            console.log("mint:liquidity", liquidity);
        } else {
            liquidity = Math.min(
                (amount0 * totalSupply) / reserve0_,
                (amount1 * totalSupply) / reserve1_
            );
            console.log("mint:liquidity", liquidity);
        }

        if (liquidity <= 0) revert InsufficientLiquidityMinted();

        _mint(to, liquidity);

        _update(balance0, balance1);

        emit Mint(msg.sender, amount0, amount1);
    }

    function burn(address to) public returns (uint amount0, uint amount1) {
        uint balance0 = IERC20(token0).balanceOf(address(this));
        console.log("burn:balance0", balance0);
        uint balance1 = IERC20(token1).balanceOf(address(this));
        console.log("burn:balance0", balance1);
        uint liquidity = balanceOf[msg.sender];
        console.log("burn:liquidity-msg.sender", liquidity);

        amount0 = (balance0 * liquidity) / totalSupply;
        console.log("burn:amount0", amount0);
        amount1 = (balance1 * liquidity) / totalSupply;
        console.log("burn:amount1", amount1);
        console.log("burn:totalSupply", totalSupply);

        if (amount0 == 0 || amount1 == 0) revert InsufficientLiquidityBurned();

        _burn(msg.sender, liquidity);

        _safeTransfer(token0, to, amount0);
        _safeTransfer(token1, to, amount1);

        balance0 = IERC20(token0).balanceOf(address(this));
        console.log("burn:balance0", balance0);
        balance1 = IERC20(token1).balanceOf(address(this));
        console.log("burn:balance1", balance1);

        console.log(totalSupply);

        _update(balance0, balance1);

        emit Burn(msg.sender, amount0, amount1, to);
    }

    function swap(uint amount0Out, uint amount1Out, address to) public {
        if (amount0Out == 0 && amount1Out == 0)
            revert InsufficientOutputAmount();

        (uint112 reserve0_, uint112 reserve1_) = getReserves();

        if (amount0Out > reserve0_ || amount1Out > reserve1_)
            revert InsufficientLiquidity();

        uint balance0 = IERC20(token0).balanceOf(address(this)) - amount0Out;
        console.log("balance0 ", balance0);
        uint balance1 = IERC20(token1).balanceOf(address(this)) - amount1Out;
        console.log("balance1 ", balance1);

        console.log("balance0 * balance1 ", balance0 * balance1);
        console.log("uint256(reserve0_) * uint256(reserve1_) ", uint256(reserve0_) * uint256(reserve1_));

        if (balance0 * balance1 < uint256(reserve0_) * uint256(reserve1_))
            revert InvalidK();

        _update(balance0, balance1);

        if (amount0Out > 0) _safeTransfer(token0, to, amount0Out);
        if (amount1Out > 0) _safeTransfer(token1, to, amount1Out);

        emit Swap(msg.sender, amount0Out, amount1Out, to);
    }

    function getReserves() public view returns (uint112, uint112) {
        return (reserve0, reserve1);
    }

    function _update(uint balance0_, uint balance1_) private {
        if (balance0_ > type(uint112).max || balance1_ > type(uint112).max)
            revert BalanceOverflow();

        reserve0 = uint112(balance0_);
        reserve1 = uint112(balance1_);
    }

    function _safeTransfer(address token, address to, uint value) private {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSignature("transfer(address,uint256)", to, value)
        );
        if (!success || (data.length != 0 && !abi.decode(data, (bool))))
            revert TransferFailed();
    }

}