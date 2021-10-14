# IDO launchpad

## Progress:
- UC-D1: Create a Pool [Done]
- UC-D2: Get Pool data [Done]
- UC-D3: Add Users to whitelist of a Pool [Done]
- UC-D4: Invest in a Pool [Done]
---
## 1- Install required packages: 
``` npm ci ```
## 2- Fill `.env` file
## 3- Deploy and test on local hardhat network 
**note that, it requires an active node on localhost!**
### To run a hardhat local node: 
``` npx hardhat node```
### then:
``` npx hardhat test```

---


## To deploy on local hardhat node:
``` npx hardhat deploy```

## To deploy on Rinkeby:
fill `DEPLOYER_PK` environment variable in the `.env` file with your account's private key.
## then
```npx hardhat deploy --network rinkeby```
## or 
```npx hardhat run scripts/deploy.ts --network rinkeby```
