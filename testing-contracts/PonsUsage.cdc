import FungibleToken from 0xFUNGIBLETOKEN
import FlowToken from 0xFLOWTOKEN
import PonsUtils from 0xPONS
import PonsNftContractInterface from 0xPONS
import PonsNftContract from 0xPONS
import PonsNftMarketContract from 0xPONS
import PonsEscrowContract from 0xPONS


pub contract PonsUsage {

	/* Creates Flow Vaults and Capabilities in the standard locations if they do not exist, and returns a capability to send Flow tokens to the account */
	pub fun prepareFlowCapability (account : AuthAccount) : Capability<&{FungibleToken.Receiver}> {
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

	/* Ensures an account has a PonsCollection, creating one if it does not exist */
	pub fun acquirePonsCollection (collector : AuthAccount) : Void {
		var collectionOptional <-
			collector .load <@PonsNftContractInterface.Collection>
				( from: PonsNftContract .CollectionStoragePath )

		if collectionOptional == nil {
			destroy collectionOptional
			collector .save (<- PonsNftContract .createEmptyPonsCollection (), to: PonsNftContract .CollectionStoragePath) }
		else {
			collector .save (<- collectionOptional !, to: PonsNftContract .CollectionStoragePath) } }

	/* Ensures an account has a PonsCollection, creating one if it does not exist */
	pub fun preparePonsNftReceiverCapability (collector : AuthAccount) : Capability<&{PonsNftContractInterface.PonsNftReceiver}> {
		var collectionOptional <-
			collector .load <@PonsNftContractInterface.Collection>
				( from: PonsNftContract .CollectionStoragePath )

		if collectionOptional == nil {
			destroy collectionOptional
			collector .save (<- PonsNftContract .createEmptyPonsCollection (), to: PonsNftContract .CollectionStoragePath) }
		else {
			collector .save (<- collectionOptional !, to: PonsNftContract .CollectionStoragePath) }


		if collector .borrow <&PonsNftContractInterface.Collection> (from: PonsNftContract .CollectionStoragePath) == nil {
			collector .save (<- PonsNftContract .createEmptyPonsCollection (), to: PonsNftContract .CollectionStoragePath) }

		if ! collector .getCapability <&{PonsNftContractInterface.PonsCollection,PonsNftContractInterface.PonsNftReceiver}> (/private/ponsCollectionNftReceiver) .check () {
			collector .link <&{PonsNftContractInterface.PonsNftReceiver}> (
				/private/ponsCollectionNftReceiver,
				target: PonsNftContract .CollectionStoragePath ) }

		return collector .getCapability <&{PonsNftContractInterface.PonsNftReceiver}> (/private/ponsCollectionNftReceiver) }

	/* Borrows a PonsCollection from an account, creating one if it does not exist */
	pub fun borrowOwnPonsCollection (collector : AuthAccount) : &PonsNftContractInterface.Collection {
		PonsUsage .acquirePonsCollection (collector: collector)

		return collector .borrow <&PonsNftContractInterface.Collection> (from: PonsNftContract .CollectionStoragePath) ! }

	/* Borrows a Pons NFT from an account */
	pub fun borrowOwnPonsNft (collector : AuthAccount, nftId : String) : &PonsNftContractInterface.NFT {
		var collectionRef =
			collector .borrow <&PonsNftContractInterface.Collection>
				( from: PonsNftContract .CollectionStoragePath ) !
		return collectionRef .borrowNft (nftId: nftId) }





	/* Create a PonsArtistCertificate authorisation resource */
	pub fun makePonsArtistCertificateDirectly (artist : AuthAccount) : @PonsNftContract.PonsArtistCertificate {
		PonsUsage .acquirePonsCollection (collector: artist)

		let ponsCollectionRef = PonsUsage .borrowOwnPonsCollection (collector : artist)
		return <- PonsNftContract .makePonsArtistCertificate (ponsCollectionRef) }

	/* Deposits a listing certificate into the account's default listing certificate collection */
	pub fun depositListingCertificate (_ account : AuthAccount, _ newListingCertificate : @{PonsNftMarketContract.PonsListingCertificate}) : Void {
		// Load the existing listing certificate collection of the account, if any
		var listingCertificateCollectionOptional <-
			account .load <@PonsNftMarketContract.PonsListingCertificateCollection>
				( from: PonsNftMarketContract .PonsListingCertificateCollectionStoragePath )

		if listingCertificateCollectionOptional != nil {
			// If the account already has a listing certificate collection
			// Add the new certificate and save the collection
			var listingCertificateCollection <- listingCertificateCollectionOptional !

			listingCertificateCollection .appendListingCertificates (item:<- newListingCertificate)

			account .save (<- listingCertificateCollection, to: PonsNftMarketContract .PonsListingCertificateCollectionStoragePath) }
		else {
			// If the account does not have a listing certificate collection
			// Create a new listing certificate collection, add the new certificate and save the collection
			// Destroy the nil to make the resource checker happy
			destroy listingCertificateCollectionOptional
			
			var listingCertificateCollection <- PonsNftMarketContract .createPonsListingCertificateCollection ()

			listingCertificateCollection .appendListingCertificates (item:<- newListingCertificate)

			account .save (<- listingCertificateCollection, to: PonsNftMarketContract .PonsListingCertificateCollectionStoragePath) } }

	/* Deposit listing certificates into the account's default listing certificate collection */
	pub fun depositListingCertificates (_ account : AuthAccount, _ newListingCertificates : @[{PonsNftMarketContract.PonsListingCertificate}]) : Void {
		// Load the existing listing certificate collection of the account, if any
		var listingCertificateCollectionOptional <-
			account .load <@PonsNftMarketContract.PonsListingCertificateCollection>
				( from: PonsNftMarketContract .PonsListingCertificateCollectionStoragePath )

		if listingCertificateCollectionOptional != nil {
			// If the account already has a listing certificate collection
			// Retrieve each new listing certificate and add it to the collection, then save the collection
			var listingCertificateCollection <- listingCertificateCollectionOptional !

			while newListingCertificates .length > 0 {
				listingCertificateCollection .appendListingCertificates (item:<- newListingCertificates .remove (at: 0)) }

			destroy newListingCertificates

			account .save (<- listingCertificateCollection, to: PonsNftMarketContract .PonsListingCertificateCollectionStoragePath) }
		else {
			// If the account already has a listing certificate collection
			// Create a new listing certificate collection, retrieve each new listing certificate and add it to the collection, then save the collection
			// Destroy the nil to make the resource checker happy
			destroy listingCertificateCollectionOptional

			var listingCertificateCollection <- PonsNftMarketContract .createPonsListingCertificateCollection ()

			while newListingCertificates .length > 0 {
				listingCertificateCollection .appendListingCertificates (item:<- newListingCertificates .remove (at: 0)) }

			destroy newListingCertificates

			account .save (<- listingCertificateCollection, to: PonsNftMarketContract .PonsListingCertificateCollectionStoragePath) } }

	/* Withdraw listing certificates from the account's default listing certificate collection */
	pub fun withdrawListingCertificate (_ account : AuthAccount, nftId : String) : @{PonsNftMarketContract.PonsListingCertificate} {
		// Load the existing listing certificate collection of the account, which must already exist
		var listingCertificateCollectionRef = account .borrow <&PonsNftMarketContract.PonsListingCertificateCollection> (from: PonsNftMarketContract .PonsListingCertificateCollectionStoragePath) !

		// We iterate through all listing certificate in the collection, from the end of the collection
		// Given that we only deposit listing certificates using append, as in the deposit functions
		// If multiple listing certificates are present with the same nftId, the last one will be the latest certificate and the previous ones will be invalid
		var listingCertificateIndex = listingCertificateCollectionRef .listingCertificates .length - 1
		while listingCertificateIndex >= 0 {
			// If the NFT has the specified nftId
			if listingCertificateCollectionRef .listingCertificates [listingCertificateIndex] .nftId == nftId {
				// If so, retrieve the NFT and return it
				return <- listingCertificateCollectionRef .removeListingCertificates (at: listingCertificateIndex) }

			listingCertificateIndex = listingCertificateIndex - 1 }
		panic ("Pons Listing Certificate for this nftId not found") }






	/* Mint new NFTs for sale for Pons artists */
	pub fun mintForSale 
	( minter : AuthAccount
	, metadata : {String: String}
	, quantity : Int
	, basePrice : PonsUtils.FlowUnits
	, incrementalPrice : PonsUtils.FlowUnits
	, _ royaltyRatio : PonsUtils.Ratio
	) : [String] {
		// Obtain the minter's Capability to receive Flow tokens
		var receivePaymentCap = PonsUsage .prepareFlowCapability (account: minter)

		// Obtain an artist certificate of the minter
		var artistCertificate <- PonsUsage .makePonsArtistCertificateDirectly (artist: minter)
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
		PonsUsage .depositListingCertificates (minter, <- listingCertificates)

		// Return list of minted nftIds
		return nftIds }

	/* Lists an owned NFT on the marketplace for sale */
	pub fun listForSale (lister : AuthAccount, nftId : String, _ salePrice : PonsUtils.FlowUnits) : Void {
		pre {
			PonsUsage .borrowOwnPonsCollection (collector: lister) .borrowNft (nftId: nftId) != nil:
				"Pons NFT with this nftId does not belong to your Pons Collection" }
		// Obtain the minter's Capability to receive Flow tokens
		var receivePaymentCap = PonsUsage .prepareFlowCapability (account: lister)
		// Withdraw the specified nft from the lister's Pons collection
		var nft <- PonsUsage .borrowOwnPonsCollection (collector: lister) .withdrawNft (nftId: nftId)
		// List the NFT on the active Pons market for a listing certificate
		var listingCertificate <- PonsNftMarketContract .ponsMarket .listForSale (<- nft, salePrice, receivePaymentCap)
		// Deposit the listing certificate in the lister's listing certificate collection
		PonsUsage .depositListingCertificate (lister, <- listingCertificate) }

	/* Purchases a NFT from the marketplace, using a specified Flow token vault */
	pub fun purchaseUsingVault (patron : AuthAccount, nftId : String, _ purchaseVault : @FungibleToken.Vault) : Void {
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
		PonsUsage .borrowOwnPonsCollection (collector: patron)
		.depositNft (<- nft) }

	/* Purchases a NFT from the marketplace, using the account's default Flow token vault */
	pub fun purchase (patron : AuthAccount, nftId : String, priceLimit : PonsUtils.FlowUnits?) : Void {
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
		PonsUsage .purchaseUsingVault (patron: patron, nftId: nftId, <- purchaseVault) }

	/* Unlists a NFT from marketplace */
	pub fun unlist (lister : AuthAccount, nftId : String) : Void {
		// Find the lister's listing certificate for this nftId
		var listingCertificate <- PonsUsage .withdrawListingCertificate (lister, nftId: nftId)

		// First, unlist the NFT from the market, giving the listing certificate in return for the NFT
		// Then, deposit the NFT into the lister's Pons collection
		PonsUsage .borrowOwnPonsCollection (collector: lister)
		.depositNft (
			<- PonsNftMarketContract .ponsMarket .unlist (<- listingCertificate) ) }


	/* Get a free Capability Path to store a Capability to an Escrow */
	pub fun escrowCapabilityPath (_ account : AuthAccount, _ id : String) : CapabilityPath {
		// This function is not yet defined in this version of Cadence
		//return PrivatePath ("escrow__" .concat (id)) !
		let potentialCapabilityPaths =
			[ /private/escrow__1, /private/escrow__2, /private/escrow__3, /private/escrow__4, /private/escrow__5, /private/escrow__6, /private/escrow__7, /private/escrow__8, /private/escrow__9, /private/escrow__10 ]
		for capabilityPath in potentialCapabilityPaths {
			if account .getCapability <&PonsEscrowContract.Escrow> (capabilityPath) .check () {
				let storagePath = account .getLinkTarget (capabilityPath) ! as! StoragePath
				let escrowRefOptional = account .borrow <&PonsEscrowContract.Escrow> (from: storagePath) 
				if escrowRefOptional == nil {
					account .unlink (capabilityPath)
					return capabilityPath }
				else {
					if escrowRefOptional !.isReleased () {
						account .unlink (capabilityPath)
						destroy account .load <@PonsEscrowContract.Escrow> (from: storagePath)
						return capabilityPath } } }
			else {
				return capabilityPath } }
		panic ("No free escrow capability paths found") }

	/* Get a free Storage Path to store a Capability to an Escrow */
	pub fun escrowStoragePath (_ account : AuthAccount, _ id : String) : StoragePath {
		//return StoragePath ("escrow__" .concat (id)) !
		let potentialStoragePaths =
			[ /storage/escrow__1, /storage/escrow__2, /storage/escrow__3, /storage/escrow__4, /storage/escrow__5, /storage/escrow__6, /storage/escrow__7, /storage/escrow__8, /storage/escrow__9, /storage/escrow__10 ]
		for storagePath in potentialStoragePaths {
			let escrowRefOptional = account .borrow <&PonsEscrowContract.Escrow> (from: storagePath) 
			if escrowRefOptional == nil {
				return storagePath }
			else {
				if escrowRefOptional !.isReleased () {
					destroy account .load <@PonsEscrowContract.Escrow> (from: storagePath)
					return storagePath } } }
		panic ("No free escrow storage paths found") }

	/* Submit an escrowing using the specified id, resources, requirement, and fulfillment */
	pub fun submitEscrowUsing
	( submitter : AuthAccount, id : String
	, resources : @PonsEscrowContract.EscrowResource
	, requirement : PonsEscrowContract.EscrowResourceDescription, fulfillment : PonsEscrowContract.EscrowFulfillment
	) : StoragePath {
		// Obtain escrow capability and storage paths
		let capabilityPath = PonsUsage .escrowCapabilityPath (submitter, id)
		let storagePath = PonsUsage .escrowStoragePath (submitter, id)

		// Create an escrow capability to the escrow storage path
		let escrowCap = submitter .link <&PonsEscrowContract.Escrow> (capabilityPath, target: storagePath) !

		// First, submit an escrow with the specified information and resources, obtaining an Escrow resource
		// Then, save the Escrow resource to the arranged storage path
		submitter .save (
			<- PonsEscrowContract .submitEscrow (
				id: id, escrowCap: escrowCap, resources: <- resources,
				requirement: requirement, fulfillment: fulfillment ),
			to: storagePath )

		return storagePath }

	/* Submit an escrow using the specified id and requirement, gathering the escrow resources and fulfillment from the default paths */
	pub fun submitEscrow
	( submitter : AuthAccount, id : String
	, heldResourceDescription : PonsEscrowContract.EscrowResourceDescription, requirement : PonsEscrowContract.EscrowResourceDescription
	) : StoragePath {
		// Ensure the submitter has a Flow Vault and a PonsCollection, constructing an EscrowFulfillment using the two
		let fulfillment =
			PonsEscrowContract.EscrowFulfillment (
				receivePaymentCap: PonsUsage .prepareFlowCapability (account: submitter),
				receiveNftCap: PonsUsage .preparePonsNftReceiverCapability (collector: submitter) )

		// Withdraw the amount specified by heldResourceDescription
		var heldFlowVault <- 
			submitter .borrow <&FungibleToken.Vault> (from: /storage/flowTokenVault) !
				.withdraw (amount: heldResourceDescription .flowUnits .flowAmount)

		// Withdraw the nfts specified by heldResourceDescription
		var heldPonsNfts : @[PonsNftContractInterface.NFT] <- []
		for nftId in heldResourceDescription .getPonsNftIds () {
			heldPonsNfts .append (<- PonsUsage .borrowOwnPonsCollection (collector: submitter) .withdrawNft (nftId: nftId)) }

		// Create EscrowResource based on the withdrawn Flow Vault and Pons NFTs
		var heldResources <-
			PonsEscrowContract .makeEscrowResource (flowVault: <- heldFlowVault, ponsNfts: <- heldPonsNfts)

		// Submit the obtained EscrowFulfillment and EscrowResource for escrow
		return PonsUsage .submitEscrowUsing (
			submitter: submitter, id: id,
			resources: <- heldResources, requirement: requirement,
			fulfillment: fulfillment ) }
	}
