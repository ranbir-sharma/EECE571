// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ITwapFeed {
    // Current TWAP price (same units as spot)
    function latestTWAP() external view returns (int256);

    // When the TWAP value was last updated (seconds)
    function lastUpdateTime() external view returns (uint256);
}