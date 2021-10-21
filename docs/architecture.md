# Architecture

## Components

`IDO` is the user-facing coordinator and owns the administrative boundary. It
uses OpenZeppelin `Ownable`, `AccessControl`, and `Pausable` dependencies, but
the current implementation does not expose pause or unpause entry points.

When the owner grants `POOL_OWNER_ROLE`, that operator can create one `Pool`,
configure its IDO information once, update its lifecycle status, and populate
the whitelist. `IDO` forwards participant deposits to the pool and forwards
claim requests to the pool's accounting before transferring project tokens.

`Pool` is deployed as a separate contract for the launch. It stores the pool
configuration, participant addresses, cumulative Ether contributions, and
token-sale accounting. Its `onlyOwner` functions are callable by `IDO`, because
`IDO` deploys the pool and becomes its owner.

`Whitelist` is inherited by `IDO` and stores approved participant addresses.
`ProjectToken` is only a sample ERC-20; deployments may use an external token
that must satisfy the assumptions in the threat model.

## Main flow

1. The deployer becomes the `IDO` owner.
2. The owner grants `POOL_OWNER_ROLE` to an operator.
3. The operator creates one pool with caps, dates, and an initial status.
4. The operator adds IDO/token parameters and whitelists participants.
5. The operator moves the pool from `Upcoming` to `Ongoing`.
6. Whitelisted accounts send Ether to `IDO`; `Pool.deposit` validates the time,
   hard cap, allocation limits, and token supply.
7. The operator moves the pool to `Finished`; participants call `refund` to
   receive their calculated project-token allocation once.

The permitted lifecycle is `Upcoming -> Ongoing -> Paused/Finished/Cancelled`,
with `Paused -> Ongoing/Cancelled`. Terminal states cannot transition again.

## Trust and call boundaries

Participants interact with `IDO`, not `Pool`, so pool ownership and accounting
are kept behind the coordinator. `Pool` accepts deposits only from its owner,
which prevents arbitrary callers from supplying a false participant address.
The participant address is nevertheless supplied by `IDO`, so the receive path
must remain the only supported deposit entry point.

The system intentionally keeps Ether in the `Pool` accounting contract; the
current code does not implement an Ether withdrawal or refund flow. Project
tokens are held by `IDO` and transferred directly during claims.
