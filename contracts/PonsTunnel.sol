// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


// import "./ERC721.sol";
import "./FxERC721.sol";

contract PonsNftTunnel { // create new instance

    address private tunnelOwner;
    constructor (address _tunnelOwner){
        tunnelOwner = _tunnelOwner;
    }

    FxERC721 tokenContract = new FxERC721(tunnelOwner); //refernce to contract.

    event nftSentThroughTunnel(uint256 tokenId,address from,string flowAddress);
    event nftReceievedFromTunnel(uint256 tokenId, address to);
    event newNftMinted(uint256 tokenId, address to);

    error nftNotHeldOnFlow();
    error nftNotSent();
    error nftNotReceieved();

    function mintNewNft(address user,uint256 tokenId,bytes memory _data) 
      internal returns (uint256 _tokenId) {
        require(!(FxERC721(tokenContract).exists(tokenId)), "NFT already exists"); // test if nft already exists.
        
        FxERC721(tokenContract).mint(user, tokenId, _data); // --> mint new nft token

        /* moving with assumption that it is minted to the pons account, will be transferred out. */

        emit newNftMinted(tokenId, user);
        return tokenId;
    }

    function sendThroughTunnel(uint256 tokenId, string calldata flowAddress) public returns (uint256) {
        require(FxERC721(tokenContract).exists(tokenId), "Nft by this token does not exist"); 
        require(FxERC721(tokenContract).ownerOf(tokenId)==address(msg.sender), "Nft not held by sender."); // --> can be adjusted if holder is different account

        FxERC721(tokenContract).transfer(msg.sender, address(this), tokenId); // --> nft held in this account.

        /* 
        TODO: 
            * unlist nft if listed in marketplace
                * handle at relay
        */

        emit nftSentThroughTunnel(tokenId, msg.sender, flowAddress);
        return tokenId;
    }

    function getFromTunnel(uint256 tokenId, address to, bytes calldata data) public returns ( uint256) {
        require(to != address(0), "Nft being transfered to 0x0 address.");
        if (!FxERC721(tokenContract).exists(tokenId)){
            bytes memory _data = data;
            tokenId = mintNewNft(address(this), tokenId, _data);
        }
        FxERC721(tokenContract).transfer(address(this), to, tokenId);
        assert(FxERC721(tokenContract).ownerOf(tokenId)==to);
        /* 
        TODO: 
            * test for ownership
            * release locked up nft
                * mint new one if being transferred for first time.
            * emit data
        */
        emit nftReceievedFromTunnel(tokenId, msg.sender);
        return tokenId;
    }
}
