 

pragma solidity ^0.4.18;

 

contract MyEtherCityGame {

    address ceoAddress = 0x699dE541253f253a4eFf0D3c006D70c43F2E2DaE;
    address InitiateLandsAddress = 0xa93a135e3c73ab77ea00e194bd080918e65149c3;
    
    modifier onlyCeo() {
        require (
            msg.sender == ceoAddress||
            msg.sender == InitiateLandsAddress
            );
        _;
    }

    uint256 priceMetal = 5000000000000000;      

    struct Land {
        address ownerAddress;
        uint256 landPrice;
        bool landForSale;
        bool landForRent;
        uint landOwnerCommission;
        bool isOccupied;
        uint cityRentingId;
    }
    Land[] lands;

    struct City {
        uint landId;
        address ownerAddress;
        uint256 cityPrice;
        uint256 cityGdp; 
        bool cityForSale;
        uint squaresOccupied;  
        uint metalStock;
    }
    City[] cities;

    struct Business {
        uint itemToProduce;
        uint256 itemPrice;
        uint cityId;
        uint32 readyTime;
    }
    Business[] businesses;

     

    struct Building {
        uint buildingType;
        uint cityId;
        uint32 readyTime;
    }
    Building[] buildings;

    struct Transaction {
        uint buyerId;
        uint sellerId;
        uint256 transactionValue;
        uint itemId;
        uint blockId;
    }
    Transaction[] transactions;

    mapping (uint => uint) public CityBuildingsCount;         
    mapping (uint => uint) public BuildingTypeMetalNeeded;    
    mapping (uint => uint) public BuildingTypeSquaresOccupied;   
    mapping (uint => uint) public CountBusinessesPerType;        
    mapping (uint => uint) public CityBusinessCount;             
    mapping (uint => uint) public CitySalesTransactionsCount;     

     
     
     

     
    function getLand(uint _landId) public view returns (
        address ownerAddress,
        uint256 landPrice,
        bool landForSale,
        bool landForRent,
        uint landOwnerCommission,
        bool isOccupied,
        uint cityRentingId
    ) {
        Land storage _land = lands[_landId];

        ownerAddress = _land.ownerAddress;
        landPrice = _land.landPrice;
        landForSale = _land.landForSale;
        landForRent = _land.landForRent;
        landOwnerCommission = _land.landOwnerCommission;
        isOccupied = _land.isOccupied;
        cityRentingId = _land.cityRentingId;
    }

     
    function getCity(uint _cityId) public view returns (
        uint landId,
        address landOwner,
        address cityOwner,
        uint256 cityPrice,
        uint256 cityGdp,
        bool cityForSale,
        uint squaresOccupied,
        uint metalStock,
        uint cityPopulation,
        uint healthCitizens,
        uint educationCitizens,
        uint happinessCitizens,
        uint productivityCitizens
    ) {
        City storage _city = cities[_cityId];

        landId = _city.landId;
        landOwner = lands[_city.landId].ownerAddress;
        cityOwner = _city.ownerAddress;
        cityPrice = _city.cityPrice;
        cityGdp = _city.cityGdp;
        cityForSale = _city.cityForSale;
        squaresOccupied = _city.squaresOccupied;
        metalStock = _city.metalStock;
        cityPopulation = getCityPopulation(_cityId);
        healthCitizens = getHealthCitizens(_cityId);
        educationCitizens = getEducationCitizens(_cityId);
        happinessCitizens = getHappinessCitizens(_cityId);
        productivityCitizens = getProductivityCitizens(_cityId);
    }

     
    function getBusiness(uint _businessId) public view returns (
        uint itemToProduce,
        uint256 itemPrice,
        uint cityId,
        uint cityMetalStock,
        uint readyTime,
        uint productionTime,
        uint cityLandId,
        address cityOwner
    ) {
        Business storage _business = businesses[_businessId];

        itemToProduce = _business.itemToProduce;
        itemPrice = _business.itemPrice;
        cityId = _business.cityId;
        cityMetalStock = cities[_business.cityId].metalStock;
        readyTime = _business.readyTime;
        productionTime = getProductionTimeBusiness(_businessId);
        cityLandId = cities[_business.cityId].landId;
        cityOwner = cities[_business.cityId].ownerAddress;
        
    }

     
    function getBuilding(uint _buildingId) public view returns (
        uint buildingType,
        uint cityId,
        uint32 readyTime
    ) {
        Building storage _building = buildings[_buildingId];

        buildingType = _building.buildingType;
        cityId = _building.cityId;
        readyTime = _building.readyTime;
    }

     
    function getTransaction(uint _transactionId) public view returns (
        uint buyerId,
        uint sellerId,
        uint256 transactionValue,
        uint itemId,
        uint blockId
    ) {
        Transaction storage _transaction = transactions[_transactionId];

        buyerId = _transaction.buyerId;
        sellerId = _transaction.sellerId;
        transactionValue = _transaction.transactionValue;
        itemId = _transaction.itemId;
        blockId = _transaction.blockId;
    }

     
    function getCityBuildings(uint _cityId, bool _active) public view returns (
        uint countBuildings,
        uint countHouses,
        uint countSchools,
        uint countHospital,
        uint countAmusement
    ) {
        countBuildings = getCountAllBuildings(_cityId, _active);
        countHouses = getCountBuildings(_cityId, 0, _active);
        countSchools = getCountBuildings(_cityId, 1, _active);
        countHospital = getCountBuildings(_cityId, 2, _active);
        countAmusement = getCountBuildings(_cityId, 3, _active);
    }
        
     
    function getSenderLands(address _senderAddress) public view returns(uint[]) {
        uint[] memory result = new uint[](getCountSenderLands(_senderAddress));
        uint counter = 0;
        for (uint i = 0; i < lands.length; i++) {
          if (lands[i].ownerAddress == _senderAddress) {
            result[counter] = i;
            counter++;
          }
        }
        return result;
    }
    
    function getCountSenderLands(address _senderAddress) public view returns(uint) {
        uint counter = 0;
        for (uint i = 0; i < lands.length; i++) {
          if (lands[i].ownerAddress == _senderAddress) {
            counter++;
          }
        }
        return(counter);
    }
    
      
    function getSenderCities(address _senderAddress) public view returns(uint[]) {
        uint[] memory result = new uint[](getCountSenderCities(_senderAddress));
        uint counter = 0;
        for (uint i = 0; i < cities.length; i++) {
          if (cities[i].ownerAddress == _senderAddress) {
            result[counter] = i;
            counter++;
          }
        }
        return result;
    }
    
    function getCountSenderCities(address _senderAddress) public view returns(uint) {
        uint counter = 0;
        for (uint i = 0; i < cities.length; i++) {
          if (cities[i].ownerAddress == _senderAddress) {
            counter++;
          }
        }
        return(counter);
    }

     
    function getCityPopulation(uint _cityId) public view returns (uint) {
         
        uint _cityActiveBuildings = getCountBuildings(_cityId, 0, true);
        return(_cityActiveBuildings * 5);
    }

     
    function getCountAllBuildings(uint _cityId, bool _active) public view returns(uint) {
        uint counter = 0;
        for (uint i = 0; i < buildings.length; i++) {
            if(_active == true) {
                 
                if(buildings[i].cityId == _cityId && buildings[i].readyTime < now) {
                    counter++;
                }
            } else {
                 
                if(buildings[i].cityId == _cityId && buildings[i].readyTime >= now) {
                    counter++;
                }
            }
            
        }
        return counter;
    }
    
     
    function getCountBuildings(uint _cityId, uint _buildingType, bool _active) public view returns(uint) {
        uint counter = 0;
        for (uint i = 0; i < buildings.length; i++) {
            if(_active == true) {
                 
                if(buildings[i].buildingType == _buildingType && buildings[i].cityId == _cityId && buildings[i].readyTime < now) {
                    counter++;
                }
            } else {
                 
                if(buildings[i].buildingType == _buildingType && buildings[i].cityId == _cityId && buildings[i].readyTime >= now) {
                    counter++;
                }
            }
        }
        return counter;
    }

     
    function getCityActiveBuildings(uint _cityId, uint _buildingType) public view returns(uint[]) {
        uint[] memory result = new uint[](getCountBuildings(_cityId, _buildingType, true));
        uint counter = 0;
        for (uint i = 0; i < buildings.length; i++) {
             
            if (buildings[i].buildingType == _buildingType && buildings[i].cityId == _cityId && buildings[i].readyTime < now) {
                result[counter] = i;
                counter++;
            }
        }
        return result;
    }

     
    function getCityPendingBuildings(uint _cityId, uint _buildingType) public view returns(uint[]) {
        uint[] memory result = new uint[](getCountBuildings(_cityId, _buildingType, false));
        uint counter = 0;
        for (uint i = 0; i < buildings.length; i++) {
             
            if (buildings[i].buildingType == _buildingType && buildings[i].cityId == _cityId && buildings[i].readyTime >= now) {
                result[counter] = i;
                counter++;
            }
        }
        return result;
    }

     
    function getActiveBusinessesPerType(uint _businessType) public view returns(uint[]) {
        uint[] memory result = new uint[](CountBusinessesPerType[_businessType]);
        uint counter = 0;
        for (uint i = 0; i < businesses.length; i++) {
             
            if (businesses[i].itemToProduce == _businessType) {
                result[counter] = i;
                counter++;
            }
        }
         
        return result;
    }

     
    function getActiveBusinessesPerCity(uint _cityId) public view returns(uint[]) {
        uint[] memory result = new uint[](CityBusinessCount[_cityId]);
        uint counter = 0;
        for (uint i = 0; i < businesses.length; i++) {
             
            if (businesses[i].cityId == _cityId) {
                result[counter] = i;
                counter++;
            }
        }
         
        return result;
    }
    
     
    function getSalesCity(uint _cityId) public view returns(uint[]) {
        uint[] memory result = new uint[](CitySalesTransactionsCount[_cityId]);
        uint counter = 0;
        uint startId = transactions.length - 1;
        for (uint i = 0; i < transactions.length; i++) {
            uint _tId = startId - i;
             
            if (transactions[_tId].sellerId == _cityId) {
                result[counter] = _tId;
                counter++;
            }
        }
         
        return result;
    }

     
    function getHealthCitizens(uint _cityId) public view returns(uint) {
        uint _hospitalsCount = getCountBuildings(_cityId, 2, true);
        uint pointsHealth = (_hospitalsCount * 500) + 50;
        uint _population = getCityPopulation(_cityId);
        uint256 _healthPopulation = 10;
        
        if(_population > 0) {
            _healthPopulation = (pointsHealth / uint256(_population));
        } else {
            _healthPopulation = 0;
        }
        
         
        if(_healthPopulation > 10) {
            _healthPopulation = 10;
        }
        return(_healthPopulation);
    }

     
    function getEducationCitizens(uint _cityId) public view returns(uint) {
        uint _schoolsCount = getCountBuildings(_cityId, 1, true);
        uint pointsEducation = (_schoolsCount * 250) + 25;
        uint _population = getCityPopulation(_cityId);
        uint256 _educationPopulation = 10;

        if(_population > 0) {
            _educationPopulation = (pointsEducation / uint256(_population));
        } else {
            _educationPopulation = 0;
        }
        
        if(_educationPopulation > 10) {
            _educationPopulation = 10;
        }
        return(_educationPopulation);
    }

     
    function getHappinessCitizens(uint _cityId) public view returns(uint) {
        uint _amusementCount = getCountBuildings(_cityId, 3, true);
        uint pointsAmusement = (_amusementCount * 350) + 35;
        uint _population = getCityPopulation(_cityId);
        uint256 _amusementPopulation = 10;
        
        if(_population > 0) {
            _amusementPopulation = (pointsAmusement / uint256(_population));
        } else {
            _amusementPopulation = 0;
        }
        
         
        if(_amusementPopulation > 10) {
            _amusementPopulation = 10;
        }
        return(_amusementPopulation);
    }

     
    function getProductivityCitizens(uint _cityId) public view returns(uint) {
        return((getEducationCitizens(_cityId) + getHealthCitizens(_cityId) + getHappinessCitizens(_cityId)) / 3);
    }

     
    function getMaxBusinessesPerCity(uint _cityId) public view returns(uint) {
        uint _citizens = getCityPopulation(_cityId);
        uint _maxBusinesses;

         
        if(_citizens >= 75) {
            _maxBusinesses = 4;
        } else if(_citizens >= 50) {
            _maxBusinesses = 3;
        } else if(_citizens >= 25) {
            _maxBusinesses = 2;
        } else {
            _maxBusinesses = 1;
        }

        return(_maxBusinesses);
    }
    
    function getCountCities() public view returns(uint) {
        return(cities.length);
    }

     
     
     
    
     
    function removeTenant(uint _landId) public {
        require(lands[_landId].ownerAddress == msg.sender);
        lands[_landId].landForRent = false;
        lands[_landId].isOccupied = false;
        cities[lands[_landId].cityRentingId].landId = 0;
        lands[_landId].cityRentingId = 0;
    }

     
     
    function createBusiness(uint _itemId, uint256 _itemPrice, uint _cityId) public {
         
        require(_itemPrice >= BuildingTypeMetalNeeded[_itemId] * priceMetal);

         
        require(cities[_cityId].ownerAddress == msg.sender);

         
        require((cities[_cityId].squaresOccupied + BuildingTypeSquaresOccupied[4]) <= 100);
        
         
        require(CityBusinessCount[_cityId] < getMaxBusinessesPerCity(_cityId));

         
        businesses.push(Business(_itemId, _itemPrice, _cityId, 0));

         
        CountBusinessesPerType[_itemId]++;

         
        CityBusinessCount[_cityId]++;

         
        cities[_cityId].squaresOccupied = cities[_cityId].squaresOccupied + BuildingTypeSquaresOccupied[4];
    }

     
    function updateBusiness(uint _businessId, uint256 _itemPrice) public {
         
        require(cities[businesses[_businessId].cityId].ownerAddress == msg.sender);

         
        require(_itemPrice >= BuildingTypeMetalNeeded[businesses[_businessId].itemToProduce] * priceMetal);

        businesses[_businessId].itemPrice = _itemPrice;
    }

     
    function purchaseMetal(uint _cityId, uint _amount) public payable {
         
        require(msg.value == _amount * priceMetal);

         
        require(cities[_cityId].ownerAddress == msg.sender);

         
        ceoAddress.transfer(msg.value);

         
        cities[_cityId].metalStock = cities[_cityId].metalStock + _amount;
    }
    
     
    function getProductionTimeBusiness(uint _businessId) public view returns(uint256) {
        uint _productivityIndicator = getProductivityCitizens(businesses[_businessId].cityId);
        uint _countCitizens = getCityPopulation(businesses[_businessId].cityId);
        
        uint256 productivityFinal;
        
        if(_countCitizens == 0) {
             
            productionTime = 7000; 
        } else {
             
            if(_productivityIndicator <= 1) {
            productivityFinal = _countCitizens;
            } else {
                productivityFinal = _countCitizens * (_productivityIndicator / 2);
            }
            
            uint256 productionTime = 60000 / uint256(productivityFinal);
        }
        return(productionTime);
    }

     
    function purchaseBuilding(uint _itemId, uint _businessId, uint _cityId) public payable {
         
        require(msg.value == businesses[_businessId].itemPrice);

         
        require(cities[_cityId].ownerAddress == msg.sender);

         
        require(_itemId == businesses[_businessId].itemToProduce);

         
        require(cities[businesses[_businessId].cityId].metalStock >= BuildingTypeMetalNeeded[_itemId]);

         
        require((cities[_cityId].squaresOccupied + BuildingTypeSquaresOccupied[_itemId]) <= 100);

         
        require(businesses[_businessId].readyTime < now);

        uint256 onePercent = msg.value / 100;

         
        uint _landId = cities[businesses[_businessId].cityId].landId;
        address landOwner = lands[_landId].ownerAddress;
        uint256 landOwnerCommission = onePercent * lands[cities[businesses[_businessId].cityId].landId].landOwnerCommission;
        landOwner.transfer(landOwnerCommission);

         
        cities[businesses[_businessId].cityId].ownerAddress.transfer(msg.value - landOwnerCommission);

         
        cities[businesses[_businessId].cityId].metalStock = cities[businesses[_businessId].cityId].metalStock - BuildingTypeMetalNeeded[_itemId];

         
        uint productionTime = getProductionTimeBusiness(_businessId);
        uint32 _buildingReadyTime = uint32(now + productionTime);

         
        businesses[_businessId].readyTime = uint32(now + productionTime);

         
        buildings.push(Building(_itemId, _cityId, _buildingReadyTime));

         
        cities[_cityId].squaresOccupied = cities[_cityId].squaresOccupied + BuildingTypeSquaresOccupied[_itemId];

         
        cities[_cityId].cityGdp = cities[_cityId].cityGdp + msg.value;

         
        CityBuildingsCount[_cityId]++;

         
        transactions.push(Transaction(_cityId, businesses[_businessId].cityId, msg.value, _itemId, block.number));
        CitySalesTransactionsCount[businesses[_businessId].cityId]++;
    }

     
    function updateLand(uint _landId, uint256 _landPrice, uint _typeUpdate, uint _commission) public {
        require(lands[_landId].ownerAddress == msg.sender);

         
         
         

        if(_typeUpdate == 0) {

             
            lands[_landId].landForSale = true;
            lands[_landId].landForRent = false;
            lands[_landId].landPrice = _landPrice;
            
        } else if(_typeUpdate == 1) {
             
            require(lands[_landId].isOccupied == false);
            
             
            lands[_landId].landForRent = true;
            lands[_landId].landForSale = false;
            lands[_landId].landOwnerCommission = _commission;

        } else if(_typeUpdate == 2) {
             
            lands[_landId].landForRent = false;
            lands[_landId].landForSale = false;
        }
    }

    function purchaseLand(uint _landId, uint _typePurchase, uint _commission) public payable {
        require(lands[_landId].landForSale == true);
        require(msg.value == lands[_landId].landPrice);

         
        lands[_landId].ownerAddress.transfer(msg.value);

         
        lands[_landId].ownerAddress = msg.sender;
        lands[_landId].landForSale = false;

         
         
         
         
        
        if(_typePurchase == 0) {
             
            createCity(_landId);
        } else if(_typePurchase == 1) {
             
            lands[_landId].landForRent = true;
            lands[_landId].landForSale = false;
            lands[_landId].landOwnerCommission = _commission;
        } 
    }
    
     
    function rentLand(uint _landId, bool _createCity, uint _cityId) public {
         
        if(lands[_landId].ownerAddress != msg.sender) {
            require(lands[_landId].landForRent == true);
        }

         
        require(lands[_landId].isOccupied == false);
                    
        if(_createCity == true) {
             
            createCity(_landId);
        } else {
             
            require(cities[_cityId].landId == 0);
        
             
            cities[_cityId].landId = _landId;
            lands[_landId].cityRentingId = _cityId;
            lands[_landId].landForSale == false;
            lands[_landId].landForRent == true;
            lands[_landId].isOccupied = true;
        }
    }

    function createCity(uint _landId) public {
        require(lands[_landId].isOccupied == false);

         
        uint cityId = cities.push(City(_landId, msg.sender, 0, 0, false, 0, 0)) - 1;

        lands[_landId].landForSale == false;
        lands[_landId].landForRent == false;
        lands[_landId].cityRentingId = cityId;
        lands[_landId].isOccupied = true;
    }
    
     
    function CreateLand(uint256 _landPrice, address _owner) public onlyCeo {
         
        if(lands.length < 300) {
            lands.push(Land(_owner, _landPrice, false, false, 0, false, 0));
        }
        
    }
    
    function UpdateInitiateContractAddress(address _newAddress) public onlyCeo { 
        InitiateLandsAddress = _newAddress;
    }
    
     
    function Initialize() public onlyCeo {
         
        lands.push(Land(ceoAddress, 0, false, false, 5, true, 0));  

         
        BuildingTypeMetalNeeded[0] = 3;
        BuildingTypeMetalNeeded[1] = 4;
        BuildingTypeMetalNeeded[2] = 5;
        BuildingTypeMetalNeeded[3] = 4;

         
        BuildingTypeSquaresOccupied[0] = 2;
        BuildingTypeSquaresOccupied[1] = 4;
        BuildingTypeSquaresOccupied[2] = 6;
        BuildingTypeSquaresOccupied[3] = 4;
        BuildingTypeSquaresOccupied[4] = 5;  
    }
}