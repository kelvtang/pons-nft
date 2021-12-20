import PonsNftMarketContract from 0xPONS

/* Get the nftIds on the market for sale */
pub fun main () : [String] {
	return PonsNftMarketContract .getForSaleIds () }
