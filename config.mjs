import { v4 } from 'uuid'
import flow_sdk_api from '@onflow/sdk'
// import { send } from '@onflow/transport-grpc'








let access_node_origin = /**/'http://lvh.me:8888'/*/'https://rest-testnet.onflow.org'//'https://rest-mainnet.onflow.org'/**/


/*Emulator*/
let address_of_names =
	{ '0xFUNGIBLETOKEN': '0xee82856bf20e2aa6'
	, '0xFLOWTOKEN': '0x0ae53cb6e3f42a79' 
	, '0xNONFUNGIBLETOKEN': '0xf8d6e0586b0a20c7'
	, '0xFUSD':'0xf8d6e0586b0a20c7' 
	, '0xPONS': '0xf8d6e0586b0a20c7'
	, '0xPROPOSER': '0xf8d6e0586b0a20c7' }
let private_keys_of_names =
	{ '0xPONS': [ '4b01a799da096bddda4c19d04e966cb05cfbe610df117ef9713d382483956070' ]
	, '0xPROPOSER': [ '4b01a799da096bddda4c19d04e966cb05cfbe610df117ef9713d382483956070' ] }


/*Testnet*/
// let address_of_names =
//         { '0xFUNGIBLETOKEN': '0x9a0766d93b6608b7'
//         , '0xFLOWTOKEN': '0x7e60df042a9c0868'
//         , '0xNONFUNGIBLETOKEN': '0x631e88ae7f1d7c20'
// 		, '0xFUSD':'0xe223d8a629e49c68'
//         , '0xPONS': '0xf0c7da31409b4012'
//         , '0xPROPOSER': '0xf0c7da31409b4012'}
// let private_keys_of_names =
//         { '0xPONS': [ '18e869feb115ebdc8180bff284868bbbb70a85c335ec4480238712ef8f79bb12']
//         , '0xPROPOSER': [ '18e869feb115ebdc8180bff284868bbbb70a85c335ec4480238712ef8f79bb12']}




let ad_hoc_accounts =
	{ '0xARTIST_1': 
		{ private_key: 'c11341eaa8555b5da488fbc057e6c531e7a82776a2e9e4874501e8499e56925e' 
		, public_key: '36d01bc278e11bb32523a89598f6dd09a207772bd52959026855b9eb48deab7588afd7f11a417136da254942c868e5bd286384e933715f44f5936741c745075e' }
	, '0xARTIST_2': 
		{ private_key: '1e06e7c7d1d2c992fe36352e7a597601c86a677871fb2344bcdfe168729820dd' 
		, public_key: 'ba6889066e202f53db1d1893e999014ada2f92e629cc6baf8fb979cf621d19edc4be018b938b3eb4700bd4931340b91cfb85df75494e9acebff93a25b0627f05' }
	, '0xPATRON_1': 
		{ private_key: 'e215a3472f028eabcc290626d9b4efe28da89607ee9f0ad7d2680376c19e3525' 
		, public_key: '2e965d64280212c1d44400ce25f2daff04f083bafaf48270065658aa0256fd2ba88030002987fa1029070fa689ed12d54623acca2dcc60fa2c1246893c92c176' }
	, '0xPATRON_2': 
		{ private_key: '1e8bb09e128f45cd63b4d4c95c6d523dff39f4964b73a2cf8c5133b2ec9e9097' 
		, public_key: '49e73bef1fedbda031bbf3af85bcc44d1c731c5338b80b1f9eb092c42d0bfaef91347321779bae6efb1ac085d5a26ea346e2067ad92baef5ead836b79dbfad45' }
	, '0xRESELLER_1': 
		{ private_key: 'e2f4948d8854c49e8ac4e38ba78519970dacd862b0f3fdb4ae05cebc0fb42c88' 
		, public_key: 'aa1f19f39139567159fa016ec866bbe1b59bd626bb12b50e3d30263f160c33942ee61c20305bc6a83bc699471ad18eab56c8e86fbcc9e49a8c6c7401b2a91839' }
	, '0xRESELLER_2':
		{ private_key: '88e6ad857eeae618576f228f0e3070785452cf5c2b0a6917341553772785ccdd' 
		, public_key: 'ff8b2b79efa2e1fa1f06594cc6fba8cf5955651c87879d2fbe0c3592f51ec21a76553db85d29147b9b993ec2f04bb783fb3cf221be58497599d3c59d17d11436' }
	, '0xRANDOM_1':
		{ private_key: '767567415a552eca8375db29ebea6f063d1b6d2168024e36588e93d03dd7fe58' 
		, public_key: 'd7b19fb5c74a3264d26e420eba384b07dba2771da78c1a74d0d666a8c60a6348b78490d68b956247912785f5d81c4a03923af80dfcd5b1b8e3a3702c6d9acd48' }
	, '0xRANDOM_2':
		{ private_key: 'ae15465ea647af298a82686cfc0cbc7f5e9185179b886a145d1239167131779e' 
		, public_key: 'e91a6286ebd16f9b3777446ce48dfa2fe7f8450661fffdf085206e50cb0d07ff2f92bfcbea47f6fc13a9d0945bcad97a25b2e26d61f063e946d15341524f3a3d' }
	}

let pons_artist_id_of_names =
	{ '0xARTIST_1': v4 ()
	, '0xARTIST_2': v4 ()
	}









;flow_sdk_api .config ()
	// .put ('sdk.transport', send)
	.put ('accessNode.api', access_node_origin)





export { flow_sdk_api }

export { access_node_origin }

export { address_of_names, private_keys_of_names }
export { ad_hoc_accounts, pons_artist_id_of_names }
