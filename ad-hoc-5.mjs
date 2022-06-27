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

for (var i=102; i<112; i++){
	console .log (
	JSON .stringify
	( await

		send_proposed_transaction_
		( [ '0xPONS' ] )
		(


`
import PonsNftContractInterface from 0xPONS
import PonsNftContract from 0xPONS
import PonsNftMarketContract from 0xPONS

/* Unlist a NFT from marketplace */
transaction
() {
	prepare (lister : AuthAccount) {
		/* Unlists a NFT from marketplace */
		let unlist =
			fun (lister : AuthAccount, nftId : String) : Void {
				// Find the lister's listing certificate for this nftId
				var listingCertificate <- withdrawListingCertificate (lister, nftId: nftId)

				// First, unlist the NFT from the market, giving the listing certificate in return for the NFT
				// Then, deposit the NFT into the lister's Pons collection
				borrowOwnPonsCollection (collector: lister)
				.depositNft (
					<- PonsNftMarketContract .ponsMarket .unlist (<- listingCertificate) ) }

		/* Borrows a PonsCollection from an account, creating one if it does not exist */
		let borrowOwnPonsCollection =
			fun (collector : AuthAccount) : &PonsNftContractInterface.Collection {
				acquirePonsCollection (collector: collector)

				return collector .borrow <&PonsNftContractInterface.Collection> (from: PonsNftContract .CollectionStoragePath) ! }

		/* Ensures an account has a PonsCollection, creating one if it does not exist */
		let acquirePonsCollection =
			fun (collector : AuthAccount) : Void {
				var collectionRefOptional =
					collector .borrow <&PonsNftContractInterface.Collection>
						( from: PonsNftContract .CollectionStoragePath )

				if collectionRefOptional == nil {
					collector .save (<- PonsNftContract .createEmptyPonsCollection (), to: PonsNftContract .CollectionStoragePath) } }

		unlist (lister: lister, nftId: "37239912-usep-9wbe-b108-emin9segggfp") } }

`


		)
		( [] )


//
	, null
	, 4 ) )
		}
/**/
