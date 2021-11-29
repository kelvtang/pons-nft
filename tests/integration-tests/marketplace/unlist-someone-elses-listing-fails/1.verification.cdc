import PonsArtistContract from 0xPONS

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

	// Verifies the setup and minting is successful

	if transactionSuccess {
		return {
			"verified": true } }
	else {
		return {
			"verified": false } } }
