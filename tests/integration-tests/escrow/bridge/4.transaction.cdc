import FungibleToken from 0xFUNGIBLETOKEN
import PonsUtils from 0xPONS
import PonsNftContract from 0xPONS
import PonsNftContract_v1 from 0xPONS
import PonsEscrowContract from 0xPONS
import ponsTunnelContract from 0xPONS

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

	prepare (ponsAccount : AuthAccount, artistAccount : AuthAccount, randomAccount : AuthAccount){//, polygonAddress: String) {

		TestUtils .log ("Random account gifts the first NFT to Artist account using escrows")
		TestUtils .log ("1) Random account submits an escrow demanding nothing in return for the first NFT")
		TestUtils .log ("2) Artist account submits an escrow demanding the first NFT in return for nothing")
		TestUtils .log ("3) Pons account uses the two escrows to satisfy each other")

		let firstNftId = testInfo ["First NFT nftId"] !
		let secondNftId = testInfo ["Second NFT nftId"] !
		let thirdNftId = testInfo ["Third NFT nftId"] !


		ponsTunnelContract .sendNftThroughTunnel(nftId: firstNftId, ponsAccount: ponsAccount, ponsHolderAccount: artistAccount, tunnelUserAccount: randomAccount, polygonAddress: "0x3455643");



		} }
