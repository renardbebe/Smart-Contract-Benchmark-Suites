 

 

pragma solidity 0.5.7;
pragma experimental ABIEncoderV2;

interface LoopringProtocol {
  function submitRings(bytes calldata data) external;
  function lrcTokenAddress() external returns (address);
  function delegateAddress() external returns (address);
}

interface ERC20 {
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);

  function totalSupply() external view returns (uint256);
  function decimals() external view returns (uint8);

  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);

  function transfer(address to, uint256 value) external;
  function transferFrom(address from, address to, uint256 value) external;
  function approve(address spender, uint256 value) external;
}

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) return 0;
    uint256 c = a * b;
    require(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0);
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;
    return c;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);
    return c;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

library Types {

  struct RelayerInfo {
    uint marginOrderIndex;
    uint marketIdS;
    uint marketIdB;
    uint fillAmountS;
    uint fillAmountB;
  }

  enum MarginOrderType { OPEN_LONG, OPEN_SHORT, CLOSE_LONG, CLOSE_SHORT }
  
  struct MarginOrderDetails {
    uint positionId;
    MarginOrderType positionType;
    uint depositAmount;
    uint depositMarketId;
    uint expiration;

     
    address owner;
    address depositToken;
    uint withdrawalMarketId;
    bool isOpen;
    bool isLong;
  }

  enum OrderDataSide { BUY, SELL }

  struct OrderData {
    OrderDataSide side;
    uint fillAmountS;
    uint fillAmountB;
    bytes ringData;
    uint marginOrderIndex;
    address trader;

     
    bool bringToZero;  
  }

  struct MarginLimitOrderDetails {
    uint positionId;
    uint marketIdS;
    uint marketIdB;
    uint depositMarketId;
    uint depositAmount;
    address broker;
    uint expiration;

     
    address depositToken;
    address trader;
  }
}

library DydxTypes {
  enum AssetDenomination { Wei, Par }
  enum AssetReference { Delta, Target }

  struct AssetAmount {
    bool sign;
    AssetDenomination denomination;
    AssetReference ref;
    uint256 value;
  }
}

library DydxPosition {
  struct Info {
    address owner;
    uint256 number;
  }
}

library DydxActions {
  enum ActionType { Deposit, Withdraw, Transfer, Buy, Sell,
    Trade, Liquidate, Vaporize, Call }

  struct ActionArgs {
    ActionType actionType;
    uint256 accountId;
    DydxTypes.AssetAmount amount;
    uint256 primaryMarketId;
    uint256 secondaryMarketId;
    address otherAddress;
    uint256 otherAccountId;
    bytes data;
  }
}

interface IDolomiteMarginTradingBroker {
  function brokerMarginRequestApproval(address owner, address token, uint amount) external;
  function brokerMarginGetTrader(address owner, bytes calldata orderData) external view returns (address);
}

 
 
contract DydxProtocol {
  struct OperatorArg {
    address operator;
    bool trusted;
  }

  function operate(
      DydxPosition.Info[] calldata accounts,
      DydxActions.ActionArgs[] calldata actions
  ) external;

  function getMarketTokenAddress(uint256 marketId) external view returns (address);
}

 
interface IDydxExchangeWrapper {
  function exchange(
    address tradeOriginator,
    address receiver,
    address makerToken,
    address takerToken,
    uint256 requestedFillAmount,
    bytes calldata orderData
  ) external returns (uint256);

  function getExchangeCost(
    address makerToken,
    address takerToken,
    uint256 desiredMakerToken,
    bytes calldata orderData
  ) external view returns (uint256);
}

library LoopringTypes {
  struct BrokerApprovalRequest {
    BrokerOrder[] orders;
    address tokenS;
    address tokenB;
    address feeToken;
    uint totalFillAmountB;
    uint totalRequestedAmountS;
    uint totalRequestedFeeAmount;
  }

  struct BrokerOrder {
    address owner;
    bytes32 orderHash;
    uint fillAmountB;
    uint requestedAmountS;
    uint requestedFeeAmount;
    address tokenRecipient;
    bytes extraData;
  }

  struct BrokerInterceptorReport {
    address owner;
    address broker;
    bytes32 orderHash;
    address tokenB;
    address tokenS;
    address feeToken;
    uint fillAmountB;
    uint spentAmountS;
    uint spentFeeAmount;
    address tokenRecipient;
    bytes extraData;
  }

  enum TokenType { ERC20 }

  struct Spendable {
    bool initialized;
    uint amount;
    uint reserved;
  }

  struct Order {
    uint      version;

     
    address   owner;
    address   tokenS;
    address   tokenB;
    uint      amountS;
    uint      amountB;
    uint      validSince;
    Spendable tokenSpendableS;
    Spendable tokenSpendableFee;

     
    address   dualAuthAddr;
    address   broker;
    Spendable brokerSpendableS;
    Spendable brokerSpendableFee;
    address   orderInterceptor;
    address   wallet;
    uint      validUntil;
    bytes     sig;
    bytes     dualAuthSig;
    bool      allOrNone;
    address   feeToken;
    uint      feeAmount;
    int16     waiveFeePercentage;
    uint16    tokenSFeePercentage;     
    uint16    tokenBFeePercentage;    
    address   tokenRecipient;
    uint16    walletSplitPercentage;

     
    bool    P2P;
    bytes32 hash;
    address brokerInterceptor;
    uint    filledAmountS;
    uint    initialFilledAmountS;
    bool    valid;

    TokenType tokenTypeS;
    TokenType tokenTypeB;
    TokenType tokenTypeFee;
    bytes32 trancheS;
    bytes32 trancheB;
    uint    maxPrimaryFillAmount;
    bool    transferFirstAsMaker;
    bytes   transferDataS;
  }
}

