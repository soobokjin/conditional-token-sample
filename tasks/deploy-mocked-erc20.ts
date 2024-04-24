import { Contract, BaseContract, ContractTransactionResponse } from "ethers";
import { task } from "hardhat/config";
import { MockERC20, SpoilerConditionalTokensV1 } from "../typechain-types";

function deployMockErc20() {
  task("deploy-mock-erc20", "(custom task) deploy mock erc20")
    .addParam<string>(
      "mintTo",
      "address that receive minted token.",
      undefined,
      undefined,
      true
    )
    .addParam<number>(
      "mintAmount",
      "amount to mint.",
      undefined,
      undefined,
      true
    )
    .setAction(async (args, hre) => {
      /**
       * Deploy mocked erc
       *
       * if need, gen token and send to specified address
       */
      const mintTo: string | undefined = args.mintTo;
      const amount: number = args.mintAmount;
      const [deployer] = await hre.ethers.getSigners();
      const MockErc20 = await hre.ethers.getContractFactory(
        "MockERC20",
        deployer
      );
      const gasPrice = (await hre.ethers.provider.getFeeData()).gasPrice;

      const mockErc20: BaseContract = await MockErc20.deploy({
        gasPrice: gasPrice,
      });
      await mockErc20.waitForDeployment();
      const address = await mockErc20.getAddress();
      console.log(`Contract deployed at address: ${address}`);

      if (mintTo) {
        console.log(`Mint ${amount} to ${mintTo}`);
        const contract: MockERC20 = await hre.ethers.getContractAt(
          "MockERC20",
          address,
          deployer
        );
        await contract.mint(mintTo, amount);
      }

      await hre.run("verify:verify", {
        address: address,
        network: hre.network.name,
      });
      console.log(`Contract verified`);
    });
}

export default deployMockErc20;
