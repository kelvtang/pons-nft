import PonsNftMarketContract from 0xPONS
import PonsNftContract from 0xPONS

/*
Borrow an NFT for browsing

Available information includes the nftId, serialNumber, royalty ratio, edition label, metadata, and Pons Artist
Available information on the Pons Artist includes the Flow address, metadata, and Capability to receive Flow tokens
*/
pub fun main (nftId : String) : {String: AnyStruct} {
	let nftRef = PonsNftMarketContract .borrowNft (nftId: nftId) !
	let artistRef = PonsNftContract .borrowArtist (nftRef)
	let artistDetails : {String: AnyStruct} = {
		"address": PonsNftContract .getArtistAddress (artistRef),
		"metadata": PonsNftContract .getArtistMetadata (artistRef),
		"receivePaymentCap": PonsNftContract .getArtistReceivePaymentCap (artistRef) }
	return {
		"nftId": PonsNftContract .getNftId (nftRef),
		"serialNumber": PonsNftContract .getSerialNumber (nftRef),
		"royalty": PonsNftContract .getRoyalty (nftRef),
		"editionLabel": PonsNftContract .getEditionLabel (nftRef),
		"metadata": PonsNftContract .getMetadata (nftRef),
		"artist": artistDetails } }
