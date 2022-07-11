import { v4 } from 'uuid'
import flow_types from '@onflow/types'
import { cadencify_object_ } from './utils/flow.mjs'
import { make_known_ad_hoc_account_, run_known_test_from_, run_known_test_returnTransaction } from './utils/flow.mjs'
import { flow_sdk_api } from './config.mjs'
import { address_of_names, pons_artist_id_of_names } from './config.mjs'

var __dirname = new URL ('.', import .meta .url) .pathname
var run_known_test_ = run_known_test_from_ (__dirname + '/tests/')
var run_known_test_getTransaction_ = run_known_test_returnTransaction (__dirname + '/tests/')


;await
	make_known_ad_hoc_account_ ('0xARTIST_1')
;await
	make_known_ad_hoc_account_ ('0xPATRON_1')
;await
	make_known_ad_hoc_account_ ('0xRANDOM_1')
;await
	make_known_ad_hoc_account_ ('0xRANDOM_2')



;await run_known_test_
	( 'integration-tests/recognise-artist/on-chain' )
	( [ '0xPONS' ] )
	(
	[ flow_sdk_api .arg ({ domain: 'storage', identifier: 'ponsArtistAuthority' }, flow_types .Path)
	, flow_sdk_api .arg (pons_artist_id_of_names ['0xARTIST_1'], flow_types .String)
	, flow_sdk_api .arg (address_of_names ['0xARTIST_1'], flow_types .Address)
	, flow_sdk_api .arg
		( cadencify_object_ (
			{ first_name: 'Artist'
			, last_name: 'One'
			, url: 'pons://artist-1' } )
		, flow_types .Dictionary ({ key: flow_types .String, value: flow_types .String }) ) ] )

;await run_known_test_
	( 'integration-tests/recognise-artist/off-chain' )
	( [ '0xPONS' ] )
	(
	[ flow_sdk_api .arg ({ domain: 'storage', identifier: 'ponsArtistAuthority' }, flow_types .Path)
	, flow_sdk_api .arg (pons_artist_id_of_names ['0xARTIST_2'], flow_types .String)
	, flow_sdk_api .arg
		( cadencify_object_ (
			{ first_name: 'Artist-2'
			, last_name: 'Two'
			, url: 'pons://artist-2' } )
		, flow_types .Dictionary ({ key: flow_types .String, value: flow_types .String }) ) ] )


;await run_known_test_
	( 'unit-tests/pons-utils/flow-units/is-at-least' )
	( [] )
	( [] )
;await run_known_test_
	( 'unit-tests/pons-utils/flow-units/scale' )
	( [] )
	( [] )

// WORKAROUND -- ignore
// For some inexplicable reason Flow is not recognising `&PonsNftContract_v1.Collection` as `&NonFungibleToken.Collection`
//;await run_known_test_
//	( 'unit-tests/pons-utils/normalise-collection/already-normalised-collection' )
//	( [ '0xPONS', '0xARTIST_1', '0xRANDOM_2' ] )
//	(
//	[ flow_sdk_api .arg ({ domain: 'storage', identifier: 'ponsMinter' }, flow_types .Path)
//	, flow_sdk_api .arg ([ v4 (), v4 (), v4 (), v4 (), v4 () ], flow_types .Array (flow_types .String))
//	, flow_sdk_api .arg
//		( cadencify_object_ (
//			{ url: 'pons://nft-link-1'
//			, title: 'NFT title 1'
//			, description: 'NFT description 1' } )
//		, flow_types .Dictionary ({ key: flow_types .String, value: flow_types .String }) )
//	, flow_sdk_api .arg ('5', flow_types .Int)
//	, flow_sdk_api .arg ('1200.0', flow_types .UFix64)
//	, flow_sdk_api .arg ('180.0', flow_types .UFix64)
//	, flow_sdk_api .arg ('0.12', flow_types .UFix64) ] )
//
//;await run_known_test_
//	( 'unit-tests/pons-utils/normalise-collection/unnormalised-collection' )
//	( [ '0xPONS', '0xARTIST_1', '0xRANDOM_2' ] )
//	(
//	[ flow_sdk_api .arg ({ domain: 'storage', identifier: 'ponsMinter' }, flow_types .Path)
//	, flow_sdk_api .arg ([ v4 (), v4 (), v4 (), v4 (), v4 () ], flow_types .Array (flow_types .String))
//	, flow_sdk_api .arg
//		( cadencify_object_ (
//			{ url: 'pons://nft-link-2'
//			, title: 'NFT title 2'
//			, description: 'NFT description 2' } )
//		, flow_types .Dictionary ({ key: flow_types .String, value: flow_types .String }) )
//	, flow_sdk_api .arg ('5', flow_types .Int)
//	, flow_sdk_api .arg ('1200.0', flow_types .UFix64)
//	, flow_sdk_api .arg ('180.0', flow_types .UFix64)
//	, flow_sdk_api .arg ('0.12', flow_types .UFix64) ] )

