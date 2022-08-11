import { v4 } from 'uuid'
import flow_sdk_api from '@onflow/sdk'
import { send as grpcSend } from "@onflow/transport-grpc"








let access_node_origin = /*/'http://lvh.me:8888'/*/'https://rest-testnet.onflow.org'//'https://rest-mainnet.onflow.org'/**/


/*Emulator*/
let address_of_names =
{
	'0xFUNGIBLETOKEN': '0xee82856bf20e2aa6'
	, '0xFLOWTOKEN': '0x0ae53cb6e3f42a79'
	, '0xNONFUNGIBLETOKEN': '0xf8d6e0586b0a20c7'
	, '0xPONS': '0xf8d6e0586b0a20c7'
	, '0xPROPOSER': '0xf8d6e0586b0a20c7'
}
let private_keys_of_names =
{
	'0xPONS': ['5983ba3ff97b3ab62c96c3aa35b4f08460284936fc4562cad425fcc6c97f9b3a']
	, '0xPROPOSER': ['5983ba3ff97b3ab62c96c3aa35b4f08460284936fc4562cad425fcc6c97f9b3a']
}





let ad_hoc_accounts =
{
	'0xARTIST_1':
	{
		private_key: 'c11341eaa8555b5da488fbc057e6c531e7a82776a2e9e4874501e8499e56925e'
		, public_key: '36d01bc278e11bb32523a89598f6dd09a207772bd52959026855b9eb48deab7588afd7f11a417136da254942c868e5bd286384e933715f44f5936741c745075e'
	}
	, '0xARTIST_2':
	{
		private_key: '1e06e7c7d1d2c992fe36352e7a597601c86a677871fb2344bcdfe168729820dd'
		, public_key: 'ba6889066e202f53db1d1893e999014ada2f92e629cc6baf8fb979cf621d19edc4be018b938b3eb4700bd4931340b91cfb85df75494e9acebff93a25b0627f05'
	}
	, '0xPATRON_1':
	{
		private_key: 'e215a3472f028eabcc290626d9b4efe28da89607ee9f0ad7d2680376c19e3525'
		, public_key: '2e965d64280212c1d44400ce25f2daff04f083bafaf48270065658aa0256fd2ba88030002987fa1029070fa689ed12d54623acca2dcc60fa2c1246893c92c176'
	}
	, '0xPATRON_2':
	{
		private_key: '1e8bb09e128f45cd63b4d4c95c6d523dff39f4964b73a2cf8c5133b2ec9e9097'
		, public_key: '49e73bef1fedbda031bbf3af85bcc44d1c731c5338b80b1f9eb092c42d0bfaef91347321779bae6efb1ac085d5a26ea346e2067ad92baef5ead836b79dbfad45'
	}
	, '0xRESELLER_1':
	{
		private_key: 'e2f4948d8854c49e8ac4e38ba78519970dacd862b0f3fdb4ae05cebc0fb42c88'
		, public_key: 'aa1f19f39139567159fa016ec866bbe1b59bd626bb12b50e3d30263f160c33942ee61c20305bc6a83bc699471ad18eab56c8e86fbcc9e49a8c6c7401b2a91839'
	}
	, '0xRESELLER_2':
	{
		private_key: '88e6ad857eeae618576f228f0e3070785452cf5c2b0a6917341553772785ccdd'
		, public_key: 'ff8b2b79efa2e1fa1f06594cc6fba8cf5955651c87879d2fbe0c3592f51ec21a76553db85d29147b9b993ec2f04bb783fb3cf221be58497599d3c59d17d11436'
	}
	, '0xRANDOM_1':
	{
		private_key: '767567415a552eca8375db29ebea6f063d1b6d2168024e36588e93d03dd7fe58'
		, public_key: 'd7b19fb5c74a3264d26e420eba384b07dba2771da78c1a74d0d666a8c60a6348b78490d68b956247912785f5d81c4a03923af80dfcd5b1b8e3a3702c6d9acd48'
	}
	, '0xRANDOM_2':
	{
		private_key: 'ae15465ea647af298a82686cfc0cbc7f5e9185179b886a145d1239167131779e'
		, public_key: 'e91a6286ebd16f9b3777446ce48dfa2fe7f8450661fffdf085206e50cb0d07ff2f92bfcbea47f6fc13a9d0945bcad97a25b2e26d61f063e946d15341524f3a3d'
	}
}

