/**
 * @Run 
 * You can run this by creating a ganache node using @command ganache-cli -p 7545 -m radar blur cabbage chef fix engine embark joy scheme fiction master release
 * Then create the executables by using @command truffle compile
 * Then, in a separate terminal, run @command node tests_2.mjs
 */


import test from 'tape';
import * as fs from 'fs'
import * as ethers from "ethers";
import {
    deployContract, createSigner, createRPCProviders, createContractInstance, encodeToBytes, createAndEncodeFunctionInterface
} from '../ethereum-api.mjs';
import {
    CHILD_TUNNEL_PROXY_ADDRESS, ROOT_TUNNEL_PROXY_ADDRESS, CHILD_TOKEN_PROXY_ADDRESS, ROOT_TOKEN_PROXY_ADDRESS,
    CHILD_ADMIN_PROXY, ROOT_ADMIN_PROXY
} from '../config.mjs';
import {
    ACCOUNT_ADDRESSES, PRIVATE_KEYS, GANACHE_PROVIDER_CHILD, GANACHE_PROVIDER_ROOT
} from '../config.mjs';
import { sign } from 'crypto';
import { json } from 'express';


const tunnelContractInformation = JSON.parse(fs.readFileSync("./build/contracts/FlowTunnel.json", 'utf8'));
const marketContractInformation = JSON.parse(fs.readFileSync("./build/contracts/PonsNftMarket.json", 'utf8'));
const tokenContractInformation = JSON.parse(fs.readFileSync("./build/contracts/FxERC721.json", 'utf8'));

const createTest = async function(){
    test("Test Deploy Contract", async _test => {
        
        // We use child provider that functions on port 7545. This is the standard dev port in the truffle suit.
        const Provider = await createRPCProviders(GANACHE_PROVIDER_CHILD);
        const ponsAccount = await createSigner(PRIVATE_KEYS[1])(Provider);

        let token = await deployContract(ponsAccount)(tokenContractInformation.abi)(tokenContractInformation.bytecode)([])
        var tokenInstance = await createContractInstance(token.contractAddress)(tokenContractInformation.abi)(ponsAccount);

        let market = await deployContract(ponsAccount)(marketContractInformation.abi)(marketContractInformation.bytecode)([tokenInstance.address]);
        var marketInstance = await createContractInstance(market.contractAddress)(marketContractInformation.abi)(ponsAccount);

        let tunnel = await deployContract(ponsAccount)(tunnelContractInformation.abi)(tunnelContractInformation.bytecode)([tokenInstance.address, marketInstance.address]);
        var tunnelInstance = await createContractInstance(tunnel.contractAddress)(tunnelContractInformation.abi)(ponsAccount);
        await marketInstance.setTunnelContractAddress(tunnelInstance.address);

        _test.pass(JSON.stringify({
                    "token": tokenInstance.address,
                    "market": marketInstance.address,
                    "tunnel": tunnelInstance.address}));
        _test.equal(await marketInstance.owner(), ponsAccount.address, "Contract Owner must be Pons");
        _test.equal(await tunnelInstance.owner(), ponsAccount.address, "Contract Owner must be Pons");

        // Testing Market
        const user1_signer = await createSigner(PRIVATE_KEYS[2])(Provider);
        const user2_signer = await createSigner(PRIVATE_KEYS[3])(Provider);
        // Simulate market being accessed by other accounts.
        var market_user1 = marketInstance.connect(user1_signer);
        var market_user2 = marketInstance.connect(user2_signer);
        // Simulate token being accessed by other accounts.
        var token_user1 = tokenInstance.connect(user1_signer);
        var token_user2 = tokenInstance.connect(user2_signer);
        // Simulate tunnel being accessed by other accounts.
        var tunnel_user1 = tunnelInstance.connect(user1_signer);
        var tunnel_user2 = tunnelInstance.connect(user2_signer);
        
        _test.test("Testing Market", async _test => {
            let dummyTokenId = 8978675698;
            const abiCoder = ethers.utils.defaultAbiCoder;

            _test.test("Mint Gift NFT", async _test => {
                let data = abiCoder.encode(["string", "address", "string", "uint96"], ["https://ipadd", ponsAccount.address, "alfram45", 89]);
                await marketInstance.mintGiftNft(dummyTokenId, user1_signer.address, data);
                _test.equal(await marketInstance.tokenOwner(dummyTokenId), user1_signer.address, "NFT must be owner by User1");
            })
            _test.test("List NFT", async _test => {
                await market_user1.listForSale(dummyTokenId, 5);
                await token_user1["safeTransferFrom(address,address,uint256)"](user1_signer.address, marketInstance.address, dummyTokenId);
                _test.ok(await marketInstance.isForSale(dummyTokenId), "NFT should be listed and available for sale");
                _test.equal(await marketInstance.getLister(dummyTokenId), user1_signer.address, "Address of lister should be User1");
                _test.ok((await marketInstance.getPrice(dummyTokenId)).eq(ethers.BigNumber.from("5")), "Price of NFT should be same as assigned");
            });
            
            _test.test("Simulate Purchase", async _test => {
                // User2 purchases NFT listed by User1
                await market_user2.purchase(dummyTokenId, {value: ethers.utils.parseEther("5")/* , gasLimit: ethers.utils.parseEther("50") */});
                _test.equal(await marketInstance.tokenOwner(dummyTokenId), user2_signer.address, "NFT should be owned by User2");
                _test.notOk(await market_user1.isListed(dummyTokenId), "NFT should have been delisted");
            });

            _test.test("List and Delist", async _test => {
                _test.test("List NFT", async _test => {
                    await market_user2.listForSale(dummyTokenId, 3);
                    await token_user2["safeTransferFrom(address,address,uint256)"](user2_signer.address, marketInstance.address, dummyTokenId);
                    _test.ok(await market_user1.isForSale(dummyTokenId), "NFT should be listed and for sale");
                    _test.equal(await marketInstance.getLister(dummyTokenId), user2_signer.address, "Lister should be original NFT owner");
                })
                _test.test("Delist NFT", async _test => {
                    await market_user2.withdrawListing(dummyTokenId);
                    _test.equal(await marketInstance.tokenOwner(dummyTokenId), user2_signer.address, "NFT should be returned to User2 (Original Lister)");
                    _test.notOk(await marketInstance.isListed(dummyTokenId), "NFT should be delisted.");
                })
            })
            


           
        });
        
        _test.test("Testing Tunnel", async _test => {
            let dummyTokenId = 8978333398;
            const abiCoder = ethers.utils.defaultAbiCoder;
            _test.test("Get unknown NFT from tunnel", async _test => {});
            _test.test("Send NFT through tunnel", async _test => {});
            _test.test("Get known NFT from tunnel", async _test => {});

            _test.test("Get Market NFT from tunnel", async _test => {});
            _test.test("Send Market NFT through tunnel", async _test => {})
        });
    })
};




await createTest();
