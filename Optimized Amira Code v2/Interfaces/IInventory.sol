// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "../Library.sol";

interface IInventroy  {
    
    //added raw material for creating Inventory at the producer end!
    function addRawMaterial(
        string memory _materialname,
        uint256 _quantity,
        uint256 _availableDate,
        uint256 _expiryDate,
        uint256 _price
    ) external; 

    // Function to update the quantity and price of a raw material from producer side!
    function updateRawMaterial(
        bytes32 _pid,
        uint256 _quantity,
        uint256 _availableDate,
        uint256 _expiryDate,
        uint256 _price
    ) external; 
    
    // return all the Inventory function with modify one too
    // this function also used at manufacturer side too.
    function getItems(address _producerID)
        external
        view
        returns (Types.Product[] memory);

    function getProductDetails(bytes32 _prodId)
        external
        view
        returns (Types.Product memory);

    //forchecking Inventory producer can check Inventroy is added or not by passing product name.
    function IsAddedInInventory(string memory _materialName, bytes32 _pid)
        external
        view
        returns (bool);

}
