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
forge test --match-contract [CONTRACT_NAME_HERE] --match-test [TEST_NAME_HERE] -vvvvv
```

## Exercise Description

The core problem involves creating a vesting vault with the following characteristics:

- One beneficiary, set on construction.
- One time function to fund the vault with ERC-20 tokens and set an unlock time.
- Only the owner can call fund.
- Beneficiary can only withdraw after unlock time.

Bonus problems:

- Maximum vesting duration.
- Ability to also vest ETH. _My solution involves vesting WETH_.
- Vesting curves (linear, linear with a cliff, etc). _To do._

Contract can be found [here](./src/VestingVault.sol).

## Feedback from Initial Implementation

Based on feedback from BowTiedPickle in this [thread](https://twitter.com/BowTiedPickle/status/1578870209850458112), the following issues were noted:

- Stylistic choice would be to define the `VestingDetails` struct inside the contract.
- Gas savings achieved by setting `startTimestamp` as immutable because it is set within the constructor.
- Error in `fund()` contract: Counters.Counter fundCount not incremented anywhere. So the contract is fundable more than once. This enables changes to vesting terms through `endTimestamp`.
- An out-of-gas denial of services attack is possible (read about DoS attacks [here](https://consensys.github.io/smart-contract-best-practices/attacks/denial-of-service/)). This is made possible because:
- I used an array of structs: see `vestingDetails`.
- `fund()` can be called multiple times.
- The owner can significantly increase the size of the array (sending many tx with 1 Wei of a token) so that when the beneficiary calls `withdraw()`, the gas limit could be exceeded which blocks the transaction from happening.

### Actions From This Feedback

I have renamed the initial contract implementation as [`VestingVaultVulnerable.sol`](./src/vulnerable/VestingVaultVulnerable.sol) and created a new [`VestingVault.sol`](./src/VestingVault.sol) implementation to incorporate feedback. I have also created additional tests in [`VestingVaultVulnerable.t.sol`](./test/VestingVaultVulnerable.t.sol) and [`VestingVault.t.sol`](./test/VestingVault.t.sol).

#### VestingVault.sol

Specific changes include:

- The struct is defined within the main contract.
- `startTimestamp` is immutable.
- The Counters.Counter fundCount is now incremented in `fund()`.
- The `withdraw(uint256 index)` function now requires an index input. The for loop has been removed.
- Added a function `getVestingDetailsLength` to retrieve the length of the `VestingDetails` array.

Tests added:

- Funding the vault by the owner & the Counters.Counter gets incremented: `testFundVault`
- The owner can only fund the vault once: `testFundCannotBeCalledAgainByOwner`
- The beneficiary can withdraw from the vault after unlock time using a suitable index: `testBeneficiaryCanWithdrawFromVault`

#### VestingVaultVulnerable.sol

One change was made to the initial contract:

- Added a way to track the gas used by the function for a test. This function now returns a `uint256 gasUsed`.

Test added:

- Tried to break the contract using an out-of-gas denial of service attack: `testOwnerCanFundVaultMultipleTimes()`
- The gas used by the contract exceeded the block gas limit of ETH mainnet (value obtained by forking and emitting a log of `block.gaslimit`).

Already implemented tests:

- Deploying the vault: `testDeployVault`
- Funding the vault by the owner: `testFundVault`
- Funding the vault cannot be done by another user: `testUserCannotFundVault`
- The vault unlock time cannot exceed the maximum duration: `testVaultEndTimestampLtMaxDuration`
- Beneficiary can withdraw from the vault after the unlock time: `testBeneficiaryCanWithdrawFromVault`
