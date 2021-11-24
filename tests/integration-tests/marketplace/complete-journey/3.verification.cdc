import PonsArtistContract from 0xPONS

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

	if ! transactionSuccess {

		let expectedError = "Pons NFT with this nftId not found"
		let expectedErrorFound = TestUtils .substring (expectedError, in: transactionErrorMessage ?? "")

		let verified = expectedErrorFound

		return {
			"verified": verified,
			"expectedError": expectedError,
			"expectedErrorFound": expectedErrorFound } }
	else {
		return {
			"verified": false } } }
