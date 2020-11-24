 

 

pragma solidity ^0.5.0;

 
library Buffer {
   
  struct buffer {
    bytes buf;
    uint capacity;
  }

   
  function init(buffer memory buf, uint capacity) internal pure returns(buffer memory) {
    if (capacity % 32 != 0) {
      capacity += 32 - (capacity % 32);
    }
     
    buf.capacity = capacity;
    assembly {
      let ptr := mload(0x40)
      mstore(buf, ptr)
      mstore(ptr, 0)
      mstore(0x40, add(32, add(ptr, capacity)))
    }
    return buf;
  }

   
  function fromBytes(bytes memory b) internal pure returns(buffer memory) {
    buffer memory buf;
    buf.buf = b;
    buf.capacity = b.length;
    return buf;
  }

  function resize(buffer memory buf, uint capacity) private pure {
    bytes memory oldbuf = buf.buf;
    init(buf, capacity);
    append(buf, oldbuf);
  }

  function max(uint a, uint b) private pure returns(uint) {
    if (a > b) {
      return a;
    }
    return b;
  }

   
  function truncate(buffer memory buf) internal pure returns (buffer memory) {
    assembly {
      let bufptr := mload(buf)
      mstore(bufptr, 0)
    }
    return buf;
  }

   
  function write(buffer memory buf, uint off, bytes memory data, uint len) internal pure returns(buffer memory) {
    require(len <= data.length);

    if (off + len > buf.capacity) {
      resize(buf, max(buf.capacity, len + off) * 2);
    }

    uint dest;
    uint src;
    assembly {
       
      let bufptr := mload(buf)
       
      let buflen := mload(bufptr)
       
      dest := add(add(bufptr, 32), off)
       
      if gt(add(len, off), buflen) {
        mstore(bufptr, add(len, off))
      }
      src := add(data, 32)
    }

     
    for (; len >= 32; len -= 32) {
      assembly {
        mstore(dest, mload(src))
      }
      dest += 32;
      src += 32;
    }

     
    uint mask = 256 ** (32 - len) - 1;
    assembly {
      let srcpart := and(mload(src), not(mask))
      let destpart := and(mload(dest), mask)
      mstore(dest, or(destpart, srcpart))
    }

    return buf;
  }

   
  function append(buffer memory buf, bytes memory data, uint len) internal pure returns (buffer memory) {
    return write(buf, buf.buf.length, data, len);
  }

   
  function append(buffer memory buf, bytes memory data) internal pure returns (buffer memory) {
    return write(buf, buf.buf.length, data, data.length);
  }

   
  function writeUint8(buffer memory buf, uint off, uint8 data) internal pure returns(buffer memory) {
    if (off >= buf.capacity) {
      resize(buf, buf.capacity * 2);
    }

    assembly {
       
      let bufptr := mload(buf)
       
      let buflen := mload(bufptr)
       
      let dest := add(add(bufptr, off), 32)
      mstore8(dest, data)
       
      if eq(off, buflen) {
        mstore(bufptr, add(buflen, 1))
      }
    }
    return buf;
  }

   
  function appendUint8(buffer memory buf, uint8 data) internal pure returns(buffer memory) {
    return writeUint8(buf, buf.buf.length, data);
  }

   
  function write(buffer memory buf, uint off, bytes32 data, uint len) private pure returns(buffer memory) {
    if (len + off > buf.capacity) {
      resize(buf, (len + off) * 2);
    }

    uint mask = 256 ** len - 1;
     
    data = data >> (8 * (32 - len));
    assembly {
       
      let bufptr := mload(buf)
       
      let dest := add(add(bufptr, off), len)
      mstore(dest, or(and(mload(dest), not(mask)), data))
       
      if gt(add(off, len), mload(bufptr)) {
        mstore(bufptr, add(off, len))
      }
    }
    return buf;
  }

   
  function writeBytes20(buffer memory buf, uint off, bytes20 data) internal pure returns (buffer memory) {
    return write(buf, off, bytes32(data), 20);
  }

   
  function appendBytes20(buffer memory buf, bytes20 data) internal pure returns (buffer memory) {
    return write(buf, buf.buf.length, bytes32(data), 20);
  }

   
  function appendBytes32(buffer memory buf, bytes32 data) internal pure returns (buffer memory) {
    return write(buf, buf.buf.length, data, 32);
  }

   
  function writeInt(buffer memory buf, uint off, uint data, uint len) private pure returns(buffer memory) {
    if (len + off > buf.capacity) {
      resize(buf, (len + off) * 2);
    }

    uint mask = 256 ** len - 1;
    assembly {
       
      let bufptr := mload(buf)
       
      let dest := add(add(bufptr, off), len)
      mstore(dest, or(and(mload(dest), not(mask)), data))
       
      if gt(add(off, len), mload(bufptr)) {
        mstore(bufptr, add(off, len))
      }
    }
    return buf;
  }

   
  function appendInt(buffer memory buf, uint data, uint len) internal pure returns(buffer memory) {
    return writeInt(buf, buf.buf.length, data, len);
  }
}

 

