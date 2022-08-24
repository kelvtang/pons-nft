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
, _basePrice : UFix64
, _incrementalPrice : UFix64
, _ _royaltyRatio : UFix64
) {
	prepare (minter : AuthAccount) {

		let basePrice = PonsUtils.FlowUnits(flowAmount: _basePrice)
		let incrementalPrice = PonsUtils.FlowUnits(flowAmount: _incrementalPrice)
		let royaltyRatio = PonsUtils.Ratio(amount: _royaltyRatio)

		/* Function to create a unique path from nft mintID*/
		let getPathFromID = fun (_ mintID:String, counter: Int?):StoragePath{
			var count:Int? = (counter == nil? 0 : counter);
			var pureString:String = "nftid".concat(String.encodeHex(HashAlgorithm.SHA3_256.hash(mintID.utf8)).concat(count!.toString()));
			return StoragePath(identifier:pureString)!;}
			
		/* Deposit listing certificates into the account's default listing certificate collection */
		let depositListingCertificates = fun (_ account : AuthAccount, _ newListingCertificates : @[{PonsNftMarketContract.PonsListingCertificate}]) : Void {
			// Loop through new listing certificates.
			while newListingCertificates .length > 0 {
				var listingCertificateHolder <- PonsNftMarketContract .createPonsListingCertificateCollection ()
				
				// Move certificate to temporary variable
				var certificate <- newListingCertificates .remove (at: 0);

				// Generate unique storage path. Since no two nft can have same ID. Each path will always empty.
				//	// Can also be used to access listing certificate like a dictionary since each id can be used like a key.
				var counter:Int = 0;
				var collection_storage_path = getPathFromID(certificate.nftId, counter: counter);
				while account .borrow <&PonsNftMarketContract.PonsListingCertificateCollection> (from: collection_storage_path) != nil{
					counter = counter + 1;
					collection_storage_path = getPathFromID(certificate.nftId, counter: counter)}
				

				// Store in to a listing certicate collection
				listingCertificateHolder .appendListingCertificate(<- certificate );

				// Save to unique storage location
				account.save (<- listingCertificateHolder, to: collection_storage_path)}
			destroy newListingCertificates;}

	

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

				return account .getCapability <&{FungibleToken.Receiver}> (/public/flowTokenReceiver)}

		/* Create a PonsArtistCertificate authorisation resource */
		let makePonsArtistCertificateDirectly =
			fun (artist : AuthAccount) : @PonsNftContract.PonsArtistCertificate {
				acquirePonsCollection (collector: artist)

				let ponsCollectionRef = borrowOwnPonsCollection (collector : artist)
				return <- PonsNftContract .makePonsArtistCertificate (ponsCollectionRef) }

		/* Ensures an account has a PonsCollection, creating one if it does not exist */
		let acquirePonsCollection =
			fun (collector : AuthAccount) : Void {
				var collectionRefOptional =
					collector .borrow <&PonsNftContractInterface.Collection>
						( from: PonsNftContract .CollectionStoragePath )

				if collectionRefOptional == nil {
					collector .save (<- PonsNftContract .createEmptyPonsCollection (), to: PonsNftContract .CollectionStoragePath) } }

		/* Borrows a PonsCollection from an account, creating one if it does not exist */
		let borrowOwnPonsCollection =
			fun (collector : AuthAccount) : &PonsNftContractInterface.Collection {
				acquirePonsCollection (collector: collector)

				return collector .borrow <&PonsNftContractInterface.Collection> (from: PonsNftContract .CollectionStoragePath) ! }
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
					PonsNftMarketContract .mintForSaleFlow (
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

		
		mintForSale (
			minter: minter,
			metadata: metadata,
			quantity: quantity,
			basePrice: basePrice,
			incrementalPrice: incrementalPrice,
			royaltyRatio ) } }
