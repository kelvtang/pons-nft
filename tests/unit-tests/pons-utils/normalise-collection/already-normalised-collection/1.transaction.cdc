import NonFungibleToken from 0xNONFUNGIBLETOKEN
import FungibleToken from 0xFUNGIBLETOKEN
import PonsUtils from 0xPONS
import PonsNftMarketContract from 0xPONS
import PonsNftContract from 0xPONS
import PonsNftContract_v1 from 0xPONS

import TestUtils from 0xPONS
import PonsUsage from 0xPONS


/*
	`normaliseCollection ()` on Normalised Collections Test

	Verifies that `normaliseCollection ()` does not have any effect on a normalised NFT collection.
*/
transaction 
( minterStoragePath : StoragePath
, mintIds : [String]
, metadata : {String: String}
, quantity: Int
, basePriceAmount : UFix64
, incrementalPriceAmount : UFix64
, royaltyRatioAmount : UFix64
) {

	prepare (ponsAccount : AuthAccount, artistAccount : AuthAccount, randomAccount : AuthAccount) {

		// Setup for the `normaliseCollection ()` test
		// 1) Refill nftIds to the minter
		// 2) Mint an NFT
		// 3) Give FLOW to 'Random' account to purchase all the NFTs

		let basePrice = PonsUtils.FlowUnits (basePriceAmount)
		let incrementalPrice = PonsUtils.FlowUnits (incrementalPriceAmount)
		let royalty = PonsUtils.Ratio (royaltyRatioAmount)

		TestUtils .log ("Refill " .concat (quantity .toString ()) .concat (" NFT ids"))

		ponsAccount
		.borrow <&PonsNftContract_v1.NftMinter_v1> (from: minterStoragePath) !
		.refillMintIds (mintIds: mintIds)

		TestUtils .log ("Mint NFTs")

		let nftIds =
			PonsUsage .mintForSale (
				minter: artistAccount,
				metadata: metadata,
				quantity: quantity,
				basePrice: basePrice,
				incrementalPrice: incrementalPrice,
				royalty )

		TestUtils .log ("Give FLOW to 'Random'")

		randomAccount .borrow <&FungibleToken.Vault> (from: /storage/flowTokenVault) !
		.deposit (
			from: <- ponsAccount .borrow <&FungibleToken.Vault> (from: /storage/flowTokenVault) !
					.withdraw (amount: 100000.0) )

		TestUtils .log ("'Random' purchase all the NFTs")

		var nftIndex = 0
		while nftIndex < quantity {
			PonsUsage .purchase (
				patron: randomAccount,
				nftId: nftIds [nftIndex],
				priceLimit: nil )
			nftIndex = nftIndex + 1 }


		// Verify that `normaliseCollection ()` has no effect
		// 1) Record the NFT collection of 'Random'
		// 2) Call `normaliseCollection ()` on 'Random's Pons collection
		// 3) Verify that the collection is unchanged

		var serialNumbers : [UInt64] = []
		var serialNumbersString = ""

		var precheckIndex = 0

		while precheckIndex < quantity {
			let nftRef = PonsUsage .borrowOwnPonsNft (collector: randomAccount, nftId: nftIds[precheckIndex])
			let serialNumber = PonsNftContract .getSerialNumber (nftRef)

			serialNumbers .append (serialNumber)
			serialNumbersString = serialNumbersString .concat (serialNumber .toString ()) .concat (" ")

			precheckIndex = precheckIndex + 1 }

		TestUtils .log ("Expecting to find serialNumbers: " .concat (serialNumbersString))

		let ponsCollectionRef =
			randomAccount .borrow <&PonsNftContract_v1.Collection>
				( from: PonsNftContract .CollectionStoragePath ) !

		TestUtils .log ("Normalise collection")

		PonsUtils .normaliseCollection (ponsCollectionRef)

		var postcheckIndex = 0

		while postcheckIndex < quantity {
			let serialNumber = serialNumbers [postcheckIndex]
			if ! ponsCollectionRef .ownedNFTs .containsKey (serialNumber) {
				panic ("serialNumber for " .concat (serialNumber .toString ()) .concat (" is missing")) }
			var nft <- ponsCollectionRef .ownedNFTs .remove (key: serialNumber) !
			if nft .id != serialNumber {
				panic ("serialNumber for " .concat (serialNumber .toString ()) .concat (" does not match")) }
			destroy ponsCollectionRef .ownedNFTs .insert (key: serialNumber, <- nft)
			postcheckIndex = postcheckIndex + 1 }

		} }
