import express from 'express';
import { ethers } from 'ethers';
import * as fs from 'fs';
import { send_transaction_, authorizer_ } from './utils/flow-api.mjs';
import {send_known_transaction_} from './utils/flow.mjs'
import { CHILD_TUNNEL_CONTRACT_ADDRESS, CHILD_TOKEN_ADDRESS, PRIVATE_KEYS } from './config.mjs';
import { BASE_TOKEN_URI, EVENT_NAME } from './config.mjs';
import { flow_sdk_api } from './config.mjs';
import fcl_api from '@onflow/fcl';
import { fileTypeFromBuffer } from 'file-type';
import fetch from 'node-fetch';
import { encodeToBytes, createSigner, createContractInstance } from "./ethereum-api.mjs";

const app = express();
app.use(express.json());


// TODO: Change file path
const templateContractInformation = JSON.parse(fs.readFileSync('./ethereum_polygon_tests/build/contracts/FxERC721.json', 'utf8'));
const childTunnelContractInformation = JSON.parse(fs.readFileSync('./ethereum_polygon_tests/build/contracts/FxERC721ChildTunnel.json', 'utf8'));


// TODO: Change Provider
const polygonProvider = await createRPCProviders("");
const signer = await createSigner(PRIVATE_KEYS[1])(polygonProvider)
const polygonChildTunnelContractInstance = await createContractInstance(CHILD_TUNNEL_CONTRACT_ADDRESS)(childTunnelContractInformation.abi)(signer)

app.get("/metadata/:nftSerialId", (req, res) => {
    const nftSerialId = req.params.nftSerialId

    // TODO: Change path accordingly
    const path = `./token-metadata/${nftSerialId}`

    const data = fs.readFileSync(`${path}.json`)
    res.header("Content-Type", 'application/json');
    res.send(data)
})


// Reverts a transacttion if the user rejects a purchase on polygon
app.get("/revert/:serialId", (req, res) => {
    const tokenId = req.params.serialId
    await marketplaceInstance.unlist(tokenId)
    
    // TODO: Edit hardcoded values
    const FxERC721ManagerContract = new ethers.Contract(FXManagerAddress, ManagerABI, signer)
    FxERC721ManagerContract.sendThroughTunnel(tokenId, USERFLOWADDRESS) // TODO: Edit hardcoded values
        .then(_ => {
            // TODO: Edit hardcoded values
            await send_transaction_ 
                (authorizer_(address)(key_id)(private_key)) // TODO: Edit hardcoded values
                (authorizer_(address)(key_id)(private_key)) // TODO: Edit hardcoded values
                ([authorizer_(address)(key_id)(private_key), authorizer_(address)(key_id)(private_key), USER_SIGNING]) // TODO: Edit hardcoded values
                (` import PonsTunnelContract from 0xPONS
          transaction(
                flowRecepientAddress: Address,
                nftSerialId: UInt64
            ) {
                prepare (ponsAccount : AuthAccount){
                    if flowRecepientAddress == tunnelUserAccount .Address{
                      PonsTunnelContract .recieveNftFromTunnel(nftSerialId: nftSerialId, ponsAccount : ponsAccount, ponsHolderAccount : ponsAccount, tunnelUserAccount : ponsAccount);
                  }else {
                      panic ("Only recipient can sign tranaction")
                  }
                }
            }`)
                ([flow_sdk_api.arg(USERFLOWADDRESS, flow_types.Address), // TODO: Edit hardcoded values
                flow_sdk_api.arg(tokenId, flow_types.UInt64)])
            res.send({ message: 'Transaction reverted' });
        })
})


app.listen(3000, () => console.log(`app running on 3000`))

fcl_api.events(EVENT_NAME).subscribe(async (event) => {

    const { nft, polygonRecipientAddress } = event
    const { nftSerialId, metadata, royalty, artistAddressPolygon } = nft

    let url, title, description;
    let tags = []

    for (const [key, value] of Object.entries(metadata)) {
        if (key === 'url') {
            url = value
        } else if (key === 'title') {
            title = value
        } else if (key === 'description') {
            description = value
        } else if (key.startsWith('tag-')) {
            tags.push(JSON.stringify({
                trait_type: "Tag",
                value: value
            }, null, 2))
        }

    }

    royalty = Math.ceil(royalty * 10000)

    let NftMetadata
    if (url.startsWith('ipfs')) {
        url = "https://" + url
        const response = await fetch(url)
        const urlContent = await response.arrayBuffer()
        const ext = (await fileTypeFromBuffer(urlContent))?.ext;
        if (ext === 'mp4') {
            NftMetadata['animation_url'] = url
        } else {
            NftMetadata['image'] = url
        }
    }

    // TODO: Change based on actual directory/folder name
    const path = `./token-metadata/${nftSerialId}`

    // TODO: Need to process token URI first
    if (!fs.existsSync(path)) {
        NftMetadata = {
            ...NftMetadata,
            name: title,
            description: description,
            attributes: tags,
        }
        fs.writeFileSync(`${path}.json`, JSON.stringify(NftMetadata, null, 2))
    }


    // TODO: Decide how to deal with user not having a polygon artist address
    if (!artistAddressPolygon) {
        artistAddressPolygon = ethers.constants.AddressZero
    }

    const depositData = await encodeToBytes(["string", "address", "uint96"])([`${BASE_TOKEN_URI}${nftSerialId}`, artistAddressPolygon, royalty])
    const data = await encodeToBytes(["address", "uint64", "bytes"])([polygonRecipientAddress, nftSerialId, depositData])
    const childSigner = await createSigner(PRIVATE_KEYS[1])(polygonProvider);
    polygonChildTunnelContractInstance.connect(childSigner)
    polygonChildTunnelContractInstance.processMessageFromFLow(data)
})


polygonChildTunnelContractInstance.on('FlowDeposit', (data) => {
    let [flowReceiver, tokenId] = abiCoder.decode(['address', 'uint256'], data)

    tokenId = tokenId.toString() // change from bigNumber to string 


    // TODO: change based on the flow implemntation
    var _transaction_response = await
    send_transaction_
        (authorizer_(address)(key_id)(private_key))
        (authorizer_(address)(key_id)(private_key))
        ([authorizer_(address)(key_id)(private_key)])
        (await readFile ('./FlowPolygonBridge/transactions/sendThroughTunnelUsingSerialId.cdc', 'utf8'))
        ([flowReceiver, tokenId])
})

