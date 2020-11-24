 

pragma solidity >=0.4.16 <0.6.0;

 
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
        require(isOwner());
        _;
    }

     
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

 
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

     
    function add(Role storage role, address account) internal {
        require(account != address(0));
        require(!has(role, account));

        role.bearer[account] = true;
    }

     
    function remove(Role storage role, address account) internal {
        require(account != address(0));
        require(has(role, account));

        role.bearer[account] = false;
    }

     
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0));
        return role.bearer[account];
    }
}

contract MinterRole {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    constructor () internal {
        _addMinter(msg.sender);
    }

    modifier onlyMinter() {
        require(isMinter(msg.sender));
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    function addMinter(address account) public onlyMinter {
        _addMinter(account);
    }

    function renounceMinter() public {
        _removeMinter(msg.sender);
    }

    function _addMinter(address account) internal {
        _minters.add(account);
        emit MinterAdded(account);
    }

    function _removeMinter(address account) internal {
        _minters.remove(account);
        emit MinterRemoved(account);
    }
}

 
contract ReentrancyGuard {
     
    uint256 private _guardCounter;

    constructor () internal {
         
         
        _guardCounter = 1;
    }

     
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter);
    }
}

contract CertificateBase {

       
    mapping(address => bool) internal _certificateSigners;
    mapping(address => uint256) internal _checkCount;
    
    event Checked(address sender);
    
    constructor(address _certificateSigner) public {
        _setCertificateSigner(_certificateSigner, true);
    }
    
     
    function _setCertificateSigner(address operator, bool authorized) internal {
        require(operator != address(0), "Action Blocked - Not a valid address");
        _certificateSigners[operator] = authorized;
    }
    
    function _checkCertificate(bytes memory _data, bytes4 _function) internal view returns(bool) {
        bytes memory sig = _extractBytes(_data, 0, 65);     
        bytes memory expHex = _extractBytes(_data, 65, 4);  
        uint expUnix = _bytesToUint(expHex);                

        require(expUnix > now, 'Certificate Expired');
       
        bytes32 txHash = _getSignHash(_getPreSignedHash(_function, address(this), expUnix, _checkCount[msg.sender]));
       
        address recovered = _ecrecoverFromSig(txHash, sig);
          
        return _certificateSigners[recovered];
    }
    
    function _ecrecoverFromSig(bytes32 hash, bytes memory sig) internal pure returns (address recoveredAddress) 
    {
        bytes32 r;
        bytes32 s;
        uint8 v;
        if (sig.length != 65) return address(0);
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
        return ecrecover(hash, v, r, s);
    }
    
    function _getPreSignedHash(bytes4 _function, address _address, uint _expiration, uint _nonce) internal pure returns(bytes32) {
         return keccak256(abi.encodePacked(_function, _address, _expiration, _nonce));
    }
    
    function _getSignHash(bytes32 _hash) internal pure returns (bytes32)
    {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash));
    }
    
    function _getRecover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        return ecrecover(hash, v, r, s);
    }
    
    function getFunctionId(string calldata _function) external pure returns(bytes32) {
        return keccak256(abi.encodePacked(_function));
    }
    
    function _getStringHash(string memory _str) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_str));
    }
    
    function _extractBytes(bytes memory _data, uint _pos, uint _length) internal pure returns(bytes memory) {
        bytes memory result = new bytes(_length);
        for(uint i = 0;i< _length; i++) {
           result[i] = _data[_pos + i];
        }
        return result;
    }
    
    function _bytesToUint(bytes memory _data) internal pure returns(uint256){
        uint256 number;
        for(uint i=0;i<_data.length;i++){
            number = number + uint8(_data[i])*(2**(8*(_data.length-(i+1))));
        }
        return number;
    }
}

contract CertificateController is CertificateBase {

     
    modifier isValidCertificate(bytes memory data, bytes4 _functionId) {
        require(_certificateSigners[msg.sender] 
        || _checkCertificate(data, _functionId), "Transfer Blocked - Sender lockup period not ended");

        _checkCount[msg.sender] += 1;  

        emit Checked(msg.sender);
        _;
    }
    
    constructor(address _certificateSigner) public CertificateBase(_certificateSigner) {}
    
     
    function checkCount(address sender) external view returns (uint256) {
       return _checkCount[sender];
    }

     
    function certificateSigners(address operator) external view returns (bool) {
       return _certificateSigners[operator];
    }
}


 
interface IERC777TokensRecipient {

  function canReceive(
    bytes32 partition,
    address from,
    address to,
    uint value,
    bytes calldata data,
    bytes calldata operatorData
  ) external view returns(bool);

