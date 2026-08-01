# CrowdFunding Smart Contract (Foundry)

A decentralized crowdfunding smart contract developed in **Solidity** and thoroughly tested using **Foundry**. This project demonstrates secure smart contract development, comprehensive testing methodologies, and security analysis using industry-standard tools.

---

## Overview

This smart contract allows users to create decentralized crowdfunding campaigns where contributors can fund a project until a target amount is reached before a specified deadline.

If the funding target is achieved, the project manager can create spending requests, contributors can vote on those requests, and approved requests can be executed.

If the funding target is not achieved before the deadline, contributors are able to claim refunds.

---

## Features

- Create crowdfunding campaign
- Minimum contribution requirement
- Track contributors and total funds raised
- Funding deadline
- Funding target
- Refund mechanism
- Spending request creation
- Contributor voting system
- Majority voting before payment execution
- Access control (Manager-only functions)

---

## Smart Contract Functions

### Contribution
- Contribute ETH to the campaign
- Tracks contributor balances
- Updates total raised amount

### Refund
- Allows contributors to withdraw funds
- Available only after deadline if target is not achieved

### Create Request
Manager can create spending requests including:
- Description
- Recipient
- Requested amount

### Vote Request
- Contributors vote on spending requests
- Double voting is prevented

### Make Payment
- Manager executes payment
- Requires majority approval
- Prevents duplicate execution

---

## Project Structure

```
CrowdFunding-Foundry
│
├── src
│   └── CrowdFunding.sol
│
├── test
│   ├── CrowdFundingTest.t.sol
│   ├── AccessControlTest.t.sol
│   ├── CrowdFundingFuzzTest.t.sol
│   ├── CrowdFundingInvariantTest.t.sol
│   └── ReentrancyAttacker
│       ├── ReentrancyAttacker.sol
│       └── CrowdFundingSecurityTest.t.sol
│
├── script
├── lib
├── foundry.toml
└── README.md
```

---

## Testing

The project includes multiple categories of tests.

### Unit Tests

- Constructor
- Contribution
- Refund
- Create Request
- Voting
- Payment Execution
- Access Control

### Fuzz Tests

Randomized input testing for:

- Contributions
- Payment execution
- State validation

### Invariant Tests

Ensures important protocol properties always remain true during execution.

### Security Tests

Includes a simulated reentrancy attacker contract to validate contract behavior against common attack vectors.

---

## Static Analysis

Security analysis performed using **Slither**.

Example findings:

- Reentrancy detection
- Timestamp dependency
- Boolean comparison improvements
- Immutable variable suggestions
- Naming convention improvements
- Low-level call warnings

---

## Tech Stack

- Solidity
- Foundry
- Forge
- Slither
- OpenZeppelin Contracts

---

## Running Locally

Clone the repository

```bash
git clone https://github.com/tapan79/CrowdFunding-Foundry.git
```

Install dependencies

```bash
forge install
```

Compile

```bash
forge build
```

Run all tests

```bash
forge test
```

Run tests with verbosity

```bash
forge test -vvvv
```

Generate gas report

```bash
forge test --gas-report
```

Run Slither

```bash
python -m slither .
```

---

## Security Concepts Covered

- Access Control
- Reentrancy
- Checks-Effects-Interactions Pattern
- Refund Logic
- Majority Voting
- State Validation
- Fuzz Testing
- Invariant Testing
- Static Analysis

---

## Future Improvements

- Multiple crowdfunding campaigns
- Event logging
- Custom errors
- Gas optimization
- NatSpec documentation
- Chainlink integration
- Upgradeable architecture

---

## Author

**Tapan Preshwala**

**Smart Contract Security** and **Blockchain Auditing**.

Skills:

- Solidity
- Foundry
- Smart Contract Security
- Fuzz Testing
- Invariant Testing
- Slither
- Ethereum
- DeFi Security

GitHub:
https://github.com/tapan79

LinkedIn:
https://www.linkedin.com/in/tapan-p-a73792344

---

## License

MIT