interface IBrokerDelegate {
  function brokerRequestAllowance(LoopringTypes.BrokerApprovalRequest calldata request) external returns (bool);
  function onOrderFillReport(LoopringTypes.BrokerInterceptorReport calldata fillReport) external;
  function brokerBalanceOf(address owner, address token) external view returns (uint);
}

library ERC20SafeTransfer {

    function safeTransfer(
        address token,
        address to,
        uint256 value)
        internal
        returns (bool success)
    {
         
         
         

         
        bytes memory callData = abi.encodeWithSelector(
            bytes4(0xa9059cbb),
            to,
            value
        );
        (success, ) = token.call(callData);
        return checkReturnValue(success);
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value)
        internal
        returns (bool success)
    {
         
         
         

         
        bytes memory callData = abi.encodeWithSelector(
            bytes4(0x23b872dd),
            from,
            to,
            value
        );
        (success, ) = token.call(callData);
        return checkReturnValue(success);
    }

    function checkReturnValue(
        bool success
        )
        internal
        pure
        returns (bool)
    {
         
         
         
        if (success) {
            assembly {
                switch returndatasize()
                 
                case 0 {
                    success := 1
                }
                 
                case 32 {
                    returndatacopy(0, 0, 32)
                    success := mload(0)
                }
                 
                default {
                    success := 0
                }
            }
        }
        return success;
    }

}

