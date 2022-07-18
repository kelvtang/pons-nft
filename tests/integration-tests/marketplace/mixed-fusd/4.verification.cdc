import PonsNftMarketContract from 0xPONS

import TestUtils from 0xPONS

pub fun main 
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
) : {String: AnyStruct} {

	// Verifies that NFTs can be listed on the marketplace
	// Displays the listed price, to aid verification

	if transactionSuccess {
		let firstNftId = testInfo ["First NFT nftId"] !

		let listedNftPrice = PonsNftMarketContract .getPriceFusd (nftId: firstNftId) !

		return {
			"verified": true,
			"listedNftPrice": listedNftPrice .fusdAmount } }
	else {
		return {
			"verified": false } } }
