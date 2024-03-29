import FungibleToken from 0xFUNGIBLETOKEN
import PonsUtils from 0xPONS
import PonsNftContractInterface from 0xPONS
import PonsNftContract from 0xPONS
import PonsNftContract_v1 from 0xPONS

import TestUtils from 0xPONS
import PonsUsage from 0xPONS

/*
	Minter v1 Minting Test

	Tests that NFT Minter v1 is able to mint NFTs as specified.
*/
transaction 
( minterStoragePath : StoragePath
, mintId : String
, ponsArtistId : String
, royaltyRatioAmount : UFix64
, editionLabel : String
, metadata : {String: String}
) {

	prepare (ponsAccount : AuthAccount, artistAccount : AuthAccount) {

		// Sets up state to mint NFTs, mints one, and destroys it
		// 1) Obtain an artist certificate from the artist
		// 2) Refill a nftId to the Minter
		// 3) Mint an NFT
		// 4) Output its data to verify the correctness of the NFT
		// 5) Destroy the NFT

		let royalty = PonsUtils.Ratio (royaltyRatioAmount)
		let minterRef = ponsAccount .borrow <&PonsNftContract_v1.NftMinter_v1> (from: minterStoragePath) !

		var artistCertificate <- PonsUsage .makePonsArtistCertificateDirectly (artist: artistAccount)

		minterRef .refillMintIds (mintIds: [ mintId ])

		var ponsNft <-
			minterRef .mintNft (
				& artistCertificate as &PonsNftContract.PonsArtistCertificate,
				royalty: royalty,
				editionLabel: editionLabel,
				metadata : metadata )
		let ponsNftRef = & ponsNft as & PonsNftContractInterface.NFT

		destroy artistCertificate

		TestUtils .log ("Minted Pons NFT")
	
		TestUtils .log ("NFT Id: " .concat (PonsNftContract .getNftId (ponsNftRef)))
		TestUtils .log ("NFT Serial Number: " .concat (PonsNftContract .getSerialNumber (ponsNftRef) .toString ()))

		let ponsArtistRef = PonsNftContract .borrowArtist (ponsNftRef)

		TestUtils .log ("NFT Royalty: " .concat (PonsNftContract .getRoyalty (ponsNftRef) .amount .toString ()))
		TestUtils .log ("NFT Edition Label: " .concat (PonsNftContract .getEditionLabel (ponsNftRef)))

		let metadata = PonsNftContract .getMetadata (ponsNftRef)

		destroy ponsNft } }
