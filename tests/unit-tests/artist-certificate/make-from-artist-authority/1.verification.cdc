pub fun main 
( artistAuthorityStoragePath : StoragePath
, ponsArtistId : String
, transactionSuccess : Bool
, transactionErrorMessage : String?
, transactionEvents : [{String: String}]
) : {String: AnyStruct} {

	if transactionSuccess {
		return { "verified": true } }
	else {
		return { "verified": false } } }
