import PonsArtistContract from 0xPONS

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

	if transactionSuccess {
		let ponsArtistRef = PonsArtistContract .borrowArtist (ponsArtistId: ponsArtistId)

		return {
			"verified": true } }
	else {
		return {
			"verified": false } } }
