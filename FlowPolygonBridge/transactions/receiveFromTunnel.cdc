/* 
    Aims to facilitate the tunnel process. Polygon --> Flow
 */

 import PonsTunnelContract from 0xPONS

 transaction(
     flowRecepientAddress: Address,
     nftSerialId: UInt64
 ) {
     prepare (ponsAccount : AuthAccount, ponsHolderAccount : AuthAccount, tunnelUserAccount : AuthAccount){
         if flowRecepientAddress == tunnelUserAccount .Address{
            PonsTunnelContract .recieveNftFromTunnel(nftSerialId: nftSerialId, ponsAccount : ponsAccount, ponsHolderAccount : ponsHolderAccount, tunnelUserAccount : AuthAccount);
        }else {
            panic ("Only recipient can sign tranaction")
        }
     }
 }