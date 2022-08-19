/* 
    Aims to facilitate the tunnel process. Polygon --> Flow
 */

 import PonsTunnelContract from 0xPONS
 import PonsUtils from 0xPONS

 transaction(
    nftSerialId: UInt64,
    salePriceFlow: PonsUtils.FlowUnits,
    polygonListingAddress: String
 ) {
     prepare (ponsAccount : AuthAccount, ponsHolderAccount : AuthAccount){
         PonsTunnelContract .recieveNftFromTunnel_market_flow (nftSerialId: nftSerialId, ponsAccount: ponsAccount, ponsHolderAccount: ponsHolderAccount, polygonListingAddress: polygonListingAddress, salePriceFlow: salePriceFlow);
     }
 }