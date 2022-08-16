// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";

contract ERC721ArtistID {
    mapping(uint256 => string) private flowArtistID;
    mapping(uint256 => address) private polygonArtistID;
    mapping(string => address) private flowPolygonArtistID;

    mapping(address => bool) private fxManagers;
    modifier onlyFxManager{
        require(fxManagers[msg.sender], "ERC721ArtistID: Function must be called by approved fxManager");
        _;
    }

    /**
        @notice on deployment contract owner is given fxManager authority.
        note: contract itself doesn't inherit from OwnableUpgradable.sol
    */
    constructor(){
        addFxManager(msg.sender);
    }
    /**
        @notice approved addresses can approve other addresses
    */
    function addFxManager(address _fxManager) public onlyFxManager{fxManagers[_fxManager] = true;}
    /**
        @notice approved addresses can revoke approval of other addresses
    */
    function revokeFxManager(address _fxManager) public onlyFxManager{delete fxManagers[_fxManager];}

    /**
        @notice Each NFT is mapped to a flow ArtistID. This is because we assume all NFT were minted on Flow or by a user with a flow account.
    */
    function setFlowArtistID(uint256 tokenId, string memory _flowArtistId) internal{
        flowArtistID[tokenId] = _flowArtistId;
    }
    /**
        @notice If artist has polygon address then we can map NFT to polygon address.
    */
    function setPolygonArtistID(uint256 tokenId, address _polygonArtistId) internal{
        polygonArtistID[tokenId] = _polygonArtistId;
    }
    /**
        @notice We can map Flow Artist ID to polygon account addresses.
        @dev The account must be manually verified by PONs and this function must be triggered 
            by Owner or other approved address.
        @dev This will allow for newly registered accounts to be able to get royalties directly 
            on transaction of older NFT's which were minted before the artist's account registration.
    */
    function setFlowIdToPolygonId(address _polygonArtistId, string calldata _flowArtistId) public onlyFxManager{
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

    /**
        @notice we try to return a polygon address associated with NFT.
            If NFT had polygon address during minting, then that is returned.
            If Artist is registered and NFT was an older work then registered address is returned.
            Else an empty address is returned, this also helps signify that no artist is associated with NFT yet.
    */
    function getPolygonFromFlow_tokenID(uint256 tokenId) public view returns (address) {
        return (polygonArtistID[tokenId] != address(0x0) ? polygonArtistID[tokenId] : flowPolygonArtistID[flowArtistID[tokenId]]);
    }

}