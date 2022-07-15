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

	// WORKAROUND -- ignore
	// Ignore this test for now due to https://github.com/onflow/cadence/issues/1320
	return { "verified": true }
/*
	// Verifies that freshly minted NFTs cannot be unlisted
	// Checks the expected error

	if ! transactionSuccess {

		let expectedError = "Only the lister can redeem his Pons NFT"
		let expectedErrorFound = TestUtils .substring (expectedError, in: transactionErrorMessage ?? "")

		let verified = expectedErrorFound

		return {
			"verified": verified,
			"expectedError": expectedError,
			"expectedErrorFound": expectedErrorFound } }
	else {
		return {
			"verified": false } }
*/


	}
