import flow_types from '@onflow/types'
import { send_known_transaction_} from './utils/flow.mjs'
import { flow_sdk_api } from './config.mjs'

//
var __dirname = new URL ('.', import .meta .url) .pathname
var send_known_transaction__ = send_known_transaction_ (__dirname + '/transactions/');


/* Initializes Fusd Wallet */
;console .log (
	JSON .stringify
	( await send_known_transaction__ ("setup-fusd")
		( [ '0xPONS' ] )
		( [] ), null, 4 ) )

/* Set up minter and saves it */
;console .log (
	JSON .stringify
	( await send_known_transaction__ ("setup-fusd-minter")
		( [ '0xPONS' ] )
		( [] ), null, 4 ) )
;console .log (
	JSON .stringify
	( await send_known_transaction__ ("deposit-fusd-minter")
		( [ '0xPONS' ] )
		( [flow_sdk_api .arg('0xf8d6e0586b0a20c7', flow_types .Address)] ), null, 4 ) )

/* Mints Fusd on testnet */
;console .log (
	JSON .stringify
	( await send_known_transaction__ ("mint-fusd-on-emulator")
		( [ '0xPONS' ] )
		( [flow_sdk_api .arg('100000.0', flow_types .UFix64), flow_sdk_api .arg('0xf8d6e0586b0a20c7', flow_types .Address)] ), null, 4 ) )