pragma solidity ^0.5.0;


library CBOR {
  using Buffer for Buffer.buffer;

  uint8 private constant MAJOR_TYPE_INT = 0;
  uint8 private constant MAJOR_TYPE_NEGATIVE_INT = 1;
  uint8 private constant MAJOR_TYPE_BYTES = 2;
  uint8 private constant MAJOR_TYPE_STRING = 3;
  uint8 private constant MAJOR_TYPE_ARRAY = 4;
  uint8 private constant MAJOR_TYPE_MAP = 5;
  uint8 private constant MAJOR_TYPE_CONTENT_FREE = 7;

  function encodeType(Buffer.buffer memory buf, uint8 major, uint value) private pure {
    if(value <= 23) {
      buf.appendUint8(uint8((major << 5) | value));
    } else if(value <= 0xFF) {
      buf.appendUint8(uint8((major << 5) | 24));
      buf.appendInt(value, 1);
    } else if(value <= 0xFFFF) {
      buf.appendUint8(uint8((major << 5) | 25));
      buf.appendInt(value, 2);
    } else if(value <= 0xFFFFFFFF) {
      buf.appendUint8(uint8((major << 5) | 26));
      buf.appendInt(value, 4);
    } else if(value <= 0xFFFFFFFFFFFFFFFF) {
      buf.appendUint8(uint8((major << 5) | 27));
      buf.appendInt(value, 8);
    }
  }

  function encodeIndefiniteLengthType(Buffer.buffer memory buf, uint8 major) private pure {
    buf.appendUint8(uint8((major << 5) | 31));
  }

  function encodeUInt(Buffer.buffer memory buf, uint value) internal pure {
    encodeType(buf, MAJOR_TYPE_INT, value);
  }

  function encodeInt(Buffer.buffer memory buf, int value) internal pure {
    if(value >= 0) {
      encodeType(buf, MAJOR_TYPE_INT, uint(value));
    } else {
      encodeType(buf, MAJOR_TYPE_NEGATIVE_INT, uint(-1 - value));
    }
  }

  function encodeBytes(Buffer.buffer memory buf, bytes memory value) internal pure {
    encodeType(buf, MAJOR_TYPE_BYTES, value.length);
    buf.append(value);
  }

  function encodeString(Buffer.buffer memory buf, string memory value) internal pure {
    encodeType(buf, MAJOR_TYPE_STRING, bytes(value).length);
    buf.append(bytes(value));
  }

  function startArray(Buffer.buffer memory buf) internal pure {
    encodeIndefiniteLengthType(buf, MAJOR_TYPE_ARRAY);
  }

  function startMap(Buffer.buffer memory buf) internal pure {
    encodeIndefiniteLengthType(buf, MAJOR_TYPE_MAP);
  }

  function endSequence(Buffer.buffer memory buf) internal pure {
    encodeIndefiniteLengthType(buf, MAJOR_TYPE_CONTENT_FREE);
  }
}

 

