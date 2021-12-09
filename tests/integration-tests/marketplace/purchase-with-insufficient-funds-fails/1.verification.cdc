import TestUtils from 0xPONS

/*
	Purchase with Insufficient Funds Fails Test

	Verifies that purchases with insufficient funds fail.
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
) : {String: AnyStruct} {

	// Verifies that NFTs cannot be purchased for less than its price on the market

	if ! transactionSuccess {

		let expectedError = "insufficient funds provided"
		let expectedErrorFound = TestUtils .substring (expectedError, in: transactionErrorMessage ?? "")

		let verified = expectedErrorFound

		return {
			"verified": verified,
			"expectedError": expectedError,
			"expectedErrorFound": expectedErrorFound } }
	else {
		return {
			"verified": false } } }
