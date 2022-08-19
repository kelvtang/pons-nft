/* 
    Aims to facilitate the tunnel process. Polygon --> Flow
 */

 import PonsTunnelContract from 0xPONS
 import PonsUtils from 0xPONS

 transaction(
    nftSerialId: UInt64
 ) {
     prepare (ponsAccount : AuthAccount, ponsHolderAccount : AuthAccount){
         PonsTunnelContract .sendNftThroughTunnel_market (nftSerialId: nftSerialId, ponsAccount: ponsAccount, ponsHolderAccount: ponsHolderAccount);
     }
 }