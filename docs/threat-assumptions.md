# Threat assumptions

This document describes the security assumptions for the current IDO launchpad
implementation. It is a scope boundary for review, not a guarantee that the
contracts are safe for production deployment.

## System boundary

The system consists of `IDO`, its per-launch `Pool`, the whitelist, and the
ERC-20 project token. Ether is deposited through `IDO`; the `Pool` records
participation and calculates each participant's token allocation; after the
pool is marked `Finished`, `IDO` transfers project tokens to participants.

## Trusted parties and assumptions

- The `IDO` owner is trusted to grant and revoke `POOL_OWNER_ROLE` only to
  competent operators. The owner key is an administrative root of trust.
- A pool owner is trusted to provide correct caps, dates, status transitions,
  wallet, token address, allocation limits, exchange rate, token price, and
  token-supply values. These values are not independently verified by the
  contracts.
- A pool owner is trusted to whitelist only intended participants. The
  whitelist is administrative; it is not an identity, Sybil-resistance, or
  compliance system.
- The project token address is assumed to implement the expected ERC-20
  transfer behavior and to have sufficient balance in `IDO` before claims.
  Fee-on-transfer, rebasing, pausing, blacklisting, callback, or otherwise
  non-standard token behavior is outside the supported model.
- Administrative keys are assumed to be secured and transactions are assumed
  to be reviewed before signing. A compromised owner or pool-owner key can
  misconfigure or control the sale within the permissions of that key.
- The deployment chain, consensus, timestamp behavior, RPC infrastructure,
  and account cryptography are assumed to be available and not compromised.
  Miner/validator timestamp manipulation and chain reorganisation risk are not
  eliminated by the contracts.

## Attacker capabilities

An untrusted participant may inspect all on-chain state, submit arbitrary
transactions from their own address, attempt deposits outside the sale window,
repeat claims, send unexpected calls, and try to exploit rounding or boundary
conditions. An attacker may also submit transactions concurrently with other
users and may deploy arbitrary contracts, including contracts with unusual
fallback behavior.

The threat model does **not** assume that an attacker can forge another
account's signature, bypass the EVM, alter deployed bytecode, or compromise the
trusted administrative keys.

## Security properties intended by the implementation

- Only whitelisted addresses can enter through `IDO`'s Ether receive path.
- Deposits are accepted only while the pool is ongoing, within its time window,
  below the hard cap, and within the configured per-user allocation limits.
- A participant can claim project tokens only after the pool is marked
  `Finished`, and the `IDO` claim flag prevents a second claim through the same
  deployment.
- Pool status changes follow the state-transition rules encoded in `Pool`.
- Reverted deposits and claims should leave their state changes reverted by the
  EVM transaction model.

## Out of scope and residual risks

- Correctness of the sale economics, exchange rate, token price, and project
  token supply is an operational responsibility of the pool owner.
- The contracts do not provide refunds of deposited Ether. A cancelled pool,
  failed soft cap, unavailable token balance, or incorrect configuration can
  therefore leave participants without the intended outcome.
- There is no on-chain recovery path for a wrong wallet, wrong token address,
  lost administrative key, or accidental transfer of assets.
- Gas exhaustion and unbounded participant enumeration can make read operations
  or future operational workflows impractical as the participant set grows.
- The implementation has not been treated as audited or production-ready;
  deployment requires an independent security review, adversarial tests, and
  operational key-management controls.

Changes to roles, token behavior, lifecycle, deposits, or claims require this
document to be reviewed and updated.
