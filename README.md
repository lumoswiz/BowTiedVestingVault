# Vesting Vault Exercise

**Inspired by a [BowTiedPickle](https://twitter.com/BowTiedPickle/status/1577320682395951109/photo/1) twitter post.**

## Setup

- Install [Foundry](https://github.com/foundry-rs/foundry).
- To run the all tests, in CL enter:

```sh
forge test
```

- To run a specific test (with stack and setup traces displayed):

```sh
forge test --match-test [TEST_NAME_HERE] -vvvvv
```

## Exercise Description

The core problem involves creating a vesting vault with the following characteristics:

- [x] One beneficiary, set on construction.
- [x] One time function to fund the vault with ERC-20 tokens and set an unlock time.
- [x] Only the owner can call fund.
- [x] Beneficiary can only withdraw after unlock time.

Bonus problems:

- [x] Maximum vesting duration.
- [x] Ability to also vest ETH. _My solution involves vesting WETH_.
- [ ] Vesting curves (linear, linear with a cliff, etc). _To do._

Contract can be found [here](./src/VestingVault.sol).

## Testing

Implemented [tests](./test/VestingVault.t.sol) for:

- Deploying the vault: `testDeployVault`
- Funding the vault by the owner: `testFundVault`
- Funding the vault cannot be done by another user: `testUserCannotFundVault`
- The vault unlock time cannot exceed the maximum duration: `testVaultEndTimestampLtMaxDuration`
- Beneficiary can withdraw from the vault after the unlock time: `testBeneficiaryCanWithdrawFromVault`
