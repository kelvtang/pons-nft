// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IFxERC721.sol";
import "./ERC721Royalty.sol";
import "./ERC721URIStorage.sol";
import "./ERC721Enumerable.sol";
import "./Initializable.sol";
import "./Pausable.sol";
import "./OwnableUpgradeable.sol";


/**
 * @title FxERC20 represents fx erc20
 */
contract FxERC721 is
    Initializable,
    IFxERC721Upgradeable,
    ERC721Upgradeable,
    ERC721EnumerableUpgradeable,
    ERC721URIStorageUpgradeable,
    ERC721RoyaltyUpgradeable,
    PausableUpgradeable,
    OwnableUpgradeable
{
    // address internal _fxManager; @red

    mapping(address => bool) internal _fxManager;
    address internal _connectedToken;

    constructor() {
        _disableInitializers();
    }

    function addFxManager(address fxManager_) public onlyOwner{
        _fxManager[fxManager_] = true;
    }

    function initialize(
        address fxManager_,
        address connectedToken_,
        string memory name_,
        string memory symbol_
    ) initializer public override {
        addFxManager(fxManager_);
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
    }

    function updateConnectedToken(
        address proxyAddress
    ) public onlyOwner {
        require(_connectedToken == address(0x0), "FxERC721: Connected token already set");
        _connectedToken = proxyAddress;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal whenNotPaused virtual override(ERC721Upgradeable, ERC721EnumerableUpgradeable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // // fxManager returns fx manager
    // function fxManager() public view override returns (address) {
    //     return _fxManager;
    // }

    // connectedToken returns root token
    function connectedToken() public view override returns (address) {
        return _connectedToken;
    }

    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
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

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        return ERC721URIStorageUpgradeable.tokenURI(tokenId);
    }

    function mint(
        address user,
        uint256 tokenId,
        bytes memory _data
    ) public override {
        require(_fxManager[msg.sender], "Invalid sender");

        (
            string memory tokenUri,
            address royaltyReceiver,
            string memory flowArtistId, // Extra parameter added to abi. Holds artist address in flow.
            uint96 royaltyNumerator
        ) = abi.decode(_data, (string, address, string, uint96));
        _safeMint(user, tokenId);
        _setTokenURI(tokenId, tokenUri);
        _setTokenRoyalty(tokenId, royaltyReceiver, royaltyNumerator);
    }

    function _burn(uint256 tokenId)
        internal
        virtual
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable, ERC721RoyaltyUpgradeable)
    {
        ERC721Upgradeable._burn(tokenId);
        ERC721RoyaltyUpgradeable._burn(tokenId);
        ERC721URIStorageUpgradeable._burn(tokenId);
    }

    function burn(uint256 tokenId) public override {
        require(_fxManager[msg.sender], "Invalid sender");

        require(
            exists(tokenId) == true,
            "Token does not exist on Polygon chain"
        );

        _burn(tokenId);
    }

}
