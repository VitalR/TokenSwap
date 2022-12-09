// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "solmate/test/utils/DSTestPlus.sol";
import "src/TokenERC20.sol";

contract TokenERC20Test is DSTestPlus {

    string public name = "Token Name";
    string public symbol = "TSB";
    uint8 public decimals = 18;
    uint256 public initialSupply = 1000 * 1e18; // 1000 ether

    TokenERC20 token;

    function setUp() public {
        token = new TokenERC20(name, symbol, decimals, initialSupply);
    }

    function testInitialState() public {
        assertEq(token.name(), name);
        assertEq(token.symbol(), symbol);
        assertEq(token.decimals(), decimals);
        assertEq(token.balanceOf(address(this)), initialSupply);
    }
}