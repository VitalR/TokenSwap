// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "openzeppelin-contracts/token/ERC20/IERC20.sol";

contract Exchange {
    address public token;

    constructor(address _token) {
        require(_token != address(0), "Invalid token address");

        token = _token;
    }

    function addLiquidity(uint256 _amount) public payable {
        IERC20(token).transferFrom(msg.sender, address(this), _amount);
    }

    function getReserve() public view returns (uint256) {
        return IERC20(token).balanceOf(address(this));
    }

    function getPrice(uint256 inputReserve, uint256 outputReserve)
        public
        view
        returns (uint256)
    {
        require(inputReserve > 0 && outputReserve > 0, "Invalid reserves");

        return (inputReserve * 1000) / outputReserve;
    }

    function getOutputAmount(
        uint256 inputAmount,
        uint256 inputReserve,
        uint256 outputReserve
    ) private pure returns (uint256) {
        require(inputReserve > 0 && outputReserve > 0, "Invalid reserves");

        return (outputReserve * inputAmount) / (inputReserve + inputAmount);
    }

    function getTokenAmount(uint256 etherSold) public view returns (uint256) {
        require(etherSold > 0, "etherSold is too small");

        uint256 tokenReserve = getReserve();

        return getOutputAmount(etherSold, address(this).balance, tokenReserve);
    }

    function getEtherAmount(uint256 tokenSold) public view returns (uint256) {
        require(tokenSold > 0, "tokenSold is too small");

        uint256 tokenReserve = getReserve();

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
