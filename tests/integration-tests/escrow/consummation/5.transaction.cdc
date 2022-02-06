import FungibleToken from 0xFUNGIBLETOKEN
import PonsUtils from 0xPONS
import PonsNftMarketContract from 0xPONS
import PonsNftContract from 0xPONS
import PonsNftContract_v1 from 0xPONS
import PonsEscrowContract from 0xPONS

import TestUtils from 0xPONS
import PonsUsage from 0xPONS

transaction 
( minterStoragePath : StoragePath
, mintIds : [String]
, metadata : {String: String}
, basePriceAmount : UFix64
, incrementalPriceAmount : UFix64
, royaltyRatioAmount : UFix64
, transactionSuccess : Bool
, transactionErrorMessage : String?
, transactionEvents : [{String: String}]
, testInfo : {String: String}
) {

	prepare (ponsAccount : AuthAccount, artistAccount : AuthAccount, randomAccount : AuthAccount) {

		TestUtils .log ("Random account gifts the second NFT to Artist account using escrows")
		TestUtils .log ("1) Random account submits an escrow demanding nothing in return for the second NFT")
		TestUtils .log ("2) Pons account consummates the escrow and deposits the second NFT")

		let firstNftId = testInfo ["First NFT nftId"] !
		let secondNftId = testInfo ["Second NFT nftId"] !
		let thirdNftId = testInfo ["Third NFT nftId"] !



		PonsUsage .submitEscrow (
			submitter: randomAccount,
			id: "consummation-test-transaction-5-random",
			heldResourceDescription: PonsEscrowContract.EscrowResourceDescription (
				flowUnits: PonsUtils.FlowUnits (0.0),
				ponsNftIds: [ secondNftId ] ),
			requirement: PonsEscrowContract.EscrowResourceDescription (
				flowUnits: PonsUtils.FlowUnits (0.0),
				ponsNftIds: [] ) )


		let escrowManagerRef = ponsAccount .borrow <&PonsEscrowContract.EscrowManager> (from: /storage/escrowManager) !
		

		escrowManagerRef .consummateEscrow (
			id: "consummation-test-transaction-5-random",
			consummation: fun (_ secondNftEscrowResource : @PonsEscrowContract.EscrowResource) : @PonsEscrowContract.EscrowResource {
				var secondNft <- secondNftEscrowResource .borrowPonsNfts () .remove (at: 0)

				PonsUsage .borrowOwnPonsCollection (collector: ponsAccount) .depositNft (<- secondNft)

				return <- secondNftEscrowResource } )

		escrowManagerRef .dismissEscrow (id: "consummation-test-transaction-5-random")

		} }
