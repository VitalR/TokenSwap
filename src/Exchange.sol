// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "openzeppelin-contracts/token/ERC20/IERC20.sol";

contract Exchange {
    address public token;

    constructor(address _token) {
        require(_token != address(0), "Invalid token address");

        token = _token;
    }

    function addLiquidity(uint tokenAmount) public payable {
        if (getReserve() == 0) {
            IERC20(token).transferFrom(msg.sender, address(this), tokenAmount);
        } else {
            uint ethReserve = address(this).balance;
            uint tokenReserve = getReserve();
            uint tokenAmount_ = (msg.value * tokenReserve) / ethReserve;
            require(tokenAmount >= tokenAmount_, "Insufficient token amount");

            IERC20(token).transferFrom(msg.sender, address(this), tokenAmount_);
        }
    }

    function getReserve() public view returns (uint) {
        return IERC20(token).balanceOf(address(this));
    }

    function getPrice(uint inputReserve, uint outputReserve) public pure returns (uint) {
        require(inputReserve > 0 && outputReserve > 0, "Invalid reserves");

        return (inputReserve * 1000) / outputReserve;
    }

    function getOutputAmount(
        uint inputAmount,
        uint inputReserve,
        uint outputReserve
    ) private pure returns (uint) {
        require(inputReserve > 0 && outputReserve > 0, "Invalid reserves");

        return (outputReserve * inputAmount) / (inputReserve + inputAmount);
    }

    function getTokenAmount(uint etherSold) public view returns (uint) {
        require(etherSold > 0, "etherSold is too small");

        uint tokenReserve = getReserve();

        return getOutputAmount(etherSold, address(this).balance, tokenReserve);
    }

    function getEtherAmount(uint tokenSold) public view returns (uint) {
        require(tokenSold > 0, "tokenSold is too small");

        uint tokenReserve = getReserve();

        return getOutputAmount(tokenSold, tokenReserve, address(this).balance);
    }

    function ethToTokenSwap(uint minTokens) public payable {
        uint tokenReserve = getReserve();
        uint tokenBought = getOutputAmount(msg.value, address(this).balance - msg.value, tokenReserve);

        require(tokenBought >= minTokens, "Insufficient output token amount");

        IERC20(token).transfer(msg.sender, tokenBought);
    }

    function tokenToEthSwap(uint tokenSold, uint minEth) public {
        uint tokenReserve = getReserve();
        uint ethBought = getOutputAmount(tokenSold, tokenReserve, address(this).balance);

        require(ethBought >= minEth, "Insufficient output ether amount");

        IERC20(token).transferFrom(msg.sender, address(this), tokenSold);
        payable(msg.sender).transfer(ethBought);
    }
}
