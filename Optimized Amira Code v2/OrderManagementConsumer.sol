// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./Register.sol";
import "./Inventory.sol";
import "./Supplier.sol";
import "./OrderManagementRetailer.sol";

contract OrderManagementConsumer is Supplier {

    GenratesAndConversion public genCn;
    StakeHolderRegistration public registration;
    OrderManagementRetailer public omretlier;
    Inventroy public inventory;

    constructor(
        GenratesAndConversion _genCn,
        StakeHolderRegistration _registration,
        OrderManagementRetailer _omretlier,
        Inventroy _inventory
    ) {
       
       genCn = _genCn;
       registration = _registration;
       omretlier = _omretlier;
       inventory = _inventory;
    }

    // mapping(address => Types.MaterialHistory[]) internal materialHistory;
    mapping(address => Types.PurchaseOrderHistoryM) internal purchasematerialsHistory;

    mapping(address => uint256) internal supllierTotalprice;

  event ReadyForShip(bytes32 productId, uint256 quantity,Types.State _itemState);    //User Before purchase request creation.
    event PickedUp(address producerID, bytes32 prodId, uint256 quantity, Types.State _itemState);  //supplier after purchase request at the manufacturer end
    event ShipmentReleased(bytes32 productId, Types.State _itemState);
    event ShipmentReceived(bytes32 productId, Types.State _itemState);  //manufacturer after order(material) received
    event Sold(bytes32 productId, Types.State _itemState);  //when user created the request
    event MaterialDelivered(bytes32 productId, Types.State _itemState);    //
    event AgreedWithData(
            address _consumerAddress,
            uint256 _supplyAmount,
            uint256 _deliveryDate
            );

    event ProductPurchasedRequest(
        address _producerId,
        bytes32 _productId,
        uint256 _quantity,
        uint256 _orderTime,
        Types.State _itemState,
        uint256 _totalAmount
    );
    event newevent(Types.manfItem);
  
    /*@consumer creating request for product*/
    //creates a material request through the function
    function createRequest (
        string memory _materialName, //prod unique ID
        uint256 _quantity,
        uint256 _deliveryDate
    ) external view returns (Types.SupplierWithMaterialID[] memory) {     
        bytes32 materialId_ = genCn.genrateUniqueIDByProductName(_materialName);   
        return supplierPrices[materialId_];
    }


    //Consumer calls this function
    function PurchaseProduct(
        address _retailerId,
        address _supplierId,
        bytes32 _ItemId,
        uint256 _quantity
    ) public {

        Types.manfItem memory _purchaseProduct = omretlier.getRetailerProductsDetails(
            _retailerId,
            _ItemId
        );

        //first fetch the product from the retailer Inventory.
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

        // supplyManufItems[_supplierId][_purchaseProduct.PId] = _newProduct;
        // supplyManufItemsInventory[_supplierId].push(_newProduct);

        // uint256 supplierPrice = supplierPrices[_ItemId].supplyprice_;
        uint256 payableAmount = (_purchaseProduct.price * _quantity);
        
        // Emiting event
        emit ProductPurchasedRequest(
            _retailerId,
            _ItemId,
            _quantity,
            block.timestamp,
            Types.State.SOLD,
            payableAmount
        );
    }

    //@Supplier calls this function 
    function supplierGenratedAgreedwithDate(address _consumerAddress, address _retailerAddress, bytes32 _manfProductID, uint256 _supplyTotalAmount, uint _deliveryDate) public {
    
        Types.manfItem memory product_ = omretlier.getRetailerProductsDetails(
            _retailerAddress,
            _manfProductID
        );

        product_.itemState = Types.State.PROCESSED;
        supllierTotalprice[_consumerAddress] = _supplyTotalAmount;
        
        emit AgreedWithData(
                _consumerAddress,
                _supplyTotalAmount,
                _deliveryDate
            );
    }

    // @consumer after agreed 
    function OrderGenarted( 
        address payable _retailerId,
        address _supplierId,
        bytes32 _ItemId,
        uint256 _quantity)
         public payable {
        
        Types.manfItem memory _purchaseProduct = omretlier.getRetailerProductsDetails(
            _retailerId,
            _ItemId
        );

         uint256 payableAmount = (_purchaseProduct.price * _quantity);
         uint256 supplyTotalAmount = supllierTotalprice[_supplierId]; 

        // Transfer money to farmer 
        _retailerId.transfer(payableAmount+supplyTotalAmount);
    }


    //Accessible by - retailer
    function markMaterialReadyForShip(bytes32 _prodId, uint256 _quantity) public
    {
        Types.manfItem memory product_ = omretlier.getRetailerProductsDetails(
            msg.sender,
            _prodId
        );
        product_.itemState = Types.State.ready_to_ship;
        emit ReadyForShip(_prodId, _quantity, product_.itemState);
    }

    //Accessible by - supplier
    function markMaterialReadyPickedUp(address _supplierOwnAddress, address _retailerID, bytes32 _prodId, uint256 _quantity)
        public
    {
        Types.manfItem memory product_ = omretlier.getRetailerProductsDetails(
            _retailerID,
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

        supplyManufItems[_supplierOwnAddress][_prodId] = _newProduct;
        supplyManufItemsInventory[_supplierOwnAddress].push(_newProduct);
        emit PickedUp(_retailerID, _prodId, _quantity, product_.itemState);
    }

     //Accessible by - retailer
    function markProductShipmentReleased(address _retailerID, bytes32 _prodId, uint256 _quantity)
        public _isRetailer(_retailerID)
    {
        Types.manfItem memory product_ = inventory.getmanufEachProductDetails(
            _retailerID,
            _prodId
        );

        product_.quantity -= _quantity;
        product_.itemState = Types.State.SHIPMENT_RELEASED;

        emit ShipmentReleased(_prodId, product_.itemState);
    }

    //Accessible by - supplier/
    function markMaterialDelivered(
        address _consumerAddress,
        address _retailerID,
        bytes32 _prodId,
        uint256 _matQuantity
    ) public _isConsumer(_consumerAddress) {

        Types.manfItem memory fetchProduct = supplyManufItems[_retailerID][_prodId];
        emit newevent(fetchProduct);

        supplyManufItems[_retailerID][_prodId] = (fetchProduct);
        supplyManufItemsInventory[_retailerID].push(fetchProduct);

        fetchProduct.itemState = Types.State.DELIVERED;
        fetchProduct.quantity -= _matQuantity;
        
        emit MaterialDelivered(_prodId, fetchProduct.itemState);
    }

    //Accessible by -consumer
    function markMaterialsRecieved(address _consumerAdd, address _retailerID, bytes32 _prodId)
        public _isConsumer(_consumerAdd)
    {
        Types.manfItem memory _newMaterial = supplyManufItems[_retailerID][_prodId];
        
        _newMaterial.itemState = Types.State.RECEIVED_SHIPMENT;
        emit ShipmentReceived(_prodId, Types.State.RECEIVED_SHIPMENT);
    }
    /*________________________________________________________________________*/
    
    //@supplier and @Maufacturer can checks raw materials from producer Inventory.
    function getConsumerProducts(address _Caddress) public _isConsumer(_Caddress) view returns(Types.Item[] memory){
        return supplyItemsInventory[_Caddress];
    } 

    /*_________________________________________________________________________*/

    
    function isRetailer(address _retailAddr) public view returns (bool) {
        return
            registration.getStakeHolderDetails(_retailAddr).role ==
            Types.StakeHolder.retailers;
    }

    function isConsumer(address _Caddress) public view returns (bool) {
        return
            registration.getStakeHolderDetails(_Caddress).role ==
            Types.StakeHolder.consumer;
    }

    function isSupplier(address _Saddress) public view returns (bool) {
        return
            registration.getStakeHolderDetails(_Saddress).role ==
            Types.StakeHolder.supplier;
    }

    /*---------------------------------------------------*/
    
   
     modifier _isRetailer(address _retailAddr) {
      require(registration.getStakeHolderDetails(_retailAddr).role ==
            Types.StakeHolder.retailers, "retailers not registered yet or only retailers can calls this function");
      _;
    }

     modifier _isConsumer(address _distAddr) {
      require(registration.getStakeHolderDetails(_distAddr).role ==
            Types.StakeHolder.consumer, "consumer have't registered yet or only consumer have permission to call this function.");
      _;
    }

    modifier _isSupplier(address _suppAddr) {
      require(registration.getStakeHolderDetails(_suppAddr).role ==
            Types.StakeHolder.supplier, "supplier not registered yet or only supplier can calls this function");
      _;
    }

}
