import express from 'express';
import { ethers } from 'ethers';
import * as fs from 'fs';
import cors from 'cors';
import { send_transaction_ } from './utils/flow-api.mjs';
import flow_types from '@onflow/types'
import { known_account_ } from './utils/flow.mjs';
import { FLOW_MARKETPLACE_ADDRESS, POLYGON_MARKETPLACE_ADDRESS, PONS_NFT_TUNNEL_ADDRESS, PRIVATE_KEYS } from './config.mjs';
import { BASE_TOKEN_URI, FLOW_EVENT_NAME, FLOW_EVENT_NAME_NOT_LISTED, POLYGON_EVENT_NAME } from './config.mjs';
import { flow_sdk_api } from './config.mjs';
import fcl_api from '@onflow/fcl';
import { fileTypeFromBuffer } from 'file-type';
import fetch from 'node-fetch';
import { encodeToBytes, createSigner, createContractInstance } from "./ethereum-api.mjs";

const app = express();
app.use(cors())
app.use(express.json());
app.use(express.urlencoded({ extended: true }));


// TODO: Change file path based on actual file path
const childTunnelContractInformation = JSON.parse(fs.readFileSync('./ethereum_polygon_tests/build/contracts/FxERC721ChildTunnel.json', 'utf8'));
const ponsNftTunnelContractInformation = JSON.parse(fs.readFileSync('./ethereum_polygon_tests/build/contracts/PonsNftTunnel.json', 'utf8'))

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
app.post("/market/revert", async (req, res) => {
    const tokenId = req.body["tokenId"]
    const marketPlaceInstance = req.body["marketPlaceInstance"]
    // TODO: Edit on actual function marketplace contract
    await marketPlaceInstance.unlist(tokenId)

    // TODO: Add flow bridge instance
    const ponsNftTunnel = new ethers.Contract(PONS_NFT_TUNNEL_ADDRESS, ponsNftTunnelContractInformation.abi, signer)
    ponsNftTunnel.sendThroughTunnel(tokenId, FLOW_MARKETPLACE_ADDRESS)
        .then(async _ => {
            await send_transaction_
                (known_account_('0xPROPOSER'))
                (known_account_('0xPROPOSER'))
                ([known_account_('0xPROPOSER')])
                (` import PonsTunnelContract from 0xPONS
          transaction(
                flowRecepientAddress: Address,
                nftSerialId: UInt64
            ) {
                prepare (ponsAccount : AuthAccount){
                    if flowRecepientAddress == tunnelUserAccount .Address{
                      PonsTunnelContract .recieveNftFromTunnel_Market(nftSerialId: nftSerialId, ponsAccount : ponsAccount, ponsHolderAccount : ponsAccount, tunnelUserAccount : ponsAccount);
                  }else {
                      panic ("Only recipient can sign tranaction")
                  }
                }
            }`)
                ([flow_sdk_api.arg(FLOW_MARKETPLACE_ADDRESS, flow_types.Address),
                flow_sdk_api.arg(tokenId, flow_types.UInt64)])
            res.send({ message: 'Transaction reverted' });
        })
})


app.post("/market/flowPurchase", (req, res) => {
    const tokenId = req.body["tokenId"]
    send_transaction_
        (known_account_('0xPROPOSER'))
        (known_account_('0xPROPOSER'))
        ([known_account_('0xPROPOSER')])
        (`import PonsTunnelContract from 0xPONS
      transaction(polygonRecepientAddress: String, nftSerialId: UInt64) {
      prepare (ponsAccount : AuthAccount){
         PonsTunnelContract .sendNftThroughTunnelUsingSerialId_Market(nftSerialId: nftSerialId, ponsAccount : ponsAccount, ponsHolderAccount : ponsAccount, tunnelUserAccount : ponsAccount, polygonAddress: polygonRecepientAddress);
      }`)
        ([flow_sdk_api.arg(POLYGON_MARKETPLACE_ADDRESS, flow_types.String),
        flow_sdk_api.arg(tokenId, flow_types.UInt64)])
        .then(_ => {
            res.status(200).send({ message: 'purchased on flow' });
        })
        .catch(_ => {
            res.status(400).send({ error: 'Something went wrong while purchasing on flow' });
        })
})