  function tokensReceived(
    bytes32 partition,
    address operator,
    address from,
    address to,
    uint value,
    bytes calldata data,
    bytes calldata operatorData
  ) external;

}

 
interface IERC777TokensSender {

  function canTransfer(
    bytes32 partition,
    address from,
    address to,
    uint value,
    bytes calldata data,
    bytes calldata operatorData
  ) external view returns(bool);

  function tokensToTransfer(
    bytes32 partition,
    address operator,
    address from,
    address to,
    uint value,
    bytes calldata data,
    bytes calldata operatorData
  ) external;

}


 
contract IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
interface IERC1410 {

     
    function balanceOfByPartition(bytes32 partition, address tokenHolder) external view returns (uint256);  
    function partitionsOf(address tokenHolder) external view returns (bytes32[] memory);  

     
    function transferByPartition(bytes32 partition, address to, uint256 value, bytes calldata data) external returns (bytes32);  
    function operatorTransferByPartition(bytes32 partition, address from, address to, uint256 value, bytes calldata data, bytes calldata operatorData) external returns (bytes32);  

     
    function getDefaultPartitions(address tokenHolder) external view returns (bytes32[] memory);  
    function setDefaultPartitions(bytes32[] calldata partitions) external;  

     
    function controllersByPartition(bytes32 partition) external view returns (address[] memory);  
    function authorizeOperatorByPartition(bytes32 partition, address operator) external;  
    function revokeOperatorByPartition(bytes32 partition, address operator) external;  
    function isOperatorForPartition(bytes32 partition, address operator, address tokenHolder) external view returns (bool);  

     
    event TransferByPartition(
        bytes32 indexed fromPartition,
        address operator,
        address indexed from,
        address indexed to,
        uint256 value,
        bytes data,
        bytes operatorData
    );

    event ChangedPartition(
        bytes32 indexed fromPartition,
        bytes32 indexed toPartition,
        uint256 value
    );

     
    event AuthorizedOperatorByPartition(bytes32 indexed partition, address indexed operator, address indexed tokenHolder);
    event RevokedOperatorByPartition(bytes32 indexed partition, address indexed operator, address indexed tokenHolder);

}


 
interface IERC777 {

  function name() external view returns (string memory);  
  function symbol() external view returns (string memory);  
  function totalSupply() external view returns (uint256);  
  function balanceOf(address owner) external view returns (uint256);  
  function granularity() external view returns (uint256);  

  function controllers() external view returns (address[] memory);  
  function authorizeOperator(address operator) external;  
  function revokeOperator(address operator) external;  
  function isOperatorFor(address operator, address tokenHolder) external view returns (bool);  

  function transferWithData(address to, uint256 value, bytes calldata data) external;  
  function transferFromWithData(address from, address to, uint256 value, bytes calldata data, bytes calldata operatorData) external;  

  function redeem(uint256 value, bytes calldata data) external;  
  function redeemFrom(address from, uint256 value, bytes calldata data, bytes calldata operatorData) external;  

  event TransferWithData(
    address indexed operator,
    address indexed from,
    address indexed to,
    uint256 value,
    bytes data,
    bytes operatorData
  );
  event Issued(address indexed operator, address indexed to, uint256 value, bytes data, bytes operatorData);
  event Redeemed(address indexed operator, address indexed from, uint256 value, bytes data, bytes operatorData);
  event AuthorizedOperator(address indexed operator, address indexed tokenHolder);
  event RevokedOperator(address indexed operator, address indexed tokenHolder);

}


 
interface IERC1400  {

     
    function getDocument(bytes32 name) external view returns (string memory, bytes32);  
    function setDocument(bytes32 name, string calldata uri, bytes32 documentHash) external;  
    event Document(bytes32 indexed name, string uri, bytes32 documentHash);

     
    function isControllable() external view returns (bool);  

     
    function isIssuable() external view returns (bool);  
    function issueByPartition(bytes32 partition, address tokenHolder, uint256 value, bytes calldata data) external;  
    event IssuedByPartition(bytes32 indexed partition, address indexed operator, address indexed to, uint256 value, bytes data, bytes operatorData);

     
    function redeemByPartition(bytes32 partition, uint256 value, bytes calldata data) external;  
    function operatorRedeemByPartition(bytes32 partition, address tokenHolder, uint256 value, bytes calldata data, bytes calldata operatorData) external;  
    event RedeemedByPartition(bytes32 indexed partition, address indexed operator, address indexed from, uint256 value, bytes data, bytes operatorData);

     
    function canTransferByPartition(bytes32 partition, address to, uint256 value, bytes calldata data) external view returns (byte, bytes32, bytes32);  
    function canOperatorTransferByPartition(bytes32 partition, address from, address to, uint256 value, bytes calldata data, bytes calldata operatorData) external view returns (byte, bytes32, bytes32);  

}

 


