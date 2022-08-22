import flow_types from '@onflow/types'
import { send_known_transaction_, run_known_test_from_, cadencify_object_} from './utils/flow.mjs'
import { flow_sdk_api } from './config.mjs'

var __dirname = new URL ('.', import .meta .url) .pathname
var send_known_transaction__ = send_known_transaction_ ('./transactions');


console.log(
    JSON.stringify(
        await send_known_transaction__('get-nft-serialID')
        (['0xPONS'])
        ([flow_sdk_api.arg('565677', flow_types.String)])

, null, 4))
