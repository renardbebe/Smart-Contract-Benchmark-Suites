 

pragma solidity ^0.4.13;

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

contract ERC20Basic {
  uint256 public totalSupply;
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

library ArrayUtils {

     
    function guardedArrayReplace(bytes memory array, bytes memory desired, bytes memory mask)
        pure
        internal
    {
        byte[8] memory bitmasks = [byte(2 ** 7), byte(2 ** 6), byte(2 ** 5), byte(2 ** 4), byte(2 ** 3), byte(2 ** 2), byte(2 ** 1), byte(2 ** 0)];
        require(array.length == desired.length);
        require(mask.length >= array.length / 8);
        for (uint i = 0; i < array.length; i++ ) {
             
            bool masked = (mask[i / 8] & bitmasks[i % 8]) == 0;
            if (!masked) {
                array[i] = desired[i];
            }
        }
    }

     
    function arrayEq(bytes memory a, bytes memory b)
        pure
        internal
        returns (bool)
    {
        if (a.length != b.length) {
            return false;
        }
        for (uint i = 0; i < a.length; i++) {
            if (a[i] != b[i]) {
                return false;
            }
        }
        return true;
    }

}

contract ReentrancyGuarded {

    bool reentrancyLock = false;

     
    modifier reentrancyGuard {
        if (reentrancyLock) {
            revert();
        }
        reentrancyLock = true;
        _;
        reentrancyLock = false;
    }

}

contract TokenRecipient {
    event ReceivedEther(address indexed sender, uint amount);
    event ReceivedTokens(address indexed from, uint256 value, address indexed token, bytes extraData);

     
    function receiveApproval(address from, uint256 value, address token, bytes extraData) public {
        ERC20 t = ERC20(token);
        require(t.transferFrom(from, this, value));
        ReceivedTokens(from, value, token, extraData);
    }

     
    function () payable public {
        ReceivedEther(msg.sender, msg.value);
    }
}

contract ExchangeCore is ReentrancyGuarded {

     
    ERC20 public exchangeToken;

     
    ProxyRegistry public registry;

     
    mapping(bytes32 => bool) public cancelledOrFinalized;

     
    mapping(bytes32 => bool) public approvedOrders;

      
    struct Sig {
         
        uint8 v;
         
        bytes32 r;
         
        bytes32 s;
    }

     
    struct Order {
         
        address exchange;
         
        address maker;
         
        address taker;
         
        uint makerFee;
         
        uint takerFee;
         
        address feeRecipient;
         
        SaleKindInterface.Side side;
         
        SaleKindInterface.SaleKind saleKind;
         
        address target;
         
        AuthenticatedProxy.HowToCall howToCall;
         
        bytes calldata;
         
        bytes replacementPattern;
         
        address staticTarget;
         
        bytes staticExtradata;
         
        ERC20 paymentToken;
         
        uint basePrice;
         
        uint extra;
         
        uint listingTime;
         
        uint expirationTime;
         
        uint salt;
    }
    
    event OrderApprovedPartOne    (bytes32 indexed hash, address exchange, address indexed maker, address taker, uint makerFee, uint takerFee, address indexed feeRecipient, SaleKindInterface.Side side, SaleKindInterface.SaleKind saleKind, address target, AuthenticatedProxy.HowToCall howToCall, bytes calldata);
    event OrderApprovedPartTwo    (bytes32 indexed hash, bytes replacementPattern, address staticTarget, bytes staticExtradata, ERC20 paymentToken, uint basePrice, uint extra, uint listingTime, uint expirationTime, uint salt, bool orderbookInclusionDesired);
    event OrderCancelled          (bytes32 indexed hash);
    event OrdersMatched           (bytes32 buyHash, bytes32 sellHash, address indexed maker, address indexed taker, uint price, bytes32 indexed metadata);

     
    function chargeFee(address from, address to, uint amount)
        internal
    {
        if (amount > 0) {
            require(exchangeToken.transferFrom(from, to, amount));
        }
    }

     
    function staticCall(address target, bytes memory calldata, bytes memory extradata)
        public
        view
        returns (bool result)
    {
        bytes memory combined = new bytes(SafeMath.add(calldata.length, extradata.length));
        for (uint i = 0; i < extradata.length; i++) {
            combined[i] = extradata[i];
        }
        for (uint j = 0; j < calldata.length; j++) {
            combined[j + extradata.length] = calldata[j];
        }
        assembly {
            result := staticcall(gas, target, add(combined, 0x20), mload(combined), mload(0x40), 0)
        }
        return result;
    }

     
    function hashOrderPartOne(Order memory order)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(order.exchange, order.maker, order.taker, order.makerFee, order.takerFee, order.feeRecipient, order.side, order.saleKind, order.target, order.howToCall, order.calldata, order.replacementPattern);
    }

     
    function hashOrderPartTwo(Order memory order)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(order.staticTarget, order.staticExtradata, order.paymentToken, order.basePrice, order.extra, order.listingTime, order.expirationTime, order.salt);
    }

     
    function hashToSign(Order memory order)
        internal
        pure
        returns (bytes32)
    {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 hash = keccak256(prefix, hashOrderPartOne(order), hashOrderPartTwo(order));
        return hash;
    }

     
    function requireValidOrder(Order memory order, Sig memory sig)
        internal
        view
        returns (bytes32)
    {
        bytes32 hash = hashToSign(order);
        require(validateOrder(hash, order, sig));
        return hash;
    }

     
    function validateOrder(bytes32 hash, Order memory order, Sig memory sig) 
        internal
        view
        returns (bool)
    {
         

         
        if (order.exchange != address(this)) {
            return false;
        }

         
        if (cancelledOrFinalized[hash]) {
            return false;
        }
        
         
        if (!SaleKindInterface.validateParameters(order.saleKind, order.expirationTime)) {
            return false;
        }

         
        if (msg.sender == order.maker) {
            return true;
        }
  
         
        if (approvedOrders[hash]) {
            return true;
        }

         
        if (ecrecover(hash, sig.v, sig.r, sig.s) == order.maker) {
            return true;
        }

        return false;
    }

     
    function approveOrder(Order memory order, bool orderbookInclusionDesired)
        internal
    {
         

         
        require(msg.sender == order.maker);

         
        bytes32 hash = hashToSign(order);

         
        require(!approvedOrders[hash]);

         
    
         
        approvedOrders[hash] = true;
  
         
        {
            OrderApprovedPartOne(hash, order.exchange, order.maker, order.taker, order.makerFee, order.takerFee, order.feeRecipient, order.side, order.saleKind, order.target, order.howToCall, order.calldata);
        }
        {   
            OrderApprovedPartTwo(hash, order.replacementPattern, order.staticTarget, order.staticExtradata, order.paymentToken, order.basePrice, order.extra, order.listingTime, order.expirationTime, order.salt, orderbookInclusionDesired);
        }
    }

     
    function cancelOrder(Order memory order, Sig memory sig) 
        internal
    {
         

         
        bytes32 hash = requireValidOrder(order, sig);

         
        require(msg.sender == order.maker);
  
         
      
         
        cancelledOrFinalized[hash] = true;

         
        OrderCancelled(hash);
    }

     
    function calculateCurrentPrice (Order memory order)
        internal  
        view
        returns (uint)
    {
        return SaleKindInterface.calculateFinalPrice(order.side, order.saleKind, order.basePrice, order.extra, order.listingTime, order.expirationTime);
    }

     
    function calculateMatchPrice(Order memory buy, Order memory sell)
        view
        internal
        returns (uint)
    {
         
        uint sellPrice = SaleKindInterface.calculateFinalPrice(sell.side, sell.saleKind, sell.basePrice, sell.extra, sell.listingTime, sell.expirationTime);

         
        uint buyPrice = SaleKindInterface.calculateFinalPrice(buy.side, buy.saleKind, buy.basePrice, buy.extra, buy.listingTime, buy.expirationTime);

         
        require(buyPrice >= sellPrice);
        
         
        return sell.feeRecipient != address(0) ? sellPrice : buyPrice;
    }

     
    function executeFundsTransfer(Order memory buy, Order memory sell)
        internal
        returns (uint)
    {
         
        uint price = calculateMatchPrice(buy, sell);

         
        if (sell.feeRecipient != address(0)) {
             
      
             
            require(sell.takerFee <= buy.takerFee);
            
             
            chargeFee(sell.maker, sell.feeRecipient, sell.makerFee);

             
            chargeFee(buy.maker, sell.feeRecipient, sell.takerFee);
        } else {
             

             
            require(buy.takerFee <= sell.takerFee);

             
            chargeFee(buy.maker, buy.feeRecipient, buy.makerFee);
      
             
            chargeFee(sell.maker, buy.feeRecipient, buy.takerFee);
        }

        if (price > 0) {
             
            require(sell.paymentToken.transferFrom(buy.maker, sell.maker, price));
        }

        return price;
    }

     
    function ordersCanMatch(Order memory buy, Order memory sell)
        internal
        view
        returns (bool)
    {
        return (
             
            (buy.side == SaleKindInterface.Side.Buy && sell.side == SaleKindInterface.Side.Sell) &&     
             
            (buy.paymentToken == sell.paymentToken) &&
             
            (sell.taker == address(0) || sell.taker == buy.maker) &&
            (buy.taker == address(0) || buy.taker == sell.maker) &&
             
            ((sell.feeRecipient == address(0) && buy.feeRecipient != address(0)) || (sell.feeRecipient != address(0) && buy.feeRecipient == address(0))) &&
             
            (buy.target == sell.target) &&
             
            (buy.howToCall == sell.howToCall) &&
             
            SaleKindInterface.canSettleOrder(buy.listingTime, buy.expirationTime) &&
             
            SaleKindInterface.canSettleOrder(sell.listingTime, sell.expirationTime)
        );
    }

     
    function atomicMatch(Order memory buy, Sig memory buySig, Order memory sell, Sig memory sellSig, bytes32 metadata)
        internal
        reentrancyGuard
    {
         
      
         
        bytes32 buyHash = requireValidOrder(buy, buySig);

         
        bytes32 sellHash = requireValidOrder(sell, sellSig); 
        
         
        require(ordersCanMatch(buy, sell));

         
        uint size;
        address target = sell.target;
        assembly {
            size := extcodesize(target)
        }
        require(size > 0);
      
          
        if (buy.replacementPattern.length > 0) {
          ArrayUtils.guardedArrayReplace(buy.calldata, sell.calldata, buy.replacementPattern);
        }
        if (sell.replacementPattern.length > 0) {
          ArrayUtils.guardedArrayReplace(sell.calldata, buy.calldata, sell.replacementPattern);
        }
        require(ArrayUtils.arrayEq(buy.calldata, sell.calldata));

         
        AuthenticatedProxy proxy = registry.proxies(sell.maker);

         
        require(proxy != address(0));

         

         
        cancelledOrFinalized[buyHash] = true;
        cancelledOrFinalized[sellHash] = true;

         

         
        uint price = executeFundsTransfer(buy, sell);

         
        require(proxy.proxy(sell.target, sell.howToCall, sell.calldata));

         

         
        if (buy.staticTarget != address(0)) {
            require(staticCall(buy.staticTarget, sell.calldata, buy.staticExtradata));
        }

         
        if (sell.staticTarget != address(0)) {
            require(staticCall(sell.staticTarget, sell.calldata, sell.staticExtradata));
        }

         
        OrdersMatched(buyHash, sellHash, sell.feeRecipient != address(0) ? sell.maker : buy.maker, sell.feeRecipient != address(0) ? buy.maker : sell.maker, price, metadata);
    }

}

