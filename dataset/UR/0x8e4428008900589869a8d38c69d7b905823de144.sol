 

pragma solidity ^0.4.25;

 
contract Ownable {
    address public owner;

    constructor() public{
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
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

 
contract ParentInterface {
    function ownerOf(uint256 _tokenId) external view returns (address owner);
    function getPet(uint256 _id) external view returns (uint64 birthTime, uint256 genes,uint64 breedTimeout,uint16 quality,address owner);
    function totalSupply() public view returns (uint);
}

 
contract Utils {
    
    function getGradeByQuailty(uint16 quality) public pure returns (uint8 grade) {
        
        require(quality <= uint16(0xF000));
        require(quality >= uint16(0x1000));
        
        if(quality == uint16(0xF000))
            return 7;
        
        quality+= uint16(0x1000);
        
        return uint8 ( quality / uint16(0x2000) );
    }
    
    function seatsByGrade(uint8 grade) public pure returns(uint8 seats) {
	    if(grade > 4)
	        return 1;
	
		seats = 8 - grade - 2;

		return seats;
	}
}

 
contract ReferralQueue {
    
     
    uint64 currentReceiverId = 1;

     
    uint64 public circleLength;
    
     
    struct ReferralSeat {
        uint64 petId;
        uint64 givenPetId;
    }
    
    mapping (uint64 => ReferralSeat) public referralCircle;
    
     
    struct PetInfo {
        uint64 parentId;
        uint256 amount;
    }
    
    mapping (uint64 => PetInfo) public petsInfo;

    
    function addPetIntoCircle(uint64 _id, uint8 _seats) internal {
        
         
        for(uint8 i=0; i < _seats; i++)
		{
		    ReferralSeat memory _seat = ReferralSeat({
                petId: _id,
                givenPetId: 0
            });

             
            circleLength++;
            referralCircle[circleLength] = _seat;
		}
		
		 
		 
		if(_id>103) {
		    
		    referralCircle[currentReceiverId].givenPetId = _id;
		    
		     
		    PetInfo memory petInfo = PetInfo({
		        parentId: referralCircle[currentReceiverId].petId,
		        amount: 0
		    });
		    
		    petsInfo[_id] = petInfo;
		    
		     
            currentReceiverId++;
        }
    }
    
     
    function getCurrentReceiverId() view public returns(uint64 receiverId) {
        
        return referralCircle[currentReceiverId].petId;
    }
}

contract Reward is ReferralQueue {
    
     
    function getEggPrice(uint64 _petId, uint16 _quality) pure public returns(uint256 price) {
        		
        uint64[6] memory egg_prices = [0, 150 finney, 600 finney, 3 ether, 12 ether, 600 finney];
        
		uint8 egg = 2;
	
		if(_quality > 55000)
		    egg = 1;
			
		if(_quality > 26000 && _quality < 26500)
			egg = 3;
			
		if(_quality > 39100 && _quality < 39550)
			egg = 3;
			
		if(_quality > 31000 && _quality < 31250)
			egg = 4;
			
		if(_quality > 34500 && _quality < 35500)
			egg = 5;
			
		price = egg_prices[egg];
		
		uint8 discount = 10;
		
		if(_petId<= 600)
			discount = 20;
		if(_petId<= 400)
			discount = 30;
		if(_petId<= 200)
			discount = 50;
		if(_petId<= 120)
			discount = 80;
		
		price = price - (price*discount / 100);
    }
    
     
    function applyReward(uint64 _petId, uint16 _quality) internal {
        
        uint8[6] memory rewardByLevel = [0,250,120,60,30,15];
        
        uint256 eggPrice = getEggPrice(_petId, _quality);
        
        uint64 _currentPetId = _petId;
        
         
        for(uint8 level=1; level<=5; level++) {
            uint64 _parentId = petsInfo[_currentPetId].parentId;
             
            if(_parentId == 0)
                break;
            
             
            petsInfo[_parentId].amount+= eggPrice * rewardByLevel[level] / 1000;
            
             
            _currentPetId = _parentId;
        }
        
    }
    
     
    function applyRewardByAmount(uint64 _petId, uint256 _price) internal {
        
        uint8[6] memory rewardByLevel = [0,250,120,60,30,15];
        
        uint64 _currentPetId = _petId;
        
         
        for(uint8 i=1; i<=5; i++) {
            uint64 _parentId = petsInfo[_currentPetId].parentId;
             
            if(_parentId == 0)
                break;
            
             
            petsInfo[_parentId].amount+= _price * rewardByLevel[i] / 1000;
            
             
            _currentPetId = _parentId;
        }
        
    }
}

 
contract ReferralCircle is Reward, Utils, Pausable {
    
     
    ParentInterface public parentInterface;
    
     
    uint8 public syncLimit = 5;
    
     
    uint64 public lastPetId = 100;
    
     
    bool public petSyncEnabled = true;
    
     
    constructor() public {
        parentInterface = ParentInterface(0x115f56742474f108AD3470DDD857C31a3f626c3C);
    }

     
    function disablePetSync() external onlyOwner {
        petSyncEnabled = false;
    }

     
    function enablePetSync() external onlyOwner {
        petSyncEnabled = true;
    }
    
     
    function sync() external whenNotPaused {
        
         
        require(petSyncEnabled);
        
         
        uint64 petSupply = uint64(parentInterface.totalSupply());
        require(petSupply > lastPetId);

         
        for(uint8 i=0; i < syncLimit; i++)
        {
            lastPetId++;
            
            if(lastPetId > petSupply)
            {
                lastPetId = petSupply;
                break;
            }
            
            addPet(lastPetId);
        }
    }
    
     
    function setSyncLimit(uint8 _limit) external onlyOwner {
        syncLimit = _limit;
    }

     
    function addPet(uint64 _id) internal {
        (uint64 birthTime, uint256 genes, uint64 breedTimeout, uint16 quality, address owner) = parentInterface.getPet(_id);
        
        uint16 gradeQuality = quality;

         
        if(_id < 244)
			gradeQuality = quality - 13777;
			
		 
        uint8 petGrade = getGradeByQuailty(gradeQuality);
        uint8 petSeats = seatsByGrade(petGrade);
        
         
        addPetIntoCircle(_id, petSeats);
        
         
        applyReward(_id, quality);
    }
    
     
    function automaticPetAdd(uint256 _price, uint16 _quality, uint64 _id) external {
        require(!petSyncEnabled);
        require(msg.sender == address(parentInterface));
        
        lastPetId = _id;
        
         
        uint8 petGrade = getGradeByQuailty(_quality);
        uint8 petSeats = seatsByGrade(petGrade);
        
         
        addPetIntoCircle(_id, petSeats);
        
         
        applyRewardByAmount(_id, _price);
    }
    
     
    function withdrawReward(uint64 _petId) external whenNotPaused {
        
         
        PetInfo memory petInfo = petsInfo[_petId];
        
         
         (uint64 birthTime, uint256 genes, uint64 breedTimeout, uint16 quality, address petOwner) = parentInterface.getPet(_petId);
        require(petOwner == msg.sender);

         
        msg.sender.transfer(petInfo.amount);
        
         
        petInfo.amount = 0;
        petsInfo[_petId] = petInfo;
    }
    
     
    function sendRewardByAdmin(uint64 _petId) external onlyOwner whenNotPaused {
        
         
        PetInfo memory petInfo = petsInfo[_petId];
        
         
        (uint64 birthTime, uint256 genes, uint64 breedTimeout, uint16 quality, address petOwner) = parentInterface.getPet(_petId);

         
        petOwner.transfer(petInfo.amount);
        
         
        petInfo.amount = 0;
        petsInfo[_petId] = petInfo;
    }
        
     
    function setParentAddress(address _address) public whenPaused onlyOwner
    {
        parentInterface = ParentInterface(_address);
    }

     
    function () public payable {}
    
     
    function withdrawBalance(uint256 summ) external onlyOwner {
        owner.transfer(summ);
    }
}