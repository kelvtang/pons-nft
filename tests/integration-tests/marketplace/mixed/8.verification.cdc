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

	// Verifies the purchase and unlisting is successful, and displays the intended recipients of
	// Flow tokens versus the actual deposits to help verify the transaction, also displaying 
	// whether intended Unlist events were emitted

	if transactionSuccess {
		let artistAddressString = testInfo ["Artist address"] !
		let marketAddressString = testInfo ["Market address"] !

		let depositsData = TestUtils .typeEvents (".TokensDeposited", transactionEvents) 
		let unlistsData = TestUtils .typeEvents (".PonsNFTUnlistedFlow", transactionEvents)

		let unlisted = unlistsData .length == 1

		return {
			"verified": unlisted,
			"unlistSuccessful": unlisted,
			"artistAddress": artistAddressString,
			"marketAddress": marketAddressString,
			"deposits": depositsData,
			"unlists": unlistsData } }
	else {
		return {
			"verified": false } } }
