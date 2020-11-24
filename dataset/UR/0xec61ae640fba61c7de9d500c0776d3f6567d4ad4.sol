 

pragma solidity ^0.4.18;

contract WorldCupEther {

	address ceoAddress = 0xb92C14C5E4a6878C9B44F4115D9C1b0aC702F092;
    address cfoAddress = 0x0A6b1ae1190C40aE0192fCd7f0C52E91D539e2c0;

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
        teams.push(Team("Russia", cfoAddress, 195000000000000000)); 
		teams.push(Team("Germany", cfoAddress, 750000000000000000)); 
		teams.push(Team("Brazil", cfoAddress, 700000000000000000)); 
        teams.push(Team("Argentina", cfoAddress, 650000000000000000)); 
        teams.push(Team("Portugal", cfoAddress, 350000000000000000)); 
        teams.push(Team("Poland", cfoAddress, 125000000000000000)); 
        teams.push(Team("France", cfoAddress, 750000000000000000)); 
        teams.push(Team("Belgium", cfoAddress, 400000000000000000)); 
        teams.push(Team("England", cfoAddress, 500000000000000000)); 
        teams.push(Team("Spain", cfoAddress, 650000000000000000)); 
        teams.push(Team("Switzerland", cfoAddress, 125000000000000000));
        teams.push(Team("Peru", cfoAddress, 60000000000000000)); 
		teams.push(Team("Uruguay", cfoAddress, 225000000000000000));
		teams.push(Team("Colombia", cfoAddress, 195000000000000000)); 		
        teams.push(Team("Mexico", cfoAddress, 125000000000000000)); 		
        teams.push(Team("Croatia", cfoAddress, 125000000000000000)); 		
        teams.push(Team("Denmark", cfoAddress, 95000000000000000)); 		
        teams.push(Team("Iceland", cfoAddress, 75000000000000000)); 
        teams.push(Team("Costa Rica", cfoAddress, 50000000000000000));		
        teams.push(Team("Sweden", cfoAddress, 95000000000000000)); 		
        teams.push(Team("Tunisia", cfoAddress, 30000000000000000)); 		
        teams.push(Team("Egypt", cfoAddress, 60000000000000000)); 		
        teams.push(Team("Senegal", cfoAddress, 70000000000000000)); 		
        teams.push(Team("Iran", cfoAddress, 30000000000000000)); 		
        teams.push(Team("Serbia", cfoAddress, 75000000000000000));		
        teams.push(Team("Nigeria", cfoAddress, 75000000000000000));		
        teams.push(Team("Australia", cfoAddress, 40000000000000000));		
        teams.push(Team("Japan", cfoAddress, 70000000000000000)); 
        teams.push(Team("Morocco", cfoAddress, 50000000000000000));			
        teams.push(Team("Panama", cfoAddress, 25000000000000000)); 		
        teams.push(Team("South Korea", cfoAddress, 30000000000000000)); 
		teams.push(Team("Saudi Arabia", cfoAddress, 15000000000000000));
	}

}