// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./OwnableUpgradeable.sol";
import "./FxERC721.sol";
import "./IERC721Receiver.sol";

contract FxERC721FxManager is OwnableUpgradeable, IERC721ReceiverUpgradeable {

    mapping(address => bool) private _approvedProxyTunnels;
    
    address public fxTokenProxy;

    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __Context_init();
        __Ownable_init();
    }

    function setTokenProxy(address _fxTokenProxy) public onlyOwner {
        require(fxTokenProxy == address(0x0), "Token proxy address already set");
        fxTokenProxy = _fxTokenProxy;
    }

    function onERC721Received(
        address, /* operator */
        address, /* from */
        uint256, /* tokenId */
        bytes calldata /* data */
    ) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function addApproval(address tunnelProxy) public onlyOwner {
        require(_approvedProxyTunnels[tunnelProxy] != true, "Tunnel address already approved");
        _approvedProxyTunnels[tunnelProxy] = true;
    }   

    function isApproved(address tunnelProxy) public view returns(bool){
        return _approvedProxyTunnels[tunnelProxy] == true ? true : false;
    }

    function removeApproval(address tunnelProxy) public onlyOwner {
        require(_approvedProxyTunnels[tunnelProxy] == true, "Tunnel proxy address has no exisiting approval");
        delete _approvedProxyTunnels[tunnelProxy];
    }

    function appendFundsDue(uint256 _tokenId, uint256 value) public {
        require (_approvedProxyTunnels[msg.sender] == true, "Caller contract not approved");
        require (fxTokenProxy != address(0x0), "No connected token proxy contract to call");

        FxERC721 childTokenContract = FxERC721(fxTokenProxy);
        // child token contract will have root token
        address _connectedProxy = childTokenContract.connectedToken();

        // validate root and child token mapping
        require(
            _connectedProxy != address(0x0),
            "FxERC721FxManager: NO_MAPPED_TOKEN"
        );
        FxERC721(fxTokenProxy)._appendFundsDue(_tokenId, value);
    }

    function emptyFundsDue(string calldata _flowArtistId) public {
        require (_approvedProxyTunnels[msg.sender] == true, "Caller contract not approved");
        require (fxTokenProxy != address(0x0), "No connected token proxy contract to call");

        FxERC721 childTokenContract = FxERC721(fxTokenProxy);
        // child token contract will have root token
        address _connectedProxy = childTokenContract.connectedToken();

        // validate root and child token mapping
        require(
            _connectedProxy != address(0x0),
            "FxERC721FxManager: NO_MAPPED_TOKEN"
        );
        FxERC721(fxTokenProxy)._emptyFundsDue(_flowArtistId);
    }

    function mintToken(
        address to,
        uint256 tokenId,
        bytes memory data
    ) public {
        require (_approvedProxyTunnels[msg.sender] == true, "Caller contract not approved");
        require (fxTokenProxy != address(0x0), "No connected token proxy contract to call");

        FxERC721 childTokenContract = FxERC721(fxTokenProxy);
        // child token contract will have root token
        address _connectedProxy = childTokenContract.connectedToken();

        // validate root and child token mapping
        require(
            _connectedProxy != address(0x0),
            "FxERC721FxManager: NO_MAPPED_TOKEN"
        );
        
        FxERC721(fxTokenProxy).mint(to, tokenId, data);
    }


    function burnToken(
        address caller,
        uint256 tokenId
    ) public {
        require (_approvedProxyTunnels[msg.sender] == true, "Caller contract not approved");
        require (fxTokenProxy != address(0x0), "No connected token proxy contract to call");

        FxERC721 TokenProxyContract = FxERC721(fxTokenProxy);

        // child token contract will have root token
        address _connectedProxy = TokenProxyContract.connectedToken();

        // validate root and child token mapping
        require(
             _connectedProxy != address(0x0),
            "FxERC721FxManager: NO_MAPPED_TOKEN"
        );

        require(
            caller == TokenProxyContract.ownerOf(tokenId),
            "Caller is not owner of token"
        );

        FxERC721(fxTokenProxy).burn(tokenId);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[48] private __gap;
}