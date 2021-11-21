import { substitutions_of_addresses, private_keys_of_addresses } from '../utils/config.mjs'
import { authorizer_ } from '../utils/flow.mjs'
import { create_account_ } from '../utils/flow.mjs'


var address = substitutions_of_addresses ['0xPONS']
var key_id = 0
var private_key = private_keys_of_addresses ['0xPONS'] [key_id]

var authorizer = authorizer_ (address) (key_id) (private_key)


var stringify_ = _value => JSON .stringify (_value)
var output_ = _value => {
	;console .log (stringify_ (_value)) }



var _flow_response =
	await 
	create_account_
	( authorizer )

;output_ (_flow_response)
