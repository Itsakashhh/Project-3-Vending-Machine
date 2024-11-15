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


    function testFullDeletionWithItemIdsAdjustment() public {
        // Add two items
        vm.prank(owner);
        vendingMachine.addItem(1001, 0.01 ether, 10);
        vm.prank(owner);
        vendingMachine.addItem(1002, 0.02 ether, 5);

        // Fully delete the first item (itemId 1001)
        vm.prank(owner);
        vendingMachine.deleteItem(1001, 10);

        // Check that item 1001 has been removed and item 1002 remains in itemIds
        uint256[] memory itemIds = vendingMachine.getItemIds();
        assertEq(itemIds.length, 1, "itemIds length should be 1 after deletion");
        assertEq(itemIds[0], 1002, "Remaining itemId should be 1002 after deletion of 1001");
    }

    function testPartialDeletion() public {
        // Add an item
        vm.prank(owner);
        vendingMachine.addItem(1001, 0.01 ether, 10);

        // Partially delete the item by removing a quantity of 5
        vm.prank(owner);
        vendingMachine.deleteItem(1001, 5);

        // Check that the quantity is reduced but item is not fully deleted
        (uint256 price, uint256 quantity) = vendingMachine.items(1001);
        assertEq(price, 0.01 ether, "Price should remain the same after partial deletion");
        assertEq(quantity, 5, "Quantity should be reduced to 5 after partial deletion");

        // Verify itemId is still in itemIds array
        uint256[] memory itemIds = vendingMachine.getItemIds();
        bool itemIdFound = false;
        for (uint256 i = 0; i < itemIds.length; i++) {
            if (itemIds[i] == 1001) {
                itemIdFound = true;
                break;
            }
        }
        assertTrue(itemIdFound, "Item ID should still be present in itemIds array after partial deletion");
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

    function testCheckFunds() public {
        // Step 1: Add an item to the vending machine
        vm.prank(owner);
        vendingMachine.addItem(1001, 0.01 ether, 10);

        // Step 2: Fund the buyer and make a purchase to increase contract balance
        vm.prank(buyer);
        vm.deal(buyer, 1 ether); // Give the buyer some ether for the test
        vendingMachine.buyItem{value: 0.02 ether}(1001, 2); // Buyer purchases 2 items at 0.01 ether each

        // Step 3: Check the vending machine's balance
        uint256 balance = vendingMachine.checkFunds();
        assertEq(balance, 0.02 ether, "Balance should be 0.02 ether after purchase");
    }

    



}