pragma solidity ^0.5.0;


 
library Chainlink {
  uint256 internal constant defaultBufferSize = 256;  

  using CBOR for Buffer.buffer;

  struct Request {
    bytes32 id;
    address callbackAddress;
    bytes4 callbackFunctionId;
    uint256 nonce;
    Buffer.buffer buf;
  }

   
  function initialize(
    Request memory self,
    bytes32 _id,
    address _callbackAddress,
    bytes4 _callbackFunction
  ) internal pure returns (Chainlink.Request memory) {
    Buffer.init(self.buf, defaultBufferSize);
    self.id = _id;
    self.callbackAddress = _callbackAddress;
    self.callbackFunctionId = _callbackFunction;
    return self;
  }

   
  function setBuffer(Request memory self, bytes memory _data)
    internal pure
  {
    Buffer.init(self.buf, _data.length);
    Buffer.append(self.buf, _data);
  }

   
  function add(Request memory self, string memory _key, string memory _value)
    internal pure
  {
    self.buf.encodeString(_key);
    self.buf.encodeString(_value);
  }

   
  function addBytes(Request memory self, string memory _key, bytes memory _value)
    internal pure
  {
    self.buf.encodeString(_key);
    self.buf.encodeBytes(_value);
  }

   
  function addInt(Request memory self, string memory _key, int256 _value)
    internal pure
  {
    self.buf.encodeString(_key);
    self.buf.encodeInt(_value);
  }

   
  function addUint(Request memory self, string memory _key, uint256 _value)
    internal pure
  {
    self.buf.encodeString(_key);
    self.buf.encodeUInt(_value);
  }

   
  function addStringArray(Request memory self, string memory _key, string[] memory _values)
    internal pure
  {
    self.buf.encodeString(_key);
    self.buf.startArray();
    for (uint256 i = 0; i < _values.length; i++) {
      self.buf.encodeString(_values[i]);
    }
    self.buf.endSequence();
  }
}

 

pragma solidity ^0.5.0;

interface ENSInterface {

   
  event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);

   
  event Transfer(bytes32 indexed node, address owner);

   
  event NewResolver(bytes32 indexed node, address resolver);

   
  event NewTTL(bytes32 indexed node, uint64 ttl);


  function setSubnodeOwner(bytes32 node, bytes32 label, address _owner) external;
  function setResolver(bytes32 node, address _resolver) external;
  function setOwner(bytes32 node, address _owner) external;
  function setTTL(bytes32 node, uint64 _ttl) external;
  function owner(bytes32 node) external view returns (address);
  function resolver(bytes32 node) external view returns (address);
  function ttl(bytes32 node) external view returns (uint64);

}

 

pragma solidity ^0.5.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external returns (uint256 remaining);
  function approve(address spender, uint256 value) external returns (bool success);
  function balanceOf(address owner) external returns (uint256 balance);
  function decimals() external returns (uint8 decimalPlaces);
  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);
  function increaseApproval(address spender, uint256 subtractedValue) external;
  function name() external returns (string memory tokenName);
  function symbol() external returns (string memory tokenSymbol);
  function totalSupply() external returns (uint256 totalTokensIssued);
  function transfer(address to, uint256 value) external returns (bool success);
  function transferAndCall(address to, uint256 value, bytes calldata data) external returns (bool success);
  function transferFrom(address from, address to, uint256 value) external returns (bool success);
}

 

pragma solidity ^0.5.0;

interface ChainlinkRequestInterface {
  function oracleRequest(
    address sender,
    uint256 requestPrice,
    bytes32 serviceAgreementID,
    address callbackAddress,
    bytes4 callbackFunctionId,
    uint256 nonce,
    uint256 dataVersion,  
    bytes calldata data
  ) external;

  function cancelOracleRequest(
    bytes32 requestId,
    uint256 payment,
    bytes4 callbackFunctionId,
    uint256 expiration
  ) external;
}

 

pragma solidity ^0.5.0;

interface PointerInterface {
  function getAddress() external view returns (address);
}

 

pragma solidity ^0.5.0;

contract ENSResolver {
  function addr(bytes32 node) public view returns (address);
}

 

pragma solidity ^0.5.0;

 
library SafeMath {
   
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "SafeMath: subtraction overflow");
    uint256 c = a - b;

    return c;
  }

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
    require(b > 0, "SafeMath: division by zero");
    uint256 c = a / b;
     

    return c;
  }

   
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, "SafeMath: modulo by zero");
    return a % b;
  }
}

 

