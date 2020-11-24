 

pragma solidity ^0.4.17;
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

    function getRandomNumber(uint16 maxRandom, uint8 min, address privateAddress) constant public returns(uint8) {
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
    
     
    function AccessControl() public {
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



contract PetCardData is IPetCardData, SafeMath {
     
    event CreatedPet(uint64 petId);
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

     
    struct PetCardSeries {
        uint8 petCardSeriesId;
        uint32 currentPetTotal;
        uint32 maxPetTotal;
    }

    struct Pet {
        uint64 petId;
        uint8 petCardSeriesId;
        address owner;
        string name;
        uint8 luck;
        uint16 auraRed;
        uint16 auraYellow;
        uint16 auraBlue;
        uint64 lastTrainingTime;
        uint64 lastBreedingTime;
        uint price; 
    }


     
  
    mapping(uint8 => PetCardSeries) public petCardSeriesCollection;
    mapping(uint => Pet) public petCollection;
    mapping(address => uint64[]) public ownerPetCollection;
    
     
     
    function PetCardData() public {
        
    }

     
    function createPetCardSeries(uint8 _petCardSeriesId, uint32 _maxTotal) onlyCREATOR public returns(uint8) {
     if ((now > 1516642200) || (totalPetCardSeries >= 19)) {revert();}
         
      
       PetCardSeries storage petCardSeries = petCardSeriesCollection[_petCardSeriesId];
        petCardSeries.petCardSeriesId = _petCardSeriesId;
        petCardSeries.maxPetTotal = _maxTotal;
        totalPetCardSeries += 1;
        return totalPetCardSeries;
    }
	
	function setPet(uint8 _petCardSeriesId, address _owner, string _name, uint8 _luck, uint16 _auraRed, uint16 _auraYellow, uint16 _auraBlue) onlySERAPHIM external returns(uint64) { 
        PetCardSeries storage series = petCardSeriesCollection[_petCardSeriesId];

        if (series.currentPetTotal >= series.maxPetTotal) {
            revert();
        }
        else {
        totalPets += 1;
        series.currentPetTotal +=1;
        Pet storage pet = petCollection[totalPets];
        pet.petId = totalPets;
        pet.petCardSeriesId = _petCardSeriesId;
        pet.owner = _owner;
        pet.name = _name;
        pet.luck = _luck;
        pet.auraRed = _auraRed;
        pet.auraYellow = _auraYellow;
        pet.auraBlue = _auraBlue;
        pet.lastTrainingTime = 0;
        pet.lastBreedingTime = 0;
        addPetIdMapping(_owner, pet.petId);
        }
    }

    function setPetAuras(uint64 _petId, uint8 _auraRed, uint8 _auraBlue, uint8 _auraYellow) onlySERAPHIM external {
        Pet storage pet = petCollection[_petId];
        if (pet.petId == _petId) {
            pet.auraRed = _auraRed;
            pet.auraBlue = _auraBlue;
            pet.auraYellow = _auraYellow;
        }
    }

    function setPetName(string _name, uint64 _petId) public {
        Pet storage pet = petCollection[_petId];
        if ((pet.petId == _petId) && (msg.sender == pet.owner)) {
            pet.name = _name;
        }
    }


    function setPetLastTrainingTime(uint64 _petId) onlySERAPHIM external {
        Pet storage pet = petCollection[_petId];
        if (pet.petId == _petId) {
            pet.lastTrainingTime = uint64(now);
        }
    }

    function setPetLastBreedingTime(uint64 _petId) onlySERAPHIM external {
        Pet storage pet = petCollection[_petId];
        if (pet.petId == _petId) {
            pet.lastBreedingTime = uint64(now);
        }
    }
    
    function addPetIdMapping(address _owner, uint64 _petId) private {
            uint64[] storage owners = ownerPetCollection[_owner];
            owners.push(_petId);
            Pet storage pet = petCollection[_petId];
            pet.owner = _owner;
             
             
        
    }
	
	function transferPet(address _from, address _to, uint64 _petId) onlySERAPHIM public returns(ResultCode) {
        Pet storage pet = petCollection[_petId];
        if (pet.owner != _from) {
            return ResultCode.ERROR_NOT_OWNER;
        }
        if (_from == _to) {revert();}
        addPetIdMapping(_to, _petId);
        pet.owner = _to;
        return ResultCode.SUCCESS;
    }
    
     
    
  function ownerPetTransfer (address _to, uint64 _petId)  public  {
     
        if ((_petId > totalPets) || (_petId == 0)) {revert();}
       if (msg.sender == _to) {revert();}  
        if (pet.owner != msg.sender) {
            revert();
        }
        else {
      Pet storage pet = petCollection[_petId];
        pet.owner = _to;
        addPetIdMapping(_to, _petId);
        }
    }

     
    function getPetCardSeries(uint8 _petCardSeriesId) constant public returns(uint8 petCardSeriesId, uint32 currentPetTotal, uint32 maxPetTotal) {
        PetCardSeries memory series = petCardSeriesCollection[_petCardSeriesId];
        petCardSeriesId = series.petCardSeriesId;
        currentPetTotal = series.currentPetTotal;
        maxPetTotal = series.maxPetTotal;
    }
	
	function getPet(uint _petId) constant public returns(uint petId, uint8 petCardSeriesId, string name, uint8 luck, uint16 auraRed, uint16 auraBlue, uint16 auraYellow, uint64 lastTrainingTime, uint64 lastBreedingTime, address owner) {
        Pet memory pet = petCollection[_petId];
        petId = pet.petId;
        petCardSeriesId = pet.petCardSeriesId;
        name = pet.name;
        luck = pet.luck;
        auraRed = pet.auraRed;
        auraBlue = pet.auraBlue;
        auraYellow = pet.auraYellow;
        lastTrainingTime = pet.lastTrainingTime;
        lastBreedingTime = pet.lastBreedingTime;
        owner = pet.owner;
    }
	
	function getOwnerPetCount(address _owner) constant public returns(uint) {
        return ownerPetCollection[_owner].length;
    }
	
	function getPetByIndex(address _owner, uint _index) constant public returns(uint) {
        if (_index >= ownerPetCollection[_owner].length)
            return 0;
        return ownerPetCollection[_owner][_index];
    }

    function getTotalPetCardSeries() constant public returns (uint8) {
        return totalPetCardSeries;
    }

    function getTotalPets() constant public returns (uint) {
        return totalPets;
    }
}