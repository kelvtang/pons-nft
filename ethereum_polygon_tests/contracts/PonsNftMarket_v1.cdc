import FungibleToken from 0xFUNGIBLETOKEN
import FlowToken from 0xFLOWTOKEN
import FUSD from 0xFUSD
import NonFungibleToken from 0xNONFUNGIBLETOKEN
import PonsNftContractInterface from 0xPONS
import PonsNftContract from 0xPONS
import PonsNftContract_v1 from 0xPONS
import PonsNftMarketContract from 0xPONS
import PonsUtils from 0xPONS


/*
	Pons NFT Market Contract v1

	This smart contract contains the concrete functionality of Pons NFT marketplace v1.
	In the v1 implementation, all Pons NFT marketplace information is straightforwardly stored inside the contract.
	The implementation also has separate commission ratios for freshly minted NFTs and resale NFTs.
*/
pub contract PonsNftMarketContract_v1 {

	/* PonsNftMarketContractInit_v1 is emitted on initialisation of this contract */
	pub event PonsNftMarketContractInit_v1 ()

	/* FundsHeldOnBehalfOfArtist is emitted when an NFT is purchased, but the artist's Capability to receive payment is invalid, and the market holds the funds on behalf of the artist */
	pub event FundsHeldOnBehalfOfArtistFlow (ponsArtistId : String, nftId : String, flowUnits : PonsUtils.FlowUnits)

	/* FundsHeldOnBehalfOfArtist is emitted when an NFT is purchased, but the artist's Capability to receive payment is invalid, and the market holds the funds on behalf of the artist */
	pub event FundsHeldOnBehalfOfArtistFusd (ponsArtistId : String, nftId : String, fusdUnits : PonsUtils.FusdUnits)

	/* The concrete Pons NFT Market resource. Striaghtforward implementation of the PonsNftMarket interface */
	pub resource PonsNftMarket_v1 : PonsNftMarketContract.PonsNftMarket {

		/* Stores the polygon Address of lister
			In event that nft was listed by Pons in behalf of a lister from polygon
			See: PonsTunnelContract */
		access(account) var nftPolygonListers: {UInt64: String}
		/* Stores the payment capabilities for polygon lister
			Listed as String => [FlowToken, FUSD];
			In event that nft was listed by Pons in behalf of a lister from polygon
			See: PonsTunnelContract */
		access(account) var polygonListerPaymentCapability: {String: [Capability<&{FungibleToken.Receiver}>; 2]}
		
		access(account) var polygonListerCertificateCollection: @PonsNftMarketContract.PonsListingCertificateCollection;

		access(account) fun mapPolygonListedNft(nftSerialId: UInt64, polygonAddress: String): String?{
			return self .nftPolygonListers .insert(key: nftSerialId, polygonAddress);}
		access(account) fun removePolygonListedNft(nftSerialId: UInt64): String?{
			return self .nftPolygonListers .remove(key: nftSerialId);}
		access(account) fun mapPolygonListerPaymentCapability(polygonAddress: String, flowTokenCapabilty: Capability<&{FungibleToken.Receiver}>, fusdTokenCapability: Capability<&{FungibleToken.Receiver}>):[Capability<&{FungibleToken.Receiver}>; 2]?{
			return self .polygonListerPaymentCapability .insert(key: polygonAddress, [flowTokenCapabilty, fusdTokenCapability])}
		access(account) fun getPolygonListerPaymentCapability(polygonAddress: String): [Capability<&{FungibleToken.Receiver}>; 2]?{
			return self .polygonListerPaymentCapability[polygonAddress]}


		access(account) fun setPolygonListingCertificate(nftSerialId: UInt64, polygonAddress: String, listingCertificate: @{PonsNftMarketContract.PonsListingCertificate}):Void{
			self .polygonListerCertificateCollection .appendListingCertificate(<- listingCertificate);
		}
		access(account) fun getPolygonListingCertificate(nftSerialId: UInt64, polygonAddress: String): @{PonsNftMarketContract.PonsListingCertificate}?{
			panic("not implemented")
			// if self .polygonListerCertificateCollection[polygonAddress] == nil{
			// 	return nil
			// }
			// var res <- nil;
			// self .polygonListerCertificateCollection[polygonAddress][nftSerialId] <-> res;
			// return <- res;
		}


		/* Pons v1 collection to store the NFTs on sale */
		access(account) let collection : @PonsNftContract_v1.Collection

		/* Capability for the market to receive Flow payment */
		access(account) var marketReceivePaymentCapFlow : Capability<&{FungibleToken.Receiver}>
		/* Capability for the market to receive Fusd payment */
		access(account) var marketReceivePaymentCapFusd : Capability<&{FungibleToken.Receiver}>

		/* Sales prices in Flow for each nftId */ // nil if in other currency
		access(account) var salePricesFlow : {String: PonsUtils.FlowUnits}
		/* Sales prices in Fusd for each nftId */ // nil if in other currency
		access(account) var salePricesFusd : {String: PonsUtils.FusdUnits}


		/* Seller capabilities to receive Flow payment for each nftId */
		access(account) var saleReceivePaymentCapsFlow : {String: Capability<&{FungibleToken.Receiver}>}
		/* Seller capabilities to receive Fusd payment for each nftId */
		access(account) var saleReceivePaymentCapsFusd : {String: Capability<&{FungibleToken.Receiver}>}

		/* Stores the number of times each nftId has been listed on the market */
		/* 0 means freshly minted listing */
		/* 1 or above means resell listing */
		/* This helps the marketplace evaluate the validity of different listing certificate */
		access(account) var listingCounts : {String: Int}

		/* Minimum Flow minting price */
		access(account) var minimumMintingPriceFlow : PonsUtils.FlowUnits
		/* Minimum Fusd minting price */
		access(account) var minimumMintingPriceFusd : PonsUtils.FusdUnits

		/* Commission ratio of the market on freshly minted NFTs */
		access(account) var primaryCommissionRatio : PonsUtils.Ratio
		/* Commission ratio of the market on resold NFTs */
		access(account) var secondaryCommissionRatio : PonsUtils.Ratio


		/* Inserts or updates a sale price in Flow */
		access(account) fun insertSalePriceFlow (nftId : String, price : PonsUtils.FlowUnits) : PonsUtils.FlowUnits? {
			return self .salePricesFlow .insert (key: nftId, price) }

		/* Removes a sale price in Flow */
		access(account) fun removeSalePriceFlow (nftId : String) : PonsUtils.FlowUnits? {
			return self .salePricesFlow .remove (key: nftId) }

		/* Inserts or updates a sale price in Fusd */
		access(account) fun insertSalePriceFusd (nftId : String, price : PonsUtils.FusdUnits) : PonsUtils.FusdUnits? {
			return self .salePricesFusd .insert (key: nftId, price) }

		/* Removes a sale price in Fusd */
		access(account) fun removeSalePriceFusd (nftId : String) : PonsUtils.FusdUnits? {
			return self .salePricesFusd .remove (key: nftId) }


		/* Get the nftIds of all NFTs for sale */
		pub fun getForSaleIds () : [String] {
			// concatenate the list of nfts with prices in both currecies.
			return self .salePricesFlow .keys .concat(self .salePricesFusd .keys) }

		/* Get the Flow price of an NFT */
		pub fun getPriceFlow (nftId : String) : PonsUtils.FlowUnits? {
			return self .salePricesFlow [nftId] }

		/* Get the Fusd price of an NFT */
		pub fun getPriceFusd (nftId : String) : PonsUtils.FusdUnits? {
			return self .salePricesFusd [nftId] }

		/* Borrow an NFT from the marketplace, to browse its details */
		pub fun borrowNft (nftId : String) : &PonsNftContractInterface.NFT? {
			return self .collection .borrowNft (nftId: nftId) }

		/* Given a Pons artist certificate, mint new Pons NFTs on behalf of the artist and list it on the marketplace for sale */
		/* The price of the first edition of the NFT minted is determined by the basePrice, which must be at least the minimumMintingPrice */
		/* When only one edition is minted, the incrementalPrice is inconsequential */
		/* When the Pons marketplace mints multiple editions of NFTs, the market price of each succeesive NFT is incremented by the incrementalPrice */
		pub fun mintForSaleFlow
		( _ artistCertificate : &PonsNftContract.PonsArtistCertificate
		, metadata : {String: String}
		, quantity : Int
		, basePrice : PonsUtils.FlowUnits
		, incrementalPrice : PonsUtils.FlowUnits
		, _ royaltyRatio : PonsUtils.Ratio
		, _ receivePaymentCap : Capability<&{FungibleToken.Receiver}>
		) : @[{PonsNftMarketContract.PonsListingCertificate}] {
			if ! basePrice .isAtLeast (self .minimumMintingPriceFlow) {
				panic ("NFTs minted on Pons must have a minimum price of " .concat (self .minimumMintingPriceFlow .toString ())) }

			// Create an array to store created listing certificates
			var mintListingCertificates : @[PonsListingCertificate_v1] <- []

			// For any mintIndex from 0 (inclusive) up to the quantity specified (exclusive)
			var mintIndex = 0
			var salePrice = basePrice
			while mintIndex < quantity {
				// Define the NFT editionLabel
				let editionLabel =
					quantity == 1
					? "One of a kind"
					: "Edition " .concat ((mintIndex + 1) .toString ())

				// Mint the NFT using the Pons NFT v1 minter capability
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

				// Deposit the NFT into the market collection, and save all relevant market data 
				self .collection .depositNft (<- nft)
				self .salePricesFlow .insert (key: nftId, salePrice)
				self .saleReceivePaymentCapsFlow .insert (key: nftId, receivePaymentCap)
				self .listingCounts .insert (key: nftId, 0)


				// Emit the Pons NFT Market listing event
				PonsNftMarketContract .emitPonsNFTListedFlow (
					nftId: nftId,
					serialNumber: serialNumber,
					editionLabel: editionLabel,
					price: salePrice )


				// First, create a new listing certificate for the NFT, where listerAddress is the market address so that the artist cannot directly unlist the NFT
				// Then, move the listing certificate to the array of minted listing certificates
				mintListingCertificates .append (
					<- create PonsListingCertificate_v1 (
						listerAddress: PonsNftMarketContract .PonsNftMarketAddress,
						nftId: nftId,
						listingCount: 0 ) )

				// Continue iterating on the next mintIndex and increment the price to sell, by the incrementalPrice
				mintIndex = mintIndex + 1
				salePrice = PonsUtils .sumFlowUnits (salePrice, incrementalPrice) }

			return <- mintListingCertificates }

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
		) : @[{PonsNftMarketContract.PonsListingCertificate}] {
			if ! basePrice .isAtLeast (self .minimumMintingPriceFusd) {
				panic ("NFTs minted on Pons must have a minimum price of " .concat (self .minimumMintingPriceFusd .toString ())) }

			// Create an array to store created listing certificates
			var mintListingCertificates : @[PonsListingCertificate_v1] <- []

			// For any mintIndex from 0 (inclusive) up to the quantity specified (exclusive)
			var mintIndex = 0
			var salePrice = basePrice
			while mintIndex < quantity {
				// Define the NFT editionLabel
				let editionLabel =
					quantity == 1
					? "One of a kind"
					: "Edition " .concat ((mintIndex + 1) .toString ())

				// Mint the NFT using the Pons NFT v1 minter capability
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

				// Deposit the NFT into the market collection, and save all relevant market data 
				self .collection .depositNft (<- nft)
				self .salePricesFusd .insert (key: nftId, salePrice)
				self .saleReceivePaymentCapsFusd .insert (key: nftId, receivePaymentCap)
				self .listingCounts .insert (key: nftId, 0)


				// Emit the Pons NFT Market listing event
				PonsNftMarketContract .emitPonsNFTListedFusd (
					nftId: nftId,
					serialNumber: serialNumber,
					editionLabel: editionLabel,
					price: salePrice )


				// First, create a new listing certificate for the NFT, where listerAddress is the market address so that the artist cannot directly unlist the NFT
				// Then, move the listing certificate to the array of minted listing certificates
				mintListingCertificates .append (
					<- create PonsListingCertificate_v1 (
						listerAddress: PonsNftMarketContract .PonsNftMarketAddress,
						nftId: nftId,
						listingCount: 0 ) )

				// Continue iterating on the next mintIndex and increment the price to sell, by the incrementalPrice
				mintIndex = mintIndex + 1
				salePrice = PonsUtils .sumFusdUnits (salePrice, incrementalPrice) }

			return <- mintListingCertificates }

		

		/* List a Pons NFT on the marketplace for sale */
		pub fun listForSaleFlow (_ nft : @PonsNftContractInterface.NFT, _ salePrice : PonsUtils.FlowUnits, _ receivePaymentCap : Capability<&{FungibleToken.Receiver}>) : @{PonsNftMarketContract.PonsListingCertificate} {
			// Record the previous owner of the NFT
			// let ownerAddress = nft .owner !.address

			// Flow implementation seems to be inconsistent regarding owners of nested resources
			// https://github.com/onflow/cadence/issues/1320
			// As a temporary workaround, assume the receivePaymentCap points to a vault with the lister as owner
			let ownerAddress = receivePaymentCap .borrow () !.owner !.address

			let nftId = nft .nftId
			let nftRef = & nft as &PonsNftContractInterface.NFT
			let serialNumber = PonsNftContract .getSerialNumber (nftRef)
			let editionLabel = PonsNftContract .getEditionLabel (nftRef)
			let listingCount = (self .listingCounts [nftId] ?? 0) + 1

			// Deposit the NFT into the market collection, and save all relevant market data
			self .collection .depositNft (<- nft)
			self .salePricesFlow .insert (key: nftId, salePrice)
			self .saleReceivePaymentCapsFlow .insert (key: nftId, receivePaymentCap)
			self .saleReceivePaymentCapsFusd .remove (key: nftId) // only latest capability should be stored
			self .listingCounts .insert (
				key: nftId,
				listingCount )

			// Create a new listing certificate for the NFT, where listerAddress is the address of the previous owner
			var ponsListingCertificate
				<- create PonsListingCertificate_v1 (
					listerAddress: ownerAddress,
					nftId: nftId,
					listingCount: listingCount )

			// Emit the Pons NFT Market listing event
			PonsNftMarketContract .emitPonsNFTListedFlow (
				nftId: nftId,
				serialNumber: serialNumber,
				editionLabel: editionLabel,
				price: salePrice )

			return <- ponsListingCertificate }

		/* List a Pons NFT on the marketplace for sale */
		pub fun listForSaleFusd (_ nft : @PonsNftContractInterface.NFT, _ salePrice : PonsUtils.FusdUnits, _ receivePaymentCap : Capability<&{FungibleToken.Receiver}>) : @{PonsNftMarketContract.PonsListingCertificate} {
			// Record the previous owner of the NFT
			// let ownerAddress = nft .owner !.address

			// Flow implementation seems to be inconsistent regarding owners of nested resources
			// https://github.com/onflow/cadence/issues/1320
			// As a temporary workaround, assume the receivePaymentCap points to a vault with the lister as owner
			let ownerAddress = receivePaymentCap .borrow () !.owner !.address

			let nftId = nft .nftId
			let nftRef = & nft as &PonsNftContractInterface.NFT
			let serialNumber = PonsNftContract .getSerialNumber (nftRef)
			let editionLabel = PonsNftContract .getEditionLabel (nftRef)
			let listingCount = (self .listingCounts [nftId] ?? 0) + 1

			// Deposit the NFT into the market collection, and save all relevant market data
			self .collection .depositNft (<- nft)
			self .salePricesFusd .insert (key: nftId, salePrice)
			self .saleReceivePaymentCapsFusd .insert (key: nftId, receivePaymentCap)
			self .saleReceivePaymentCapsFlow .remove (key: nftId) // only latest capability should be stored
			self .listingCounts .insert (
				key: nftId,
				listingCount )

			// Create a new listing certificate for the NFT, where listerAddress is the address of the previous owner
			var ponsListingCertificate
				<- create PonsListingCertificate_v1 (
					listerAddress: ownerAddress,
					nftId: nftId,
					listingCount: listingCount )

			// Emit the Pons NFT Market listing event
			PonsNftMarketContract .emitPonsNFTListedFusd (
				nftId: nftId,
				serialNumber: serialNumber,
				editionLabel: editionLabel,
				price: salePrice )

			return <- ponsListingCertificate }
		
		/* Purchase a Pons NFT from the marketplace */
		pub fun purchaseFlow (nftId : String, _ purchaseVault : @FungibleToken.Vault) : @PonsNftContractInterface.NFT {
			// Check that the NFT is available on the market
			if ! self .salePricesFlow .containsKey (nftId) {
				panic ("Pons NFT with ID " .concat (nftId) .concat (" not on the market")) }

			// Check that the sufficient funds of Flow tokens have been provided
			let purchasePrice = self .salePricesFlow .remove (key: nftId) !
			if ! PonsUtils .FlowUnits (purchaseVault .balance) .isAtLeast (purchasePrice) {
				panic ("Pons NFT with ID " .concat (nftId) .concat (" is on sale for ") .concat (purchasePrice .toString ()) .concat (", insufficient funds provided")) }


			// Withdraw the NFT from the market collection
			var nft <- self .collection .withdrawNft (nftId: nftId)
			let nftRef = & nft as &PonsNftContractInterface.NFT

			// Record the owner of the paying Vault if any, to identify the new owner of the NFT
			let vaultOwnerAddress = purchaseVault .owner ?.address

			// Check whether the purchase is an original sale or resale, and calculate commissions and royalties accordingly
			let primarySale = (self .listingCounts [nftId] == 0)
			let royalties =
				primarySale
				? (nil as! PonsUtils.FlowUnits?)
				: purchasePrice .scale (ratio: PonsNftContract .getRoyalty (nftRef))
			let commissionPrice =
				primarySale
				? purchasePrice .scale (ratio: self .primaryCommissionRatio)
				: purchasePrice .scale (ratio: self .secondaryCommissionRatio)
			let sellerPrice =
				purchasePrice
				.cut (commissionPrice)
				.cut (royalties ?? PonsUtils .FlowUnits (0.0))

			// If royalties are due, pay the royalties
			if royalties != nil {
				// Withdraw royalties from the purchase funds
				var royaltiesVault <- purchaseVault .withdraw (amount: royalties !.flowAmount)
				let artistRef = PonsNftContract .borrowArtist (nftRef)
				let artistReceivePaymentCapOptional = PonsNftContract .getArtistReceivePaymentCapFlow (artistRef)

				// If the artist's Capability for receiving Flow tokens is valid
				if artistReceivePaymentCapOptional != nil && artistReceivePaymentCapOptional !.check () {
					// Deposit royalty funds to the artist
					artistReceivePaymentCapOptional !.borrow () !.deposit (from: <- royaltiesVault) }
				else {
					// If the artist does not have a valid Capability to receive payments, hold the funds on behalf of the artist
					// Emit the funds held on behalf of artist event
					emit FundsHeldOnBehalfOfArtistFlow (ponsArtistId: artistRef .ponsArtistId, nftId: nftId, flowUnits: royalties !)
					self .marketReceivePaymentCapFlow .borrow () !.deposit (from: <- royaltiesVault) } }

			// Pay the seller the amount due
			let sellerReceivePaymentCap = self .saleReceivePaymentCapsFlow [nftId] !
			sellerReceivePaymentCap .borrow () !.deposit (from: <- purchaseVault .withdraw (amount: sellerPrice .flowAmount))

			// Market takes the rest as commission
			self .marketReceivePaymentCapFlow .borrow () !.deposit (from: <- purchaseVault)

			// Emit the Pons NFT Market sold event
			PonsNftMarketContract .emitPonsNFTSoldFlow (
				nftId: nftId,
				serialNumber: PonsNftContract .getSerialNumber (nftRef),
				editionLabel: PonsNftContract .getEditionLabel (nftRef),
				price: purchasePrice )
			// If the purchasing account is known, emit the Pons NFT ownership event
			if vaultOwnerAddress != nil {
				PonsNftMarketContract .emitPonsNFTOwnsFlow (
					owner: vaultOwnerAddress !,
					nftId: nftId,
					serialNumber: PonsNftContract .getSerialNumber (nftRef),
					editionLabel: PonsNftContract .getEditionLabel (nftRef),
					price: purchasePrice ) }

			return <- nft }

		/* Purchase a Pons NFT from the marketplace */
		pub fun purchaseFusd (nftId : String, _ purchaseVault : @FungibleToken.Vault) : @PonsNftContractInterface.NFT {
			// Check that the NFT is available on the market
			if ! self .salePricesFusd .containsKey (nftId) {
				panic ("Pons NFT with ID " .concat (nftId) .concat (" not on the market")) }

			// Check that the sufficient funds of Flow tokens have been provided
			let purchasePrice = self .salePricesFusd .remove (key: nftId) !
			if ! PonsUtils .FusdUnits (purchaseVault .balance) .isAtLeast (purchasePrice) {
				panic ("Pons NFT with ID " .concat (nftId) .concat (" is on sale for ") .concat (purchasePrice .toString ()) .concat (", insufficient funds provided")) }


			// Withdraw the NFT from the market collection
			var nft <- self .collection .withdrawNft (nftId: nftId)
			let nftRef = & nft as &PonsNftContractInterface.NFT

			// Record the owner of the paying Vault if any, to identify the new owner of the NFT
			let vaultOwnerAddress = purchaseVault .owner ?.address

			// Check whether the purchase is an original sale or resale, and calculate commissions and royalties accordingly
			let primarySale = (self .listingCounts [nftId] == 0)
			let royalties =
				primarySale
				? (nil as! PonsUtils.FusdUnits?)
				: purchasePrice .scale (ratio: PonsNftContract .getRoyalty (nftRef))
			let commissionPrice =
				primarySale
				? purchasePrice .scale (ratio: self .primaryCommissionRatio)
				: purchasePrice .scale (ratio: self .secondaryCommissionRatio)
			let sellerPrice =
				purchasePrice
				.cut (commissionPrice)
				.cut (royalties ?? PonsUtils .FusdUnits (0.0))

			// If royalties are due, pay the royalties
			if royalties != nil {
				// Withdraw royalties from the purchase funds
				var royaltiesVault <- purchaseVault .withdraw (amount: royalties !.fusdAmount)
				let artistRef = PonsNftContract .borrowArtist (nftRef)
				let artistReceivePaymentCapOptional = PonsNftContract .getArtistReceivePaymentCapFusd (artistRef)

				// If the artist's Capability for receiving Flow tokens is valid
				if artistReceivePaymentCapOptional != nil && artistReceivePaymentCapOptional !.check () {
					// Deposit royalty funds to the artist
					artistReceivePaymentCapOptional !.borrow () !.deposit (from: <- royaltiesVault) }
				else {
					// If the artist does not have a valid Capability to receive payments, hold the funds on behalf of the artist
					// Emit the funds held on behalf of artist event
					emit FundsHeldOnBehalfOfArtistFusd (ponsArtistId: artistRef .ponsArtistId, nftId: nftId, fusdUnits: royalties !)
					self .marketReceivePaymentCapFusd .borrow () !.deposit (from: <- royaltiesVault) } }

			// Pay the seller the amount due
			let sellerReceivePaymentCap = self .saleReceivePaymentCapsFusd [nftId] !
			sellerReceivePaymentCap .borrow () !.deposit (from: <- purchaseVault .withdraw (amount: sellerPrice .fusdAmount))

			// Market takes the rest as commission
			self .marketReceivePaymentCapFusd .borrow () !.deposit (from: <- purchaseVault)

			// Emit the Pons NFT Market sold event
			PonsNftMarketContract .emitPonsNFTSoldFusd (
				nftId: nftId,
				serialNumber: PonsNftContract .getSerialNumber (nftRef),
				editionLabel: PonsNftContract .getEditionLabel (nftRef),
				price: purchasePrice )
			// If the purchasing account is known, emit the Pons NFT ownership event
			if vaultOwnerAddress != nil {
				PonsNftMarketContract .emitPonsNFTOwnsFusd (
					owner: vaultOwnerAddress !,
					nftId: nftId,
					serialNumber: PonsNftContract .getSerialNumber (nftRef),
					editionLabel: PonsNftContract .getEditionLabel (nftRef),
					price: purchasePrice ) }

			return <- nft }

		/* Unlist a Pons NFT from the marketplace */
		access(account) fun unlist_onlyParameters (nftId: String) : @PonsNftContractInterface.NFT {
			

			// Retrieve the NFT market data, and check that the NFT is not freshly minted
			let salePriceFlow = self .removeSalePriceFlow (nftId: nftId)
			let salePriceFusd = self .removeSalePriceFusd (nftId: nftId)
			if salePriceFlow == nil && salePriceFusd == nil{
				panic ("Nft not found in sales price dictionary.")
			}

			
			// Withdraw the NFT from the market collection
			var nft <- self .collection .withdrawNft (nftId: nftId)
			let nftRef = & nft as &PonsNftContractInterface.NFT

			// Emit the Pons NFT Market unlisted event
			if salePriceFlow != nil {
				PonsNftMarketContract .emitPonsNFTUnlistedFlow (
					nftId: nftId,
					serialNumber: PonsNftContract .getSerialNumber (nftRef),
					editionLabel: PonsNftContract .getEditionLabel (nftRef),
					price: salePriceFlow! )
			}else{
				PonsNftMarketContract .emitPonsNFTUnlistedFusd (
					nftId: nftId,
					serialNumber: PonsNftContract .getSerialNumber (nftRef),
					editionLabel: PonsNftContract .getEditionLabel (nftRef),
					price: salePriceFusd! )
			}
			return <- nft;
		}
		
		/* Unlist a Pons NFT from the marketplace */
		pub fun unlist (_ ponsListingCertificate : @{PonsNftMarketContract.PonsListingCertificate}) : @PonsNftContractInterface.NFT {
			// Cast the certificate to a @PonsListingCertificate_v1, which is the only resource type recognised in this contract
			var ponsListingCertificate_v1 <-
				ponsListingCertificate as! @PonsListingCertificate_v1

			// Retrieve the certificate nftId
			let nftId = ponsListingCertificate_v1 .nftId

			// Verify that the certificate is still valid (i.e. issued for a listing that is currently for sale)
			if ponsListingCertificate_v1 .listingCount != self .listingCounts [nftId] {
				panic ("This Listing Certificate is not valid anymore") }

			// Consume the certificate
			destroy ponsListingCertificate_v1

			// Retrieve the NFT market data, and check that the NFT is not freshly minted
			let salePriceFlow = self .removeSalePriceFlow (nftId: nftId)
			let salePriceFusd = self .removeSalePriceFusd (nftId: nftId)
			if salePriceFlow == nil && salePriceFusd == nil{
				panic ("Nft not found in sales price dictionary.")
			}


			if self .listingCounts [nftId] == 0 {
				panic
					( "Pons NFT with ID " .concat (nftId) .concat (" had just been freshly minted on Pons market, and cannot be unlisted. ")
					.concat ("Pons NFTs can be unlisted if a buyer of the Pons NFT lists the NFT again.") ) }

			// Withdraw the NFT from the market collection
			var nft <- self .collection .withdrawNft (nftId: nftId)
			let nftRef = & nft as &PonsNftContractInterface.NFT

			// Emit the Pons NFT Market unlisted event
			if salePriceFlow != nil {
				PonsNftMarketContract .emitPonsNFTUnlistedFlow (
					nftId: nftId,
					serialNumber: PonsNftContract .getSerialNumber (nftRef),
					editionLabel: PonsNftContract .getEditionLabel (nftRef),
					price: salePriceFlow! )
			}else{
				PonsNftMarketContract .emitPonsNFTUnlistedFusd (
					nftId: nftId,
					serialNumber: PonsNftContract .getSerialNumber (nftRef),
					editionLabel: PonsNftContract .getEditionLabel (nftRef),
					price: salePriceFusd! )
			}

			return <- nft }

		init
		( marketReceivePaymentCapFlow : Capability<&{FungibleToken.Receiver}>
		, marketReceivePaymentCapFusd : Capability<&{FungibleToken.Receiver}>
		, minimumMintingPriceFlow : PonsUtils.FlowUnits
		, minimumMintingPriceFusd : PonsUtils.FusdUnits
		, primaryCommissionRatio : PonsUtils.Ratio
		, secondaryCommissionRatio : PonsUtils.Ratio
		) {
			self .collection <- PonsNftContract_v1 .createEmptyCollection ()

			self .marketReceivePaymentCapFlow = marketReceivePaymentCapFlow
			self .marketReceivePaymentCapFusd = marketReceivePaymentCapFusd

			self .salePricesFlow = {}
			self .saleReceivePaymentCapsFlow = {}
			self .salePricesFusd = {}
			self .saleReceivePaymentCapsFusd = {}
			self .listingCounts = {}

			self .minimumMintingPriceFlow = minimumMintingPriceFlow
			self .minimumMintingPriceFusd = minimumMintingPriceFusd
			self .primaryCommissionRatio = primaryCommissionRatio
			self .secondaryCommissionRatio = secondaryCommissionRatio 
			
			self .nftPolygonListers = {};
			self .polygonListerPaymentCapability = {};
			self .polygonListerCertificateCollection <- PonsNftMarketContract.createPonsListingCertificateCollection();

			}

		destroy () {
			destroy self .collection 
			destroy self .polygonListerCertificateCollection} }

	/* The concrete Pons Listing Certificate resource. Striaghtforward implementation of the PonsNftMarket interface, and also record the number of times the NFT has previously been listed */
	pub resource PonsListingCertificate_v1 : PonsNftMarketContract.PonsListingCertificate {
		pub let listerAddress : Address
		pub let nftId : String
		pub let listingCount : Int

		init (listerAddress : Address, nftId : String, listingCount : Int) {
			self .listerAddress = listerAddress
			self .nftId = nftId
			self .listingCount = listingCount } }

	
	init () {
		let account = self .account

		/* Initialize flow token vault */
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


		/* Initialize fusd vault */
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

		let marketReceivePaymentCapFlow = account .getCapability <&{FungibleToken.Receiver}> (/public/flowTokenReceiver)
		let marketReceivePaymentCapFusd = account .getCapability <&{FungibleToken.Receiver}> (/public/fusdReceiver)

		var ponsMarketV1 <-
			create PonsNftMarket_v1
				( marketReceivePaymentCapFlow: marketReceivePaymentCapFlow
				, marketReceivePaymentCapFusd: marketReceivePaymentCapFusd
				, minimumMintingPriceFlow: PonsUtils.FlowUnits (1.0)
				, minimumMintingPriceFusd: PonsUtils.FusdUnits (1.0)
				, primaryCommissionRatio: PonsUtils.Ratio (0.2)
				, secondaryCommissionRatio: PonsUtils.Ratio (0.1) )
		// Activate PonsNftMarket_v1 as the active implementation of the Pons NFT marketplace
		PonsNftMarketContract .setPonsMarket (<- ponsMarketV1)

		// Emit the PonsNftMarketContractInit_v1 contract initialised event
		emit PonsNftMarketContractInit_v1 () }
	}
