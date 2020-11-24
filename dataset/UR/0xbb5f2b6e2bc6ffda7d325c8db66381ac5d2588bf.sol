 

pragma solidity ^0.4.24;

 

 
 
 
 
contract Database{

     
    mapping(bytes32 => uint) public uintStorage;
    mapping(bytes32 => string) public stringStorage;
    mapping(bytes32 => address) public addressStorage;
    mapping(bytes32 => bytes) public bytesStorage;
    mapping(bytes32 => bytes32) public bytes32Storage;
    mapping(bytes32 => bool) public boolStorage;
    mapping(bytes32 => int) public intStorage;



     
     
    constructor(address[] _owners, bool _upgradeable)
    public {
      for(uint i=0; i<_owners.length; i++){
        require(_owners[i] != address(0), "Empty address");
        boolStorage[keccak256(abi.encodePacked("owner", _owners[i]))] = true;
        emit LogInitialized(_owners[i], _upgradeable);
      }
      if (_upgradeable){
        boolStorage[keccak256("upgradeable")] = true;
      }
    }

     
     
    function enableContractManagement(address _contractManager)
    external
    returns (bool){
        require(_contractManager != address(0), "Empty address");
        require(boolStorage[keccak256(abi.encodePacked("owner", msg.sender))], "Not owner");
        require(addressStorage[keccak256(abi.encodePacked("contract", "ContractManager"))] == address(0), "There is already a contract manager");
        addressStorage[keccak256(abi.encodePacked("contract", "ContractManager"))] = _contractManager;
        boolStorage[keccak256(abi.encodePacked("contract", _contractManager))] = true;
        return true;
    }

     
    function setAddress(bytes32 _key, address _value)
    onlyApprovedContract
    external {
        addressStorage[_key] = _value;
    }

    function setUint(bytes32 _key, uint _value)
    onlyApprovedContract
    external {
        uintStorage[_key] = _value;
    }

    function setString(bytes32 _key, string _value)
    onlyApprovedContract
    external {
        stringStorage[_key] = _value;
    }

    function setBytes(bytes32 _key, bytes _value)
    onlyApprovedContract
    external {
        bytesStorage[_key] = _value;
    }

    function setBytes32(bytes32 _key, bytes32 _value)
    onlyApprovedContract
    external {
        bytes32Storage[_key] = _value;
    }

    function setBool(bytes32 _key, bool _value)
    onlyApprovedContract
    external {
        boolStorage[_key] = _value;
    }

    function setInt(bytes32 _key, int _value)
    onlyApprovedContract
    external {
        intStorage[_key] = _value;
    }


     
    function deleteAddress(bytes32 _key)
    onlyApprovedContract
    external {
        delete addressStorage[_key];
    }

    function deleteUint(bytes32 _key)
    onlyApprovedContract
    external {
        delete uintStorage[_key];
    }

    function deleteString(bytes32 _key)
    onlyApprovedContract
    external {
        delete stringStorage[_key];
    }

    function deleteBytes(bytes32 _key)
    onlyApprovedContract
    external {
        delete bytesStorage[_key];
    }

    function deleteBytes32(bytes32 _key)
    onlyApprovedContract
    external {
        delete bytes32Storage[_key];
    }

    function deleteBool(bytes32 _key)
    onlyApprovedContract
    external {
        delete boolStorage[_key];
    }

    function deleteInt(bytes32 _key)
    onlyApprovedContract
    external {
        delete intStorage[_key];
    }


     
     
     

     
    modifier onlyApprovedContract() {
        require(boolStorage[keccak256(abi.encodePacked("contract", msg.sender))]);
        _;
    }

     
     
     
    event LogInitialized(address _owner, bool _upgradeable);
}

 

 
interface DBInterface {

  function setContractManager(address _contractManager)
  external;

     

    function setAddress(bytes32 _key, address _value)
    external;

    function setUint(bytes32 _key, uint _value)
    external;

    function setString(bytes32 _key, string _value)
    external;

