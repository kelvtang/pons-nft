# Pons NFT Contracts

This directory contains all the contracts involved in the Pons NFT marketplace.

On the Pons NFT marketplace, Pons certified artists can request for the marketplace to mint and list their artworks for sale, and set a royalty ratio. On purchase of the NFT, the marketplace takes a commission and the rest of the proceeds are sent to the artist. Once sold, the owner of the NFT is able to list the NFT on the Pons marketplace again, for resale. NFTs listed for resale can be unlisted by the owner.


# Main Resources

In the Pons NFT marketplace system, different kinds of resources are involved:

## PonsArtist 
The PonsArtist resource represents an artist recognised by Pons. Each PonsArtist resource is associated with a unique ponsArtistId (`String`), and also metadata (`{String: String}`), and optionally a Flow Address and a FungibleToken Receiver Capability. All PonsArtist resouces are owned by the Pons account, and everyone can borrow any PonsArtist to check their information.

## PonsArtistCertificate 
The PonsArtistCertificate resource represents an intent on behalf of a recognised Pons Artist. Each PonsArtistCertificate resource contains the ponsArtistId (`String`) which it is related to. PonsArtistCertificate resources can be created either by the artist himself, with the `makePonsArtistCertificate` function using their `PonsCollection`, or by the Pons account on behalf of the artist. The latter method is useful in cases for example when the artist wishes to mint a NFT, but does not yet have a Flow account.

## PonsArtistAuthority 
The PonsArtistAuthority resource represents a controller for the information provided about each Pons Artist. Like a NFT Minter, only one instance is created, and is stored in the contract account. The PonsArtistAuthority resource is also used to create `PonsArtistCertificate`s on behalf of artists.

## PonsCertification
The PonsCertification is a bare resource with no fields, whose only purpose is to indicate certification by Pons for the existence of a PonsNFT. Its purpose will be further elaborated on in the following section on the PonsNft resource.

## PonsNft 
The PonsNft is the main subject of the Pons NFT system. The PonsNft is a NFT which represent artwork created by Pons Artists, implementing the Flow NonFungibleToken contract interface. To ensure authenticity of all PonsNfts that implement the PonsNft resource interface, all PonsNfts are required to possess a `PonsCertification`. This is guaranteed by virtue of the Flow type and resource system, of which the only way to obtain a PonsCertification resource is via a call made by the Pons account to the `makePonsCertification` function.

Each PonsNft is associated with a unique nftId (`String`), a unique serialNumber (`UInt64`; this is the same field as the `id` field required by the NonFungibleToken interface), and also a Pons Artist (`&PonsArtist`), a royalties rate (`Ratio`), an edition label (`String`), and any other metadata (`{String: String}`). These information are accessible to anyone with a reference to a PonsNft.

## NftMinter
The NftMinter (specifically, the NftMinter_v1) resource represents a minter for PonsNft. Only one instance is created, and stored in the Pons account. The NftMinter is used to mint PonsNfts on behalf of Pons Artists.

## PonsCollection 
The PonsCollection resource represents the collection of artwork that a user possesses in the form of NFTs. The PonsCollection resource is used to manage and store PonsNfts owned by users, typically in the standard StoragePath /storage/ponsCollection. The nftIds of PonsNfts in a PonsCollection can be enumerated, and PonsNfts can be borrowed or withdrawn from a PonsCollection, and also PonsNfts can be deposited into a PonsCollection.

## PonsNftMarket 
The PonsNftMarket is the main point of interaction between users and the Pons NFT system. A single instance of the PonsNftMarket resource is globally accessible to anyone on the Flow network. On the Pons NFT Marketplace, Pons Artists can mint and list their artworks as PonsNfts, and anyone can purchase the PonsNfts for sale. After the PonsNft is purchased, it can be listed on the Pons NFT Marketplace again for resale. Later on, the reseller can decide to unlist the PonsNft if he wishes to.

All PonsNfts listed for sale on the Pons NFT Marketplace are available for purchase with Flow tokens. For every purchase made on the Pons NFT Marketplace, the market takes a commission. If the purchase is also a resale, a percentage of the purchase, as indicated by the royalties information of the PonsNft, is delivered to the artist. The rest of the fees are delivered to the artist or lister of the PonsNft.

Whenever a Pons Artist mints a PonsNft or a user lists a PonsNft for resale, he receives a PonsListingCertificate with the details of the listing or minting. If the reseller decides to unlist his PonsNft from the market, this is achieved by trading in the corresponding PonsListingCertificate to prove the listing. PonsListingCertificates issued for the minting of a PonsNft cannot be traded in for the PonsNft. Once the listed PonsNft has been purchased, the issued PonsListingCertificates become ineligible for redemption.

