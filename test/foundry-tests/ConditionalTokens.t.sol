pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/Vm.sol";
import "forge-std/console.sol";

import {MockERC20} from "../../contracts/mocks/MockERC20.sol";
import {ConditionalTokens} from "../../contracts/ConditionalTokens.sol";

contract ConditionalTokenTest is Test {
    address public deployerAddress;
    address public oracleAddress;
    address public liquidityProviderAddress;

    MockERC20 public collateralToken;

    ConditionalTokens public ctf;
    bytes32 public questionId = hex"1111";

    function setUp() public {
        deployerAddress = makeAddr("deployer");
        vm.deal(deployerAddress, 100 ether);
        oracleAddress = makeAddr("oracle");
        vm.deal(oracleAddress, 1 ether);
        liquidityProviderAddress = makeAddr("lp");
        vm.deal(liquidityProviderAddress, 1 ether);

        ctf = new ConditionalTokens();
        collateralToken = new MockERC20();
        collateralToken.mint(liquidityProviderAddress, 10000);

        ctf.prepareCondition(oracleAddress, questionId, 2);
    }

    function _getConditionId() public view returns (bytes32) {
        return ctf.getConditionId(oracleAddress, questionId, 2);
    }

    function _getCollectionId(uint256 indexSet) public view returns (bytes32) {
        return ctf.getCollectionId(bytes32(0), _getConditionId(), indexSet);
    }

    function _getPositionId(uint256 indexSet) public view returns (uint) {
        return ctf.getPositionId(collateralToken, _getCollectionId(indexSet));
    }

    function test_prepareCondition() public view {
        assertEq(2, ctf.getOutcomeSlotCount(_getConditionId()));
    }

    function test_splitPosition() public {
        // 담보물로 투자했을 때 담보물 만큼 position token 이 생성되는 지 체크
        uint256[] memory partition = new uint256[](2);
        partition[0] = 1;
        partition[1] = 2;

        vm.startPrank(liquidityProviderAddress);
        collateralToken.approve(address(ctf), 10000);
        ctf.splitPosition(
            collateralToken,
            bytes32(0),
            _getConditionId(),
            partition,
            10000
        );
        vm.stopPrank();

        assertEq(collateralToken.balanceOf(address(ctf)), 10000);
        assertEq(
            ctf.balanceOf(liquidityProviderAddress, _getPositionId(1)),
            10000
        );
        assertEq(
            ctf.balanceOf(liquidityProviderAddress, _getPositionId(2)),
            10000
        );
    }

    function test_mergePositionWhenPartitionIsTwo() public {
        // A, B -> A||B 로 merge 할 때 각 position token 개수 변동 확인
        uint256[] memory partition = new uint256[](2);
        partition[0] = 1;
        partition[1] = 2;

        vm.startPrank(liquidityProviderAddress);
        // additional mint
        collateralToken.mint(liquidityProviderAddress, 10000);
        collateralToken.approve(address(ctf), 20000);
        ctf.splitPosition(
            collateralToken,
            bytes32(0),
            _getConditionId(),
            partition,
            10000
        );
        assertEq(
            ctf.balanceOf(liquidityProviderAddress, _getPositionId(1)),
            10000
        );
        assertEq(
            ctf.balanceOf(liquidityProviderAddress, _getPositionId(2)),
            10000
        );

        ctf.mergePositions(
            collateralToken,
            bytes32(0),
            _getConditionId(),
            partition,
            10000
        );
        vm.stopPrank();

        assertEq(ctf.balanceOf(liquidityProviderAddress, _getPositionId(1)), 0);
        assertEq(ctf.balanceOf(liquidityProviderAddress, _getPositionId(2)), 0);
        assertEq(
            ctf.balanceOf(liquidityProviderAddress, _getPositionId(3)),
            0
        );
    }

    function test_redeemPosition() public {
        // 담보물로 투자했을 때 담보물 만큼 position token 이 생성되는 지 체크
        address winner = makeAddr("winner");
        vm.deal(winner, 1 ether);
        address loser = makeAddr("loser");
        vm.deal(loser, 1 ether);

        uint256[] memory partition = new uint256[](2);
        partition[0] = 1;
        partition[1] = 2;
        uint256[] memory oracleResult = new uint256[](2);
        oracleResult[0] = 1;
        oracleResult[1] = 0;

        vm.startPrank(liquidityProviderAddress);
        collateralToken.approve(address(ctf), 10000);
        ctf.splitPosition(
            collateralToken,
            bytes32(0),
            _getConditionId(),
            partition,
            10000
        );
        ctf.safeTransferFrom(
            liquidityProviderAddress,
            winner,
            _getPositionId(1),
            10000,
            ""
        );
        ctf.safeTransferFrom(
            liquidityProviderAddress,
            loser,
            _getPositionId(2),
            10000,
            ""
        );
        vm.stopPrank();

        vm.prank(oracleAddress);
        ctf.reportPayouts(questionId, oracleResult);

        vm.startPrank(winner);
        ctf.redeemPositions(
            collateralToken,
            bytes32(0),
            _getConditionId(),
            partition
        );
        vm.stopPrank();

        vm.startPrank(loser);
        ctf.redeemPositions(
            collateralToken,
            bytes32(0),
            _getConditionId(),
            partition
        );
        vm.stopPrank();
        assertEq(collateralToken.balanceOf(winner), 10000);
        assertEq(collateralToken.balanceOf(loser), 0);
    }
}
