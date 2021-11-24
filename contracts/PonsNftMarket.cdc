import FungibleToken from 0xFUNGIBLETOKEN
import NonFungibleToken from 0xNONFUNGIBLETOKEN
import FlowToken from 0xFLOWTOKEN
import PonsArtistContract from 0xPONS
import PonsNftContractInterface from 0xPONS
import PonsNftContract from 0xPONS
import PonsUtils from 0xPONS


pub contract PonsNftMarketContract {
	pub let PonsNftMarketAddress : Address
	pub let PonsListingCertificateStoragePath : StoragePath


	pub event PonsMarketContractInit ()

	pub event PonsNFTListed (nftId : String, serialNumber : UInt64, editionLabel : String, price : PonsUtils.FlowUnits)
	pub event PonsNFTUnlisted (nftId : String, serialNumber : UInt64, editionLabel : String, price : PonsUtils.FlowUnits)
	pub event PonsNFTSold (nftId : String, serialNumber : UInt64, editionLabel : String, price : PonsUtils.FlowUnits)
	pub event PonsNFTOwns (owner : Address, nftId : String, serialNumber : UInt64, editionLabel : String, price : PonsUtils.FlowUnits)


	access(account) fun emitPonsNFTListed (nftId : String, serialNumber : UInt64, editionLabel : String, price : PonsUtils.FlowUnits) : Void {
		emit PonsNFTListed (nftId: nftId, serialNumber: serialNumber, editionLabel: editionLabel, price: price) }
	access(account) fun emitPonsNFTUnlisted (nftId : String, serialNumber : UInt64, editionLabel : String, price : PonsUtils.FlowUnits) : Void {
		emit PonsNFTUnlisted (nftId: nftId, serialNumber: serialNumber, editionLabel: editionLabel, price: price) }
	access(account) fun emitPonsNFTSold (nftId : String, serialNumber : UInt64, editionLabel : String, price : PonsUtils.FlowUnits) : Void {
		emit PonsNFTSold (nftId: nftId, serialNumber: serialNumber, editionLabel: editionLabel, price: price) }



	pub resource interface PonsNftMarket {
		pub fun getForSaleIds () : [String]
		pub fun getPrice (nftId : String) : PonsUtils.FlowUnits?
		pub fun borrowNft (nftId : String) : &PonsNftContractInterface.NFT?

		pub fun mintForSale
		( _ artistCertificate : &PonsArtistContract.PonsArtistCertificate
		, metadata : {String: String}
		, quantity : Int
		, basePrice : PonsUtils.FlowUnits
		, incrementalPrice : PonsUtils.FlowUnits
		, _ royaltyRatio : PonsUtils.Ratio
		, _ receivePaymentCap : Capability<&{FungibleToken.Receiver}>
		) : @[{PonsListingCertificate}] /*{
			post {
				PonsNftMarketContract .certificatesOwnedByMarket ((& result) as &[{PonsListingCertificate}]):
					"" } }*/
		pub fun listForSale (_ nft : @PonsNftContractInterface.NFT, _ salePrice : PonsUtils.FlowUnits, _ receivePaymentCap : Capability<&{FungibleToken.Receiver}>) : @{PonsListingCertificate} {
			post {
				result .listerAddress == before (nft .owner !.address) } }
		pub fun purchase (nftId : String, _ purchaseVault : @FungibleToken.Vault) : @PonsNftContractInterface.NFT {
			pre {
				purchaseVault .isInstance (Type<@FlowToken.Vault> ()) }
			post {
				result .nftId == nftId } }
		pub fun unlist (_ ponsListingCertificate : @{PonsListingCertificate}) : @PonsNftContractInterface.NFT {
			pre {
				ponsListingCertificate .listerAddress == ponsListingCertificate .owner !.address:
					"Some error" } } }
	pub resource interface PonsListingCertificate {
		pub listerAddress : Address
		pub nftId : String }


	pub fun certificatesOwnedByMarket (_ listingCertificates : &[{PonsListingCertificate}]) : Bool {
		let forall =
			fun (list : &[{PonsListingCertificate}], condition : ((&{PonsListingCertificate}) : Bool)) : Bool {
				var index = 0
				while index < list .length {
					if ! condition (& list [index] as &{PonsListingCertificate}) {
						return false }
					index = index + 1 }
				return true }

		return forall (
			listingCertificates,
			fun (_ ponsListingCertificate : &{PonsListingCertificate}) : Bool {
				return ponsListingCertificate .listerAddress == PonsNftMarketContract .PonsNftMarketAddress } ) }




	pub fun getForSaleIds () : [String] {
		return PonsNftMarketContract .ponsMarket .getForSaleIds () }

	pub fun getPrice (nftId : String) : PonsUtils.FlowUnits? {
		return PonsNftMarketContract .ponsMarket .getPrice (nftId: nftId) }
	pub fun borrowNft (nftId : String) : &PonsNftContractInterface.NFT? {
		return PonsNftMarketContract .ponsMarket .borrowNft (nftId: nftId) }


	pub fun borrowPonsMarket () : &{PonsNftMarket} {
		return & self .ponsMarket as &{PonsNftMarket} }




	pub fun mintForSale
	( minter : AuthAccount
	, metadata : {String: String}
	, quantity : Int
	, basePrice : PonsUtils.FlowUnits
	, incrementalPrice : PonsUtils.FlowUnits
	, _ royaltyRatio : PonsUtils.Ratio
	) : [String] {
		var receivePaymentCap = PonsUtils .prepareFlowCapability (account: minter)

		var artistCertificate <- PonsArtistContract .makePonsArtistCertificate (artistAccount: minter)
		var listingCertificates <-
			PonsNftMarketContract .ponsMarket .mintForSale (
				& artistCertificate as &PonsArtistContract.PonsArtistCertificate,
				metadata: metadata,
				quantity: quantity,
				basePrice: basePrice,
				incrementalPrice: incrementalPrice,
				royaltyRatio,
				receivePaymentCap )

		let nftIds : [String] = []
		var nftIndex = 0
		while nftIndex < listingCertificates .length {
			nftIds .append (listingCertificates [nftIndex] .nftId)
			nftIndex = nftIndex + 1 }

		destroy artistCertificate
		PonsNftMarketContract .depositListingCertificates (minter, <- listingCertificates)

		return nftIds }

	pub fun listForSale (lister : AuthAccount, nftId : String, _ salePrice : PonsUtils.FlowUnits) : Void {
		pre {
			PonsNftContract .borrowOwnPonsCollection (collector: lister) .borrowNft (nftId: nftId) != nil:
				"Pons NFT with this nftId does not belong to your Pons Collection" }
		var receivePaymentCap = PonsUtils .prepareFlowCapability (account: lister)
		var nft <- PonsNftContract .borrowOwnPonsCollection (collector: lister) .withdrawNft (nftId: nftId)
		var listingCertificate <- PonsNftMarketContract .ponsMarket .listForSale (<- nft, salePrice, receivePaymentCap)
		PonsNftMarketContract .depositListingCertificate (lister, <- listingCertificate) }

	pub fun purchaseUsingVault (patron : AuthAccount, nftId : String, _ purchaseVault : @FungibleToken.Vault) : Void {
		pre {
			self .borrowNft (nftId: nftId) != nil:
				"Pons NFT with this nftId is not available on the market" }
		let price = PonsNftMarketContract .getPrice (nftId: nftId) !
		let nftRef = PonsNftMarketContract .borrowNft (nftId: nftId) !
		let serialNumber = PonsNftContract .getSerialNumber (nftRef)
		let editionLabel = PonsNftContract .getEditionLabel (nftRef)

		var nft <-
			PonsNftMarketContract .ponsMarket .purchase (nftId: nftId, <- purchaseVault)

		PonsNftContract .borrowOwnPonsCollection (collector: patron)
		.depositNft (<- nft)

		emit PonsNFTOwns (
			owner: patron .address,
			nftId: nftId,
			serialNumber: serialNumber,
			editionLabel: editionLabel,
			price : price ) }

	pub fun purchase (patron : AuthAccount, nftId : String) : Void {
		pre {
			self .borrowNft (nftId: nftId) != nil:
				"Pons NFT with this nftId is not available on the market" }
		var paymentVault <-
			patron .borrow <&FungibleToken.Vault> (from: /storage/flowTokenVault) !
				.withdraw (amount: PonsNftMarketContract .getPrice (nftId: nftId) !.flowAmount)
		PonsNftMarketContract .purchaseUsingVault (patron: patron, nftId: nftId, <- paymentVault) }

	pub fun unlist (lister : AuthAccount, nftId : String) : Void {
		var listingCertificate <- PonsNftMarketContract .withdrawListingCertificate (lister, nftId: nftId)

		PonsNftContract .borrowOwnPonsCollection (collector: lister)
		.depositNft (
			<- PonsNftMarketContract .ponsMarket .unlist (<- listingCertificate) ) }




	pub fun depositListingCertificate (_ account : AuthAccount, _ newListingCertificate : @{PonsListingCertificate}) : Void {
		var listingCertificatesOptional <-
			account .load <@[{PonsListingCertificate}]>
				( from: PonsNftMarketContract .PonsListingCertificateStoragePath )

		if listingCertificatesOptional != nil {
			var listingCertificates <- listingCertificatesOptional !

			listingCertificates .append (<- newListingCertificate)

			account .save (<- listingCertificates, to: PonsNftMarketContract .PonsListingCertificateStoragePath) }
		else {
			destroy listingCertificatesOptional
			
			var listingCertificates : @[{PonsListingCertificate}] <- []

			listingCertificates .append (<- newListingCertificate)

			account .save (<- listingCertificates, to: PonsNftMarketContract .PonsListingCertificateStoragePath) } }

	pub fun depositListingCertificates (_ account : AuthAccount, _ newListingCertificates : @[{PonsListingCertificate}]) : Void {
		var listingCertificatesOptional <- account .load <@[{PonsListingCertificate}]> (from: PonsNftMarketContract .PonsListingCertificateStoragePath)

		if listingCertificatesOptional != nil {
			var listingCertificates <- listingCertificatesOptional !

			while newListingCertificates .length > 0 {
				listingCertificates .append (<- newListingCertificates .remove (at: 0)) }

			destroy newListingCertificates

			account .save (<- listingCertificates, to: PonsNftMarketContract .PonsListingCertificateStoragePath) }
		else {
			destroy listingCertificatesOptional

			var listingCertificates : @[{PonsListingCertificate}] <- []

			while newListingCertificates .length > 0 {
				listingCertificates .append (<- newListingCertificates .remove (at: 0)) }

			destroy newListingCertificates

			account .save (<- listingCertificates, to: PonsNftMarketContract .PonsListingCertificateStoragePath)  } }

	pub fun withdrawListingCertificate (_ account : AuthAccount, nftId : String) : @{PonsListingCertificate} {
		var listingCertificates <- account .load <@[{PonsListingCertificate}]> (from: PonsNftMarketContract .PonsListingCertificateStoragePath) !

		var listingCertificateIndex = 0
		while listingCertificateIndex < listingCertificates .length {
			if listingCertificates [listingCertificateIndex] .nftId == nftId {
				var listingCertificate <- listingCertificates .remove (at: listingCertificateIndex)

				account .save (<- listingCertificates, to: PonsNftMarketContract .PonsListingCertificateStoragePath)

				return <- listingCertificate }

			listingCertificateIndex = listingCertificateIndex + 1 }

		destroy listingCertificates
		panic ("Pons Listing Certificate for this nftId not found") }




	access(account) var historicalPonsMarkets : @[{PonsNftMarket}]
	access(account) var ponsMarket : @{PonsNftMarket}
	access(account) fun setPonsMarket (_ ponsMarket : @{PonsNftMarket}) : Void {
		var newPonsMarket <- ponsMarket
		newPonsMarket <-> PonsNftMarketContract .ponsMarket
		PonsNftMarketContract .historicalPonsMarkets .append (<- newPonsMarket) }





	init (ponsListingCertificateStoragePath : StoragePath) {
		self .historicalPonsMarkets <- []
		self .ponsMarket <- create InvalidPonsNftMarket ()

		self .PonsNftMarketAddress = self .account .address
		self .PonsListingCertificateStoragePath = ponsListingCertificateStoragePath

		emit PonsMarketContractInit () }

	pub resource InvalidPonsNftMarket : PonsNftMarket {
		pub fun getForSaleIds () : [String] {
			panic ("not implemented") }
		pub fun getPrice (nftId : String) : PonsUtils.FlowUnits? {
			panic ("not implemented") }
		pub fun borrowNft (nftId : String) : &PonsNftContractInterface.NFT? {
			panic ("not implemented") }

		pub fun mintForSale 
		( _ artistCertificate : &PonsArtistContract.PonsArtistCertificate
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
