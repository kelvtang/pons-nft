// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libraries/stringUtils.sol";
import "../../contracts/FxERC721.sol";

contract PonsNftMarket {
    event nftPurchased(address from, address to, string nftId, uint256 amount);
    event nftListed(address by, string nftId, uint256 amount);
    event nftUnlisted(string nftId);
    error nftOfferTooLow();
    error nftNotFound();

    struct listingCertificate {
        address payable listerAddress;
        string nftId;
        uint256 listingCount;
    }

    // IterableMapping.itmap private listingCertificateCollection; // nftId ==> listingCertificate

    mapping(string => listingCertificate) private listingCertificateCollection;

    mapping(string => uint256) private nftSalesPrice; // denominator 10,000 // nftId ==> listingPrice
    string[] private nftForSale; // list of for sale. --> keys for nftSalesPrice

    function listForSale(string calldata nftId, uint256 salesPricex100)
        public
        returns (listingCertificate memory)
    {
        /*
        TODO: be able to hold listed nfts.
        TODO: nftId should be inferred from nft token
        */

        listingCertificate memory cert;

        cert.listerAddress = payable(msg.sender);
        cert.nftId = nftId;
        cert.listingCount = (
            listingCertificateCollection[nftId].listingCount == 0
                ? 1
                : listingCertificateCollection[nftId].listingCount + 1
        ); // reference at: https://stackoverflow.com/a/59463026

        listingCertificateCollection[nftId] = cert;

        nftSalesPrice[nftId] = salesPricex100;
        nftForSale.push(nftId);

        emit nftListed(msg.sender, nftId, salesPricex100);
        return cert;
    }

    function unlist(string calldata nftId) public {
        uint256 end = nftForSale.length;
        for (uint256 i = 0; i < nftForSale.length; i++) {
            if (
                StringUtils.equal(nftForSale[i], nftId) /* keccak256(nftForSale[i]) == keccak256(nftId) */
            ) {
                nftForSale[i] = "";
                nftSalesPrice[nftId] = 0;
                delete end;
                delete listingCertificateCollection[nftId];

                emit nftUnlisted(nftId);
            }
        }
        revert nftNotFound();
    }

    function purchase(string calldata nftId) external payable returns (bool) {
        if (listingCertificateCollection[nftId].listingCount >= 1) {
            if (msg.value < nftSalesPrice[nftId]) {
                listingCertificateCollection[nftId].listerAddress.transfer(
                    msg.value
                );
                /*
                TODO: send held nft to msg.sender;
                */
                emit nftPurchased(
                    listingCertificateCollection[nftId].listerAddress,
                    msg.sender,
                    nftId,
                    msg.value
                );
                unlist(nftId);
            } else {
                revert nftOfferTooLow();
            }
        }
        revert nftNotFound();
    }

    function getForSaleIds() public view returns (string[] memory) {
        return nftForSale;
    }

    function getPrice(string calldata nftId) public view returns (uint256) {
        return nftSalesPrice[nftId];
    }
}
