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

		TestUtils .log ("Escrows can be consummated when the NFT requirements are exceeded")
		TestUtils .log ("1) Artist account submits an escrow demanding the first NFT and 5 FLOW in return for the second NFT")
		TestUtils .log ("2) Pons account consummates the escrow with the first NFT and 10 Flow tokens")
		TestUtils .log ("This should succeed")

		let firstNftId = testInfo ["First NFT nftId"] !
		let secondNftId = testInfo ["Second NFT nftId"] !
		let thirdNftId = testInfo ["Third NFT nftId"] !



		PonsUsage .submitEscrow (
			submitter: artistAccount,
			id: "consummation-test-transaction-10-artist",
			heldResourceDescription: PonsEscrowContract.EscrowResourceDescription (
				flowUnits: PonsUtils.FlowUnits (0.0, "Flow Token"),
				ponsNftIds: [ secondNftId ] ),
			requirement: PonsEscrowContract.EscrowResourceDescription (
				flowUnits: PonsUtils.FlowUnits (5.0, "Flow Token"),
				ponsNftIds: [ firstNftId ] ) )


		let escrowManagerRef = ponsAccount .borrow <&PonsEscrowContract.EscrowManager> (from: /storage/escrowManager) !
		

		escrowManagerRef .consummateEscrow (
			id: "consummation-test-transaction-10-artist",
			consummation: fun (_ firstNftEscrowResource : @PonsEscrowContract.EscrowResource) : @PonsEscrowContract.EscrowResource {

				var firstNft <- firstNftEscrowResource .borrowPonsNfts () .remove (at: 0)

				PonsUsage .borrowOwnPonsCollection (collector: ponsAccount) .depositNft (<- firstNft)

				destroy firstNftEscrowResource

				return <- PonsEscrowContract .makeEscrowResource (
					flowVault: <- ponsAccount .borrow <&FungibleToken.Vault> (from: /storage/flowTokenVault) ! .withdraw (amount: 10.0),
					ponsNfts: <- [ <- PonsUsage .borrowOwnPonsCollection (collector: ponsAccount) .withdrawNft (nftId: firstNftId) ] ) } )

		escrowManagerRef .dismissEscrow (id: "consummation-test-transaction-10-artist")

		} }
