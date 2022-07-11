import FungibleToken from 0xFUNGIBLETOKEN
import PonsUtils from 0xPONS
import PonsNftMarketContract from 0xPONS
import PonsNftContract_v1 from 0xPONS

import TestUtils from 0xPONS
import PonsUsage from 0xPONS

/*
	Unlist someone else's Listing Test

	Verifies that accounts can only unlist NFTs which he has listed
*/
transaction 
( minterStoragePath : StoragePath
, mintId : String
, metadata : {String: String}
, basePriceAmount : UFix64
, royaltyRatioAmount : UFix64
, transactionSuccess : Bool
, transactionErrorMessage : String?
, transactionEvents : [{String: String}]
, testInfo : {String: String}
) {

	prepare (ponsAccount : AuthAccount, artistAccount : AuthAccount, patronAccount : AuthAccount, randomAccount : AuthAccount) {

		// 'Patron' attempts to unlist the NFT from the marketplace, even though it is being listed by 'Random'
		// Should fail

		TestUtils .log ("Patron 1 normal tries to redeem same NFT with ListingCertificate")

		let firstNftId = testInfo ["First NFT nftId"] !

		PonsUsage .unlist (
			lister: patronAccount,
			nftId: firstNftId )

		} }
