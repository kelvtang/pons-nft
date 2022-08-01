// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "../libraries/stringUtils.sol";
import "../../contracts/FxERC721.sol";

// import "../../contracts/ERC721.sol";

contract PonsNftMarket is FxERC721 {
    event nftPurchased(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount
    );
    event nftListed(address by, uint256 tokenId, uint256 amount);
    event nftUnlisted(uint256 tokenId);
    error nftOfferTooLow();
    error nftNotFound();

    struct listingCertificate {
        address payable listerAddress;
        uint256 tokenId;
        uint256 listingCount;
    }

    // IterableMapping.itmap private listingCertificateCollection; // tokenId ==> listingCertificate

    mapping(uint256 => listingCertificate) private listingCertificateCollection;

    mapping(uint256 => uint256) private nftSalesPrice; // denominator 10,000 // tokenId ==> listingPrice
    uint256[] private nftForSale; // list of for sale. --> keys for nftSalesPrice

    function listForSale(uint256 tokenId, uint256 salesPricex100)
        public
        returns (listingCertificate memory)
    {
        listingCertificate memory cert;

        cert.listerAddress = payable(msg.sender);
        cert.tokenId = tokenId;
        cert.listingCount = (
            listingCertificateCollection[tokenId].listingCount == 0
                ? 1
                : listingCertificateCollection[tokenId].listingCount + 1
        ); // reference at: https://stackoverflow.com/a/59463026

        listingCertificateCollection[tokenId] = cert;

        nftSalesPrice[tokenId] = salesPricex100;
        nftForSale.push(tokenId);

        emit nftListed(msg.sender, tokenId, salesPricex100);
        return cert;
    }

    function unlist(uint256 tokenId) public {
        uint256 end = nftForSale.length;
        for (uint256 i = 0; i < nftForSale.length; i++) {
            if (nftForSale[i] == tokenId) {
                nftForSale[i] = 0;
                nftSalesPrice[tokenId] = 0;
                delete end;
                delete listingCertificateCollection[tokenId];

                emit nftUnlisted(tokenId);
            }
        }
        revert nftNotFound();
    }

    function purchase(uint256 tokenId) external payable returns (bool) {
        if (listingCertificateCollection[tokenId].listingCount >= 1) {
            if (msg.value < nftSalesPrice[tokenId]) {
                listingCertificateCollection[tokenId].listerAddress.transfer(
                    msg.value
                );

                // Initiate transfer of nft from listed seller to new owner.
                safeTransferFrom(
                    _msgSender(),
                    listingCertificateCollection[tokenId].listerAddress,
                    tokenId
                );

                emit nftPurchased(
                    listingCertificateCollection[tokenId].listerAddress,
                    msg.sender,
                    tokenId,
                    msg.value
                );
                unlist(tokenId);
            } else {
                revert nftOfferTooLow();
            }
        }
        revert nftNotFound();
    }

    function getForSaleIds() public view returns (uint256[] memory) {
        return nftForSale;
    }

    function getPrice(uint256 tokenId) public view returns (uint256) {
        return nftSalesPrice[tokenId];
    }
}
