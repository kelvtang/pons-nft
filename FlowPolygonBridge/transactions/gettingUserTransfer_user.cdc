/* 
    Aims to facilitate the tunnel process. Polygon --> Flow
 */

 import PonsTunnelContract from 0xPONS

 transaction(
     nftSerialId: UInt64
 ) {
     prepare (userAccount : AuthAccount){
         PonsTunnelContract .withdrawFromTunnel (nftSerialId: nftSerialId, userAccount: userAccount);
     }
 }