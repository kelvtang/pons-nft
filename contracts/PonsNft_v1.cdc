import NonFungibleToken from 0xNONFUNGIBLETOKEN
import PonsCertificationContract from 0xPONS
import PonsArtistContract from 0xPONS
import PonsNftContractInterface from 0xPONS
import PonsNftContract from 0xPONS
import PonsUtils from 0xPONS



pub contract PonsNftContract_v1 : PonsNftContractInterface, NonFungibleToken {

	access(account) let PonsNft_v1_Address : Address
	access(account) let MinterStoragePath : StoragePath
	access(account) let MinterCapability : Capability<&NftMinter_v1>

	pub event PonsNftContractInit_v1 ()

	pub event ContractInitialized ()
	pub event Withdraw (id : UInt64, from : Address?)
	pub event Deposit (id : UInt64, to : Address?)




	pub var totalSupply : UInt64

	access(account) var ponsNftSerialNumbers : {String: UInt64}
	access(account) var ponsNftIds : {UInt64: String}
	access(account) var ponsNftArtistIds : {String: String}
	access(account) var ponsNftRoyalties : {String: PonsUtils.Ratio}
	access(account) var ponsNftEditionLabels : {String: String}
	access(account) var ponsNftMetadatas : {String: {String: String}}


	pub resource NFT : PonsNftContractInterface.PonsNft, NonFungibleToken.INFT {
		pub let ponsCertification : @PonsCertificationContract.PonsCertification
		pub let nftId : String
		pub let id : UInt64

		init (nftId : String, serialNumber : UInt64) {
			pre {
				! PonsNftContract_v1 .ponsNftSerialNumbers .containsKey (nftId): 
					""
				! PonsNftContract_v1 .ponsNftIds .containsKey (serialNumber): 
					"" }
			post {
				PonsNftContract_v1 .ponsNftSerialNumbers .containsKey (nftId): 
					""
				PonsNftContract_v1 .ponsNftIds .containsKey (serialNumber): 
					"" }

			self .ponsCertification <- PonsCertificationContract .makePonsCertification ()
			self .nftId = nftId
			self .id = serialNumber

			PonsNftContract_v1 .ponsNftSerialNumbers .insert (key: nftId, serialNumber)
			PonsNftContract_v1 .ponsNftIds .insert (key: serialNumber, nftId) }

		destroy () {
			destroy self .ponsCertification } }

	pub resource Collection : PonsNftContractInterface.PonsCollection, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic {
		pub let ponsCertification : @PonsCertificationContract.PonsCertification
		pub var ownedNFTs : @{UInt64: NonFungibleToken.NFT}


		pub fun withdrawNft (nftId : String) : @PonsNftContractInterface.NFT {
			pre {
				self .ownedNFTs .containsKey (PonsNftContract_v1 .ponsNftSerialNumbers [nftId] !):
					"" }
			post {
				! self .ownedNFTs .containsKey (PonsNftContract_v1 .ponsNftSerialNumbers [nftId] !):
					"" 
				result .nftId == nftId:
					"" }

			let serialNumber = PonsNftContract_v1 .ponsNftSerialNumbers [nftId] !
			var ponsNft : @PonsNftContractInterface.NFT <-
				(self .ownedNFTs .remove (key: serialNumber) ! as! @PonsNftContractInterface.NFT)

			emit Withdraw (id: serialNumber, from: self .owner ?.address)
            		PonsNftContract .emitPonsNftWithdrawFromCollection (nftId: nftId, serialNumber: ponsNft .id, from: self .owner ?.address)

			return <- PonsNftContract .updatePonsNft (<- ponsNft) }

		pub fun depositNft (_ ponsNft : @PonsNftContractInterface.NFT) : Void {
			pre {
				! self .ownedNFTs .containsKey (PonsNftContract_v1 .ponsNftSerialNumbers [ponsNft .nftId] !):
					"" }
			/*post {
				self .ownedNFTs .containsKey (PonsNftContract_v1 .ponsNftSerialNumbers [before (ponsNft .nftId)] !):
					"" }*/

			let nftId = ponsNft .nftId
			let serialNumber = ponsNft .id
			var nft <- ponsNft as! @NonFungibleToken.NFT
			var replacedTokenOptional <-
				self .ownedNFTs .insert (key: serialNumber, <- nft)
			if replacedTokenOptional != nil {
				panic ("Aborting transaction due to conflict with another token") }
			destroy replacedTokenOptional

			emit Deposit (id: serialNumber, to: self .owner ?.address)
            		PonsNftContract .emitPonsNftDepositToCollection (nftId: nftId, serialNumber: serialNumber, to: self .owner ?.address) }

		pub fun getNftIds () : [String] {
			let serialNumbers = self .ownedNFTs .keys
			var nftIds : [String] = []
			var index = 0
			while index < serialNumbers .length {
				let serialNumber = serialNumbers [index] !
				let nftId = PonsNftContract_v1 .ponsNftIds [serialNumber] !
				nftIds .append (nftId)
				index = index + 1 }
			return nftIds }

		pub fun borrowNft (nftId : String) : &PonsNftContractInterface.NFT {
			post {
				result .id != serialNumber:
					"" }
			let serialNumber = PonsNftContract_v1 .ponsNftSerialNumbers [nftId] !
			let nftRef = & self .ownedNFTs [serialNumber] as auth &NonFungibleToken.NFT
			let ponsNftRef = nftRef as! &PonsNftContractInterface.NFT
            		return ponsNftRef }



		pub fun withdraw (withdrawID : UInt64) : @NonFungibleToken.NFT {
			let nftId = PonsNftContract_v1 .ponsNftIds [withdrawID] !
			var nft <- self .withdrawNft (nftId: nftId) as! @NonFungibleToken.NFT
			return <- nft }

		pub fun deposit (token : @NonFungibleToken.NFT) : Void {
			var nft <- token as! @PonsNftContractInterface.NFT
			self .depositNft (<- nft) }

		pub fun getIDs () : [UInt64] {
			return self .ownedNFTs .keys }

		pub fun borrowNFT (id : UInt64) : &NonFungibleToken.NFT {
			let serialNumber = id
			let nftRef = & self .ownedNFTs [serialNumber] as &NonFungibleToken.NFT
			return nftRef }



		init () {
			self .ponsCertification <- PonsCertificationContract .makePonsCertification ()
			self .ownedNFTs <- {} }

		destroy () {
			if self .owner ?.address != PonsNftContract_v1 .PonsNft_v1_Address {
				panic ("Pons Collections cannot be destroyed") }

			destroy self .ponsCertification
			destroy self .ownedNFTs } }

	pub fun createEmptyCollection () : @Collection {
		return <- create Collection () }




	pub resource NftMinter_v1 {
		access(account) var nftIds : [String]

		pub fun mintNft
		( _ artistCertificate : &PonsArtistContract.PonsArtistCertificate
		, royalty : PonsUtils.Ratio
		, editionLabel : String
		, metadata : {String: String}
		) : @PonsNftContractInterface.NFT {
			let nftId = self .nftIds .remove (at: 0) !
			let serialNumber = PonsNftContract .takeSerialNumber ()

			var nft <- create NFT (nftId: nftId, serialNumber: serialNumber)
			let nftRef = & nft as &PonsNftContractInterface.NFT

			PonsNftContract_v1 .ponsNftArtistIds .insert (key: nftId, artistCertificate .ponsArtistId)
			PonsNftContract_v1 .ponsNftRoyalties .insert (key: nftId, royalty)
			PonsNftContract_v1 .ponsNftEditionLabels .insert (key: nftId, editionLabel)
			PonsNftContract_v1 .ponsNftMetadatas .insert (key: nftId, metadata)


			PonsNftContract_v1 .totalSupply = PonsNftContract_v1 .totalSupply + UInt64 (1)

			PonsNftContract .emitPonsNftMinted (
				nftId: nft .nftId,
				serialNumber: nft .id,
				artistId: PonsNftContract .borrowArtist (nftRef) .ponsArtistId,
				royalty : PonsNftContract .getRoyalty (nftRef),
				editionLabel : PonsNftContract .getEditionLabel (nftRef),
				metadata : PonsNftContract .getMetadata (nftRef) )

			return <- nft }

		init () {
			self .nftIds = [] } }




	pub resource PonsNftContractImplementation_v1 : PonsNftContract.PonsNftContractImplementation {
		pub fun borrowArtist (_ ponsNft : &PonsNftContractInterface.NFT) : &PonsArtistContract.PonsArtist {
			let ponsArtistId = PonsNftContract_v1 .ponsNftArtistIds [ponsNft .nftId] !
			return PonsArtistContract .borrowArtist (ponsArtistId: ponsArtistId) }
		pub fun getRoyalty (_ ponsNft : &PonsNftContractInterface.NFT) : PonsUtils.Ratio {
			return PonsNftContract_v1 .ponsNftRoyalties [ponsNft .nftId] ! }
		pub fun getEditionLabel (_ ponsNft : &PonsNftContractInterface.NFT) : String {
			return PonsNftContract_v1 .ponsNftEditionLabels [ponsNft .nftId] ! }
		pub fun getMetadata (_ ponsNft : &PonsNftContractInterface.NFT) : {String: String} {
			return PonsNftContract_v1 .ponsNftMetadatas [ponsNft .nftId] ! }

		access(account) fun createEmptyPonsCollection () : @PonsNftContractInterface.Collection {
			return <- create Collection () }

		pub fun updatePonsNft (_ ponsNft : @PonsNftContractInterface.NFT) : @PonsNftContractInterface.NFT {
			return <- ponsNft } }


	

	init (minterStoragePath : StoragePath, minterCapabilityPath : CapabilityPath) {
		// let minterStoragePath = /storage/ponsMinter
		// let minterCapabilityPath = /private/ponsMinter
		self .PonsNft_v1_Address = self .account .address
		self .MinterStoragePath = minterStoragePath

		self .totalSupply = 0

		self .ponsNftSerialNumbers = {}
		self .ponsNftIds = {}
		self .ponsNftArtistIds = {}
		self .ponsNftRoyalties = {}
		self .ponsNftEditionLabels = {}
		self .ponsNftMetadatas = {}

        	self .account .save (<- create NftMinter_v1 (), to: minterStoragePath)

		self .MinterCapability = self .account .link <&NftMinter_v1> (minterCapabilityPath, target: minterStoragePath) !

		PonsNftContract .update (<- create PonsNftContractImplementation_v1 ())

		emit ContractInitialized ()
		emit PonsNftContractInit_v1 () } }
