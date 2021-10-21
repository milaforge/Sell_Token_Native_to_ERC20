# Solidity IDO launchpad

This is a Solidity implementation of a small IDO launchpad: an operator
creates a token sale, whitelists participants, accepts native-token deposits,
tracks allocations, and lets participants claim project tokens after the sale
finishes.

It is a compact example of building a stateful smart-contract system with role
permissions, lifecycle validation, accounting invariants, and adversarial
tests. It is not presented as audited or production-ready code.

## What I built

- `IDO.sol` — participant-facing coordinator, role administration, whitelist
  boundary, deposit routing, and one-time token claims.
- `Pool.sol` — per-sale configuration, lifecycle state machine, participant
  accounting, hard-cap enforcement, allocation calculation, and token claim
  amounts.
- `Whitelist.sol` — managed participant allowlist.
- `ProjectToken.sol` — sample ERC-20 used by the local test suite.
- `IPool.sol` and `Validations.sol` — explicit interfaces and shared input
  validation.

The contract boundary is intentionally simple: `IDO` deploys and owns one
`Pool`; the pool accepts deposits only through its owner (`IDO`); participants
interact with `IDO`; and project tokens are held by `IDO` until claims.

## Security and correctness demonstrated

The test suite exercises both normal flows and rejected transitions:

- only whitelisted addresses can deposit through the native-token receive path;
- deposits respect the sale window, hard cap, cumulative per-user limits, and
  available token supply;
- rejected deposits revert without changing accounting state;
- total raised equals the sum of participant records across generated deposits;
- claims are available only after `Finished`, transfer the expected allocation,
  and cannot be repeated;
- only declared pool status transitions are accepted.

The deeper design decisions and boundaries are documented here:

- [Architecture](docs/architecture.md)
- [Trade-offs](docs/tradeoffs.md)
- [Threat assumptions](docs/threat-assumptions.md)

## Run the tests

```bash
npm ci
npm test
```

The project uses Solidity `0.8.0`, Hardhat, ethers, OpenZeppelin Contracts,
and deterministic stateful/invariant-style tests in
[`test/ido.invariant.ts`](test/ido.invariant.ts).

## Important limitations

The current implementation has no Ether refund flow, no recovery path for
incorrect administrative configuration, and assumes a standard ERC-20 token
with sufficient balance. Administrative keys and sale parameters remain
trusted inputs. These are deliberate boundaries of this demonstration and are
described in the [threat assumptions](docs/threat-assumptions.md).
