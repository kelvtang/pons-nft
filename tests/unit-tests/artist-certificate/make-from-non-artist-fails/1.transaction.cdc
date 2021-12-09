import PonsNftContract from 0xPONS

import TestUtils from 0xPONS

transaction () {

	prepare (randomAccount : AuthAccount) {
		var artistCertificate <- PonsNftContract .makePonsArtistCertificateDirectly (artist: randomAccount)
		destroy artistCertificate } }
