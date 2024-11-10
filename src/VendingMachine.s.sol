// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VendingMachine {
    // Struct to store item details
    struct Item {
        uint256 price;
        uint256 quantity;
    }

    // Mapping to store items by their IDs
    mapping(uint256 => Item) public items;
    uint256[] private itemIds; // Array to track item IDs
    
    // Address of the contract owner
    address public owner;

    // Event to log purchases
    event Purchase(address indexed buyer, uint256 itemId, uint256 amount);

    // Modifier to restrict access to owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Not the contract owner");
        _;
    }

    // Constructor to set the contract owner
    constructor() {
        owner = msg.sender;
    }

    //Function to add new items and exciting Items
    function addItem(uint256 itemId, uint256 price, uint256 quantity) public onlyOwner {
        // Only push new itemId if it's a new item
        if (items[itemId].quantity == 0 && items[itemId].price == 0) {
            itemIds.push(itemId);
        }
        items[itemId].price = price;
        items[itemId].quantity += quantity;
    }


    // Function to buy an item
    function buyItem(uint256 itemId) public payable {
        Item storage item = items[itemId];

        // Check if the item exists and is in stock
        require(item.quantity > 0, "Item out of stock");
        require(msg.value >= item.price, "Insufficient payment");

        // Decrease the quantity and process the purchase
        item.quantity--;
        
        // Emit a purchase event
        emit Purchase(msg.sender, itemId, msg.value);

        // Refund any excess Ether sent
        if (msg.value > item.price) {
            payable(msg.sender).transfer(msg.value - item.price);
        }
    }

    // Function for the owner to withdraw funds
    function withdrawFunds() public onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    //function to check balance.    
    function checkFunds() public view returns (uint256) {
        return address(this).balance;
    }

     // Function to delete a specific item by ID
    function deleteItem(uint256 itemId, uint256 quantityToRemove) public onlyOwner {
        Item storage item = items[itemId];
        require(item.price != 0 || item.quantity != 0, "Item does not exist");
        require(quantityToRemove > 0, "Quantity to remove must be greater than zero");
        require(item.quantity >= quantityToRemove, "Not enough quantity to delete");

        if (item.quantity == quantityToRemove) {
            // Remove the item fully if quantity matches
            delete items[itemId];

            // Remove itemId from itemIds array using swap-and-pop
            uint256 length = itemIds.length;
            for (uint256 i = 0; i < length; i++) {
                if (itemIds[i] == itemId) {
                    itemIds[i] = itemIds[length - 1];
                    itemIds.pop();
                    break;
                }
            }
        } else {
            // Otherwise, just reduce the quantity
            item.quantity -= quantityToRemove;
        }
    }

     // Function to get a list of all item IDs that are in stock
    function getItemsInStock() public view returns (uint256[] memory) {
        uint256 length = itemIds.length;
        uint256 count = 0;

        // Step 1: Count items in stock to determine array size
        for (uint256 i = 0; i < length; i++) {
            if (items[itemIds[i]].quantity > 0) {
                count++;
            }
        }

        // Step 2: Populate in-stock items into an array of the exact size needed
        uint256[] memory inStockItems = new uint256[](count);
        uint256 index = 0;
        for (uint256 i = 0; i < length; i++) {
            if (items[itemIds[i]].quantity > 0) {
                inStockItems[index] = itemIds[i];
                index++;
            }
        }

        return inStockItems;
    }

      // Helper function to get the list of all item IDs
    function getItemIds() public view returns (uint256[] memory) {
        return itemIds;
    }

}



