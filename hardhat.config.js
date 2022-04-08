/**
 * @type import('hardhat/config').HardhatUserConfig
 */
require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-ethers");
require("@nomiclabs/hardhat-truffle5");
require("@nomiclabs/hardhat-etherscan"); // in order to verify our contract
require("hardhat-deploy");
// all requires above should be add through terminal by yarn add @...

require("dotenv").config(); // this line will load all the env variables from .env
// and we will be able to use below variables

const MAINNET_RPC_URL =
  process.env.MAINNET_RPC_URL || process.env.ALCHEMY_MAINNET_RPC_URL || "";
const RINKEBY_RPC_URL = process.env.RINKEBY_RPC_URL || ""; // grabbing rinkeby rpc url
const KOVAN_RPC_URL = process.env.KOVAN_RPC_URL || "";
const MNEMONIC = process.env.MNEMONIC || ""; // we are gonna pull our accounts from mnemonic phrase
const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY || ""; // to verify our contract
// optional
const PRIVATE_KEY = process.env.PRIVATE_KEY || "";

module.exports = {
  defaultNetwork: "hardhat", // fake local testnet
  networks: {
    hardhat: {
      // // If you want to do some forking, uncomment this
      // forking: {
      //   url: MAINNET_RPC_URL
      // }
    },
    localhost: {},
    /* kovan: {
            url: KOVAN_RPC_URL,
            accounts: [PRIVATE_KEY],
             accounts: {
                 mnemonic: MNEMONIC,
             },
            saveDeployments: true,
        },*/
    rinkeby: {
      url: RINKEBY_RPC_URL, // to connect to rinkeby chain, got it from alchemy
      accounts: [PRIVATE_KEY],
      // accounts: {
      //     mnemonic: MNEMONIC,
      // },
      saveDeployments: true, // to save our deployments
    } /*
        ganache: {
            url: "http://localhost:8545",
            accounts: [PRIVATE_KEY],
            // accounts: {
            //     mnemonic: MNEMONIC,
            // }
        },
        mainnet: {
            url: MAINNET_RPC_URL,
            accounts: [PRIVATE_KEY],
            // accounts: {
            //     mnemonic: MNEMONIC,
            // },
            saveDeployments: true,
        },*/,
    polygon: {
      url: "https://rpc-mainnet.maticvigil.com/",
      accounts: [PRIVATE_KEY],
      // accounts: {
      //     mnemonic: MNEMONIC,
      // },
      saveDeployments: true,
    },
  },
  etherscan: {
    //  we included this as a part of our importing etherscan section, require("@nomiclabs/hardhat-etherscan");
    // Your API key for Etherscan
    // Obtain one at https://etherscan.io/
    apiKey: ETHERSCAN_API_KEY,
  },
  namedAccounts: {
    deployer: {
      default: 0, // here this will be by default take the first account as deployer
      1: 0, // similarly on mainnet it will take the first account as deployer. Note though that depending on how hardhat network are configured, the account 0 on one network can be different than on another
    },
    feeCollector: {
      default: 1,
    },
  },
  // below is how we can have different versions of compilers in hardhat
  solidity: {
    compilers: [
      {
        version: "0.8.4",
      },
      {
        version: "0.7.0",
      },
      {
        version: "0.6.6",
      },
      {
        version: "0.4.24",
      },
    ],
  },
  mocha: {
    timeout: 100000,
  },
};
