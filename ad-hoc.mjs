import flow_types from '@onflow/types'
import { send_proposed_transaction_, send_known_transaction_} from './utils/flow.mjs'
import { flow_sdk_api } from './config.mjs'

var __dirname = new URL ('.', import .meta .url) .pathname

;console.log(
	JSON.stringify(
		await send_known_transaction_
			("./transactions")
			("list-for-sale")
			(['0xARTIST_1'])
			([
				flow_sdk_api. arg("iio", flow_types .String),
				flow_sdk_api. arg("Flow", flow_types .String),
				flow_sdk_api. arg("2.4", flow_types .UFix64)
			])
		, null, 4)
)
