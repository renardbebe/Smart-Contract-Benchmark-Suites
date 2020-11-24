 

pragma solidity ^0.4.18;

 

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

contract ERC223 {
  uint public totalSupply;
  function balanceOf(address who) constant returns (uint);

  function name() constant returns (string _name);
  function symbol() constant returns (string _symbol);
  function decimals() constant returns (uint8 _decimals);
  function totalSupply() constant returns (uint256 _supply);

  function transfer(address to, uint value) returns (bool ok);
  function transfer(address to, uint value, bytes data) returns (bool ok);
  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event ERC223Transfer(address indexed _from, address indexed _to, uint256 _value, bytes _data);
}

contract ContractReceiver {
  function tokenFallback(address _from, uint _value, bytes _data);
}

contract ERC223Token is ERC223 {
  using SafeMath for uint;

  mapping(address => uint) balances;

  string public name;
  string public symbol;
  uint8 public decimals;
  uint256 public totalSupply;


   
  function name() constant returns (string _name) {
      return name;
  }
   
  function symbol() constant returns (string _symbol) {
      return symbol;
  }
   
  function decimals() constant returns (uint8 _decimals) {
      return decimals;
  }
   
  function totalSupply() constant returns (uint256 _totalSupply) {
      return totalSupply;
  }

   
  function transfer(address _to, uint _value, bytes _data) returns (bool success) {
    if(isContract(_to)) {
        return transferToContract(_to, _value, _data);
    }
    else {
        return transferToAddress(_to, _value, _data);
    }
}

   
   
  function transfer(address _to, uint _value) returns (bool success) {

     
     
    bytes memory empty;
    if(isContract(_to)) {
        return transferToContract(_to, _value, empty);
    }
    else {
        return transferToAddress(_to, _value, empty);
    }
}

 
  function isContract(address _addr) private returns (bool is_contract) {
      uint length;
      assembly {
             
            length := extcodesize(_addr)
        }
        if(length>0) {
            return true;
        }
        else {
            return false;
        }
    }

   
  function transferToAddress(address _to, uint _value, bytes _data) private returns (bool success) {
    if (balanceOf(msg.sender) < _value) revert();
    balances[msg.sender] = balanceOf(msg.sender).sub(_value);
    balances[_to] = balanceOf(_to).add(_value);
    Transfer(msg.sender, _to, _value);
    ERC223Transfer(msg.sender, _to, _value, _data);
    return true;
  }

   
  function transferToContract(address _to, uint _value, bytes _data) private returns (bool success) {
    if (balanceOf(msg.sender) < _value) revert();
    balances[msg.sender] = balanceOf(msg.sender).sub(_value);
    balances[_to] = balanceOf(_to).add(_value);
    ContractReceiver reciever = ContractReceiver(_to);
    reciever.tokenFallback(msg.sender, _value, _data);
    Transfer(msg.sender, _to, _value);
    ERC223Transfer(msg.sender, _to, _value, _data);
    return true;
  }


  function balanceOf(address _owner) constant returns (uint balance) {
    return balances[_owner];
  }
}

contract SaturnPresale is ContractReceiver {
  using SafeMath for uint256;

  bool    public active = false;
  address public tokenAddress;
  uint256 public hardCap;
  uint256 public sold;

  struct Order {
    address owner;
    uint256 amount;
    uint256 lockup;
    bool    claimed;
  }

  mapping(uint256 => Order) private orders;
  uint256 private latestOrderId = 0;
  address private owner;
  address private treasury;

  event Activated(uint256 time);
  event Finished(uint256 time);
  event Purchase(address indexed purchaser, uint256 id, uint256 amount, uint256 purchasedAt, uint256 redeemAt);
  event Claim(address indexed purchaser, uint256 id, uint256 amount);

  function SaturnPresale(address token, address ethRecepient, uint256 presaleHardCap) public {
    tokenAddress  = token;
    owner         = msg.sender;
    treasury      = ethRecepient;
    hardCap       = presaleHardCap;
  }

  function tokenFallback(address  , uint _value, bytes  ) public {
     
    if (msg.sender != tokenAddress) { revert(); }
     
    if (active) { revert(); }
     
    if (_value != hardCap) { revert(); }

    active = true;
    Activated(now);
  }

  function amountOf(uint256 orderId) constant public returns (uint256 amount) {
    return orders[orderId].amount;
  }

  function lockupOf(uint256 orderId) constant public returns (uint256 timestamp) {
    return orders[orderId].lockup;
  }

  function ownerOf(uint256 orderId) constant public returns (address orderOwner) {
    return orders[orderId].owner;
  }

  function isClaimed(uint256 orderId) constant public returns (bool claimed) {
    return orders[orderId].claimed;
  }

  function () external payable {
    revert();
  }

  function shortBuy() public payable {
     
    uint256 lockup = now + 12 weeks;
    uint256 priceDiv = 1818181818;
    processPurchase(priceDiv, lockup);
  }

  function mediumBuy() public payable {
     
    uint256 lockup = now + 24 weeks;
    uint256 priceDiv = 1600000000;
    processPurchase(priceDiv, lockup);
  }

  function longBuy() public payable {
     
    uint256 lockup = now + 52 weeks;
    uint256 priceDiv = 1333333333;
    processPurchase(priceDiv, lockup);
  }

  function processPurchase(uint256 priceDiv, uint256 lockup) private {
    if (!active) { revert(); }
    if (msg.value == 0) { revert(); }
    ++latestOrderId;

    uint256 purchasedAmount = msg.value.div(priceDiv);
    if (purchasedAmount == 0) { revert(); }  
    if (purchasedAmount > hardCap - sold) { revert(); }  

    orders[latestOrderId] = Order(msg.sender, purchasedAmount, lockup, false);
    sold += purchasedAmount;

    treasury.transfer(msg.value);
    Purchase(msg.sender, latestOrderId, purchasedAmount, now, lockup);
  }

  function redeem(uint256 orderId) public {
    if (orderId > latestOrderId) { revert(); }
    Order storage order = orders[orderId];

     
    if (msg.sender != order.owner) { revert(); }
    if (now < order.lockup) { revert(); }
    if (order.claimed) { revert(); }
    order.claimed = true;

    ERC223 token = ERC223(tokenAddress);
    token.transfer(order.owner, order.amount);

    Claim(order.owner, orderId, order.amount);
  }

  function endPresale() public {
     
     
    if (msg.sender != owner) { revert(); }
     
    if (!active) { revert(); }
    _end();
  }

  function _end() private {
     
    if (sold < hardCap) {
      ERC223 token = ERC223(tokenAddress);
      token.transfer(treasury, hardCap.sub(sold));
    }
    active = false;
    Finished(now);
  }
}