const Eathereum = artifacts.require("Eathereum");

module.exports = function(deployer, network, accounts) {
  deployer.deploy(Eathereum, '1000000000000000000', '1000000000000000000', '100000000000000000000000',{from: accounts[0] });
};
