import test from 'tape';
import {
    deployContracts, createSigner, transferToEthereum, createRPCProviders, setFxChildTunnel,
    setFxRootTunnel, deployChildToken, createContractInstance, changeArrToBytes
} from './test_functions.mjs';
import {
    templateContractInformation, rootTunnelContractInformation, childTunnelContractInformation
} from './test_functions.mjs';

import { ACCOUNT_ADDRESSES, PRIVATE_KEYS, ROOT_TUNNEL_CONTRACT_ADDRESS, CHILD_TUNNEL_CONTRACT_ADDRESS, ROOT_TOKEN_ADDRESS, CHILD_TOKEN_ADDRESS } from '../config.mjs';

const deploy_contracts_ = async () => {
    test("deploy contracts", async _test => {
        const [parentProvider, childProvider] = await createRPCProviders()
        const parentSigner = await createSigner(PRIVATE_KEYS[0])(parentProvider);
        const childSigner = await createSigner(PRIVATE_KEYS[1])(childProvider);
        const [rootTunnelInstance, childTunnelInstance] = await deployContracts(parentSigner)(childSigner);

        await setFxChildTunnel(rootTunnelInstance)(childTunnelInstance)
        await setFxRootTunnel(childTunnelInstance)(rootTunnelInstance)

        const expected = JSON.stringify({
            rootTunnelAddress: rootTunnelInstance.address,
            childTunnelAddress: childTunnelInstance.address,
        })

        const actual = JSON.stringify({
            rootTunnelAddress: await childTunnelInstance.fxRootTunnel(),
            childTunnelAddress: await rootTunnelInstance.fxChildTunnel(),
        })
        _test.comment(expected)
        _test.equal(actual, expected)

        _test.test("cannot reset FxChildTunnel address after it is set", async _test => {
            try {
                await setFxChildTunnel(rootTunnelInstance)(childTunnelInstance)
                _test.fail("Should not be able to set the child tunnel again")
            } catch (e) {
                _test.pass("Child tunnel address did not change")
            }
        })

        _test.test("cannot reset FxRootTunnel address after it is set", async _test => {
            try {
                await setFxRootTunnel(childTunnelInstance)(rootTunnelInstance)
                _test.fail("Should not be able to set the root tunnel again")
            } catch (e) {
                _test.pass("Root tunnel address did not change")
            }
        })
    })
}

const deploy_token_ = (uniqueId) => (name) => async (symbol) => {
    test("deploy child Token and map it to root", async _test => {
        const [parentProvider, childProvider] = await createRPCProviders()
        const childSigner = await createSigner(PRIVATE_KEYS[1])(childProvider);
        const childTunnelInstance = await createContractInstance(CHILD_TUNNEL_CONTRACT_ADDRESS)(childTunnelContractInformation.abi)(childSigner);

        const expected = JSON.stringify({
            name: name,
            symbol: symbol
        })

        const mappedTokenAddresses = await deployChildToken(childTunnelInstance)(uniqueId)(name)(symbol)
        const childTokenInstance = await createContractInstance(mappedTokenAddresses["childAddress"])(templateContractInformation.abi)(childSigner);
        const actual = JSON.stringify({
            name: await childTokenInstance.name(),
            symbol: await childTokenInstance.symbol(),
        })

        _test.comment(JSON.stringify(mappedTokenAddresses))
        _test.equals(actual, expected)
        _test.test("Deploy an already exisiting child token that is mapped", async _test => {
            try {
                await deployChildToken(childTunnelInstance)(uniqueId)(name)(symbol)
                _test.fail("Should not be deployed")
            } catch (e) {
                _test.pass(`child token associated with ID ${uniqueId} already deployed`)
            }
        })
    })
}

