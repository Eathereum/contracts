require('babel-register');
require('babel-polyfill');
var HDWalletProvider = require("truffle-hdwallet-provider");
var mnemonic = "invite ceiling yellow analyst regular pony toe mansion battle almost focus where polar area switch wrong source exist allow vessel robot minute raccoon immense";
module.exports = {
  networks: {
    development: {
      host: "127.0.0.1",
      port: 7545,
      network_id: "*" // Match any network id
    },
    // rinkeby: {
    //   provider: function() { 
    //    return new HDWalletProvider(['0x1a2229b1f6a54d4047c52933f1f413b68d091917438ff763244cbafa0e4501fc'], "https://rinkeby.infura.io/v3/8517a422ca5e47eb932065f61843a491");
    //   },
    //   network_id: 4,
    //   gas: 4500000,
    //   gasPrice: 10000000000,
  // }
  },
  contracts_directory: './src/contracts/',
  contracts_build_directory: './src/abis/',
  compilers: {
    solc: {
      version: "0.6.12"

    }
  }
}
