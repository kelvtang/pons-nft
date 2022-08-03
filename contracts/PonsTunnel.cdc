import FungibleToken from 0xFUNGIBLETOKEN
import NonFungibleToken from 0xNONFUNGIBLETOKEN
import FlowToken from 0xFLOWTOKEN
import FUSD from 0xFUSD
import PonsNftContractInterface from 0xPONS
import PonsNftContract from 0xPONS
import PonsUtils from 0xPONS
import PonsEscrowTunnelContract from 0xPONS

/*  This contract aims at enabling a tunnel between Flow and Polygon
    The transfer will implement a hold and release mechanism, where we hold items from one chain before releasing in the other.
    The benefit of this is to future proof the mechanism in the event that either Polygon or Flow become expensive to mint nft on.

    The mechanism would hold the nft from the current chain, and emit and event signaling that it has held it. 
    On the other side, the nft of the same ID would be released (or minted if being transfered for the first time).

    This mechanism would ensure that the gas fees would only be as much as a transfer of nft.

     */
pub contract PonsTunnelContract{

    pub event nftSubmittedThroughTunnel (data: sentTunnelData)
    pub event nftRecievedThroughTunnel (data: recieveTunnelData)
 

	/* These structs define the emitted data in proper structure */
	pub struct nftDetails{
		pub let nftId: String
		pub let nftSerialId: UInt64
		pub let metadata: {String:String} 
		pub let artistAddressFlow: Address
		pub var artistAddressPolygon: String?
		pub let royalty: UFix64

		pub fun setArtistAddressPolygon (artistAddressPolygon: String){
			self .artistAddressPolygon = artistAddressPolygon;
		}

		init (nftId:String, nftSerialId:UInt64, metadata: {String:String}, artistAddressFlow:Address, royalty:UFix64){
			self .nftId = nftId
			self .nftSerialId = nftSerialId
			self .metadata = metadata
			self .artistAddressFlow = artistAddressFlow
			self .artistAddressPolygon = nil
			self .royalty = royalty}}

	pub struct sentTunnelData{
		pub let nft: nftDetails
		pub let polygonRecipientAddress: String

		init(polygonRecipientAddress: String, nft:PonsTunnelContract.nftDetails){
			self .nft = nft
			self .polygonRecipientAddress = polygonRecipientAddress}}

	pub struct recieveTunnelData{
		pub let nft: nftDetails
		pub let flowRecipientAddress: Address /* Reciepient Address in flow */

		init(flowRecipientAddress: Address, nft:PonsTunnelContract.nftDetails){
			self .nft = nft
			self .flowRecipientAddress = flowRecipientAddress}
	}

	access(self) fun generateNftEmitData(nftRef: &PonsNftContractInterface.NFT):PonsTunnelContract.nftDetails{

		let artistAddressFlow:Address = PonsNftContract .getArtistAddress (PonsNftContract .borrowArtistById (ponsArtistId: PonsNftContract .implementation .getArtistIdFromId(nftRef .nftId)))!;
		
		let royalty:UFix64 = PonsNftContract .getRoyalty(nftRef) .amount;
		let nftEmitData: PonsTunnelContract.nftDetails = PonsTunnelContract .nftDetails(nftId:nftRef .nftId, nftSerialId:nftRef .id, metdata: PonsNftContract .getMetadata(nftRef), artistAddressFlow:artistAddressFlow, royalty:royalty)
		return nftEmitData;}

	access(self) fun generateSentTunnelEmitData(nftRef: &PonsNftContractInterface.NFT, artistAddressPolygon: String?, polygonRecipientAddress: String):PonsTunnelContract.sentTunnelData{
		let nftEmitData:PonsTunnelContract.nftDetails = PonsTunnelContract .generateNftEmitData(nftRef: nftRef)

		if artistAddressPolygon != nil { 
			nftEmitData .setArtistAddressPolygon (artistAddressPolygon:artistAddressPolygon!)
		}


		let sentData: PonsTunnelContract.sentTunnelData = PonsTunnelContract .sentTunnelData(polygonRecipientAddress: polygonRecipientAddress, nft: nftEmitData)

		return sentData}
	access(self) fun generateRecieveTunnelEmitData(nftRef: &PonsNftContractInterface.NFT, artistAddressPolygon: String?, flowRecipientAddress: Address):PonsTunnelContract.recieveTunnelData{
		let nftEmitData:PonsTunnelContract.nftDetails = PonsTunnelContract .generateNftEmitData(nftRef: nftRef)

		if artistAddressPolygon != nil { 
			nftEmitData .setArtistAddressPolygon (artistAddressPolygon:artistAddressPolygon!)
		}

		let recievedData: PonsTunnelContract.recieveTunnelData = PonsTunnelContract .recieveTunnelData(flowRecipientAddress: flowRecipientAddress, nft: nftEmitData)
		return recievedData
	}
		

   /* Creates Flow Vaults and Capabilities in the standard locations if they do not exist, and returns a capability to send Flow tokens to the account */
	pub fun prepareFlowCapability (account : AuthAccount) : Capability<&{FungibleToken.Receiver}> {
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

	/* Creates FUSD Vaults and Capabilities in the standard locations if they do not exist, and returns a capability to send FUSD tokens to the account */
	pub fun prepareFusdCapability (account : AuthAccount) : Capability<&{FungibleToken.Receiver}> {
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

		return account .getCapability <&{FungibleToken.Receiver}> (/public/fusdReceiver)
	}

	/* Ensures an account has a PonsCollection, creating one if it does not exist */
	pub fun acquirePonsCollection (collector : AuthAccount) : Void {
		var collectionRefOptional =
			collector .borrow <&PonsNftContractInterface.Collection>
				( from: PonsNftContract .CollectionStoragePath )

		if collectionRefOptional == nil {
			collector .save (<- PonsNftContract .createEmptyPonsCollection (), to: PonsNftContract .CollectionStoragePath) }}
	
	/* Ensures an account has a PonsCollection, creating one if it does not exist */
	pub fun preparePonsNftReceiverCapability (collector : AuthAccount) : Capability<&{PonsNftContractInterface.PonsNftReceiver}> {
		var collectionRefOptional =
			collector .borrow <&PonsNftContractInterface.Collection>
				( from: PonsNftContract .CollectionStoragePath )

		if collectionRefOptional == nil {
			collector .save (<- PonsNftContract .createEmptyPonsCollection (), to: PonsNftContract .CollectionStoragePath) }


		if collector .borrow <&PonsNftContractInterface.Collection> (from: PonsNftContract .CollectionStoragePath) == nil {
			collector .save (<- PonsNftContract .createEmptyPonsCollection (), to: PonsNftContract .CollectionStoragePath) }

		if ! collector .getCapability <&{PonsNftContractInterface.PonsCollection,PonsNftContractInterface.PonsNftReceiver}> (/private/ponsCollectionNftReceiver) .check () {
			collector .link <&{PonsNftContractInterface.PonsNftReceiver}> (
				/private/ponsCollectionNftReceiver,
				target: PonsNftContract .CollectionStoragePath ) }

		return collector .getCapability <&{PonsNftContractInterface.PonsNftReceiver}> (/private/ponsCollectionNftReceiver)}

	/* Borrows a PonsCollection from an account, creating one if it does not exist */
	pub fun borrowOwnPonsCollection (collector : AuthAccount) : &PonsNftContractInterface.Collection {
		PonsTunnelContract .acquirePonsCollection (collector: collector)
		return collector .borrow <&PonsNftContractInterface.Collection> (from: PonsNftContract .CollectionStoragePath) !
	}

	
	/* Get a free Capability Path to store a Capability to an Escrow */
	pub fun escrowCapabilityPath (_ account : AuthAccount, _ id : String) : CapabilityPath {
		// This function is not yet defined in this version of Cadence
		//return PrivatePath ("escrow___" .concat (id)) !
		let potentialCapabilityPaths =
			[ /private/escrow___1, /private/escrow___2, /private/escrow___3, /private/escrow___4, /private/escrow___5, /private/escrow___6, /private/escrow___7, /private/escrow___8, /private/escrow___9, /private/escrow___10 ]
		for capabilityPath in potentialCapabilityPaths {
			if account .getCapability <&PonsEscrowTunnelContract.Escrow> (capabilityPath) .check () {
				let storagePath = account .getLinkTarget (capabilityPath) ! as! StoragePath
				let escrowRefOptional = account .borrow <&PonsEscrowTunnelContract.Escrow> (from: storagePath) 
				if escrowRefOptional == nil {
					account .unlink (capabilityPath)
					return capabilityPath }
				else {
					if escrowRefOptional !.isReleased () {
						account .unlink (capabilityPath)
						destroy account .load <@PonsEscrowTunnelContract.Escrow> (from: storagePath)
						return capabilityPath } } }
			else {
				return capabilityPath } }
		panic ("No free escrow capability paths found") }

	/* Get a free Storage Path to store a Capability to an Escrow */
	pub fun escrowStoragePath (_ account : AuthAccount, _ id : String) : StoragePath {
		//return StoragePath ("escrow___" .concat (id)) !
		let potentialStoragePaths =
			[ /storage/escrow___1, /storage/escrow___2, /storage/escrow___3, /storage/escrow___4, /storage/escrow___5, /storage/escrow___6, /storage/escrow___7, /storage/escrow___8, /storage/escrow___9, /storage/escrow___10 ]
		for storagePath in potentialStoragePaths {
			let escrowRefOptional = account .borrow <&PonsEscrowTunnelContract.Escrow> (from: storagePath) 
			if escrowRefOptional == nil {
				return storagePath }
			else {
				if escrowRefOptional !.isReleased () {
					destroy account .load <@PonsEscrowTunnelContract.Escrow> (from: storagePath)
					return storagePath } } }
		panic ("No free escrow storage paths found") }

	/* Submit an escrowing using the specified id, resources, requirement, and fulfillment */
	pub fun submitEscrowUsing
	( submitter : AuthAccount, id : String
	, resources : @PonsEscrowTunnelContract.EscrowResource
	, requirement : PonsEscrowTunnelContract.EscrowResourceDescription, 
	fulfillment : PonsEscrowTunnelContract.EscrowFulfillment
	) : StoragePath {
		// Obtain escrow capability and storage paths
		let capabilityPath = PonsTunnelContract .escrowCapabilityPath (submitter, id)
		let storagePath = PonsTunnelContract .escrowStoragePath (submitter, id)

		// Create an escrow capability to the escrow storage path
		let escrowCap = submitter .link <&PonsEscrowTunnelContract.Escrow> (capabilityPath, target: storagePath) !

		// First, submit an escrow with the specified information and resources, obtaining an Escrow resource
		// Then, save the Escrow resource to the arranged storage path
		submitter .save (
			<- PonsEscrowTunnelContract .submitEscrow (
				id: id, escrowCap: escrowCap, resources: <- resources,
				requirement: requirement, fulfillment: fulfillment ),
			to: storagePath )

		return storagePath }

	/* Submit an escrow using the specified id and requirement, gathering the escrow resources and fulfillment from the default paths */
	pub fun submitEscrow
	( submitter : AuthAccount, id : String
	, heldResourceDescription : PonsEscrowTunnelContract.EscrowResourceDescription, requirement : PonsEscrowTunnelContract.EscrowResourceDescription
	) : StoragePath {
		// Ensure the submitter has a Flow Vault and a PonsCollection, constructing an EscrowFulfillment using the two
		let fulfillment =
			PonsEscrowTunnelContract.EscrowFulfillment (
				receivePaymentCapFlow: PonsTunnelContract .prepareFlowCapability (account: submitter),
				receivePaymentCapFusd: PonsTunnelContract .prepareFusdCapability (account: submitter),
				receiveNftCap: PonsTunnelContract .preparePonsNftReceiverCapability (collector: submitter) )

		// Withdraw the amount specified by heldResourceDescription
		var heldFlowVault <- 
			submitter .borrow <&FungibleToken.Vault> (from: /storage/flowTokenVault) !
				.withdraw (amount: heldResourceDescription .flowUnits .flowAmount)
		
		// Withdraw the amount specified by heldResourceDescription
		var heldFusdVault <- 
			submitter .borrow <&FungibleToken.Vault> (from: /storage/fusdVault) !
				.withdraw (amount: heldResourceDescription .fusdUnits .fusdAmount)

		// Withdraw the nfts specified by heldResourceDescription
		var heldPonsNfts : @[PonsNftContractInterface.NFT] <- []
		for nftId in heldResourceDescription .getPonsNftIds () {
			heldPonsNfts .append (<- PonsTunnelContract .borrowOwnPonsCollection (collector: submitter) .withdrawNft (nftId: nftId)) }

		// Create EscrowResource based on the withdrawn Flow Vault and Pons NFTs
		var heldResources <-
			PonsEscrowTunnelContract .makeEscrowResource (flowVault: <- heldFlowVault, fusdVault: <- heldFusdVault, ponsNfts: <- heldPonsNfts)

		// Submit the obtained EscrowFulfillment and EscrowResource for escrow
		return PonsTunnelContract .submitEscrowUsing (
			submitter: submitter, id: id,
			resources: <- heldResources, requirement: requirement,
			fulfillment: fulfillment ) 
	}
	
	pub fun sendNftThroughTunnel(nftId:String, ponsAccount : AuthAccount, ponsHolderAccount : AuthAccount, tunnelUserAccount : AuthAccount, polygonAddress: String){
		pre {
			/* ponsHolderAccount.toString() == "":
				panic("Can only go through tunnel by burning using Pons Burner") */
		}

		let nftRef:&PonsNftContractInterface.NFT = PonsTunnelContract .borrowOwnPonsCollection (collector: tunnelUserAccount) .borrowNft (nftId: nftId)
		
		PonsTunnelContract .submitEscrow (
			submitter: tunnelUserAccount,
			id: nftId.concat("Tunnel-User-Escrow"),
			heldResourceDescription: PonsEscrowTunnelContract.EscrowResourceDescription (
				flowUnits: PonsUtils.FlowUnits (0.0),
				fusdUnits: PonsUtils.FusdUnits (0.0),
				ponsNftIds: [ nftId ] ),
			requirement: PonsEscrowTunnelContract.EscrowResourceDescription (
				flowUnits: PonsUtils.FlowUnits (0.0),
				fusdUnits: PonsUtils.FusdUnits (0.0),
				ponsNftIds: [] ) )

		PonsTunnelContract .submitEscrow (
			submitter: ponsHolderAccount,
			id: nftId.concat("Tunnel-PonsBurner-Escrow"),
			heldResourceDescription: PonsEscrowTunnelContract.EscrowResourceDescription (
				flowUnits: PonsUtils.FlowUnits (0.0),
				fusdUnits: PonsUtils.FusdUnits (0.0),
				ponsNftIds: [] ),
			requirement: PonsEscrowTunnelContract.EscrowResourceDescription (
				flowUnits: PonsUtils.FlowUnits (0.0),
				fusdUnits: PonsUtils.FusdUnits (0.0),
				ponsNftIds: [ nftId ] ) )	

		let escrowManagerRef = ponsAccount .borrow <&PonsEscrowTunnelContract.EscrowManager> (from: /storage/escrowTunnelManager) !
		

		let subConsummation =
			fun (_ escrowResourceListRef : &[PonsEscrowTunnelContract.EscrowResource]) : Void {
				escrowManagerRef .consummateEscrow (
					id: nftId.concat("Tunnel-User-Escrow"),
					consummation: fun (_ giftEscrowResource : @PonsEscrowTunnelContract.EscrowResource) : @PonsEscrowTunnelContract.EscrowResource {

						var emptyEscrowResource <- escrowResourceListRef .remove (at: 0)

						escrowResourceListRef .insert (at: 0, <- giftEscrowResource)

						return <- emptyEscrowResource } ) }

		escrowManagerRef .consummateEscrow (
			id: nftId.concat("Tunnel-PonsBurner-Escrow"),
			consummation: fun (_ emptyEscrowResource : @PonsEscrowTunnelContract.EscrowResource) : @PonsEscrowTunnelContract.EscrowResource {

				var consummatedEscrowResourceList : @[PonsEscrowTunnelContract.EscrowResource] <- [ <- emptyEscrowResource ]

				let escrowResourceListRef = &consummatedEscrowResourceList as &[PonsEscrowTunnelContract.EscrowResource]

				subConsummation (escrowResourceListRef)

				var giftEscrowResource <- escrowResourceListRef .remove (at: 0)

				destroy consummatedEscrowResourceList

				return <- giftEscrowResource } )

		escrowManagerRef .dismissEscrow (id: nftId.concat("Tunnel-User-Escrow"))
		escrowManagerRef .dismissEscrow (id: nftId.concat("Tunnel-PonsBurner-Escrow"))	

		let tunnelData = PonsTunnelContract .generateSentTunnelEmitData(nftRef: nftRef, artistAddressPolygon: nil, polygonRecipientAddress: polygonAddress);
		emit nftSubmittedThroughTunnel (data: tunnelData)
	}
	
	pub fun sendNftThroughTunnelUsingSerialId(nftSerialId: UInt64, ponsAccount : AuthAccount, ponsHolderAccount : AuthAccount, tunnelUserAccount : AuthAccount, polygonAddress: String){
		pre {
			/* ponsHolderAccount.toString() == "":
				panic("Can only go through tunnel by burning using Pons Burner") */
		}

		let nftId = PonsTunnelContract .borrowOwnPonsCollection (collector: tunnelUserAccount) .getNftId (serialId: nftSerialId)!
		let nftRef:&PonsNftContractInterface.NFT = PonsTunnelContract .borrowOwnPonsCollection (collector: tunnelUserAccount) .borrowNft (nftId: nftId)
		
		PonsTunnelContract .submitEscrow (
			submitter: tunnelUserAccount,
			id: nftId.concat("Tunnel-User-Escrow"),
			heldResourceDescription: PonsEscrowTunnelContract.EscrowResourceDescription (
				flowUnits: PonsUtils.FlowUnits (0.0),
				fusdUnits: PonsUtils.FusdUnits (0.0),
				ponsNftIds: [ nftId ] ),
			requirement: PonsEscrowTunnelContract.EscrowResourceDescription (
				flowUnits: PonsUtils.FlowUnits (0.0),
				fusdUnits: PonsUtils.FusdUnits (0.0),
				ponsNftIds: [] ) )

		PonsTunnelContract .submitEscrow (
			submitter: ponsHolderAccount,
			id: nftId.concat("Tunnel-PonsBurner-Escrow"),
			heldResourceDescription: PonsEscrowTunnelContract.EscrowResourceDescription (
				flowUnits: PonsUtils.FlowUnits (0.0),
				fusdUnits: PonsUtils.FusdUnits (0.0),
				ponsNftIds: [] ),
			requirement: PonsEscrowTunnelContract.EscrowResourceDescription (
				flowUnits: PonsUtils.FlowUnits (0.0),
				fusdUnits: PonsUtils.FusdUnits (0.0),
				ponsNftIds: [ nftId ] ) )	

		let escrowManagerRef = ponsAccount .borrow <&PonsEscrowTunnelContract.EscrowManager> (from: /storage/escrowTunnelManager) !
		

		let subConsummation =
			fun (_ escrowResourceListRef : &[PonsEscrowTunnelContract.EscrowResource]) : Void {
				escrowManagerRef .consummateEscrow (
					id: nftId.concat("Tunnel-User-Escrow"),
					consummation: fun (_ giftEscrowResource : @PonsEscrowTunnelContract.EscrowResource) : @PonsEscrowTunnelContract.EscrowResource {

						var emptyEscrowResource <- escrowResourceListRef .remove (at: 0)

						escrowResourceListRef .insert (at: 0, <- giftEscrowResource)

						return <- emptyEscrowResource } ) }

		escrowManagerRef .consummateEscrow (
			id: nftId.concat("Tunnel-PonsBurner-Escrow"),
			consummation: fun (_ emptyEscrowResource : @PonsEscrowTunnelContract.EscrowResource) : @PonsEscrowTunnelContract.EscrowResource {

				var consummatedEscrowResourceList : @[PonsEscrowTunnelContract.EscrowResource] <- [ <- emptyEscrowResource ]

				let escrowResourceListRef = &consummatedEscrowResourceList as &[PonsEscrowTunnelContract.EscrowResource]

				subConsummation (escrowResourceListRef)

				var giftEscrowResource <- escrowResourceListRef .remove (at: 0)

				destroy consummatedEscrowResourceList

				return <- giftEscrowResource } )

		escrowManagerRef .dismissEscrow (id: nftId.concat("Tunnel-User-Escrow"))
		escrowManagerRef .dismissEscrow (id: nftId.concat("Tunnel-PonsBurner-Escrow"))	

		let tunnelData = PonsTunnelContract .generateSentTunnelEmitData(nftRef: nftRef, artistAddressPolygon: nil, polygonRecipientAddress: polygonAddress);
		emit nftSubmittedThroughTunnel (data: tunnelData)
	}

    pub fun recieveNftFromTunnelUsingSerialId(nftSerialId:UInt64, ponsAccount : AuthAccount, ponsHolderAccount : AuthAccount, tunnelUserAccount : AuthAccount){
		pre {
			/* ponsHolderAccount.toString() == "":
				panic("Can only go through tunnel by burning using Pons Burner") */
			
		}

		let nftId = PonsTunnelContract .borrowOwnPonsCollection (collector: ponsHolderAccount) .getNftId(serialId: nftSerialId)!
		let nftRef:&PonsNftContractInterface.NFT = PonsTunnelContract .borrowOwnPonsCollection (collector: ponsHolderAccount) .borrowNft (nftId: nftId)
		

		PonsTunnelContract .submitEscrow (
			submitter: ponsHolderAccount,
			id: nftId.concat("Tunnel-User-Escrow"),
			heldResourceDescription: PonsEscrowTunnelContract.EscrowResourceDescription (
				flowUnits: PonsUtils.FlowUnits (0.0),
				fusdUnits: PonsUtils.FusdUnits (0.0),
				ponsNftIds: [ nftId ] ),
			requirement: PonsEscrowTunnelContract.EscrowResourceDescription (
				flowUnits: PonsUtils.FlowUnits (0.0),
				fusdUnits: PonsUtils.FusdUnits (0.0),
				ponsNftIds: [] ) )

		PonsTunnelContract .submitEscrow (
			submitter: tunnelUserAccount,
			id: nftId.concat("Tunnel-PonsBurner-Escrow"),
			heldResourceDescription: PonsEscrowTunnelContract.EscrowResourceDescription (
				flowUnits: PonsUtils.FlowUnits (0.0),
				fusdUnits: PonsUtils.FusdUnits (0.0),
				ponsNftIds: [] ),
			requirement: PonsEscrowTunnelContract.EscrowResourceDescription (
				flowUnits: PonsUtils.FlowUnits (0.0),
				fusdUnits: PonsUtils.FusdUnits (0.0),
				ponsNftIds: [ nftId ] ) )	

		let escrowManagerRef = ponsAccount .borrow <&PonsEscrowTunnelContract.EscrowManager> (from: /storage/escrowTunnelManager) !
		

		let subConsummation =
			fun (_ escrowResourceListRef : &[PonsEscrowTunnelContract.EscrowResource]) : Void {
				escrowManagerRef .consummateEscrow (
					id: nftId.concat("Tunnel-User-Escrow"),
					consummation: fun (_ giftEscrowResource : @PonsEscrowTunnelContract.EscrowResource) : @PonsEscrowTunnelContract.EscrowResource {

						var emptyEscrowResource <- escrowResourceListRef .remove (at: 0)

						escrowResourceListRef .insert (at: 0, <- giftEscrowResource)

						return <- emptyEscrowResource } ) }

		escrowManagerRef .consummateEscrow (
			id: nftId.concat("Tunnel-PonsBurner-Escrow"),
			consummation: fun (_ emptyEscrowResource : @PonsEscrowTunnelContract.EscrowResource) : @PonsEscrowTunnelContract.EscrowResource {

				var consummatedEscrowResourceList : @[PonsEscrowTunnelContract.EscrowResource] <- [ <- emptyEscrowResource ]

				let escrowResourceListRef = &consummatedEscrowResourceList as &[PonsEscrowTunnelContract.EscrowResource]

				subConsummation (escrowResourceListRef)

				var giftEscrowResource <- escrowResourceListRef .remove (at: 0)

				destroy consummatedEscrowResourceList

				return <- giftEscrowResource } )

		escrowManagerRef .dismissEscrow (id: nftId.concat("Tunnel-User-Escrow"))
		escrowManagerRef .dismissEscrow (id: nftId.concat("Tunnel-PonsBurner-Escrow"))
		
		let tunnelData = PonsTunnelContract .generateRecieveTunnelEmitData(nftRef: nftRef, artistAddressPolygon: nil, flowRecipientAddress: tunnelUserAccount .address);
		emit nftRecievedThroughTunnel (data: tunnelData)
	}
	
    pub fun recieveNftFromTunnel(nftId: String, ponsAccount : AuthAccount, ponsHolderAccount : AuthAccount, tunnelUserAccount : AuthAccount){
		pre {
			/* ponsHolderAccount.toString() == "":
				panic("Can only go through tunnel by burning using Pons Burner") */
			
		}

		let nftRef:&PonsNftContractInterface.NFT = PonsTunnelContract .borrowOwnPonsCollection (collector: ponsHolderAccount) .borrowNft (nftId: nftId)
		

		PonsTunnelContract .submitEscrow (
			submitter: ponsHolderAccount,
			id: nftId.concat("Tunnel-User-Escrow"),
			heldResourceDescription: PonsEscrowTunnelContract.EscrowResourceDescription (
				flowUnits: PonsUtils.FlowUnits (0.0),
				fusdUnits: PonsUtils.FusdUnits (0.0),
				ponsNftIds: [ nftId ] ),
			requirement: PonsEscrowTunnelContract.EscrowResourceDescription (
				flowUnits: PonsUtils.FlowUnits (0.0),
				fusdUnits: PonsUtils.FusdUnits (0.0),
				ponsNftIds: [] ) )

		PonsTunnelContract .submitEscrow (
			submitter: tunnelUserAccount,
			id: nftId.concat("Tunnel-PonsBurner-Escrow"),
			heldResourceDescription: PonsEscrowTunnelContract.EscrowResourceDescription (
				flowUnits: PonsUtils.FlowUnits (0.0),
				fusdUnits: PonsUtils.FusdUnits (0.0),
				ponsNftIds: [] ),
			requirement: PonsEscrowTunnelContract.EscrowResourceDescription (
				flowUnits: PonsUtils.FlowUnits (0.0),
				fusdUnits: PonsUtils.FusdUnits (0.0),
				ponsNftIds: [ nftId ] ) )	

		let escrowManagerRef = ponsAccount .borrow <&PonsEscrowTunnelContract.EscrowManager> (from: /storage/escrowTunnelManager) !
		

		let subConsummation =
			fun (_ escrowResourceListRef : &[PonsEscrowTunnelContract.EscrowResource]) : Void {
				escrowManagerRef .consummateEscrow (
					id: nftId.concat("Tunnel-User-Escrow"),
					consummation: fun (_ giftEscrowResource : @PonsEscrowTunnelContract.EscrowResource) : @PonsEscrowTunnelContract.EscrowResource {

						var emptyEscrowResource <- escrowResourceListRef .remove (at: 0)

						escrowResourceListRef .insert (at: 0, <- giftEscrowResource)

						return <- emptyEscrowResource } ) }

		escrowManagerRef .consummateEscrow (
			id: nftId.concat("Tunnel-PonsBurner-Escrow"),
			consummation: fun (_ emptyEscrowResource : @PonsEscrowTunnelContract.EscrowResource) : @PonsEscrowTunnelContract.EscrowResource {

				var consummatedEscrowResourceList : @[PonsEscrowTunnelContract.EscrowResource] <- [ <- emptyEscrowResource ]

				let escrowResourceListRef = &consummatedEscrowResourceList as &[PonsEscrowTunnelContract.EscrowResource]

				subConsummation (escrowResourceListRef)

				var giftEscrowResource <- escrowResourceListRef .remove (at: 0)

				destroy consummatedEscrowResourceList

				return <- giftEscrowResource } )

		escrowManagerRef .dismissEscrow (id: nftId.concat("Tunnel-User-Escrow"))
		escrowManagerRef .dismissEscrow (id: nftId.concat("Tunnel-PonsBurner-Escrow"))
		
		let tunnelData = PonsTunnelContract .generateRecieveTunnelEmitData(nftRef: nftRef, artistAddressPolygon: nil, flowRecipientAddress: tunnelUserAccount .address);
		emit nftRecievedThroughTunnel (data: tunnelData)
	}

}