 

pragma solidity ^0.4.24;

contract AccessControl {
    address public creatorAddress;
    uint16 public totalSeraphims = 0;
    mapping (address => bool) public seraphims;

    bool public isMaintenanceMode = true;
 
    modifier onlyCREATOR() {
        require(msg.sender == creatorAddress);
        _;
    }

    modifier onlySERAPHIM() {
      
      require(seraphims[msg.sender] == true);
        _;
    }
    modifier isContractActive {
        require(!isMaintenanceMode);
        _;
    }
    
     
    constructor() public {
        creatorAddress = msg.sender;
    }
    

    function addSERAPHIM(address _newSeraphim) onlyCREATOR public {
        if (seraphims[_newSeraphim] == false) {
            seraphims[_newSeraphim] = true;
            totalSeraphims += 1;
        }
    }
    
    function removeSERAPHIM(address _oldSeraphim) onlyCREATOR public {
        if (seraphims[_oldSeraphim] == true) {
            seraphims[_oldSeraphim] = false;
            totalSeraphims -= 1;
        }
    }

    function updateMaintenanceMode(bool _isMaintaining) onlyCREATOR public {
        isMaintenanceMode = _isMaintaining;
    }

  
} 

pragma solidity ^0.4.16;

contract SafeMath {
    function safeAdd(uint x, uint y) pure internal returns(uint) {
      uint z = x + y;
      assert((z >= x) && (z >= y));
      return z;
    }

    function safeSubtract(uint x, uint y) pure internal returns(uint) {
      assert(x >= y);
      uint z = x - y;
      return z;
    }

    function safeMult(uint x, uint y) pure internal returns(uint) {
      uint z = x * y;
      assert((x == 0)||(z/x == y));
      return z;
    }
    
     function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

    function getRandomNumber(uint16 maxRandom, uint16 min, address privateAddress) constant public returns(uint8) {
        uint256 genNum = uint256(block.blockhash(block.number-1)) + uint256(privateAddress);
        return uint8(genNum % (maxRandom - min + 1)+min);
    }
}

contract Enums {
    enum ResultCode {
        SUCCESS,
        ERROR_CLASS_NOT_FOUND,
        ERROR_LOW_BALANCE,
        ERROR_SEND_FAIL,
        ERROR_NOT_OWNER,
        ERROR_NOT_ENOUGH_MONEY,
        ERROR_INVALID_AMOUNT
    }

    enum AngelAura { 
        Blue, 
        Yellow, 
        Purple, 
        Orange, 
        Red, 
        Green 
    }
}


