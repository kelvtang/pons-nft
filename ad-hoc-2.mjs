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

import PonsUtils from 0xPONS
import PonsNftMarketContract from 0xPONS
import PonsNftContract_v1 from 0xPONS
import PonsNftContract from 0xPONS

transaction 
( ) {
	prepare (ponsAccount : AuthAccount) {
		
		let artistId = "4176cebe-8656-414c-a6ce-158662a6ef87"					//"4176cebe-8886-414c-a6ce-15bc22a6ef87"
		let mintIds = ["37239912-usep-9wbe-b${i.toString()}-emin9segggfp"]					// ["3474e012-defc-49be-b65e-e2508a9c8ac0"]
		let metadata = {
			"title":"Starry Night AI-NFT #120",									//"title":"Starry Night AI-NFT #119",
			"media":"ipfs://QmTv1Nta4sicWcYcsP97oVEjotPQPALzVq6799ye2Qanzu",	//"media":"ipfs://QmTv1Nta4sicWcYcsP97oVEjotPQPALzVq6799ye2Qnpbu",
			"description": "Made at JUMPSTARTER 2022 K12 MUSEA",				//"description": "Made at JUMPSTARTER 2022 K11 MUSEA",
			"backstory":"Your own AI-NFT."
		}
		let quantity =1
	    let basePriceAmount = 10.0
		let incrementalPriceAmount = 0.0
		let royaltyRatioAmount = 0.05

		let minterRef = ponsAccount .borrow <&PonsNftContract_v1.NftMinter_v1> (from: /storage/ponsMinter) !
		let artistAuthorityRef = ponsAccount .borrow <&PonsNftContract.PonsArtistAuthority> (from: /storage/ponsArtistAuthority) !

		minterRef .refillMintIds (mintIds: mintIds)

		let ponsArtistRef = PonsNftContract .borrowArtistById (ponsArtistId: artistId)

		let basePrice = PonsUtils.FlowUnits (basePriceAmount)
		let incrementalPrice = PonsUtils.FlowUnits (incrementalPriceAmount)
		let royaltyRatio = PonsUtils.Ratio (royaltyRatioAmount)

        
        /* Function to create a unique path from nft mintID*/
	    let getPathFromID = fun (_ mintID:String, counter: Int?):StoragePath{
		// Certain assumptions had to be made to allow this function to work
		//  // 1) mintID will always follow regex // [a-z, 0-9]{8}-[a-z, 0-9]{4}-[a-z, 0-9]{4}-[a-z, 0-9]{4}-[a-z, 0-9]{12}
		//  // 2) we will only return a storage path.

        // Handles nil values.
        var count:Int? = (counter == nil? 0 : counter);


		// Pure string is a string following two conditions
		//  // 1) must only contain alphanumerical characters
		//  // 2) must always start with an alphabet charater
			var pureString:String = "nftid".concat(mintID.slice(from:0,upTo:8).concat(
			mintID.slice(from: 9, upTo: 13).concat(
				mintID.slice(from: 14, upTo: 18).concat(
					mintID.slice(from: 19, upTo: 23).concat(
						mintID.slice(from: 24, upTo: 36).concat(
                            count!.toString()
                        )
					)
				))));
		// Create a storage path
		var createdStoragePath:StoragePath = StoragePath(identifier:pureString)!;

		return createdStoragePath;
        }

		/* Deposit listing certificates into the account''s default listing certificate collection */
		let depositListingCertificates =
			fun (_ account : AuthAccount, _ newListingCertificates : @[{PonsNftMarketContract.PonsListingCertificate}]) : Void {
				// Load the existing listing certificate collection of the account, if any
				
				// Loop through new listing certificates.
				while newListingCertificates .length > 0 {
					var listingCertificateHolder <- PonsNftMarketContract .createPonsListingCertificateCollection ()
					
					// Move certificate to temporary variable
					var certificate <- newListingCertificates .remove (at: 0);

					// Generate unique storage path. Since no two nft can have same ID. Each path will always empty.
					//	// Can also be used to access listing certificate like a dictionary since each id can be used like a key.
					var counter:Int = 0;
                    while ponsAccount .borrow <&PonsNftMarketContract.PonsListingCertificateCollection> (from: getPathFromID(certificate.nftId, counter)) != nil{
                        counter = counter + 1;
                    }
                    var collection_storage_path = getPathFromID(certificate.nftId, counter);

					// Store in to a listing certicate collection
					listingCertificateHolder .appendListingCertificate(<- certificate );

					// Save to unique storage location
					account.save (<- listingCertificateHolder, to: collection_storage_path);
					
				}
				destroy newListingCertificates
		}

		
		/* Mint new NFTs for sale for Pons artists */
		let indirectlyMintForSale =
			fun
			( metadata : {String: String}
			, quantity : Int
			, basePrice : PonsUtils.FlowUnits
			, incrementalPrice : PonsUtils.FlowUnits
			, _ royaltyRatio : PonsUtils.Ratio
			) : [String] {
				// Obtain the minter''s Capability to receive Flow tokens
				var receivePaymentCap = PonsNftContract .getArtistReceivePaymentCap (ponsArtistRef) !

		        let ponsArtistAuthorityRef = ponsAccount .borrow<&PonsNftContract.PonsArtistAuthority> (from: /storage/ponsArtistAuthority) !

				// Obtain an artist certificate of the minter
				var artistCertificate <- ponsArtistAuthorityRef .makePonsArtistCertificateFromId (ponsArtistId: artistId)
				// Mint and list the specified NFT on the active Pons market, producing some listing certificates
				var listingCertificates <-
					PonsNftMarketContract .borrowPonsMarket () .mintForSale (
						& artistCertificate as &PonsNftContract.PonsArtistCertificate,
						metadata: metadata,
						quantity: quantity,
						basePrice: basePrice,
						incrementalPrice: incrementalPrice,
						royaltyRatio,
						receivePaymentCap )

				// Iterate over the obtained listing certificates to produce the nftIds of the newly minted NFTs
				let nftIds : [String] = []
				var nftIndex = 0
				while nftIndex < listingCertificates .length {
					nftIds .append (listingCertificates [nftIndex] .nftId)
					nftIndex = nftIndex + 1 }

				// Dispose of the artist certificate
				destroy artistCertificate
				// Deposit the listing certificates in the minter''s storage
				depositListingCertificates (ponsAccount, <- listingCertificates)

				// Return list of minted nftIds
				return nftIds }

		indirectlyMintForSale (
			metadata: metadata,
			quantity: quantity,
			basePrice: basePrice,
			incrementalPrice: incrementalPrice,
			royaltyRatio )  } }
`


		)
		( [] )


//
	, null
	, 4 ) )
		}
/**/
