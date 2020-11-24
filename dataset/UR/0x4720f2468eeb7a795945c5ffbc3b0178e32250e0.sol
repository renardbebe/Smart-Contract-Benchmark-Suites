 

pragma solidity ^0.4.23;

 

 
contract Ownable {
    address public owner;
    address public cfoAddress;

    constructor() public{
        owner = msg.sender;
        cfoAddress = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    modifier onlyCFO() {
        require(msg.sender == cfoAddress);
        _;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
    
    function setCFO(address newCFO) external onlyOwner {
        require(newCFO != address(0));

        cfoAddress = newCFO;
    }
}

 
contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;

     
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

     
    modifier whenPaused() {
        require(paused);
        _;
    }


     
    function pause() onlyOwner whenNotPaused public {
        paused = true;
        emit Pause();
    }

     
    function unpause() onlyOwner whenPaused public {
        paused = false;
        emit Unpause();
    }
}

 
contract MixGenInterface {
    function isMixGen() public pure returns (bool);
    function openEgg(uint64 userNumber, uint16 eggQuality) public returns (uint256 genes, uint16 quality);
    function uniquePet(uint64 newPetId) public returns (uint256 genes, uint16 quality);
}

contract RewardContract {
     function get(address receiver, uint256 ethValue) external;
}

 
contract ExternalContracts is Ownable {
    MixGenInterface public geneScience;
    RewardContract public reward;
    
    address public storeAddress;
    
    function setMixGenAddress(address _address) external onlyOwner {
        MixGenInterface candidateContract = MixGenInterface(_address);
        require(candidateContract.isMixGen());
        
        geneScience = candidateContract;
    }
    
    function setStoreAddress(address _address) external onlyOwner {
        storeAddress = _address;
    }
        
    function setRewardAddress(address _address) external onlyOwner {
        reward = RewardContract(_address);
    }
}

 
contract PopulationControl is Pausable {
    
     
    uint32 public breedTimeout = 12 hours;
    uint32 maxTimeout = 178 days;
    
    function setBreedTimeout(uint32 timeout) external onlyOwner {
        require(timeout <= maxTimeout);
        
        breedTimeout = timeout;
    }
}

 

 
contract PetBase is PopulationControl{
    
     
    event Birth(address owner, uint64 petId, uint16 quality, uint256 genes);
    event Death(uint64 petId);
    
    event Transfer(address from, address to, uint256 tokenId);
    
     
    struct Pet {
        uint256 genes;
        uint64 birthTime;
        uint16 quality;
    }
    
    mapping (uint64 => Pet) pets;
    mapping (uint64 => address) petIndexToOwner;
    mapping (address => uint256) public ownershipTokenCount;
    mapping (uint64 => uint64) breedTimeouts;
 
    uint64 tokensCount;
    uint64 lastTokenId;

     
    function createPet(
        uint256 _genes,
        uint16 _quality,
        address _owner
    )
        internal
        returns (uint64)
    {
        Pet memory _pet = Pet({
            genes: _genes,
            birthTime: uint64(now),
            quality: _quality
        });
               
        lastTokenId++;
        tokensCount++;
		
        uint64 newPetId = lastTokenId;
                
        pets[newPetId] = _pet;
        
        _transfer(0, _owner, newPetId);
        
        breedTimeouts[newPetId] = uint64( now + (breedTimeout / 2) );
        emit Birth(_owner, newPetId, _quality, _genes);

        return newPetId;
    }
    
     
    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        uint64 _tokenId64bit = uint64(_tokenId);
        
        ownershipTokenCount[_to]++;
        petIndexToOwner[_tokenId64bit] = _to;
        if (_from != address(0)) {
            ownershipTokenCount[_from]--;
        }
        
         emit Transfer(_from, _to, _tokenId);
    }
    
	 
    function recommendedPrice(uint16 quality) public pure returns(uint256 price) {
        
        require(quality <= uint16(0xF000));
        require(quality >= uint16(0x1000));
        
        uint256 startPrice = 1000;
        
        price = startPrice;
        
        uint256 revertQuality = uint16(0xF000) - quality;
        uint256 oneLevel = uint16(0x2000);
        uint256 oneQuart = oneLevel/4;
        
        uint256 fullLevels = revertQuality/oneLevel;
        uint256 fullQuarts =  (revertQuality % oneLevel) / oneQuart ;
        
        uint256 surplus = revertQuality - (fullLevels*oneLevel) - (fullQuarts*oneQuart);
        
        
         
        price = price * 44**fullLevels;
        price = price / 10**fullLevels;
        
         
        if(fullQuarts != 0)
        {
            price = price * 14483154**fullQuarts;
            price = price / 10**(7 * fullQuarts);
        }

         
        if(surplus != 0)
        {
            uint256 nextQuartPrice = (price * 14483154) / 10**7;
            uint256 surPlusCoefficient = surplus * 10**6  /oneQuart;
            uint256 surPlusPrice = ((nextQuartPrice - price) * surPlusCoefficient) / 10**6;
            
            price+= surPlusPrice;
        }
        
        price*= 50 szabo;
    }
    
	 
    function getGradeByQuailty(uint16 quality) public pure returns (uint8 grade) {
        
        require(quality <= uint16(0xF000));
        require(quality >= uint16(0x1000));
        
        if(quality == uint16(0xF000))
            return 7;
        
        quality+= uint16(0x1000);
        
        return uint8 ( quality / uint16(0x2000) );
    }
}

 
contract PetOwnership is PetBase {

     
    function transfer(
        address _to,
        uint256 _tokenId
    )
        external
        whenNotPaused
    {
        require(_to != address(0));
        require(_to != address(this));
        require(_owns(msg.sender, uint64(_tokenId)));

        _transfer(msg.sender, _to, _tokenId);
    }
 
	 
    function _owns(address _claimant, uint64 _tokenId) internal view returns (bool) {
        return petIndexToOwner[_tokenId] == _claimant;
    }
    
	 
    function ownerOf(uint256 _tokenId) external view returns (address owner) {
        uint64 _tokenId64bit = uint64(_tokenId);
        owner = petIndexToOwner[_tokenId64bit];
        
        require(owner != address(0));
    }   
}

 
contract EggMinting is PetOwnership{
    
    uint8 public uniquePetsCount = 100;
    
    uint16 public globalPresaleLimit = 1500;

    mapping (uint16 => uint16) public eggLimits;
    mapping (uint16 => uint16) public purchesedEggs;
    
    constructor() public {
        eggLimits[55375] = 200;
        eggLimits[47780] = 400;
        eggLimits[38820] = 100;
        eggLimits[31201] = 50;
    }
    
    function totalSupply() public view returns (uint) {
        return tokensCount;
    }
    
    function setEggLimit(uint16 quality, uint16 limit) external onlyOwner {
        eggLimits[quality] = limit;
    }

    function eggAvailable(uint16 quality) constant public returns(bool) {
         
        if( quality < 47000 && tokensCount < ( 100 + uniquePetsCount ) )
           return false;
        
        return (eggLimits[quality] > purchesedEggs[quality]);
    }
}

 
contract EggPurchase is EggMinting, ExternalContracts {
    
    uint16[4] discountThresholds =    [20, 100, 250, 500];
    uint8[4]  discountPercents   =    [75, 50,  30,  20 ];
    
	 
    function purchaseEgg(uint64 userNumber, uint16 quality) external payable whenNotPaused {

        require(tokensCount >= uniquePetsCount);
		
         
        require(eggAvailable(quality));
        
         
        require(tokensCount <= globalPresaleLimit);

         
        uint256 eggPrice = ( recommendedPrice(quality) * (100 - getCurrentDiscountPercent()) ) / 100;

         
        require(msg.value >= eggPrice);
        
         
        purchesedEggs[quality]++;
        
         
        uint256 childGenes;
        uint16 childQuality;

         
        (childGenes, childQuality) = geneScience.openEgg(userNumber, quality);
         
         
        createPet(
            childGenes,       
            childQuality,     
            msg.sender        
        );
        
        reward.get(msg.sender, recommendedPrice(quality));
    }
    
    function getCurrentDiscountPercent() constant public returns (uint8 discount) {
        
        for(uint8 i = 0; i <= 3; i++)
        {
            if(tokensCount < (discountThresholds[i] + uniquePetsCount ))
                return discountPercents[i];
        }
        
        return 10;
    }
}

 
contract PreSale is EggPurchase {
    
    constructor() public {
        paused = true;
    }
        
    function generateUniquePets(uint8 count) external onlyOwner whenNotPaused {
        
        require(storeAddress != address(0));
        require(address(geneScience) != address(0));
        require(tokensCount < uniquePetsCount);
        
        uint256 childGenes;
        uint16 childQuality;
        uint64 newPetId;

        for(uint8 i = 0; i< count; i++)
        {
            if(tokensCount >= uniquePetsCount)
                continue;
            
            newPetId = tokensCount+1;

            (childGenes, childQuality) = geneScience.uniquePet(newPetId);
            createPet(childGenes, childQuality, storeAddress);
        }
    }
    
    function getPet(uint256 _id) external view returns (
        uint64 birthTime,
        uint256 genes,
        uint64 breedTimeout,
        uint16 quality,
        address owner
    ) {
        uint64 _tokenId64bit = uint64(_id);
        
        Pet storage pet = pets[_tokenId64bit];
        
        birthTime = pet.birthTime;
        genes = pet.genes;
        breedTimeout = uint64(breedTimeouts[_tokenId64bit]);
        quality = pet.quality;
        owner = petIndexToOwner[_tokenId64bit];
    }
    
    function unpause() public onlyOwner whenPaused {
        require(address(geneScience) != address(0));
		require(address(reward) != address(0));

        super.unpause();
    }
    
    function withdrawBalance(uint256 summ) external onlyCFO {
        cfoAddress.transfer(summ);
    }
}