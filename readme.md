# Capture The Flag Audit Report
## 1. Summary

This document presents a security review conducted by **[Bayou020](https://www.github.com/bayou020)** on the Solidity-based [Capture The Flag challenges](https://github.com/ewagmig/ctf_solidity/tree/master).

The purpose of this assessment is to:

1. Analyze each in-scope CTF challenge.
2. Identify vulnerabilities, flawed assumptions, or unsafe design choices.
3. Demonstrate exploitability through a proof-of-concept (PoC) such that the final assertion holds:

  ```solidity
   assertTrue(setup.isSolved(), "Challenge not solved");
   ```
4. Provide security observations and practical recommendations to eliminate or mitigate each weak point.

The review focuses exclusively on the challenge implementation and their associated setup contracts.
# 2. In Scope
Three challenges were included in scope.
Each reference below includes the file paths and the associated commit hash [b9d46df](https://github.com/ewagmig/ctf_solidity/commit/b9d46df5efb42d9cf9e55cf8fce3664b030647e2) to guarantee reproducibility.
### CTF 2
#### Files Reviewed
- [Lender.sol](https://github.com/ewagmig/ctf_solidity/tree/master/CTF_2/src/Lender.sol)  
- [Setup.sol](https://github.com/ewagmig/ctf_solidity/tree/master/CTF_2/src/Setup.sol) 
#### Commit [b9d46df](https://github.com/ewagmig/ctf_solidity/commit/b9d46df5efb42d9cf9e55cf8fce3664b030647e2)
### CTF 3
#### Files Reviewed
- [SafeLender.sol](https://github.com/ewagmig/ctf_solidity/blob/master/CTF_3/src/SafeLender.sol) 
- [Setup.sol](https://github.com/ewagmig/ctf_solidity/tree/master/CTF_3/src/Setup.sol) 
#### Commit [b9d46df](https://github.com/ewagmig/ctf_solidity/commit/b9d46df5efb42d9cf9e55cf8fce3664b030647e2)
### CTF 7
- [Governance.sol](https://github.com/ewagmig/ctf_solidity/blob/master/CTF_7/src/Governance.sol) 
- [Masterchef.sol](https://github.com/ewagmig/ctf_solidity/blob/master/CTF_7/src/Masterchef.sol) 
- [Setup.sol](https://github.com/ewagmig/ctf_solidity/tree/master/CTF_7/src/Setup.sol) 
##### Commit [b9d46df](https://github.com/ewagmig/ctf_solidity/commit/b9d46df5efb42d9cf9e55cf8fce3664b030647e2)
# 3. Findings
## 3.1 CTF 2
### Price Oracle Manipulation
 #### Severity: High
 #### Status: **Exploited**
 **Files Affected** 
`src/Lender.sol`

**Description**: The `Lender.rate` function L34 simply divides the WETH reserve by the ERC20 reserve from the Uniswap pair instead of using TWAP or Trusted Oracle. The exploit Contract uses the flash loan to temporarily skew the pair reserves via a large swap, which collapses the apparent rate, lets the attacker borrow the full `safeDebt` amount, and liquidate enough collateral to drain WETH before the price normalizes.

**Proof**:
- Setup Contract deposits 25 WETH and 500000 tokens into the pair before the challenge begins, so the lender’s initial rate is 500000/25 = 20000 tokens per WETH and a 1 WETH deposit permits borrowing `safeDebt = 1 * rate * 2 / 3 ≈ 13333` tokens.
- In `receiveFlashLoan` the attacker deposits 1 WETH, borrows those 13333 tokens, and swaps the remaining 999 WETH for tokens through `_swapWethForToken`, which uses `_getAmountOut` . The swap drains 487759 tokens from the pool, leaving ≈ 12241 tokens and ≈ 1024 WETH in the reserves, so the new rate becomes ≈ 12241/1024 ≈ 11.9 tokens per WETH.
- After the swap, `safeDebt` falls to ≈ 8 tokens while the debt ledger still reads ≈ 13333 tokens, satisfying `Lender.liquidate`’s overcollateralization guard. Repaying `lenderBalance * rateAfter` (≈ 26 WETH * 11.9 ≈ 311 tokens) withdraws around 25.7 WETH, leaving the lender almost empty as the setup proves.



**Testing**: Running `forge test` passes and confirms `Setup.isSolved()` becomes true after the flash‑loan-driven swap/liquidation. Execution traces show the flash loan, swap, liquidation, unwind, and final `WETH9::balanceOf(lender)` returning `0`, which matches the provided log excerpt.

**Recommendation**: Use Uniswap TWAP mechanism, or use Trusted oracles.

### Missing Input Validation
 #### Severity: low
 **Files Affected** 
`src/Lender.sol`

**Description**: It's important to validate inputs, even if they only come from trusted addresses, to avoid human error. The following inputs should be validated:

- `Lender.safeDebt(address user)`
        - Validate that `user` isn't a 0 address in the beginning of the function.
- `Lender.borrow(uint256 amount)` and `Lender.repay(uint256 amount)`
        - Reject zero amount loans/repayments or unwrap to `require(amount > 0)` so accounting stays consistent and underflow becomes impossible even if a faulty caller manipulates allowances.

**Recommendation**: Require non-zero addresses and amounts before touching state, and fail early rather than letting downstream calculations rely on implicit behavior.

### Missing Transfer Return Checks
 #### Severity: info
 **Files Affected**
`src/Lender.sol`

**Description**:  `Lender` call ERC-20 transfer or approval functions without checking the returned `bool`. `Lender` uses `token.transfer`, `token.transferFrom`, and WETH transfers inside its lending logic. 
**Recommendation**: For good practice, use `SafeERC20`, so the transaction reverts immediately on failed transfers/approvals and the state remains deterministic for auditing.


### Missing Event Support
 #### Severity: Info
 **Files Affected**
`src/Lender.sol`

**Description**: `Lender` exposes no events around deposits, borrows, repayments, withdrawals, or liquidations. Without emitted events it becomes difficult to correlate the price-swing flash loan with the on-chain state changes during post-mortems or alerting systems.

**Recommendation**: Define and emit the following events:
- `event Deposited(address indexed user, uint256 amount, uint256 totalCollateral)` right after collateral is pulled in `deposit`.
- `event Withdrawn(address indexed user, uint256 amount, uint256 remainingCollateral)` in `withdraw`.
- `event Borrowed(address indexed user, uint256 amount, uint256 totalDebt)` in `borrow`.
- `event Repaid(address indexed user, uint256 amount, uint256 remainingDebt)` in `repay`.
- `event Liquidated(address indexed user, uint256 amount, uint256 collateralReturned)` in `liquidate`.


## 3.2 CTF 3
 ### Flash Loan Repayment Guard
  #### Severity: High
#### Status: **Exploited**
  **Files Affected** 
`src/SafeLender.sol`

**Description**: `SafeLender.flashLoan` lets the borrower specify both the target and calldata, so the lender performs arbitrary calls from its own context before verifying repayment. The only incentive for repayment is the balance check after the call, but an **attacker that obtains approval can still transfer WETH out of the lender** after the execution of the `flashLoan` function while satisfying `newBalance >= balanceBefore` by repaying only part of the owed amount or by minting/burning tokens from the borrowed contract.

**Proof**:
- `ExploitTest` Attacking contract calls `safeLender.flashLoan(0, address(weth), abi.encodeWithSignature("approve(address,uint256)", address(this), type(uint256).max))`. Because the flash loan runs the borrower-controlled call while `SafeLender` is the caller, the WETH contract approves the attacker for unlimited allowance **from the lender’s balance**, even though no WETH leaves the lender.
- After the flash loan returns, the attacker simply reads `weth.balanceOf(address(safeLender))` and executes `weth.transferFrom(address(safeLender), address(this), lenderBalance)`, draining the entire pool; `Setup.isSolved()` returns `True` then reports the lender empty.

**Testing**: Running `forge test` passes and confirms `Setup.isSolved()` becomes true after the `WETH9::transferFrom` draining all WETH from `SafeLender` Contract. 

**Recommendation**: Restrict the external call (let the borrower pull funds back) and track repayments explicitly instead of relying on the post-call balance check; disallow borrower-controlled calldata and approvals so the pool can’t grant itself allowances.

## 3.3 CTF 7
 ### Emergency Withdraw Double Counting
  #### Severity: High
  #### Status: **Exploited**
  **Files Affected** 
`src/Masterchef.sol`, `src/Governance.sol`

**Description**: `MasterChef.emergencyWithdraw` copies `PoolInfo` and `UserInfo` to memory, returns the user’s entire balance, but never updates the storage entries or emits a control flag. Repeating deposit/emergencyWithdraw keeps the recorded stake even after withdrawal, letting the exploit grow the attacker’s apparent stake until it controls >2/3 of votes, becomes `ValidatorOwner`, and flips the governance flag.

**Proof**:
- `masterChef.airdrop()` gives the attacker 1 token; `_growStake` then deposits and calls `emergencyWithdraw` which does not update the storage (The variables `poolInfo` and `UserInfo` are in **Memory**), so `balanceOf(attacker)` stays high and the loop keeps inflating the recorded stake.
- `_finalizeLoot()` confirms the stale storage, withdraws the inflated amount (~1M tokens), and distributes it across `VoteProxy` contracts that vote until `validatorVotes[attacker] >= totalSupply * 2/3`.
- Once the threshold is met, `governance.setValidator()` makes the attacker `ValidatorOwner` and `governance.setflag()` emits `Sendflag`, so `Setup.isSolved()` returns true.


**Recommendation**: Update `emergencyWithdraw` to mutate storage directly (`UserInfo storage user = userInfo[_pid][msg.sender]` and `PoolInfo storage pool = poolInfo[_pid]`), zero the staker’s recorded `amount`/`rewardDebt`, and ensure `pool.totalstake` decreases so the contract cannot double-count stakes; additionally, add a flag or reentrancy guard that prevents repeated deposit/withdraw cycles from counting the same tokens as fresh voting power.


 ### Reeantrant Functionalities
  #### Severity: info
  **Files Affected** 
`src/Masterchef.sol`, `src/Governance.sol`

**Description**:`MasterChef.airdrop`,`MasterChef.deposit`,`MasterChef.Withdraw`,`MasterChef.emergencyWithdraw`,`Governance.vote`  are missing non reeantrant flag, that could lead into fast reapeated deposit/withdraw cycles.


**Recommendation**: Add a non-reentrancy guard or short timestamp lock on `airdrop`, `deposit`, `withdraw`, `emergencyWithdraw`, and `governance.vote` so the attacker cannot spin rapid loops that replay the same tokens into the voting snapshot.

 ### Obsolete Solidity version
  #### Severity: info
  **Files Affected** 
`ctf_solidity/CTF_7/src/Masterchef.sol`, `ctf_solidity/CTF_7/src/Governance.sol`

**Description**: These contracts still `pragma solidity 0.6.12`, so they lack the safety improvements (built-in overflow checks, improved ABI encoder, etc.) and ergonomic syntax introduced in the 0.8.x series.

**Recommendation**: Upgrade the contracts to a recent stable compiler (>=0.8.0).

# 4. Conclusion

All reviewed CTF challenges contained exploitable vulnerabilities affecting loan safety, asset integrity, or governance correctness.
The provided PoCs successfully exploited each vulnerability, and
`setup.isSolved()` was satisfied in every case.
The recommended changes—safe pricing mechanisms, strict flash-loan accounting, correct storage management, and general best practices—are sufficient to mitigate the identified issues.