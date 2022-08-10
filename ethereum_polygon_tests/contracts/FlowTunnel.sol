// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./FxERC721.sol";
import "./Ownable.sol";
import "./IERC721Receiver.sol";
import "./PonsNftMarket.sol";

contract FlowTunnel is Ownable, IERC721Receiver { 

    address private tokenContractAddress;
    address private marketContractAddress;

    constructor(address _tokenContractAddress, address _marketContractAddress){
        tokenContractAddress = _tokenContractAddress;
        marketContractAddress = _marketContractAddress;
    }
    function setMarketContractAddress(address _marketContractAddress) public onlyOwner{
        marketContractAddress = _marketContractAddress;
    }
    function setTokenContractAddress(address _tokenContractAddress) public onlyOwner{
        tokenContractAddress = _tokenContractAddress;
    }

    event nftSentThroughTunnel(uint256 tokenId,address from,string flowAddress);
    event nftReceievedFromTunnel(uint256 tokenId, address to);
    event newNftMinted(uint256 tokenId, address to);

    error nftNotHeldOnFlow();
    error nftNotSent();
    error nftNotReceieved();

    function tokenExists(uint256 tokenId) public view returns (bool){
        return FxERC721(tokenContractAddress).exists(tokenId);
    }
    function tokenOwner(uint256 tokenId) public view returns (address){
        return FxERC721(tokenContractAddress).ownerOf(tokenId);
    }

    function mintNewNft(address user, uint256 tokenId, bytes memory _data) internal returns (uint256) {
        require(!tokenExists(tokenId), "NFT already exists"); // test if nft already exists.
        
        FxERC721(tokenContractAddress).mint(user, tokenId, _data); // --> mint new nft token

        /* moving with assumption that it is minted to the pons account, will be transferred out. */

        emit newNftMinted(tokenId, user);
        return tokenId;
    }

    function sendThroughTunnel(uint256 tokenId, string calldata flowAddress) public {
        require (tokenExists(tokenId), "Nft by this token does not exist"); 
        require (tokenOwner(tokenId) == msg.sender, "Nft not held by sender");

        /**
        * nft will be transfered from user to contract.
        * nft will be held in FlowTunnel.sol contract.
        */    
        FxERC721(tokenContractAddress).transfer(msg.sender, address(this), tokenId);
        
        /**
        * Delist nft from marketplace, nft should not be sold in two places at once.
        */
        if (PonsNftMarket(marketContractAddress).islisted(tokenId)){
            PonsNftMarket(marketContractAddress).unlist(tokenId);
        }

        emit nftSentThroughTunnel(tokenId, msg.sender, flowAddress);
    }

    function getFromTunnel(uint256 tokenId, address to, bytes calldata data) public onlyOwner {
        require(to != address(0x0), "Nft being transfered to 0x0 address.");
        if (!tokenExists(tokenId)){
            bytes memory _data = data;
            tokenId = mintNewNft(address(this), tokenId, _data);
        }

        FxERC721(tokenContractAddress).transfer(address(this), to, tokenId);
        assert(tokenOwner(tokenId) == to);

        /**
        * To handle inter-blockchain purchases, we list transfered nft on polygon marketplace.
         */
        if (to == marketContractAddress){
            PonsNftMarket(marketContractAddress).listForSale(tokenId, 5000); // Dummy price
        }

        emit nftReceievedFromTunnel(tokenId, msg.sender);
    }


    function onERC721Received(
        address, /* operator */
        address, /* from */
        uint256, /* tokenId */
        bytes calldata /* data */
    ) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