contract Exchange is ExchangeCore {

     
    function guardedArrayReplace(bytes array, bytes desired, bytes mask)
        public
        pure
        returns (bytes)
    {
        ArrayUtils.guardedArrayReplace(array, desired, mask);
        return array;
    }

     
    function calculateFinalPrice(SaleKindInterface.Side side, SaleKindInterface.SaleKind saleKind, uint basePrice, uint extra, uint listingTime, uint expirationTime)
        public
        view
        returns (uint)
    {
        return SaleKindInterface.calculateFinalPrice(side, saleKind, basePrice, extra, listingTime, expirationTime);
    }

     
    function hashOrder_(
        address[7] addrs,
        uint[7] uints,
        SaleKindInterface.Side side,
        SaleKindInterface.SaleKind saleKind,
        AuthenticatedProxy.HowToCall howToCall,
        bytes calldata,
        bytes replacementPattern,
        bytes staticExtradata)
        public
        pure
        returns (bytes32)
    { 
        return hashToSign(
          Order(addrs[0], addrs[1], addrs[2], uints[0], uints[1], addrs[3], side, saleKind, addrs[4], howToCall, calldata, replacementPattern, addrs[5], staticExtradata, ERC20(addrs[6]), uints[2], uints[3], uints[4], uints[5], uints[6])
        );
    }

     
    function validateOrder_ (
        address[7] addrs,
        uint[7] uints,
        SaleKindInterface.Side side,
        SaleKindInterface.SaleKind saleKind,
        AuthenticatedProxy.HowToCall howToCall,
        bytes calldata,
        bytes replacementPattern,
        bytes staticExtradata,
        uint8 v,
        bytes32 r,
        bytes32 s)
        view
        public
        returns (bool)
    {
        Order memory order = Order(addrs[0], addrs[1], addrs[2], uints[0], uints[1], addrs[3], side, saleKind, addrs[4], howToCall, calldata, replacementPattern, addrs[5], staticExtradata, ERC20(addrs[6]), uints[2], uints[3], uints[4], uints[5], uints[6]);
        return validateOrder(
          hashToSign(order),
          order,
          Sig(v, r, s)
        );
    }

     
    function approveOrder_ (
        address[7] addrs,
        uint[7] uints,
        SaleKindInterface.Side side,
        SaleKindInterface.SaleKind saleKind,
        AuthenticatedProxy.HowToCall howToCall,
        bytes calldata,
        bytes replacementPattern,
        bytes staticExtradata,
        bool orderbookInclusionDesired) 
        public
    {
        Order memory order = Order(addrs[0], addrs[1], addrs[2], uints[0], uints[1], addrs[3], side, saleKind, addrs[4], howToCall, calldata, replacementPattern, addrs[5], staticExtradata, ERC20(addrs[6]), uints[2], uints[3], uints[4], uints[5], uints[6]);
        return approveOrder(order, orderbookInclusionDesired);
    }

     
    function cancelOrder_(
        address[7] addrs,
        uint[7] uints,
        SaleKindInterface.Side side,
        SaleKindInterface.SaleKind saleKind,
        AuthenticatedProxy.HowToCall howToCall,
        bytes calldata,
        bytes replacementPattern,
        bytes staticExtradata,
        uint8 v,
        bytes32 r,
        bytes32 s)
        public
    {

        return cancelOrder(
          Order(addrs[0], addrs[1], addrs[2], uints[0], uints[1], addrs[3], side, saleKind, addrs[4], howToCall, calldata, replacementPattern, addrs[5], staticExtradata, ERC20(addrs[6]), uints[2], uints[3], uints[4], uints[5], uints[6]),
          Sig(v, r, s)
        );
    }

     
    function calculateCurrentPrice_(
        address[7] addrs,
        uint[7] uints,
        SaleKindInterface.Side side,
        SaleKindInterface.SaleKind saleKind,
        AuthenticatedProxy.HowToCall howToCall,
        bytes calldata,
        bytes replacementPattern,
        bytes staticExtradata)
        public
        view
        returns (uint)
    {
        return calculateCurrentPrice(
          Order(addrs[0], addrs[1], addrs[2], uints[0], uints[1], addrs[3], side, saleKind, addrs[4], howToCall, calldata, replacementPattern, addrs[5], staticExtradata, ERC20(addrs[6]), uints[2], uints[3], uints[4], uints[5], uints[6])
        );
    }

     
    function ordersCanMatch_(
        address[14] addrs,
        uint[14] uints,
        uint8[6] sidesKindsHowToCalls,
        bytes calldataBuy,
        bytes calldataSell,
        bytes replacementPatternBuy,
        bytes replacementPatternSell,
        bytes staticExtradataBuy,
        bytes staticExtradataSell)
        public
        view
        returns (bool)
    {
        Order memory buy = Order(addrs[0], addrs[1], addrs[2], uints[0], uints[1], addrs[3], SaleKindInterface.Side(sidesKindsHowToCalls[0]), SaleKindInterface.SaleKind(sidesKindsHowToCalls[1]), addrs[4], AuthenticatedProxy.HowToCall(sidesKindsHowToCalls[2]), calldataBuy, replacementPatternBuy, addrs[5], staticExtradataBuy, ERC20(addrs[6]), uints[2], uints[3], uints[4], uints[5], uints[6]);
        Order memory sell = Order(addrs[7], addrs[8], addrs[9], uints[7], uints[8], addrs[10], SaleKindInterface.Side(sidesKindsHowToCalls[3]), SaleKindInterface.SaleKind(sidesKindsHowToCalls[4]), addrs[11], AuthenticatedProxy.HowToCall(sidesKindsHowToCalls[5]), calldataSell, replacementPatternSell, addrs[12], staticExtradataSell, ERC20(addrs[13]), uints[9], uints[10], uints[11], uints[12], uints[13]);
        return ordersCanMatch(
          buy,
          sell
        );
    }

     
    function orderCalldataCanMatch(bytes buyCalldata, bytes buyReplacementPattern, bytes sellCalldata, bytes sellReplacementPattern)
        public
        pure
        returns (bool)
    {
        ArrayUtils.guardedArrayReplace(buyCalldata, sellCalldata, buyReplacementPattern);
        ArrayUtils.guardedArrayReplace(sellCalldata, buyCalldata, sellReplacementPattern);
        return ArrayUtils.arrayEq(buyCalldata, sellCalldata);
    }

     
    function calculateMatchPrice_(
        address[14] addrs,
        uint[14] uints,
        uint8[6] sidesKindsHowToCalls,
        bytes calldataBuy,
        bytes calldataSell,
        bytes replacementPatternBuy,
        bytes replacementPatternSell,
        bytes staticExtradataBuy,
        bytes staticExtradataSell)
        public
        view
        returns (uint)
    {
        Order memory buy = Order(addrs[0], addrs[1], addrs[2], uints[0], uints[1], addrs[3], SaleKindInterface.Side(sidesKindsHowToCalls[0]), SaleKindInterface.SaleKind(sidesKindsHowToCalls[1]), addrs[4], AuthenticatedProxy.HowToCall(sidesKindsHowToCalls[2]), calldataBuy, replacementPatternBuy, addrs[5], staticExtradataBuy, ERC20(addrs[6]), uints[2], uints[3], uints[4], uints[5], uints[6]);
        Order memory sell = Order(addrs[7], addrs[8], addrs[9], uints[7], uints[8], addrs[10], SaleKindInterface.Side(sidesKindsHowToCalls[3]), SaleKindInterface.SaleKind(sidesKindsHowToCalls[4]), addrs[11], AuthenticatedProxy.HowToCall(sidesKindsHowToCalls[5]), calldataSell, replacementPatternSell, addrs[12], staticExtradataSell, ERC20(addrs[13]), uints[9], uints[10], uints[11], uints[12], uints[13]);
        return calculateMatchPrice(
          buy,
          sell
        );
    }

     
    function atomicMatch_(
        address[14] addrs,
        uint[14] uints,
        uint8[6] sidesKindsHowToCalls,
        bytes calldataBuy,
        bytes calldataSell,
        bytes replacementPatternBuy,
        bytes replacementPatternSell,
        bytes staticExtradataBuy,
        bytes staticExtradataSell,
        uint8[2] vs,
        bytes32[5] rssMetadata)
        public
    {
        return atomicMatch(
          Order(addrs[0], addrs[1], addrs[2], uints[0], uints[1], addrs[3], SaleKindInterface.Side(sidesKindsHowToCalls[0]), SaleKindInterface.SaleKind(sidesKindsHowToCalls[1]), addrs[4], AuthenticatedProxy.HowToCall(sidesKindsHowToCalls[2]), calldataBuy, replacementPatternBuy, addrs[5], staticExtradataBuy, ERC20(addrs[6]), uints[2], uints[3], uints[4], uints[5], uints[6]),
          Sig(vs[0], rssMetadata[0], rssMetadata[1]),
          Order(addrs[7], addrs[8], addrs[9], uints[7], uints[8], addrs[10], SaleKindInterface.Side(sidesKindsHowToCalls[3]), SaleKindInterface.SaleKind(sidesKindsHowToCalls[4]), addrs[11], AuthenticatedProxy.HowToCall(sidesKindsHowToCalls[5]), calldataSell, replacementPatternSell, addrs[12], staticExtradataSell, ERC20(addrs[13]), uints[9], uints[10], uints[11], uints[12], uints[13]),
          Sig(vs[1], rssMetadata[2], rssMetadata[3]),
          rssMetadata[4]
        );
    }

}

