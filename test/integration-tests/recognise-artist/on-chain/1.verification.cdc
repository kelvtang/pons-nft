import PonsArtistContract from 0xPONS

pub fun main 
( artistAuthorityStoragePath : StoragePath
, ponsArtistId : String
, ponsArtistAddress : Address
, metadata : {String: String}
, transactionSuccess : Bool
, transactionErrorMessage : String?
, transactionEvents : [{String: String}]
) : {String: AnyStruct} {

	if transactionSuccess {
		let ponsArtistRef = PonsArtistContract .borrowArtist (ponsArtistId: ponsArtistId)

		let addressOptional = PonsArtistContract .getAddress (ponsArtistRef)
		let metadata = PonsArtistContract .getMetadata (ponsArtistRef)
		let receivePaymentCap = PonsArtistContract .getReceivePaymentCap (ponsArtistRef)


		return {
			"verified": true,

			"addressOptional": addressOptional,
			"metadata": metadata,
			"receivePaymentCap": receivePaymentCap } }
	else {
		return {
			"verified": false } } }
