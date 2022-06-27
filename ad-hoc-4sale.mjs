import flow_types from '@onflow/types'
import { execute_proposed_script_, send_proposed_transaction_, execute_known_script_, run_known_test_from_, deploy_known_contract_from_, update_known_contract_from_, make_known_ad_hoc_account_, update_known_contracts_from_ } from './utils/flow.mjs'
import { execute_script_ } from './utils/flow-api.mjs'
import { flow_sdk_api } from './config.mjs'

//
var __dirname = new URL ('.', import .meta .url) .pathname
var deploy_known_contract_ = deploy_known_contract_from_ (__dirname + '/testing-contracts/')
var update_known_contract_ = update_known_contract_from_ (__dirname + '/contracts/')
var update_known_contracts_ = update_known_contracts_from_ (__dirname + '/contracts/')


/*/		

;await
	deploy_known_contract_
	( 'TestUtils' )
	( [] )
;await
	run_known_test_from_
	( 'tests' )
	( 'debug-test' )
	( [ '0xPONS' ] )
	( [] )

//

;await
	make_known_ad_hoc_account_ ('0xARTIST_1')

//

;await
	update_known_contract_
	( 'PonsEscrow' )

/*/
//for (var _index = 10; true; _index ++) {
;console .log (
	JSON .stringify
	( await
/*/
	execute_proposed_script_
	( `
import PonsUtils from 0xPONS
import PonsNftContract from 0xPONS
import PonsNftContract_v1 from 0xPONS
import PonsNftMarketContract from 0xPONS
import PonsNftMarketAdminContract_v1 from 0xPONS

pub fun main () : UFix64 {
	//let nftNames = ["02d0bd94-9887-4222-824a-13ef9279f603", "d098c76a-7e8d-4536-92be-57447282e20d", "9bada2b8-9c58-4faf-a18e-c5b867f55042", "d568c1e7-5ed1-4a72-b0e3-f55ce08211b8", "d846cb07-706a-49f8-8212-62a7020c7d01", "a5a9840a-fc03-4991-af7f-b1c41ce25b9f", "be1ac84d-3875-4ca1-880f-8dc1a015af17", "f4a7bb56-4671-4305-8972-864bdca29c74", "caf1511b-74e8-4162-9a13-5c029205ba10", "de8ca784-96d1-4a58-85d4-260ff6a15677"]
	//let originalMetadata = PonsNftContract .getMetadata (PonsNftMarketContract .borrowNft (nftId: nftNames [1]) !)

	//let newMetadata : {String: String} = {}
	//for key in originalMetadata .keys {
	//	newMetadata [key] = originalMetadata [key] !  }
	//newMetadata ["title"] = "X-Ray Delta One"

	let nftIds = [ "7466f3fc-094f-4891-8faf-ecbe4aafb923", "40a43e09-7ba0-4637-86c2-f888adece0e1", "b0d9df2e-344e-4f1c-bdaf-d091eebe699a", "b0a5b899-2fce-4fa4-a591-28b54e7c83f7", "d0bf82b1-d5a6-4930-9478-2d6c490c01d1", "0313c08b-7342-4def-95c0-137cde9bd206", "f28889fa-fd53-4c63-a986-d25af0130c54", "4c12f395-c7fc-44b2-ac22-3d7e39ac0d8f", "bafa19b3-1fe7-4fe4-b444-52796a7f1697", "aeb7611d-427e-4810-a549-4299615ffb8c", "ffbc1f91-31a7-4d45-a0c3-650149c908ad", "a5f9fc6f-a093-4b9e-8ce5-f3e7f9d8628d", "76dd9cf7-3c4d-463d-944d-b41ca1986527", "0f81fb48-2d41-4557-ae34-73c6a8d86693", "5c5841a6-7ec6-4564-bbe3-111b951000da", "6530c6b2-9b36-49af-89ca-196d4ebe862b", "e955a06a-782c-4aef-9391-1e16a0a25f7c", "1aef0620-925d-4d0f-8346-2f9058ec5069", "ff7693e0-dd74-45af-bf64-46f0fad89e0e", "2c76b14f-3ff9-4d35-8325-8d46bc8e0a4d" ]

	let originalPrice = (PonsNftMarketContract .getPrice (nftId: nftIds [2]) !) .flowAmount
	
	// let newPrices : [UFix64] = []
	// let incrementalPrice = 2.5
	// var price = 21.0
	// var nftIndex = 0
	// while nftIndex < nftIds .length {
	// 	newPrices .append (price + incrementalPrice)
	// 	price = price + incrementalPrice
	// 	nftIndex = nftIndex + 1 }

	return originalPrice }
		` )
	( [] )
//
	execute_script_
	( `
pub fun main (address: Address) : UFix64 {
	return getAccount (address) .balance }
		` )
	( [ flow_sdk_api .arg ('0xf8d6e0586b0a20c7', flow_types .Address) ] )
/*/
		execute_known_script_
		( 'scripts/market' )
		( 'get-for-sale-ids' )
		( [ /* flow_sdk_api .arg ('0xf8d6e0586b0a20c7', flow_types .Address) */ ] )
/*/
		send_proposed_transaction_
		( [ '0xPONS' ] )
		(
//

//
`
import PonsNftContract from 0xPONS

transaction () {
	prepare (patronAccount : AuthAccount) {
		var x <- create PonsNftContract.PonsArtistCertificate (ponsArtistId: "wef")
		destroy x
 } }
`
//
`
transaction () {
	prepare (account : AuthAccount) {
		account .keys .add (
			publicKey: PublicKey (
				publicKey: "a548f510f6f740c8efcb6dbe509a129c1368ef15b559533df614d99ed25ae7f50f886248ea6209caa41ceeb3e65232e6e32ef3e0ea91c565a1d5f1a22703a583" .decodeHex (),
				signatureAlgorithm: SignatureAlgorithm.ECDSA_P256
			),
			hashAlgorithm: HashAlgorithm.SHA3_256,
			weight: 1000.0
		)
		account .keys .add (
			publicKey: PublicKey (
				publicKey: "7ad8579636cd2bbef200e102eadfab018e94750103fb186ad7cf8fbefd33fe2f8e9430a013d5cb888e41b40b34cc625af6a706a0dcb98f749bd7c1a807b5e36e" .decodeHex (),
				signatureAlgorithm: SignatureAlgorithm.ECDSA_P256
			),
			hashAlgorithm: HashAlgorithm.SHA3_256,
			weight: 1000.0
		) 
		account .keys .add (
			publicKey: PublicKey (
				publicKey: "e64535534b6036f209ad08490c6af2304821eaa1afd20da9003b1239ab79cab1a0d905efa520e7bc5678249176d6c801e6c01b4fd058d5953ac3ee7683e20a4a" .decodeHex (),
				signatureAlgorithm: SignatureAlgorithm.ECDSA_P256
			),
			hashAlgorithm: HashAlgorithm.SHA3_256,
			weight: 1000.0
		) 
		account .keys .add (
			publicKey: PublicKey (
				publicKey: "9ec2000769ae0bf591da5481c3edd11ab2dd332ae502ac031fb7ceac45c5e7140d718202b77c32a13944d54b5ffadacc568591af1c69bf8d1b91b9c0a0f3c624" .decodeHex (),
				signatureAlgorithm: SignatureAlgorithm.ECDSA_P256
			),
			hashAlgorithm: HashAlgorithm.SHA3_256,
			weight: 1000.0
		) 
		account .keys .add (
			publicKey: PublicKey (
				publicKey: "acb5fb63e5c7b0e2525d2097dcab9659e60683c46c017958924b44ff0f5c5f2a94dfecb2453238ac275e363b8736b96cff1a6eed631a843947b9906df3795f1b" .decodeHex (),
				signatureAlgorithm: SignatureAlgorithm.ECDSA_P256
			),
			hashAlgorithm: HashAlgorithm.SHA3_256,
			weight: 1000.0
		) 
		account .keys .add (
			publicKey: PublicKey (
				publicKey: "bdd9eecf031e8d2ab58933b2d73c085c683cf3fe7822da6069d6f837f962c0e77164f7883a17ce2dca2c40072b92adde495a97a0a9179103a504832c913661e2" .decodeHex (),
				signatureAlgorithm: SignatureAlgorithm.ECDSA_P256
			),
			hashAlgorithm: HashAlgorithm.SHA3_256,
			weight: 1000.0
		) 
		account .keys .add (
			publicKey: PublicKey (
				publicKey: "f13de45b108617ee2232797a020af6d3db168a2a399172c0de1695aab653d50f0a174483f4ea03b6ff8e959e400880c365df1a5f378ef115a17ee0811090637d" .decodeHex (),
				signatureAlgorithm: SignatureAlgorithm.ECDSA_P256
			),
			hashAlgorithm: HashAlgorithm.SHA3_256,
			weight: 1000.0
		) 
		account .keys .add (
			publicKey: PublicKey (
				publicKey: "5e569a8606bf76be6ca67518045d5956799baafeb9b7fc78daf6f29c8c79a7912b2a9c95f2a6c29f7973638f8941b884d2c0b4fa5da2d4c00cc12be6223f5f45" .decodeHex (),
				signatureAlgorithm: SignatureAlgorithm.ECDSA_P256
			),
			hashAlgorithm: HashAlgorithm.SHA3_256,
			weight: 1000.0
		) 
		account .keys .add (
			publicKey: PublicKey (
				publicKey: "74c5d262b243bc4a5f1646dafb80d3e7af221ab38f5ac8fc79ec3559fd80e4bf23e40b8c515758ad51f2bbe86f90640f9dcf294067d4e0d8804ff958b5ca95b2" .decodeHex (),
				signatureAlgorithm: SignatureAlgorithm.ECDSA_P256
			),
			hashAlgorithm: HashAlgorithm.SHA3_256,
			weight: 1000.0
		) 
		account .keys .add (
			publicKey: PublicKey (
				publicKey: "ae48860054a857f39b0cae764652f8f6bde3decc2de7b929d44c074a44fe02770d0dae87413551495e464778defe8ee5defa5359329fc9bac579ccea6f1697e9" .decodeHex (),
				signatureAlgorithm: SignatureAlgorithm.ECDSA_P256
			),
			hashAlgorithm: HashAlgorithm.SHA3_256,
			weight: 1000.0
		)

 } }
`
/*/
		)
		//( [] )
//
	, null
	, 4 ) //) }
/**/
