import TestUtils from 0xPONS

pub fun main 
( transactionSuccess : Bool
, transactionErrorMessage : String?
, transactionEvents : [{String: String}]
) : {String: AnyStruct} {

	if transactionSuccess {
		return {
			"verified": true } }
	else {
		return {
			"verified": false } } }
