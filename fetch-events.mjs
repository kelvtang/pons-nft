import fcl_api from '@onflow/fcl'
import { flow_sdk_api } from "./config.mjs"


const args = process.argv.slice(2)

var add_event_listener_ = _contract_address => _contract_name =>  _event_type => async _start => {

	// concat arguements to get the full event name which will be used for query
	var _event_name = `A.${_contract_address}.${_contract_name}.${_event_type}`

	// get height of latest block
	var _latest_block = await fcl_api.send([fcl_api.getBlock(true),])
	
	var _end = _latest_block.block.height

	var _response = []

	// can only read 250 blocks at a time
	for (var _i = _start; _start < _end; _start += 250) {
		var _res;
		if (_i + 249 > _end) {
			_res = await fcl_api.send([fcl_api.getEventsAtBlockHeightRange(_event_name, _i, _end)])
		} else {
			_res = await fcl_api.send([fcl_api.getEventsAtBlockHeightRange(_event_name, _i, _i + 249)])
		}
		const {events} = _res
		var _payloads = events.map(_e => {
			return {
				contract_address : _e.payload.value.id.split('.')[1],
				contract_name: _e.payload.value.id.split('.')[2],
				event_type: _e.payload.value.id.split('.')[3],
				data: JSON.stringify({..._e.payload.value.fields}),
				block_height: _e.blockHeight,
				latest_block_height: _end
			}

		})
		_response = [..._response, ..._payloads]
	}

	if (_response){
			console.log(JSON.stringify({events: _response}))
	}
}

add_event_listener_(args[0])(args[1])(args[2])(parseInt(args[3]))