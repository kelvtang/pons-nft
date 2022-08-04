var PonsTunnel = artifacts.require("PonsTunnel"); // get contract
var PonsNftMarket = artifacts.require("PonsNftMarket"); // get contract

var mono = artifacts.require("mono"); // get contract

const ethers = require("ethers");
// create address using ethers.
const ponsAccountAddress = ethers.utils.getAddress("0x07eC6512C66617fc0Dea66eF8A0622E648481149");

// export deployer.
module.exports = function(deployer) {
  deployer.deploy(PonsTunnel, ponsAccountAddress).then(()=>{
    // using `.then(function)` we can arrange order of deployment.
    return deployer.deploy(PonsNftMarket, ponsAccountAddress).then(()=>{
      return deployer.deploy(mono);
    });
  });
};