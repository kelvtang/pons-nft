/* 
    Aims to facilitate the tunnel process. Polygon --> Flow
 */

 import PonsTunnelContract from 0xPONS

 transaction(
     nftSerialId: UInt64
 ) {
     prepare (ponsHolderAccount : AuthAccount, userAddress : AuthAccount){
         PonsTunnelContract .recieveNftFromTunnel (nftSerialId: nftSerialId, ponsHolderAccount: ponsHolderAccount, userAddress: userAddress);
     }
 }