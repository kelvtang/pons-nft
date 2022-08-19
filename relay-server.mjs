import express from 'express';
import { ethers } from 'ethers';
import * as fs from 'fs';
import cors from 'cors';
import { send_transaction_ } from './utils/flow-api.mjs';
import flow_types from '@onflow/types'
import { known_account_ } from './utils/flow.mjs';
import { FLOW_MARKETPLACE_ADDRESS, POLYGON_MARKETPLACE_ADDRESS, FLOW_TUNNEL_PROXY_ADDRESS, METAMASK_ACCOUNT_PRIVATE_KEY } from './config.mjs';
import { BASE_TOKEN_URI, FLOW_MARKET_TRANSFER_EVENT, FLOW_USER_TRANSFER_EVENT, POLYGON_FUSD_MARKET_TRANSFER_EVENT, POLYGON_FLOW_MARKET_TRANSFER_EVENT, POLYGON_PROVIDER_URL } from './config.mjs';
import { flow_sdk_api } from './config.mjs';
import fcl_api from '@onflow/fcl';
import { fileTypeFromBuffer } from 'file-type';
import fetch from 'node-fetch';
import { encodeToBytes, createSigner, createContractInstance, createRPCProviders } from "./ethereum-api.mjs";

const app = express();
app.use(cors())
app.use(express.json());
app.use(express.urlencoded({ extended: true }));


// TODO: Change file path based on actual file path
// N.B Whenever any contract we need to restart server
const ponsNftTunnelContractInformation = JSON.parse(fs.readFileSync('./build/contracts/PonsNftTunnel.json', 'utf8'))
const marketPlaceContractInformation = JSON.parse(fs.readFileSync('./build/contracts/PonsNftMarket.json', 'utf8'))
const flowTunnelContractInformation = JSON.parse(fs.readFileSync('./build/contracts/FlowTunnel.json', 'utf8'))

const polygonProvider = await createRPCProviders(POLYGON_PROVIDER_URL);
const signer = await createSigner(METAMASK_ACCOUNT_PRIVATE_KEY)(polygonProvider)
const flowTunnelProxyInstance = await createContractInstance(FLOW_TUNNEL_PROXY_ADDRESS)(flowTunnelContractInformation.abi)(signer)
const marketPlaceInstance = await createContractInstance(POLYGON_MARKETPLACE_ADDRESS)(marketPlaceContractInformation.abi)(signer)

app.get("/metadata/:nftSerialId", async (req, res) => {
    const nftSerialId = req.params.nftSerialId

    // TODO: Change path accordingly
    const path = `./token-metadata/${nftSerialId}`

    const data = fs.readFileSync(`${path}.json`)
    res.header("Content-Type", 'application/json');
    res.send(data)
})


// Reverts a transacttion if the user rejects a purchase on polygon
// Market to market transfer
app.post("/market/revert", async (req, res) => {
    const tokenId = req.body["tokenId"]

    // Event will be picked up by event listener and revert transaction on flow
    await marketPlaceInstance.sendThroughTunnel(tokenId, FLOW_MARKETPLACE_ADDRESS)
    res.send({ message: 'Transaction reverted on polygon. It will be reflected on flow once the transcation event is picked up and processed' });
})

// Market to market transfer
app.post("/market/flowPurchase", (req, res) => {
    const tokenId = req.body["tokenId"]

    send_transaction_
        (known_account_('0xPROPOSER'))
        (known_account_('0xPROPOSER'))
        ([known_account_('0xPROPOSER'), known_account_('0xPROPOSER')])
        (`
            import PonsTunnelContract from 0xPONS
            import PonsUtils from 0xPONS
        
            transaction(
            nftSerialId: UInt64
            ) {
                prepare (ponsAccount : AuthAccount, ponsHolderAccount : AuthAccount){
                    PonsTunnelContract .sendNftThroughTunnel_market (nftSerialId: nftSerialId, ponsAccount: ponsAccount, ponsHolderAccount: ponsHolderAccount);
                }
            }
        `)
        ([flow_sdk_api.arg(tokenId, flow_types.UInt64)])
        .then(_ => {
            res.status(200).send({ message: 'purchased on flow' });
        })
        .catch(_ => {
            res.status(400).send({ error: 'Something went wrong while purchasing on flow' });
        })
})

app.listen(3010, () => console.log(`app running on 3010`))

