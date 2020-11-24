 

pragma solidity ^0.4.11;

 
contract ERC20 {
  function totalSupply() constant returns (uint);
  function balanceOf(address _owner) constant returns (uint balance);
  function transfer(address _to, uint _value) returns (bool success);
  function transferFrom(address _from, address _to, uint _value) returns (bool success);
  function approve(address _spender, uint _value) returns (bool success);
  function allowance(address _owner, address _spender) constant returns (uint remaining);
  event Transfer(address indexed _from, address indexed _to, uint _value);
  event Approval(address indexed _owner, address indexed _spender, uint _value);
}

 
 
 
 
 
contract BookERC20EthV1 {

  enum BookType {
    ERC20EthV1
  }

  enum Direction {
    Invalid,
    Buy,
    Sell
  }

  enum Status {
    Unknown,
    Rejected,
    Open,
    Done,
    NeedsGas,
    Sending,  
    FailedSend,  
    FailedTxn  
  }

  enum ReasonCode {
    None,
    InvalidPrice,
    InvalidSize,
    InvalidTerms,
    InsufficientFunds,
    WouldTake,
    Unmatched,
    TooManyMatches,
    ClientCancel
  }

  enum Terms {
    GTCNoGasTopup,
    GTCWithGasTopup,
    ImmediateOrCancel,
    MakerOnly
  }

  struct Order {
     

    address client;
    uint16 price;               
    uint sizeBase;
    Terms terms;

     
    
    Status status;
    ReasonCode reasonCode;
    uint128 executedBase;       
    uint128 executedCntr;       
    uint128 feesBaseOrCntr;     
    uint128 feesRwrd;
  }
  
  struct OrderChain {
    uint128 firstOrderId;
    uint128 lastOrderId;
  }

  struct OrderChainNode {
    uint128 nextOrderId;
    uint128 prevOrderId;
  }
  
   
   
   
   
  
  enum ClientPaymentEventType {
    Deposit,
    Withdraw,
    TransferFrom,
    Transfer
  }

  enum BalanceType {
    Base,
    Cntr,
    Rwrd
  }

  event ClientPaymentEvent(
    address indexed client,
    ClientPaymentEventType clientPaymentEventType,
    BalanceType balanceType,
    int clientBalanceDelta
  );

  enum ClientOrderEventType {
    Create,
    Continue,
    Cancel
  }

  event ClientOrderEvent(
    address indexed client,
    ClientOrderEventType clientOrderEventType,
    uint128 orderId,
    uint maxMatches
  );

  enum MarketOrderEventType {
     
    Add,
     
    Remove,
     
     
    CompleteFill,
     
    PartialFill
  }

   
   

  event MarketOrderEvent(
    uint256 indexed eventTimestamp,
    uint128 indexed orderId,
    MarketOrderEventType marketOrderEventType,
    uint16 price,
    uint depthBase,
    uint tradeBase
  );

   
  
  ERC20 baseToken;

   
  uint constant baseMinInitialSize = 100 finney;

   
   
  uint constant baseMinRemainingSize = 10 finney;

   
   
   
   
   
   
  uint constant baseMaxSize = 10 ** 30;

   
   

   
  uint constant cntrMinInitialSize = 10 finney;

   
  uint constant cntrMaxSize = 10 ** 30;

   

  ERC20 rwrdToken;

   
  uint constant ethRwrdRate = 1000;
  
   

  mapping (address => uint) balanceBaseForClient;
  mapping (address => uint) balanceCntrForClient;
  mapping (address => uint) balanceRwrdForClient;

   
   

  uint constant feeDivisor = 2000;
  
   
  
  address feeCollector;

   
  
  mapping (uint128 => Order) orderForOrderId;
  
   
   

  uint256[85] occupiedPriceBitmaps;

   

  mapping (uint16 => OrderChain) orderChainForOccupiedPrice;
  mapping (uint128 => OrderChainNode) orderChainNodeForOpenOrderId;

   
   
   

  mapping (address => uint128) mostRecentOrderIdForClient;
  mapping (uint128 => uint128) clientPreviousOrderIdBeforeOrderId;

   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
  
  int8 constant minPriceExponent = -5;

  uint constant invalidPrice = 0;

   
  uint constant maxBuyPrice = 1; 
  uint constant minBuyPrice = 10800;
  uint constant minSellPrice = 10801;
  uint constant maxSellPrice = 21600;

   
   
   
   
  function BookERC20EthV1() {
    address creator = msg.sender;
    feeCollector = creator;
  }

   
   
   
   
   
   
  function init(ERC20 _baseToken, ERC20 _rwrdToken) public {
    require(msg.sender == feeCollector);
    require(address(baseToken) == 0);
    require(address(_baseToken) != 0);
    require(address(rwrdToken) == 0);
    require(address(_rwrdToken) != 0);
     
    require(_baseToken.totalSupply() > 0);
    baseToken = _baseToken;
    require(_rwrdToken.totalSupply() > 0);
    rwrdToken = _rwrdToken;
  }

   
   
   
   
  function changeFeeCollector(address newFeeCollector) public {
    address oldFeeCollector = feeCollector;
    require(msg.sender == oldFeeCollector);
    require(newFeeCollector != oldFeeCollector);
    feeCollector = newFeeCollector;
  }
  
   
   
  function getBookInfo() public constant returns (
      BookType _bookType, address _baseToken, address _rwrdToken,
      uint _baseMinInitialSize, uint _cntrMinInitialSize,
      uint _feeDivisor, address _feeCollector
    ) {
    return (
      BookType.ERC20EthV1,
      address(baseToken),
      address(rwrdToken),
      baseMinInitialSize,
      cntrMinInitialSize,
      feeDivisor,
      feeCollector
    );
  }

   
   
   
   
   
   
   
   
   
   
   
   
  function getClientBalances(address client) public constant returns (
      uint bookBalanceBase,
      uint bookBalanceCntr,
      uint bookBalanceRwrd,
      uint approvedBalanceBase,
      uint approvedBalanceRwrd,
      uint ownBalanceBase,
      uint ownBalanceRwrd
    ) {
    bookBalanceBase = balanceBaseForClient[client];
    bookBalanceCntr = balanceCntrForClient[client];
    bookBalanceRwrd = balanceRwrdForClient[client];
    approvedBalanceBase = baseToken.allowance(client, address(this));
    approvedBalanceRwrd = rwrdToken.allowance(client, address(this));
    ownBalanceBase = baseToken.balanceOf(client);
    ownBalanceRwrd = rwrdToken.balanceOf(client);
  }

   
   
  function transferFromBase() public {
    address client = msg.sender;
    address book = address(this);
     
     
    uint amountBase = baseToken.allowance(client, book);
    require(amountBase > 0);
     
    require(baseToken.transferFrom(client, book, amountBase));
     
    assert(baseToken.allowance(client, book) == 0);
    balanceBaseForClient[client] += amountBase;
    ClientPaymentEvent(client, ClientPaymentEventType.TransferFrom, BalanceType.Base, int(amountBase));
  }

   
   
  function transferBase(uint amountBase) public {
    address client = msg.sender;
    require(amountBase > 0);
    require(amountBase <= balanceBaseForClient[client]);
     
    balanceBaseForClient[client] -= amountBase;
     
     
     
    require(baseToken.transfer(client, amountBase));
    ClientPaymentEvent(client, ClientPaymentEventType.Transfer, BalanceType.Base, -int(amountBase));
  }

   
   
  function depositCntr() public payable {
    address client = msg.sender;
    uint amountCntr = msg.value;
    require(amountCntr > 0);
     
    balanceCntrForClient[client] += amountCntr;
    ClientPaymentEvent(client, ClientPaymentEventType.Deposit, BalanceType.Cntr, int(amountCntr));
  }

   
   
  function withdrawCntr(uint amountCntr) public {
    address client = msg.sender;
    require(amountCntr > 0);
    require(amountCntr <= balanceCntrForClient[client]);
     
    balanceCntrForClient[client] -= amountCntr;
     
    client.transfer(amountCntr);
    ClientPaymentEvent(client, ClientPaymentEventType.Withdraw, BalanceType.Cntr, -int(amountCntr));
  }

   
   
  function transferFromRwrd() public {
    address client = msg.sender;
    address book = address(this);
    uint amountRwrd = rwrdToken.allowance(client, book);
    require(amountRwrd > 0);
     
    require(rwrdToken.transferFrom(client, book, amountRwrd));
     
    assert(rwrdToken.allowance(client, book) == 0);
    balanceRwrdForClient[client] += amountRwrd;
    ClientPaymentEvent(client, ClientPaymentEventType.TransferFrom, BalanceType.Rwrd, int(amountRwrd));
  }

   
   
  function transferRwrd(uint amountRwrd) public {
    address client = msg.sender;
    require(amountRwrd > 0);
    require(amountRwrd <= balanceRwrdForClient[client]);
     
    balanceRwrdForClient[client] -= amountRwrd;
     
    require(rwrdToken.transfer(client, amountRwrd));
    ClientPaymentEvent(client, ClientPaymentEventType.Transfer, BalanceType.Rwrd, -int(amountRwrd));
  }

   
   
   
   
  function getOrder(uint128 orderId) public constant returns (
    address client, uint16 price, uint sizeBase, Terms terms,
    Status status, ReasonCode reasonCode, uint executedBase, uint executedCntr,
    uint feesBaseOrCntr, uint feesRwrd) {
    Order storage order = orderForOrderId[orderId];
    return (order.client, order.price, order.sizeBase, order.terms,
            order.status, order.reasonCode, order.executedBase, order.executedCntr,
            order.feesBaseOrCntr, order.feesRwrd);
  }

   
   
   
   
  function getOrderState(uint128 orderId) public constant returns (
    Status status, ReasonCode reasonCode, uint executedBase, uint executedCntr,
    uint feesBaseOrCntr, uint feesRwrd) {
    Order storage order = orderForOrderId[orderId];
    return (order.status, order.reasonCode, order.executedBase, order.executedCntr,
            order.feesBaseOrCntr, order.feesRwrd);
  }
  
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
  function walkClientOrders(
      address client, uint128 maybeLastOrderIdReturned, uint128 minClosedOrderIdCutoff
    ) public constant returns (
      uint128 orderId, uint16 price, uint sizeBase, Terms terms,
      Status status, ReasonCode reasonCode, uint executedBase, uint executedCntr,
      uint feesBaseOrCntr, uint feesRwrd) {
    if (maybeLastOrderIdReturned == 0) {
      orderId = mostRecentOrderIdForClient[client];
    } else {
      orderId = clientPreviousOrderIdBeforeOrderId[maybeLastOrderIdReturned];
    }
    while (true) {
      if (orderId == 0) return;
      Order storage order = orderForOrderId[orderId];
      if (orderId >= minClosedOrderIdCutoff) break;
      if (order.status == Status.Open || order.status == Status.NeedsGas) break;
      orderId = clientPreviousOrderIdBeforeOrderId[orderId];
    }
    return (orderId, order.price, order.sizeBase, order.terms,
            order.status, order.reasonCode, order.executedBase, order.executedCntr,
            order.feesBaseOrCntr, order.feesRwrd);
  }
 
   
   
  function unpackPrice(uint16 price) internal constant returns (
      Direction direction, uint16 mantissa, int8 exponent
    ) {
    uint sidedPriceIndex = uint(price);
    uint priceIndex;
    if (sidedPriceIndex < 1 || sidedPriceIndex > maxSellPrice) {
      direction = Direction.Invalid;
      mantissa = 0;
      exponent = 0;
      return;
    } else if (sidedPriceIndex <= minBuyPrice) {
      direction = Direction.Buy;
      priceIndex = minBuyPrice - sidedPriceIndex;
    } else {
      direction = Direction.Sell;
      priceIndex = sidedPriceIndex - minSellPrice;
    }
    uint zeroBasedMantissa = priceIndex % 900;
    uint zeroBasedExponent = priceIndex / 900;
    mantissa = uint16(zeroBasedMantissa + 100);
    exponent = int8(zeroBasedExponent) + minPriceExponent;
    return;
  }
  
   
   
   
   
  function isBuyPrice(uint16 price) internal constant returns (bool isBuy) {
     
    return price >= maxBuyPrice && price <= minBuyPrice;
  }
  
   
   
   
   
  function computeOppositePrice(uint16 price) internal constant returns (uint16 opposite) {
    if (price < maxBuyPrice || price > maxSellPrice) {
      return uint16(invalidPrice);
    } else if (price <= minBuyPrice) {
      return uint16(maxSellPrice - (price - maxBuyPrice));
    } else {
      return uint16(maxBuyPrice + (maxSellPrice - price));
    }
  }
  
   
   
   
   
   
   
   
   
   
   
   
  function computeCntrAmountUsingUnpacked(
      uint baseAmount, uint16 mantissa, int8 exponent
    ) internal constant returns (uint cntrAmount) {
    if (exponent < 0) {
      return baseAmount * uint(mantissa) / 1000 / 10 ** uint(-exponent);
    } else {
      return baseAmount * uint(mantissa) / 1000 * 10 ** uint(exponent);
    }
  }

   
   
   
   
   
   
   
   
   
   
   
   
  function computeCntrAmountUsingPacked(
      uint baseAmount, uint16 price
    ) internal constant returns (uint) {
    var (, mantissa, exponent) = unpackPrice(price);
    return computeCntrAmountUsingUnpacked(baseAmount, mantissa, exponent);
  }

   
   
  function createOrder(
      uint128 orderId, uint16 price, uint sizeBase, Terms terms, uint maxMatches
    ) public {
    address client = msg.sender;
    require(orderId != 0 && orderForOrderId[orderId].client == 0);
    ClientOrderEvent(client, ClientOrderEventType.Create, orderId, maxMatches);
    orderForOrderId[orderId] =
      Order(client, price, sizeBase, terms, Status.Unknown, ReasonCode.None, 0, 0, 0, 0);
    uint128 previousMostRecentOrderIdForClient = mostRecentOrderIdForClient[client];
    mostRecentOrderIdForClient[client] = orderId;
    clientPreviousOrderIdBeforeOrderId[orderId] = previousMostRecentOrderIdForClient;
    Order storage order = orderForOrderId[orderId];
    var (direction, mantissa, exponent) = unpackPrice(price);
    if (direction == Direction.Invalid) {
      order.status = Status.Rejected;
      order.reasonCode = ReasonCode.InvalidPrice;
      return;
    }
    if (sizeBase < baseMinInitialSize || sizeBase > baseMaxSize) {
      order.status = Status.Rejected;
      order.reasonCode = ReasonCode.InvalidSize;
      return;
    }
    uint sizeCntr = computeCntrAmountUsingUnpacked(sizeBase, mantissa, exponent);
    if (sizeCntr < cntrMinInitialSize || sizeCntr > cntrMaxSize) {
      order.status = Status.Rejected;
      order.reasonCode = ReasonCode.InvalidSize;
      return;
    }
    if (terms == Terms.MakerOnly && maxMatches != 0) {
      order.status = Status.Rejected;
      order.reasonCode = ReasonCode.InvalidTerms;
      return;
    }
    if (!debitFunds(client, direction, sizeBase, sizeCntr)) {
      order.status = Status.Rejected;
      order.reasonCode = ReasonCode.InsufficientFunds;
      return;
    }
    processOrder(orderId, maxMatches);
  }

   
   
  function cancelOrder(uint128 orderId) public {
    address client = msg.sender;
    Order storage order = orderForOrderId[orderId];
    require(order.client == client);
    Status status = order.status;
    if (status != Status.Open && status != Status.NeedsGas) {
      return;
    }
    ClientOrderEvent(client, ClientOrderEventType.Cancel, orderId, 0);
    if (status == Status.Open) {
      removeOpenOrderFromBook(orderId);
      MarketOrderEvent(block.timestamp, orderId, MarketOrderEventType.Remove, order.price,
        order.sizeBase - order.executedBase, 0);
    }
    refundUnmatchedAndFinish(orderId, Status.Done, ReasonCode.ClientCancel);
  }

   
   
  function continueOrder(uint128 orderId, uint maxMatches) public {
    address client = msg.sender;
    Order storage order = orderForOrderId[orderId];
    require(order.client == client);
    if (order.status != Status.NeedsGas) {
      return;
    }
    ClientOrderEvent(client, ClientOrderEventType.Continue, orderId, maxMatches);
    order.status = Status.Unknown;
    processOrder(orderId, maxMatches);
  }

   
   
   
   
   
   
   
   
  function removeOpenOrderFromBook(uint128 orderId) internal {
    Order storage order = orderForOrderId[orderId];
    uint16 price = order.price;
    OrderChain storage orderChain = orderChainForOccupiedPrice[price];
    OrderChainNode storage orderChainNode = orderChainNodeForOpenOrderId[orderId];
    uint128 nextOrderId = orderChainNode.nextOrderId;
    uint128 prevOrderId = orderChainNode.prevOrderId;
    if (nextOrderId != 0) {
      OrderChainNode storage nextOrderChainNode = orderChainNodeForOpenOrderId[nextOrderId];
      nextOrderChainNode.prevOrderId = prevOrderId;
    } else {
      orderChain.lastOrderId = prevOrderId;
    }
    if (prevOrderId != 0) {
      OrderChainNode storage prevOrderChainNode = orderChainNodeForOpenOrderId[prevOrderId];
      prevOrderChainNode.nextOrderId = nextOrderId;
    } else {
      orderChain.firstOrderId = nextOrderId;
    }
    if (nextOrderId == 0 && prevOrderId == 0) {
      uint bmi = price / 256;   
      uint bti = price % 256;   
       
      occupiedPriceBitmaps[bmi] ^= 2 ** bti;
    }
  }

   
   
  function creditExecutedFundsLessFees(uint128 orderId, uint originalExecutedBase, uint originalExecutedCntr) internal {
    Order storage order = orderForOrderId[orderId];
    uint liquidityTakenBase = order.executedBase - originalExecutedBase;
    uint liquidityTakenCntr = order.executedCntr - originalExecutedCntr;
     
     
     
     
     
     
    uint feesRwrd = liquidityTakenCntr / feeDivisor * ethRwrdRate;
    uint feesBaseOrCntr;
    address client = order.client;
    uint availRwrd = balanceRwrdForClient[client];
    if (feesRwrd <= availRwrd) {
      balanceRwrdForClient[client] = availRwrd - feesRwrd;
      balanceRwrdForClient[feeCollector] = feesRwrd;
       
       
       
      order.feesRwrd += uint128(feesRwrd);
      if (isBuyPrice(order.price)) {
        balanceBaseForClient[client] += liquidityTakenBase;
      } else {
        balanceCntrForClient[client] += liquidityTakenCntr;
      }
    } else if (isBuyPrice(order.price)) {
       
      feesBaseOrCntr = liquidityTakenBase / feeDivisor;
      balanceBaseForClient[order.client] += (liquidityTakenBase - feesBaseOrCntr);
      order.feesBaseOrCntr += uint128(feesBaseOrCntr);
      balanceBaseForClient[feeCollector] += feesBaseOrCntr;
    } else {
       
      feesBaseOrCntr = liquidityTakenCntr / feeDivisor;
      balanceCntrForClient[order.client] += (liquidityTakenCntr - feesBaseOrCntr);
      order.feesBaseOrCntr += uint128(feesBaseOrCntr);
      balanceCntrForClient[feeCollector] += feesBaseOrCntr;
    }
  }

   
   
   
   
  function processOrder(uint128 orderId, uint maxMatches) internal {
    Order storage order = orderForOrderId[orderId];

    uint ourOriginalExecutedBase = order.executedBase;
    uint ourOriginalExecutedCntr = order.executedCntr;

    var (ourDirection,) = unpackPrice(order.price);
    uint theirPriceStart = (ourDirection == Direction.Buy) ? minSellPrice : maxBuyPrice;
    uint theirPriceEnd = computeOppositePrice(order.price);
   
    MatchStopReason matchStopReason =
      matchAgainstBook(orderId, theirPriceStart, theirPriceEnd, maxMatches);

    creditExecutedFundsLessFees(orderId, ourOriginalExecutedBase, ourOriginalExecutedCntr);

    if (order.terms == Terms.ImmediateOrCancel) {
      if (matchStopReason == MatchStopReason.Satisfied) {
        refundUnmatchedAndFinish(orderId, Status.Done, ReasonCode.None);
        return;
      } else if (matchStopReason == MatchStopReason.MaxMatches) {
        refundUnmatchedAndFinish(orderId, Status.Done, ReasonCode.TooManyMatches);
        return;
      } else if (matchStopReason == MatchStopReason.BookExhausted) {
        refundUnmatchedAndFinish(orderId, Status.Done, ReasonCode.Unmatched);
        return;
      }
    } else if (order.terms == Terms.MakerOnly) {
      if (matchStopReason == MatchStopReason.MaxMatches) {
        refundUnmatchedAndFinish(orderId, Status.Rejected, ReasonCode.WouldTake);
        return;
      } else if (matchStopReason == MatchStopReason.BookExhausted) {
        enterOrder(orderId);
        return;
      }
    } else if (order.terms == Terms.GTCNoGasTopup) {
      if (matchStopReason == MatchStopReason.Satisfied) {
        refundUnmatchedAndFinish(orderId, Status.Done, ReasonCode.None);
        return;
      } else if (matchStopReason == MatchStopReason.MaxMatches) {
        refundUnmatchedAndFinish(orderId, Status.Done, ReasonCode.TooManyMatches);
        return;
      } else if (matchStopReason == MatchStopReason.BookExhausted) {
        enterOrder(orderId);
        return;
      }
    } else if (order.terms == Terms.GTCWithGasTopup) {
      if (matchStopReason == MatchStopReason.Satisfied) {
        refundUnmatchedAndFinish(orderId, Status.Done, ReasonCode.None);
        return;
      } else if (matchStopReason == MatchStopReason.MaxMatches) {
        order.status = Status.NeedsGas;
        return;
      } else if (matchStopReason == MatchStopReason.BookExhausted) {
        enterOrder(orderId);
        return;
      }
    }
    assert(false);  
  }
 
   

  enum MatchStopReason {
    None,
    MaxMatches,
    Satisfied,
    PriceExhausted,
    BookExhausted
  }
 
   
   
   
   
   
   
   
   
   
   
   
  function matchAgainstBook(
      uint128 orderId, uint theirPriceStart, uint theirPriceEnd, uint maxMatches
    ) internal returns (
      MatchStopReason matchStopReason
    ) {
    Order storage order = orderForOrderId[orderId];
    
    uint bmi = theirPriceStart / 256;   
    uint bti = theirPriceStart % 256;   
    uint bmiEnd = theirPriceEnd / 256;  
    uint btiEnd = theirPriceEnd % 256;  

    uint cbm = occupiedPriceBitmaps[bmi];  
    uint dbm = cbm;  
    uint wbm = cbm >> bti;  
    
     
     

    bool removedLastAtPrice;
    matchStopReason = MatchStopReason.None;

    while (bmi < bmiEnd) {
      if (wbm == 0 || bti == 256) {
        if (dbm != cbm) {
          occupiedPriceBitmaps[bmi] = dbm;
        }
        bti = 0;
        bmi++;
        cbm = occupiedPriceBitmaps[bmi];
        wbm = cbm;
        dbm = cbm;
      } else {
        if ((wbm & 1) != 0) {
           
          (removedLastAtPrice, maxMatches, matchStopReason) =
            matchWithOccupiedPrice(order, uint16(bmi * 256 + bti), maxMatches);
          if (removedLastAtPrice) {
            dbm ^= 2 ** bti;
          }
          if (matchStopReason == MatchStopReason.PriceExhausted) {
            matchStopReason = MatchStopReason.None;
          } else if (matchStopReason != MatchStopReason.None) {
             
            break;
          }
        }
        bti += 1;
        wbm /= 2;
      }
    }
    if (matchStopReason == MatchStopReason.None) {
       
       
      while (bti <= btiEnd && wbm != 0) {
        if ((wbm & 1) != 0) {
           
          (removedLastAtPrice, maxMatches, matchStopReason) =
            matchWithOccupiedPrice(order, uint16(bmi * 256 + bti), maxMatches);
          if (removedLastAtPrice) {
            dbm ^= 2 ** bti;
          }
          if (matchStopReason == MatchStopReason.PriceExhausted) {
            matchStopReason = MatchStopReason.None;
          } else if (matchStopReason != MatchStopReason.None) {
            break;
          }
        }
        bti += 1;
        wbm /= 2;
      }
    }
     
     
     
    if (dbm != cbm) {
      occupiedPriceBitmaps[bmi] = dbm;
    }
    if (matchStopReason == MatchStopReason.None) {
      matchStopReason = MatchStopReason.BookExhausted;
    }
  }

   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
  function matchWithOccupiedPrice(
      Order storage ourOrder, uint16 theirPrice, uint maxMatches
    ) internal returns (
    bool removedLastAtPrice, uint matchesLeft, MatchStopReason matchStopReason) {
    matchesLeft = maxMatches;
    uint workingOurExecutedBase = ourOrder.executedBase;
    uint workingOurExecutedCntr = ourOrder.executedCntr;
    uint128 theirOrderId = orderChainForOccupiedPrice[theirPrice].firstOrderId;
    matchStopReason = MatchStopReason.None;
    while (true) {
      if (matchesLeft == 0) {
        matchStopReason = MatchStopReason.MaxMatches;
        break;
      }
      uint matchBase;
      uint matchCntr;
      (theirOrderId, matchBase, matchCntr, matchStopReason) =
        matchWithTheirs((ourOrder.sizeBase - workingOurExecutedBase), theirOrderId, theirPrice);
      workingOurExecutedBase += matchBase;
      workingOurExecutedCntr += matchCntr;
      matchesLeft -= 1;
      if (matchStopReason != MatchStopReason.None) {
        break;
      }
    }
    ourOrder.executedBase = uint128(workingOurExecutedBase);
    ourOrder.executedCntr = uint128(workingOurExecutedCntr);
    if (theirOrderId == 0) {
      orderChainForOccupiedPrice[theirPrice].firstOrderId = 0;
      orderChainForOccupiedPrice[theirPrice].lastOrderId = 0;
      removedLastAtPrice = true;
    } else {
       
      orderChainForOccupiedPrice[theirPrice].firstOrderId = theirOrderId;
      orderChainNodeForOpenOrderId[theirOrderId].prevOrderId = 0;
      removedLastAtPrice = false;
    }
  }
  
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
  function matchWithTheirs(
    uint ourRemainingBase, uint128 theirOrderId, uint16 theirPrice) internal returns (
    uint128 nextTheirOrderId, uint matchBase, uint matchCntr, MatchStopReason matchStopReason) {
    Order storage theirOrder = orderForOrderId[theirOrderId];
    uint theirRemainingBase = theirOrder.sizeBase - theirOrder.executedBase;
    if (ourRemainingBase < theirRemainingBase) {
      matchBase = ourRemainingBase;
    } else {
      matchBase = theirRemainingBase;
    }
    matchCntr = computeCntrAmountUsingPacked(matchBase, theirPrice);
     
     
     
     
    if ((ourRemainingBase - matchBase) < baseMinRemainingSize) {
      matchStopReason = MatchStopReason.Satisfied;
    } else {
      matchStopReason = MatchStopReason.None;
    }
    bool theirsDead = recordTheirMatch(theirOrder, theirOrderId, theirPrice, matchBase, matchCntr);
    if (theirsDead) {
      nextTheirOrderId = orderChainNodeForOpenOrderId[theirOrderId].nextOrderId;
      if (matchStopReason == MatchStopReason.None && nextTheirOrderId == 0) {
        matchStopReason = MatchStopReason.PriceExhausted;
      }
    } else {
      nextTheirOrderId = theirOrderId;
    }
  }

   
   
   
   
   
   
   
   
   
   
   
   
   
   
  function recordTheirMatch(
      Order storage theirOrder, uint128 theirOrderId, uint16 theirPrice, uint matchBase, uint matchCntr
    ) internal returns (bool theirsDead) {
     
     
     
    theirOrder.executedBase += uint128(matchBase);
    theirOrder.executedCntr += uint128(matchCntr);
    if (isBuyPrice(theirPrice)) {
       
      balanceBaseForClient[theirOrder.client] += matchBase;
    } else {
       
      balanceCntrForClient[theirOrder.client] += matchCntr;
    }
    uint stillRemainingBase = theirOrder.sizeBase - theirOrder.executedBase;
     
    if (stillRemainingBase < baseMinRemainingSize) {
      refundUnmatchedAndFinish(theirOrderId, Status.Done, ReasonCode.None);
       
      MarketOrderEvent(block.timestamp, theirOrderId, MarketOrderEventType.CompleteFill,
        theirPrice, matchBase + stillRemainingBase, matchBase);
      return true;
    } else {
      MarketOrderEvent(block.timestamp, theirOrderId, MarketOrderEventType.PartialFill,
        theirPrice, matchBase, matchBase);
      return false;
    }
  }

   
   
   
   
   
   
   
   
  function refundUnmatchedAndFinish(uint128 orderId, Status status, ReasonCode reasonCode) internal {
    Order storage order = orderForOrderId[orderId];
    uint16 price = order.price;
    if (isBuyPrice(price)) {
      uint sizeCntr = computeCntrAmountUsingPacked(order.sizeBase, price);
      balanceCntrForClient[order.client] += sizeCntr - order.executedCntr;
    } else {
      balanceBaseForClient[order.client] += order.sizeBase - order.executedBase;
    }
    order.status = status;
    order.reasonCode = reasonCode;
  }

   
   
   
   
   
   
   
   
   
  function enterOrder(uint128 orderId) internal {
    Order storage order = orderForOrderId[orderId];
    uint16 price = order.price;
    OrderChain storage orderChain = orderChainForOccupiedPrice[price];
    OrderChainNode storage orderChainNode = orderChainNodeForOpenOrderId[orderId];
    if (orderChain.firstOrderId == 0) {
      orderChain.firstOrderId = orderId;
      orderChain.lastOrderId = orderId;
      orderChainNode.nextOrderId = 0;
      orderChainNode.prevOrderId = 0;
      uint bitmapIndex = price / 256;
      uint bitIndex = price % 256;
      occupiedPriceBitmaps[bitmapIndex] |= (2 ** bitIndex);
    } else {
      uint128 existingLastOrderId = orderChain.lastOrderId;
      OrderChainNode storage existingLastOrderChainNode = orderChainNodeForOpenOrderId[existingLastOrderId];
      orderChainNode.nextOrderId = 0;
      orderChainNode.prevOrderId = existingLastOrderId;
      existingLastOrderChainNode.nextOrderId = orderId;
      orderChain.lastOrderId = orderId;
    }
    MarketOrderEvent(block.timestamp, orderId, MarketOrderEventType.Add,
      price, order.sizeBase - order.executedBase, 0);
    order.status = Status.Open;
  }

   
   
   
   
   
   
  function debitFunds(
      address client, Direction direction, uint sizeBase, uint sizeCntr
    ) internal returns (bool success) {
    if (direction == Direction.Buy) {
      uint availableCntr = balanceCntrForClient[client];
      if (availableCntr < sizeCntr) {
        return false;
      }
      balanceCntrForClient[client] = availableCntr - sizeCntr;
      return true;
    } else if (direction == Direction.Sell) {
      uint availableBase = balanceBaseForClient[client];
      if (availableBase < sizeBase) {
        return false;
      }
      balanceBaseForClient[client] = availableBase - sizeBase;
      return true;
    } else {
      return false;
    }
  }

   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
  function walkBook(uint16 fromPrice) public constant returns (
      uint16 price, uint depthBase, uint orderCount, uint blockNumber
    ) {
    uint priceStart = fromPrice;
    uint priceEnd = (isBuyPrice(fromPrice)) ? minBuyPrice : maxSellPrice;
    
     
    
    uint bmi = priceStart / 256;
    uint bti = priceStart % 256;
    uint bmiEnd = priceEnd / 256;
    uint btiEnd = priceEnd % 256;

    uint wbm = occupiedPriceBitmaps[bmi] >> bti;
    
    while (bmi < bmiEnd) {
      if (wbm == 0 || bti == 256) {
        bti = 0;
        bmi++;
        wbm = occupiedPriceBitmaps[bmi];
      } else {
        if ((wbm & 1) != 0) {
           
          price = uint16(bmi * 256 + bti);
          (depthBase, orderCount) = sumDepth(orderChainForOccupiedPrice[price].firstOrderId);
          return (price, depthBase, orderCount, block.number);
        }
        bti += 1;
        wbm /= 2;
      }
    }
     
    while (bti <= btiEnd && wbm != 0) {
      if ((wbm & 1) != 0) {
         
        price = uint16(bmi * 256 + bti);
        (depthBase, orderCount) = sumDepth(orderChainForOccupiedPrice[price].firstOrderId);
        return (price, depthBase, orderCount, block.number);
      }
      bti += 1;
      wbm /= 2;
    }
    return (uint16(priceEnd), 0, 0, block.number);
  }

   
   
   
   
   
  function sumDepth(uint128 orderId) internal constant returns (uint depth, uint orderCount) {
    while (true) {
      Order storage order = orderForOrderId[orderId];
      depth += order.sizeBase - order.executedBase;
      orderCount++;
      orderId = orderChainNodeForOpenOrderId[orderId].nextOrderId;
      if (orderId == 0) {
        return (depth, orderCount);
      }
    }
  }
}