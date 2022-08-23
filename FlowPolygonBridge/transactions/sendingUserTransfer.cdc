/* 
    Aims to facilitate the tunnel process. Polygon --> Flow
 */

 import PonsTunnelContract from 0xPONS

 transaction(
     polygonRecepientAddress: String,
     nftSerialId: UInt64
 ) {
     prepare (ponsHolderAccount : AuthAccount, userAccount : AuthAccount){
        PonsTunnelContract .sendNftThroughTunnel (nftSerialId: UInt64, ponsHolderAccount: ponsHolderAccount, userAccount: tunnelUserAccount, polygonAddress: polygonRecepientAddress);
     }
 }