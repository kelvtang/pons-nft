import flow_types from '@onflow/types'
import { execute_proposed_script_, send_proposed_transaction_, execute_known_script_, run_known_test_from_, deploy_known_contract_from_, update_known_contract_from_, make_known_ad_hoc_account_, update_known_contracts_from_ } from './utils/flow.mjs'
import { execute_script_ } from './utils/flow-api.mjs'
import { flow_sdk_api } from './config.mjs'

//
var __dirname = new URL ('.', import .meta .url) .pathname
var deploy_known_contract_ = deploy_known_contract_from_ (__dirname + './uzair_test')
var update_known_contract_ = update_known_contract_from_ (__dirname + '/contracts/')
var update_known_contracts_ = update_known_contracts_from_ (__dirname + '/contracts/')


//		



/*/
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
	( 'PonsNft_v1' )

/*/
;console .log (
	JSON .stringify
	( await

		send_proposed_transaction_
		( [ '0xPONS' ] )
		(

`import FungibleToken from 0xFUNGIBLETOKEN
import PonsNftContract from 0xPONS


transaction 
() {

	prepare (ponsAccount : AuthAccount) {

		// Recognises the Pons artist with the provided data

		let artistAuthorityRef = ponsAccount .borrow <&PonsNftContract.PonsArtistAuthority> (from: /storage/ponsArtistAuthority) !
		let artistAccount = getAccount (0xf8d6e0586b0a20c7)
		let artistAccountBalanceRef = artistAccount .getCapability <&{FungibleToken.Balance}> (/public/flowTokenBalance) .borrow () !

		artistAuthorityRef .recognisePonsArtist (
			ponsArtistId: "4176cebe-8656-414c-a6ce-158662a6ef87",		//"4176cebe-8886-414c-a6ce-15bc22a6ef87",
			metadata : {},
			0xf8d6e0586b0a20c7,
			artistAccount .getCapability <&{FungibleToken.Receiver}> (/public/flowTokenReceiver) )

		

		let artistBalance = artistAccountBalanceRef .balance

		
		} }
`
//

		)
		( [] )
//
	, null
	, 4 ) )
/**/
