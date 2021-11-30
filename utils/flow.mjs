import * as fs from 'fs'
import { readFile, access } from 'fs/promises'
import { URL } from 'url'
import flow_types from '@onflow/types'
import test from 'tape'
import { authorizer_, create_account_, execute_script_, send_transaction_, deploy_contract_ } from './flow-api.mjs'
import { flow_sdk_api } from '../config.mjs'
import { address_of_names, private_keys_of_names } from '../config.mjs'
import { ad_hoc_accounts } from '../config.mjs'






var file_exists_ = async _path => {
	return access (_path, fs .constants .F_OK)
		.then (_ => true)
		.catch (_ => false) }



var stringify_values_ = _object => {
	var _stringified_object = {}
	for (var _key in _object) {
		if (typeof (_object [_key]) === 'string') {
			;_stringified_object [_key] = _object [_key] }
		else {
			;_stringified_object [_key] = JSON .stringify (_object [_key]) } }
	return _stringified_object }




var cadencify_object_ = _object => {
	var _cadence_object = []
	for (var _key in _object) {
		;_cadence_object .push ({ key: _key, value: _object [_key] }) }
	return _cadence_object }


var substitute_addresses_ = _substitutions_of_addresses => _cadence_code => {
	// naive implementation, works for non-adversarial inputs

	var [ _, _import_code, _post_import_code ] = _cadence_code .match (/^((?:\/\*[\s\S]*?\*\/|(?:[^\\:]|^)\/\/.*$|\s*|import\s+\S+\s+from\s+0x[0-9a-zA-Z]+)*)([^]*)$/m)

	for (var _address in _substitutions_of_addresses) {
		var _substitution = _substitutions_of_addresses [_address]

		;_import_code = _import_code .split (_address) .join (_substitution) }

	return _import_code + _post_import_code }














var known_account_ = _named_address => {
	if
	( (! (_named_address in address_of_names))
	&& (! (_named_address in private_keys_of_names))
	) {
		;throw new Error ('User ' + _named_address + ' is not deployed') }

	var _address = address_of_names [_named_address]
	var _key_id = 0
	var _private_key = private_keys_of_names [_named_address] [_key_id]

	return authorizer_ (_address) (_key_id) (_private_key) }


var make_known_ad_hoc_account_ = async _named_address => {
	var _private_key = ad_hoc_accounts [_named_address] .private_key
	var _public_key = ad_hoc_accounts [_named_address] .public_key

	var _flow_response =
		await
		create_account_
		( known_account_ ('0xPROPOSER') )
		( _public_key )
	var _address =
		_flow_response .events
		.filter (({ type }) => type === 'flow.AccountCreated') [0]
		.data .address

	;address_of_names [_named_address] = _address
	;private_keys_of_names [_named_address] = [ _private_key ] }





var deploy_proposed_contract_ = _cadence_code => async _flow_arguments => {
	var _deployed_cadence_code =
		substitute_addresses_
			( address_of_names )
			( _cadence_code )
	return await
		deploy_contract_
			( known_account_ ('0xPROPOSER') )
			( _deployed_cadence_code )
			( _flow_arguments ) }



var deploy_known_contract_from_ = _base_path => _file_name => async _flow_arguments => {
	;test ('deploy ' + _file_name, async _test => {
		var _cadence_code = await readFile (_base_path + '/' + _file_name + '.cdc', 'utf8')
		var _flow_response =
			await
			deploy_proposed_contract_
				( _cadence_code )
				( _flow_arguments )
		;_test .comment (JSON .stringify (_flow_response)) } ) }




