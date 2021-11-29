import PonsArtistContract from 0xPONS

/*
	Recognise Off-chain Artist Test

	Tests that `recognisePonsArtist ()` works for artists without a Flow account.
*/
pub fun main 
( artistAuthorityStoragePath : StoragePath
, ponsArtistId : String
, metadata : {String: String}
, transactionSuccess : Bool
, transactionErrorMessage : String?
, transactionEvents : [{String: String}]
) : {String: AnyStruct} {

	// Verifies that the test completed successfully with no failed assertions, and produces a summary of the recorded artist's information for verification

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
