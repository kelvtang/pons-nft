import FungibleToken from 0xFUNGIBLETOKEN
import FlowToken from 0xFLOWTOKEN
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

		/* Exhaustive list of currencies accepted */
		pub let currency:[String]

		/* Holds Type of currency */
		pub var token:String;

		init (flowAmount : UFix64) {
			self .flowAmount = flowAmount 

			self .currency = ["Flow Token", "FUSD"];
			// By default each token is Flow Token
			self .token = self .currency[0]
			}

		/* Function to toggle token to FUSD */
		pub fun setFusd(){
			self .setToken(self .currency[1]);}

		/* Function to toggle token to known currency */
		pub fun setToken(_ key:String){
			if self .currency .contains(key){
				self .token = key;}
			else{
				panic ("Currency Not Recognized")}}

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
			return self .flowAmount .toString () .concat (" ") .concat(self.token) } }

	/* Ratio struct */
	pub struct Ratio {
		/* Represents the numerical ratio, so that for example 0.1 represents 10%, and 1.0 represents 100% */
		pub let amount : UFix64 

		init (amount : UFix64) {
			self .amount = amount } }


	/* Produce a FlowUnits equivalent to the sum of the two separate amounts of FlowUnits */
	pub fun sumFlowUnits (_ flowUnits1 : FlowUnits, _ flowUnits2 : FlowUnits) : FlowUnits {
		if flowUnits1.token != flowUnits2.token{
			panic ("Cannot sum different tokens.");
		}
		let flowAmount1 = flowUnits1 .flowAmount
		let flowAmount2 = flowUnits2 .flowAmount
		var res = FlowUnits (flowAmount: flowAmount1 + flowAmount2);
		res .setToken(flowUnits1.token);
		return res;}

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