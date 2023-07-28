// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./Register.sol";
import "./Inventory.sol";
import "./Supplier.sol";

contract OrderManagementDistributor is Supplier {

    GenratesAndConversion public genCn;
    StakeHolderRegistration public registration;
    Inventroy public inventory;

    constructor(
        GenratesAndConversion _genCn,
        StakeHolderRegistration _registration,
        Inventroy _inventory
    ) {
       genCn = _genCn;
       registration = _registration;
       inventory = _inventory;
    }


    mapping(address => Types.ProductHistory[]) internal productHistory;
    mapping(address => Types.PurchaseOrderHistoryD) internal purchaseproductsHistory;

    mapping(string => Types.productAvailableManuf[]) internal sameproductLinkedWithDistributors;


    event ReadyForShip(bytes32 productId, uint256 quantity,Types.State _itemState);    //User Before purchase request creation.
    event PickedUp(address producerID, bytes32 prodId, uint256 quantity, Types.State _itemState);  //supplier after purchase request at the manufacturer end
    event ShipmentReleased(bytes32 productId, Types.State _itemState);
    event ShipmentReceived(bytes32 productId, Types.State _itemState);  //manufacturer after order(material) received
    event Sold(bytes32 productId, Types.State _itemState);  //when user created the request
    event MaterialDelivered(bytes32 productId, Types.State _itemState);    //
    event ProductPurchased(
        address _producerId,
        bytes32 _productId,
        uint256 _quantity,
        uint256 _orderTime,
        Types.State _itemState
    );
    event newevent(Types.manfItem);

    
     //creates a material request through the function
    function createRequest(
        bytes32 materialId_, //prod unique ID
        uint256 quantity_,
        uint256 availableDate_
    ) external view  returns (Types.SupplierWithMaterialID[] memory) {
        
        return supplierPrices[materialId_];
    }


    //Distributors calls this function
    function PurchaseProduct(
        address _manufactureId,
        address _supplierrId,
        bytes32 _productId,
        uint256 _quantity
    )public _isDisributor(msg.sender) {

        Types.manfItem memory _purchaseProduct = inventory.getmanufEachProductDetails(
            _manufactureId,
            _productId
        );

        emit newevent(_purchaseProduct);

        require(
            _purchaseProduct.quantity >= _quantity,
            "Insufficient inventory"
        );

        Types.manfItem memory _newProduct = Types.manfItem({
            ArrIndex: supplyManufItemsInventory[msg.sender].length,
            name: _purchaseProduct.name,
            PId: _purchaseProduct.PId,
            description: _purchaseProduct.description,
            expDateEpoch: _purchaseProduct.expDateEpoch,
            barcodeId: _purchaseProduct.barcodeId,
            quantity: _quantity,
            price: _purchaseProduct.price,
            weights: _purchaseProduct.weights,
            manDateEpoch: _purchaseProduct.manDateEpoch, //available date
            prebookCount: _quantity,
            itemState: Types.State.SOLD
        });

        // supplyManufItems[_supplierrId][_purchaseProduct.PId] = _newProduct;
        // supplyManufItemsInventory[_supplierrId].push(_newProduct);

        Types.productAvailableManuf memory _productAvailableManuf = Types.productAvailableManuf({
            id: msg.sender,
            productName: _purchaseProduct.name,
            productID: _purchaseProduct.PId,
            quantity: _quantity,
            price: _purchaseProduct.price,
            availableDate: _purchaseProduct.manDateEpoch,
            weights: _purchaseProduct.weights,
            expDateEpoch: _purchaseProduct.expDateEpoch
        });

        sameproductLinkedWithDistributors[_purchaseProduct.name].push(_productAvailableManuf); 

        Types.PurchaseOrderHistoryD memory purchaseOrderHistory_ = Types
            .PurchaseOrderHistoryD({
                distributorId: msg.sender,
                manufacturerid: _manufactureId,
                supplierId: _supplierrId,
                product: _newProduct,
                orderTime: block.timestamp
            });

        Types.ProductHistory memory newProd_ = Types.ProductHistory({
            distributor: purchaseOrderHistory_
        });


        if (
            registration.getStakeHolderDetails(msg.sender).role ==
            Types.StakeHolder.distributors
        ) {
            productHistory[msg.sender].push(newProd_);
        }

        // Emiting event
        emit ProductPurchased(
            _manufactureId,
            _productId,
            _quantity,
            block.timestamp,
            Types.State.pre_bookable
        );
    }

    //Accessible by - manufacturer
    function markProductReadyForShip(address _manufacturerAdd, bytes32 _manfProductID, uint256 _quantity)
        public _isManufacturer(_manufacturerAdd)
    {
        Types.manfItem memory product_ = inventory.getmanufEachProductDetails(
            _manufacturerAdd,
            _manfProductID
        );
        product_.itemState = Types.State.ready_to_ship;
        emit ReadyForShip(_manfProductID, _quantity, product_.itemState);
    }

    //Accessible by - supplier
    function markProductPickedUp(address _suuplierOwnAddress, address _manufacturerID, bytes32 _prodId, uint256 _quantity)
        public _isSupplier(_suuplierOwnAddress)
    {
        Types.manfItem memory product_ = inventory.getmanufEachProductDetails(
            _manufacturerID,
            _prodId
        );
        product_.itemState = Types.State.PICKUP;
        //after picking up product has been came in the supplier Inventory
         Types.manfItem memory _newProduct = Types.manfItem({
            ArrIndex: supplyManufItemsInventory[msg.sender].length,
            name: product_.name,
            PId: product_.PId,
            description: product_.description,
            expDateEpoch: product_.expDateEpoch,
            barcodeId: product_.barcodeId,
            quantity: _quantity,
            price: product_.price,
            weights: product_.weights,
            manDateEpoch: product_.manDateEpoch, //available date
            prebookCount: _quantity,
            itemState: Types.State.SOLD
        });
        emit newevent(_newProduct);

        supplyManufItems[_suuplierOwnAddress][_prodId] = _newProduct;
        supplyManufItemsInventory[_suuplierOwnAddress].push(_newProduct);
        emit PickedUp(_manufacturerID, _prodId, _quantity, product_.itemState);
    }

    //Accessible by - Manufacturer
    function markProductShipmentReleased(address _manufacturerID, bytes32 _prodId, uint256 _quantity)
        public _isManufacturer(_manufacturerID) 
    {
        Types.manfItem memory product_ = inventory.getmanufEachProductDetails(
            _manufacturerID,
            _prodId
        );

        product_.quantity -= _quantity;
        product_.itemState = Types.State.SHIPMENT_RELEASED;
        
        emit ShipmentReleased(_prodId, product_.itemState);
    }

    //Accessible by - supplier
    function markProductDelivered(
        address _supplierOwnAddress,
        address _distributorID,
        bytes32 _prodId,
        uint256 _prodQuantity
    ) public _isSupplier(_supplierOwnAddress) {

        Types.manfItem memory fetchProduct = supplyManufItems[_supplierOwnAddress][_prodId];
        emit newevent(fetchProduct);

        supplyManufItems[_distributorID][_prodId] = (fetchProduct);
        supplyManufItemsInventory[_distributorID].push(fetchProduct);

        fetchProduct.quantity -= _prodQuantity;
        fetchProduct.itemState = Types.State.DELIVERED;

        // emit MaterialDelivered(_prodId, Types.State.DELIVERED);
    }


    //Accessible by -Distributors
    function markProductsRecieved(address _distributorID, bytes32 _prodId)
        public _isDisributor(_distributorID)
    {
        Types.manfItem memory _newMaterial = supplyManufItems[_distributorID][_prodId];  
        
        _newMaterial.itemState = Types.State.RECEIVED_SHIPMENT;

        emit ShipmentReceived(_prodId, Types.State.RECEIVED_SHIPMENT);
    }

    /*________________________________________________________________________*/
    
    function getDistributorProductsDetails(address _distributorID, bytes32 _prodId) public view returns(Types.manfItem memory){
        Types.manfItem memory _newMaterial = supplyManufItems[_distributorID][_prodId];
        return _newMaterial;
    }

    //@supplier and @Maufacturer can checks raw materials from producer Inventory.
    function getDistributorProducts(address _distributorId) public view returns(Types.manfItem[] memory){
        return supplyManufItemsInventory[_distributorId];
    } 

    // onlyManufacturer()
    function getProductPurchaseHistory() public view returns(Types.ProductHistory[] memory){
        return productHistory[msg.sender];
    }

    function getDistributorProductsByName(string memory _productName)
        external
        view
        returns (Types.productAvailableManuf[] memory)
    {
        return sameproductLinkedWithDistributors[_productName];
    }
    
    /*_________________________________________________________________________*/

    
    function isManufacturer(address _Maddress) public view returns (bool) {
        return
            registration.getStakeHolderDetails(_Maddress).role ==
            Types.StakeHolder.ManuFacturer;
    }

    function isDistributor(address _Daddress) public view returns (bool) {
        return
            registration.getStakeHolderDetails(_Daddress).role ==
            Types.StakeHolder.distributors;
    }

    function isSupplier(address _Saddress) public view returns (bool) {
        return
            registration.getStakeHolderDetails(_Saddress).role ==
            Types.StakeHolder.supplier;
    }

    
    modifier _isManufacturer(address _manfAddr) {
      require(registration.getStakeHolderDetails(_manfAddr).role ==
            Types.StakeHolder.ManuFacturer, "manufcaturer not registered yet or only manufacturer can calls this function");
      _;
    }

    modifier _isDisributor(address _prodAddr) {
      require(registration.getStakeHolderDetails(_prodAddr).role ==
            Types.StakeHolder.distributors, "Distrubtor have't registered yet or only distributor have permission to call this function.");
      _;
    }

    modifier _isSupplier(address _suppAddr) {
      require(registration.getStakeHolderDetails(_suppAddr).role ==
            Types.StakeHolder.supplier, "supplier not registered yet or only supplier can calls this function");
      _;
    }
}
