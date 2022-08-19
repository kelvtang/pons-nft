import test from 'tape';
import * as fs from 'fs'
import {
    deployContract, createSigner, createRPCProviders, createContractInstance, encodeToBytes, createAndEncodeFunctionInterface
} from '../ethereum-api.mjs';
import {
    CHILD_TUNNEL_PROXY_ADDRESS, ROOT_TUNNEL_PROXY_ADDRESS, CHILD_FX_TOKEN_PROXY_ADDRESS, ROOT_FX_TOKEN_PROXY_ADDRESS, CHILD_PROXY_ADMIN_ADDRESS
} from '../config.mjs';
import {
    ACCOUNT_ADDRESSES, PRIVATE_KEYS, GANACHE_PROVIDER_CHILD, GANACHE_PROVIDER_ROOT
} from '../config.mjs';
import { ZERO_ADDRESS } from '../ethereum-api.mjs';

const fxErc721ContractInformation = JSON.parse(fs.readFileSync('./build/contracts/FxERC721.json', 'utf8'));
const rootTunnelContractInformation = JSON.parse(fs.readFileSync('./build/contracts/FxERC721RootTunnel.json', 'utf8'));
const childTunnelContractInformation = JSON.parse(fs.readFileSync('./build/contracts/FxERC721ChildTunnel.json', 'utf8'));
const proxyAdminContractInformation = JSON.parse(fs.readFileSync('./build/contracts/ProxyAdmin.json', 'utf8'));
const transparentProxyContractInformation = JSON.parse(fs.readFileSync('./build/contracts/TransparentUpgradeableProxy.json', 'utf8'));
const FxERC721ManagerInformation = JSON.parse(fs.readFileSync('./build/contracts/FxERC721FxManager.json', 'utf8'));

/*
 * Child chain refers to polygon while root chain refers to ethereum 
 * For local testing do the following:
 * Mnemonic phrase is `radar blur cabbage chef fix engine embark joy scheme fiction master release`
 * Run `truffle compile` to compile contracts and have the json files in the build folder
 * Run `truffle network --clean` to remove previously deployed contracts on the network if u want to delete previous contracts deployed
 * Run `ganache-cli -m <mnemonic phrase>` in one terminal to run the parent node i.e. ethereum. runs on port 8545
 * Run `ganache-cli -p 7545 -m <mnemonic phrase>` in another terminal to run the child node i.e. polygon
*/

/* 
 * Deployment process is as follows:
 * Deploy ProxyAdmin on both ethereum and polygon
 * Deploy FxERC721 tokens on both Ethereum and polygon
 * Deploy root tunnel on Ethereum
 * Deploy child tunnel on polygon
 * Deploy Fx Manager on polygon
 * Deploy Fx Manager Proxy on polygon with data variable containing the initialize function encoded 
   with required arguments
 * Deploy FxERC721 token proxy on polygon with data variable containing the initialize function encoded with required arguments 
   and connected_token address to 0x0
 * Deploy child tunnel proxy on polygon with data variable containing the initialize function encoded with required arguments
 * Deploy root tunnel proxy on ethereum with data variable containing the initialize function encoded with required arguments
 * Deploy FxERC721 token proxy on Etheruem with data variable containing the initialize function encoded with required arguments 
   and connected_token address to 0x0
 * Add approval for the child tunnel proxy in the Fx Manager contract
 * setFxChildTunnel and setFxRootTunnel with the tunnel proxy addresses on ethereum and polygon for the tunnel proxy contracts
 * Set the connected token with the opposite chain token proxy address on ethereum and polygon for the token proxy contract
 * setTokenProxy with the token proxy address on ethereum for the tunnel proxy contract
 * setTokenProxy with token proxy address on polygon for the Fx Manager proxy contract
*/