pragma solidity ^0.5.0;








 
contract ChainlinkClient {
  using Chainlink for Chainlink.Request;
  using SafeMath for uint256;

  uint256 constant internal LINK = 10**18;
  uint256 constant private AMOUNT_OVERRIDE = 0;
  address constant private SENDER_OVERRIDE = address(0);
  uint256 constant private ARGS_VERSION = 1;
  bytes32 constant private ENS_TOKEN_SUBNAME = keccak256("link");
  bytes32 constant private ENS_ORACLE_SUBNAME = keccak256("oracle");
  address constant private LINK_TOKEN_POINTER = 0xC89bD4E1632D3A43CB03AAAd5262cbe4038Bc571;

  ENSInterface private ens;
  bytes32 private ensNode;
  LinkTokenInterface private link;
  ChainlinkRequestInterface private oracle;
  uint256 private requestCount = 1;
  mapping(bytes32 => address) private pendingRequests;

  event ChainlinkRequested(bytes32 indexed id);
  event ChainlinkFulfilled(bytes32 indexed id);
  event ChainlinkCancelled(bytes32 indexed id);

   
  function buildChainlinkRequest(
    bytes32 _specId,
    address _callbackAddress,
    bytes4 _callbackFunctionSignature
  ) internal pure returns (Chainlink.Request memory) {
    Chainlink.Request memory req;
    return req.initialize(_specId, _callbackAddress, _callbackFunctionSignature);
  }

   
  function sendChainlinkRequest(Chainlink.Request memory _req, uint256 _payment)
    internal
    returns (bytes32)
  {
    return sendChainlinkRequestTo(address(oracle), _req, _payment);
  }

   
  function sendChainlinkRequestTo(address _oracle, Chainlink.Request memory _req, uint256 _payment)
    internal
    returns (bytes32 requestId)
  {
    requestId = keccak256(abi.encodePacked(this, requestCount));
    _req.nonce = requestCount;
    pendingRequests[requestId] = _oracle;
    emit ChainlinkRequested(requestId);
    require(link.transferAndCall(_oracle, _payment, encodeRequest(_req)), "unable to transferAndCall to oracle");
    requestCount += 1;

    return requestId;
  }

   
  function cancelChainlinkRequest(
    bytes32 _requestId,
    uint256 _payment,
    bytes4 _callbackFunc,
    uint256 _expiration
  )
    internal
  {
    ChainlinkRequestInterface requested = ChainlinkRequestInterface(pendingRequests[_requestId]);
    delete pendingRequests[_requestId];
    emit ChainlinkCancelled(_requestId);
    requested.cancelOracleRequest(_requestId, _payment, _callbackFunc, _expiration);
  }

   
  function setChainlinkOracle(address _oracle) internal {
    oracle = ChainlinkRequestInterface(_oracle);
  }

   
  function setChainlinkToken(address _link) internal {
    link = LinkTokenInterface(_link);
  }

   
  function setPublicChainlinkToken() internal {
    setChainlinkToken(PointerInterface(LINK_TOKEN_POINTER).getAddress());
  }

   
  function chainlinkTokenAddress()
    internal
    view
    returns (address)
  {
    return address(link);
  }

   
  function chainlinkOracleAddress()
    internal
    view
    returns (address)
  {
    return address(oracle);
  }

   
  function addChainlinkExternalRequest(address _oracle, bytes32 _requestId)
    internal
    notPendingRequest(_requestId)
  {
    pendingRequests[_requestId] = _oracle;
  }

   
  function useChainlinkWithENS(address _ens, bytes32 _node)
    internal
  {
    ens = ENSInterface(_ens);
    ensNode = _node;
    bytes32 linkSubnode = keccak256(abi.encodePacked(ensNode, ENS_TOKEN_SUBNAME));
    ENSResolver resolver = ENSResolver(ens.resolver(linkSubnode));
    setChainlinkToken(resolver.addr(linkSubnode));
    updateChainlinkOracleWithENS();
  }

   
  function updateChainlinkOracleWithENS()
    internal
  {
    bytes32 oracleSubnode = keccak256(abi.encodePacked(ensNode, ENS_ORACLE_SUBNAME));
    ENSResolver resolver = ENSResolver(ens.resolver(oracleSubnode));
    setChainlinkOracle(resolver.addr(oracleSubnode));
  }

   
  function encodeRequest(Chainlink.Request memory _req)
    private
    view
    returns (bytes memory)
  {
    return abi.encodeWithSelector(
      oracle.oracleRequest.selector,
      SENDER_OVERRIDE,  
      AMOUNT_OVERRIDE,  
      _req.id,
      _req.callbackAddress,
      _req.callbackFunctionId,
      _req.nonce,
      ARGS_VERSION,
      _req.buf.buf);
  }

   
  function validateChainlinkCallback(bytes32 _requestId)
    internal
    recordChainlinkFulfillment(_requestId)
     
  {}

   
  modifier recordChainlinkFulfillment(bytes32 _requestId) {
    require(msg.sender == pendingRequests[_requestId],
            "Source must be the oracle of the request");
    delete pendingRequests[_requestId];
    emit ChainlinkFulfilled(_requestId);
    _;
  }

   
  modifier notPendingRequest(bytes32 _requestId) {
    require(pendingRequests[_requestId] == address(0), "Request is already pending");
    _;
  }
}

 

