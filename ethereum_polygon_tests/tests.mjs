import test from 'tape';
import * as fs from 'fs'
import {
    deployContract, createSigner, createRPCProviders, createContractInstance, encodeToBytes, createAndEncodeFunctionInterface
} from '../ethereum-api.mjs';
import {
    CHILD_TUNNEL_PROXY_ADDRESS, ROOT_TUNNEL_PROXY_ADDRESS, CHILD_TOKEN_PROXY_ADDRESS, ROOT_TOKEN_PROXY_ADDRESS,
    CHILD_ADMIN_PROXY, ROOT_ADMIN_PROXY
} from '../config.mjs';
import {
    ACCOUNT_ADDRESSES, PRIVATE_KEYS, GANACHE_PROVIDER_CHILD, GANACHE_PROVIDER_ROOT
} from '../config.mjs';

const fxErc721ContractInformation = JSON.parse(fs.readFileSync('./build/contracts/FxERC721.json', 'utf8'));
const rootTunnelContractInformation = JSON.parse(fs.readFileSync('./build/contracts/FxERC721RootTunnel.json', 'utf8'));
const childTunnelContractInformation = JSON.parse(fs.readFileSync('./build/contracts/FxERC721ChildTunnel.json', 'utf8'));
const proxyAdminContractInformation = JSON.parse(fs.readFileSync('./build/contracts/ProxyAdmin.json', 'utf8'));
const transparentProxyContractInformation = JSON.parse(fs.readFileSync('./build/contracts/TransparentUpgradeableProxy.json', 'utf8'));

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
 * Deploy root and child Tunnels on Ethereum and polygon respectively
 * Deploy root and child Tunnels proxies on ethereum and polygon respectively with data variable containing the initialize function encoded 
   with required arguments
 * Deploy FxERC721 proxies on both Ethereum and polygon with data variable containing the initialize function encoded with required arguments 
   and connected_token address to 0x0
 * Set the tunnels proxy addresses when u get the proxy addresses
 * Set Fxroot and FxChild addresses respectively 
*/

