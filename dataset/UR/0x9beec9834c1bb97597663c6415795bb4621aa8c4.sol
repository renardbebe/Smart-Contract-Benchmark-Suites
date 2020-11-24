 

pragma solidity ^0.4.18;

 


 
pragma solidity ^0.4.15;

 

 
pragma solidity ^0.4.15;

 
 

contract iERC20Token {
  function totalSupply() public constant returns (uint supply);
  function balanceOf( address who ) public constant returns (uint value);
  function allowance( address owner, address spender ) public constant returns (uint remaining);

  function transfer( address to, uint value) public returns (bool ok);
  function transferFrom( address from, address to, uint value) public returns (bool ok);
  function approve( address spender, uint value ) public returns (bool ok);

  event Transfer( address indexed from, address indexed to, uint value);
  event Approval( address indexed owner, address indexed spender, uint value);
}

contract iBurnableToken is iERC20Token {
  function burnTokens(uint _burnCount) public;
  function unPaidBurnTokens(uint _burnCount) public;
}

 
pragma solidity ^0.4.11;

 
contract SafeMath {
     
    function SafeMath() public {
    }

     
    function safeAdd(uint256 _x, uint256 _y) pure internal returns (uint256) {
        uint256 z = _x + _y;
        assert(z >= _x);
        return z;
    }

     
    function safeSub(uint256 _x, uint256 _y) pure internal returns (uint256) {
        assert(_x >= _y);
        return _x - _y;
    }

     
    function safeMul(uint256 _x, uint256 _y) pure internal returns (uint256) {
        uint256 z = _x * _y;
        assert(_x == 0 || z / _x == _y);
        return z;
    }
}


