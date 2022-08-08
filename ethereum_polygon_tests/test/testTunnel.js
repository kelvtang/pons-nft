const Tunnel = artifacts.require("FlowTunnel");
const ethers = require("ethers");

// Create address type using ethers. 
    // This address must be in ganache environment.
const ponsAccountAddress = ethers.utils.getAddress("0x5c3266FDb6BbC76e428ADA42C06d6615170C5BB2");


contract("FlowTunnel", (accounts)=>{
    let tunnel;
    before("Setup Tunnel", async ()=>{
        tunnel = Tunnel.new({from: accounts[0]});
    })
    describe("", async ()=>{});


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