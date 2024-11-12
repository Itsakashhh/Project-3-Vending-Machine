// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {VendingMachine} from "../src/VendingMachine.s.sol";

contract VendingMachineTest is Test {
    VendingMachine vendingMachine;
    address owner = address(0x1);
    address buyer = address(0x2);

    function setUp() public {
        vm.prank(owner);
        vendingMachine = new VendingMachine();
    }

    function testAddItem() public {
        vm.prank(owner);
        vendingMachine.addItem(1001, 0.01 ether, 10);
        (uint256 price, uint256 quantity) = vendingMachine.items(1001);
        assertEq(price, 0.01 ether, "Price should match");
        assertEq(quantity, 10, "Quantity should match");
    }

    function testBuyItem() public {
        // Add item by owner
        vm.prank(owner);
        vendingMachine.addItem(1001, 0.01 ether, 10);

        // Buyer purchases the item
        vm.deal(buyer, 0.05 ether); // Fund buyer with some ether
        vm.prank(buyer);
        vendingMachine.buyItem{value: 0.02 ether}(1001, 2);

        // Check item stock after purchase
        (, uint256 remainingQuantity) = vendingMachine.items(1001);
        assertEq(remainingQuantity, 8, "Remaining quantity should be correct");

        // Check buyer's purchase history
        uint256 purchasedQty = vendingMachine.buyerPurchases(buyer, 1001);
        assertEq(purchasedQty, 2, "Buyer should have purchased 2 items");
    }

    function testWithdrawFunds() public {
    // Add item and have the buyer purchase it to fund the contract
    vm.deal(buyer, 0.5 ether); // Fund buyer with some ether
    vm.prank(owner);
    vendingMachine.addItem(1001, 0.01 ether, 10);
    vm.prank(buyer);
    vendingMachine.buyItem{value: 0.01 ether}(1001, 1);

    // Check the contract balance before withdrawal
    uint256 contractBalanceBefore = address(vendingMachine).balance;
    assertGt(contractBalanceBefore, 0, "Contract balance should be greater than zero");

    // Owner withdraws funds
    uint256 initialOwnerBalance = owner.balance;
    vm.prank(owner);
    vendingMachine.withdrawFunds();

    // Check the contract balance after withdrawal
    uint256 contractBalanceAfter = address(vendingMachine).balance;
    assertEq(contractBalanceAfter, 0, "Contract balance should be zero after withdrawal");

    // Confirm the owner's balance has increased
    uint256 finalOwnerBalance = owner.balance;
    assertGt(finalOwnerBalance, initialOwnerBalance, "Owner balance should increase after withdrawal");
}


    function testDeleteItem() public {
        vm.prank(owner);
        vendingMachine.addItem(1001, 0.01 ether, 10);

        // Delete item with quantity to remove
        vm.prank(owner);
        vendingMachine.deleteItem(1001, 10);

        (uint256 price, uint256 quantity) = vendingMachine.items(1001);
        assertEq(price, 0, "Price should be zero after deletion");
        assertEq(quantity, 0, "Quantity should be zero after deletion");
    }

    function testGetBuyerPurchases() public {
        vm.startPrank(owner);
        vendingMachine.addItem(1001, 0.01 ether, 10);
        vendingMachine.addItem(1002, 0.02 ether, 5);
        vm.stopPrank();

        // Buyer purchases items
        vm.deal(buyer, 0.05 ether);
        vm.startPrank(buyer);
        vendingMachine.buyItem{value: 0.03 ether}(1001, 2);
        vendingMachine.buyItem{value: 0.02 ether}(1002, 1);
        vm.stopPrank();

        // Get buyer's purchase details
        (uint256[] memory ids, uint256[] memory quantities) = vendingMachine.getBuyerPurchases(buyer);

        // Check that returned IDs and quantities are correct
        assertEq(ids.length, 2, "Should return two item IDs");
        assertEq(ids[0], 1001, "First ID should match");
        assertEq(ids[1], 1002, "Second ID should match");
        assertEq(quantities[0], 2, "First quantity should match");
        assertEq(quantities[1], 1, "Second quantity should match");
    }
}
