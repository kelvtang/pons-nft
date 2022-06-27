import flow_types from '@onflow/types'
import { execute_proposed_script_, send_proposed_transaction_, execute_known_script_, run_known_test_from_, deploy_known_contract_from_, update_known_contract_from_, make_known_ad_hoc_account_, update_known_contracts_from_ } from './utils/flow.mjs'
import { execute_script_ } from './utils/flow-api.mjs'
import { flow_sdk_api } from './config.mjs'

//
var __dirname = new URL ('.', import .meta .url) .pathname
var deploy_known_contract_ = deploy_known_contract_from_ (__dirname + './uzair_test')
var update_known_contract_ = update_known_contract_from_ (__dirname + '/contracts/')
var update_known_contracts_ = update_known_contracts_from_ (__dirname + '/contracts/')


//		



/*/
;await
	run_known_test_from_
	( 'tests' )
	( 'debug-test' )
	( [ '0xPONS' ] )
	( [] )

//

;await
	make_known_ad_hoc_account_ ('0xARTIST_1')

//

;await
	update_known_contract_
	( 'PonsNft_v1' )

/*/
;

var nft_id = "37239912-usep-9wbe-b102-emin9segggfp";
var escrow_id = "koillo";

	console .log (
	JSON .stringify
	( await

		send_proposed_transaction_
		( [ '0xPONS' ] )
		(


`
import FungibleToken from 0xFUNGIBLETOKEN
import PonsUtils from 0xPONS
import PonsNftMarketContract from 0xPONS
import PonsNftContract from 0xPONS
import PonsNftContract_v1 from 0xPONS
import PonsEscrowContract from 0xPONS
import PonsNftMarketAdminContract_v1 from 0xPONS

transaction
() {

        prepare (ponsAccount : AuthAccount) {

			let nftId : String = \"${nft_id}\";
			let prepaidEscrowId : String = \"${escrow_id}\";

                let nftAdminRef = ponsAccount .getCapability <&PonsNftMarketAdminContract_v1.NftMarketAdmin_v1> (/private/ponsMarketAdmin_v1) .borrow () !

                let escrowManagerRef = ponsAccount .borrow <&PonsEscrowContract.EscrowManager> (from: /storage/escrowManager) !

                escrowManagerRef .consummateEscrow (
                        id: prepaidEscrowId,
                        consummation: fun (_ prepaidEscrowResource : @PonsEscrowContract.EscrowResource) : @PonsEscrowContract.EscrowResource {

                                var nft <- nftAdminRef .borrowCollection () .withdrawNft (nftId: nftId)

                                // Signaling sold
                                nftAdminRef .updateSalePrice (nftId: nftId, price: PonsUtils.FlowUnits (0.0))

								// Should happen automaticall during unlist.
								// // Do it forcibly
								nftAdminRef .delistNftFromMarketplace(nftId: nftId)

                                prepaidEscrowResource .borrowPonsNfts () .insert (at: 0, <- nft)

                                return <- prepaidEscrowResource } )

                escrowManagerRef .dismissEscrow (id: prepaidEscrowId)

                } }
`


		)
		( [] )


//
	, null
	, 4 ) )
/**/