    function setBytes(bytes32 _key, bytes _value)
    external;

    function setBytes32(bytes32 _key, bytes32 _value)
    external;

    function setBool(bytes32 _key, bool _value)
    external;

    function setInt(bytes32 _key, int _value)
    external;


      

    function deleteAddress(bytes32 _key)
    external;

    function deleteUint(bytes32 _key)
    external;

    function deleteString(bytes32 _key)
    external;

    function deleteBytes(bytes32 _key)
    external;

    function deleteBytes32(bytes32 _key)
    external;

    function deleteBool(bytes32 _key)
    external;

    function deleteInt(bytes32 _key)
    external;

     

    function uintStorage(bytes32 _key)
    external
    view
    returns (uint);

    function stringStorage(bytes32 _key)
    external
    view
    returns (string);

    function addressStorage(bytes32 _key)
    external
    view
    returns (address);

    function bytesStorage(bytes32 _key)
    external
    view
    returns (bytes);

    function bytes32Storage(bytes32 _key)
    external
    view
    returns (bytes32);

    function boolStorage(bytes32 _key)
    external
    view
    returns (bool);

    function intStorage(bytes32 _key)
    external
    view
    returns (bool);
}

 

contract Events {
  DBInterface public database;

  constructor(address _database) public{
    database = DBInterface(_database);
  }

  function message(string _message)
  external
  onlyApprovedContract {
      emit LogEvent(_message, keccak256(abi.encodePacked(_message)), tx.origin);
  }

  function transaction(string _message, address _from, address _to, uint _amount, address _token)
  external
  onlyApprovedContract {
      emit LogTransaction(_message, keccak256(abi.encodePacked(_message)), _from, _to, _amount, _token, tx.origin);
  }

  function registration(string _message, address _account)
  external
  onlyApprovedContract {
      emit LogAddress(_message, keccak256(abi.encodePacked(_message)), _account, tx.origin);
  }

  function contractChange(string _message, address _account, string _name)
  external
  onlyApprovedContract {
      emit LogContractChange(_message, keccak256(abi.encodePacked(_message)), _account, _name, tx.origin);
  }

  function asset(string _message, string _uri, address _assetAddress, address _manager)
  external
  onlyApprovedContract {
      emit LogAsset(_message, keccak256(abi.encodePacked(_message)), _uri, keccak256(abi.encodePacked(_uri)), _assetAddress, _manager, tx.origin);
  }

  function escrow(string _message, address _assetAddress, bytes32 _escrowID, address _manager, uint _amount)
  external
  onlyApprovedContract {
      emit LogEscrow(_message, keccak256(abi.encodePacked(_message)), _assetAddress, _escrowID, _manager, _amount, tx.origin);
  }

  function order(string _message, bytes32 _orderID, uint _amount, uint _price)
  external
  onlyApprovedContract {
      emit LogOrder(_message, keccak256(abi.encodePacked(_message)), _orderID, _amount, _price, tx.origin);
  }

  function exchange(string _message, bytes32 _orderID, address _assetAddress, address _account)
  external
  onlyApprovedContract {
      emit LogExchange(_message, keccak256(abi.encodePacked(_message)), _orderID, _assetAddress, _account, tx.origin);
  }

  function operator(string _message, bytes32 _id, string _name, string _ipfs, address _account)
  external
  onlyApprovedContract {
      emit LogOperator(_message, keccak256(abi.encodePacked(_message)), _id, _name, _ipfs, _account, tx.origin);
  }

  function consensus(string _message, bytes32 _executionID, bytes32 _votesID, uint _votes, uint _tokens, uint _quorum)
  external
  onlyApprovedContract {
    emit LogConsensus(_message, keccak256(abi.encodePacked(_message)), _executionID, _votesID, _votes, _tokens, _quorum, tx.origin);
  }

   
  event LogEvent(string message, bytes32 indexed messageID, address indexed origin);
  event LogTransaction(string message, bytes32 indexed messageID, address indexed from, address indexed to, uint amount, address token, address origin);  
  event LogAddress(string message, bytes32 indexed messageID, address indexed account, address indexed origin);
  event LogContractChange(string message, bytes32 indexed messageID, address indexed account, string name, address indexed origin);
  event LogAsset(string message, bytes32 indexed messageID, string uri, bytes32 indexed assetID, address asset, address manager, address indexed origin);
  event LogEscrow(string message, bytes32 indexed messageID, address asset, bytes32  escrowID, address indexed manager, uint amount, address indexed origin);
  event LogOrder(string message, bytes32 indexed messageID, bytes32 indexed orderID, uint amount, uint price, address indexed origin);
  event LogExchange(string message, bytes32 indexed messageID, bytes32 orderID, address indexed asset, address account, address indexed origin);
  event LogOperator(string message, bytes32 indexed messageID, bytes32 id, string name, string ipfs, address indexed account, address indexed origin);
  event LogConsensus(string message, bytes32 indexed messageID, bytes32 executionID, bytes32 votesID, uint votes, uint tokens, uint quorum, address indexed origin);


   
   
   
  modifier onlyApprovedContract() {
      require(database.boolStorage(keccak256(abi.encodePacked("contract", msg.sender))));
      _;
  }

}

 

