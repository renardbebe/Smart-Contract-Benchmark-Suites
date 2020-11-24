 

pragma solidity ^0.4.11;

contract Grid {
   
   
  address admin;

   
  uint16 public size;

   
  uint public defaultPrice;

   
   
   
   
  uint public feeRatio;

   
   
  uint public incrementRate;

   
   
  struct User {
     
    uint pendingWithdrawal;

     
     
    uint totalSales;
  }

  struct Pixel {
     
     
     
    address owner;

     
    uint price;

     
     
    uint24 color;
  }

   
  mapping(uint32 => Pixel) pixels;

   
  mapping(address => User) users;

   
   
  mapping(address => string) messages;

   
   
   

  event PixelTransfer(uint16 row, uint16 col, uint price, address prevOwner, address newOwner);
  event PixelColor(uint16 row, uint16 col, address owner, uint24 color);
  event PixelPrice(uint16 row, uint16 col, address owner, uint price);
  event UserMessage(address user, string message);

   
   
   

  function Grid(
    uint16 _size,
    uint _defaultPrice,
    uint _feeRatio,
    uint _incrementRate) {
    admin = msg.sender;
    defaultPrice = _defaultPrice;
    feeRatio = _feeRatio;
    size = _size;
    incrementRate = _incrementRate;
  }

  modifier onlyAdmin {
    require(msg.sender == admin);
    _;
  }

  modifier onlyOwner(uint16 row, uint16 col) {
    require(msg.sender == getPixelOwner(row, col));
    _;
  }

  function getKey(uint16 row, uint16 col) constant returns (uint32) {
    require(row < size && col < size);
    return uint32(SafeMath.add(SafeMath.mul(row, size), col));
  }

  function() payable {}

   
   
   

  function setAdmin(address _admin) onlyAdmin {
    admin = _admin;
  }

  function setFeeRatio(uint _feeRatio) onlyAdmin {
    feeRatio = _feeRatio;
  }

  function setDefaultPrice(uint _defaultPrice) onlyAdmin {
    defaultPrice = _defaultPrice;
  }

   
   
   

  function getPixelColor(uint16 row, uint16 col) constant returns (uint24) {
    uint32 key = getKey(row, col);
    return pixels[key].color;
  }

  function getPixelOwner(uint16 row, uint16 col) constant returns (address) {
    uint32 key = getKey(row, col);
    if (pixels[key].owner == 0) {
      return admin;
    }
    return pixels[key].owner;
  }

  function getPixelPrice(uint16 row, uint16 col) constant returns (uint) {
    uint32 key = getKey(row, col);
    if (pixels[key].owner == 0) {
      return defaultPrice;
    }
    return pixels[key].price;
  }

  function getUserMessage(address user) constant returns (string) {
    return messages[user];
  }

  function getUserTotalSales(address user) constant returns (uint) {
    return users[user].totalSales;
  }

   
   
   

  function checkPendingWithdrawal() constant returns (uint) {
    return users[msg.sender].pendingWithdrawal;
  }

  function withdraw() {
    if (users[msg.sender].pendingWithdrawal > 0) {
      uint amount = users[msg.sender].pendingWithdrawal;
      users[msg.sender].pendingWithdrawal = 0;
      msg.sender.transfer(amount);
    }
  }

  function buyPixel(uint16 row, uint16 col, uint24 newColor) payable {
    uint balance = users[msg.sender].pendingWithdrawal;
     
     
    if (row >= size || col >= size) {
      users[msg.sender].pendingWithdrawal = SafeMath.add(balance, msg.value);
      return;
    }

    uint32 key = getKey(row, col);
    uint price = getPixelPrice(row, col);
    address owner = getPixelOwner(row, col);

     
     
    if (msg.value < price) {
      users[msg.sender].pendingWithdrawal = SafeMath.add(balance, msg.value);
      return;
    }

    uint fee = SafeMath.div(msg.value, feeRatio);
    uint payout = SafeMath.sub(msg.value, fee);

    uint adminBalance = users[admin].pendingWithdrawal;
    users[admin].pendingWithdrawal = SafeMath.add(adminBalance, fee);

    uint ownerBalance = users[owner].pendingWithdrawal;
    users[owner].pendingWithdrawal = SafeMath.add(ownerBalance, payout);
    users[owner].totalSales = SafeMath.add(users[owner].totalSales, payout);

     
    uint increase = SafeMath.div(SafeMath.mul(price, incrementRate), 100);
    pixels[key].price = SafeMath.add(price, increase);
    pixels[key].owner = msg.sender;

    PixelTransfer(row, col, price, owner, msg.sender);
    setPixelColor(row, col, newColor);
  }

   
   
   

  function transferPixel(uint16 row, uint16 col, address newOwner) onlyOwner(row, col) {
    uint32 key = getKey(row, col);
    address owner = pixels[key].owner;
    if (owner != newOwner) {
      pixels[key].owner = newOwner;
      PixelTransfer(row, col, 0, owner, newOwner);
    }
  }

  function setPixelColor(uint16 row, uint16 col, uint24 color) onlyOwner(row, col) {
    uint32 key = getKey(row, col);
    if (pixels[key].color != color) {
      pixels[key].color = color;
      PixelColor(row, col, pixels[key].owner, color);
    }
  }

  function setPixelPrice(uint16 row, uint16 col, uint newPrice) onlyOwner(row, col) {
    uint32 key = getKey(row, col);
     
     
    require(pixels[key].price > newPrice);

    pixels[key].price = newPrice;
    PixelPrice(row, col, pixels[key].owner, newPrice);
  }

   
   
   

  function setUserMessage(string message) {
    messages[msg.sender] = message;
    UserMessage(msg.sender, message);
  }
}

library SafeMath {
  function mul(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}