// NB: After deploying, change the contract addresses in the config file
const deploy_contracts_ = async () => {
    test("Deploy all contracts", async _test => {

        const rootProvider = await createRPCProviders(GANACHE_PROVIDER_ROOT);
        const childProvider = await createRPCProviders(GANACHE_PROVIDER_CHILD);

        const rootSigner = await createSigner(PRIVATE_KEYS[0])(rootProvider);
        const childSigner = await createSigner(PRIVATE_KEYS[1])(childProvider);

        // Deploy admin proxy contracts that manage all other proxy contracts and are used to upgrade proxy implementations
        let adminProxyRoot = await deployContract(rootSigner)(proxyAdminContractInformation.abi)(proxyAdminContractInformation.bytecode)([])
        let adminProxyChild = await deployContract(childSigner)(proxyAdminContractInformation.abi)(proxyAdminContractInformation.bytecode)([])

        // Deploy FxERC721 Token Contract
        let FxERC721Root = await deployContract(rootSigner)(fxErc721ContractInformation.abi)(fxErc721ContractInformation.bytecode)([])
        let FxERC721Child = await deployContract(childSigner)(fxErc721ContractInformation.abi)(fxErc721ContractInformation.bytecode)([])

        // Deploy root and child tunnel contracts on ethereum and polygon respectively
        let rootTunnel = await deployContract(rootSigner)(rootTunnelContractInformation.abi)(rootTunnelContractInformation.bytecode)([])
        let childTunnel = await deployContract(childSigner)(childTunnelContractInformation.abi)(childTunnelContractInformation.bytecode)([])

        // Deploy the TransparentUpgradeable proxy for the child tunnel on polygon
        const childTunnelInitializerEncoded = await createAndEncodeFunctionInterface("function initialize(address _fxChild)")("initialize")
            (["0x0000000000000000000000000000000000000000"])
        let childTunnelProxy = await deployContract(childSigner)(transparentProxyContractInformation.abi)
            (transparentProxyContractInformation.bytecode)
            ([childTunnel.contractAddress, adminProxyChild.contractAddress, childTunnelInitializerEncoded])

        // Deploy the TransparentUpgradeable proxy for the root tunnel on ethereum
        const rootTunnelInitializerEncoded = await createAndEncodeFunctionInterface
            ("function initialize(address _checkpointManager, address _fxRoot)")("initialize")
            (["0x0000000000000000000000000000000000000000", "0x0000000000000000000000000000000000000000"])

        let rootTunnelProxy = await deployContract(rootSigner)(transparentProxyContractInformation.abi)
            (transparentProxyContractInformation.bytecode)
            ([rootTunnel.contractAddress, adminProxyRoot.contractAddress, rootTunnelInitializerEncoded])

        // Deploy proxy contract for FxERC721 Token on polygon
        const fxERC721ChildInitializerEncoded = await createAndEncodeFunctionInterface
            ("function initialize(address fxManager_,address connectedToken_,string memory name_,string memory symbol_)")
            ("initialize")([childTunnelProxy.contractAddress, "0x0000000000000000000000000000000000000000", "test101", "tst"])

        let fxERC721ChildProxy = await deployContract(childSigner)(transparentProxyContractInformation.abi)
            (transparentProxyContractInformation.bytecode)
            ([FxERC721Child.contractAddress, adminProxyChild.contractAddress, fxERC721ChildInitializerEncoded])

        const fxERC721RootInitializerEncoded = await createAndEncodeFunctionInterface
            ("function initialize(address fxManager_,address connectedToken_,string memory name_,string memory symbol_)")
            ("initialize")([rootTunnelProxy.contractAddress, "0x0000000000000000000000000000000000000000", "test101", "tst"])

        let fxERC721RootProxy = await deployContract(rootSigner)(transparentProxyContractInformation.abi)
            (transparentProxyContractInformation.bytecode)
            ([FxERC721Root.contractAddress, adminProxyRoot.contractAddress, fxERC721RootInitializerEncoded])

        const childTunnelProxyInstance = await createContractInstance(childTunnelProxy.contractAddress)(childTunnelContractInformation.abi)(childSigner)
        const rootTunnelProxyInstance = await createContractInstance(rootTunnelProxy.contractAddress)(rootTunnelContractInformation.abi)(rootSigner)

        const childFxERC721ProxyInstance = await createContractInstance(fxERC721ChildProxy.contractAddress)(fxErc721ContractInformation.abi)(childSigner)
        const rootFxERC721ProxyInstance = await createContractInstance(fxERC721RootProxy.contractAddress)(fxErc721ContractInformation.abi)(rootSigner)

        const addressObject = {
            childProxyToken: childFxERC721ProxyInstance.address,
            rootProxyToken: rootFxERC721ProxyInstance.address,
            childTunnelProxy: childTunnelProxyInstance.address,
            rootTunnelProxy: rootTunnelProxyInstance.address,
            childAdminProxy: adminProxyChild.contractAddress,
            rootAdminProxy: adminProxyRoot.contractAddress,
        }

        _test.pass(JSON.stringify(addressObject, null, '\t'))

        _test.test("Non-owner trying to updateConnectedToken on child Fx proxy token", async _test => {
            try {
                const nonOwnerSigner = await createSigner(PRIVATE_KEYS[2])(childProvider);
                const contractWithWrongSigner = childFxERC721ProxyInstance.connect(nonOwnerSigner)
                await contractWithWrongSigner.updateConnectedToken(rootFxERC721ProxyInstance.address)
                _test.fail("Should not be able to update connected token on child Fx proxy contract")
            } catch (e) {
                _test.pass("connected token address did not change on child Fx proxy")
            }
        })

        _test.test("Non-owner trying to updateConnectedToken on root Fx proxy token", async _test => {
            try {
                const nonOwnerSigner = await createSigner(PRIVATE_KEYS[2])(rootProvider);
                const contractWithWrongSigner = rootFxERC721ProxyInstance.connect(nonOwnerSigner)
                await contractWithWrongSigner.updateConnectedToken(childFxERC721ProxyInstance.address)
                _test.fail("Should not be able to update connected token on root Fx proxy contract")
            } catch (e) {
                _test.pass("connected token address did not change on root Fx proxy")
            }
        })

        await childFxERC721ProxyInstance.updateConnectedToken(rootFxERC721ProxyInstance.address)
        await rootFxERC721ProxyInstance.updateConnectedToken(childFxERC721ProxyInstance.address)

        _test.test("cannot reset child tunnel connected proxy token address after it is set", async _test => {
            try {
                await childFxERC721ProxyInstance.updateConnectedToken(rootFxERC721ProxyInstance.address)
                _test.fail("Should not be able to set connected proxy token address again")
            } catch (e) {
                _test.pass("Root tunnel address did not change")
            }
        })

        _test.test("cannot reset root tunnel connected proxy token address after it is set", async _test => {
            try {
                await rootFxERC721ProxyInstance.updateConnectedToken(childFxERC721ProxyInstance.address)
                _test.fail("Should not be able to set the connected proxy token address  again")
            } catch (e) {
                _test.pass("Root tunnel address did not change")
            }
        })

        _test.test("Non-owner trying to setProxy addresses on child tunnel proxy", async _test => {
            try {
                const nonOwnerSigner = await createSigner(PRIVATE_KEYS[2])(childProvider);
                const contractWithWrongSigner = childTunnelProxyInstance.connect(nonOwnerSigner)
                await contractWithWrongSigner.setProxyAddresses(childFxERC721ProxyInstance.address, rootFxERC721ProxyInstance.address)
                _test.fail("Proxy addresses should not have been set since signer is not the owner")
            } catch (e) {
                _test.pass("Non-owner signer could not set proxy addresses on child tunnel proxy")
            }
        })

        _test.test("Non-owner trying to setProxy addresses on root tunnel proxy", async _test => {
            try {
                const nonOwnerSigner = await createSigner(PRIVATE_KEYS[2])(rootProvider);
                const contractWithWrongSigner = rootTunnelProxyInstance.connect(nonOwnerSigner)
                await contractWithWrongSigner.setProxyAddresses(childFxERC721ProxyInstance.address, rootFxERC721ProxyInstance.address)
                _test.fail("Proxy addresses should not have been set since signer is not the owner")
            } catch (e) {
                _test.pass("Non-owner signer could not set proxy addresses on root tunnel proxy")
            }
        })

        await childTunnelProxyInstance.setProxyAddresses(childFxERC721ProxyInstance.address, rootFxERC721ProxyInstance.address)
        await rootTunnelProxyInstance.setProxyAddresses(childFxERC721ProxyInstance.address, rootFxERC721ProxyInstance.address)

        _test.test("cannot reset child tunnel proxy addresses after it is set", async _test => {
            try {
                await childTunnelProxyInstance.setProxyAddresses(childFxERC721ProxyInstance.address, rootFxERC721ProxyInstance.address)
                _test.fail("Should not be able to set proxy addresses again")
            } catch (e) {
                _test.pass("Root tunnel address did not change")
            }
        })

        _test.test("cannot reset root tunnel proxy addresses after it is set", async _test => {
            try {
                await rootTunnelProxyInstance.setProxyAddresses(childFxERC721ProxyInstance.address, rootFxERC721ProxyInstance.address)
                _test.fail("Should not be able to set the proxy addresses again")
            } catch (e) {
                _test.pass("Root tunnel address did not change")
            }
        })

        await childTunnelProxyInstance.setFxRootTunnel(rootTunnelProxyInstance.address)
        await rootTunnelProxyInstance.setFxChildTunnel(childTunnelProxyInstance.address)

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
    })
}