contract IABToken is AccessControl {
 
 
    function balanceOf(address owner) public view returns (uint256);
    function totalSupply() external view returns (uint256) ;
    function ownerOf(uint256 tokenId) public view returns (address) ;
    function setMaxAngels() external;
    function setMaxAccessories() external;
    function setMaxMedals()  external ;
    function initAngelPrices() external;
    function initAccessoryPrices() external ;
    function setCardSeriesPrice(uint8 _cardSeriesId, uint _newPrice) external;
    function approve(address to, uint256 tokenId) public;
    function getRandomNumber(uint16 maxRandom, uint8 min, address privateAddress) view public returns(uint8) ;
    function tokenURI(uint256 _tokenId) public pure returns (string memory) ;
    function baseTokenURI() public pure returns (string memory) ;
    function name() external pure returns (string memory _name) ;
    function symbol() external pure returns (string memory _symbol) ;
    function getApproved(uint256 tokenId) public view returns (address) ;
    function setApprovalForAll(address to, bool approved) public ;
    function isApprovedForAll(address owner, address operator) public view returns (bool);
    function transferFrom(address from, address to, uint256 tokenId) public ;
    function safeTransferFrom(address from, address to, uint256 tokenId) public ;
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public ;
    function _exists(uint256 tokenId) internal view returns (bool) ;
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) ;
    function _mint(address to, uint256 tokenId) internal ;
    function mintABToken(address owner, uint8 _cardSeriesId, uint16 _power, uint16 _auraRed, uint16 _auraYellow, uint16 _auraBlue, string memory _name, uint16 _experience, uint16 _oldId) public;
    function addABTokenIdMapping(address _owner, uint256 _tokenId) private ;
    function getPrice(uint8 _cardSeriesId) public view returns (uint);
    function buyAngel(uint8 _angelSeriesId) public payable ;
    function buyAccessory(uint8 _accessorySeriesId) public payable ;
    function getAura(uint8 _angelSeriesId) pure public returns (uint8 auraRed, uint8 auraYellow, uint8 auraBlue) ;
    function getAngelPower(uint8 _angelSeriesId) private view returns (uint16) ;
    function getABToken(uint256 tokenId) view public returns(uint8 cardSeriesId, uint16 power, uint16 auraRed, uint16 auraYellow, uint16 auraBlue, string memory name, uint16 experience, uint64 lastBattleTime, uint16 lastBattleResult, address owner, uint16 oldId);
    function setAuras(uint256 tokenId, uint16 _red, uint16 _blue, uint16 _yellow) external;
    function setName(uint256 tokenId,string memory namechange) public ;
    function setExperience(uint256 tokenId, uint16 _experience) external;
    function setLastBattleResult(uint256 tokenId, uint16 _result) external ;
    function setLastBattleTime(uint256 tokenId) external;
    function setLastBreedingTime(uint256 tokenId) external ;
    function setoldId(uint256 tokenId, uint16 _oldId) external;
    function getABTokenByIndex(address _owner, uint64 _index) view external returns(uint256) ;
    function _burn(address owner, uint256 tokenId) internal ;
    function _burn(uint256 tokenId) internal ;
    function _transferFrom(address from, address to, uint256 tokenId) internal ;
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data) internal returns (bool);
    function _clearApproval(uint256 tokenId) private ;
}


contract IPetCardData is AccessControl, Enums {
    uint8 public totalPetCardSeries;    
    uint64 public totalPets;
    
     
    function createPetCardSeries(uint8 _petCardSeriesId, uint32 _maxTotal) onlyCREATOR public returns(uint8);
    function setPet(uint8 _petCardSeriesId, address _owner, string _name, uint8 _luck, uint16 _auraRed, uint16 _auraYellow, uint16 _auraBlue) onlySERAPHIM external returns(uint64);
    function setPetAuras(uint64 _petId, uint8 _auraRed, uint8 _auraBlue, uint8 _auraYellow) onlySERAPHIM external;
    function setPetLastTrainingTime(uint64 _petId) onlySERAPHIM external;
    function setPetLastBreedingTime(uint64 _petId) onlySERAPHIM external;
    function addPetIdMapping(address _owner, uint64 _petId) private;
    function transferPet(address _from, address _to, uint64 _petId) onlySERAPHIM public returns(ResultCode);
    function ownerPetTransfer (address _to, uint64 _petId)  public;
    function setPetName(string _name, uint64 _petId) public;

     
    function getPetCardSeries(uint8 _petCardSeriesId) constant public returns(uint8 petCardSeriesId, uint32 currentPetTotal, uint32 maxPetTotal);
    function getPet(uint _petId) constant public returns(uint petId, uint8 petCardSeriesId, string name, uint8 luck, uint16 auraRed, uint16 auraBlue, uint16 auraYellow, uint64 lastTrainingTime, uint64 lastBreedingTime, address owner);
    function getOwnerPetCount(address _owner) constant public returns(uint);
    function getPetByIndex(address _owner, uint _index) constant public returns(uint);
    function getTotalPetCardSeries() constant public returns (uint8);
    function getTotalPets() constant public returns (uint);
}



