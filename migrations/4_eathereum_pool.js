const EAT = artifacts.require("EAT");
const Farm = artifacts.require("Farm");
const RewardPool = artifacts.require("RewardPool");
const DummyERC20 = artifacts.require("DummyERC20");
const Etherio = artifacts.require("Etherio");

module.exports = async function(deployer, network, accounts) {
    let eater_token = new web3.eth.Contract(EAT.abi, EAT.address);
    await deployer.deploy(
    Farm,
    accounts[3],
    '650000000000000000',
    '0',
    '0'
    )

    await deployer.deploy(RewardPool, EAT.address, accounts[3])
  
    let eater_maker = new web3.eth.Contract(Farm.abi, Farm.address);
    console.log(DummyERC20.address)
    // eater_maker.methods.addPool(
    //     '100',
    //     DummyERC20.address,
    //     false
    // ).send({from: accounts[0]}).catch(err => console.log(err)).then(res => console.log(res))

};
