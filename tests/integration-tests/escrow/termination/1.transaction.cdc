import FungibleToken from 0xFUNGIBLETOKEN
import PonsUtils from 0xPONS
import PonsNftMarketContract from 0xPONS
import PonsNftContract from 0xPONS
import PonsNftContract_v1 from 0xPONS
import PonsEscrowContract from 0xPONS

import TestUtils from 0xPONS
import PonsUsage from 0xPONS

transaction 
( minterStoragePath : StoragePath
, mintIds : [String]
, metadata : {String: String}
, basePriceAmount : UFix64
, incrementalPriceAmount : UFix64
, royaltyRatioAmount : UFix64
) {

	prepare (ponsAccount : AuthAccount, artistAccount : AuthAccount, randomAccount : AuthAccount) {

		// Setup state so that NFTs and Flow tokens can be exchanged in escrow:
		// 1) Add untaken NFT ids to Pons NFT minter, so that NFTs can be minted for artists
		// 2) Mint NFTs for the artist
		// 3) Purchase the NFTs with the Pons account

		TestUtils .log ("Pons Market account mints 3 NFTs on behalf of Artist account")

		let minterRef = ponsAccount .borrow <&PonsNftContract_v1.NftMinter_v1> (from: minterStoragePath) !

		minterRef .refillMintIds (mintIds: mintIds)

		let basePrice = PonsUtils.FlowUnits (basePriceAmount, "Flow Token")
		let incrementalPrice = PonsUtils.FlowUnits (incrementalPriceAmount, "Flow Token")
		let royalty = PonsUtils.Ratio (royaltyRatioAmount)

		let nftIds =
			PonsUsage .mintForSale (
				minter: artistAccount,
				metadata: metadata,
				quantity: 3,
				basePrice: basePrice,
				incrementalPrice: incrementalPrice,
				royalty )

		artistAccount .borrow <&FungibleToken.Vault> (from: /storage/flowTokenVault) !
		.deposit (
			from: <- ponsAccount .borrow <&FungibleToken.Vault> (from: /storage/flowTokenVault) !
					.withdraw (amount: 100.0) )


		let firstNftId = nftIds [0]
		let secondNftId = nftIds [1]
		let thirdNftId = nftIds [2]


		TestUtils .testInfo ("First NFT nftId", firstNftId)

		TestUtils .testInfo ("Second NFT nftId", secondNftId)

		TestUtils .testInfo ("Third NFT nftId", thirdNftId)

		TestUtils .testInfo ("Market address", ponsAccount .address .toString ())

		TestUtils .testInfo ("Artist address", PonsNftContract .getArtistAddress (PonsNftContract .borrowArtist (PonsNftMarketContract .borrowNft (nftId: firstNftId) !)) !.toString ())

		} }
