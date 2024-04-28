pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/Vm.sol";
import "forge-std/console.sol";

import {MockERC20} from "../../contracts/mocks/MockERC20.sol";
import {Condition, SpoilerConditionalTokensV1} from "../../contracts/SpoilerConditionalTokensV1.sol";
import {SpoilerPoint} from "../../contracts/SpoilerPoint.sol";

contract SpoilerConditionalTokensV1Test is Test {
  address public deployerAddress;
  address public oracleAddress;

  MockERC20 public collateralToken;

  SpoilerConditionalTokensV1 public sct;
  SpoilerPoint public sp;
  bytes32 public questionId = hex"1111";

  function setUp() public { 
    deployerAddress = makeAddr("deployer");
    vm.deal(deployerAddress, 100 ether);
    oracleAddress = makeAddr("oracle");
    vm.deal(oracleAddress, 1 ether);

    collateralToken = new MockERC20();
    sp = new SpoilerPoint(collateralToken);
    sct = new SpoilerConditionalTokensV1(address(sp));
    
    sct.prepareCondition(collateralToken, oracleAddress, questionId, 2, 1000, 3000);
    sp.addApprovedTokenIssuer(address(sct));
  }

  // 다른 쪽에 베팅한 유저가 0 명이라도 해도 redeem 이 가능해야 함

  function _mintAndApproveColleteral(address to, uint256 amount) private {
    collateralToken.mint(to, amount);
    
    vm.prank(to);
    collateralToken.approve(address(sct), amount);
  }
  
  function _getConditionId() public view returns(bytes32) {
    return sct.getConditionId(oracleAddress, questionId);
  }

  function test_prepareCondition() public view {
    bool initialized = sct.isInitialized(sct.getConditionId(oracleAddress, questionId));
    (uint256 start, uint256 end) = sct.getTimestampsByConditionId(sct.getConditionId(oracleAddress, questionId));

    assertEq(initialized, true);
    assertEq(start, 1000);
    assertEq(end, 3000);
  }


  function test_takePositionNotInitialized() public {
    address userA = makeAddr("userA");
    _mintAndApproveColleteral(userA, 10000);
    bytes32 conditionId = bytes32(0);

    vm.prank(userA);
    vm.expectRevert("SpoilerConditionalTokensV1: Not initialized");
    sct.takePosition(conditionId, 0, 10000);
  }

  function test_takePositionWhenBeforeActivated() public {
    address userA = makeAddr("userA");
    _mintAndApproveColleteral(userA, 10000);
    bytes32 conditionId = _getConditionId();

    vm.prank(userA);
    vm.expectRevert("SpoilerConditionalTokensV1: Condition not activated");
    sct.takePosition(conditionId, 0, 10000);
  }


  function test_takePosition() public {
    address userA = makeAddr("userA");
    bytes32 conditionId = _getConditionId();
    _mintAndApproveColleteral(userA, 10000);

    skip(1500);
    vm.startPrank(userA);
    sct.takePosition(conditionId, 0, 10000);
    vm.stopPrank();

    assertEq(collateralToken.balanceOf(userA), 0);
    assertEq(collateralToken.balanceOf(address(sct)), 0);
    assertEq(collateralToken.balanceOf(address(sp)), 10000);
    assertEq(sct.balanceOf(userA, sct.getPositionId(conditionId, 0)), 10000);
    assertEq(sct.getPositionTotalSupply(conditionId, 0), 10000);
    assertEq(sct.getPositionTotalSupply(conditionId, 1), 0);
    assertEq(sp.balanceOf(address(sct)), 10000);
  }

  function test_redeemPosition() public {
    address winUserA = makeAddr("winUserA");
    _mintAndApproveColleteral(winUserA, 10000);
    address winUserB = makeAddr("winUserB");
    _mintAndApproveColleteral(winUserB, 10000);
    address loseUserC = makeAddr("loseUserC");
    _mintAndApproveColleteral(loseUserC, 10000);

    skip(1500);
    vm.startPrank(winUserA);
    sct.takePosition(_getConditionId(), 0, 10000);
    vm.stopPrank();
    vm.startPrank(winUserB);
    sct.takePosition(_getConditionId(), 0, 10000);
    vm.stopPrank();
    vm.startPrank(loseUserC);
    sct.takePosition(_getConditionId(), 1, 10000);
    vm.stopPrank();

    skip(1500);
    vm.startPrank(oracleAddress);
    sct.resolve(questionId, 0);
    vm.stopPrank();

    vm.startPrank(winUserA);
    sct.redeemPosition(_getConditionId());
    vm.stopPrank();
    vm.startPrank(winUserB);
    sct.redeemPosition(_getConditionId());
    vm.stopPrank();
    vm.startPrank(loseUserC);
    sct.redeemPosition(_getConditionId());
    vm.stopPrank();

    assertEq(collateralToken.balanceOf(winUserA), 0);
    assertEq(collateralToken.balanceOf(winUserB), 0);
    assertEq(collateralToken.balanceOf(loseUserC), 0);
    assertEq(collateralToken.balanceOf(address(sct)), 0);
    assertEq(collateralToken.balanceOf(address(sp)), 30000);

    assertEq(sp.balanceOf(address(sct)), 0);
    assertEq(sp.balanceOf(winUserA), 15000);
    assertEq(sp.balanceOf(winUserB), 15000);
    assertEq(sp.balanceOf(loseUserC), 0);
  }

  function test_redeemColleteral() public {
    address winUserA = makeAddr("winUserA");
    _mintAndApproveColleteral(winUserA, 10000);
    address loseUserC = makeAddr("loseUserC");
    _mintAndApproveColleteral(loseUserC, 10000);

    skip(1500);
    vm.startPrank(winUserA);
    sct.takePosition(_getConditionId(), 0, 10000);
    vm.stopPrank();
    vm.startPrank(loseUserC);
    sct.takePosition(_getConditionId(), 1, 10000);
    vm.stopPrank();

    skip(1500);
    vm.startPrank(oracleAddress);
    sct.resolve(questionId, 0);
    vm.stopPrank();

    vm.startPrank(winUserA);
    sct.redeemPosition(_getConditionId());
    vm.stopPrank();
    vm.startPrank(loseUserC);
    sct.redeemPosition(_getConditionId());
    vm.stopPrank();

    assertEq(collateralToken.balanceOf(winUserA), 0);
    assertEq(collateralToken.balanceOf(loseUserC), 0);
    assertEq(collateralToken.balanceOf(address(sct)), 0);
    assertEq(collateralToken.balanceOf(address(sp)), 20000);
    assertEq(sp.balanceOf(address(sct)), 0);
    assertEq(sp.balanceOf(winUserA), 20000);
    assertEq(sp.balanceOf(loseUserC), 0);

    vm.startPrank(winUserA);
    sp.approve(address(sct), 20000);
    sct.redeemColleteral(20000);
    vm.stopPrank();

    assertEq(collateralToken.balanceOf(winUserA), 20000);
    assertEq(collateralToken.balanceOf(address(sct)), 0);
    assertEq(collateralToken.balanceOf(address(sp)), 0);
    assertEq(sp.balanceOf(address(sct)), 0);
    assertEq(sp.balanceOf(winUserA), 0);
  }
}