let pons_artist_id_of_names =
{
	'0xARTIST_1': v4()
	, '0xARTIST_2': v4()
}



const MNEMONIC_PHRASE = "radar blur cabbage chef fix engine embark joy scheme fiction master release"


// ganache-cli
const ACCOUNT_ADDRESSES = [
	"0x49dfBB5b17910Ee3b51b3f7F6873d7142CDE68F1",
	"0x4f0208C95c7E21BD28f29D45C77ab0906B7AdD9E",
	"0x14a1A67A1d18ebA5B38C95895A4c764405e6655f",
	"0x5DCC066C661426a9d84a14b1da0aC785cbAd70a2",
	"0xAC8Dd1eCfd804B70AFc74624B2A03043BD9E1991",
	"0x1d21Bc92905e4744E646ADBCFb93ec61b04f2b21",
	"0xcc036cd8f8469b7D067911509E65ce4342E6Dd34",
	"0x5a9B50215c3BfFBa4a7982bFABF3C615Fb6107C1",
	"0x468fecDB5200e97eE5F52760fc3425E43bd8dC78",
	"0xb9Dc38691CB2383e88abB2622CE1DfF73101a7c4"
]

// ganache-cli
const PRIVATE_KEYS = [
	"0xe3dd8a292b98033326ca1e1586852e38507fbae74ed3856a5d05589fb5b3775f",
	"0x5b63b8dac815ee27d9bf06e1598da7455b12f37f11452004c8464254c76cc669",
	"0x3677a623b70370eb03e0c1604f90491184f316d36f6b4a1084c064a1cf739c07",
	"0x2b9585542d3da08192a5e7bbdb5dd54cf6f573edee2a82870c18298fdef32968",
	"0x8dc5b32c42257ddfbdabe970190ed18819de563edf93127c743fd1b70b9d25bf",
	"0x973fbff95897d44f224c4ce4939e0a519c9159ad8fc875d1fa094bae74e6367d",
	"0xe4b74cb0ddd96ba616b15f47cca8122a38f19bf2952ef3f09cc70f496d5d92d1",
	"0x7aa277798acb59740fa9f35c649741a2b8e702aec557a0b9785e8662ad5b6373",
	"0x92113e9c3cecbedee82cb6875cf1692cbeac3909406621f20a802df77af07985",
	"0x54dc1f227612fbd2f66ab224bddc55713977d6e207b48d95d13c5022da2d4acc"
]


const CHILD_TOKEN_PROXY_ADDRESS = ""
const ROOT_TOKEN_PROXY_ADDRESS = ""
const CHILD_TUNNEL_PROXY_ADDRESS = ""
const ROOT_TUNNEL_PROXY_ADDRESS = ""
const CHILD_ADMIN_PROXY = ""
const ROOT_ADMIN_PROXY = ""

const GANACHE_PROVIDER_CHILD = "http://127.0.0.1:7545"
const GANACHE_PROVIDER_ROOT = "http://127.0.0.1:8545"

const BURN_PROOF_EVENT_SIG = "0x8c5261668696ce22758910d05bab8f186d6eb247ceac2af2e82c7dc17669b036"
const NETWORK_TYPE = "testnet"
const NETWORK_NAME = "mumbai"

// TODO: Change to the actual event name
const EVENT_NAME = ""

// TODO: Change based on our actual server address
const BASE_TOKEN_URI = "";

; flow_sdk_api.config()
	.put("sdk.transport", grpcSend)
	.put("accessNode.api", access_node_origin)
// .put("accessNode.api", " https://access-mainnet-beta.onflow.org")





export { flow_sdk_api }

export { access_node_origin }

export { address_of_names, private_keys_of_names }
export { ad_hoc_accounts, pons_artist_id_of_names }
export { ACCOUNT_ADDRESSES, PRIVATE_KEYS, GANACHE_PROVIDER_CHILD, GANACHE_PROVIDER_ROOT }
export { CHILD_TUNNEL_PROXY_ADDRESS, ROOT_TUNNEL_PROXY_ADDRESS, CHILD_TOKEN_PROXY_ADDRESS, ROOT_TOKEN_PROXY_ADDRESS, CHILD_ADMIN_PROXY, ROOT_ADMIN_PROXY }
export { BASE_TOKEN_URI, EVENT_NAME }
export { NETWORK_TYPE, NETWORK_NAME, BURN_PROOF_EVENT_SIG }
