import pkg from "@maticnetwork/maticjs"
import pkg1 from '@maticnetwork/maticjs-ethers'
import pkg2 from '@fxportal/maticjs-fxportal';
import { ethers, providers, Wallet } from "ethers";
import path from 'path';
import fs from 'fs';
import solc from 'solc';
import { fileURLToPath } from 'url';
// const path = require("path");
// const fs = require("fs");
// const solc = require("solc");

const parentProvider = new providers.JsonRpcProvider("https://goerli.infura.io/v3/516e2b3a94b64665a2b9c8cec1bc4690")
const childProvider = new providers.JsonRpcProvider("https://matic-mumbai.chainstacklabs.com/")

const privateKey = ""

const { ExitUtil, RootChain, use, Web3SideChainClient, POSClient, setProofApi } = pkg
const { Web3ClientPlugin } = pkg1
const { FxPortalClient } = pkg2
use(Web3ClientPlugin);
const fxPortalClient = new Web3SideChainClient()
await fxPortalClient.init({
	network: 'testnet',
	version: 'mumbai',
	parent: {
		provider: new Wallet(privateKey, parentProvider)
	},
	child: {
		provider: new Wallet(privateKey, childProvider)
	}
});

// // create root chain instance
// const rootChain = new RootChain(fxPortalClient,"0x2890bA17EfE978480615e330ecB65333b880928e"); //root chain proxy address

// // create exitUtil Instance
// const exitUtil = new ExitUtil(fxPortalClient, rootChain);

// // generate proof
// const proof = await exitUtil.buildPayloadForExit(
//     "0x1671c39fcff60508b71ffc68e215afc7c0c7c5342214b402c185bae835897f77",
//     "0x8c5261668696ce22758910d05bab8f186d6eb247ceac2af2e82c7dc17669b036"
// )
// console.log(proof)

const fxPortalClient1 = new FxPortalClient()
await fxPortalClient1.init({
	network: 'testnet',
	version: 'mumbai',
	parent: {
		provider: new Wallet(privateKey, parentProvider)
	},
	child: {
		provider: new Wallet(privateKey, childProvider)
	}
});


const isDeposited = await fxPortalClient1.isDeposited("0xd1a6afc84aeb4cc296c5372ea6f3db8298c770f92307c8b18dd925d2b7eb8623");
console.log(isDeposited)


// const isCheckPointene2 = await fxPortalClient1.exitUtil.getChainBlockInfo("0x501df49e4d2f58046a3f997312494753b5317cb88bf9558b9ae0e7d1471f0407")
// console.log(isCheckPointene2)

// const proof = await fxPortalClient1.exitUtil.buildPayloadForExit(
//     "0x501df49e4d2f58046a3f997312494753b5317cb88bf9558b9ae0e7d1471f0407",
//     "0x8c5261668696ce22758910d05bab8f186d6eb247ceac2af2e82c7dc17669b036"
// )
// console.log(proof)

// const isCheckPointenew = await fxPortalClient1.isCheckPointed("0xae54348b6c31a8a48a434249ed7f2e7ba21c0716bd72a4ce0ce09b458596b943");
// console.log(isCheckPointenew)

// const isCheckPointed = await fxPortalClient1.isCheckPointed("0x7b5df5b8d50dfb24d93c2cf8dce9193a85788ddbe3e0fe9761672b042628bd84");
// console.log(isCheckPointed)


// const isCheckPointenewd = await fxPortalClient1.isCheckPointed("0x41634f5e03ce462b3d49e4ba3e4d09cf3489c6fcfe60c867ab28ac496bb2b52f");
// console.log(isCheckPointenewd)


// const proof = await fxPortalClient.exitUtil.buildPayloadForExit(
//     "0xe0df62c6253b1257283ac99d7dc1b12b74952d31018446f661e9d90a4550e399",
//     "0x8c5261668696ce22758910d05bab8f186d6eb247ceac2af2e82c7dc17669b036"
// )
// console.log(proof)

// const isCheckPointed1 = await fxPortalClient.isCheckPointed("0xf856a00b7dd97e867e741b6277f67867a1eff2577e68d508a8669092fc6bddef");
// console.log(isCheckPointed1)

// const proof = await fxPortalClient.exitUtil.buildPayloadForExit(
//     "0xf856a00b7dd97e867e741b6277f67867a1eff2577e68d508a8669092fc6bddef",
//     "0x8c5261668696ce22758910d05bab8f186d6eb247ceac2af2e82c7dc17669b036"
// )

