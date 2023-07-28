// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./Register.sol";
import "./Inventory.sol";
import "./Supplier.sol";
import "./OrderManagementDistributor.sol";

contract OrderManagementRetailer is Supplier {

    GenratesAndConversion public genCn;
    StakeHolderRegistration public registration;
    OrderManagementDistributor public omdistr;
    Inventroy public inventory;

    constructor(
        GenratesAndConversion _genCn,
        StakeHolderRegistration _registration,
        Inventroy _inventory,
        OrderManagementDistributor _omdistr
    ) {
       genCn = _genCn;
       registration = _registration;
       inventory = _inventory;
       omdistr = _omdistr;
    }

    mapping(address => Types.ProductHistoryRetail[]) internal productHistoryRetail;
    mapping(address => Types.PurchaseOrderHistoryR) internal purchaseProductsHistoryRetailer;
    mapping(string => Types.productAvailableManuf[]) internal sameProductLinkedWithRetailer;

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
    ) external view returns (Types.SupplierWithMaterialID[] memory) {
        return supplierPrices[materialId_];
    }

    //retailers calls this function
    function PurchaseProductByRetailer(
        address _distributorId,
        address _supplierrId,
        bytes32 _productId,
        uint256 _quantity
    )public _isRetailer(_distributorId) {

        Types.manfItem memory _purchaseProduct;
         
        // if(registration.getStakeHolderDetails(_distributorId).role == Types.StakeHolder.ManuFacturer){
        //     Types.manfItem memory _purchaseProductM = inventory.getmanufProductDetail(
        //     _distributorId,
        //     _productId
        // );
        // _purchaseProduct = _purchaseProductM;
        // }
        // else 
        if(registration.getStakeHolderDetails(_distributorId).role == Types.StakeHolder.distributors){
              Types.manfItem memory _purchaseProductD = omdistr.getDistributorProductsDetails(
            _distributorId,
            _productId
        );
        _purchaseProduct = _purchaseProductD;
        emit newevent(_purchaseProduct);
        }

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

        sameProductLinkedWithRetailer[_purchaseProduct.name].push(_productAvailableManuf); 
        
        Types.PurchaseOrderHistoryR memory purchaseOrderHistory_ = Types.PurchaseOrderHistoryR({
                retailerId: msg.sender,
                distributorId: _distributorId,
                supplierId: _supplierrId,
                product: _newProduct,
                orderTime: block.timestamp
            });

        Types.ProductHistoryRetail memory newProd_ = Types.ProductHistoryRetail({
            retailer: purchaseOrderHistory_
        });

        if (
            registration.getStakeHolderDetails(msg.sender).role ==
            Types.StakeHolder.retailers
        ) {
            productHistoryRetail[msg.sender].push(newProd_);
        }

        // Emiting event
        emit ProductPurchased(
            _distributorId,
            _productId,
            _quantity,
            block.timestamp,
            Types.State.pre_bookable
        );
    }

    //Accessible by - distributor
    function markProductReadyForShip(address _distributorId, bytes32 _manfProductID, uint256 _quantity)
        public _isDisributor(_distributorId)
    {
        Types.manfItem memory product_ = inventory.getmanufEachProductDetails(
            _distributorId,
            _manfProductID
        );
        product_.itemState = Types.State.ready_to_ship;
        emit ReadyForShip(_manfProductID, _quantity, product_.itemState);
    }

    //Accessible by - supplier
    function markProductPickedUpBySupplier(address _suuplierOwnAddress, address _DistributorID, bytes32 _prodId, uint256 _quantity)
        public
    {
        Types.manfItem memory product_ = inventory.getmanufEachProductDetails(
            _DistributorID,
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
        emit PickedUp(_DistributorID, _prodId, _quantity, product_.itemState);
    }

    //Accessible by - Distributor
    function markProductShipmentReleased(address _DistributorID, bytes32 _prodId, uint256 _quantity)
        public _isDisributor(_DistributorID)
    {
        Types.manfItem memory product_ = inventory.getmanufEachProductDetails(
            _DistributorID,
            _prodId
        );

        product_.quantity -= _quantity;
        product_.itemState = Types.State.SHIPMENT_RELEASED;

        emit ShipmentReleased(_prodId, product_.itemState);
    }

    //Accessible by - supplier
    function markProductDeliveredBySupplier(
        address _supplierOwnAddress,
        address _retailerID,
        bytes32 _prodId,
        uint256 _prodQuantity
    ) public _isSupplier(_supplierOwnAddress) {

        Types.manfItem memory fetchProduct = supplyManufItems[_supplierOwnAddress][_prodId];
        emit newevent(fetchProduct);

        supplyManufItems[_retailerID][_prodId] = (fetchProduct);
        supplyManufItemsInventory[_retailerID].push(fetchProduct);

        fetchProduct.quantity -= _prodQuantity;
        fetchProduct.itemState = Types.State.DELIVERED;
        
        emit MaterialDelivered(_prodId, fetchProduct.itemState);
    }


    //Accessible by -retailer
    function markProductRecievedByRetail(address _retailerID, bytes32 _prodId)
        public _isRetailer(_retailerID)
    {
        Types.manfItem memory _newMaterial = supplyManufItems[_retailerID][_prodId];  
        _newMaterial.itemState = Types.State.RECEIVED_SHIPMENT;
        emit ShipmentReceived(_prodId, Types.State.RECEIVED_SHIPMENT);
    }
    /*___________________________________________________*/
     
    function getRetailerProductsDetails(address _retailerID, bytes32 _prodId) public view returns(Types.manfItem memory){
        Types.manfItem memory _newMaterial = supplyManufItems[_retailerID][_prodId];
        return _newMaterial;
    }

    //@supplier and @retailer can checks raw materials from producer Inventory.
    function getRetailerProducts(address _retailerId) public view returns(Types.manfItem[] memory){
        return supplyManufItemsInventory[_retailerId];
    } 

    // onlyManufacturer()
    function getProductPurchaseHistory() public view returns(Types.ProductHistoryRetail[] memory){
        return  productHistoryRetail[msg.sender];
    }

    function getRetailerProductsByName(string memory _productName)
        external
        view
        returns (Types.productAvailableManuf[] memory)
    {
        return sameProductLinkedWithRetailer[_productName];
    }

    /*---------------------------------------------------*/

    function isDistributor(address _Daddress) public view returns (bool) {
        return
            registration.getStakeHolderDetails(_Daddress).role ==
            Types.StakeHolder.distributors;
    }

    function isRetailer(address _retailAddr) public view returns (bool) {
        return
            registration.getStakeHolderDetails(_retailAddr).role ==
            Types.StakeHolder.retailers;
    }

    function isSupplier(address _Saddress) public view returns (bool) {
        return
            registration.getStakeHolderDetails(_Saddress).role ==
            Types.StakeHolder.supplier;
    }

    /*---------------------------------------------------*/
    
   
    modifier _isDisributor(address _distAddr) {
      require(registration.getStakeHolderDetails(_distAddr).role ==
            Types.StakeHolder.distributors, "Distrubtor have't registered yet or only distributor have permission to call this function.");
      _;
    }

     modifier _isRetailer(address _retailAddr) {
      require(registration.getStakeHolderDetails(_retailAddr).role ==
            Types.StakeHolder.retailers, "retailers not registered yet or only retailers can calls this function");
      _;
    }

    modifier _isSupplier(address _suppAddr) {
      require(registration.getStakeHolderDetails(_suppAddr).role ==
            Types.StakeHolder.supplier, "supplier not registered yet or only supplier can calls this function");
      _;
    }

    /*_____________________________________________________*/
    function compareStrings(string memory a, string memory b)
        internal
        pure
        returns (bool)
    {
        return (keccak256(abi.encodePacked((a))) ==
            keccak256(abi.encodePacked((b))));
    }

}