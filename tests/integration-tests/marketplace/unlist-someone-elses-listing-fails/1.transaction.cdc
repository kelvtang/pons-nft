import FungibleToken from 0xFUNGIBLETOKEN
import PonsUtils from 0xPONS
import PonsArtistContract from 0xPONS
import PonsNftMarketContract from 0xPONS
import PonsNftContract from 0xPONS
import PonsNftContract_v1 from 0xPONS

import TestUtils from 0xPONS

/*
	Unlist someone else's Listing Test

	Verifies that accounts can only unlist NFTs which he has listed
*/
transaction 
( minterStoragePath : StoragePath
, mintId : String
, metadata : {String: String}
, basePriceAmount : UFix64
, royaltyRatioAmount : UFix64
) {

	prepare (ponsAccount : AuthAccount, artistAccount : AuthAccount, patronAccount : AuthAccount, randomAccount : AuthAccount) {

		// Setup state for the test
		// 1) Add an untaken nftId to Pons NFT minter, so that NFTs can be minted for artists
		// 2) Mint NFT for the artist
		// 3) Give Flow tokens to the 'Patron' and 'Random' accounts, so they may participate in purchasing
		// 4) 'Patron' buys the NFT, and lists it on the market 
		// 5) 'Random' buys the NFT, and lists it on the market 

		TestUtils .log ("Give FLOW to Patron 1 and Random 1")

		let minterRef = ponsAccount .borrow <&PonsNftContract_v1.NftMinter_v1> (from: minterStoragePath) !

		minterRef .refillMintIds (mintIds: [ mintId ])

		let basePrice = PonsUtils.FlowUnits (basePriceAmount)
		let royalty = PonsUtils.Ratio (royaltyRatioAmount)

		let nftIds =
			PonsNftMarketContract .mintForSale (
				minter: artistAccount,
				metadata: metadata,
				quantity: 1,
				basePrice: basePrice,
				incrementalPrice: PonsUtils.FlowUnits (0.0),
				royalty )


		let firstNftId = nftIds [0]
		
		patronAccount .borrow <&FungibleToken.Vault> (from: /storage/flowTokenVault) !
		.deposit (
			from: <- ponsAccount .borrow <&FungibleToken.Vault> (from: /storage/flowTokenVault) !
					.withdraw (amount: PonsNftMarketContract .getPrice (nftId: firstNftId) !.flowAmount) )

		randomAccount .borrow <&FungibleToken.Vault> (from: /storage/flowTokenVault) !
		.deposit (
			from: <- ponsAccount .borrow <&FungibleToken.Vault> (from: /storage/flowTokenVault) !
					.withdraw (amount: 10000.0) )

		TestUtils .testInfo ("First NFT nftId", firstNftId)

		TestUtils .testInfo ("Market address", ponsAccount .address .toString ())

		TestUtils .testInfo ("Artist address", PonsArtistContract .getAddress (PonsNftContract .borrowArtist (PonsNftMarketContract .borrowNft (nftId: firstNftId) !)) !.toString ())

		PonsNftMarketContract .purchase (
			patron: patronAccount,
			nftId: firstNftId )

		PonsNftMarketContract .listForSale (
			lister: patronAccount,
			nftId: firstNftId,
			PonsUtils.FlowUnits (2000.0) )

		PonsNftMarketContract .purchase (
			patron: randomAccount,
			nftId: firstNftId )

		PonsNftMarketContract .listForSale (
			lister: randomAccount,
			nftId: firstNftId,
			PonsUtils.FlowUnits (2000.0) )

		} }