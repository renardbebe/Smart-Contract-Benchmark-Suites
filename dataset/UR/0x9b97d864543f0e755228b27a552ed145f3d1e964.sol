 

pragma solidity 0.4.24;

 

 
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

 

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
     
     
     
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

 

 
interface IRegistry {
  function owner()
    external
    returns (address);

  function updateContractAddress(
    string _name,
    address _address
  )
    external
    returns (address);

  function getContractAddress(
    string _name
  )
    external
    view
    returns (address);
}

 

interface IPoaToken {
  function initializeToken
  (
    bytes32 _name32,  
    bytes32 _symbol32,  
    address _issuer,
    address _custodian,
    address _registry,
    uint256 _totalSupply  
  )
    external
    returns (bool);

  function issuer()
    external
    view
    returns (address);

  function startPreFunding()
    external
    returns (bool);

  function pause()
    external;

  function unpause()
    external;

  function terminate()
    external
    returns (bool);

  function proofOfCustody()
    external
    view
    returns (string);
}

 

interface IPoaCrowdsale {
  function initializeCrowdsale(
    bytes32 _fiatCurrency32,                 
    uint256 _startTimeForFundingPeriod,      
    uint256 _durationForFiatFundingPeriod,   
    uint256 _durationForEthFundingPeriod,    
    uint256 _durationForActivationPeriod,    
    uint256 _fundingGoalInCents              
  )
    external
    returns (bool);
}

 

 
contract PoaProxyCommon {
   

   
  address public poaTokenMaster;

   
  address public poaCrowdsaleMaster;

   
  address public registry;

   


   

   
  function getContractAddress(string _name)
    public
    view
    returns (address _contractAddress)
  {
    bytes4 _signature = bytes4(keccak256("getContractAddress32(bytes32)"));
    bytes32 _name32 = keccak256(abi.encodePacked(_name));

    assembly {
      let _registry := sload(registry_slot)  
      let _pointer := mload(0x40)           
      mstore(_pointer, _signature)          
      mstore(add(_pointer, 0x04), _name32)  

       
      let result := staticcall(
        gas,        
        _registry,  
        _pointer,   
        0x24,       
        _pointer,   
        0x20        
      )

       
      if iszero(result) {
        revert(0, 0)
      }

      _contractAddress := mload(_pointer)  
      mstore(0x40, add(_pointer, 0x24))    
    }
  }

   
}

 

 
contract PoaProxy is PoaProxyCommon {
  uint8 public constant version = 1;

  event ProxyUpgraded(address upgradedFrom, address upgradedTo);

   
  constructor(
    address _poaTokenMaster,
    address _poaCrowdsaleMaster,
    address _registry
  )
    public
  {
     
    require(_poaTokenMaster != address(0));
    require(_poaCrowdsaleMaster != address(0));
    require(_registry != address(0));

     
    poaTokenMaster = _poaTokenMaster;
    poaCrowdsaleMaster = _poaCrowdsaleMaster;
    registry = _registry;
  }

   

   
  function isContract(address _address)
    private
    view
    returns (bool)
  {
    uint256 _size;
    assembly { _size := extcodesize(_address) }

    return _size > 0;
  }

   


   

   
  function proxyChangeTokenMaster(address _newMaster)
    public
    returns (bool)
  {
    require(msg.sender == getContractAddress("PoaManager"));
    require(_newMaster != address(0));
    require(poaTokenMaster != _newMaster);
    require(isContract(_newMaster));
    address _oldMaster = poaTokenMaster;
    poaTokenMaster = _newMaster;

    emit ProxyUpgraded(_oldMaster, _newMaster);
    getContractAddress("PoaLogger").call(
      abi.encodeWithSignature(
        "logProxyUpgraded(address,address)",
        _oldMaster,
        _newMaster
      )
    );

    return true;
  }

   
  function proxyChangeCrowdsaleMaster(address _newMaster)
    public
    returns (bool)
  {
    require(msg.sender == getContractAddress("PoaManager"));
    require(_newMaster != address(0));
    require(poaCrowdsaleMaster != _newMaster);
    require(isContract(_newMaster));
    address _oldMaster = poaCrowdsaleMaster;
    poaCrowdsaleMaster = _newMaster;

    emit ProxyUpgraded(_oldMaster, _newMaster);
    getContractAddress("PoaLogger").call(
      abi.encodeWithSignature(
        "logProxyUpgraded(address,address)",
        _oldMaster,
        _newMaster
      )
    );

    return true;
  }

   

   
  function()
    external
    payable
  {
    assembly {
       
      let _poaTokenMaster := sload(poaTokenMaster_slot)

       
      calldatacopy(
        0x0,  
        0x0,  
        calldatasize  
      )

       
      let result := delegatecall(
        gas,  
        _poaTokenMaster,  
        0x0,  
        calldatasize,  
        0x0,  
        0  
      )

       
      if iszero(result) {
         
        revert(0, 0)
      }

       
      returndatacopy(
        0x0,  
        0x0,   
        returndatasize  
      )
       
      return(
        0x0,
        returndatasize
      )
    }
  }
}

 

