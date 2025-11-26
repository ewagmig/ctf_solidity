Your task is to implement the exploit, and confirm that the challenge condition isSolved() returns true.

## Objective

To verify whether the `SafeLender` contract can be drained of all `WETH` such that:
```solidity
  Setup.isSolved() == true
```
Use a Foundry test to simulate the full exploit flow.

## Project Structure
.
├── src/
│   ├── SafeLender.sol
│   ├── Setup.sol
│   ├── ReentrancyGuard.sol
│
└── test/
    └── Exploit.t.sol   ← implement your exploit here


- SafeLender.sol: the vulnerable contract

- Setup.sol: deploys WETH, transfers funds, and exposes isSolved()

- Exploit.t.sol: Foundry test file where you will write the exploit

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
