# Using truffle

## Installing Dependencies
```bash 
npm install --global truffle ganache-cli
```
```bash 
npm install --save @truffle/hdwallet-provider fs ethers
```
```bash
npm install --save-dev tape @types/tape
```

## Usage 
* Create a .secret file to hold your mnemonic phrase and store it in the ethereum_polygon_tests/ directory.
```bash
touch ethereum_polygon_tests/.secret && vi ethereum_polygon_tests/.secret
```
* Then use following commands for task.  
        `cd ethereum_polygon_tests/`
    * Deploy to Ganache local environment (Make Sure ganache environment is running):  
        `truffle migrate --network development`
    * Deploy to Polygon:  
        `truffle migrate --network matic`
    * Test on truffle:  
        `truffle test --network development`