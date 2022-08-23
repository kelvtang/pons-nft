import FungibleToken from 0xFUNGIBLETOKEN
import FlowToken from 0xFLOWTOKEN
import PonsUtils from 0xPONS
import PonsNftContractInterface from 0xPONS
import PonsNftContract from 0xPONS
import PonsNftMarketContract from 0xPONS


/* List an owned NFT on the marketplace for sale */
transaction 
( nftId : String
, currencyChoice: String
, salePrice : UFix64
) {
	prepare (lister : AuthAccount) {
		/* Lists an owned NFT on the marketplace for sale */
		let listForSale_flow =
			fun (lister : AuthAccount, nftId : String, _ salePrice : UFix64) : Void {
				pre {
					borrowOwnPonsCollection (collector: lister) .borrowNft (nftId: nftId) != nil:
						"Pons NFT with this nftId does not belong to your Pons Collection" }

				let saleUnit = PonsUtils.FlowUnits(flowAmount: salePrice);
				// Obtain the minter's Capability to receive Flow tokens
				var receivePaymentCap = prepareFlowCapability (account: lister)
				// Withdraw the specified nft from the lister's Pons collection
				var nft <- borrowOwnPonsCollection (collector: lister) .withdrawNft (nftId: nftId)
				// List the NFT on the active Pons market for a listing certificate
				var listingCertificate <- PonsNftMarketContract .ponsMarket .listForSaleFlow (<- nft, saleUnit, receivePaymentCap)
				// Deposit the listing certificate in the lister's listing certificate collection
				depositListingCertificate (lister, <- listingCertificate) }
		/* Lists an owned NFT on the marketplace for sale */
		let listForSale_fusd =
			fun (lister : AuthAccount, nftId : String, _ salePrice : UFix64) : Void {
				pre {
					borrowOwnPonsCollection (collector: lister) .borrowNft (nftId: nftId) != nil:
						"Pons NFT with this nftId does not belong to your Pons Collection" }

				let saleUnit = PonsUtils.FusdUnits(fusdAmount: salePrice);
				// Obtain the minter's Capability to receive Flow tokens
				var receivePaymentCap = prepareFusdCapability (account: lister)
				// Withdraw the specified nft from the lister's Pons collection
				var nft <- borrowOwnPonsCollection (collector: lister) .withdrawNft (nftId: nftId)
				// List the NFT on the active Pons market for a listing certificate
				var listingCertificate <- PonsNftMarketContract .ponsMarket .listForSaleFusd (<- nft, saleUnit, receivePaymentCap)
				// Deposit the listing certificate in the lister's listing certificate collection
				depositListingCertificate (lister, <- listingCertificate) }

		let depositListingCertificate = 
			fun (_ account : AuthAccount, _ newListingCertificate : @{PonsNftMarketContract.PonsListingCertificate}) : Void {
		
			var listingCertificateHolder <- PonsNftMarketContract .createPonsListingCertificateCollection ()
				
			// Generate unique storage path. Since no two nft can have same ID. Each path will always empty.
			//	// Can also be used to access listing certificate like a dictionary since each id can be used like a key.
			var counter:Int = 0;
			var collection_storage_path = PonsUsage .getPathFromID(newListingCertificate.nftId, counter: counter);
			while account .borrow <&PonsNftMarketContract.PonsListingCertificateCollection> (from: collection_storage_path) != nil{
				counter = counter + 1;
				collection_storage_path = PonsUsage .getPathFromID(newListingCertificate.nftId, counter: counter);}
			

			// Store in to a listing certicate collection
			listingCertificateHolder .appendListingCertificate(<- newListingCertificate );

			// Save to unique storage location
			account.save (<- listingCertificateHolder, to: collection_storage_path)}

	

		/* Borrows a PonsCollection from an account, creating one if it does not exist */
		let borrowOwnPonsCollection =
			fun (collector : AuthAccount) : &PonsNftContractInterface.Collection {
				acquirePonsCollection (collector: collector)

				return collector .borrow <&PonsNftContractInterface.Collection> (from: PonsNftContract .CollectionStoragePath) ! }

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

		let prepareFusdCapability =
			 fun (account : AuthAccount) : Capability<&{FungibleToken.Receiver}> {
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

	/* Ensures an account has a PonsCollection, creating one if it does not exist */
		let acquirePonsCollection =
			fun (collector : AuthAccount) : Void {
				var collectionRefOptional =
					collector .borrow <&PonsNftContractInterface.Collection>
						( from: PonsNftContract .CollectionStoragePath )

				if collectionRefOptional == nil {
					collector .save (<- PonsNftContract .createEmptyPonsCollection (), to: PonsNftContract .CollectionStoragePath) } }

		if currencyChoice == "FUSD"{
			listForSale_fusd (lister: lister, nftId: nftId, salePrice)	
		}else{
			listForSale_flow (lister: lister, nftId: nftId, salePrice)
		}
			
 } }

