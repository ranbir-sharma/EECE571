// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./IPriceFeed.sol";

contract MockPriceFeed is IPriceFeed {
    int256 private price;

    constructor(int256 _initial) {
        price = _initial;
    }

    function setPrice(int256 _price) external {
        price = _price;
    }

    function latestPrice() external view override returns (int256) {
        return price;
    }
}