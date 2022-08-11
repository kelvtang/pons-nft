const Tunnel = artifacts.require("FlowTunnel");
const Market = artifacts.require("PonsNftMarket");
const Token = artifacts.require("FxERC721");

const { assert } = require("console");
const ethers = require("ethers");
const { closeSync } = require("fs");




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
        await market.setTunnelContractAddress(tunnel.address);
    });

    describe("Test Contract Owner", async function(){
        it("Test if ponsAddressAccount is owner of tunnel contract", async function(){
            expect(await tunnel.owner({from: ponsAccountAddress})).to.equal(ponsAccountAddress);
        });
    });

    

    describe("Testing Tunnel Functionality", function(){
        // Since both tests uses the same token, we place this dummy tokenId as a global variable.
        const tokenId = 787675267876449;
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
                await tunnel.getFromTunnel(tokenId, userAddress, data, 0, {from: ponsAccountAddress});
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
                    before(async function(){

                        this.timeout(20000); // trasaction takes too long.
                        // setup tunnel
                        await tunnel.setupTunnel(tokenId, {from: userAddress});
                        await token.safeTransferFrom(userAddress, tunnel.address, tokenId, {from: userAddress});
                        await tunnel.sendThroughTunnel(tokenId, "0xffff", {from:userAddress});

                    });
                    it("Test for NFT after sending", async function(){
                        expect(await tunnel.tokenOwner(tokenId, {from:userAddress})).to.equal(tunnel.address);
                    });
                })
            });
        });
    });

    describe("Test direct market to flow", function(){

        const abiCoder = ethers.utils.defaultAbiCoder;
        const tokenId = 787675288888449;
        before(async function(){

            this.timeout(50_000);
            
            let data = abiCoder.encode(["string", "address", "string", "uint96"], ["https://ipadd", ponsAccountAddress, "alfram45", 89]);
            await market.mintNewNft(tokenId, 25, data, {from: ponsAccountAddress});
            let token_exist_flag = await market.tokenExists(tokenId, {from:ponsAccountAddress});
            assert(await token_exist_flag, "Token should exist");
            
            await market.sendThroughTunnel(tokenId, {from:ponsAccountAddress});

        });
        it("Test that token has entered tunnel", async function(){
            expect(await tunnel.tokenOwner(tokenId)).to.equal(tunnel.address);
        })
        
    });
});