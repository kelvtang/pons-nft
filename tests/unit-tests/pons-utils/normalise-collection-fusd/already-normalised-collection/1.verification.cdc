import TestUtils from 0xPONS

/*
	`normaliseCollection ()` on Normalised Collections Test

	Verifies that `normaliseCollection ()` does not have any effect on a normalised NFT collection.
*/
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
) : {String: AnyStruct} {

	// Verifies the collection normalisation completed successfully, and no assertions failed

	if transactionSuccess {

		return {
			"verified": true } }
	else {
		return {
			"verified": false } } }
