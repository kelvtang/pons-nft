// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Initializable.sol";

contract ERC721ArtistID is Initializable {
    function __ERC721ArtistID_init() internal onlyInitializing {
    }

    function __ERC721ArtistID_init_unchained() internal onlyInitializing {
    }

    mapping(uint256 => string) private artistID;
    mapping(uint256 => address) private polygonArtistAddress;
    mapping(string => address) internal flowPolygonArtistAddress;

    /**
    * @notice Each NFT is mapped to a flow ArtistID. 
    * This is because we assume all NFT were minted on Flow or by a user with a flow account.
    */
    function setArtistId(uint256 tokenId, string memory _artistId) internal{
        artistID[tokenId] = _artistId;
    }
    /**
    * @notice If artist has polygon address then we can map NFT to polygon address.
    */
    function setPolygonArtistAddress(uint256 tokenId, address _polygonArtistAddress) internal{
        polygonArtistAddress[tokenId] = _polygonArtistAddress;
    }
    
    function getArtistId(uint256 tokenId) public view returns (string memory) {
        return artistID[tokenId];
    }
    function getPolygonArtistAddress(uint256 tokenId) public view returns (address) {
        return polygonArtistAddress[tokenId];
    }
    function getPolygonFromFlow_calldata(string calldata _artistId) public view returns (address) {
        return flowPolygonArtistAddress[_artistId];
    }
    function getPolygonFromFlow_memory(string memory _artistId) public view returns (address) {
        return flowPolygonArtistAddress[_artistId];
    }

    /**
    * @notice we try to return a polygon address associated with NFT.
    * If NFT had polygon address during minting, then that is returned.
    * If Artist is registered and NFT was an older work then registered address is returned.
    * Else an empty address is returned, this also helps signify that no artist is associated with NFT yet.
    */
    function getPolygonFromFlow_tokenID(uint256 tokenId) public view returns (address) {
        return (polygonArtistAddress[tokenId] != address(0x0) ? polygonArtistAddress[tokenId] 
        : flowPolygonArtistAddress[artistID[tokenId]]);
    }

    /**
    * @dev This empty reserved space is put in place to allow future versions to add new
    * variables without shifting down storage in the inheritance chain.
    * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
    */
    uint256[47] private __gap;
}