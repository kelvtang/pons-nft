import FungibleToken from 0xFUNGIBLETOKEN
import FlowToken from 0xFLOWTOKEN
import PonsUtils from 0xPONS
import PonsNftContractInterface from 0xPONS
import PonsNftContract from 0xPONS
import PonsNftMarketContract from 0xPONS

/* Mint new NFTs for sale */
transaction 
( metadata : {String: String}
, quantity : Int
, basePrice : PonsUtils.FlowUnits
, incrementalPrice : PonsUtils.FlowUnits
, _ royaltyRatio : PonsUtils.Ratio
) {
	prepare (minter : AuthAccount) {
		/* Mint new NFTs for sale for Pons artists */
		let mintForSale =
			fun
			( minter : AuthAccount
			, metadata : {String: String}
			, quantity : Int
			, basePrice : PonsUtils.FlowUnits
			, incrementalPrice : PonsUtils.FlowUnits
			, _ royaltyRatio : PonsUtils.Ratio
			) : [String] {
				// Obtain the minter's Capability to receive Flow tokens
				var receivePaymentCap = prepareFlowCapability (account: minter)

				// Obtain an artist certificate of the minter
				var artistCertificate <- makePonsArtistCertificateDirectly (artist: minter)
				// Mint and list the specified NFT on the active Pons market, producing some listing certificates
				var listingCertificates <-
					PonsNftMarketContract .ponsMarket .mintForSale (
						& artistCertificate as &PonsNftContract.PonsArtistCertificate,
						metadata: metadata,
						quantity: quantity,
						basePrice: basePrice,
						incrementalPrice: incrementalPrice,
						royaltyRatio,
						receivePaymentCap )

				// Iterate over the obtained listing certificates to produce the nftIds of the newly minted NFTs
				let nftIds : [String] = []
				var nftIndex = 0
				while nftIndex < listingCertificates .length {
					nftIds .append (listingCertificates [nftIndex] .nftId)
					nftIndex = nftIndex + 1 }

				// Dispose of the artist certificate
				destroy artistCertificate
				// Deposit the listing certificates in the minter's storage
				depositListingCertificates (minter, <- listingCertificates)

				// Return list of minted nftIds
				return nftIds }

		/* Creates Flow Vaults and Capabilities in the standard locations if they do not exist, and returns a capability to send Flow tokens to the account */
		let prepareFlowCapability =
			fun (account : AuthAccount) : Capability<&{FungibleToken.Receiver}> {
				if account .borrow <&FlowToken.Vault> (from: /storage/flowTokenVault) == nil {
					account .save (<- FlowToken .createEmptyVault (), to: /storage/flowTokenVault) }

				if ! account .getCapability <&FlowToken.Vault{FungibleToken.Receiver}> (/public/flowTokenReceiver) .check () {
					account .link <&FlowToken.Vault{FungibleToken.Receiver}> (
						/public/flowTokenReceiver,
						target: /storage/flowTokenVault ) }

				if ! account .getCapability <&FlowToken.Vault{FungibleToken.Balance}> (/public/flowTokenBalance) .check () {
					// Create a public capability to the Vault that only exposes
					// the balance field through the Balance interface
					account .link <&FlowToken.Vault{FungibleToken.Balance}> (
						/public/flowTokenBalance,
						target: /storage/flowTokenVault ) }

				return account .getCapability <&{FungibleToken.Receiver}> (/public/flowTokenReceiver) }

		/* Create a PonsArtistCertificate authorisation resource */
		let makePonsArtistCertificateDirectly =
			fun (artist : AuthAccount) : @PonsNftContract.PonsArtistCertificate {
				acquirePonsCollection (collector: artist)

				let ponsCollectionRef = borrowOwnPonsCollection (collector : artist)
				return <- PonsNftContract .makePonsArtistCertificate (ponsCollectionRef) }

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

		/* Borrows a PonsCollection from an account, creating one if it does not exist */
		let borrowOwnPonsCollection =
			fun (collector : AuthAccount) : &PonsNftContractInterface.Collection {
				acquirePonsCollection (collector: collector)

				return collector .borrow <&PonsNftContractInterface.Collection> (from: PonsNftContract .CollectionStoragePath) ! }

		mintForSale (
			minter: minter,
			metadata: metadata,
			quantity: quantity,
			basePrice: basePrice,
			incrementalPrice: incrementalPrice,
			royaltyRatio ) } }