;await run_known_test_
	( 'unit-tests/artist-certificate/make-from-artist' )
	( [ '0xARTIST_1' ] )
	( [] )

;await run_known_test_
	( 'unit-tests/artist-certificate/make-from-non-artist-fails' )
	( [ '0xRANDOM_1' ] )
	( [] )

;await run_known_test_
	( 'unit-tests/artist-certificate/make-from-artist-authority' )
	( [ '0xPONS' ] )
	(
	[ flow_sdk_api .arg ({ domain: 'storage', identifier: 'ponsArtistAuthority' }, flow_types .Path)
	, flow_sdk_api .arg (pons_artist_id_of_names ['0xARTIST_1'], flow_types .String) ] )



;await run_known_test_
	( 'integration-tests/minter/mint-nft' )
	( [ '0xPONS', '0xARTIST_1' ] )
	(
	[ flow_sdk_api .arg ({ domain: 'storage', identifier: 'ponsMinter' }, flow_types .Path)
	, flow_sdk_api .arg (v4 (), flow_types .String)
	, flow_sdk_api .arg (pons_artist_id_of_names ['0xARTIST_1'], flow_types .String)
	, flow_sdk_api .arg ('0.10', flow_types .UFix64)
	, flow_sdk_api .arg ('Only edition', flow_types .String)
	, flow_sdk_api .arg
		( cadencify_object_ (
			{ url: 'pons://nft-link-3'
			, title: 'NFT title 3'
			, description: 'NFT description 3' } )
		, flow_types .Dictionary ({ key: flow_types .String, value: flow_types .String }) ) ] )

;await run_known_test_
	( 'integration-tests/marketplace/mint' )
	( [ '0xPONS', '0xARTIST_1' ] )
	(
	[ flow_sdk_api .arg ({ domain: 'storage', identifier: 'ponsMinter' }, flow_types .Path)
	, flow_sdk_api .arg ([ v4 (), v4 (), v4 (), v4 (), v4 () ], flow_types .Array (flow_types .String))
	, flow_sdk_api .arg
		( cadencify_object_ (
			{ url: 'pons://nft-link-4'
			, title: 'NFT title 4'
			, description: 'NFT description 4' } )
		, flow_types .Dictionary ({ key: flow_types .String, value: flow_types .String }) )
	, flow_sdk_api .arg ('5', flow_types .Int)
	, flow_sdk_api .arg ('500.0', flow_types .UFix64)
	, flow_sdk_api .arg ('10.0', flow_types .UFix64)
	, flow_sdk_api .arg ('0.05', flow_types .UFix64) ] )

