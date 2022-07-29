// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IFxERC721} from "./IFxERC721.sol";
import "./ERC721Royalty.sol";
import "./ERC721URIStorage.sol";
import "./ERC721Enumerable.sol";

/**
 * @title FxERC20 represents fx erc20
 */
contract FxERC721 is
    IFxERC721,
    ERC721,
    ERC721Enumerable,
    ERC721URIStorage,
    ERC721Royalty
{
    address internal _fxManager;
    address internal _connectedToken;

    // // TODO: Needs to be implemented correctly based on what we get from flow
    // struct EventInformation {
    //     bool approved;
    // }

    // mapping(uint256 => EventInformation) private _EventInfo;

    // // TODO: Needs to be implemented correctly based on what we get from flow
    // function setApproval(bool approval, uint256 tokenId) public {
    //     require(msg.sender == _fxManager, "Invalid sender");
    //     _EventInfo[tokenId].approved = approval;
    // }

    function initialize(
        address fxManager_,
        address connectedToken_,
        string memory name_,
        string memory symbol_
    ) public override {
        require(
            _fxManager == address(0x0) && _connectedToken == address(0x0),
            "Token is already initialized"
        );
        _fxManager = fxManager_;
        _connectedToken = connectedToken_;

        // setup meta data
        setupMetaData(name_, symbol_);
    }

    function _baseURI()
        internal
        view
        virtual
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return "ipfs://";
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // fxManager returns fx manager
    function fxManager() public view override returns (address) {
        return _fxManager;
    }

    // connectedToken returns root token
    function connectedToken() public view override returns (address) {
        return _connectedToken;
    }

    // setup name, symbol
    function setupMetaData(string memory _name, string memory _symbol) public {
        require(msg.sender == _fxManager, "Invalid sender");
        _setupMetaData(_name, _symbol);
    }

    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165, ERC721, ERC721Enumerable, ERC721Royalty)
        returns (bool)
    {
        return
            ERC721Royalty.supportsInterface(interfaceId) ||
            ERC721Enumerable.supportsInterface(interfaceId) ||
            ERC721.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return ERC721URIStorage.tokenURI(tokenId);
    }

    function mint(
        address user,
        uint256 tokenId,
        bytes memory _data
    ) public override {
        require(msg.sender == _fxManager, "Invalid sender");
        // // TODO: Needs to be implemented correctly based on what we get from flow
        // require(
        //     _EventInfo[tokenId].approved == true,
        //     "Token not approved for minting on polygon Blockchain"
        // );

        // TODO: Fix this based on the actual struct
        (
            string memory tokenUri,
            address royaltyReceiver,
            uint96 royaltyNumerator
        ) = abi.decode(_data, (string, address, uint96));
        _safeMint(user, tokenId);
        _setTokenURI(tokenId, tokenUri);
        _setTokenRoyalty(tokenId, royaltyReceiver, royaltyNumerator);
        // delete _EventInfo[tokenId];
    }

    function _burn(uint256 tokenId)
        internal
        virtual
        override(ERC721, ERC721URIStorage, ERC721Royalty)
    {
        ERC721._burn(tokenId);
        ERC721Royalty._burn(tokenId);
        ERC721URIStorage._burn(tokenId);
    }

    function burn(uint256 tokenId) public override {
        require(msg.sender == _fxManager, "Invalid sender");

        require(
            exists(tokenId) == true,
            "Token does not exist on Polygon chain"
        );
        // // TODO: Needs to be implemented correctly based on what we get from flow
        // require(
        //     _EventInfo[tokenId].approved == true,
        //     "Token not approved for burning on polygon Blockchain"
        // );

        _burn(tokenId);
        // delete _EventInfo[tokenId];
    }
}
