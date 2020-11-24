 

pragma solidity ^0.4.19;

 

contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

   
  function isOwner() public {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


 
contract EtherCup is Ownable {

   

  using SafeMath for uint256;

   
  event NewPlayer(uint tokenId, string name);
  event TokenSold(uint256 tokenId, uint256 oldPrice, address prevOwner, address winner, string name);
  event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);


   
  uint256 private price = 0.01 ether;
  uint256 private priceLimitOne = 0.05 ether;
  uint256 private priceLimitTwo = 0.5 ether;
  uint256 private priceLimitThree = 2 ether;
  uint256 private priceLimitFour = 5 ether;


   
  mapping (uint => address) public playerToOwner;
  mapping (address => uint) ownerPlayerCount;
  mapping (uint256 => uint256) public playerToPrice;
  mapping (uint => address) playerApprovals;

   
  address public ceoAddress;

   
  struct Player {
    string name;
  }

  Player[] public players;


   
   
  modifier onlyCEO() {
    require(msg.sender == ceoAddress);
    _;
  }

  modifier onlyOwnerOf(uint _tokenId) {
    require(msg.sender == playerToOwner[_tokenId]);
    _;
  }

   
   
  constructor() public {
    ceoAddress = msg.sender;

  }

   
   
   
  function setCEO(address _newCEO) public onlyCEO {
    require(_newCEO != address(0));
    ceoAddress = _newCEO;
  }


   
  function createNewPlayer(string _name) public onlyCEO {
    _createPlayer(_name, price);
  }

  function _createPlayer(string _name, uint256 _price) internal {
    uint id = players.push(Player(_name)) - 1;
    playerToOwner[id] = msg.sender;
    ownerPlayerCount[msg.sender] = ownerPlayerCount[msg.sender].add(1);
    emit NewPlayer(id, _name);

    playerToPrice[id] = _price;
  }


   
  function calculateNextPrice (uint256 _price) public view returns (uint256 _nextPrice) {
    if (_price < priceLimitOne) {
      return _price.mul(200).div(95);  
    } else if (_price < priceLimitTwo) {
      return _price.mul(175).div(95);  
    } else if (_price < priceLimitThree) {
      return _price.mul(150).div(95);  
    } else if (_price < priceLimitFour) {
      return _price.mul(125).div(95);  
    } else {
      return _price.mul(115).div(95);  
    }
  }

  function calculateDevCut (uint256 _price) public pure returns (uint256 _devCut) {
    return _price.mul(5).div(100);

  }

  function purchase(uint256 _tokenId) public payable {

    address oldOwner = playerToOwner[_tokenId];
    address newOwner = msg.sender;

    uint256 sellingPrice = playerToPrice[_tokenId];
    uint256 purchaseExcess = msg.value.sub(sellingPrice);

     
    require(oldOwner != newOwner);

     
    require(msg.value >= sellingPrice);

    _transfer(oldOwner, newOwner, _tokenId);
    playerToPrice[_tokenId] = nextPriceOf(_tokenId);

     
     
    uint256 devCut = calculateDevCut(sellingPrice);

    uint256 payment = sellingPrice.sub(devCut);

     
    if (oldOwner != address(this)) {
      oldOwner.transfer(payment);
    }

    if (purchaseExcess > 0){
        newOwner.transfer(purchaseExcess);
    }


    emit TokenSold(_tokenId, sellingPrice, oldOwner, newOwner, players[_tokenId].name);
  }

   
   
  function withdrawAll () onlyCEO() public {
    ceoAddress.transfer(address(this).balance);
  }

  function withdrawAmount (uint256 _amount) onlyCEO() public {
    ceoAddress.transfer(_amount);
  }

  function showDevCut () onlyCEO() public view returns (uint256) {
    return address(this).balance;
  }


   
  function priceOf(uint256 _tokenId) public view returns (uint256 _price) {
    return playerToPrice[_tokenId];
  }

  function priceOfMultiple(uint256[] _tokenIds) public view returns (uint256[]) {
    uint[] memory values = new uint[](_tokenIds.length);

    for (uint256 i = 0; i < _tokenIds.length; i++) {
      values[i] = priceOf(_tokenIds[i]);
    }
    return values;
  }

  function nextPriceOf(uint256 _tokenId) public view returns (uint256 _nextPrice) {
    return calculateNextPrice(priceOf(_tokenId));
  }

   
  function totalSupply() public view returns (uint256 total) {
    return players.length;
  }

  function balanceOf(address _owner) public view returns (uint256 _balance) {
    return ownerPlayerCount[_owner];
  }

  function ownerOf(uint256 _tokenId) public view returns (address _owner) {
    return playerToOwner[_tokenId];
  }

  function approve(address _to, uint256 _tokenId) public onlyOwnerOf(_tokenId) {
    playerApprovals[_tokenId] = _to;
    emit Approval(msg.sender, _to, _tokenId);
  }

  function transfer(address _to, uint256 _tokenId) public onlyOwnerOf(_tokenId) {
    _transfer(msg.sender, _to, _tokenId);
  }

  function _transfer(address _from, address _to, uint256 _tokenId) private {

    ownerPlayerCount[_to] = ownerPlayerCount[_to].add(1);
    ownerPlayerCount[_from] = ownerPlayerCount[_from].sub(1);
    playerToOwner[_tokenId] = _to;
    emit Transfer(_from, _to, _tokenId);
  }

   
   
   
   
  function tokensOfOwner(address _owner) public view returns(uint256[] ownerTokens) {
    uint256 tokenCount = balanceOf(_owner);
    if (tokenCount == 0) {
         
      return new uint256[](0);
    } else {
      uint256[] memory result = new uint256[](tokenCount);
      uint256 totalPlayers = totalSupply();
      uint256 resultIndex = 0;

      uint256 playerId;
      for (playerId = 0; playerId <= totalPlayers; playerId++) {
        if (playerToOwner[playerId] == _owner) {
          result[resultIndex] = playerId;
          resultIndex++;
        }
      }
      return result;
    }
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