contract Operators {

  Database public database;
  Events public events;

  constructor(address _database, address _events) public {
    database = Database(_database);
    events = Events(_events);
  }

   
   
  function registerOperator(address _operatorAddress, string _operatorURI, string _ipfs, address _referrerAddress)
  external
  onlyOwner {
    require(_operatorAddress != address(0));
    bytes32 operatorID = keccak256(abi.encodePacked("operator.uri", _operatorURI));
    require(database.addressStorage(keccak256(abi.encodePacked("operator", operatorID))) == address(0));
    database.setBytes32(keccak256(abi.encodePacked("operator", _operatorAddress)), operatorID);
    database.setAddress(keccak256(abi.encodePacked("operator", operatorID)), _operatorAddress);
    database.setString(keccak256(abi.encodePacked("operator.ipfs", operatorID)), _ipfs);
    if(_referrerAddress == address(0)){
      database.setAddress(keccak256(abi.encodePacked("referrer", operatorID)), database.addressStorage(keccak256(abi.encodePacked("platform.wallet.assets"))));
    } else {
      database.setAddress(keccak256(abi.encodePacked("referrer", operatorID)), _referrerAddress);
    }

    events.operator('Operator registered', operatorID, _operatorURI, _ipfs, _operatorAddress);
  }

   
  function removeOperator(bytes32 _operatorID)
  external {
    address operatorAddress = database.addressStorage(keccak256(abi.encodePacked("operator", _operatorID)));
    require(database.boolStorage(keccak256(abi.encodePacked("owner", msg.sender))) || msg.sender == operatorAddress);
    database.deleteBytes32(keccak256(abi.encodePacked("operator", operatorAddress)));
    database.deleteAddress(keccak256(abi.encodePacked("operator", _operatorID)));
    database.deleteAddress(keccak256(abi.encodePacked("referrer", _operatorID)));
    events.operator('Operator removed', _operatorID, '', '', msg.sender);
  }


   
  function changeOperatorAddress(bytes32 _operatorID, address _newAddress)
  external {
    address oldAddress = database.addressStorage(keccak256(abi.encodePacked("operator", _operatorID)));
    require(oldAddress != address(0));
    require(msg.sender == oldAddress || database.boolStorage(keccak256(abi.encodePacked("owner", msg.sender))));
    database.setAddress(keccak256(abi.encodePacked("operator", _operatorID)), _newAddress);
    database.deleteBytes32(keccak256(abi.encodePacked("operator", oldAddress)));
    database.setBytes32(keccak256(abi.encodePacked("operator", _newAddress)), _operatorID);
    events.operator('Operator address changed', _operatorID, '', '', _newAddress);
  }

  function changeReferrerAddress(bytes32 _operatorID, address _newAddress)
  external {
    address oldAddress = database.addressStorage(keccak256(abi.encodePacked("referrer", _operatorID)));
    require(oldAddress != address(0));
    require(msg.sender == oldAddress || database.boolStorage(keccak256(abi.encodePacked("owner", msg.sender))));
    database.setAddress(keccak256(abi.encodePacked("referrer", _operatorID)), _newAddress);
    events.operator('Referrer address changed', _operatorID, '', '', _newAddress);
  }

  function updateIPFS(bytes32 _operatorID, string _ipfs)
  external
  onlyOperator(_operatorID)
  returns(bool){
    database.setString(keccak256(abi.encodePacked("operator.ipfs", _operatorID)), _ipfs);
    events.operator('Operator ipfs', _operatorID, '', _ipfs, msg.sender);
  }

  function addAsset(bytes32 _operatorID, string _name, string _ipfs, bool _acceptCrypto, bool _payoutCrypto, address _token)
  external
  onlyOperator(_operatorID)
  returns (bool) {
    bytes32 modelID = keccak256(abi.encodePacked('model.id', _operatorID, _name));
    require(database.addressStorage(keccak256(abi.encodePacked("model.operator", modelID))) == address(0));
    database.setAddress(keccak256(abi.encodePacked("model.operator", modelID)), msg.sender);
    database.setString(keccak256(abi.encodePacked('model.ipfs', modelID)), _ipfs);
    acceptToken(modelID, _token, _acceptCrypto);
    payoutToken(modelID, _token, _payoutCrypto);
    events.operator('Asset added', modelID, _name, _ipfs, msg.sender);
    return true;
  }

  function removeAsset(bytes32 _modelID)
  external
  onlyOperator(_modelID)
  returns (bool) {
    database.deleteAddress(keccak256(abi.encodePacked("model.operator", _modelID)));
    database.deleteString(keccak256(abi.encodePacked('model.ipfs', _modelID)));
    events.operator('Asset removed', _modelID, '', '', msg.sender);
  }

  function updateModelIPFS(bytes32 _modelID, string _ipfs)
  external
  onlyOperator(_modelID)
  returns(bool){
    database.setString(keccak256(abi.encodePacked("model.ipfs", _modelID)), _ipfs);
    events.operator('Model ipfs', _modelID, '', _ipfs, msg.sender);
  }

   
  function acceptToken(bytes32 _modelID, address _tokenAddress, bool _accept)
  public
  onlyOperator(_modelID)
  returns (bool) {
    if(_tokenAddress == address(0)){
      database.setBool(keccak256(abi.encodePacked("model.acceptsEther", _modelID)), _accept);
    }
    database.setBool(keccak256(abi.encodePacked("model.acceptsToken", _modelID, _tokenAddress)), _accept);
    return true;
  }


   
  function payoutToken(bytes32 _modelID, address _tokenAddress, bool _payout)
  public
  onlyOperator(_modelID)
  returns (bool) {
    if(_tokenAddress == address(0)){
      database.setBool(keccak256(abi.encodePacked("model.payoutEther", _modelID)), _payout);
    }
    database.setBool(keccak256(abi.encodePacked("model.payoutToken", _modelID, _tokenAddress)), _payout);
    return true;
  }

   
  function destroy()
  onlyOwner
  external {
    events.transaction('Operators destroyed', address(this), msg.sender, address(this).balance, address(0));
    selfdestruct(msg.sender);
  }

   
   
   

   
  modifier onlyOwner {
    require(database.boolStorage(keccak256(abi.encodePacked("owner", msg.sender))));
    _;
  }

   
  modifier onlyOperator(bytes32 _id) {
    require(database.addressStorage(keccak256(abi.encodePacked("operator", _id))) == msg.sender || database.addressStorage(keccak256(abi.encodePacked("model.operator", _id))) == msg.sender || database.boolStorage(keccak256(abi.encodePacked("owner", msg.sender))));
    _;
  }

}