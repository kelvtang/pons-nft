import FungibleToken from 0xFUNGIBLETOKEN
import NonFungibleToken from 0xNONFUNGIBLETOKEN
import FlowToken from 0xFLOWTOKEN
import PonsNftContractInterface from 0xPONS
import PonsNftContract from 0xPONS
import PonsUtils from 0xPONS


/*
	Pons NFT Market Contract

	This smart contract contains the core functionality of the Pons NFT market.
	The contract defines the core mechanisms of minting, listing, purchasing, and unlisting NFTs, and also the Listing Certificate resource that proves a NFT listing.
	This smart contract serves as the API for users of the Pons NFT marketplace, and delegates concrete functionality to another resource which implements contract functionality, so that updates can be made to the marketplace in a controlled manner if necessary.
	When the Pons marketplace mints multiple editions of NFTs, the market price of each succeesive NFT is incremented by an incremental price.
	This is adjustable by the minting Pons artist.
*/
pub contract PonsNftMarketContract {

	/* The storage path for the PonsNftMarket */
	pub let PonsNftMarketAddress : Address
	/* Standardised storage path for PonsListingCertificateCollection */
	pub let PonsListingCertificateCollectionStoragePath : StoragePath


	/* PonsMarketContractInit is emitted on initialisation of this contract */
	pub event PonsMarketContractInit ()

	/* PonsNFTListed is emitted on the listing of Pons NFTs on the marketplace */
	pub event PonsNFTListed (nftId : String, serialNumber : UInt64, editionLabel : String, price : PonsUtils.FlowUnits)

	/* PonsNFTUnlisted is emitted on the unlisting of Pons NFTs from the marketplace */
	pub event PonsNFTUnlisted (nftId : String, serialNumber : UInt64, editionLabel : String, price : PonsUtils.FlowUnits)

	/* PonsNFTSold is emitted when a Pons NFT is sold */
	pub event PonsNFTSold (nftId : String, serialNumber : UInt64, editionLabel : String, price : PonsUtils.FlowUnits)

	/* PonsNFTSold is emitted when a Pons NFT is sold, and the new owner address is known */
	pub event PonsNFTOwns (owner : Address, nftId : String, serialNumber : UInt64, editionLabel : String, price : PonsUtils.FlowUnits)


	/* Allow the PonsNft events to be emitted by all implementations of Pons NFTs from the same account */
	access(account) fun emitPonsNFTListed (nftId : String, serialNumber : UInt64, editionLabel : String, price : PonsUtils.FlowUnits) : Void {
		emit PonsNFTListed (nftId: nftId, serialNumber: serialNumber, editionLabel: editionLabel, price: price) }
	access(account) fun emitPonsNFTUnlisted (nftId : String, serialNumber : UInt64, editionLabel : String, price : PonsUtils.FlowUnits) : Void {
		emit PonsNFTUnlisted (nftId: nftId, serialNumber: serialNumber, editionLabel: editionLabel, price: price) }
	access(account) fun emitPonsNFTSold (nftId : String, serialNumber : UInt64, editionLabel : String, price : PonsUtils.FlowUnits) : Void {
		emit PonsNFTSold (nftId: nftId, serialNumber: serialNumber, editionLabel: editionLabel, price: price) }



/*
	Pons NFT Market Resource Interface

	This resource interface defines the mechanisms and requirements for Pons NFT market implementations.
*/
	pub resource interface PonsNftMarket {
		/* Get the nftIds of all NFTs for sale */
		pub fun getForSaleIds () : [String]

		/* Get the price of an NFT */
		pub fun getPrice (nftId : String) : PonsUtils.FlowUnits?

		/* Borrow an NFT from the marketplace, to browse its details */
		pub fun borrowNft (nftId : String) : &PonsNftContractInterface.NFT?

		/* Given a Pons artist certificate, mint new Pons NFTs on behalf of the artist and list it on the marketplace for sale */
		/* The price of the first edition of the NFT minted is determined by the basePrice */
		/* When only one edition is minted, the incrementalPrice is inconsequential */
		/* When the Pons marketplace mints multiple editions of NFTs, the market price of each succeesive NFT is incremented by the incrementalPrice */
		pub fun mintForSale
		( _ artistCertificate : &PonsNftContract.PonsArtistCertificate
		, metadata : {String: String}
		, quantity : Int
		, basePrice : PonsUtils.FlowUnits
		, incrementalPrice : PonsUtils.FlowUnits
		, _ royaltyRatio : PonsUtils.Ratio
		, _ receivePaymentCap : Capability<&{FungibleToken.Receiver}>
		) : @[{PonsListingCertificate}] {
			pre {
				quantity >= 0:
					"The quantity minted must not be a negative number"
				basePrice .flowAmount >= 0.0:
					"The base price must be a positive amount of Flow units"
				incrementalPrice .flowAmount >= 0.0:
					"The base price must be a positive amount of Flow units"
				royaltyRatio .amount >= 0.0:
					"The royalty ratio must be in the range 0% - 100%"
				royaltyRatio .amount <= 1.0:
					"The royalty ratio must be in the range 0% - 100%" }
			/*
			// For some reason not understood, the certificatesOwnedByMarket function fails to type-check in this post-condition
			post {
				PonsNftMarketContract .certificatesOwnedByMarket (& result as &[{PonsListingCertificate}]):
					"Failed to mint NFTs for sale" } */ }

		/* List a Pons NFT on the marketplace for sale */
		pub fun listForSale (_ nft : @PonsNftContractInterface.NFT, _ salePrice : PonsUtils.FlowUnits, _ receivePaymentCap : Capability<&{FungibleToken.Receiver}>) : @{PonsListingCertificate} {
			post {
				result .listerAddress == before (nft .owner !.address):
					"Failed to list this Pons NFT" } }

		/* Purchase a Pons NFT from the marketplace */
		pub fun purchase (nftId : String, _ purchaseVault : @FungibleToken.Vault) : @PonsNftContractInterface.NFT {
			pre {
				// Given that the purchaseVault is a FlowToken vault, preconditions on FungibleToken and FlowToken ensure that
				// the balance of the vault is positive, and that only amounts between zero and the balance of the vault can be withdrawn from the vault, so that
				// attempts to game the market using unreasonable royalty ratios (e.g. < 0% or > 100%) will result in failed assertions
				purchaseVault .isInstance (Type<@FlowToken.Vault> ()):
					"Pons NFTs must be purchased using Flow tokens"
				self .borrowNft (nftId: nftId) != nil:
					"This Pons NFT is not on the market anymore" }
			post {
				result .nftId == nftId:
					"Failed to purchase the Pons NFT" } }
		/* Unlist a Pons NFT from the marketplace */
		pub fun unlist (_ ponsListingCertificate : @{PonsListingCertificate}) : @PonsNftContractInterface.NFT {
			pre {
				ponsListingCertificate .listerAddress == ponsListingCertificate .owner !.address:
					"Only the lister can redeem his Pons NFT"
				self .borrowNft (nftId: ponsListingCertificate .nftId) != nil:
					"This Pons NFT is not on the market anymore" } } }
/*
	Pons Listing Certificate Resource Interface

	This resource interface defines basic information about listing certificates.
	Pons market implementations may provide additional details regarding the listing.
*/
	pub resource interface PonsListingCertificate {
		pub listerAddress : Address
		pub nftId : String }

/*
	Pons Listing Certificate Collection Resource

	This resource manages a user's listing certificates, and is stored in a standardised location.
*/
	pub resource PonsListingCertificateCollection {
		pub var listingCertificates : @[{PonsListingCertificate}]

		init () {
			self .listingCertificates <- [] }
		destroy () {
			destroy self .listingCertificates } }

	/* Checks whether all the listing certificates provided belong to the market */
//	pub fun certificatesOwnedByMarket (_ listingCertificatesRef : &[{PonsListingCertificate}]) : Bool {
//		var index = 0
//		while index < listingCertificatesRef .length {
//			if listingCertificatesRef [index] .listerAddress != PonsNftMarketContract .PonsNftMarketAddress {
//				return false }
//			index = index + 1 }
//		return true }



	/* API to get the nftIds on the market for sale */
	pub fun getForSaleIds () : [String] {
		return PonsNftMarketContract .ponsMarket .getForSaleIds () }

	/* API to get the price of an NFT on the market */
	pub fun getPrice (nftId : String) : PonsUtils.FlowUnits? {
		return PonsNftMarketContract .ponsMarket .getPrice (nftId: nftId) }

	/* API to borrow an NFT for browsing */
	pub fun borrowNft (nftId : String) : &PonsNftContractInterface.NFT? {
		return PonsNftMarketContract .ponsMarket .borrowNft (nftId: nftId) }


	/* API to borrow the active Pons market instance */
	pub fun borrowPonsMarket () : &{PonsNftMarket} {
		return & self .ponsMarket as &{PonsNftMarket} }




	/* Convenience API for Pons artists to mint new NFTs for sale */
	pub fun mintForSale
	( minter : AuthAccount
	, metadata : {String: String}
	, quantity : Int
	, basePrice : PonsUtils.FlowUnits
	, incrementalPrice : PonsUtils.FlowUnits
	, _ royaltyRatio : PonsUtils.Ratio
	) : [String] {
		// Obtain the minter's Capability to receive Flow tokens
		var receivePaymentCap = PonsUtils .prepareFlowCapability (account: minter)

		// Obtain an artist certificate of the minter
		var artistCertificate <- PonsNftContract .makePonsArtistCertificateDirectly (artist: minter)
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
		PonsNftMarketContract .depositListingCertificates (minter, <- listingCertificates)

		// Return list of minted nftIds
		return nftIds }

	/* Convenience API to list owned NFTs on the marketplace for sale */
	pub fun listForSale (lister : AuthAccount, nftId : String, _ salePrice : PonsUtils.FlowUnits) : Void {
		pre {
			PonsNftContract .borrowOwnPonsCollection (collector: lister) .borrowNft (nftId: nftId) != nil:
				"Pons NFT with this nftId does not belong to your Pons Collection" }
		// Obtain the minter's Capability to receive Flow tokens
		var receivePaymentCap = PonsUtils .prepareFlowCapability (account: lister)
		// Withdraw the specified nft from the lister's Pons collection
		var nft <- PonsNftContract .borrowOwnPonsCollection (collector: lister) .withdrawNft (nftId: nftId)
		// List the NFT on the active Pons market for a listing certificate
		var listingCertificate <- PonsNftMarketContract .ponsMarket .listForSale (<- nft, salePrice, receivePaymentCap)
		// Deposit the listing certificate in the lister's listing certificate collection
		PonsNftMarketContract .depositListingCertificate (lister, <- listingCertificate) }

	/* Convenience API to purchase on the marketplace for sale, using a specified Flow token vault */
	pub fun purchaseUsingVault (patron : AuthAccount, nftId : String, _ purchaseVault : @FungibleToken.Vault) : Void {
		pre {
			self .borrowNft (nftId: nftId) != nil:
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
		PonsNftContract .borrowOwnPonsCollection (collector: patron)
		.depositNft (<- nft)

		// Emit the Pons NFT ownership event
		emit PonsNFTOwns (
			owner: patron .address,
			nftId: nftId,
			serialNumber: serialNumber,
			editionLabel: editionLabel,
			price : price ) }

	/* Convenience API to purchase on the marketplace for sale, using the account's default Flow token vault */
	pub fun purchase (patron : AuthAccount, nftId : String) : Void {
		pre {
			self .borrowNft (nftId: nftId) != nil:
				"Pons NFT with this nftId is not available on the market" }
		// Obtain the Flow token vault of the patron
		var paymentVault <-
			patron .borrow <&FungibleToken.Vault> (from: /storage/flowTokenVault) !
				.withdraw (amount: PonsNftMarketContract .getPrice (nftId: nftId) !.flowAmount)
		// Purchase the specified NFT using the Flow token vault
		PonsNftMarketContract .purchaseUsingVault (patron: patron, nftId: nftId, <- paymentVault) }

	/* Convenience API to unlist a NFT from marketplace */
	pub fun unlist (lister : AuthAccount, nftId : String) : Void {
		// Find the lister's listing certificate for this nftId
		var listingCertificate <- PonsNftMarketContract .withdrawListingCertificate (lister, nftId: nftId)

		// First, unlist the NFT from the market, giving the listing certificate in return for the NFT
		// Then, deposit the NFT into the lister's Pons collection
		PonsNftContract .borrowOwnPonsCollection (collector: lister)
		.depositNft (
			<- PonsNftMarketContract .ponsMarket .unlist (<- listingCertificate) ) }




	/* Convenience API to deposit a listing certificate into the account's default listing certificate collection */
	pub fun depositListingCertificate (_ account : AuthAccount, _ newListingCertificate : @{PonsListingCertificate}) : Void {
		// Load the existing listing certificate collection of the account, if any
		var listingCertificateCollectionOptional <-
			account .load <@PonsListingCertificateCollection>
				( from: PonsNftMarketContract .PonsListingCertificateCollectionStoragePath )

		if listingCertificateCollectionOptional != nil {
			// If the account already has a listing certificate collection
			// Add the new certificate and save the collection
			var listingCertificateCollection <- listingCertificateCollectionOptional !

			listingCertificateCollection .listingCertificates .append (<- newListingCertificate)

			account .save (<- listingCertificateCollection, to: PonsNftMarketContract .PonsListingCertificateCollectionStoragePath) }
		else {
			// If the account does not have a listing certificate collection
			// Create a new listing certificate collection, add the new certificate and save the collection
			// Destroy the nil to make the resource checker happy
			destroy listingCertificateCollectionOptional
			
			var listingCertificateCollection <- create PonsListingCertificateCollection ()

			listingCertificateCollection .listingCertificates .append (<- newListingCertificate)

			account .save (<- listingCertificateCollection, to: PonsNftMarketContract .PonsListingCertificateCollectionStoragePath) } }

	/* Convenience API to deposit listing certificates into the account's default listing certificate collection */
	pub fun depositListingCertificates (_ account : AuthAccount, _ newListingCertificates : @[{PonsListingCertificate}]) : Void {
		// Load the existing listing certificate collection of the account, if any
		var listingCertificateCollectionOptional <-
			account .load <@PonsListingCertificateCollection>
				( from: PonsNftMarketContract .PonsListingCertificateCollectionStoragePath )

		if listingCertificateCollectionOptional != nil {
			// If the account already has a listing certificate collection
			// Retrieve each new listing certificate and add it to the collection, then save the collection
			var listingCertificateCollection <- listingCertificateCollectionOptional !

			while newListingCertificates .length > 0 {
				listingCertificateCollection .listingCertificates .append (<- newListingCertificates .remove (at: 0)) }

			destroy newListingCertificates

			account .save (<- listingCertificateCollection, to: PonsNftMarketContract .PonsListingCertificateCollectionStoragePath) }
		else {
			// If the account already has a listing certificate collection
			// Create a new listing certificate collection, retrieve each new listing certificate and add it to the collection, then save the collection
			// Destroy the nil to make the resource checker happy
			destroy listingCertificateCollectionOptional

			var listingCertificateCollection <- create PonsListingCertificateCollection ()

			while newListingCertificates .length > 0 {
				listingCertificateCollection .listingCertificates .append (<- newListingCertificates .remove (at: 0)) }

			destroy newListingCertificates

			account .save (<- listingCertificateCollection, to: PonsNftMarketContract .PonsListingCertificateCollectionStoragePath) } }

	/* Convenience API to withdraw listing certificates from the account's default listing certificate collection */
	pub fun withdrawListingCertificate (_ account : AuthAccount, nftId : String) : @{PonsListingCertificate} {
		// Load the existing listing certificate collection of the account, which must already exist
		var listingCertificateCollectionRef = account .borrow <&PonsListingCertificateCollection> (from: PonsNftMarketContract .PonsListingCertificateCollectionStoragePath) !

		// We iterate through all listing certificate in the collection, from the end of the collection
		// Given that we only deposit listing certificates using append, as in the convenience API deposit functions
		// If multiple listing certificates are present with the same nftId, the last one will be the latest certificate and the previous ones will be invalid
		var listingCertificateIndex = listingCertificateCollectionRef .listingCertificates .length - 1
		while listingCertificateIndex >= 0 {
			// If the NFT has the specified nftId
			if listingCertificateCollectionRef .listingCertificates [listingCertificateIndex] .nftId == nftId {
				// If so, retrieve the NFT and return it
				return <- listingCertificateCollectionRef .listingCertificates .remove (at: listingCertificateIndex) }

			listingCertificateIndex = listingCertificateIndex - 1 }
		panic ("Pons Listing Certificate for this nftId not found") }




	/* A list recording all previously active instances of PonsNftMarket */
	access(account) var historicalPonsMarkets : @[{PonsNftMarket}]
	/* The currently active instance of PonsNftMarket */
	access(account) var ponsMarket : @{PonsNftMarket}

	/* Updates the currently active PonsNftMarket */
	access(account) fun setPonsMarket (_ ponsMarket : @{PonsNftMarket}) : Void {
		var newPonsMarket <- ponsMarket
		newPonsMarket <-> PonsNftMarketContract .ponsMarket
		PonsNftMarketContract .historicalPonsMarkets .append (<- newPonsMarket) }





	init () {
		self .historicalPonsMarkets <- []
		// Activate InvalidPonsNftMarket as the active implementation of the Pons NFT market
		self .ponsMarket <- create InvalidPonsNftMarket ()

		// Save the market address
		self .PonsNftMarketAddress = self .account .address
		// Save the standardised Pons listing certificate collection storage path
		self .PonsListingCertificateCollectionStoragePath = /storage/listingCertificateCollection

		// Emit the PonsNftMarket initialisation event
		emit PonsMarketContractInit () }

	/* An trivial instance of PonsNftMarket which panics on all calls, used on initialization of the PonsNftMarket contract. */
	pub resource InvalidPonsNftMarket : PonsNftMarket {
		pub fun getForSaleIds () : [String] {
			panic ("not implemented") }
		pub fun getPrice (nftId : String) : PonsUtils.FlowUnits? {
			panic ("not implemented") }
		pub fun borrowNft (nftId : String) : &PonsNftContractInterface.NFT? {
			panic ("not implemented") }

		pub fun mintForSale 
		( _ artistCertificate : &PonsNftContract.PonsArtistCertificate
		, metadata : {String: String}
		, quantity : Int
		, basePrice : PonsUtils.FlowUnits
		, incrementalPrice : PonsUtils.FlowUnits
		, _ royaltyRatio : PonsUtils.Ratio
		, _ receivePaymentCap : Capability<&{FungibleToken.Receiver}>
		) : @[{PonsListingCertificate}] {
			panic ("not implemented") }
		pub fun listForSale (_ nft : @PonsNftContractInterface.NFT, _ salePrice : PonsUtils.FlowUnits, _ receivePaymentCap : Capability<&{FungibleToken.Receiver}>) : @{PonsListingCertificate} {
			panic ("not implemented") }
		pub fun purchase (nftId : String, _ purchaseVault : @FungibleToken.Vault) : @PonsNftContractInterface.NFT {
			panic ("not implemented") }
		pub fun purchaseBySerialId (nftSerialId : UInt64, _ purchaseVault : @FungibleToken.Vault) : @PonsNftContractInterface.NFT {
			panic ("not implemented") }
		pub fun unlist (_ ponsListingCertificate : @{PonsListingCertificate}) : @PonsNftContractInterface.NFT {
			panic ("not implemented") } }

	 }
