// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../contracts/MockPriceFeed.sol";
import "../contracts/MockTWAPFeed.sol";
import "../contracts/OracleMonitorV2.sol";
import "../contracts/SimpleLendingProtocolV2.sol";

contract OracleMonitorV2Test {

    function testFlashSpikeBlockedByMonitor() public {
        int256 truePrice = 100;

        // -------------------------------
        // Deploy mock spot oracles
        // -------------------------------
        MockPriceFeed o1 = new MockPriceFeed(truePrice);
        MockPriceFeed o2 = new MockPriceFeed(truePrice);
        MockPriceFeed o3 = new MockPriceFeed(truePrice);

        // -------------------------------
        // Deploy mock TWAP oracle
        // -------------------------------
        MockTWAPFeed twap = new MockTWAPFeed(truePrice);

        // -------------------------------
        // Deploy V2 oracle monitor
        // -------------------------------
        OracleMonitorV2 monitor =
            new OracleMonitorV2(
                IPriceFeed(o1),
                IPriceFeed(o2),
                IPriceFeed(o3),
                IPriceFeed(o1),   // spot price source
                ITwapFeed(twap),  // TWAP source
                500,  // cross-oracle threshold = 5%
                300,  // spot vs TWAP threshold = 3%
                5     // TWAP slope threshold (bps/sec)
            );

        // -------------------------------
        // Deploy lending protocol (V2)
        // -------------------------------
        SimpleLendingProtocolV2 protocol =
            new SimpleLendingProtocolV2(
                IPriceFeed(o1),
                IOracleMonitor(address(monitor))
            );

        protocol.depositCollateral(1);

        // ===============================
        // NORMAL CASE (no attack)
        // ===============================
        o1.setPrice(truePrice);
        o2.setPrice(truePrice);
        o3.setPrice(truePrice);
        twap.setTWAP(truePrice);

        bool anomaly = monitor.check();
        require(!anomaly, "Normal prices should not trigger anomaly");

        // ===============================
        // ATTACK: Flash price spike
        // ===============================
        o1.setPrice(truePrice * 2);   // spot manipulated
        // TWAP does NOT move (flash loan attack)
        twap.setTWAP(truePrice);

        // Monitor should detect anomaly
        anomaly = monitor.check();
        require(anomaly, "Flash spike should be detected");

        // Borrow should now be BLOCKED
        bool reverted;
        try protocol.borrow() {
            reverted = false;
        } catch {
            reverted = true;
        }

        require(reverted, "Borrow should be blocked due to oracle anomaly");
    }
}