// After running this function, two new tokens with Ids tokenId and tokenId + 1 will exist
const mint_on_polygon_ = (tokenId) => (tokenUri) => (royaltyReceiver) => async (royaltyNumerator) => {
    const mintingData = await encodeToBytes(["string", "address", "uint96"])([tokenUri, royaltyReceiver, royaltyNumerator])
    const childProvider = await createRPCProviders(GANACHE_PROVIDER_CHILD);
    let childSigner = await createSigner(PRIVATE_KEYS[1])(childProvider);
    let childTunnelProxyInstance = await createContractInstance(CHILD_TUNNEL_PROXY_ADDRESS)(childTunnelContractInformation.abi)(childSigner);
    let childTokenProxyInstance = await createContractInstance(CHILD_TOKEN_PROXY_ADDRESS)(fxErc721ContractInformation.abi)(childSigner)

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
                const childAdminProxy = await createContractInstance(CHILD_ADMIN_PROXY)(proxyAdminContractInformation.abi)(childSigner);

                let FxERC721Child = await deployContract(childSigner)(fxErc721ContractInformation.abi)(fxErc721ContractInformation.bytecode)([])
                await childAdminProxy.upgrade(CHILD_TOKEN_PROXY_ADDRESS, FxERC721Child.contractAddress)

                // update instances to use new implementations
                childTokenProxyInstance = await createContractInstance(CHILD_TOKEN_PROXY_ADDRESS)(fxErc721ContractInformation.abi)(childSigner)
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

const burning_on_polygon_and_transfer_to_ethereum_ = (tokenId) => (tokenUri) => (royaltyReceiver) => async (royaltyNumerator) => {
    const childProvider = await createRPCProviders(GANACHE_PROVIDER_CHILD);
    const rootProvider = await createRPCProviders(GANACHE_PROVIDER_ROOT)

    let childSigner = await createSigner(PRIVATE_KEYS[1])(childProvider);
    let rootSigner = await createSigner(PRIVATE_KEYS[0])(rootProvider);

    const mintingData = await encodeToBytes(["string", "address", "uint96"])([tokenUri, royaltyReceiver, royaltyNumerator])

    let childTunnelProxyInstance = await createContractInstance(CHILD_TUNNEL_PROXY_ADDRESS)(childTunnelContractInformation.abi)(childSigner);
    let rootTunnelProxyInstance = await createContractInstance(ROOT_TUNNEL_PROXY_ADDRESS)(rootTunnelContractInformation.abi)(rootSigner);

    let childTokenProxyInstance = await createContractInstance(CHILD_TOKEN_PROXY_ADDRESS)(fxErc721ContractInformation.abi)(childSigner)
    let rootTokenProxyInstance = await createContractInstance(ROOT_TOKEN_PROXY_ADDRESS)(fxErc721ContractInformation.abi)(rootSigner);

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
            await childTunnelProxyInstance.withdraw(1000000000000000, tokenUri, royaltyReceiver, royaltyNumerator)
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
                await childTunnelProxyInstance.withdraw(tokenId, tokenUri, royaltyReceiver, royaltyNumerator)
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
                await childTunnelProxyInstance.withdraw(tokenId, tokenUri, royaltyReceiver, royaltyNumerator)
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
                const childAdminProxy = await createContractInstance(CHILD_ADMIN_PROXY)(proxyAdminContractInformation.abi)(childSigner);

                let FxERC721Child = await deployContract(childSigner)(fxErc721ContractInformation.abi)(fxErc721ContractInformation.bytecode)([])
                await childAdminProxy.upgrade(CHILD_TOKEN_PROXY_ADDRESS, FxERC721Child.contractAddress)

                // update instances to use new implementations
                childTokenProxyInstance = await createContractInstance(CHILD_TOKEN_PROXY_ADDRESS)(fxErc721ContractInformation.abi)(childSigner)
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
                await childTunnelProxyInstance.withdraw(tokenId, tokenUri, royaltyReceiver, royaltyNumerator)
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
            await childTunnelProxyInstance.withdraw(tokenId, tokenUri, royaltyReceiver, royaltyNumerator)
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
                    await contractWithWrongSigner.withdraw(tokenId, tokenUri, royaltyReceiver, royaltyNumerator)
                    _test.fail("Non-owner should not be able to burn the token")
                } catch (e) {
                    _test.pass("Token not burned as caller is not owner")
                }
            })

            const tx = await childTunnelProxyInstance.withdraw(tokenId, tokenUri, royaltyReceiver, royaltyNumerator)
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