contract ERC820Registry {
    function setInterfaceImplementer(address _addr, bytes32 _interfaceHash, address _implementer) external;
    function getInterfaceImplementer(address _addr, bytes32 _interfaceHash) external view returns (address);
    function setManager(address _addr, address _newManager) external;
    function getManager(address _addr) public view returns(address);
}


 
contract ERC820Client {
    ERC820Registry constant ERC820REGISTRY = ERC820Registry(0x820b586C8C28125366C998641B09DCbE7d4cBF06);

    function setInterfaceImplementation(string memory _interfaceLabel, address _implementation) internal {
        bytes32 interfaceHash = keccak256(abi.encodePacked(_interfaceLabel));
        ERC820REGISTRY.setInterfaceImplementer(address(this), interfaceHash, _implementation);
    }

    function interfaceAddr(address addr, string memory _interfaceLabel) internal view returns(address) {
        bytes32 interfaceHash = keccak256(abi.encodePacked(_interfaceLabel));
        return ERC820REGISTRY.getInterfaceImplementer(addr, interfaceHash);
    }

    function delegateManagement(address _newManager) internal {
        ERC820REGISTRY.setManager(address(this), _newManager);
    }
}

 
contract ERC777 is IERC777, Ownable, ERC820Client, CertificateController, ReentrancyGuard {
  using SafeMath for uint256;

  string internal _name;
  string internal _symbol;
  uint256 internal _granularity;
  uint256 internal _totalSupply;

   
  bool internal _isControllable;

   
  mapping(address => uint256) internal _balances;

   
   
  mapping(address => mapping(address => bool)) internal _authorizedOperator;

   
  address[] internal _controllers;

   
  mapping(address => bool) internal _isController;
   

   
  constructor(
    string memory name,
    string memory symbol,
    uint256 granularity,
    address[] memory controllers,
    address certificateSigner
  )
    public
    CertificateController(certificateSigner)
  {
    _name = name;
    _symbol = symbol;
    _totalSupply = 0;
    require(granularity >= 1, "Constructor Blocked - Token granularity can not be lower than 1");
    _granularity = granularity;

    _setControllers(controllers);

    setInterfaceImplementation("ERC777Token", address(this));
  }

   

   
  function name() external view returns(string memory) {
    return _name;
  }

   
  function symbol() external view returns(string memory) {
    return _symbol;
  }

   
  function totalSupply() external view returns (uint256) {
    return _totalSupply;
  }

   
  function balanceOf(address tokenHolder) external view returns (uint256) {
    return _balances[tokenHolder];
  }

   
  function granularity() external view returns(uint256) {
    return _granularity;
  }

   
  function controllers() external view returns (address[] memory) {
    return _controllers;
  }

   
  function authorizeOperator(address operator) external {
    _authorizedOperator[operator][msg.sender] = true;
    emit AuthorizedOperator(operator, msg.sender);
  }

   
  function revokeOperator(address operator) external {
    _authorizedOperator[operator][msg.sender] = false;
    emit RevokedOperator(operator, msg.sender);
  }

   
  function isOperatorFor(address operator, address tokenHolder) external view returns (bool) {
    return _isOperatorFor(operator, tokenHolder);
  }

   
  function transferWithData(address to, uint256 value, bytes calldata data)
    external
    isValidCertificate(data, 0x2535f762)
  {
    _transferWithData("", msg.sender, msg.sender, to, value, data, "", true);
  }

   
  function transferFromWithData(address from, address to, uint256 value, bytes calldata data, bytes calldata operatorData)
    external
    isValidCertificate(operatorData, 0x868d5383)
  {
    address _from = (from == address(0)) ? msg.sender : from;

    require(_isOperatorFor(msg.sender, _from), "A7: Transfer Blocked - Identity restriction");

    _transferWithData("", msg.sender, _from, to, value, data, operatorData, true);
  }

   
  function redeem(uint256 value, bytes calldata data)
    external
    isValidCertificate(data, 0xe77c646d)
  {
    _redeem("", msg.sender, msg.sender, value, data, "");
  }

   
  function redeemFrom(address from, uint256 value, bytes calldata data, bytes calldata operatorData)
    external
    isValidCertificate(operatorData, 0xffa90f7f)
  {
    address _from = (from == address(0)) ? msg.sender : from;

    require(_isOperatorFor(msg.sender, _from), "A7: Transfer Blocked - Identity restriction");

    _redeem("", msg.sender, _from, value, data, operatorData);
  }

   

   
  function _isMultiple(uint256 value) internal view returns(bool) {
    return(value.div(_granularity).mul(_granularity) == value);
  }

   
  function _isRegularAddress(address addr) internal view returns(bool) {
    if (addr == address(0)) { return false; }
    uint size;
    assembly { size := extcodesize(addr) }  
    return size == 0;
  }

   
  function _isOperatorFor(address operator, address tokenHolder) internal view returns (bool) {
    return (operator == tokenHolder
      || _authorizedOperator[operator][tokenHolder]
      || (_isControllable && _isController[operator])
    );
  }

    
  function _transferWithData(
    bytes32 partition,
    address operator,
    address from,
    address to,
    uint256 value,
    bytes memory data,
    bytes memory operatorData,
    bool preventLocking
  )
    internal
    nonReentrant
  {
    require(_isMultiple(value), "A9: Transfer Blocked - Token granularity");
    require(to != address(0), "A6: Transfer Blocked - Receiver not eligible");
    require(_balances[from] >= value, "A4: Transfer Blocked - Sender balance insufficient");

    _callSender(partition, operator, from, to, value, data, operatorData);

    _balances[from] = _balances[from].sub(value);
    _balances[to] = _balances[to].add(value);

    _callRecipient(partition, operator, from, to, value, data, operatorData, preventLocking);

    emit TransferWithData(operator, from, to, value, data, operatorData);
  }

   
  function _redeem(
    bytes32 partition, 
    address operator, 
    address from, 
    uint256 value, 
    bytes memory data, 
    bytes memory operatorData
  )
    internal
    nonReentrant
  {
    require(_isMultiple(value), "A9: Transfer Blocked - Token granularity");
    require(from != address(0), "A5: Transfer Blocked - Sender not eligible");
    require(_balances[from] >= value, "A4: Transfer Blocked - Sender balance insufficient");

    _callSender(partition, operator, from, address(0), value, data, operatorData);

    _balances[from] = _balances[from].sub(value);
    _totalSupply = _totalSupply.sub(value);

    emit Redeemed(operator, from, value, data, operatorData);
  }

   
  function _callSender(
    bytes32 partition,
    address operator,
    address from,
    address to,
    uint256 value,
    bytes memory data,
    bytes memory operatorData
  )
    internal
  {
    address senderImplementation;
    senderImplementation = interfaceAddr(from, "ERC777TokensSender");

    if (senderImplementation != address(0)) {
      IERC777TokensSender(senderImplementation).tokensToTransfer(partition, operator, from, to, value, data, operatorData);
    }
  }

   
  function _callRecipient(
    bytes32 partition,
    address operator,
    address from,
    address to,
    uint256 value,
    bytes memory data,
    bytes memory operatorData,
    bool preventLocking
  )
    internal
  {
    address recipientImplementation;
    recipientImplementation = interfaceAddr(to, "ERC777TokensRecipient");

    if (recipientImplementation != address(0)) {
      IERC777TokensRecipient(recipientImplementation).tokensReceived(partition, operator, from, to, value, data, operatorData);
    } else if (preventLocking) {
      require(_isRegularAddress(to), "A6: Transfer Blocked - Receiver not eligible");
    }
  }

   
  function _issue(
    bytes32 partition, 
    address operator, 
    address to, 
    uint256 value, 
    bytes memory data, 
    bytes memory operatorData
  ) 
    internal nonReentrant   
  {
    require(_isMultiple(value), "A9: Transfer Blocked - Token granularity");
    require(to != address(0), "A6: Transfer Blocked - Receiver not eligible");

    _totalSupply = _totalSupply.add(value);
    _balances[to] = _balances[to].add(value);

    _callRecipient(partition, operator, address(0), to, value, data, operatorData, true);

    emit Issued(operator, to, value, data, operatorData);
  }

   

   
  function _setControllers(address[] memory operators) internal {
    for (uint i = 0; i<_controllers.length; i++){
      _isController[_controllers[i]] = false;
    }
    for (uint j = 0; j<operators.length; j++){
      _isController[operators[j]] = true;
    }
    _controllers = operators;
  }

}

 
contract ERC1410 is IERC1410, ERC777{

   
   
  bytes32[] internal _totalPartitions;

   
  mapping (bytes32 => uint256) internal _totalSupplyByPartition;

   
  mapping (address => bytes32[]) internal _partitionsOf;

   
  mapping (address => mapping (bytes32 => uint256)) internal _balanceOfByPartition;

   
  mapping (address => bytes32[]) internal _defaultPartitionsOf;

   
  bytes32[] internal _tokenDefaultPartitions;
   

   
   
  mapping (address => mapping (bytes32 => mapping (address => bool))) internal _authorizedOperatorByPartition;

   
  mapping (bytes32 => address[]) internal _controllersByPartition;

   
  mapping (bytes32 => mapping (address => bool)) internal _isControllerByPartition;
   

   
  constructor(
    string memory name,
    string memory symbol,
    uint256 granularity,
    address[] memory controllers,
    address certificateSigner,
    bytes32[] memory tokenDefaultPartitions
  )
    public
    ERC777(name, symbol, granularity, controllers, certificateSigner)
  {
    _tokenDefaultPartitions = tokenDefaultPartitions;
  }

   

   
  function balanceOfByPartition(bytes32 partition, address tokenHolder) external view returns (uint256) {
    return _balanceOfByPartition[tokenHolder][partition];
  }

   
  function partitionsOf(address tokenHolder) external view returns (bytes32[] memory) {
    return _partitionsOf[tokenHolder];
  }

   
  function transferByPartition(
    bytes32 partition,
    address to,
    uint256 value,
    bytes calldata data
  )
    external
    isValidCertificate(data, 0xf3d490db)
    returns (bytes32)
  {
    return _transferByPartition(partition, msg.sender, msg.sender, to, value, data, "");
  }

   
  function operatorTransferByPartition(
    bytes32 partition,
    address from,
    address to,
    uint256 value,
    bytes calldata data,
    bytes calldata operatorData
  )
    external
    isValidCertificate(operatorData, 0x8c0dee9c)
    returns (bytes32)
  {
    address _from = (from == address(0)) ? msg.sender : from;
    require(_isOperatorForPartition(partition, msg.sender, _from), "A7: Transfer Blocked - Identity restriction");

    return _transferByPartition(partition, msg.sender, _from, to, value, data, operatorData);
  }

   
  function getDefaultPartitions(address tokenHolder) external view returns (bytes32[] memory) {
    return _defaultPartitionsOf[tokenHolder];
  }

   
  function setDefaultPartitions(bytes32[] calldata partitions) external {
    _defaultPartitionsOf[msg.sender] = partitions;
  }

   
  function controllersByPartition(bytes32 partition) external view returns (address[] memory) {
    return _controllersByPartition[partition];
  }

   
  function authorizeOperatorByPartition(bytes32 partition, address operator) external {
    _authorizedOperatorByPartition[msg.sender][partition][operator] = true;
    emit AuthorizedOperatorByPartition(partition, operator, msg.sender);
  }

   
  function revokeOperatorByPartition(bytes32 partition, address operator) external {
    _authorizedOperatorByPartition[msg.sender][partition][operator] = false;
    emit RevokedOperatorByPartition(partition, operator, msg.sender);
  }

   
  function isOperatorForPartition(bytes32 partition, address operator, address tokenHolder) external view returns (bool) {
    return _isOperatorForPartition(partition, operator, tokenHolder);
  }

   

   
   function _isOperatorForPartition(bytes32 partition, address operator, address tokenHolder) internal view returns (bool) {
     return (_isOperatorFor(operator, tokenHolder)
       || _authorizedOperatorByPartition[tokenHolder][partition][operator]
       || (_isControllable && _isControllerByPartition[partition][operator])
     );
   }

   
  function _transferByPartition(
    bytes32 fromPartition,
    address operator,
    address from,
    address to,
    uint256 value,
    bytes memory data,
    bytes memory operatorData
  )
    internal
    returns (bytes32)
  {
     
    require(_balanceOfByPartition[from][fromPartition] >= value, "A4: Transfer Blocked - Sender balance insufficient"); 
    
    bytes32 toPartition = fromPartition;

    if(operatorData.length != 0 && data.length != 0) {
      toPartition = _getDestinationPartition(fromPartition, data);
    }

    _removeTokenFromPartition(from, fromPartition, value);
    _transferWithData(fromPartition, operator, from, to, value, data, operatorData, true);
    _addTokenToPartition(to, toPartition, value);

    emit TransferByPartition(fromPartition, operator, from, to, value, data, operatorData);

    if(toPartition != fromPartition) {
      emit ChangedPartition(fromPartition, toPartition, value);
    }

    return toPartition;
  }

   
  function _removeTokenFromPartition(address from, bytes32 partition, uint256 value) internal {
    _balanceOfByPartition[from][partition] = _balanceOfByPartition[from][partition].sub(value);
    _totalSupplyByPartition[partition] = _totalSupplyByPartition[partition].sub(value);

     
    if(_balanceOfByPartition[from][partition] == 0) {
      for (uint i = 0; i < _partitionsOf[from].length; i++) {
        if(_partitionsOf[from][i] == partition) {
          _partitionsOf[from][i] = _partitionsOf[from][_partitionsOf[from].length - 1];
          delete _partitionsOf[from][_partitionsOf[from].length - 1];
          _partitionsOf[from].length--;
          break;
        }
      }
    }

     
    if(_totalSupplyByPartition[partition] == 0) {
      for (uint i = 0; i < _totalPartitions.length; i++) {
        if(_totalPartitions[i] == partition) {
          _totalPartitions[i] = _totalPartitions[_totalPartitions.length - 1];
          delete _totalPartitions[_totalPartitions.length - 1];
          _totalPartitions.length--;
          break;
        }
      }
    }
  }

   
  function _addTokenToPartition(address to, bytes32 partition, uint256 value) internal {
    if(value != 0) {
      if(_balanceOfByPartition[to][partition] == 0) {
        _partitionsOf[to].push(partition);
      }
      _balanceOfByPartition[to][partition] = _balanceOfByPartition[to][partition].add(value);

      if(_totalSupplyByPartition[partition] == 0) {
        _totalPartitions.push(partition);
      }
      _totalSupplyByPartition[partition] = _totalSupplyByPartition[partition].add(value);
    }
  }

   
  function _getDestinationPartition(bytes32 fromPartition, bytes memory data) internal pure returns(bytes32 toPartition) {
    bytes32 changePartitionFlag = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    bytes32 flag;
    assembly {
      flag := mload(add(data, 32))
    }
    if(flag == changePartitionFlag) {
      assembly {
        toPartition := mload(add(data, 64))
      }
    } else {
      toPartition = fromPartition;
    }
  }

   
  function _getDefaultPartitions(address tokenHolder) internal view returns(bytes32[] memory) {
    if(_defaultPartitionsOf[tokenHolder].length != 0) {
      return _defaultPartitionsOf[tokenHolder];
    } else {
      return _tokenDefaultPartitions;
    }
  }


   

   
  function totalPartitions() external view returns (bytes32[] memory) {
    return _totalPartitions;
  }

   
   function _setPartitionControllers(bytes32 partition, address[] memory operators) internal {
     for (uint i = 0; i<_controllersByPartition[partition].length; i++){
       _isControllerByPartition[partition][_controllersByPartition[partition][i]] = false;
     }
     for (uint j = 0; j<operators.length; j++){
       _isControllerByPartition[partition][operators[j]] = true;
     }
     _controllersByPartition[partition] = operators;
   }
}


 
contract ERC1400 is IERC1400, ERC1410, MinterRole {

  struct Doc {
    string docURI;
    bytes32 docHash;
  }

   
  mapping(bytes32 => Doc) internal _documents;

   
  bool internal _isIssuable;

   
  modifier issuableToken() {
    require(_isIssuable, "A8, Transfer Blocked - Token restriction");
    _;
  }

   
  constructor(
    string memory name,
    string memory symbol,
    uint256 granularity,
    address[] memory controllers,
    address certificateSigner,
    bytes32[] memory tokenDefaultPartitions
  )
    public
    ERC1410(name, symbol, granularity, controllers, certificateSigner, tokenDefaultPartitions)
  {
    setInterfaceImplementation("ERC1400Token", address(this));
    _isControllable = true;
    _isIssuable = true;
  }

   

   
  function getDocument(bytes32 name) external view returns (string memory, bytes32) {
    require(bytes(_documents[name].docURI).length != 0, "Action Blocked - Empty document");
    return (
      _documents[name].docURI,
      _documents[name].docHash
    );
  }

   
  function setDocument(bytes32 name, string calldata uri, bytes32 documentHash) external onlyOwner {
    _documents[name] = Doc({
      docURI: uri,
      docHash: documentHash
    });
    emit Document(name, uri, documentHash);
  }

   
  function isControllable() external view returns (bool) {
    return _isControllable;
  }

   
  function isIssuable() external view returns (bool) {
    return _isIssuable;
  }

   
  function issueByPartition(bytes32 partition, address tokenHolder, uint256 value, bytes calldata data)
    external
    onlyMinter
    issuableToken
    isValidCertificate(data, 0x67c84919)
  {
    _issueByPartition(partition, msg.sender, tokenHolder, value, data, "");
  }

   
  function redeemByPartition(bytes32 partition, uint256 value, bytes calldata data)
    external
    isValidCertificate(data, 0x62eb0068)
  {
    _redeemByPartition(partition, msg.sender, msg.sender, value, data, "");
  }

   
  function operatorRedeemByPartition(
    bytes32 partition, 
    address tokenHolder, 
    uint256 value, 
    bytes calldata data, 
    bytes calldata operatorData
  )
    external
    isValidCertificate(operatorData, 0x13d557bc)
  {
    address _from = (tokenHolder == address(0)) ? msg.sender : tokenHolder;
    require(_isOperatorForPartition(partition, msg.sender, _from), "A7: Transfer Blocked - Identity restriction");

    _redeemByPartition(partition, msg.sender, _from, value, data, operatorData);
  }

   
  function canTransferByPartition(bytes32 partition, address to, uint256 value, bytes calldata data)
    external
    view
    returns (byte, bytes32, bytes32)
  {
    if(!_checkCertificate(data, 0xf3d490db)) {  
      return(hex"A3", "", partition);  
    } else {
      return _canTransfer(partition, msg.sender, msg.sender, to, value, data, "");
    }
  }

   
  function canOperatorTransferByPartition(
    bytes32 partition, 
    address from, 
    address to, 
    uint256 value, 
    bytes calldata data, 
    bytes calldata operatorData
  )
    external
    view
    returns (byte, bytes32, bytes32)
  {
     
    if(!_checkCertificate(operatorData, 0x8c0dee9c)) { 
      return(hex"A3", "", partition);  
    } else {
      address _from = (from == address(0)) ? msg.sender : from;
      return _canTransfer(partition, msg.sender, _from, to, value, data, operatorData);
    }
  }

   

   
   function _canTransfer(
     bytes32 partition, 
     address operator, 
     address from, 
     address to, 
     uint256 value, 
     bytes memory data, 
     bytes memory operatorData
   )
     internal
     view
     returns (byte, bytes32, bytes32)
   {
     if(!_isOperatorForPartition(partition, operator, from))
       return(hex"A7", "", partition); // "Transfer Blocked - Identity restriction"

     if((_balances[from] < value) || (_balanceOfByPartition[from][partition] < value))
       return(hex"A4", "", partition);  

     if(to == address(0))
       return(hex"A6", "", partition);  

     address senderImplementation;
     address recipientImplementation;
     senderImplementation = interfaceAddr(from, "ERC777TokensSender");
     recipientImplementation = interfaceAddr(to, "ERC777TokensRecipient");

     if((senderImplementation != address(0))
       && !IERC777TokensSender(senderImplementation).canTransfer(partition, from, to, value, data, operatorData))
       return(hex"A5", "", partition);  

     if((recipientImplementation != address(0))
       && !IERC777TokensRecipient(recipientImplementation).canReceive(partition, from, to, value, data, operatorData))
       return(hex"A6", "", partition);  

     if(!_isMultiple(value))
       return(hex"A9", "", partition);  

     return(hex"A2", "", partition);   
   }

   
  function _issueByPartition(
    bytes32 toPartition,
    address operator,
    address to,
    uint256 value,
    bytes memory data,
    bytes memory operatorData
  )
    internal
  {
    _issue(toPartition, operator, to, value, data, operatorData);
    _addTokenToPartition(to, toPartition, value);

    emit IssuedByPartition(toPartition, operator, to, value, data, operatorData);
  }

   
  function _redeemByPartition(
    bytes32 fromPartition,
    address operator,
    address from,
    uint256 value,
    bytes memory data,
    bytes memory operatorData
  )
    internal
  {
    require(_balanceOfByPartition[from][fromPartition] >= value, "A4: Transfer Blocked - Sender balance insufficient");

    _removeTokenFromPartition(from, fromPartition, value);
    _redeem(fromPartition, operator, from, value, data, operatorData);

    emit RedeemedByPartition(fromPartition, operator, from, value, data, operatorData);
  }

   

   
  function renounceControl() external onlyOwner {
    _isControllable = false;
  }

   
  function renounceIssuance() external onlyOwner {
    _isIssuable = false;
  }

   
  function setControllers(address[] calldata operators) external onlyOwner {
    _setControllers(operators);
  }

   
   function setPartitionControllers(bytes32 partition, address[] calldata operators) external onlyOwner {
     _setPartitionControllers(partition, operators);
   }

    
  function setCertificateSigner(address operator, bool authorized) external onlyOwner {
    _setCertificateSigner(operator, authorized);
  }

   

   
  function getTokenDefaultPartitions() external view returns (bytes32[] memory) {
    return _tokenDefaultPartitions;
  }

   
  function setTokenDefaultPartitions(bytes32[] calldata defaultPartitions) external onlyOwner {
    _tokenDefaultPartitions = defaultPartitions;
  }
}

 
contract CPITech is ERC1400 {

   
  mapping (bytes32 => mapping (address => bool)) internal _whitelistedByPartition;
   
  mapping (bytes32 => mapping (address => uint)) _issuedDatesByPartition;
   
  mapping (bytes32 => mapping (bytes32 => bool)) _transferRulesByPartition;
  
  uint private _lockPeriod = 3600 * 24 * 365;  

   
  modifier isWhitelistedByParition(bytes32 partition, address recipient) {
    require(_whitelistedByPartition[partition][recipient], "A3: Transfer Blocked - Recipient not whitelisted");
    _;
  }
  
   
  modifier isLockedByPartition(bytes32 partition, address tokenHolder) {
    require((_isControllable && _isController[msg.sender])
        || (_isControllable && _isControllerByPartition[partition][msg.sender])
        || ((_issuedDatesByPartition[partition][tokenHolder] + _lockPeriod) >= now), 
        "A3: Transfer Blocked - Sender lockup period not ended");
    _;
  }
  
   
  constructor(
    string memory name,
    string memory symbol,
    uint256 granularity,
    address[] memory controllers,
    address certificateSigner,
    bytes32[] memory tokenDefaultPartitions
  )
    public
    ERC1400(name, symbol, granularity, controllers, certificateSigner, tokenDefaultPartitions)
  {
  }
  
   
  function transferRuleByPartition(bytes32 fromPartition, bytes32 toParition) external view returns(bool) {
    return _transferRulesByPartition[fromPartition][toParition];
  }
  
   
  function setTransferRulesByPartition(
    bytes32[] calldata fromPartitions, 
    bytes32[] calldata toPartitions, 
    bool[] calldata rules
  ) 
   external onlyOwner
  {
    _setTransferRulesByPartition(fromPartitions, toPartitions, rules);
  }
  
   
   function _setTransferRulesByPartition(
     bytes32[] memory fromPartitions, 
     bytes32[] memory toPartitions, 
     bool[] memory rules
   ) 
     internal 
   {
     require(fromPartitions.length == toPartitions.length && toPartitions.length == rules.length, 
     "Action Blocked - Not valid  transfer rules");
     
     for (uint i = 0; i<fromPartitions.length; i++){
       _transferRulesByPartition[fromPartitions[i]][toPartitions[i]] = rules[i];
     }
   }
  
   
  function whitelistedByPartition(bytes32 partition, address tokenHolder) external view returns (bool) {
    return _whitelistedByPartition[partition][tokenHolder];
  }

   
  function setWhitelistedByPartition(bytes32 partition, address tokenHolder, bool authorized) external {
    require((_isControllable && _isController[msg.sender])
        || (_isControllable && _isControllerByPartition[partition][msg.sender]), 
        "Action Blocked - Not a valid controller");
    
    _setWhitelistedByPartition(partition, tokenHolder, authorized);
  }

   
  function _setWhitelistedByPartition(bytes32 partition, address tokenHolder, bool authorized) internal {
    require(tokenHolder != address(0), "Action Blocked - Not a valid address");
    if(_whitelistedByPartition[partition][tokenHolder] != authorized) {
        _whitelistedByPartition[partition][tokenHolder] = authorized;
    }
  }
  
   
  function _setIssuedDateByPartition(bytes32 partition, address tokenHolder) internal {
    require(tokenHolder != address(0), "Action Blocked - Not a valid address");
    if(_issuedDatesByPartition[partition][tokenHolder] == 0) {
        _issuedDatesByPartition[partition][tokenHolder] = now;
    }
  }
  
   
  function _transferWithData(
    bytes32 partition,
    address operator,
    address from,
    address to,
    uint256 value,
    bytes memory data,
    bytes memory operatorData,
    bool preventLocking
  )
    internal
    isWhitelistedByParition(partition, to)
    isLockedByPartition(partition, from)
  {
    bytes32 fromPartition = partition;
    bytes32 toPartition = partition;
    
    if(operatorData.length != 0 && data.length != 0) {
      toPartition = _getDestinationPartition(fromPartition, data);
    }
    
    if(toPartition != fromPartition) {
       require(((_isControllable && _isController[from]) || (_isControllable && _isControllerByPartition[fromPartition][from]))
        && (_transferRulesByPartition[fromPartition][toPartition]), "Action Blocked - Not a valid transfer rule");
    }
    
    ERC777._transferWithData(partition, operator, from, to, value, data, operatorData, preventLocking);
  }
  
   
  function _issue(
    bytes32 partition, 
    address operator, 
    address to, 
    uint256 value, 
    bytes memory data, 
    bytes memory operatorData
  ) 
    internal 
  {
    ERC777._issue(partition, operator, to, value, data, operatorData);

    _setWhitelistedByPartition(partition, to, true);
    _setIssuedDateByPartition(partition, to);
  }
}