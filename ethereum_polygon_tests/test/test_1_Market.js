const Market = artifacts.require("PonsNftMarket");
const Token = artifacts.require("FxERC721");
const ethers = require("ethers");


contract("PonsNftMarket", (accounts) => {
    const abiCoder = ethers.utils.defaultAbiCoder;
    const ponsAccountAddress = ethers.utils.getAddress(accounts[0]);

    const userAddress_1 = ethers.utils.getAddress(accounts[1]);
    const userAddress_2 = ethers.utils.getAddress(accounts[2]);

    const tokenId = 89789878; // Dummy ID
    let market;


    before(async function(){
        let token = await Token.new({from: ponsAccountAddress});
        market = await Market.new(token.address, {from: ponsAccountAddress});
    });

    describe("Test Contract Owner", function(){
        describe("Switching Owners", function(){
            it("Test that current owner is still original", async function(){
                expect(
                    await market.owner({from: ponsAccountAddress})
                ).to.not.equal(userAddress_1);
            });

            describe("Switch Owners and test again", function(){
                before(async function(){
                    await market.transferOwnership(userAddress_1, {from: ponsAccountAddress});
                });
                it("Test if owners have changed", async function(){
                    expect(
                        await market.owner({from: ponsAccountAddress})
                    ).to.equal(userAddress_1);
                });
            });
        });

        after("Reset Owner Back to original account", async function(){
            await market.transferOwnership(ponsAccountAddress, {from: userAddress_1});
        });
    });

    describe("NFT Listing", function(){
        let tokenPrice = 56;    // Dummy price
        let nftPrice;
        let nftIds = [];
        before(async function(){
            data = abiCoder.encode(["string", "address", "string", "uint96"], ["https://ipadd", ponsAccountAddress, "alfram45", 89]);
            await market.mintNewNft(tokenId, tokenPrice, data, {from: ponsAccountAddress}); // newly minted NFT's are always listed.
        });
        describe("Test Listing", async function(){
            before(async function(){
                nftPrice = await market.getPrice(tokenId, {from: ponsAccountAddress});
                (await market.getForSaleIds({from: ponsAccountAddress})).map(item => {
                    nftIds.push(item.toNumber()); // May throw error uint256 might be too large for js.
                });
            });
            it("Listing compared to value set", async function(){
                expect(nftPrice.toNumber()).to.equal(tokenPrice);
            })
            it("Test if nft ID is listed on sale", async function(){
                await expect(nftIds).to.be.an('array').that.includes(tokenId);
            });
        });
        describe("Test unlisting", async function(){
            before(async function(){
                nftIds = [];
                await market.unlist(tokenId, {from: ponsAccountAddress});
                (await market.getForSaleIds({from: ponsAccountAddress})).map(item => {
                    nftIds.push(item.toNumber()); // May throw error uint256 might be too large for js.
                });
            });
            it("Check that id is not among nft's listed for sale", async function(){
                expect(nftIds.includes(tokenId)).to.equal(false);
            });
            after(function(){
                describe("Relisting after unlist", function(){
                    before(async function(){await market.listForSale(tokenId, nftPrice, {from:ponsAccountAddress});})
                    it("Test if nft relisted", async function(){
                        expect(await market.islisted(tokenId, {from: ponsAccountAddress})).to.be.true;
                    })
                });
            })
        });
    });
    // describe("Purchase of nft", function(){
    //     before(async function(){await market.purchase(tokenId, {from: userAddress_1});});
    //     it("Test if nft is owned by customer", async function(){
    //         expect(await market.tokenOwner(tokenId, {from:userAddress_2})).to.equal(userAddress_1);})
    //     it("Test if nft has been delisted after purchase", async function(){
    //         expect(await market.islisted(tokenId, {from:ponsAccountAddress})).to.be.false;})
    // })


});

