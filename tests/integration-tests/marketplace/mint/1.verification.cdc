/*
	Mint for Sale Test

	Verifies that artists can mint NFTs for sale.
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

	// Verifies that the minting for sale completes successfully with no failed assertions

	if transactionSuccess {
		return {
			"verified": true } }
	else {
		return {
			"verified": false } } }
