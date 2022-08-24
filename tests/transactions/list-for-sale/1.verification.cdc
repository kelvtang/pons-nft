import PonsNftMarketContract from 0xPONS

pub fun main 
( nftId: String
, currencyChoice: String /* Either "Flow" or "Fusd" */
, salePrice: UFix64
, transactionSuccess : Bool
, transactionErrorMessage : String?
, transactionEvents : [{String: String}]
) : {String: AnyStruct} {

	if transactionSuccess {
		return { "verified": PonsNftMarketContract .getForSaleIds() .contains(nftId) } }
	else {
		return { "verified": false } } }
