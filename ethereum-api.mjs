import pkg from "@maticnetwork/maticjs"
import pkg1 from '@maticnetwork/maticjs-ethers'
import pkg2 from '@fxportal/maticjs-fxportal';
import { ethers, providers, Wallet } from "ethers";
import { NETWORK_TYPE, NETWORK_NAME, BURN_PROOF_EVENT_SIG } from "./config.mjs";

const { use } = pkg
const { Web3ClientPlugin } = pkg1
const { FxPortalClient } = pkg2
use(Web3ClientPlugin);

const ZERO_ADDRESS = ethers.constants.AddressZero

const createFxClient = (privateKey) => (rootProvider) => async (childProvider) => {
	const fxPortalClient = new FxPortalClient()
	await fxPortalClient.init({
		network: NETWORK_TYPE,
		version: NETWORK_NAME,
		parent: {
			provider: new Wallet(privateKey, rootProvider)
		},
		child: {
			provider: new Wallet(privateKey, childProvider)
		}
	});
	return fxPortalClient
}

const generateBurnProof = (client) => async (transactionHash) => {
	const proof = await client.exitUtil.buildPayloadForExit(
		transactionHash,
		BURN_PROOF_EVENT_SIG
	)
	return proof
}

// for ethereum to polygon transactions
const checkIfTransactionDeposited = (client) => async (transactionHash) => {
	const isDeposited = await client.isDeposited(transactionHash)
	return isDeposited
}

const checkLatestProcessedBlock = (client) => async (transactionHash) => {
	const chainBlockInfo = await client.exitUtil.getChainBlockInfo(transactionHash)
	return chainBlockInfo
}

// for polygon to ethereum transfer transactions
const checkIfTransactionCheckpointed = (client) => async (transactionHash) => {
	const isCheckPointed = await client.isCheckPointed(transactionHash);
	return isCheckPointed
}

// Deploys a single contract
const deployContract = (signer) => (contractAbi) => (contractBytecode) => async (constructorArgs) => {
	const factory = new ethers.ContractFactory(contractAbi, contractBytecode, signer);
	const contract = await factory.deploy(...constructorArgs);
	const deploymentTransactionResult = await contract.deployTransaction.wait();
	return deploymentTransactionResult;
};

// Creates a contract instance that we can use to read from and write to the contract depending on whether a signer or provider was passed
const createContractInstance = (contractAddress) => (contractAbi) => async (signerOrProvider) => {
	return new ethers.Contract(contractAddress, contractAbi, signerOrProvider)
}

const createRPCProviders = async (providerLink) => {
	return new ethers.providers.JsonRpcProvider(providerLink)
}

// creates the wallet that will sign the transaction
const createSigner = (privateKey) => async (provider) => {
	return new ethers.Wallet(privateKey, provider);
}

/*
 * This functions encodes arguments as bytes if a function on solidity requires passing in data as bytes
 * typeArr would be something like ["address", "string"]
 * It's respective dataArr would be something like ["0xaC39b311DCEb2A4b2f5d8461c1cdaF756F4F7Ae9", "Hello"]
 * returns a byte string
*/
const encodeToBytes = (typeArr) => async (dataArr) => {
	return ethers.utils.defaultAbiCoder.encode(typeArr, dataArr)
}

/*
 * Creates an interface for a function, encodes it and returns the encoded output
 * An example is as follows:
 * We have the the following function in a contract: function initialize(address _fxChild) initializer public { <logic> }
 * functionHeader would be 'function initialize(address _fxChild)'
 * functionName would be 'initialize'
 * functionArgs would be an array of values for the function arguements i.e [<someAddress>] in this case
 * returns encoded function interface
*/
const createAndEncodeFunctionInterface = (functionHeader) => (functionName) => async (functionArgs) => {
	const iface = new ethers.utils.Interface([functionHeader])
	return iface.encodeFunctionData(functionName, functionArgs)
}

export { createFxClient, generateBurnProof, checkIfTransactionDeposited, checkLatestProcessedBlock, checkIfTransactionCheckpointed };
export { deployContract, createSigner, createRPCProviders, createContractInstance, encodeToBytes, createAndEncodeFunctionInterface };
export { ZERO_ADDRESS };