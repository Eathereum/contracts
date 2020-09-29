const EAT = artifacts.require("EAT");
const RewardPool = artifacts.require("RewardPool");
const DummyERC20 = artifacts.require("DummyERC20");

module.exports = async function(deployer, network, accounts) {
  // if(network === 'development' || network === 'rinkeby') {
    await deployer.deploy(
      DummyERC20,
      'AMPL/EATH',
      'AMPL',
      '3000000000000000000000000'
    )

    await deployer.deploy(EAT, {from: accounts[0]});
};
