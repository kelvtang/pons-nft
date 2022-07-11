import FungibleToken from 0xFUNGIBLETOKEN
import PonsUtils from 0xPONS
import PonsNftMarketContract from 0xPONS
import PonsNftContract from 0xPONS
import PonsNftContract_v1 from 0xPONS

import TestUtils from 0xPONS
import PonsUsage from 0xPONS

/*
	Admin Test

	Verifies that the NFT Admin resource can update and maintain the NFT marketplace
*/
transaction 
( minterStoragePath : StoragePath
, mintId : String
, metadata : {String: String}
, changedMetadata : {String: String}
, basePriceAmount : UFix64
, changedPriceAmount : UFix64
, royaltyRatioAmount : UFix64
) {

	prepare (ponsAccount : AuthAccount, artistAccount : AuthAccount) {

		// Setup state for the test
		// 1) Mint an NFT for the artist

		TestUtils .log ("Mint 1 NFT")

		let minterRef = ponsAccount .borrow <&PonsNftContract_v1.NftMinter_v1> (from: minterStoragePath) !

		minterRef .refillMintIds (mintIds: [ mintId ])

		let basePrice = PonsUtils.FlowUnits (basePriceAmount, "FUSD")
		let royalty = PonsUtils.Ratio (royaltyRatioAmount)

		let nftIds =
			PonsUsage .mintForSale (
				minter: artistAccount,
				metadata: metadata,
				quantity: 1,
				basePrice: basePrice,
				incrementalPrice: PonsUtils.FlowUnits (0.0, "FUSD"),
				royalty )


		let firstNftId = nftIds [0]

		TestUtils .testInfo ("First NFT nftId", firstNftId)

		} }
