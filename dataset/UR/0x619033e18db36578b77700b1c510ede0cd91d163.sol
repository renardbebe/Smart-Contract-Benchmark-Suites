 

pragma solidity ^0.4.18;

contract EtherTower {
  using SafeMath for uint256;

   
  address public owner;

   
  uint256 private constant TOWER_BOSS_TOKEN_ID = 0;
  uint256 private constant APARTMENT_MANAGER_ID = 1;
  uint256 private constant HOTEL_MANAGER_ID = 2;
  uint256 private constant CONDO_MANAGER_ID = 3;

  uint256 private constant BOTTOM_FLOOR_ID = 4;
  uint256 private constant APARTMENT_INDEX_MIN = 4;
  uint256 private constant APARTMENT_INDEX_MAX = 9;
  uint256 private constant HOTEL_INDEX_MIN = 10;
  uint256 private constant HOTEL_INDEX_MAX = 15;
  uint256 private constant CONDO_INDEX_MIN = 16;
  uint256 private constant CONDO_INDEX_MAX = 21;

  uint256 private firstStepLimit = 0.04 ether;
  uint256 private secondStepLimit = 0.2 ether;

   
  uint256 public gameStartTime = 1520647080;

   
  struct Token {
    uint256 price;
    address owner;
  }

  mapping (uint256 => Token) public tokens;

   
  mapping (address => uint256) public earnings;

  event TokenPurchased(
    uint256 tokenId,
    address oldOwner,
    address newOwner,
    uint256 oldPrice,
    uint256 newPrice,
    uint256 timestamp
  );

  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  modifier onlyGameStarted {
    require(now >= gameStartTime);
    _;
  }

  function EtherTower() public {
    owner = msg.sender;
    createToken(0, 2 ether);  
    createToken(1, 0.5 ether);  
    createToken(2, 0.5 ether);  
    createToken(3, 0.5 ether);  

     
    createToken(4, 0.05 ether);
    createToken(5, 0.005 ether);
    createToken(6, 0.005 ether);
    createToken(7, 0.005 ether);
    createToken(8, 0.005 ether);
    createToken(9, 0.05 ether);

     
    createToken(10, 0.05 ether);
    createToken(11, 0.005 ether);
    createToken(12, 0.005 ether);
    createToken(13, 0.005 ether);
    createToken(14, 0.005 ether);
    createToken(15, 0.05 ether);

     
    createToken(16, 0.05 ether);
    createToken(17, 0.005 ether);
    createToken(18, 0.005 ether);
    createToken(19, 0.005 ether);
    createToken(20, 0.005 ether);
    createToken(21, 0.1 ether);  
  }

   

  function createToken(uint256 _tokenId, uint256 _startingPrice) public onlyOwner {
    Token memory token = Token({
      price: _startingPrice,
      owner: owner
    });

    tokens[_tokenId] = token;
  }

  function getToken(uint256 _tokenId) public view returns (
    uint256 _price,
    uint256 _nextPrice,
    address _owner
  ) {
    Token memory token = tokens[_tokenId];
    _price = token.price;
    _nextPrice = getNextPrice(token.price);
    _owner = token.owner;
  }

  function setGameStartTime(uint256 _gameStartTime) public onlyOwner {
    gameStartTime = _gameStartTime;
  }

  function purchase(uint256 _tokenId) public payable onlyGameStarted {
    Token storage token = tokens[_tokenId];

     
    require(msg.value >= token.price);

     
    require(msg.sender != token.owner);

    uint256 purchaseExcess = msg.value.sub(token.price);

    address newOwner = msg.sender;
    address oldOwner = token.owner;

    uint256 devCut = token.price.mul(4).div(100);  
    uint256 towerBossCut = token.price.mul(3).div(100);  
    uint256 managerCut = getManagerCut(_tokenId, token.price);  
    uint256 oldOwnerProfit = token.price.sub(devCut).sub(towerBossCut).sub(managerCut);

     
    uint256 oldPrice = token.price;
    token.owner = newOwner;
    token.price = getNextPrice(token.price);

     
    earnings[owner] = earnings[owner].add(devCut);

     
    earnings[tokens[TOWER_BOSS_TOKEN_ID].owner] = earnings[tokens[TOWER_BOSS_TOKEN_ID].owner].add(towerBossCut);

     
    if (managerCut > 0) {
      address managerAddress = getManagerAddress(_tokenId);
      earnings[managerAddress] = earnings[managerAddress].add(managerCut);
    }

     
    sendFunds(oldOwner, oldOwnerProfit);

     
    if (purchaseExcess > 0) {
      sendFunds(newOwner, purchaseExcess);
    }

    TokenPurchased(_tokenId, oldOwner, newOwner, oldPrice, token.price, now);
  }

  function withdrawEarnings() public {
    uint256 amount = earnings[msg.sender];
    earnings[msg.sender] = 0;
    msg.sender.transfer(amount);
  }

   

   
  function getManagerCut(uint256 _tokenId, uint256 _price) private pure returns (uint256) {
    if (_tokenId >= BOTTOM_FLOOR_ID) {
      return _price.mul(3).div(100);  
    } else {
      return 0;
    }
  }

  function getManagerAddress(uint256 _tokenId) private view returns (address) {
    if (_tokenId >= APARTMENT_INDEX_MIN && _tokenId <= APARTMENT_INDEX_MAX) {
      return tokens[APARTMENT_MANAGER_ID].owner;
    } else if (_tokenId >= HOTEL_INDEX_MIN && _tokenId <= HOTEL_INDEX_MAX) {
      return tokens[HOTEL_MANAGER_ID].owner;
    } else if (_tokenId >= CONDO_INDEX_MIN && _tokenId <= CONDO_INDEX_MAX) {
      return tokens[CONDO_MANAGER_ID].owner;
    } else {
       
      return owner;
    }
  }

  function getNextPrice(uint256 _price) private view returns (uint256) {
    if (_price <= firstStepLimit) {
      return _price.mul(2);  
    } else if (_price <= secondStepLimit) {
      return _price.mul(125).div(100);  
    } else {
      return _price.mul(118).div(100);  
    }
  }

   
  function sendFunds(address _recipient, uint256 _amount) private {
    if (!_recipient.send(_amount)) {
      earnings[_recipient] = earnings[_recipient].add(_amount);
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