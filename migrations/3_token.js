const EAT = artifacts.require("EAT");
const DummyERC20 = artifacts.require("DummyERC20");

module.exports = async function(deployer, network, accounts) {
  // if(network === 'development' || network === 'rinkeby') {
    await deployer.deploy(
      DummyERC20,
      'AMPL/EATH',
      'AMPL',
      '3000000000000000000000000'
    )
  //     let dummyerc = new web3.eth.Contract(DummyERC20.abi, DummyERC20.address);
  //     dummyerc.methods.transfer(accounts[1], '1000000000000000000000000').send({ from: accounts[0] }).catch(err => console.log(err)).then(res=>console.log('ttranferred ercdumy'))
  //     dummyerc.methods.transfer(accounts[2], '500000000000000000000000').send({ from: '0xBaDDdDE345D4EB32449426d126f8B307B709DC8f'}).catch(err => console.log(err)).then(res=>console.log('ttranferred ercdumy'))
  //     dummyerc.methods.transfer(accounts[3], '500000000000000000000000').send({ from: '0x8EFD00918474c909F913637Fd310cA35ed9FC4E6' }).catch(err => console.log(err)).then(res=>console.log('ttranferred ercdumy'))
  // }
  await deployer.deploy(EAT, {from: accounts[0]});

};
