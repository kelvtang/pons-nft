import FungibleToken from 0xFUNGIBLETOKEN
import FlowToken from 0xFLOWTOKEN
import FUSD from 0xFUSD
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

		return account .getCapability <&{FungibleToken.Receiver}> (/public/flowTokenReceiver)}

	/* Creates FUSD Vaults and Capabilities in the standard locations if they do not exist, and returns a capability to send FUSD tokens to the account */
	pub fun prepareFusdCapability (account : AuthAccount) : Capability<&{FungibleToken.Receiver}> {
		if account .borrow <&FUSD.Vault> (from: /storage/fusdVault) == nil {
			account .save (<- FUSD .createEmptyVault (), to: /storage/fusdVault) }

		if ! account .getCapability <&FUSD.Vault{FungibleToken.Receiver}> (/public/fusdReceiver) .check () {
			account .link <&FUSD.Vault{FungibleToken.Receiver}> (
				/public/fusdReceiver,
				target: /storage/fusdVault ) }

		if ! account .getCapability <&FUSD.Vault{FungibleToken.Balance}> (/public/fusdBalance) .check () {
			// Create a public capability to the Vault that only exposes
			// the balance field through the Balance interface
			account .link <&FUSD.Vault{FungibleToken.Balance}> (
				/public/fusdBalance,
				target: /storage/fusdVault ) }

		return account .getCapability <&{FungibleToken.Receiver}> (/public/fusdReceiver)}

	/* Creates FUSD Vaults and Capabilities in the standard locations if they do not exist*/
	pub fun prepareFusd (account : AuthAccount) : Void {
		if account .borrow <&FUSD.Vault> (from: /storage/fusdVault) == nil {
			account .save (<- FUSD .createEmptyVault (), to: /storage/fusdVault) }

		if ! account .getCapability <&FUSD.Vault{FungibleToken.Receiver}> (/public/fusdReceiver) .check () {
			account .link <&FUSD.Vault{FungibleToken.Receiver}> (
				/public/fusdReceiver,
				target: /storage/fusdVault ) }

		if ! account .getCapability <&FUSD.Vault{FungibleToken.Balance}> (/public/fusdBalance) .check () {
			// Create a public capability to the Vault that only exposes
			// the balance field through the Balance interface
			account .link <&FUSD.Vault{FungibleToken.Balance}> (
				/public/fusdBalance,
				target: /storage/fusdVault ) }}


	/* Ensures an account has a PonsCollection, creating one if it does not exist */
	pub fun acquirePonsCollection (collector : AuthAccount) : Void {
		var collectionRefOptional =
			collector .borrow <&PonsNftContractInterface.Collection>
				( from: PonsNftContract .CollectionStoragePath )

		if collectionRefOptional == nil {
			collector .save (<- PonsNftContract .createEmptyPonsCollection (), to: PonsNftContract .CollectionStoragePath) } }

	/* Ensures an account has a PonsCollection, creating one if it does not exist */
	pub fun preparePonsNftReceiverCapability (collector : AuthAccount) : Capability<&{PonsNftContractInterface.PonsNftReceiver}> {
		var collectionRefOptional =
			collector .borrow <&PonsNftContractInterface.Collection>
				( from: PonsNftContract .CollectionStoragePath )

		if collectionRefOptional == nil {
			collector .save (<- PonsNftContract .createEmptyPonsCollection (), to: PonsNftContract .CollectionStoragePath) }


		if collector .borrow <&PonsNftContractInterface.Collection> (from: PonsNftContract .CollectionStoragePath) == nil {
			collector .save (<- PonsNftContract .createEmptyPonsCollection (), to: PonsNftContract .CollectionStoragePath) }

		if ! collector .getCapability <&{PonsNftContractInterface.PonsCollection,PonsNftContractInterface.PonsNftReceiver}> (/private/ponsCollectionNftReceiver) .check () {
			collector .link <&{PonsNftContractInterface.PonsNftReceiver}> (
				/private/ponsCollectionNftReceiver,
				target: PonsNftContract .CollectionStoragePath ) }

		return collector .getCapability <&{PonsNftContractInterface.PonsNftReceiver}> (/private/ponsCollectionNftReceiver)}

	/* Borrows a PonsCollection from an account, creating one if it does not exist */
	pub fun borrowOwnPonsCollection (collector : AuthAccount) : &PonsNftContractInterface.Collection {
		PonsUsage .acquirePonsCollection (collector: collector)
		return collector .borrow <&PonsNftContractInterface.Collection> (from: PonsNftContract .CollectionStoragePath) !}

	/* Borrows a Pons NFT from an account */
	pub fun borrowOwnPonsNft (collector : AuthAccount, nftId : String) : &PonsNftContractInterface.NFT {
		var collectionRef =
			collector .borrow <&PonsNftContractInterface.Collection>
				( from: PonsNftContract .CollectionStoragePath ) !
		return collectionRef .borrowNft (nftId: nftId)}

	/* Create a PonsArtistCertificate authorisation resource */
	pub fun makePonsArtistCertificateDirectly (artist : AuthAccount) : @PonsNftContract.PonsArtistCertificate {
		PonsUsage .acquirePonsCollection (collector: artist)

		let ponsCollectionRef = PonsUsage .borrowOwnPonsCollection (collector : artist)
		return <- PonsNftContract .makePonsArtistCertificate (ponsCollectionRef)}

	/* Deposits a listing certificate into the account's default listing certificate collection */
	pub fun depositListingCertificate (_ account : AuthAccount, _ newListingCertificate : @{PonsNftMarketContract.PonsListingCertificate}) : Void {
		// Borrow the existing listing certificate collection of the account, if any
		var listingCertificateCollectionRefOptional =
			account .borrow <&PonsNftMarketContract.PonsListingCertificateCollection>
				( from: PonsNftMarketContract .PonsListingCertificateCollectionStoragePath )

		if listingCertificateCollectionRefOptional != nil {
			// If the account already has a listing certificate collection
			// Add the new certificate and save the collection
			var listingCertificateCollectionRef = listingCertificateCollectionRefOptional !

			listingCertificateCollectionRef .appendListingCertificate (<- newListingCertificate) }
		else {
			// If the account does not have a listing certificate collection
			// Create a new listing certificate collection, add the new certificate and save the collection
			
			var listingCertificateCollection <- PonsNftMarketContract .createPonsListingCertificateCollection ()

		// Handles nil values.
		var count:Int? = (counter == nil? 0 : counter);


	/* Deposit listing certificates into the account's default listing certificate collection */
	pub fun depositListingCertificates (_ account : AuthAccount, _ newListingCertificates : @[{PonsNftMarketContract.PonsListingCertificate}]) : Void {
		// Borrow the existing listing certificate collection of the account, if any
		var listingCertificateCollectionRefOptional =
			account .borrow <&PonsNftMarketContract.PonsListingCertificateCollection>
				( from: PonsNftMarketContract .PonsListingCertificateCollectionStoragePath )

		if listingCertificateCollectionRefOptional != nil {
			// If the account already has a listing certificate collection
			// Retrieve each new listing certificate and add it to the collection, then save the collection
			var listingCertificateCollectionRef = listingCertificateCollectionRefOptional !

			while newListingCertificates .length > 0 {
				listingCertificateCollectionRef .appendListingCertificate (<- newListingCertificates .remove (at: 0)) }

			destroy newListingCertificates }
		else {
			// If the account already has a listing certificate collection
			// Create a new listing certificate collection, retrieve each new listing certificate and add it to the collection, then save the collection

		// Save to unique storage location
		account.save (<- listingCertificateHolder, to: collection_storage_path)}

	/* Deposit listing certificates into the account's default listing certificate collection */
	pub fun depositListingCertificates (_ account : AuthAccount, _ newListingCertificates : @[{PonsNftMarketContract.PonsListingCertificate}]) : Void {
		// Loop through new listing certificates.
		while newListingCertificates .length > 0 {
			var listingCertificateHolder <- PonsNftMarketContract .createPonsListingCertificateCollection ()
			
			// Move certificate to temporary variable
			var certificate <- newListingCertificates .remove (at: 0);

			// Generate unique storage path. Since no two nft can have same ID. Each path will always empty.
			//	// Can also be used to access listing certificate like a dictionary since each id can be used like a key.
			var counter:Int = 0;
			var collection_storage_path = PonsUsage .getPathFromID(certificate.nftId, counter: counter);
			while account .borrow <&PonsNftMarketContract.PonsListingCertificateCollection> (from: collection_storage_path) != nil{
				counter = counter + 1;
				collection_storage_path = PonsUsage .getPathFromID(certificate.nftId, counter: counter)}
			

			// Store in to a listing certicate collection
			listingCertificateHolder .appendListingCertificate(<- certificate );

			// Save to unique storage location
			account.save (<- listingCertificateHolder, to: collection_storage_path)}
		destroy newListingCertificates;}

	/* Withdraw listing certificates from the account's default listing certificate collection */
	pub fun withdrawListingCertificate (_ account : AuthAccount, nftId : String) : @{PonsNftMarketContract.PonsListingCertificate} {
		// Borrow the existing listing certificate collection of the account, which must already exist
		var listingCertificateCollectionRef = account .borrow <&PonsNftMarketContract.PonsListingCertificateCollection> (from: PonsNftMarketContract .PonsListingCertificateCollectionStoragePath) !

		// We iterate through all listing certificate in the collection, from the end of the collection
		// Given that we only deposit listing certificates using append, as in the deposit functions
		// If multiple listing certificates are present with the same nftId, the last one will be the latest certificate and the previous ones will be invalid
		var listingCertificateIndex = listingCertificateCollectionRef .listingCertificates .length - 1
		while listingCertificateIndex >= 0 {
			// If the NFT has the specified nftId
			if listingCertificateCollectionRef .listingCertificates [listingCertificateIndex] .nftId == nftId {
				// If so, retrieve the NFT and return it
				return <- listingCertificateCollectionRef .removeListingCertificate (at: listingCertificateIndex) }

			listingCertificateIndex = listingCertificateIndex - 1 }
		panic ("Pons Listing Certificate for this nftId not found") }






	/* Mint new NFTs for sale for Pons artists */
	pub fun mintForSaleFlow 
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
			PonsNftMarketContract .ponsMarket .mintForSaleFlow (
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
		return nftIds}

	/* Mint new NFTs for sale for Pons artists */
	pub fun mintForSaleFusd 
	( minter : AuthAccount
	, metadata : {String: String}
	, quantity : Int
	, basePrice : PonsUtils.FusdUnits
	, incrementalPrice : PonsUtils.FusdUnits
	, _ royaltyRatio : PonsUtils.Ratio
	) : [String] {
		// Obtain the minter's Capability to receive Fusd tokens
		var receivePaymentCap = PonsUsage .prepareFusdCapability (account: minter)

		// Obtain an artist certificate of the minter
		var artistCertificate <- PonsUsage .makePonsArtistCertificateDirectly (artist: minter)
		// Mint and list the specified NFT on the active Pons market, producing some listing certificates
		var listingCertificates <-
			PonsNftMarketContract .ponsMarket .mintForSaleFusd (
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
		return nftIds}
	
	pub fun listForSaleFlow (lister : AuthAccount, nftId : String, _ salePrice : PonsUtils.FlowUnits) : Void {
		pre {
			PonsUsage .borrowOwnPonsCollection (collector: lister) .borrowNft (nftId: nftId) != nil:
				"Pons NFT with this nftId does not belong to your Pons Collection" }
		// Obtain the minter's Capability to receive Flow tokens
		var receivePaymentCap = PonsUsage .prepareFlowCapability (account: lister)
		// Withdraw the specified nft from the lister's Pons collection
		var nft <- PonsUsage .borrowOwnPonsCollection (collector: lister) .withdrawNft (nftId: nftId)
		// List the NFT on the active Pons market for a listing certificate
		var listingCertificate <- PonsNftMarketContract .ponsMarket .listForSaleFlow (<- nft, salePrice, receivePaymentCap)
		// Deposit the listing certificate in the lister's listing certificate collection
		PonsUsage .depositListingCertificate (lister, <- listingCertificate)}


	pub fun listForSaleFusd (lister : AuthAccount, nftId : String, _ salePrice : PonsUtils.FusdUnits) : Void {
		pre {
			PonsUsage .borrowOwnPonsCollection (collector: lister) .borrowNft (nftId: nftId) != nil:
				"Pons NFT with this nftId does not belong to your Pons Collection" }
		// Obtain the minter's Capability to receive Flow tokens
		var receivePaymentCap = PonsUsage .prepareFusdCapability (account: lister)
		// Withdraw the specified nft from the lister's Pons collection
		var nft <- PonsUsage .borrowOwnPonsCollection (collector: lister) .withdrawNft (nftId: nftId)
		// List the NFT on the active Pons market for a listing certificate
		var listingCertificate <- PonsNftMarketContract .ponsMarket .listForSaleFusd (<- nft, salePrice, receivePaymentCap)
		// Deposit the listing certificate in the lister's listing certificate collection
		PonsUsage .depositListingCertificate (lister, <- listingCertificate)}


	/* Purchases a NFT from the marketplace, using a specified Flow token vault */
	pub fun purchaseUsingVaultFlow (patron : AuthAccount, nftId : String, _ purchaseVault : @FungibleToken.Vault) : Void {
		pre {
			PonsNftMarketContract .borrowNft (nftId: nftId) != nil:
				"Pons NFT with this nftId is not available on the market" }

		// Obtain information on the NFT to be purchased
		let price = PonsNftMarketContract .getPriceFlow (nftId: nftId) !
		let nftRef = PonsNftMarketContract .borrowNft (nftId: nftId) !
		let serialNumber = PonsNftContract .getSerialNumber (nftRef)
		let editionLabel = PonsNftContract .getEditionLabel (nftRef)

		// Purchase the NFT from the active Pons market, using the provided Flow token vault
		var nft <-
			PonsNftMarketContract .ponsMarket .purchaseFlow (nftId: nftId, <- purchaseVault)

		// Deposit the purchased NFT in the patron's Pons collection
		PonsUsage .borrowOwnPonsCollection (collector: patron)
		.depositNft (<- nft)}


	pub fun purchaseUsingVaultFusd (patron : AuthAccount, nftId : String, _ purchaseVault : @FungibleToken.Vault) : Void {
		pre {
			PonsNftMarketContract .borrowNft (nftId: nftId) != nil:
				"Pons NFT with this nftId is not available on the market" }

		// Obtain information on the NFT to be purchased
		let price = PonsNftMarketContract .getPriceFusd (nftId: nftId) !
		let nftRef = PonsNftMarketContract .borrowNft (nftId: nftId) !
		let serialNumber = PonsNftContract .getSerialNumber (nftRef)
		let editionLabel = PonsNftContract .getEditionLabel (nftRef)

		// Purchase the NFT from the active Pons market, using the provided Flow token vault
		var nft <-
			PonsNftMarketContract .ponsMarket .purchaseFusd (nftId: nftId, <- purchaseVault)

		// Deposit the purchased NFT in the patron's Pons collection
		PonsUsage .borrowOwnPonsCollection (collector: patron)
		.depositNft (<- nft)}


	
	/* Purchases a NFT from the marketplace, using the account's default Flow token vault */
	pub fun purchaseFlow (patron : AuthAccount, nftId : String, priceLimit : PonsUtils.FlowUnits?) : Void {
		pre {
			PonsNftMarketContract .borrowNft (nftId: nftId) != nil:
				"Pons NFT with this nftId is not available on the market" }

		// Obtain the price of the NFT to be purchased
		let nftFlowUnits = PonsNftMarketContract .getPriceFlow (nftId: nftId) !
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
			to: /storage/ponsMarketPurchaseVaultFlow )

		// Withdraw the vault, now marked with its owner
		var purchaseVault <-
			patron .load <@FungibleToken.Vault> (
				from: /storage/ponsMarketPurchaseVaultFlow ) !

		// Purchase the specified NFT using the Flow token vault
		PonsUsage .purchaseUsingVaultFlow (patron: patron, nftId: nftId, <- purchaseVault)}



	/* Purchases a NFT from the marketplace, using the account's default FUSD token vault */
	pub fun purchaseFusd (patron : AuthAccount, nftId : String, priceLimit : PonsUtils.FusdUnits?) : Void {
		pre {
			PonsNftMarketContract .borrowNft (nftId: nftId) != nil:
				"Pons NFT with this nftId is not available on the market" }

		// Obtain the price of the NFT to be purchased
		let nftFlowUnits = PonsNftMarketContract .getPriceFusd (nftId: nftId) !
		let nftPrice = nftFlowUnits .fusdAmount

		// Obtain the price of the NFT to be purchased
		if priceLimit != nil && ! (priceLimit !.isAtLeast (nftFlowUnits)) {
			panic ("The price of the Pons NFT exceeds your price limit") }

		// Obtain the Flow token vault of the patron and withdraw the amount for which the NFT is on sale
		var paymentVault <-
			patron .borrow <&FungibleToken.Vault> (from: /storage/fusdVault) !
				.withdraw (amount: nftPrice)

		// Save the payment vault to the users storage so that its owner will be marked as the patron.
		// This allows the Pons NFT system to detect the new owner of the NFT
		patron .save (
			<- paymentVault,
			to: /storage/ponsMarketPurchaseVaultFusd )

		// Withdraw the vault, now marked with its owner
		var purchaseVault <-
			patron .load <@FungibleToken.Vault> (
				from: /storage/ponsMarketPurchaseVaultFusd ) !

		// Purchase the specified NFT using the Flow token vault
		PonsUsage .purchaseUsingVaultFusd (patron: patron, nftId: nftId, <- purchaseVault)}



	/* Unlists a NFT from marketplace */
	pub fun unlist (lister : AuthAccount, nftId : String) : Void {
		// Find the lister's listing certificate for this nftId
		var listingCertificate <- PonsUsage .withdrawListingCertificate (lister, nftId: nftId)

		// First, unlist the NFT from the market, giving the listing certificate in return for the NFT
		var nft <- PonsNftMarketContract .ponsMarket .unlist (<- listingCertificate)
		
		// Then, deposit the NFT into the lister's Pons collection
		PonsUsage .borrowOwnPonsCollection (collector: lister) .depositNft ( <- nft )}

		
	
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
	, requirement : PonsEscrowContract.EscrowResourceDescription, 
	fulfillment : PonsEscrowContract.EscrowFulfillment
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
				receivePaymentCapFlow: PonsUsage .prepareFlowCapability (account: submitter),
				receivePaymentCapFusd: PonsUsage .prepareFusdCapability (account: submitter),
				receiveNftCap: PonsUsage .preparePonsNftReceiverCapability (collector: submitter) )

		// Withdraw the amount specified by heldResourceDescription
		var heldFlowVault <- 
			submitter .borrow <&FungibleToken.Vault> (from: /storage/flowTokenVault) !
				.withdraw (amount: heldResourceDescription .flowUnits .flowAmount)
		
		// Withdraw the amount specified by heldResourceDescription
		var heldFusdVault <- 
			submitter .borrow <&FungibleToken.Vault> (from: /storage/fusdVault) !
				.withdraw (amount: heldResourceDescription .fusdUnits .fusdAmount)

		// Withdraw the nfts specified by heldResourceDescription
		var heldPonsNfts : @[PonsNftContractInterface.NFT] <- []
		for nftId in heldResourceDescription .getPonsNftIds () {
			heldPonsNfts .append (<- PonsUsage .borrowOwnPonsCollection (collector: submitter) .withdrawNft (nftId: nftId)) }

		// Create EscrowResource based on the withdrawn Flow Vault and Pons NFTs
		var heldResources <-
			PonsEscrowContract .makeEscrowResource (flowVault: <- heldFlowVault, fusdVault: <- heldFusdVault, ponsNfts: <- heldPonsNfts)

		// Submit the obtained EscrowFulfillment and EscrowResource for escrow
		return PonsUsage .submitEscrowUsing (
			submitter: submitter, id: id,
			resources: <- heldResources, requirement: requirement,
			fulfillment: fulfillment ) 
	}
}
	