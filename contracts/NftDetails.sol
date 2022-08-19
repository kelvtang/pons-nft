// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./FxERC721.sol";

contract NftDetails is Ownable{

    address private tokenContractProxy;

    function setTokenAddress(address _tokenContractProxy) public onlyOwner{
        tokenContractProxy = _tokenContractProxy;
    }

    /**
        @notice returns the metadata details associated with nft minted by using @param tokenId of Nft.
     */
    function getNftDataDetails(uint256 tokenId) public view returns (bytes memory){
        (address royaltyAddress, uint96 royaltyFraction) = FxERC721(tokenContractProxy).getRoyaltyDetails(tokenId);
        return (
            abi.encode(
                FxERC721(tokenContractProxy).getTokenURI(tokenId),
                FxERC721(tokenContractProxy).getPolygonArtistAddress(tokenId),
                FxERC721(tokenContractProxy).getArtistId(tokenId),
                royaltyAddress,
                royaltyFraction
            )
        );
    }

}