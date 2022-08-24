import FungibleToken from 0xFUNGIBLETOKEN
import FlowToken from 0xFLOWTOKEN
import FUSD from 0xFUSD
import NonFungibleToken from 0xNONFUNGIBLETOKEN

/*
	Pons Utils Contract

	This smart contract contains useful type definitions and convenience methods.
*/
pub contract PonsUtils {

	/* Flow Units struct */
	pub struct FlowUnits {
		/* Represents the amount of Flow tokens */
		pub let flowAmount : UFix64 

		init (flowAmount : UFix64) {
			self .flowAmount = flowAmount }

		/* Check whether the amount is at least the amount of another FlowUnits */
		pub fun isAtLeast (_ flowUnits : FlowUnits) : Bool {
			return self .flowAmount >= flowUnits .flowAmount }

		/* Make another FlowUnits equivalent to the amount being scaled by a ratio */
		pub fun scale (ratio : Ratio) : FlowUnits {
			return FlowUnits (flowAmount: self .flowAmount * ratio .amount) }

		/* Make another FlowUnits equivalent to the amount being subtracted by another amount of FlowUnits */
		pub fun cut (_ flowUnits : FlowUnits) : FlowUnits {
			return FlowUnits (flowAmount: self .flowAmount - flowUnits .flowAmount) }


		/* Produce a string representation in a format like "1234.56 FLOW" */
		pub fun toString () : String {
			return self .flowAmount .toString () .concat (" FLOW") } }

	/* Fusd Units struct */
 	pub struct FusdUnits {
		/* Represents the amount of FUSD tokens */
		pub let fusdAmount : UFix64 

		init (fusdAmount : UFix64) {
			self .fusdAmount = fusdAmount }

		/* Check whether the amount is at least the amount of another FusdUnits */
		pub fun isAtLeast (_ fusdUnits : FusdUnits) : Bool {
			return self .fusdAmount >= fusdUnits .fusdAmount }

		/* Make another fusdUnits equivalent to the amount being scaled by a ratio */
		pub fun scale (ratio : Ratio) : FusdUnits {
			return FusdUnits (fusdAmount: self .fusdAmount * ratio .amount) }

		/* Make another FusdUnits equivalent to the amount being subtracted by another amount of FusdUnits */
		pub fun cut (_ fusdUnits : FusdUnits) : FusdUnits {
			return FusdUnits (fusdAmount: self .fusdAmount - fusdUnits .fusdAmount) }


		/* Produce a string representation in a format like "1234.56 FLOW" */
		pub fun toString () : String {
			return self .fusdAmount .toString () .concat (" FUSD") } }

	/* Ratio struct */
	pub struct Ratio {
		/* Represents the numerical ratio, so that for example 0.1 represents 10%, and 1.0 represents 100% */
		pub let amount : UFix64 

		init (amount : UFix64) {
			self .amount = amount } }


	/* Produce a FlowUnits equivalent to the sum of the two separate amounts of FlowUnits */
	pub fun sumFlowUnits (_ flowUnits1 : FlowUnits, _ flowUnits2 : FlowUnits) : FlowUnits {
		let flowAmount1 = flowUnits1 .flowAmount
		let flowAmount2 = flowUnits2 .flowAmount
		return FlowUnits (flowAmount: flowAmount1 + flowAmount2) }

 	/* Produce a FlowUnits equivalent to the sum of the two separate amounts of FusdUnits */
	pub fun sumFusdUnits (_ fusdUnits1 : FusdUnits, _ fusdUnits2 : FusdUnits) : FusdUnits {
		let fusdAmount1 = fusdUnits1 .fusdAmount
		let fusdAmount2 = fusdUnits2 .fusdAmount
		return FusdUnits (fusdAmount: fusdAmount1 + fusdAmount2) } 

// WORKAROUND -- ignore
// For some inexplicable reason Flow is not recognising `&PonsNftContract_v1.Collection` as `&NonFungibleToken.Collection`
//	/* Ensures that the NFTs in a NFT Collection are stored at the correct keys */
//	pub fun normaliseCollection (_ nftCollection : &NonFungibleToken.Collection) : Void {
//		post {
//			nftCollection .ownedNFTs .keys .length == before (nftCollection .ownedNFTs .keys .length):
//				"Size of NFT collection changed" }
//
//		for id in nftCollection .ownedNFTs .keys {
//			PonsUtils .normaliseId (nftCollection, id: id) } }
//
//	/* Ensures that the NFT in a NFT Collection stored at a certain key occupies the key corresponding to its NFT id */
//	priv fun normaliseId (_ nftCollection : &NonFungibleToken.Collection, id : UInt64) : Void {
//		var nftOptional <- nftCollection .ownedNFTs .remove (key: id)
//
//		if nftOptional == nil {
//			destroy nftOptional }
//		else {
//			var nft <- nftOptional !
//
//			if nft .id != id {
//				PonsUtils .normaliseId (nftCollection, id: nft .id) }
//
//			var nftBin <- nftCollection .ownedNFTs .insert (key: nft .id, <- nft)
//			assert (nftBin == nil, message: "Failed to normalise NFT collection")
//			destroy nftBin } }
	}