contract WyvernExchange is Exchange {

    string public constant name = "Project Wyvern Exchange";

     
    function WyvernExchange (ProxyRegistry registryAddress, ERC20 tokenAddress) public {
        exchangeToken = tokenAddress;
        registry = registryAddress;
    }

}

library SaleKindInterface {

     
    enum Side { Buy, Sell }

     
    enum SaleKind { FixedPrice, DutchAuction }

     
    function validateParameters(SaleKind saleKind, uint expirationTime)
        pure
        internal
        returns (bool)
    {
         
        return (saleKind == SaleKind.FixedPrice || expirationTime > 0);
    }

     
    function canSettleOrder(uint listingTime, uint expirationTime)
        view
        internal
        returns (bool)
    {
        return (listingTime < now) && (expirationTime == 0 || now < expirationTime);
    }

     
    function calculateFinalPrice(Side side, SaleKind saleKind, uint basePrice, uint extra, uint listingTime, uint expirationTime)
        view
        internal
        returns (uint finalPrice)
    {
        if (saleKind == SaleKind.FixedPrice) {
            return basePrice;
        } else if (saleKind == SaleKind.DutchAuction) {
            uint diff = SafeMath.div(SafeMath.mul(extra, SafeMath.sub(now, listingTime)), SafeMath.sub(expirationTime, listingTime));
            if (side == Side.Sell) {
                 
                return SafeMath.sub(basePrice, diff);
            } else {
                 
                return SafeMath.add(basePrice, diff);
            }
        }
    }

}