; await run_known_test_getTransaction_
	( 'integration-tests/marketplace/mint' )
	( [ '0xPONS', '0xARTIST_1' ] )
	(
	[ flow_sdk_api .arg ({ domain: 'storage', identifier: 'ponsMinter' }, flow_types .Path)
	, flow_sdk_api .arg ([ v4 (), v4 (), v4 (), v4 (), v4 (), v4 (), v4 (), v4 (), v4 (), v4 () ], flow_types .Array (flow_types .String))
	, flow_sdk_api .arg
		( cadencify_object_ (
			{ url: 'pons://nft-link-4'
			, title: 'NFT title 4'
			, description: 'NFT description 4' } )
		, flow_types .Dictionary ({ key: flow_types .String, value: flow_types .String }) )
	, flow_sdk_api .arg ('10', flow_types .Int)
	, flow_sdk_api .arg ('500.0', flow_types .UFix64)
	, flow_sdk_api .arg ('10.0', flow_types .UFix64)
	, flow_sdk_api .arg ('0.05', flow_types .UFix64) ] );
;

;await run_known_test_
	( 'integration-tests/marketplace/purchase-with-insufficient-funds-fails' )
	( [ '0xPONS', '0xARTIST_1', '0xPATRON_1' ] )
	(
	[ flow_sdk_api .arg ({ domain: 'storage', identifier: 'ponsMinter' }, flow_types .Path)
	, flow_sdk_api .arg (v4 (), flow_types .String)
	, flow_sdk_api .arg
		( cadencify_object_ (
			{ url: 'pons://nft-link-5'
			, title: 'NFT title 5'
			, description: 'NFT description 5' } )
		, flow_types .Dictionary ({ key: flow_types .String, value: flow_types .String }) )
	, flow_sdk_api .arg ('500.0', flow_types .UFix64)
	, flow_sdk_api .arg ('0.05', flow_types .UFix64) ] )

;await run_known_test_
	( 'integration-tests/marketplace/unlist-sold-listing-fails' )
	( [ '0xPONS', '0xARTIST_1', '0xPATRON_1', '0xRANDOM_1' ] )
	(
	[ flow_sdk_api .arg ({ domain: 'storage', identifier: 'ponsMinter' }, flow_types .Path)
	, flow_sdk_api .arg (v4 (), flow_types .String)
	, flow_sdk_api .arg
		( cadencify_object_ (
			{ url: 'pons://nft-link-6'
			, title: 'NFT title 6'
			, description: 'NFT description 6' } )
		, flow_types .Dictionary ({ key: flow_types .String, value: flow_types .String }) )
	, flow_sdk_api .arg ('50.0', flow_types .UFix64)
	, flow_sdk_api .arg ('0.05', flow_types .UFix64) ] )

;await run_known_test_
	( 'integration-tests/marketplace/unlist-someone-elses-listing-fails' )
	( [ '0xPONS', '0xARTIST_1', '0xPATRON_1', '0xRANDOM_1' ] )
	(
	[ flow_sdk_api .arg ({ domain: 'storage', identifier: 'ponsMinter' }, flow_types .Path)
	, flow_sdk_api .arg (v4 (), flow_types .String)
	, flow_sdk_api .arg
		( cadencify_object_ (
			{ url: 'pons://nft-link-7'
			, title: 'NFT title 7'
			, description: 'NFT description 7' } )
		, flow_types .Dictionary ({ key: flow_types .String, value: flow_types .String }) )
	, flow_sdk_api .arg ('50.0', flow_types .UFix64)
	, flow_sdk_api .arg ('0.05', flow_types .UFix64) ] )

;await run_known_test_
	( 'integration-tests/marketplace/mixed' )
	( [ '0xPONS', '0xARTIST_1', '0xPATRON_1', '0xRANDOM_1' ] )
	(
	[ flow_sdk_api .arg ({ domain: 'storage', identifier: 'ponsMinter' }, flow_types .Path)
	, flow_sdk_api .arg ([ v4 (), v4 (), v4 (), v4 (), v4 () ], flow_types .Array (flow_types .String))
	, flow_sdk_api .arg
		( cadencify_object_ (
			{ url: 'pons://nft-link-8'
			, title: 'NFT title 8'
			, description: 'NFT description 8' } )
		, flow_types .Dictionary ({ key: flow_types .String, value: flow_types .String }) )
	, flow_sdk_api .arg ('5', flow_types .Int)
	, flow_sdk_api .arg ('50.0', flow_types .UFix64)
	, flow_sdk_api .arg ('10.0', flow_types .UFix64)
	, flow_sdk_api .arg ('0.05', flow_types .UFix64) ] )

