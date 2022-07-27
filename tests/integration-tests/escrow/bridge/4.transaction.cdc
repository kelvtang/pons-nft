import FungibleToken from 0xFUNGIBLETOKEN
import PonsUtils from 0xPONS
import PonsNftContract from 0xPONS
import PonsNftContract_v1 from 0xPONS
import PonsEscrowContract from 0xPONS
import PonsTunnelContract from 0xPONS

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

		TestUtils .log ("NFT sent through tunnel is sent by user")

		let firstNftId = testInfo ["First NFT nftId"] !
		let secondNftId = testInfo ["Second NFT nftId"] !
		let thirdNftId = testInfo ["Third NFT nftId"] !


		PonsTunnelContract .sendNftThroughTunnel(nftId: firstNftId, ponsAccount: ponsAccount, ponsHolderAccount: artistAccount, tunnelUserAccount: randomAccount, polygonAddress: "0x3455643");
		PonsTunnelContract .sendNftThroughTunnel(nftId: secondNftId, ponsAccount: ponsAccount, ponsHolderAccount: artistAccount, tunnelUserAccount: randomAccount, polygonAddress: "0x3455643");

		} }