contract PoaManager is Ownable {
  using SafeMath for uint256;

  uint256 constant version = 1;

  IRegistry public registry;

  struct EntityState {
    uint256 index;
    bool active;
  }

   
  address[] private issuerAddressList;
  address[] private tokenAddressList;

   
  mapping (address => EntityState) private tokenMap;
  mapping (address => EntityState) private issuerMap;

  event IssuerAdded(address indexed issuer);
  event IssuerRemoved(address indexed issuer);
  event IssuerStatusChanged(address indexed issuer, bool active);

  event TokenAdded(address indexed token);
  event TokenRemoved(address indexed token);
  event TokenStatusChanged(address indexed token, bool active);

  modifier isNewIssuer(address _issuerAddress) {
    require(_issuerAddress != address(0));
    require(issuerMap[_issuerAddress].index == 0);
    _;
  }

  modifier onlyActiveIssuer() {
    EntityState memory entity = issuerMap[msg.sender];
    require(entity.active);
    _;
  }

  constructor(address _registryAddress)
    public
  {
    require(_registryAddress != address(0));
    registry = IRegistry(_registryAddress);
  }

   
   
   

  function doesEntityExist(
    address _entityAddress,
    EntityState entity
  )
    private
    pure
    returns (bool)
  {
    return (_entityAddress != address(0) && entity.index != 0);
  }

  function addEntity(
    address _entityAddress,
    address[] storage entityList,
    bool _active
  )
    private
    returns (EntityState)
  {
    entityList.push(_entityAddress);
     
     
    uint256 index = entityList.length;
    EntityState memory entity = EntityState(index, _active);

    return entity;
  }

  function removeEntity(
    EntityState _entityToRemove,
    address[] storage _entityList
  )
    private
    returns (address, uint256)
  {
     
    uint256 index = _entityToRemove.index.sub(1);

     
    _entityList[index] = _entityList[_entityList.length - 1];

     
     
     
    address entityToSwapAddress = _entityList[index];

     
    _entityList.length--;

    return (entityToSwapAddress, _entityToRemove.index);
  }

  function setEntityActiveValue(
    EntityState storage entity,
    bool _active
  )
    private
  {
    require(entity.active != _active);
    entity.active = _active;
  }

   
   
   

   
  function getIssuerAddressList()
    public
    view
    returns (address[])
  {
    return issuerAddressList;
  }

   
  function addIssuer(address _issuerAddress)
    public
    onlyOwner
    isNewIssuer(_issuerAddress)
  {
    issuerMap[_issuerAddress] = addEntity(
      _issuerAddress,
      issuerAddressList,
      true
    );

    emit IssuerAdded(_issuerAddress);
  }

   
  function removeIssuer(address _issuerAddress)
    public
    onlyOwner
  {
    require(doesEntityExist(_issuerAddress, issuerMap[_issuerAddress]));

    address addressToUpdate;
    uint256 indexUpdate;
    (addressToUpdate, indexUpdate) = removeEntity(issuerMap[_issuerAddress], issuerAddressList);
    issuerMap[addressToUpdate].index = indexUpdate;
    delete issuerMap[_issuerAddress];

    emit IssuerRemoved(_issuerAddress);
  }

   
  function listIssuer(address _issuerAddress)
    public
    onlyOwner
  {
    require(doesEntityExist(_issuerAddress, issuerMap[_issuerAddress]));

    setEntityActiveValue(issuerMap[_issuerAddress], true);
    emit IssuerStatusChanged(_issuerAddress, true);
  }

   
  function delistIssuer(address _issuerAddress)
    public
    onlyOwner
  {
    require(doesEntityExist(_issuerAddress, issuerMap[_issuerAddress]));

    setEntityActiveValue(issuerMap[_issuerAddress], false);
    emit IssuerStatusChanged(_issuerAddress, false);
  }

  function isActiveIssuer(address _issuerAddress)
    public
    view
    returns (bool)
  {
    require(doesEntityExist(_issuerAddress, issuerMap[_issuerAddress]));

    return issuerMap[_issuerAddress].active;
  }

  function isRegisteredIssuer(address _issuerAddress)
    external
    view
    returns (bool)
  {
    return doesEntityExist(_issuerAddress, issuerMap[_issuerAddress]);
  }

   
   
   

   
  function getTokenAddressList()
    public
    view
    returns (address[])
  {
    return tokenAddressList;
  }

  function createPoaTokenProxy()
    private
    returns (address _proxyContract)
  {
    address _poaTokenMaster = registry.getContractAddress("PoaTokenMaster");
    address _poaCrowdsaleMaster = registry.getContractAddress("PoaCrowdsaleMaster");
    _proxyContract = new PoaProxy(_poaTokenMaster, _poaCrowdsaleMaster, address(registry));
  }

   
  function addNewToken(
    bytes32 _name32,
    bytes32 _symbol32,
    bytes32 _fiatCurrency32,
    address _custodian,
    uint256 _totalSupply,
    uint256 _startTimeForFundingPeriod,
    uint256 _durationForFiatFundingPeriod,
    uint256 _durationForEthFundingPeriod,
    uint256 _durationForActivationPeriod,
    uint256 _fundingGoalInCents
  )
    public
    onlyActiveIssuer
    returns (address)
  {
    address _tokenAddress = createPoaTokenProxy();

    IPoaToken(_tokenAddress).initializeToken(
      _name32,
      _symbol32,
      msg.sender,
      _custodian,
      registry,
      _totalSupply
    );

    IPoaCrowdsale(_tokenAddress).initializeCrowdsale(
      _fiatCurrency32,
      _startTimeForFundingPeriod,
      _durationForFiatFundingPeriod,
      _durationForEthFundingPeriod,
      _durationForActivationPeriod,
      _fundingGoalInCents
    );

    tokenMap[_tokenAddress] = addEntity(
      _tokenAddress,
      tokenAddressList,
      false
    );

    emit TokenAdded(_tokenAddress);

    return _tokenAddress;
  }

   
  function addExistingToken(address _tokenAddress, bool _isListed)
    external
    onlyOwner
  {
    require(!doesEntityExist(_tokenAddress, tokenMap[_tokenAddress]));
     
     
    require(isActiveIssuer(IPoaToken(_tokenAddress).issuer()));

    tokenMap[_tokenAddress] = addEntity(
      _tokenAddress,
      tokenAddressList,
      _isListed
    );
  }

   
  function removeToken(address _tokenAddress)
    public
    onlyOwner
  {
    require(doesEntityExist(_tokenAddress, tokenMap[_tokenAddress]));

    address addressToUpdate;
    uint256 indexUpdate;
    (addressToUpdate, indexUpdate) = removeEntity(tokenMap[_tokenAddress], tokenAddressList);
    tokenMap[addressToUpdate].index = indexUpdate;
    delete tokenMap[_tokenAddress];

    emit TokenRemoved(_tokenAddress);
  }

   
  function listToken(address _tokenAddress)
    public
    onlyOwner
  {
    require(doesEntityExist(_tokenAddress, tokenMap[_tokenAddress]));

    setEntityActiveValue(tokenMap[_tokenAddress], true);
    emit TokenStatusChanged(_tokenAddress, true);
  }

   
  function delistToken(address _tokenAddress)
    public
    onlyOwner
  {
    require(doesEntityExist(_tokenAddress, tokenMap[_tokenAddress]));

    setEntityActiveValue(tokenMap[_tokenAddress], false);
    emit TokenStatusChanged(_tokenAddress, false);
  }

  function isActiveToken(address _tokenAddress)
    public
    view
    returns (bool)
  {
    require(doesEntityExist(_tokenAddress, tokenMap[_tokenAddress]));

    return tokenMap[_tokenAddress].active;
  }

  function isRegisteredToken(address _tokenAddress)
    external
    view
    returns (bool)
  {
    return doesEntityExist(_tokenAddress, tokenMap[_tokenAddress]);
  }

   
   
   

   
  function pauseToken(address _tokenAddress)
    public
    onlyOwner
  {
    IPoaToken(_tokenAddress).pause();
  }

   
  function unpauseToken(IPoaToken _tokenAddress)
    public
    onlyOwner
  {
    _tokenAddress.unpause();
  }

   
  function terminateToken(IPoaToken _tokenAddress)
    public
    onlyOwner
  {
    _tokenAddress.terminate();
  }

   
  function upgradeToken(PoaProxy _proxyToken)
    external
    onlyOwner
    returns (bool)
  {
    _proxyToken.proxyChangeTokenMaster(
      registry.getContractAddress("PoaTokenMaster")
    );

    return true;
  }

   
  function upgradeCrowdsale(PoaProxy _proxyToken)
    external
    onlyOwner
    returns (bool)
  {
    _proxyToken.proxyChangeCrowdsaleMaster(
      registry.getContractAddress("PoaCrowdsaleMaster")
    );

    return true;
  }
}