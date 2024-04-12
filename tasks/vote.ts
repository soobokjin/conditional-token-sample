import { task } from "hardhat/config";

function voteTask() {
  task("vote", "vote to deployed contract").setAction(async (args, hre) => {
    const [deployer] = await hre.ethers.getSigners();

    const voteContract = await hre.ethers.getContractAt(
      "VoteV1",
      "0x27f6fA05644FF639cc5F992cDbD7b7fedfd4648e",
      deployer
    );

    const result = await voteContract.isCandidates(
      "0x83D5EBB6c43C00e50E82318eeC08ebF708AB7678"
    );
    const voteTx = await voteContract.vote(
      "0x83D5EBB6c43C00e50E82318eeC08ebF708AB7678"
    );
    const voteResult = await voteTx.wait();

    const regTx = await voteContract.register();

    const getVersion = await voteContract.getVersion();
    const cnt = await voteContract.voteCnt();
    console.log(result);
    console.log(cnt);
    console.log(voteResult);
  });
}

export default voteTask;