app.listen(3010, () => console.log(`app running on 3010`))

fcl_api.events(FLOW_EVENT_NAME).subscribe(async (event) => {

    const { nft, polygonRecipientAddress } = event
    const { nftSerialId, metadata, royalty, artistAddressPolygon, flowToken, fusdToken } = nft

    // TODO: Change based on actual directory/folder name
    const path = `./token-metadata/${nftSerialId}`

    if (!fs.existsSync(path)) {
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
        NftMetadata = {
            ...NftMetadata,
            name: title,
            description: description,
            attributes: tags,
        }
        fs.writeFileSync(`${path}.json`, JSON.stringify(NftMetadata, null, 2))
    }

    let HkdFlowPrice = 0, polygonPrice = 0
    if (flowToken !== null) {
        const flowInfoResp = await fetch(`https://api.coingecko.com/api/v3/coins/flow?
    localization=false&tickers=false&market_data=true&community_data=false&developer_data=false&sparkline=false`)
        const flowMarketInfo = await flowInfoResp.json()
        HkdFlowPrice = flowToken * flowMarketInfo.market_data.current_price.hkd
    } else {
        const exchangeResponse = await (await fetch(`https://api.exchangerate.host/convert?from=USD&to=HKD&amount=${fusdToken}`)).json()
        HkdFlowPrice = exchangeResponse.result
    }


    const polygonInfoResp = await fetch(`https://api.coingecko.com/api/v3/coins/matic-network?
    localization=false&tickers=false&market_data=true&community_data=false&developer_data=false&sparkline=false`)

    const polygonMarketInfo = await polygonInfoResp.json()
    polygonPrice = Number((HkdFlowPrice / polygonMarketInfo.market_data.current_price.hkd).toFixed(3))


    // TODO: Edit based on what we need in polygon
    const depositData = await encodeToBytes(["string", "address", "uint96"])([`${BASE_TOKEN_URI}${nftSerialId}`, artistAddressPolygon, royalty])

    //TODO: Add polygon stuff to receive the nft
    const ponsNftTunnel = new ethers.Contract(PONS_NFT_TUNNEL_ADDRESS, ponsNftTunnelContractInformation.abi, signer)
    ponsNftTunnel.getFromTunnel(nftSerialId, polygonRecipientAddress, depositData)
})


fcl_api.events(FLOW_EVENT_NAME_NOT_LISTED).subscribe(async (event) => {

    const { nft, polygonRecipientAddress } = event
    const { nftSerialId, metadata, royalty, artistAddressPolygon } = nft

    // TODO: Change based on actual directory/folder name
    const path = `./token-metadata/${nftSerialId}`

    if (!fs.existsSync(path)) {
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
        NftMetadata = {
            ...NftMetadata,
            name: title,
            description: description,
            attributes: tags,
        }
        fs.writeFileSync(`${path}.json`, JSON.stringify(NftMetadata, null, 2))
    }

    // TODO: Edit based on what we need in polygon
    const depositData = await encodeToBytes(["string", "address", "uint96"])([`${BASE_TOKEN_URI}${nftSerialId}`, artistAddressPolygon, royalty])

    //TODO: Add polygon stuff to receive the nft
    const ponsNftTunnel = new ethers.Contract(PONS_NFT_TUNNEL_ADDRESS, ponsNftTunnelContractInformation.abi, signer)
    ponsNftTunnel.getFromTunnel(nftSerialId, polygonRecipientAddress, depositData)
})

polygonChildTunnelContractInstance.on(POLYGON_EVENT_NAME, async (data) => {
    // TODO: EDIT based on the actual polygon tunnel event
    let [flowReceiver, tokenId] = abiCoder.decode(['address', 'uint256'], data)

    tokenId = tokenId.toString() // change from bigNumber to string

    // TODO: Make sure this is correct
    if (flowReceiver == ethers.constants.AddressZero) {
        flowReceiver = FLOW_MARKETPLACE_ADDRESS
    }

    var _transaction_response = await
        send_transaction_
            (known_account_('0xPROPOSER'))
            (known_account_('0xPROPOSER'))
            ([known_account_('0xPROPOSER')])
            (`import PonsTunnelContract from 0xPONS

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
            ([flowReceiver, tokenId])
})