 

pragma solidity ^0.4.24;

 

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
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

library BytesLib {
  function toAddress(bytes _bytes, uint _start) internal pure returns (address) {
    require(_bytes.length >= (_start + 20));
    address tempAddress;

    assembly {
      tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
    }

    return tempAddress;
  }

  function toUint(bytes _bytes, uint _start) internal pure returns (uint256) {
    require(_bytes.length >= (_start + 32));
    uint256 tempUint;

    assembly {
      tempUint := mload(add(add(_bytes, 0x20), _start))
    }

    return tempUint;
  }
}

contract ERC223 {
  uint public totalSupply;
  function balanceOf(address who) constant public returns (uint);

  function name() constant public returns (string _name);
  function symbol() constant public returns (string _symbol);
  function decimals() constant public returns (uint8 _decimals);
  function totalSupply() constant public returns (uint256 _supply);

  function transfer(address to, uint value) public returns (bool ok);
  function transfer(address to, uint value, bytes data) public returns (bool ok);
  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event ERC223Transfer(address indexed _from, address indexed _to, uint256 _value, bytes _data);
}

contract ContractReceiver {
  function tokenFallback(address _from, uint _value, bytes _data) public;
}

contract ERC20 {
    function totalSupply() public view returns (uint);
    function balanceOf(address holder) public view returns (uint);
    function allowance(address holder, address other) public view returns (uint);

    function approve(address other, uint amount) public returns (bool);
    function transfer(address to, uint amount) public returns (bool);
    function transferFrom(
        address from, address to, uint amount
    ) public returns (bool);
}

