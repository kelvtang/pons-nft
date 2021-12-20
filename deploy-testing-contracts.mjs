import { deploy_known_contract_from_ } from './utils/flow.mjs'

var __dirname = new URL ('.', import .meta .url) .pathname
var deploy_known_contract_ = deploy_known_contract_from_ (__dirname + '/testing-contracts/')


;await deploy_known_contract_ ('TestUtils') ([])
;await deploy_known_contract_ ('PonsUsage') ([])
