import PonsArtistContract from 0xPONS

import TestUtils from 0xPONS

pub fun main 
( minterStoragePath : StoragePath
, mintIds : [String]
, metadata : {String: String}
, quantity: Int
, basePriceAmount : UFix64
, incrementalPriceAmount : UFix64
, royaltyRatioAmount : UFix64
, transactionSuccess : Bool
, transactionErrorMessage : String?
, transactionEvents : [{String: String}]
, testInfo : {String: String}
) : {String: AnyStruct} {

	if transactionSuccess {
		let artistAddressString = testInfo ["First Artist address"] !
		let marketAddressString = testInfo ["Market address"] !

		let depositsData = TestUtils .typeEvents (".TokensDeposited", transactionEvents) 

		return {
			"verified": true,
			"artistAddress": artistAddressString,
			"marketAddress": marketAddressString,
			"deposits": depositsData
			} }
	else {
		return {
			"verified": false } } }
