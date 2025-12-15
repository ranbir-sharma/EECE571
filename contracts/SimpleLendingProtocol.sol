// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./IPriceFeed.sol";

contract SimpleLendingProtocol {

    IPriceFeed public oracle;
    uint256 public collateral;
    uint256 public debt;
    uint256 public ltvBps = 7000; // 70%

    constructor(IPriceFeed _oracle) {
        oracle = _oracle;
    }

    function depositCollateral(uint256 amount) external {
        collateral += amount;
    }

    function borrow() external {
        int256 p = oracle.latestPrice();
        // bool anomaly = oracle.check();
        // require(!oracle.check(), "Oracle anomaly detected");
        require(p > 0, "Invalid price");

        uint256 value = uint256(p) * collateral;
        uint256 maxBorrow = (value * ltvBps) / 10_000;

        debt += maxBorrow;
    }

    // used only in testing to check if attack succeeded
    function isUnderCollateralized(int256 truePrice) external view returns (bool) {
        uint256 trueValue = uint256(truePrice) * collateral;
        uint256 required = (trueValue * ltvBps) / 10_000;
        return debt > required;
    }
}