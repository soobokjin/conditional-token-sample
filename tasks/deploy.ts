import { task } from "hardhat/config";

function deployContracts() {
  task("deploy-v1", "(custom task) deploy contracts").setAction(
    async (args, hre) => {
      // get network (rinkeby)
      // deploy to ethereum
      // record result
      const [deployer] = await hre.ethers.getSigners();
      const VoteV1 = await hre.ethers.getContractFactory("VoteV1", deployer);
      const voteV1 = await hre.upgrades.deployProxy(
        VoteV1,
        [deployer.address],
        {
          kind: "uups",
          timeout: 60000,
        }
      );

      await voteV1.waitForDeployment();
      console.log("V1 deployed to:", await voteV1.getAddress());

      await voteV1.register();

      console.log(await voteV1.isCandidates(deployer.address));
    }
  );
}

export default deployContracts;
