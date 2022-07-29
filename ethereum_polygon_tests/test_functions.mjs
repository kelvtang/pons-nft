import * as ethers from 'ethers'
import * as fs from 'fs'

/*
    * mnemonic phrase is `radar blur cabbage chef fix engine embark joy scheme fiction master release`
    * Run `truffle compile` to compile contracts and have the json files in the build folder
    * Run `truffle network --clean` to remove previously deployed contracts on the network if u want to delete previous contracts deployed
    * Run `ganache-cli -m <mnemonic phrase>` in one terminal to run the parent node i.e. ethereum. runs on port 8545
    * Run `ganache-cli -p 7545 -m <mnemonic phrase>` in another terminal to run the child node i.e. polygon
*/

const templateContractInformation = JSON.parse(fs.readFileSync('./build/contracts/FxERC721.json', 'utf8'));
const rootTunnelContractInformation = JSON.parse(fs.readFileSync('./build/contracts/FxERC721RootTunnel.json', 'utf8'));
const childTunnelContractInformation = JSON.parse(fs.readFileSync('./build/contracts/FxERC721ChildTunnel.json', 'utf8'));
const FxRootContractInformation = JSON.parse(fs.readFileSync('./build/contracts/FxRoot.json', 'utf8'));
const FxChildContractInformation = JSON.parse(fs.readFileSync('./build/contracts/FxChild.json', 'utf8'));

// Deploys a single contract
const deployContract = (signer) => (contractInfo) => async (constructorArgs) => {
    const factory = new ethers.ContractFactory(contractInfo.abi, contractInfo.bytecode, signer);
    const contract = await factory.deploy(...constructorArgs);
    const deploymentTransactionResult = await contract.deployTransaction.wait();
    return deploymentTransactionResult;
};


// Deploys root and child contracts and their associated dependant contracts
const deployContracts = (parentSigner) => async (childSigner) => {
    let FxERC721RootDeploymentResult = await deployContract(parentSigner)(templateContractInformation)([]);
    let FxRootDeploymentResult = await deployContract(parentSigner)(FxRootContractInformation)([]);
    let FxRootTunnelDeploymentResult =
        await deployContract(parentSigner)(rootTunnelContractInformation)(["0x0000000000000000000000000000000000000000",
            FxRootDeploymentResult.contractAddress, FxERC721RootDeploymentResult.contractAddress]);

    let FxERC721ChildDeploymentResult = await deployContract(childSigner)(templateContractInformation)([]);
    let FxChildDeploymentResult = await deployContract(childSigner)(FxChildContractInformation)([]);
    let FxChildTunnelDeploymentResult =
        await deployContract(childSigner)(childTunnelContractInformation)([FxChildDeploymentResult.contractAddress,
        FxERC721ChildDeploymentResult.contractAddress, FxERC721RootDeploymentResult.contractAddress]);

    const rootInstance = new ethers.Contract(FxRootTunnelDeploymentResult.contractAddress, rootTunnelContractInformation.abi, parentSigner)
    const childInstance = new ethers.Contract(FxChildTunnelDeploymentResult.contractAddress, childTunnelContractInformation.abi, childSigner)
    return [rootInstance, childInstance];
}


// Creates a contract instance that we can use to read from and write to the contract
const createContractInstance = (tunnelAddresses) => (abi) => async (signer) => {
    return new ethers.Contract(tunnelAddresses, abi, signer)
}

const createRPCProviders = async () => {
    let parentProvider = new ethers.providers.JsonRpcProvider("http://127.0.0.1:8545");
    let childProvider = new ethers.providers.JsonRpcProvider("http://127.0.0.1:7545");
    return [parentProvider, childProvider]
}

const setFxRootTunnel = (childTunnelInstance) => async (rootTunnelInstance) => {
    await childTunnelInstance.setFxRootTunnel(rootTunnelInstance.address)
}

const setFxChildTunnel = (rootTunnelInstance) => async (childTunnelInstance) => {
    await rootTunnelInstance.setFxChildTunnel(childTunnelInstance.address)
}

// Deploys the token contract on the child chain and computes the corresponding root token contract address that will be deployed
const deployChildToken = (childTunnelInstance) => (uniqueId) => (name) => async (symbol) => {
    const transactionReceipt = await childTunnelInstance.deployChildToken(uniqueId, name, symbol)
    const logs = await transactionReceipt.wait()
    return {
        rootAddress: logs.events[0].args[0],
        childAddress: logs.events[0].args[1]
    }
}

// creates the wallet that will sign the transaction
const createSigner = (privateKey) => async (provider) => {
    return new ethers.Wallet(privateKey, provider);
}


// mimics the transfer of a token from polygon to ethereum
const transferToEthereum = (childTunnelInstance) => (rootTunnelInstance) => (childTokenAddress) => (tokenId) => async (data) => {
    const transactionReceipt = await childTunnelInstance.withdraw(childTokenAddress, tokenId, data)
    const log = await transactionReceipt.wait()
    await rootTunnelInstance.receiveMessage(log.events[1].args[0])
}

const changeArrToBytes = async (dataArr) => {
    return ethers.utils.defaultAbiCoder.encode(["string", "address", "uint96"], dataArr)
}


export { deployContracts, createSigner, transferToEthereum, createRPCProviders, setFxChildTunnel, setFxRootTunnel, deployChildToken, createContractInstance, changeArrToBytes };
export { templateContractInformation, rootTunnelContractInformation, childTunnelContractInformation };

