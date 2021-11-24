import PonsArtistContract from 0xPONS

import TestUtils from 0xPONS

transaction () {

	prepare (artistAccount : AuthAccount) {
		var artistCertificate <- PonsArtistContract .makePonsArtistCertificate (artistAccount : artistAccount)
		TestUtils .log ("artistCertificate id: " .concat (artistCertificate .ponsArtistId))
		destroy artistCertificate } }