// Market to market transfer
fcl_api.events(FLOW_MARKET_TRANSFER_EVENT).subscribe(async (event) => {

    const { nft, polygonRecipientAddress } = event
    const { nftSerialId, metadata, artistAddressFlow, artistAddressPolygon, flowToken, fusdToken, royalty } = nft

    // TODO: Change based on actual directory/folder name
    const path = `./token-metadata/${nftSerialId}`

    if (!fs.existsSync(path)) {
        let url = "", title = "", description = "";
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

    let HkdFlowPrice = 0
    if (flowToken) {
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
    const polygonPrice = Number((HkdFlowPrice / polygonMarketInfo.market_data.current_price.hkd).toFixed(3))

    if (!artistAddressPolygon) {
        artistAddressPolygon = ethers.constants.AddressZero
    }

    const depositData = await encodeToBytes(["string", "address", "string", "address", "uint96"])
        ([`${BASE_TOKEN_URI}${nftSerialId}`, artistAddressPolygon, artistAddressFlow, POLYGON_MARKETPLACE_ADDRESS, royalty])

    const ponsNftTunnel = new ethers.Contract(PONS_NFT_TUNNEL_ADDRESS, ponsNftTunnelContractInformation.abi, signer)

    if (!polygonRecipientAddress) {
        polygonRecipientAddress = POLYGON_MARKETPLACE_ADDRESS
    }

    await ponsNftTunnel.getFromTunnel(nftSerialId, polygonRecipientAddress, depositData, polygonPrice)
})

// user to user transfer
fcl_api.events(FLOW_USER_TRANSFER_EVENT).subscribe(async (event) => {

    const { nft, polygonRecipientAddress } = event
    const { nftSerialId, metadata, artistAddressFlow, artistAddressPolygon, royalty } = nft

    // TODO: Change based on actual directory/folder name
    const path = `./token-metadata/${nftSerialId}`

    if (!fs.existsSync(path)) {
        let url = "", title = "", description = "";
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

    if (!artistAddressPolygon) {
        artistAddressPolygon = ethers.constants.AddressZero
    }

    const depositData = await encodeToBytes(["string", "address", "string", "address", "uint96"])
        ([`${BASE_TOKEN_URI}${nftSerialId}`, artistAddressPolygon, artistAddressFlow, POLYGON_MARKETPLACE_ADDRESS, royalty])

    const ponsNftTunnel = new ethers.Contract(PONS_NFT_TUNNEL_ADDRESS, ponsNftTunnelContractInformation.abi, signer)

    if (!polygonRecipientAddress) {
        polygonRecipientAddress = POLYGON_MARKETPLACE_ADDRESS
    }

    await ponsNftTunnel.getFromTunnel(nftSerialId, polygonRecipientAddress, depositData, ethers.constants.MaxUint256)
})


// Market to market transfer using FUSD
flowTunnelProxyInstance.on(POLYGON_FUSD_MARKET_TRANSFER_EVENT, async (tokenId, sender, flowAddress, polygonLister, price) => {

    tokenId = tokenId.toString()
    price = price.toString()

    if (!flowAddress) {
        flowAddress = FLOW_MARKETPLACE_ADDRESS
    }

    await
        send_transaction_
            (known_account_('0xPROPOSER'))
            (known_account_('0xPROPOSER'))
            ([known_account_('0xPROPOSER'), known_account_('0xPROPOSER')])
            (`
                import PonsTunnelContract from 0xPONS
                import PonsUtils from 0xPONS
            
                transaction(
                nftSerialId: UInt64,
                salePriceFUSD: UFix64,
                polygonListingAddress: String
                ) {
                    prepare (ponsAccount : AuthAccount, ponsHolderAccount : AuthAccount){
                        PonsTunnelContract .recieveNftFromTunnel_market_fusd (nftSerialId: nftSerialId, ponsAccount: ponsAccount, ponsHolderAccount: ponsHolderAccount, polygonListingAddress: polygonListingAddress, salePriceFUSD: salePriceFUSD);
                    }
                }
            `)
            ([flow_sdk_api.arg(tokenId, flow_types.UInt64),
            flow_sdk_api.arg(""  + price, flow_types.UFix64),
            flow_sdk_api.arg(polygonLister, flow_types.String),
            ])
})

// Market to market transfer using Flow token
flowTunnelProxyInstance.on(POLYGON_FLOW_MARKET_TRANSFER_EVENT, async (tokenId, sender, flowAddress, polygonLister, price) => {

    tokenId = tokenId.toString()
    price = price.toString()

    if (!flowAddress) {
        flowAddress = FLOW_MARKETPLACE_ADDRESS
    }

    await
        send_transaction_
            (known_account_('0xPROPOSER'))
            (known_account_('0xPROPOSER'))
            ([known_account_('0xPROPOSER'), known_account_('0xPROPOSER')])
            (`
                import PonsTunnelContract from 0xPONS
                import PonsUtils from 0xPONS
            
                transaction(
                nftSerialId: UInt64,
                salePriceFlow: UFix64,
                polygonListingAddress: String
                ) {
                    prepare (ponsAccount : AuthAccount, ponsHolderAccount : AuthAccount){
                        PonsTunnelContract .recieveNftFromTunnel_market_flow (nftSerialId: nftSerialId, ponsAccount: ponsAccount, ponsHolderAccount: ponsHolderAccount, polygonListingAddress: polygonListingAddress, salePriceFlow: salePriceFlow);
                    }
                }
            `)
            ([flow_sdk_api.arg(tokenId, flow_types.UInt64),
            flow_sdk_api.arg(""  + price, flow_types.UFix64),
            flow_sdk_api.arg(polygonLister, flow_types.String),
            ])
})