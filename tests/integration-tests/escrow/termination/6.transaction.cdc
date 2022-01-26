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

		TestUtils .log ("Terminated Escrows can be dismissed")
		TestUtils .log ("Dismissed Escrows can be terminated")
		TestUtils .log ("This should succeed")

		let firstNftId = testInfo ["First NFT nftId"] !
		let secondNftId = testInfo ["Second NFT nftId"] !
		let thirdNftId = testInfo ["Third NFT nftId"] !



		let escrowManagerRef = ponsAccount .borrow <&PonsEscrowContract.EscrowManager> (from: /storage/escrowManager) !


		escrowManagerRef .dismissEscrow (id: "termination-test-transaction-3-random")


		PonsUsage .submitEscrow (
			submitter: ponsAccount,
			id: "termination-test-transaction-6-pons",
			heldResourceDescription: PonsEscrowContract.EscrowResourceDescription (
				flowUnits: PonsUtils.FlowUnits (0.0),
				ponsNftIds: [] ),
			requirement: PonsEscrowContract.EscrowResourceDescription (
				flowUnits: PonsUtils.FlowUnits (0.0),
				ponsNftIds: [] ) )

		let escrowRef = escrowManagerRef .escrow (id: "termination-test-transaction-6-pons") !

		escrowManagerRef .dismissEscrow (id: "termination-test-transaction-6-pons")

		PonsEscrowContract .terminateEscrow (escrowRef)


		} }