const ethereum_to_polygon_transfer_ = (userAddress) => (tokenId) => (tokenUri) => (royaltyReceiver) => async (royaltyNumerator) => {

    const childProvider = await createRPCProviders(GANACHE_PROVIDER_CHILD);
    const rootProvider = await createRPCProviders(GANACHE_PROVIDER_ROOT)

    let childSigner = await createSigner(PRIVATE_KEYS[1])(childProvider);
    let rootSigner = await createSigner(PRIVATE_KEYS[1])(rootProvider);

    const childTunnelProxyInstance = await createContractInstance(CHILD_TUNNEL_PROXY_ADDRESS)(childTunnelContractInformation.abi)(childSigner);
    const childTokenProxyInstace = await createContractInstance(CHILD_TOKEN_PROXY_ADDRESS)(fxErc721ContractInformation.abi)(childSigner)
    const rootTunnelProxyInstance = await createContractInstance(ROOT_TUNNEL_PROXY_ADDRESS)(rootTunnelContractInformation.abi)(rootSigner);
    const rootTokenProxyInstance = await createContractInstance(ROOT_TOKEN_PROXY_ADDRESS)(fxErc721ContractInformation.abi)(rootSigner);

    test("Transfer of an exisitng token from ethereum to polygon without owner's approval", async _test => {
        try {

            const transactionReceipt = await rootTunnelProxyInstance.deposit(userAddress, tokenId, tokenUri, royaltyReceiver, royaltyNumerator)
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

            const transactionReceipt = await rootTunnelProxyInstance.deposit(userAddress, 1000000000000000, tokenUri, royaltyReceiver, royaltyNumerator)
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
                        await rootTunnelProxyInstance.deposit(userAddress, tokenId, tokenUri, royaltyReceiver, royaltyNumerator)
                        _test.fail("Deposit should not happen as contract is paused")
                    } catch (e) {
                        await rootTokenProxyOwnerSigner.unpause()
                        _test.pass("Transfer did not happen as contract is paused")
                    }

                })

                _test.test("transfer of token with owner's approval while contract is unpaused", async _test => {
                    const transactionReceipt = await rootTunnelProxyInstance.deposit(userAddress, tokenId, tokenUri, royaltyReceiver, royaltyNumerator)
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


// deploy_contracts_()
// mint_on_polygon_(5)("QmcRXwGFhEBGsV6DMioaHPKXAxnTcStDfdP1zV86z5sXCz")(ACCOUNT_ADDRESSES[1])(500)
// burning_on_polygon_and_transfer_to_ethereum_(7)("QmcRXwGFhEBGsV6DMioaHPKXAxnTcStDfdP1zV86z5sXCz")(ACCOUNT_ADDRESSES[1])(500)
// ethereum_to_polygon_transfer_(ACCOUNT_ADDRESSES[1])(7)("QmcRXwGFhEBGsV6DMioaHPKXAxnTcStDfdP1zV86z5sXCz")(ACCOUNT_ADDRESSES[1])(500)
// burning_on_polygon_and_transfer_to_ethereum_(7)("QmcRXwGFhEBGsV6DMioaHPKXAxnTcStDfdP1zV86z5sXCz")(ACCOUNT_ADDRESSES[1])(500)
// ethereum_to_polygon_transfer_(ACCOUNT_ADDRESSES[1])(7)("QmcRXwGFhEBGsV6DMioaHPKXAxnTcStDfdP1zV86z5sXCz")(ACCOUNT_ADDRESSES[1])(500)