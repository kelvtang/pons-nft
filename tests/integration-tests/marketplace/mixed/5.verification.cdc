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

	// Verifies the purchase is successful, and displays the intended recipients of
	// Flow tokens versus the actual deposits to help verify the transaction 

	if transactionSuccess {
		let artistAddressString = testInfo ["Artist address"] !
		let marketAddressString = testInfo ["Market address"] !

		let depositsData = TestUtils .typeEvents (".TokensDeposited", transactionEvents) 

		return {
			"verified": true,
			"artistAddress": artistAddressString,
			"marketAddress": marketAddressString,
			"deposits": depositsData
			} }
	else {
		return {
			"verified": false } } }
