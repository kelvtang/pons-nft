/* 
    Aims to facilitate the tunnel process. Polygon --> Flow
 */

 import PonsTunnelContract from 0xPONS

 transaction(
     polygonRecepientAddress: String,
     nftSerialId: UInt64
 ) {
     prepare (ponsAccount : AuthAccount, ponsHolderAccount : AuthAccount, tunnelUserAccount : AuthAccount){
        PonsTunnelContract .sendNftThroughTunnelUsingSerialId(nftSerialId: nftSerialId, ponsAccount : ponsAccount, ponsHolderAccount : ponsHolderAccount, tunnelUserAccount : tunnelUserAccount, polygonAddress: polygonRecepientAddress);
     }
 }