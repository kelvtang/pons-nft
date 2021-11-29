import flow_types from '@onflow/types'
import { deploy_known_contract_from_ } from './utils/flow.mjs'
import { flow_sdk_api } from './config.mjs'
import { artist_authority_storage_path, collection_storage_path, minter_storage_path, minter_private_path, listing_certificate_collection_storage_path } from './config.mjs'
import { minimum_minting_price, primary_commission_ratio_amount, secondary_commission_ratio_amount } from './config.mjs'

var __dirname = new URL ('.', import .meta .url) .pathname
var deploy_known_contract_ = deploy_known_contract_from_ (__dirname + '/contracts/')


;await deploy_known_contract_ ('PonsUtils') ([])
;await deploy_known_contract_ ('PonsArtist') (
	[ flow_sdk_api .arg ({ domain: 'storage', identifier: artist_authority_storage_path }, flow_types .Path) ] )
;await deploy_known_contract_ ('PonsCertification') ([])
;await deploy_known_contract_ ('PonsNftInterface') (
	[ flow_sdk_api .arg ({ domain: 'storage', identifier: collection_storage_path }, flow_types .Path) ] )
;await deploy_known_contract_ ('PonsNft') (
	[ flow_sdk_api .arg ({ domain: 'storage', identifier: collection_storage_path }, flow_types .Path) ] )
;await deploy_known_contract_ ('PonsNftMarket') (
	[ flow_sdk_api .arg ({ domain: 'storage', identifier: listing_certificate_collection_storage_path }, flow_types .Path) ] )
;await deploy_known_contract_ ('PonsNft_v1') (
	[ flow_sdk_api .arg ({ domain: 'storage', identifier: minter_storage_path }, flow_types .Path)
	, flow_sdk_api .arg ({ domain: 'private', identifier: minter_private_path }, flow_types .Path) ] )
;await deploy_known_contract_ ('PonsNftMarket_v1') (
	[ flow_sdk_api .arg (minimum_minting_price, flow_types .UFix64)
	, flow_sdk_api .arg (primary_commission_ratio_amount, flow_types .UFix64)
	, flow_sdk_api .arg (secondary_commission_ratio_amount, flow_types .UFix64) ] )
