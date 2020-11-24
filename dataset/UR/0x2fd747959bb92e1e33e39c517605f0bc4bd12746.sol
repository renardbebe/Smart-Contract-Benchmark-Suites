 

pragma solidity ^0.4.18;

contract NBACrypto {

	address ceoAddress = 0xD2f0e35EB79789Ea24426233336DDa6b13E2fA1f;
    address cfoAddress = 0x831a278fF506bf4dAa955359F9c5DA9B9Be18f3A;

	struct Team {
		string name;
		address ownerAddress;
		uint256 curPrice;
	}
	Team[] teams;

	modifier onlyCeo() {
        require (msg.sender == ceoAddress);
        _;
    }

    bool teamsAreInitiated;
    bool isPaused;
    
     
    function pauseGame() public onlyCeo {
        isPaused = true;
    }
    function unPauseGame() public onlyCeo {
        isPaused = false;
    }
    function GetIsPauded() public view returns(bool) {
       return(isPaused);
    }

     
	function purchaseCountry(uint _countryId) public payable {
		require(msg.value == teams[_countryId].curPrice);
		require(isPaused == false);

		 
		uint256 commission5percent = (msg.value / 10);

		 
		uint256 commissionOwner = msg.value - commission5percent;  
		teams[_countryId].ownerAddress.transfer(commissionOwner);

		 
		cfoAddress.transfer(commission5percent);  

		 
		teams[_countryId].ownerAddress = msg.sender;
		teams[_countryId].curPrice = mul(teams[_countryId].curPrice, 2);
	}
	
	 
	function modifyPriceCountry(uint _teamId, uint256 _newPrice) public {
	    require(_newPrice > 0);
	    require(teams[_teamId].ownerAddress == msg.sender);
	    require(_newPrice < teams[_teamId].curPrice);
	    teams[_teamId].curPrice = _newPrice;
	}
	
	 
	function getTeam(uint _teamId) public view returns (
        string name,
        address ownerAddress,
        uint256 curPrice
    ) {
        Team storage _team = teams[_teamId];

        name = _team.name;
        ownerAddress = _team.ownerAddress;
        curPrice = _team.curPrice;
    }
    
     
    function getTeamPrice(uint _teamId) public view returns(uint256) {
        return(teams[_teamId].curPrice);
    }
    
     
    function getTeamOwner(uint _teamId) public view returns(address) {
        return(teams[_teamId].ownerAddress);
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

	 
	function InitiateTeams() public onlyCeo {
		require(teamsAreInitiated == false);
        teams.push(Team("Raptors", cfoAddress, 750000000000000000)); 
		teams.push(Team("Rockets", cfoAddress, 750000000000000000)); 
		teams.push(Team("Celtics", cfoAddress, 700000000000000000)); 
        teams.push(Team("Warriors", cfoAddress, 700000000000000000)); 
        teams.push(Team("Cavaliers", cfoAddress, 650000000000000000)); 
        teams.push(Team("Spurs", cfoAddress, 650000000000000000)); 
        teams.push(Team("Wizards", cfoAddress, 600000000000000000)); 
        teams.push(Team("Timberwolves", cfoAddress, 600000000000000000)); 
        teams.push(Team("Pacers", cfoAddress, 550000000000000000)); 
        teams.push(Team("Thunder", cfoAddress, 550000000000000000)); 
        teams.push(Team("Bucks", cfoAddress, 500000000000000000));
        teams.push(Team("Nuggets", cfoAddress, 500000000000000000)); 
		teams.push(Team("76ers", cfoAddress, 450000000000000000));
		teams.push(Team("Blazers", cfoAddress, 450000000000000000)); 		
        teams.push(Team("Heat", cfoAddress, 400000000000000000)); 		
        teams.push(Team("Pelicans", cfoAddress, 400000000000000000)); 		
        teams.push(Team("Pistons", cfoAddress, 350000000000000000)); 		
        teams.push(Team("Clippers", cfoAddress, 350000000000000000)); 
        teams.push(Team("Hornets", cfoAddress, 300000000000000000));		
        teams.push(Team("Jazz", cfoAddress, 300000000000000000)); 		
        teams.push(Team("Knicks", cfoAddress, 250000000000000000)); 		
        teams.push(Team("Lakers", cfoAddress, 250000000000000000)); 		
        teams.push(Team("Bulls", cfoAddress, 200000000000000000)); 		
        teams.push(Team("Grizzlies", cfoAddress, 200000000000000000)); 		
        teams.push(Team("Nets", cfoAddress, 150000000000000000));		
        teams.push(Team("Kings", cfoAddress, 150000000000000000));		
        teams.push(Team("Magic", cfoAddress, 100000000000000000));		
        teams.push(Team("Mavericks", cfoAddress, 100000000000000000)); 
        teams.push(Team("Hawks", cfoAddress, 100000000000000000));			
        teams.push(Team("Suns", cfoAddress, 100000000000000000)); 		
	}

}