import express from 'express';
import { ethers } from 'ethers';
import * as fs from 'fs';
import { send_transaction_, authorizer_ } from './utils/flow-api.mjs';
import {send_known_transaction_} from './utils/flow.mjs'
import { CHILD_TUNNEL_CONTRACT_ADDRESS, CHILD_TOKEN_ADDRESS, PRIVATE_KEYS } from './config.mjs';
import { BASE_TOKEN_URI } from './config.mjs';
import { flow_sdk_api } from './config.mjs';
import fcl_api from '@onflow/fcl';
import { fileTypeFromBuffer } from 'file-type';
import fetch from 'node-fetch';

const app = express();
app.use(express.json());


// TODO: Change file path
const templateContractInformation = JSON.parse(fs.readFileSync('./ethereum_polygon_tests/build/contracts/FxERC721.json', 'utf8'));
const childTunnelContractInformation = JSON.parse(fs.readFileSync('./ethereum_polygon_tests/build/contracts/FxERC721ChildTunnel.json', 'utf8'));


// TODO: Change Provider
const polygonProvider = new ethers.providers.JsonRpcProvider("http://127.0.0.1:7545"); 
const signer = new ethers.Wallet(PRIVATE_KEYS[1], polygonProvider)
const polygonChildTunnelContractInstance = new ethers.Contract(CHILD_TUNNEL_CONTRACT_ADDRESS, childTunnelContractInformation.abi,
    signer)
const abiCoder = ethers.utils.defaultAbiCoder

app.get("/metadata/:nftSerialId", (req, res) => {
    const nftSerialId = req.params.nftSerialId

    // TODO: Change path accordingly
    const path = `./token-metadata/${nftSerialId}`

    const data = fs.readFileSync(`${path}.json`)
    res.header("Content-Type", 'application/json');
    res.send(data)
})


// TODO: Change to the actual event name
const EVENT_NAME = "A.1654653399040a61.FlowToken.TokensDeposited"

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
        } else if (key.startsWith('tag')) {
            tags.push(JSON.stringify({
                trait_type: "Tag",
                value: value
            }, null, 2))
        }

    }

    royalty = Math.ceil(royalty * 10000)

    let imageAnimationAttribute

    if (url.startsWith('ipfs')) {
        url = "https://" + url
        const response = await fetch(url)
        const urlContent = await response.arrayBuffer()
        const ext = (await fileTypeFromBuffer(urlContent))?.ext;
        if (ext === 'mp4') {
            imageAnimationAttribute = 'animation_url'
        } else {
            imageAnimationAttribute = 'image'
        }
    }

    // TODO: Change based on actual directory/folder name
    const path = `./token-metadata/${nftSerialId}`

    // TODO: Need to process token URI first
    if (!fs.existsSync(path)) {
        let NFTMetada = {
            imageAnimationAttribute: url,
            name: title,
            description: description,
            attributes: tags,
        }
        fs.writeFileSync(`${path}.json`, JSON.stringify(NFTMetada, null, 2))
    }


    // TODO: Decide how to deal with user not having a polygon artist address
    if (!artistAddressPolygon) {
        artistAddressPolygon = ethers.constants.AddressZero
    }

    const depositData = abiCoder.encode(["string", "address", "uint96"], [`${BASE_TOKEN_URI}${nftSerialId}`, artistAddressPolygon, royalty])
    const data = abiCoder.encode(["address", "address", "uint64", "bytes"], [CHILD_TOKEN_ADDRESS, polygonRecipientAddress, nftSerialId, depositData])
    const childSigner = new ethers.Wallet(PRIVATE_KEYS[1], polygonProvider);
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

