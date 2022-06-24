import PonsNftContractInterface from 0xPONS
import PonsNftContract from 0xPONS
import PonsNftMarketContract from 0xPONS

/* Unlist a NFT from marketplace */
transaction
( nftId : String
) {
	prepare (lister : AuthAccount) {
		/* Unlists a NFT from marketplace */
		let unlist =
			fun (lister : AuthAccount, nftId : String) : Void {
				// Find the lister's listing certificate for this nftId
				var listingCertificate <- withdrawListingCertificate (lister, nftId: nftId)

				// First, unlist the NFT from the market, giving the listing certificate in return for the NFT
				// Then, deposit the NFT into the lister's Pons collection
				borrowOwnPonsCollection (collector: lister)
				.depositNft (
					<- PonsNftMarketContract .ponsMarket .unlist (<- listingCertificate) ) }

		/* Borrows a PonsCollection from an account, creating one if it does not exist */
		let borrowOwnPonsCollection =
			fun (collector : AuthAccount) : &PonsNftContractInterface.Collection {
				acquirePonsCollection (collector: collector)

				return collector .borrow <&PonsNftContractInterface.Collection> (from: PonsNftContract .CollectionStoragePath) ! }

		/* Ensures an account has a PonsCollection, creating one if it does not exist */
		let acquirePonsCollection =
			fun (collector : AuthAccount) : Void {
				var collectionRefOptional =
					collector .borrow <&PonsNftContractInterface.Collection>
						( from: PonsNftContract .CollectionStoragePath )

				if collectionRefOptional == nil {
					collector .save (<- PonsNftContract .createEmptyPonsCollection (), to: PonsNftContract .CollectionStoragePath) } }

		unlist (lister: lister, nftId: nftId) } }
