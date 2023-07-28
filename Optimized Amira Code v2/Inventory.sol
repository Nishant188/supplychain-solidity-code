// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./Library.sol";
import "./Register.sol";
import "./Genraters.sol";

contract Inventroy {
    
    StakeHolderRegistration registration;
    GenratesAndConversion genCn;
    
    constructor(GenratesAndConversion _genCn, StakeHolderRegistration _registration){
        genCn = _genCn;
        registration = _registration;
    }

    mapping(address => Types.Item[]) internal producerInventor;
    mapping(address => mapping(bytes32 => Types.Item)) internal rawMaterials; //mapping change public to normal
    mapping(address => Types.manfItem[]) internal productInventory;
    mapping(address => mapping(bytes32 => Types.manfItem))
        internal manufacturedProduct;
    mapping(string => Types.productAvailableManuf[]) internal sameproductLinkedWithManufacturer;
    

    //raw materials added In inventory
    event AddedInInventory(
        bytes32 _uniqueId,
        string _materialName,
        uint256 _quantity,
        uint256 _availableDate,
        uint256 _expiryDate,
        uint256 _price
    );

    //when Inventory Updated at the producer end
    event InventoryUpdate(
        bytes32 _pid,
        uint256 _quantity,
        uint256 _availableDate,
        uint256 _expiryDate,
        uint256 _price
    );

    //when Manufacturer added Product
    event ManufacturedProductAdded(
        string _productName,
        address _manufacturerAddress,
        string _barcodeId,
        uint256 _availableDate,
        uint256 _expiryDate,
        Types.State status
    );

    //when Manufacturer update The Product
    event ManufacturedProductUpdated(
        string _prodName,
        address _manufacturerAddress,
        uint256 _availableDate,
        uint256 _expiryDate,
        bytes32 _updatedHash
    );

    //added raw material for creating Inventory at the producer end!
    function addRawMaterial(
        string memory _materialname,
        uint256 _quantity,
        uint256 _availableDate,
        uint256 _expiryDate,
        uint256 _price
    ) public {
        bytes32 _pidHash = genCn.genrateUniqueIDByProductName(_materialname); //creates unique key using product name
        
        if(rawMaterials[msg.sender][_pidHash].PId == _pidHash){
            updateRawMaterial(_pidHash, rawMaterials[msg.sender][_pidHash].Quantity+_quantity,_availableDate, _expiryDate, _price);
        } else {

        Types.Item memory newRawMaterial = Types.Item({
            ArrayIndex: producerInventor[msg.sender].length,
            PId: _pidHash,
            MaterialName: _materialname,
            Quantity: _quantity,
            AvailableDate: _availableDate,
            ExpiryDate: _expiryDate,
            Price: _price,
            IsAdded: true,
            itemState: Types.State.PRODUCED,
            prebookCount: 0
        });

        rawMaterials[msg.sender][_pidHash] = newRawMaterial;
        addItemsInProducerInventory(rawMaterials[msg.sender][_pidHash]);
    
        emit AddedInInventory(
            _pidHash,
            _materialname,
            _quantity,
            _availableDate,
            _expiryDate,
            _price
        );
        }
    }

    // Function to update the quantity and price of a raw material from producer side!
    function updateRawMaterial(
        bytes32 _pid,
        uint256 _quantity,
        uint256 _availableDate,
        uint256 _expiryDate,
        uint256 _price
    ) internal {
        Types.Item storage updateMaterial = rawMaterials[msg.sender][_pid];
        
        updateMaterial.AvailableDate = _availableDate;
        updateMaterial.ExpiryDate = _expiryDate;
        updateMaterial.Quantity = _quantity;
        updateMaterial.Price = _price;

        //logic implemented here by adding ArrayIndex
        Types.Item[] storage products = producerInventor[msg.sender];
        uint256 index = rawMaterials[msg.sender][_pid].ArrayIndex;

        products[index].AvailableDate = _availableDate;
        products[index].ExpiryDate = _expiryDate;
        products[index].Quantity = _quantity;
        products[index].Price = _price;

        emit InventoryUpdate(
            _pid,
            _quantity,
            _availableDate,
            _expiryDate,
            _price
        );
    }

    //for adding new raw material in Inventory and also adding at modified Inventory!
    function addItemsInProducerInventory(Types.Item storage _newRawMaterial)
        private
    {
        producerInventor[msg.sender].push(_newRawMaterial);
    }

    // return all the Inventory function with modify one too
    // this function also used at manufacturer side too.
    function getProducerItems(address _producerID)
        public
        view
        returns (Types.Item[] memory)
    {
        return producerInventor[_producerID];
    }

    // function getProductDetails(bytes32 _prodId)
    //     public
    //     view
    //     returns (Types.Item memory)
    // {
    //     return rawMaterials[msg.sender][_prodId];
    // }

    function getAddedMaterialDetails(address _producerID, bytes32 _productID)
        external
        view
        returns (Types.Item memory)
    {
        return rawMaterials[_producerID][_productID];
    }

    //forchecking Inventory producer can check Inventroy is added or not by passing product name.
    // function IsAddedInInventory(string memory _materialName, bytes32 _pid)
    //     public
    //     view
    //     returns (bool)
    // {
    //     // bytes32 hash = keccak256(abi.encodePacked(_materialname));
    //     return (keccak256(
    //         abi.encodePacked((rawMaterials[msg.sender][_pid].MaterialName))
    //     ) == keccak256(abi.encodePacked((_materialName))));
    // }

    //Manufacturer Product Adding

    function addAProduct(
        string memory _prodName,
        string memory _description,
        uint256 _expiryDate,
        string memory _barcodeId,
        uint256 _quantity,
        uint256 _price,
        uint256 _weights,
        uint256 _availableDate
    ) public // productNotExists(_)
    // onlyManufacturer
    {
        bytes32 _pidHash = genCn.genrateUniqueIDByProductName(_prodName);
        if(_pidHash == manufacturedProduct[msg.sender][_pidHash].PId){
            updateAProduct(_prodName, _pidHash, _description, _expiryDate, manufacturedProduct[msg.sender][_pidHash].quantity+=_quantity, _price, _weights, _availableDate);
        }
        else    {
        
        Types.manfItem memory manufProduct_ = Types.manfItem({
            ArrIndex: productInventory[msg.sender].length,
            name: _prodName,
            PId: _pidHash,
            description: _description,
            expDateEpoch: _expiryDate,
            barcodeId: _barcodeId,
            quantity: _quantity,
            price: _price,
            weights: _weights,
            manDateEpoch: _availableDate, //available date
            prebookCount: 0,
            itemState: Types.State.ready_to_ship
        });

        manufacturedProduct[msg.sender][_pidHash] = manufProduct_;
        productInventory[msg.sender].push(manufProduct_);
        
        Types.productAvailableManuf memory _productAvailableManuf = Types.productAvailableManuf({
            id: msg.sender,
            productName: _prodName,
            productID: _pidHash,
            quantity: _quantity,
            price: _price,
            availableDate: _availableDate,
            weights: _weights,
            expDateEpoch: _expiryDate
        });

        sameproductLinkedWithManufacturer[_prodName].push(_productAvailableManuf); 

        emit ManufacturedProductAdded(
            _prodName,
            msg.sender,
            _barcodeId,
            _availableDate,
            _expiryDate,
            Types.State.ready_to_ship
            );
        }
    }

    // getManufacturedProducts
    function getManufacturedProductsByProductName(string memory _productName)
        external
        view
        returns (Types.productAvailableManuf[] memory)
    {
        return sameproductLinkedWithManufacturer[_productName];
    }


    function getManufacturerProducts(address _manufAdd)
        public
        view
        returns (Types.manfItem[] memory)
    {
        return productInventory[_manufAdd];
    }

    function getmanufEachProductDetails(address _manufAddress, bytes32 _manfProductID)
        external
        view
        returns (Types.manfItem memory)
    {
        return manufacturedProduct[_manufAddress][_manfProductID];
    }

    function updateAProduct(
        string memory _prodName,
        bytes32 _pID,
        string memory _description,
        uint256 _expiryDate,
        uint256 _quantity,
        uint256 _price,
        uint256 _weights,
        uint256 _availableDate
    ) internal // productNotExists(_)
    // onlyManufacturer
    {
        bytes32 _pidHash = genCn.genrateUniqueIDByProductName(_prodName);
        Types.manfItem storage updatingProduct = manufacturedProduct[
            msg.sender
        ][_pidHash];
        updatingProduct.name = _prodName;
        updatingProduct.PId = _pidHash;
        updatingProduct.description = _description;
        updatingProduct.expDateEpoch = _expiryDate;
        updatingProduct.quantity = _quantity;
        updatingProduct.price = _price;
        updatingProduct.weights = _weights;
        updatingProduct.manDateEpoch = _availableDate;

        Types.manfItem[] storage products_ = productInventory[msg.sender];
        uint256 index = manufacturedProduct[msg.sender][_pID].ArrIndex;

        products_[index].name = _prodName;
        products_[index].PId = _pidHash;
        products_[index].description = _description;
        products_[index].expDateEpoch = _expiryDate;
        products_[index].quantity = _quantity;
        products_[index].price = _price;
        products_[index].weights = _weights;
        products_[index].manDateEpoch = _availableDate;

        emit ManufacturedProductUpdated(
            _prodName,
            msg.sender,
            _availableDate,
            _expiryDate,
            _pidHash
        );
    }
}