contract Pets is AccessControl, SafeMath {
     
  
    address public petCardDataContract = 0xB340686da996b8B3d486b4D27E38E38500A9E926;
    address public ABTokenDataContract = 0xDC32FF5aaDA11b5cE3CAf2D00459cfDA05293F96;
    uint16 public maxRetireAura = 30;
    uint16 public minRetireAura = 10;
    
    uint64 public breedingDelay = 0;
    uint64 public breedingPrice = 0;
    uint8  public upgradeChance = 17;
 
    uint8  public bigAuraRand = 100;
    uint8  public smallAuraRand = 50;
    
    uint16 public elementalThreshold = 300;
    
     

 
struct ABCard {
    uint256 tokenId;       
        uint8 cardSeriesId;
         
        uint16 power;
         
        uint16 auraRed;
        uint16 auraYellow;
        uint16 auraBlue;
        string name;
        uint64 lastBattleTime;
     
    }
    
    
 

     
    function DataContacts(address _petCardDataContract, address _ABTokenDataContract) onlyCREATOR external {
        petCardDataContract = _petCardDataContract;
        ABTokenDataContract = _ABTokenDataContract;
    }
    
    function setParameters(uint16 _minRetireAura, uint16 _maxRetireAura, uint64 _breedingDelay, uint64 _breedingPrice, uint8 _upgradeChance, uint8 _bigAuraRand, uint8 _smallAuraRand) onlyCREATOR external {
        minRetireAura = _minRetireAura;
        maxRetireAura = _maxRetireAura;
        breedingDelay = _breedingDelay;
        breedingPrice = _breedingPrice;
        upgradeChance = _upgradeChance;
        bigAuraRand = _bigAuraRand;
        smallAuraRand = _smallAuraRand;
    }
     
      function getParameters() view external returns (uint16 _minRetireAura, uint16 _maxRetireAura, uint64 _breedingDelay, uint64 _breedingPrice, uint8 _upgradeChance, uint8 _bigAuraRand, uint8 _smallAuraRand)  {
        _minRetireAura = minRetireAura;
        _maxRetireAura = maxRetireAura;
        _breedingDelay = breedingDelay;
        _breedingPrice = breedingPrice;
        _upgradeChance = upgradeChance;
        _bigAuraRand = bigAuraRand;
        _smallAuraRand = smallAuraRand;
    }
     
     
      
      
     
     
    function checkPet (uint64  petID) private constant returns (uint8) {
        
        IPetCardData petCardData = IPetCardData(petCardDataContract);
         
         
        if ((petID <= 0) || (petID > petCardData.getTotalPets())) {return 0;}
        address petowner;
        uint8 petcardSeriesID;
      (,petcardSeriesID,,,,,,,,petowner) = petCardData.getPet(petID);
         if  (petowner != msg.sender)  {return 0;}
        return petcardSeriesID;
        
        
}
     function retireLegacyPets(uint64 pet1, uint64 pet2, uint64 pet3, uint64 pet4, uint64 pet5, uint64 pet6) public {
            IPetCardData petCardData = IPetCardData(petCardDataContract);
          
          
      
         if (checkPet(pet1) <5) {revert();}
         if (checkPet(pet2) <5) {revert();}
         if (checkPet(pet3) <5) {revert();}
         if (checkPet(pet4) <5) {revert();}
         if (checkPet(pet5) <5) {revert();}
         if (checkPet(pet6) <5) {revert();}
         
        uint8 _newLuck = getRandomNumber(39,30,msg.sender);
        uint8 base = 9;
         if ((checkPet(pet1) >8) && (checkPet(pet2) >8) && (checkPet(pet3) >8) && (checkPet(pet4) >8) && (checkPet(pet5) >8) && (checkPet(pet6) >8)) {
              
             _newLuck = getRandomNumber(49,40,msg.sender);
             base = 13;
         }
         
       petCardData.transferPet(msg.sender, address(0), pet1);
       petCardData.transferPet(msg.sender, address(0), pet2);
       petCardData.transferPet(msg.sender, address(0), pet3);
       petCardData.transferPet(msg.sender, address(0), pet4);
       petCardData.transferPet(msg.sender, address(0), pet5);
       petCardData.transferPet(msg.sender, address(0), pet6);
        
        getNewPetCard(getRandomNumber(base+4,9,msg.sender), _newLuck);
         
         }
     
      
         function check721Pet (uint256  petId) private constant returns (uint8) {
      
         IABToken ABTokenData = IABToken(ABTokenDataContract);
         
         
    
        address petowner;
        uint8 petCardSeriesId;
     
         (petCardSeriesId,,,,,,,,,,)  = ABTokenData.getABToken(petId);
         if  (ABTokenData.ownerOf(petId) != msg.sender)  {return 0;}
        return petCardSeriesId;
        }
     
     
      function retirePets(uint256 pet1, uint256 pet2, uint256 pet3, uint256 pet4, uint256 pet5, uint256 pet6) public {
        
          
          
      
        IABToken ABTokenData = IABToken(ABTokenDataContract);
      
         if (check721Pet(pet1) <28) {revert();}
         if (check721Pet(pet2) <28) {revert();}
         if (check721Pet(pet3) <28) {revert();}
         if (check721Pet(pet4) <28) {revert();}
         if (check721Pet(pet5) <28) {revert();}
         if (check721Pet(pet6) <28) {revert();}
         
        uint8 _newLuck = getRandomNumber(39,30,msg.sender);
        uint8 base = 31;
         if ((check721Pet(pet1) >31) && (check721Pet(pet2) >31) && (check721Pet(pet3) >31) && (check721Pet(pet4) >31) && (check721Pet(pet5) >31) && (check721Pet(pet6) >31)) {
              
             _newLuck = getRandomNumber(49,40,msg.sender);
             base = 35;
         }
          
        ABTokenData.transferFrom(address(this), address(0), pet1);
        ABTokenData.transferFrom(address(this), address(0), pet2);
        ABTokenData.transferFrom(address(this), address(0), pet3);
        ABTokenData.transferFrom(address(this), address(0), pet4);
        ABTokenData.transferFrom(address(this), address(0), pet5);
        ABTokenData.transferFrom(address(this), address(0), pet6);
            
        getNewPetCard(getRandomNumber(base+4,31,msg.sender), _newLuck);
         
     }
     
 
 

    
   function getNewPetCard(uint8 seriesId, uint8 _luck) private {
        uint16 _auraRed = getRandomNumber(maxRetireAura,minRetireAura,msg.sender);
        uint16 _auraYellow = getRandomNumber(maxRetireAura,minRetireAura,msg.sender);
        uint16 _auraBlue = getRandomNumber(maxRetireAura,minRetireAura,msg.sender);
      
       IABToken ABTokenData = IABToken(ABTokenDataContract);

        
       ABTokenData.mintABToken(msg.sender,seriesId + 23, _luck, _auraRed, _auraYellow,_auraBlue, "Lucky",0, 0);
    }



 
 
 
function getLevelFreePet(uint8 petSeriesId) public {
     
    IABToken ABTokenData = IABToken(ABTokenDataContract);
    require(petSeriesId >23 && petSeriesId <28, 'You must only use this to create a free pet');
    uint8 _power = getRandomNumber(19,10, msg.sender);
    ABTokenData.mintABToken(msg.sender, petSeriesId, _power, 2, 2, 2, 'Lucky', 0, 0);
}


 
 
 
      function BreedElemental (uint16 pet1Red, uint16 pet2Red, uint16 pet1Yellow, uint16 pet2Yellow, uint16 pet1Blue, uint16 pet2Blue) private {
          uint16 newPetRed;
          uint16 newPetYellow;
          uint16 newPetBlue;
          
           
          uint16 largest = pet1Red+pet2Red;
          uint8 petCardSeriesId = 40;
          newPetRed = largest - bigAuraRand;
          newPetBlue = getRandomNumber(bigAuraRand, 0, msg.sender);
          newPetYellow = getRandomNumber(bigAuraRand, 0, msg.sender);
         
          if ((pet1Yellow + pet2Yellow) > largest) {
              largest = pet1Yellow + pet2Yellow;
              petCardSeriesId = 42;
              newPetYellow = largest - bigAuraRand;
              newPetRed = getRandomNumber(bigAuraRand, 0, msg.sender);
              newPetBlue = getRandomNumber(bigAuraRand, 0, msg.sender);
          }
          if ((pet1Blue + pet2Blue) > largest) {
              largest = pet1Blue + pet2Blue;
              petCardSeriesId = 41;
              newPetBlue = largest - bigAuraRand;
              newPetRed = getRandomNumber(bigAuraRand, 0, msg.sender);
              newPetYellow = getRandomNumber(bigAuraRand, 0, msg.sender);
          }
          
        IABToken ABTokenData = IABToken(ABTokenDataContract);
        uint8 newPetPowerToCreate = getRandomNumber(59,50,msg.sender);
        
               
        ABTokenData.mintABToken(msg.sender,petCardSeriesId, newPetPowerToCreate, newPetRed, newPetYellow,newPetBlue,"lucky",0, 0);
        setNewPetLastBreedingTime();
          
      }
       

    function Breed (uint256  pet1Id, uint256 pet2Id) external payable  {
         
        IABToken ABTokenData = IABToken(ABTokenDataContract);
        if (msg.value < breedingPrice) {revert();}
         
          
        if ((ABTokenData.ownerOf(pet1Id) != msg.sender) || (ABTokenData.ownerOf(pet2Id) != msg.sender)) {revert();}
        
        ABCard memory pet1;
        ABCard memory pet2;
        (pet1.cardSeriesId,,pet1.auraRed,pet1.auraYellow,pet1.auraBlue,,,pet1.lastBattleTime,,,)  = ABTokenData.getABToken(pet1Id);
        (pet2.cardSeriesId,,pet2.auraRed,pet2.auraYellow,pet2.auraBlue,,,pet2.lastBattleTime,,,)  = ABTokenData.getABToken(pet1Id);
        
  if ((now < (pet1.lastBattleTime+breedingDelay)) || (now < (pet2.lastBattleTime+ breedingDelay))) {revert();}
   
     
   ABTokenData.setLastBattleTime(pet1Id);
   ABTokenData.setLastBattleTime(pet2Id);
   
   
   
   if ((pet1.cardSeriesId <24) || (pet1.cardSeriesId >39) || (pet2.cardSeriesId <24) || (pet2.cardSeriesId > 39)) {revert();}
    


   
    (uint8 petSeriesIDtoCreate, uint16 newPetPowerToCreate) =  getNewPetSeries(pet1.cardSeriesId, pet2.cardSeriesId);
 
    uint16 newPetRed =  findAuras(pet1.auraRed, pet2.auraRed);
    uint16 newPetYellow =  findAuras(pet1.auraYellow,pet2.auraYellow);
    uint16 newPetBlue =  findAuras(pet1.auraBlue, pet2.auraBlue);

    if (((pet1.cardSeriesId >35) && (pet2.cardSeriesId >35))  && ((getRandomNumber((pet1.auraRed + pet2.auraRed),0,msg.sender) > elementalThreshold) || (getRandomNumber((pet1.auraYellow + pet2.auraYellow),0,msg.sender) > elementalThreshold) || (getRandomNumber((pet1.auraRed + pet2.auraRed),0,msg.sender) > elementalThreshold))){
       
            BreedElemental (pet1.auraRed, pet2.auraRed, pet1.auraYellow, pet2.auraYellow, pet1.auraBlue, pet2.auraBlue);
    }
    
    else {
     
        ABTokenData.mintABToken(msg.sender,petSeriesIDtoCreate, newPetPowerToCreate, newPetRed, newPetYellow,newPetBlue,"lucky",0, 0);
        setNewPetLastBreedingTime();
   
        }
    }
   
    function getNewPetSeries (uint8 pet1CardSeries, uint8 pet2CardSeries) private returns (uint8 newPetLineToCreate, uint16 newPetPowerToCreate) {
      uint8 newPetLine = 0; 
        
       
        uint8 petRand = getRandomNumber(9,0,msg.sender); 
        uint8 petPowerRand = getRandomNumber(8,0,msg.sender) + 1;
         
        pet1CardSeries = (((pet1CardSeries - 24) - ((pet1CardSeries - 24) % 4)) + 1);
        pet2CardSeries = (((pet2CardSeries - 24) - ((pet2CardSeries - 24) % 4)) + 1);
        uint8 newPetPower =20 + petPowerRand;
        if (pet1CardSeries + pet2CardSeries + petRand > upgradeChance) {newPetPowerToCreate = 30 + petPowerRand;}
        if (pet1CardSeries + pet2CardSeries + petRand > upgradeChance + 8 ) {newPetPowerToCreate = 40 + petPowerRand;}
        
    if (getRandomNumber(100, 0, msg.sender) < 50) {
        if ((pet1CardSeries-24) % 4 == 0)  {newPetLine = 1;}  
        if ((pet1CardSeries-24) % 4 == 1)  {newPetLine = 2;}  
        if ((pet1CardSeries-24) % 4 == 2)  {newPetLine = 3;}  
        if ((pet1CardSeries-24) % 4 == 3)  {newPetLine = 4;}  
        
    }
    else {
        if ((pet2CardSeries-24) % 4 == 0)  {newPetLine = 1;}  
        if ((pet2CardSeries-24) % 4 == 1)  {newPetLine = 2;}  
        if ((pet2CardSeries-24) % 4 == 2)  {newPetLine = 3;}  
        if ((pet2CardSeries-24) % 4 == 3)  {newPetLine = 4;}  
    }
	

      (newPetLineToCreate, newPetPowerToCreate) = findNewPetType(newPetPower, newPetLine);
    
}

 

   function findNewPetType (uint16 _newPetPower, uint8 _newPetLine) private returns (uint8  newPetLine, uint16 newPetPower) {
    newPetPower = _newPetPower;
    newPetLine = _newPetLine;
    
    if (newPetPower < 20) {return;}
     
	if (newPetPower < 30) {newPetLine = (27 + _newPetLine);}   
	if (newPetPower < 40) {newPetLine = (31 + _newPetLine);}   
	if (newPetPower >= 40) {newPetLine = (35 + _newPetLine);}   
   }

 

        
    function findAuras (uint16 pet1Aura, uint16 pet2Aura) private returns (uint16) {
        if ((pet1Aura + pet2Aura) >= 300) {
       return (pet1Aura + pet2Aura - getRandomNumber (bigAuraRand,bigAuraRand-100,msg.sender)) ;
        }
          if ((pet1Aura + pet2Aura) >= 100) {
       return (pet1Aura + pet2Aura- getRandomNumber (smallAuraRand,smallAuraRand-50,msg.sender)) ;
        }
        if ((pet1Aura + pet2Aura) >= 30) {
       return (pet1Aura + pet2Aura- getRandomNumber (30,10,msg.sender)) ;
        }
        else {return 15;}
        
    }


 

function setNewPetLastBreedingTime () private {
    IABToken ABTokenData = IABToken(ABTokenDataContract);
    uint256 ownerTokens = ABTokenData.balanceOf(msg.sender);
    uint256 newPetID = ABTokenData.getABTokenByIndex(msg.sender, uint64(ownerTokens-1));
    ABTokenData.setLastBattleTime(newPetID);
    
   
}

    function withdrawEther() external onlyCREATOR {
    creatorAddress.transfer(this.balance);
}
        
      function kill() onlyCREATOR external {
        selfdestruct(creatorAddress);
    }
}