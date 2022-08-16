import { v4 } from 'uuid'
import flow_sdk_api from '@onflow/sdk'
import { send as grpcSend } from "@onflow/transport-grpc"








let access_node_origin = /*/'http://lvh.me:8888'/*/'https://rest-testnet.onflow.org'//'https://rest-mainnet.onflow.org'/**/



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
	"0xaC39b311DCEb2A4b2f5d8461c1cdaF756F4F7Ae9",
	"0xD7c0Cd9e7d2701c710D64Fc492C7086679BdF7b4",
	"0x1acFb961C5A8268EAc8e09d6241a26CBEFF42241",
	"0xaBC2bCA51709b8615147352C62420F547a63A00c",
	"0x26042cb13Cc4140a281C0fCc7464074c5e9fD0B4",
	"0x5d0D1A012A3Ab2B3424c2023246d8c834Bf599D9",
	"0xECC9BaA0e1454d20d0d6be3c01EDD58CEe9Da0f6",
	"0x79b7E1d28eFf3cCCB9B49143314Dd04b7FA09FCc",
	"0x452887EAF3B60448653e1024C9E5CdEb24f002C1",
	"0x8aA2ccb35f90EFf1c6f38ed43e550b67E8aDC728",
]

// ganache-cli
const PRIVATE_KEYS = [
	"0xb96e9ccb774cc33213cbcb2c69d3cdae17b0fe4888a1ccd343cbd1a17fd98b18",
	"0x7d27cb85ef5e8c319099e8c390b3018e646bed8e32594a655294d20a3496b7c2",
	"0xa5b76293595735a9fa409894c6d03e607046b1fbc42cc6bf23d5fbc25ba9e235",
	"0x578a438ff112de8c86338b4c90b325d0c0e149580c1af21cb518a4730dde52ba",
	"0x763b51bb0580d9fedb9850c6a28baec5f0016edfaca36cf026bb1f0cb80a6f96",
	"0x50cde187eef8a8fed874b90e6d628f4147af6eeb06371ce8d6ac39f505d6e2a3",
	"0x4b92e1be8b84a7535a01191873881e17684579a22e8e1edb887ef34f79f50e4f",
	"0x3b7f5cf5726cbfe765dde21265aa53f2b8e816e9227d113a354ec21ec219411e",
	"0xbfcba3c2ee7fe24a258710d7966b7aeb4fa3447bfdcba9d7e71cf9c50e0dfd22",
	"0xc10059c762a98075390e82cdb851b24f6d65b329ebe5777a74bfb8d245d72089"
]


const CHILD_FX_TOKEN_PROXY_ADDRESS = ""
const ROOT_FX_TOKEN_PROXY_ADDRESS = ""
const CHILD_TUNNEL_PROXY_ADDRESS = ""
const ROOT_TUNNEL_PROXY_ADDRESS = ""
const CHILD_PROXY_ADMIN_ADDRESS = ""
const ROOT_PROXY_ADMIN_ADDRESS = ""
const FX_MANAGER_PROXY_ADDRESS = ""
const FLOW_MARKETPLACE_ADDRESS = ""
const POLYGON_MARKETPLACE_ADDRESS = ""
const PONS_NFT_TUNNEL_ADDRESS = ""

const GANACHE_PROVIDER_CHILD = "http://127.0.0.1:7545"
const GANACHE_PROVIDER_ROOT = "http://127.0.0.1:8545"

const BURN_PROOF_EVENT_SIG = "0x8c5261668696ce22758910d05bab8f186d6eb247ceac2af2e82c7dc17669b036"
const NETWORK_TYPE = "testnet"
const NETWORK_NAME = "mumbai"

const FLOW_EVENT_NAME = ""
const FLOW_EVENT_NAME_NOT_LISTED = ""
const POLYGON_EVENT_NAME = ""

const BASE_TOKEN_URI = "";

const METAMASK_ACCOUNT_PRIVATE_KEY = ""
const POLYGON_PROVIDER_URL = ""

; flow_sdk_api.config()
	.put("sdk.transport", grpcSend)
	.put("accessNode.api", access_node_origin)
// .put("accessNode.api", " https://access-mainnet-beta.onflow.org")





export { flow_sdk_api }

export { access_node_origin }

export { address_of_names, private_keys_of_names }
export { ad_hoc_accounts, pons_artist_id_of_names }
export { ACCOUNT_ADDRESSES, PRIVATE_KEYS, GANACHE_PROVIDER_CHILD, GANACHE_PROVIDER_ROOT, METAMASK_ACCOUNT_PRIVATE_KEY, POLYGON_PROVIDER_URL }
export { CHILD_TUNNEL_PROXY_ADDRESS, ROOT_TUNNEL_PROXY_ADDRESS, CHILD_FX_TOKEN_PROXY_ADDRESS, ROOT_FX_TOKEN_PROXY_ADDRESS, CHILD_PROXY_ADMIN_ADDRESS, ROOT_PROXY_ADMIN_ADDRESS, FX_MANAGER_PROXY_ADDRESS, FLOW_MARKETPLACE_ADDRESS, POLYGON_MARKETPLACE_ADDRESS, PONS_NFT_TUNNEL_ADDRESS }
export { BASE_TOKEN_URI, FLOW_EVENT_NAME, FLOW_EVENT_NAME_NOT_LISTED, POLYGON_EVENT_NAME }
export { NETWORK_TYPE, NETWORK_NAME, BURN_PROOF_EVENT_SIG }
