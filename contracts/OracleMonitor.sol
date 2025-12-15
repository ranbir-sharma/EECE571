// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./IPriceFeed.sol";

contract OracleMonitor {

    IPriceFeed public feed1;
    IPriceFeed public feed2;
    IPriceFeed public feed3;

    uint256 public thresholdBps; // 500 = 5%

    event AnomalyDetected(int256 p1, int256 p2, int256 p3, int256 median, uint256 timestamp);
    event PricesOK(int256 p1, int256 p2, int256 p3, int256 median, uint256 timestamp);

    constructor(
        IPriceFeed _feed1,
        IPriceFeed _feed2,
        IPriceFeed _feed3,
        uint256 _thresholdBps
    ) {
        feed1 = _feed1;
        feed2 = _feed2;
        feed3 = _feed3;
        thresholdBps = _thresholdBps;
    }

    function check() external returns (bool) {
        int256 p1 = feed1.latestPrice();
        int256 p2 = feed2.latestPrice();
        int256 p3 = feed3.latestPrice();

        int256 median = _median(p1, p2, p3);

        bool anomaly = _hasOutlier(p1, median)
                    || _hasOutlier(p2, median)
                    || _hasOutlier(p3, median);

        if (anomaly) {
            emit AnomalyDetected(p1, p2, p3, median, block.timestamp);
        } else {
            emit PricesOK(p1, p2, p3, median, block.timestamp);
        }

        return anomaly;
    }

    function _median(int256 a, int256 b, int256 c) internal pure returns (int256) {
        // return median of 3 numbers
        if ((a >= b && a <= c) || (a >= c && a <= b)) return a;
        if ((b >= a && b <= c) || (b >= c && b <= a)) return b;
        return c;
    }

    function _hasOutlier(int256 p, int256 m) internal view returns (bool) {
        if (m == 0) return false;
        uint256 diff = _abs(p - m);
        uint256 bps = (diff * 10000) / _abs(m);
        return bps > thresholdBps;
    }

    function _abs(int256 x) internal pure returns (uint256) {
        return uint256(x >= 0 ? x : -x);
    }
}