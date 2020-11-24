 

pragma solidity ^0.4.11;

contract Grid {
   
   
  address admin;

   
  uint public defaultPrice;

   
   
   
   
  uint public feeRatio;

   
   
  uint public incrementRate;

  struct Pixel {
     
     
     
    address owner;

     
    uint price;

     
     
    uint24 color;
  }

   
   
  Pixel[1000][1000] pixels;

   
  mapping(address => uint) pendingWithdrawals;

   
   
  mapping(address => string) messages;

   
   
   

  event PixelTransfer(uint16 row, uint16 col, uint price, address prevOwner, address newOwner);
  event PixelColor(uint16 row, uint16 col, address owner, uint24 color);
  event PixelPrice(uint16 row, uint16 col, address owner, uint price);

   
   
   

  function Grid(
    uint _defaultPrice,
    uint _feeRatio,
    uint _incrementRate) {
    admin = msg.sender;
    defaultPrice = _defaultPrice;
    feeRatio = _feeRatio;
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

  modifier validPixel(uint16 row, uint16 col) {
    require(row < 1000 && col < 1000);
    _;
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

   
   
   

  function getPixelColor(uint16 row, uint16 col) constant
    validPixel(row, col) returns (uint24) {
    return pixels[row][col].color;
  }

  function getPixelOwner(uint16 row, uint16 col) constant
    validPixel(row, col) returns (address) {
    if (pixels[row][col].owner == 0) {
      return admin;
    }
    return pixels[row][col].owner;
  }

  function getPixelPrice(uint16 row, uint16 col) constant
    validPixel(row,col) returns (uint) {
    if (pixels[row][col].owner == 0) {
      return defaultPrice;
    }
    return pixels[row][col].price;
  }

  function getUserMessage(address user) constant returns (string) {
    return messages[user];
  }

   
   
   

  function checkPendingWithdrawal() constant returns (uint) {
    return pendingWithdrawals[msg.sender];
  }

  function withdraw() {
    if (pendingWithdrawals[msg.sender] > 0) {
      uint amount = pendingWithdrawals[msg.sender];
      pendingWithdrawals[msg.sender] = 0;
      msg.sender.transfer(amount);
    }
  }

  function buyPixel(uint16 row, uint16 col, uint24 newColor) payable {
    uint balance = pendingWithdrawals[msg.sender];
     
     
    if (row >= 1000 || col >= 1000) {
      pendingWithdrawals[msg.sender] = SafeMath.add(balance, msg.value);
      return;
    }

    uint price = getPixelPrice(row, col);
    address owner = getPixelOwner(row, col);

     
     
    if (msg.value < price) {
      pendingWithdrawals[msg.sender] = SafeMath.add(balance, msg.value);
      return;
    }

    uint fee = SafeMath.div(msg.value, feeRatio);
    uint payout = SafeMath.sub(msg.value, fee);

    uint adminBalance = pendingWithdrawals[admin];
    pendingWithdrawals[admin] = SafeMath.add(adminBalance, fee);

    uint ownerBalance = pendingWithdrawals[owner];
    pendingWithdrawals[owner] = SafeMath.add(ownerBalance, payout);

     
    uint increase = SafeMath.div(SafeMath.mul(price, incrementRate), 100);
    pixels[row][col].price = SafeMath.add(price, increase);
    pixels[row][col].owner = msg.sender;

    PixelTransfer(row, col, price, owner, msg.sender);
    setPixelColor(row, col, newColor);
  }

   
   
   

  function setPixelColor(uint16 row, uint16 col, uint24 color)
    validPixel(row, col) onlyOwner(row, col) {
    if (pixels[row][col].color != color) {
      pixels[row][col].color = color;
      PixelColor(row, col, pixels[row][col].owner, color);
    }
  }

  function setPixelPrice(uint16 row, uint16 col, uint newPrice)
    validPixel(row, col) onlyOwner(row, col) {
     
     
    require(pixels[row][col].price > newPrice);

    pixels[row][col].price = newPrice;
    PixelPrice(row, col, pixels[row][col].owner, newPrice);
  }

   
   
   

  function setUserMessage(string message) {
    messages[msg.sender] = message;
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