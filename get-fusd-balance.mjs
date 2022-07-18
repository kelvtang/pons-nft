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
	( 'PonsNft_v1' )

/*/
;console .log (
	JSON .stringify
	( await
//
	execute_proposed_script_
	( `
// This script returns the balance of an account's FUSD vault.
//
// Parameters:
// - address: The address of the account holding the FUSD vault.
//
// This script will fail if they account does not have an FUSD vault. 
// To check if an account has a vault or initialize a new vault, 
// use check_fusd_vault_setup.cdc and setup_fusd_vault.cdc respectively.
import FungibleToken from 0xFUNGIBLETOKEN
import FUSD from 0xFUSD

pub fun main(address: Address): UFix64 {
    let account = getAccount(address)

    let vaultRef = account.getCapability(/public/fusdBalance)!
        .borrow<&FUSD.Vault{FungibleToken.Balance}>()
        ?? panic("Could not borrow Balance reference to the Vault")

    return vaultRef.balance
}
		` )
	( [flow_sdk_api .arg('0xf8d6e0586b0a20c7', flow_types .Address)] )

	, null
	, 4 ) )
/**/
