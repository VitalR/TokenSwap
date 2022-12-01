// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "solmate/tokens/ERC20.sol";

contract MintableERC20 is ERC20 {
    constructor(
        string memory _name,
        string memory _symbol, 
        uint8 _decimals
    ) ERC20 (_name, _symbol, _decimals) {}

    function mint(address _to, uint _amount) public {
        _mint(_to, _amount);
    }
}
