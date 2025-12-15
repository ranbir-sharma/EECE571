// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ITwapFeed.sol";

contract MockTWAPFeed is ITwapFeed {
    int256 private twap;
    uint256 private t;

    constructor(int256 _initialTWAP) {
        twap = _initialTWAP;
        t = block.timestamp;
    }

    function setTWAP(int256 _twap) external {
        twap = _twap;
        t = block.timestamp;
    }

    function setTWAPWithTime(int256 _twap, uint256 _time) external {
        twap = _twap;
        t = _time;
    }

    function latestTWAP() external view override returns (int256) {
        return twap;
    }

    function lastUpdateTime() external view override returns (uint256) {
        return t;
    }
}