const send_mint_or_burn_approval_ = (childTokenAddress) => (approval) => async (tokenId) => {
    test("Owner sending approval for token", async _test => {
        const [parentProvider, childProvider] = await createRPCProviders()
        let childSigner = await createSigner(PRIVATE_KEYS[1])(childProvider);
        const childTunnelInstance = await createContractInstance(CHILD_TUNNEL_CONTRACT_ADDRESS)(childTunnelContractInformation.abi)(childSigner);
        try {
            await childTunnelInstance.sendApproval(childTokenAddress, approval, tokenId)
            _test.pass("Approved")
        } catch (e) {
            _test.fail(e)
        }

        _test.test("Non-Owner sending approval for token", async _test => {
            childSigner = await createSigner(PRIVATE_KEYS[0])(childProvider);
            const childTunnelInstance = await createContractInstance(CHILD_TUNNEL_CONTRACT_ADDRESS)(childTunnelContractInformation.abi)(childSigner);
            try {
                await childTunnelInstance.sendApproval(childTokenAddress, approval, tokenId)
                _test.fail("Approval should not be set")
            } catch (e) {
                _test.pass("Approval not set")
            }
        })

        _test.test("None Fx-Manager calling the setApproval function", async _test => {
            const childTokenInstance = await createContractInstance(childTokenAddress)(templateContractInformation.abi)(childSigner);
            try {
                await childTokenInstance.setApproval(approval, tokenId)
                _test.fail("Approval should not be set")
            } catch (e) {
                _test.pass("Approval not set")
            }
        })
    })
}

const minting_on_polygon_ = (childTokenAddress) => (tokenId) => (royaltyReceiver) => (royaltyNumerator) => async (tokenUri) => {
    const data = await changeArrToBytes([tokenUri, royaltyReceiver, royaltyNumerator])

    test("Minting on polygon without token mapping", async _test => {
        const [parentProvider, childProvider] = await createRPCProviders()
        let childSigner = await createSigner(PRIVATE_KEYS[1])(childProvider);
        const childTunnelInstance = await createContractInstance(CHILD_TUNNEL_CONTRACT_ADDRESS)(childTunnelContractInformation.abi)(childSigner);
        try {
            await childTunnelInstance.mintToken("0xB786132b1158923194905aF4489346b6CA463338", tokenId, data)
            _test.fail("Minting should not happen")
        } catch (e) {
            _test.pass("Minting Fails")
        }

        _test.test("Non fx-Manager calling mint function on polygon", async _test => {
            const childTokenInstance = await createContractInstance(CHILD_TOKEN_ADDRESS)(templateContractInformation.abi)(childSigner);
            try {
                await childTokenInstance.mint(ACCOUNT_ADDRESSES[1], tokenId, data)
                _test.fail("Minting should not happen")
            } catch (e) {
                _test.pass("Minting Fails")
            }
        })

        _test.test("Minting on polygon without approval", async _test => {
            try {
                await childTunnelInstance.mintToken(childTokenAddress, tokenId, data)
                _test.fail("Minting should not happen")
            } catch (e) {
                _test.pass("Minting Fails")
            }
        })

        _test.test("Minting on polygon with approval", async _test => {
            await childTunnelInstance.sendApproval(childTokenAddress, true, tokenId)
            try {
                await childTunnelInstance.mintToken(childTokenAddress, tokenId, data)
                await childTunnelInstance.sendApproval(childTokenAddress, true, tokenId)
                await childTunnelInstance.withdrawToFlow(childTokenAddress, "0x8652959903DaC486423B83E3aAB0485C6AD7049F", tokenId)
                _test.pass("Minted Successfully")
            } catch (e) {
                const childTokenInstance = await createContractInstance(CHILD_TOKEN_ADDRESS)(templateContractInformation.abi)(childSigner);
                if (await childTokenInstance.exists(tokenId)) {
                    _test.fail("Token already exists")
                } else {
                    _test.fail(e)
                }
            }
        })

    })
}

