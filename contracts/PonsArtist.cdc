import FungibleToken from 0xFUNGIBLETOKEN

pub contract PonsArtistContract {

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
					"" }

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



	access(account) fun recognisePonsArtist
	( ponsArtistId : String
	, _ addressOptional : Address?
	, metadata : {String: String}
	, receivePaymentCap : Capability<&{FungibleToken.Receiver}>
	) : Void {
		pre {
			! PonsArtistContract .ponsArtists .containsKey (ponsArtistId):
				"Already exists" }
		post {
			PonsArtistContract .ponsArtists .containsKey (ponsArtistId):
				"did not recognize?" }

		var ponsArtist <- create PonsArtist (ponsArtistId: ponsArtistId)

		var replacedArtistOptional <- PonsArtistContract .ponsArtists .insert (key: ponsArtistId, <- ponsArtist)
		if replacedArtistOptional != nil {
			panic ("") }
		destroy replacedArtistOptional

		if addressOptional != nil {
			PonsArtistContract .ponsArtistIds .insert (key: addressOptional !, ponsArtistId)
			PonsArtistContract .addresses .insert (key: ponsArtistId, addressOptional !) }

		PonsArtistContract .metadatas .insert (key: ponsArtistId, metadata)
		PonsArtistContract .receivePaymentCaps .insert (key: ponsArtistId, receivePaymentCap) }




	pub fun makePonsArtistCertificate (artistAccount : AuthAccount) : @PonsArtistCertificate {
		let ponsArtistId = PonsArtistContract .ponsArtistIds [artistAccount .address] !
		return <- create PonsArtistCertificate (ponsArtistId: ponsArtistId) }

	access(account) fun makePonsArtistCertificateFromArtistRef (ponsArtistRef : &PonsArtist) : @PonsArtistCertificate {
		return <- create PonsArtistCertificate (ponsArtistId: ponsArtistRef .ponsArtistId) }

	access(account) fun makePonsArtistCertificateFromId (ponsArtistId : String) : @PonsArtistCertificate {
		return <- create PonsArtistCertificate (ponsArtistId: ponsArtistId) }




	init () {
		self .ponsArtists <- {}
		self .ponsArtistIds = {}
		self .addresses = {}
		self .metadatas = {}
		self .receivePaymentCaps = {} } }
