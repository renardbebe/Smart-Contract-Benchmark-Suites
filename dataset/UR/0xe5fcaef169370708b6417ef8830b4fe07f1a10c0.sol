 

 

pragma solidity ^0.4.18;


 
 
contract OwnerBase {

     
    address public ceoAddress;
    address public cfoAddress;
    address public cooAddress;

     
    bool public paused = false;
    
     
    function OwnerBase() public {
       ceoAddress = msg.sender;
       cfoAddress = msg.sender;
       cooAddress = msg.sender;
    }

     
    modifier onlyCEO() {
        require(msg.sender == ceoAddress);
        _;
    }

     
    modifier onlyCFO() {
        require(msg.sender == cfoAddress);
        _;
    }
    
     
    modifier onlyCOO() {
        require(msg.sender == cooAddress);
        _;
    }

     
     
    function setCEO(address _newCEO) external onlyCEO {
        require(_newCEO != address(0));

        ceoAddress = _newCEO;
    }


     
     
    function setCFO(address _newCFO) external onlyCEO {
        require(_newCFO != address(0));

        cfoAddress = _newCFO;
    }
    
     
     
    function setCOO(address _newCOO) external onlyCEO {
        require(_newCOO != address(0));

        cooAddress = _newCOO;
    }

     
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

     
    modifier whenPaused {
        require(paused);
        _;
    }

     
     
    function pause() external onlyCOO whenNotPaused {
        paused = true;
    }

     
     
     
     
     
    function unpause() public onlyCOO whenPaused {
         
        paused = false;
    }
}



 
contract FighterCamp {
    
     
    function isCamp() public pure returns (bool);
    
     
    function getFighter(uint _tokenId) external view returns (uint32);
    
}


 
 
contract RabbitArena is OwnerBase {
    
	event FightersReady(uint32 season);
    event SeasonWinner(uint32 season, uint winnerID);
    
	
    struct Fighter {
        uint tokenID;
        uint32 strength;
    }
	
     
    FighterCamp public theCamp; 
	
	
	mapping (uint => Fighter) soldiers;
	
	
	uint32[] public seasons;
    
    
	uint32 public matchDay;
	
	
	 
	function RabbitArena(address _camp) public {
		FighterCamp tmp = FighterCamp(_camp);
        require(tmp.isCamp());
        theCamp = tmp;
	}
    
    
    
     
    function setBaseInfo(address _camp) external onlyCOO {
        FighterCamp tmp = FighterCamp(_camp);
        require(tmp.isCamp());
        theCamp = tmp;
    }
	
	
	 
	function releaseOldData() internal {
		for (uint i = 0; i < seasons.length; i++) {
            uint _season = seasons[i];
			for (uint j = 0; j < 8; j++) {
				uint key = _season * 1000 + j;
				delete soldiers[key];
			}
        }
		delete seasons; 
	}

    
     
    function setFighters(uint32 _today, uint32 _season, uint[] _tokenIDs) external onlyCOO {
		require(_tokenIDs.length == 8);
		
		if (matchDay != _today) {
			releaseOldData();
			matchDay = _today;
		}
		seasons.push(_season); 
		
         
        for(uint i = 0; i < 8; i++) {
            uint tmpID = _tokenIDs[i];
            
            Fighter memory soldier = Fighter({
                tokenID: tmpID,
				strength: theCamp.getFighter(tmpID)
            });
			
			uint key = _season * 1000 + i;
            soldiers[key] = soldier;
        }
        
         
        emit FightersReady(_season);
    }
    
    
     
    function getFighterInfo(uint32 _season, uint32 _index) external view returns (
        uint outTokenID,
        uint32 outStrength
    ) {
		require(_index < 8);
		uint key = _season * 1000 + _index;
        
        Fighter storage soldier = soldiers[key];
		require(soldier.strength > 0);
        
        outTokenID = soldier.tokenID;
        outStrength = soldier.strength;
    }
    
    
     
     
     
    function processOneCombat(uint32 _season, uint32 _seed) external onlyCOO 
    {
        uint[] memory powers = new uint[](8);
        
		uint sumPower = 0;
        uint i = 0;
		uint key = 0;
        for (i = 0; i < 8; i++) {
			key = _season * 1000 + i;
            Fighter storage soldier = soldiers[key];
            powers[i] = soldier.strength;
            sumPower = sumPower + soldier.strength;
        }
        
        uint sumValue = 0;
		uint tmpPower = 0;
        for (i = 0; i < 8; i++) {
            tmpPower = powers[i] ** 5; 
            sumValue += tmpPower;
            powers[i] = sumValue;
        }
        uint singleDeno = sumPower ** 5;
        uint randomVal = _getRandom(_seed);
        
        uint winner = 0;
        uint shoot = sumValue * randomVal * 10000000000 / singleDeno / 0xffffffff;
        for (i = 0; i < 8; i++) {
            tmpPower = powers[i];
            if (shoot <= tmpPower * 10000000000 / singleDeno) {
                winner = i;
                break;
            }
        }
		
		key = _season * 1000 + winner;
		Fighter storage tmp = soldiers[key];        
        emit SeasonWinner(_season, tmp.tokenID);
    }
    
    
     
     
    function _getRandom(uint32 _seed) pure internal returns(uint32) {
        return uint32(keccak256(_seed));
    }
}