const burning_on_polygon_and_transfer_to_ethereum_ = (childTokenAddress) => (tokenId) => (royaltyReceiver) => (royaltyNumerator) => async (tokenUri) => {
    const data = await changeArrToBytes([tokenUri, royaltyReceiver, royaltyNumerator])

    test("Burning on polygon without token mapping", async _test => {
        const [parentProvider, childProvider] = await createRPCProviders()
        let childSigner = await createSigner(PRIVATE_KEYS[1])(childProvider);
        let parentSigner = await createSigner(PRIVATE_KEYS[0])(parentProvider)

        const childTunnelInstance = await createContractInstance(CHILD_TUNNEL_CONTRACT_ADDRESS)(childTunnelContractInformation.abi)(childSigner);

        try {
            await childTunnelInstance.withdraw("0xB786132b1158923194905aF4489346b6CA463338", tokenId, data)
            _test.fail("Burning should not happen")
        } catch (e) {
            _test.pass("Burning Fails")
        }

        _test.test("Non fx-Manager calling burn function on polygon", async _test => {
            const childTokenInstance = await createContractInstance(CHILD_TOKEN_ADDRESS)(templateContractInformation.abi)(childSigner);
            try {
                await childTokenInstance.burn(tokenId)
                _test.fail("Burning should not happen")
            } catch (e) {
                _test.pass("Burning failed as caller not fx-Manager")
            }
        })

        _test.test("burning on polygon without approval or token does not exist", async _test => {
            try {
                await childTunnelInstance.withdraw(childTokenAddress, tokenId, data)
                _test.fail("Burning should not happen")
            } catch (e) {
                const childTokenInstance = await createContractInstance(CHILD_TOKEN_ADDRESS)(templateContractInformation.abi)(childSigner);
                if (await childTokenInstance.exists(tokenId)) {
                    _test.pass("Burning Fails due to no approval")
                } else {
                    _test.pass("Token Does not exist to be burned")
                }
            }
        })

        _test.test("Burning on polygon with approval for a minted token and transfer to ethereum", async _test => {
            try {
                await childTunnelInstance.sendApproval(childTokenAddress, true, tokenId)
                const rootTunnelInstance = await createContractInstance(ROOT_TUNNEL_CONTRACT_ADDRESS)(rootTunnelContractInformation.abi)(parentSigner);
                await transferToEthereum(childTunnelInstance)(rootTunnelInstance)(childTokenAddress)(tokenId)(data)
                const rootTokenInstance = await createContractInstance(ROOT_TOKEN_ADDRESS)(templateContractInformation.abi)(parentSigner);
                _test.pass("Burning Successful")
                if (rootTokenInstance.exists(tokenId)) {
                    _test.pass("Token transferred to ethereum successfully")
                } else {
                    _test.fail("Something went wrong while transferring to ethereum")
                }
            } catch (e) {
                _test.fail(e)
            }
        })

    })
}

