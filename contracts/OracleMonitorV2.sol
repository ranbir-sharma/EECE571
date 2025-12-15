// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./IPriceFeed.sol";
import "./ITwapFeed.sol";

contract OracleMonitorV2{
    // --- Feeds ---
    IPriceFeed public feed1;
    IPriceFeed public feed2;
    IPriceFeed public feed3;

    IPriceFeed public spotFeed;   // can be one of feed1/feed2/feed3
    ITwapFeed  public twapFeed;

    // --- Thresholds ---
    uint256 public crossOracleThresholdBps; // e.g. 500 = 5%
    uint256 public spotTwapThresholdBps;    // e.g. 300 = 3%

    // TWAP slope threshold in BPS per second (scaled):
    // slopeBpsPerSec = (|twapNow - twapPrev| * 10_000) / |twapPrev| / dt
    uint256 public maxTwapSlopeBpsPerSec;   // e.g. 5 = 0.05%/sec (tune)

    // --- State for accumulator/slope test ---
    int256 public lastTWAP;
    uint256 public lastTWAPTime;
    bool public twapInitialized;

    // --- Events ---
    event AnomalyDetected(
        bool crossOracle,
        bool spotVsTwap,
        bool twapSlope,
        int256 p1,
        int256 p2,
        int256 p3,
        int256 median,
        int256 spot,
        int256 twap,
        uint256 timestamp
    );

    event PricesOK(
        int256 p1,
        int256 p2,
        int256 p3,
        int256 median,
        int256 spot,
        int256 twap,
        uint256 timestamp
    );

    constructor(
        IPriceFeed _feed1,
        IPriceFeed _feed2,
        IPriceFeed _feed3,
        IPriceFeed _spotFeed,
        ITwapFeed  _twapFeed,
        uint256 _crossOracleThresholdBps,
        uint256 _spotTwapThresholdBps,
        uint256 _maxTwapSlopeBpsPerSec
    ) {
        feed1 = _feed1;
        feed2 = _feed2;
        feed3 = _feed3;

        spotFeed = _spotFeed;
        twapFeed = _twapFeed;

        crossOracleThresholdBps = _crossOracleThresholdBps;
        spotTwapThresholdBps = _spotTwapThresholdBps;
        maxTwapSlopeBpsPerSec = _maxTwapSlopeBpsPerSec;
    }

    /// @notice Returns true if ANY anomaly test triggers.
    function check() external returns (bool) {
        int256 p1 = feed1.latestPrice();
        int256 p2 = feed2.latestPrice();
        int256 p3 = feed3.latestPrice();
        int256 med = _median3(p1, p2, p3);

        int256 spot = spotFeed.latestPrice();
        int256 twap = twapFeed.latestTWAP();

        bool crossOracle = _crossOracleDeviation(p1, p2, p3, med);
        bool spotVsTwap  = _spotVsTwapDeviation(spot, twap);
        bool twapSlope   = _twapAccumulatorSlope(twap);

        bool anomaly = crossOracle || spotVsTwap || twapSlope;

        if (anomaly) {
            emit AnomalyDetected(
                crossOracle,
                spotVsTwap,
                twapSlope,
                p1, p2, p3,
                med,
                spot,
                twap,
                block.timestamp
            );
        } else {
            emit PricesOK(p1, p2, p3, med, spot, twap, block.timestamp);
        }

        return anomaly;
    }

    // -------------------------
    // Test 1: Cross-oracle deviation
    // -------------------------
    function _crossOracleDeviation(int256 p1, int256 p2, int256 p3, int256 m) internal view returns (bool) {
        return _isOutlierBps(p1, m, crossOracleThresholdBps)
            || _isOutlierBps(p2, m, crossOracleThresholdBps)
            || _isOutlierBps(p3, m, crossOracleThresholdBps);
    }

    // -------------------------
    // Test 2: Spot vs TWAP stability
    // -------------------------
    function _spotVsTwapDeviation(int256 spot, int256 twap) internal view returns (bool) {
        // If twap is 0, skip (avoid division by 0)
        if (twap == 0) return false;

        uint256 diff = _abs(spot - twap);
        uint256 diffBps = (diff * 10_000) / _abs(twap);

        return diffBps > spotTwapThresholdBps;
    }

    // -------------------------
    // Test 3: TWAP accumulator/slope test
    // (limits how fast TWAP is allowed to move)
    // -------------------------
    function _twapAccumulatorSlope(int256 currentTWAP) internal returns (bool) {
        uint256 nowT = twapFeed.lastUpdateTime(); // use feed's reported time

        // First call initializes baseline
        if (!twapInitialized) {
            twapInitialized = true;
            lastTWAP = currentTWAP;
            lastTWAPTime = nowT;
            return false;
        }

        // If no time advanced, can't compute slope → don't flag
        if (nowT <= lastTWAPTime) {
            return false;
        }

        uint256 dt = nowT - lastTWAPTime;

        // If baseline TWAP is 0, reset baseline to avoid division by 0
        if (lastTWAP == 0) {
            lastTWAP = currentTWAP;
            lastTWAPTime = nowT;
            return false;
        }

        uint256 diff = _abs(currentTWAP - lastTWAP);

        // slopeBpsPerSec = (diff / |lastTWAP|) * 10000 / dt
        uint256 slopeBpsPerSec = (diff * 10_000) / _abs(lastTWAP) / dt;

        // update baseline
        lastTWAP = currentTWAP;
        lastTWAPTime = nowT;

        return slopeBpsPerSec > maxTwapSlopeBpsPerSec;
    }

    // -------------------------
    // Helpers
    // -------------------------
    function _isOutlierBps(int256 p, int256 m, uint256 thresholdBps) internal pure returns (bool) {
        if (m == 0) return false;
        uint256 diff = _abs(p - m);
        uint256 bps = (diff * 10_000) / _abs(m);
        return bps > thresholdBps;
    }

    function _median3(int256 a, int256 b, int256 c) internal pure returns (int256) {
        if ((a >= b && a <= c) || (a >= c && a <= b)) return a;
        if ((b >= a && b <= c) || (b >= c && b <= a)) return b;
        return c;
    }

    function _abs(int256 x) internal pure returns (uint256) {
        return uint256(x >= 0 ? x : -x);
    }
}