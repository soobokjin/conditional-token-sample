// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "hardhat/console.sol";
import "openzeppelin-contracts/contracts/proxy/utils/Initializable.sol";
import "openzeppelin-contracts/contracts/proxy/utils/UUPSUpgradeable.sol";

// env setting
// env 변경해가면서 설정가능해야 함 (hardhat, local, testnet, mainnet)
//

// V1 에서는 voting 만 할 수 있음
// V1 의 vote 를 v2 에서 로직 변경함
// (v1: candidate 에 추가, v2: 아에 완전 다른 register 로직추가 (candidate 비용 넣기), v1 method 막기 )
// (v1: candidate 에 추가, v2: override 해서 처리 )
contract VoteV1 is Initializable, UUPSUpgradeable {
    address public admin;
    uint256 public voteCnt;
    mapping(address => bool) isCandidate;
    mapping(address => uint256) voteCntPerCandidate;

    modifier onlyOwner() {
        require(msg.sender == admin);
        _;
    }

    function initialize(address _admin) public initializer {
        voteCnt = 0;
        admin = _admin;
    }

    function register() external virtual {
        isCandidate[msg.sender] = true;
    }

    function vote(address candidate) external virtual {
        voteCntPerCandidate[candidate] += 1;
        voteCnt += 1;
    }

    function getTotalVoteCount() external virtual returns (uint256) {
        return voteCnt;
    }

    function getVersion() public pure virtual returns (string memory) {
        return "1";
    }

    function isCandidates(address candidate) public view returns (bool) {
        return isCandidate[candidate];
    }

    function getCandidateVoteCnt(
        address candidate
    ) public view returns (uint256) {
        return voteCntPerCandidate[candidate];
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}
}
