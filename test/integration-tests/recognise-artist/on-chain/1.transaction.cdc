import FungibleToken from 0xFUNGIBLETOKEN
import PonsArtistContract from 0xPONS

import TestUtils from 0xPONS

transaction 
( artistAuthorityStoragePath : StoragePath
, ponsArtistId : String
, ponsArtistAddress : Address
, metadata : {String: String}
) {

	prepare (ponsAccount : AuthAccount) {
		let artistAuthorityRef = ponsAccount .borrow <&PonsArtistContract.PonsArtistAuthority> (from: artistAuthorityStoragePath) !
		let artistAccount = getAccount (ponsArtistAddress)
		let artistAccountBalanceRef = artistAccount .getCapability <&{FungibleToken.Balance}> (/public/flowTokenBalance) .borrow () !

		artistAuthorityRef .recognisePonsArtist (
			ponsArtistId: ponsArtistId,
			ponsArtistAddress,
			metadata : metadata,
			receivePaymentCap: artistAccount .getCapability <&{FungibleToken.Receiver}> (/public/flowTokenReceiver) )

		TestUtils .log ("Recognized artist")

		let artistBalance = artistAccountBalanceRef .balance

		TestUtils .log ("Artist balance: " .concat (artistBalance .toString ()))
		} }
