import NonFungibleToken from 0xNONFUNGIBLETOKEN
import PonsArtistContract from 0xPONS
import PonsNftContractInterface from 0xPONS
import PonsUtils from 0xPONS



/*
	Pons NFT Contract

	This smart contract contains the core functionality of Pons NFTs.
	The contract provides APIs to access useful information of Pons NFTs, and events which signify the creation and movement of Pons NFTs.
	This smart contract serves as the API for users of Pons NFTs, and delegates concrete functionality to another resource which implements contract functionality, so that updates can be made to Pons NFTs in a controlled manner if necessary.
*/
pub contract PonsNftContract {

	/* Standardised storage path for PonsCollection */
	pub let CollectionStoragePath : StoragePath

	/* Total Pons NFTs minted */
	pub var mintedCount : UInt64


	/* PonsNftContractInit is emitted on initialisation of this contract */
	pub event PonsNftContractInit ()

	/* PonsNftMinted is emitted on minting of new Pons NFTs */
	pub event PonsNftMinted (nftId : String, serialNumber : UInt64, artistId : String, royalty : PonsUtils.Ratio, editionLabel : String, metadata : {String: String})

	/* PonsNftWithdrawFromCollection is emitted on withdrawal of Pons NFTs from its colllection */
	pub event PonsNftWithdrawFromCollection (nftId : String, serialNumber : UInt64, from : Address?)
	/* PonsNftWithdrawFromCollection is emitted on depositing of Pons NFTs to a colllection */
	pub event PonsNftDepositToCollection (nftId : String, serialNumber : UInt64, to : Address?)


	/* Allow the PonsNft events to be emitted by implementations of Pons NFTs from the Pons account */
	access(account) fun emitPonsNftMinted (nftId : String, serialNumber : UInt64, artistId : String, royalty : PonsUtils.Ratio, editionLabel : String, metadata : {String: String}) : Void {
		emit PonsNftMinted (nftId: nftId, serialNumber: serialNumber, artistId: artistId, royalty: royalty, editionLabel: editionLabel, metadata: metadata) }

	access(account) fun emitPonsNftWithdrawFromCollection (nftId : String, serialNumber : UInt64, from : Address?) : Void {
		emit PonsNftWithdrawFromCollection (nftId: nftId, serialNumber: serialNumber, from: from) }
	access(account) fun emitPonsNftDepositToCollection (nftId : String, serialNumber : UInt64, to : Address?) : Void {
		emit PonsNftDepositToCollection (nftId: nftId, serialNumber: serialNumber, to: to) }






	/* Takes the next unused UInt64 as the NonFungibleToken.INFT id; which we call serialNumber */
	access(account) fun takeSerialNumber () : UInt64 {
		self .mintedCount = self .mintedCount + UInt64 (1)

		return self .mintedCount }




	/* Gets the nftId of a Pons NFT */
	pub fun getNftId (_ ponsNftRef : &PonsNftContractInterface.NFT) : String {
		return ponsNftRef .nftId }
	
	/* Gets the serialNumber of a Pons NFT */
	pub fun getSerialNumber (_ ponsNftRef : &PonsNftContractInterface.NFT) : UInt64 {
		return ponsNftRef .id }



	/* Borrows the PonsArtist of a Pons NFT */
	pub fun borrowArtist (_ ponsNftRef : &PonsNftContractInterface.NFT) : &PonsArtistContract.PonsArtist {
		return PonsNftContract .implementation .borrowArtist (ponsNftRef) }

	/* Gets the royalty Ratio of a Pons NFT (i.e. how much percentage of resales are royalties to the artist) */
	pub fun getRoyalty (_ ponsNftRef : &PonsNftContractInterface.NFT) : PonsUtils.Ratio {
		return PonsNftContract .implementation .getRoyalty (ponsNftRef) }

	/* Gets the edition label a Pons NFT to differentiate between distinct limited editions */
	pub fun getEditionLabel (_ ponsNftRef : &PonsNftContractInterface.NFT) : String {
		return PonsNftContract .implementation .getEditionLabel (ponsNftRef) }

	/* Gets any other metadata of a Pons NFT (e.g. IPFS media url) */
	pub fun getMetadata (_ ponsNftRef : &PonsNftContractInterface.NFT) : {String: String} {
		return PonsNftContract .implementation .getMetadata (ponsNftRef) }


	/* API for creating new PonsCollection */
	access(account) fun createEmptyPonsCollection () : @PonsNftContractInterface.Collection {
		return <- PonsNftContract .implementation .createEmptyPonsCollection () }




	/* API to ensure an account has a PonsCollection, creating one if it does not exist */
	pub fun acquirePonsCollection (collector : AuthAccount) : Void {
		var collectionOptional <-
			collector .load <@PonsNftContractInterface.Collection>
				( from: PonsNftContract .CollectionStoragePath )

		if collectionOptional == nil {
			destroy collectionOptional
			collector .save (<- PonsNftContract .createEmptyPonsCollection (), to: PonsNftContract .CollectionStoragePath) }
		else {
			collector .save (<- collectionOptional !, to: PonsNftContract .CollectionStoragePath) } }

	/* API to borrow a PonsCollection from an account, creating one if it does not exist */
	pub fun borrowOwnPonsCollection (collector : AuthAccount) : &PonsNftContractInterface.Collection {
		PonsNftContract .acquirePonsCollection (collector: collector)

		return collector .borrow <&PonsNftContractInterface.Collection> (from: PonsNftContract .CollectionStoragePath) ! }

	/* API to borrow a Pons NFT from an account */
	pub fun borrowOwnPonsNft (collector : AuthAccount, nftId : String) : &PonsNftContractInterface.NFT {
		var collectionRef =
			collector .borrow <&PonsNftContractInterface.Collection>
				( from: PonsNftContract .CollectionStoragePath ) !
		return collectionRef .borrowNft (nftId: nftId) }





	/* API to produce an updated Pons NFT from any Pons NFT, so that the Pons contracts can perform any contract updates in a controlled, future-proof manner */
	pub fun updatePonsNft (_ ponsNft : @PonsNftContractInterface.NFT) : @PonsNftContractInterface.NFT {
		return <- PonsNftContract .implementation .updatePonsNft (<- ponsNft) }








/*
	PonsNft implementation resource interface

	This interface defines the concrete functionality that the PonsNft contract delegates.
*/
	pub resource interface PonsNftContractImplementation {
		pub fun borrowArtist (_ ponsNftRef : &PonsNftContractInterface.NFT) : &PonsArtistContract.PonsArtist 
		pub fun getRoyalty (_ ponsNftRef : &PonsNftContractInterface.NFT) : PonsUtils.Ratio 
		pub fun getEditionLabel (_ ponsNftRef : &PonsNftContractInterface.NFT) : String 
		pub fun getMetadata (_ ponsNftRef : &PonsNftContractInterface.NFT) : {String: String} 

		access(account) fun createEmptyPonsCollection () : @PonsNftContractInterface.Collection

		pub fun updatePonsNft (_ ponsNft : @PonsNftContractInterface.NFT) : @PonsNftContractInterface.NFT }

	/* A list recording all previously active instances of PonsNftContractImplementation */
	access(account) var historicalImplementations : @[{PonsNftContractImplementation}]
	/* The currently active instance of PonsNftContractImplementation */
	access(account) var implementation : @{PonsNftContractImplementation}

	/* Updates the currently active PonsNftContractImplementation */
	access(account) fun update (_ newImplementation : @{PonsNftContractImplementation}) : Void {
		var implementation <- newImplementation
		implementation <-> PonsNftContract .implementation
		PonsNftContract .historicalImplementations .append (<- implementation) }



	/* A trivial instance of PonsNftContractImplementation which panics on all calls, used on initialization of the PonsNft contract. */
	pub resource InvalidPonsNftContractImplementation : PonsNftContractImplementation {
		pub fun borrowArtist (_ ponsNftRef : &PonsNftContractInterface.NFT) : &PonsArtistContract.PonsArtist {
			panic ("not implemented") }
		pub fun getRoyalty (_ ponsNftRef : &PonsNftContractInterface.NFT) : PonsUtils.Ratio {
			panic ("not implemented") }
		pub fun getEditionLabel (_ ponsNftRef : &PonsNftContractInterface.NFT) : String {
			panic ("not implemented") }
		pub fun getMetadata (_ ponsNftRef : &PonsNftContractInterface.NFT) : {String: String} {
			panic ("not implemented") }

		access(account) fun createEmptyPonsCollection () : @PonsNftContractInterface.Collection {
			panic ("not implemented") }

		pub fun updatePonsNft (_ ponsNft : @PonsNftContractInterface.NFT) : @PonsNftContractInterface.NFT {
			panic ("not implemented") } }






	init (collectionStoragePath : StoragePath) {
		// Save the standardised Pons collection storage path
		self .CollectionStoragePath = collectionStoragePath

		self .mintedCount = 0

		self .historicalImplementations <- []
		// Activate InvalidPonsNftContractImplementation as the active implementation of the Pons NFT system
		self .implementation <- create InvalidPonsNftContractImplementation ()


		// Emit the PonsNft contract initialisation event
		emit PonsNftContract.PonsNftContractInit () } }
