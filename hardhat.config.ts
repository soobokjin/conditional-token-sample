import { HardhatUserConfig } from "hardhat/types";
import "@nomicfoundation/hardhat-toolbox";
import "@openzeppelin/hardhat-upgrades";
import "@nomiclabs/hardhat-ganache";
import "@nomicfoundation/hardhat-foundry";
import "@nomicfoundation/hardhat-ethers";
import importToml from "import-toml";

import { config as dotenvConfig } from "dotenv";
import { resolve } from "path";

import deploySpolierConditionTokenV1 from "./tasks/deploy-spoiler-v1";

const foundryConfig: any = importToml.sync("foundry.toml");
dotenvConfig({ path: resolve(__dirname, "./.env") });

// Setup Task
deploySpolierConditionTokenV1();

const ETHERSCAN_API_KEY: string = process.env.ETHERSCAN_API_KEY || "";
const ALCHEMY_API_KEY: string = process.env.ALCHEMY_API_KEY || "";
const DEPLOYER_PRIVATE_KEY: string = process.env.DEPLOYER_PRIVATE_KEY || "";

const config: HardhatUserConfig = {
  networks: {
    baseSepolia: {
      url: `https://base-sepolia.g.alchemy.com/v2/${ALCHEMY_API_KEY}`,
      accounts: [DEPLOYER_PRIVATE_KEY],
    },
    hardhat: {
      accounts: [
        {
          privateKey: DEPLOYER_PRIVATE_KEY,
          balance: "2000000000000000000000",
        },
      ],
      forking: {
        url: `https://eth-mainnet.g.alchemy.com/v2/${ALCHEMY_API_KEY}`,
        blockNumber: 17000000,
      },
      mining: {
        mempool: {
          order: "fifo",
        },
      },
      chainId: 1337,
    },
    localhost: {
      url: "http://0.0.0.0:8545",
      accounts: [DEPLOYER_PRIVATE_KEY],
    },
  },
  etherscan: {
    // Your API key for Etherscan
    // Obtain one at https://etherscan.io/
    apiKey: ETHERSCAN_API_KEY,
  },
  solidity: {
    version: foundryConfig.profile.default.solc_version,
    settings: {
      viaIR: foundryConfig.profile.default.via_ir,
      optimizer: {
        enabled: true,
        runs: foundryConfig.profile.default.optimizer_runs,
      },
      metadata: {
        // do not include the metadata hash, since this is machine dependent
        // and we want all generated code to be deterministic
        // https://docs.soliditylang.org/en/v0.8.20/metadata.html
        bytecodeHash: "none",
      },
    },
  },
};

export default config;
