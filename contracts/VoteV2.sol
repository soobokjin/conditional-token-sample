// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "hardhat/console.sol";
import "openzeppelin-contracts/contracts/proxy/utils/Initializable.sol";
import "./VoteV1.sol";

contract VoteV2 is VoteV1 {
    modifier onlyToCandidate(address candiate) {
        require(isCandidate[candiate] == true, "Only Vote to candidate");
        _;
    }

    function register() external virtual override {
        isCandidate[msg.sender] = true;
    }

    function vote(
        address candidate
    ) external virtual override onlyToCandidate(candidate) {
        voteCntPerCandidate[candidate] += 2;
        voteCnt += 2;
    }

    function getVersion() public pure virtual override returns (string memory) {
        return "2";
    }
}
