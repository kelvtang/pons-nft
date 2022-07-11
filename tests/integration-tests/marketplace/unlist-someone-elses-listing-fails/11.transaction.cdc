import FungibleToken from 0xFUNGIBLETOKEN
import PonsUtils from 0xPONS
import PonsNftMarketContract from 0xPONS
import PonsNftContract from 0xPONS
import PonsNftContract_v1 from 0xPONS

import TestUtils from 0xPONS
import PonsUsage from 0xPONS

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

		let basePrice = PonsUtils.FlowUnits (basePriceAmount, "FUSD")
		let royalty = PonsUtils.Ratio (royaltyRatioAmount)

		let nftIds =
			PonsUsage .mintForSale (
				minter: artistAccount,
				metadata: metadata,
				quantity: 1,
				basePrice: basePrice,
				incrementalPrice: PonsUtils.FlowUnits (0.0, "FUSD"),
				royalty )


		let firstNftId = nftIds [0]
		
		patronAccount .borrow <&FungibleToken.Vault> (from: /storage/fusdVault) !
		.deposit (
			from: <- ponsAccount .borrow <&FungibleToken.Vault> (from: /storage/fusdVault) !
					.withdraw (amount: PonsNftMarketContract .getPrice (nftId: firstNftId) !.flowAmount) )

		randomAccount .borrow <&FungibleToken.Vault> (from: /storage/fusdVault) !
		.deposit (
			from: <- ponsAccount .borrow <&FungibleToken.Vault> (from: /storage/fusdVault) !
					.withdraw (amount: 100.0) )

		TestUtils .testInfo ("First NFT nftId", firstNftId)

		TestUtils .testInfo ("Market address", ponsAccount .address .toString ())

		TestUtils .testInfo ("Artist address", PonsNftContract .getArtistAddress (PonsNftContract .borrowArtist (PonsNftMarketContract .borrowNft (nftId: firstNftId) !)) !.toString ())

		PonsUsage .purchase (
			patron: patronAccount,
			nftId: firstNftId,
			priceLimit: nil )

		PonsUsage .listForSale (
			lister: patronAccount,
			nftId: firstNftId,
			PonsUtils.FlowUnits (90.0, "FUSD") )

		PonsUsage .purchase (
			patron: randomAccount,
			nftId: firstNftId,
			priceLimit: nil )

		PonsUsage .listForSale (
			lister: randomAccount,
			nftId: firstNftId,
			PonsUtils.FlowUnits (90.0, "FUSD") )

		} }
