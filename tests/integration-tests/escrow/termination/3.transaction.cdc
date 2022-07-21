import PonsUtils from 0xPONS
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

		TestUtils .log ("Pons account can terminate Escrows")
		TestUtils .log ("Random account submits an Escrow demanding all the NFTs and 1000 FLOW in exchange for none of his own resources")
		TestUtils .log ("Pons account terminates the Escrow")

		let firstNftId = testInfo ["First NFT nftId"] !
		let secondNftId = testInfo ["Second NFT nftId"] !
		let thirdNftId = testInfo ["Third NFT nftId"] !



		PonsUsage .submitEscrow (
			submitter: randomAccount,
			id: "termination-test-transaction-3-random",
			heldResourceDescription: PonsEscrowContract.EscrowResourceDescription (
				flowUnits: PonsUtils.FlowUnits (0.0),
				fusdUnits: PonsUtils.FusdUnits (0.0),
				ponsNftIds: [] ),
			requirement: PonsEscrowContract.EscrowResourceDescription (
				flowUnits: PonsUtils.FlowUnits (1000.0),
				fusdUnits: PonsUtils.FusdUnits (1000.0),
				ponsNftIds: [ firstNftId, secondNftId, thirdNftId ] ) )


		let escrowManagerRef = ponsAccount .borrow <&PonsEscrowContract.EscrowManager> (from: /storage/escrowManager) !


		escrowManagerRef .terminateEscrow (id: "termination-test-transaction-3-random")

		} }
