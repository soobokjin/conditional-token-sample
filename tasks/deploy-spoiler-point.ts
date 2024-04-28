import { Contract, BaseContract, ContractTransactionResponse } from "ethers";
import { task } from "hardhat/config";

function deploySpoilerPoint() {
  task("deploy-spoiler-point", "(custom task) deploy spoiler point")
    .addParam<string>("collateral", "collateral token address")
    .setAction(async (args, hre) => {
      const [deployer] = await hre.ethers.getSigners();
      const collateral: string = args.collateral;
      const SpoilerPoint = await hre.ethers.getContractFactory(
        "SpoilerPoint",
        deployer
      );
      const gasPrice = (await hre.ethers.provider.getFeeData()).gasPrice;

      const spoilerPoint: BaseContract = await SpoilerPoint.deploy(collateral, {
        gasPrice: gasPrice,
      });
      await spoilerPoint.waitForDeployment();
      const address = await spoilerPoint.getAddress();

      console.log(`Contract deployed at address: ${address}`);

      await hre.run("verify:verify", {
        address: address,
        constructorArguments: [collateral],
        network: hre.network.name,
      });
    });
}

export default deploySpoilerPoint;
