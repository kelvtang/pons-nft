// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./FxERC721.sol";
import "./Ownable.sol";
import "./IERC721Receiver.sol";
import "./PonsNftMarket.sol";

contract FlowTunnel is Ownable, IERC721ReceiverUpgradeable { 

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

    /**
    * Transfer NFT held by this contract to an address.
    */
    function transferToken(uint256 tokenId, address to) public onlyOwner {
        require(tokenOwner(tokenId)!=to, "Tunnel: Transfer NFT to owner");
        FxERC721(tokenContractAddress).safeTransferFrom(address(this), to, tokenId);
    }

    function mintNewNft(uint256 tokenId, bytes memory _data) internal returns (uint256) {
        require(!tokenExists(tokenId), "NFT already exists"); // test if nft already exists.
        
        // New nft minted and owned by tunnel contract
        FxERC721(tokenContractAddress).mint(address(this), tokenId, _data); 
        
        emit newNftMinted(tokenId, address(this));
        return tokenId;
    }


    mapping(uint256 => address) private tunnelUserAddress;
    
    function setupTunnel(uint256 tokenId) public {
        require(tokenExists(tokenId), "Tunnel: NFT by this token ID doesn't exist");
        require(tokenOwner(tokenId) == msg.sender, "Tunnel: NFT can only be sent by owner");
        // List who originally owns the NFT.
        tunnelUserAddress[tokenId] = msg.sender;
    }

    function sendThroughTunnel(uint256 tokenId, string calldata flowAddress) public {
        require(tokenExists(tokenId), "Tunnel: NFT by this token ID doesn't exist"); 
        require (tunnelUserAddress[tokenId] == msg.sender, "Tunnel: NFT can only be sent by original owner.");
        require (tokenOwner(tokenId) == address(this), "Tunnel: NFT not held by contract. Send nft to contract.");

        // No need to transfers, nft is held by Tunnel contract.

        // Revoke any approvals on NFT.
        FxERC721(tokenContractAddress).revokeApproval(tokenId);
        assert(FxERC721(tokenContractAddress).getApproved(tokenId) == address(0x0));

        // Delist nft from marketplace.
        if (PonsNftMarket(marketContractAddress).islisted(tokenId)){
            PonsNftMarket(marketContractAddress).unlist(tokenId);
        }

        delete tunnelUserAddress[tokenId];

        emit nftSentThroughTunnel(tokenId, msg.sender, flowAddress);
    }

    function getFromTunnel(uint256 tokenId, address to, bytes calldata data, uint256 tokenPrice) public onlyOwner {
        require(to != address(0x0), "Tunnel: NFT being transfered to 0x0 address.");
        if (!tokenExists(tokenId)){
            bytes memory _data = data;
            tokenId = mintNewNft(tokenId, _data);
        }

        /**
        * You must list token on market place before transferring it.
        */
        if (to == marketContractAddress){
            PonsNftMarket(marketContractAddress).listForSale(tokenId, tokenPrice); //TODO: Replace dummy price
        }
        FxERC721(tokenContractAddress).safeTransferFrom(address(this), to, tokenId);
        assert(tokenOwner(tokenId) == to);

        /**
        * To handle inter-blockchain purchases, we list transfered nft on polygon marketplace.
         */
        

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
