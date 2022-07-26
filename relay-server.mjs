import express from 'express';
import { ethers } from 'ethers';
import * as fs from 'fs';
// import { send_transaction_, authorizer_ } from './utils/flow-api.mjs';
import { CHILD_TUNNEL_CONTRACT_ADDRESS, CHILD_TOKEN_ADDRESS, PRIVATE_KEYS } from './config.mjs';
import { BASE_TOKEN_URI } from './config.mjs';
import { flow_sdk_api } from './config.mjs';
import fcl_api from '@onflow/fcl';

const app = express();
app.use(express.json());

const templateContractInformation = JSON.parse(fs.readFileSync('./ethereum_polygon_tests/build/contracts/FxERC721.json', 'utf8'));
const childTunnelContractInformation = JSON.parse(fs.readFileSync('./ethereum_polygon_tests/build/contracts/FxERC721ChildTunnel.json', 'utf8'));

const polygonProvider = new ethers.providers.JsonRpcProvider("http://127.0.0.1:7545"); // change provider accordingly
const signer = new ethers.Wallet(PRIVATE_KEYS[1], polygonProvider)
const polygonChildTunnelContractInstance = new ethers.Contract(CHILD_TUNNEL_CONTRACT_ADDRESS, childTunnelContractInformation.abi,
    signer)
const abiCoder = ethers.utils.defaultAbiCoder

app.get("/metadata/:tokenId", (req, res) => {
    const tokenId = req.params.tokenId

    const path = `./token-metadata/${tokenId}`

    const data = fs.readFileSync(`${path}.json`)
    res.header("Content-Type", 'application/json');
    res.send(data)
})


// TODO: CH
const eventName = "A.7e60df042a9c0868.FlowToken.TokensDeposited"

app.listen(3000, () => console.log(`app running on 3000`))

fcl_api.events(eventName).subscribe((event) => {
    console.log(event)
    const { receiver, tokenId, tokenUri, royaltyReceiver, royaltyNumerator } = event

    const path = `./token-metadata/${tokenId}`

    // TODO: Need to process token URI first

    if (!fs.existsSync(path)) {
        let NFTMetada = {
            image: tokenUri,
            name: "bla",
            description: "blabla",
        }
        fs.writeFileSync(`${path}.json`, JSON.stringify(NFTMetada, null, 2))
    }


    // TODO: edit based on what we get from the flow event
    const depositData = abiCoder.encode(["string", "address", "uint96"], [`${BASE_TOKEN_URI}${tokenId}`, royaltyReceiver, royaltyNumerator])
    const data = abiCoder.encode(["address", "address", "uint256", "bytes"], [CHILD_TOKEN_ADDRESS, receiver, tokenId, depositData])
    const childSigner = new ethers.Wallet(PRIVATE_KEYS[1], polygonProvider);
    polygonChildTunnelContractInstance.connect(childSigner)
    polygonChildTunnelContractInstance.processMessageFromFLow(data)
})


polygonChildTunnelContractInstance.on('FlowDeposit', (data) => {
    let [flowReceiver, tokenId] = abiCoder.decode(['address', 'uint256'], data)
    tokenId = tokenId.toString() // change from bigNumber to string // could be an issue


    // TODO: change based on the flow implemntation
    var _transaction_response = await
    send_transaction_
        (authorizer_(address)(key_id)(private_key))
        (authorizer_(address)(key_id)(private_key))
        ([authorizer_(address)(key_id)(private_key)])
        ('transaction () {prepare (artistAccount : AuthAccount, ponsAccount : AuthAccount) {} }')
        ([flowReceiver, tokenId])
})

