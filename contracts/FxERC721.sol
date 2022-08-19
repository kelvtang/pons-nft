// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IFxERC721.sol";
import "./ERC721Royalty.sol";
import "./ERC721URIStorage.sol";
import "./ERC721Enumerable.sol";
import "./Initializable.sol";
import "./Pausable.sol";
import "./OwnableUpgradeable.sol";
import "./ERC721ArtistID.sol";


/**
 * @title FxERC721 represents fx erc721
 */
contract FxERC721 is
    Initializable,
    IFxERC721Upgradeable,
    ERC721Upgradeable,
    ERC721EnumerableUpgradeable,
    ERC721URIStorageUpgradeable,
    ERC721RoyaltyUpgradeable,
    ERC721ArtistID,
    PausableUpgradeable,
    OwnableUpgradeable
{
    address internal _fxManager;
    address internal _connectedToken;

    constructor() {
        _disableInitializers();
    }

    /** 
    * @dev public function that is called when the proxy contract managing this contract is deployed through the {_data} variable
    * This function can only be called once when proxy is deployed
    * Cannot be called again later on, even when the contract is upgraded.
    * See {ERC1967Proxy-constructor}.
    * 
    * @param fxManager_ address representing the Fx manager proxy contract
    * @param connectedToken_ address representing the FxERC721 proxy token contract on the other chain
    * @param name_ string representing the name of the token
    * @param symbol_ string representing the symbol of the token
    */
    function initialize(
        address fxManager_,
        address connectedToken_,
        string memory name_,
        string memory symbol_
    )  
        public 
        override
        initializer 
    {
        _fxManager = fxManager_;
        _connectedToken = connectedToken_;
        __Context_init();
        __Ownable_init();
        __ERC721_init(name_, symbol_);
        __ERC721Enumerable_init();
        __ERC721URIStorage_init();
        __Pausable_init();
        __ERC721Royalty_init();
        __ERC165_init();
        __ERC2981_init();
        __ERC721ArtistID_init();
    }

    /** 
    * @dev public function that can only be called by the deployer of the contract
    * Sets the address of the corresponding FxERC721 proxy contract deployed on the other chain
    * Can only set the address once since the proxy contract will not change
    *
    * @param proxyAddress address representing the FxERC721 proxy contract on the opposite chain
    */
    function updateConnectedToken(address proxyAddress) public onlyOwner {
        require(_connectedToken == address(0x0), "FxERC721: Connected token already set");
        _connectedToken = proxyAddress;
    }

    /**
    * @dev public function that can only be called by the deployer of the contract
    * When called, minting and burning will not work on this contract
    * This is beneficial if a bug is found and the contract has to be upgraded and we do not want users to mint/burn until resolved 
    */
    function pause() public onlyOwner {
        _pause();
    }

    /**
    * @dev public function that can only be called by the deployer of the contract
    * When called, minting and burning is resumed 
    * Should only be called if the contract was previously paused
    */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
    * @dev Hook that is called before any token transfer. This includes minting
    * and burning.
    *
    * Calling conditions:
    *
    * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
    * transferred to `to`.
    * - When `from` is zero, `tokenId` will be minted for `to`.
    * - When `to` is zero, ``from``'s `tokenId` will be burned.
    * - `from` cannot be the zero address.
    * - `to` cannot be the zero address.
    *
    * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
    */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) 
        internal 
        virtual 
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
        whenNotPaused
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
    * @return address of the Fx Manager proxy contract that is allowed to mint/burn through this contract
    */
    function fxManager() public view override returns (address) {
        return _fxManager;
    }

    /**
    * @return address of the FxERC721 proxy contract of the opposite chain
    */
    function connectedToken() public view override returns (address) {
        return _connectedToken;
    }

    /**
    * @dev Returns whether `tokenId` exists.
    *
    * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
    *
    * Tokens start existing when they are minted (`_mint`),
    * and stop existing when they are burned (`_burn`).
    */
    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    /**
    * @dev See {IERC165-supportsInterface}.
    */
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(IERC165Upgradeable, ERC721Upgradeable, ERC721EnumerableUpgradeable, ERC721RoyaltyUpgradeable)
        returns (bool)
    {
        return
            ERC721RoyaltyUpgradeable.supportsInterface(interfaceId) ||
            ERC721EnumerableUpgradeable.supportsInterface(interfaceId) ||
            ERC721Upgradeable.supportsInterface(interfaceId);
    }

    /**
    * @dev See {IERC721Metadata-tokenURI}.
    */
    function tokenURI(
        uint256 tokenId
    )
        public
        view
        virtual
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        return ERC721URIStorageUpgradeable.tokenURI(tokenId);
    }

    /**
    * @dev See {ERC721-_safeMint}.
    * Can only be called by the FxManager contract
    * The override additionally sets artistId, tokenRoyalty, tokenURI, polygonArtistAddress, tokenRoyaltyFlow
    *
    * @param user address representing where the token is going to be transferred to after mintin 
    * @param tokenId uint256 representing the Id of the token to be minted
    * @param _data bytes containig the additional information needed to mint a token
    *
    * Token starts exisiting after this function runs successfully
    */
    function mint(address user, uint256 tokenId, bytes memory _data) public override {
        require(msg.sender == _fxManager, "Invalid sender");

        (
            string memory tokenUri,
            address polygonArtistAddress,
            string memory flowArtistId,
            address royaltyReceiver,
            uint96 royaltyNumerator
        ) = abi.decode(_data, (string, address, string, address, uint96));
        
        setArtistId(tokenId, flowArtistId);

        if (polygonArtistAddress != address(0x0)){
            // If polygon artist address is available then we will set royalty recipient to be same as artist address
            setPolygonArtistAddress(tokenId, polygonArtistAddress);
            _setTokenRoyalty(tokenId, polygonArtistAddress, royaltyNumerator);
        }else{
            // We may set royalty recpient to be anyone (manually set to PonsNftMarket address), since we donot have Polygon Address for Artist.
            _setTokenRoyalty(tokenId, royaltyReceiver, royaltyNumerator);
            _setTokenRoyalty_flow(tokenId, flowArtistId, royaltyNumerator);
        }
        
        _safeMint(user, tokenId);
        _setTokenURI(tokenId, tokenUri);
    }

    /**
    * @notice We can map Flow Artist ID to polygon account addresses.
    * @dev The account must be manually verified by PONs and this function must be triggered 
    * by Owner or other approved address.
    * @dev This will allow for newly registered accounts to be able to get royalties directly 
    * on transaction of older NFT's which were minted before the artist's account registration.
    */
    function setArtistIdToPolygonAddress(address _polygonArtistAddress, string calldata _artistId) public onlyOwner{
        flowPolygonArtistAddress[_artistId] = _polygonArtistAddress;
    }

    /** 
    * @dev See {ERC721-_burn}. This override additionally clears the royalty information for the token.
    * The override also checks to see if a
    * token-specific URI was set for the token, and if so, it deletes the token URI from
    * the storage mapping.
    */
    function _burn(
        uint256 tokenId
    )
        internal
        virtual
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable, ERC721RoyaltyUpgradeable)
    {
        ERC721Upgradeable._burn(tokenId);
        ERC721RoyaltyUpgradeable._burn(tokenId);
        ERC721URIStorageUpgradeable._burn(tokenId);
    }

    function burn(uint256 tokenId) public override {
        require(msg.sender == _fxManager, "Invalid sender");

        require(
            exists(tokenId) == true,
            "Token does not exist on Polygon chain"
        );

        _burn(tokenId);
    }

    /**
    * @dev This empty reserved space is put in place to allow future versions to add new
    * variables without shifting down storage in the inheritance chain.
    * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
    */
    uint256[48] private __gap;
}