;await run_known_test_
	( 'integration-tests/marketplace/admin' )
	( [ '0xPONS', '0xARTIST_1' ] )
	(
	[ flow_sdk_api .arg ({ domain: 'storage', identifier: 'ponsMinter' }, flow_types .Path)
	, flow_sdk_api .arg (v4 (), flow_types .String)
	, flow_sdk_api .arg
		( cadencify_object_ (
			{ first_name: 'Artist'
			, last_name: 'One'
			, url: 'pons://artist-1' } )
		, flow_types .Dictionary ({ key: flow_types .String, value: flow_types .String }) )
	, flow_sdk_api .arg
		( cadencify_object_ (
			{ first_name: 'Artist'
			, last_name: 'One'
			, url: 'pons://artist-1.1' } )
		, flow_types .Dictionary ({ key: flow_types .String, value: flow_types .String }) )
	, flow_sdk_api .arg ('2.0', flow_types .UFix64)
	, flow_sdk_api .arg ('3.0', flow_types .UFix64)
	, flow_sdk_api .arg ('0.10', flow_types .UFix64) ] )

;await run_known_test_
	( 'integration-tests/escrow/consummation' )
	( [ '0xPONS', '0xARTIST_1', '0xRANDOM_1' ] )
	(
	[ flow_sdk_api .arg ({ domain: 'storage', identifier: 'ponsMinter' }, flow_types .Path)
	, flow_sdk_api .arg ([ v4 (), v4 (), v4 () ], flow_types .Array (flow_types .String))
	, flow_sdk_api .arg
		( cadencify_object_ (
			{ url: 'pons://nft-link-9'
			, title: 'NFT title 9'
			, description: 'NFT description 9' } )
		, flow_types .Dictionary ({ key: flow_types .String, value: flow_types .String }) )
	, flow_sdk_api .arg ('5.0', flow_types .UFix64)
	, flow_sdk_api .arg ('0.0', flow_types .UFix64)
	, flow_sdk_api .arg ('0.05', flow_types .UFix64) ] )

;await run_known_test_
	( 'integration-tests/escrow/consummation_v2' )
	( [ '0xPONS', '0xARTIST_1', '0xRANDOM_1' ] )
	(
	[ flow_sdk_api .arg ({ domain: 'storage', identifier: 'ponsMinter' }, flow_types .Path)
	, flow_sdk_api .arg ([ v4 (), v4 (), v4 () ], flow_types .Array (flow_types .String))
	, flow_sdk_api .arg
		( cadencify_object_ (
			{ url: 'pons://nft-link-9'
			, title: 'NFT title 9'
			, description: 'NFT description 9' } )
		, flow_types .Dictionary ({ key: flow_types .String, value: flow_types .String }) )
	, flow_sdk_api .arg ('5.0', flow_types .UFix64)
	, flow_sdk_api .arg ('0.0', flow_types .UFix64)
	, flow_sdk_api .arg ('0.05', flow_types .UFix64) ] )

;await run_known_test_
	( 'integration-tests/escrow/termination' )
	( [ '0xPONS', '0xARTIST_1', '0xRANDOM_1' ] )
	(
	[ flow_sdk_api .arg ({ domain: 'storage', identifier: 'ponsMinter' }, flow_types .Path)
	, flow_sdk_api .arg ([ v4 (), v4 (), v4 () ], flow_types .Array (flow_types .String))
	, flow_sdk_api .arg
		( cadencify_object_ (
			{ url: 'pons://nft-link-10'
			, title: 'NFT title 10'
			, description: 'NFT description 10' } )
		, flow_types .Dictionary ({ key: flow_types .String, value: flow_types .String }) )
	, flow_sdk_api .arg ('5.0', flow_types .UFix64)
	, flow_sdk_api .arg ('0.0', flow_types .UFix64)
	, flow_sdk_api .arg ('0.05', flow_types .UFix64) ] )
