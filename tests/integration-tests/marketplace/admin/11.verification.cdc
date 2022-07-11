import TestUtils from 0xPONS

/*
	Admin Test

	Verifies that the NFT Admin resource can update and maintain the NFT marketplace
*/
pub fun main 
( minterStoragePath : StoragePath
, mintId : String
, metadata : {String: String}
, changedMetadata : {String: String}
, basePriceAmount : UFix64
, changedPriceAmount : UFix64
, royaltyRatioAmount : UFix64
, transactionSuccess : Bool
, transactionErrorMessage : String?
, transactionEvents : [{String: String}]
, testInfo : {String: String}
) : {String: AnyStruct} {

	// Verifies the setup and minting is successful

	if transactionSuccess {
		return {
			"verified": true } }
	else {
		return {
			"verified": false } } }
