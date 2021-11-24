import PonsUtils from 0xPONS

import TestUtils from 0xPONS

pub fun main
( transactionSuccess : Bool
, transactionErrorMessage : String?
, transactionEvents : [{String: String}]
) : {String: AnyStruct} {
	let pass = true

	return {
		"verified": pass } }
