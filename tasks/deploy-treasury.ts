import { Contract, BaseContract, ContractTransactionResponse } from "ethers";
import { task } from "hardhat/config";

function deployTreasury() {
  task("deploy-treasury", "(custom task) deploy treasury").setAction(
    async (args, hre) => {
      const [deployer] = await hre.ethers.getSigners();
      const Treasury = await hre.ethers.getContractFactory(
        "SpoilerTreasury",
        deployer
      );
      const gasPrice = (await hre.ethers.provider.getFeeData()).gasPrice;
      const treasury: BaseContract = await Treasury.deploy({
        gasPrice: gasPrice,
      });
      await treasury.waitForDeployment();
      const address = await treasury.getAddress();
      console.log(`Contract deployed at address: ${address}`);
      await hre.run("verify:verify", {
        address: address,
        network: hre.network.name,
      });
    }
  );
}

export default deployTreasury;
