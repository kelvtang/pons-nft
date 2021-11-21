import NonFungibleToken from 0xNONFUNGIBLETOKEN
import PonsArtistContract from 0xPONS
import PonsNftContractInterface from 0xPONS
import PonsUtils from 0xPONS



pub contract PonsNftContract {

	pub let CollectionStoragePath : StoragePath

	pub var mintedCount : UInt64



	pub event PonsNftContractInit ()

	pub event PonsNftMinted (nftId : String, serialNumber : UInt64, artistId : String, royalty : PonsUtils.Ratio, editionLabel : String, metadata : {String: String})

	pub event PonsNftWithdrawFromCollection (nftId : String, serialNumber : UInt64, from : Address?)
	pub event PonsNftDepositToCollection (nftId : String, serialNumber : UInt64, to : Address?)

	access(account) fun emitPonsNftMinted (nftId : String, serialNumber : UInt64, artistId : String, royalty : PonsUtils.Ratio, editionLabel : String, metadata : {String: String}) : Void {
		emit PonsNftMinted (nftId: nftId, serialNumber: serialNumber, artistId: artistId, royalty: royalty, editionLabel: editionLabel, metadata: metadata) }

	access(account) fun emitPonsNftWithdrawFromCollection (nftId : String, serialNumber : UInt64, from : Address?) : Void {
		emit PonsNftWithdrawFromCollection (nftId: nftId, serialNumber: serialNumber, from: from) }
	access(account) fun emitPonsNftDepositToCollection (nftId : String, serialNumber : UInt64, to : Address?) : Void {
		emit PonsNftDepositToCollection (nftId: nftId, serialNumber: serialNumber, to: to) }






	access(account) fun takeSerialNumber () : UInt64 {
		self .mintedCount = self .mintedCount + UInt64 (1)

		return self .mintedCount }




	pub fun getNftId (_ ponsNft : &PonsNftContractInterface.NFT) : String {
		return ponsNft .nftId }
	
	pub fun getSerialNumber (_ ponsNft : &PonsNftContractInterface.NFT) : UInt64 {
		return ponsNft .id }



	pub fun borrowArtist (_ ponsNft : &PonsNftContractInterface.NFT) : &PonsArtistContract.PonsArtist {
		return PonsNftContract .implementation .borrowArtist (ponsNft) }

	pub fun getRoyalty (_ ponsNft : &PonsNftContractInterface.NFT) : PonsUtils.Ratio {
		return PonsNftContract .implementation .getRoyalty (ponsNft) }

	pub fun getEditionLabel (_ ponsNft : &PonsNftContractInterface.NFT) : String {
		return PonsNftContract .implementation .getEditionLabel (ponsNft) }

	pub fun getMetadata (_ ponsNft : &PonsNftContractInterface.NFT) : {String: String} {
		return PonsNftContract .implementation .getMetadata (ponsNft) }


	access(account) fun createEmptyPonsCollection () : @PonsNftContractInterface.Collection {
		return <- PonsNftContract .implementation .createEmptyPonsCollection () }




	pub fun acquirePonsCollection (collector : AuthAccount) : Void {
		var collectionOptional <-
			collector .load <@PonsNftContractInterface.Collection>
				( from: PonsNftContract .CollectionStoragePath )

		if collectionOptional == nil {
			destroy collectionOptional
			collector .save (<- PonsNftContract .createEmptyPonsCollection (), to: PonsNftContract .CollectionStoragePath) }
		else {
			collector .save (<- collectionOptional !, to: PonsNftContract .CollectionStoragePath) } }

	pub fun borrowOwnPonsCollection (collector : AuthAccount) : &PonsNftContractInterface.Collection {
		PonsNftContract .acquirePonsCollection (collector: collector)

		return collector .borrow <&PonsNftContractInterface.Collection> (from: PonsNftContract .CollectionStoragePath) ! }

	pub fun borrowOwnPonsNft (collector : AuthAccount, nftId : String) : &PonsNftContractInterface.NFT {
		var collectionRef =
			collector .borrow <&PonsNftContractInterface.Collection>
				( from: PonsNftContract .CollectionStoragePath ) !
		return collectionRef .borrowNft (nftId: nftId) }





	pub fun updatePonsNft (_ ponsNft : @PonsNftContractInterface.NFT) : @PonsNftContractInterface.NFT {
		return <- PonsNftContract .implementation .updatePonsNft (<- ponsNft) }








	pub resource interface PonsNftContractImplementation {
		pub fun borrowArtist (_ ponsNft : &PonsNftContractInterface.NFT) : &PonsArtistContract.PonsArtist 
		pub fun getRoyalty (_ ponsNft : &PonsNftContractInterface.NFT) : PonsUtils.Ratio 
		pub fun getEditionLabel (_ ponsNft : &PonsNftContractInterface.NFT) : String 
		pub fun getMetadata (_ ponsNft : &PonsNftContractInterface.NFT) : {String: String} 

		access(account) fun createEmptyPonsCollection () : @PonsNftContractInterface.Collection

		pub fun updatePonsNft (_ ponsNft : @PonsNftContractInterface.NFT) : @PonsNftContractInterface.NFT }

	access(account) var historicalImplementations : @[{PonsNftContractImplementation}]
	access(account) var implementation : @{PonsNftContractImplementation}

	access(account) fun update (_ newImplementation : @{PonsNftContractImplementation}) : Void {
		var implementation <- newImplementation
		implementation <-> PonsNftContract .implementation
		PonsNftContract .historicalImplementations .append (<- implementation) }



	pub resource TrivialPonsNftContractImplementation : PonsNftContractImplementation {
		pub fun borrowArtist (_ ponsNft : &PonsNftContractInterface.NFT) : &PonsArtistContract.PonsArtist {
			panic ("not implemented") }
		pub fun getRoyalty (_ ponsNft : &PonsNftContractInterface.NFT) : PonsUtils.Ratio {
			panic ("not implemented") }
		pub fun getEditionLabel (_ ponsNft : &PonsNftContractInterface.NFT) : String {
			panic ("not implemented") }
		pub fun getMetadata (_ ponsNft : &PonsNftContractInterface.NFT) : {String: String} {
			panic ("not implemented") }

		access(account) fun createEmptyPonsCollection () : @PonsNftContractInterface.Collection {
			panic ("not implemented") }

		pub fun updatePonsNft (_ ponsNft : @PonsNftContractInterface.NFT) : @PonsNftContractInterface.NFT {
			panic ("not implemented") } }






	init (collectionStoragePath : StoragePath) {
		self .CollectionStoragePath = collectionStoragePath // /storage/ponsCollection

		self .mintedCount = 0

		self .historicalImplementations <- []
		self .implementation <- create TrivialPonsNftContractImplementation ()


		emit PonsNftContract.PonsNftContractInit () } }
