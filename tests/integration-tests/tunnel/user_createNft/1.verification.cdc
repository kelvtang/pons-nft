/*
	Mint for Sale Test

	Verifies that artists can mint NFTs for sale.
*/
pub fun main 
( minterStoragePath : StoragePath
, mintId : String
, ponsArtistId : String
, royaltyRatioAmount : UFix64
, editionLabel : String
, metadata : {String: String}
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
