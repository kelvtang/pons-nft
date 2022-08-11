// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./FxERC721.sol";
import "./Ownable.sol";
import "./IERC721Receiver.sol";

contract PonsNftMarket is Ownable, IERC721Receiver{

    event newNftMinted(uint256 tokenId, address to);
    event nftPurchased(address from,address to,uint256 tokenId,uint256 amount);
    event nftListed(address by, uint256 tokenId, uint256 amount);
    event nftUnlisted(uint256 tokenId);
    
    error nftNotFound();
    error nftOfferTooLow();

    struct listingCertificate {
        address payable listerAddress;
        uint256 tokenId;
        uint256 listingCount;
    }

    mapping(uint256 => listingCertificate) private listingCertificateCollection;
    mapping(uint256 => uint256) private nftSalesPrice; // denominator 10,000 // tokenId ==> listingPrice
    uint256[] private nftForSale; // list of for sale. --> keys for nftSalesPrice
    
    mapping(string => uint256) private RoyaltyHolder_flow; // Holds the amount of royalty due to atrist.
    // mapping(address => uint256) private RoyaltyHolder; // Holds the amount of royalty due to atrist.

    address private tokenContractAddress;

    constructor (address _tokenContractAddress){
        tokenContractAddress = _tokenContractAddress;
    }

    function tokenExists(uint256 tokenId) public view returns (bool){
        return FxERC721(tokenContractAddress).exists(tokenId);}
    function tokenOwner(uint256 tokenId) public view returns (address){
        return FxERC721(tokenContractAddress).ownerOf(tokenId);}
    function mintNewNft(uint256 tokenId, uint256 salesPricex100, bytes memory _data) public onlyOwner {
        require(!tokenExists(tokenId), "NFT already exists");
        
        FxERC721(tokenContractAddress).mint(address(this), tokenId, _data);

        listForSale(tokenId, salesPricex100);

        emit newNftMinted(tokenId, address(this));
    }



    // Gives artist their due royalty (in matic) to their polygon address.
    function withdrawRoyalty_flow(string calldata flowArtistId, address polygonAddress) public onlyOwner {
        require(RoyaltyHolder_flow[flowArtistId]>0, "No royalty due for this artist");
        require(polygonAddress != address(0x0), "Cannot send token to an empty address");
        
        // create payable address.
        address payable polygonAddressPaybale = payable(polygonAddress);

        // send value to address.
        //  // Denominator of 10,000 since floating point values is still an experimental feature in solidity
        polygonAddressPaybale.transfer((RoyaltyHolder_flow[flowArtistId]/10_000)); 
    }

    function setRoyalty_flow(uint256 tokenId, uint256 salePrice) internal {
        (string memory _artistID, uint256 _royaltyAmount) = FxERC721(tokenContractAddress).royaltyInfo_flow(tokenId, salePrice);
        RoyaltyHolder_flow[_artistID] += _royaltyAmount;
    }
    
    function onERC721Received(
        address, /* operator */
        address, /* from */
        uint256, /* tokenId */
        bytes calldata /* data */
    ) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function listForSale(uint256 tokenId, uint256 salesPricex100) public returns (listingCertificate memory){
        require(tokenExists(tokenId), "NFT by this Token ID does not exist");
        require(tokenOwner(tokenId) == msg.sender || (tokenOwner(tokenId) == address(this) && msg.sender == owner()), "NFT can only be listed by account that owns it.");

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

        // TODO: some approval system to allow for contract to move token.
        // TODO: crate artist
        if (tokenOwner(tokenId) != address(this)){
            FxERC721(tokenContractAddress).safeTransferFrom(msg.sender, address(this), tokenId);
        }

        emit nftListed(msg.sender, tokenId, salesPricex100);
        return cert;
    }

    function unlist(uint256 tokenId) public onlyOwner {
        require(nftSalesPrice[tokenId] > 0, "Only listed NFTs can be delisted.");
        uint256 end = nftForSale.length;
        for (uint256 i = 0; i < nftForSale.length; i++) {
            if (nftForSale[i] == tokenId) {
                nftForSale[i] = 0;
                nftSalesPrice[tokenId] = 0;
                delete end;
                delete listingCertificateCollection[tokenId];
                emit nftUnlisted(tokenId);
                break;
            }
        }
    }



    function withdrawListing(uint256 tokenId) public {
        require (tokenExists(tokenId), "NFT by this token ID does not exist");
        require (tokenOwner(tokenId) == address(this), "Only NFT held by market contract can be withdrawn");
        require (listingCertificateCollection[tokenId].listerAddress == msg.sender, "Only original lister account can request widthrawal");
        
        FxERC721(tokenContractAddress).safeTransferFrom(address(this), msg.sender, tokenId);
        unlist(tokenId);
    }
    
    function purchase(uint256 tokenId) external payable returns (bool) {
        if (listingCertificateCollection[tokenId].listingCount >= 1) {
            if ( msg.value < nftSalesPrice[tokenId] ) {

                (string memory _artistID, uint256 _royaltyAmount) = FxERC721(tokenContractAddress).royaltyInfo_flow(tokenId, nftSalesPrice[tokenId]);
                delete _artistID;

                
                // If flow royalty exist, then royalty will be held.
                if (FxERC721(tokenContractAddress).flowRoyaltyExist(tokenId)){
                    setRoyalty_flow(tokenId, uint256(msg.value)); // Store royalty into contract
                }
                
                // Deduct royalty value before transfering 
                listingCertificateCollection[tokenId].listerAddress.transfer((msg.value - _royaltyAmount)); 
               

                // Initiate transfer of nft from listed seller to new owner.
                FxERC721(tokenContractAddress).safeTransferFrom(
                    address(this),
                    msg.sender,
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

    function islisted(uint256 tokenId) public view returns (bool){
        return (nftSalesPrice[tokenId]>0);
    }

    function setTokenContractAddress(address _tokenContractAddress) public onlyOwner{
        require(_tokenContractAddress != address(0x0), "Cannot be set to null value");
        tokenContractAddress = _tokenContractAddress;
    }

    function getTokenContractAddress() public view returns (address) {
        return tokenContractAddress;
    }
}
