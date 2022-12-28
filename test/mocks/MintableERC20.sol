// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "solmate/tokens/ERC20.sol";

contract MintableERC20 is ERC20 {
    constructor(
        string memory _name,
        string memory _symbol
    ) ERC20 (_name, _symbol, 18) {}

    function mint(address _to, uint _amount) public {
        _mint(_to, _amount);
    }
}
