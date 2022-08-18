import FungibleToken from 0xFUNGIBLETOKEN
import NonFungibleToken from 0xNONFUNGIBLETOKEN
import FlowToken from 0xFLOWTOKEN
import FUSD from 0xFUSD
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
	//pub let PonsListingCertificateCollectionStoragePath : StoragePath


	/* PonsMarketContractInit is emitted on initialisation of this contract */
	pub event PonsMarketContractInit ()

	/* PonsNFTListed is emitted on the listing of Pons NFTs on the marketplace */
	pub event PonsNFTListedFlow (nftId : String, serialNumber : UInt64, editionLabel : String, price : PonsUtils.FlowUnits)

	/* PonsNFTUnlisted is emitted on the unlisting of Pons NFTs from the marketplace */
	pub event PonsNFTUnlistedFlow (nftId : String, serialNumber : UInt64, editionLabel : String, price : PonsUtils.FlowUnits)

	/* PonsNFTSold is emitted when a Pons NFT is sold */
	pub event PonsNFTSoldFlow (nftId : String, serialNumber : UInt64, editionLabel : String, price : PonsUtils.FlowUnits)

	/* PonsNFTSold is emitted when a Pons NFT is sold, and the new owner address is known */
	pub event PonsNFTOwnsFlow (owner : Address, nftId : String, serialNumber : UInt64, editionLabel : String, price : PonsUtils.FlowUnits)


	/* Allow the PonsNft events to be emitted by all implementations of Pons NFTs from the same account */
	access(account) fun emitPonsNFTListedFlow (nftId : String, serialNumber : UInt64, editionLabel : String, price : PonsUtils.FlowUnits) : Void {
		emit PonsNFTListedFlow (nftId: nftId, serialNumber: serialNumber, editionLabel: editionLabel, price: price) }
	access(account) fun emitPonsNFTUnlistedFlow (nftId : String, serialNumber : UInt64, editionLabel : String, price : PonsUtils.FlowUnits) : Void {
		emit PonsNFTUnlistedFlow (nftId: nftId, serialNumber: serialNumber, editionLabel: editionLabel, price: price) }
	access(account) fun emitPonsNFTSoldFlow (nftId : String, serialNumber : UInt64, editionLabel : String, price : PonsUtils.FlowUnits) : Void {
		emit PonsNFTSoldFlow (nftId: nftId, serialNumber: serialNumber, editionLabel: editionLabel, price: price) }
	access(account) fun emitPonsNFTOwnsFlow (owner : Address, nftId : String, serialNumber : UInt64, editionLabel : String, price : PonsUtils.FlowUnits) : Void {
		emit PonsNFTOwnsFlow (owner: owner, nftId: nftId, serialNumber: serialNumber, editionLabel: editionLabel, price: price) }

	/* PonsNFTListed is emitted on the listing of Pons NFTs on the marketplace */
	pub event PonsNFTListedFusd (nftId : String, serialNumber : UInt64, editionLabel : String, price : PonsUtils.FusdUnits)

	/* PonsNFTUnlisted is emitted on the unlisting of Pons NFTs from the marketplace */
	pub event PonsNFTUnlistedFusd (nftId : String, serialNumber : UInt64, editionLabel : String, price : PonsUtils.FusdUnits)

	/* PonsNFTSold is emitted when a Pons NFT is sold */
	pub event PonsNFTSoldFusd (nftId : String, serialNumber : UInt64, editionLabel : String, price : PonsUtils.FusdUnits)

	/* PonsNFTSold is emitted when a Pons NFT is sold, and the new owner address is known */
	pub event PonsNFTOwnsFusd (owner : Address, nftId : String, serialNumber : UInt64, editionLabel : String, price : PonsUtils.FusdUnits)


	/* Allow the PonsNft events to be emitted by all implementations of Pons NFTs from the same account */
	access(account) fun emitPonsNFTListedFusd (nftId : String, serialNumber : UInt64, editionLabel : String, price : PonsUtils.FusdUnits) : Void {
		emit PonsNFTListedFusd (nftId: nftId, serialNumber: serialNumber, editionLabel: editionLabel, price: price) }
	access(account) fun emitPonsNFTUnlistedFusd (nftId : String, serialNumber : UInt64, editionLabel : String, price : PonsUtils.FusdUnits) : Void {
		emit PonsNFTUnlistedFusd (nftId: nftId, serialNumber: serialNumber, editionLabel: editionLabel, price: price) }
	access(account) fun emitPonsNFTSoldFusd (nftId : String, serialNumber : UInt64, editionLabel : String, price : PonsUtils.FusdUnits) : Void {
		emit PonsNFTSoldFusd (nftId: nftId, serialNumber: serialNumber, editionLabel: editionLabel, price: price) }
	access(account) fun emitPonsNFTOwnsFusd (owner : Address, nftId : String, serialNumber : UInt64, editionLabel : String, price : PonsUtils.FusdUnits) : Void {
		emit PonsNFTOwnsFusd (owner: owner, nftId: nftId, serialNumber: serialNumber, editionLabel: editionLabel, price: price) }



