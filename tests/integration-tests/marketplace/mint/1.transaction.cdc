import PonsUtils from 0xPONS
import PonsNftMarketContract from 0xPONS
import PonsNftContract_v1 from 0xPONS

import TestUtils from 0xPONS
import PonsUsage from 0xPONS

/*
	Mint for Sale Test

	Verifies that artists can mint NFTs for sale.
*/
transaction 
( minterStoragePath : StoragePath
, mintIds : [String]
, metadata : {String: String}
, quantity: Int
, basePriceAmount : UFix64
, incrementalPriceAmount : UFix64
, royaltyRatioAmount : UFix64
) {

	prepare (ponsAccount : AuthAccount, artistAccount : AuthAccount) {

		// Refill nftIds to the minter and call the `mintForSale ()` function

		let minterRef = ponsAccount .borrow <&PonsNftContract_v1.NftMinter_v1> (from: minterStoragePath) !

		minterRef .refillMintIds (mintIds: mintIds)

		let basePrice = PonsUtils.FlowUnits (basePriceAmount)
		let incrementalPrice = PonsUtils.FlowUnits (incrementalPriceAmount)
		let royalty = PonsUtils.Ratio (royaltyRatioAmount)

		let nftIds =
			PonsUsage .mintForSale (
				minter: artistAccount,
				metadata: metadata,
				quantity: quantity,
				basePrice: basePrice,
				incrementalPrice: incrementalPrice,
				royalty ) } }