const ethereum_to_polygon_transfer_ = (rootTokenAddress) => (userAddress) => (tokenId) => (royaltyReceiver) => (royaltyNumerator) => async (tokenUri) => {
    const data = await changeArrToBytes([tokenUri, royaltyReceiver, royaltyNumerator])

    test("transfer token for a non-mapped token contract", async _test => {
        const [parentProvider, childProvider] = await createRPCProviders()
        let childSigner = await createSigner(PRIVATE_KEYS[1])(childProvider);
        let parentSigner = await createSigner(PRIVATE_KEYS[0])(parentProvider)

        const rootTunnelInstance = await createContractInstance(ROOT_TUNNEL_CONTRACT_ADDRESS)(rootTunnelContractInformation.abi)(parentSigner);

        try {
            await rootTunnelInstance.deposit("0xB786132b1158923194905aF4489346b6CA463338", userAddress, tokenId, data)
            _test.fail("transfer should not happen")
        } catch (e) {
            _test.pass("transfer fails because rootTokenAddress is not mapped")
        }

        _test.test("transfer of token without owner's approval", async _test => {
            try {
                const transactionReceipt = await rootTunnelInstance.deposit(rootTokenAddress, userAddress, tokenId, dataBytes)
                const log = await transactionReceipt.wait()

                const childTunnelInstance = await createContractInstance(CHILD_TUNNEL_CONTRACT_ADDRESS)(childTunnelContractInformation.abi)(childSigner);
                await childTunnelInstance.syncDeposit(rootTunnelInstance.address, log.events[2].args[0])
                _test.fail("transfer should fail as owner did not approve")
            } catch (e) {
                _test.pass("Transfer not approved by owner")
            }
        })

        _test.test("transfer of token with owner's approval", async _test => {
            try {
                const childTunnelInstance = await createContractInstance(CHILD_TUNNEL_CONTRACT_ADDRESS)(childTunnelContractInformation.abi)(childSigner);
                // await transferToPolygon(rootTunnelInstance)(childTunnelInstance)(rootTokenAddress)(tokenId)(userAddress)(dataArr)
                parentSigner = await createSigner(PRIVATE_KEYS[1])(parentProvider)
                const rootTokenInstace = await createContractInstance(rootTokenAddress)(templateContractInformation.abi)(parentSigner)
                if (await rootTokenInstace.ownerOf(tokenId) == ACCOUNT_ADDRESSES[1]) {

                    await rootTokenInstace.approve(ROOT_TUNNEL_CONTRACT_ADDRESS, tokenId)

                    const rootcontractWithSigner = rootTunnelInstance.connect(parentSigner)
                    const transactionReceipt = await rootcontractWithSigner.deposit(rootTokenAddress, userAddress, tokenId, data)
                    const log = await transactionReceipt.wait()

                    await childTunnelInstance.syncDeposit(ROOT_TUNNEL_CONTRACT_ADDRESS, log.events[2].args[0])
                    const childTokenInstance = await createContractInstance(CHILD_TOKEN_ADDRESS)(templateContractInformation.abi)(childSigner);

                    if (childTokenInstance.exists(tokenId)) {
                        _test.pass("Token transferred to polygon successfully")
                    } else {
                        _test.fail("Something went wrong while transferring to polygon")
                    }

                } else {
                    _test.fail("signer account not owner of token")
                }
            } catch (e) {
                _test.fail("Transfer not approved by owner")
            }
        })


    })
}


// deploy_contracts_()
deploy_token_(3)("test")("tt")
// send_mint_or_burn_approval_(CHILD_TOKEN_ADDRESS)(true)(1)
// minting_on_polygon_(CHILD_TOKEN_ADDRESS)(101)(ACCOUNT_ADDRESSES[1])(500)("QmcRXwGFhEBGsV6DMioaHPKXAxnTcStDfdP1zV86z5sXCz")
// burning_on_polygon_and_transfer_to_ethereum_(CHILD_TOKEN_ADDRESS)(101)(ACCOUNT_ADDRESSES[1])(500)("QmcRXwGFhEBGsV6DMioaHPKXAxnTcStDfdP1zV86z5sXCz")
// ethereum_to_polygon_transfer_(ROOT_TOKEN_ADDRESS)(ACCOUNT_ADDRESSES[1])(101)(ACCOUNT_ADDRESSES[1])(500)("QmcRXwGFhEBGsV6DMioaHPKXAxnTcStDfdP1zV86z5sXCz")
// burning_on_polygon_and_transfer_to_ethereum_(CHILD_TOKEN_ADDRESS)(101)(ACCOUNT_ADDRESSES[1])(500)("QmcRXwGFhEBGsV6DMioaHPKXAxnTcStDfdP1zV86z5sXCz")
// ethereum_to_polygon_transfer_(ROOT_TOKEN_ADDRESS)(ACCOUNT_ADDRESSES[1])(101)(ACCOUNT_ADDRESSES[1])(500)("QmcRXwGFhEBGsV6DMioaHPKXAxnTcStDfdP1zV86z5sXCz")