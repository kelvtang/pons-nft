
import PonsTunnelContract from 0xPONS

/* Unlist a NFT from marketplace */
transaction
( nftId : String
) {
	prepare (nftHolder : AuthAccount) {
        PonsTunnelContract .getNftSerialId (nftId: nftId, collector: nftHolder);
    }
}
