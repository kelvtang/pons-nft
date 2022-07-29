// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PonsNftMarket {
    struct listingCertificate {
        address payable listerAddress;
        string nftId;
        uint256 listingCount;
        uint256 nftSalesPrice; // denominator 10,000
    }

    mapping(string => listingCertificate) public listingCertificateList; // nftId ==> listingCertificate

    function listForSale(
        string memory nftId,
        uint256 salesPricex100,
        address listerAddress
    ) public payable returns (listingCertificate memory) {
        listingCertificate memory cert;

        cert.listerAddress = payable(listerAddress);
        cert.nftId = nftId;
        cert.listingCount = 0;
        cert.nftSalesPrice = salesPricex100;

        listingCertificateList[nftId] = cert;

        return listingCertificateList[nftId];
    }

    function unlist() public {}

    function purchase() public {}

    // function mint() public {}
}
