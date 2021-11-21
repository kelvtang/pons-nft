import flow_sdk_api from '@onflow/sdk'


let access_node_origin = /**/'http://lvh.me:8080' /*/'https://access-mainnet-beta.onflow.org'/**/

let substitutions_of_addresses =
	{ '0xFUNGIBLETOKEN': '0xee82856bf20e2aa6'
	, '0xFLOWTOKEN': '0x0ae53cb6e3f42a79' 
	, '0xNONFUNGIBLETOKEN': '0xf8d6e0586b0a20c7' 
	, '0xPONS': '0xf8d6e0586b0a20c7' }
let private_keys_of_addresses =
	{ '0xPONS': [ '5983ba3ff97b3ab62c96c3aa35b4f08460284936fc4562cad425fcc6c97f9b3a' ] }


;flow_sdk_api .config () .put ('accessNode.api', access_node_origin)


export { flow_sdk_api }
export { access_node_origin, substitutions_of_addresses, private_keys_of_addresses }
