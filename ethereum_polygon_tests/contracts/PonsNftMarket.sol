// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./FxERC721.sol";
import "./FxERC721FxManager.sol";
import "./OwnableUpgradeable.sol";
import "./IERC721Receiver.sol";
import "./FlowTunnel.sol";
import "./Initializable.sol";

contract PonsNftMarket is Initializable, OwnableUpgradeable, IERC721ReceiverUpgradeable{

    event newNftMinted(uint256 tokenId, address to);
    event nftPurchased(address from,address to,uint256 tokenId,uint256 amount);
    event nftListed(address by, uint256 tokenId, uint256 amount);
    event nftUnlisted(uint256 tokenId);


    struct listingCertificate {
        address payable listerAddress;
        uint256 tokenId;
        uint256 listingCount;
    }

    mapping(uint256 => listingCertificate) private listingCertificateCollection;
    mapping(uint256 => uint256) private nftSalesPrice; // denominator 10,000 // tokenId ==> listingPrice
    uint256[] private nftForSale; // list of for sale. --> keys for nftSalesPrice
    

    address private tokenContractAddress;
    address private fxManagerContractAddress;
    address private tunnelContractAddress;

    constructor() {
        _disableInitializers();
    }

    /**
    @notice initialize has two parameters
        @param _tokenContractAddress requires the contract addresses of FxERC721
        @param _fxManagerContractAddress requires the contract addresses of FxERC721FxManager
    @dev contract address of PonsNftMarket.sol should be added to FxERC721FxManager by owner.
    */
    function initialize(
        address _tokenContractAddress,
        address _fxManagerContractAddress
    ) initializer public {
        tokenContractAddress = _tokenContractAddress;
        fxManagerContractAddress = _fxManagerContractAddress;
        __Context_init();
        __Ownable_init();
    }

    function tokenExists(uint256 tokenId) public view returns (bool){
        return FxERC721(tokenContractAddress).exists(tokenId);}

    function tokenOwner(uint256 tokenId) public view returns (address){
        require(tokenExists(tokenId), "Market: NFT by this token ID does not exist");
        return FxERC721(tokenContractAddress).ownerOf(tokenId);}
    
    function mintNewNft(uint256 tokenId, uint256 salesPrice, bytes memory _data) public onlyOwner {
        require(!tokenExists(tokenId), "Market: NFT already exists");
        
        FxERC721(tokenContractAddress).mint(address(this), tokenId, _data);

        listForSale(tokenId, salesPrice);

        emit newNftMinted(tokenId, address(this));
    }

    function mintGiftNft(uint256 tokenId, address to, bytes memory _data) public onlyOwner {
        require(!tokenExists(tokenId), "Market: NFT already exists");
        require(to != address(this), "Market: Should not gift NFT to self");
        require(to != address(0x0), "Market: Should not gift NFT to empty address");
        
        FxERC721(tokenContractAddress).mint(to, tokenId, _data);

        emit newNftMinted(tokenId, to);
    }

    /**
    @notice withdrawFunds takes the @param _flowArtistId and transfers the amount of matic due to the artist in royalties, and funds.
    @dev This is only allowed when the artist has registered his flowArtist account with Pons. and the Pons account calls the function setFlowIdToPolygonId in ./contracts/ERC721ArtistID.sol
     */
    function withdrawFunds(string calldata _flowArtistId) public {
        require(FxERC721(tokenContractAddress).getPolygonFromFlow_calldata(_flowArtistId) == msg.sender, "Market: Only Registered Artists may widthdraw their royalty. Please register your Flow Artist ID with Pons");
        require(FxERC721(tokenContractAddress).getFundsDue(_flowArtistId) > 0, "Market: There are no funds due to this Artist ID");
        payable(msg.sender).transfer(FxERC721(tokenContractAddress).getFundsDue(_flowArtistId)/10_000);
        FxERC721FxManager(fxManagerContractAddress).emptyFundsDue(_flowArtistId);
    }

    /**
        @notice returns the metadata details associated with nft minted by using @param tokenId of Nft.
     */
    function getNftDataDetails(uint256 tokenId) public view returns (bytes memory){
        (address royaltyAddress, uint96 royaltyFraction) = FxERC721(tokenContractAddress).getRoyaltyDetails(tokenId);
        return (
            abi.encode(
                FxERC721(tokenContractAddress).getTokenURI(tokenId),
                FxERC721(tokenContractAddress).getPolygonArtistAddress(tokenId),
                FxERC721(tokenContractAddress).getArtistId(tokenId),
                royaltyAddress,
                royaltyFraction
            )
        );
    }
    
    function onERC721Received(
        address, /* operator */
        address, /* from */
        uint256, /* tokenId */
        bytes calldata /* data */
    ) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /**
    @notice listForSale takes two arguments:
        @param tokenId is the ID of the NFT
        @param salesPrice is the Price of the NFT
    @dev since the argument @param salesPrice is a numerator of a function, we must know that denominator is 10_000.
    */
    function listForSale(uint256 tokenId, uint256 salesPrice) public returns (listingCertificate memory){
        require(tokenExists(tokenId), "Market: NFT by this token ID does not exist");
        require(tokenOwner(tokenId) == msg.sender || (tokenOwner(tokenId) == address(this) && msg.sender == owner()), "Market: NFT can only be listed by account that owns it.");

        listingCertificate memory cert;

        cert.listerAddress = payable(msg.sender);
        cert.tokenId = tokenId;
        cert.listingCount = (
            listingCertificateCollection[tokenId].listingCount == 0
                ? 1
                : listingCertificateCollection[tokenId].listingCount + 1
        ); // reference at: https://stackoverflow.com/a/59463026

        listingCertificateCollection[tokenId] = cert;

        nftSalesPrice[tokenId] = salesPrice;
        nftForSale.push(tokenId);
        
        
        emit nftListed(msg.sender, tokenId, salesPrice);
        return cert;
    }

    function unlist(uint256 tokenId) public {
        require(tokenExists(tokenId), "Market: NFT by this token ID does not exist");
        require(tokenOwner(tokenId) != address(this), "Market: withdraw token before unlisting.");
        require(isListed(tokenId), "Market: Only listed NFTs can be delisted.");
        uint256 end = nftForSale.length;
        for (uint256 i = 0; i < nftForSale.length; i++) {
            if (nftForSale[i] == tokenId) {
                delete nftForSale[i];
                delete nftSalesPrice[tokenId];
                delete end;
                delete listingCertificateCollection[tokenId];
                emit nftUnlisted(tokenId);
                break;
            }
        }
    }

    function sendThroughTunnel(uint256 tokenId) public {
        require(tokenExists(tokenId), "Market: NFT by this token ID does not exist");
        require(tunnelContractAddress != address(0x0), "Market: Tunnel contract address not set");
        require(isListed(tokenId), "Market: Cannot send an unlisted nft");

        FlowTunnel(tunnelContractAddress).setupTunnel(tokenId);             // setup tunnel for use
        FxERC721(tokenContractAddress).safeTransferFrom(
                address(this), tunnelContractAddress, tokenId);             // transfer nft to tunnel
        FlowTunnel(tunnelContractAddress).sendThroughTunnel(tokenId, "");   // empty flowAddress goes to PonsNftMarket in Flow blockchain.
                                                                            // --> Handle in relay.
    }

    function withdrawListing(uint256 tokenId) public {
        require(isForSale(tokenId), "Market: NFT is not for sale");
        require(listingCertificateCollection[tokenId].listerAddress == msg.sender, "Market: Only original lister account can request widthrawal");
        
        FxERC721(tokenContractAddress).safeTransferFrom(address(this), msg.sender, tokenId);
        unlist(tokenId);
    }
    
    function purchase(uint256 tokenId) external payable {
        require(tokenExists(tokenId), "Market: NFT by this token ID does not exist");
        require(tokenOwner(tokenId) == address(this), "Market: Cannot sell NFT unless it is given to PonsNftMarket");
        require(listingCertificateCollection[tokenId].listingCount >= 1, "Market: NFT not listed");
        require(msg.value >= (nftSalesPrice[tokenId]/10_000), "Market: Value offered is too low");
        

        // extract the royalty details
        (address royaltyRecipient, uint256 _royaltyAmount) = FxERC721(tokenContractAddress).royaltyInfo(tokenId, nftSalesPrice[tokenId]);
        if (royaltyRecipient != address(this)){
            // if recipient is not this contract itself then payout immediately
            payable(royaltyRecipient).transfer(_royaltyAmount);
        }else{
            address _royaltyRecipient = FxERC721(tokenContractAddress).getPolygonFromFlow_tokenID(tokenId);
            if (_royaltyRecipient != address(0x0)){
                // if the NFT has recipient detail OR recipient has registered himself with PONS
                payable(_royaltyRecipient).transfer(_royaltyAmount);
            }else{
                // test for flow details and store value owed to artist
                FxERC721FxManager(fxManagerContractAddress).appendFlowRoyaltyDue(tokenId, (_royaltyAmount*10_000));
            }
        }
        
        // Deduct royalty value before transfering 
        listingCertificateCollection[tokenId].listerAddress.transfer((msg.value - _royaltyAmount)); 
        
        // Initiate transfer of nft from listed seller to new owner.
        FxERC721(tokenContractAddress).safeTransferFrom(address(this),msg.sender,tokenId);

        emit nftPurchased(listingCertificateCollection[tokenId].listerAddress,msg.sender,tokenId,msg.value);
        unlist(tokenId);
        
    }


    function getForSaleIds() public view returns (uint256[] memory) {
        return nftForSale;
    }

    /**
    @notice returns price numerator of listed NFT.
    @dev the denominator of price is 10_000; (as of writing solidity doesnot support floating point values.)
    */
    function getPrice(uint256 tokenId) public view returns (uint256) {
        require(tokenExists(tokenId), "Market: NFT by this token ID does not exist");
        require(tokenOwner(tokenId) == address(this), "Market: Nft not transfered to Market");
        return nftSalesPrice[tokenId];
    }

    function isForSale(uint256 tokenId) public view returns (bool){
        require(tokenExists(tokenId), "Market: NFT by this token ID does not exist");
        require(tokenOwner(tokenId) == address(this), "Market: Nft not transfered to Market");
        return isListed(tokenId);
    }
    function isListed(uint256 tokenId) public view returns (bool){
        require(tokenExists(tokenId), "Market: NFT by this token ID does not exist");
        return (listingCertificateCollection[tokenId].listerAddress != address(0x0));
    }

    function setTokenContractAddress(address _tokenContractAddress) public onlyOwner{
        require(_tokenContractAddress != address(0x0), "Market: Cannot be set token to empty address");
        tokenContractAddress = _tokenContractAddress;
    }
    
    function setTunnelContractAddress(address _tunnelContractAddress) public onlyOwner{
        require(_tunnelContractAddress != address(0x0), "Market: Cannot set tunnel to empty address");
        tunnelContractAddress = _tunnelContractAddress;
    }

    function getLister(uint256 tokenId) public view returns (address){
        require(tokenExists(tokenId), "Market: NFT by this token ID does not exist");
        return listingCertificateCollection[tokenId].listerAddress;
    }

    /**
    * @dev This empty reserved space is put in place to allow future versions to add new
    * variables without shifting down storage in the inheritance chain.
    * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
    */
    uint256[43] private __gap;
}
