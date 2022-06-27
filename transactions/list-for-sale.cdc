import FungibleToken from 0xFUNGIBLETOKEN
import FlowToken from 0xFLOWTOKEN
import PonsUtils from 0xPONS
import PonsNftContractInterface from 0xPONS
import PonsNftContract from 0xPONS
import PonsNftMarketContract from 0xPONS

/* List an owned NFT on the marketplace for sale */
transaction 
( nftId : String
, _ salePrice : PonsUtils.FlowUnits
) {
	prepare (lister : AuthAccount) {
		/* Lists an owned NFT on the marketplace for sale */
		let listForSale =
			fun (lister : AuthAccount, nftId : String, _ salePrice : PonsUtils.FlowUnits) : Void {
				pre {
					borrowOwnPonsCollection (collector: lister) .borrowNft (nftId: nftId) != nil:
						"Pons NFT with this nftId does not belong to your Pons Collection" }
				// Obtain the minter's Capability to receive Flow tokens
				var receivePaymentCap = prepareFlowCapability (account: lister)
				// Withdraw the specified nft from the lister's Pons collection
				var nft <- borrowOwnPonsCollection (collector: lister) .withdrawNft (nftId: nftId)
				// List the NFT on the active Pons market for a listing certificate
				var listingCertificate <- PonsNftMarketContract .ponsMarket .listForSale (<- nft, salePrice, receivePaymentCap)
				// Deposit the listing certificate in the lister's listing certificate collection
				depositListingCertificate (lister, <- listingCertificate) }

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

		/* Ensures an account has a PonsCollection, creating one if it does not exist */
		let acquirePonsCollection =
			fun (collector : AuthAccount) : Void {
				var collectionRefOptional =
					collector .borrow <&PonsNftContractInterface.Collection>
						( from: PonsNftContract .CollectionStoragePath )

				if collectionRefOptional == nil {
					collector .save (<- PonsNftContract .createEmptyPonsCollection (), to: PonsNftContract .CollectionStoragePath) } }

		listForSale (lister: lister, nftId: nftId, salePrice) } }
