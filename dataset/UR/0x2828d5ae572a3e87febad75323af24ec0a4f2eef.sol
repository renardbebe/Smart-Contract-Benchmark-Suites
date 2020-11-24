 

pragma solidity ^0.4.18;

 

contract CryptoPlanets {

    address ceoAddress = 0x8e6DBF31540d2299a674b8240596ae85ebD21314;
    
    modifier onlyCeo() {
        require (msg.sender == ceoAddress);
        _;
    }
    
    struct Planet {
        string name;
        address ownerAddress;
        uint256 curPrice;
        uint256 curResources;
    }
    Planet[] planets;


     
    mapping (address => uint) public addressPlanetsCount;
    mapping (address => uint) public addressAttackCount;
    mapping (address => uint) public addressDefenseCount;
    

    uint256 attackCost = 10000000000000000;
    uint256 defenseCost = 10000000000000000;
    
    uint randNonce = 0;
    bool planetsAreInitiated;

     
    function purchasePlanet(uint _planetId) public payable {
        require(msg.value == planets[_planetId].curPrice);

         
        uint256 commission5percent = ((msg.value / 10)/2);

         
        uint256 commissionOwner = msg.value - (commission5percent * 2);  
        planets[_planetId].ownerAddress.transfer(commissionOwner);

         
        addressPlanetsCount[planets[_planetId].ownerAddress] = addressPlanetsCount[planets[_planetId].ownerAddress] - 1;

         
        planets[_planetId].curResources =  planets[_planetId].curResources + commission5percent;

         
        ceoAddress.transfer(commission5percent);                  

         
        planets[_planetId].ownerAddress = msg.sender;
        planets[_planetId].curPrice = planets[_planetId].curPrice + (planets[_planetId].curPrice / 2);

         
        addressPlanetsCount[msg.sender] = addressPlanetsCount[msg.sender] + 1;
    }

     
    function purchaseAttack() payable {

         
        require(msg.value == attackCost);
        
         
        ceoAddress.transfer(msg.value);

        addressAttackCount[msg.sender]++;
    }

     
    function purchaseDefense() payable {
         
        require(msg.value == defenseCost);
        
         
        ceoAddress.transfer(msg.value);
        
        addressDefenseCount[msg.sender]++;
    }

    function StealResources(uint _planetId) {
         
        require(addressPlanetsCount[msg.sender] > 0);

         
        require(planets[_planetId].ownerAddress != msg.sender);

         
        require(planets[_planetId].curResources > 0);

         
        if(addressAttackCount[msg.sender] > addressDefenseCount[planets[_planetId].ownerAddress]) {
             
            uint random = uint(keccak256(now, msg.sender, randNonce)) % 49;
            randNonce++;
            
             
            uint256 resourcesStealable = (planets[_planetId].curResources * (50 + random)) / 100;
            msg.sender.transfer(resourcesStealable);
            
             
            planets[_planetId].curResources = planets[_planetId].curResources - resourcesStealable;
        }

    }
    
     
    function getUserDetails(address _user) public view returns(uint, uint, uint) {
        return(addressPlanetsCount[_user], addressAttackCount[_user], addressDefenseCount[_user]);
    }
    
     
    function getPlanet(uint _planetId) public view returns (
        string name,
        address ownerAddress,
        uint256 curPrice,
        uint256 curResources,
        uint ownerAttack,
        uint ownerDefense
    ) {
        Planet storage _planet = planets[_planetId];

        name = _planet.name;
        ownerAddress = _planet.ownerAddress;
        curPrice = _planet.curPrice;
        curResources = _planet.curResources;
        ownerAttack = addressAttackCount[_planet.ownerAddress];
        ownerDefense = addressDefenseCount[_planet.ownerAddress];
    }
    
    
     
    function createPlanet(string _planetName, uint256 _planetPrice) public onlyCeo {
        uint planetId = planets.push(Planet(_planetName, ceoAddress, _planetPrice, 0)) - 1;
    }
    
     
    function InitiatePlanets() public onlyCeo {
        require(planetsAreInitiated == false);
        createPlanet("Blue Lagoon", 100000000000000000); 
        createPlanet("GreenPeace", 100000000000000000); 
        createPlanet("Medusa", 100000000000000000); 
        createPlanet("O'Ranger", 100000000000000000); 
        createPlanet("Queen", 90000000000000000); 
        createPlanet("Citrus", 90000000000000000); 
        createPlanet("O'Ranger II", 90000000000000000); 
        createPlanet("Craterion", 50000000000000000);
        createPlanet("Dark'Air", 50000000000000000);

    }
}