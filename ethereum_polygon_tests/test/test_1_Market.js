const Market = artifacts.require("PonsNftMarket");
const Token = artifacts.require("FxERC721");
const ethers = require("ethers");


contract("PonsNftMarket", function(accounts){
    const abiCoder = ethers.utils.defaultAbiCoder;
    const ponsAccountAddress = ethers.utils.getAddress(accounts[0]);

    const userAddress_1 = ethers.utils.getAddress(accounts[1]);
    const userAddress_2 = ethers.utils.getAddress(accounts[2]);

    let market;
    let token;


    before(async function(){
        token = await Token.new({from: ponsAccountAddress});
        market = await Market.new(token.address, {from: ponsAccountAddress});
        
        // await token.addFxManager(market.address, {from: ponsAccountAddress});
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

    describe("Mint NFT", function(){
        const tokenId = 89789878; // Dummy ID

        before(async function(){
            let data = abiCoder.encode(["string", "address", "string", "uint96"], ["https://ipadd", ponsAccountAddress, "alfram45", 89]);
            
            // Owner mints nft as gift for a user.
            await market.mintGiftNft(tokenId, userAddress_1, data, {from: ponsAccountAddress});
        });
        it("Test that NFT owner and existence", async function(){
            expect(await market.tokenOwner(tokenId, {from: userAddress_2})).to.equal(userAddress_1);
        });
        describe("List to marketplace", function(){
            before(async function(){
                // List for sale first.
                await market.listForSale(tokenId, 0, {from: userAddress_1});
                // Transfer nft to market place.
                await token.safeTransferFrom(userAddress_1, market.address, tokenId, {from: userAddress_1});
            })
            it("Test Listing lister", async function(){
                // Lister address should be original owner
                expect(await market.getLister(tokenId, {from: userAddress_2})).to.equal(userAddress_1);
            });
            it("Test Listing owner", async function(){
                // NFT should be held by contract
                expect(await market.tokenOwner(tokenId, {from: userAddress_2})).to.equal(market.address);
            });
            it("Testing withdrawal and unlisting", async function(){
                this.timeout(5000);
                await market.withdrawListing(tokenId, {from: userAddress_1});
                // nft returned to original owner
                expect(await market.tokenOwner(tokenId, {from: userAddress_2})).to.equal(userAddress_1);
                // unlisted
                expect(await market.islisted(tokenId, {from: userAddress_2})).to.be.false;
            });
        });
    });

    describe("Purchase NFT", function(){
        let tokenId = 8978988745878; // Dummy ID
        before(async function(){
            let data = abiCoder.encode(["string", "address", "string", "uint96"], ["https://ipadd", ponsAccountAddress, "alfram45", 89]);
            // Mint new NFT and list for 5 ETH.
            await market.mintNewNft(tokenId, 5, data, {from:ponsAccountAddress});
        })
        it("Test for Purchase", async function(){
            this.timeout(5000);
            // User 1 purchases it.
            await market.purchase(tokenId, {from: userAddress_1, value: ethers.utils.parseEther("5")});
            expect(await market.tokenOwner(tokenId)).to.equal(userAddress_1);
            expect(await market.islisted(tokenId)).to.be.false;
        });
        after(function(){
            tokenId = 8978666655878; // Dummy ID
            describe("Test Listing and Purchase", async function(){
                before(async function(){
                    this.timeout(50000);
                    let data = abiCoder.encode(["string", "address", "string", "uint96"], ["https://ipadd", ponsAccountAddress, "alfram45", 89]);
                    // Owner mints nft as gift for a user.
                    await market.mintGiftNft(tokenId, userAddress_2, data, {from: ponsAccountAddress});
                });
                it("Test for listing and Purchase", async function(){
                    this.timeout(50000);
                    expect(await market.tokenOwner(tokenId, {from: userAddress_2})).to.equal(userAddress_2);
                
                    await market.listForSale(tokenId, 2, {from: userAddress_2});
                    await token.safeTransferFrom(userAddress_2, market.address, tokenId, {from: userAddress_2});
                    expect(await market.islisted(tokenId, {from:userAddress_1})).to.be.true;
                    
                    await market.purchase(tokenId, {from: userAddress_1, value: ethers.utils.parseEther(
                        /* Buys at asking price */
                        (await market.getPrice(tokenId, {from:userAddress_1})).toString()
                    )})
                    expect(await market.tokenOwner(tokenId, {from:userAddress_2})).to.equal(userAddress_1);
                    expect(await market.islisted(tokenId, {from:userAddress_2})).to.be.false;
                })
            })
        });
    });

});

