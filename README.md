# IDO launchpad

## Progress:
* Roles
    * Admin [Deployer]
    * PoolOnwer [admin defines it]
* Creating a Pool in 2 steps
    * pool info:
        * hardCap
        * softCap
        * startDateTime
        * endDateTime
        * status
    * pool details:
        * walletAddress
        * projectTokenAddress
        * minAllocationPerUser;
        * maxAllocationPerUser;
        * totalTokenProvided;
        * exchangeRate;
        * tokenPrice;
        * totalTokenSold;
* Get pool complete details
    * Investors and their allocations
    * other pool related info required by the business

---
## Install required packages: 
``` npm ci ```
## Deploy and test on local hardhat network 
### note that, it requires an active node on localhost!
#### To run a hardhat local node: 
``` npx hardhar node```
### then:
``` npx hardhat test```

---

## Deploy on Rinkeby:
fill `DEPLOYER_PK` environment variable in the `.env` file with your accounts private key.
## then
```npx hardhat deploy --network rinkeby```
## or 
```npx hardhat run scripts/deploy.ts --network rinkeby```

## deploy on local hardhat node:
``` npx hardhat deploy```
