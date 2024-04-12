/**
 * Deploy
 *
 * Transfer
 *
 * allowance
 */

pragma solidity ^0.8.9;

import "forge-std/Test.sol";
import "forge-std/Vm.sol";
import "forge-std/console.sol";

import "../../contracts/Erc.sol";

contract ErcTest is Test {
    VectorERC vectorErc;
    address alice;

    receive() external payable {}

    function setUp() public {
        alice = address(0x1);
        hoax(alice, 100 ether);

        vectorErc = new VectorERC(9, 1000);

        console.log(alice.balance);
    }

    function test_Balance() public {
        uint256 balance = vectorErc.balanceOf(address(alice));

        assertEq(balance, 1000 * 10 ** 9);
    }

    function test_Transfer() public {
        vm.prank(alice);
        vectorErc.transfer(address(0x2), 500 * 10 ** 9);

        assertEq(vectorErc.balanceOf(address(0x2)), 500 * 10 ** 9);
        console.log(address(this).balance);
        console.log(address(0x1).balance);
        console.log(address(0x2).balance);
    }

    function test_ApproveAndTransfer() public {}
}
