 

pragma solidity ^0.4.18;

 

contract DragonBallZ {
    
     
	address contractCreator = 0x606A19ea257aF8ED76D160Ad080782C938660A33;
    address devFeeAddress = 0xAe406d5900DCe1bB7cF3Bc5e92657b5ac9cBa34B;

	struct Hero {
		string heroName;
		address ownerAddress;
		address DBZHeroOwnerAddress;
		uint256 currentPrice;
		uint currentLevel;
	}
	Hero[] heroes;
	
	 
	uint256 heroMax = 55;
	
	 
    uint256[] winners;


	modifier onlyContractCreator() {
        require (msg.sender == contractCreator);
        _;
    }

    bool isPaused;
    
    
     
    function pauseGame() public onlyContractCreator {
        isPaused = true;
    }
    function unPauseGame() public onlyContractCreator {
        isPaused = false;
    }
    function GetGamestatus() public view returns(bool) {
        return(isPaused);
    }

     
	function purchaseHero(uint _heroId) public payable {
	     
		require(msg.value == heroes[_heroId].currentPrice);
		
		 
		require(isPaused == false);
		
		 
		uint256 TournamentPrizeFee = (msg.value / 10);  
	    
		 
		uint256 devFee = ((msg.value / 10)/2);   
		
		 
		uint256 DBZHeroOwnerCommission = (msg.value / 10);  

		 
		uint256 commissionOwner = (msg.value - (devFee + TournamentPrizeFee + DBZHeroOwnerCommission)); 
		heroes[_heroId].ownerAddress.transfer(commissionOwner);  

		 
		heroes[_heroId].DBZHeroOwnerAddress.transfer(DBZHeroOwnerCommission);  

		
		 
		devFeeAddress.transfer(devFee);  
		
		 
		heroes[_heroId].currentLevel +=1;

		 
		heroes[_heroId].ownerAddress = msg.sender;
		heroes[_heroId].currentPrice = mul(heroes[_heroId].currentPrice, 2);
	}
	
	 
	function updateDBZHeroDetails(uint _heroId, string _heroName,address _ownerAddress, address _newDBZHeroOwnerAddress, uint _currentLevel) public onlyContractCreator{
	    require(heroes[_heroId].ownerAddress != _newDBZHeroOwnerAddress);
		heroes[_heroId].heroName = _heroName;		
		heroes[_heroId].ownerAddress = _ownerAddress;
	    heroes[_heroId].DBZHeroOwnerAddress = _newDBZHeroOwnerAddress;
	    heroes[_heroId].currentLevel = _currentLevel;
	}
	
	 
	function modifyCurrentHeroPrice(uint _heroId, uint256 _newPrice) public {
	    require(_newPrice > 0);
	    require(heroes[_heroId].ownerAddress == msg.sender);
	    require(_newPrice < heroes[_heroId].currentPrice);
	    heroes[_heroId].currentPrice = _newPrice;
	}
	
	 
	function getHeroDetails(uint _heroId) public view returns (
        string heroName,
        address ownerAddress,
        address DBZHeroOwnerAddress,
        uint256 currentPrice,
        uint currentLevel
    ) {
        Hero storage _hero = heroes[_heroId];

        heroName = _hero.heroName;
        ownerAddress = _hero.ownerAddress;
        DBZHeroOwnerAddress = _hero.DBZHeroOwnerAddress;
        currentPrice = _hero.currentPrice;
        currentLevel = _hero.currentLevel;
    }
    
     
    function getHeroCurrentPrice(uint _heroId) public view returns(uint256) {
        return(heroes[_heroId].currentPrice);
    }
    
     
    function getHeroCurrentLevel(uint _heroId) public view returns(uint256) {
        return(heroes[_heroId].currentLevel);
    }
    
     
    function getHeroOwner(uint _heroId) public view returns(address) {
        return(heroes[_heroId].ownerAddress);
    }
    
     
    function getHeroDBZHeroAddress(uint _heroId) public view returns(address) {
        return(heroes[_heroId].DBZHeroOwnerAddress);
    }
    
     
    function getTotalPrize() public view returns(uint256) {
        return this.balance;
    }
    
     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
          return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        uint256 c = a / b;
         
        return c;
    }
    
	 
	function addHero(string _heroName, address _ownerAddress, address _DBZHeroOwnerAddress, uint256 _currentPrice, uint _currentLevel) public onlyContractCreator {
        heroes.push(Hero(_heroName,_ownerAddress,_DBZHeroOwnerAddress,_currentPrice,_currentLevel));
    }
     
        
    function getWinner() public onlyContractCreator returns (uint256[]) {
        uint i;
		
		 
		for(i=0;i<=4;i++){
		     
			winners.push(uint256(sha256(block.timestamp, block.number-i-1)) % heroMax);
		}
		
		return winners;
    }

     
    function getWinnerDetails(uint _winnerId) public view returns(uint256) {
        return(winners[_winnerId]);
    }
    
     
    function payoutWinners() public onlyContractCreator {
         
        uint256 TotalPrize20PercentShare = (this.balance/5);
        uint i;
			for(i=0;i<=4;i++){
			     
			    uint _heroID = getWinnerDetails(i);
			     
			    address winner = heroes[_heroID].ownerAddress;
			    
			    if(winner != address(0)){
			      
                 winner.transfer(TotalPrize20PercentShare);			       
			    }
			    
			     
			    winner = address(0);
			}
    }
    
}