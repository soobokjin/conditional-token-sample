import { Contract, BaseContract, ContractTransactionResponse } from "ethers";
import { task } from "hardhat/config";

function deploySpoilerPoint() {
  task("deploy-spoiler-point", "(custom task) deploy spoiler point")
    .addParam<string>("collateral", "collateral token address")
    .addParam<string>("treasury", "treasury address")
    .setAction(async (args, hre) => {
      const [deployer] = await hre.ethers.getSigners();
      const collateral: string = args.collateral;
      const treasury: string = args.treasury;
      const SpoilerPoint = await hre.ethers.getContractFactory(
        "SpoilerPoint",
        deployer
      );
      const gasPrice = (await hre.ethers.provider.getFeeData()).gasPrice;

      const treauryContract = await hre.ethers.getContractAt(
        "SpoilerTreasury",
        treasury
      );
      const spoilerPoint: BaseContract = await SpoilerPoint.deploy(
        collateral,
        treasury,
        {
          gasPrice: gasPrice,
        }
      );
      await spoilerPoint.waitForDeployment();
      const address = await spoilerPoint.getAddress();
      const txResult = await treauryContract.addApprovedTokenDepositor(address);
      const tx = await txResult.wait();

      console.log(`Contract deployed at address: ${address}`);
      console.log(`Added SpoilerPoint to Treasury. tx: ${tx?.hash}`);

      await hre.run("verify:verify", {
        address: address,
        constructorArguments: [collateral, treasury],
        network: hre.network.name,
      });
    });
}

export default deploySpoilerPoint;