// console.log(proof)

// const isCheckPointed = await fxPortalClient.isCheckPointed("0xae54348b6c31a8a48a434249ed7f2e7ba21c0716bd72a4ce0ce09b458596b943");
// console.log(isCheckPointed)
// const erc721 = posClient.erc20('0x7a68efba11bfdb4955317d96f6b5f8d31bdf6835', true)
// const result = await erc721.withdrawExit("0xe0eae44d381a143383be3d74f32ad36332688353a3553c97c96dbde22fdb77d2");
// console.log("0: ", result)
// const txHash = await result.getTransactionHash();
// console.log("1: ", txHash)
// const txReceipt = await result.getReceipt();
// console.log(txReceipt)


const createFxClient = (privateKey) => (parentProvider) => (network) => async (childProvider) => {
	const fxPortalClient = new FxPortalClient()
	await fxPortalClient.init({
		network: 'testnet',
		version: network,
		parent: {
			provider: new Wallet(privateKey, parentProvider)
		},
		child: {
			provider: new Wallet(privateKey, childProvider)
		}
	});
	return fxPortalClient
}

const generateBurnProof = (client) => (transactionHash) =>
	async (MESSAGE_SENT_EVENT_SIG = "0x8c5261668696ce22758910d05bab8f186d6eb247ceac2af2e82c7dc17669b036") => {
		const proof = await client.exitUtil.buildPayloadForExit(
			transactionHash,
			MESSAGE_SENT_EVENT_SIG
		)
		return proof
	}


// for ethereum to polygon transactions
const checkIfTransactionDeposited = (client) => async (transactionHash) => {
	const isDeposited = await client.exitUtil.isDeposited(transactionHash)
	return isDeposited
}


// for polygon to ethereum transfer transactions
const checkIfTransactionCheckpointed = (client) => async (transactionHash) => {
	const isCheckPointed = await client.isCheckPointed(transactionHash);
	return isCheckPointed
}

const compileContracts = async () => {
	const __filename = fileURLToPath(import.meta.url);

	const __dirname = path.dirname(__filename);
	const contractPath = path.join(__dirname, 'contracts')

	const files = fs.readdirSync(contractPath)
	var input = {
		language: 'Solidity',
		sources: {
		},
		settings: {
			outputSelection: {
				'*': {
					'*': ['*']
				}
			}
		}
	};

	for (const file of files) {
		if (file.endsWith(".sol")) {
			const filePath = path.join(contractPath, file)
			const source = fs.readFileSync(filePath, "utf8");
			input.sources[`./${file}`] = {
				content: source
			}
		}

	}
	const output = JSON.parse(solc.compile(JSON.stringify(input)))
	const compiledContracts = []
	for (const file of files) {
		if (file.endsWith(".sol")) {
			for (var contractName in output.contracts[`./${file}`]) {
				compiledContracts.push({
					contractName: contractName,
					Bytecode: output.contracts[`./${file}`][contractName].evm.bytecode,
					ABI: output.contracts[`./${file}`][contractName].abi
				})
			}
		}
	}
	return compiledContracts
}

// args is an array of constructor arguemnts for the contract initialization
const deployContract = (provider) => (contractName) => async (constructorArgs) => {
	const compiledContracts = await compileContracts()
	const targetContract = compiledContracts.filter(contract => contract.contractName === contractName)
	const signer = new ethers.Wallet(privateKey, provider)
	const factory = new ethers.ContractFactory(targetContract[0].ABI, targetContract[0].Bytecode, signer)
	const contract = await factory.deploy(...constructorArgs)
	const deploymentTransactionResult = await contract.deployTransaction.wait()
	// console.log(deploymentTransactionResult)
	return deploymentTransactionResult
}


