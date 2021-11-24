import FungibleToken from 0xFUNGIBLETOKEN
import FlowToken from 0xFLOWTOKEN
import NonFungibleToken from 0xNONFUNGIBLETOKEN

pub contract PonsUtils {

	pub struct FlowUnits {
		pub let flowAmount : UFix64 

		init (flowAmount : UFix64) {
			self .flowAmount = flowAmount }

		pub fun isAtLeast (_ flowUnits : FlowUnits) : Bool {
			return self .flowAmount >= flowUnits .flowAmount }

		pub fun scale (ratio : Ratio) : FlowUnits {
			return FlowUnits (flowAmount: self .flowAmount * ratio .amount) }

		pub fun cut (_ flowUnits : FlowUnits) : FlowUnits {
			return FlowUnits (flowAmount: self .flowAmount - flowUnits .flowAmount) }


		pub fun toString () : String {
			return self .flowAmount .toString () .concat (" FLOW") } }

	pub struct Ratio {
		pub let amount : UFix64 

		init (amount : UFix64) {
			self .amount = amount } }


	pub fun sumFlowUnits (_ flowUnits1 : FlowUnits, _ flowUnits2 : FlowUnits) : FlowUnits {
		let flowAmount1 = flowUnits1 .flowAmount
		let flowAmount2 = flowUnits2 .flowAmount
		return FlowUnits (flowAmount: flowAmount1 + flowAmount2) }

	pub fun prepareFlowCapability (account : AuthAccount) : Capability<&{FungibleToken.Receiver}> {
		if account .borrow <&FlowToken.Vault> (from: /storage/flowTokenVault) == nil {
			account .save (<- FlowToken .createEmptyVault (), to: /storage/flowTokenVault) }

		if ! account .getCapability <&FlowToken.Vault{FungibleToken.Receiver}> (/public/flowTokenReceiver) .check () {
			account .link <&FlowToken.Vault{FungibleToken.Receiver}> (
				/public/flowTokenReceiver,
				target: /storage/flowTokenVault ) }

		if ! account .getCapability <&FlowToken.Vault{FungibleToken.Balance}> (/public/flowTokenBalance) .check () {
			// Create a public capability to the Vault that only exposes
			// the balance field through the Balance interface
			account .link <&FlowToken.Vault{FungibleToken.Balance}> (
				/public/flowTokenBalance,
				target: /storage/flowTokenVault ) }

		return account .getCapability <&{FungibleToken.Receiver}> (/public/flowTokenReceiver) }

	pub fun normaliseCollection (nftCollection : &NonFungibleToken.Collection) : Void {
		post {
			nftCollection .ownedNFTs .keys .length == before (nftCollection .ownedNFTs .keys .length):
				"Size of NFT collection changed" }

		for id in nftCollection .ownedNFTs .keys {
			PonsUtils .normaliseId (nftCollection : nftCollection, id: id) } }

	priv fun normaliseId (nftCollection : &NonFungibleToken.Collection, id : UInt64) : Void {
		var nftOptional <- nftCollection .ownedNFTs .remove (key: id)

		if nftOptional == nil {
			destroy nftOptional }
		else {
			var nft <- nftOptional !

			if nft .id != id {
				PonsUtils .normaliseId (nftCollection : nftCollection, id: id) }

			var nftBin <- nftCollection .ownedNFTs .insert (key: id, <- nft)
			assert (nftBin == nil, message: "Failed to normalise NFT collection")
			destroy nftBin } }
	}
