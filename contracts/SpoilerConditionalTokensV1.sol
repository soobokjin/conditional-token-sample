// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import {SafeMath} from "./utils/SafeMath.sol";
import {Address} from "openzeppelin-contracts/contracts/utils/Address.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {ERC1155} from "openzeppelin-contracts/contracts/token/ERC1155/ERC1155.sol";


// TODO: devide collateral treasury and this logic
// TODO: owner
// TODO: restriction
// TODO: set eventlog

// oracle, questionId 를 조합하여 condition Id 생성. (slot count 는 상관없음)
// position Id: condition Id + position index 
struct Condition {
  bool isInitialized;
  address collateralToken;
  address oracle;
  uint8 positionCount;
  uint256 startBlockNumber;
  uint256 endBlockNumber;
  // key: position id, value: total supply condition open 까지만 업데이트
  mapping(uint256 => uint256) positionTotalSupply;
  // default: max uint8
  uint8 selectedIndex;
}

// TODO: setup url
contract SpoilerConditionalTokensV1 is ERC1155("url") {
  using SafeMath for uint256;
  using SafeMath for uint8;
  using Address for address;

  mapping(bytes32 => Condition) internal conditions;

  // condition 생성
  // take position eventlog <- user 별 포지션 정보 BE 에서 기록, 보여주기 위함
  // user 별 총 금액, 승리 경험 등을 별도로 기록한다.
  // user Address, fid, user betting 횟수, 승리, 진행중, 패배, 등을 기록하기 위함 (POINT)
  // redeem 

  event PrepareCondition(bytes32 conditionId, bytes32 questionId, address oracle, uint positionCount);
  event ResolveCondition(bytes32 conditionId, address oracle, uint8 selectedIdx);
  event TakePosition(bytes32 indexed conditionId, address indexed positionBuyer, uint8 positionIdx, uint256 amount);
  event RedeemPosition(bytes32 indexed conditionId, address indexed positionBuyer, uint256 amount);


  function prepareCondition(
    IERC20 collateralToken, 
    address oracle, 
    bytes32 questionId, 
    uint8 positionCount, 
    uint256 startBlockNumber,
    uint256 endBlockNumber
    ) external {
    // precondtion check
    // condition 등록
    // position count 가 max - 1 보다 작아야 함
    bytes conditionId = getConditionId(oracle, questionId);
    Condition storage condition = conditions[conditionId];

    condition.isInitialized = true;
    condition.collateralToken = address(collateralToken);
    condition.oracle = oracle;
    condition.positionCount = positionCount;
    condition.startBlockNumber = startBlockNumber;
    condition.endBlockNumber = endBlockNumber;
    condition.selectedIndex = type(uint8).max;

    emit PrepareCondition(conditionId);
  }

  function isInitialized(bytes32 conditionId) external view returns (bool) {
    return conditions[conditionId].isInitialized;
  }

  function resolve(bytes32 conditionId, uint8 selectedIdx) external {
    Condition storage condition = conditions[conditionId];
    // TODO: only oracle can call this method
    require(condition.isInitialized == true, "SpoilerConditionalTokensV1: Not initialized");
    require(condition.selectedIndex == type(uint8).max, "SpoilerConditionalTokensV1: Already resolved");
    require(selectedIdx < condition.positionCount - 1, "SpoilerConditionalTokensV1: Not in range");

    condition.selectedIndex = selectedIdx;

    emit ResolveCondition(conditionId, condition.oracle, selectedIndex);
  }

  function takePosition(bytes32 conditionId, uint8 positionIdx, uint256 amount) external {
    // transfer token to here
    // mint position token
    // check if exceed the allowed position
    Condition storage condition = conditions[conditionId];
    require(condition.isInitialized == true, "SpoilerConditionalTokensV1: Not initialized");
    uint256 positionId = getPositionId(conditionId, positionIdx);

    IERC20(condition.collateralToken).transferFrom(msg.sender, address(this), amount);
    _mint(msg.sender, positionId, amount, "");
    condition.positionTotalSupply[positionId] = condition.positionTotalSupply[positionId].add(amount);

    emit TakePosition(conditionId, msg.sender, positionIdx, amount);
  }

  function redeemPosition(bytes32 conditionId) external {
    // redeem position by share;
    Condition storage condition = conditions[conditionId];

    uint256 winPositionId = getPositionId(conditionId, condition.selectedIndex);
    uint256 winPositonAmount = balanceOf(msg.sender, winPositionId);
    uint256 loseTotalSupply = 0;
    for (uint8 i = 0; i < condition.positionCount; i++) {
      if (i == condition.selectedIndex) {
        continue;
      }
      loseTotalSupply = loseTotalSupply.add(condition.positionTotalSupply[getPositionId(conditionId, i)]);
    }
    uint256 prize = loseTotalSupply.mul(winPositonAmount).div(condition.positionTotalSupply[winPositionId]);

    _burn(msg.sender, winPositionId, winPositonAmount);
    IERC20(condition.collateralToken).transfer(msg.sender, prize.add(winPositonAmount));

    emit RedeemPosition(conditionId, msg.sender, amount);
  }

  function getConditionId(address oracle, bytes32 questionId) public pure returns(bytes32) {
    return keccak256(abi.encodePacked(oracle, questionId));
  }

  function getPositionId(bytes32 conditionId, uint8 positionIdx) public pure returns(uint256) {
    return uint256(keccak256(abi.encodePacked(conditionId, positionIdx)));
  }
}