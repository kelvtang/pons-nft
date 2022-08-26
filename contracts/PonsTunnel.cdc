import FungibleToken from 0xFUNGIBLETOKEN
import NonFungibleToken from 0xNONFUNGIBLETOKEN
import FlowToken from 0xFLOWTOKEN
import FUSD from 0xFUSD
import PonsNftContractInterface from 0xPONS
import PonsNftContract from 0xPONS
import PonsNftMarketContract from 0xPONS
import PonsUtils from 0xPONS

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
			self .artistAddressPolygon = artistAddressPolygon;}

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
			self .artistAddressPolygon = artistAddressPolygon;}

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
			self .flowRecipientAddress = flowRecipientAddress}}

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
			self .flowRecipientAddress = flowRecipientAddress}}

	// Holds the polygon address of PonsNftMarket.sol
	access(self) var polygonMarketAddress: String

	access(account) fun setPolygonMarketAddress(_polygonMarketAddress: String):Void{
		PonsTunnelContract .polygonMarketAddress = _polygonMarketAddress}
	pub fun getPolygonMarketAddress():String{
		return PonsTunnelContract .polygonMarketAddress}

	// add lister address for market send
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
			nftEmitData .setArtistAddressPolygon (artistAddressPolygon: artistAddressPolygon!)}

		let sentData: PonsTunnelContract.sentTunnelData_Market = PonsTunnelContract .sentTunnelData_Market(polygonRecipientAddress: polygonRecipientAddress, nft: nftEmitData)

		return sentData}
	access(self) fun generateRecieveTunnelEmitData_Market(nftRef: &PonsNftContractInterface.NFT, artistAddressPolygon: String?, flowRecipientAddress: Address): PonsTunnelContract.recieveTunnelData_Market{
		let nftEmitData: PonsTunnelContract.nftDetails_Market = PonsTunnelContract .generateNftEmitData_Market(nftRef: nftRef)

		if artistAddressPolygon != nil { 
			nftEmitData .setArtistAddressPolygon (artistAddressPolygon: artistAddressPolygon!)}

		let recievedData: PonsTunnelContract.recieveTunnelData_Market = PonsTunnelContract .recieveTunnelData_Market(flowRecipientAddress: flowRecipientAddress, nft: nftEmitData)
		return recievedData}

	access(self) fun generateNftEmitData_User(nftRef: &PonsNftContractInterface.NFT): PonsTunnelContract.nftDetails_User{
		let artistAddressFlow: Address = PonsNftContract .getArtistAddress (PonsNftContract .borrowArtistById (ponsArtistId: PonsNftContract .implementation .getArtistIdFromId(nftRef .nftId)))!;
		let royalty: UFix64 = PonsNftContract .getRoyalty(nftRef) .amount;

		let nftEmitData: PonsTunnelContract.nftDetails_User = PonsTunnelContract .nftDetails_User(nftId: nftRef .nftId, nftSerialId: nftRef .id, metdata: PonsNftContract .getMetadata(nftRef), artistAddressFlow: artistAddressFlow, royalty: royalty);
		return nftEmitData;}

	access(self) fun generateSentTunnelEmitData_User(nftRef: &PonsNftContractInterface.NFT, artistAddressPolygon: String?, polygonRecipientAddress: String): PonsTunnelContract.sentTunnelData_User{
		let nftEmitData: PonsTunnelContract.nftDetails_User = PonsTunnelContract .generateNftEmitData_User(nftRef: nftRef)

		if artistAddressPolygon != nil { 
			nftEmitData .setArtistAddressPolygon (artistAddressPolygon: artistAddressPolygon!)}

		let sentData: PonsTunnelContract.sentTunnelData_User = PonsTunnelContract .sentTunnelData_User(polygonRecipientAddress: polygonRecipientAddress, nft: nftEmitData)

		return sentData}
	access(self) fun generateRecieveTunnelEmitData_User(nftRef: &PonsNftContractInterface.NFT, artistAddressPolygon: String?, flowRecipientAddress: Address): PonsTunnelContract.recieveTunnelData_User{
		let nftEmitData: PonsTunnelContract.nftDetails_User = PonsTunnelContract .generateNftEmitData_User(nftRef: nftRef)

		if artistAddressPolygon != nil { 
			nftEmitData .setArtistAddressPolygon (artistAddressPolygon: artistAddressPolygon!)}

		let recievedData: PonsTunnelContract.recieveTunnelData_User = PonsTunnelContract .recieveTunnelData_User(flowRecipientAddress: flowRecipientAddress, nft: nftEmitData)
		return recievedData}
		




	/* Creates FUSD Vaults and Capabilities in the standard locations if they do not exist, and returns a capability to send FUSD tokens to the account */
	pub fun prepareCapabilityForPolygonLister (account: AuthAccount, polygonAddress:String): [Capability<&{FungibleToken.Receiver}>;2] {
		
		let uniqPathPrefix:String = "polygon".concat(polygonAddress);
		let storagePathFusd:StoragePath = StoragePath(identifier: uniqPathPrefix.concat("fusdVault"))!;
		let storagePathFlow:StoragePath = StoragePath(identifier: uniqPathPrefix.concat("flowTokenVault"))!;

		if account .borrow <&FUSD.Vault> (from: storagePathFusd) == nil {
			account .save (<- FUSD .createEmptyVault (), to: storagePathFusd) }

		if ! account .getCapability <&FUSD.Vault{FungibleToken.Receiver}> (PublicPath(identifier: uniqPathPrefix.concat("fusdReceiver"))!) .check () {
			account .link <&FUSD.Vault{FungibleToken.Receiver}> (
				PublicPath(identifier: uniqPathPrefix.concat("fusdReceiver"))!,
				target: storagePathFusd ) }

		if ! account .getCapability <&FUSD.Vault{FungibleToken.Balance}> (PublicPath(identifier: uniqPathPrefix.concat("fusdBalance"))!) .check () {
			// Create a public capability to the Vault that only exposes
			// the balance field through the Balance interface
			account .link <&FUSD.Vault{FungibleToken.Balance}> (
				PublicPath(identifier: uniqPathPrefix.concat("fusdBalance"))!,
				target: storagePathFusd ) }

		if account .borrow <&FlowToken.Vault> (from: storagePathFlow) == nil {
			account .save (<- FlowToken .createEmptyVault (), to: storagePathFlow) }

		if ! account .getCapability <&FlowToken.Vault{FungibleToken.Receiver}> (PublicPath(identifier: uniqPathPrefix.concat("flowTokenReceiver"))!) .check () {
			account .link <&FlowToken.Vault{FungibleToken.Receiver}> (
				PublicPath(identifier: uniqPathPrefix.concat("flowTokenReceiver"))!,
				target: storagePathFlow ) }

		if ! account .getCapability <&FlowToken.Vault{FungibleToken.Balance}> (PublicPath(identifier: uniqPathPrefix.concat("flowTokenBalance"))!) .check () {
			// Create a public capability to the Vault that only exposes
			// the balance field through the Balance interface
			account .link <&FlowToken.Vault{FungibleToken.Balance}> (
				PublicPath(identifier: uniqPathPrefix.concat("flowTokenBalance"))!,
				target: storagePathFlow ) }

		return [
			account .getCapability <&{FungibleToken.Receiver}> (PublicPath(identifier: uniqPathPrefix.concat("flowTokenReceiver"))!), 
			account .getCapability <&{FungibleToken.Receiver}> (PublicPath(identifier: uniqPathPrefix.concat("fusdReceiver"))!)
			]}



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

		return account .getCapability <&{FungibleToken.Receiver}> (/public/fusdReceiver)}

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
		return collector .borrow <&PonsNftContractInterface.Collection> (from: PonsNftContract .CollectionStoragePath) !}



	pub fun getNftSerialId (nftId: String, collector: AuthAccount) : UInt64{
		let serialId = PonsTunnelContract .borrowOwnPonsCollection(collector: collector) .getNftSerialId (nftId: nftId);
		if serialId == nil{
			panic("Serial Id of this nft not found");}
		return serialId!;}
	


	access(self) var escrow : @{Address: {UInt64: PonsNftContractInterface.NFT}};
	pub event user_tunnel_submission(nftSerialId: UInt64, userAddress: Address);
	pub event user_tunnel_retrieval(nftSerialId: UInt64, userAddress: Address);

	/* 
	Called by user and signed by ponsHolderAccount to transfer nft through tunnel.
	*/
	pub fun sendNftThroughTunnel (nftSerialId: UInt64, ponsHolderAccount: AuthAccount, userAccount: AuthAccount, polygonAddress: String){

		let nft <- PonsTunnelContract .borrowOwnPonsCollection (collector: userAccount) .withdrawNft (nftId : PonsTunnelContract .borrowOwnPonsCollection (collector: userAccount) .getNftId(serialId: nftSerialId)!);
		let nftRef = & nft as &PonsNftContractInterface.NFT
		PonsTunnelContract .borrowOwnPonsCollection (collector: ponsHolderAccount) .depositNft (<- nft);

		emit user_tunnel_submission(nftSerialId: nftSerialId, userAddress: userAccount.address)

		let tunnelEmitData = PonsTunnelContract .generateSentTunnelEmitData_User(nftRef: nftRef, artistAddressPolygon:"", polygonRecipientAddress: polygonAddress);
		emit nftSubmittedThroughTunnel_User(data: tunnelEmitData);}

	/* 
		Nft withdrawal from tunnel is a two step process, 
			1. First the server calls "recieveNftFromTunnel" using transaction "FlowPolygonBridge/transactions/gettingUserTransfer_server.cdc"
				* This allows the server to withdraw nft from pons holder account and store it in escrow.
			2. User then signs transaction "FlowPolygonBridge/transactions/gettingUserTransfer_user.cdc" and calls it to withdraw his nft from escrow via the function "withdrawFromTunnel".
	*/
	/* 
	Called by ponsHolderAccount to store nft in esrcow
	 */
	pub fun recieveNftFromTunnel (nftSerialId: UInt64, ponsHolderAccount: AuthAccount, userAddress: Address):Void{
		let nft <- PonsTunnelContract .borrowOwnPonsCollection (collector: ponsHolderAccount) .withdrawNft (nftId : PonsTunnelContract .borrowOwnPonsCollection (collector: ponsHolderAccount) .getNftId(serialId: nftSerialId)!);
		let nftRef = & nft as &PonsNftContractInterface.NFT
		
		if self .escrow[userAddress] == nil{
			let des <- self .escrow .insert(key: userAddress, <- {});
			destroy des;}

		let tmp <- self .escrow .remove(key: userAddress)!;
		let des1 <- tmp .insert(key: nftSerialId, <-nft);
		destroy des1;
		let des2 <- self .escrow .insert(key: userAddress, <- tmp!);
		destroy des2;

		let tunnelEmitData = PonsTunnelContract .generateRecieveTunnelEmitData_User(nftRef: nftRef, artistAddressPolygon:"", flowRecipientAddress: userAddress);
		emit nftRecievedThroughTunnel_User(data: tunnelEmitData);}
	/* 
	Called by User (recipient) to withdraw nft held in escrow.
	 */
	pub fun withdrawFromTunnel (nftSerialId: UInt64, userAccount: AuthAccount): @PonsNftContractInterface.NFT?{

		if self .escrow[userAccount.address] == nil{
			return nil;
		}else{
			var tmp <- self .escrow .remove(key: userAccount.address)!;
			if tmp[nftSerialId] == nil{
				let des <- self .escrow .insert(key: userAccount.address, <-tmp!);
				destroy des;
				return nil;
			}else{
				let nft:@PonsNftContractInterface.NFT <- tmp .remove(key: nftSerialId)!;
				let des <- self .escrow .insert(key: userAccount.address, <- tmp);
				destroy des;
				emit user_tunnel_retrieval(nftSerialId: nftSerialId, userAddress: userAccount.address);
				return <- nft;}}}







	// -------------------------------------------------------------------
	// -------------------------------------------------------------------
	// -------------------------------------------------------------------
	// -------------------------------------------------------------------
	
	pub fun sendNftThroughTunnel_market (nftSerialId: UInt64, ponsAccount: AuthAccount, ponsHolderAccount: AuthAccount){
		
		let nftId = PonsTunnelContract .borrowOwnPonsCollection (collector: ponsAccount) .getNftId (serialId: nftSerialId)!
		let nftRef = PonsNftMarketContract .borrowNft (nftId: nftId);
		if nftRef == nil{
			panic("Pons NFT with this nftId is not available on the market");}
		let tunnelData = PonsTunnelContract .generateSentTunnelEmitData_Market(nftRef: nftRef!, artistAddressPolygon: nil, polygonRecipientAddress: PonsTunnelContract .polygonMarketAddress);
		
		let nft <- PonsNftMarketContract .ponsMarket .unlist_onlyParameters(nftId: nftId);
		
		PonsTunnelContract .borrowOwnPonsCollection (collector: ponsHolderAccount) .depositNft (<- nft);

		emit nftSubmittedThroughTunnel_Market (data: tunnelData)}

	pub fun recieveNftFromTunnel_market_flow (nftSerialId: UInt64, ponsAccount: AuthAccount, ponsHolderAccount: AuthAccount, polygonListingAddress: String, salePrice: UFix64){

		let salePriceFlow = PonsUtils .FlowUnits(flowAmount: salePrice);

		let nftId = PonsTunnelContract .borrowOwnPonsCollection (collector: ponsHolderAccount) .getNftId(serialId: nftSerialId)!
		let nft <- PonsTunnelContract .borrowOwnPonsCollection (collector: ponsHolderAccount) .withdrawNft (nftId : nftId);
		let paymentCapability = PonsTunnelContract .prepareCapabilityForPolygonLister(account: ponsAccount, polygonAddress: polygonListingAddress);
		let listingCertificate <- PonsNftMarketContract .ponsMarket .listForSaleFlow(<-nft, salePriceFlow, paymentCapability[0])
		PonsNftMarketContract .ponsMarket .setPolygonListingCertificate(nftSerialId: nftSerialId, polygonAddress: polygonListingAddress, listingCertificate: <-listingCertificate);}
	pub fun recieveNftFromTunnel_market_fusd (nftSerialId: UInt64, ponsAccount: AuthAccount, ponsHolderAccount: AuthAccount, polygonListingAddress: String, salePrice: UFix64){

		let salePriceFUSD = PonsUtils .FusdUnits(fusdAmount: salePrice);
		
		let nftId = PonsTunnelContract .borrowOwnPonsCollection (collector: ponsHolderAccount) .getNftId(serialId: nftSerialId)!
		let nft <- PonsTunnelContract .borrowOwnPonsCollection (collector: ponsHolderAccount) .withdrawNft (nftId : nftId);
		let paymentCapability = PonsTunnelContract .prepareCapabilityForPolygonLister(account: ponsAccount, polygonAddress: polygonListingAddress);
		let listingCertificate <- PonsNftMarketContract .ponsMarket .listForSaleFusd(<-nft, salePriceFUSD, paymentCapability[1]);
		PonsNftMarketContract .ponsMarket .setPolygonListingCertificate(nftSerialId: nftSerialId, polygonAddress: polygonListingAddress, listingCertificate: <-listingCertificate);}

	init(){
		self .polygonMarketAddress = "";
		self .escrow <- {};}
}