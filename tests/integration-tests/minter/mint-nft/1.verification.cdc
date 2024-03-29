/*
	Minter v1 Minting Test

	Tests that NFT Minter v1 is able to mint NFTs as specified.
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

	// Verifies the test completed with no failed assertions

	if transactionSuccess {
		return {
			"verified": true } }
	else {
		return {
			"verified": false } } }
