const Market = artifacts.require("PonsNftMarket");
const ethers = require("ethers");

// Create address type using ethers. 
    // This address must be in ganache environment.
const ponsAccountAddress = ethers.utils.getAddress("0x5c3266FDb6BbC76e428ADA42C06d6615170C5BB2");


contract("PonsNftMarket", (accounts) => {
    let market;

    before(async () => {
        market = await Market.new({from: accounts[0]});
    });

    describe("Test setting childProxyAddress", async ()=>{
        before("Set Address", async ()=>{
            await market.setChildProxyAddress(ponsAccountAddress, {from:accounts[0]});
        });
        describe("Call childProxyAddress from contract", async ()=>{
            let childProxyAddress;
            before(async ()=>{
                childProxyAddress = await market.getChildProxyAdress({from: accounts[0]});
            });
            it("Test against set address", async ()=>{
                expect(childProxyAddress).to.be.equal(ponsAccountAddress);
            });
        })
    })

    describe("Test Owner Address", async ()=>{
        let owner;
        before(async ()=>{
            owner = await market.owner({from: accounts[0]});
        });
        it("Switching Owners", ()=>{
            expect(owner).to.not.equal(ponsAccountAddress);
            describe("Switch Owners and test again",async ()=>{
                before(async ()=>{
                    await market.transferOwnership(ponsAccountAddress, {from: accounts[0]});
                    owner = await market.owner({from: accounts[0]});
                });
                it("Test if owners have changed", ()=>{
                    expect(owner).to.equal(ponsAccountAddress);
                })
            });
        })
    });

    describe("Testing List for sale", async ()=>{
        let tokenID = 89789878; // Dummy ID
        let tokenPrice = 56;    // Dummy price
        let nftPrice;
        let nftIds = [];
        before(async ()=>{
            await market.listForSale(tokenID, tokenPrice, {from: accounts[0]});
        });
        describe("Test if listed", async ()=>{
            before(async ()=>{
                nftPrice = await market.getPrice(tokenID, {from:accounts[0]});
                (await market.getForSaleIds({from:accounts[0]})).map(item => {
                    nftIds.push(item.toNumber()); // May throw error uint256 might be too large for js.
                });
            });
            it("Listing compared to value set", async ()=>{
                await expect(nftPrice.toNumber()).to.equal(tokenPrice);
            })
            it("Test if nft ID is listed on sale", async ()=>{
                await expect(nftIds).to.be.an('array').that.includes(tokenID);
            });
        });
        describe("Test unlisting", async ()=>{
            before(async ()=>{
                nftIds = [];
                await market.unlist(tokenID, {from:accounts[0]});
                (await market.getForSaleIds({from:accounts[0]})).map(item => {
                    nftIds.push(item.toNumber()); // May throw error uint256 might be too large for js.
                });
            });
            it("Check that id is not among nft's listed for sale", async ()=>{
                await expect(nftIds.includes(tokenID)).to.equal(false);
            });
        });
    });

    /* 
        Write a test for purchase(uint256 tokenId)
    */




    // describe("", async ()=>{});


});