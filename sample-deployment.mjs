import {
    deployContract, createSigner, createRPCProviders, createContractInstance, encodeToBytes, createAndEncodeFunctionInterface,
    createFxClient, generateBurnProof, checkIfTransactionDeposited, checkLatestProcessedBlock, checkIfTransactionCheckpointed
} from './ethereum-api.mjs';
import { ZERO_ADDRESS } from './ethereum-api.mjs';
import * as fs from 'fs'


const fxErc721ContractInformation = JSON.parse(fs.readFileSync('./build/contracts/FxERC721.json', 'utf8'));
const rootTunnelContractInformation = JSON.parse(fs.readFileSync('./build/contracts/FxERC721RootTunnel.json', 'utf8'));
const childTunnelContractInformation = JSON.parse(fs.readFileSync('./build/contracts/FxERC721ChildTunnel.json', 'utf8'));
const proxyAdminContractInformation = JSON.parse(fs.readFileSync('./build/contracts/ProxyAdmin.json', 'utf8'));
const transparentProxyContractInformation = JSON.parse(fs.readFileSync('./build/contracts/TransparentUpgradeableProxy.json', 'utf8'));
const FxERC721ManagerInformation = JSON.parse(fs.readFileSync('./build/contracts/FxERC721FxManager.json', 'utf8'));
const ponsNftMarketContractInformation = JSON.parse(fs.readFileSync('./build/contracts/PonsNftMarket.json', 'utf8'))
const flowTunnelContractInformation = JSON.parse(fs.readFileSync('./build/contracts/FlowTunnel.json', 'utf8'))

const rootProvider = await createRPCProviders("");
const childProvider = await createRPCProviders("");

const rootSigner = await createSigner("")(rootProvider);
const childSigner = await createSigner("")(childProvider);

console.log("---------------------- Deploying Proxy Admin Contract on polygon ------------------------------------")
tx = await deployContract(childSigner)(proxyAdminContractInformation.abi)(proxyAdminContractInformation.bytecode)([])
console.log(tx)

console.log("---------------------- Deploying Proxy Admin Contract on ethereum ------------------------------------")
tx = await deployContract(rootSigner)(proxyAdminContractInformation.abi)(proxyAdminContractInformation.bytecode)([])
console.log(tx)


console.log("---------------------- Deploying Fx token Contract on polygon ------------------------------------")
tx = await deployContract(childSigner)(fxErc721ContractInformation.abi)(fxErc721ContractInformation.bytecode)([])
console.log(tx)

console.log("---------------------- Deploying Fx token Contract on ethereum ------------------------------------")
tx = await deployContract(rootSigner)(fxErc721ContractInformation.abi)(fxErc721ContractInformation.bytecode)([])
console.log(tx)

console.log("---------------------- Deploying child tunnel Contract on polygon ------------------------------------")
tx = await deployContract(childSigner)(childTunnelContractInformation.abi)(childTunnelContractInformation.bytecode)([])
console.log(tx)

console.log("---------------------- Deploying root tunnel Contract on ethereum ------------------------------------")
tx = await deployContract(rootSigner)(rootTunnelContractInformation.abi)(rootTunnelContractInformation.bytecode)([])
console.log(tx)

console.log("---------------------- Deploying Fx Manager Contract on polygon ------------------------------------")
tx = await deployContract(childSigner)(FxERC721ManagerInformation.abi)(FxERC721ManagerInformation.bytecode)([])
console.log(tx)

console.log("---------------------- Deploying Fx Manager Proxy Contract on polygon ------------------------------------")
const fxManagerinitializerEncoded = await createAndEncodeFunctionInterface('function initialize()')('initialize')([])
tx =  await deployContract(childSigner)(transparentProxyContractInformation.abi)
(transparentProxyContractInformation.bytecode)
(['', '', fxManagerinitializerEncoded])
console.log(tx)

console.log("---------------------- Deploying Fx token Proxy Contract on polygon ------------------------------------")
const childFxErc721InitializerEncoded = await createAndEncodeFunctionInterface
    ('function initialize(address fxManager_,address connectedToken_,string memory name_,string memory symbol_)')
    ('initialize')(['', ZERO_ADDRESS, '', ''])
tx = await deployContract(childSigner)(transparentProxyContractInformation.abi)
    (transparentProxyContractInformation.bytecode)
    (['', '', childFxErc721InitializerEncoded])
console.log(tx)


console.log("---------------------- Deploying child tunnel proxy Contract on polygon ------------------------------------")
const childTunnelInitializerEncoded = await createAndEncodeFunctionInterface
    ('function initialize(address _fxChild, address _childFxManagerProxy)')('initialize')
    (['=', ''])
tx = await deployContract(childSigner)(transparentProxyContractInformation.abi)
    (transparentProxyContractInformation.bytecode)
    (['', '', childTunnelInitializerEncoded])
