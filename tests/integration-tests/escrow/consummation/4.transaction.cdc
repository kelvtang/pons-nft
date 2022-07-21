import FungibleToken from 0xFUNGIBLETOKEN
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

		TestUtils .log ("Random account gifts the first NFT to Artist account using escrows")
		TestUtils .log ("1) Random account submits an escrow demanding nothing in return for the first NFT")
		TestUtils .log ("2) Artist account submits an escrow demanding the first NFT in return for nothing")
		TestUtils .log ("3) Pons account uses the two escrows to satisfy each other")

		let firstNftId = testInfo ["First NFT nftId"] !
		let secondNftId = testInfo ["Second NFT nftId"] !
		let thirdNftId = testInfo ["Third NFT nftId"] !



		PonsUsage .submitEscrow (
			submitter: randomAccount,
			id: "consummation-test-transaction-4-random",
			heldResourceDescription: PonsEscrowContract.EscrowResourceDescription (
				flowUnits: PonsUtils.FlowUnits (0.0),
				fusdUnits: PonsUtils.FusdUnits (0.0),
				ponsNftIds: [ firstNftId ] ),
			requirement: PonsEscrowContract.EscrowResourceDescription (
				flowUnits: PonsUtils.FlowUnits (0.0),
				fusdUnits: PonsUtils.FusdUnits (0.0),
				ponsNftIds: [] ) )

		PonsUsage .submitEscrow (
			submitter: artistAccount,
			id: "consummation-test-transaction-4-artist",
			heldResourceDescription: PonsEscrowContract.EscrowResourceDescription (
				flowUnits: PonsUtils.FlowUnits (0.0),
				fusdUnits: PonsUtils.FusdUnits (0.0),
				ponsNftIds: [] ),
			requirement: PonsEscrowContract.EscrowResourceDescription (
				flowUnits: PonsUtils.FlowUnits (0.0),
				fusdUnits: PonsUtils.FusdUnits (0.0),
				ponsNftIds: [ firstNftId ] ) )


		let escrowManagerRef = ponsAccount .borrow <&PonsEscrowContract.EscrowManager> (from: /storage/escrowManager) !
		

		let subConsummation =
			fun (_ escrowResourceListRef : &[PonsEscrowContract.EscrowResource]) : Void {
				escrowManagerRef .consummateEscrow (
					id: "consummation-test-transaction-4-random",
					consummation: fun (_ giftEscrowResource : @PonsEscrowContract.EscrowResource) : @PonsEscrowContract.EscrowResource {

						var emptyEscrowResource <- escrowResourceListRef .remove (at: 0)

						escrowResourceListRef .insert (at: 0, <- giftEscrowResource)

						return <- emptyEscrowResource } ) }

		escrowManagerRef .consummateEscrow (
			id: "consummation-test-transaction-4-artist",
			consummation: fun (_ emptyEscrowResource : @PonsEscrowContract.EscrowResource) : @PonsEscrowContract.EscrowResource {

				var consummatedEscrowResourceList : @[PonsEscrowContract.EscrowResource] <- [ <- emptyEscrowResource ]

				let escrowResourceListRef = &consummatedEscrowResourceList as &[PonsEscrowContract.EscrowResource]

				subConsummation (escrowResourceListRef)

				var giftEscrowResource <- escrowResourceListRef .remove (at: 0)

				destroy consummatedEscrowResourceList

				return <- giftEscrowResource } )

		escrowManagerRef .dismissEscrow (id: "consummation-test-transaction-4-random")
		escrowManagerRef .dismissEscrow (id: "consummation-test-transaction-4-artist")

		} }
