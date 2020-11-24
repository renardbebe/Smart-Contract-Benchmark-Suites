 

pragma solidity ^0.4.23;

library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Ownable {
   
  address owner;

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function Ownable() public {
    owner = msg.sender;
  }

   
  function transferOwnership(address newOwner) onlyOwner {
    owner = newOwner;
  }

}

contract Transaction is Ownable {
   
  struct TransactionNeoPlace {
    uint id;
    address seller;
    address buyer;
    bytes16 itemId;
    bytes8 typeItem;
    string location;
    string pictureHash;
    bytes16 receiptHash;
    string comment;
    bytes8 status;
    uint256 _price;
  }

   
  mapping(uint => TransactionNeoPlace) public transactions;
  mapping(bytes16 => uint256) public fundsLocked;

  uint transactionCounter;

   
  event BuyItem(
    uint indexed _id,
    bytes16 indexed _itemId,
    address _seller,
    address _buyer,
    uint256 _price
  );

  function kill() public onlyOwner {
    selfdestruct(owner);
  }

   
  function getNumberOfTransactions() public view returns (uint) {
    return transactionCounter;
  }

   
  function getSales() public view returns (uint[]) {
     
    uint[] memory transactionIds = new uint[](transactionCounter);

    uint numberOfSales = 0;

     
    for(uint i = 1; i <= transactionCounter; i++) {
       
      if(transactions[i].seller == msg.sender) {
        transactionIds[numberOfSales] = transactions[i].id;
        numberOfSales++;
      }
    }

     
    uint[] memory sales = new uint[](numberOfSales);
    for(uint j = 0; j < numberOfSales; j++) {
      sales[j] = transactionIds[j];
    }
    return sales;
  }

   
  function getPurchases() public view returns (uint[]) {
     
    uint[] memory transactionIds = new uint[](transactionCounter);

    uint numberOfBuy = 0;

     
    for(uint i = 1; i <= transactionCounter; i++) {
       
      if(transactions[i].buyer == msg.sender) {
        transactionIds[numberOfBuy] = transactions[i].id;
        numberOfBuy++;
      }
    }

     
    uint[] memory buy = new uint[](numberOfBuy);
    for(uint j = 0; j < numberOfBuy; j++) {
      buy[j] = transactionIds[j];
    }
    return buy;
  }

   
  function buyItem(address _seller, bytes16 _itemId, bytes8 _typeItem, string _location, string _pictureHash, string _comment, bytes8 _status, uint256 _price) payable public {
     
    require(_seller != 0x0);
     
    require(msg.sender != _seller);

    require(_itemId.length > 0);
    require(_typeItem.length > 0);
    require(bytes(_location).length > 0);
    require(bytes(_pictureHash).length > 0);
     

    require(msg.value == _price);


     
     
    fundsLocked[_itemId]=fundsLocked[_itemId] + _price;

     
    transactionCounter++;

     
    transactions[transactionCounter] = TransactionNeoPlace(
      transactionCounter,
      _seller,
      msg.sender,
      _itemId,
      _typeItem,
      _location,
      _pictureHash,
      "",
      _comment,
      _status,
      _price
    );

     
    BuyItem(transactionCounter, _itemId, _seller, msg.sender, _price);
  }

   
   
  function sendAdditionalFunds(address _seller, bytes16 _itemId, uint256 _price) payable public {
     
    require(_seller != 0x0);
     
    require(msg.sender != _seller);

    require(_itemId.length > 0);

    require(msg.value == _price);

    for(uint i = 0; i <= transactionCounter; i++) {
      if(transactions[i].itemId == _itemId) {

        require(msg.sender == transactions[i].buyer);
        require(stringToBytes8("paid") == transactions[i].status);
        address seller = transactions[i].seller;
        transactions[i]._price = transactions[i]._price + msg.value;

         
        seller.transfer(msg.value);

        break;
      }
    }
  }

  function unlockFunds(bytes16 _itemId) public {

    for(uint i = 0; i <= transactionCounter; i++) {
      if(transactions[i].itemId == _itemId) {

        require(msg.sender == transactions[i].buyer);
        require(stringToBytes8("paid") != transactions[i].status);
        address buyer = transactions[i].buyer;
        address seller = transactions[i].seller;
        uint256 priceTransaction = transactions[i]._price;

        require(fundsLocked[_itemId]>0);
        fundsLocked[_itemId]=fundsLocked[_itemId] - (priceTransaction);

         
        seller.transfer(priceTransaction);

        transactions[i].status = stringToBytes8('paid');

        break;
      }
    }
  }

   function sendAmount(address seller) payable public {
       
      require(seller != 0x0);
       
      require(msg.sender != seller);

      seller.transfer(msg.value);
   }

  function stringToBytes8(string memory source) returns (bytes8 result) {
    bytes memory tempEmptyStringTest = bytes(source);
    if (tempEmptyStringTest.length == 0) {
      return 0x0;
    }

    assembly {
      result := mload(add(source, 8))
    }
  }

}