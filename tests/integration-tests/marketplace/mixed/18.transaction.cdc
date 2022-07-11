import FungibleToken from 0xFUNGIBLETOKEN
import PonsUtils from 0xPONS
import PonsNftMarketContract from 0xPONS
import PonsNftContract from 0xPONS
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
		
		// Tests unlisting of a NFT after it is purchased and listed on the marketplace

		TestUtils .log ("Random 1 normal purchase, list, then unlist")

		let thirdNftId = testInfo ["Third NFT nftId"] !
		let artistAddressString = testInfo ["Artist address"] !
		let marketAddressString = testInfo ["Market address"] !

		TestUtils .log ("Purchasing")
		PonsUsage .purchase (
			patron: randomAccount,
			nftId: thirdNftId,
			priceLimit: nil )
		TestUtils .log ("Listing")
		PonsUsage .listForSale (
			lister: randomAccount,
			nftId: thirdNftId,
			PonsUtils.FlowUnits (1.0, "Flow Token") )
		TestUtils .log ("Unlisting")
		PonsUsage .unlist (
			lister: randomAccount,
			nftId: thirdNftId )

		} }
