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
;

var _escrow_id = "koillo";

	console .log (
	JSON .stringify
	( await

		send_proposed_transaction_
		( [ '0xPONS' ] )
		(


`
import FungibleToken from 0xFUNGIBLETOKEN
import FlowToken from 0xFLOWTOKEN
import PonsNftContractInterface from 0xPONS
import PonsNftContract from 0xPONS
import PonsEscrowContract from 0xPONS
import PonsUtils from 0xPONS
import PonsUsage from 0xPONS

/* Submit an escrow using the specified id and requirement, gathering the escrow resources and fulfillment from the default paths */
transaction () {
        prepare (submitter : AuthAccount) {

                let heldResourceDescription = PonsEscrowContract.EscrowResourceDescription (
                        flowUnits: PonsUtils.FlowUnits (0.0),
                        ponsNftIds: [] )
                let requirement = PonsEscrowContract.EscrowResourceDescription (
                        flowUnits: PonsUtils.FlowUnits (0.0),
                        ponsNftIds: [] )

                PonsUsage .submitEscrow (
                        submitter: submitter,
                        id: "${_escrow_id}",
                        heldResourceDescription: heldResourceDescription,
                        requirement: requirement ) } }
`


		)
		( [] )


//
	, null
	, 4 ) )
		
/**/
