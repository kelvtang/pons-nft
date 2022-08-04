const Market = artifacts.require("PonsNftMarket");
const ethers = require("ethers");
// create address using ethers.
const ponsAccountAddress = ethers.utils.getAddress("0x07eC6512C66617fc0Dea66eF8A0622E648481149");
const nftId = ethers.utils.get

contract("PonsNftMarket", (accounts) => {
    let market;
    

    before(async () => {
        market = await Market.new(ponsAccountAddress, {from: accounts[0]});
    });
    describe("Test Owner Address", async ()=>{
        let owner;
        before(async ()=>{
            owner = await market.owner({from: accounts[0]});
        });
        it("help", ()=>{
            expect(owner).to.not.equal(ponsAccountAddress);
            await market.transferOwnership(ponsAccountAddress, {from: accounts[0]});
        })
    });

    // describe("Test listing of nft", async()=>{
    //     let nftId = ethers.utils
    //     before(async ()=>{

    //     });
    //     it("List Nft", ()=>{});
    // });

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