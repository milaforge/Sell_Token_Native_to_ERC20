# IDO launchpad
## report security vulnerabilities 
` to my@email.com`

# test on local hardhat network; first run a node: 
``` npx hardhar node```
then:
``` npx hardhat test```

## deploy on Rinkeby:
fill DEPLOYER_PK environment variable using .env file with your accounts private key. then
```npx hardhat deploy --network rinkeby```
or 
```npx hardhat run scripts/deploy.ts --network rinkeby```

## deploy on local hardhat node:
``` npx hardhat deploy```
