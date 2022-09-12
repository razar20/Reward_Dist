require('@openzeppelin/hardhat-upgrades');
require("@nomiclabs/hardhat-waffle");

const { deployerPrivateKey } = require("./secrets.json");

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: "0.8.4",
  settings: {
    optimizer: {
      enabled: true,
      runs: 200
    }
  },
  networks: {
    hardhat: {
      // 'loggingEnabled': true
    },
    gatherdevnet: {
      url: "https://devnet.gather.network",
      accounts: [deployerPrivateKey],
      timeout: 600000
    },
  }
};