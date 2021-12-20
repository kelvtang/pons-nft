import FungibleToken from 0xFUNGIBLETOKEN
import PonsUtils from 0xPONS
import PonsNftMarketContract from 0xPONS
import PonsNftContract_v1 from 0xPONS

import TestUtils from 0xPONS
import PonsUsage from 0xPONS

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

		// Tests the purchase of an already purchased NFT, which is no longer on the market.
		// Should fail.

		TestUtils .log ("Random 1 normal purchase same NFT afterwards")

		let firstNftId = testInfo ["First NFT nftId"] !

		PonsUsage .purchase (
			patron: randomAccount,
			nftId: firstNftId,
			priceLimit: nil )

		} }
