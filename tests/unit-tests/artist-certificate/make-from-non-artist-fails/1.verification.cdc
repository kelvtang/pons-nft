import TestUtils from 0xPONS

pub fun main 
( transactionSuccess : Bool
, transactionErrorMessage : String?
, transactionEvents : [{String: String}]
) : {String: AnyStruct} {

	if ! transactionSuccess {

		let expectedError = "No artist is known to have this address"
		let expectedErrorFound = TestUtils .substring (expectedError, in: transactionErrorMessage ?? "")

		let verified = expectedErrorFound

		return {
			"verified": verified,
			"expectedError": expectedError,
			"expectedErrorFound": expectedErrorFound } }
	else {
		return { "verified": false } } }
