 

pragma solidity ^0.4.18;

 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


 
contract Destructible is Ownable {

  function Destructible() public payable { }

   
  function destroy() onlyOwner public {
    selfdestruct(owner);
  }

  function destroyAndSend(address _recipient) onlyOwner public {
    selfdestruct(_recipient);
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

contract BallerToken is Ownable, Destructible {
    using SafeMath for uint;
     

     
    event BallerCreated(uint256 tokenId, string name, address owner);

     
    event BallerPlayerCreated(uint256 tokenId, string name, uint teamID, address owner);

     
    event TokenSold(uint256 tokenId, uint256 oldPrice, uint256 newPrice, address prevOwner, address newOwner, string name);

     
    event Transfer(address from, address to, uint256 tokenId);

     

    uint constant private DEFAULT_START_PRICE = 0.01 ether;
    uint constant private FIRST_PRICE_LIMIT =  0.5 ether;
    uint constant private SECOND_PRICE_LIMIT =  2 ether;
    uint constant private THIRD_PRICE_LIMIT =  5 ether;
    uint constant private FIRST_COMMISSION_LEVEL = 5;
    uint constant private SECOND_COMMISSION_LEVEL = 4;
    uint constant private THIRD_COMMISSION_LEVEL = 3;
    uint constant private FOURTH_COMMISSION_LEVEL = 2;
    uint constant private FIRST_LEVEL_INCREASE = 200;
    uint constant private SECOND_LEVEL_INCREASE = 135;
    uint constant private THIRD_LEVEL_INCREASE = 125;
    uint constant private FOURTH_LEVEL_INCREASE = 115;

     

     
    mapping (uint => address) private teamIndexToOwner;

     
    mapping (uint => uint) private teamIndexToPrice;

     
    mapping (address => uint) private ownershipTokenCount;


     
    mapping (uint => address) public playerIndexToOwner;

     
    mapping (uint => uint) private playerIndexToPrice;

     
    mapping (address => uint) private playerOwnershipTokenCount;


     
     
    struct Team {
        string name;
    }

     
    struct Player {
        string name;
        uint teamID;
    }

     
    Team[] private ballerTeams;

     
    Player[] private ballerPlayers;

     

     

    function createTeam(string _name, uint _price) public onlyOwner {
        _createTeam(_name, this, _price);
    }

     
    function createPromoTeam(string _name, address _owner, uint _price) public onlyOwner {
        _createTeam(_name, _owner, _price);
    }


     
    function createPlayer(string _name, uint _teamID, uint _price) public onlyOwner {
        _createPlayer(_name, _teamID, this, _price);
    }

     
    function getTeam(uint _tokenId) public view returns(string teamName, uint currPrice, address owner) {
        Team storage currTeam = ballerTeams[_tokenId];
        teamName = currTeam.name;
        currPrice = teamIndexToPrice[_tokenId];
        owner = ownerOf(_tokenId);
    }

     
    function getPlayer(uint _tokenId) public view returns(string playerName, uint currPrice, address owner, uint owningTeamID) {
        Player storage currPlayer = ballerPlayers[_tokenId];
        playerName = currPlayer.name;
        currPrice = playerIndexToPrice[_tokenId];
        owner = ownerOfPlayer(_tokenId);
        owningTeamID = currPlayer.teamID;
    }

     
    function changeTeamName(uint _tokenId, string _newName) public onlyOwner {
        require(_tokenId < ballerTeams.length && _tokenId >= 0);
        ballerTeams[_tokenId].name = _newName;
    }

     
    function changePlayerName(uint _tokenId, string _newName) public onlyOwner {
        require(_tokenId < ballerPlayers.length && _tokenId >= 0);
        ballerPlayers[_tokenId].name = _newName;
    }

     

    function changePlayerTeam(uint _tokenId, uint _newTeamId) public onlyOwner {
        require(_newTeamId < ballerPlayers.length && _newTeamId >= 0);
        ballerPlayers[_tokenId].teamID = _newTeamId;
    }

     

    function payout(address _to) public onlyOwner {
      _withdrawAmount(_to, this.balance);
    }

     
    function withdrawAmount(address _to, uint _amount) public onlyOwner {
      _withdrawAmount(_to, _amount);
    }

     
    function priceOfTeam(uint _teamId) public view returns (uint price) {
      price = teamIndexToPrice[_teamId];
    }

     

    function priceOfPlayer(uint _playerID) public view returns (uint price) {
        price = playerIndexToPrice[_playerID];
    }

     
    function getTeamsOfOwner(address _owner) public view returns (uint[] ownedTeams) {
      uint tokenCount = balanceOf(_owner);
      ownedTeams = new uint[](tokenCount);
      uint totalTeams = totalSupply();
      uint resultIndex = 0;
      if (tokenCount != 0) {
        for (uint pos = 0; pos < totalTeams; pos++) {
          address currOwner = ownerOf(pos);
          if (currOwner == _owner) {
            ownedTeams[resultIndex] = pos;
            resultIndex++;
          }
        }
      }
    }


     

    function getPlayersOfOwner(address _owner) public view returns (uint[] ownedPlayers) {
        uint numPlayersOwned = balanceOfPlayers(_owner);
        ownedPlayers = new uint[](numPlayersOwned);
        uint totalPlayers = totalPlayerSupply();
        uint resultIndex = 0;
        if (numPlayersOwned != 0) {
            for (uint pos = 0; pos < totalPlayers; pos++) {
                address currOwner = ownerOfPlayer(pos);
                if (currOwner == _owner) {
                    ownedPlayers[resultIndex] = pos;
                    resultIndex++;
                }
            }
        }
    }

     
    function ownerOf(uint _tokenId) public view returns (address owner) {
      owner = teamIndexToOwner[_tokenId];
      require(owner != address(0));
    }

     

    function ownerOfPlayer(uint _playerId) public view returns (address owner) {
        owner = playerIndexToOwner[_playerId];
        require(owner != address(0));
    }

    function teamOwnerOfPlayer(uint _playerId) public view returns (address teamOwner) {
        uint teamOwnerId = ballerPlayers[_playerId].teamID;
        teamOwner = ownerOf(teamOwnerId);
    }
     

    function balanceOf(address _owner) public view returns (uint numTeamsOwned) {
      numTeamsOwned = ownershipTokenCount[_owner];
    }

     

    function balanceOfPlayers(address _owner) public view returns (uint numPlayersOwned) {
        numPlayersOwned = playerOwnershipTokenCount[_owner];
    }

     
    function totalSupply() public view returns (uint totalNumTeams) {
      totalNumTeams = ballerTeams.length;
    }

     

    function totalPlayerSupply() public view returns (uint totalNumPlayers) {
        totalNumPlayers = ballerPlayers.length;
    }

     
    function purchase(uint _teamId) public payable {
      address oldOwner = ownerOf(_teamId);
      address newOwner = msg.sender;

      uint sellingPrice = teamIndexToPrice[_teamId];

       
      require(oldOwner != newOwner);

       
      require(_addressNotNull(newOwner));

       
      require(msg.value >= sellingPrice);

      uint payment =  _calculatePaymentToOwner(sellingPrice, true);
      uint excessPayment = msg.value.sub(sellingPrice);
      uint newPrice = _calculateNewPrice(sellingPrice);
      teamIndexToPrice[_teamId] = newPrice;

      _transfer(oldOwner, newOwner, _teamId);
       
      if (oldOwner != address(this)) {
        oldOwner.transfer(payment);
      }

      newOwner.transfer(excessPayment);
      string memory teamName = ballerTeams[_teamId].name;
      TokenSold(_teamId, sellingPrice, newPrice, oldOwner, newOwner, teamName);
    }


     

    function purchasePlayer(uint _playerId) public payable {
        address oldOwner = ownerOfPlayer(_playerId);
        address newOwner = msg.sender;
        address teamOwner = teamOwnerOfPlayer(_playerId);

        uint sellingPrice = playerIndexToPrice[_playerId];

         
        require(oldOwner != newOwner);

         
        require(_addressNotNull(newOwner));

         
        require(msg.value >= sellingPrice);

        bool sellingTeam = false;
        uint payment = _calculatePaymentToOwner(sellingPrice, sellingTeam);
        uint commission = msg.value.sub(payment);
        uint teamOwnerCommission = commission.div(2);
        uint excessPayment = msg.value.sub(sellingPrice);
        uint newPrice = _calculateNewPrice(sellingPrice);
        playerIndexToPrice[_playerId] = newPrice;

        _transferPlayer(oldOwner, newOwner, _playerId);

         
        if (oldOwner != address(this)) {
            oldOwner.transfer(payment);
        }

         
        if (teamOwner != address(this)) {
            teamOwner.transfer(teamOwnerCommission);
        }

        newOwner.transfer(excessPayment);
        string memory playerName = ballerPlayers[_playerId].name;
        TokenSold(_playerId, sellingPrice, newPrice, oldOwner, newOwner, playerName);
    }


     
    function _addressNotNull(address _to) private pure returns (bool) {
      return _to != address(0);
    }

     
    function _withdrawAmount(address _to, uint _amount) private {
      require(this.balance >= _amount);
      if (_to == address(0)) {
        owner.transfer(_amount);
      } else {
        _to.transfer(_amount);
      }
    }

     
    function _createTeam(string _name, address _owner, uint _startingPrice) private {
      Team memory currTeam = Team(_name);
      uint newTeamId = ballerTeams.push(currTeam) - 1;

       
       
      require(newTeamId == uint256(uint32(newTeamId)));

      BallerCreated(newTeamId, _name, _owner);
      teamIndexToPrice[newTeamId] = _startingPrice;
      _transfer(address(0), _owner, newTeamId);
    }

     

    function _createPlayer(string _name, uint _teamID, address _owner, uint _startingPrice) private {
        Player memory currPlayer = Player(_name, _teamID);
        uint newPlayerId = ballerPlayers.push(currPlayer) - 1;

         
         
        require(newPlayerId == uint256(uint32(newPlayerId)));
        BallerPlayerCreated(newPlayerId, _name, _teamID, _owner);
        playerIndexToPrice[newPlayerId] = _startingPrice;
        _transferPlayer(address(0), _owner, newPlayerId);
    }

     
    function _transfer(address _from, address _to, uint _teamId) private {
      ownershipTokenCount[_to]++;
      teamIndexToOwner[_teamId] = _to;

       
      if (_from != address(0)) {
        ownershipTokenCount[_from]--;
      }

      Transfer(_from, _to, _teamId);
    }


     

    function _transferPlayer(address _from, address _to, uint _playerId) private {
        playerOwnershipTokenCount[_to]++;
        playerIndexToOwner[_playerId] = _to;

         
        if (_from != address(0)) {
            playerOwnershipTokenCount[_from]--;
        }

        Transfer(_from, _to, _playerId);
    }

     
    function _calculatePaymentToOwner(uint _sellingPrice, bool _sellingTeam) private pure returns (uint payment) {
      uint multiplier = 1;
      if (! _sellingTeam) {
          multiplier = 2;
      }
      uint commissionAmount = 100;
      if (_sellingPrice < FIRST_PRICE_LIMIT) {
        commissionAmount = commissionAmount.sub(FIRST_COMMISSION_LEVEL.mul(multiplier));
        payment = uint256(_sellingPrice.mul(commissionAmount).div(100));
      }
      else if (_sellingPrice < SECOND_PRICE_LIMIT) {
        commissionAmount = commissionAmount.sub(SECOND_COMMISSION_LEVEL.mul(multiplier));

        payment = uint256(_sellingPrice.mul(commissionAmount).div(100));
      }
      else if (_sellingPrice < THIRD_PRICE_LIMIT) {
        commissionAmount = commissionAmount.sub(THIRD_COMMISSION_LEVEL.mul(multiplier));

        payment = uint256(_sellingPrice.mul(commissionAmount).div(100));
      }
      else {
        commissionAmount = commissionAmount.sub(FOURTH_COMMISSION_LEVEL.mul(multiplier));
        payment = uint256(_sellingPrice.mul(commissionAmount).div(100));
      }
    }

     
    function _calculateNewPrice(uint _sellingPrice) private pure returns (uint newPrice) {
      if (_sellingPrice < FIRST_PRICE_LIMIT) {
        newPrice = uint256(_sellingPrice.mul(FIRST_LEVEL_INCREASE).div(100));
      }
      else if (_sellingPrice < SECOND_PRICE_LIMIT) {
        newPrice = uint256(_sellingPrice.mul(SECOND_LEVEL_INCREASE).div(100));
      }
      else if (_sellingPrice < THIRD_PRICE_LIMIT) {
        newPrice = uint256(_sellingPrice.mul(THIRD_LEVEL_INCREASE).div(100));
      }
      else {
        newPrice = uint256(_sellingPrice.mul(FOURTH_LEVEL_INCREASE).div(100));
      }
    }
}