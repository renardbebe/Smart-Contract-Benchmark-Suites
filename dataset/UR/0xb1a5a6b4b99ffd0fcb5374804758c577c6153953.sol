 

pragma solidity 0.5.7;
pragma experimental ABIEncoderV2;


interface IERC20 {
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
        if (a == 0) {
            return 0;
        }

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


interface IVersionable {
  
   
  function versionBeginUsage(
    address owner, 
    address payable depositAddress, 
    address oldVersion, 
    bytes calldata additionalData
  ) external;

   
  function versionEndUsage(
    address owner,
    address payable depositAddress,
    address newVersion,
    bytes calldata additionalData
  ) external;
}


library LoopringTypes {
  struct BrokerOrder {
      address owner;
      bytes32 orderHash;
      uint fillAmountB;
      uint requestedAmountS;
      uint requestedFeeAmount;
      address tokenRecipient;
      bytes extraData;
  }

  struct BrokerApprovalRequest {
      BrokerOrder[] orders;
      address tokenS;
      address tokenB;
      address feeToken;
      uint totalFillAmountB;
      uint totalRequestedAmountS;
      uint totalRequestedFeeAmount;
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
}


interface IBrokerDelegate {

   
  function brokerRequestAllowance(LoopringTypes.BrokerApprovalRequest calldata request) external returns (bool);

   
  function onOrderFillReport(LoopringTypes.BrokerInterceptorReport calldata fillReport) external;

   
  function brokerBalanceOf(address owner, address token) external view returns (uint);
}


interface IDolomiteMarginTradingBroker {
  
   
  function brokerMarginRequestApproval(address owner, address token, uint amount) external;

   
  function brokerMarginGetTrader(address owner, bytes calldata orderData) external returns (address);
}



library Types {

  struct RequestFee {
    address feeRecipient;
    address feeToken;
    uint feeAmount;
  }

  struct RequestSignature {
    uint8 v; 
    bytes32 r; 
    bytes32 s;
  }

  enum RequestType { Update, Transfer }

  struct Request {
    address owner;
    address target;
    RequestType requestType;
    bytes payload;
    uint nonce;
    RequestFee fee;
    RequestSignature signature;
  }

  struct TransferRequest {
    address token;
    address recipient;
    uint amount;
    bool unwrap;
  }
}

library RequestHelper {

  bytes constant personalPrefix = "\x19Ethereum Signed Message:\n32";

  function getSigner(Types.Request memory self) internal pure returns (address) {
    bytes32 messageHash = keccak256(abi.encode(
      self.owner,
      self.target,
      self.requestType,
      self.payload,
      self.nonce,
      abi.encode(self.fee.feeRecipient, self.fee.feeToken, self.fee.feeAmount)
    ));

    bytes32 prefixedHash = keccak256(abi.encodePacked(personalPrefix, messageHash));
    return ecrecover(prefixedHash, self.signature.v, self.signature.r, self.signature.s);
  }

  function decodeTransferRequest(Types.Request memory self) 
    internal 
    pure 
    returns (Types.TransferRequest memory transferRequest) 
  {
    require(self.requestType == Types.RequestType.Transfer, "INVALID_REQUEST_TYPE");

    (
      transferRequest.token,
      transferRequest.recipient,
      transferRequest.amount,
      transferRequest.unwrap
    ) = abi.decode(self.payload, (address, address, uint, bool));
  }
}


contract Requestable {
  using RequestHelper for Types.Request;

  mapping(address => uint) nonces;

  function validateRequest(Types.Request memory request) internal {
    require(request.target == address(this), "INVALID_TARGET");
    require(request.getSigner() == request.owner, "INVALID_SIGNATURE");
    require(nonces[request.owner] + 1 == request.nonce, "INVALID_NONCE");
    
    if (request.fee.feeAmount > 0) {
      require(balanceOf(request.owner, request.fee.feeToken) >= request.fee.feeAmount, "INSUFFICIENT_FEE_BALANCE");
    }

    nonces[request.owner] += 1;
  }

  function completeRequest(Types.Request memory request) internal {
    if (request.fee.feeAmount > 0) {
      _payRequestFee(request.owner, request.fee.feeToken, request.fee.feeRecipient, request.fee.feeAmount);
    }
  }

  function nonceOf(address owner) public view returns (uint) {
    return nonces[owner];
  }

   
  function balanceOf(address owner, address token) public view returns (uint);
  function _payRequestFee(address owner, address feeToken, address feeRecipient, uint feeAmount) internal;
}


contract DepositContract {
  address public owner;
  address public parent;
  address public version;
    
  function setVersion(address newVersion) external;

  function perform(
    address addr, 
    string calldata signature, 
    bytes calldata encodedParams,
    uint value
  ) external returns (bytes memory);
}


library DepositContractHelper {

  function wrapAndTransferToken(DepositContract self, address token, address recipient, uint amount, address wethAddress) internal {
    if (token == wethAddress) {
      uint etherBalance = address(self).balance;
      if (etherBalance > 0) wrapEth(self, token, etherBalance);
    }
    transferToken(self, token, recipient, amount);
  }

  function transferToken(DepositContract self, address token, address recipient, uint amount) internal {
    self.perform(token, "transfer(address,uint256)", abi.encode(recipient, amount), 0);
  }

  function transferEth(DepositContract self, address recipient, uint amount) internal {
    self.perform(recipient, "", abi.encode(), amount);
  }

  function approveToken(DepositContract self, address token, address broker, uint amount) internal {
    self.perform(token, "approve(address,uint256)", abi.encode(broker, amount), 0);
  }

  function wrapEth(DepositContract self, address wethToken, uint amount) internal {
    self.perform(wethToken, "deposit()", abi.encode(), amount);
  }

  function unwrapWeth(DepositContract self, address wethToken, uint amount) internal {
    self.perform(wethToken, "withdraw(uint256)", abi.encode(amount), 0);
  }

  function setDydxOperator(DepositContract self, address dydxContract, address operator) internal {
    bytes memory encodedParams = abi.encode(
      bytes32(0x0000000000000000000000000000000000000000000000000000000000000020),
      bytes32(0x0000000000000000000000000000000000000000000000000000000000000001),
      operator,
      bytes32(0x0000000000000000000000000000000000000000000000000000000000000001)
    );
    self.perform(dydxContract, "setOperators((address,bool)[])", encodedParams, 0);
  }
}


interface IDepositContractRegistry {
  function depositAddressOf(address owner) external view returns (address payable);
}


 
contract DolomiteDirectV1 is Requestable, IVersionable, IBrokerDelegate, IDolomiteMarginTradingBroker {
  using DepositContractHelper for DepositContract;
  using SafeMath for uint;

  IDepositContractRegistry public registry;
  address public loopringProtocolAddress;
  address public dolomiteMarginProtocolAddress;
  address public dydxProtocolAddress;
  address public wethTokenAddress;

  constructor(
    address _depositContractRegistry,
    address _loopringRingSubmitter,
    address _dolomiteMarginProtocol,
    address _dydxProtocolAddress,
    address _wethTokenAddress
  ) public {
    registry = IDepositContractRegistry(_depositContractRegistry);
    loopringProtocolAddress = _loopringRingSubmitter;
    dolomiteMarginProtocolAddress = _dolomiteMarginProtocol;
    dydxProtocolAddress = _dydxProtocolAddress;
    wethTokenAddress = _wethTokenAddress;
  }

   
  function balanceOf(address owner, address token) public view returns (uint) {
    address depositAddress = registry.depositAddressOf(owner);
    uint tokenBalance = IERC20(token).balanceOf(depositAddress);
    if (token == wethTokenAddress) tokenBalance = tokenBalance.add(depositAddress.balance);
    return tokenBalance;
  }

   
  function transfer(Types.Request memory request) public {
    validateRequest(request);
    
    Types.TransferRequest memory transferRequest = request.decodeTransferRequest();
    address payable depositAddress = registry.depositAddressOf(request.owner);

    _transfer(
      transferRequest.token, 
      depositAddress, 
      transferRequest.recipient, 
      transferRequest.amount, 
      transferRequest.unwrap
    );

    completeRequest(request);
  }

   

  function _transfer(address token, address payable depositAddress, address recipient, uint amount, bool unwrap) internal {
    DepositContract depositContract = DepositContract(depositAddress);
    
    if (token == wethTokenAddress && unwrap) {
      if (depositAddress.balance < amount) {
        depositContract.unwrapWeth(wethTokenAddress, amount.sub(depositAddress.balance));
      }

      depositContract.transferEth(recipient, amount);
      return;
    }

    depositContract.wrapAndTransferToken(token, recipient, amount, wethTokenAddress);
  }

   
   

  function brokerRequestAllowance(LoopringTypes.BrokerApprovalRequest memory request) public returns (bool) {
    require(msg.sender == loopringProtocolAddress);

    LoopringTypes.BrokerOrder[] memory mergedOrders = new LoopringTypes.BrokerOrder[](request.orders.length);
    uint numMergedOrders = 1;

    mergedOrders[0] = request.orders[0];
    
    if (request.orders.length > 1) {
      for (uint i = 1; i < request.orders.length; i++) {
        bool isDuplicate = false;

        for (uint b = 0; b < numMergedOrders; b++) {
          if (request.orders[i].owner == mergedOrders[b].owner) {
            mergedOrders[b].requestedAmountS += request.orders[i].requestedAmountS;
            mergedOrders[b].requestedFeeAmount += request.orders[i].requestedFeeAmount;
            isDuplicate = true;
            break;
          }
        }

        if (!isDuplicate) {
          mergedOrders[numMergedOrders] = request.orders[i];
          numMergedOrders += 1;
        }
      }
    }

    for (uint j = 0; j < numMergedOrders; j++) {
      LoopringTypes.BrokerOrder memory order = mergedOrders[j];
      address payable depositAddress = registry.depositAddressOf(order.owner);
      
      _transfer(request.tokenS, depositAddress, address(this), order.requestedAmountS, false);
      if (order.requestedFeeAmount > 0) _transfer(request.feeToken, depositAddress, address(this), order.requestedFeeAmount, false);
    }

    return false;  
  }

  function onOrderFillReport(LoopringTypes.BrokerInterceptorReport memory fillReport) public {
     
  }

  function brokerBalanceOf(address owner, address tokenAddress) public view returns (uint) {
    return balanceOf(owner, tokenAddress);
  }

   
   

  function brokerMarginRequestApproval(address owner, address token, uint amount) public {
    require(msg.sender == dolomiteMarginProtocolAddress);

    address payable depositAddress = registry.depositAddressOf(owner);
    _transfer(token, depositAddress, address(this), amount, false);
  }

  function brokerMarginGetTrader(address owner, bytes memory orderData) public returns (address) {
    return registry.depositAddressOf(owner);
  }

   
   

  function _payRequestFee(address owner, address feeToken, address feeRecipient, uint feeAmount) internal {
    _transfer(feeToken, registry.depositAddressOf(owner), feeRecipient, feeAmount, false);
  }

   
   

  function versionBeginUsage(
    address owner, 
    address payable depositAddress, 
    address oldVersion, 
    bytes calldata additionalData
  ) external { 
     
    DepositContract(depositAddress).setDydxOperator(dydxProtocolAddress, dolomiteMarginProtocolAddress);
  }

  function versionEndUsage(
    address owner,
    address payable depositAddress,
    address newVersion,
    bytes calldata additionalData
  ) external {   }


   
   

   
  function enableTrading(address token) external {
    IERC20(token).approve(loopringProtocolAddress, 10**70);
    IERC20(token).approve(dolomiteMarginProtocolAddress, 10**70);
  }
}