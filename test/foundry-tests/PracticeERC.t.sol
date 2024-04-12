pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "forge-std/Vm.sol";
import "forge-std/console.sol";

import "../../contracts/interfaces/IUniswapV2Router02.sol";
import "../../contracts/interfaces/IUniswapV2Pair.sol";
import {PracticeERC} from "../../contracts/PracticeERC.sol";

// Fork test
contract PracticeTest is Test {
    uint256 goerliFork;

    PracticeERC practiceERC;
    
    address teamWallet = 0x37aAb97476bA8dC785476611006fD5dDA4eed66B;
    address revWallet = 0x90c858023Efd445fF8b8F11911Cff5f59863d61a;
    address treasuryWallet = 0xDa74C6B4E6813bdb83cb4cff6ad4eB8D43F34B0D;
    IUniswapV2Router02 uniswapV2Router =
        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    uint256 public constant MAX_UINT256 = type(uint256).max;
    uint256 public constant INITIAL_FRAGMENTS_SUPPLY = 25_000_000 * 10 ** 9;

    // TOTAL_GONS is a multiple of INITIAL_FRAGMENTS_SUPPLY so that _gonsPerFragment is an integer.
    // Use the highest value that fits in a uint256 for max granularity.
    // 딱 떨어지게 하기 위한 값인가?
    uint256 public constant TOTAL_GONS =
        MAX_UINT256 - (MAX_UINT256 % INITIAL_FRAGMENTS_SUPPLY);

    function setUp() public {
        goerliFork = vm.createSelectFork(
            vm.envString("ALCHEMY_TESTNET_URL")
        );
        practiceERC = new PracticeERC();
        console.log(MAX_UINT256);
        console.log(TOTAL_GONS);
        console.log(MAX_UINT256 % INITIAL_FRAGMENTS_SUPPLY);
        console.log(TOTAL_GONS / INITIAL_FRAGMENTS_SUPPLY);
    }

    function test_TotalSupply() public {
        assertEq(
            practiceERC.totalSupply(),
            practiceERC.balanceOf(address(practiceERC)) +
                practiceERC.balanceOf(address(this)) +
                practiceERC.balanceOf(treasuryWallet)
        );
    }

    function test_NotTransferBeforeLaunch() public {
        address user = address(0x14);
        practiceERC.transfer(user, 100);

        vm.prank(user); 
        vm.expectRevert("Trading not enabled");
        practiceERC.transfer(address(0x15), 100);        
    }

    function test_CanTransferBeforeLaunch() public {
        address transferableUser = address(0x14);
        practiceERC.transfer(transferableUser, 100);
        practiceERC.setTransferableBeforeLaunch(transferableUser, true);

        vm.prank(transferableUser);
        practiceERC.transfer(address(0x15), 100);

        assertEq(practiceERC.balanceOf(address(0x15)), 100);
    }

    function test_LimitsNotEffectBeforeLaunch() public {
        address transferableUser = address(0x14);
        uint256 exceedTransactionAmount = practiceERC.maxTransactionAmount() + 1000;
        practiceERC.transfer(transferableUser, exceedTransactionAmount);
        practiceERC.setTransferableBeforeLaunch(transferableUser, true);

        vm.prank(transferableUser);
        practiceERC.transfer(address(0x15), exceedTransactionAmount);

        assertEq(practiceERC.balanceOf(address(0x15)), exceedTransactionAmount);
    }

    function test_AddInitialLiquidity() public {
        practiceERC.addInitialLiquidity{value: 4 ether}();

        assertEq(practiceERC.isAutomatedMarketMakerPairs(practiceERC.uniswapV2Pair()), true);

        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = IUniswapV2Pair(practiceERC.uniswapV2Pair()).getReserves();
        console.log(reserve0);
        console.log(reserve1);
        console.log(blockTimestampLast);
    }


}
