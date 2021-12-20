import FungibleToken from 0xFUNGIBLETOKEN
import FlowToken from 0xFLOWTOKEN
import PonsUtils from 0xPONS
import PonsNftContractInterface from 0xPONS
import PonsNftContract from 0xPONS
import PonsNftMarketContract from 0xPONS

transaction
( nftId : String
, priceLimit : PonsUtils.FlowUnits?
) {
	prepare (patron : AuthAccount) {
		/* Purchases a NFT from the marketplace, using the account's default Flow token vault */
		let purchase =
			fun (patron : AuthAccount, nftId : String, priceLimit : PonsUtils.FlowUnits?) : Void {
				pre {
					PonsNftMarketContract .borrowNft (nftId: nftId) != nil:
						"Pons NFT with this nftId is not available on the market" }

				// Obtain the price of the NFT to be purchased
				let nftFlowUnits = PonsNftMarketContract .getPrice (nftId: nftId) !
				let nftPrice = nftFlowUnits .flowAmount

				// Obtain the price of the NFT to be purchased
				if priceLimit != nil && ! (priceLimit !.isAtLeast (nftFlowUnits)) {
					panic ("The price of the Pons NFT exceeds your price limit") }

				// Obtain the Flow token vault of the patron and withdraw the amount for which the NFT is on sale
				var paymentVault <-
					patron .borrow <&FungibleToken.Vault> (from: /storage/flowTokenVault) !
						.withdraw (amount: nftPrice)

				// Save the payment vault to the users storage so that its owner will be marked as the patron.
				// This allows the Pons NFT system to detect the new owner of the NFT
				patron .save (
					<- paymentVault,
					to: /storage/ponsMarketPurchaseVault )

				// Withdraw the vault, now marked with its owner
				var purchaseVault <-
					patron .load <@FungibleToken.Vault> (
						from: /storage/ponsMarketPurchaseVault ) !

				// Purchase the specified NFT using the Flow token vault
				purchaseUsingVault (patron: patron, nftId: nftId, <- purchaseVault) }

		/* Purchases a NFT from the marketplace, using a specified Flow token vault */
		let purchaseUsingVault =
			fun (patron : AuthAccount, nftId : String, _ purchaseVault : @FungibleToken.Vault) : Void {
				pre {
					PonsNftMarketContract .borrowNft (nftId: nftId) != nil:
						"Pons NFT with this nftId is not available on the market" }

				// Obtain information on the NFT to be purchased
				let price = PonsNftMarketContract .getPrice (nftId: nftId) !
				let nftRef = PonsNftMarketContract .borrowNft (nftId: nftId) !
				let serialNumber = PonsNftContract .getSerialNumber (nftRef)
				let editionLabel = PonsNftContract .getEditionLabel (nftRef)

				// Purchase the NFT from the active Pons market, using the provided Flow token vault
				var nft <-
					PonsNftMarketContract .ponsMarket .purchase (nftId: nftId, <- purchaseVault)

				// Deposit the purchased NFT in the patron's Pons collection
				borrowOwnPonsCollection (collector: patron)
				.depositNft (<- nft) }

		/* Borrows a PonsCollection from an account, creating one if it does not exist */
		let borrowOwnPonsCollection =
			fun (collector : AuthAccount) : &PonsNftContractInterface.Collection {
				acquirePonsCollection (collector: collector)

				return collector .borrow <&PonsNftContractInterface.Collection> (from: PonsNftContract .CollectionStoragePath) ! }

		/* Ensures an account has a PonsCollection, creating one if it does not exist */
		let acquirePonsCollection =
			fun (collector : AuthAccount) : Void {
				var collectionOptional <-
					collector .load <@PonsNftContractInterface.Collection>
						( from: PonsNftContract .CollectionStoragePath )

				if collectionOptional == nil {
					destroy collectionOptional
					collector .save (<- PonsNftContract .createEmptyPonsCollection (), to: PonsNftContract .CollectionStoragePath) }
				else {
					collector .save (<- collectionOptional !, to: PonsNftContract .CollectionStoragePath) } }

		purchase (patron: patron, nftId: nftId, priceLimit: priceLimit) } }
