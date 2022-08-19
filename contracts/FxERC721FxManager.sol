// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./OwnableUpgradeable.sol";
import "./FxERC721.sol";
import "./IERC721Receiver.sol";

contract FxERC721FxManager is OwnableUpgradeable, IERC721ReceiverUpgradeable {

    // mapping that stores tunnel addresses that can call this contract's functions
    mapping(address => bool) private _approvedProxyTunnels;
    
    address public fxTokenProxy;

    constructor() {
        _disableInitializers();
    }

    /** 
    * @dev public function that is called when the proxy contract managing this contract is deployed through the {_data} variable
    * This function can only be called once and cannot be called again later on, even when the contract is upgraded.
    * See {ERC1967Proxy-constructor}.
    */
    function initialize() public initializer {
        __Context_init();
        __Ownable_init();
    }

    /**
    * @dev public function that can be only called by the deployer of the contract when {fxTokenProxy} is not set
    *
    * @param _fxTokenProxy address representing the FxERC721 contract proxy deployed on polygons
    */
    function setTokenProxy(address _fxTokenProxy) public onlyOwner {
        require(fxTokenProxy == address(0x0), "Token proxy address already set");
        fxTokenProxy = _fxTokenProxy;
    }

    function onERC721Received(
        address, /* operator */
        address, /* from */
        uint256, /* tokenId */
        bytes calldata /* data */
    ) 
        external 
        pure 
        override 
        returns (bytes4) 
    {
        return this.onERC721Received.selector;
    }

    /**
    * @dev public function that approves a tunnel address to call fxERC721 functions that require fxManager approval
    * Can only be called by owner
    *
    * @param tunnelProxy address representing the tunnel proxy contract to give approval to
    */
    function addApproval(address tunnelProxy) public onlyOwner {
        require(_approvedProxyTunnels[tunnelProxy] != true, "Tunnel address already approved");
        _approvedProxyTunnels[tunnelProxy] = true;
    }   

    /**
    * @dev public function that returns whether a given address is approved to call this contract's functions or not
    *
    * @param tunnelProxy address representing the contract to be checked for approval
    * @return boolean true if tunnel is approved, false otherwise 
    */
    function isApproved(address tunnelProxy) public view returns(bool){
        return _approvedProxyTunnels[tunnelProxy] == true ? true : false;
    }

    /**
    * @dev public function that deletes an approved tunnel address approval
    * Can only be called by owner
    * After this is called for an address, the removed address can no longer use this contract's functions
    *
    * @param tunnelProxy address representing the contract to remove approval for
    */
    function removeApproval(address tunnelProxy) public onlyOwner {
        require(_approvedProxyTunnels[tunnelProxy] == true, "Tunnel proxy address has no exisiting approval");
        delete _approvedProxyTunnels[tunnelProxy];
    }

    function appendFlowRoyaltyDue(uint256 _tokenId, uint256 value) public {
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
        FxERC721(fxTokenProxy)._appendFlowRoyaltyDue(_tokenId, value);
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

    /**
    * @dev public function that can be called to mint a token using {FxERC721.mint()}
    * Only succeeds if the sender is an approved address to use this contract's functions and token proxy address is set
    * This contract is set as the fxManager for {FxERC721} contract so it is the only one that can call its functionalities
    * that require the caller to be the fxManager
    *
    * @param to address representing the user to mint the token for
    * @param tokenId uint256 represting the Id of the token to mint
    * @param data bytes representing the extra information needed for the mint to happen
    */
    function mintToken(address to, uint256 tokenId, bytes memory data) public {
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

    /**
    * @dev public function that can be called to burn a token using {FxERC721.burn()}
    * Only succeeds if the sender is an approved address to use this contract's functions and token proxy address is set
    * This contract is set as the fxManager for {FxERC721} contract so it is the only one that can call its functionalities
    * that require the caller to be the fxManager
    *
    * @param caller address representing the user who called this function to check if they are the owner of the token
    * @param tokenId uint256 represting the Id of the token to burn
    */
    function burnToken(address caller, uint256 tokenId) public {
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
    * @dev public function that can be called to retrieve a token details needed for minting
    *
    * @param tokenId uint256 representing the Id of the token to retrieve details for
    * @return bytes representing the details of the nft needed for a mint
    */
    function getNftDataDetails(uint256 tokenId) public view returns (bytes memory){
        FxERC721 TokenProxyContract = FxERC721(fxTokenProxy);

        (address royaltyAddress, uint96 royaltyFraction) = TokenProxyContract.getRoyaltyDetails(tokenId);
        return (
            abi.encode(
                TokenProxyContract.getTokenURI(tokenId),
                TokenProxyContract.getPolygonArtistAddress(tokenId),
                TokenProxyContract.getArtistId(tokenId),
                royaltyAddress,
                royaltyFraction
            )
        );
    }
    
    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[48] private __gap;
}