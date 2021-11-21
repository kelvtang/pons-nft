import FungibleToken from 0xFUNGIBLETOKEN
import FlowToken from 0xFLOWTOKEN
import NonFungibleToken from 0xNONFUNGIBLETOKEN
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



	pub struct NftMintSaleDetails {
		pub let quantity : Int
		pub let basePrice : PonsUtils.FlowUnits
		pub let incrementalPrice : PonsUtils.FlowUnits
		pub let royaltyRatio : PonsUtils.Ratio
		pub let receivePaymentCap : Capability<&{FungibleToken.Receiver}>

		init
		( quantity : Int
		, basePrice : PonsUtils.FlowUnits
		, incrementalPrice : PonsUtils.FlowUnits
		, royaltyRatio : PonsUtils.Ratio
		, receivePaymentCap : Capability<&{FungibleToken.Receiver}>
		) {
			self .quantity = quantity
			self .basePrice = basePrice
			self .incrementalPrice = incrementalPrice
			self .royaltyRatio = royaltyRatio
			self .receivePaymentCap = receivePaymentCap } }




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
		pub fun purchase (nftId : String, _ purchaseVault : @FlowToken.Vault) : @PonsNftContractInterface.NFT {
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
	) : Void {
		var receivePaymentCap = PonsUtils .prepareFlowCapability (account: self .account)

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

		destroy artistCertificate
		PonsNftMarketContract .depositListingCertificates (minter, <- listingCertificates) }

	pub fun listForSale (lister : AuthAccount, nftId : String, _ salePrice : PonsUtils.FlowUnits) : Void {
		var receivePaymentCap = PonsUtils .prepareFlowCapability (account: self .account)
		var nft <- PonsNftContract .borrowOwnPonsCollection (collector: lister) .withdrawNft (nftId: nftId)
		var listingCertificate <- PonsNftMarketContract .ponsMarket .listForSale (<- nft, salePrice, receivePaymentCap)
		PonsNftMarketContract .depositListingCertificate (lister, <- listingCertificate) }

	pub fun purchase (patron : AuthAccount, nftId : String, _ purchaseVault : @FlowToken.Vault) : Void {
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

	pub fun unlist (lister : AuthAccount, nftId : String) : Void {
		var listingCertificate <- PonsNftMarketContract .withdrawListingCertificate (lister, nftId: nftId)

		PonsNftContract .borrowOwnPonsCollection (collector: lister)
		.depositNft (
			<- PonsNftMarketContract .ponsMarket .unlist (<- listingCertificate) ) }




	pub fun depositListingCertificate (_ account : AuthAccount, _ newListingCertificate : @{PonsListingCertificate}) : Void {
		var listingCertificatesOptional <-
			account .load <@[{PonsListingCertificate}]>
				( from: PonsNftMarketContract .PonsListingCertificateStoragePath )
		var listingCertificates <- listingCertificatesOptional ?? []

		listingCertificates .append (<- newListingCertificate)

		account .save (<- listingCertificates, to: PonsNftMarketContract .PonsListingCertificateStoragePath) }

	pub fun depositListingCertificates (_ account : AuthAccount, _ newListingCertificates : @[{PonsListingCertificate}]) : Void {
		var listingCertificatesOptional <- account .load <@[{PonsListingCertificate}]> (from: PonsNftMarketContract .PonsListingCertificateStoragePath)
		var listingCertificates <- listingCertificatesOptional ?? []

		while newListingCertificates .length > 0 {
			listingCertificates .append (<- newListingCertificates .remove (at: 0)) }

		destroy newListingCertificates

		account .save (<- listingCertificates, to: PonsNftMarketContract .PonsListingCertificateStoragePath) }

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
		panic ("") }




	access(account) var historicalPonsMarkets : @[{PonsNftMarket}]
	access(account) var ponsMarket : @{PonsNftMarket}
	access(account) fun setPonsMarket (_ ponsMarket : @{PonsNftMarket}) : Void {
		var newPonsMarket <- ponsMarket
		newPonsMarket <-> PonsNftMarketContract .ponsMarket
		PonsNftMarketContract .historicalPonsMarkets .append (<- newPonsMarket) }





	init (ponsListingCertificateStoragePath : StoragePath) {
		//let ponsListingCertificateStoragePath = /storage/listingCertificates
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
		pub fun purchase (nftId : String, _ purchaseVault : @FlowToken.Vault) : @PonsNftContractInterface.NFT {
			panic ("not implemented") }
		pub fun purchaseBySerialId (nftSerialId : UInt64, _ purchaseVault : @FlowToken.Vault) : @PonsNftContractInterface.NFT {
			panic ("not implemented") }
		pub fun unlist (_ ponsListingCertificate : @{PonsListingCertificate}) : @PonsNftContractInterface.NFT {
			panic ("not implemented") } }

	 }
