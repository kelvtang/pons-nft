import PonsArtistContract from 0xPONS

import TestUtils from 0xPONS

transaction (artistAuthorityStoragePath : StoragePath, ponsArtistId : String) {

	prepare (ponsAccount : AuthAccount) {
		let artistAuthorityRef = ponsAccount .borrow <&PonsArtistContract.PonsArtistAuthority> (from: artistAuthorityStoragePath) !

		var artistCertificate1 <-
			artistAuthorityRef .makePonsArtistCertificateFromArtistRef (
				PonsArtistContract .borrowArtist (ponsArtistId: ponsArtistId) )
		TestUtils .log ("artistCertificate1 id: " .concat (artistCertificate1 .ponsArtistId))
		destroy artistCertificate1

		var artistCertificate2 <-
			artistAuthorityRef .makePonsArtistCertificateFromId ( ponsArtistId: ponsArtistId ) 
		TestUtils .log ("artistCertificate2 id: " .concat (artistCertificate2 .ponsArtistId))
		destroy artistCertificate2 } }
