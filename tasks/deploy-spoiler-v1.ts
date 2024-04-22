import { Contract, BaseContract, ContractTransactionResponse } from "ethers";
import { task } from "hardhat/config";

function deploySpolierConditionTokenV1() {
  task("deploy-spoiler-v1", "(custom task) deploy spoiler v1").setAction(
    async (args, hre) => {
      const [deployer] = await hre.ethers.getSigners();
      const SpoilerV1 = await hre.ethers.getContractFactory(
        "SpoilerConditionalTokensV1",
        deployer
      );
      const gasPrice = (await hre.ethers.provider.getFeeData()).gasPrice;

      const spoilerV1: BaseContract = await SpoilerV1.deploy({
        gasPrice: gasPrice,
      });
      await spoilerV1.waitForDeployment();

      console.log(
        `Contract deployed at address: ${await spoilerV1.getAddress()}`
      );
    }
  );
}

export default deploySpolierConditionTokenV1;