## PonsListingCertificate 
The PonsListingCertificate resource represents a listing or minting of a PonsNft on to the Pons NFT Marketplace. If it represents a listing, it can be redeemed for the original PonsNft if it has not yet been purchased.

## Escrow
The Escrow resource represents a certain request for the Pons account to exchange resources (i.e. Pons NFTs and Flow tokens) for other resources. Anyone can submit Escrows to the Pons Escrow contract. Once submitted, the committed resources are locked-up in a Escrow resource inside the submitter's storage, until either the Escrow is terminated, or the Pons account consummates the Escrow, which grants the exchange for the desired resources. Both the submitter and the Pons account are able to terminate an Escrow, which will cause the locked-up resources to be released to the submitter. Once the Pons account decides that an Escrow no longer requires attention, the Pons account can dismiss the Escrow.

Each Escrow is associated with an id (`String`), a heldResourceDescription (`EscrowResourceDescription`), a requirement (`EscrowResourceDescription`), and a fulfillment (`EscrowFulfillment`). The id is unique at any given time, among Escrows that have not yet been dismissed. This allows the Pons account to differentiate between and fulfill each individual Escrow differently. The heldResourceDescription describes the resources that are locked-up in the Escrow. The requirement describes the minimum amount of Flow tokens and the minimal set of NFTs which will be accepted in exchange for the resources locked-up in the Escrow. The fulfillment contains capabilities for the submitter to receive Flow tokens and NFTs obtained via exchange with the Escrow.

## EscrowManager
The EscrowManager resource represents the means by which the Pons account can browse, consummate, terminate, and dismiss submitted Escrows. Only one instance is created, and stored in the Pons account.


# Contracts

The directory consists of the contracts that form the Pons NFT marketplace:

- PonsUtils.cdc
- PonsCertification.cdc
- PonsNftInterface.cdc
- PonsNft.cdc
- PonsNftMarket.cdc
- PonsNft_v1.cdc
- PonsNftMarket_v1.cdc
- PonsEscrow.cdc

## PonsUtils

This contract provides general utilities for the Pons system, including:

### FlowUnits
The FlowUnits struct type indicates a fixed amount of Flow tokens, allowing the type system to distinguish between arbitrary numbers of `UFix64` and amounts specifically indicating units of Flow.

### Ratio
The Ratio struct type indicates a proportion or percentage, allowing the type system to distinguish between arbitrary or absolute numbers, and amounts specifically meant to be ratios (e.g. a percentage to be taken as royalties).

## PonsCertification

This contract declares the PonsCertification resource.

## PonsNftInterface

This contract is the contract interface for PonsNfts, declaring the resource interfaces for PonsNft, PonsCollection, and PonsNftReceiver. Contracts which implement both the PonsNftInterface and NonFungibleToken interfaces require a NFT resource type which implements PonsNft, and a Collection type which implements PonsCollection and PonsNftReceiver, in addition to the requirements from the NonFungibleToken interface.

As a contract interface, this cannot be merged with the concrete PonsNft contract implementations.

### `PonsNftReceiver`
This resource interface implements only the `depositNft()` function. This interface allows the creation of a Capability that is only able to deposit NFTs into a PonsCollection, but not withdraw from it.

## PonsNft

This contract declares the PonsArtist, PonsArtistCertificate, and PonsArtistAuthority resources. 

### `CollectionStoragePath`
CollectionStoragePath specifies the standard storage path of the PonsCollection of an account.

### `getNftId()`, `getSerialNumber()`, `borrowArtist()`, `getRoyalty()`, `getEditionLabel()`, `getMetadata()` 
These functions are provided for anyone to browse details about PonsNfts.

### `updatePonsNft()`, `PonsNftContractImplementation`
This function provides a mechanism for PonsNfts to be automatically updated when the contract is changed. PonsNfts are automatically updated when a PonsNft is accessed.

Updates to the PonsNft mechanisms can be done by the Pons account via an implementation of the resource interface `PonsNftContractImplementation`.

### `borrowArtistById()`, `getArtistMetadata()`, `getArtistAddress()`, `getArtistReceivePaymentCap()`
These functions are provided for anyone to browse details about Pons artists. 

## PonsNftMarket

This contract declares the resource interfaces PonsNftMarket and PonsListingCertificate.

### `PonsListingCertificateStoragePath`
PonsListingCertificateStoragePath specifies the standard storage path of the ListingCertificates of an account.

### `certificatesOwnedByMarket()`, `getForSaleIds()`, `getPrice()`, `borrowNft()`, `borrowPonsMarket()`,
These functions are provided for anyone to browse the Pons NFT marketplace.

