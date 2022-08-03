// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/ERC721Royalty.sol)

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC2981.sol";
import "./ERC165.sol";

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
abstract contract ERC721Royalty is ERC2981, ERC721  {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC2981) returns (bool) {
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
    mapping(uint256 => RoyaltyInfo_flow) private _tokenRoyaltyInfo_flow;

    function flowRoyaltyExist(uint256 _tokenId) public view returns (bool){
        return (_tokenRoyaltyInfo_flow[_tokenId].royaltyFraction != uint96(0));
    }

    function royaltyInfo_flow(uint256 _tokenId, uint256 _salePrice) public view returns (string memory, uint256) {
        RoyaltyInfo_flow memory royalty = _tokenRoyaltyInfo_flow[_tokenId];

        if (royalty.royaltyFraction == 0) {
            return (royalty.flowArtistId, uint256(0));
        }

        uint256 royaltyAmount = (_salePrice * royalty.royaltyFraction) / super._feeDenominator(); // Denominator is 10,000

        return (royalty.flowArtistId, royaltyAmount);
    }

    function _setTokenRoyalty_flow(
        uint256 tokenId,
        string memory artistId,
        uint96 feeNumerator
    ) internal {
        require(feeNumerator <= super._feeDenominator(), "ERC2981: royalty fee will exceed salePrice");

        _tokenRoyaltyInfo_flow[tokenId] = RoyaltyInfo_flow(artistId, feeNumerator);
    }

}