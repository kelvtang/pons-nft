import PonsNftContract from 0xPONS

import TestUtils from 0xPONS
import PonsUsage from 0xPONS

transaction () {

	prepare (artistAccount : AuthAccount) {
		var artistCertificate <- PonsUsage .makePonsArtistCertificateDirectly (artist: artistAccount)
		TestUtils .log ("artistCertificate id: " .concat (artistCertificate .ponsArtistId))
		destroy artistCertificate } }