contract Exchange is ContractReceiver {
  using SafeMath for uint256;
  using BytesLib for bytes;

  struct Order {
    address owner;
    bool    active;
    address sellToken;
    address buyToken;
    address ring;
    uint256 amount;
    uint256 priceMul;
    uint256 priceDiv;
  }

   
  mapping(address => mapping(address => uint256)) private balances;
  mapping(uint256 => Order) private orderBook;
  uint256 public orderCount;
  address private etherAddress = 0x0;

  address private saturnToken;
  address private admin;
  uint256 public tradeMiningBalance;
  address public treasury;

  uint256 public feeMul;
  uint256 public feeDiv;
  uint256 public tradeMiningMul;
  uint256 public tradeMiningDiv;

  event NewOrder(
    uint256 id,
    address owner,
    address sellToken,
    address buyToken,
    address ring,
    uint256 amount,
    uint256 priceMul,
    uint256 priceDiv,
    uint256 time
  );

  event OrderCancelled(
    uint256 id,
    uint256 time
  );

  event OrderFulfilled(
    uint256 id,
    uint256 time
  );

  event Trade(
    address from,
    address to,
    uint256 orderId,
    uint256 soldTokens,
    uint256 boughtTokens,
    uint256 feePaid,
    uint256 time
  );

  event Mined(
    address trader,
    uint256 amount,
    uint256 time
  );

   
   
  function Exchange(
    address _saturnToken,
    address _treasury,
    uint256 _feeMul,
    uint256 _feeDiv,
    uint256 _tradeMiningMul,
    uint256 _tradeMiningDiv
  ) public {
    saturnToken    = _saturnToken;
    treasury       = _treasury;
    feeMul         = _feeMul;
    feeDiv         = _feeDiv;
    tradeMiningMul = _tradeMiningMul;
    tradeMiningDiv = _tradeMiningDiv;
     
     
    admin          = msg.sender;
  }

  function() payable public { revert(); }

   
   
   
   
   

  function getBalance(address token, address user) view public returns(uint256) {
    return balances[user][token];
  }

  function isOrderActive(uint256 orderId) view public returns(bool) {
    return orderBook[orderId].active;
  }

  function remainingAmount(uint256 orderId) view public returns(uint256) {
    return orderBook[orderId].amount;
  }

  function getBuyTokenAmount(uint256 desiredSellTokenAmount, uint256 orderId) public view returns(uint256 amount) {
    require(desiredSellTokenAmount > 0);
    Order storage order = orderBook[orderId];

    if (order.sellToken == etherAddress || order.buyToken == etherAddress) {
      uint256 feediff = feeDiv.sub(feeMul);
      amount = desiredSellTokenAmount.mul(order.priceDiv).mul(feeDiv).div(order.priceMul).div(feediff);
    } else {
      amount = desiredSellTokenAmount.mul(order.priceDiv).div(order.priceMul);
    }
    require(amount > 0);
  }

  function calcFees(uint256 amount, uint256 orderId) public view returns(uint256 fees) {
    Order storage order = orderBook[orderId];

    if (order.sellToken == etherAddress) {
      uint256 sellTokenAmount = amount.mul(order.priceMul).div(order.priceDiv);
      fees = sellTokenAmount.mul(feeMul).div(feeDiv);
    } else if (order.buyToken == etherAddress) {
      fees = amount.mul(feeMul).div(feeDiv);
    } else {
      fees = 0;
    }
    return fees;
  }

  function tradeMiningAmount(uint256 fees, uint256 orderId) public view returns(uint256) {
    if (fees == 0) { return 0; }
    Order storage order = orderBook[orderId];
    if (!order.active) { return 0; }
    uint256 tokenAmount = fees.mul(tradeMiningMul).div(tradeMiningDiv);

    if (tradeMiningBalance < tokenAmount) {
      return tradeMiningBalance;
    } else {
      return tokenAmount;
    }
  }

   
   
   

  function withdrawTradeMining() public {
    if (msg.sender != admin) { revert(); }
    require(tradeMiningBalance > 0);

    uint toSend = tradeMiningBalance;
    tradeMiningBalance = 0;
    require(sendTokensTo(admin, toSend, saturnToken));
  }

  function changeTradeMiningPrice(uint256 newMul, uint256 newDiv) public {
    if (msg.sender != admin) { revert(); }
    require(newDiv != 0);
    tradeMiningMul = newMul;
    tradeMiningDiv = newDiv;
  }

   
  function tokenFallback(address from, uint value, bytes data) public {
     
     
     
     
    if (data.length == 0 && msg.sender == saturnToken) {
      _topUpTradeMining(value);
    } else if (data.length == 84) {
      _newOrder(from, msg.sender, data.toAddress(64), value, data.toUint(0), data.toUint(32), etherAddress);
    } else if (data.length == 104) {
      _newOrder(from, msg.sender, data.toAddress(64), value, data.toUint(0), data.toUint(32), data.toAddress(84));
    } else if (data.length == 32) {
      _executeOrder(from, data.toUint(0), msg.sender, value);
    } else {
       
      revert();
    }
  }

  function sellEther(
    address buyToken,
    uint256 priceMul,
    uint256 priceDiv
  ) public payable returns(uint256 orderId) {
    require(msg.value > 0);
    return _newOrder(msg.sender, etherAddress, buyToken, msg.value, priceMul, priceDiv, etherAddress);
  }

  function sellEtherWithRing(
    address buyToken,
    uint256 priceMul,
    uint256 priceDiv,
    address ring
  ) public payable returns(uint256 orderId) {
    require(msg.value > 0);
    return _newOrder(msg.sender, etherAddress, buyToken, msg.value, priceMul, priceDiv, ring);
  }

  function buyOrderWithEth(uint256 orderId) public payable {
    require(msg.value > 0);
    _executeOrder(msg.sender, orderId, etherAddress, msg.value);
  }

  function sellERC20Token(
    address sellToken,
    address buyToken,
    uint256 amount,
    uint256 priceMul,
    uint256 priceDiv
  ) public returns(uint256 orderId) {
    require(amount > 0);
    require(pullTokens(sellToken, amount));
    return _newOrder(msg.sender, sellToken, buyToken, amount, priceMul, priceDiv, etherAddress);
  }

  function sellERC20TokenWithRing(
    address sellToken,
    address buyToken,
    uint256 amount,
    uint256 priceMul,
    uint256 priceDiv,
    address ring
  ) public returns(uint256 orderId) {
    require(amount > 0);
    require(pullTokens(sellToken, amount));
    return _newOrder(msg.sender, sellToken, buyToken, amount, priceMul, priceDiv, ring);
  }

  function buyOrderWithERC20Token(
    uint256 orderId,
    address token,
    uint256 amount
  ) public {
    require(amount > 0);
    require(pullTokens(token, amount));
    _executeOrder(msg.sender, orderId, token, amount);
  }

  function cancelOrder(uint256 orderId) public {
    Order storage order = orderBook[orderId];
    require(order.amount > 0);
    require(order.active);
    require(msg.sender == order.owner);

    balances[msg.sender][order.sellToken] = balances[msg.sender][order.sellToken].sub(order.amount);
    require(sendTokensTo(order.owner, order.amount, order.sellToken));

     
     
    delete orderBook[orderId];
    emit OrderCancelled(orderId, now);
  }

   
   
   

  function _newOrder(
    address owner,
    address sellToken,
    address buyToken,
    uint256 amount,
    uint256 priceMul,
    uint256 priceDiv,
    address ring
  ) private returns(uint256 orderId) {
     
     
     
    require(amount > 0);
    require(priceMul > 0);
    require(priceDiv > 0);
    require(sellToken != buyToken);
     
     
     
    orderId = orderCount++;
    orderBook[orderId] = Order(owner, true, sellToken, buyToken, ring, amount, priceMul, priceDiv);
    balances[owner][sellToken] = balances[owner][sellToken].add(amount);

    emit NewOrder(orderId, owner, sellToken, buyToken, ring, amount, priceMul, priceDiv, now);
  }

  function _executeBuyOrder(address trader, uint256 orderId, uint256 buyTokenAmount) private returns(uint256) {
     
     
    Order storage order = orderBook[orderId];
    uint256 sellTokenAmount = buyTokenAmount.mul(order.priceMul).div(order.priceDiv);
    uint256 fees = sellTokenAmount.mul(feeMul).div(feeDiv);

    require(sellTokenAmount > 0);
    require(sellTokenAmount <= order.amount);
    order.amount = order.amount.sub(sellTokenAmount);
     
    require(sendTokensTo(order.owner, buyTokenAmount, order.buyToken));
     
    require(sendTokensTo(trader, sellTokenAmount.sub(fees), order.sellToken));

    emit Trade(trader, order.owner, orderId, sellTokenAmount.sub(fees), buyTokenAmount, fees, now);
    return fees;
  }

  function _executeSellOrder(address trader, uint256 orderId, uint256 buyTokenAmount) private returns(uint256) {
     
     
    Order storage order = orderBook[orderId];
    uint256 fees = buyTokenAmount.mul(feeMul).div(feeDiv);
    uint256 sellTokenAmount = buyTokenAmount.sub(fees).mul(order.priceMul).div(order.priceDiv);


    require(sellTokenAmount > 0);
    require(sellTokenAmount <= order.amount);
    order.amount = order.amount.sub(sellTokenAmount);
     
    require(sendTokensTo(order.owner, buyTokenAmount.sub(fees), order.buyToken));
     
    require(sendTokensTo(trader, sellTokenAmount, order.sellToken));

    emit Trade(trader, order.owner, orderId, sellTokenAmount, buyTokenAmount.sub(fees), fees, now);
    return fees;
  }

  function _executeTokenSwap(address trader, uint256 orderId, uint256 buyTokenAmount) private returns(uint256) {
     
    Order storage order = orderBook[orderId];
    uint256 sellTokenAmount = buyTokenAmount.mul(order.priceMul).div(order.priceDiv);

    require(sellTokenAmount > 0);
    require(sellTokenAmount <= order.amount);
    order.amount = order.amount.sub(sellTokenAmount);

    require(sendTokensTo(order.owner, buyTokenAmount, order.buyToken));
    require(sendTokensTo(trader, sellTokenAmount, order.sellToken));

    emit Trade(trader, order.owner, orderId, sellTokenAmount, buyTokenAmount, 0, now);
    return 0;
  }

  function _executeOrder(address trader, uint256 orderId, address buyToken, uint256 buyTokenAmount) private {
     
     
     
    require(orderId < orderCount);
    require(buyTokenAmount > 0);
    Order storage order = orderBook[orderId];
    require(order.active);
    require(trader != order.owner);
    require(buyToken == order.buyToken);

     
    if (order.ring != etherAddress) { require(order.ring == tx.origin); }

     
     
     
    uint256 fees;
    if (order.sellToken == etherAddress) {
       
      fees = _executeBuyOrder(trader, orderId, buyTokenAmount);
    } else if (order.buyToken == etherAddress) {
       
      fees = _executeSellOrder(trader, orderId, buyTokenAmount);
    } else {
      fees = _executeTokenSwap(trader, orderId, buyTokenAmount);
    }

     
     
     
     
    require(_tradeMiningAndFees(fees, trader));
     
    if (orderBook[orderId].amount == 0) {
      delete orderBook[orderId];
      emit OrderFulfilled(orderId, now);
    }
  }

  function _tradeMiningAndFees(uint256 fees, address trader) private returns(bool) {
    if (fees == 0) { return true; }
     
    require(sendTokensTo(treasury, fees, etherAddress));
    if (tradeMiningBalance == 0) { return true; }

     
    uint256 tokenAmount = fees.mul(tradeMiningMul).div(tradeMiningDiv);
    if (tokenAmount == 0) { return true; }
    if (tokenAmount > tradeMiningBalance) { tokenAmount = tradeMiningBalance; }

     
    tradeMiningBalance = tradeMiningBalance.sub(tokenAmount);
     
    require(sendTokensTo(trader, tokenAmount, saturnToken));
    emit Mined(trader, tokenAmount, now);
    return true;
  }

  function sendTokensTo(address destination, uint256 amount, address tkn) private returns(bool) {
    if (tkn == etherAddress) {
      destination.transfer(amount);
    } else {
       
      require(ERC20(tkn).transfer(destination, amount));
    }
    return true;
  }

   
  function pullTokens(address token, uint256 amount) private returns(bool) {
    return ERC20(token).transferFrom(msg.sender, address(this), amount);
  }

  function _topUpTradeMining(uint256 amount) private returns(bool) {
    tradeMiningBalance = tradeMiningBalance.add(amount);
    return true;
  }
}