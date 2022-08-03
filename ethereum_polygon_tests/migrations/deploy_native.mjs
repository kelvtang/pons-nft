// import {deployContract, createSigner, createRPCProviders} from "../test_functions.mjs";
// import * as ethers from 'ethers';
// import * as fs from 'fs'

// const provider = await createRPCProviders();
// const signerParent = createSigner("8d2d418923ca11e09f09b43fa61c00aecc72a9b0ee2a54e4de09787e5dc2b252", provider[0]);
// const signerChild = createSigner("8d2d418923ca11e09f09b43fa61c00aecc72a9b0ee2a54e4de09787e5dc2b252", provider[1]);

// const PonsMarket_contractInfo = JSON.parse(fs.readFileSync('./build/contracts/PonsNftMarket.json', 'utf8'));

// const donel = deployContract(signerParent, PonsMarket_contractInfo, ethers.utils.getAddress("0x07eC6512C66617fc0Dea66eF8A0622E648481149"));

// console.log(donel);