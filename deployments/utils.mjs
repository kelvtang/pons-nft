import { readFile } from 'fs/promises'
import { URL } from 'url'
import flow_types from '@onflow/types'
import { flow_sdk_api } from '../utils/config.mjs'
import { substitutions_of_addresses, private_keys_of_addresses } from '../utils/config.mjs'
import { substitute_addresses_, authorizer_ } from '../utils/flow.mjs'
import { execute_script_, send_transaction_, deploy_contract_ } from '../utils/flow.mjs'


var address = substitutions_of_addresses ['0xPONS']
var key_id = 0
var private_key = private_keys_of_addresses ['0xPONS'] [key_id]

var authorizer = authorizer_ (address) (key_id) (private_key)


var direct_deploy_contract_ = _cadence_code => async _flow_arguments => {
	var _deployed_cadence_code =
		substitute_addresses_
			( substitutions_of_addresses )
			( _cadence_code )
	return await
		deploy_contract_
			( authorizer )
			( _deployed_cadence_code )
			( _flow_arguments ) }


var __dirname = new URL ('.', import .meta .url) .pathname

var stringify_ = _value => JSON .stringify (_value)
var output_ = _value => {
	;console .log (stringify_ (_value)) }

var deploy_known_core_contract_ = _file_name => async _flow_arguments => {
	var _cadence_code = await readFile (__dirname + '/../core-contracts/' + _file_name + '.cdc', 'utf8')
	var _flow_response =
		await
		direct_deploy_contract_
			( _cadence_code )
			( _flow_arguments )
	;output_ (_flow_response) }

var deploy_known_contract_ = _file_name => async _flow_arguments => {
	var _cadence_code = await readFile (__dirname + '/../contracts/' + _file_name + '.cdc', 'utf8')
	var _flow_response =
		await
		direct_deploy_contract_
			( _cadence_code )
			( _flow_arguments )
	;output_ (_flow_response) }
		

export { deploy_known_core_contract_, deploy_known_contract_ }
