import PonsArtistContract from 0xPONS

import TestUtils from 0xPONS

/*
	Unlist Purchased Listing Test

	Verifies that accounts can only unlist NFTs when it has not yet been purchased
*/
pub fun main 
( minterStoragePath : StoragePath
, mintId : String
, metadata : {String: String}
, basePriceAmount : UFix64
, royaltyRatioAmount : UFix64
, transactionSuccess : Bool
, transactionErrorMessage : String?
, transactionEvents : [{String: String}]
, testInfo : {String: String}
) : {String: AnyStruct} {

	// Verifies that already purchased NFTs cannot be unlisted
	// Checks the expected error

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
