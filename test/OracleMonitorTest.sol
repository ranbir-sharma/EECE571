// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../contracts/MockPriceFeed.sol";
import "../contracts/OracleMonitor.sol";
import "../contracts/SimpleLendingProtocol.sol";

contract OracleMonitorTest {

    function testFlashSpikeDetected() public {
        int256 truePrice = 100;

        MockPriceFeed o1 = new MockPriceFeed(truePrice);
        MockPriceFeed o2 = new MockPriceFeed(truePrice);
        MockPriceFeed o3 = new MockPriceFeed(truePrice);

        OracleMonitor monitor =
            new OracleMonitor(
                IPriceFeed(o1),
                IPriceFeed(o2),
                IPriceFeed(o3),
                500  // 5%
            );

        SimpleLendingProtocol protocol =
            new SimpleLendingProtocol(IPriceFeed(o1));

        protocol.depositCollateral(1);

        // ---------------- Normal case ----------------
        o1.setPrice(truePrice);
        o2.setPrice(truePrice);
        o3.setPrice(truePrice);

        bool anomaly = monitor.check();
        require(!anomaly, "Normal case should NOT detect anomaly");

        // ---------------- Attack ----------------
        o1.setPrice(truePrice * 2);  
        protocol.borrow();      

        anomaly = monitor.check();
        require(anomaly, "Flash spike should be detected");

        bool unsafe = protocol.isUnderCollateralized(truePrice);
        require(unsafe, "Protocol should be under-collateralized after attack");
    }
}