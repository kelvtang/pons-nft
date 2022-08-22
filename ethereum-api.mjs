import pkg from "@maticnetwork/maticjs"
import pkg1 from '@maticnetwork/maticjs-ethers'
import pkg2 from '@fxportal/maticjs-fxportal';
import { ethers, Wallet } from "ethers";
import { NETWORK_TYPE, NETWORK_NAME, BURN_PROOF_EVENT_SIG } from "./config.mjs";

const { use } = pkg
const { Web3ClientPlugin } = pkg1
const { FxPortalClient } = pkg2
use(Web3ClientPlugin);


// Address(0x0) in solidity
const ZERO_ADDRESS = ethers.constants.AddressZero


// Creates and returns a new Fx Protal client instance
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

/*
* This function creates the burn proof needed to receive a token on Ethereum
* Can be called for a transaction that has been checkpointed on polygon
* Fails if transaction is not checkpointed
* returns burn proof which the user can pass to {FxERC721RootTunnel.receiveMessage} to transfer the token to ethereum
*/
const generateBurnProof = (client) => async (transactionHash) => {
	const proof = await client.exitUtil.buildPayloadForExit(
		transactionHash,
		BURN_PROOF_EVENT_SIG
	)
	return proof
}

/*
* Used to check if a token transfer from ethereum to polygon is complete
* returns true when the token has been statesynced by the polygon chain and transferred to the user's account
* No need for user to call any extra function when transferring to polygon
*/
const checkIfTransactionDeposited = (client) => async (transactionHash) => {
	const isDeposited = await client.isDeposited(transactionHash)
	return isDeposited
}

/*
* Used to check which block a transaction is in, as well as the latest processed block by the polygon chain's checkpoint
* can be used instead of {checkIfTransactionCheckpointed} to check if a transaction has been checkpointed
* if the transaction's block number < latest processed block number then the transaction has been checkpointed
* And the user can generate the burn proof for the transaction and redeem their token on ethereum
* Otherwise, transaction is not yet checkpointed and the user cannot redeem it yet on ethereum
*/
const checkLatestProcessedBlock = (client) => async (transactionHash) => {
	const chainBlockInfo = await client.exitUtil.getChainBlockInfo(transactionHash)
	return chainBlockInfo
}

/*
* can be used instead of {checkLatestProcessedBlock} to check if a transaction has been checkpointed on polygon
* returns true if the transaction is checkpointed and the user could generate the burn proof and redeem the token on ethereum
*/
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

// Creates a contract instance that can be used to read from and write to the contract depending on whether a provider or signer was passed
const createContractInstance = (contractAddress) => (contractAbi) => async (signerOrProvider) => {
	return new ethers.Contract(contractAddress, contractAbi, signerOrProvider)
}

// Creates a provider instance for a the given passed in link
const createRPCProviders = async (providerLink) => {
	return new ethers.providers.JsonRpcProvider(providerLink)
}

// Creates a wallet instance that can be used to sign a transaction
const createSigner = (privateKey) => async (provider) => {
	return new ethers.Wallet(privateKey, provider);
}

/*
* This functions encodes arguments as bytes if a function on solidity requires passing in data as bytes
* typeArr would be something like ["address", "string"]
* It's respective dataArr could be something like ["0xaC39b311DCEb2A4b2f5d8461c1cdaF756F4F7Ae9", "Hello"]
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