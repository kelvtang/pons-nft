const Market = artifacts.require("PonsNftMarket");
const Token = artifacts.require("FxERC721");
const ethers = require("ethers");


contract("PonsNftMarket", (accounts) => {
    const abiCoder = ethers.utils.defaultAbiCoder;
    const ponsAccountAddress = ethers.utils.getAddress(accounts[0]);

    const userAddress_1 = ethers.utils.getAddress(accounts[1]);
    const userAddress_2 = ethers.utils.getAddress(accounts[2]);

    const tokenId = 8978988745878; // Dummy ID
    let market;


    before(async function(){
        let token = await Token.new({from: ponsAccountAddress});
        market = await Market.new(token.address, {from: ponsAccountAddress});
    });

    describe("Purchase of nft", function(){
        before("Mint token and purchase", async function(){
            let data = abiCoder.encode(["string", "address", "string", "uint96"], ["https://ipadd", ponsAccountAddress, "alfram45", 89]);
            // Mint nft and list it for free.
            await market.mintNewNft(tokenId, 0, data, {from:ponsAccountAddress});

            await market.purchase(tokenId, {from: userAddress_1})
        });
        // it("Test if nft is owned by customer", async function(){
        //     expect(await market.tokenOwner(tokenId, {from:ponsAccountAddress})).to.equal(userAddress_1);})
        it("Test if nft has been delisted after purchase", async function(){
            expect(await market.islisted(tokenId, {from:ponsAccountAddress})).to.be.false;})
    });


});