// NB: After deploying, change the contract addresses in the config file
const deploy_contracts_ = (tokenName) => async (tokenSymbol) => {
    test("Deploying all contracts", async _test => {

        const rootProvider = await createRPCProviders(GANACHE_PROVIDER_ROOT);
        const childProvider = await createRPCProviders(GANACHE_PROVIDER_CHILD);

        const rootSigner = await createSigner(PRIVATE_KEYS[0])(rootProvider);
        const childSigner = await createSigner(PRIVATE_KEYS[1])(childProvider);

        // Deploy proxy admin contracts that manage all other proxy contracts and are used to upgrade proxy implementations
        const rootProxyAdmin = await deployContract(rootSigner)(proxyAdminContractInformation.abi)(proxyAdminContractInformation.bytecode)([])
        const childProxyAdmin = await deployContract(childSigner)(proxyAdminContractInformation.abi)(proxyAdminContractInformation.bytecode)([])

        // Deploy FxERC721 Token Contracts
        const rootFxErc721Token = await deployContract(rootSigner)(fxErc721ContractInformation.abi)(fxErc721ContractInformation.bytecode)([])
        const childFxErc721Token = await deployContract(childSigner)(fxErc721ContractInformation.abi)(fxErc721ContractInformation.bytecode)([])

        // Deploy root and child tunnel contracts
        const rootTunnel = await deployContract(rootSigner)(rootTunnelContractInformation.abi)(rootTunnelContractInformation.bytecode)([])
        const childTunnel = await deployContract(childSigner)(childTunnelContractInformation.abi)(childTunnelContractInformation.bytecode)([])

        // Deploy FxManager contract to allow multiple contracts to send a request to the same fx token
        const childFxManager = await deployContract(childSigner)(FxERC721ManagerInformation.abi)(FxERC721ManagerInformation.bytecode)([])

        // Deploy Fx Manager Proxy contract
        const fxManagerinitializerEncoded = await createAndEncodeFunctionInterface('function initialize()')('initialize')([])
        const childFxManagerProxy = await deployContract(childSigner)(transparentProxyContractInformation.abi)
            (transparentProxyContractInformation.bytecode)
            ([childFxManager.contractAddress, childProxyAdmin.contractAddress, fxManagerinitializerEncoded])

        // Deploy Fx token proxy on polygon
        const childFxErc721InitializerEncoded = await createAndEncodeFunctionInterface
            ('function initialize(address fxManager_,address connectedToken_,string memory name_,string memory symbol_)')
            ('initialize')([childFxManagerProxy.contractAddress, ZERO_ADDRESS, tokenName, tokenSymbol])
        const childFxErc721TokenProxy = await deployContract(childSigner)(transparentProxyContractInformation.abi)
            (transparentProxyContractInformation.bytecode)
            ([childFxErc721Token.contractAddress, childProxyAdmin.contractAddress, childFxErc721InitializerEncoded])

        // Deploy tunnel proxy on polygon
        const childTunnelInitializerEncoded = await createAndEncodeFunctionInterface
            ('function initialize(address _fxChild, address _childFxManagerProxy)')('initialize')
            ([ZERO_ADDRESS, childFxManagerProxy.contractAddress])
        const childTunnelProxy = await deployContract(childSigner)(transparentProxyContractInformation.abi)
            (transparentProxyContractInformation.bytecode)
            ([childTunnel.contractAddress, childProxyAdmin.contractAddress, childTunnelInitializerEncoded])

        // Deploy tunnel proxy on ethereum
        const rootTunnelInitializerEncoded = await createAndEncodeFunctionInterface
            ('function initialize(address _checkpointManager,address _fxRoot)')('initialize')
            ([ZERO_ADDRESS, ZERO_ADDRESS])
        const rootTunnelProxy = await deployContract(rootSigner)(transparentProxyContractInformation.abi)
            (transparentProxyContractInformation.bytecode)
            ([rootTunnel.contractAddress, rootProxyAdmin.contractAddress, rootTunnelInitializerEncoded])

        // Deploy Fx token proxy on ethereum
        const rootFxErc721InitializerEncoded = await createAndEncodeFunctionInterface
            ('function initialize(address fxManager_,address connectedToken_,string memory name_,string memory symbol_)')
            ('initialize')([rootTunnelProxy.contractAddress, ZERO_ADDRESS, tokenName, tokenSymbol])
        const rootFxErc721TokenProxy = await deployContract(rootSigner)(transparentProxyContractInformation.abi)
            (transparentProxyContractInformation.bytecode)
            ([rootFxErc721Token.contractAddress, rootProxyAdmin.contractAddress, rootFxErc721InitializerEncoded])

        // Create contract instances to call needed setup functions
        const childFxManagerProxyInstance = await createContractInstance(childFxManagerProxy.contractAddress)(FxERC721ManagerInformation.abi)(childSigner)
        const childTunnelProxyInstance = await createContractInstance(childTunnelProxy.contractAddress)(childTunnelContractInformation.abi)(childSigner)
        const childFxErc721TokenProxyInstance = await createContractInstance(childFxErc721TokenProxy.contractAddress)(fxErc721ContractInformation.abi)(childSigner)
        const rootTunnelProxyInstance = await createContractInstance(rootTunnelProxy.contractAddress)(rootTunnelContractInformation.abi)(rootSigner)
        const rootFxErc721TokenProxyInstance = await createContractInstance(rootFxErc721TokenProxy.contractAddress)(fxErc721ContractInformation.abi)(rootSigner)

        _test.test("Owner adding Approval for the child tunnel proxy", async _test => {
            try {
                await childFxManagerProxyInstance.addApproval(childTunnelProxy.contractAddress)
                _test.pass("Approval added successfully")
            } catch (e) {
                _test.fail("Address should not have been approved")
            }
        })

        _test.test("Non-owner removing Approval for the child tunnel proxy", async _test => {
            try {
                const nonOwnerSigner = await createSigner(PRIVATE_KEYS[2])(childProvider);
                const contractWithWrongSigner = childFxManagerProxyInstance.connect(nonOwnerSigner)
                await contractWithWrongSigner.removeApproval(childTunnelProxy.contractAddress)
                _test.fail("Address should not have been removed")
            } catch (e) {
                _test.pass("Address was not removed")
            }
        })

        await rootTunnelProxyInstance.setFxChildTunnel(childTunnelProxy.contractAddress)

        _test.test("Non-owner adding Approval for the child tunnel proxy", async _test => {
            try {
                const nonOwnerSigner = await createSigner(PRIVATE_KEYS[2])(childProvider);
                const contractWithWrongSigner = childFxManagerProxyInstance.connect(nonOwnerSigner)
                await contractWithWrongSigner.addApproval(childTunnelProxy.contractAddress)
                _test.fail("Address should not have been approved")
            } catch (e) {
                _test.pass("Address was not approved")
            }
        })

        await childTunnelProxyInstance.setFxRootTunnel(rootTunnelProxyInstance.address)

        _test.test("cannot reset FxChildTunnel address after it is set", async _test => {
            try {
                await rootTunnelProxyInstance.setFxChildTunnel(childTunnelProxyInstance.address)
                _test.fail("Should not be able to set the child tunnel again")
            } catch (e) {
                _test.pass("Child tunnel address did not change")
            }
        })

        _test.test("cannot reset FxRootTunnel address after it is set", async _test => {
            try {
                await childTunnelProxyInstance.setFxRootTunnel(rootTunnelProxyInstance.address)
                _test.fail("Should not be able to set the root tunnel again")
            } catch (e) {
                _test.pass("Root tunnel address did not change")
            }
        })

        _test.test("Non-owner trying to set connected token address on child fx token proxy contract", async _test => {
            try {
                const nonOwnerSigner = await createSigner(PRIVATE_KEYS[2])(childProvider);
                const contractWithWrongSigner = childFxErc721TokenProxyInstance.connect(nonOwnerSigner)
                await contractWithWrongSigner.updateConnectedToken(rootFxErc721TokenProxyInstance.address)
                _test.fail("Should not be able to update connected token on child Fx proxy contract")
            } catch (e) {
                _test.pass("connected token address did not change on child Fx proxy")
            }
        })

        _test.test("Owner trying to set connected token address on child fx token proxy contract", async _test => {
            try {
                await childFxErc721TokenProxyInstance.updateConnectedToken(rootFxErc721TokenProxyInstance.address)
                _test.pass("Connected token address set successfully")
                _test.test("Owner trying to set connected token address when it is already set", async _test => {
                    try {
                        await childFxErc721TokenProxyInstance.updateConnectedToken(rootFxErc721TokenProxyInstance.address)
                        _test.fail("Connected token address should have changed")
                    } catch (e) {
                        _test.pass("Connected token address did not change")
                    }
                })
            } catch (e) {
                _test.fail("Connected token address should have been set")
            }
        })

        _test.test("Non-owner trying to set connected token address on root fx token proxy contract", async _test => {
            try {
                const nonOwnerSigner = await createSigner(PRIVATE_KEYS[2])(rootProvider);
                const contractWithWrongSigner = rootFxErc721TokenProxyInstance.connect(nonOwnerSigner)
                await contractWithWrongSigner.updateConnectedToken(childFxErc721TokenProxyInstance.address)
                _test.fail("Should not be able to set connected token on root fx token proxy contract")
            } catch (e) {
                _test.pass("connected token address did not change on root fx token proxy")
            }
        })

        _test.test("Owner trying to set connected token address on root fx token proxy contract", async _test => {
            try {
                await rootFxErc721TokenProxyInstance.updateConnectedToken(childFxErc721TokenProxyInstance.address)
                _test.pass("Connected token address set successfully")
                _test.test("Owner trying to set connected token address when it is already set", async _test => {
                    try {
                        await rootFxErc721TokenProxyInstance.updateConnectedToken(childFxErc721TokenProxyInstance.address)
                        _test.fail("Connected token address should have changed")
                    } catch (e) {
                        _test.pass("Connected token address did not change")
                    }
                })
            } catch (e) {
                _test.fail("Connected token address should have been set")
            }
        })

        _test.test("Non-owner trying to set token proxy address on root tunnel proxy contract", async _test => {
            try {
                const nonOwnerSigner = await createSigner(PRIVATE_KEYS[2])(rootProvider);
                const contractWithWrongSigner = rootTunnelProxyInstance.connect(nonOwnerSigner)
                await contractWithWrongSigner.setTokenProxy(rootFxErc721TokenProxyInstance.address)
                _test.fail("Should not be able to set token proxy address on root tunnel proxy contract")
            } catch (e) {
                _test.pass("Token proxy address did not change on root tunnel proxy contract")
            }
        })

        _test.test("Owner trying to set token proxy address on root tunnel proxy contract", async _test => {
            try {
                await rootTunnelProxyInstance.setTokenProxy(rootFxErc721TokenProxyInstance.address)
                _test.pass("Token proxy address set successfully")
                _test.test("Owner trying to set token proxy address when it is already set", async _test => {
                    try {
                        await rootTunnelProxyInstance.setTokenProxy(rootFxErc721TokenProxyInstance.address)
                        _test.fail("Token proxy address should have changed")
                    } catch (e) {
                        _test.pass("Token proxy address did not change")
                    }
                })
            } catch (e) {
                _test.fail("Token proxy address should have been set")
            }
        })

        _test.test("Non-owner trying to set token proxy address on the fx manager proxy contract", async _test => {
            try {
                const nonOwnerSigner = await createSigner(PRIVATE_KEYS[2])(childProvider);
                const contractWithWrongSigner = childFxManagerProxyInstance.connect(nonOwnerSigner)
                await contractWithWrongSigner.setTokenProxy(childFxErc721TokenProxy.contractAddress)
                _test.fail("Token proxy should not be set")
            } catch (e) {
                _test.pass("Token proxy address was not set")
            }
        })

        _test.test("Owner trying to set token proxy address on the fx manager proxy contract", async _test => {
            try {
                await childFxManagerProxyInstance.setTokenProxy(childFxErc721TokenProxy.contractAddress)
                _test.pass("Token proxy address set successfully")
                _test.test("Owner trying to set token proxy address when it is already set", async _test => {
                    try {
                        await childFxManagerProxyInstance.setTokenProxy(childFxErc721TokenProxy.contractAddress)
                        _test.fail("Token proxy address should have changed")
                    } catch (e) {
                        _test.comment("Token proxy address did not change")
                        _test.pass(JSON.stringify({
                            childTokenProxyAddress: childFxErc721TokenProxy.contractAddress,
                            rootTokenProxyAddress: rootFxErc721TokenProxy.contractAddress,
                            childTunnelProxyAddress: childTunnelProxy.contractAddress,
                            rootTunnelProxyAddress: rootTunnelProxy.contractAddress,
                            childAdminProxy: childProxyAdmin.contractAddress,
                            rootAdminProxy: rootProxyAdmin.contractAddress,
                            FxManagerProxy: childFxManagerProxy.contractAddress
                        }, null, 2))
                    }
                })
            } catch (e) {
                _test.fail("Token proxy address should have been set")
            }
        })
    })
}

