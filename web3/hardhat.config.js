require("@nomicfoundation/hardhat-toolbox");
require("@nomicfoundation/hardhat-verify");
const path = require("path");
require("dotenv").config({ path: path.resolve(__dirname, "./.env") });

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.19",
    settings: {
      optimizer: {
        enabled: true,
        runs: 1000,
      },
    },
  },
  networks: {
    localhost: {
      url: "http://127.0.0.1:8545",
    },
    // sepolia: {
    //   url: `${process.env.SEPOLIA_RPC}/${process.env.PROJECT_ID}`,
    //   accounts: [process.env.PRIVATE_KEY],
    // },
    blast_sepolia: {
      url: `${process.env.BLAST_SEPOLIA_RPC}`,
      accounts: [process.env.PRIVATE_KEY],
      chainId: 168587773,
      gasPrice: 1000000000,
    },
  },
  etherscan: {
    apiKey: {
      blast_sepolia: "blast_sepolia",
    },
    customChains: [
      {
        network: "blast_sepolia",
        chainId: 168587773,
        urls: {
          apiURL:
            "https://api.routescan.io/v2/network/testnet/evm/168587773/etherscan",
          browserURL: "https://testnet.blastscan.io",
        },
      },
    ],
  },
};
