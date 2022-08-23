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
    nftId: String, 
    polygonListingAddress: String, 
    salePrice: UFix64
){
    prepare(ponsAccount: AuthAccount, ponsHolderAccount: AuthAccount){
        let nftSerialId = PonsTunnelContract .getNftSerialId (nftId: nftId, collector: ponsHolderAccount);

        PonsTunnelContract .recieveNftFromTunnel_market_flow (nftSerialId: nftSerialId, ponsAccount: ponsAccount, ponsHolderAccount: ponsHolderAccount, polygonListingAddress: polygonListingAddress, salePrice: salePrice);

        if !PonsNftMarketContract .getForSaleIds() .contains(nftId){
            panic("Tunnel: NFT not relisted at market")
        }

    }
}