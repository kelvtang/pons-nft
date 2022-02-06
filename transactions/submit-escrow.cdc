import FungibleToken from 0xFUNGIBLETOKEN
import FlowToken from 0xFLOWTOKEN
import PonsNftContractInterface from 0xPONS
import PonsNftContract from 0xPONS
import PonsEscrowContract from 0xPONS

/* Submit an escrow using the specified id and requirement, gathering the escrow resources and fulfillment from the default paths */
transaction
( id : String
, heldResourceDescription : PonsEscrowContract.EscrowResourceDescription
, requirement : PonsEscrowContract.EscrowResourceDescription
) {
	prepare (submitter : AuthAccount) {
		/* Submit an escrow using the specified id and requirement, gathering the escrow resources and fulfillment from the default paths */
		let submitEscrow =
			fun
			( submitter : AuthAccount, id : String
			, heldResourceDescription : PonsEscrowContract.EscrowResourceDescription, requirement : PonsEscrowContract.EscrowResourceDescription
			) : StoragePath {
				// Ensure the submitter has a Flow Vault and a PonsCollection, constructing an EscrowFulfillment using the two
				let fulfillment =
					PonsEscrowContract.EscrowFulfillment (
						receivePaymentCap: prepareFlowCapability (account: submitter),
						receiveNftCap: preparePonsNftReceiverCapability (collector: submitter) )

				// Withdraw the amount specified by heldResourceDescription
				var heldFlowVault <- 
					submitter .borrow <&FungibleToken.Vault> (from: /storage/flowTokenVault) !
						.withdraw (amount: heldResourceDescription .flowUnits .flowAmount)

				// Withdraw the nfts specified by heldResourceDescription
				var heldPonsNfts : @[PonsNftContractInterface.NFT] <- []
				for nftId in heldResourceDescription .getPonsNftIds () {
					heldPonsNfts .append (<- borrowOwnPonsCollection (collector: submitter) .withdrawNft (nftId: nftId)) }

				// Create EscrowResource based on the withdrawn Flow Vault and Pons NFTs
				var heldResources <-
					PonsEscrowContract .makeEscrowResource (flowVault: <- heldFlowVault, ponsNfts: <- heldPonsNfts)

				// Submit the obtained EscrowFulfillment and EscrowResource for escrow
				return submitEscrowUsing (
					submitter: submitter, id: id,
					resources: <- heldResources, requirement: requirement,
					fulfillment: fulfillment ) }

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
		let preparePonsNftReceiverCapability =
			fun (collector : AuthAccount) : Capability<&{PonsNftContractInterface.PonsNftReceiver}> {
				var collectionOptional <-
					collector .load <@PonsNftContractInterface.Collection>
						( from: PonsNftContract .CollectionStoragePath )

				if collectionOptional == nil {
					destroy collectionOptional
					collector .save (<- PonsNftContract .createEmptyPonsCollection (), to: PonsNftContract .CollectionStoragePath) }
				else {
					collector .save (<- collectionOptional !, to: PonsNftContract .CollectionStoragePath) }


				if collector .borrow <&PonsNftContractInterface.Collection> (from: PonsNftContract .CollectionStoragePath) == nil {
					collector .save (<- PonsNftContract .createEmptyPonsCollection (), to: PonsNftContract .CollectionStoragePath) }

				if ! collector .getCapability <&{PonsNftContractInterface.PonsCollection,PonsNftContractInterface.PonsNftReceiver}> (/private/ponsCollectionNftReceiver) .check () {
					collector .link <&{PonsNftContractInterface.PonsNftReceiver}> (
						/private/ponsCollectionNftReceiver,
						target: PonsNftContract .CollectionStoragePath ) }

				return collector .getCapability <&{PonsNftContractInterface.PonsNftReceiver}> (/private/ponsCollectionNftReceiver) }

		/* Borrows a PonsCollection from an account, creating one if it does not exist */
		let borrowOwnPonsCollection =
			fun (collector : AuthAccount) : &PonsNftContractInterface.Collection {
				acquirePonsCollection (collector: collector)

				return collector .borrow <&PonsNftContractInterface.Collection> (from: PonsNftContract .CollectionStoragePath) ! }

		/* Submit an escrowing using the specified id, resources, requirement, and fulfillment */
		let submitEscrowUsing =
			fun 
			( submitter : AuthAccount, id : String
			, resources : @PonsEscrowContract.EscrowResource
			, requirement : PonsEscrowContract.EscrowResourceDescription, fulfillment : PonsEscrowContract.EscrowFulfillment
			) : StoragePath {
				// Obtain escrow capability and storage paths
				let capabilityPath = escrowCapabilityPath (submitter, id)
				let storagePath = escrowStoragePath (submitter, id)

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

		/* Ensures an account has a PonsCollection, creating one if it does not exist */
		let acquirePonsCollection =
			fun (collector : AuthAccount) : Void {
				var collectionOptional <-
					collector .load <@PonsNftContractInterface.Collection>
						( from: PonsNftContract .CollectionStoragePath )

				if collectionOptional == nil {
					destroy collectionOptional
					collector .save (<- PonsNftContract .createEmptyPonsCollection (), to: PonsNftContract .CollectionStoragePath) }
				else {
					collector .save (<- collectionOptional !, to: PonsNftContract .CollectionStoragePath) } }

		/* Get a free Capability Path to store a Capability to an Escrow */
		let escrowCapabilityPath =
			fun (_ account : AuthAccount, _ id : String) : CapabilityPath {
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
		let escrowStoragePath =
			fun (_ account : AuthAccount, _ id : String) : StoragePath {
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
		

		submitEscrow (
			submitter: submitter,
			id: id,
			heldResourceDescription: heldResourceDescription,
			requirement: requirement ) } }
