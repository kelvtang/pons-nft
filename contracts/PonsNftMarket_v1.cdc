import FungibleToken from 0xFUNGIBLETOKEN
import FlowToken from 0xFLOWTOKEN
import NonFungibleToken from 0xNONFUNGIBLETOKEN
import PonsArtistContract from 0xPONS
import PonsNftContractInterface from 0xPONS
import PonsNftContract from 0xPONS
import PonsNftContract_v1 from 0xPONS
import PonsNftMarketContract from 0xPONS
import PonsUtils from 0xPONS


pub contract PonsNftMarketContract_v1 {

	pub event PonsNftMarketContractInit_v1 ()

	pub resource PonsNftMarket_v1 : PonsNftMarketContract.PonsNftMarket {
		access(account) let collection : @PonsNftContract_v1.Collection

		access(account) var marketReceivePaymentCap : Capability<&{FungibleToken.Receiver}>

		access(account) var salePrices : {String: PonsUtils.FlowUnits}
		access(account) var saleReceivePaymentCaps : {String: Capability<&{FungibleToken.Receiver}>}
		// 0 means primary listing
		// 1 or above means secondary listing
		access(account) var listingCounts : {String: Int}

		access(account) var primaryCommissionRatio : PonsUtils.Ratio
		access(account) var secondaryCommissionRatio : PonsUtils.Ratio



		pub fun getForSaleIds () : [String] {
			return self .salePrices .keys }
		pub fun getPrice (nftId : String) : PonsUtils.FlowUnits? {
			return self .salePrices [nftId] }
		pub fun borrowNft (nftId : String) : &PonsNftContractInterface.NFT? {
			return self .collection .borrowNft (nftId: nftId) }


		pub fun mintForSale
		( _ artistCertificate : &PonsArtistContract.PonsArtistCertificate
		, metadata : {String: String}
		, quantity : Int
		, basePrice : PonsUtils.FlowUnits
		, incrementalPrice : PonsUtils.FlowUnits
		, _ royaltyRatio : PonsUtils.Ratio
		, _ receivePaymentCap : Capability<&{FungibleToken.Receiver}>
		) : @[{PonsNftMarketContract.PonsListingCertificate}] {
			var mintListingCertificates : @[PonsListingCertificate_v1] <- []

			var mintIndex = 0
			var salePrice = basePrice
			while mintIndex < quantity {
				let editionLabel =
					quantity == 1
					? "One of a kind"
					: "Edition " .concat ((mintIndex + 1) .toString ())

				var nft : @PonsNftContractInterface.NFT <-
					PonsNftContract_v1 .MinterCapability
					.borrow () !.mintNft (
						artistCertificate,
						royalty: royaltyRatio,
						editionLabel: editionLabel,
						metadata: metadata )

				let nftId = nft .nftId
				let nftRef = & nft as &PonsNftContractInterface.NFT
				let serialNumber = PonsNftContract .getSerialNumber (nftRef)

				self .collection .depositNft (<- nft)
				self .salePrices .insert (key: nftId, salePrice)
				self .saleReceivePaymentCaps .insert (key: nftId, receivePaymentCap)
				self .listingCounts .insert (key: nftId, 0)


				PonsNftMarketContract .emitPonsNFTListed (
					nftId: nftId,
					serialNumber: serialNumber,
					editionLabel: editionLabel,
					price: salePrice )


				mintListingCertificates .append (
					<- create PonsListingCertificate_v1 (
						listerAddress: PonsNftMarketContract .PonsNftMarketAddress,
						nftId: nftId,
						listingCount: 0 ) )

				mintIndex = mintIndex + 1
				salePrice = PonsUtils .sumFlowUnits (salePrice, incrementalPrice) }

			return <- mintListingCertificates }
		pub fun listForSale (_ nft : @PonsNftContractInterface.NFT, _ salePrice : PonsUtils.FlowUnits, _ receivePaymentCap : Capability<&{FungibleToken.Receiver}>) : @{PonsNftMarketContract.PonsListingCertificate} {
			let ownerAddress = nft .owner !.address

			let nftId = nft .nftId
			let nftRef = & nft as &PonsNftContractInterface.NFT
			let serialNumber = PonsNftContract .getSerialNumber (nftRef)
			let editionLabel = PonsNftContract .getEditionLabel (nftRef)
			let listingCount = (self .listingCounts [nftId] ?? 0) + 1

			self .collection .depositNft (<- nft)
			self .salePrices .insert (key: nftId, salePrice)
			self .saleReceivePaymentCaps .insert (key: nftId, receivePaymentCap)
			self .listingCounts .insert (
				key: nftId,
				listingCount )

			var ponsListingCertificate
				<- create PonsListingCertificate_v1 (
					listerAddress: ownerAddress,
					nftId: nftId,
					listingCount: listingCount )

			PonsNftMarketContract .emitPonsNFTListed (
				nftId: nftId,
				serialNumber: serialNumber,
				editionLabel: editionLabel,
				price: salePrice )

			return <- ponsListingCertificate }
		pub fun purchase (nftId: String, _ purchaseVault : @FlowToken.Vault) : @PonsNftContractInterface.NFT {
			if ! self .salePrices .containsKey (nftId) {
				panic ("Pons NFT with ID " .concat (nftId) .concat (" not on the market")) }

			let purchasePrice = self .salePrices .remove (key: nftId) !
			if ! PonsUtils .FlowUnits (purchaseVault .balance) .isAtLeast (purchasePrice) {
				panic ("Pons NFT with ID " .concat (nftId) .concat (" is on sale for ") .concat (purchasePrice .toString ()) .concat (", insufficient funds provided")) }


			var nft <- self .collection .withdrawNft (nftId: nftId)
			let nftRef = & nft as &PonsNftContractInterface.NFT

			let primarySale = (self .listingCounts [nftId] == 0)
			let royalties =
				primarySale
				? (nil as! PonsUtils.FlowUnits?)
				: purchasePrice .scale (ratio: PonsNftContract .getRoyalty (nftRef))
			let commissionPrice =
				primarySale
				? purchasePrice .scale (ratio: self .primaryCommissionRatio)
				: purchasePrice .scale (ratio: self .secondaryCommissionRatio)

			if royalties != nil {
				let artistReceivePaymentCap = PonsArtistContract .getReceivePaymentCap (PonsNftContract .borrowArtist (nftRef))
				artistReceivePaymentCap .borrow () !.deposit (from: <- purchaseVault .withdraw (amount: royalties !.flowAmount)) }
			self .marketReceivePaymentCap .borrow () !.deposit (from: <- purchaseVault .withdraw (amount: commissionPrice .flowAmount))

			let sellerReceivePaymentCap = self .saleReceivePaymentCaps [nftId] !
			sellerReceivePaymentCap .borrow () !.deposit (from: <- purchaseVault)

			// Seller gets excess

			PonsNftMarketContract .emitPonsNFTSold (
				nftId: nftId,
				serialNumber: PonsNftContract .getSerialNumber (nftRef),
				editionLabel: PonsNftContract .getEditionLabel (nftRef),
				price: purchasePrice )

			return <- nft }

		pub fun unlist (_ ponsListingCertificate : @{PonsNftMarketContract.PonsListingCertificate}) : @PonsNftContractInterface.NFT {
			var ponsListingCertificate_v1 <-
				ponsListingCertificate as! @PonsListingCertificate_v1

			let nftId = ponsListingCertificate_v1 .nftId
			destroy ponsListingCertificate_v1

			let salePrice = self .salePrices .remove (key: nftId) !
			if self .listingCounts [nftId] == 0 {
				panic
					( "Pons NFT with ID " .concat (nftId) .concat (" had just been freshly minted on Pons market, and cannot be unlisted. ")
					.concat ("Pons NFTs can be unlisted if a buyer of the Pons NFT lists the NFT again.") ) }

			var nft <- self .collection .withdrawNft (nftId: nftId)
			let nftRef = & nft as &PonsNftContractInterface.NFT

			PonsNftMarketContract .emitPonsNFTUnlisted (
				nftId: nftId,
				serialNumber: PonsNftContract .getSerialNumber (nftRef),
				editionLabel: PonsNftContract .getEditionLabel (nftRef),
				price: salePrice )

			return <- nft }

		init
		( marketReceivePaymentCap : Capability<&{FungibleToken.Receiver}>
		, primaryCommissionRatio : PonsUtils.Ratio
		, secondaryCommissionRatio : PonsUtils.Ratio
		) {
			self .collection <- PonsNftContract_v1 .createEmptyCollection ()

			self .marketReceivePaymentCap = marketReceivePaymentCap

			self .salePrices = {}
			self .saleReceivePaymentCaps = {}
			self .listingCounts = {}

			self .primaryCommissionRatio = primaryCommissionRatio
			self .secondaryCommissionRatio = secondaryCommissionRatio }

		destroy () {
			destroy self .collection } }

	pub resource PonsListingCertificate_v1 : PonsNftMarketContract.PonsListingCertificate {
		pub let listerAddress : Address
		pub let nftId : String
		pub let listingCount : Int

		init (listerAddress : Address, nftId : String, listingCount : Int) {
			self .listerAddress = listerAddress
			self .nftId = nftId
			self .listingCount = listingCount } }

	
	init () {
		var ponsMarketV1 <-
			create PonsNftMarket_v1
				( marketReceivePaymentCap : PonsUtils .prepareFlowCapability (account: self .account)
				, primaryCommissionRatio: PonsUtils.Ratio (0.2)
				, secondaryCommissionRatio: PonsUtils.Ratio (0.1) )
		PonsNftMarketContract .setPonsMarket (<- ponsMarketV1)

		emit PonsNftMarketContractInit_v1 () }
	}
