var FxERC721 = artifacts.require("FxERC721.sol")
var FlowTunnel = artifacts.require("FlowTunnel"); // get contract
var PonsNftMarket = artifacts.require("PonsNftMarket"); // get contract

// const ethers = require("ethers");
// create address using ethers.
// const ponsAccountAddress = ethers.utils.getAddress("0x07eC6512C66617fc0Dea66eF8A0622E648481149");

// export deployer.
module.exports = function(deployer) {
  // deployer.deploy(PonsNftMarket).then(()=>{
  //   // using `.then(function)` we can arrange order of deployment.
  //   return deployer.deploy(FlowTunnel);
  // });

  var token, market, tunnel;
  deployer.then(()=>{
    return FxERC721.new();
  }).then((instance) => {
    token = instance;

    return PonsNftMarket.new(token.address);
  }).then((instance) => {
    market = instance;

    return FlowTunnel.new(token.address, market.address);
  })

};