## Objective

Your task is to analyze the contracts, identify vulnerabilities, and craft an exploit that successfully activates the `governance` flag.
```solidity
  Setup.isSolved() == true
```
Use a Foundry test to simulate the full exploit flow.

## Project Structure
.
├── src/
│   ├── Governance.sol
│   ├── interface.sol
│   ├── Masterchef.sol
│   ├── Setup.sol
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