pragma solidity ^0.5.0;

contract LinkTokenReceiver {

  bytes4 constant private ORACLE_REQUEST_SELECTOR = 0x40429946;
  uint256 constant private SELECTOR_LENGTH = 4;
  uint256 constant private EXPECTED_REQUEST_WORDS = 2;
  uint256 constant private MINIMUM_REQUEST_LENGTH = SELECTOR_LENGTH + (32 * EXPECTED_REQUEST_WORDS);
   
  function onTokenTransfer(
    address _sender,
    uint256 _amount,
    bytes memory _data
  )
    public
    onlyLINK
    validRequestLength(_data)
    permittedFunctionsForLINK(_data)
  {
    assembly {
       
      mstore(add(_data, 36), _sender)  
       
      mstore(add(_data, 68), _amount)     
    }
     
    (bool success, ) = address(this).delegatecall(_data);  
    require(success, "Unable to create request");
  }

  function getChainlinkToken() public view returns (address);

   
  modifier onlyLINK() {
    require(msg.sender == getChainlinkToken(), "Must use LINK token");
    _;
  }

   
  modifier permittedFunctionsForLINK(bytes memory _data) {
    bytes4 funcSelector;
    assembly {
       
      funcSelector := mload(add(_data, 32))
    }
    require(funcSelector == ORACLE_REQUEST_SELECTOR, "Must use whitelisted functions");
    _;
  }

   
  modifier validRequestLength(bytes memory _data) {
    require(_data.length >= MINIMUM_REQUEST_LENGTH, "Invalid request length");
    _;
  }
}

 

pragma solidity ^0.5.0;

library SignedSafeMath {

   
  function add(int256 _a, int256 _b)
    internal
    pure
    returns (int256)
  {
     
    int256 c = _a + _b;
    require((_b >= 0 && c >= _a) || (_b < 0 && c < _a), "SignedSafeMath: addition overflow");

    return c;
  }
}

 

pragma solidity ^0.5.0;



library Median {
  using SafeMath for uint256;
  using SignedSafeMath for int256;

   
  function calculate(int256[] memory _list)
    internal
    returns (int256)
  {
    uint256 answerLength = _list.length;
    uint256 middleIndex = answerLength.div(2);
    if (answerLength % 2 == 0) {
      int256 median1 = quickselect(copy(_list), middleIndex);
      int256 median2 = quickselect(_list, middleIndex.add(1));  
      int256 remainder = (median1 % 2 + median2 % 2) / 2;
      return (median1 / 2).add(median2 / 2).add(remainder);  
    } else {
      return quickselect(_list, middleIndex.add(1));  
    }
  }

   
  function quickselect(int256[] memory _a, uint256 _k)
    private
    pure
    returns (int256)
  {
    int256[] memory a = _a;
    uint256 k = _k;
    uint256 aLen = a.length;
    int256[] memory a1 = new int256[](aLen);
    int256[] memory a2 = new int256[](aLen);
    uint256 a1Len;
    uint256 a2Len;
    int256 pivot;
    uint256 i;

    while (true) {
      pivot = a[aLen.div(2)];
      a1Len = 0;
      a2Len = 0;
      for (i = 0; i < aLen; i++) {
        if (a[i] < pivot) {
          a1[a1Len] = a[i];
          a1Len++;
        } else if (a[i] > pivot) {
          a2[a2Len] = a[i];
          a2Len++;
        }
      }
      if (k <= a1Len) {
        aLen = a1Len;
        (a, a1) = swap(a, a1);
      } else if (k > (aLen.sub(a2Len))) {
        k = k.sub(aLen.sub(a2Len));
        aLen = a2Len;
        (a, a2) = swap(a, a2);
      } else {
        return pivot;
      }
    }
  }

   
  function swap(int256[] memory _a, int256[] memory _b)
    private
    pure
    returns(int256[] memory, int256[] memory)
  {
    return (_b, _a);
  }

   
  function copy(int256[] memory _list)
    private
    pure
    returns(int256[] memory)
  {
    int256[] memory list2 = new int256[](_list.length);
    for (uint256 i = 0; i < _list.length; i++) {
      list2[i] = _list[i];
    }
    return list2;
  }

}

 

