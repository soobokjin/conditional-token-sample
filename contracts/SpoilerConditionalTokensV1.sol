// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import {SafeMath} from "./utils/SafeMath.sol";
import {Address} from "openzeppelin-contracts/contracts/utils/Address.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {ERC1155} from "openzeppelin-contracts/contracts/token/ERC1155/ERC1155.sol";
import {CTHelpers} from "./CTHelpers.sol";


// TODO: owner restriction
// TODO: devide collateral treasury and this logic

// oracle, questionId 를 조합하여 condition Id 생성. (slot count 는 상관없음)
// position Id: condition Id + position index 
struct Condition {
  address collateralToken;
  address oracle;
  uint8 positionCount;
  uint256 startBlockNumber;
  uint256 endBlockNumber;
  // key: position id, value: total supply condition open 까지만 업데이트
  mapping(bytes32 => uint256) positionTotalSupply;
  // default: max uint8
  uint8 selectedIndex;
}

// TODO: setup url
contract SpoilerConditionalTokensV1 is ERC1155("url") {
  using SafeMath for uint256;
  using SafeMath for uint8;
  using Address for address;

  mapping(bytes32 => Condition) conditions;
  

  function prepareCondition(address oracle, bytes32 questionId, uint8 positionCount) external {
    // condition 등록, 이미 존재하면 error
  }

  function resolve(bytes conditionId, uint8 selectedIdx) external {
  }

  function takePosition(bytes conditionId, uint8 positionIdx) external {
    
  }

  function redeem(bytes conditionId) external {
    
  }

  function getConditionId(address oracle, bytes32 questionId) public pure returns(bytes32) {

  }

  function getPositionId() public pure returns(bytes32) {

  }
}