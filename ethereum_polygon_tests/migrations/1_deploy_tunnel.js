var FlowTunnel = artifacts.require("FlowTunnel"); // get contract
var PonsNftMarket = artifacts.require("PonsNftMarket"); // get contract

// const ethers = require("ethers");
// create address using ethers.
// const ponsAccountAddress = ethers.utils.getAddress("0x07eC6512C66617fc0Dea66eF8A0622E648481149");

// export deployer.
module.exports = function(deployer) {
  deployer.deploy(PonsNftMarket).then(()=>{
    // using `.then(function)` we can arrange order of deployment.
    return deployer.deploy(FlowTunnel);
  });
};