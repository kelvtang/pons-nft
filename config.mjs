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
	"0x07eC6512C66617fc0Dea66eF8A0622E648481149",
	"0x167C27d597607491d6416e05c2cCB528087ed834",
	"0xE9949B8def6cb4DfF4E8557d564674f0ca91dc77",
	"0x21c90eC9077338Ab30a908f66CD14385Da9FCC36",
	"0xa66a949790Aa765AFbfB589192aE5D2235BCEF5F",
	"0x118a30A2287d0c8C0B71842A291dDC52e02A4288",
	"0xBC1202fBC323ef56aCC361BfF3b841Dc930f8374",
	"0xb8b0e4354868BF1FbA707A733C71511cC9334C3B",
	"0x4df7434B5aAa98A572Bb4c7f77864726C43d2D97",
	"0x365db4634887E8208a00025948E7AFD7795E7692",
]

// ganache-cli
const PRIVATE_KEYS = [
	"0x1ce1c439dfa2245884d240f8c8b2bb1508e3d838c39ac41e241f95a12cb47fc1",
	"0xd86058e7d22c5aa38cb8aee96af861b764a3a2b03df5bc963c3f3eec25d2686d",
	"0x73bc4bfab92abb0cb8f625c1a1ccf273853f7adbae9fedb539df37128facbeb9",
	"0xa61101ac634a6dc0e27df990f043198a6bc168a717ce59f90fc4f4594c1b8b9d",
	"0xb3bf1a1480e06fe750413906baf78c2b6271e25c5392f27945b023b999a7418b",
	"0x5d9a4ceb3816822edfb43ae223ffacb500aab0d69385983229341bd71a296dac",
	"0x64221bab3bd5bf12f88bf0832c74ab7326cefb0bff26ce1688ec2f1a92c23f2f",
	"0xa248a87c64c49f013e18132a74d5c743f4d61c653cf69701148320316fbb526b",
	"0xaf9cb5b554af42cbc6020702af7caa3c4855b72aaf74613f23fc5ebe3c6dd1bd",
	"0x6f648defab380755373d2d00da4183ba3d4ef43e81cf5e3ef1c04add11943f35"
]

const ROOT_TUNNEL_CONTRACT_ADDRESS = "0x07eC6512C66617fc0Dea66eF8A0622E648481149" // Owner is Account[0]
const CHILD_TUNNEL_CONTRACT_ADDRESS = "0x167C27d597607491d6416e05c2cCB528087ed834" // Owner is Account[1]
const ROOT_TOKEN_ADDRESS = "0xa66a949790Aa765AFbfB589192aE5D2235BCEF5F"
const CHILD_TOKEN_ADDRESS = "0x118a30A2287d0c8C0B71842A291dDC52e02A4288"


// TODO: Change based on our actual server address
const BASE_TOKEN_URI = "https://6f2d-61-244-192-118.ap.ngrok.io/metadata/";

;flow_sdk_api .config ()
	.put("sdk.transport", grpcSend)
	.put("accessNode.api", access_node_origin)
	// .put("accessNode.api", " https://access-mainnet-beta.onflow.org")





export { flow_sdk_api }

export { access_node_origin }

export { address_of_names, private_keys_of_names }
export { ad_hoc_accounts, pons_artist_id_of_names }
export { ACCOUNT_ADDRESSES, PRIVATE_KEYS }
export { ROOT_TUNNEL_CONTRACT_ADDRESS, CHILD_TUNNEL_CONTRACT_ADDRESS, ROOT_TOKEN_ADDRESS, CHILD_TOKEN_ADDRESS }
export { BASE_TOKEN_URI }
