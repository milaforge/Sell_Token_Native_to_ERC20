# Architecture trade-offs

## Separate pool contract per launch

Each launch gets an isolated `Pool`, which keeps participant accounting and
configuration separate and makes the one-pool lifecycle explicit. The cost is
additional deployment gas, more contracts to monitor, and no built-in support
for multiple pools under one `IDO` instance.

## Central coordinator with delegated operator role

`IDO` provides one participant-facing address while `POOL_OWNER_ROLE` lets the
owner delegate routine launch operations. This is simpler than a governance
system, but both the owner and operator are trusted: a compromised key can
misconfigure the sale or its whitelist within its permissions.

## Pull-based token claims

Participants claim tokens themselves after the operator marks the pool
`Finished`. This avoids an unbounded batch transfer and lets each claim fail
independently. It requires participants to submit a transaction and requires
the `IDO` contract to be funded with enough project tokens.

## Ether receive path instead of an explicit deposit call

Allowing users to send Ether directly to `IDO` provides a small participant
interface. The trade-off is less explicit transaction intent and a stronger
reliance on the receive-function whitelist gate; direct calls to `Pool` revert.

## On-chain participant enumeration

The pool stores an address array so complete participation details can be
queried. This is convenient for small launches, but reads and any future
looping operations grow with participant count and may become impractical.

## Fixed configuration and limited recovery

Pool and IDO parameters are deliberately write-once or tightly state-gated to
reduce mutable-sale complexity. The corresponding trade-off is poor recovery
after an incorrect token address, wallet, economic parameter, or lost key.
There is also no Ether refund mechanism in the current implementation, so
operational validation must happen before accepting deposits.

## Minimal token compatibility

The implementation calls the standard ERC-20 `transfer` interface directly,
avoiding token-specific adapters and dependencies. This keeps the code small,
but excludes tokens with transfer fees, rebasing, blacklists, pausing, hooks, or
other behavior that changes the expected amount delivered.
