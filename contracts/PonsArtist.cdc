import FungibleToken from 0xFUNGIBLETOKEN

/*
	Pons Artist Contract

	This smart contract contains the definitions for Pons Artists.
*/

pub contract PonsArtistContract {

	/* Standardised storage path for PonsArtistAuthority */
	access(account) let artistAuthorityStoragePath : StoragePath


	/* Stores the resource instance to all PonsArtists */
	access(account) var ponsArtists : @{String: PonsArtist}

	/* Stores the ponsArtistId corresponding to each Address */
	access(account) var ponsArtistIds : {Address: String}

	/* Stores the Address corresponding to each ponsArtistId */
	access(account) var addresses : {String: Address}
	
	/* Stores the metadata of each PonsArtist */
	access(account) var metadatas : {String: {String: String}}

	/* Stores the Capability to receive Flow tokens for each artist */
	access(account) var receivePaymentCaps : {String: Capability<&{FungibleToken.Receiver}>}

	/*  */
	pub event PonsArtistRecognised (ponsArtistId : String, metadata : {String: String}, addressOptional : Address?)

/*
	Pons Artist Resource

	This resource represents each verified Pons artist.
	For extensibility, concrete artist information is stored outside of the reource (which can be updated), so it only contains the identifying ponsArtistId.
	All PonsArtist resources are kept in the Pons account.
*/
	pub resource PonsArtist {
		pub let ponsArtistId : String

		init (ponsArtistId : String) {
			self .ponsArtistId = ponsArtistId } }

/*
	Pons Artist Certificate Resource

	This resource represents an authorisation from a Pons artist.
	This can be created by the artist himself, or by the Pons account on behalf of the artist.
*/
	pub resource PonsArtistCertificate {
		pub let ponsArtistId : String

		init (ponsArtistId : String) {
			pre {
				PonsArtistContract .ponsArtists .containsKey (ponsArtistId):
					"Not recognised Pons Artist" }

			self .ponsArtistId = ponsArtistId } }


	/* Borrow any PonsArtist, given his ponsArtistId, to browse further information about the artist */
	pub fun borrowArtist (ponsArtistId : String) : &PonsArtist {
		var ponsArtist <- PonsArtistContract .ponsArtists .remove (key: ponsArtistId) !
		let ponsArtistRef = & ponsArtist as &PonsArtist
		var replacedArtistOptional <- PonsArtistContract .ponsArtists .insert (key: ponsArtistId, <- ponsArtist) 
		destroy replacedArtistOptional
		return ponsArtistRef }


	/* Get the metadata of a PonsArtist */
	pub fun getMetadata (_ ponsArtist : &PonsArtist) : {String: String} {
		return PonsArtistContract .metadatas [ponsArtist .ponsArtistId] ! }

	/* Get the Flow address of a PonsArtist if available */
	pub fun getAddress (_ ponsArtist : &PonsArtist) : Address? {
		return PonsArtistContract .addresses [ponsArtist .ponsArtistId] }

	/* Get the Capability to receive Flow tokens of a PonsArtist */
	pub fun getReceivePaymentCap (_ ponsArtist : &PonsArtist) : Capability<&{FungibleToken.Receiver}>? {
		return PonsArtistContract .receivePaymentCaps [ponsArtist .ponsArtistId] }







	/* Create a PonsArtistCertificate authorisation resource, given his AuthAccount */
	pub fun makePonsArtistCertificate (artistAccount : AuthAccount) : @PonsArtistCertificate {
		pre {
			PonsArtistContract .ponsArtistIds .containsKey (artistAccount .address):
				"No artist is known to have this address" }
		let ponsArtistId = PonsArtistContract .ponsArtistIds [artistAccount .address] !
		return <- create PonsArtistCertificate (ponsArtistId: ponsArtistId) }




/* 
	Pons Artist Authority Resource

	This resource allows Pons to manage information on Pons artists.
	All Pons artist information can be viewed or modified with a PonsArtistAuthority.
	This resource also allows recognising new Pons artists, and create PonsArtistCertificate authorisations on their behalf.
*/
	pub resource PonsArtistAuthority {
		/* Borrow the dictionary which stores all PonsArtist instances */
		pub fun borrowPonsArtists () : &{String: PonsArtist} {
			return & PonsArtistContract .ponsArtists as &{String: PonsArtist} }

		/* Get the dictionary mapping Address to ponsArtistId */
		pub fun getPonsArtistIds () : {Address: String} {
			return PonsArtistContract .ponsArtistIds }
		/* Update the dictionary mapping Address to ponsArtistId */
		pub fun setPonsArtistIds (_ ponsArtistIds :  {Address: String}) : Void {
			PonsArtistContract .ponsArtistIds = ponsArtistIds }

		/* Get the dictionary mapping ponsArtistId to Address */
		pub fun getAddresses () : {String: Address} {
			return PonsArtistContract .addresses }
		/* Update the dictionary mapping ponsArtistId to Address */
		pub fun setAddresses (_ addresses : {String: Address}) : Void {
			PonsArtistContract .addresses = addresses }

		/* Get the dictionary mapping ponsArtistId to metadata */
		pub fun getMetadatas () : {String: {String: String}} {
			return PonsArtistContract .metadatas }
		/* Update the dictionary mapping ponsArtistId to metadata */
		pub fun setMetadatas (_ metadatas : {String: {String: String}}) : Void {
			PonsArtistContract .metadatas = metadatas }

		/* Get the dictionary mapping ponsArtistId to Capability of receiving Flow tokens */
		pub fun getReceivePaymentCaps () : {String: Capability<&{FungibleToken.Receiver}>} {
			return PonsArtistContract .receivePaymentCaps }
		/* Update the dictionary mapping ponsArtistId to Capability of receiving Flow tokens */
		pub fun setReceivePaymentCaps (_ receivePaymentCaps : {String: Capability<&{FungibleToken.Receiver}>}) : Void {
			PonsArtistContract .receivePaymentCaps = receivePaymentCaps }

		/* Recognise a new Pons artist, and store the PonsArtist resource instance */
		pub fun recognisePonsArtist
		( ponsArtistId : String
		, metadata : {String: String}
		, _ addressOptional : Address?
		, _ receivePaymentCapOptional : Capability<&{FungibleToken.Receiver}>?
		) : Void {
			pre {
				! PonsArtistContract .ponsArtists .containsKey (ponsArtistId):
					"Pons Artist with this ponsArtistId already exists" }
			post {
				PonsArtistContract .ponsArtists .containsKey (ponsArtistId):
					"Unable to recognise Pons Artist" }

			// Create a PonsArtist with the specified ponsArtistId
			var ponsArtist <- create PonsArtist (ponsArtistId: ponsArtistId)

			// Store the PonsArtist resource into the PonsArtist contract storage
			// Ensure that the key has not been taken
			var replacedArtistOptional <- PonsArtistContract .ponsArtists .insert (key: ponsArtistId, <- ponsArtist)
			if replacedArtistOptional != nil {
				panic ("Pons Artist with this ponsArtistId already exists") }
			destroy replacedArtistOptional

			// Save the Pons artist's metadata
			PonsArtistContract .metadatas .insert (key: ponsArtistId, metadata)

			// Save the address information of the Pons artist
			if addressOptional != nil {
				PonsArtistContract .ponsArtistIds .insert (key: addressOptional !, ponsArtistId)
				PonsArtistContract .addresses .insert (key: ponsArtistId, addressOptional !) }

			// Save the artist's Capability to receive Flow tokens
			if receivePaymentCapOptional != nil {
				PonsArtistContract .receivePaymentCaps .insert (key: ponsArtistId, receivePaymentCapOptional !) }

			emit PonsArtistRecognised (ponsArtistId: ponsArtistId, metadata: metadata, addressOptional: addressOptional) }

		/* Create a PonsArtistCertificate authorisation, given a PonsArtist reference */
		pub fun makePonsArtistCertificateFromArtistRef (_ ponsArtistRef : &PonsArtist) : @PonsArtistCertificate {
			return <- create PonsArtistCertificate (ponsArtistId: ponsArtistRef .ponsArtistId) }

		/* Create a PonsArtistCertificate authorisation, given a ponsArtistId */
		pub fun makePonsArtistCertificateFromId (ponsArtistId : String) : @PonsArtistCertificate {
			return <- create PonsArtistCertificate (ponsArtistId: ponsArtistId) } }




	init (artistAuthorityStoragePath : StoragePath) {
		// Save the Artist Authority storage path
		self .artistAuthorityStoragePath = artistAuthorityStoragePath
		self .ponsArtists <- {}
		self .ponsArtistIds = {}
		self .addresses = {}
		self .metadatas = {}
		self .receivePaymentCaps = {}

		// Create and save an Artist Authority resource to the storage path
        	self .account .save (<- create PonsArtistAuthority (), to: artistAuthorityStoragePath) } }
