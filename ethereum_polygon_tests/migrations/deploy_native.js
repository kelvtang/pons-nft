import {deployContract, createSigner, createRPCProviders} from "../test_functions.mjs";
import * as ethers from 'ethers';

const provider = await createRPCProviders();
const signerParent = await createSigner("8d2d418923ca11e09f09b43fa61c00aecc72a9b0ee2a54e4de09787e5dc2b252", provider[0]);
const signerChild = await createSigner("8d2d418923ca11e09f09b43fa61c00aecc72a9b0ee2a54e4de09787e5dc2b252", provider[1]);


console.table(await deployContract(signerParent, /* ContractInfo */, ethers.utils.getAddress("0x07eC6512C66617fc0Dea66eF8A0622E648481149")));