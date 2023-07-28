// SPDX-License-Identifier: MIT
pragma solidity >=0.4.25 <0.9.0;

library Types {
   
   enum StakeHolder {      //currently we have only 2 stakeholder so, that's why I'm using  
        Producer, //0 for producer.
        ManuFacturer, // 1 for manfacturer at the registeration time.
        distributors, // 2
        retailers, // 3
        supplier,//4
        consumer //5
    }
    
    enum State {
        PRODUCED,   //0
        PROCESSED,  //1
        ready_to_ship,  //2
        pre_bookable,   //3
        PICKUP,     //4
        SHIPMENT_RELEASED,  //5 
        RECEIVED_SHIPMENT,  //6
        DELIVERED,  //7
        READY_FOR_SALE, //8
        SOLD    //9
    }

        //stakeholder details
    struct Stakeholder {
        StakeHolder role;
        address id_;
        string name;
        string email;
        uint256 MobNo;
        bool IsRegistered;
        string country;
        string city;
        // address distributorID;
        // address retailerID;
        }

    //Product => RawMaterial
    struct Item {
        uint256 ArrayIndex; //flag for checking the availablity
        bytes32 PId; // => now we created an auto genrated uid for each product using product name!
        string MaterialName;
        uint256 AvailableDate;
        uint256 Quantity;
        uint256 ExpiryDate;
        uint256 Price;
        bool IsAdded; //flag for checking the availablity
        State itemState;
        uint256 prebookCount;
    }

    struct manfItem { 
        uint256 ArrIndex;        
        string name;
        bytes32 PId;
        string description;
        uint256 expDateEpoch;
        string barcodeId;
        uint256 quantity;
        uint256 price;
        uint256 weights;
        uint256 manDateEpoch;       //available date
        uint256 prebookCount;
        State itemState;
    }

    struct UserHistory {
        address id_;
        manfItem Product_;
        uint256 orderTime_;  
    }

    struct productAvailableManuf {
        address id;
        string  productName;
        bytes32 productID;
        uint256 quantity;
        uint256 price;
        uint256 availableDate;
        uint256 weights;
        uint256 expDateEpoch;
    }

    struct SupplierWithMaterialID  {
        // uint256 ArrInd_;
        address id_; // account Id of the user
        // bool itemExists_;
        bytes32 itemId_;// Added, Purchased date in epoch in UTC timezone
        uint256 supplyprice_;
    }

    struct PurchaseOrderHistoryM {
        address manufacturerid;
        address supplierId;
        address producerId;
        Item rawMaterial;
        uint256 orderTime;  
    }

    struct PurchaseOrderHistoryD {
        address distributorId;
        address manufacturerid;
        address supplierId;
        manfItem product;
        uint256 orderTime;  
    }

    
    struct PurchaseOrderHistoryR {
        address retailerId;
        address distributorId;
        address supplierId;
        manfItem product;
        uint256 orderTime;  
    }
       
    struct MaterialHistory {
        PurchaseOrderHistoryM manufacturer;    
    }            

    struct ProductHistory   {    
        PurchaseOrderHistoryD distributor;
    }

    struct ProductHistoryRetail {    
        PurchaseOrderHistoryR retailer;
    }

}