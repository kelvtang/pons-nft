# Pons NFT

This repository contains the Pons NFT system. Detailed documentation for the Pons NFT contracts are in the `contracts/` directory.

The structure of the repository is as follow:

- config.mjs
- utils/

- core-contracts/
- deploy-core-contracts.mjs

- testing-contracts/
- deploy-testing-contracts.mjs

- contracts/
- deploy-contracts.mjs

- test/
- run-test.mjs


## config.mjs

This file contains all the configurable parameters for this project, including settings such as the default storage paths to be passed into the Pons contracts, and the Flow network access node to connect to.

## utils/

This directory contains Javasscript utilities which assist in calling the Flow APIs.

## core-contracts/

This directory contains the Cadence Flow core contracts required for the Pons NFT system. They are included here, so that they can be deployed in Flow environments which do not possess them, such as the Flow emulator.

## deploy-core-contracts.mjs

This file can be directly run with `node deploy-core-contracts.mjs` to deploy the required Flow core contracts to the Flow network specified by config.mjs.

## testing-contracts/

This directory contains Cadence contracts which make testing easier.

## deploy-testing-contracts.mjs

This file can be directly run with `node deploy-testing-contracts.mjs` to deploy the testing contracts to the Flow network specified by config.mjs.

## contracts/

This directory contains Cadence contracts which make up the Pons NFT system.

## deploy-contracts.mjs

This file can be directly run with `node deploy-contracts.mjs` to deploy the Pons NFT marketplace contracts to the Flow network specified by config.mjs.

## test/

This file contains Cadence transactions and verification scripts, which make up the unit tests and integration tests for the Pons NFT marketplace.

## run-test.mjs

This file can be directly run with `node run-test.mjs` to run the Pons NFT marketplace tests on the Flow network specified by config.mjs. The tests produce test output in TAP format, and can be prettified by piping through TAP prettifiers such as `npx tap-spec`. The tests also produce a good amount of useful test information in the form of TAP comments.


# Cavaets

Make sure the Flow network of choice (emulator/Testnet) is turned on and reachable before running the tests, otherwise the Flow Node.js module is prone to conjuring an obscenely ugly error.

Uses top-level awaits, recent versions of Node.js required. Windows not supported.