var run_known_test_from_ = _base_path => _test_name => _authorizer_names => async _flow_arguments => {
	;test (_test_name, async _test => {
		var _test_path = _base_path + '/' + _test_name

		var _step_count = 0
		var _last_transaction_arguments = []
		var _test_info

		while (true) {
			;_step_count = _step_count + 1

			var _verification_path = _test_path + '/' + _step_count + '.verification.cdc'
			var _verification_exists = await file_exists_ (_verification_path)

			if (! _verification_exists) {
				if (_step_count === 1) {
					;throw new Error ('Test ' + _test_name + ' not found') }
				else {
					;break } } }

		for (var _step = 1; _step < _step_count; _step ++) {
			;(_step => {
				;_test .test ('step ' + _step, async _test => {
					var _transaction_path = _test_path + '/' + _step + '.transaction.cdc'
					var _verification_path = _test_path + '/' + _step + '.verification.cdc'

					var _transaction_exists = await file_exists_ (_transaction_path)
					if (_transaction_exists) {
						var _transaction_code = await readFile (_transaction_path, 'utf8')
						try {
							var _transaction_response =
								await
								send_transaction_
									( known_account_ ('0xPROPOSER') )
									( known_account_ ('0xPROPOSER') )
									( _authorizer_names .map (known_account_) )
									( substitute_addresses_
										( address_of_names )
										( _transaction_code ) )
									( [ ... _flow_arguments, ... _last_transaction_arguments ] ) }
						catch (_exception) {
							var _transaction_response =
								{ fail: true
								, errorMessage: '' + _exception }
							if (Object .isPrototypeOf (_exception) && 'stack' in _exception) {
								_transaction_response .stack = _exception .stack } }

						var _latest_test_info = []

						var _latest_events = _transaction_response .events || []

						for (var _event_index = 0; _event_index < _latest_events .length; _event_index ++) {
							var _event = _latest_events [_event_index]
							if (_event .type .endsWith ('TestUtils.TestInfo')) {
								var { data } = _event
								var { key, value } = data
								;_test .comment ('[' + key + ']=' + value)
								;_latest_test_info .push (data) }
							else if (_event .type .endsWith ('TestUtils.Log')) {
								var { data: { info } } = _event
								;_test .comment (info) }
							else {
								var { type, data } = _event
								;_test .comment ('(' + type .split ('.') .slice (-2) .join ('.') + '); ' + JSON .stringify (data)) } }

						if (_latest_test_info .length > 0) {
							if (_test_info === undefined) {
								;_test_info = {} }

							for (var _info_index = 0; _info_index < _latest_test_info .length; _info_index ++) {
								var { key, value } = _latest_test_info [_info_index]
								;_test_info [key] = value } }

						;_last_transaction_arguments =
							[ flow_sdk_api .arg
								( ! _transaction_response .fail
								, flow_types .Bool )
							, flow_sdk_api .arg
								( _transaction_response .errorMessage || null
								, flow_types .Optional (flow_types .String) )
							, flow_sdk_api .arg
								( (_transaction_response .events || []) .map (({ type, data }) => ({ type, ... data })) .map (stringify_values_) .map (cadencify_object_)
								, flow_types .Array (flow_types .Dictionary ({ key: flow_types .String, value: flow_types .String })) )
							, ... (
								(_test_info === undefined) ? []
								: [ flow_sdk_api .arg (cadencify_object_ (_test_info), flow_types .Dictionary ({ key: flow_types .String, value: flow_types .String })) ] ) ] }

					try {
						var _verification_code = await readFile (_verification_path, 'utf8')
						var _verification_response =
							await
							execute_script_
								( substitute_addresses_
									( address_of_names )
									( _verification_code ) )
								( [ ... _flow_arguments, ... _last_transaction_arguments ] ) }
					catch (_exception) {
						if (_transaction_exists) {
							;_test .comment (JSON .stringify ({ transaction: _transaction_response })) }
						;throw (_exception) }

					var test_result = { ... _verification_response }
					if
					( _transaction_exists &&
					! ('transaction' in _verification_response)
					) {
						;test_result .transaction = _transaction_response }
					if (! ('args' in _verification_response)) {
						;test_result .args = _flow_arguments }

					;_test .comment (JSON .stringify (test_result))
					;_test .ok (test_result .verified) } )
				} ) (_step) } } ) }





export { cadencify_object_, substitute_addresses_ }
export { known_account_, make_known_ad_hoc_account_ }
export { deploy_known_contract_from_ }
export { run_known_test_from_ }
