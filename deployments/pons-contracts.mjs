import flow_types from '@onflow/types'
import { flow_sdk_api } from '../flow-utils/config.mjs'
import { deploy_known_contract_ } from './utils.mjs'
import { artist_authority_storage_path, collection_storage_path, minter_storage_path, minter_private_path, listing_certificates_storage_path } from './params.mjs'
import { primary_commission_ratio_amount, secondary_commission_ratio_amount } from './params.mjs'

;await deploy_known_contract_ ('PonsUtils') ([])
;await deploy_known_contract_ ('PonsNftUtils') ([])
;await deploy_known_contract_ ('PonsCertification') ([])
;await deploy_known_contract_ ('PonsArtist') (
	[ flow_sdk_api .arg ({ domain: 'storage', identifier: artist_authority_storage_path }, flow_types .Path) ] )
;await deploy_known_contract_ ('PonsNftInterface') ([])
;await deploy_known_contract_ ('PonsNft') (
	[ flow_sdk_api .arg ({ domain: 'storage', identifier: collection_storage_path }, flow_types .Path) ] )
;await deploy_known_contract_ ('PonsNftMarket') (
	[ flow_sdk_api .arg ({ domain: 'storage', identifier: listing_certificates_storage_path }, flow_types .Path) ] )
;await deploy_known_contract_ ('PonsNft_v1') (
	[ flow_sdk_api .arg ({ domain: 'storage', identifier: minter_storage_path }, flow_types .Path)
	, flow_sdk_api .arg ({ domain: 'private', identifier: minter_private_path }, flow_types .Path) ] )
;await deploy_known_contract_ ('PonsNftMarket_v1') (
	[ flow_sdk_api .arg (primary_commission_ratio_amount, flow_types .UFix64)
	, flow_sdk_api .arg (secondary_commission_ratio_amount, flow_types .UFix64) ] )
