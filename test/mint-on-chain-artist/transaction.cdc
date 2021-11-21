import PonsArtistContract from 0xPONS

transaction 
( ponsArtistId : String
, ponsArtistAddress : Address
, metadata : {String: String}
) {

	execute {
		let artistAccount = getAccount (ponsArtistAddress)
		recognisePonsArtist (
			ponsArtistId: ponsArtistId,
			ponsArtistAddress,
			metadata,
			artistAccount .getCapability <&{FungibleToken.Receiver}> (/public/flowTokenBalance) } }
