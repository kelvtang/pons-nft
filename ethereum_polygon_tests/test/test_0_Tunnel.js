const Tunnel = artifacts.require("FlowTunnel");
const ethers = require("ethers");

// Create address type using ethers. 
    // This address must be in ganache environment.
const currentAddress = ethers.utils.getAddress("0xa588c0322Fb61152966EB67d1fb2BadB0F30AC51");


contract("FlowTunnel", (accounts)=>{
    var tunnel;

    before("Setup Tunnel", async ()=>{
        tunnel = await Tunnel.new({from: accounts[0]});
    });

    describe("Test Owner", async ()=>{
        let owner;
        before("Load address of contract owner", async ()=>{
            owner = await tunnel.owner({from: accounts[0]});
        });
        it("Test if current address is correct", async ()=>{
            expect(currentAddress).to.equal(owner);
        });
    });

    describe("Testing Tunnel Functionality", async ()=>{
        const tokenId = 26787689; // Dummy value
        let _tokenId;
        let data;
        const ownerId = currentAddress; // Let pons be owner of this dummy nft.
        const abiCoder = ethers.utils.defaultAbiCoder;

        before("Setup Dummy Data", async ()=>{
            data = abiCoder.encode(["string", "address", "string", "uint96"], ["https://cool_boi.png", ownerId, "0x78785678", 78])
        });

        describe("Testing token", async ()=>{
            let token_exits;
            before("Load token - 1", async ()=>{     
                token_exits = await tunnel.tokenExists(tokenId, {from:accounts[0]});
            });
            it("Token does not exist", async ()=>{
                await expect(token_exits).to.equal(false);
            });
        });
        // describe("Testing sending into Tunnel", async ()=>{});
    });


    // describe("", async ()=>{});
     
});


// const Adoption = artifacts.require("Adoption");

// contract("Adoption", (accounts) => {
//   let adoption;
//   let expectedAdopter;

//   before(async () => {
//       adoption = await Adoption.deployed();
//   });

//   describe("adopting a pet and retrieving account addresses", async () => {
//   before("adopt a pet using accounts[0]", async () => {
//     await adoption.adopt(8, { from: accounts[0] });
//     expectedAdopter = accounts[0];
//   });

//   it("can fetch the address of an owner by pet id", async () => {
//     const adopter = await adoption.adopters(8);
//     assert.equal(adopter, expectedAdopter, "The owner of the adopted pet should be the first account.");
//   });
//   it("can fetch the collection of all pet owners' addresses", async () => {
//   const adopters = await adoption.getAdopters();
//   assert.equal(adopters[8], expectedAdopter, "The owner of the adopted pet should be in the collection.");
// });

// });


//   describe("adopting a pet and retrieving account addresses", async () => {
//     before("adopt a pet using accounts[0]", async () => {
//       await adoption.adopt(8, { from: accounts[0] });
//       expectedAdopter = accounts[0];
//     });
//   });
// });