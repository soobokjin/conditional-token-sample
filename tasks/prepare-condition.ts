import { Contract, BaseContract, ContractTransactionResponse } from "ethers";
import { task } from "hardhat/config";
import { SpoilerConditionalTokensV1 } from "../typechain-types";

import crypto from "crypto";

function generateBytes32HexString(): string {
  // Generate 32 random bytes
  const bytes = crypto.randomBytes(32);
  // Convert these bytes to a hexadecimal string
  const hexString = `0x${bytes.toString("hex")}`;
  return hexString;
}

function prepareCondition() {
  task("prepare-condition", "(custom task) prepare condition")
    .addPositionalParam<string>("spoiler", "spoiler address")
    .addParam<string>("collateral", "collateral token address")
    .addParam<string>("oracle", "oracle address")
    .addParam<number>("positionCnt", "position count")
    .addParam<number>(
      "startTimestamp",
      "start timestamp",
      undefined,
      undefined,
      true
    )
    .addParam<number>("endTimestamp", "end timestamp")
    .setAction(async (args, hre) => {
      const spoiler: string = args.spoiler;
      const oracle: string = args.oracle;
      const collateral: string = args.collateral;
      const positionCnt: number = args.positionCnt;
      const questionId = generateBytes32HexString();
      let startTimestamp: number = args.startTimestamp;
      let endTimestamp: number = args.endTimestamp;

      const [deployer] = await hre.ethers.getSigners();

      const spolierContract: SpoilerConditionalTokensV1 =
        await hre.ethers.getContractAt(
          "SpoilerConditionalTokensV1",
          spoiler,
          deployer
        );
      const block = await hre.ethers.provider.getBlock("latest");
      // Extract the timestamp from the block

      if (!startTimestamp) {
        startTimestamp = block?.timestamp || 0;
        startTimestamp += 10000;
        console.log(`Timestamp: ${startTimestamp}`);
      }

      const tx = await spolierContract.prepareCondition(
        collateral,
        oracle,
        questionId,
        positionCnt,
        startTimestamp,
        endTimestamp
      );
      const receipt = await tx.wait();

      console.log(
        `Successfully send tx. question id: ${questionId} hash: ${receipt?.hash}`
      );
    });
}

export default prepareCondition;
