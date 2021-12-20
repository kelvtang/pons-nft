import PonsNftContractInterface from 0xPONS
import PonsNftContract from 0xPONS

/* Get the nftIds on the market for sale */
pub fun main (address: Address) : [String] {
	let collector = getAuthAccount (address)
	let ponsCollectionRef = 
		collector .borrow <&{PonsNftContractInterface.PonsCollection}>
			( from: PonsNftContract .CollectionStoragePath )
	return ponsCollectionRef .getNftIds () }
