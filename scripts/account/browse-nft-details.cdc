import PonsNftContractInterface from 0xPONS
import PonsNftContract from 0xPONS

/* Borrow an NFT for browsing */
	/* Gets the nftId of a Pons NFT */
	/* Gets the serialNumber of a Pons NFT */
	/* Borrows the PonsArtist of a Pons NFT */
	/* Gets the royalty Ratio of a Pons NFT (i.e. how much percentage of resales are royalties to the artist) */
	/* Gets the edition label a Pons NFT to differentiate between distinct limited editions */
	/* Gets any other metadata of a Pons NFT (e.g. IPFS media url) */
	/* Get the metadata of a PonsArtist */
	/* Get the Flow address of a PonsArtist if available */
	/* Get the Capability to receive Flow tokens of a PonsArtist */
pub fun main (address : Address, nftId : String) : {String: AnyStruct} {
	let collector = getAuthAccount (address)
	let ponsCollectionRef = 
		collector .borrow <&{PonsNftContractInterface.PonsCollection}>
			( from: PonsNftContract .CollectionStoragePath )
	let nftRef = ponsCollectionRef .borrowNft (nftId: nftId)
	let artistRef = PonsNftContract .borrowArtist (nftRef)
	return {
		"nftId": PonsNftContract .getNftId (nftRef),
		"serialNumber": PonsNftContract .getSerialNumber (nftRef),
		"royalty": PonsNftContract .getRoyalty (nftRef),
		"editionLabel": PonsNftContract .getEditionLabel (nftRef),
		"metadata": PonsNftContract .getMetadata (nftRef),
		"artist": {
			"address": PonsNftContract .getArtistAddress (artistRef),
			"metadata": PonsNftContract .getArtistMetadata (artistRef),
			"receivePaymentCap": PonsNftContract .receivePaymentCap (artistRef) } } }
