pub fun main 
( metadata : {String: String}
, quantity : Int
, _basePrice : UFix64
, _incrementalPrice : UFix64
, _ _royaltyRatio : UFix64
, transactionSuccess : Bool
, transactionErrorMessage : String?
, transactionEvents : [{String: String}]
) : {String: AnyStruct} {

	if transactionSuccess {
		return { "verified": true } }
	else {
		return { "verified": false } } }
