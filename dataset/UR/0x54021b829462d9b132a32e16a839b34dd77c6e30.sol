 

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
    returns(address);

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
    address _broker,
    address _custodian,
    address _registry,
    uint256 _totalSupply  
  )
    external
    returns (bool);

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

   


   

   
  function getContractAddress
  (
    string _name
  )
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

 

 

pragma solidity 0.4.24;



 
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
      bytes4(keccak256("logProxyUpgraded(address,address)")),
      _oldMaster, _newMaster
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
      bytes4(keccak256("logProxyUpgraded(address,address)")),
      _oldMaster, _newMaster
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

   
  address[] private brokerAddressList;
  address[] private tokenAddressList;

   
  mapping (address => EntityState) private tokenMap;
  mapping (address => EntityState) private brokerMap;

  event BrokerAdded(address indexed broker);
  event BrokerRemoved(address indexed broker);
  event BrokerStatusChanged(address indexed broker, bool active);

  event TokenAdded(address indexed token);
  event TokenRemoved(address indexed token);
  event TokenStatusChanged(address indexed token, bool active);

  modifier isNewBroker(address _brokerAddress) {
    require(_brokerAddress != address(0));
    require(brokerMap[_brokerAddress].index == 0);
    _;
  }

  modifier onlyActiveBroker() {
    EntityState memory entity = brokerMap[msg.sender];
    require(entity.active);
    _;
  }

  constructor(
    address _registryAddress
  )
    public
  {
    require(_registryAddress != address(0));
    registry = IRegistry(_registryAddress);
  }

   
   
   

  function doesEntityExist(address _entityAddress, EntityState entity)
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

   
   
   

   
  function getBrokerAddressList()
    public
    view
    returns (address[])
  {
    return brokerAddressList;
  }

   
  function addBroker(address _brokerAddress)
    public
    onlyOwner
    isNewBroker(_brokerAddress)
  {
    brokerMap[_brokerAddress] = addEntity(
      _brokerAddress,
      brokerAddressList,
      true
    );

    emit BrokerAdded(_brokerAddress);
  }

   
  function removeBroker(address _brokerAddress)
    public
    onlyOwner
  {
    require(doesEntityExist(_brokerAddress, brokerMap[_brokerAddress]));

    address addressToUpdate;
    uint256 indexUpdate;
    (addressToUpdate, indexUpdate) = removeEntity(brokerMap[_brokerAddress], brokerAddressList);
    brokerMap[addressToUpdate].index = indexUpdate;
    delete brokerMap[_brokerAddress];

    emit BrokerRemoved(_brokerAddress);
  }

   
  function listBroker(address _brokerAddress)
    public
    onlyOwner
  {
    require(doesEntityExist(_brokerAddress, brokerMap[_brokerAddress]));

    setEntityActiveValue(brokerMap[_brokerAddress], true);
    emit BrokerStatusChanged(_brokerAddress, true);
  }

   
  function delistBroker(address _brokerAddress)
    public
    onlyOwner
  {
    require(doesEntityExist(_brokerAddress, brokerMap[_brokerAddress]));

    setEntityActiveValue(brokerMap[_brokerAddress], false);
    emit BrokerStatusChanged(_brokerAddress, false);
  }

  function getBrokerStatus(address _brokerAddress)
    public
    view
    returns (bool)
  {
    require(doesEntityExist(_brokerAddress, brokerMap[_brokerAddress]));

    return brokerMap[_brokerAddress].active;
  }

  function isRegisteredBroker(address _brokerAddress)
    external
    view
    returns (bool)
  {
    return doesEntityExist(_brokerAddress, brokerMap[_brokerAddress]);
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

   
  function addToken
  (
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
    onlyActiveBroker
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

  function getTokenStatus(address _tokenAddress)
    public
    view
    returns (bool)
  {
    require(doesEntityExist(_tokenAddress, tokenMap[_tokenAddress]));

    return tokenMap[_tokenAddress].active;
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

   
  function upgradeToken(
    PoaProxy _proxyToken
  )
    external
    onlyOwner
    returns (bool)
  {
    _proxyToken.proxyChangeTokenMaster(
      registry.getContractAddress("PoaTokenMaster")
    );
  }

   
  function upgradeCrowdsale(
    PoaProxy _proxyToken
  )
    external
    onlyOwner
    returns (bool)
  {
    _proxyToken.proxyChangeCrowdsaleMaster(
      registry.getContractAddress("PoaCrowdsaleMaster")
    );
  }
}