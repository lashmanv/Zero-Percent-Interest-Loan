require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-etherscan");
require("@nomiclabs/hardhat-ethers");
// require('hardhat-contract-sizer');
require("@nomiclabs/hardhat-web3");
require('dotenv').config({path:'C:/Users/User/Desktop/zusd/.env'});

const GOERLI_URL = "https://eth-goerli.g.alchemy.com/v2/UaaYF43sj3JMJovB77fp8Zke3Dg0LUko";
const PRIVATE_KEY = ['0c063eb37e4ae8e58266b00606de9c5fc0666c5c45e39fd4263825075dba3d26'];

task("hardhat", "Prints the list of accounts", async () => {
  const accounts = await ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

task("accounts", "Prints the list of accounts", async () => {
  const Web3 = require('web3');
  const web3 = new Web3('http://127.0.0.1:8545');

  web3.eth.getAccounts()
  .then(accounts => {
    console.log(accounts);
    accounts.forEach(account => {
      const privateKey = web3.eth.accounts.wallet //.privateKey;
      console.log('Account:', account, 'Private key:', privateKey);
    });
  })
  .catch(error => {
    console.log(error);
  });
  // let signerAddress = await signer.getAddress();
  // signerAddress = [`${signerAddress}`];
  // console.log(signerAddress[0]);

  // console.log(signerAddress);
});

task("balance", "Prints an account's balance")
  .addParam("account", "The account's address")
  .setAction(async (taskArgs) => {
    const account = web3.utils.toChecksumAddress(taskArgs.account);
    const balance = await web3.eth.getBalance(account);

    console.log(web3.utils.fromWei(balance, "ether"), "ETH");
  });

module.exports = {
  solidity: {
    version: "0.8.10",
    settings: {
      optimizer: {
        enabled: true,
        runs: 1000,
      },
    },
  },
  networks: {
    hardhat: {
      allowUnlimitedContractSize: true
    },
  	mumbai: {
      // Infura
      url: `https://rpc-mumbai.maticvigil.com`,
      accounts: PRIVATE_KEY,
      gasPrice: 30000000,
      saveDeployments: true,
    },
    goerli: {
      // Infura
      url: GOERLI_URL,
      accounts: PRIVATE_KEY,
      gasPrice: 30000000,
      saveDeployments: true,
    },
    ganache: {
      url: 'http://127.0.0.1:8545',
    }
  },
  paths: {
    sources: "./TestScript",
    tests: "./test",
    cache: "./cache",
    artifacts: "./client/src/artifacts"
  },
  mocha: {
    timeout: 200000
  },
  
  etherscan: {
    apiKey: "1DZFZGP1NUZ339VI6I5WTWT7619GGKEKYS"//"VNEKXPT3VGZVAA88HUS5XYM2TRISJTTTKJ" 
  },
  polyscan: {
    apiKey: "57M6RGRNETYA7RZ53WQHSBMMWC3JF2X2K6"
  },

  contractSizer: {
    alphaSort: true,
    runOnCompile: true,
    disambiguatePaths: false,
    strict: false
  }
}