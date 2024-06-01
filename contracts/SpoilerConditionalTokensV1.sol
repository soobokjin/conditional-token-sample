// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import {Address} from "openzeppelin-contracts/contracts/utils/Address.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
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
  using SafeERC20 for IERC20;
  using SafeMath for uint256;
  using SafeMath for uint8;
  using Address for address;

  /// EVENTS ///

  event PrepareCondition(bytes32 conditionId, bytes32 questionId, address oracle, uint positionCount);
  event ResolveCondition(bytes32 conditionId, address oracle, uint8 selectedIdx);
  
  event TakePosition(bytes32 indexed conditionId, address indexed positionBuyer, uint8 positionIdx, uint256 amount);
  event RedeemPosition(bytes32 indexed conditionId, address indexed positionBuyer, uint256 amount);
  event RedeemColleteral(address indexed pointOwner, address collateralToken, uint256 amount);

  /// STATE VARIABLES ///

  ISpoilerPoint public immutable spoilerPoint;
  IERC20 public immutable collateralToken;
  mapping(bytes32 => Condition) internal conditions;
  uint256 public minPositionLimits;
  uint256 public maxPositionLimits;

  constructor(address _spoilerPoint) Ownable(msg.sender) ERC1155("url"){
    // TODO: colleteral token and spoilerToken's backed token must be matched
    spoilerPoint = ISpoilerPoint(_spoilerPoint);
    collateralToken = IERC20(spoilerPoint.backedToken());
    maxPositionLimits = type(uint256).max;

    spoilerPoint.approve(address(spoilerPoint), type(uint256).max);
    collateralToken.approve(address(spoilerPoint), type(uint256).max);
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

  function getSelectedIdxByConditionId(bytes32 conditionId) external view returns (uint8) {
    return conditions[conditionId].selectedIndex;
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

  function takePosition(bytes32 conditionId, uint8 positionIdx, uint256 amount) external {
    Condition storage condition = conditions[conditionId];
    uint256 positionId = getPositionId(conditionId, positionIdx);
    require(condition.isInitialized == true, "SpoilerConditionalTokensV1: Not initialized");
    require(block.timestamp >= condition.startTimestamp && block.timestamp <= condition.endTimestamp, "SpoilerConditionalTokensV1: Condition not activated");
    uint256 positionAmount = balanceOf(msg.sender, positionId).add(amount);
    require(positionAmount >= minPositionLimits, "SpoilerConditionalTokensV1: Insufficient position amount");
    require(positionAmount <= maxPositionLimits, "SpoilerConditionalTokensV1: Exceed max position");

    IERC20(collateralToken).transferFrom(msg.sender, address(this), amount);
    spoilerPoint.issuePointTo(address(this), amount);
    _mint(msg.sender, positionId, amount, "");
    condition.positionTotalSupply[positionId] = condition.positionTotalSupply[positionId].add(amount);

    emit TakePosition(conditionId, msg.sender, positionIdx, amount);
  }

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
    spoilerPoint.transfer(msg.sender, redeemAmount);

    emit RedeemPosition(conditionId, msg.sender, redeemAmount);
  }

  function redeemColleteral(uint256 pointAmount) external {
    spoilerPoint.transferFrom(msg.sender, address(this), pointAmount);
    spoilerPoint.burnPointFrom(address(this), pointAmount);
    collateralToken.safeTransfer(msg.sender, pointAmount);

    emit RedeemColleteral(msg.sender, address(collateralToken), pointAmount);
  }

}