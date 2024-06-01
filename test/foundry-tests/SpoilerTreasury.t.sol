pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/Vm.sol";
import "forge-std/console.sol";

import {SpoilerTreasury} from "../../contracts/SpoilerTreasury.sol";
import {MockERC20} from "../../contracts/mocks/MockERC20.sol";

contract SpoilerTreasuryTest is Test {
    address public deployerAddress;
    SpoilerTreasury public treasury;
    MockERC20 public mockERC20;

    function setUp() public {
        deployerAddress = makeAddr("deployer");
        vm.deal(deployerAddress, 100 ether);

        treasury = new SpoilerTreasury();
        mockERC20 = new MockERC20();
    }

    function test_addApprovedTokenDepositor() public {
        treasury.addApprovedTokenDepositor(deployerAddress);

        bool result = treasury.approvedTokenDepositor(deployerAddress);
    }

    function test_removeApprovedTokenDepositor() public {
        treasury.addApprovedTokenDepositor(deployerAddress);
        treasury.removeApprovedTokenDepositor(deployerAddress);

        bool result = treasury.approvedTokenDepositor(deployerAddress);

    }

    function test_setwithdrawActive() public {
        treasury.setwithdrawActive(true);

        bool result = treasury.withdrawActive();

    }

    function test_depositToken() public {
        mockERC20.mint(deployerAddress, 100 ether);
        mockERC20.approve(address(treasury), 100 ether);

        treasury.addApprovedTokenDepositor(deployerAddress);

        treasury.depositToken(address(mockERC20), 100 ether);

        uint256 balance = treasury.depositorTokenBalance(deployerAddress, address(mockERC20));

    }

    function test_withdrawToken() public {
        mockERC20.mint(deployerAddress, 100 ether);
        mockERC20.approve(address(treasury), 100 ether);

        treasury.addApprovedTokenDepositor(deployerAddress);
        treasury.depositToken(address(mockERC20), 100 ether);

        treasury.setwithdrawActive(true);

        treasury.withdrawToken(
            address(mockERC20),
            deployerAddress,
            100 ether
        );
    } 
  }


