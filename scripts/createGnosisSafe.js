const { ethers } = require("hardhat");
const { EthersAdapter, SafeFactory } = require("@gnosis.pm/safe-core-sdk");
const { gnosisSafeConfig, multisigSigners } = require("../secrets.json");

async function main() {
  const [owner, ...others] = await ethers.getSigners();
  const safeAdapter = new EthersAdapter({ethers: ethers, signer: owner});
  
  const network = await ethers.provider.getNetwork();
  const contractNetworks = {};
  contractNetworks[network.chainId] = gnosisSafeConfig;
  const safeFactory = await SafeFactory.create({ethAdapter: safeAdapter, contractNetworks: contractNetworks});

  const threshold = multisigSigners.length > 1 ? multisigSigners.length - 1 : 1;
  const safeAccountConfig = { owners: multisigSigners, threshold: threshold };

  const safe = await safeFactory.deploySafe(safeAccountConfig);

  console.log("safe deployed at ", safe.getAddress());
  console.log("safe owners ", await safe.getOwners());
  console.log("safe threshold", await safe.getThreshold());
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });