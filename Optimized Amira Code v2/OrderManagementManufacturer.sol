// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;


import "./Register.sol";
import "./Inventory.sol";
import "./Supplier.sol";


contract OrderManagementManufacturer is Supplier {

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

    
    mapping(address => Types.MaterialHistory[]) internal materialHistory;
    mapping(address => Types.PurchaseOrderHistoryM) internal purchasematerialsHistory;

    event ReadyForShip(bytes32 productId, uint256 quantity,Types.State itemState);    //User Before purchase request creation.
    event PickedUp(address producerID, bytes32 prodId, uint256 quantity,Types.State itemState);  //supplier after purchase request at the manufacturer end
    event ShipmentReleased(bytes32 productId);
    event ShipmentReceived(bytes32 productId);  //manufacturer after order(material) received
    event Sold(bytes32 productId);  //when user created the request
    event MaterialDelivered(bytes32 productId);    //
    event RawMaterialsPurchased(
        address _producerId,
        bytes32 _productId,
        uint256 _quantity,
        uint256 _orderTime,
        Types.State _itemState
    );
    event newevent(Types.Item);
    event newevent2(Types.Stakeholder);
    /*
    step1
    @Manufacturer
    createMapping this function creates a mapping of potential suppliers and their prices
     by mapping the material id with each supplier. 
     The function createRequest returns a list containing the potential suppliers and their prices. 
    */

    //creates a material request through the function
    function createRequest(
        bytes32 materialId_, //prod unique ID
        uint256 quantity_,
        uint256 availableDate_
    ) external view  returns (Types.SupplierWithMaterialID[] memory) {
        
        return supplierPrices[materialId_];
    }
    

    //Manufacturer calls this function
    function PurchaseRawMaterials(
        address _producerId,
        address _supplierId,
        bytes32 _ItemId,
        uint256 _quantity
    ) public _isManufacturer(msg.sender) {
        
        // Updating product history in manfacturer orders
        Types.Item memory _purchaseMaterial = inventory.getAddedMaterialDetails(
            _producerId,
            _ItemId
        );

        // emit newevent(_purchaseMaterial);

        require(
            _purchaseMaterial.Quantity >= _quantity,
            "Insufficient inventory"
        );

        Types.Item memory _newMaterial = Types.Item({
            ArrayIndex: supplyItemsInventory[msg.sender].length,
            PId: _purchaseMaterial.PId,
            MaterialName: _purchaseMaterial.MaterialName,
            Quantity: _quantity,
            AvailableDate: _purchaseMaterial.AvailableDate,
            ExpiryDate: _purchaseMaterial.ExpiryDate,
            Price: _purchaseMaterial.Price,
            IsAdded: true,
            itemState: Types.State.SOLD,
            prebookCount: _quantity
        });

        // emit newevent(_newMaterial);

        // supplyItems[_supplierId][_ItemId] = _newMaterial;
        // supplyItemsInventory[_supplierId].push(_newMaterial);

        
        Types.PurchaseOrderHistoryM memory purchaseOrderHistory_ = Types
            .PurchaseOrderHistoryM({
                manufacturerid: msg.sender,
                supplierId: _supplierId,
                producerId: _producerId,
                rawMaterial: _newMaterial,
                orderTime: block.timestamp
            });

        Types.MaterialHistory memory newProd_ = Types.MaterialHistory({
            manufacturer: purchaseOrderHistory_
        });

        if (
            registration.getStakeHolderDetails(msg.sender).role ==
            Types.StakeHolder.ManuFacturer
        ) {
            materialHistory[msg.sender].push(newProd_);
        }

        // Emiting event
        emit RawMaterialsPurchased(
            _producerId,
            _ItemId,
            _quantity,
            block.timestamp,
            Types.State.SOLD
        );
    }

    //Accessible by - producer
    function markMaterialReadyForShip(bytes32 _prodId, uint256 _quantity) public 
    {
        require(isProducer(msg.sender), "Not a producer!.");
        Types.Item memory product_ = inventory.getAddedMaterialDetails(
            msg.sender,
            _prodId
        );
        product_.itemState = Types.State.ready_to_ship;
        emit ReadyForShip(_prodId, _quantity, product_.itemState);
    }

    //Accessible by - supplier
    function markMaterialPickedUp(address _supplierOwnAddress, address _producerID, bytes32 _prodId, uint256 _quantity)
        public _isSupplier(msg.sender)
    {

        Types.Item memory _purchaseMaterial = inventory.getAddedMaterialDetails(
            _producerID,
            _prodId
        );

        require(
            _purchaseMaterial.Quantity >= _quantity,
            "Insufficient inventory"
        );

        _purchaseMaterial.itemState = Types.State.PICKUP;
        emit newevent(_purchaseMaterial);

        Types.Item memory _newMaterial = Types.Item({
            ArrayIndex: supplyItemsInventory[msg.sender].length,
            PId: _purchaseMaterial.PId,
            MaterialName: _purchaseMaterial.MaterialName,
            Quantity: _quantity,
            AvailableDate: _purchaseMaterial.AvailableDate,
            ExpiryDate: _purchaseMaterial.ExpiryDate,
            Price: _purchaseMaterial.Price,
            IsAdded: true,
            itemState: Types.State.SOLD,
            prebookCount: _quantity
        });
        emit newevent(_newMaterial);

        supplyItems[_supplierOwnAddress][_prodId] = _newMaterial;
        supplyItemsInventory[_supplierOwnAddress].push(_newMaterial);

        emit PickedUp(_producerID, _prodId, _quantity, _purchaseMaterial.itemState);
    }

     //Accessible by - producer
    function markMaterialShipmentReleased(address _producerID, bytes32 _prodId, uint256 _quantity)
        public
    {
        require(isProducer(msg.sender), "Not a producer!.");
        Types.Item memory product_ = inventory.getAddedMaterialDetails(
            _producerID,
            _prodId
        );

        product_.Quantity -= _quantity;
        product_.itemState = Types.State.SHIPMENT_RELEASED;
        
        emit ShipmentReleased(_prodId);
    }

    //Accessible by - supplier/
    function markMaterialDelivered(
        address _supplierOwnAddress,
        address _manufacturerID,
        bytes32 _matId,
        uint256 _matQuantity
    ) public _isSupplier(msg.sender) {
       
        Types.Item memory _newMaterial = supplyItems[_supplierOwnAddress][_matId];
        emit newevent(_newMaterial);

        supplyItems[_manufacturerID][_matId] = (_newMaterial);
        supplyItemsInventory[_manufacturerID].push(_newMaterial);

        _newMaterial.itemState = Types.State.DELIVERED;
        _newMaterial.Quantity -= _matQuantity;
        
        emit MaterialDelivered(_matId);
    }

    //Accessible by -manufacturer
    function markMaterialsRecieved(address _producerId, bytes32 _prodId)
        public _isManufacturer(msg.sender)
    {   
        Types.Item memory _newMaterial = supplyItems[_producerId][_prodId];
        
        _newMaterial.itemState = Types.State.RECEIVED_SHIPMENT;
        emit ShipmentReceived(_prodId);
    }
    /*________________________________________________________________________*/
    // onlyManufacturer()
    //@supplier and @Maufacturer can checks raw materials from producer Inventory.
    // _isManufacturer _isSupplier
    function getRawItemsPurchased() public view returns(Types.Item[] memory){
        return supplyItemsInventory[msg.sender];
    } 

    // onlyManufacturer()
    function getMaterialPurchaseHistory() public view returns(Types.MaterialHistory[] memory){
        return materialHistory[msg.sender];
    }
    /*_________________________________________________________________________*/

    function isProducer(address _Paddress) public view returns (bool) {
        return
            registration.getStakeHolderDetails(_Paddress).role ==
            Types.StakeHolder.Producer;
    }

    function isManufacturer(address _Maddress) public view returns (bool) {
        return
            registration.getStakeHolderDetails(_Maddress).role ==
            Types.StakeHolder.ManuFacturer;
    }

    function isSupplier(address _Saddress) public view returns (bool) {
        return
            registration.getStakeHolderDetails(_Saddress).role ==
            Types.StakeHolder.supplier;
    }

     modifier _isProducer(address _prodAddr) {
      require(registration.getStakeHolderDetails(_prodAddr).role ==
            Types.StakeHolder.Producer, "producer not registered yet or only producer can calls this function");
      _;
   }

    modifier _isManufacturer(address _manfAddr) {
      require(registration.getStakeHolderDetails(_manfAddr).role ==
            Types.StakeHolder.ManuFacturer, "manufcaturer not registered yet or only manufacturer can calls this function");
      _;
   }

   modifier _isSupplier(address _suppAddr) {
      require(registration.getStakeHolderDetails(_suppAddr).role ==
            Types.StakeHolder.supplier, "supplier not registered yet or only supplier can calls this function");
      _;
   }

}
