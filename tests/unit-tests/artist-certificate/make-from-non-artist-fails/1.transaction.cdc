import PonsNftContract from 0xPONS

import TestUtils from 0xPONS
import PonsUsage from 0xPONS

transaction () {

	prepare (randomAccount : AuthAccount) {
		var artistCertificate <- PonsUsage .makePonsArtistCertificateDirectly (artist: randomAccount)
		destroy artistCertificate } }
