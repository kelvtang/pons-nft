import flow_types from '@onflow/types'
import { deploy_known_contract_from_, update_known_contract_from_ } from './utils/flow.mjs'
import { flow_sdk_api } from './config.mjs'

var __dirname = new URL ('.', import .meta .url) .pathname
//var deploy_known_contract_ = deploy_known_contract_from_ (__dirname + '/contracts/')
var update_known_contract_ = update_known_contract_from_ (__dirname + '/contracts/')
;await update_known_contract_ ('PonsUtils') 
;await update_known_contract_ ('PonsCertification')
;await update_known_contract_ ('PonsNftInterface') 
;await update_known_contract_ ('PonsNft') 
;await update_known_contract_ ('PonsNftMarket') 
;await update_known_contract_ ('PonsNft_v1') 
;await update_known_contract_ ('PonsNftMarket_v1') 
;await update_known_contract_ ('PonsNftMarketAdmin_v1') 
;await update_known_contract_ ('PonsEscrow')

;await update_known_contract_ ('PonsTunnel')  

update_known_contract_ = update_known_contract_from_ (__dirname + '/testing-contracts/')
;await update_known_contract_ ('PonsUsage') 
;await update_known_contract_ ('TestUtils') 