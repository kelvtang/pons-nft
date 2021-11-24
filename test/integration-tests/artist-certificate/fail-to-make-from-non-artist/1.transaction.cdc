import PonsArtistContract from 0xPONS

import TestUtils from 0xPONS

transaction () {

	prepare (randomAccount : AuthAccount) {
		var artistCertificate <- PonsArtistContract .makePonsArtistCertificate (artistAccount : randomAccount)
		destroy artistCertificate } }
