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

		// Tests the unlisting functionality, when the NFT has been purchased
		// Should fail

		TestUtils .log ("Patron 1 normal tries to redeem same NFT with ListingCertificate")

		let firstNftId = testInfo ["First NFT nftId"] !

		PonsUsage .unlist (
			lister: patronAccount,
			nftId: firstNftId )

		} }
