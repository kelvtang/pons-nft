import FungibleToken from 0xFUNGIBLETOKEN

pub contract PonsArtistContract {

	access(account) let artistAuthorityStoragePath : StoragePath

	access(account) var ponsArtists : @{String: PonsArtist}
	access(account) var ponsArtistIds : {Address: String}
	access(account) var addresses : {String: Address}
	access(account) var metadatas : {String: {String: String}}
	access(account) var receivePaymentCaps : {String: Capability<&{FungibleToken.Receiver}>}

	pub resource PonsArtist {
		pub let ponsArtistId : String

		init (ponsArtistId : String) {
			self .ponsArtistId = ponsArtistId } }

	pub resource PonsArtistCertificate {
		pub let ponsArtistId : String

		init (ponsArtistId : String) {
			pre {
				PonsArtistContract .ponsArtists .containsKey (ponsArtistId):
					"Not recognised Pons Artist" }

			self .ponsArtistId = ponsArtistId } }


	pub fun borrowArtist (ponsArtistId : String) : &PonsArtist {
		var ponsArtist <- PonsArtistContract .ponsArtists .remove (key: ponsArtistId) !
		let ponsArtistRef = & ponsArtist as &PonsArtist
		var replacedArtistOptional <- PonsArtistContract .ponsArtists .insert (key: ponsArtistId, <- ponsArtist) 
		destroy replacedArtistOptional
		return ponsArtistRef }


	pub fun getAddress (_ ponsArtist : &PonsArtist) : Address? {
		return PonsArtistContract .addresses [ponsArtist .ponsArtistId] }

	pub fun getMetadata (_ ponsArtist : &PonsArtist) : {String: String} {
		return PonsArtistContract .metadatas [ponsArtist .ponsArtistId] ! }

	pub fun getReceivePaymentCap (_ ponsArtist : &PonsArtist) : Capability<&{FungibleToken.Receiver}> {
		return PonsArtistContract .receivePaymentCaps [ponsArtist .ponsArtistId] ! }







	pub fun makePonsArtistCertificate (artistAccount : AuthAccount) : @PonsArtistCertificate {
		pre {
			PonsArtistContract .ponsArtistIds .containsKey (artistAccount .address):
				"No artist is known to have this address" }
		let ponsArtistId = PonsArtistContract .ponsArtistIds [artistAccount .address] !
		return <- create PonsArtistCertificate (ponsArtistId: ponsArtistId) }




	pub resource PonsArtistAuthority {
		pub fun borrowPonsArtists () : &{String: PonsArtist} {
			return & PonsArtistContract .ponsArtists as &{String: PonsArtist} }

		pub fun getPonsArtistIds () : {Address: String} {
			return PonsArtistContract .ponsArtistIds }
		pub fun setPonsArtistIds (_ ponsArtistIds :  {Address: String}) : Void {
			PonsArtistContract .ponsArtistIds = ponsArtistIds }

		pub fun getAddresses () : {String: Address} {
			return PonsArtistContract .addresses }
		pub fun setAddresses (_ addresses : {String: Address}) : Void {
			PonsArtistContract .addresses = addresses }

		pub fun getMetadatas () : {String: {String: String}} {
			return PonsArtistContract .metadatas }
		pub fun setMetadatas (_ metadatas : {String: {String: String}}) : Void {
			PonsArtistContract .metadatas = metadatas }

		pub fun getReceivePaymentCaps () : {String: Capability<&{FungibleToken.Receiver}>} {
			return PonsArtistContract .receivePaymentCaps }
		pub fun setReceivePaymentCaps (_ receivePaymentCaps : {String: Capability<&{FungibleToken.Receiver}>}) : Void {
			PonsArtistContract .receivePaymentCaps = receivePaymentCaps }

		pub fun recognisePonsArtist
		( ponsArtistId : String
		, _ addressOptional : Address?
		, metadata : {String: String}
		, receivePaymentCap : Capability<&{FungibleToken.Receiver}>
		) : Void {
			pre {
				! PonsArtistContract .ponsArtists .containsKey (ponsArtistId):
					"Pons Artist with this ponsArtistId already exists" }
			post {
				PonsArtistContract .ponsArtists .containsKey (ponsArtistId):
					"Unable to recognise Pons Artist" }

			var ponsArtist <- create PonsArtist (ponsArtistId: ponsArtistId)

			var replacedArtistOptional <- PonsArtistContract .ponsArtists .insert (key: ponsArtistId, <- ponsArtist)
			if replacedArtistOptional != nil {
				panic ("Pons Artist with this ponsArtistId Already exists") }
			destroy replacedArtistOptional

			if addressOptional != nil {
				PonsArtistContract .ponsArtistIds .insert (key: addressOptional !, ponsArtistId)
				PonsArtistContract .addresses .insert (key: ponsArtistId, addressOptional !) }

			PonsArtistContract .metadatas .insert (key: ponsArtistId, metadata)
			PonsArtistContract .receivePaymentCaps .insert (key: ponsArtistId, receivePaymentCap) }

		pub fun makePonsArtistCertificateFromArtistRef (_ ponsArtistRef : &PonsArtist) : @PonsArtistCertificate {
			return <- create PonsArtistCertificate (ponsArtistId: ponsArtistRef .ponsArtistId) }

		pub fun makePonsArtistCertificateFromId (ponsArtistId : String) : @PonsArtistCertificate {
			return <- create PonsArtistCertificate (ponsArtistId: ponsArtistId) } }





	init (artistAuthorityStoragePath : StoragePath) {
		self .artistAuthorityStoragePath = artistAuthorityStoragePath
		self .ponsArtists <- {}
		self .ponsArtistIds = {}
		self .addresses = {}
		self .metadatas = {}
		self .receivePaymentCaps = {}

        	self .account .save (<- create PonsArtistAuthority (), to: artistAuthorityStoragePath) } }
