import express from 'express';
import { ethers } from 'ethers';
import * as fs from 'fs';
import cors from 'cors';
import flow_types from '@onflow/types'
import { send_proposed_transaction_ } from './utils/flow.mjs';
import { FLOW_MARKETPLACE_ADDRESS, POLYGON_MARKETPLACE_ADDRESS, FLOW_TUNNEL_PROXY_ADDRESS, METAMASK_ACCOUNT_PRIVATE_KEY } from './config.mjs';
import { BASE_TOKEN_URI, FLOW_MARKET_TRANSFER_EVENT, FLOW_USER_TRANSFER_EVENT, POLYGON_FUSD_MARKET_TRANSFER_EVENT, POLYGON_FLOW_MARKET_TRANSFER_EVENT, POLYGON_PROVIDER_URL, POLYGON_FLOW_USER_TRANSFER_EVENT } from './config.mjs';
import { flow_sdk_api } from './config.mjs';
import fcl_api from '@onflow/fcl';
import { fileTypeFromBuffer } from 'file-type';
import fetch from 'node-fetch';
import { encodeToBytes, createSigner, createContractInstance, createRPCProviders } from "./ethereum-api.mjs";

const app = express();
app.use(cors())
app.use(express.json())

// TODO: Change file path based on actual file path
// N.B Whenever any contract we need to restart server
const marketPlaceContractInformation = JSON.parse(fs.readFileSync('./build/contracts/PonsNftMarket.json', 'utf8'))
const flowTunnelContractInformation = JSON.parse(fs.readFileSync('./build/contracts/FlowTunnel.json', 'utf8'))

const polygonProvider = await createRPCProviders(POLYGON_PROVIDER_URL);
const signer = await createSigner(METAMASK_ACCOUNT_PRIVATE_KEY)(polygonProvider)
const flowTunnelProxyInstance = await createContractInstance(FLOW_TUNNEL_PROXY_ADDRESS)(flowTunnelContractInformation.abi)(signer)
const marketPlaceInstance = await createContractInstance(POLYGON_MARKETPLACE_ADDRESS)(marketPlaceContractInformation.abi)(signer)

const transactionLedger = {}

const currency = {
    flowToken: 0,
    FUSD: 1
}

// Returns token metadata information stored in the JSON file
app.get("/metadata/:nftSerialId", async (req, res) => {
    const nftSerialId = req.params.nftSerialId

    // TODO: Change path accordingly
    const path = `./token-metadata/${nftSerialId}`

    const data = fs.readFileSync(`${path}.json`)
    res.header("Content-Type", 'application/json');
    res.send(data)
})


/*
* For flow to polygon market transfer
* If a user agrees to to buy a token on polygon from flow but when prompted to buy on polygon, they reject or the transaction fails
* A request will be made to this path to send back the token from polygon to flow
* After the transaction succeeds, an event will be emitted which the server is actively listening for 
* when the server picks up the event, it will revert the transaction on flow as well
*/
app.post("/market/revert", async (req, res) => {
    const tokenId = req.body["tokenId"]

    // TODO: Get it from file logs
    await marketPlaceInstance.sendThroughTunnel(tokenId, currency[((transactionLedger[tokenId]).at(-1))["tokenType"]])
    res.status(200).send(JSON.stringify({ message: 'Transaction reverted on polygon. It will be reflected on flow once the transcation event is picked up and processed' }));
})