// After running this function, two new tokens with Ids tokenId and tokenId + 1 will exist
const mint_on_polygon_ = (tokenId) => (tokenUri) => (polygonArtistAddress) => (flowArtistId) => (royaltyReceiver) => async (royaltyNumerator) => {
    const mintingData = await encodeToBytes(["string", "address", "string", "address", "uint96"])([tokenUri, polygonArtistAddress, flowArtistId, royaltyReceiver, royaltyNumerator])
    const childProvider = await createRPCProviders(GANACHE_PROVIDER_CHILD);
    let childSigner = await createSigner(PRIVATE_KEYS[1])(childProvider);
    let childTunnelProxyInstance = await createContractInstance(CHILD_TUNNEL_PROXY_ADDRESS)(childTunnelContractInformation.abi)(childSigner);
    let childTokenProxyInstance = await createContractInstance(CHILD_FX_TOKEN_PROXY_ADDRESS)(fxErc721ContractInformation.abi)(childSigner)

    test("Minting a token on child chain through Fx proxy contract directly", async _test => {

        try {
            await childTokenProxyInstance.mint(ACCOUNT_ADDRESSES[1], tokenId, mintingData)
            _test.fail("Minting should not happen as caller is not FxManager")
        } catch (e) {
            _test.pass("Minting did not happen as caller is not the child tunnel proxy contract")
        }
    })

    test("Minting a token on child chain through proxy tunnel contract", async _test => {

        if (await childTokenProxyInstance.exists(tokenId)) {
            _test.comment(`token with id ${tokenId} already exists`)
            try {
                await childTunnelProxyInstance.mintToken(tokenId, mintingData)
                _test.fail("Token minting should not happen as token already exists")
            } catch (e) {
                _test.pass("Token was not minted")
            }
        } else {
            await childTunnelProxyInstance.mintToken(tokenId, mintingData)
            _test.pass("Token minted successfully")
        }

    })

    test("Pause minting on child chain for contract upgrade, etc...", async _test => {

        _test.test("Non-owner trying to pause contract minting", async _test => {
            try {
                const nonOwnerSigner = await createSigner(PRIVATE_KEYS[2])(childProvider);
                const contractWithWrongSigner = childTokenProxyInstance.connect(nonOwnerSigner)
                await contractWithWrongSigner.pause()
                _test.fail("Minting should not be paused as sender is not owner of proxy")
            } catch (e) {
                await childTunnelProxyInstance.mintToken(tokenId + 1, mintingData)
                _test.pass("Minting was not paused as sender is not owner")
            }
        })

        _test.test("Proxy Owner trying to pause contract minting", async _test => {
            await childTokenProxyInstance.pause()
            if (await childTokenProxyInstance.exists(tokenId + 2)) {
                _test.comment(`token with id ${tokenId + 2} already exists`)
                try {
                    await childTunnelProxyInstance.mintToken(tokenId + 2, mintingData)
                    _test.fail("Token minting should not happen as token already exists")
                } catch (e) {
                    _test.pass("Token was not minted because it already exists ")
                }
            } else {
                try {
                    await childTunnelProxyInstance.mintToken(tokenId + 2, mintingData)
                    _test.fail("Token minting should not happen as token minting is paused")
                } catch (e) {
                    await childTokenProxyInstance.unpause()
                    _test.pass("Token was not minted as minting is paused")
                }

            }
        })
    })

    test("Unpausing minting on proxy contract after upgrade is done", async _test => {

        _test.test("Upgrade child proxy implementation", async _test => {
            try {
                await childTokenProxyInstance.pause()
                const childAdminProxy = await createContractInstance(CHILD_PROXY_ADMIN_ADDRESS)(proxyAdminContractInformation.abi)(childSigner);

                let FxERC721Child = await deployContract(childSigner)(fxErc721ContractInformation.abi)(fxErc721ContractInformation.bytecode)([])
                await childAdminProxy.upgrade(CHILD_FX_TOKEN_PROXY_ADDRESS, FxERC721Child.contractAddress)

                // update instances to use new implementations
                childTokenProxyInstance = await createContractInstance(CHILD_FX_TOKEN_PROXY_ADDRESS)(fxErc721ContractInformation.abi)(childSigner)
                childTunnelProxyInstance = await createContractInstance(CHILD_TUNNEL_PROXY_ADDRESS)(childTunnelContractInformation.abi)(childSigner);
                _test.pass("Upgrading done successfully")
            } catch (e) {
                _test.fail("Something went wrong while upgrading:\n", e)
            }
        })

        _test.test("Make sure old tokens still exist after upgrade", async _test => {
            if (await childTokenProxyInstance.exists(tokenId)) {
                _test.pass("previous minted still token exists")
            } else {
                _test.fail("previous minted still token does not exist")
            }
        })

        _test.test("Try minting before unpausing", async _test => {
            try {
                await childTunnelProxyInstance.mintToken(tokenId + 1, mintingData)
                _test.fail("Token minting should not happen as token minting is paused")
            } catch (e) {
                _test.pass("Token was not minted as minting is paused")
            }
        })

        _test.test("Non-owner trying to unpause minting on contract", async _test => {
            try {
                const nonOwnerSigner = await createSigner(PRIVATE_KEYS[2])(childProvider);
                const contractWithWrongSigner = childTokenProxyInstance.connect(nonOwnerSigner)
                await contractWithWrongSigner.unpause()
                _test.fail("Minting should not be unpaused as sender is not owner of proxy")
            } catch (e) {
                _test.pass("Minting was not unpaused as sender is not owner")
            }
        })

        _test.test("Owner unpausing and minting a new token", async _test => {
            await childTokenProxyInstance.unpause()
            await childTunnelProxyInstance.mintToken(tokenId + 2, mintingData)
            _test.pass("Token minted successfully after unpausing")
        })

    })
}

