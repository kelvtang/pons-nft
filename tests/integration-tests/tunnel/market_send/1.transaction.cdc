import FungibleToken from 0xFUNGIBLETOKEN
import PonsUtils from 0xPONS
import PonsNftContractInterface from 0xPONS
import PonsNftContract from 0xPONS
import PonsNftContract_v1 from 0xPONS
import PonsNftMarketContract from 0xPONS
import PonsTunnelContract from 0xPONS

import TestUtils from 0xPONS
import PonsUsage from 0xPONS

transaction(
    nftID: String
){
    prepare(ponsAccount: AuthAccount, ponsHolderAccount: AuthAccount){
        var nftSerialID:UInt64 = PonsTunnelContract .getNftSerialId (nftId: nftID, collector: ponsAccount);
        PonsTunnelContract .sendNftThroughTunnel_market(nftSerialId: nftSerialID, ponsAccount: ponsAccount, ponsHolderAccount: ponsHolderAccount);

        if PonsNftMarketContract .getForSaleIds() .contains(nftID){
            panic("Tunnel: NFT not delisted")
        }
    }
}