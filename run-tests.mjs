import { v4 } from 'uuid'
import flow_types from '@onflow/types'
import { cadencify_object_ } from './utils/flow.mjs'
import { make_known_ad_hoc_account_, run_known_test_from_ } from './utils/flow.mjs'
import { flow_sdk_api } from './config.mjs'
import { address_of_names, pons_artist_id_of_names } from './config.mjs'
import { artist_authority_storage_path, minter_storage_path } from './config.mjs'

var __dirname = new URL ('.', import .meta .url) .pathname
var run_known_test_ = run_known_test_from_ (__dirname + '/tests/')


;await
	make_known_ad_hoc_account_ ('0xARTIST_1')
;await
	make_known_ad_hoc_account_ ('0xPATRON_1')
;await
	make_known_ad_hoc_account_ ('0xRANDOM_1')



//;await run_known_test_
//	( 'unit-tests/pons-utils/flow-units/is-at-least' )
//	( [] )
//	( [] )
//;await run_known_test_
//	( 'unit-tests/pons-utils/flow-units/scale' )
//	( [] )
//	( [] )


////;await run_known_test_
////	( 'unit-tests/pons-utils/prepare-flow-capability' )
////	( [ '0xRANDOM_1' ] )
////	( [] )


;await run_known_test_
	( 'integration-tests/recognise-artist/on-chain' )
	( [ '0xPONS' ] )
	(
	[ flow_sdk_api .arg ({ domain: 'storage', identifier: artist_authority_storage_path }, flow_types .Path)
	, flow_sdk_api .arg (pons_artist_id_of_names ['0xARTIST_1'], flow_types .String)
	, flow_sdk_api .arg (address_of_names ['0xARTIST_1'], flow_types .Address)
	, flow_sdk_api .arg
		( cadencify_object_ (
			{ first_name: 'Artist'
			, last_name: 'One'
			, url: 'pons://artist-1' } )
		, flow_types .Dictionary ({ key: flow_types .String, value: flow_types .String }) ) ] )

;await run_known_test_
	( 'integration-tests/artist-certificate/make-from-artist' )
	( [ '0xARTIST_1' ] )
	( [] )

;await run_known_test_
	( 'integration-tests/artist-certificate/fail-to-make-from-non-artist' )
	( [ '0xRANDOM_1' ] )
	( [] )

;await run_known_test_
	( 'integration-tests/artist-certificate/make-from-artist-authority' )
	( [ '0xPONS' ] )
	(
	[ flow_sdk_api .arg ({ domain: 'storage', identifier: artist_authority_storage_path }, flow_types .Path)
	, flow_sdk_api .arg (pons_artist_id_of_names ['0xARTIST_1'], flow_types .String) ] )

;await run_known_test_
	( 'integration-tests/direct-mint-nft' )
	( [ '0xPONS', '0xARTIST_1' ] )
	(
	[ flow_sdk_api .arg ({ domain: 'storage', identifier: minter_storage_path }, flow_types .Path)
	, flow_sdk_api .arg (v4 (), flow_types .String)
	, flow_sdk_api .arg (pons_artist_id_of_names ['0xARTIST_1'], flow_types .String)
	, flow_sdk_api .arg ('0.10', flow_types .UFix64)
	, flow_sdk_api .arg ('Only edition', flow_types .String)
	, flow_sdk_api .arg
		( cadencify_object_ (
			{ url: 'pons://nft-link'
			, title: 'NFT title'
			, description: 'NFT description' } )
		, flow_types .Dictionary ({ key: flow_types .String, value: flow_types .String }) ) ] )

;await run_known_test_
	( 'integration-tests/marketplace/mint' )
	( [ '0xPONS', '0xARTIST_1' ] )
	(
	[ flow_sdk_api .arg ({ domain: 'storage', identifier: minter_storage_path }, flow_types .Path)
	, flow_sdk_api .arg ([ v4 (), v4 (), v4 (), v4 (), v4 () ], flow_types .Array (flow_types .String))
	, flow_sdk_api .arg
		( cadencify_object_ (
			{ url: 'pons://nft-link-2'
			, title: 'NFT title 2'
			, description: 'NFT description 2' } )
		, flow_types .Dictionary ({ key: flow_types .String, value: flow_types .String }) )
	, flow_sdk_api .arg (5, flow_types .Int)
	, flow_sdk_api .arg ('500.0', flow_types .UFix64)
	, flow_sdk_api .arg ('10.0', flow_types .UFix64)
	, flow_sdk_api .arg ('0.05', flow_types .UFix64) ] )

;await run_known_test_
	( 'integration-tests/marketplace/complete-journey' )
	( [ '0xPONS', '0xARTIST_1', '0xPATRON_1', '0xRANDOM_1' ] )
	(
	[ flow_sdk_api .arg ({ domain: 'storage', identifier: minter_storage_path }, flow_types .Path)
	, flow_sdk_api .arg ([ v4 (), v4 (), v4 (), v4 (), v4 () ], flow_types .Array (flow_types .String))
	, flow_sdk_api .arg
		( cadencify_object_ (
			{ url: 'pons://nft-link-3'
			, title: 'NFT title 3'
			, description: 'NFT description 3' } )
		, flow_types .Dictionary ({ key: flow_types .String, value: flow_types .String }) )
	, flow_sdk_api .arg (5, flow_types .Int)
	, flow_sdk_api .arg ('500.0', flow_types .UFix64)
	, flow_sdk_api .arg ('10.0', flow_types .UFix64)
	, flow_sdk_api .arg ('0.05', flow_types .UFix64) ] )
