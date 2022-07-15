import FungibleToken from 0xFUNGIBLETOKEN
import PonsUtils from 0xPONS
import PonsNftMarketContract from 0xPONS
import PonsNftContract from 0xPONS
import PonsNftContract_v1 from 0xPONS

import TestUtils from 0xPONS
import PonsUsage from 0xPONS

/*
	Purchase with Insufficient Funds Fails Test

	Verifies that purchases with insufficient funds fail.
*/
transaction 
( minterStoragePath : StoragePath
, mintId : String
, metadata : {String: String}
, basePriceAmount : UFix64
, royaltyRatioAmount : UFix64
) {

	prepare (ponsAccount : AuthAccount, artistAccount : AuthAccount, patronAccount : AuthAccount) {

		// Setup state for the test
		// 1) Add an untaken nftId to Pons NFT minter, so that NFTs can be minted for artists
		// 2) Mint NFT for the artist
		// 3) Give FUSD tokens to the 'Patron'
		// 4) 'Patron' buys the NFT with a Vault of insufficient funds

		TestUtils .log ("Give FUSD to 'Patron'")

		let minterRef = ponsAccount .borrow <&PonsNftContract_v1.NftMinter_v1> (from: minterStoragePath) !

		minterRef .refillMintIds (mintIds: [ mintId ])

		let basePrice = PonsUtils.FusdUnits (basePriceAmount)
		let royalty = PonsUtils.Ratio (royaltyRatioAmount)

		let nftIds =
			PonsUsage .mintForSaleFusd (
				minter: artistAccount,
				metadata: metadata,
				quantity: 1,
				basePrice: basePrice,
				incrementalPrice: PonsUtils.FusdUnits (0.0),
				royalty )


		let firstNftId = nftIds [0]
		
		patronAccount .borrow <&FungibleToken.Vault> (from: /storage/fusdVault) !
		.deposit (
			from: <- ponsAccount .borrow <&FungibleToken.Vault> (from: /storage/fusdVault) !
					.withdraw (amount: PonsNftMarketContract .getPriceFusd (nftId: firstNftId) !.fusdAmount) )

		TestUtils .testInfo ("First NFT nftId", firstNftId)

		TestUtils .testInfo ("Market address", ponsAccount .address .toString ())

		TestUtils .testInfo ("Artist address", PonsNftContract .getArtistAddress (PonsNftContract .borrowArtist (PonsNftMarketContract .borrowNft (nftId: firstNftId) !)) !.toString ())

		var insufficientFundsVault <-
			patronAccount .borrow <&FungibleToken.Vault> (from: /storage/fusdVault) !
				.withdraw (amount: PonsNftMarketContract .getPriceFusd (nftId: firstNftId) !.fusdAmount * 0.99)

		PonsUsage .purchaseUsingVaultFusd (
			patron: patronAccount,
			nftId: firstNftId,
			<- insufficientFundsVault )

		} }