const burning_on_polygon_and_transfer_to_ethereum_ = (tokenId) => (tokenUri) => (polygonArtistAddress) => (flowArtistId) => (royaltyReceiver) => async (royaltyNumerator) => {
    const childProvider = await createRPCProviders(GANACHE_PROVIDER_CHILD);
    const rootProvider = await createRPCProviders(GANACHE_PROVIDER_ROOT)

    let childSigner = await createSigner(PRIVATE_KEYS[1])(childProvider);
    let rootSigner = await createSigner(PRIVATE_KEYS[0])(rootProvider);

    const mintingData = await encodeToBytes(["string", "address", "string", "address", "uint96"])([tokenUri, polygonArtistAddress, flowArtistId, royaltyReceiver, royaltyNumerator])
    let childTunnelProxyInstance = await createContractInstance(CHILD_TUNNEL_PROXY_ADDRESS)(childTunnelContractInformation.abi)(childSigner);
    let rootTunnelProxyInstance = await createContractInstance(ROOT_TUNNEL_PROXY_ADDRESS)(rootTunnelContractInformation.abi)(rootSigner);

    let childTokenProxyInstance = await createContractInstance(CHILD_FX_TOKEN_PROXY_ADDRESS)(fxErc721ContractInformation.abi)(childSigner)
    let rootTokenProxyInstance = await createContractInstance(ROOT_FX_TOKEN_PROXY_ADDRESS)(fxErc721ContractInformation.abi)(rootSigner);

    test("Burning on child chain by calling Fx Proxy contract directly", async _test => {
        try {
            await childTokenProxyInstance.burn(tokenId)
            _test.fail("Burning should not happen as caller is not FxManager")
        } catch (e) {
            _test.pass("Burning did not happen as caller is not the child tunnel proxy contract")
        }
    })

    test("Burning on child chain a token that does not exist", async _test => {
        try {
            await childTunnelProxyInstance.withdraw(1000000000000000)
            _test.fail("Burning should not happen as caller is not FxManager")
        } catch (e) {
            _test.pass("Burning did not happen as caller is not the child tunnel proxy contract")
        }
    })

    test("Pause Burning on child chain for contract upgrade, etc...", async _test => {

        _test.test("Non-owner trying to pause contract burning", async _test => {
            try {
                const nonOwnerSigner = await createSigner(PRIVATE_KEYS[2])(childProvider);
                const contractWithWrongSigner = childTokenProxyInstance.connect(nonOwnerSigner)
                await contractWithWrongSigner.pause()
                _test.fail("Burning should not be paused as sender is not owner of proxy")
            } catch (e) {
                if (!await childTokenProxyInstance.exists(tokenId)) {
                    _test.comment("Minting token")
                    await childTunnelProxyInstance.mintToken(tokenId, mintingData)
                    _test.comment("Token minted")
                }
                await childTunnelProxyInstance.withdraw(tokenId)
                _test.comment("Token got burned")
                _test.pass("Burning was not paused as sender is not owner")
            }
        })

        _test.test("Proxy Owner trying to pause contract burning", async _test => {
            try {
                if (!await childTokenProxyInstance.exists(tokenId)) {
                    _test.comment("Minting token")
                    await childTunnelProxyInstance.mintToken(tokenId, mintingData)
                    _test.comment("Token minted")
                }
                await childTokenProxyInstance.pause()
                await childTunnelProxyInstance.withdraw(tokenId)
                _test.fail("Token should not have been burned")
            } catch (e) {
                await childTokenProxyInstance.unpause()
                _test.pass("Token was not burned")
            }
        })
    })

    test("Unpausing minting on proxy contract after upgrade is done", async _test => {

        _test.test("Upgrade child proxy implementation", async _test => {
            try {
                await childTokenProxyInstance.pause()
                const childAdminProxy = await createContractInstance(CHILD_PROXY_ADMIN_ADDRESS)(proxyAdminContractInformation.abi)(childSigner);

                let FxERC721Child = await deployContract(childSigner)(fxErc721ContractInformation.abi)(fxErc721ContractInformation.bytecode)([])
                await childAdminProxy.upgrade(CHILD_FX_TOKEN_PROXY_ADDRESS, FxERC721Child.contractAddress)

                // update instances to use new implementations
                childTokenProxyInstance = await createContractInstance(CHILD_FX_TOKEN_PROXY_ADDRESS)(fxErc721ContractInformation.abi)(childSigner)
                childTunnelProxyInstance = await createContractInstance(CHILD_TUNNEL_PROXY_ADDRESS)(childTunnelContractInformation.abi)(childSigner);
                _test.pass("Upgrading done successfully")
            } catch (e) {
                _test.fail("Something went wrong while upgrading:\n", e)
            }
        })

        _test.test("Try burning before unpausing", async _test => {
            try {
                if (!await childTokenProxyInstance.exists(tokenId)) {
                    _test.comment("Minting token")
                    await childTunnelProxyInstance.mintToken(tokenId, mintingData)
                    _test.comment("Token minted")
                }
                await childTunnelProxyInstance.withdraw(tokenId)
                _test.fail("Token burning should not happen as contract is paused")
            } catch (e) {
                _test.pass("Token was not burned as contract is paused")
            }
        })

        _test.test("Non-owner trying to unpause burning on contract", async _test => {
            try {
                const nonOwnerSigner = await createSigner(PRIVATE_KEYS[2])(childProvider);
                const contractWithWrongSigner = childTokenProxyInstance.connect(nonOwnerSigner)
                await contractWithWrongSigner.unpause()
                _test.fail("contract should not be unpaused as sender is not owner of proxy")
            } catch (e) {
                _test.pass("contract was not unpaused as sender is not owner")
            }
        })

        _test.test("Owner unpausing and burning a token", async _test => {
            await childTokenProxyInstance.unpause()
            if (!await childTokenProxyInstance.exists(tokenId)) {
                _test.comment("Minting token")
                await childTunnelProxyInstance.mintToken(tokenId, mintingData)
                _test.comment("Token minted")
            }
            await childTunnelProxyInstance.withdraw(tokenId)
            _test.pass("Token minted successfully after unpausing")
        })

    })

    test("Burning a token on polygon and withdraw to ethereum through proxy", async _test => {
        try {

            if (!(await childTokenProxyInstance.exists(tokenId))) {
                _test.comment("Minting token")
                await childTunnelProxyInstance.mintToken(tokenId, mintingData)
                _test.comment("Token minted")
            }

            // Test whether a non-owner could burn another user's token or not
            const nonOwnerSigner = await createSigner(PRIVATE_KEYS[2])(childProvider);
            const contractWithWrongSigner = childTunnelProxyInstance.connect(nonOwnerSigner)
            _test.test("Non-owner of a token trying to burn the token", async _test => {
                try {
                    await contractWithWrongSigner.withdraw(tokenId)
                    _test.fail("Non-owner should not be able to burn the token")
                } catch (e) {
                    _test.pass("Token not burned as caller is not owner")
                }
            })

            const tx = await childTunnelProxyInstance.withdraw(tokenId)
            _test.comment("Token burned and withdrawn")
            const logs = await tx.wait()
            const nftData = logs.events.filter(event => event.event === 'MessageSent')
            await rootTunnelProxyInstance.receiveMessage(nftData[0].args[0])
            _test.ok(await rootTokenProxyInstance.exists(tokenId), "Token minted/transferred to ethereum account successfully")
        } catch (e) {
            _test.fail(e)
        }
    })
}

