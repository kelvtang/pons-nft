import FungibleToken from 0xFUNGIBLETOKEN
import PonsNftContract from 0xPONS
// import PonsUsage from 0xPONS
import TestUtils from 0xPONS

/*
	Recognise On-chain Artist Test

	Tests that `recognisePonsArtist ()` works for artists with a Flow account.
*/
transaction 
( artistAuthorityStoragePath : StoragePath
, ponsArtistId : String
, ponsArtistAddress : Address
, metadata : {String: String}
) {

	prepare (ponsAccount : AuthAccount) {

		// Recognises the Pons artist with the provided data

		let artistAuthorityRef = ponsAccount .borrow <&PonsNftContract.PonsArtistAuthority> (from: artistAuthorityStoragePath) !
		let artistAccount = getAccount (ponsArtistAddress)
		
		let artistAccountBalanceRef = artistAccount .getCapability <&{FungibleToken.Balance}> (/public/flowTokenBalance) .borrow () !

		artistAuthorityRef .recognisePonsArtist (
			ponsArtistId: ponsArtistId,
			metadata : metadata,
			ponsArtistAddress,
			artistAccount .getCapability <&{FungibleToken.Receiver}> (/public/flowTokenReceiver),
			artistAccount .getCapability <&{FungibleToken.Receiver}> (/public/fusdReceiver) )


		TestUtils .log ("Recognized artist")

		let artistBalance = artistAccountBalanceRef .balance

		TestUtils .log ("Artist balance: " .concat (artistBalance .toString ()))
		} }
