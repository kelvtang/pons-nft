import FungibleToken from 0xFUNGIBLETOKEN
import PonsNftContract from 0xPONS
import PonsNftContract_v1 from 0xPONS
import PonsEscrowContract from 0xPONS

import TestUtils from 0xPONS
import PonsUsage from 0xPONS

transaction 
( minterStoragePath : StoragePath
, mintIds : [String]
, metadata : {String: String}
, basePriceAmount : UFix64
, incrementalPriceAmount : UFix64
, royaltyRatioAmount : UFix64
, transactionSuccess : Bool
, transactionErrorMessage : String?
, transactionEvents : [{String: String}]
, testInfo : {String: String}
) {

	prepare (ponsAccount : AuthAccount, artistAccount : AuthAccount, randomAccount : AuthAccount) {

		// ?

		TestUtils .log ("Pons account purchases all the NFTs")

		let firstNftId = testInfo ["First NFT nftId"] !
		let secondNftId = testInfo ["Second NFT nftId"] !
		let thirdNftId = testInfo ["Third NFT nftId"] !


		PonsUsage .purchaseFlow (
			patron: ponsAccount,
			nftId: firstNftId,
			priceLimit: nil )
		PonsUsage .purchaseFlow (
			patron: ponsAccount,
			nftId: secondNftId,
			priceLimit: nil )
		PonsUsage .purchaseFlow (
			patron: ponsAccount,
			nftId: thirdNftId,
			priceLimit: nil )
		

		} }
