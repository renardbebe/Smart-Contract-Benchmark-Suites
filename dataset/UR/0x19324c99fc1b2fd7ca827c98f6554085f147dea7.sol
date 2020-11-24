 

pragma solidity ^0.4.19;

 
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

 
contract BlockMarket is Ownable {
  struct Stock {
    string  name;
    uint256 priceIncrease;
    uint256 dividendAmount;
    uint256 lastAction;
    uint256 dividendsPaid;
  }

  struct Share {
    address holder;
    uint256 purchasePrice;
  }

  Stock[] public stocks;
  Share[] public shares;
  mapping (uint256 => uint256[]) public stockShares;

  event CompanyListed(string company, uint256 basePrice);
  event DividendPaid(address shareholder, uint256 amount);
  event ShareSold(
    uint256 stockId,
    uint256 shareId,
    uint256 oldPrice,
    uint256 newPrice,
    address oldOwner,
    address newOwner
  );

   
  function () payable public { }

   
  function addStock(
    string  _name,
    uint256 _initialPrice,
    uint256 _priceIncrease,
    uint256 _dividendAmount,
    uint8   _numShares
  ) public onlyOwner returns (uint256 stockId) {
    stockId = stocks.length;

    stocks.push(
      Stock(
        _name,
        _priceIncrease == 0 ? 130 : _priceIncrease,  
        _dividendAmount == 0 ? 110 : _dividendAmount,  
        block.timestamp,
        0
      )
    );

    for(uint8 i = 0; i < _numShares; i++) {
      stockShares[stockId].push(shares.length);
      shares.push(Share(owner, _initialPrice));
    }

    CompanyListed(_name, _initialPrice);
  }

   
  function purchase(uint256 _stockId, uint256 _shareId) public payable {
    require(_stockId < stocks.length && _shareId < shares.length);

     
    Stock storage stock = stocks[_stockId];
    uint256[] storage sharesForStock = stockShares[_stockId];
    Share storage share = shares[sharesForStock[_shareId]];

     
    address previousHolder = share.holder;

     
    uint256 currentPrice = getPurchasePrice(
      share.purchasePrice,
      stock.priceIncrease
    );
    require(msg.value >= currentPrice);

     
    if (msg.value > currentPrice) {
      msg.sender.transfer(SafeMath.sub(msg.value, currentPrice));
    }

     
    uint256 dividendPerRecipient = getDividendPayout(
      currentPrice,
      stock.dividendAmount,
      sharesForStock.length - 1
    );

     
    uint256 previousHolderShare = SafeMath.sub(
      currentPrice,
      SafeMath.mul(dividendPerRecipient, sharesForStock.length - 1)
    );

     
    uint256 fee = SafeMath.div(previousHolderShare, 40);
    owner.transfer(fee);

     
    previousHolder.transfer(SafeMath.sub(previousHolderShare, fee));

     
    for(uint8 i = 0; i < sharesForStock.length; i++) {
      if (i != _shareId) {
        shares[sharesForStock[i]].holder.transfer(dividendPerRecipient);
        stock.dividendsPaid = SafeMath.add(stock.dividendsPaid, dividendPerRecipient);
        DividendPaid(
          shares[sharesForStock[i]].holder,
          dividendPerRecipient
        );
      }
    }

    ShareSold(
      _stockId,
      _shareId,
      share.purchasePrice,
      currentPrice,
      share.holder,
      msg.sender
    );

     
    share.holder = msg.sender;
    share.purchasePrice = currentPrice;
    stock.lastAction = block.timestamp;
  }

   
  function getCurrentPrice(
    uint256 _stockId,
    uint256 _shareId
  ) public view returns (uint256 currentPrice) {
    require(_stockId < stocks.length && _shareId < shares.length);
    currentPrice = SafeMath.div(
      SafeMath.mul(stocks[_stockId].priceIncrease, shares[_shareId].purchasePrice),
      100
    );
  }

   
  function getPurchasePrice(
    uint256 _currentPrice,
    uint256 _priceIncrease
  ) internal pure returns (uint256 currentPrice) {
    currentPrice = SafeMath.div(
      SafeMath.mul(_currentPrice, _priceIncrease),
      100
    );
  }

   
  function getDividendPayout(
    uint256 _purchasePrice,
    uint256 _stockDividend,
    uint256 _numDividends
  ) public pure returns (uint256 dividend) {
    uint256 dividendPerRecipient = SafeMath.sub(
      SafeMath.div(SafeMath.mul(_purchasePrice, _stockDividend), 100),
      _purchasePrice
    );
    dividend = SafeMath.div(dividendPerRecipient, _numDividends);
  }

   
  function getStockCount() public view returns (uint256) {
    return stocks.length;
  }

   
  function getStockShares(uint256 _stockId) public view returns (uint256[]) {
    return stockShares[_stockId];
  }

   
  function withdraw(uint256 _amount, address _destination) public onlyOwner {
    require(_destination != address(0));
    require(_amount <= this.balance);
    _destination.transfer(_amount == 0 ? this.balance : _amount);
  }
}