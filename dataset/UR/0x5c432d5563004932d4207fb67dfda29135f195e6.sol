 

pragma solidity ^0.4.18;  

contract FootieToken {

	 

	 
	event Birth(uint256 teamId, string name, address owner);

	 
	 
	event Transfer(address from, address to, uint256 teamId);

	 
	event TeamSold(uint256 index, uint256 oldPrice, uint256 newPrice, address prevOwner, address newOwne, string name);


	 

	 
	string public constant NAME = "CryptoFootie";  
	string public constant SYMBOL = "FootieToken";  

	uint256 private startingPrice = 0.002 ether;
	uint256 private constant TEAM_CREATION_LIMIT = 1000;
	uint256 private princeIncreasePercentage = 24;


	 

	 
	 
	mapping (uint256 => address) private teamIndexToOwner;

	 
	 
	mapping (address => uint256) private ownershipTeamCount;

	 
	 
	 
	mapping (uint256 => address) private teamIndexToApproved;

	 
	mapping (uint256 => uint256) private teamIndexToPrice;

	 
	mapping (uint256 => uint256) private teamIndexToGoals;

	 
	address public creatorAddress;

	 
	uint256 public teamsCreatedCount;


	 
	struct Team {
		string name;
	}
	Team[] private teams;


	 
	 
	modifier onlyCreator() {
		require(msg.sender == creatorAddress);
		_;
	}


	 
	function FootieToken() public {
		creatorAddress = msg.sender;
	}

	function _createTeam(string _name, uint256 _price) public onlyCreator {
		require(teamsCreatedCount < TEAM_CREATION_LIMIT);
		 
		if (_price <= 0) {
			_price = startingPrice;
		}

		 
		teamsCreatedCount++;

		Team memory _team = Team({
			name: _name
		});
		uint256 newteamId = teams.push(_team) - 1;

		 
		 
		require(newteamId == uint256(uint32(newteamId)));

		 
		Birth(newteamId, _name, creatorAddress);

		teamIndexToPrice[newteamId] = _price;

		 
		 
		_transfer(creatorAddress, creatorAddress, newteamId);
	}

	 
	 
	function getTeam(uint256 _index) public view returns (string teamName, uint256 sellingPrice, address owner, uint256 goals) {
		Team storage team = teams[_index];
		teamName = team.name;
		sellingPrice = teamIndexToPrice[_index];
		owner = teamIndexToOwner[_index];
		goals = teamIndexToGoals[_index];
	}
	
	 
	 
	 
	function balanceOf(address _owner) public view returns (uint256 balance) {
		return ownershipTeamCount[_owner];
	}

	 
	 
	 
	function ownerOf(uint256 _index) public view returns (address owner) {
		owner = teamIndexToOwner[_index];
		require(owner != address(0));
	}

	 
	function buyTeam(uint256 _index) public payable {
		address oldOwner = teamIndexToOwner[_index];
		address newOwner = msg.sender;

		uint256 sellingPrice = teamIndexToPrice[_index];

		 
		require(oldOwner != newOwner);

		 
		require(_addressNotNull(newOwner));

		 
		require(msg.value >= sellingPrice);


		 
		uint256 payment = uint256(SafeMath.div(SafeMath.mul(sellingPrice, 96), 100));

		 
		uint256 fee = uint256(SafeMath.div(SafeMath.mul(sellingPrice, 4), 100));
		
		 
		uint256 purchaseExcess = SafeMath.sub(msg.value, sellingPrice);

		 
		teamIndexToPrice[_index] = sellingPrice + SafeMath.div(SafeMath.mul(sellingPrice, princeIncreasePercentage), 100);

		 
		teamIndexToGoals[_index] = teamIndexToGoals[_index] + 1;

		 
		oldOwner.transfer(payment);
		 
		creatorAddress.transfer(fee);

		 
		_transfer(oldOwner, newOwner, _index);

		TeamSold(_index, sellingPrice, teamIndexToPrice[_index], oldOwner, newOwner, teams[_index].name);

		msg.sender.transfer(purchaseExcess);
	}



	 

	 
	function _addressNotNull(address _to) private pure returns (bool) {
		return _to != address(0);
	}

	 
	function _transfer(address _from, address _to, uint256 _index) private {
		 
		ownershipTeamCount[_to]++;
		 
		teamIndexToOwner[_index] = _to;

		 
		Transfer(_from, _to, _index);
	}

}





library SafeMath {

	 
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

	 
	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		assert(b <= a);
		return a - b;
	}

	 
	function add(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a + b;
		assert(c >= a);
	return c;
	}
}