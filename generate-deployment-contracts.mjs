import { generate_deployment_contract_from_ } from './utils/flow.mjs'

var __dirname = new URL ('.', import .meta .url) .pathname
var generate_deployment_contract_ = generate_deployment_contract_from_ (__dirname + '/contracts/') (__dirname + '/deployment-contracts/')


;await generate_deployment_contract_ ('PonsUtils')
;await generate_deployment_contract_ ('PonsCertification')
;await generate_deployment_contract_ ('PonsNftInterface')
;await generate_deployment_contract_ ('PonsNft')
;await generate_deployment_contract_ ('PonsNftMarket')
;await generate_deployment_contract_ ('PonsNft_v1')
;await generate_deployment_contract_ ('PonsNftMarket_v1')
;await generate_deployment_contract_ ('PonsEscrow')