pragma solidity ^0.5.0;

 
contract Ownable {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

   
  constructor () internal {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

   
  function owner() public view returns (address) {
    return _owner;
  }

   
  modifier onlyOwner() {
    require(isOwner(), "Ownable: caller is not the owner");
    _;
  }

   
  function isOwner() public view returns (bool) {
    return msg.sender == _owner;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

   
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

 

pragma solidity ^0.5.0;






 
contract PreCoordinator is ChainlinkClient, Ownable, ChainlinkRequestInterface, LinkTokenReceiver {
  using SafeMath for uint256;

  uint256 constant private MAX_ORACLE_COUNT = 45;

  uint256 private globalNonce;

  struct ServiceAgreement {
    uint256 totalPayment;
    uint256 minResponses;
    uint256 activeRequests;
    address[] oracles;
    bytes32[] jobIds;
    uint256[] payments;
  }

  struct Requester {
    bytes4 callbackFunctionId;
    address sender;
    address callbackAddress;
    int256[] responses;
  }

   
  mapping(bytes32 => ServiceAgreement) internal serviceAgreements;
   
  mapping(bytes32 => bytes32) internal serviceAgreementRequests;
   
  mapping(bytes32 => Requester) internal requesters;
   
  mapping(bytes32 => bytes32) internal requests;

  event NewServiceAgreement(bytes32 indexed saId, uint256 payment, uint256 minresponses);
  event ServiceAgreementRequested(bytes32 indexed saId, bytes32 indexed requestId, uint256 payment);
  event ServiceAgreementResponseReceived(bytes32 indexed saId, bytes32 indexed requestId, address indexed oracle, int256 answer);
  event ServiceAgreementAnswerUpdated(bytes32 indexed saId, bytes32 indexed requestId, int256 answer);
  event ServiceAgreementDeleted(bytes32 indexed saId);

   
  constructor(address _link) public {
    if(_link == address(0)) {
      setPublicChainlinkToken();
    } else {
      setChainlinkToken(_link);
    }
  }

   
  function createServiceAgreement(
    uint256 _minResponses,
    address[] calldata _oracles,
    bytes32[] calldata _jobIds,
    uint256[] calldata _payments
  )
    external onlyOwner returns (bytes32 saId)
  {
    require(_minResponses > 0, "Min responses must be > 0");
    require(_oracles.length == _jobIds.length && _oracles.length == _payments.length, "Unmet length");
    require(_oracles.length <= MAX_ORACLE_COUNT, "Cannot have more than 45 oracles");
    require(_oracles.length >= _minResponses, "Invalid min responses");
    uint256 totalPayment;
    for (uint i = 0; i < _payments.length; i++) {
      totalPayment = totalPayment.add(_payments[i]);
    }
    saId = keccak256(abi.encodePacked(globalNonce, now));
    globalNonce++;  
    serviceAgreements[saId] = ServiceAgreement(totalPayment, _minResponses, 0, _oracles, _jobIds, _payments);

    emit NewServiceAgreement(saId, totalPayment, _minResponses);
  }

   
  function getServiceAgreement(bytes32 _saId)
    external view returns
  (
    uint256 totalPayment,
    uint256 minResponses,
    uint256 activeRequests,
    address[] memory oracles,
    bytes32[] memory jobIds,
    uint256[] memory payments
  )
  {
    return
    (
      serviceAgreements[_saId].totalPayment,
      serviceAgreements[_saId].minResponses,
      serviceAgreements[_saId].activeRequests,
      serviceAgreements[_saId].oracles,
      serviceAgreements[_saId].jobIds,
      serviceAgreements[_saId].payments
    );
  }

   
  function deleteServiceAgreement(bytes32 _saId)
    external
    onlyOwner
    whenNotActive(_saId)
  {
    delete serviceAgreements[_saId];
    emit ServiceAgreementDeleted(_saId);
  }

   
  function getChainlinkToken() public view returns (address) {
    return chainlinkTokenAddress();
  }

   
  function oracleRequest(
    address _sender,
    uint256 _payment,
    bytes32 _saId,
    address _callbackAddress,
    bytes4 _callbackFunctionId,
    uint256 _nonce,
    uint256,
    bytes calldata _data
  )
    external
    onlyLINK
    checkCallbackAddress(_callbackAddress)
  {
    uint256 totalPayment = serviceAgreements[_saId].totalPayment;
     
    require(_payment >= totalPayment, "Insufficient payment");
    bytes32 callbackRequestId = keccak256(abi.encodePacked(_sender, _nonce));
    require(requesters[callbackRequestId].sender == address(0), "Nonce already in-use");
    requesters[callbackRequestId].callbackFunctionId = _callbackFunctionId;
    requesters[callbackRequestId].callbackAddress = _callbackAddress;
    requesters[callbackRequestId].sender = _sender;
    createRequests(_saId, callbackRequestId, _data);
    if (_payment > totalPayment) {
      uint256 overage = _payment.sub(totalPayment);
      LinkTokenInterface _link = LinkTokenInterface(chainlinkTokenAddress());
      assert(_link.transfer(_sender, overage));
    }
  }

   
  function createRequests(bytes32 _saId, bytes32 _incomingRequestId, bytes memory _data) private {
    ServiceAgreement memory sa = serviceAgreements[_saId];
    require(sa.minResponses > 0, "Invalid service agreement");
    Chainlink.Request memory request;
    bytes32 outgoingRequestId;
    serviceAgreements[_saId].activeRequests = serviceAgreements[_saId].activeRequests.add(1);
    emit ServiceAgreementRequested(_saId, _incomingRequestId, sa.totalPayment);
    for (uint i = 0; i < sa.oracles.length; i++) {
      request = buildChainlinkRequest(sa.jobIds[i], address(this), this.chainlinkCallback.selector);
      request.setBuffer(_data);
      outgoingRequestId = sendChainlinkRequestTo(sa.oracles[i], request, sa.payments[i]);
      requests[outgoingRequestId] = _incomingRequestId;
      serviceAgreementRequests[outgoingRequestId] = _saId;
    }
  }

   
  function chainlinkCallback(bytes32 _requestId, int256 _data)
    external
    recordChainlinkFulfillment(_requestId)
    returns (bool)
  {
    uint256 minResponses = serviceAgreements[serviceAgreementRequests[_requestId]].minResponses;
    bytes32 cbRequestId = requests[_requestId];
    bytes32 saId = serviceAgreementRequests[_requestId];
    delete requests[_requestId];
    delete serviceAgreementRequests[_requestId];
    emit ServiceAgreementResponseReceived(saId, cbRequestId, msg.sender, _data);
    if (requesters[cbRequestId].responses.push(_data) == minResponses) {
      serviceAgreements[saId].activeRequests = serviceAgreements[saId].activeRequests.sub(1);
      Requester memory req = requesters[cbRequestId];
      delete requesters[cbRequestId];
      int256 result = Median.calculate(req.responses);
      emit ServiceAgreementAnswerUpdated(saId, cbRequestId, result);
       
      (bool success, ) = req.callbackAddress.call(abi.encodeWithSelector(req.callbackFunctionId, cbRequestId, result));
      return success;
    }
    return true;
  }

   
  function withdrawLink() external onlyOwner {
    LinkTokenInterface _link = LinkTokenInterface(chainlinkTokenAddress());
    require(_link.transfer(msg.sender, _link.balanceOf(address(this))), "Unable to transfer");
  }

   
  function cancelOracleRequest(
    bytes32 _requestId,
    uint256 _payment,
    bytes4 _callbackFunctionId,
    uint256 _expiration
  )
    external
  {
    bytes32 cbRequestId = requests[_requestId];
    delete requests[_requestId];
    delete serviceAgreementRequests[_requestId];
    Requester memory req = requesters[cbRequestId];
    require(req.sender == msg.sender, "Only requester can cancel");
    delete requesters[cbRequestId];
    cancelChainlinkRequest(_requestId, _payment, _callbackFunctionId, _expiration);
    LinkTokenInterface _link = LinkTokenInterface(chainlinkTokenAddress());
    require(_link.transfer(req.sender, _payment), "Unable to transfer");
  }

   
  modifier whenNotActive(bytes32 _saId) {
    require(serviceAgreements[_saId].activeRequests == 0, "Cannot delete while active");
    _;
  }

   
  modifier checkCallbackAddress(address _to) {
    require(_to != chainlinkTokenAddress(), "Cannot callback to LINK");
    _;
  }
}