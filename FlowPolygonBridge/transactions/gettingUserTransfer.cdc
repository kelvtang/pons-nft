/* 
    Aims to facilitate the tunnel process. Polygon --> Flow
 */

 import PonsTunnelContract from 0xPONS

 transaction(
     nftSerialId: UInt64
 ) {
     prepare (ponsAccount : AuthAccount, ponsHolderAccount : AuthAccount, tunnelUserAccount : AuthAccount){
         PonsTunnelContract .recieveNftFromTunnel (nftSerialId: nftSerialId, ponsAccount: ponsAccount, ponsHolderAccount: ponsHolderAccount, tunnelUserAccount: tunnelUserAccount);
     }
 }