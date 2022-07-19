# Pons NFT

This repository contains the Pons NFT system. Detailed documentation for the Pons NFT contracts are in the `contracts/` directory.. Detailed documentation for tests are in the `tests/` directory.

The structure of the repository is as follow:

- config.mjs
- utils/

- generate-deployment-contracts.mjs
- deployment-contracts/
- flow.json

- transactions/
- scripts/

- core-contracts/
- deploy-core-contracts.mjs

- testing-contracts/
- deploy-testing-contracts.mjs

- contracts/
- deploy-contracts.mjs

- tests/
- run-test.mjs


## config.mjs

This file contains all the configurable parameters for this project, including settings such as the default storage paths to be passed into the Pons contracts, and the Flow network access node to connect to.

Before running scripts from this project, make sure that:
- `access_node_origin` points to an accessible access node;
- `address_of_names` and `private_keys_of_names` contain the correct values for the network. `0xFUNGIBLETOKEN`, `0xFLOWTOKEN`, and `0xNONFUNGIBLETOKEN` should point to the addresses of the corresponding core contract on the network, and `0xPONS` and `0xPROPOSER` should point to the testing account. The private keys of the testing account should be put under both `0xPONS` and `0xPROPOSER` in `private_keys_of_names`.

## utils/

This directory contains Javascript utilities which assist in calling the Flow APIs.

# generate-deployment-contracts.mjs

This file can be directly run with `node generate-deployment-contracts.mjs` to generate a version of the Pons NFT system contracts into the `deployment-contracts/` directory. The generated version of the Pons contracts are substituted with import addresses for the specified network from `config.mjs`.

# deployment-contracts/

Contracts generated by `generate-deployment-contracts.mjs`, ready for deployment, are situated in this directory. Paths in this directory are referenced by `flow.json`.

# flow.json

This file is the Flow CLI configuration file. It can be used to deploy the Pons Flow contracts, once the contracts for the network are generated. This file defines three networks: localnet, testnet, and mainnet. Provide the private key to the deploying account via the environment variable PONS_PRIVATE_KEY.

# transactions/

This directory contains ready-made Cadence Flow transactions for the Pons NFT system. Users who wish to mint, purchase, list, or unlist their NFTs on Pons can directly make use of these transactions, or make any modifications which they desire.

# scripts/

This directory contains ready-made Cadence Flow scripts for the Pons NFT system. Users can make use of these scripts to browse NFTs available for sale on the marketplace and browse NFTs belonging to any particular account.

## core-contracts/

This directory contains the Cadence Flow core contracts required for the Pons NFT system. They are included here, so that they can be deployed in Flow environments which do not possess them, such as the Flow emulator.

## deploy-core-contracts.mjs

This file can be directly run with `node deploy-core-contracts.mjs` to deploy the required Flow core contracts to the Flow network specified by config.mjs.

## testing-contracts/

This directory contains Cadence contracts which make testing easier. This directory also includes the `PonsUsage` contract, which contains many functions useful in transactions or scripts.

## deploy-testing-contracts.mjs

This file can be directly run with `node deploy-testing-contracts.mjs` to deploy the testing contracts to the Flow network specified by config.mjs.

## contracts/

This directory contains Cadence contracts which make up the Pons NFT system.

## deploy-contracts.mjs

This file can be directly run with `node deploy-contracts.mjs` to deploy the Pons NFT marketplace contracts to the Flow network specified by config.mjs.

## mint-fusd-on-emulator.mjs

This file can be directly run with `node mint-fusd-on-emulator.mjs` to mint FUSD token on the emulator and deposit them into the PONs account for testing.  
The emulator address `0xf8d6e0586b0a20c7` is hardcoded in line 28 and 35 of mint-fusd-on-emulator.mjs and can be replaced with testnet address.

## get-fusd-balance.mjs

This file can be directly run with `node get-fusd-balance.mjs` to return the FUSD balance held in the account. It can be run in pair with mint-fusd-on-emulator.mjs to test if the minting process was successful.  
The emulator address `0xf8d6e0586b0a20c7` is hardcoded in the script at line 32 and can be replaced with a testnet or mainnet address.

## tests/

This directory contains Cadence transactions and verification scripts, which make up the unit tests and integration tests for the Pons NFT marketplace.

## run-test.mjs

This file can be directly run with `node run-test.mjs` to run the Pons NFT marketplace tests on the Flow network specified by config.mjs. The tests produce test output in TAP format, and can be prettified by piping through TAP prettifiers such as `npx tap-spec`. The tests also produce a good amount of useful test information in the form of TAP comments.

Before running the tests, make sure that the the testing contracts in `testing-contracts/`, the required Flow core contracts in `core-contracts/`, and the Pons contracts iin `contracts/` are all deployed. For example, on the emulator, before running tests, you can deploy all the required contracts with `node deploy-core-contracts.mjs ; node deploy-contracts.mjs ; node deploy-testing-contracts.mjs`.


# Cavaets

Make sure the Flow network of choice (emulator/Testnet) is turned on and reachable before running the tests, otherwise the Flow Node.js module is prone to conjuring an obscenely ugly error.

Uses top-level awaits, recent versions of Node.js required. Windows not supported.

Make sure you run `node generate-deployment-contracts.mjs` before using the Flow CLI to deploy or interact with the Pons contracts. Provide the private key to the deploying account via the environment variable PONS_PRIVATE_KEY when using the Flow CLI. The provided networks in flow.json are localnet, testnet, and mainnet.
