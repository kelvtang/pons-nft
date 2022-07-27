/* 
    Aims to facilitate the tunnel process. Polygon --> Flow
 */

 import PonsTunnelContract from 0xPONS

 transaction(
     polygonRecepientAddress: String,
     nftId: String
 ) {
     prepare (ponsAccount : AuthAccount, ponsHolderAccount : AuthAccount, tunnelUserAccount : AuthAccount){
        ponsTunnelContract .sendNftThroughTunnel(nftId : nftId, ponsAccount : ponsAccount, ponsHolderAccount : ponsHolderAccount, tunnelUserAccount : tunnelUserAccount, polygonAddress: polygonRecepientAddress);
     }
 }