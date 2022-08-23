import FungibleToken from 0xFUNGIBLETOKEN
import PonsUtils from 0xPONS
import PonsNftContractInterface from 0xPONS
import PonsNftContract from 0xPONS
import PonsNftContract_v1 from 0xPONS
import PonsNftMarketContract from 0xPONS
import PonsTunnelContract from 0xPONS

import TestUtils from 0xPONS
import PonsUsage from 0xPONS


transaction (
    nftId: String, 
){
    prepare(ponsHolderAccount: AuthAccount, userAccount: AuthAccount){
        let nftSerialId = PonsTunnelContract .getNftSerialId (nftId: nftId, collector: userAccount);

        PonsTunnelContract .recieveNftFromTunnel (nftSerialId: nftSerialId, ponsHolderAccount: ponsHolderAccount, userAddress: userAccount.address);

        let nft <- PonsTunnelContract .withdrawFromTunnel (nftSerialId: nftSerialId, userAccount: userAccount);
        if nft == nil{
            panic("Nft Extraction Failed")
        }
    }
}