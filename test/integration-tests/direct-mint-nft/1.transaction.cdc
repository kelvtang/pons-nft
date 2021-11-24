import FungibleToken from 0xFUNGIBLETOKEN
import PonsUtils from 0xPONS
import PonsArtistContract from 0xPONS
import PonsNftContractInterface from 0xPONS
import PonsNftContract from 0xPONS
import PonsNftContract_v1 from 0xPONS

import TestUtils from 0xPONS

transaction 
( minterStoragePath : StoragePath
, mintId : String
, ponsArtistId : String
, royaltyRatioAmount : UFix64
, editionLabel : String
, metadata : {String: String}
) {

	prepare (ponsAccount : AuthAccount, artistAccount : AuthAccount) {
		let royalty = PonsUtils.Ratio (royaltyRatioAmount)
		let minterRef = ponsAccount .borrow <&PonsNftContract_v1.NftMinter_v1> (from: minterStoragePath) !

		var artistCertificate <- PonsArtistContract .makePonsArtistCertificate (artistAccount : artistAccount)

		minterRef .refillMintIds (mintIds: [ mintId ])

		var ponsNft <-
			minterRef .mintNft (
				& artistCertificate as &PonsArtistContract.PonsArtistCertificate,
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