const ethereum_to_polygon_transfer_ = (userAddress) => (tokenId) => (tokenUri) => (polygonArtistAddress) => (flowArtistId) => (royaltyReceiver) => async (royaltyNumerator) => {

    const childProvider = await createRPCProviders(GANACHE_PROVIDER_CHILD);
    const rootProvider = await createRPCProviders(GANACHE_PROVIDER_ROOT)

    let childSigner = await createSigner(PRIVATE_KEYS[1])(childProvider);
    let rootSigner = await createSigner(PRIVATE_KEYS[1])(rootProvider);

    const childTunnelProxyInstance = await createContractInstance(CHILD_TUNNEL_PROXY_ADDRESS)(childTunnelContractInformation.abi)(childSigner);
    const childTokenProxyInstace = await createContractInstance(CHILD_FX_TOKEN_PROXY_ADDRESS)(fxErc721ContractInformation.abi)(childSigner)
    const rootTunnelProxyInstance = await createContractInstance(ROOT_TUNNEL_PROXY_ADDRESS)(rootTunnelContractInformation.abi)(rootSigner);
    const rootTokenProxyInstance = await createContractInstance(ROOT_FX_TOKEN_PROXY_ADDRESS)(fxErc721ContractInformation.abi)(rootSigner);

    test("Transfer of an exisitng token from ethereum to polygon without owner's approval", async _test => {
        try {

            const transactionReceipt = await rootTunnelProxyInstance.deposit(userAddress, tokenId)
            const logs = await transactionReceipt.wait()

            const nftData = logs.events.filter(event => event.event === 'rootToChild')

            await childTunnelProxyInstance.syncDeposit(ROOT_TUNNEL_PROXY_ADDRESS, nftData[0].args[0])
            _test.fail("Token should not be deposited to polygon")
        } catch (e) {
            _test.pass("Token was not deposited as owner did not provide approval")
        }
    })

    test("Attempt to transfer a non-existent token from ethereum to polygon", async _test => {
        try {

            const transactionReceipt = await rootTunnelProxyInstance.deposit(userAddress, 1000000000000000)
            const logs = await transactionReceipt.wait()

            const nftData = logs.events.filter(event => event.event === 'rootToChild')

            await childTunnelProxyInstance.syncDeposit(ROOT_TUNNEL_PROXY_ADDRESS, nftData[0].args[0])
            _test.fail("Token should not be deposited to polygon")
        } catch (e) {
            _test.pass("Token was not deposited as it does not exist on ethereum")
        }
    })

    test("Transfer of an exisitng token from ethereum to polygon", async _test => {
        try {
            if (await rootTokenProxyInstance.ownerOf(tokenId) == ACCOUNT_ADDRESSES[1]) {

                // Who ever uses this to approve should be the owner of the contract
                await rootTokenProxyInstance.approve(ROOT_TUNNEL_PROXY_ADDRESS, tokenId)

                _test.test("Trying to deposit to polygon with owner's approval when transfering is paused", async _test => {
                    const rootTokenProxySigner = await createSigner(PRIVATE_KEYS[0])(rootProvider)
                    const rootTokenProxyOwnerSigner = rootTokenProxyInstance.connect(rootTokenProxySigner)
                    try {
                        await rootTokenProxyOwnerSigner.pause()
                        await rootTunnelProxyInstance.deposit(userAddress, tokenId)
                        _test.fail("Deposit should not happen as contract is paused")
                    } catch (e) {
                        await rootTokenProxyOwnerSigner.unpause()
                        _test.pass("Transfer did not happen as contract is paused")
                    }

                })

                _test.test("transfer of token with owner's approval while contract is unpaused", async _test => {
                    const transactionReceipt = await rootTunnelProxyInstance.deposit(userAddress, tokenId)
                    const logs = await transactionReceipt.wait()

                    const nftData = logs.events.filter(event => event.event === 'rootToChild')

                    await childTunnelProxyInstance.syncDeposit(ROOT_TUNNEL_PROXY_ADDRESS, nftData[0].args[0])

                    if (childTokenProxyInstace.exists(tokenId)) {
                        _test.pass("Token transferred to polygon successfully")
                    } else {
                        _test.fail("Something went wrong while transferring to polygon")
                    }
                })
            } else {
                _test.fail("signer account not owner of token")
            }
        } catch (e) {
            _test.fail(e)
        }
    })
}


