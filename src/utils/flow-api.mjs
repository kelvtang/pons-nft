import * as fcl_api from '@onflow/fcl'
import * as flow_types from '@onflow/types'
import * as ec_api from 'elliptic'
import { SHA3 } from 'sha3'
import { flow_sdk_api } from '../config.mjs'
import { access_node_origin } from '../config.mjs'



var sleep_ = async _duration => {
	return new Promise (resolve_ => setTimeout (resolve_, _duration * 1000)) }

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





















var authorizer_ = _address => _key_id => _private_key => {
	return accountData => {
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


var raw_transaction_response_ = 
	_proposer_authorizer => _payer_authorizer => _authorization_authorizers =>
	_transaction_code => async _arguments => {
		try {
			return await
				fcl_api .mutate
				(
				{ cadence: _transaction_code
				, args: (_arg, _t) => _arguments
				, proposer: _proposer_authorizer
				, authorizations: _authorization_authorizers
				, payer: _payer_authorizer
				, limit: 9999 } ) }
		catch (_exception) {
			if
			( _exception .message .includes ('failed to get state commitment for block')
			|| _exception .message .includes ('upstream connect error or disconnect/reset before headers. reset reason: connection failure')
			//|| _exception .message .includes ('Error while dialing dial tcp')
			) {
				;await sleep_ (1)
				return await
					raw_transaction_response_
					( _proposer_authorizer )
					( _payer_authorizer )
					( _authorization_authorizers )
					( _transaction_code )
					( _arguments ) }
			else {
				throw (_exception) } } }








var send_transaction_ =
	_proposer_authorizer => _payer_authorizer => _authorization_authorizers =>
	_transaction_code => async _arguments => {
		var response =
			await
			raw_transaction_response_
			( _proposer_authorizer )
			( _payer_authorizer )
			( _authorization_authorizers )
			( _transaction_code )
			( _arguments )

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

var update_contract_ = _authorizer => async _contract_code => {
	var _contract_code_hex = Buffer .from (_contract_code, 'utf8') .toString ('hex')

	var _contract_name = _contract_code .replace (/\/\*[\s\S]*?\*\/|([^\\:]|^)\/\/.*$/gm, '') .match (/contract\s+(?:interface\s+)?\b(\S+)\b/) [1]

	return await
		send_transaction_
		( _authorizer )
		( _authorizer )
		( [ _authorizer ] )
		( `
transaction (name : String, code : String) {
	prepare (account : AuthAccount) {
		account .contracts .update__experimental (
			name: name,
			code: code .decodeHex () ) } }
		` )
		(
		[ flow_sdk_api .arg (_contract_name, flow_types .String)
		, flow_sdk_api .arg (_contract_code_hex, flow_types .String) ] ) }

var update_contracts_ = _authorizer => async _contract_codes => {
	var _contract_code_hexs = _contract_codes .map (_contract_code => Buffer .from (_contract_code, 'utf8') .toString ('hex'))

	var _contract_names = _contract_codes .map (_contract_code => _contract_code .replace (/\/\*[\s\S]*?\*\/|([^\\:]|^)\/\/.*$/gm, '') .match (/contract\s+(?:interface\s+)?\b(\S+)\b/) [1])

	return await
		send_transaction_
		( _authorizer )
		( _authorizer )
		( [ _authorizer ] )
		( `
transaction (${_contract_names .map ((_, _index) => `name_${_index} : String`) .join (', ')} , ${_contract_codes .map ((_, _index) => `code_${_index} : String`) .join (', ')}) {
	prepare (account : AuthAccount) {
		${_contract_names .map ((_, _index) =>
			`account .contracts .update__experimental (
				name: name_${_index},
				code: code_${_index} .decodeHex () )`
		) .join ('\n')} } }
		` )
		(
		[ ... _contract_names .map (_contract_name => flow_sdk_api .arg (_contract_name, flow_types .String))
		, ... _contract_code_hexs .map (_contract_code_hex => flow_sdk_api .arg (_contract_code_hex, flow_types .String)) ] ) }

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



export { authorizer_ }
export { send_transaction_, execute_script_, deploy_contract_, update_contract_, update_contracts_, create_account_ }
