import FungibleToken from 0xFUNGIBLETOKEN
import PonsArtistContract from 0xPONS

import TestUtils from 0xPONS

/*
	Recognise Off-chain Artist Test

	Tests that `recognisePonsArtist ()` works for artists without a Flow account.
*/
transaction 
( artistAuthorityStoragePath : StoragePath
, ponsArtistId : String
, metadata : {String: String}
) {

	prepare (ponsAccount : AuthAccount) {

		// Recognises a Pons artists which does not have a Flow account

		let artistAuthorityRef = ponsAccount .borrow <&PonsArtistContract.PonsArtistAuthority> (from: artistAuthorityStoragePath) !

		artistAuthorityRef .recognisePonsArtist (
			ponsArtistId: ponsArtistId,
			metadata : metadata,
			nil,
			nil )

		TestUtils .log ("Recognised artist") } }
