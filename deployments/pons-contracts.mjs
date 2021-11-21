import { deploy_known_contract_ } from '../utils.mjs'

;await deploy_known_contract_ ('PonsUtils') ([])
;await deploy_known_contract_ ('PonsNftUtils') ([])
;await deploy_known_contract_ ('PonsCertification') ([])
;await deploy_known_contract_ ('PonsArtist') ([])
;await deploy_known_contract_ ('PonsNftInterface') ([])
;await deploy_known_contract_ ('PonsNft') (
	[ flow_sdk_api .arg ({ domain: 'storage', identifier: 'ponsCollection' }, flow_types .Path) ] )
;await deploy_known_contract_ ('PonsNftMarket') (
	[ flow_sdk_api .arg ({ domain: 'storage', identifier: 'listingCertificates' }, flow_types .Path) ] )
;await deploy_known_contract_ ('PonsNft_v1') (
	[ flow_sdk_api .arg ({ domain: 'storage', identifier: 'ponsMinter' }, flow_types .Path)
	, flow_sdk_api .arg ({ domain: 'private', identifier: 'ponsMinter' }, flow_types .Path) ] )
;await deploy_known_contract_ ('PonsNftMarket_v1') ([])
