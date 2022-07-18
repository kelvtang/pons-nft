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

		// Random account submits an Escrow demanding all the NFTs in exchange for none of his own resources
		// Pons account grants the NFTs from the account's PonsCollection 

		TestUtils .log ("Random account submits an Escrow demanding all the NFTs in exchange for none of his own resources, and Pons account consummates it")

		let firstNftId = testInfo ["First NFT nftId"] !
		let secondNftId = testInfo ["Second NFT nftId"] !
		let thirdNftId = testInfo ["Third NFT nftId"] !



		PonsUsage .submitEscrowFlow (
			submitter: randomAccount,
			id: "consummation-test-transaction-3-random",
			heldResourceDescription: PonsEscrowContract.EscrowResourceDescription (
				flowUnits: PonsUtils.FlowUnits (0.0),
				ponsNftIds: [] ),
			requirement: PonsEscrowContract.EscrowResourceDescription (
				flowUnits: PonsUtils.FlowUnits (0.0),
				ponsNftIds: [ firstNftId, secondNftId, thirdNftId ] ) )


		let escrowManagerRef = ponsAccount .borrow <&PonsEscrowContract.EscrowManager> (from: /storage/escrowManager) !


		escrowManagerRef .consummateEscrow (
			id: "consummation-test-transaction-3-random",
			consummation: fun (_ escrowResource : @PonsEscrowContract.EscrowResource) : @PonsEscrowContract.EscrowResource {

				escrowResource .borrowPonsNfts () .append (
					<- PonsUsage .borrowOwnPonsCollection (collector: ponsAccount) .withdrawNft (nftId: firstNftId) )
				escrowResource .borrowPonsNfts () .append (
					<- PonsUsage .borrowOwnPonsCollection (collector: ponsAccount) .withdrawNft (nftId: secondNftId) )
				escrowResource .borrowPonsNfts () .append (
					<- PonsUsage .borrowOwnPonsCollection (collector: ponsAccount) .withdrawNft (nftId: thirdNftId) )

				return <- escrowResource } )

		escrowManagerRef .dismissEscrow (id: "consummation-test-transaction-3-random")

		} }
