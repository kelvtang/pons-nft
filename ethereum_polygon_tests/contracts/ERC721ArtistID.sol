// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";

contract ERC721ArtistID is Ownable{
    mapping(uint256 => string) private flowArtistID;
    mapping(uint256 => address) private polygonArtistID;
    mapping(string => address) private flowPolygonArtistID;

    mapping(address => bool) private fxManagers;
    modifier onlyFxManager{
        require(fxManagers[msg.sender], "ERC721ArtistID: Function must be called by approved fxManager");
        _;
    }

    constructor(){
        addFxManager(owner()); // Owner can call functions.
    }

    function addFxManager(address _fxManager) public onlyOwner{fxManagers[_fxManager] = true;}
    function revokeFxManager(address _fxManager) public onlyOwner{delete fxManagers[_fxManager];}


    function setFlowArtistID(uint256 tokenId, string memory _flowArtistId) public onlyFxManager{
        flowArtistID[tokenId] = _flowArtistId;
    }
    function setPolygonArtistID(uint256 tokenId, address _polygonArtistId) public onlyFxManager{
        polygonArtistID[tokenId] = _polygonArtistId;
    }
    
    function setFlowIdToPolygonId(address _polygonArtistId, string memory _flowArtistId) public onlyOwner {
        flowPolygonArtistID[_flowArtistId] = _polygonArtistId;
    }

    function getFlowArtistId(uint256 tokenId) public view returns (string memory) {
        return flowArtistID[tokenId];
    }
    function getPolygonArtistId(uint256 tokenId) public view returns (address) {
        return polygonArtistID[tokenId];
    }
    function getPolygonFromFlow_calldata(string calldata _flowArtistId) public view returns (address) {
        return flowPolygonArtistID[_flowArtistId];
    }
    function getPolygonFromFlow_memory(string memory _flowArtistId) public view returns (address) {
        return flowPolygonArtistID[_flowArtistId];
    }

}