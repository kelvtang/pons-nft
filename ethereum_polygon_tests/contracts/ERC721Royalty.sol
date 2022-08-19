// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/ERC721Royalty.sol)

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC2981.sol";
import "./Initializable.sol";

/**
* @dev Extension of ERC721 with the ERC2981 NFT Royalty Standard, a standardized way to retrieve royalty payment
* information.
*
* Royalty information can be specified globally for all token ids via {_setDefaultRoyalty}, and/or individually for
* specific token ids via {_setTokenRoyalty}. The latter takes precedence over the first.
*
* IMPORTANT: ERC-2981 only specifies a way to signal royalty information and does not enforce its payment. See
* https://eips.ethereum.org/EIPS/eip-2981#optional-royalty-payments[Rationale] in the EIP. Marketplaces are expected to
* voluntarily pay royalties together with sales, but note that this standard is not yet widely supported.
*
* _Available since v4.5._
*/
abstract contract ERC721RoyaltyUpgradeable is Initializable, ERC2981Upgradeable, ERC721Upgradeable {
    function __ERC721Royalty_init() internal onlyInitializing {
    }

    function __ERC721Royalty_init_unchained() internal onlyInitializing {
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
        override(ERC721Upgradeable, ERC2981Upgradeable) 
        returns (bool) 
    {
        return super.supportsInterface(interfaceId);
    }

    /**
    * @dev See {ERC721-_burn}. This override additionally clears the royalty information for the token.
    */
    function _burn(uint256 tokenId) internal virtual override {
        _resetTokenRoyalty(tokenId);
    }


    struct RoyaltyInfo_flow{
        string flowArtistId;
        uint96 royaltyFraction;
    }

    // maps nftId to royalty information.
    mapping(uint256 => RoyaltyInfo_flow) internal _tokenRoyaltyInfo_flow;
    mapping(string => uint256) internal _flowRoyaltyDue;

    function getFundsDue(string calldata _flowArtistId) public view returns (uint256){
        return _flowRoyaltyDue[_flowArtistId];
    }

    function flowRoyaltyExist(uint256 _tokenId) public view returns (bool){
        return (_tokenRoyaltyInfo_flow[_tokenId].royaltyFraction != uint96(0));
    }

    function _setTokenRoyalty_flow(uint256 tokenId, string memory artistId, uint96 feeNumerator) internal {
        require(feeNumerator <= super._feeDenominator(), "ERC2981: royalty fee will exceed salePrice");

        _tokenRoyaltyInfo_flow[tokenId] = RoyaltyInfo_flow(artistId, feeNumerator);
    }

    /**
    * @dev This empty reserved space is put in place to allow future versions to add new
    * variables without shifting down storage in the inheritance chain.
    * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
    */
    uint256[50] private __gap;
}