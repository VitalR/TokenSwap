// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "openzeppelin-contracts/token/ERC20/ERC20.sol";
import "openzeppelin-contracts/token/ERC20/IERC20.sol";

interface IFactory {
    function getExchange(address token) external view returns (address);
}

interface IExchange {
    function balanceOf(address account) external view returns (uint256);
    function addLiquidity(uint256 tokenAmount) external payable returns (uint256);
    function ethToTokenSwap(uint256 minTokens) external payable;
    function ethToTokenTransfer(uint minTokens, address recipient) external payable;
    function tokenToTokenSwap(uint tokenSold, uint minTokenBought, address tokenBought) external;
}

contract Exchange is ERC20 {
    address public token;
    address public factory;

    constructor(address token_) ERC20("Swap-V1", "SWP-V1") {
        require(token_ != address(0), "constructor::Invalid token address");

        token = token_;
        factory = msg.sender;
    }

    function addLiquidity(uint256 tokenAmount)
        public
        payable
        returns (uint256)
    {
        if (getReserve() == 0) {
            IERC20(token).transferFrom(msg.sender, address(this), tokenAmount);

            uint256 liquidity = address(this).balance;
            _mint(msg.sender, liquidity);

            return liquidity;
        } else {
            uint256 ethReserve = address(this).balance;
            uint256 tokenReserve = getReserve();
            uint256 tokenAmount_ = (msg.value * tokenReserve) / ethReserve;
            require(tokenAmount >= tokenAmount_, "addLiquidity::Insufficient token amount");

            IERC20(token).transferFrom(msg.sender, address(this), tokenAmount_);

            uint256 lpTotalAmount = totalSupply();
            uint256 liquidity = (lpTotalAmount * msg.value) / ethReserve;
            _mint(msg.sender, liquidity);

            return liquidity;
        }
    }

    function removeLiquidity(uint256 lpAmount)
        public
        returns (uint256, uint256)
    {
        require(lpAmount > 0, "removeLiquidity::Invalid token amount");

        uint256 lpTotalAmount = totalSupply();
        uint256 ethAmount = (address(this).balance * lpAmount) / lpTotalAmount;
        uint256 tokenAmount = (getReserve() * lpAmount) / lpTotalAmount;

        _burn(msg.sender, lpAmount);
       
        IERC20(token).transfer(msg.sender, tokenAmount);
        (bool success, ) = payable(msg.sender).call{value: ethAmount}("");
        require(success, "removeLiquidity::withdraw failed");

        return (ethAmount, tokenAmount);
    }

    function tokenToTokenSwap(uint tokenSold, uint minTokenBought, address tokenBought) public {
        address exchange = IFactory(factory).getExchange(tokenBought);
        require(exchange != address(this) && exchange != address(0), "tokenToTokenSwap::Invalid exchange address");

        uint tokenReserve = getReserve();
        uint ethBought = getOutputAmount(tokenSold, tokenReserve, address(this).balance);   

        IERC20(token).transferFrom(msg.sender, address(this), tokenSold);
        IExchange(exchange).ethToTokenTransfer{ value: ethBought }(minTokenBought, msg.sender);
    }

    function ethToToken(uint256 minTokens, address recipient) private {
        uint256 tokenReserve = getReserve();
        uint256 tokenBought = getOutputAmount(
            msg.value,
            address(this).balance - msg.value,
            tokenReserve
        );

        require(tokenBought >= minTokens, "ethToToken::Insufficient output token amount");

        IERC20(token).transfer(recipient, tokenBought);
    }

    function ethToTokenSwap(uint minTokens) public payable {
        ethToToken(minTokens, msg.sender);
    }

    function ethToTokenTransfer(uint minTokens, address recipient) public payable {
        ethToToken(minTokens, recipient);
    }

    function tokenToEthSwap(uint256 tokenSold, uint256 minEth) public {
        uint256 tokenReserve = getReserve();
        uint256 ethBought = getOutputAmount(
            tokenSold,
            tokenReserve,
            address(this).balance
        );

        require(ethBought >= minEth, "tokenToEthSwap::Insufficient output ether amount");

        IERC20(token).transferFrom(msg.sender, address(this), tokenSold);
        payable(msg.sender).transfer(ethBought);
    }

    function getReserve() public view returns (uint256) {
        return IERC20(token).balanceOf(address(this));
    }

    function getPrice(uint256 inputReserve, uint256 outputReserve)
        public
        pure
        returns (uint256)
    {
        require(inputReserve > 0 && outputReserve > 0, "getPrice::Invalid reserves");

        return (inputReserve * 1000) / outputReserve;
    }

    function getTokenAmount(uint256 etherSold) public view returns (uint256) {
        require(etherSold > 0, "getTokenAmount::etherSold is too small");

        uint256 tokenReserve = getReserve();

        return getOutputAmount(etherSold, address(this).balance, tokenReserve);
    }

    function getEtherAmount(uint256 tokenSold) public view returns (uint256) {
        require(tokenSold > 0, "getEtherAmount::tokenSold is too small");

        uint256 tokenReserve = getReserve();

        return getOutputAmount(tokenSold, tokenReserve, address(this).balance);
    }

    function getOutputAmount(
        uint256 inputAmount,
        uint256 inputReserve,
        uint256 outputReserve
    ) private pure returns (uint256) {
        require(inputReserve > 0 && outputReserve > 0, "getOutputAmount::Invalid reserves");

        uint256 inputAmountWithFees = inputAmount * 99; // inputAmount * (100 - fee), fee == 1 %
        uint256 numerator = outputReserve * inputAmountWithFees;
        uint256 denominator = (inputAmount * 100) + inputAmountWithFees;

        return numerator / denominator;
    }
}
