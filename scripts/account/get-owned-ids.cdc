import PonsNftContractInterface from 0xPONS
import PonsNftContract from 0xPONS

/* Get the nftIds owned by an account */
pub fun main (address: Address) : [String] {
	// This does not work yet; refer to 
	// https://github.com/onflow/cadence/issues/1321
	let collector = getAuthAccount (address)
	let ponsCollectionRef = 
		collector .borrow <&{PonsNftContractInterface.PonsCollection}>
			( from: PonsNftContract .CollectionStoragePath )
	return ponsCollectionRef .getNftIds () }
