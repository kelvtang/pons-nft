import PonsNftContract from 0xPONS

import TestUtils from 0xPONS

transaction () {

	prepare (artistAccount : AuthAccount) {
		var artistCertificate <- PonsNftContract .makePonsArtistCertificateDirectly (artist: artistAccount)
		TestUtils .log ("artistCertificate id: " .concat (artistCertificate .ponsArtistId))
		destroy artistCertificate } }