// deploy_contracts_("test200")("tt1")
// mint_on_polygon_(0)("QmcRXwGFhEBGsV6DMioaHPKXAxnTcStDfdP1zV86z5sXCz")(ACCOUNT_ADDRESSES[1])("0x0")(ACCOUNT_ADDRESSES[1])(500)
// burning_on_polygon_and_transfer_to_ethereum_(2)("QmcRXwGFhEBGsV6DMioaHPKXAxnTcStDfdP1zV86z5sXCz")(ACCOUNT_ADDRESSES[1])("0x0")(ACCOUNT_ADDRESSES[1])(500)
// ethereum_to_polygon_transfer_(ACCOUNT_ADDRESSES[1])(2)("QmcRXwGFhEBGsV6DMioaHPKXAxnTcStDfdP1zV86z5sXCz")(ACCOUNT_ADDRESSES[1])("0x0")(ACCOUNT_ADDRESSES[1])(500)
// burning_on_polygon_and_transfer_to_ethereum_(2)("QmcRXwGFhEBGsV6DMioaHPKXAxnTcStDfdP1zV86z5sXCz")(ACCOUNT_ADDRESSES[1])("0x0")(ACCOUNT_ADDRESSES[1])(500)
// ethereum_to_polygon_transfer_(ACCOUNT_ADDRESSES[1])(2)("QmcRXwGFhEBGsV6DMioaHPKXAxnTcStDfdP1zV86z5sXCz")(ACCOUNT_ADDRESSES[1])("0x0")(ACCOUNT_ADDRESSES[1])(500)