### `setPonsMarket()`
Similar to the `updatePonsNft()`, this function provides a mechanism for the Pons marketplace to be automatically updated.

## PonsNft_v1

This contract declares a simple implementation of the PonsNftInterface and declares a minter resource, NftMinter_v1, for the NFT. On `init()`, this contract utilises the PonsNft update mechanism to activate this implementation.

## PonsNftMarket_v1

This contract declares a simple implementation of the PonsNftMarket resource interface that collects separate commissions for the initial minting and a resale of an NFT. On `init()`, this contract utilises the PonsNftMarket update mechanism to activate this implementation.

## PonsEscrow

This contract declares the EscrowResource, Escrow, and EscrowManager resources. 

### `EscrowResource`
The EscrowResource resource contains resources that are locked-up in an Escrow.

### `EscrowResourceDescription`
The EscrowResourceDescription struct type represents an amount a Flow tokens and a set of Pons NFT IDs.

### `EscrowFulfillment`
The EscrowFulfillment struct type represents capabilities to deposit Flow tokens and Pons NFTs.

### `makeEscrowResource()` 
This function allows anyone to wrap their resources into an EscrowResource.

### `submitEscrow()`, `terminateEscrow()`
This function allows anybody to submit an Escrow, and to terminate Escrows of which they have a reference.

### `resourceDescription()`, `satisfiesResourceDescription()`, `fullfillResource()`
These utility functions allow users to compare EscrowResources with EscrowResourceDescriptions, and to release EscrowResources with EscrowFulfillments.


# Events

## PonsNft

### `PonsNftContractInit()`
Emitted when the PonsNft contract is initialised.

### `PonsNftMinted(nftId : String, serialNumber : UInt64, artistId : String, royalty : PonsUtils.Ratio, editionLabel : String, metadata : {String: String})`
Emitted when a PonsNft is minted.

### `PonsNftWithdrawFromCollection(nftId : String, serialNumber : UInt64, from : Address?)`
Emitted when a PonsNft is withdrawn from a PonsCollection

### `PonsNftDepositToCollection(nftId : String, serialNumber : UInt64, to : Address?)`
Emitted when a PonsNft is deposited to a PonsCollection

## PonsMarket

### `PonsMarketContractInit()`
Emitted when the PonsMarketContract contract is initialised.

### `PonsNFTListed(nftId : String, serialNumber : UInt64, editionLabel : String, price : PonsUtils.FlowUnits)`
Emitted when a PonsNft is listed on the Pons marketplace.

### `PonsNFTUnlisted(nftId : String, serialNumber : UInt64, editionLabel : String, price : PonsUtils.FlowUnits)`
Emitted when a PonsNft is unlisted from the Pons marketplace.

### `PonsNFTSold(nftId : String, serialNumber : UInt64, editionLabel : String, price : PonsUtils.FlowUnits)`
Emitted when a PonsNft on the Pons marketplace is sold.

### `PonsNFTOwns(owner : Address, nftId : String, serialNumber : UInt64, editionLabel : String, price : PonsUtils.FlowUnits)`
Emitted when a PonsNft on the Pons marketplace is sold, and the new owner is known.

## PonsNft_v1

### `PonsNftContractInit_v1()`
Emitted when the PonsNftContract_v1 contract is initialised.

## PonsMarket_v1

### `PonsNftMarketContractInit_v1()`
Emitted when the PonsMarketContract_v1 contract is initialised.

## PonsEscrow

### `PonsEscrowContractInit()`
Emitted when the PonsEscrowContract contract is initialised.

### `PonsEscrowSubmitted(id : String, address : Address, heldResourceDescription : EscrowResourceDescription, requirement : EscrowResourceDescription)`
Emitted when an Escrow is submitted to the Pons account.

### `PonsEscrowConsummated(id : String, address : Address, heldResourceDescription : EscrowResourceDescription, requirement : EscrowResourceDescription, fulfilledResourceDescription : EscrowResourceDescription)`
Emitted when the Pons account consummates an Escrow.

### `PonsEscrowTerminated(id : String, address : Address, heldResourceDescription : EscrowResourceDescription, requirement : EscrowResourceDescription)`
Emitted when an Escrow is terminated.

### `PonsEscrowDismissed(id : String, address : Address)`
Emitted when an Escrow is dismissed.


# Style

- In the Pons NFT marketplace, properties of the system are enforced by types whenever possible
- Functions use named arguments whenever the correctness of the argument is ambigious given its type, and names are omitted whenever the correctness of the argument is evident given its type
- Spaces are liberally used to separate tokens
- Lisp indentation
