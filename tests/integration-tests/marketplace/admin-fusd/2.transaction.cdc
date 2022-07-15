import PonsUtils from 0xPONS
import PonsNftContract from 0xPONS
import PonsNftContract_v1 from 0xPONS
import PonsNftMarketContract from 0xPONS
import PonsNftMarketAdminContract_v1 from 0xPONS

import TestUtils from 0xPONS
import PonsUsage from 0xPONS

/*
	Admin Test

	Verifies that the NFT Admin resource can update and maintain the NFT marketplace
*/
transaction 
( minterStoragePath : StoragePath
, mintId : String
, metadata : {String: String}
, changedMetadata : {String: String}
, basePriceAmount : UFix64
, changedPriceAmount : UFix64
, royaltyRatioAmount : UFix64
, transactionSuccess : Bool
, transactionErrorMessage : String?
, transactionEvents : [{String: String}]
, testInfo : {String: String}
) {

	prepare (ponsAccount : AuthAccount, artistAccount : AuthAccount) {

		// Admin updates the NFT price and metadata, and helps the artist directly withdraw his NFT

		TestUtils .log ("Admin updates NFT price and metadata")

		let firstNftId = testInfo ["First NFT nftId"] !

		let nftRef = PonsNftMarketContract .borrowPonsMarket () .borrowNft (nftId: firstNftId) !
		let nftAdminRef = ponsAccount .getCapability <&PonsNftMarketAdminContract_v1.NftMarketAdmin_v1> (/private/ponsMarketAdmin_v1) .borrow () !



		let originalPrice = PonsNftMarketContract .getPriceFusd (nftId: firstNftId) !
		TestUtils .log ("Original price: " .concat (originalPrice .fusdAmount .toString ()))

		let changedPrice = PonsUtils.FusdUnits (changedPriceAmount)
		nftAdminRef .updateSalePriceFusd (nftId: firstNftId, price: changedPrice)

		let updatedPrice = PonsNftMarketContract .getPriceFusd (nftId: firstNftId) !
		TestUtils .log ("Updated price: " .concat (updatedPrice .fusdAmount .toString ()))



		let originalMetadata = PonsNftContract .getMetadata (nftRef)
		TestUtils .log ("Original url: " .concat (originalMetadata ["url"] !))

		nftAdminRef .updatePonsNftMetadata (nftId: firstNftId, metadata: changedMetadata)

		let updatedMetadata = PonsNftContract .getMetadata (nftRef)
		TestUtils .log ("Updated url: " .concat (updatedMetadata ["url"] !))



		var nft <- nftAdminRef .borrowCollection () .withdrawNft (nftId: firstNftId)
		PonsUsage .borrowOwnPonsCollection (collector: artistAccount) .depositNft (<- nft)

		TestUtils .log ("NFT given to artist")

		} }
