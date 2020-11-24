 

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

     

     
    mapping (uint => address) public teamIndexToOwner;

     
    mapping (uint => uint) private teamIndexToPrice;

     
    mapping (address => uint) private ownershipTokenCount;


     
     
    struct Team {
      string name;
    }

     
    Team[] private ballerTeams;

     

     

    function createTeam(string _name, uint _price) public onlyOwner {
      _createTeam(_name, this, _price);
    }

     
    function getTeam(uint _tokenId) public view returns(string teamName, uint currPrice, address owner) {
        Team storage currTeam = ballerTeams[_tokenId];
        teamName = currTeam.name;
        currPrice = teamIndexToPrice[_tokenId];
        owner = ownerOf(_tokenId);
    }

     
    function changeTeamName(uint _tokenId, string _newName) public onlyOwner {
      require(_tokenId < ballerTeams.length);
      ballerTeams[_tokenId].name = _newName;
    }

     

    function payout(address _to) public onlyOwner {
      _withdrawAmount(_to, this.balance);
    }

     
    function withdrawAmount(address _to, uint _amount) public onlyOwner {
      _withdrawAmount(_to, _amount);
    }

     
    function priceOfTeam(uint _teamId) public view returns (uint price, uint teamId) {
      price = teamIndexToPrice[_teamId];
      teamId = _teamId;
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

     
    function ownerOf(uint _tokenId) public view returns (address owner) {
      owner = teamIndexToOwner[_tokenId];
      require(owner != address(0));
    }

     
    function balanceOf(address _owner) public view returns (uint numTeamsOwned) {
      numTeamsOwned = ownershipTokenCount[_owner];
    }

     
    function totalSupply() public view returns (uint totalNumTeams) {
      totalNumTeams = ballerTeams.length;
    }

     
    function purchase(uint _teamId) public payable {
      address oldOwner = ownerOf(_teamId);
      address newOwner = msg.sender;

      uint sellingPrice = teamIndexToPrice[_teamId];

       
      require(oldOwner != newOwner);

       
      require(_addressNotNull(newOwner));

       
      require(msg.value >= sellingPrice);

      uint payment =  _calculatePaymentToOwner(sellingPrice);
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

     
    function _transfer(address _from, address _to, uint _teamId) private {
      ownershipTokenCount[_to]++;
      teamIndexToOwner[_teamId] = _to;

       
      if (_from != address(0)) {
        ownershipTokenCount[_from]--;
      }

      Transfer(_from, _to, _teamId);
    }

     
    function _calculatePaymentToOwner(uint _sellingPrice) private pure returns (uint payment) {
      if (_sellingPrice < FIRST_PRICE_LIMIT) {
        payment = uint256(_sellingPrice.mul(100-FIRST_COMMISSION_LEVEL).div(100));
      }
      else if (_sellingPrice < SECOND_PRICE_LIMIT) {
        payment = uint256(_sellingPrice.mul(100-SECOND_COMMISSION_LEVEL).div(100));
      }
      else if (_sellingPrice < THIRD_PRICE_LIMIT) {
        payment = uint256(_sellingPrice.mul(100-THIRD_COMMISSION_LEVEL).div(100));
      }
      else {
        payment = uint256(_sellingPrice.mul(100-FOURTH_COMMISSION_LEVEL).div(100));
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