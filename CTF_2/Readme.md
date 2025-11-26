This challenge provides a vulnerable lending protocol and supporting contracts. Your goal is to analyze the system, understand the flaw, and demonstrate how an attacker can bankrupt the Lender contract.

This README explains the environment, the contracts involved, and what the interviewer expects from you.



## Objective

Inside the `Setup` contract, the system is considered solved if:
```solidity
    function isSolved() public view returns (bool) {
        return weth.balanceOf(address(lender)) < 2 ether;
    }

```
You must drain the `Lender` contract so that its WETH balance drops below 2 ETH. This means the attack should ultimately make the `Lender` insolvent.

```solidity
   Setup.isSolved() == true
```
Use a Foundry test to simulate the full exploit flow.

## Project Structure
.
├── src/
│   ├── Lender.sol
│   ├── Setup.sol
│  
│
└── test/
    └── Exploit.t.sol   ← implement your exploit here


## Steps

1. Install & Initialize Foundry
2. Running the Test Suite
   ```sh
    forge test -vvv --fork-url ...
   ```
   Your goal is to complete the exploit so the final assertion passes:
   ```solidity
   assertTrue(setup.isSolved(), "Challenge not solved");
   ```
3. What You Need to Implement
   Inside `test/Exploit.t.sol`, you will fill in the exploit logic.

```solidity
    // SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/Setup.sol";

contract ExploitTest is Test {
    
    // Your exploit logic goes here...

    function setUp() public {
        // Your exploit logic goes here...
    }

    function testExploit() public {
        // Your exploit logic goes here...
        
        // Assert condition
        assertTrue(setup.isSolved(), "Challenge not solved");
    }
}

```
