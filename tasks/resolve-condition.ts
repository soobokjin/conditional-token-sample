import { Contract, BaseContract, ContractTransactionResponse } from "ethers";
import { task } from "hardhat/config";
import { SpoilerConditionalTokensV1 } from "../typechain-types";
import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";

function resolveCondition() {
  task("resolve-condition", "(custom task) resolve condition")
    .addPositionalParam<string>("spoiler", "spoiler address")
    .addPositionalParam<string>("questionId", "question ID")
    .addParam<number>("selectedIdx", "selected position index")
    .addParam<string>("oraclePrivateKey", "oracle private key")
    .setAction(async (args, hre) => {
      const spoiler: string = args.spoiler;
      const questionId: string = args.questionId;
      const selectedIdx: number = args.selectedIdx;
      const oraclePrivateKey: string = args.oraclePrivateKey;

      const oracleWallet = new hre.ethers.Wallet(
        oraclePrivateKey,
        hre.ethers.provider
      );
      const spolierContract: SpoilerConditionalTokensV1 =
        await hre.ethers.getContractAt(
          "SpoilerConditionalTokensV1",
          spoiler,
          oracleWallet
        );

      const tx = await spolierContract.resolve(questionId, selectedIdx);
      const receipt = await tx.wait();

      console.log(
        `Successfully send tx. question id: ${questionId} hash: ${receipt?.hash}`
      );
    });
}

export default resolveCondition;
