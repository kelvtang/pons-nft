import flow_types from '@onflow/types'
import { deploy_known_contract_from_ } from './utils/flow.mjs'
import { flow_sdk_api } from './config.mjs'

var __dirname = new URL ('.', import .meta .url) .pathname
var deploy_known_contract_ = deploy_known_contract_from_ (__dirname + '/contracts/')


;await deploy_known_contract_ ('PonsUtils') ([])
;await deploy_known_contract_ ('PonsCertification') ([])
;await deploy_known_contract_ ('PonsNftInterface') ([])
;await deploy_known_contract_ ('PonsNft') ([])
;await deploy_known_contract_ ('PonsNftMarket') ([])
;await deploy_known_contract_ ('PonsNft_v1') ([])
;await deploy_known_contract_ ('PonsNftMarket_v1') ([])
;await deploy_known_contract_ ('PonsNftMarketAdmin_v1') ([])
;await deploy_known_contract_ ('PonsEscrow') ([])
;await deploy_known_contract_ ('PonsTunnel') ([])