contract AuthenticatedProxy is TokenRecipient {

     
    address public user;

     
    ProxyRegistry public registry;

     
    bool public revoked;

     
    enum HowToCall { Call, DelegateCall }

     
    event Revoked(bool revoked);

     
    function AuthenticatedProxy(address addrUser, ProxyRegistry addrRegistry) public {
        user = addrUser;
        registry = addrRegistry;
    }

     
    function setRevoke(bool revoke)
        public
    {
        require(msg.sender == user);
        revoked = revoke;
        Revoked(revoke);
    }

     
    function proxy(address dest, HowToCall howToCall, bytes calldata)
        public
        returns (bool result)
    {
        require(msg.sender == user || (!revoked && registry.contracts(msg.sender)));
        if (howToCall == HowToCall.Call) {
            result = dest.call(calldata);
        } else if (howToCall == HowToCall.DelegateCall) {
            result = dest.delegatecall(calldata);
        }
        return result;
    }

     
    function proxyAssert(address dest, HowToCall howToCall, bytes calldata)
        public
    {
        require(proxy(dest, howToCall, calldata));
    }

}

contract ProxyRegistry is Ownable {

     
    mapping(address => AuthenticatedProxy) public proxies;

     
    mapping(address => uint) public pending;

     
    mapping(address => bool) public contracts;

     
    uint public DELAY_PERIOD = 2 weeks;

     
    function startGrantAuthentication (address addr)
        public
        onlyOwner
    {
        require(!contracts[addr] && pending[addr] == 0);
        pending[addr] = now;
    }

     
    function endGrantAuthentication (address addr)
        public
        onlyOwner
    {
        require(!contracts[addr] && pending[addr] != 0 && ((pending[addr] + DELAY_PERIOD) < now));
        pending[addr] = 0;
        contracts[addr] = true;
    }

         
    function revokeAuthentication (address addr)
        public
        onlyOwner
    {
        contracts[addr] = false;
    }

     
    function registerProxy()
        public
        returns (AuthenticatedProxy proxy)
    {
        require(proxies[msg.sender] == address(0));
        proxy = new AuthenticatedProxy(msg.sender, this);
        proxies[msg.sender] = proxy;
        return proxy;
    }

}