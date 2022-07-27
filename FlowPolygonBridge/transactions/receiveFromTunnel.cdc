/* 
    Aims to facilitate the tunnel process. Polygon --> Flow
 */

 import PonsTunnelContract from 0xPONS

 transaction(
     flowRecepientAddress: Address,
     nftId: String
 ) {
     prepare (ponsAccount : AuthAccount, ponsHolderAccount : AuthAccount, tunnelUserAccount : AuthAccount){
         if flowRecepientAddress == tunnelUserAccount .Address{
            ponsTunnelContract .recieveNftFromTunnel(nftId : nftId, ponsAccount : ponsAccount, ponsHolderAccount : ponsHolderAccount, tunnelUserAccount : AuthAccount);
        }else {
            panic ("Only recipient can sign tranaction")
        }
     }
 }