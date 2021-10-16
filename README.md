# IDO launchpad

## use cases:

- [UC-D0] IDO Smart contract deployer gets the Admin Role
- [UC-D0] Admin determines PoolOwner Role
- [UC-D1] [UC-D2] PoolOwner creates and manages the Pool
- [UC-D3] PoolOwner add Whitelisted addresses
- [UC-D4] Whitelisted participants, can participate in the Pool by sending ETH to IDO smart contract
- [UC-D5]: After the Pool is Finished, Participants can withdraw their share (only once) 

---

# Setting up to run tests

* `npm ci`

* Set variables in `.env` file

* `npm run test`

---
## Deploy on Rinkeby:

* Uncomment and set variables in `.env` file ([Rinkeby] section)

### then

`npx hardhat deploy --network rinkeby`

## or

`npx hardhat run scripts/deploy.ts --network rinkeby`
