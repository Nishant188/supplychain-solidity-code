// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./Library.sol";
import "./Genraters.sol";

contract StakeHolderRegistration {
    GenratesAndConversion genr;

    constructor(GenratesAndConversion _genr) {
        genr = _genr;
        emit AuthorizedCaller(msg.sender);
    }

    Types.Stakeholder[] internal producerList;
    Types.Stakeholder[] internal manufacturerList;
    Types.Stakeholder[] internal distributorsList;
    Types.Stakeholder[] internal retailersList;
    Types.Stakeholder[] internal supplierList;
    Types.Stakeholder[] internal consumerList;

    mapping(address => bytes32[3]) stakeholderspharse; //internal
    mapping(address => Types.Stakeholder) stakeholders;
    mapping(string => Types.Stakeholder[]) internal servesCountry;
    mapping(string => Types.Stakeholder[]) internal distributoresServesCountry;
    mapping(string => Types.Stakeholder[]) internal supplierServesCountry;
    mapping(string => Types.Stakeholder[]) internal retailersServesCity;

    mapping(address => Types.Stakeholder[])
        internal distributerLinkedWithmanufacturer;
    mapping(address => Types.Stakeholder[])
        internal retailersLinkedWithdistributer;

    event AuthorizedCaller(address caller);
    event StakeHolderRegisterd(
        Types.StakeHolder role,
        address id_,
        string name,
        string email,
        uint256 MobNo,
        bool IsRegistered,
        bytes32[3],
        string country,
        string city
    );

    //before adding raw materials(products) producer needs to be register yourself first then only he/she can createhis Invenotry.
    // always registerd with unique ID if alraedy registered.
    //all the stakeholders can Register Via This.
    function Register(
        Types.StakeHolder _role,
        string memory _name,
        string memory _email,
        uint256 _mobNo,
        string memory _country,
        string memory _city
    ) public returns (string memory) {
        // Producer And ManuFacturer Both Have Different Adress Must!
        require(msg.sender != address(0));
        require(
            !stakeholders[msg.sender].IsRegistered == true,
            "stakeholder alraedy registered with a role!"
        );

        Types.Stakeholder memory sk_ = Types.Stakeholder({
            role: _role,
            id_: msg.sender,
            name: _name,
            email: _email,
            MobNo: _mobNo,
            IsRegistered: true,
            country: _country,
            city: _city
        });
        add(sk_);

        bytes32 g1 = genr.random(1);
        bytes32 g2 = genr.random(2);
        bytes32 g3 = genr.random(3);
        stakeholderspharse[msg.sender] = [g1, g2, g3];

        //if stake holder is producer then only can add Producer list
        if (Types.StakeHolder.Producer == _role) {
            producerList.push(sk_);
        }
        //if stake holder is producer then only can add Manufacturer list
        else if (Types.StakeHolder.ManuFacturer == _role) {
            manufacturerList.push(sk_);
            servesCountry[_country].push(sk_);
        }
        //if stake holder is producer then only can add Distributors list
        else if (Types.StakeHolder.distributors == _role) {
            distributorsList.push(sk_);
            distributoresServesCountry[_country].push(sk_);
        }
        //if stake holder is producer then only can add Retailers list
        else if (Types.StakeHolder.retailers == _role) {
            retailersList.push(sk_);
            retailersServesCity[_city].push(sk_);
        } 
        
        else if (Types.StakeHolder.supplier == _role) {
            supplierList.push(sk_);
            supplierServesCountry[_country].push(sk_);
        }
        else if(Types.StakeHolder.supplier == _role){
            consumerList.push(sk_);
        }

        emit StakeHolderRegisterd(
            _role,
            msg.sender,
            _name,
            _email,
            _mobNo,
            true,
            stakeholderspharse[msg.sender],
            _country,
            _city
        );

        return "successfully registered!";
    }
    
    //Login StakeHolders
    function login(
        address id,
        bytes32 pharse,
        Types.StakeHolder _role
    ) public view returns (bool) {
        if (stakeholders[id].role == _role) {
            if (
                stakeholderspharse[id][0] == pharse ||
                stakeholderspharse[id][1] == pharse ||
                stakeholderspharse[id][0] == pharse
            ) {
                return true;
            }
        }
        return false;
    }

    function userRegisterUnderOtherStakeHolder(
        //(if user registered under other stakeholders like under manufacturer registered distributors and retailers same for others.)
        Types.StakeHolder _role,
        address _userref,
        string memory _name,
        string memory _email,
        uint256 _mobNo,
        string memory _country,
        string memory _city
    ) public returns (string memory) {
        require(msg.sender != address(0));

        require(
            !stakeholders[msg.sender].IsRegistered == true, //not working here
            "stakeholder alraedy registered with a role!"
        );

        require(
            (Types.StakeHolder.distributors == _role ||
                Types.StakeHolder.retailers == _role),
            "Under Manufacturer Can only Select Distributors and Retailers Role!"
        );

        require(
            (stakeholders[_userref].role == Types.StakeHolder.ManuFacturer ||
                stakeholders[_userref].role == Types.StakeHolder.distributors),
            "only under Manufacturer and Distributors you can register yourself!"
        );

        bytes32 g1 = genr.random(1);
        bytes32 g2 = genr.random(2);
        bytes32 g3 = genr.random(3);
        stakeholderspharse[msg.sender] = [g1, g2, g3];

        Types.Stakeholder memory sk_ = Types.Stakeholder({
            role: _role,
            id_: msg.sender,
            name: _name,
            email: _email,
            MobNo: _mobNo,
            IsRegistered: true,
            country: _country,
            city: _city
        });
        add(sk_);
        if (
            Types.StakeHolder.ManuFacturer == stakeholders[_userref].role ||
            Types.StakeHolder.distributors == _role
        ) {
            distributorsList.push(sk_);
            distributoresServesCountry[_country].push(sk_);
            distributerLinkedWithmanufacturer[_userref].push(sk_);
        }
        //if stake holder is producer then only can add Retailers list
        else if (
            Types.StakeHolder.distributors == stakeholders[_userref].role ||
            Types.StakeHolder.retailers == _role
        ) {
            retailersList.push(sk_);
            retailersServesCity[_city].push(sk_);
            retailersLinkedWithdistributer[_userref].push(sk_);
        }

        return "successfully registered!";
    }

    function getStakeHolderDetails(address id_)
        external
        view
        returns (Types.Stakeholder memory)
    {
        require(id_ != address(0));
        require(stakeholders[id_].id_ != address(0));
        return stakeholders[id_];
    }

    //used at producer list
    function getProducerList()
        public
        view
        returns (Types.Stakeholder[] memory)
    {
        return producerList;
    }

    //list of manufacturer
    function getManuFacturerList()
        public
        view
        returns (Types.Stakeholder[] memory)
    {
        return manufacturerList;
    }

    //list of distributors
    function getDistributorsList()
        public
        view
        returns (Types.Stakeholder[] memory)
    {
        return distributorsList;
    }

    //list of retailers
    function getRetailersList()
        public
        view
        returns (Types.Stakeholder[] memory)
    {
        return retailersList;
    }

    //list of supplier
    function getSupplierList()
        public
        view
        returns (Types.Stakeholder[] memory)
    {
        return supplierList;
    }

    //list of distributersLinkedWithManufacturers
    function getStakeHolderListLinkedManufacturer(address _manufAdd)
        public
        view
        returns (Types.Stakeholder[] memory)
    {
        return distributerLinkedWithmanufacturer[_manufAdd];
    }

    //list of stakeholder linked with other distributer
    function getStakeHolderListLinkedWithDistributer(address _distAdd)
        public
        view
        returns (Types.Stakeholder[] memory)
    {
        return retailersLinkedWithdistributer[_distAdd];
    }

    //list of manufacturer list via countryname
    function getDistViaCountryServe(string memory _countryName)
        public
        view
        returns (Types.Stakeholder[] memory)
    {
        return distributoresServesCountry[_countryName];
    }

    //list of manufacturer list via countryname
    function getManufViaCountryServe(string memory _countryName)
        public
        view
        returns (Types.Stakeholder[] memory)
    {
        return servesCountry[_countryName];
    }

    //list of suppliers list via countryname
    function getSupplierViaCountryServe(string memory _countryName)
        public
        view
        returns (Types.Stakeholder[] memory)
    {
        return supplierServesCountry[_countryName];
    }

    function add(Types.Stakeholder memory user) internal {
        require(user.id_ != address(0));
        stakeholders[user.id_] = user;
    }

    function getPhrases() public view returns (bytes32, bytes32, bytes32) {
        require(
            stakeholderspharse[msg.sender][0] != bytes32(0),
            "User not registered"
        );
        return (
        stakeholderspharse[msg.sender][0],
        stakeholderspharse[msg.sender][1],
        stakeholderspharse[msg.sender][2]
        );
    }
}