library LoopringBytesUtil {
    function bytesToBytes32(
        bytes memory b,
        uint offset
        )
        internal
        pure
        returns (bytes32)
    {
        return bytes32(bytesToUintX(b, offset, 32));
    }

    function bytesToUint(
        bytes memory b,
        uint offset
        )
        internal
        pure
        returns (uint)
    {
        return bytesToUintX(b, offset, 32);
    }

    function bytesToAddress(
        bytes memory b,
        uint offset
        )
        internal
        pure
        returns (address)
    {
        return address(bytesToUintX(b, offset, 20) & 0x00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
    }

    function bytesToUint16(
        bytes memory b,
        uint offset
        )
        internal
        pure
        returns (uint16)
    {
        return uint16(bytesToUintX(b, offset, 2) & 0xFFFF);
    }

    function bytesToUintX(
        bytes memory b,
        uint offset,
        uint numBytes
        )
        private
        pure
        returns (uint data)
    {
        require(b.length >= offset + numBytes, "INVALID_SIZE");
        assembly {
            data := mload(add(add(b, numBytes), offset))
        }
    }

    function subBytes(
        bytes memory b,
        uint offset
        )
        internal
        pure
        returns (bytes memory data)
    {
        require(b.length >= offset + 32, "INVALID_SIZE");
        assembly {
            data := add(add(b, 32), offset)
        }
    }
}

library DecodeHelper {
  using LoopringBytesUtil for bytes;

  function decodeRelayerInfo(bytes memory self) internal pure returns (Types.RelayerInfo memory relayerInfo) {
    (
      relayerInfo.marginOrderIndex,
      relayerInfo.marketIdS,
      relayerInfo.marketIdB,
      relayerInfo.fillAmountS,
      relayerInfo.fillAmountB
    ) = abi.decode(self, (uint, uint, uint, uint, uint));
  }

  function decodeMarginTradeDetails(bytes memory self, bytes4 requiredOrderSelector) 
    internal 
    pure 
    returns (Types.MarginOrderDetails memory details) 
  {
    uint typeRaw;
    bytes4 orderSelector;

    (
      orderSelector,
      details.positionId,
      typeRaw,
      details.depositAmount,
      details.depositMarketId,
      details.expiration
    ) = abi.decode(self, (bytes4, uint, uint, uint, uint, uint));

    require(orderSelector == requiredOrderSelector, "Margin order must have proper selector header in transferDataS");

    if (typeRaw == 0) details.positionType = Types.MarginOrderType.OPEN_LONG;
    else if (typeRaw == 1) details.positionType = Types.MarginOrderType.OPEN_SHORT;
    else if (typeRaw == 2) details.positionType = Types.MarginOrderType.CLOSE_LONG;
    else if (typeRaw == 3) details.positionType = Types.MarginOrderType.CLOSE_SHORT;
    else revert("Invalid margin order type");

    details.isOpen = typeRaw < 2;
    details.isLong = typeRaw == 0 || typeRaw == 2;
  }

  function decodeMarginLimitOrderDetails(bytes memory self)
    internal
    pure
    returns (Types.MarginLimitOrderDetails memory details)
  {
    (
      details.positionId,
      details.marketIdS,
      details.marketIdB,
      details.depositMarketId,
      details.depositAmount,
      details.broker,
      details.expiration   
    ) = abi.decode(self, (uint, uint, uint, uint, uint, address, uint));
  }

  function decodeOrderData(bytes memory self) internal pure returns (Types.OrderData memory orderData) {
    uint sideRaw;

    (
      sideRaw,
      orderData.fillAmountS,
      orderData.fillAmountB,
      orderData.ringData,
      orderData.marginOrderIndex,
      orderData.trader
    ) = abi.decode(self, (uint, uint, uint, bytes, uint, address));

    orderData.side = sideRaw == 0 ? Types.OrderDataSide.BUY : Types.OrderDataSide.SELL;
  }

   
  uint private constant ORDER_STRUCT_SIZE = 38 * 32;

  function decodeMinimalOrderAtIndex(
    bytes memory self, 
    uint orderIndex, 
    address lrcTokenAddress
  ) 
    internal 
    pure 
    returns (LoopringTypes.Order memory order) 
  {
    
     
    uint numOrders = self.bytesToUint16(2);
    uint numRings = self.bytesToUint16(4);

     
    uint dataPtr;
    assembly { dataPtr := self }
    uint tablesPtr = dataPtr + 8 + (3 * 2);
    uint data = (tablesPtr + (32 * numOrders) * 2) + (numRings * 9) + 32;
    
     
    bytes memory emptyBytes = new bytes(0);
    uint offset = orderIndex * ORDER_STRUCT_SIZE;  
    tablesPtr += 2;

    assembly {
      
       
      offset := mul(and(mload(add(tablesPtr,  2)), 0xFFFF), 4)
      mstore(
        add(order,  32),
        and(mload(add(add(data, 20), offset)), 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
      )

       
      offset := mul(and(mload(add(tablesPtr,  4)), 0xFFFF), 4)
      mstore(
        add(order,  64),
        and(mload(add(add(data, 20), offset)), 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
      )

       
      offset := mul(and(mload(add(tablesPtr,  6)), 0xFFFF), 4)
      mstore(
        add(order,  96),
        and(mload(add(add(data, 20), offset)), 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
      )

       
      offset := mul(and(mload(add(tablesPtr,  8)), 0xFFFF), 4)
      mstore(
        add(order, 128),
        mload(add(add(data, 32), offset))
      )

       
      offset := mul(and(mload(add(tablesPtr, 10)), 0xFFFF), 4)
      mstore(
        add(order, 160),
        mload(add(add(data, 32), offset))
      )

       
      offset := mul(and(mload(add(tablesPtr, 20)), 0xFFFF), 4)
      mstore(
          add(order, 320),
          and(mload(add(add(data, 20), offset)), 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
      )

       
      mstore(add(data, 20), lrcTokenAddress)

       
      offset := mul(and(mload(add(tablesPtr, 34)), 0xFFFF), 4)
      mstore(
          add(order, 608),
          and(mload(add(add(data, 20), offset)), 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
      )

       
      mstore(add(data, 20), 0)

       
      offset := mul(and(mload(add(tablesPtr, 36)), 0xFFFF), 4)
      mstore(
          add(order, 640),
          mload(add(add(data, 32), offset))
      )

       
      offset := and(mload(add(tablesPtr, 38)), 0xFFFF)
      mstore(
          add(order, 672),
          offset
      )

       
      mstore(add(data, 20), mload(add(order, 32)))  

       
      offset := mul(and(mload(add(tablesPtr, 44)), 0xFFFF), 4)
      mstore(
          add(order, 768),
          and(mload(add(add(data, 20), offset)), 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
      )

       
      mstore(add(data, 20), 0)

       
      mstore(add(data, 32), emptyBytes)

       
      offset := mul(and(mload(add(tablesPtr, 62)), 0xFFFF), 4)
      mstore(
          add(order, 1248),
          add(data, add(offset, 32))
      )
    }
  }
}

library MarginOrderHelper {
  using DecodeHelper for bytes;
  using SafeMath for uint;

  function getAmountB(LoopringTypes.Order memory self) internal pure returns (uint) {
    return calculateActualAmount(self, self.amountB, self.tokenB);
  }

  function getAmountS(LoopringTypes.Order memory self) internal pure returns (uint) {
    return calculateActualAmount(self, self.amountS, self.tokenS);
  }

   
  function calculateActualAmount(
    LoopringTypes.Order memory self, 
    uint fillAmount, 
    address token
  ) 
    internal 
    pure 
    returns (uint) 
  {
    uint feeMultiple = self.waiveFeePercentage < 0 ? 1000 : 1000 - uint(self.waiveFeePercentage);
    if (token == self.tokenS && token == self.feeToken) return fillAmount.add(self.feeAmount.mul(feeMultiple) / 1000);
    if (token == self.tokenB && token == self.feeToken) return fillAmount.sub(self.feeAmount.mul(feeMultiple) / 1000);
    return fillAmount;
  }

   
  function getMarginOrderDetails(LoopringTypes.Order memory self, bytes4 requiredOrderSelector) 
    internal 
    view 
    returns (Types.MarginOrderDetails memory details) 
  {
    details = self.transferDataS.decodeMarginTradeDetails(requiredOrderSelector);
    details.owner = self.owner;
    details.depositToken = self.tokenB;
  }

   
  string constant INVALID_MARKET_S = "marketIdS provided by relayer must have address equal to tokenS";
  string constant INVALID_MARKET_B = "marketIdB provided by relayer must have address equal to tokenB";
  string constant INVALID_DEPOSIT_MARKET = "depositMarketId must have an address equal to tokenB";
  string constant INVALID_TOKEN_RECIPIENT = "Invalid tokenRecipient - must be set correctly";

  function checkValidity(
    LoopringTypes.Order memory self, 
    Types.RelayerInfo memory relayerInfo,
    Types.MarginOrderDetails memory marginDetails,
    DydxProtocol dydxProtocol
  ) 
    internal
    view 
  {
     
    marginDetails.withdrawalMarketId = relayerInfo.marketIdS;

     
    address marketAddressS = dydxProtocol.getMarketTokenAddress(relayerInfo.marketIdS);
    require(self.tokenS == marketAddressS, INVALID_MARKET_S);

     
    address marketAddressB = dydxProtocol.getMarketTokenAddress(relayerInfo.marketIdB);
    require(self.tokenB == marketAddressB, INVALID_MARKET_B);

     
    if (marginDetails.isOpen) {
      require(marginDetails.depositMarketId == relayerInfo.marketIdB, INVALID_DEPOSIT_MARKET);
    }

     
    require(self.tokenRecipient == address(this), INVALID_TOKEN_RECIPIENT);
  }
}

library OrderDataHelper {

   
  function encodeWithRingData(Types.OrderData memory self, bytes memory ringData) 
    internal 
    returns (bytes memory) 
  {
    self.ringData = ringData;
    return abi.encode(
      uint(self.side), 
      self.fillAmountS, 
      self.fillAmountB, 
      self.ringData,
      self.marginOrderIndex,
      self.trader
    );
  }
}


contract TradeDelegate {
  function batchTransfer(bytes32[] calldata batch) external;
}

library MiscHelper {
  using MiscHelper for *;
  using ERC20SafeTransfer for address;

   
   

   
  function transferTokenFrom(
    TradeDelegate self, 
    address token,
    address from, 
    address to, 
    uint256 amount
  ) internal {
    bytes32[] memory transferData = new bytes32[](4);
    transferData[0] = token.toBytes32();
    transferData[1] = from.toBytes32();
    transferData[2] = to.toBytes32();
    transferData[3] = bytes32(amount);

    self.batchTransfer(transferData);
  }

   
   

  function safeTransfer(ERC20 self, address to, uint amount) internal {
    require(address(self).safeTransfer(to, amount), "Transfer failed");
  }

  function safeTransferFrom(ERC20 self, address from, address to, uint amount) internal {
    require(address(self).safeTransferFrom(from, to, amount), "TransferFrom failed");
  }

   
   

  function toPayable(address self) internal pure returns (address payable) {
    return address(uint160(self));
  }

  function toBytes32(address self) internal pure returns (bytes32) {
    return bytes32(uint256(self));
  }
}


contract Globals {
  using MiscHelper for *;

  string constant public ORDER_SIGNATURE = "dolomiteMarginOrder(version 1.0.0)";
  bytes4 constant public ORDER_SELECTOR = bytes4(keccak256(bytes(ORDER_SIGNATURE)));

  address internal LRC_TOKEN_ADDRESS;
  LoopringProtocol internal LOOPRING_PROTOCOL;
  TradeDelegate internal TRADE_DELEGATE;
  DydxProtocol internal DYDX_PROTOCOL;
  address internal DYDX_EXPIRATION_CONTRACT;

   
   
  mapping(bytes32 => bool) positionRegistered;

  constructor(
    address payable loopringRingSubmitterAddress, 
    address dydxProtocolAddress,
    address dydxExpirationContractAddress
  ) public {

    LOOPRING_PROTOCOL = LoopringProtocol(loopringRingSubmitterAddress);
    LRC_TOKEN_ADDRESS = LOOPRING_PROTOCOL.lrcTokenAddress();

    address payable tradeDelegateAddress = LOOPRING_PROTOCOL.delegateAddress().toPayable();
    TRADE_DELEGATE = TradeDelegate(tradeDelegateAddress);
    
    DYDX_PROTOCOL = DydxProtocol(dydxProtocolAddress);
    DYDX_EXPIRATION_CONTRACT = dydxExpirationContractAddress;
  }

  function registerPosition(address owner, uint positionId) internal {
    if (isPositionRegistered(owner, positionId)) return;
    bytes32 positionKey = keccak256(abi.encodePacked(owner, positionId));
    positionRegistered[positionKey] = true;
  }

  function isPositionRegistered(address owner, uint positionId) internal returns (bool) {
    bytes32 positionKey = keccak256(abi.encodePacked(owner, positionId));
    return positionRegistered[positionKey];
  }
}

 
contract LoopringV2ExchangeWrapper is IDydxExchangeWrapper, Globals {
  using MiscHelper for *;
  using DecodeHelper for bytes;
  using SafeMath for uint;

  address constant ZERO_ADDRESS = address(0x0);

  string constant INVALID_MSG_SENDER = "The msg.sender must be Dydx protocol";
  string constant INVALID_RECEIVER = "Bought token receiver must be Dydx protocol";
  string constant INVALID_TOKEN_RECIPIENT = "Invalid tokenRecipient in Loopring order";
  string constant INVALID_TRADE_ORIGINATOR = "Loopring order owner must be originator";
  string constant NOTHING_RECEIVED = "Amount received is zero. Ring submission most likely failed";

   
  function exchange(
    address tradeOriginator,
    address receiver,
    address makerToken,
    address takerToken,
    uint256 requestedFillAmount,
    bytes calldata orderData
  ) external returns (uint256) {
    require(msg.sender == address(DYDX_PROTOCOL), INVALID_MSG_SENDER);
    require(receiver == address(DYDX_PROTOCOL), INVALID_RECEIVER);

    Types.OrderData memory orderInfo = orderData.decodeOrderData();
    LoopringTypes.Order memory order = orderInfo.ringData.decodeMinimalOrderAtIndex(
      orderInfo.marginOrderIndex,
      ZERO_ADDRESS
    );

    require(order.tokenRecipient == address(this), INVALID_TOKEN_RECIPIENT);
    require(order.broker == address(0x0)
      ? tradeOriginator == order.owner
      : tradeOriginator == orderInfo.trader
    , INVALID_TRADE_ORIGINATOR);

     
    ERC20(takerToken).safeTransfer(orderInfo.trader, requestedFillAmount);

     
    uint balanceBeforeSubmission = ERC20(makerToken).balanceOf(address(this));

     
    LOOPRING_PROTOCOL.submitRings(orderInfo.ringData);

     
    uint amountReceived = ERC20(makerToken).balanceOf(address(this)).sub(balanceBeforeSubmission);
    require(amountReceived > 0, NOTHING_RECEIVED);
     
       

    return amountReceived;
  }

   
  function getExchangeCost(
    address makerToken,
    address takerToken,
    uint256 desiredMakerToken,
    bytes calldata orderData
  ) external view returns (uint256) {
    return orderData.decodeOrderData().fillAmountS;
  }


   

  function unexpectedReceivedError(uint expected, uint actual) private pure returns (string memory) {
    return string(abi.encodePacked(
      "Amount received (",
      uintToString(expected),
      ") must be exactly equal to expected amountB (",
      uintToString(actual),
      ") provided by either relayer or order"
    ));
  }

  function uintToString(uint num) private pure returns (string memory) {
    if (num == 0) {
      return "0";
    }
    uint j = num;
    uint len;
    while (j != 0) {
      len++;
      j /= 10;
    }
    bytes memory bstr = new bytes(len);
    uint k = len - 1;
    while (num != 0) {
      bstr[k--] = byte(uint8(48 + num % 10));
      num /= 10;
    }
    return string(bstr);
  }
}

 
contract MarginLimitBroker is Globals, IBrokerDelegate {
  using DecodeHelper for bytes;
  using SafeMath for uint;

  event FilledPosition(address indexed trader, uint indexed id, uint fillAmountB, uint fillAmountS, uint depositAmount);

  mapping(bytes32 => bool) public hasExecutedDeposit;

  function brokerRequestAllowance(LoopringTypes.BrokerApprovalRequest memory request) public returns (bool) {
    require(msg.sender == address(LOOPRING_PROTOCOL), "The msg.sender must be the Loopring protocol");

    DydxActions.ActionArgs[] memory actionsQueue = new DydxActions.ActionArgs[](request.orders.length * 3);
    DydxPosition.Info[] memory positionsQueue = new DydxPosition.Info[](request.orders.length);

    uint numActions;
    uint numPositions;

    for (uint i = 0; i < request.orders.length; i++) {
      (
        LoopringTypes.BrokerOrder memory order,
        Types.MarginLimitOrderDetails memory limitOrder
      ) = _marginLimitOrderAtIndex(request, i);

      uint positionIndex;
      uint totalDepositAmount = order.fillAmountB;
      uint depositedCollateralAmount = 0;

      (
        numPositions,
        positionIndex
      ) = _generatePositionIndex(positionsQueue, numPositions, limitOrder.trader, limitOrder.positionId);

       
      if (!hasExecutedDeposit[order.orderHash]) {
        hasExecutedDeposit[order.orderHash] = true;
        totalDepositAmount += limitOrder.depositAmount;
        depositedCollateralAmount = limitOrder.depositAmount;

        if (limitOrder.broker == address(0x0)) {
          TRADE_DELEGATE.transferTokenFrom(limitOrder.depositToken, order.owner, address(this), limitOrder.depositAmount);
        } else {
          IDolomiteMarginTradingBroker(limitOrder.broker)
            .brokerMarginRequestApproval(order.owner, limitOrder.depositToken, limitOrder.depositAmount);
          ERC20(limitOrder.depositToken).transferFrom(limitOrder.broker, address(this), limitOrder.depositAmount);
        }
      }

       
      actionsQueue[numActions] = _constructDydxTokenAction({
        positionIndex: positionIndex,
        isDeposit: true,
        amount: totalDepositAmount,
        marketId: limitOrder.marketIdB,
        targetAddress: address(this)
      });

       
      actionsQueue[numActions + 1] = _constructDydxTokenAction({
        positionIndex: positionIndex,
        isDeposit: false,
        amount: order.requestedAmountS,
        marketId: limitOrder.marketIdS,
        targetAddress: address(this)
      });

      numActions += 2;

       
      if (limitOrder.expiration > 0 && !isPositionRegistered(limitOrder.trader, limitOrder.positionId)) {
        actionsQueue[numActions] = _constructDydxExpirationAction(
          positionIndex, 
          limitOrder.marketIdS, 
          limitOrder.expiration
        );

        numActions++;
      }

      registerPosition(limitOrder.trader, limitOrder.positionId);
      emit FilledPosition(limitOrder.trader, limitOrder.positionId, order.fillAmountB, order.requestedAmountS, depositedCollateralAmount);
    }

     
    DydxActions.ActionArgs[] memory actions = new DydxActions.ActionArgs[](numActions);
    DydxPosition.Info[] memory positions = new DydxPosition.Info[](numPositions);

    for (uint b = 0; b < numActions; b++) {
      actions[b] = actionsQueue[b];
      if (b < numPositions) positions[b] = positionsQueue[b];
    }

    DYDX_PROTOCOL.operate(positions, actions);

     
    return false; 
  }

  function onOrderFillReport(LoopringTypes.BrokerInterceptorReport memory fillReport) public {
     
  }

  function brokerBalanceOf(address owner, address tokenAddress) public view returns (uint) {
    return 10**70;  
  }

   
   

  function _constructDydxTokenAction(uint positionIndex, bool isDeposit, uint amount, uint marketId, address targetAddress)
    private
    pure
    returns (DydxActions.ActionArgs memory action)
  {
    action.actionType = isDeposit ? DydxActions.ActionType.Deposit : DydxActions.ActionType.Withdraw;
    action.accountId = positionIndex;
    action.primaryMarketId = marketId;
    action.otherAddress = targetAddress;
    action.amount = DydxTypes.AssetAmount({
      sign: isDeposit,
      denomination: DydxTypes.AssetDenomination.Wei,
      ref: DydxTypes.AssetReference.Delta,
      value: amount
    });
  }

  function _constructDydxExpirationAction(uint positionIndex, uint marketId, uint expiration) 
    private 
    view 
    returns (DydxActions.ActionArgs memory action) 
  {
    action.actionType = DydxActions.ActionType.Call;
    action.accountId = positionIndex;
    action.otherAddress = DYDX_EXPIRATION_CONTRACT;
    action.data = abi.encode(marketId, block.timestamp + expiration);
  }

  function _generatePositionIndex(
    DydxPosition.Info[] memory positions, 
    uint numPositions, 
    address trader, 
    uint positionId
  ) 
    private 
    returns (uint, uint)  
  {
    for (uint i = 0; i < numPositions; i++) {
      if (positions[i].owner == trader && positions[i].number == positionId) {
        return (numPositions, i);
      }
    }

    positions[numPositions] = DydxPosition.Info(trader, positionId);
    return (numPositions + 1, numPositions);
  }

  function _marginLimitOrderAtIndex(LoopringTypes.BrokerApprovalRequest memory request, uint index)
    private
    view
    returns (
      LoopringTypes.BrokerOrder memory order,
      Types.MarginLimitOrderDetails memory limitOrder
    )
  {
    order = request.orders[index];
    limitOrder = order.extraData.decodeMarginLimitOrderDetails();

    address marketAddressS = DYDX_PROTOCOL.getMarketTokenAddress(limitOrder.marketIdS);
    require(request.tokenS == marketAddressS, "marketIdS must have address equal to tokenS");

    address marketAddressB = DYDX_PROTOCOL.getMarketTokenAddress(limitOrder.marketIdB);
    require(request.tokenB == marketAddressB, "marketIdB must have address equal to tokenB");

    limitOrder.depositToken = DYDX_PROTOCOL.getMarketTokenAddress(limitOrder.depositMarketId);
    require(request.tokenB == limitOrder.depositToken, "depositMarketId must have an address equal to tokenB");

    require(order.tokenRecipient == address(this), "Invalid tokenRecipient - must be set correctly");

    if (limitOrder.broker != address(0x0)) {
      limitOrder.trader = IDolomiteMarginTradingBroker(limitOrder.broker)
        .brokerMarginGetTrader(order.owner, order.extraData);
    } else {
      limitOrder.trader = order.owner;
    }
  }
}

 
contract MarginRingSubmitterWrapper is Globals {
  using MiscHelper for *;
  using DecodeHelper for bytes;
  using MarginOrderHelper for LoopringTypes.Order;
  using OrderDataHelper for Types.OrderData;

  event OpenPosition(address indexed trader, uint indexed id);
  event ClosePosition(address indexed trader, uint indexed id);

   
  function submitRingsWithMarginOrder(
    bytes calldata ringData, 
    bytes calldata relayData
  ) external {

    (
      Types.RelayerInfo memory relayerInfo,
      LoopringTypes.Order memory order,
      Types.MarginOrderDetails memory marginDetails
    ) = decodeParams(ringData, relayData);

     
     

    Types.OrderData memory orderData;

    if (order.broker == address(0x0)) {
      orderData.trader = order.owner;
    } else {
      orderData.trader = IDolomiteMarginTradingBroker(order.broker).brokerMarginGetTrader(
        order.owner, 
        order.transferDataS
      );
    }

    if (marginDetails.isOpen && marginDetails.isLong) {
       
      orderData.side = Types.OrderDataSide.BUY;
      orderData.fillAmountS = order.calculateActualAmount(relayerInfo.fillAmountS, order.tokenS);
      orderData.fillAmountB = order.getAmountB();

    } else if (marginDetails.isOpen && !marginDetails.isLong) {
       
      orderData.side = Types.OrderDataSide.SELL;
      orderData.fillAmountS = order.getAmountS();
      orderData.fillAmountB = order.calculateActualAmount(relayerInfo.fillAmountB, order.tokenB);

    } else if (!marginDetails.isOpen && marginDetails.isLong) {
       
      orderData.side = Types.OrderDataSide.BUY;
      orderData.fillAmountS = order.getAmountS();
      orderData.fillAmountB = order.calculateActualAmount(relayerInfo.fillAmountB, order.tokenB);
      orderData.bringToZero = true;

    } else if (!marginDetails.isOpen && !marginDetails.isLong) {
       
      orderData.side = Types.OrderDataSide.BUY;
      orderData.fillAmountS = order.calculateActualAmount(relayerInfo.fillAmountS, order.tokenS);
      orderData.fillAmountB = order.getAmountB();
      orderData.bringToZero = true;
    }

    bytes memory encodedOrderData = orderData.encodeWithRingData(ringData);

     
     

    DydxActions.ActionArgs[] memory actions;
    DydxPosition.Info[] memory positions = new DydxPosition.Info[](1);
    
     
    positions[0] = DydxPosition.Info({
      owner: orderData.trader,
      number: marginDetails.positionId
    });

     
    DydxActions.ActionArgs memory exchangeAction;
    exchangeAction.otherAddress = address(this);
    exchangeAction.data = encodedOrderData;

    if (orderData.side == Types.OrderDataSide.BUY) {
       
      exchangeAction.actionType = DydxActions.ActionType.Buy;
      exchangeAction.primaryMarketId = relayerInfo.marketIdB;
      exchangeAction.secondaryMarketId = relayerInfo.marketIdS;

      if (orderData.bringToZero) {
         
        exchangeAction.amount = DydxTypes.AssetAmount({
          sign: true,
          denomination: DydxTypes.AssetDenomination.Wei,
          ref: DydxTypes.AssetReference.Target,
          value: 0
        });

      } else {
        exchangeAction.amount = DydxTypes.AssetAmount({
          sign: true,
          denomination: DydxTypes.AssetDenomination.Wei,
          ref: DydxTypes.AssetReference.Delta,
          value: orderData.fillAmountB
        });
      }
      
    } else if (orderData.side == Types.OrderDataSide.SELL) {
       
      exchangeAction.actionType = DydxActions.ActionType.Sell;
      exchangeAction.primaryMarketId = relayerInfo.marketIdS;
      exchangeAction.secondaryMarketId = relayerInfo.marketIdB;
      exchangeAction.amount = DydxTypes.AssetAmount({
        sign: false,
        denomination: DydxTypes.AssetDenomination.Wei,
        ref: DydxTypes.AssetReference.Delta,
        value: orderData.fillAmountS
      });
    }

    if (marginDetails.isOpen) {
      
      if (order.broker == address(0x0)) {
         
        TRADE_DELEGATE.transferTokenFrom(
          marginDetails.depositToken, 
          marginDetails.owner,
          address(this), 
          marginDetails.depositAmount
        );
      } else {

         
        IDolomiteMarginTradingBroker(order.broker).brokerMarginRequestApproval(
          marginDetails.owner, 
          marginDetails.depositToken, 
          marginDetails.depositAmount
        );

         
        ERC20(marginDetails.depositToken).transferFrom(
          order.broker,
          address(this),
          marginDetails.depositAmount
        );
      }

       
      DydxActions.ActionArgs memory depositAction;
      depositAction.actionType = DydxActions.ActionType.Deposit;
      depositAction.primaryMarketId = marginDetails.depositMarketId;
      depositAction.otherAddress = address(this);
      depositAction.amount = DydxTypes.AssetAmount({
        sign: true,
        denomination: DydxTypes.AssetDenomination.Wei,
        ref: DydxTypes.AssetReference.Delta,
        value: marginDetails.depositAmount
      });

      if (marginDetails.expiration == 0) {
        actions = new DydxActions.ActionArgs[](2);
      } else {
         
        DydxActions.ActionArgs memory expirationAction;
        expirationAction.actionType = DydxActions.ActionType.Call;
        expirationAction.otherAddress = DYDX_EXPIRATION_CONTRACT;
        expirationAction.data = encodeExpiration(relayerInfo.marketIdS, marginDetails.expiration);

        actions = new DydxActions.ActionArgs[](3);
        actions[2] = expirationAction;
      }

       
      actions[0] = depositAction;
      actions[1] = exchangeAction;
      
    } else {
       
      DydxActions.ActionArgs memory withdrawAction;
      withdrawAction.actionType = DydxActions.ActionType.Withdraw;
      withdrawAction.primaryMarketId = marginDetails.withdrawalMarketId;
      withdrawAction.otherAddress = orderData.trader;
      withdrawAction.amount = DydxTypes.AssetAmount({
        sign: true,
        denomination: DydxTypes.AssetDenomination.Wei,
        ref: DydxTypes.AssetReference.Target,
        value: 0
      });

      DydxActions.ActionArgs memory withdrawDustAction;
      withdrawDustAction.actionType = DydxActions.ActionType.Withdraw;
      withdrawDustAction.primaryMarketId = relayerInfo.marketIdB;
      withdrawDustAction.otherAddress = orderData.trader;
      withdrawDustAction.amount = DydxTypes.AssetAmount({
        sign: true,
        denomination: DydxTypes.AssetDenomination.Wei,
        ref: DydxTypes.AssetReference.Target,
        value: 0
      });

       
      actions = new DydxActions.ActionArgs[](3);
      actions[0] = exchangeAction;
      actions[1] = withdrawAction;
      actions[2] = withdrawDustAction;
    }

     
     

    DYDX_PROTOCOL.operate(positions, actions);

     
     

    if (marginDetails.isOpen) {
      registerPosition(positions[0].owner, positions[0].number);
      emit OpenPosition(positions[0].owner, positions[0].number);
    } else emit ClosePosition(positions[0].owner, positions[0].number);
  }

   
   

  function decodeParams(bytes memory ringData, bytes memory relayData)
    private
    view
    returns (
      Types.RelayerInfo memory relayerInfo,
      LoopringTypes.Order memory order,
      Types.MarginOrderDetails memory marginDetails
    ) 
  {
    relayerInfo = relayData.decodeRelayerInfo();
    order = ringData.decodeMinimalOrderAtIndex(
      relayerInfo.marginOrderIndex, 
      LRC_TOKEN_ADDRESS
    );
    marginDetails = order.getMarginOrderDetails(ORDER_SELECTOR);
    order.checkValidity(relayerInfo, marginDetails, DYDX_PROTOCOL);
  }

  function encodeExpiration(uint marketId, uint expiration) private pure returns (bytes memory) {
    return abi.encode(marketId, expiration);
  }
}


 
contract DolomiteMarginTrading is Globals, MarginRingSubmitterWrapper, LoopringV2ExchangeWrapper, MarginLimitBroker {

  constructor(
    address payable loopringRingSubmitterAddress, 
    address dydxProtocolAddress,
    address dydxExpirationContractAddress
  ) 
    public 
    Globals(loopringRingSubmitterAddress, dydxProtocolAddress, dydxExpirationContractAddress) { }

   
   

  function enableToken(address token) external returns (bool) {
    ERC20(token).approve(address(LOOPRING_PROTOCOL), 10**70);
    ERC20(token).approve(address(TRADE_DELEGATE), 10**70);
    ERC20(token).approve(address(DYDX_PROTOCOL), 10**70);
    return true;
  }
}