/*
	Pons NFT Market Resource Interface

	This resource interface defines the mechanisms and requirements for Pons NFT market implementations.
*/
	pub resource interface PonsNftMarket {

		
		access(account) fun mapPolygonListedNft(nftSerialId: UInt64, polygonAddress: String): String?
		access(account) fun removePolygonListedNft(nftSerialId: UInt64): String?
		access(account) fun mapPolygonListerPaymentCapability(polygonAddress: String, flowTokenCapabilty: Capability<&{FungibleToken.Receiver}>, fusdTokenCapability: Capability<&{FungibleToken.Receiver}>):[Capability<&{FungibleToken.Receiver}>; 2]?
		access(account) fun getPolygonListerPaymentCapability(polygonAddress: String): [Capability<&{FungibleToken.Receiver}>; 2]?

		/* Get the nftIds of all NFTs for sale */
		pub fun getForSaleIds () : [String]

		/* Get the Flow price of an NFT */
		pub fun getPriceFlow (nftId : String) : PonsUtils.FlowUnits?
		/* Get the FUSD price of an NFT */
		pub fun getPriceFusd (nftId : String) : PonsUtils.FusdUnits?

		/* Borrow an NFT from the marketplace, to browse its details */
		pub fun borrowNft (nftId : String) : &PonsNftContractInterface.NFT?

		/* Given a Pons artist certificate, mint new Pons NFTs on behalf of the artist and list it on the marketplace for sale */
		/* The price of the first edition of the NFT minted is determined by the basePrice */
		/* When only one edition is minted, the incrementalPrice is inconsequential */
		/* When the Pons marketplace mints multiple editions of NFTs, the market price of each successive NFT is incremented by the incrementalPrice */
		pub fun mintForSaleFlow
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

		/* The same as previous function but handles fusd minting */
		/* The logic behind this is that the minting function doesn't handle nil for its prices. 
			This leaves us without the option of expanding parameters.
			So the only real way to enable fusd is to create a separate minting function. */
		pub fun mintForSaleFusd
		( _ artistCertificate : &PonsNftContract.PonsArtistCertificate
		, metadata : {String: String}
		, quantity : Int
		, basePrice : PonsUtils.FusdUnits
		, incrementalPrice : PonsUtils.FusdUnits
		, _ royaltyRatio : PonsUtils.Ratio
		, _ receivePaymentCap : Capability<&{FungibleToken.Receiver}>
		) : @[{PonsListingCertificate}] {
			pre {
				quantity >= 0:
					"The quantity minted must not be a negative number"
				basePrice .fusdAmount >= 0.0:
					"The base price must be a positive amount of Fusd units"
				incrementalPrice .fusdAmount >= 0.0:
					"The base price must be a positive amount of Fusd units"
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
		pub fun listForSaleFlow (_ nft : @PonsNftContractInterface.NFT, _ salePrice : PonsUtils.FlowUnits, _ receivePaymentCap : Capability<&{FungibleToken.Receiver}>) : @{PonsListingCertificate} /*{
			// WORKAROUND -- ignore
			// Flow implementation seems to be inconsistent regarding owners of nested resources
			// https://github.com/onflow/cadence/issues/1320
			post {
				result .listerAddress == before (nft .owner !.address):
					"Failed to list this Pons NFT" } }*/
		
		/* List a Pons NFT on the marketplace for sale */
		pub fun listForSaleFusd (_ nft : @PonsNftContractInterface.NFT, _ salePrice : PonsUtils.FusdUnits, _ receivePaymentCap : Capability<&{FungibleToken.Receiver}>) : @{PonsListingCertificate} /*{
			// WORKAROUND -- ignore
			// Flow implementation seems to be inconsistent regarding owners of nested resources
			// https://github.com/onflow/cadence/issues/1320
			post {
				result .listerAddress == before (nft .owner !.address):
					"Failed to list this Pons NFT" } }*/

		/* Purchase a Pons NFT from the marketplace using Flow */
		pub fun purchaseFlow (nftId : String, _ purchaseVault : @FungibleToken.Vault) : @PonsNftContractInterface.NFT {
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

		/* Purchase a Pons NFT from the marketplace using FUSD */
		pub fun purchaseFusd (nftId : String, _ purchaseVault : @FungibleToken.Vault) : @PonsNftContractInterface.NFT {
			pre {
				// Given that the purchaseVault is a FlowToken vault, preconditions on FungibleToken and FlowToken ensure that
				// the balance of the vault is positive, and that only amounts between zero and the balance of the vault can be withdrawn from the vault, so that
				// attempts to game the market using unreasonable royalty ratios (e.g. < 0% or > 100%) will result in failed assertions
				purchaseVault .isInstance (Type<@FUSD.Vault> ()):
					"Pons NFTs must be purchased using Flow tokens"
				self .borrowNft (nftId: nftId) != nil:
					"This Pons NFT is not on the market anymore" }
			post {
				result .nftId == nftId:
					"Failed to purchase the Pons NFT" } }
		
		/* Unlist a Pons NFT from the marketplace */
		/*
			This function aims at only removing the parameters of listed nft.
			Since NFT is due to be withdrawn and held without a listing certificate, we cannot 
				implement the procedures necessary for the verifcation and destruction of listingCertificate.
		*/
		access(account) fun unlist_onlyParameters (nftId: String) : @PonsNftContractInterface.NFT{
			pre {
				// WORKAROUND -- ignore
				/*
				// Flow implementation seems to be inconsistent regarding owners of nested resources
				// https://github.com/onflow/cadence/issues/1320
				// For the moment, allow all listing certificate holders redeem...
				ponsListingCertificate .listerAddress == ponsListingCertificate .owner !.address:
					"Only the lister can redeem his Pons NFT"
				*/
				self .borrowNft (nftId: nftId) != nil:
					"This Pons NFT is not on the market anymore" 
				}	 
		} 
		
		/* Unlist a Pons NFT from the marketplace */
		pub fun unlist (_ ponsListingCertificate : @{PonsListingCertificate}) : @PonsNftContractInterface.NFT {
			pre {
				// WORKAROUND -- ignore
				/*
				// Flow implementation seems to be inconsistent regarding owners of nested resources
				// https://github.com/onflow/cadence/issues/1320
				// For the moment, allow all listing certificate holders redeem...
				ponsListingCertificate .listerAddress == ponsListingCertificate .owner !.address:
					"Only the lister can redeem his Pons NFT"
				*/
				self .borrowNft (nftId: ponsListingCertificate .nftId) != nil:
					"This Pons NFT is not on the market anymore" 
				}
			
			 
		} 
	}
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
			destroy self .listingCertificates }

		/* API to add listing certificates to a listing certificate collection */
		pub fun appendListingCertificate (_ listingCertificate : @{PonsListingCertificate}) : Void {
			self .listingCertificates .append (<- listingCertificate) }

		/* API to remove listing certificates from a listing certificate collection */
		pub fun removeListingCertificate (at index : Int) : @{PonsListingCertificate} {
			return <- self .listingCertificates .remove (at: index) } }

	pub fun createPonsListingCertificateCollection () : @PonsListingCertificateCollection {
		return <- create PonsListingCertificateCollection () }

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

	/* API to get the Flow price of an NFT on the market */
	pub fun getPriceFlow (nftId : String) : PonsUtils.FlowUnits? {
		return PonsNftMarketContract .ponsMarket .getPriceFlow (nftId: nftId) }

	/* API to get the Fusd price of an NFT on the market */
	pub fun getPriceFusd (nftId : String) : PonsUtils.FusdUnits? {
		return PonsNftMarketContract .ponsMarket .getPriceFusd (nftId: nftId) }

	/* API to borrow an NFT for browsing */
	pub fun borrowNft (nftId : String) : &PonsNftContractInterface.NFT? {
		return PonsNftMarketContract .ponsMarket .borrowNft (nftId: nftId) }


	/* API to borrow the active Pons market instance */
	pub fun borrowPonsMarket () : &{PonsNftMarket} {
		return & self .ponsMarket as &{PonsNftMarket} }




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
		
		/* Removed as listing certificate collections are now stored in unique locations
		// Save the standardised Pons listing certificate collection storage path
		self .PonsListingCertificateCollectionStoragePath = /storage/listingCertificateCollection */

		// Emit the PonsNftMarket initialisation event
		emit PonsMarketContractInit () }

	/* An trivial instance of PonsNftMarket which panics on all calls, used on initialization of the PonsNftMarket contract. */
	pub resource InvalidPonsNftMarket : PonsNftMarket {
		pub fun getForSaleIds () : [String] {
			panic ("not implemented") }
		pub fun getPriceFlow (nftId : String) : PonsUtils.FlowUnits? {
			panic ("not implemented") }
		pub fun getPriceFusd (nftId : String) : PonsUtils.FusdUnits? {
			panic ("not implemented") }
		pub fun borrowNft (nftId : String) : &PonsNftContractInterface.NFT? {
			panic ("not implemented") }

		pub fun mintForSaleFlow
		( _ artistCertificate : &PonsNftContract.PonsArtistCertificate
		, metadata : {String: String}
		, quantity : Int
		, basePrice : PonsUtils.FlowUnits
		, incrementalPrice : PonsUtils.FlowUnits
		, _ royaltyRatio : PonsUtils.Ratio
		, _ receivePaymentCap : Capability<&{FungibleToken.Receiver}>
		) : @[{PonsListingCertificate}] {
			panic ("not implemented") }
		pub fun mintForSaleFusd
		( _ artistCertificate : &PonsNftContract.PonsArtistCertificate
		, metadata : {String: String}
		, quantity : Int
		, basePrice : PonsUtils.FusdUnits
		, incrementalPrice : PonsUtils.FusdUnits
		, _ royaltyRatio : PonsUtils.Ratio
		, _ receivePaymentCap : Capability<&{FungibleToken.Receiver}>
		) : @[{PonsListingCertificate}] {
			panic ("not implemented") }
		pub fun listForSaleFlow (_ nft : @PonsNftContractInterface.NFT, _ salePrice : PonsUtils.FlowUnits, _ receivePaymentCap : Capability<&{FungibleToken.Receiver}>) : @{PonsListingCertificate} {
			panic ("not implemented") }
		pub fun listForSaleFusd (_ nft : @PonsNftContractInterface.NFT, _ salePrice : PonsUtils.FusdUnits, _ receivePaymentCap : Capability<&{FungibleToken.Receiver}>) : @{PonsListingCertificate} {
			panic ("not implemented") }
		pub fun purchaseFlow (nftId : String, _ purchaseVault : @FungibleToken.Vault) : @PonsNftContractInterface.NFT {
			panic ("not implemented") }
		pub fun purchaseFusd (nftId : String, _ purchaseVault : @FungibleToken.Vault) : @PonsNftContractInterface.NFT {
			panic ("not implemented") }
		pub fun purchaseBySerialId (nftSerialId : UInt64, _ purchaseVault : @FungibleToken.Vault) : @PonsNftContractInterface.NFT {
			panic ("not implemented") }
		access(account) fun unlist_onlyParameters (nftId: String) : @PonsNftContractInterface.NFT{
			panic ("not implemented") }
		pub fun unlist (_ ponsListingCertificate : @{PonsListingCertificate}) : @PonsNftContractInterface.NFT {
			panic ("not implemented") } }

	 }
