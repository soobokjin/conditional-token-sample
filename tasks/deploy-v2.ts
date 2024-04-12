import { Contract } from "ethers";
import { task } from "hardhat/config";

function deployContractsV2() {
  task("deploy-v2", "(custom task) deploy contracts").setAction(
    async (args, hre) => {
      // get network (rinkeby)
      // deploy to ethereum
      // record result
      const addr: string = "0x83D5EBB6c43C00e50E82318eeC08ebF708AB7678";
      const [deployer] = await hre.ethers.getSigners();
      const VoteV1 = await hre.ethers.getContractFactory("VoteV1", deployer);
      const voteV1: Contract = await hre.upgrades.deployProxy(
        VoteV1,
        [deployer.address],
        {
          kind: "uups",
          timeout: 60000,
        }
      );

      await voteV1.waitForDeployment();
      console.log("V1 deployed to:", voteV1.address);

      await voteV1.register();
      console.log(await voteV1.isCandidates(deployer.address));

      await voteV1.vote(deployer.address);

      console.log(await voteV1.getCandidateVoteCnt(deployer.address));
      console.log(await voteV1.getVersion());

      const VoteV2 = await hre.ethers.getContractFactory("VoteV2");
      const box = await hre.upgrades.upgradeProxy(
        await voteV1.getAddress(),
        VoteV2
      );

      console.log(await voteV1.getCandidateVoteCnt(deployer.address));
      console.log(await voteV1.getVersion());

      await voteV1.vote(deployer.address);
      await voteV1.vote(addr);

      console.log(await voteV1.getCandidateVoteCnt(deployer.address));
    }
  );
}

export default deployContractsV2;
