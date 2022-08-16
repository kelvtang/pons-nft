import FungibleToken from 0xFUNGIBLETOKEN
import NonFungibleToken from 0xNONFUNGIBLETOKEN
import FlowToken from 0xFLOWTOKEN
import FUSD from 0xFUSD
import PonsNftContractInterface from 0xPONS
import PonsNftContract from 0xPONS
import PonsNftMarketContract from 0xPONS
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

    pub event nftSubmittedThroughTunnel_Market (data: sentTunnelData_Market)
    pub event nftSubmittedThroughTunnel_User (data: sentTunnelData_User)
    pub event nftRecievedThroughTunnel_Market (data: recieveTunnelData_Market)
	pub event nftRecievedThroughTunnel_User (data: recieveTunnelData_User)
 

	/* These structs define the emitted data in proper structure - for Market to Market (contains Token detail) */
	pub struct nftDetails_Market{
		/* Either or none of Token may be nil */
		pub let nftId: String
		pub let nftSerialId: UInt64
		pub let metadata: {String: String} 
		pub let artistAddressFlow: Address
		pub var artistAddressPolygon: String?
		pub var flowToken: PonsUtils.FlowUnits?
		pub var fusdToken: PonsUtils.FusdUnits?
		pub let royalty: UFix64

		pub fun setArtistAddressPolygon (artistAddressPolygon: String){
			self .artistAddressPolygon = artistAddressPolygon;
		}

		init (nftId: String, nftSerialId: UInt64, metadata: {String: String}, artistAddressFlow: Address, royalty: UFix64, flowToken: PonsUtils.FlowUnits?, fusdToken: PonsUtils.FusdUnits?){
			self .nftId = nftId
			self .nftSerialId = nftSerialId
			self .metadata = metadata
			self .artistAddressFlow = artistAddressFlow
			self .artistAddressPolygon = nil
			self .royalty = royalty
			self .flowToken = flowToken
			self .fusdToken = fusdToken}}

	/* These structs define the emitted data in proper structure - for User to User */
	pub struct nftDetails_User{
		pub let nftId: String
		pub let nftSerialId: UInt64
		pub let metadata: {String: String} 
		pub let artistAddressFlow: Address
		pub var artistAddressPolygon: String?
		pub let royalty: UFix64

		pub fun setArtistAddressPolygon (artistAddressPolygon: String){
			self .artistAddressPolygon = artistAddressPolygon;
		}

		init (nftId: String, nftSerialId: UInt64, metadata: {String: String}, artistAddressFlow: Address, royalty: UFix64){
			self .nftId = nftId
			self .nftSerialId = nftSerialId
			self .metadata = metadata
			self .artistAddressFlow = artistAddressFlow
			self .artistAddressPolygon = nil
			self .royalty = royalty}}

	pub struct sentTunnelData_Market{
		pub let nft: nftDetails_Market
		pub let polygonRecipientAddress: String

		init(polygonRecipientAddress: String, nft: PonsTunnelContract.nftDetails_Market){
			self .nft = nft
			self .polygonRecipientAddress = polygonRecipientAddress}}

	pub struct recieveTunnelData_Market{
		pub let nft: nftDetails_Market
		pub let flowRecipientAddress: Address /* Reciepient Address in flow */

		init(flowRecipientAddress: Address, nft: PonsTunnelContract.nftDetails_Market){
			self .nft = nft
			self .flowRecipientAddress = flowRecipientAddress}
	}

	pub struct sentTunnelData_User{
		pub let nft: nftDetails_User
		pub let polygonRecipientAddress: String

		init(polygonRecipientAddress: String, nft: PonsTunnelContract.nftDetails_User){
			self .nft = nft
			self .polygonRecipientAddress = polygonRecipientAddress}}

	pub struct recieveTunnelData_User{
		pub let nft: nftDetails_User
		pub let flowRecipientAddress: Address /* Reciepient Address in flow */

		init(flowRecipientAddress: Address, nft: PonsTunnelContract.nftDetails_User){
			self .nft = nft
			self .flowRecipientAddress = flowRecipientAddress}
	}

	access(self) fun generateNftEmitData_Market(nftRef: &PonsNftContractInterface.NFT): PonsTunnelContract.nftDetails_Market{
		let artistAddressFlow: Address = PonsNftContract .getArtistAddress (PonsNftContract .borrowArtistById (ponsArtistId: PonsNftContract .implementation .getArtistIdFromId(nftRef .nftId)))!;
		let royalty: UFix64 = PonsNftContract .getRoyalty(nftRef) .amount;

		/* 
		Add flowToken, fusdToken if listed on Marketplace.
		 */
		let flowToken = PonsNftMarketContract .ponsMarket .getPriceFlow(nftId: nftRef .nftId);
		let fusdToken = PonsNftMarketContract .ponsMarket .getPriceFusd(nftId: nftRef .nftId);

		let nftEmitData: PonsTunnelContract.nftDetails_Market = PonsTunnelContract .nftDetails_Market(nftId: nftRef .nftId, nftSerialId: nftRef .id, metdata: PonsNftContract .getMetadata(nftRef), artistAddressFlow: artistAddressFlow, royalty: royalty, flowToken: flowToken, fusdToken: fusdToken)
		return nftEmitData;}

	access(self) fun generateSentTunnelEmitData_Market(nftRef: &PonsNftContractInterface.NFT, artistAddressPolygon: String?, polygonRecipientAddress: String): PonsTunnelContract.sentTunnelData_Market{
		let nftEmitData: PonsTunnelContract.nftDetails_Market = PonsTunnelContract .generateNftEmitData_Market(nftRef: nftRef)

		if artistAddressPolygon != nil { 
			nftEmitData .setArtistAddressPolygon (artistAddressPolygon: artistAddressPolygon!)
		}

		let sentData: PonsTunnelContract.sentTunnelData_Market = PonsTunnelContract .sentTunnelData_Market(polygonRecipientAddress: polygonRecipientAddress, nft: nftEmitData)

		return sentData}
	access(self) fun generateRecieveTunnelEmitData_Market(nftRef: &PonsNftContractInterface.NFT, artistAddressPolygon: String?, flowRecipientAddress: Address): PonsTunnelContract.recieveTunnelData_Market{
		let nftEmitData: PonsTunnelContract.nftDetails_Market = PonsTunnelContract .generateNftEmitData_Market(nftRef: nftRef)

		if artistAddressPolygon != nil { 
			nftEmitData .setArtistAddressPolygon (artistAddressPolygon: artistAddressPolygon!)
		}

		let recievedData: PonsTunnelContract.recieveTunnelData_Market = PonsTunnelContract .recieveTunnelData_Market(flowRecipientAddress: flowRecipientAddress, nft: nftEmitData)
		return recievedData
	}

	access(self) fun generateNftEmitData_User(nftRef: &PonsNftContractInterface.NFT): PonsTunnelContract.nftDetails_User{
		let artistAddressFlow: Address = PonsNftContract .getArtistAddress (PonsNftContract .borrowArtistById (ponsArtistId: PonsNftContract .implementation .getArtistIdFromId(nftRef .nftId)))!;
		let royalty: UFix64 = PonsNftContract .getRoyalty(nftRef) .amount;

		let nftEmitData: PonsTunnelContract.nftDetails_User = PonsTunnelContract .nftDetails_User(nftId: nftRef .nftId, nftSerialId: nftRef .id, metdata: PonsNftContract .getMetadata(nftRef), artistAddressFlow: artistAddressFlow, royalty: royalty);
		return nftEmitData;}

	access(self) fun generateSentTunnelEmitData_User(nftRef: &PonsNftContractInterface.NFT, artistAddressPolygon: String?, polygonRecipientAddress: String): PonsTunnelContract.sentTunnelData_User{
		let nftEmitData: PonsTunnelContract.nftDetails_User = PonsTunnelContract .generateNftEmitData_User(nftRef: nftRef)

		if artistAddressPolygon != nil { 
			nftEmitData .setArtistAddressPolygon (artistAddressPolygon: artistAddressPolygon!)
		}

		let sentData: PonsTunnelContract.sentTunnelData_User = PonsTunnelContract .sentTunnelData_User(polygonRecipientAddress: polygonRecipientAddress, nft: nftEmitData)

		return sentData}
	access(self) fun generateRecieveTunnelEmitData_User(nftRef: &PonsNftContractInterface.NFT, artistAddressPolygon: String?, flowRecipientAddress: Address): PonsTunnelContract.recieveTunnelData_User{
		let nftEmitData: PonsTunnelContract.nftDetails_User = PonsTunnelContract .generateNftEmitData_User(nftRef: nftRef)

		if artistAddressPolygon != nil { 
			nftEmitData .setArtistAddressPolygon (artistAddressPolygon: artistAddressPolygon!)
		}

		let recievedData: PonsTunnelContract.recieveTunnelData_User = PonsTunnelContract .recieveTunnelData_User(flowRecipientAddress: flowRecipientAddress, nft: nftEmitData)
		return recievedData
	}
		

   /* Creates Flow Vaults and Capabilities in the standard locations if they do not exist, and returns a capability to send Flow tokens to the account */
	pub fun prepareFlowCapability (account: AuthAccount): Capability<&{FungibleToken.Receiver}> {
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
	pub fun prepareFusdCapability (account: AuthAccount): Capability<&{FungibleToken.Receiver}> {
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
	pub fun acquirePonsCollection (collector: AuthAccount): Void {
		var collectionRefOptional =
			collector .borrow <&PonsNftContractInterface.Collection>
				( from: PonsNftContract .CollectionStoragePath )

		if collectionRefOptional == nil {
			collector .save (<- PonsNftContract .createEmptyPonsCollection (), to: PonsNftContract .CollectionStoragePath) }}
	
	/* Ensures an account has a PonsCollection, creating one if it does not exist */
	pub fun preparePonsNftReceiverCapability (collector: AuthAccount): Capability<&{PonsNftContractInterface.PonsNftReceiver}> {
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
	pub fun borrowOwnPonsCollection (collector: AuthAccount): &PonsNftContractInterface.Collection {
		PonsTunnelContract .acquirePonsCollection (collector: collector)
		return collector .borrow <&PonsNftContractInterface.Collection> (from: PonsNftContract .CollectionStoragePath) !
	}

	
	/* Get a free Capability Path to store a Capability to an Escrow */
	pub fun escrowCapabilityPath (_ account: AuthAccount, _ id: String): CapabilityPath {
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
	pub fun escrowStoragePath (_ account: AuthAccount, _ id: String): StoragePath {
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
	( submitter: AuthAccount, id: String
	, resources: @PonsEscrowTunnelContract.EscrowResource
	, requirement: PonsEscrowTunnelContract.EscrowResourceDescription, 
	fulfillment: PonsEscrowTunnelContract.EscrowFulfillment
	): StoragePath {
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
	( submitter: AuthAccount, id: String
	, heldResourceDescription: PonsEscrowTunnelContract.EscrowResourceDescription, requirement: PonsEscrowTunnelContract.EscrowResourceDescription
	): StoragePath {
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
		var heldPonsNfts: @[PonsNftContractInterface.NFT] <- []
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
	
	pub fun sendNftThroughTunnel(nftId: String, ponsAccount: AuthAccount, ponsHolderAccount: AuthAccount, tunnelUserAccount: AuthAccount, polygonAddress: String){
		pre {
			/* ponsHolderAccount.toString() == "": 
				panic("Can only go through tunnel by burning using Pons Burner") */
		}

		let nftRef: &PonsNftContractInterface.NFT = PonsTunnelContract .borrowOwnPonsCollection (collector: tunnelUserAccount) .borrowNft (nftId: nftId)
		
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
			fun (_ escrowResourceListRef: &[PonsEscrowTunnelContract.EscrowResource]): Void {
				escrowManagerRef .consummateEscrow (
					id: nftId.concat("Tunnel-User-Escrow"),
					consummation: fun (_ giftEscrowResource: @PonsEscrowTunnelContract.EscrowResource): @PonsEscrowTunnelContract.EscrowResource {

						var emptyEscrowResource <- escrowResourceListRef .remove (at: 0)

						escrowResourceListRef .insert (at: 0, <- giftEscrowResource)

						return <- emptyEscrowResource } ) }

		escrowManagerRef .consummateEscrow (
			id: nftId.concat("Tunnel-PonsBurner-Escrow"),
			consummation: fun (_ emptyEscrowResource: @PonsEscrowTunnelContract.EscrowResource): @PonsEscrowTunnelContract.EscrowResource {

				var consummatedEscrowResourceList: @[PonsEscrowTunnelContract.EscrowResource] <- [ <- emptyEscrowResource ]

				let escrowResourceListRef = &consummatedEscrowResourceList as &[PonsEscrowTunnelContract.EscrowResource]

				subConsummation (escrowResourceListRef)

				var giftEscrowResource <- escrowResourceListRef .remove (at: 0)

				destroy consummatedEscrowResourceList

				return <- giftEscrowResource } )

		escrowManagerRef .dismissEscrow (id: nftId.concat("Tunnel-User-Escrow"))
		escrowManagerRef .dismissEscrow (id: nftId.concat("Tunnel-PonsBurner-Escrow"))	

		let tunnelData = PonsTunnelContract .generateSentTunnelEmitData_User(nftRef: nftRef, artistAddressPolygon: nil, polygonRecipientAddress: polygonAddress);
		emit nftSubmittedThroughTunnel_User (data: tunnelData)
	}
	
	pub fun sendNftThroughTunnelUsingSerialId(nftSerialId: UInt64, ponsAccount: AuthAccount, ponsHolderAccount: AuthAccount, tunnelUserAccount: AuthAccount, polygonAddress: String){
		pre {
			/* ponsHolderAccount.toString() == "": 
				panic("Can only go through tunnel by burning using Pons Burner") */
		}

		let nftId = PonsTunnelContract .borrowOwnPonsCollection (collector: tunnelUserAccount) .getNftId (serialId: nftSerialId)!
		let nftRef: &PonsNftContractInterface.NFT = PonsTunnelContract .borrowOwnPonsCollection (collector: tunnelUserAccount) .borrowNft (nftId: nftId)
		
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
			fun (_ escrowResourceListRef: &[PonsEscrowTunnelContract.EscrowResource]): Void {
				escrowManagerRef .consummateEscrow (
					id: nftId.concat("Tunnel-User-Escrow"),
					consummation: fun (_ giftEscrowResource: @PonsEscrowTunnelContract.EscrowResource): @PonsEscrowTunnelContract.EscrowResource {

						var emptyEscrowResource <- escrowResourceListRef .remove (at: 0)

						escrowResourceListRef .insert (at: 0, <- giftEscrowResource)

						return <- emptyEscrowResource } ) }

		escrowManagerRef .consummateEscrow (
			id: nftId.concat("Tunnel-PonsBurner-Escrow"),
			consummation: fun (_ emptyEscrowResource: @PonsEscrowTunnelContract.EscrowResource): @PonsEscrowTunnelContract.EscrowResource {

				var consummatedEscrowResourceList: @[PonsEscrowTunnelContract.EscrowResource] <- [ <- emptyEscrowResource ]

				let escrowResourceListRef = &consummatedEscrowResourceList as &[PonsEscrowTunnelContract.EscrowResource]

				subConsummation (escrowResourceListRef)

				var giftEscrowResource <- escrowResourceListRef .remove (at: 0)

				destroy consummatedEscrowResourceList

				return <- giftEscrowResource } )

		escrowManagerRef .dismissEscrow (id: nftId.concat("Tunnel-User-Escrow"))
		escrowManagerRef .dismissEscrow (id: nftId.concat("Tunnel-PonsBurner-Escrow"))	

		let tunnelData = PonsTunnelContract .generateSentTunnelEmitData_User(nftRef: nftRef, artistAddressPolygon: nil, polygonRecipientAddress: polygonAddress);
		emit nftSubmittedThroughTunnel_User (data: tunnelData)
	}
	
    pub fun recieveNftFromTunnel(nftId: String, ponsAccount: AuthAccount, ponsHolderAccount: AuthAccount, tunnelUserAccount: AuthAccount){
		pre {
			/* ponsHolderAccount.toString() == "": 
				panic("Can only go through tunnel by burning using Pons Burner") */
			
		}

		let nftRef: &PonsNftContractInterface.NFT = PonsTunnelContract .borrowOwnPonsCollection (collector: ponsHolderAccount) .borrowNft (nftId: nftId)
		

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
			fun (_ escrowResourceListRef: &[PonsEscrowTunnelContract.EscrowResource]): Void {
				escrowManagerRef .consummateEscrow (
					id: nftId.concat("Tunnel-User-Escrow"),
					consummation: fun (_ giftEscrowResource: @PonsEscrowTunnelContract.EscrowResource): @PonsEscrowTunnelContract.EscrowResource {

						var emptyEscrowResource <- escrowResourceListRef .remove (at: 0)

						escrowResourceListRef .insert (at: 0, <- giftEscrowResource)

						return <- emptyEscrowResource } ) }

		escrowManagerRef .consummateEscrow (
			id: nftId.concat("Tunnel-PonsBurner-Escrow"),
			consummation: fun (_ emptyEscrowResource: @PonsEscrowTunnelContract.EscrowResource): @PonsEscrowTunnelContract.EscrowResource {

				var consummatedEscrowResourceList: @[PonsEscrowTunnelContract.EscrowResource] <- [ <- emptyEscrowResource ]

				let escrowResourceListRef = &consummatedEscrowResourceList as &[PonsEscrowTunnelContract.EscrowResource]

				subConsummation (escrowResourceListRef)

				var giftEscrowResource <- escrowResourceListRef .remove (at: 0)

				destroy consummatedEscrowResourceList

				return <- giftEscrowResource } )

		escrowManagerRef .dismissEscrow (id: nftId.concat("Tunnel-User-Escrow"))
		escrowManagerRef .dismissEscrow (id: nftId.concat("Tunnel-PonsBurner-Escrow"))
		
		let tunnelData = PonsTunnelContract .generateRecieveTunnelEmitData_User(nftRef: nftRef, artistAddressPolygon: nil, flowRecipientAddress: tunnelUserAccount .address);
		emit nftRecievedThroughTunnel_User (data: tunnelData)
	}

	pub fun recieveNftFromTunnelUsingSerialId(nftSerialId: UInt64, ponsAccount: AuthAccount, ponsHolderAccount: AuthAccount, tunnelUserAccount: AuthAccount){
		pre {
			/* ponsHolderAccount.toString() == "": 
				panic("Can only go through tunnel by burning using Pons Burner") */
			
		}

		let nftId = PonsTunnelContract .borrowOwnPonsCollection (collector: ponsHolderAccount) .getNftId(serialId: nftSerialId)!
		let nftRef: &PonsNftContractInterface.NFT = PonsTunnelContract .borrowOwnPonsCollection (collector: ponsHolderAccount) .borrowNft (nftId: nftId)
		

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
			fun (_ escrowResourceListRef: &[PonsEscrowTunnelContract.EscrowResource]): Void {
				escrowManagerRef .consummateEscrow (
					id: nftId.concat("Tunnel-User-Escrow"),
					consummation: fun (_ giftEscrowResource: @PonsEscrowTunnelContract.EscrowResource): @PonsEscrowTunnelContract.EscrowResource {

						var emptyEscrowResource <- escrowResourceListRef .remove (at: 0)

						escrowResourceListRef .insert (at: 0, <- giftEscrowResource)

						return <- emptyEscrowResource } ) }

		escrowManagerRef .consummateEscrow (
			id: nftId.concat("Tunnel-PonsBurner-Escrow"),
			consummation: fun (_ emptyEscrowResource: @PonsEscrowTunnelContract.EscrowResource): @PonsEscrowTunnelContract.EscrowResource {

				var consummatedEscrowResourceList: @[PonsEscrowTunnelContract.EscrowResource] <- [ <- emptyEscrowResource ]

				let escrowResourceListRef = &consummatedEscrowResourceList as &[PonsEscrowTunnelContract.EscrowResource]

				subConsummation (escrowResourceListRef)

				var giftEscrowResource <- escrowResourceListRef .remove (at: 0)

				destroy consummatedEscrowResourceList

				return <- giftEscrowResource } )

		escrowManagerRef .dismissEscrow (id: nftId.concat("Tunnel-User-Escrow"))
		escrowManagerRef .dismissEscrow (id: nftId.concat("Tunnel-PonsBurner-Escrow"))
		
		let tunnelData = PonsTunnelContract .generateRecieveTunnelEmitData_User(nftRef: nftRef, artistAddressPolygon: nil, flowRecipientAddress: tunnelUserAccount .address);
		emit nftRecievedThroughTunnel_User (data: tunnelData)
	}

	// -------------------------------------------------------------------
	// -------------------------------------------------------------------
	// -------------------------------------------------------------------
	// -------------------------------------------------------------------
	
	pub fun sendNftThroughTunnel_Market(nftId: String, ponsAccount: AuthAccount, ponsHolderAccount: AuthAccount){
		pre {
			// Test if NFT is listed in marketPlace
			!(PonsNftMarketContract .ponsMarket .getForSaleIds() .contains(nftId)): panic("Only listed nft can be sent to Polygon Market");
		}

		let nft <- PonsNftMarketContract .ponsMarket .collection .withdrawNft (nftId: nftId)
		let nftRef = & nft as &PonsNftContractInterface.NFT


		let tunnelData = PonsTunnelContract .generateSentTunnelEmitData_Market(nftRef: nftRef, artistAddressPolygon: nil, polygonRecipientAddress: polygonAddress);
		emit nftSubmittedThroughTunnel_Market (data: tunnelData)
		/**
		[*] withdraw nft 
			[*] create nftRef for malleability
			[*] unlist nft
		[] transfer nft to ponsHolderAccount
		[*] emit data
		 */

		
		/* PonsTunnelContract .submitEscrow (
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
			fun (_ escrowResourceListRef: &[PonsEscrowTunnelContract.EscrowResource]): Void {
				escrowManagerRef .consummateEscrow (
					id: nftId.concat("Tunnel-User-Escrow"),
					consummation: fun (_ giftEscrowResource: @PonsEscrowTunnelContract.EscrowResource): @PonsEscrowTunnelContract.EscrowResource {

						var emptyEscrowResource <- escrowResourceListRef .remove (at: 0)

						escrowResourceListRef .insert (at: 0, <- giftEscrowResource)

						return <- emptyEscrowResource } ) }

		escrowManagerRef .consummateEscrow (
			id: nftId.concat("Tunnel-PonsBurner-Escrow"),
			consummation: fun (_ emptyEscrowResource: @PonsEscrowTunnelContract.EscrowResource): @PonsEscrowTunnelContract.EscrowResource {

				var consummatedEscrowResourceList: @[PonsEscrowTunnelContract.EscrowResource] <- [ <- emptyEscrowResource ]

				let escrowResourceListRef = &consummatedEscrowResourceList as &[PonsEscrowTunnelContract.EscrowResource]

				subConsummation (escrowResourceListRef)

				var giftEscrowResource <- escrowResourceListRef .remove (at: 0)

				destroy consummatedEscrowResourceList

				return <- giftEscrowResource } )

		escrowManagerRef .dismissEscrow (id: nftId.concat("Tunnel-User-Escrow"))
		escrowManagerRef .dismissEscrow (id: nftId.concat("Tunnel-PonsBurner-Escrow")) */	

		
	}
	
	/* pub fun sendNftThroughTunnelUsingSerialId_Market(nftSerialId: UInt64, ponsAccount: AuthAccount, ponsHolderAccount: AuthAccount){
		pre {
			/* ponsHolderAccount.toString() == "": 
				panic("Can only go through tunnel by burning using Pons Burner") */
		}

		let nftId = PonsTunnelContract .borrowOwnPonsCollection (collector: tunnelUserAccount) .getNftId (serialId: nftSerialId)!
		let nftRef: &PonsNftContractInterface.NFT = PonsTunnelContract .borrowOwnPonsCollection (collector: tunnelUserAccount) .borrowNft (nftId: nftId)
		
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
			fun (_ escrowResourceListRef: &[PonsEscrowTunnelContract.EscrowResource]): Void {
				escrowManagerRef .consummateEscrow (
					id: nftId.concat("Tunnel-User-Escrow"),
					consummation: fun (_ giftEscrowResource: @PonsEscrowTunnelContract.EscrowResource): @PonsEscrowTunnelContract.EscrowResource {

						var emptyEscrowResource <- escrowResourceListRef .remove (at: 0)

						escrowResourceListRef .insert (at: 0, <- giftEscrowResource)

						return <- emptyEscrowResource } ) }

		escrowManagerRef .consummateEscrow (
			id: nftId.concat("Tunnel-PonsBurner-Escrow"),
			consummation: fun (_ emptyEscrowResource: @PonsEscrowTunnelContract.EscrowResource): @PonsEscrowTunnelContract.EscrowResource {

				var consummatedEscrowResourceList: @[PonsEscrowTunnelContract.EscrowResource] <- [ <- emptyEscrowResource ]

				let escrowResourceListRef = &consummatedEscrowResourceList as &[PonsEscrowTunnelContract.EscrowResource]

				subConsummation (escrowResourceListRef)

				var giftEscrowResource <- escrowResourceListRef .remove (at: 0)

				destroy consummatedEscrowResourceList

				return <- giftEscrowResource } )

		escrowManagerRef .dismissEscrow (id: nftId.concat("Tunnel-User-Escrow"))
		escrowManagerRef .dismissEscrow (id: nftId.concat("Tunnel-PonsBurner-Escrow"))	

		let tunnelData = PonsTunnelContract .generateSentTunnelEmitData_Market(nftRef: nftRef, artistAddressPolygon: nil, polygonRecipientAddress: polygonAddress);
		emit nftSubmittedThroughTunnel_Market (data: tunnelData)
	} */
	
    /* pub fun recieveNftFromTunnel_Market(nftId: String, ponsAccount: AuthAccount, ponsHolderAccount: AuthAccount){
		pre {
			/* ponsHolderAccount.toString() == "": 
				panic("Can only go through tunnel by burning using Pons Burner") */
			
		}

		let nftRef: &PonsNftContractInterface.NFT = PonsTunnelContract .borrowOwnPonsCollection (collector: ponsHolderAccount) .borrowNft (nftId: nftId)
		

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
			fun (_ escrowResourceListRef: &[PonsEscrowTunnelContract.EscrowResource]): Void {
				escrowManagerRef .consummateEscrow (
					id: nftId.concat("Tunnel-User-Escrow"),
					consummation: fun (_ giftEscrowResource: @PonsEscrowTunnelContract.EscrowResource): @PonsEscrowTunnelContract.EscrowResource {

						var emptyEscrowResource <- escrowResourceListRef .remove (at: 0)

						escrowResourceListRef .insert (at: 0, <- giftEscrowResource)

						return <- emptyEscrowResource } ) }

		escrowManagerRef .consummateEscrow (
			id: nftId.concat("Tunnel-PonsBurner-Escrow"),
			consummation: fun (_ emptyEscrowResource: @PonsEscrowTunnelContract.EscrowResource): @PonsEscrowTunnelContract.EscrowResource {

				var consummatedEscrowResourceList: @[PonsEscrowTunnelContract.EscrowResource] <- [ <- emptyEscrowResource ]

				let escrowResourceListRef = &consummatedEscrowResourceList as &[PonsEscrowTunnelContract.EscrowResource]

				subConsummation (escrowResourceListRef)

				var giftEscrowResource <- escrowResourceListRef .remove (at: 0)

				destroy consummatedEscrowResourceList

				return <- giftEscrowResource } )

		escrowManagerRef .dismissEscrow (id: nftId.concat("Tunnel-User-Escrow"))
		escrowManagerRef .dismissEscrow (id: nftId.concat("Tunnel-PonsBurner-Escrow"))
		
		let tunnelData = PonsTunnelContract .generateRecieveTunnelEmitData_Market(nftRef: nftRef, artistAddressPolygon: nil, flowRecipientAddress: tunnelUserAccount .address);
		emit nftRecievedThroughTunnel_Market (data: tunnelData)
	} */

	/* pub fun recieveNftFromTunnelUsingSerialId_Market(nftSerialId: UInt64, ponsAccount: AuthAccount, ponsHolderAccount: AuthAccount){
		pre {
			/* ponsHolderAccount.toString() == "": 
				panic("Can only go through tunnel by burning using Pons Burner") */
			
		}

		let nftId = PonsTunnelContract .borrowOwnPonsCollection (collector: ponsHolderAccount) .getNftId(serialId: nftSerialId)!
		let nftRef: &PonsNftContractInterface.NFT = PonsTunnelContract .borrowOwnPonsCollection (collector: ponsHolderAccount) .borrowNft (nftId: nftId)
		

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
			fun (_ escrowResourceListRef: &[PonsEscrowTunnelContract.EscrowResource]): Void {
				escrowManagerRef .consummateEscrow (
					id: nftId.concat("Tunnel-User-Escrow"),
					consummation: fun (_ giftEscrowResource: @PonsEscrowTunnelContract.EscrowResource): @PonsEscrowTunnelContract.EscrowResource {

						var emptyEscrowResource <- escrowResourceListRef .remove (at: 0)

						escrowResourceListRef .insert (at: 0, <- giftEscrowResource)

						return <- emptyEscrowResource } ) }

		escrowManagerRef .consummateEscrow (
			id: nftId.concat("Tunnel-PonsBurner-Escrow"),
			consummation: fun (_ emptyEscrowResource: @PonsEscrowTunnelContract.EscrowResource): @PonsEscrowTunnelContract.EscrowResource {

				var consummatedEscrowResourceList: @[PonsEscrowTunnelContract.EscrowResource] <- [ <- emptyEscrowResource ]

				let escrowResourceListRef = &consummatedEscrowResourceList as &[PonsEscrowTunnelContract.EscrowResource]

				subConsummation (escrowResourceListRef)

				var giftEscrowResource <- escrowResourceListRef .remove (at: 0)

				destroy consummatedEscrowResourceList

				return <- giftEscrowResource } )

		escrowManagerRef .dismissEscrow (id: nftId.concat("Tunnel-User-Escrow"))
		escrowManagerRef .dismissEscrow (id: nftId.concat("Tunnel-PonsBurner-Escrow"))
		
		let tunnelData = PonsTunnelContract .generateRecieveTunnelEmitData_Market(nftRef: nftRef, artistAddressPolygon: nil, flowRecipientAddress: tunnelUserAccount .address);
		emit nftRecievedThroughTunnel_Market (data: tunnelData)
	} */

}