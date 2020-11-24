 

 

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

  struct UpdateRequest {
    address version;
    bytes additionalData;
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

  function decodeUpdateRequest(Types.Request memory self) 
    internal 
    pure 
    returns (Types.UpdateRequest memory updateRequest) 
  {
    require(self.requestType == Types.RequestType.Update, "INVALID_REQUEST_TYPE");

    (
      updateRequest.version,
      updateRequest.additionalData
    ) = abi.decode(self.payload, (address, bytes));
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

  constructor(address _owner) public {
    parent = msg.sender;
    owner = _owner;
  }

   
  function() external payable { }

   
  function setVersion(address newVersion) external {
    require(msg.sender == parent);
    version = newVersion;
  }

   
  function perform(
    address addr, 
    string calldata signature, 
    bytes calldata encodedParams,
    uint value
  ) 
    external 
    returns (bytes memory) 
  {
    require(msg.sender == owner || msg.sender == parent || msg.sender == version, "NOT_PERMISSIBLE");

    if (bytes(signature).length == 0) {
      address(uint160(addr)).transfer(value);  
    } else {
      bytes4 functionSelector = bytes4(keccak256(bytes(signature)));
      bytes memory payload = abi.encodePacked(functionSelector, encodedParams);
      
      (bool success, bytes memory returnData) = addr.call.value(value)(payload);
      require(success, "OPERATION_REVERTED");

      return returnData;
    }
  }
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
}


 
contract DepositContractRegistry is Requestable {
  using DepositContractHelper for DepositContract;

  event CreatedDepositContract(address indexed owner, address indexed depositAddress);
  event UpgradedVersion(address indexed owner, address indexed depositAddress, address newVersion);

  bytes constant public DEPOSIT_CONTRACT_BYTECODE = type(DepositContract).creationCode;

   
  
  address public wethTokenAddress;
  mapping(address => address payable) public registry;
  mapping(address => address) public versions;

  constructor(address _wethTokenAddress) public {
    wethTokenAddress = _wethTokenAddress;
  }

   
  function depositAddressOf(address owner) public view returns (address payable) {
    bytes32 codeHash = keccak256(_getCreationBytecode(owner));
    bytes32 addressHash = keccak256(abi.encodePacked(byte(0xff), address(this), uint256(owner), codeHash));
    return address(uint160(uint256(addressHash)));
  }

  function isDepositContractCreatedFor(address owner) public view returns (bool) {
    return registry[owner] != address(0x0);
  }

   
  function versionOf(address owner) public view returns (address) {
    return versions[owner];
  }

   
  function balanceOf(address owner, address token) public view returns (uint) {
    address depositAddress = depositAddressOf(owner);
    uint tokenBalance = IERC20(token).balanceOf(depositAddress);
    if (token == wethTokenAddress) tokenBalance = tokenBalance + depositAddress.balance;
    return tokenBalance;
  }

   
  function createDepositContract(Types.Request memory request) public {
    validateRequest(request);
    _createDepositContract(request.owner);
    _upgradeVersion(request);
  }

   
  function upgradeVersion(Types.Request memory request) public {
    validateRequest(request);
    _upgradeVersion(request);
  }

   
   

  function _payRequestFee(address owner, address feeToken, address feeRecipient, uint feeAmount) internal {
    DepositContract(registry[owner]).wrapAndTransferToken(feeToken, feeRecipient, feeAmount, wethTokenAddress);
  }

  function _getCreationBytecode(address owner) private view returns (bytes memory) {
    return abi.encodePacked(DEPOSIT_CONTRACT_BYTECODE, bytes12(0x000000000000000000000000), owner);
  }

  function _createDepositContract(address owner) private returns (address) {
    require(registry[owner] == address(0x0), "ALREADY_CREATED");

    address payable depositAddress;
    bytes memory code = _getCreationBytecode(owner);
    uint256 salt = uint256(owner);

    assembly {
      depositAddress := create2(0, add(code, 0x20), mload(code), salt)
      if iszero(extcodesize(depositAddress)) { revert(0, 0) }
    }

    emit CreatedDepositContract(owner, depositAddress);

    registry[owner] = depositAddress;
    return depositAddress;
  }

  function _upgradeVersion(Types.Request memory request) internal {
    require(registry[request.owner] != address(0x0), "NEEDS_CREATION");
    
    Types.UpdateRequest memory upgradeRequest = request.decodeUpdateRequest();
    address currentVersion = versions[request.owner];
    address payable depositAddress = registry[request.owner];

     
    if (currentVersion != address(0x0)) {
      IVersionable(currentVersion).versionEndUsage(
        request.owner,
        depositAddress,
        upgradeRequest.version,
        upgradeRequest.additionalData
      );
    }

     
    completeRequest(request);
    DepositContract(depositAddress).setVersion(upgradeRequest.version);
    versions[request.owner] = upgradeRequest.version;

     
    IVersionable(upgradeRequest.version).versionBeginUsage(
      request.owner,
      depositAddress,
      currentVersion,
      upgradeRequest.additionalData
    );

    emit UpgradedVersion(request.owner, depositAddress, upgradeRequest.version);
  }
}