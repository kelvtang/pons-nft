import FungibleToken from 0xFUNGIBLETOKEN
import PonsNftContractInterface from 0xPONS
import PonsNftContract from 0xPONS
import PonsNftContract_v1 from 0xPONS
import PonsNftMarketContract from 0xPONS
import PonsNftMarketContract_v1 from 0xPONS
import PonsUtils from 0xPONS



/*
	Pons NFT Market Admin Contract v1

	This smart contract contains the Pons NFT Market Admin resource.
	The resource allows updates to be delivered to NFTs, and allows the marketplace to retrieve and deliver directly NFTs when payment has been otherwise rendered.
*/
pub contract PonsNftMarketAdminContract_v1 {

	/* Storage path at which the NFT Admin resource will be stored */
	access(account) let AdminStoragePath : StoragePath

	/* Capability to the NFT Admin, for convenience of usage */
	access(account) let AdminCapability : Capability<&NftMarketAdmin_v1>


	/* PonsNftMarketAdminContractInit_v1 is emitted on initialisation of this contract */
	pub event PonsNftMarketAdminContractInit_v1 ()




/*
	Pons NFT Market v1 Admin resource

	This resource enables updates to Pons NFTs and maintenance of the marketplace.
*/
	pub resource NftMarketAdmin_v1 {

		/* Updates the price of the Pons NFT on the marketplace */
		pub fun updateSalePriceFlow (nftId : String, price : PonsUtils.FlowUnits) : Void {
			let ponsNftMarketRef = & PonsNftMarketContract .ponsMarket as auth &{PonsNftMarketContract.PonsNftMarket}
			let ponsNftMarketV1Ref = ponsNftMarketRef as! &PonsNftMarketContract_v1.PonsNftMarket_v1
			ponsNftMarketV1Ref .insertSalePriceFlow (nftId: nftId, price: price) }
		pub fun updateSalePriceFusd (nftId : String, price : PonsUtils.FusdUnits) : Void {
			let ponsNftMarketRef = & PonsNftMarketContract .ponsMarket as auth &{PonsNftMarketContract.PonsNftMarket}
			let ponsNftMarketV1Ref = ponsNftMarketRef as! &PonsNftMarketContract_v1.PonsNftMarket_v1
			ponsNftMarketV1Ref .insertSalePriceFusd (nftId: nftId, price: price) }

		/* Borrows the NFT collection of the marketplace */
		pub fun borrowCollection () : &PonsNftContract_v1.Collection {
			let ponsNftMarketRef = & PonsNftMarketContract .ponsMarket as auth &{PonsNftMarketContract.PonsNftMarket}
			let ponsNftMarketV1Ref = ponsNftMarketRef as! &PonsNftMarketContract_v1.PonsNftMarket_v1
			return & ponsNftMarketV1Ref .collection as &PonsNftContract_v1.Collection } 

		/* Delist NFT from the marketplace */
		pub fun delistNftFromMarketplace(nftId : String) : Void{
			let ponsNftMarketRef = & PonsNftMarketContract .ponsMarket as auth &{PonsNftMarketContract.PonsNftMarket}
			let ponsNftMarketV1Ref = ponsNftMarketRef as! &PonsNftMarketContract_v1.PonsNftMarket_v1
			var sale_price_flow = ponsNftMarketV1Ref .removeSalePriceFlow(nftId:nftId)
			var sale_price_fusd = ponsNftMarketV1Ref .removeSalePriceFusd(nftId:nftId)
			if sale_price_flow == nil && sale_price_fusd == nil {
				panic ("nft not included in sales list")
			}
		}
	}

	

	init () {
		// Save the admin storage path
		self .AdminStoragePath = /storage/ponsMarketAdmin_v1

		// Save a NFT v1 Admin to the specified storage path
        	self .account .save (<- create NftMarketAdmin_v1 (), to: self .AdminStoragePath)

		// Create and save a capability to the admin for convenience
		self .AdminCapability = self .account .link <&NftMarketAdmin_v1> (/private/ponsMarketAdmin_v1, target: self .AdminStoragePath) !

		// Emit the Pons NFT Market Admin v1 contract initialisation event
		emit PonsNftMarketAdminContractInit_v1 () } }
