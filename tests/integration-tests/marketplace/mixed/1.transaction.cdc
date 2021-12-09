import FungibleToken from 0xFUNGIBLETOKEN
import PonsUtils from 0xPONS
import PonsNftMarketContract from 0xPONS
import PonsNftContract from 0xPONS
import PonsNftContract_v1 from 0xPONS

import TestUtils from 0xPONS

transaction 
( minterStoragePath : StoragePath
, mintIds : [String]
, metadata : {String: String}
, quantity: Int
, basePriceAmount : UFix64
, incrementalPriceAmount : UFix64
, royaltyRatioAmount : UFix64
) {

	prepare (ponsAccount : AuthAccount, artistAccount : AuthAccount, patronAccount : AuthAccount, randomAccount : AuthAccount) {

		// Setup state so that marketplace mint, listing, unlisting, purchasing tests can proceed, and test minting:
		// 1) Add untaken NFT ids to Pons NFT minter, so that NFTs can be minted for artists
		// 2) Mint NFTs for the artist
		// 3) Give Flow tokens to the 'Patron' and 'Random' accounts, so they may participate in purchasing

		TestUtils .log ("Mint " .concat (quantity .toString () .concat (" NFTs")))
		TestUtils .log ("Give money to Patron 1 and Random 1")

		let minterRef = ponsAccount .borrow <&PonsNftContract_v1.NftMinter_v1> (from: minterStoragePath) !

		minterRef .refillMintIds (mintIds: mintIds)

		let basePrice = PonsUtils.FlowUnits (basePriceAmount)
		let incrementalPrice = PonsUtils.FlowUnits (incrementalPriceAmount)
		let royalty = PonsUtils.Ratio (royaltyRatioAmount)

		let nftIds =
			PonsNftMarketContract .mintForSale (
				minter: artistAccount,
				metadata: metadata,
				quantity: quantity,
				basePrice: basePrice,
				incrementalPrice: incrementalPrice,
				royalty )


		let firstNftId = nftIds [0]
		let secondNftId = nftIds [1]
		let thirdNftId = nftIds [2]
		
		patronAccount .borrow <&FungibleToken.Vault> (from: /storage/flowTokenVault) !
		.deposit (
			from: <- ponsAccount .borrow <&FungibleToken.Vault> (from: /storage/flowTokenVault) !
					.withdraw (amount: PonsNftMarketContract .getPrice (nftId: firstNftId) !.flowAmount) )

		randomAccount .borrow <&FungibleToken.Vault> (from: /storage/flowTokenVault) !
		.deposit (
			from: <- ponsAccount .borrow <&FungibleToken.Vault> (from: /storage/flowTokenVault) !
					.withdraw (amount: 10000.0) )

		TestUtils .testInfo ("First NFT nftId", firstNftId)

		TestUtils .testInfo ("Second NFT nftId", secondNftId)

		TestUtils .testInfo ("Third NFT nftId", thirdNftId)

		TestUtils .testInfo ("Market address", ponsAccount .address .toString ())

		TestUtils .testInfo ("Artist address", PonsNftContract .getArtistAddress (PonsNftContract .borrowArtist (PonsNftMarketContract .borrowNft (nftId: firstNftId) !)) !.toString ())

		} }