console.log(tx)

console.log("---------------------- Deploying root tunnel proxy Contract on ethereum ------------------------------------")
const rootTunnelInitializerEncoded = await createAndEncodeFunctionInterface
    ('function initialize(address _checkpointManager,address _fxRoot)')('initialize')
    (['', ''])
tx = await deployContract(rootSigner)(transparentProxyContractInformation.abi)
    (transparentProxyContractInformation.bytecode)
    (['', '', rootTunnelInitializerEncoded])
console.log(tx)


console.log("---------------------- Deploying Fx token proxy Contract on ethereum ------------------------------------")
const rootFxErc721InitializerEncoded = await createAndEncodeFunctionInterface
    ('function initialize(address fxManager_,address connectedToken_,string memory name_,string memory symbol_)')
    ('initialize')(['', ZERO_ADDRESS, '', ''])
tx = await deployContract(rootSigner)(transparentProxyContractInformation.abi)
    (transparentProxyContractInformation.bytecode)
    (['', '', rootFxErc721InitializerEncoded])
console.log(tx)

console.log("---------------------- Deploying market Contract on polygon ------------------------------------")
tx = await deployContract(childSigner)(ponsNftMarketContractInformation.abi)(ponsNftMarketContractInformation.bytecode)([])
console.log(tx)

console.log("---------------------- Deploying market proxy Contract on polygon ------------------------------------")
const ponsNftMarketInitializedEncoded = await createAndEncodeFunctionInterface
('function initialize(address _tokenContractAddress, address _fxManagerContractAddress)')
('initialize')(['', ''])
tx = await deployContract(childSigner)(transparentProxyContractInformation.abi)
(transparentProxyContractInformation.bytecode)
(['', '', ponsNftMarketInitializedEncoded])
console.log(tx)

console.log("---------------------- Deploying flow tunnel Contract on polygon ------------------------------------")
tx = await deployContract(childSigner)(flowTunnelContractInformation.abi)(flowTunnelContractInformation.bytecode)([])
console.log(tx)

console.log("---------------------- Deploying flow tunnel proxy Contract on polygon ------------------------------------")
const flowTunnelInitializedEncoded = await createAndEncodeFunctionInterface
('function initialize(address _tokenContractAddress, address _marketContractAddress, address _fxManagerAddress)')
('initialize')(['', '', ''])
tx = await deployContract(childSigner)(transparentProxyContractInformation.abi)
(transparentProxyContractInformation.bytecode)
(['', '', flowTunnelInitializedEncoded])
console.log(tx)


const childFxManagerProxyInstance = await createContractInstance('')(FxERC721ManagerInformation.abi)(childSigner)
const childTunnelProxyInstance = await createContractInstance('')(childTunnelContractInformation.abi)(childSigner)
const childFxErc721TokenProxyInstance = await createContractInstance('')(fxErc721ContractInformation.abi)(childSigner)
const rootTunnelProxyInstance = await createContractInstance('')(rootTunnelContractInformation.abi)(rootSigner)
const rootFxErc721TokenProxyInstance = await createContractInstance('')(fxErc721ContractInformation.abi)(rootSigner)
const ponsNftMarketplaceProxyInstance = await createContractInstance('')(ponsNftMarketContractInformation.abi)
(childSigner)

console.log("---------------------- Setting flow tunnel contract proxy address for market proxy on polygon ------------------------------------")
tx = await ponsNftMarketplaceProxyInstance.setTunnelContractAddress('')
console.log(tx)

console.log("------- Adding approval for flow tunnel, market contract and child tunnel proxy addresses in FxManager contract on polygon --------")
tx = await childFxManagerProxyInstance.addApproval('')
console.log(tx)
tx = await childFxManagerProxyInstance.addApproval('')
console.log(tx)
tx = await childFxManagerProxyInstance.addApproval('')
console.log(tx)


console.log("---------------------- Setting FxChild on ethereum ------------------------------------")
tx = await rootTunnelProxyInstance.setFxChildTunnel('')
console.log(tx)

console.log("---------------------- Setting FxRoot on polygon ------------------------------------")
tx = await childTunnelProxyInstance.setFxRootTunnel('')
console.log(tx)

console.log("---------------------- Setting Connected token on polygon ------------------------------------")
tx = await childFxErc721TokenProxyInstance.updateConnectedToken('')
console.log(tx)

console.log("---------------------- Setting Connected token on ethereum ------------------------------------")
tx = await rootFxErc721TokenProxyInstance.updateConnectedToken('')
console.log(tx)

console.log("---------------------- Setting token Proxy address on ethereum ------------------------------------")
tx = await rootTunnelProxyInstance.setTokenProxy('')
console.log(tx)

console.log("---------------------- Setting token Proxy address on polygon ------------------------------------")
tx = await childFxManagerProxyInstance.setTokenProxy('')
console.log(tx)
