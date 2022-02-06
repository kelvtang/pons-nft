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

		TestUtils .log ("Escrows cannot be consummated if the NFT requirements are not met")
		TestUtils .log ("Artist account has submitted an escrow demanding the second NFT and 5 FLOW in return for the first NFT")
		TestUtils .log ("Pons account attempts to consummate the escrow with the second NFT, and no Flow tokens")
		TestUtils .log ("This should fail")

		let firstNftId = testInfo ["First NFT nftId"] !
		let secondNftId = testInfo ["Second NFT nftId"] !
		let thirdNftId = testInfo ["Third NFT nftId"] !



		let escrowManagerRef = ponsAccount .borrow <&PonsEscrowContract.EscrowManager> (from: /storage/escrowManager) !
		

		escrowManagerRef .consummateEscrow (
			id: "consummation-test-transaction-6-artist",
			consummation: fun (_ firstNftEscrowResource : @PonsEscrowContract.EscrowResource) : @PonsEscrowContract.EscrowResource {

				var firstNft <- firstNftEscrowResource .borrowPonsNfts () .remove (at: 0)

				PonsUsage .borrowOwnPonsCollection (collector: ponsAccount) .depositNft (<- firstNft)

				destroy firstNftEscrowResource

				return <- PonsEscrowContract .makeEscrowResource (
					flowVault: <- ponsAccount .borrow <&FungibleToken.Vault> (from: /storage/flowTokenVault) ! .withdraw (amount: 0.0),
					ponsNfts: <- [ <- PonsUsage .borrowOwnPonsCollection (collector: ponsAccount) .withdrawNft (nftId: secondNftId) ] ) } )

		} }
