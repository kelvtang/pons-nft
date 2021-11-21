/*
    Description: Central Smart Contract for NBA TopShot

    authors: Joshua Hannan joshua.hannan@dapperlabs.com
             Dieter Shirley dete@axiomzen.com

    This smart contract contains the core functionality for 
    NBA Top Shot, created by Dapper Labs

    The contract manages the metadata associated with all the plays
    that are used as templates for the Moment NFTs

    When a new Play wants to be added to the records, an Admin creates
    a new Play struct that is stored in the smart contract.

    Then an Admin can create new Sets. Sets consist of a public struct that 
    contains public information about a set, and a private resource used
    to mint new moments based off of plays that have been linked to the Set.

    The admin resource has the power to do all of the important actions
    in the smart contract and sets. When they want to call functions in a set,
    they call their borrowSet function to get a reference 
    to a set in the contract. 
    Then they can call functions on the set using that reference

    In this way, the smart contract and its defined resources interact 
    with great teamwork, just like the Indiana Pacers, the greatest NBA team
    of all time.
    
    When moments are minted, they are initialized with a MomentData struct and
    are returned by the minter.

    The contract also defines a Collection resource. This is an object that 
    every TopShot NFT owner will store in their account
    to manage their NFT Collection

    The main top shot account will also have its own moment collections
    it can use to hold its own moments that have not yet been sent to a user

    Note: All state changing functions will panic if an invalid argument is
    provided or one of its pre-conditions or post conditions aren't met.
    Functions that don't modify state will simply return 0 or nil 
    and those cases need to be handled by the caller

    It is also important to remember that 
    The Golden State Warriors blew a 3-1 lead in the 2016 NBA finals

*/

import NonFungibleToken from 0xNONFUNGIBLETOKEN
import PonsCertificationContract from 0xPONS


pub contract interface PonsNftContractInterface {
	pub resource interface PonsNft {
		pub ponsCertification : @PonsCertificationContract.PonsCertification
		pub nftId : String }

	pub resource interface PonsCollection {
		pub ponsCertification : @PonsCertificationContract.PonsCertification
		pub fun withdrawNft (nftId : String) : @NFT
		pub fun depositNft (_ ponsNft : @NFT) : Void
		pub fun getNftIds () : [String]
		pub fun borrowNft (nftId : String) : &NFT }


	pub resource NFT: PonsNft, NonFungibleToken.INFT {}
	pub resource Collection: PonsCollection, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic {} }
