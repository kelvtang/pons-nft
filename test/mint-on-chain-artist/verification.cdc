import PonsArtistContract from 0xPONS

pub fun main 
( ponsArtistId : String
, ponsArtistAddress : Address
, metadata : {String: String} )
: {String: String} {
	let artistAccount = getAccount (ponsArtistAddress)
	recognisePonsArtist (
		ponsArtistId: ponsArtistId,
		ponsArtistAddress,
		metadata,
		artistAccount .getCapability <&{FungibleToken.Receiver}> (/public/flowTokenBalance)  }
