// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./Library.sol";
import "./Register.sol";


contract Supplier {

    Types.SupplierWithMaterialID[] internal supplierWithMaterialID;
    mapping(bytes32 => Types.SupplierWithMaterialID[]) public supplierPrices;
    // mapping(address => mapping(bytes32 => Types.SupplierWithMaterialID[])) public supplierPrices2;
    

    mapping(address =>mapping(bytes32 => Types.Item)) public supplyItems;
    mapping(address => Types.Item[]) public supplyItemsInventory;
    mapping(address =>mapping(bytes32 => Types.manfItem)) public supplyManufItems;
    mapping(address => Types.manfItem[]) public supplyManufItemsInventory;
    event supplierSet(
        address id_, // account Id of the user
        bytes32 productid_,
        uint256 supplyprice_,
        uint256 requestCreationTime_
    );
 
function supplierSetMaterialIDandPrice(bytes32 Itemid_, uint256 supplyprice_) public {
    Types.SupplierWithMaterialID memory supplierMaterialID_ = Types.SupplierWithMaterialID({
        // ArrInd_: supplierPrices[Itemid_].length, 
        id_: msg.sender,
        // itemExists_ : true,
        itemId_: Itemid_,
        supplyprice_: supplyprice_
    });

        supplierWithMaterialID.push(supplierMaterialID_);
        supplierPrices[Itemid_].push(supplierMaterialID_);
        emit supplierSet(msg.sender, Itemid_, supplyprice_, block.timestamp);

    // Types.SupplierWithMaterialID[] storage suppliers = supplierPrices[Itemid_];
    // uint256 index = supplier.ArrInd_;
    
    // if (supplierPrices[Itemid_].id_ == address(msg.sender)) {
    //     supplierWithMaterialID.push(supplierMaterialID_);
    //     supplierPrices[Itemid_].push(supplierMaterialID_);
    // }
    
    emit supplierSet(msg.sender, Itemid_, supplyprice_, block.timestamp);
}
}
