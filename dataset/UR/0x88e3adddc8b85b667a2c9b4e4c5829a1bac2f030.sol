 

pragma solidity ^0.4.24;

 

 
contract ERC735 {

    event ClaimRequested(
        uint256 indexed claimRequestId,
        uint256 indexed topic,
        uint256 scheme,
        address indexed issuer,
        bytes signature,
        bytes data,
        string uri
    );
    event ClaimAdded(
        bytes32 indexed claimId,
        uint256 indexed topic,
        uint256 scheme,
        address indexed issuer,
        bytes signature,
        bytes data,
        string uri
    );
    event ClaimRemoved(
        bytes32 indexed claimId,
        uint256 indexed topic,
        uint256 scheme,
        address indexed issuer,
        bytes signature,
        bytes data,
        string uri
    );
    event ClaimChanged(
        bytes32 indexed claimId,
        uint256 indexed topic,
        uint256 scheme,
        address indexed issuer,
        bytes signature,
        bytes data,
        string uri
    );

    struct Claim {
        uint256 topic;
        uint256 scheme;
        address issuer;  
        bytes signature;  
        bytes data;
        string uri;
    }

    function getClaim(bytes32 _claimId)
        public view returns(uint256 topic, uint256 scheme, address issuer, bytes signature, bytes data, string uri);
    function getClaimIdsByTopic(uint256 _topic)
        public view returns(bytes32[] claimIds);
    function addClaim(uint256 _topic, uint256 _scheme, address issuer, bytes _signature, bytes _data, string _uri)
        public returns (bytes32 claimRequestId);
    function removeClaim(bytes32 _claimId)
        public returns (bool success);
}

 

 
contract ERC725 {

    uint256 constant MANAGEMENT_KEY = 1;
    uint256 constant ACTION_KEY = 2;
    uint256 constant CLAIM_SIGNER_KEY = 3;
    uint256 constant ENCRYPTION_KEY = 4;

    event KeyAdded(bytes32 indexed key, uint256 indexed purpose, uint256 indexed keyType);
    event KeyRemoved(bytes32 indexed key, uint256 indexed purpose, uint256 indexed keyType);
    event ExecutionRequested(uint256 indexed executionId, address indexed to, uint256 indexed value, bytes data);
    event Executed(uint256 indexed executionId, address indexed to, uint256 indexed value, bytes data);
    event Approved(uint256 indexed executionId, bool approved);

    function getKey(bytes32 _key) public view returns(uint256[] purposes, uint256 keyType, bytes32 key);
    function keyHasPurpose(bytes32 _key, uint256 _purpose) public view returns (bool exists);
    function getKeysByPurpose(uint256 _purpose) public view returns(bytes32[] keys);
    function addKey(bytes32 _key, uint256 _purpose, uint256 _keyType) public returns (bool success);
    function removeKey(bytes32 _key, uint256 _purpose) public returns (bool success);
    function execute(address _to, uint256 _value, bytes _data) public returns (uint256 executionId);
    function approve(uint256 _id, bool _approve) public returns (bool success);
}

 

 
library KeyHolderLibrary {
    event KeyAdded(bytes32 indexed key, uint256 indexed purpose, uint256 indexed keyType);
    event KeyRemoved(bytes32 indexed key, uint256 indexed purpose, uint256 indexed keyType);
    event PurposeAdded(bytes32 indexed key, uint256 indexed purpose);
    event ExecutionRequested(uint256 indexed executionId, address indexed to, uint256 indexed value, bytes data);
    event ExecutionFailed(uint256 indexed executionId, address indexed to, uint256 indexed value, bytes data);
    event Executed(uint256 indexed executionId, address indexed to, uint256 indexed value, bytes data);
    event Approved(uint256 indexed executionId, bool approved);

    struct Key {
        uint256[] purposes;  
        uint256 keyType;  
        bytes32 key;
    }

    struct KeyHolderData {
        uint256 executionNonce;
        mapping (bytes32 => Key) keys;
        mapping (uint256 => bytes32[]) keysByPurpose;
        mapping (uint256 => Execution) executions;
    }

    struct Execution {
        address to;
        uint256 value;
        bytes data;
        bool approved;
        bool executed;
    }

    function init(KeyHolderData storage _keyHolderData)
        public
    {
        bytes32 _key = keccak256(abi.encodePacked(msg.sender));
        _keyHolderData.keys[_key].key = _key;
        _keyHolderData.keys[_key].purposes.push(1);
        _keyHolderData.keys[_key].keyType = 1;
        _keyHolderData.keysByPurpose[1].push(_key);
        emit KeyAdded(_key, 1, 1);
    }

    function getKey(KeyHolderData storage _keyHolderData, bytes32 _key)
        public
        view
        returns(uint256[] purposes, uint256 keyType, bytes32 key)
    {
        return (
            _keyHolderData.keys[_key].purposes,
            _keyHolderData.keys[_key].keyType,
            _keyHolderData.keys[_key].key
        );
    }

    function getKeyPurposes(KeyHolderData storage _keyHolderData, bytes32 _key)
        public
        view
        returns(uint256[] purposes)
    {
        return (_keyHolderData.keys[_key].purposes);
    }

    function getKeysByPurpose(KeyHolderData storage _keyHolderData, uint256 _purpose)
        public
        view
        returns(bytes32[] _keys)
    {
        return _keyHolderData.keysByPurpose[_purpose];
    }

    function addKey(KeyHolderData storage _keyHolderData, bytes32 _key, uint256 _purpose, uint256 _type)
        public
        returns (bool success)
    {
        require(_keyHolderData.keys[_key].key != _key, "Key already exists");  
        if (msg.sender != address(this)) {
            require(keyHasPurpose(_keyHolderData, keccak256(abi.encodePacked(msg.sender)), 1), "Sender does not have management key");  
        }

        _keyHolderData.keys[_key].key = _key;
        _keyHolderData.keys[_key].purposes.push(_purpose);
        _keyHolderData.keys[_key].keyType = _type;

        _keyHolderData.keysByPurpose[_purpose].push(_key);

        emit KeyAdded(_key, _purpose, _type);

        return true;
    }

     
    function addPurpose(KeyHolderData storage _keyHolderData, bytes32 _key, uint256 _purpose)
        public
        returns (bool)
    {
        require(_keyHolderData.keys[_key].key == _key, "Key does not exist");  
        if (msg.sender != address(this)) {
            require(keyHasPurpose(_keyHolderData, keccak256(abi.encodePacked(msg.sender)), 1), "Sender does not have management key");  
        }

        _keyHolderData.keys[_key].purposes.push(_purpose);

        _keyHolderData.keysByPurpose[_purpose].push(_key);

        emit PurposeAdded(_key, _purpose);

        return true;
    }

    function approve(KeyHolderData storage _keyHolderData, uint256 _id, bool _approve)
        public
        returns (bool success)
    {
        require(keyHasPurpose(_keyHolderData, keccak256(abi.encodePacked(msg.sender)), 2), "Sender does not have action key");
        require(!_keyHolderData.executions[_id].executed, "Already executed");

        emit Approved(_id, _approve);

        if (_approve == true) {
            _keyHolderData.executions[_id].approved = true;
            success = _keyHolderData.executions[_id].to.call(_keyHolderData.executions[_id].data, 0);
            if (success) {
                _keyHolderData.executions[_id].executed = true;
                emit Executed(
                    _id,
                    _keyHolderData.executions[_id].to,
                    _keyHolderData.executions[_id].value,
                    _keyHolderData.executions[_id].data
                );
                return;
            } else {
                emit ExecutionFailed(
                    _id,
                    _keyHolderData.executions[_id].to,
                    _keyHolderData.executions[_id].value,
                    _keyHolderData.executions[_id].data
                );
                return;
            }
        } else {
            _keyHolderData.executions[_id].approved = false;
        }
        return true;
    }

    function execute(KeyHolderData storage _keyHolderData, address _to, uint256 _value, bytes _data)
        public
        returns (uint256 executionId)
    {
        require(!_keyHolderData.executions[_keyHolderData.executionNonce].executed, "Already executed");
        _keyHolderData.executions[_keyHolderData.executionNonce].to = _to;
        _keyHolderData.executions[_keyHolderData.executionNonce].value = _value;
        _keyHolderData.executions[_keyHolderData.executionNonce].data = _data;

        emit ExecutionRequested(_keyHolderData.executionNonce, _to, _value, _data);

        if (
            keyHasPurpose(_keyHolderData, keccak256(abi.encodePacked(msg.sender)),1) ||
            keyHasPurpose(_keyHolderData, keccak256(abi.encodePacked(msg.sender)),2)
        ) {
            approve(_keyHolderData, _keyHolderData.executionNonce, true);
        }

        _keyHolderData.executionNonce++;
        return _keyHolderData.executionNonce-1;
    }

    function removeKey(KeyHolderData storage _keyHolderData, bytes32 _key, uint256 _purpose)
        public
        returns (bool success)
    {
        if (msg.sender != address(this)) {
            require(keyHasPurpose(_keyHolderData, keccak256(abi.encodePacked(msg.sender)), 1), "Sender does not have management key");  
        }

        require(_keyHolderData.keys[_key].key == _key, "No such key");
        emit KeyRemoved(_key, _purpose, _keyHolderData.keys[_key].keyType);

         
        uint256[] storage purposes = _keyHolderData.keys[_key].purposes;
        for (uint i = 0; i < purposes.length; i++) {
            if (purposes[i] == _purpose) {
                purposes[i] = purposes[purposes.length - 1];
                delete purposes[purposes.length - 1];
                purposes.length--;
                break;
            }
        }

         
        if (purposes.length == 0) {
            delete _keyHolderData.keys[_key];
        }

         
        bytes32[] storage keys = _keyHolderData.keysByPurpose[_purpose];
        for (uint j = 0; j < keys.length; j++) {
            if (keys[j] == _key) {
                keys[j] = keys[keys.length - 1];
                delete keys[keys.length - 1];
                keys.length--;
                break;
            }
        }

        return true;
    }

    function keyHasPurpose(KeyHolderData storage _keyHolderData, bytes32 _key, uint256 _purpose)
        public
        view
        returns(bool isThere)
    {
        if (_keyHolderData.keys[_key].key == 0) {
            isThere = false;
        }

        uint256[] storage purposes = _keyHolderData.keys[_key].purposes;
        for (uint i = 0; i < purposes.length; i++) {
             
             
            if (purposes[i] == _purpose || purposes[i] == 1) {
                isThere = true;
                break;
            }
        }
    }
}

 

 
contract KeyHolder is ERC725 {
    KeyHolderLibrary.KeyHolderData keyHolderData;

    constructor() public {
        KeyHolderLibrary.init(keyHolderData);
    }

    function getKey(bytes32 _key)
        public
        view
        returns(uint256[] purposes, uint256 keyType, bytes32 key)
    {
        return KeyHolderLibrary.getKey(keyHolderData, _key);
    }

    function getKeyPurposes(bytes32 _key)
        public
        view
        returns(uint256[] purposes)
    {
        return KeyHolderLibrary.getKeyPurposes(keyHolderData, _key);
    }

    function getKeysByPurpose(uint256 _purpose)
        public
        view
        returns(bytes32[] _keys)
    {
        return KeyHolderLibrary.getKeysByPurpose(keyHolderData, _purpose);
    }

    function addKey(bytes32 _key, uint256 _purpose, uint256 _type)
        public
        returns (bool success)
    {
        return KeyHolderLibrary.addKey(keyHolderData, _key, _purpose, _type);
    }

    function addPurpose(bytes32 _key, uint256 _purpose)
        public
        returns (bool)
    {
        return KeyHolderLibrary.addPurpose(keyHolderData, _key, _purpose);
    }

    function approve(uint256 _id, bool _approve)
        public
        returns (bool success)
    {
        return KeyHolderLibrary.approve(keyHolderData, _id, _approve);
    }

    function execute(address _to, uint256 _value, bytes _data)
        public
        returns (uint256 executionId)
    {
        return KeyHolderLibrary.execute(keyHolderData, _to, _value, _data);
    }

    function removeKey(bytes32 _key, uint256 _purpose)
        public
        returns (bool success)
    {
        return KeyHolderLibrary.removeKey(keyHolderData, _key, _purpose);
    }

    function keyHasPurpose(bytes32 _key, uint256 _purpose)
        public
        view
        returns(bool exists)
    {
        return KeyHolderLibrary.keyHasPurpose(keyHolderData, _key, _purpose);
    }

}

 

 
library ClaimHolderLibrary {
    event ClaimAdded(
        bytes32 indexed claimId,
        uint256 indexed topic,
        uint256 scheme,
        address indexed issuer,
        bytes signature,
        bytes data,
        string uri
    );
    event ClaimRemoved(
        bytes32 indexed claimId,
        uint256 indexed topic,
        uint256 scheme,
        address indexed issuer,
        bytes signature,
        bytes data,
        string uri
    );

    struct Claim {
        uint256 topic;
        uint256 scheme;
        address issuer;  
        bytes signature;  
        bytes data;
        string uri;
    }

    struct Claims {
        mapping (bytes32 => Claim) byId;
        mapping (uint256 => bytes32[]) byTopic;
    }

    function addClaim(
        KeyHolderLibrary.KeyHolderData storage _keyHolderData,
        Claims storage _claims,
        uint256 _topic,
        uint256 _scheme,
        address _issuer,
        bytes _signature,
        bytes _data,
        string _uri
    )
        public
        returns (bytes32 claimRequestId)
    {
        if (msg.sender != address(this)) {
            require(KeyHolderLibrary.keyHasPurpose(_keyHolderData, keccak256(abi.encodePacked(msg.sender)), 3), "Sender does not have claim signer key");
        }

        bytes32 claimId = keccak256(abi.encodePacked(_issuer, _topic));

        if (_claims.byId[claimId].issuer != _issuer) {
            _claims.byTopic[_topic].push(claimId);
        }

        _claims.byId[claimId].topic = _topic;
        _claims.byId[claimId].scheme = _scheme;
        _claims.byId[claimId].issuer = _issuer;
        _claims.byId[claimId].signature = _signature;
        _claims.byId[claimId].data = _data;
        _claims.byId[claimId].uri = _uri;

        emit ClaimAdded(
            claimId,
            _topic,
            _scheme,
            _issuer,
            _signature,
            _data,
            _uri
        );

        return claimId;
    }

     
    function addClaims(
        KeyHolderLibrary.KeyHolderData storage _keyHolderData,
        Claims storage _claims,
        uint256[] _topic,
        address[] _issuer,
        bytes _signature,
        bytes _data,
        uint256[] _offsets
    )
        public
    {
        uint offset = 0;
        for (uint16 i = 0; i < _topic.length; i++) {
            if (_signature.length > 0) {
                addClaim(
                    _keyHolderData,
                    _claims,
                    _topic[i],
                    1,
                    _issuer[i],
                    getBytes(_signature, (i * 32), 32),
                    getBytes(_data, offset, _offsets[i]),
                    ""
                );
            } else {
                addClaim(
                    _keyHolderData,
                    _claims,
                    _topic[i],
                    1,
                    _issuer[i],
                    "",
                    getBytes(_data, offset, _offsets[i]),
                    ""
                );
            }
            offset += _offsets[i];
        }
    }

    function removeClaim(
        KeyHolderLibrary.KeyHolderData storage _keyHolderData,
        Claims storage _claims,
        bytes32 _claimId
    )
        public
        returns (bool success)
    {
        if (msg.sender != address(this)) {
            require(KeyHolderLibrary.keyHasPurpose(_keyHolderData, keccak256(abi.encodePacked(msg.sender)), 1), "Sender does not have management key");
        }

        emit ClaimRemoved(
            _claimId,
            _claims.byId[_claimId].topic,
            _claims.byId[_claimId].scheme,
            _claims.byId[_claimId].issuer,
            _claims.byId[_claimId].signature,
            _claims.byId[_claimId].data,
            _claims.byId[_claimId].uri
        );

        delete _claims.byId[_claimId];
        return true;
    }

     
    function updateSelfClaims(
        KeyHolderLibrary.KeyHolderData storage _keyHolderData,
        Claims storage _claims,
        uint256[] _topic,
        bytes _data,
        uint256[] _offsets
    )
        public
    {
        uint offset = 0;
        for (uint16 i = 0; i < _topic.length; i++) {
            removeClaim(
                _keyHolderData,
                _claims,
                keccak256(abi.encodePacked(msg.sender, _topic[i]))
            );
            addClaim(
                _keyHolderData,
                _claims,
                _topic[i],
                1,
                msg.sender,
                "",
                getBytes(_data, offset, _offsets[i]),
                ""
            );
            offset += _offsets[i];
        }
    }

    function getClaim(Claims storage _claims, bytes32 _claimId)
        public
        view
        returns(
          uint256 topic,
          uint256 scheme,
          address issuer,
          bytes signature,
          bytes data,
          string uri
        )
    {
        return (
            _claims.byId[_claimId].topic,
            _claims.byId[_claimId].scheme,
            _claims.byId[_claimId].issuer,
            _claims.byId[_claimId].signature,
            _claims.byId[_claimId].data,
            _claims.byId[_claimId].uri
        );
    }

    function getBytes(bytes _str, uint256 _offset, uint256 _length)
        internal
        pure
        returns (bytes)
    {
        bytes memory sig = new bytes(_length);
        uint256 j = 0;
        for (uint256 k = _offset; k < _offset + _length; k++) {
            sig[j] = _str[k];
            j++;
        }
        return sig;
    }
}

 

 
contract ClaimHolder is KeyHolder, ERC735 {

    ClaimHolderLibrary.Claims claims;

    function addClaim(
        uint256 _topic,
        uint256 _scheme,
        address _issuer,
        bytes _signature,
        bytes _data,
        string _uri
    )
        public
        returns (bytes32 claimRequestId)
    {
        return ClaimHolderLibrary.addClaim(
            keyHolderData,
            claims,
            _topic,
            _scheme,
            _issuer,
            _signature,
            _data,
            _uri
        );
    }

    function addClaims(
        uint256[] _topic,
        address[] _issuer,
        bytes _signature,
        bytes _data,
        uint256[] _offsets
    )
        public
    {
        ClaimHolderLibrary.addClaims(
            keyHolderData,
            claims,
            _topic,
            _issuer,
            _signature,
            _data,
            _offsets
        );
    }

    function removeClaim(bytes32 _claimId) public returns (bool success) {
        return ClaimHolderLibrary.removeClaim(keyHolderData, claims, _claimId);
    }

    function updateSelfClaims(
        uint256[] _topic,
        bytes _data,
        uint256[] _offsets
    )
        public
    {
        ClaimHolderLibrary.updateSelfClaims(
            keyHolderData,
            claims,
            _topic,
            _data,
            _offsets
        );
    }

    function getClaim(bytes32 _claimId)
        public
        view
        returns(
            uint256 topic,
            uint256 scheme,
            address issuer,
            bytes signature,
            bytes data,
            string uri
        )
    {
        return ClaimHolderLibrary.getClaim(claims, _claimId);
    }

    function getClaimIdsByTopic(uint256 _topic)
        public
        view
        returns(bytes32[] claimIds)
    {
        return claims.byTopic[_topic];
    }
}

 

 
contract OwnableUpdated {
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

 

 
contract Foundation is OwnableUpdated {

     
    mapping(address => bool) public factories;

     
    mapping(address => address) public ownersToContracts;

     
    mapping(address => address) public contractsToOwners;

     
    address[] private contractsIndex;

     
     
     
     
    mapping(address => address) public membersToContracts;

     
     
    mapping(address => address[]) public contractsToKnownMembersIndexes;

     
    event FactoryAdded(address _factory);
    event FactoryRemoved(address _factory);

     
    function addFactory(address _factory) external onlyOwner {
        factories[_factory] = true;
        emit FactoryAdded(_factory);
    }

     
    function removeFactory(address _factory) external onlyOwner {
        factories[_factory] = false;
        emit FactoryRemoved(_factory);
    }

     
    modifier onlyFactory() {
        require(
            factories[msg.sender],
            "You are not a factory"
        );
        _;
    }

     
    function setInitialOwnerInFoundation(
        address _contract,
        address _account
    )
        external
        onlyFactory
    {
        require(
            contractsToOwners[_contract] == address(0),
            "Contract already has owner"
        );
        require(
            ownersToContracts[_account] == address(0),
            "Account already has contract"
        );
        contractsToOwners[_contract] = _account;
        contractsIndex.push(_contract);
        ownersToContracts[_account] = _contract;
        membersToContracts[_account] = _contract;
    }

     
    function transferOwnershipInFoundation(
        address _contract,
        address _newAccount
    )
        external
    {
        require(
            (
                ownersToContracts[msg.sender] == _contract &&
                contractsToOwners[_contract] == msg.sender
            ),
            "You are not the owner"
        );
        ownersToContracts[msg.sender] = address(0);
        membersToContracts[msg.sender] = address(0);
        ownersToContracts[_newAccount] = _contract;
        membersToContracts[_newAccount] = _contract;
        contractsToOwners[_contract] = _newAccount;
         
         
    }

     
    function renounceOwnershipInFoundation() external returns (bool success) {
         
        delete(contractsToKnownMembersIndexes[msg.sender]);
         
        delete(ownersToContracts[contractsToOwners[msg.sender]]);
         
        delete(contractsToOwners[msg.sender]);
         
        success = true;
    }

     
    function addMember(address _member) external {
        require(
            ownersToContracts[msg.sender] != address(0),
            "You own no contract"
        );
        require(
            membersToContracts[_member] == address(0),
            "Address is already member of a contract"
        );
        membersToContracts[_member] = ownersToContracts[msg.sender];
        contractsToKnownMembersIndexes[ownersToContracts[msg.sender]].push(_member);
    }

     
    function removeMember(address _member) external {
        require(
            ownersToContracts[msg.sender] != address(0),
            "You own no contract"
        );
        require(
            membersToContracts[_member] == ownersToContracts[msg.sender],
            "Address is not member of this contract"
        );
        membersToContracts[_member] = address(0);
        contractsToKnownMembersIndexes[ownersToContracts[msg.sender]].push(_member);
    }

     
    function getContractsIndex()
        external
        onlyOwner
        view
        returns (address[])
    {
        return contractsIndex;
    }

     
    function() public {
        revert("Prevent accidental sending of ether");
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

 
contract TalaoMarketplace is Ownable {
  using SafeMath for uint256;

  TalaoToken public token;

  struct MarketplaceData {
    uint buyPrice;
    uint sellPrice;
    uint unitPrice;
  }

  MarketplaceData public marketplace;

  event SellingPrice(uint sellingPrice);
  event TalaoBought(address buyer, uint amount, uint price, uint unitPrice);
  event TalaoSold(address seller, uint amount, uint price, uint unitPrice);

   
  constructor(address talao)
      public
  {
      token = TalaoToken(talao);
  }

   
  function setPrices(uint256 newSellPrice, uint256 newBuyPrice, uint256 newUnitPrice)
      public
      onlyOwner
  {
      require (newSellPrice > 0 && newBuyPrice > 0 && newUnitPrice > 0, "wrong inputs");
      marketplace.sellPrice = newSellPrice;
      marketplace.buyPrice = newBuyPrice;
      marketplace.unitPrice = newUnitPrice;
  }

   
  function buy()
      public
      payable
      returns (uint amount)
  {
      amount = msg.value.mul(marketplace.unitPrice).div(marketplace.buyPrice);
      token.transfer(msg.sender, amount);
      emit TalaoBought(msg.sender, amount, marketplace.buyPrice, marketplace.unitPrice);
      return amount;
  }

   
  function sell(uint amount)
      public
      returns (uint revenue)
  {
      require(token.balanceOf(msg.sender) >= amount, "sender has not enough tokens");
      token.transferFrom(msg.sender, this, amount);
      revenue = amount.mul(marketplace.sellPrice).div(marketplace.unitPrice);
      msg.sender.transfer(revenue);
      emit TalaoSold(msg.sender, amount, marketplace.sellPrice, marketplace.unitPrice);
      return revenue;
  }

   
  function withdrawEther(uint256 ethers)
      public
      onlyOwner
  {
      if (this.balance >= ethers) {
          msg.sender.transfer(ethers);
      }
  }

   
  function withdrawTalao(uint256 tokens)
      public
      onlyOwner
  {
      token.transfer(msg.sender, tokens);
  }


   
  function ()
      public
      payable
      onlyOwner
  {

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


 
contract TokenTimelock {
  using SafeERC20 for ERC20Basic;

   
  ERC20Basic public token;

   
  address public beneficiary;

   
  uint256 public releaseTime;

  function TokenTimelock(ERC20Basic _token, address _beneficiary, uint256 _releaseTime) public {
    require(_releaseTime > now);
    token = _token;
    beneficiary = _beneficiary;
    releaseTime = _releaseTime;
  }

   
  function release() public {
    require(now >= releaseTime);

    uint256 amount = token.balanceOf(this);

    token.safeTransfer(beneficiary, amount);
  }
}


 
contract TokenVesting is Ownable {
  using SafeMath for uint256;
  using SafeERC20 for ERC20Basic;

  event Released(uint256 amount);
  event Revoked();

   
  address public beneficiary;

  uint256 public cliff;
  uint256 public start;
  uint256 public duration;

  bool public revocable;

  mapping (address => uint256) public released;
  mapping (address => bool) public revoked;

   
  function TokenVesting(address _beneficiary, uint256 _start, uint256 _cliff, uint256 _duration, bool _revocable) public {
    require(_beneficiary != address(0));
    require(_cliff <= _duration);

    beneficiary = _beneficiary;
    revocable = _revocable;
    duration = _duration;
    cliff = _start.add(_cliff);
    start = _start;
  }

   
  function release(ERC20Basic token) public {
    uint256 unreleased = releasableAmount(token);

    released[token] = released[token].add(unreleased);

    token.safeTransfer(beneficiary, unreleased);

    Released(unreleased);
  }

   
  function revoke(ERC20Basic token) public onlyOwner {
    require(revocable);
    require(!revoked[token]);

    uint256 balance = token.balanceOf(this);

    uint256 unreleased = releasableAmount(token);
    uint256 refund = balance.sub(unreleased);

    revoked[token] = true;

    token.safeTransfer(owner, refund);

    Revoked();
  }

   
  function releasableAmount(ERC20Basic token) public view returns (uint256) {
    return vestedAmount(token).sub(released[token]);
  }

   
  function vestedAmount(ERC20Basic token) public view returns (uint256) {
    uint256 currentBalance = token.balanceOf(this);
    uint256 totalBalance = currentBalance.add(released[token]);

    if (now < cliff) {
      return 0;
    } else if (now >= start.add(duration) || revoked[token]) {
      return totalBalance;
    } else {
      return totalBalance.mul(now.sub(start)).div(duration);
    }
  }
}

 
contract Crowdsale {
  using SafeMath for uint256;

   
  MintableToken public token;

   
  uint256 public startTime;
  uint256 public endTime;

   
  address public wallet;

   
  uint256 public rate;

   
  uint256 public weiRaised;

   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

  function Crowdsale(uint256 _rate, uint256 _startTime, uint256 _endTime, address _wallet) public {
    require(_rate > 0);
    require(_startTime >= now);
    require(_endTime >= _startTime);
    require(_wallet != address(0));

    token = createTokenContract();
    startTime = _startTime;
    endTime = _endTime;
    wallet = _wallet;
  }

   
   
  function createTokenContract() internal returns (MintableToken) {
    return new MintableToken();
  }


   
  function () external payable {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address beneficiary) public payable {
    require(beneficiary != address(0));
    require(validPurchase());

    uint256 weiAmount = msg.value;

     
    uint256 tokens = weiAmount.mul(rate);

     
    weiRaised = weiRaised.add(weiAmount);

    token.mint(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

    forwardFunds();
  }

   
   
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }

   
   
  function validPurchase() internal returns (bool) {
    bool withinPeriod = now >= startTime && now <= endTime;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase;
  }

   
  function hasEnded() public view returns (bool) {
    return now > endTime;
  }


}


 
contract FinalizableCrowdsale is Crowdsale, Ownable {
  using SafeMath for uint256;

  bool public isFinalized = false;

  event Finalized();

   
  function finalize() public {
    require(!isFinalized);
    require(hasEnded());

    finalization();
    Finalized();

    isFinalized = true;
  }

   
  function finalization() internal {
  }
}


 
contract RefundVault is Ownable {
  using SafeMath for uint256;

  enum State { Active, Refunding, Closed }

  mapping (address => uint256) public deposited;
  address public wallet;
  State public state;

  event Closed();
  event RefundsEnabled();
  event Refunded(address indexed beneficiary, uint256 weiAmount);

  function RefundVault(address _wallet) public {
    require(_wallet != address(0));
    wallet = _wallet;
    state = State.Active;
  }

  function deposit(address investor) onlyOwner public payable {
    require(state == State.Active);
    deposited[investor] = deposited[investor].add(msg.value);
  }

  function close() onlyOwner public {
    require(state == State.Active);
    state = State.Closed;
    Closed();
    wallet.transfer(this.balance);
  }

  function enableRefunds() onlyOwner public {
    require(state == State.Active);
    state = State.Refunding;
    RefundsEnabled();
  }

  function refund(address investor) public {
    require(state == State.Refunding);
    uint256 depositedValue = deposited[investor];
    deposited[investor] = 0;
    investor.transfer(depositedValue);
    Refunded(investor, depositedValue);
  }
}



 
contract RefundableCrowdsale is FinalizableCrowdsale {
  using SafeMath for uint256;

   
  uint256 public goal;

   
  RefundVault public vault;

  function RefundableCrowdsale(uint256 _goal) public {
    require(_goal > 0);
    vault = new RefundVault(wallet);
    goal = _goal;
  }

   
   
   
  function forwardFunds() internal {
    vault.deposit.value(msg.value)(msg.sender);
  }

   
  function claimRefund() public {
    require(isFinalized);
    require(!goalReached());

    vault.refund(msg.sender);
  }

   
  function finalization() internal {
    if (goalReached()) {
      vault.close();
    } else {
      vault.enableRefunds();
    }

    super.finalization();
  }

  function goalReached() public view returns (bool) {
    return weiRaised >= goal;
  }

}


 
contract CappedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 public cap;

  function CappedCrowdsale(uint256 _cap) public {
    require(_cap > 0);
    cap = _cap;
  }

   
   
   
  function validPurchase() internal returns (bool) {
    bool withinCap = weiRaised.add(msg.value) <= cap;
    return super.validPurchase() && withinCap;
  }

   
   
  function hasEnded() public view returns (bool) {
    bool capReached = weiRaised >= cap;
    return super.hasEnded() || capReached;
  }

}

 
contract ProgressiveIndividualCappedCrowdsale is RefundableCrowdsale, CappedCrowdsale {

    uint public startGeneralSale;
    uint public constant TIME_PERIOD_IN_SEC = 1 days;
    uint public constant minimumParticipation = 10 finney;
    uint public constant GAS_LIMIT_IN_WEI = 5E10 wei;  
    uint256 public baseEthCapPerAddress;

    mapping(address=>uint) public participated;

    function ProgressiveIndividualCappedCrowdsale(uint _baseEthCapPerAddress, uint _startGeneralSale)
        public
    {
        baseEthCapPerAddress = _baseEthCapPerAddress;
        startGeneralSale = _startGeneralSale;
    }

     
    function setBaseCap(uint _newBaseCap)
        public
        onlyOwner
    {
        require(now < startGeneralSale);
        baseEthCapPerAddress = _newBaseCap;
    }

     
    function validPurchase()
        internal
        returns(bool)
    {
        bool gasCheck = tx.gasprice <= GAS_LIMIT_IN_WEI;
        uint ethCapPerAddress = getCurrentEthCapPerAddress();
        participated[msg.sender] = participated[msg.sender].add(msg.value);
        bool enough = participated[msg.sender] >= minimumParticipation;
        return participated[msg.sender] <= ethCapPerAddress && enough && gasCheck;
    }

     
    function getCurrentEthCapPerAddress()
        public
        constant
        returns(uint)
    {
        if (block.timestamp < startGeneralSale) return 0;
        uint timeSinceStartInSec = block.timestamp.sub(startGeneralSale);
        uint currentPeriod = timeSinceStartInSec.div(TIME_PERIOD_IN_SEC).add(1);

         
        return (2 ** currentPeriod.sub(1)).mul(baseEthCapPerAddress);
    }
}

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}


 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

 

contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

   
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(address(0), _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}


interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

 
contract TalaoToken is MintableToken {
  using SafeMath for uint256;

   
  string public constant name = "Talao";
  string public constant symbol = "TALAO";
  uint8 public constant decimals = 18;

   
  address public marketplace;

   
  uint256 public vaultDeposit;
   
  uint256 public totalDeposit;

  struct FreelanceData {
       
      uint256 accessPrice;
       
      address appointedAgent;
       
      uint sharingPlan;
       
      uint256 userDeposit;
  }

   
  struct ClientAccess {
       
      bool clientAgreement;
       
      uint clientDate;
  }

   
  mapping (address => mapping (address => ClientAccess)) public accessAllowance;

   
  mapping (address=>FreelanceData) public data;

  enum VaultStatus {Closed, Created, PriceTooHigh, NotEnoughTokensDeposited, AgentRemoved, NewAgent, NewAccess, WrongAccessPrice}

   
   
   
   
   
   
   
   
   
  event Vault(address indexed client, address indexed freelance, VaultStatus status);

  modifier onlyMintingFinished()
  {
      require(mintingFinished == true, "minting has not finished");
      _;
  }

   
  function setMarketplace(address theMarketplace)
      public
      onlyMintingFinished
      onlyOwner
  {
      marketplace = theMarketplace;
  }

   
  function approve(address _spender, uint256 _value)
      public
      onlyMintingFinished
      returns (bool)
  {
      return super.approve(_spender, _value);
  }

   
  function transfer(address _to, uint256 _value)
      public
      onlyMintingFinished
      returns (bool result)
  {
      return super.transfer(_to, _value);
  }

   
  function transferFrom(address _from, address _to, uint256 _value)
      public
      onlyMintingFinished
      returns (bool)
  {
      return super.transferFrom(_from, _to, _value);
  }

   
  function approveAndCall(address _spender, uint256 _value, bytes _extraData)
      public
      onlyMintingFinished
      returns (bool)
  {
      tokenRecipient spender = tokenRecipient(_spender);
      if (approve(_spender, _value)) {
          spender.receiveApproval(msg.sender, _value, this, _extraData);
          return true;
      }
  }

   
  function withdrawEther(uint256 ethers)
      public
      onlyOwner
  {
      msg.sender.transfer(ethers);
  }

   
  function withdrawTalao(uint256 tokens)
      public
      onlyOwner
  {
      require(balanceOf(this).sub(totalDeposit) >= tokens, "too much tokens asked");
      _transfer(this, msg.sender, tokens);
  }

   
   
   

   
  function createVaultAccess (uint256 price)
      public
      onlyMintingFinished
  {
      require(accessAllowance[msg.sender][msg.sender].clientAgreement==false, "vault already created");
      require(price<=vaultDeposit, "price asked is too high");
      require(balanceOf(msg.sender)>vaultDeposit, "user has not enough tokens to send deposit");
      data[msg.sender].accessPrice=price;
      super.transfer(this, vaultDeposit);
      totalDeposit = totalDeposit.add(vaultDeposit);
      data[msg.sender].userDeposit=vaultDeposit;
      data[msg.sender].sharingPlan=100;
      accessAllowance[msg.sender][msg.sender].clientAgreement=true;
      emit Vault(msg.sender, msg.sender, VaultStatus.Created);
  }

   
  function closeVaultAccess()
      public
      onlyMintingFinished
  {
      require(accessAllowance[msg.sender][msg.sender].clientAgreement==true, "vault has not been created");
      require(_transfer(this, msg.sender, data[msg.sender].userDeposit), "token deposit transfer failed");
      accessAllowance[msg.sender][msg.sender].clientAgreement=false;
      totalDeposit=totalDeposit.sub(data[msg.sender].userDeposit);
      data[msg.sender].sharingPlan=0;
      emit Vault(msg.sender, msg.sender, VaultStatus.Closed);
  }

   
  function _transfer(address _from, address _to, uint _value)
      internal
      returns (bool)
  {
      require(_to != 0x0, "destination cannot be 0x0");
      require(balances[_from] >= _value, "not enough tokens in sender wallet");

      balances[_from] = balances[_from].sub(_value);
      balances[_to] = balances[_to].add(_value);
      emit Transfer(_from, _to, _value);
      return true;
  }

   
  function agentApproval (address newagent, uint newplan)
      public
      onlyMintingFinished
  {
      require(newplan>=0&&newplan<=100, "plan must be between 0 and 100");
      require(accessAllowance[msg.sender][msg.sender].clientAgreement==true, "vault has not been created");
      emit Vault(data[msg.sender].appointedAgent, msg.sender, VaultStatus.AgentRemoved);
      data[msg.sender].appointedAgent=newagent;
      data[msg.sender].sharingPlan=newplan;
      emit Vault(newagent, msg.sender, VaultStatus.NewAgent);
  }

   
  function setVaultDeposit (uint newdeposit)
      public
      onlyOwner
  {
      vaultDeposit = newdeposit;
  }

   
  function getVaultAccess (address freelance)
      public
      onlyMintingFinished
      returns (bool)
  {
      require(accessAllowance[freelance][freelance].clientAgreement==true, "vault does not exist");
      require(accessAllowance[msg.sender][freelance].clientAgreement!=true, "access was already granted");
      require(balanceOf(msg.sender)>data[freelance].accessPrice, "user has not enough tokens to get access to vault");

      uint256 freelance_share = data[freelance].accessPrice.mul(data[freelance].sharingPlan).div(100);
      uint256 agent_share = data[freelance].accessPrice.sub(freelance_share);
      if(freelance_share>0) super.transfer(freelance, freelance_share);
      if(agent_share>0) super.transfer(data[freelance].appointedAgent, agent_share);
      accessAllowance[msg.sender][freelance].clientAgreement=true;
      accessAllowance[msg.sender][freelance].clientDate=block.number;
      emit Vault(msg.sender, freelance, VaultStatus.NewAccess);
      return true;
  }

   
  function getFreelanceAgent(address freelance)
      public
      view
      returns (address)
  {
      return data[freelance].appointedAgent;
  }

   
  function hasVaultAccess(address freelance, address user)
      public
      view
      returns (bool)
  {
      return ((accessAllowance[user][freelance].clientAgreement) || (data[freelance].appointedAgent == user));
  }

}

 

 
contract Identity is ClaimHolder {

     
    Foundation foundation;

     
    TalaoToken public token;

     
    struct IdentityInformation {
         
         
        address creator;

         
         
         
         
         
         
         
         
         
        uint16 category;

         
         
         
         
        uint16 asymetricEncryptionAlgorithm;

         
         
         
         
        uint16 symetricEncryptionAlgorithm;

         
         
         
         
        bytes asymetricEncryptionPublicKey;

         
         
         
         
         
        bytes symetricEncryptionEncryptedKey;

         
        bytes encryptedSecret;
    }
     
    IdentityInformation public identityInformation;

     
    mapping(address => bool) public identityboxBlacklisted;

     
    event TextReceived (
        address indexed sender,
        uint indexed category,
        bytes text
    );

     
    event FileReceived (
        address indexed sender,
        uint indexed fileType,
        uint fileEngine,
        bytes fileHash
    );

     
    constructor(
        address _foundation,
        address _token,
        uint16 _category,
        uint16 _asymetricEncryptionAlgorithm,
        uint16 _symetricEncryptionAlgorithm,
        bytes _asymetricEncryptionPublicKey,
        bytes _symetricEncryptionEncryptedKey,
        bytes _encryptedSecret
    )
        public
    {
        foundation = Foundation(_foundation);
        token = TalaoToken(_token);
        identityInformation.creator = msg.sender;
        identityInformation.category = _category;
        identityInformation.asymetricEncryptionAlgorithm = _asymetricEncryptionAlgorithm;
        identityInformation.symetricEncryptionAlgorithm = _symetricEncryptionAlgorithm;
        identityInformation.asymetricEncryptionPublicKey = _asymetricEncryptionPublicKey;
        identityInformation.symetricEncryptionEncryptedKey = _symetricEncryptionEncryptedKey;
        identityInformation.encryptedSecret = _encryptedSecret;
    }

     
    function identityOwner() internal view returns (address) {
        return foundation.contractsToOwners(address(this));
    }

     
    function isIdentityOwner() internal view returns (bool) {
        return msg.sender == identityOwner();
    }

     
    modifier onlyIdentityOwner() {
        require(isIdentityOwner(), "Access denied");
        _;
    }

     
    function isActiveIdentityOwner() public view returns (bool) {
        return isIdentityOwner() && token.hasVaultAccess(msg.sender, msg.sender);
    }

     
    modifier onlyActiveIdentityOwner() {
        require(isActiveIdentityOwner(), "Access denied");
        _;
    }

     
    function isActiveIdentity() public view returns (bool) {
        return token.hasVaultAccess(identityOwner(), identityOwner());
    }

     
    function hasIdentityPurpose(uint256 _purpose) public view returns (bool) {
        return (
            keyHasPurpose(keccak256(abi.encodePacked(msg.sender)), _purpose) &&
            isActiveIdentity()
        );
    }

     
    modifier onlyIdentityPurpose(uint256 _purpose) {
        require(hasIdentityPurpose(_purpose), "Access denied");
        _;
    }

     
    function identityboxSendtext(uint _category, bytes _text) external {
        require(!identityboxBlacklisted[msg.sender], "You are blacklisted");
        emit TextReceived(msg.sender, _category, _text);
    }

     
    function identityboxSendfile(
        uint _fileType, uint _fileEngine, bytes _fileHash
    )
        external
    {
        require(!identityboxBlacklisted[msg.sender], "You are blacklisted");
        emit FileReceived(msg.sender, _fileType, _fileEngine, _fileHash);
    }

     
    function identityboxBlacklist(address _address)
        external
        onlyIdentityPurpose(20004)
    {
        identityboxBlacklisted[_address] = true;
    }

     
    function identityboxUnblacklist(address _address)
        external
        onlyIdentityPurpose(20004)
    {
        identityboxBlacklisted[_address] = false;
    }
}

 
interface IdentityInterface {
    function identityInformation()
        external
        view
        returns (address, uint16, uint16, uint16, bytes, bytes, bytes);
    function identityboxSendtext(uint, bytes) external;
}

 

 
library SafeMathUpdated {
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

 

 
contract Partnership is Identity {

    using SafeMathUpdated for uint;

     
    Foundation foundation;

     
    enum PartnershipAuthorization { Unknown, Authorized, Pending, Rejected, Removed }

     
    struct PartnershipContract {
         
         
        PartnershipAuthorization authorization;
         
         
         
         
        uint40 created;
         
         
        bytes symetricEncryptionEncryptedKey;
    }
     
    mapping(address => PartnershipContract) internal partnershipContracts;

     
    address[] internal knownPartnershipContracts;

     
    uint public partnershipsNumber;

     
    event PartnershipRequested();

     
    event PartnershipAccepted();

     
    constructor(
        address _foundation,
        address _token,
        uint16 _category,
        uint16 _asymetricEncryptionAlgorithm,
        uint16 _symetricEncryptionAlgorithm,
        bytes _asymetricEncryptionPublicKey,
        bytes _symetricEncryptionEncryptedKey,
        bytes _encryptedSecret
    )
        Identity(
            _foundation,
            _token,
            _category,
            _asymetricEncryptionAlgorithm,
            _symetricEncryptionAlgorithm,
            _asymetricEncryptionPublicKey,
            _symetricEncryptionEncryptedKey,
            _encryptedSecret
        )
        public
    {
        foundation = Foundation(_foundation);
        token = TalaoToken(_token);
        identityInformation.creator = msg.sender;
        identityInformation.category = _category;
        identityInformation.asymetricEncryptionAlgorithm = _asymetricEncryptionAlgorithm;
        identityInformation.symetricEncryptionAlgorithm = _symetricEncryptionAlgorithm;
        identityInformation.asymetricEncryptionPublicKey = _asymetricEncryptionPublicKey;
        identityInformation.symetricEncryptionEncryptedKey = _symetricEncryptionEncryptedKey;
        identityInformation.encryptedSecret = _encryptedSecret;
    }

     
    function isPartnershipMember() public view returns (bool) {
        return partnershipContracts[foundation.membersToContracts(msg.sender)].authorization == PartnershipAuthorization.Authorized;
    }

     
    modifier onlyPartnershipMember() {
        require(isPartnershipMember());
        _;
    }

     
    function getMyPartnershipStatus()
        external
        view
        returns (uint authorization)
    {
         
        if (foundation.membersToContracts(msg.sender) == address(0)) {
            return uint(PartnershipAuthorization.Unknown);
        } else {
            return uint(partnershipContracts[foundation.membersToContracts(msg.sender)].authorization);
        }
    }

     
    function getKnownPartnershipsContracts()
        external
        view
        onlyIdentityPurpose(20003)
        returns (address[])
    {
        return knownPartnershipContracts;
    }

     
    function getPartnership(address _hisContract)
        external
        view
        onlyIdentityPurpose(20003)
        returns (uint, uint, uint40, bytes, bytes)
    {
        (
            ,
            uint16 hisCategory,
            ,
            ,
            bytes memory hisAsymetricEncryptionPublicKey,
            ,
        ) = IdentityInterface(_hisContract).identityInformation();
        return (
            hisCategory,
            uint(partnershipContracts[_hisContract].authorization),
            partnershipContracts[_hisContract].created,
            hisAsymetricEncryptionPublicKey,
            partnershipContracts[_hisContract].symetricEncryptionEncryptedKey
        );
    }

     
    function requestPartnership(address _hisContract, bytes _ourSymetricKey)
        external
        onlyIdentityPurpose(1)
    {
         
         
         
         
         
        require(
            partnershipContracts[_hisContract].authorization == PartnershipAuthorization.Unknown ||
            partnershipContracts[_hisContract].authorization == PartnershipAuthorization.Removed
        );
         
         
        PartnershipInterface hisInterface = PartnershipInterface(_hisContract);
        bool success = hisInterface._requestPartnership(_ourSymetricKey);
         
        if (success) {
             
            if (partnershipContracts[_hisContract].authorization == PartnershipAuthorization.Unknown) {
                 
                knownPartnershipContracts.push(_hisContract);
            }
             
            partnershipContracts[_hisContract].authorization = PartnershipAuthorization.Authorized;
             
            partnershipContracts[_hisContract].created = uint40(now);
             
            addKey(keccak256(abi.encodePacked(foundation.contractsToOwners(_hisContract))), 3, 1);
             
            addKey(keccak256(abi.encodePacked(_hisContract)), 3, 1);
             
            partnershipsNumber = partnershipsNumber.add(1);
        }
    }

     
    function _requestPartnership(bytes _hisSymetricKey)
        external
        returns (bool success)
    {
        require(
            partnershipContracts[msg.sender].authorization == PartnershipAuthorization.Unknown ||
            partnershipContracts[msg.sender].authorization == PartnershipAuthorization.Removed
        );
         
        if (partnershipContracts[msg.sender].authorization == PartnershipAuthorization.Unknown) {
             
            knownPartnershipContracts.push(msg.sender);
             
            partnershipContracts[msg.sender].created = uint40(now);
        }
         
        partnershipContracts[msg.sender].authorization = PartnershipAuthorization.Pending;
         
         
        partnershipContracts[msg.sender].symetricEncryptionEncryptedKey = _hisSymetricKey;
         
        emit PartnershipRequested();
         
        success = true;
    }

     
    function authorizePartnership(address _hisContract, bytes _ourSymetricKey)
        external
        onlyIdentityPurpose(1)
    {
        require(
            partnershipContracts[_hisContract].authorization == PartnershipAuthorization.Pending,
            "Partnership must be Pending"
        );
         
        partnershipContracts[_hisContract].authorization = PartnershipAuthorization.Authorized;
         
        partnershipContracts[_hisContract].created = uint40(now);
         
        addKey(keccak256(abi.encodePacked(foundation.contractsToOwners(_hisContract))), 3, 1);
         
        addKey(keccak256(abi.encodePacked(_hisContract)), 3, 1);
         
        partnershipsNumber = partnershipsNumber.add(1);
         
        PartnershipInterface hisInterface = PartnershipInterface(_hisContract);
        hisInterface._authorizePartnership(_ourSymetricKey);
    }

     
    function _authorizePartnership(bytes _hisSymetricKey) external {
        require(
            partnershipContracts[msg.sender].authorization == PartnershipAuthorization.Authorized,
            "You have no authorized partnership"
        );
        partnershipContracts[msg.sender].symetricEncryptionEncryptedKey = _hisSymetricKey;
        emit PartnershipAccepted();
    }

     
    function rejectPartnership(address _hisContract)
        external
        onlyIdentityPurpose(1)
    {
        require(
            partnershipContracts[_hisContract].authorization == PartnershipAuthorization.Pending,
            "Partner must be Pending"
        );
        partnershipContracts[_hisContract].authorization = PartnershipAuthorization.Rejected;
    }

     
    function removePartnership(address _hisContract)
        external
        onlyIdentityPurpose(1)
    {
        require(
            (
                partnershipContracts[_hisContract].authorization == PartnershipAuthorization.Authorized ||
                partnershipContracts[_hisContract].authorization == PartnershipAuthorization.Rejected
            ),
            "Partnership must be Authorized or Rejected"
        );
         
        PartnershipInterface hisInterface = PartnershipInterface(_hisContract);
        bool success = hisInterface._removePartnership();
         
        if (success) {
             
            if (partnershipContracts[_hisContract].authorization == PartnershipAuthorization.Authorized) {
                 
                delete partnershipContracts[_hisContract].created;
                 
                delete partnershipContracts[_hisContract].symetricEncryptionEncryptedKey;
                 
                partnershipsNumber = partnershipsNumber.sub(1);
            }
             
            if (keyHasPurpose(keccak256(abi.encodePacked(foundation.contractsToOwners(_hisContract))), 3)) {
                removeKey(keccak256(abi.encodePacked(foundation.contractsToOwners(_hisContract))), 3);
            }
             
            if (keyHasPurpose(keccak256(abi.encodePacked(_hisContract)), 3)) {
                removeKey(keccak256(abi.encodePacked(_hisContract)), 3);
            }
             
             
             
             
            partnershipContracts[_hisContract].authorization = PartnershipAuthorization.Removed;
        }
    }

     
    function _removePartnership() external returns (bool success) {
         
         
        if (partnershipContracts[msg.sender].authorization == PartnershipAuthorization.Authorized) {
             
            delete partnershipContracts[msg.sender].created;
             
            delete partnershipContracts[msg.sender].symetricEncryptionEncryptedKey;
             
            partnershipsNumber = partnershipsNumber.sub(1);
        }
         
         
         

         
        partnershipContracts[msg.sender].authorization = PartnershipAuthorization.Removed;
         
        success = true;
    }

     
    function cleanupPartnership() internal returns (bool success) {
         
        for (uint i = 0; i < knownPartnershipContracts.length; i++) {
             
            if (partnershipContracts[knownPartnershipContracts[i]].authorization == PartnershipAuthorization.Authorized) {
                 
                PartnershipInterface hisInterface = PartnershipInterface(knownPartnershipContracts[i]);
                hisInterface._removePartnership();
            }
        }
        success = true;
    }
}


 
interface PartnershipInterface {
    function _requestPartnership(bytes) external view returns (bool);
    function _authorizePartnership(bytes) external;
    function _removePartnership() external returns (bool success);
    function getKnownPartnershipsContracts() external returns (address[]);
    function getPartnership(address)
        external
        returns (uint, uint, uint40, bytes, bytes);
}

 

 
contract Permissions is Partnership {

     
    Foundation foundation;

     
    TalaoToken public token;

     
    constructor(
        address _foundation,
        address _token,
        uint16 _category,
        uint16 _asymetricEncryptionAlgorithm,
        uint16 _symetricEncryptionAlgorithm,
        bytes _asymetricEncryptionPublicKey,
        bytes _symetricEncryptionEncryptedKey,
        bytes _encryptedSecret
    )
        Partnership(
            _foundation,
            _token,
            _category,
            _asymetricEncryptionAlgorithm,
            _symetricEncryptionAlgorithm,
            _asymetricEncryptionPublicKey,
            _symetricEncryptionEncryptedKey,
            _encryptedSecret
        )
        public
    {
        foundation = Foundation(_foundation);
        token = TalaoToken(_token);
        identityInformation.creator = msg.sender;
        identityInformation.category = _category;
        identityInformation.asymetricEncryptionAlgorithm = _asymetricEncryptionAlgorithm;
        identityInformation.symetricEncryptionAlgorithm = _symetricEncryptionAlgorithm;
        identityInformation.asymetricEncryptionPublicKey = _asymetricEncryptionPublicKey;
        identityInformation.symetricEncryptionEncryptedKey = _symetricEncryptionEncryptedKey;
        identityInformation.encryptedSecret = _encryptedSecret;
    }

     
    function isMember() public view returns (bool) {
        return foundation.membersToContracts(msg.sender) == address(this);
    }

     
    function isReader() public view returns (bool) {
         
         
        (uint accessPrice,,,) = token.data(identityOwner());
         
         
         
         
         
         
         
         
         
        return(
            token.hasVaultAccess(identityOwner(), msg.sender) ||
            (
                token.hasVaultAccess(identityOwner(), identityOwner()) &&
                (
                    isMember() ||
                    isPartnershipMember() ||
                    hasIdentityPurpose(20001) ||
                    (accessPrice == 0 && msg.sender != address(0))
                )
            )
        );
    }

     
    modifier onlyReader() {
        require(isReader(), "Access denied");
        _;
    }
}

 

 
contract Profile is Permissions {

     
     
     
     
    struct PrivateProfile {
         
        bytes email;

         
        bytes mobile;
    }
    PrivateProfile internal privateProfile;

     
    function getPrivateProfile()
        external
        view
        onlyReader
        returns (bytes, bytes)
    {
        return (
            privateProfile.email,
            privateProfile.mobile
        );
    }

     
    function setPrivateProfile(
        bytes _privateEmail,
        bytes _mobile
    )
        external
        onlyIdentityPurpose(20002)
    {
        privateProfile.email = _privateEmail;
        privateProfile.mobile = _mobile;
    }
}

 

 
contract Documents is Permissions {

    using SafeMathUpdated for uint;

     
    struct Document {

         
         
        bool published;

         
         
        bool encrypted;

         
         
        uint16 index;

         
         
         
         
         
        uint16 docType;

         
         
        uint16 docTypeVersion;

         
         
        uint16 related;

         
         
         
        uint16 fileLocationEngine;

         
         
        address issuer;

         
         
        bytes32 fileChecksum;

         
        uint40 expires;

         
         
         
        bytes fileLocationHash;
    }

     
    mapping(uint => Document) internal documents;

     
    uint[] internal documentsIndex;

     
    uint internal documentsCounter;

     
    event DocumentAdded (uint id);

     
    event DocumentRemoved (uint id);

     
    event CertificateIssued (bytes32 indexed checksum, address indexed issuer, uint id);

     
    event CertificateAccepted (bytes32 indexed checksum, address indexed issuer, uint id);

     
    function getDocument(uint _id)
        external
        view
        onlyReader
        returns (
            uint16,
            uint16,
            uint40,
            address,
            bytes32,
            uint16,
            bytes,
            bool,
            uint16
        )
    {
        Document memory doc = documents[_id];
        require(doc.published);
        return(
            doc.docType,
            doc.docTypeVersion,
            doc.expires,
            doc.issuer,
            doc.fileChecksum,
            doc.fileLocationEngine,
            doc.fileLocationHash,
            doc.encrypted,
            doc.related
        );
    }

     
    function getDocuments() external view onlyReader returns (uint[]) {
        return documentsIndex;
    }

     
    function createDocument(
        uint16 _docType,
        uint16 _docTypeVersion,
        uint40 _expires,
        bytes32 _fileChecksum,
        uint16 _fileLocationEngine,
        bytes _fileLocationHash,
        bool _encrypted
    )
        external
        onlyIdentityPurpose(20002)
        returns(uint)
    {
        require(_docType < 60000);
        _createDocument(
            _docType,
            _docTypeVersion,
            _expires,
            msg.sender,
            _fileChecksum,
            _fileLocationEngine,
            _fileLocationHash,
            _encrypted,
            0
        );
        return documentsCounter;
    }

     
    function issueCertificate(
        uint16 _docType,
        uint16 _docTypeVersion,
        bytes32 _fileChecksum,
        uint16 _fileLocationEngine,
        bytes _fileLocationHash,
        bool _encrypted,
        uint16 _related
    )
        external
        returns(uint)
    {
        require(
            keyHasPurpose(keccak256(abi.encodePacked(foundation.membersToContracts(msg.sender))), 3) &&
            isActiveIdentity() &&
            _docType >= 60000
        );
        uint id = _createDocument(
            _docType,
            _docTypeVersion,
            0,
            foundation.membersToContracts(msg.sender),
            _fileChecksum,
            _fileLocationEngine,
            _fileLocationHash,
            _encrypted,
            _related
        );
        emit CertificateIssued(_fileChecksum, foundation.membersToContracts(msg.sender), id);
        return id;
    }

     
    function acceptCertificate(uint _id) external onlyIdentityPurpose(20002) {
        Document storage doc = documents[_id];
        require(!doc.published && doc.docType >= 60000);
         
        doc.index = uint16(documentsIndex.push(_id).sub(1));
         
        doc.published = true;
         
        if (documents[doc.related].published) {
            _deleteDocument(doc.related);
        }
         
        emit CertificateAccepted(doc.fileChecksum, doc.issuer, _id);
    }

     
    function _createDocument(
        uint16 _docType,
        uint16 _docTypeVersion,
        uint40 _expires,
        address _issuer,
        bytes32 _fileChecksum,
        uint16 _fileLocationEngine,
        bytes _fileLocationHash,
        bool _encrypted,
        uint16 _related
    )
        internal
        returns(uint)
    {
         
        documentsCounter = documentsCounter.add(1);
         
        Document storage doc = documents[documentsCounter];
         
         
         
         
        if (_docType >= 60000) {
            doc.related = _related;
        } else {
             
            doc.index = uint16(documentsIndex.push(documentsCounter).sub(1));
             
            doc.published = true;
        }
         
        doc.encrypted = _encrypted;
        doc.docType = _docType;
        doc.docTypeVersion = _docTypeVersion;
        doc.expires = _expires;
        doc.fileLocationEngine = _fileLocationEngine;
        doc.issuer = _issuer;
        doc.fileChecksum = _fileChecksum;
        doc.fileLocationHash = _fileLocationHash;
         
        emit DocumentAdded(documentsCounter);
         
        return documentsCounter;
    }

     
    function deleteDocument (uint _id) external onlyIdentityPurpose(20002) {
        _deleteDocument(_id);
    }

     
    function _deleteDocument (uint _id) internal {
        Document storage docToDelete = documents[_id];
        require (_id > 0);
        require(docToDelete.published);
         
        if (docToDelete.index < (documentsIndex.length).sub(1)) {
             
            uint lastDocId = documentsIndex[(documentsIndex.length).sub(1)];
            Document storage lastDoc = documents[lastDocId];
             
            documentsIndex[docToDelete.index] = lastDocId;
             
            lastDoc.index = docToDelete.index;
        }
         
        documentsIndex.length --;
         
        docToDelete.published = false;
         
        emit DocumentRemoved(_id);
    }

     
    function updateDocument(
        uint _id,
        uint16 _docType,
        uint16 _docTypeVersion,
        uint40 _expires,
        bytes32 _fileChecksum,
        uint16 _fileLocationEngine,
        bytes _fileLocationHash,
        bool _encrypted
    )
        external
        onlyIdentityPurpose(20002)
        returns (uint)
    {
        require(_docType < 60000);
        _deleteDocument(_id);
        _createDocument(
            _docType,
            _docTypeVersion,
            _expires,
            msg.sender,
            _fileChecksum,
            _fileLocationEngine,
            _fileLocationHash,
            _encrypted,
            0
        );
        return documentsCounter;
    }
}


 
interface DocumentsInterface {
    function getDocuments() external returns(uint[]);
    function getDocument(uint)
        external
        returns (
            uint16,
            uint16,
            uint40,
            address,
            bytes32,
            uint16,
            bytes,
            bool,
            uint16
        );
}

 

 
contract Workspace is Permissions, Profile, Documents {

     
    constructor(
        address _foundation,
        address _token,
        uint16 _category,
        uint16 _asymetricEncryptionAlgorithm,
        uint16 _symetricEncryptionAlgorithm,
        bytes _asymetricEncryptionPublicKey,
        bytes _symetricEncryptionEncryptedKey,
        bytes _encryptedSecret
    )
        Permissions(
            _foundation,
            _token,
            _category,
            _asymetricEncryptionAlgorithm,
            _symetricEncryptionAlgorithm,
            _asymetricEncryptionPublicKey,
            _symetricEncryptionEncryptedKey,
            _encryptedSecret
        )
        public
    {
        foundation = Foundation(_foundation);
        token = TalaoToken(_token);
        identityInformation.creator = msg.sender;
        identityInformation.category = _category;
        identityInformation.asymetricEncryptionAlgorithm = _asymetricEncryptionAlgorithm;
        identityInformation.symetricEncryptionAlgorithm = _symetricEncryptionAlgorithm;
        identityInformation.asymetricEncryptionPublicKey = _asymetricEncryptionPublicKey;
        identityInformation.symetricEncryptionEncryptedKey = _symetricEncryptionEncryptedKey;
        identityInformation.encryptedSecret = _encryptedSecret;
    }

     
    function destroyWorkspace() external onlyIdentityOwner {
        if (cleanupPartnership() && foundation.renounceOwnershipInFoundation()) {
            selfdestruct(msg.sender);
        }
    }

     
    function() public {
        revert();
    }
}