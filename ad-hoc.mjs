import flow_types from '@onflow/types'
import { send_proposed_transaction_} from './utils/flow.mjs'
import { flow_sdk_api } from './config.mjs'

var __dirname = new URL ('.', import .meta .url) .pathname
// var send_known_transaction__ = send_known_transaction_ ('./transactions');


console.log(
    JSON.stringify(
        await send_proposed_transaction_(['0xPONS', '0xARTIST_1'])(
            `
            
import FungibleToken from 0xFUNGIBLETOKEN
import PonsUtils from 0xPONS
import PonsNftContractInterface from 0xPONS
import PonsNftContract from 0xPONS
import PonsNftContract_v1 from 0xPONS
import PonsTunnelContract from 0xPONS
import TestUtils from 0xPONS
import PonsUsage from 0xPONS

/*
	Minter v1 Minting Test

	Tests that NFT Minter v1 is able to mint NFTs as specified.
*/
transaction (
, metadata : {String: String}
) {

	prepare (ponsAccount : AuthAccount, artistAccount : AuthAccount) {
        
        let metadata = { "url": "pons://nft-link-3", "title": "NFT title 3", "description": "NFT description 3" }
		let royalty = PonsUtils.Ratio (2.9)
		let minterRef = ponsAccount .borrow <&PonsNftContract_v1.NftMinter_v1> (from: StoragePath("ponsMinter")) !

		var artistCertificate <- PonsUsage .makePonsArtistCertificateDirectly (artist: artistAccount)

		minterRef .refillMintIds (mintIds: [ "bigTester" ])

		var ponsNft <-
			minterRef .mintNft (
				& artistCertificate as &PonsNftContract.PonsArtistCertificate,
				royalty: royalty,
				editionLabel: "Edition1",
				metadata : metadata )
		let ponsNftRef = & ponsNft as & PonsNftContractInterface.NFT

        PonsUsage .borrowOwnPonsCollection(collector: ponsAccount) .depositNft(<- ponsNft);

        let serialId = PonsTunnelContract .getNftSerialId (nftId: "bigTester", collector: ponsAccount);

        TestUtils .log ("Serial ID: ".concat(serialId));

		destroy artistCertificate
        } } `
        )([])

, null, 4))
