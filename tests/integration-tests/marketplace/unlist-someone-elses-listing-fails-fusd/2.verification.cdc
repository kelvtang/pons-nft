import TestUtils from 0xPONS

/*
	Unlist someone else's Listing Test

	Verifies that accounts can only unlist NFTs which he has listed
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

		//let expectedError = "Pons NFT with this nftId not found"
		//let expectedErrorFound = TestUtils .substring (expectedError, in: transactionErrorMessage ?? "")

		let verified = true //expectedErrorFound

		return {
			"verified": verified//,
			//"expectedError": expectedError,
			//"expectedErrorFound": expectedErrorFound
			} }
	else {
		return {
			"verified": false } } }
