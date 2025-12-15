// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./IPriceFeed.sol";

interface IOracleMonitor {
    function check() external returns (bool);
}

contract SimpleLendingProtocolV2 {
    IPriceFeed public oracle;         // spot price used for value
    IOracleMonitor public monitor;    // your POMA monitor

    uint256 public collateral;
    uint256 public debt;
    uint256 public ltvBps = 7000; // 70%

    constructor(IPriceFeed _oracle, IOracleMonitor _monitor) {
        oracle = _oracle;
        monitor = _monitor;
    }

    function depositCollateral(uint256 amount) external {
        collateral += amount;
    }

    function borrow() external {
        // 🔥 the key defense: refuse to borrow if oracle looks manipulated
        require(!monitor.check(), "Oracle anomaly detected");

        int256 p = oracle.latestPrice();
        require(p > 0, "Invalid price");

        uint256 value = uint256(p) * collateral;
        uint256 maxBorrow = (value * ltvBps) / 10_000;

        debt += maxBorrow;
    }

    function isUnderCollateralized(int256 truePrice) external view returns (bool) {
        uint256 trueValue = uint256(truePrice) * collateral;
        uint256 required = (trueValue * ltvBps) / 10_000;
        return debt > required;
    }
}