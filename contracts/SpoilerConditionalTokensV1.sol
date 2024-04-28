// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import {Address} from "openzeppelin-contracts/contracts/utils/Address.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {ERC1155} from "openzeppelin-contracts/contracts/token/ERC1155/ERC1155.sol";
import {Ownable}  from "openzeppelin-contracts/contracts/access/Ownable.sol";

import {SafeMath} from "./utils/SafeMath.sol";

import {ISpoilerPoint} from "./interfaces/ISpoilerPoint.sol";
/**
// TODO: devide collateral treasury and this logic
 */

// condition Id: oracle, questionId
// position Id: condition Id + position index 
struct Condition {
  bool isInitialized;
  address collateralToken;
  address oracle;
  uint8 positionCount;
  uint256 startTimestamp;
  uint256 endTimestamp;
  // key: position id, value: total supply condition open 까지만 업데이트
  mapping(uint256 => uint256) positionTotalSupply;
  // default: max uint8
  uint8 selectedIndex;
}

// TODO: setup url
contract SpoilerConditionalTokensV1 is ERC1155, Ownable {
  using SafeMath for uint256;
  using SafeMath for uint8;
  using Address for address;

  /// EVENTS ///

  event PrepareCondition(bytes32 conditionId, bytes32 questionId, address oracle, uint positionCount);
  event ResolveCondition(bytes32 conditionId, address oracle, uint8 selectedIdx);
  event TakePosition(bytes32 indexed conditionId, address indexed positionBuyer, uint8 positionIdx, uint256 amount);
  event RedeemPosition(bytes32 indexed conditionId, address indexed positionBuyer, uint256 amount);

  /// STATE VARIABLES ///

  ISpoilerPoint spoilerPoint;
  mapping(bytes32 => Condition) internal conditions;
  uint256 minPositionLimits;
  uint256 maxPositionLimits;

  

  constructor(address spoilerPoint) Ownable(msg.sender) ERC1155("url"){
    spoilerPoint = ISpoilerPoint(spoilerPoint);
    maxPositionLimits = type(uint256).max;

    spoilerPoint.approve(address(this), type(uint256).max);
  }

  /// VIEW FUNCTION ///

  function getConditionId(address oracle, bytes32 questionId) public pure returns(bytes32) {
    return keccak256(abi.encodePacked(oracle, questionId));
  }

  function getPositionId(bytes32 conditionId, uint8 positionIdx) public pure returns(uint256) {
    return uint256(keccak256(abi.encodePacked(conditionId, positionIdx)));
  }

  function isInitialized(bytes32 conditionId) external view returns (bool) {
    return conditions[conditionId].isInitialized;
  }

  function getTimestampsByConditionId(bytes32 conditionId) external view returns (uint256 startTimestamp, uint256 endTimestamp) {
    startTimestamp = conditions[conditionId].startTimestamp;
    endTimestamp = conditions[conditionId].endTimestamp;
  }

  function getPositionTotalSupply(bytes32 conditionId, uint8 positionIdx) public view returns (uint256) {
    uint256 positionId = getPositionId(conditionId, positionIdx);
    Condition storage condition = conditions[conditionId];

    return condition.positionTotalSupply[positionId];
  }

  /// STATE MODIFY FUNCTION ///

  function setMinPositionLimits(uint256 limits) onlyOwner() external {
    minPositionLimits = limits;
  }

  function setMaxPositionLimits(uint256 limits) onlyOwner() external {
    maxPositionLimits = limits;  
  }

  function updateStartTimestamp(bytes32 conditionId, uint256 timestamp) onlyOwner() external {
    Condition storage condition = conditions[conditionId];

    require(condition.isInitialized == true, "SpoilerConditionalTokensV1: Not initialized");
    require(block.timestamp < condition.startTimestamp , "SpoilerConditionalTokensV1: Cannot change after started");
    require(timestamp < condition.endTimestamp , "SpoilerConditionalTokensV1: Invalid timestamp");

    condition.startTimestamp = timestamp;
  }

  function updateEndTimestamp(bytes32 conditionId, uint256 timestamp) onlyOwner() external {
    Condition storage condition = conditions[conditionId];

    require(condition.isInitialized == true, "SpoilerConditionalTokensV1: Not initialized");
    require(block.timestamp < condition.endTimestamp , "SpoilerConditionalTokensV1: Cannot change after ended");
    require(timestamp > block.timestamp , "SpoilerConditionalTokensV1: Invalid timestamp");    
    require(timestamp > condition.startTimestamp , "SpoilerConditionalTokensV1: Invalid timestamp");

    condition.endTimestamp = timestamp;
  }

  function prepareCondition(
    IERC20 collateralToken, 
    address oracle, 
    bytes32 questionId, 
    uint8 positionCount, 
    uint256 startTimestamp,
    uint256 endTimestamp
    ) onlyOwner() external {
    // precondtion check
    bytes32 conditionId = getConditionId(oracle, questionId);
    Condition storage condition = conditions[conditionId];

    require(condition.isInitialized == false, "SpoilerConditionalTokensV1: Already initialized");
    require(positionCount < type(uint8).max, "SpoilerConditionalTokensV1: Exceed max position count");
    require(startTimestamp >= block.timestamp, "SpoilerConditionalTokensV1: Invalid timestamp");
    require(startTimestamp < endTimestamp, "SpoilerConditionalTokensV1: Invalid timestamp");

    condition.isInitialized = true;
    condition.collateralToken = address(collateralToken);
    condition.oracle = oracle;
    condition.positionCount = positionCount;
    condition.startTimestamp = startTimestamp;
    condition.endTimestamp = endTimestamp;
    condition.selectedIndex = type(uint8).max;

    emit PrepareCondition(conditionId, questionId, oracle, positionCount);
  }

  function resolve(bytes32 questionId, uint8 selectedIdx) external {
    bytes32 conditionId = getConditionId(msg.sender, questionId);
    Condition storage condition = conditions[conditionId];
    require(condition.isInitialized == true, "SpoilerConditionalTokensV1: Not initialized");
    require(block.timestamp > condition.endTimestamp, "SpoilerConditionalTokensV1: Condition not ended");
    require(condition.selectedIndex == type(uint8).max, "SpoilerConditionalTokensV1: Already resolved");
    require(selectedIdx <= condition.positionCount - 1, "SpoilerConditionalTokensV1: Not in range");

    condition.selectedIndex = selectedIdx;

    emit ResolveCondition(conditionId, condition.oracle, selectedIdx);
  }

  /**
    TODO: mint point
   */
  function takePosition(bytes32 conditionId, uint8 positionIdx, uint256 amount) external {
    Condition storage condition = conditions[conditionId];
    uint256 positionId = getPositionId(conditionId, positionIdx);
    require(condition.isInitialized == true, "SpoilerConditionalTokensV1: Not initialized");
    require(block.timestamp >= condition.startTimestamp && block.timestamp <= condition.endTimestamp, "SpoilerConditionalTokensV1: Condition not activated");
    uint256 positionAmount = balanceOf(msg.sender, positionId).add(amount);
    require(positionAmount >= minPositionLimits, "SpoilerConditionalTokensV1: Insufficient position amount");
    require(positionAmount <= maxPositionLimits, "SpoilerConditionalTokensV1: Exceed max position");

    IERC20(condition.collateralToken).transferFrom(msg.sender, address(this), amount);
    _mint(msg.sender, positionId, amount, "");
    condition.positionTotalSupply[positionId] = condition.positionTotalSupply[positionId].add(amount);

    emit TakePosition(conditionId, msg.sender, positionIdx, amount);
  }

  /**
    TODO: send minted point
   */
  function redeemPosition(bytes32 conditionId) external {
    // redeem position by share;
    Condition storage condition = conditions[conditionId];
    require(condition.selectedIndex != type(uint8).max, "SpoilerConditionalTokensV1: Not resolved");

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
    uint256 redeemAmount = prize.add(winPositonAmount);

    _burn(msg.sender, winPositionId, winPositonAmount);
    IERC20(condition.collateralToken).transfer(msg.sender, prize.add(winPositonAmount));

    emit RedeemPosition(conditionId, msg.sender, redeemAmount);
  }

  /**
    TODO: redeem point to colleteral
   */
  // 담보물은 단일로 가져가는 것이 좋을 것 같음. 아니면 담보물 별 ERC20 을 보유하고 있어야 함 (이에따라 담보물 토큰도 condition 별로 변경할 수 없도록 할 필요가 있음)
  function redeemColleteral(uint256 pointAmount) external {

  }

}