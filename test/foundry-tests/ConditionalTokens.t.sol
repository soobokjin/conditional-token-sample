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
        collateralToken.mint(liquidityProviderAddress, 1000);

        ctf.prepareCondition(oracleAddress, questionId, 2);
    }

    function test_prepareCondition() public view {
        assertEq(
            2,
            ctf.getOutcomeSlotCount(
                ctf.getConditionId(oracleAddress, questionId, 2)
            )
        );
    }

    function test_splitPosition() public {
        // 담보물로 투자했을 때 담보물 만큼 position token 이 생성되는 지 체크
    }

    function test_mergePosition() public {
        // A, B -> A||B 로 merge 할 때 각 position token 개수 변동 확인
    }

    function test_redeemPosition() public {
        // A, B 에서 A 가 승리하도록 세팅후 oracle 제출 후 redeem 할 때 처리 확인
    }
}