const approveContract = (rootTunnelAddress) => (rootTokenAddress) => (provider) => async (tokenId) => {
	var contract = new ethers.Contract(rootTokenAddress, [
		{
			"anonymous": false,
			"inputs": [
				{
					"indexed": true,
					"internalType": "address",
					"name": "owner",
					"type": "address"
				},
				{
					"indexed": true,
					"internalType": "address",
					"name": "approved",
					"type": "address"
				},
				{
					"indexed": true,
					"internalType": "uint256",
					"name": "tokenId",
					"type": "uint256"
				}
			],
			"name": "Approval",
			"type": "event"
		},
		{
			"anonymous": false,
			"inputs": [
				{
					"indexed": true,
					"internalType": "address",
					"name": "owner",
					"type": "address"
				},
				{
					"indexed": true,
					"internalType": "address",
					"name": "operator",
					"type": "address"
				},
				{
					"indexed": false,
					"internalType": "bool",
					"name": "approved",
					"type": "bool"
				}
			],
			"name": "ApprovalForAll",
			"type": "event"
		},
		{
			"inputs": [
				{
					"internalType": "address",
					"name": "to",
					"type": "address"
				},
				{
					"internalType": "uint256",
					"name": "tokenId",
					"type": "uint256"
				}
			],
			"name": "approve",
			"outputs": [],
			"stateMutability": "nonpayable",
			"type": "function"
		},
		{
			"inputs": [
				{
					"internalType": "uint256",
					"name": "tokenId",
					"type": "uint256"
				}
			],
			"name": "burn",
			"outputs": [],
			"stateMutability": "nonpayable",
			"type": "function"
		},
		{
			"inputs": [
				{
					"internalType": "uint256",
					"name": "tokenId",
					"type": "uint256"
				}
			],
			"name": "exists",
			"outputs": [
				{
					"internalType": "bool",
					"name": "",
					"type": "bool"
				}
			],
			"stateMutability": "nonpayable",
			"type": "function"
		},
		{
			"inputs": [
				{
					"internalType": "address",
					"name": "fxManager_",
					"type": "address"
				},
				{
					"internalType": "address",
					"name": "connectedToken_",
					"type": "address"
				},
				{
					"internalType": "string",
					"name": "name_",
					"type": "string"
				},
				{
					"internalType": "string",
					"name": "symbol_",
					"type": "string"
				}
			],
			"name": "initialize",
			"outputs": [],
			"stateMutability": "nonpayable",
			"type": "function"
		},
		{
			"inputs": [
				{
					"internalType": "address",
					"name": "user",
					"type": "address"
				},
				{
					"internalType": "uint256",
					"name": "tokenId",
					"type": "uint256"
				},
				{
					"internalType": "bytes",
					"name": "_data",
					"type": "bytes"
				}
			],
			"name": "mint",
			"outputs": [],
			"stateMutability": "nonpayable",
			"type": "function"
		},
		{
			"inputs": [
				{
					"internalType": "address",
					"name": "from",
					"type": "address"
				},
				{
					"internalType": "address",
					"name": "to",
					"type": "address"
				},
				{
					"internalType": "uint256",
					"name": "tokenId",
					"type": "uint256"
				}
			],
			"name": "safeTransferFrom",
			"outputs": [],
			"stateMutability": "nonpayable",
			"type": "function"
		},
		{
			"inputs": [
				{
					"internalType": "address",
					"name": "from",
					"type": "address"
				},
				{
					"internalType": "address",
					"name": "to",
					"type": "address"
				},
				{
					"internalType": "uint256",
					"name": "tokenId",
					"type": "uint256"
				},
				{
					"internalType": "bytes",
					"name": "_data",
					"type": "bytes"
				}
			],
			"name": "safeTransferFrom",
			"outputs": [],
			"stateMutability": "nonpayable",
			"type": "function"
		},
		{
			"inputs": [
				{
					"internalType": "address",
					"name": "operator",
					"type": "address"
				},
				{
					"internalType": "bool",
					"name": "approved",
					"type": "bool"
				}
			],
			"name": "setApprovalForAll",
			"outputs": [],
			"stateMutability": "nonpayable",
			"type": "function"
		},
		{
			"inputs": [
				{
					"internalType": "string",
					"name": "_name",
					"type": "string"
				},
				{
					"internalType": "string",
					"name": "_symbol",
					"type": "string"
				}
			],
			"name": "setupMetaData",
			"outputs": [],
			"stateMutability": "nonpayable",
			"type": "function"
		},
		{
			"anonymous": false,
			"inputs": [
				{
					"indexed": true,
					"internalType": "address",
					"name": "from",
					"type": "address"
				},
				{
					"indexed": true,
					"internalType": "address",
					"name": "to",
					"type": "address"
				},
				{
					"indexed": true,
					"internalType": "uint256",
					"name": "tokenId",
					"type": "uint256"
				}
			],
			"name": "Transfer",
			"type": "event"
		},
		{
			"inputs": [
				{
					"internalType": "address",
					"name": "from",
					"type": "address"
				},
				{
					"internalType": "address",
					"name": "to",
					"type": "address"
				},
				{
					"internalType": "uint256",
					"name": "tokenId",
					"type": "uint256"
				}
			],
			"name": "transferFrom",
			"outputs": [],
			"stateMutability": "nonpayable",
			"type": "function"
		},
		{
			"inputs": [
				{
					"internalType": "address",
					"name": "owner",
					"type": "address"
				}
			],
			"name": "balanceOf",
			"outputs": [
				{
					"internalType": "uint256",
					"name": "",
					"type": "uint256"
				}
			],
			"stateMutability": "view",
			"type": "function"
		},
		{
			"inputs": [],
			"name": "connectedToken",
			"outputs": [
				{
					"internalType": "address",
					"name": "",
					"type": "address"
				}
			],
			"stateMutability": "view",
			"type": "function"
		},
		{
			"inputs": [],
			"name": "fxManager",
			"outputs": [
				{
					"internalType": "address",
					"name": "",
					"type": "address"
				}
			],
			"stateMutability": "view",
			"type": "function"
		},
		{
			"inputs": [
				{
					"internalType": "uint256",
					"name": "tokenId",
					"type": "uint256"
				}
			],
			"name": "getApproved",
			"outputs": [
				{
					"internalType": "address",
					"name": "",
					"type": "address"
				}
			],
			"stateMutability": "view",
			"type": "function"
		},
		{
			"inputs": [
				{
					"internalType": "address",
					"name": "owner",
					"type": "address"
				},
				{
					"internalType": "address",
					"name": "operator",
					"type": "address"
				}
			],
			"name": "isApprovedForAll",
			"outputs": [
				{
					"internalType": "bool",
					"name": "",
					"type": "bool"
				}
			],
			"stateMutability": "view",
			"type": "function"
		},
		{
			"inputs": [],
			"name": "name",
			"outputs": [
				{
					"internalType": "string",
					"name": "",
					"type": "string"
				}
			],
			"stateMutability": "view",
			"type": "function"
		},
		{
			"inputs": [
				{
					"internalType": "uint256",
					"name": "tokenId",
					"type": "uint256"
				}
			],
			"name": "ownerOf",
			"outputs": [
				{
					"internalType": "address",
					"name": "",
					"type": "address"
				}
			],
			"stateMutability": "view",
			"type": "function"
		},
		{
			"inputs": [
				{
					"internalType": "bytes4",
					"name": "interfaceId",
					"type": "bytes4"
				}
			],
			"name": "supportsInterface",
			"outputs": [
				{
					"internalType": "bool",
					"name": "",
					"type": "bool"
				}
			],
			"stateMutability": "view",
			"type": "function"
		},
		{
			"inputs": [],
			"name": "symbol",
			"outputs": [
				{
					"internalType": "string",
					"name": "",
					"type": "string"
				}
			],
			"stateMutability": "view",
			"type": "function"
		},
		{
			"inputs": [
				{
					"internalType": "uint256",
					"name": "index",
					"type": "uint256"
				}
			],
			"name": "tokenByIndex",
			"outputs": [
				{
					"internalType": "uint256",
					"name": "",
					"type": "uint256"
				}
			],
			"stateMutability": "view",
			"type": "function"
		},
		{
			"inputs": [
				{
					"internalType": "address",
					"name": "owner",
					"type": "address"
				},
				{
					"internalType": "uint256",
					"name": "index",
					"type": "uint256"
				}
			],
			"name": "tokenOfOwnerByIndex",
			"outputs": [
				{
					"internalType": "uint256",
					"name": "",
					"type": "uint256"
				}
			],
			"stateMutability": "view",
			"type": "function"
		},
		{
			"inputs": [
				{
					"internalType": "uint256",
					"name": "tokenId",
					"type": "uint256"
				}
			],
			"name": "tokenURI",
			"outputs": [
				{
					"internalType": "string",
					"name": "",
					"type": "string"
				}
			],
			"stateMutability": "view",
			"type": "function"
		},
		{
			"inputs": [],
			"name": "totalSupply",
			"outputs": [
				{
					"internalType": "uint256",
					"name": "",
					"type": "uint256"
				}
			],
			"stateMutability": "view",
			"type": "function"
		}
	], provider)
	var contractWithSigner = contract.connect(new Wallet(privateKey, parentProvider))
	const tx = await contractWithSigner.approve(rootTunnelAddress, tokenId)
	console.log(tx)
}


// await approveContract("0x4eFb59A9D172A0357dE1e76042FaF7167Ac20297")("0x298d2d417340cd7ab7d9c71b01c33fd4c335fab1")(parentProvider)(1)



// // console.log(await deployContract(childProvider)("./FlowPolygonBridge/contracts/PonsNftMarket.sol")());