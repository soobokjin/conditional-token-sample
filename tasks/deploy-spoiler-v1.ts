import { Contract, BaseContract, ContractTransactionResponse } from "ethers";
import { task } from "hardhat/config";

function deploySpolierConditionTokenV1() {
  task("deploy-spoiler-v1", "(custom task) deploy spoiler v1")
    .addParam<string>("spoilerPoint", "spoilerPoint address")
    .setAction(async (args, hre) => {
      const [deployer] = await hre.ethers.getSigners();
      const spoilerPoint: string = args.spoilerPoint;
      const SpoilerV1 = await hre.ethers.getContractFactory(
        "SpoilerConditionalTokensV1",
        deployer
      );
      const gasPrice = (await hre.ethers.provider.getFeeData()).gasPrice;

      const spoilerV1: BaseContract = await SpoilerV1.deploy(spoilerPoint, {
        gasPrice: gasPrice,
      });
      await spoilerV1.waitForDeployment();
      const address = await spoilerV1.getAddress();

      console.log(`Contract deployed at address: ${address}`);

      const spolierPointContract = await hre.ethers.getContractAt(
        "SpoilerPoint",
        spoilerPoint
      );
      const tx = await spolierPointContract.addApprovedTokenIssuer(address);
      const txReceipt = await tx.wait();
      console.log(`Added Conditional Token to Issuer. tx: ${txReceipt?.hash}`);

      await hre.run("verify:verify", {
        address: address,
        constructorArguments: [spoilerPoint],
        network: hre.network.name,
      });
    });
}

export default deploySpolierConditionTokenV1;
