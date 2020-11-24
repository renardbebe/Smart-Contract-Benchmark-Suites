 

pragma solidity 0.4.18;


 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


 
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    assert(token.transfer(to, value));
  }

  function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
    assert(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    assert(token.approve(spender, value));
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


 
contract ReentrancyGuard {

   
  bool private reentrancy_lock = false;

   
  modifier nonReentrant() {
    require(!reentrancy_lock);
    reentrancy_lock = true;
    _;
    reentrancy_lock = false;
  }

}

library Utils {
  function isEther(address addr) internal pure returns (bool) {
    return addr == address(0x0);
  }
}


contract DUBIex is ReentrancyGuard {
  using SafeMath for uint256;
  using SafeERC20 for ERC20;
  
   
  struct Order {
    uint256 id;
    address maker;
    uint256 amount;
    address pairA;
    address pairB;
    uint256 priceA;
    uint256 priceB;
  }

   
  mapping(uint256 => Order) public orders;

   
  uint256 private weiSend = 0;

   
  modifier weiSendGuard() {
    weiSend = msg.value;
    _;
    weiSend = 0;
  }

   
  event LogMakeOrder(uint256 id, address indexed maker, uint256 amount, address indexed pairA, address indexed pairB, uint256 priceA, uint256 priceB);
  event LogTakeOrder(uint256 indexed id, address indexed taker, uint256 amount);
  event LogCancelOrder(uint256 indexed id);

   
  function _makeOrder(uint256 id, uint256 amount, address pairA, address pairB, uint256 priceA, uint256 priceB, address maker) internal returns (bool) {
     
    if (
      id <= 0 ||
      amount <= 0 ||
      pairA == pairB ||
      priceA <= 0 ||
      priceB <= 0 ||
      orders[id].id == id
    ) return false;

    bool pairAisEther = Utils.isEther(pairA);
    ERC20 tokenA = ERC20(pairA);

     
    if (pairAisEther && (weiSend <= 0 || weiSend < amount)) return false;
    else if (!pairAisEther && (tokenA.allowance(maker, this) < amount || tokenA.balanceOf(maker) < amount)) return false;

     
    orders[id] = Order(id, maker, amount, pairA, pairB, priceA, priceB);

     
    if (pairAisEther) {
       
      weiSend = weiSend.sub(amount);
    } else {
       
      tokenA.safeTransferFrom(maker, this, amount);
    }

    LogMakeOrder(id, maker, amount, pairA, pairB, priceA, priceB);

    return true;
  }

  function _takeOrder(uint256 id, uint256 amount, address taker) internal returns (bool) {
     
    if (
      id <= 0 ||
      amount <= 0
    ) return false;
    
     
    Order storage order = orders[id];
     
    if (order.id != id) return false;
    
    bool pairAisEther = Utils.isEther(order.pairA);
    bool pairBisEther = Utils.isEther(order.pairB);
     
    uint256 usableAmount = amount > order.amount ? order.amount : amount;
     
    uint256 totalB = usableAmount.mul(order.priceB).div(order.priceA);

     
    ERC20 tokenA = ERC20(order.pairA);
    ERC20 tokenB = ERC20(order.pairB);

     
    if (pairBisEther && (weiSend <= 0 || weiSend < totalB)) return false;
    else if (!pairBisEther && (tokenB.allowance(taker, this) < totalB || tokenB.balanceOf(taker) < amount)) return false;

     
    order.amount = order.amount.sub(usableAmount);

     
    if (pairBisEther) {
      weiSend = weiSend.sub(totalB);
      order.maker.transfer(totalB);
    } else {
      tokenB.safeTransferFrom(taker, order.maker, totalB);
    }

     
    if (pairAisEther) {
      taker.transfer(usableAmount);
    } else {
      tokenA.safeTransfer(taker, usableAmount);
    }

    LogTakeOrder(id, taker, usableAmount);

    return true;
  }

  function _cancelOrder(uint256 id, address maker) internal returns (bool) {
     
    if (id <= 0) return false;

     
    Order storage order = orders[id];
    if (
      order.id != id ||
      order.maker != maker
    ) return false;

    uint256 amount = order.amount;
    bool pairAisEther = Utils.isEther(order.pairA);

     
    order.amount = 0;

     
    if (pairAisEther) {
      order.maker.transfer(amount);
    } else {
      ERC20(order.pairA).safeTransfer(order.maker, amount);
    }

    LogCancelOrder(id);

    return true;
  }

   
  function makeOrder(uint256 id, uint256 amount, address pairA, address pairB, uint256 priceA, uint256 priceB) external payable weiSendGuard nonReentrant returns (bool) {
    bool success = _makeOrder(id, amount, pairA, pairB, priceA, priceB, msg.sender);

    if (weiSend > 0) msg.sender.transfer(weiSend);

    return success;
  }

  function takeOrder(uint256 id, uint256 amount) external payable weiSendGuard nonReentrant returns (bool) {
    bool success = _takeOrder(id, amount, msg.sender);

    if (weiSend > 0) msg.sender.transfer(weiSend);

    return success;
  }

  function cancelOrder(uint256 id) external nonReentrant returns (bool) {
    return _cancelOrder(id, msg.sender);
  }

   
  function makeOrders(uint256[] ids, uint256[] amounts, address[] pairAs, address[] pairBs, uint256[] priceAs, uint256[] priceBs) external payable weiSendGuard nonReentrant returns (bool) {
    require(
      amounts.length == ids.length &&
      pairAs.length == ids.length &&
      pairBs.length == ids.length &&
      priceAs.length == ids.length &&
      priceBs.length == ids.length
    );

    bool allSuccess = true;

    for (uint256 i = 0; i < ids.length; i++) {
       
       
      if (allSuccess && !_makeOrder(ids[i], amounts[i], pairAs[i], pairBs[i], priceAs[i], priceBs[i], msg.sender)) allSuccess = false;
    }

    if (weiSend > 0) msg.sender.transfer(weiSend);

    return allSuccess;
  }

  function takeOrders(uint256[] ids, uint256[] amounts) external payable weiSendGuard nonReentrant returns (bool) {
    require(ids.length == amounts.length);

    bool allSuccess = true;

    for (uint256 i = 0; i < ids.length; i++) {
      bool success = _takeOrder(ids[i], amounts[i], msg.sender);

       
      if (allSuccess && !success) allSuccess = success;
    }

    if (weiSend > 0) msg.sender.transfer(weiSend);

    return allSuccess;
  }

  function cancelOrders(uint256[] ids) external nonReentrant returns (bool) {
    bool allSuccess = true;

    for (uint256 i = 0; i < ids.length; i++) {
      bool success = _cancelOrder(ids[i], msg.sender);

       
      if (allSuccess && !success) allSuccess = success;
    }

    return allSuccess;
  }
}