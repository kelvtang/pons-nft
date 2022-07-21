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

		TestUtils .log ("Submitter of the an Escrow can terminate the Escrow and recover held resources")
		TestUtils .log ("Artist account submits an Escrow demanding all the NFTs in exchange for 2 FLOW")
		TestUtils .log ("Artist account terminates the Escrow")
		TestUtils .log ("This should succeed")

		let firstNftId = testInfo ["First NFT nftId"] !
		let secondNftId = testInfo ["Second NFT nftId"] !
		let thirdNftId = testInfo ["Third NFT nftId"] !


		let storagePath = PonsUsage .submitEscrow (
			submitter: artistAccount,
			id: "termination-test-transaction-7-artist",
			heldResourceDescription: PonsEscrowContract.EscrowResourceDescription (
				flowUnits: PonsUtils.FlowUnits (2.0),
				fusdUnits: PonsUtils.FusdUnits (2.0),
				ponsNftIds: [] ),
			requirement: PonsEscrowContract.EscrowResourceDescription (
				flowUnits: PonsUtils.FlowUnits (0.0),
				fusdUnits: PonsUtils.FusdUnits (0.0),
				ponsNftIds: [ firstNftId, secondNftId, thirdNftId ] ) )

		PonsEscrowContract .terminateEscrow (
			artistAccount .borrow <&PonsEscrowContract.Escrow> (from: storagePath) ! )

		let escrowManagerRef = ponsAccount .borrow <&PonsEscrowContract.EscrowManager> (from: /storage/escrowManager) !

		escrowManagerRef .dismissEscrow (id: "termination-test-transaction-7-artist")

		} }
