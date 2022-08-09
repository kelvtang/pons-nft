/**
 * Handles testing of contracts `FlowTunnel.sol` and `PonsNftMarket.sol`
 * 
 */

import test from 'tape';
import {
    deployContracts, createSigner, transferToEthereum, createRPCProviders, setFxChildTunnel,
    setFxRootTunnel, deployChildToken, createContractInstance, changeArrToBytes
} from './test_functions.mjs';
import {
    templateContractInformation, rootTunnelContractInformation, childTunnelContractInformation
} from './test_functions.mjs';

import { ACCOUNT_ADDRESSES, PRIVATE_KEYS, ROOT_TUNNEL_CONTRACT_ADDRESS, CHILD_TUNNEL_CONTRACT_ADDRESS, ROOT_TOKEN_ADDRESS, CHILD_TOKEN_ADDRESS } from '../config.mjs';
