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

		TestUtils .log ("Escrows cannot be consummated")

		let firstNftId = testInfo ["First NFT nftId"] !
		let secondNftId = testInfo ["Second NFT nftId"] !
		let thirdNftId = testInfo ["Third NFT nftId"] !



		let escrowManagerRef = ponsAccount .borrow <&PonsEscrowContract.EscrowManager> (from: /storage/escrowManager) !

		escrowManagerRef .consummateEscrow (
			id: "termination-test-transaction-3-random",
			consummation: fun (_ escrowResource : @PonsEscrowContract.EscrowResource) : @PonsEscrowContract.EscrowResource {

				escrowResource .borrowPonsNfts () .append (
					<- PonsUsage .borrowOwnPonsCollection (collector: ponsAccount) .withdrawNft (nftId: firstNftId) )
				escrowResource .borrowPonsNfts () .append (
					<- PonsUsage .borrowOwnPonsCollection (collector: ponsAccount) .withdrawNft (nftId: secondNftId) )
				escrowResource .borrowPonsNfts () .append (
					<- PonsUsage .borrowOwnPonsCollection (collector: ponsAccount) .withdrawNft (nftId: thirdNftId) )

				return <- escrowResource } )

		} }
