# POMABuster-Style Detection of Oracle Manipulation in DeFi

This repository implements a **POMABuster-style oracle manipulation detection framework** for decentralized finance (DeFi) protocols. The system monitors multiple price sources and identifies anomalous price behavior using **cross-oracle deviation**, **spot vs. TWAP consistency**, and **TWAP rate-of-change constraints**. The detector is integrated with a simplified lending protocol to demonstrate how oracle manipulation attacks can be **detected and actively prevented**.

---

## Motivation

DeFi protocols rely heavily on price oracles to value assets, determine borrowing limits, and trigger liquidations. Manipulation of oracle prices—often enabled by flash loans and low-liquidity markets—has led to numerous real-world exploits and significant financial losses.

This project demonstrates that:
- Liquidity pools themselves cannot prevent price manipulation
- Oracles are a critical attack surface
- Protocols can defend themselves by **detecting abnormal oracle behavior** before executing sensitive actions such as borrowing

---

## Repository Structure
contracts/
├── IPriceFeed.sol
├── ITwapFeed.sol
├── MockPriceFeed.sol
├── MockTWAPFeed.sol
├── OracleMonitor.sol
├── OracleMonitorV2.sol
├── SimpleLendingProtocol.sol
└── SimpleLendingProtocolV2.sol

---

## Contract Overview

### Interfaces
- **IPriceFeed.sol**  
  Interface for spot price oracle feeds.

- **ITwapFeed.sol**  
  Interface for TWAP (Time-Weighted Average Price) oracle feeds.

### Mock Oracles
- **MockPriceFeed.sol**  
  Simulates a spot price oracle with manually adjustable prices.

- **MockTWAPFeed.sol**  
  Simulates a TWAP oracle with controllable price and timestamp, enabling temporal attack simulations.

### Oracle Monitors
- **OracleMonitor.sol**  
  Baseline monitor implementing **cross-oracle deviation detection** only.

- **OracleMonitorV2.sol**  
  Enhanced POMABuster-style monitor implementing:
  - Cross-oracle deviation detection  
  - Spot price vs. TWAP consistency checks  
  - TWAP accumulator (rate-of-change) constraints  

### Lending Protocols
- **SimpleLendingProtocol.sol**  
  Baseline lending protocol vulnerable to oracle manipulation.

- **SimpleLendingProtocolV2.sol**  
  Secured lending protocol that **blocks borrowing when oracle anomalies are detected**.

---

## Threat Model

The system considers adversaries capable of:
- Using flash loans to manipulate liquidity pool prices
- Temporarily inflating spot prices
- Attempting slow-drift TWAP manipulation

The monitor assumes:
- Oracle sources are not all compromised simultaneously
- At least one oracle provides an honest reference price

---

## Detection Design

The enhanced oracle monitor (`OracleMonitorV2`) performs three complementary checks:

1. **Cross-Oracle Deviation**  
   Detects disagreement between independent oracle price feeds.

2. **Spot vs. TWAP Consistency**  
   Detects short-lived price spikes characteristic of flash-loan-based attacks.

3. **TWAP Rate-of-Change (Accumulator Test)**  
   Detects slow, sustained price manipulation that evades instantaneous checks.

An anomaly is flagged if **any** test fails.

---

## Security Guarantees

With the enhanced monitor enabled:
- Flash-loan-based oracle manipulation attacks are detected
- Borrowing requests using manipulated prices are rejected
- Liquidity pool manipulation alone does not result in protocol loss

The framework does **not** attempt to prevent swaps or flash loans themselves; instead, it prevents **unsafe protocol decisions** based on manipulated oracle data.

---

## Overhead

- **Computation:** Constant-time checks (O(1))
- **Gas:** Modest overhead limited to oracle-dependent operations
- **Latency:** No additional block-level delay
- **Storage:** Minimal (TWAP baseline state only)

The design prioritizes protocol safety over short-term availability during extreme market conditions.

---

## Limitations

- Cannot detect coordinated majority-oracle compromise
- Effectiveness depends on oracle source independence
- Conservative thresholds may temporarily block legitimate borrowing during high volatility
- Does not attribute anomalies to specific attackers or attack mechanisms

---

## Use Cases

- Research and teaching demonstrations
- Prototyping oracle-aware DeFi protocols
- Security analysis of oracle manipulation defenses
- Comparative evaluation of oracle designs

---

## How to Use

1. Deploy mock oracles (`MockPriceFeed`, `MockTWAPFeed`)
2. Deploy `OracleMonitorV2` with appropriate thresholds
3. Deploy `SimpleLendingProtocolV2` using the monitor
4. Simulate normal operation and oracle manipulation scenarios
5. Observe borrowing behavior with and without anomaly detection

---

## License

This project is released under the **MIT License**.

---

## Acknowledgements

This work is inspired by prior research on oracle manipulation attacks, particularly **POMABuster**, and by real-world oracle designs used in protocols such as MakerDAO, Aave, and Chainlink.