/*
* For Flow to polygon market transfer
* When the user clicks the buy on polygon button in flow, a request will be sent to this path
* A transaction is sent on the flow side to transfer a token from flow to polygon
* The transaction emits an event which the server is actively listening for
* When the event is picked up, the server send a request to polygon to transfer the token
* The user should then be prompted to buy the token on polygon through metamask
*/
app.post("/market/flowPurchase", (req, res) => {
    const tokenId = req.body["tokenId"]

    send_proposed_transaction_
        (['0xPONS'])
        (`
            import PonsTunnelContract from 0xPONS
            import PonsUtils from 0xPONS
        
            transaction(
            nftSerialId: UInt64
            ) {
                prepare (ponsAccount : AuthAccount){
                    PonsTunnelContract .sendNftThroughTunnel_market (nftSerialId: nftSerialId, ponsAccount: ponsAccount, ponsHolderAccount: ponsAccount);
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

/*
* For flow to polygon market transfer
* Listens to see if an event associated with tunnel market transfer is emitted
* Checks if an associated json file with the token exists
* If it does not exist, a new one is created with the token's metadata
* Otherwise, the exisiting file is used
* The relevant token price on polygon is then calculated by converting flow to hkd then to matic
* If the artist does not have an address on polygon, we assign it to address(0x0)
* The token is then received on the polygon side
*/
fcl_api.events(FLOW_MARKET_TRANSFER_EVENT).subscribe(async (event) => {
    // console.log("----------------------------------------------- Event listener -------------------------------------------------")

    let { nft, polygonRecipientAddress } = event.data
    let { nftSerialId, metadata, artistAddressFlow, artistAddressPolygon, flowToken, fusdToken, royalty } = nft

    flowToken = flowToken.flowAmount

    const ledgerEntry = {
        origin: 'flow',
        price: flowToken ? flowToken : fusdToken,
        tokenType: flowToken ? "flowToken" : "FUSD"
    }

    // TODO: Figure out file logs stuff
    // const prevLogs = JSON.parse(fs.readFileSync('./logs/transfers.log', 'utf8'))
    // fs.writeFileSync("./logs/tempFile.log", JSON.stringify(ledgerEntry))
    // save to back up file then merge to big file
    if (transactionLedger[nftSerialId]){
        transactionLedger[nftSerialId].push(ledgerEntry)
    } else {
        transactionLedger[nftSerialId] = [ledgerEntry]
    }
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

        let NftMetadata = {}
        // TODO: Edit this based on how urls are actually stored plus where we want to point it to
        if (url.startsWith('ipfs')) {
            url = "https://" + url
        } else {
            url = "https://ipfs.io/" + url
        }

        const response = await fetch(url)
        const urlContent = await response.arrayBuffer()
        const ext = (await fileTypeFromBuffer(urlContent))?.ext;

        if (ext === 'mp4') {
            NftMetadata['animation_url'] = url
        } else {
            NftMetadata['image'] = url
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
    const polygonPrice = Math.ceil(Number((HkdFlowPrice / polygonMarketInfo.market_data.current_price.hkd)) * 10000)

    if (!artistAddressPolygon) {
        artistAddressPolygon = ethers.constants.AddressZero
    }

    const depositData = await encodeToBytes(["string", "address", "string", "address", "uint96"])
        ([`${BASE_TOKEN_URI}${nftSerialId}`, artistAddressPolygon, artistAddressFlow, POLYGON_MARKETPLACE_ADDRESS, royalty])

    const ponsNftTunnelProxy = new ethers.Contract(FLOW_TUNNEL_PROXY_ADDRESS, flowTunnelContractInformation.abi, signer)

    if (!polygonRecipientAddress) {
        polygonRecipientAddress = POLYGON_MARKETPLACE_ADDRESS
    }

    const tx = await ponsNftTunnelProxy.getFromTunnel(nftSerialId, polygonRecipientAddress, depositData, polygonPrice)
    // console.log(await tx.wait())
})

/*
* For flow to polygon user transfer
* Listens to see if an event associated with tunnel user transfer is emitted
* Checks if an associated json file with the token exists
* If it does not exist, a new one is created with the token's metadata
* Otherwise, the exisiting file is used
* If the artist does not have an address on polygon, we assign it to address(0x0)
* The token is then received on the polygon side if a polygonRecipientAddress is passed
*/
fcl_api.events(FLOW_USER_TRANSFER_EVENT).subscribe(async (event) => {

    let { nft, polygonRecipientAddress } = event
    let { nftSerialId, metadata, artistAddressFlow, artistAddressPolygon, royalty } = nft

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

    const ponsNftTunnel = new ethers.Contract(PONS_NFT_TUNNEL_ADDRESS, flowTunnelContractInformation.abi, signer)

    if (polygonRecipientAddress) {
        await ponsNftTunnel.getFromTunnel(nftSerialId, polygonRecipientAddress, depositData, ethers.constants.MaxUint256)
    } else {
        // TODO: Add transaction to send back token to flow if no recipient address on polygon
    }
})


/*
* For polygon to flow market transfer and listing in FUSD
* Actively listens to check if an event associated with the cross bridge market trasnfer is emitted
* When an event is picked up, both the tokenId and price are converted from bigNumber to strings
* flowAddress should be the flowMarketplace address
* A transaction is then sent to the flow side receive the nft and list it FUSD
*/
flowTunnelProxyInstance.on(POLYGON_FUSD_MARKET_TRANSFER_EVENT, async (tokenId, sender, flowAddress, polygonLister, price) => {

    tokenId = tokenId.toString()
    price = price.toString()

    if (!flowAddress) {
        flowAddress = FLOW_MARKETPLACE_ADDRESS
    }

    await
        send_proposed_transaction_
            ('0xPONS')
            (`
                import PonsTunnelContract from 0xPONS
                import PonsUtils from 0xPONS
            
                transaction(
                nftSerialId: UInt64,
                salePrice: UFix64,
                polygonListingAddress: String
                ) {
                    prepare (ponsAccount : AuthAccount){
                        PonsTunnelContract .recieveNftFromTunnel_market_fusd (nftSerialId: nftSerialId, ponsAccount: ponsAccount, ponsHolderAccount: ponsAccount, polygonListingAddress: polygonListingAddress, salePrice: salePrice);
                    }
                }
            `)
            ([flow_sdk_api.arg(tokenId, flow_types.UInt64),
            flow_sdk_api.arg('' + Number(price).toFixed(1), flow_types.UFix64),
            flow_sdk_api.arg(polygonLister, flow_types.String),
            ])
})

/*
* For polygon to flow market transfer and listing in flow tokens
* Actively listens to check if an event associated with the cross bridge market trasnfer is emitted
* When an event is picked up, both the tokenId and price are converted from bigNumber to strings
* flowAddress should be the flowMarketplace address
* A transaction is then sent to the flow side receive the nft and list it flow tokens
*/
flowTunnelProxyInstance.on(POLYGON_FLOW_MARKET_TRANSFER_EVENT, async (tokenId, sender, flowAddress, polygonLister, price) => {
    // console.log("----------------------------------------- POLYGON listener -----------------------------------------")
    tokenId = tokenId.toString()
    price = price.toString()

    if (!flowAddress) {
        flowAddress = FLOW_MARKETPLACE_ADDRESS
    }

    await
    send_proposed_transaction_
            (['0xPONS'])
            (`
                import PonsTunnelContract from 0xPONS
                import PonsUtils from 0xPONS
            
                transaction(
                nftSerialId: UInt64,
                salePrice: UFix64,
                polygonListingAddress: String
                ) {
                    prepare (ponsAccount : AuthAccount){
                        PonsTunnelContract .recieveNftFromTunnel_market_flow (nftSerialId: nftSerialId, ponsAccount: ponsAccount, ponsHolderAccount: ponsAccount, polygonListingAddress: polygonListingAddress, salePrice: salePrice);
                    }
                }
            `)
            ([flow_sdk_api.arg(tokenId, flow_types.UInt64),
            flow_sdk_api.arg('' + Number(price).toFixed(1), flow_types.UFix64),
            flow_sdk_api.arg(polygonLister, flow_types.String),
            ])
})


/*
* For polygon to flow user transfer
* Actively listens to check if an event associated with the cross bridge market trasnfer is emitted
* When an event is picked up, the tokenId is converted from BigNumber to string
* flowAddress should be the recepient's address on flow
* A transaction is then sent to the flow side to send the token to the PONSHOLDER account till the user redeems it
*/
flowTunnelProxyInstance.on(POLYGON_FLOW_USER_TRANSFER_EVENT, async (tokenId, sender, flowAddress) => {

    tokenId = tokenId.toString()

    if (flowAddress) {
        await
        send_proposed_transaction_
                (['0xPONS'])
                (`
                import PonsTunnelContract from 0xPONS
                            
                transaction(
                nftSerialId: UInt64,
                userAddress: Address,
                ) {
                    prepare (ponsHolderAccount : AuthAccount){
                        PonsTunnelContract .recieveNftFromTunnel (nftSerialId: nftSerialId, ponsHolderAccount: ponsHolderAccount, userAddress: userAddress);
                    }
                }
                `)
                ([flow_sdk_api.arg(tokenId, flow_types.UInt64),
                flow_sdk_api.arg(flowAddress, flow_types.Address)
                ])
    } else {
        // TODO: Add transaction to send back token to polygon flow address is not given
    }
}) 