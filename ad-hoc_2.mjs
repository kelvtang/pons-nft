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

for (var i=100; i<101; i++){
	console .log (
	JSON .stringify
	( await

		send_proposed_transaction_
		( [ '0xPONS' ] )
		(



// `
// import PonsUtils from 0xPONS
// import PonsNftMarketContract from 0xPONS
// import PonsNftContract_v1 from 0xPONS
// import PonsNftContract from 0xPONS

// transaction 
// ( ) {
// 	prepare (ponsAccount : AuthAccount) {
		
// 		let artistId = "4176cebe-8656-414c-a6ce-156722a6ef87"					//"4176cebe-8886-414c-a6ce-15bc22a6ef87"
// 		let mintIds = ["3474e012-uufc-sxbe-b6ui-e00nysecs555"]					// ["3474e012-defc-49be-b65e-e2508a9c8ac0"]
// 		let metadata = {
// 			"title":"Starry Night AI-NFT #120",									//"title":"Starry Night AI-NFT #119",
// 			"media":"ipfs://QmTv1Nta4sicWcYcsP97oVEjotPQPALzVq6799ye2Qanzu",	//"media":"ipfs://QmTv1Nta4sicWcYcsP97oVEjotPQPALzVq6799ye2Qnpbu",
// 			"description": "Made at JUMPSTARTER 2022 K12 MUSEA",				//"description": "Made at JUMPSTARTER 2022 K11 MUSEA",
// 			"backstory":"Your own AI-NFT."
// 		}
// 		let quantity =1
// 	    let basePriceAmount = 10.0
// 		let incrementalPriceAmount = 0.0
// 		let royaltyRatioAmount = 0.05

// 		let minterRef = ponsAccount .borrow <&PonsNftContract_v1.NftMinter_v1> (from: /storage/ponsMinter) !
// 		let artistAuthorityRef = ponsAccount .borrow <&PonsNftContract.PonsArtistAuthority> (from: /storage/ponsArtistAuthority) !

// 		minterRef .refillMintIds (mintIds: mintIds)

// 		let ponsArtistRef = PonsNftContract .borrowArtistById (ponsArtistId: artistId)

// 		let basePrice = PonsUtils.FlowUnits (basePriceAmount)
// 		let incrementalPrice = PonsUtils.FlowUnits (incrementalPriceAmount)
// 		let royaltyRatio = PonsUtils.Ratio (royaltyRatioAmount)


// 		/* Deposit listing certificates into the account''s default listing certificate collection */
// 		let depositListingCertificates =
// 			fun (_ account : AuthAccount, _ newListingCertificates : @[{PonsNftMarketContract.PonsListingCertificate}]) : Void {
// 				// Load the existing listing certificate collection of the account, if any
				
// 				var listingCertificateCollectionOptional <- account .load <@PonsNftMarketContract.PonsListingCertificateCollection> ( from: PonsNftMarketContract .PonsListingCertificateCollectionStoragePath )
				

// 				if listingCertificateCollectionOptional != nil {
// 					// If the account already has a listing certificate collection
// 					// Retrieve each new listing certificate and add it to the collection, then save the collection
// 					var listingCertificateCollection <- listingCertificateCollectionOptional !

// 					while newListingCertificates .length > 0 {
// 						listingCertificateCollection .appendListingCertificate (item: <- newListingCertificates .remove (at: 0)) 
//                         }

// 					destroy newListingCertificates

// 					account .save (<- listingCertificateCollection, to: PonsNftMarketContract .PonsListingCertificateCollectionStoragePath) 
//                     }
// 				else {
// 					// If the account already has a listing certificate collection
// 					// Create a new listing certificate collection, retrieve each new listing certificate and add it to the collection, then save the collection
// 					// Destroy the nil to make the resource checker happy
// 					destroy listingCertificateCollectionOptional

// 					var listingCertificateCollection <- PonsNftMarketContract .createPonsListingCertificateCollection ()

// 					while newListingCertificates .length > 0 {
// 						listingCertificateCollection.appendListingCertificate (item: <- newListingCertificates.remove (at: 0)) 
//                     }

// 					destroy newListingCertificates

// 					account .save (<- listingCertificateCollection, to: PonsNftMarketContract .PonsListingCertificateCollectionStoragePath) 
//                     } 
//                 }

// 		/* Mint new NFTs for sale for Pons artists */
// 		let indirectlyMintForSale =
// 			fun
// 			( metadata : {String: String}
// 			, quantity : Int
// 			, basePrice : PonsUtils.FlowUnits
// 			, incrementalPrice : PonsUtils.FlowUnits
// 			, _ royaltyRatio : PonsUtils.Ratio
// 			) : [String] {
// 				// Obtain the minter''s Capability to receive Flow tokens
// 				var receivePaymentCap = PonsNftContract .getArtistReceivePaymentCap (ponsArtistRef) !

// 		        	let ponsArtistAuthorityRef = ponsAccount .borrow<&PonsNftContract.PonsArtistAuthority> (from: /storage/ponsArtistAuthority) !

// 				// Obtain an artist certificate of the minter
// 				var artistCertificate <- ponsArtistAuthorityRef .makePonsArtistCertificateFromId (ponsArtistId: artistId)
// 				// Mint and list the specified NFT on the active Pons market, producing some listing certificates
// 				var listingCertificates <-
// 					PonsNftMarketContract .borrowPonsMarket () .mintForSale (
// 						& artistCertificate as &PonsNftContract.PonsArtistCertificate,
// 						metadata: metadata,
// 						quantity: quantity,
// 						basePrice: basePrice,
// 						incrementalPrice: incrementalPrice,
// 						royaltyRatio,
// 						receivePaymentCap )

// 				// Iterate over the obtained listing certificates to produce the nftIds of the newly minted NFTs
// 				let nftIds : [String] = []
// 				var nftIndex = 0
// 				while nftIndex < listingCertificates .length {
// 					nftIds .append (listingCertificates [nftIndex] .nftId)
// 					nftIndex = nftIndex + 1 }

// 				// Dispose of the artist certificate
// 				destroy artistCertificate
// 				// Deposit the listing certificates in the minter''s storage
// 				depositListingCertificates (ponsAccount, <- listingCertificates)

// 				// Return list of minted nftIds
// 				return nftIds }

// 		indirectlyMintForSale (
// 			metadata: metadata,
// 			quantity: quantity,
// 			basePrice: basePrice,
// 			incrementalPrice: incrementalPrice,
// 			royaltyRatio )  } }
// `

`
import PonsUtils from 0xPONS
import PonsNftMarketContract from 0xPONS
import PonsNftContract_v1 from 0xPONS
import PonsNftContract from 0xPONS

transaction 
( ) {
	prepare (ponsAccount : AuthAccount) {
		
		let artistId = "4176cebe-8656-414c-a6ce-158662a6ef87"					//"4176cebe-8886-414c-a6ce-15bc22a6ef87"
		let mintIds = ["37239912-usec-xwbe-b6pi-emin9se${i.toString()}fp"]					// ["3474e012-defc-49be-b65e-e2508a9c8ac0"]
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
					var collection_storage_path = PonsNftMarketContract.getPathFromID(certificate.nftId);

					// Store in to a listing certicate collection
					listingCertificateHolder .appendListingCertificate(item: <- certificate );

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
