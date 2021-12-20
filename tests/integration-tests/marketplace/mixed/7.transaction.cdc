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

	// Ignore this test for now due to https://github.com/onflow/cadence/issues/1320
/*
		// Tests the unlisting functionality, when the NFT has only been minted but never purchased
		// Should fail

		TestUtils .log ("Artist 1 normal tries to redeem freshly minted NFT with ListingCertificate")

		let secondNftId = testInfo ["Second NFT nftId"] !

		PonsUsage .unlist (
			lister: artistAccount,
			nftId: secondNftId )
*/

		} }
