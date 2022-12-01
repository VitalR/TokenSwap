// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "solmate/tokens/ERC20.sol";

contract TokenERC20 is ERC20 {
    constructor(
        string memory _name,
        string memory _symbol, 
        uint8 _decimals,
        uint _initialSupply
    ) ERC20 (_name, _symbol, _decimals) {
        _mint(msg.sender, _initialSupply);
    }
}
