import NonFungibleToken from 0xNONFUNGIBLETOKEN

pub contract PonsNftUtils {

	pub fun normaliseCollection (nftCollection : &NonFungibleToken.Collection) : Void {
		post {
			nftCollection .ownedNFTs .keys .length == before (nftCollection .ownedNFTs .keys .length):
				"" }

		for id in nftCollection .ownedNFTs .keys {
			PonsNftUtils .normaliseId (nftCollection : nftCollection, id: id) } }
	priv fun normaliseId (nftCollection : &NonFungibleToken.Collection, id : UInt64) : Void {
		var nftOptional <- nftCollection .ownedNFTs .remove (key: id)

		if nftOptional == nil {
			destroy nftOptional }
		else {
			var nft <- nftOptional !

			if nft .id != id {
				PonsNftUtils .normaliseId (nftCollection : nftCollection, id: id) }

			var nftBin <- nftCollection .ownedNFTs .insert (key: id, <- nft)
			assert (nftBin == nil, message: "")
			destroy nftBin } }
	}