contract TokenAuction is SafeMath {

  struct SecretBid {
    bool disqualified;      
    uint deposit;           
    uint refund;            
    uint tokens;            
    bytes32 hash;           
  }
  uint constant  AUCTION_START_EVENT = 0x01;
  uint constant  AUCTION_END_EVENT   = 0x02;
  uint constant  SALE_START_EVENT    = 0x04;
  uint constant  SALE_END_EVENT      = 0x08;

  event SecretBidEvent(uint indexed batch, address indexed bidder, uint deposit, bytes32 hash, bytes message);
  event ExecuteEvent(uint indexed batch, address indexed bidder, uint cost, uint refund);
  event ExpireEvent(uint indexed batch, address indexed bidder, uint cost, uint refund);
  event BizarreEvent(address indexed addr, string message, uint val);
  event BidDisqualifiedEvent(address indexed bidder, bytes32 hash);
  event StateChangeEvent(uint mask);
   
   
   
   
   

  bool public isLocked;
  uint public stateMask;
  address public owner;
  address public developers;
  address public underwriter;
  iBurnableToken public token;
  uint public proceeds;
  uint public strikePrice;
  uint public strikePricePctX10;
  uint public decimalMultiplier;
  uint public developerReserve;
  uint public developerPctX10K;
  uint public purchasedCount;
  uint public secretBidCount;
  uint public executedCount;
  uint public expiredCount;
  uint public saleDuration;
  uint public auctionStart;
  uint public auctionEnd;
  uint public saleEnd;
  mapping (address => SecretBid) public secretBids;

   
   
  uint batchSize = 4;
  uint contractSendGas = 100000;

  modifier ownerOnly {
    require(msg.sender == owner);
    _;
  }

  modifier unlockedOnly {
    require(!isLocked);
    _;
  }

  modifier duringAuction {
    require((stateMask & (AUCTION_START_EVENT | AUCTION_END_EVENT)) == AUCTION_START_EVENT);
    _;
  }

  modifier afterAuction {
    require((stateMask & AUCTION_END_EVENT) != 0);
    _;
  }

  modifier duringSale {
    require((stateMask & (SALE_START_EVENT | SALE_END_EVENT)) == SALE_START_EVENT);
    _;
  }

  modifier afterSale {
    require((stateMask & SALE_END_EVENT) != 0);
    _;
  }


   
   
   
  function TokenAuction() public {
    owner = msg.sender;
  }

  function lock() public ownerOnly {
    isLocked = true;
  }

  function setToken(iBurnableToken _token, uint _decimalMultiplier, address _underwriter) public ownerOnly unlockedOnly {
    token = _token;
    decimalMultiplier = _decimalMultiplier;
    underwriter = _underwriter;
  }

  function setAuctionParms(uint _auctionStart, uint _auctionDuration, uint _saleDuration) public ownerOnly unlockedOnly {
    auctionStart = _auctionStart;
    auctionEnd = safeAdd(_auctionStart, _auctionDuration);
    saleDuration = _saleDuration;
    if (stateMask != 0) {
       
      stateMask = 0;
      strikePrice = 0;
      executedCount = 0;
      houseKeep();
    }
  }


  function reserveDeveloperTokens(address _developers, uint _developerPctX10K) public ownerOnly unlockedOnly {
    require(developerPctX10K < 1000000);
    developers = _developers;
    developerPctX10K = _developerPctX10K;
    uint _tokenCount = token.balanceOf(this);
    developerReserve = safeMul(_tokenCount, developerPctX10K) / 1000000;
  }

  function tune(uint _batchSize, uint _contractSendGas) public ownerOnly {
    batchSize = _batchSize;
    contractSendGas = _contractSendGas;
  }


   
   
   
  function houseKeep() public {
    uint _oldMask = stateMask;
    if (now >= auctionStart) {
      stateMask |= AUCTION_START_EVENT;
      if (now >= auctionEnd) {
        stateMask |= AUCTION_END_EVENT;
        if (strikePrice > 0) {
          stateMask |= SALE_START_EVENT;
          if (now >= saleEnd)
            stateMask |= SALE_END_EVENT;
        }
      }
    }
    if (stateMask != _oldMask)
      StateChangeEvent(stateMask);
  }



   
   
   
   
   
   
   
   
  function setStrikePrice(uint _strikePrice, uint _strikePricePctX10) public ownerOnly afterAuction {
    require(executedCount == 0);
    strikePrice = _strikePrice;
    strikePricePctX10 = _strikePricePctX10;
    saleEnd = safeAdd(now, saleDuration);
    houseKeep();
  }


   
   
   
   
   
  function () public payable {
    proceeds = safeAdd(proceeds, msg.value);
    BizarreEvent(msg.sender, "bizarre payment", msg.value);
  }


  function depositSecretBid(bytes32 _hash, bytes _message) public duringAuction payable {
     
     
    if (!(msg.sender == owner && !isLocked) &&
         (_hash == 0 || secretBids[msg.sender].hash != 0) )
        revert();
    secretBids[msg.sender].hash = _hash;
    secretBids[msg.sender].deposit = msg.value;
    secretBids[msg.sender].disqualified = false;
    secretBidCount += 1;
    uint _batch = secretBidCount / batchSize;
    SecretBidEvent(_batch, msg.sender, msg.value, _hash, _message);
  }


   
   
   
   
   
   
  function disqualifyBid(address _from, bool _doRefund) public ownerOnly duringAuction {
    secretBids[_from].disqualified = true;
    BidDisqualifiedEvent(_from, secretBids[_from].hash);
    if (_doRefund == true) {
      uint _amount = secretBids[_from].deposit;
      secretBids[_from].hash = bytes32(0);
      secretBids[_from].deposit = 0;
      secretBidCount = safeSub(secretBidCount, 1);
      if (_amount > 0)
        _from.transfer(_amount);
    }
  }


   
   
   
   
   
   
   
   
   
  function executeBid(uint256 _secret, uint256 _price, uint256 _quantity) public duringSale {
    executeBidFor(msg.sender, _secret, _price, _quantity);
  }
  function executeBidFor(address _addr, uint256 _secret, uint256 _price, uint256 _quantity) public duringSale {
    bytes32 computedHash = keccak256(_secret, _price, _quantity);
     
    require(secretBids[_addr].hash == computedHash);
     
    if (secretBids[_addr].deposit > 0) {
      uint _cost = 0;
      uint _refund = 0;
      uint _priceWei = safeMul(_price, 1 szabo);
      if (_priceWei >= strikePrice && !secretBids[_addr].disqualified) {
          
          
         uint _lowLevelQuantity = safeMul(_quantity, decimalMultiplier);
         uint _lowLevelPrice = strikePrice / decimalMultiplier;
         uint256 _purchaseCount = (_priceWei > strikePrice) ? _lowLevelQuantity : (safeMul(strikePricePctX10, _lowLevelQuantity) / 1000);
         var _maxPurchase = safeSub(token.balanceOf(this), developerReserve);
         if (_purchaseCount > _maxPurchase)
           _purchaseCount = _maxPurchase;
         _cost = safeMul(_purchaseCount, _lowLevelPrice);
         if (secretBids[_addr].deposit >= _cost) {
           secretBids[_addr].deposit -= _cost;
           proceeds = safeAdd(proceeds, _cost);
           secretBids[_addr].tokens += _purchaseCount;
           purchasedCount += _purchaseCount;
            
           if (!token.transfer(_addr, _purchaseCount))
             revert();
         }
      }
       
       
      if (secretBids[_addr].deposit > 0) {
        _refund = secretBids[_addr].deposit;
        secretBids[_addr].refund += _refund;
        secretBids[_addr].deposit = 0;
      }
      executedCount += 1;
      uint _batch = executedCount / batchSize;
      ExecuteEvent(_batch, _addr, _cost, _refund);
    }
  }


   
   
   
   
   
   
   
  function expireBid(address _addr) public ownerOnly afterSale {
    if (secretBids[_addr].deposit > 0) {
      uint _forfeit = secretBids[_addr].deposit / 2;
      proceeds = safeAdd(proceeds, _forfeit);
       
      uint _refund = safeSub(secretBids[_addr].deposit, _forfeit);
       
      secretBids[msg.sender].refund += _refund;
      secretBids[_addr].deposit = 0;
      expiredCount += 1;
      uint _batch = expiredCount / batchSize;
      ExpireEvent(_batch, _addr, _forfeit, _refund);
    }
  }


   
   
   
  function withdrawRefund() public {
    uint _amount = secretBids[msg.sender].refund;
    secretBids[msg.sender].refund = 0;
    msg.sender.transfer(_amount);
  }


   
   
   
   
  function doDeveloperGrant() public afterSale {
    uint _quantity = safeMul(purchasedCount, developerPctX10K) / 1000000;
    uint _tokensLeft = token.balanceOf(this);
    if (_quantity > _tokensLeft)
      _quantity = _tokensLeft;
    if (_quantity > 0) {
       
      _tokensLeft -= _quantity;
      if (!token.transfer(developers, _quantity))
        revert();
    }
     
    token.unPaidBurnTokens(_tokensLeft);
  }


   
   
   
   
  function payUnderwriter() public {
    require(msg.sender == owner || msg.sender == underwriter);
    uint _amount = proceeds;
    proceeds = 0;
    if (!underwriter.call.gas(contractSendGas).value(_amount)())
      revert();
  }


   
   
  function haraKiri() public ownerOnly unlockedOnly {
    selfdestruct(owner);
  }
}