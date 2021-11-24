import FungibleToken from 0xFUNGIBLETOKEN
import PonsUtils from 0xPONS
import PonsArtistContract from 0xPONS
import PonsNftMarketContract from 0xPONS
import PonsNftContract from 0xPONS
import PonsNftContract_v1 from 0xPONS

import TestUtils from 0xPONS

transaction 
( minterStoragePath : StoragePath
, mintIds : [String]
, metadata : {String: String}
, quantity: Int
, basePriceAmount : UFix64
, incrementalPriceAmount : UFix64
, royaltyRatioAmount : UFix64
, transactionSuccess : Bool
, transactionErrorMessage : String?
, transactionEvents : [{String: String}]
, testInfo : {String: String}
) {

	prepare (ponsAccount : AuthAccount, artistAccount : AuthAccount, patronAccount : AuthAccount, randomAccount : AuthAccount) {
		let firstNftId = testInfo ["First NFT nftId"] !
		let artistAddressString = testInfo ["First Artist address"] !
		let marketAddressString = testInfo ["Market address"] !


		TestUtils .log ("Patron 1 regular purchase")

		PonsNftMarketContract .purchase (
			patron: patronAccount,
			nftId: firstNftId )

		} }
