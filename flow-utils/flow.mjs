import { access_node_origin } from './config.mjs'
import { flow_sdk_api } from './config.mjs'
import fcl_api from '@onflow/fcl'
import flow_types from '@onflow/types'
import * as ec_api from 'elliptic'
import { SHA3 } from 'sha3'



// due to FLOW_SERVICEKEYSIGALGO='ECDSA_P256' 
var ec_service = new ec_api .default .ec ('p256')
var sign_ = privateKey => msg => {
	var key = ec_service .keyFromPrivate (Buffer .from (privateKey, 'hex'))
	var sig = key .sign (hash_ (msg))
	var n = 32
	var r = sig .r .toArrayLike (Buffer, 'be', n)
	var s = sig .s .toArrayLike (Buffer, 'be', n)
	return Buffer .concat ([r, s]) .toString ('hex') }

// due to FLOW_SERVICEKEYHASHALGO='SHA3_256'
var hash_ = msg => {
	var sha = new SHA3 (256)
	sha .update (Buffer .from (msg, 'hex'))
	return sha .digest () }




















var substitute_addresses_ = _substitutions_of_addresses => _cadence_code => {
	// naive implementation, works for non-adversarial inputs

	var [ _, _import_code, _post_import_code ] = _cadence_code .match (/^((?:\/\*[\s\S]*?\*\/|(?:[^\\:]|^)\/\/.*$|\s*|import\s+\S+\s+from\s+0x[0-9a-zA-Z]+)*)([^]*)$/m)

	for (var _address in _substitutions_of_addresses) {
		var _substitution = _substitutions_of_addresses [_address]

		;_import_code = _import_code .split (_address) .join (_substitution) }

	return _import_code + _post_import_code }








var authorizer_ = _address => _key_id => _private_key => {
	return async accountData => {
		return (
			{ ... accountData
			, tempId: _address + '-' + _key_id
			, addr: fcl_api .sansPrefix (_address)
			, keyId: + _key_id
			, signingFunction: signing_data => {
				var { message } = signing_data
				return (
					{ addr: _address
					, keyId: _key_id
					, signature: sign_ (_private_key) (message) } ) } } ) } }









var send_transaction_ =
	_proposer_authorizer => _payer_authorizer => _authorization_authorizers =>
	_transaction_code => async _arguments => {
		var response =
			await
			flow_sdk_api .send
			(
			[ flow_sdk_api .transaction (_transaction_code)
			, flow_sdk_api .args (_arguments)
			, flow_sdk_api .proposer (_proposer_authorizer)
			, flow_sdk_api .payer (_payer_authorizer)
			, flow_sdk_api .authorizations (_authorization_authorizers)
			, flow_sdk_api .limit (9999) ] )
		return await
			fcl_api .tx (response) .onceSealed () }

var execute_script_ = _script_code => async _arguments => {
	var response =
		await
		flow_sdk_api .send
		(
		[ flow_sdk_api .script (_script_code)
		, flow_sdk_api .args (_arguments) ] )
	return await
		flow_sdk_api .decode (response) }

var deploy_contract_ = _authorizer => _contract_code => async _arguments => {
	var _contract_code_hex = Buffer .from (_contract_code, 'utf8') .toString ('hex')

	var _contract_name = _contract_code .replace (/\/\*[\s\S]*?\*\/|([^\\:]|^)\/\/.*$/gm, '') .match (/contract\s+(?:interface\s+)?\b(\S+)\b/) [1]

	var _argument_names =
		_arguments .map ((_, _index) =>
			'_argument_' + _index )

	var _arguments_declaration_code =
		_arguments
		.map ((_flow_arg, _index) => {
			// implementation only for primitive types
			var _type_name =
				(_flow_arg .xform .label === 'Path') ?
				(_flow_arg .value .domain) .slice (0, 1) .toUpperCase () + (_flow_arg .value .domain) .slice (1) + 'Path'
				: (_flow_arg .xform .label === 'Dictionary') ?
				'{String: String}'
				:
				_flow_arg .xform .label
			return _argument_names [_index] + ' : ' + _type_name } )
		.join (', ')

	var _argument_list_code =
		_argument_names
		.map (_argument_name => ', ' + _argument_name)
		.join ('')

	return await
		send_transaction_
		( _authorizer )
		( _authorizer )
		( [ _authorizer ] )
		( `
transaction (name : String, code : String ${_arguments_declaration_code}) {
	prepare (account : AuthAccount) {
		account .contracts .add (
			name: name,
			code: code .decodeHex ()
			${_argument_list_code} ) } }
		` )
		(
		[ flow_sdk_api .arg (_contract_name, flow_types .String)
		, flow_sdk_api .arg (_contract_code_hex, flow_types .String)
		, ... _arguments ] ) }


var create_account_ = _authorizer => async _public_key => {
	return await
		send_transaction_
		( _authorizer )
		( _authorizer )
		( [ _authorizer ] )
		( `
transaction (publicKey : String) {
	let createdAccount : AuthAccount

	prepare (signer : AuthAccount) {
		self .createdAccount = AuthAccount (payer: signer) }

	execute {
		let key = PublicKey (
			publicKey: publicKey .decodeHex (),
			signatureAlgorithm: SignatureAlgorithm .ECDSA_P256 )

		self .createdAccount .keys .add (
			publicKey: key,
			hashAlgorithm: HashAlgorithm.SHA3_256,
			weight: 1000.0 ) } }
		` )
		( [ flow_sdk_api .arg (_public_key, flow_types .String) ] ) }



export { substitute_addresses_ }
export { authorizer_ }
export { send_transaction_, execute_script_, deploy_contract_, create_account_ }
