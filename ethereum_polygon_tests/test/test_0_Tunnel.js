const Tunnel = artifacts.require("FlowTunnel");
const Market = artifacts.require("PonsNftMarket");
const Token = artifacts.require("FxERC721");

const ethers = require("ethers");




contract("FlowTunnel", (accounts)=>{
    var tunnel;
    var token;
    var market;
    /**
     * @augments ponsAccountAddress holds the first address of ganache accounts provided in the emulator. Can be used to represent PonsAccount.
     * @augments userAddress holds the second address of ganache accounts provided in the emulator. Can be used to represent a user account.
     * By allowing this we can leave the automation to be handled by truffle.
     * 
     * Ganache environment can be run via command: @command `ganache-cli -p 7545`. 
    */
    const ponsAccountAddress = ethers.utils.getAddress(accounts[0]);
    const userAddress = ethers.utils.getAddress(accounts[1]);

    before("Setup Tunnel", async function(){
        /**
         * @argument token holds the contract instance of deployed FxERC721.sol contract 
         * @todo Need to understand what is fxManager address from FxERC721 and how to initialize it.
         * 
         * @argument market holds the contract instance of deployed PonsNftMarket.sol contract, it is passed the contract address of @argument token in constructor.
         * @argument tunnel holds the contract instance of deployed FlowTunnel.sol contract, it is passed the contract address of @argument token and @argument market in constructor.
        */

        token = await Token.new({from: ponsAccountAddress});
        market = await Market.new(token.address, {from: ponsAccountAddress});
        tunnel = await Tunnel.new(token.address, market.address, {from: ponsAccountAddress});
    });

    describe("Test Contract Owner", async function(){
        it("Test if ponsAddressAccount is owner of tunnel contract", async function(){
            expect(await tunnel.owner({from: ponsAccountAddress})).to.equal(ponsAccountAddress);
        });
    });

    // Since both tests uses the same token, we place this dummy tokenId as a global variable.
    const tokenId = 267876449; // Dummy value

    describe("Testing Tunnel Functionality", function(){
        const abiCoder = ethers.utils.defaultAbiCoder;

        describe("Testing token", async function(){
            it("Token does not exist", async function(){
                await expect(
                    await tunnel.tokenExists(tokenId, {from: ponsAccountAddress})
                ).to.be.false;
            });
        });
        describe("Getting from Tunnel", function(){
            before("Trigger tunnel", async function(){
                data = abiCoder.encode(["string", "address", "string", "uint96"], ["https://ipadd", ponsAccountAddress, "alfram45", 89])
                /**
                 * The following `getFromTunnel` not only tests the tunnel contract but also triggers the mint function as well.
                 */
                await tunnel.getFromTunnel(tokenId, userAddress, data, {from: ponsAccountAddress});
            });
            it("Test if token now exists", async function(){
                expect(
                    await tunnel.tokenExists(tokenId, {from: ponsAccountAddress})
                ).to.be.true;
            });
            it("Test for token owner", async function(){
                expect(
                    await tunnel.tokenOwner(tokenId, {from: ponsAccountAddress})
                ).to.equal(userAddress);
            });

            /**
             * Must be done after getting from tunnel. This ensures that a nft exists by a known Id.
             */
            after("Send into Tunnel - after getting from tunnel", function(){
                describe("Send into Tunnel", function(){
                    before("Trigger contract transaction", async function(){
                        /**
                         * Send existing nft into polygon (simulate relay node)
                         */
                        await tunnel.sendThroughTunnel(tokenId, "0x78564534" /* Dummy flow address */, {from: userAddress});
                    });
                    it("Testing that owner of nft is the tunnel contract", async function(){
                        /**
                         * Test that, after sending, nft is being held by Tunnel Contract.
                         */
                        expect(
                            await tunnel.tokenOwner(tokenId, {from: userAddress})
                        ).to.equal(tunnel.address, {from: ponsAccountAddress});
                    });
                    it("Testing that sent nft's are delisted", async function(){
                        /**
                         * Test that, after sending, nft has been delisted from polygon marketplace.
                         */
                        expect(
                            await market.islisted(tokenId, {from:userAddress})
                        ).to.be.false;
                    });
                    after("Testing Inter-Blockchain purchases", function(){
                        describe("Testing Tunnel Direct Market", function(){
                            before("Receive NFT from tunnel which is due for market", async function(){
                                /**
                                 * We pass the market address so that nft is set to be listed for sale instead of being handed to a user.
                                 */
                                await tunnel.getFromTunnel(tokenId, market.address, data, {from: ponsAccountAddress});
                            });
                            it("Test if token is listed", async function(){
                                expect(
                                    await market.islisted(tokenId, {from: ponsAccountAddress})
                                ).to.be.true;
                            });
                            it("Test if token is owned by Pons Market", async function(){
                                expect(
                                    await tunnel.tokenOwner(tokenId, {from: ponsAccountAddress})
                                ).to.equal(market.address);
                            });
                            // it("", async function(){});
                        });
                    });
                })
            });
        });
    });
});