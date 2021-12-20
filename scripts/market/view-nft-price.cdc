import PonsUtils from 0xPONS
import PonsNftMarketContract from 0xPONS

/* Get the price of a NFT on the market for sale */
pub fun main (nftId : String) : PonsUtils.FlowUnits {
	return PonsNftMarketContract .getPrice (nftId: nftId) ! }
