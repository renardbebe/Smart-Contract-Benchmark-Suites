 

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

 

interface IExchangeRateProvider {
  function sendQuery(
    string _queryString,
    uint256 _callInterval,
    uint256 _callbackGasLimit,
    string _queryType
  )
    external
    payable
    returns (bool);

  function setCallbackGasPrice(uint256 _gasPrice)
    external
    returns (bool);

  function selfDestruct(address _address)
    external;
}

 

 

 
contract ExchangeRates is Ownable {
  using SafeMath for uint256;

  uint8 public constant version = 1;
  uint256 public constant permilleDenominator = 1000;
   
  IRegistry private registry;
   
  bool public ratesActive = true;

  struct Settings {
    string queryString;
    uint256 callInterval;
    uint256 callbackGasLimit;
     
     
    uint256 ratePenalty;
  }

   
   
   
  mapping (bytes32 => uint256) private rates;
   
   
  mapping (bytes32 => string) public queryTypes;
   
   
  mapping (string => Settings) private currencySettings;

  event RateUpdated(string currency, uint256 rate);
  event NotEnoughBalance();
  event QuerySent(string currency);
  event SettingsUpdated(string currency);

   
  modifier onlyContract(string _contractName)
  {
    require(
      msg.sender == registry.getContractAddress(_contractName)
    );
    _;
  }

   
  constructor(
    address _registryAddress
  )
    public
    payable
  {
    require(_registryAddress != address(0));
    registry = IRegistry(_registryAddress);
    owner = msg.sender;
  }

   
   
  function fetchRate(string _queryType)
    external
    onlyOwner
    payable
    returns (bool)
  {
     
    IExchangeRateProvider provider = IExchangeRateProvider(
      registry.getContractAddress("ExchangeRateProvider")
    );

     
    uint256 _callInterval;
    uint256 _callbackGasLimit;
    string memory _queryString;
    uint256 _ratePenalty;
    (
      _callInterval,
      _callbackGasLimit,
      _queryString,
      _ratePenalty  
    ) = getCurrencySettings(_queryType);

     
    require(bytes(_queryString).length > 0);

     
     
     
     
    provider.sendQuery.value(msg.value)(
      _queryString,
      _callInterval,
      _callbackGasLimit,
      _queryType
    );
    return true;
  }

   
   
   

   
   
   
  function setQueryId(
    bytes32 _queryId,
    string _queryType
  )
    external
    onlyContract("ExchangeRateProvider")
    returns (bool)
  {
    if (_queryId[0] != 0x0 && bytes(_queryType)[0] != 0x0) {
      emit QuerySent(_queryType);
      queryTypes[_queryId] = _queryType;
    } else {
      emit NotEnoughBalance();
    }
    return true;
  }

   
   
   
  function setRate(
    bytes32 _queryId,
    uint256 _rateInCents
  )
    external
    onlyContract("ExchangeRateProvider")
    returns (bool)
  {
     
    string memory _currencyName = queryTypes[_queryId];
     
     
    require(bytes(_currencyName).length > 0);
     
    uint256 _penaltyInPermille = currencySettings[toUpperCase(_currencyName)].ratePenalty;
    uint256 _penalizedRate = _rateInCents
      .mul(permilleDenominator.sub(_penaltyInPermille))
      .div(permilleDenominator);
     
    delete queryTypes[_queryId];
     
    rates[keccak256(abi.encodePacked(_currencyName))] = _penalizedRate;
     
    emit RateUpdated(
      _currencyName,
      _penalizedRate
    );

    return true;
  }

   
   
   

   
  function setCurrencySettings(
    string _currencyName,
    string _queryString,
    uint256 _callInterval,
    uint256 _callbackGasLimit,
    uint256 _ratePenalty
  )
    external
    onlyOwner
    returns (bool)
  {
     
    require(_ratePenalty < 1000);
     
    currencySettings[toUpperCase(_currencyName)] = Settings(
      _queryString,
      _callInterval,
      _callbackGasLimit,
      _ratePenalty
    );
    emit SettingsUpdated(_currencyName);
    return true;
  }

   
  function setCurrencySettingQueryString(
    string _currencyName,
    string _queryString
  )
    external
    onlyOwner
    returns (bool)
  {
    Settings storage _settings = currencySettings[toUpperCase(_currencyName)];
    _settings.queryString = _queryString;
    emit SettingsUpdated(_currencyName);
    return true;
  }

   
  function setCurrencySettingCallInterval(
    string _currencyName,
    uint256 _callInterval
  )
    external
    onlyOwner
    returns (bool)
  {
    Settings storage _settings = currencySettings[toUpperCase(_currencyName)];
    _settings.callInterval = _callInterval;
    emit SettingsUpdated(_currencyName);
    return true;
  }

   
  function setCurrencySettingCallbackGasLimit(
    string _currencyName,
    uint256 _callbackGasLimit
  )
    external
    onlyOwner
    returns (bool)
  {
    Settings storage _settings = currencySettings[toUpperCase(_currencyName)];
    _settings.callbackGasLimit = _callbackGasLimit;
    emit SettingsUpdated(_currencyName);
    return true;
  }

   
  function setCurrencySettingRatePenalty(
    string _currencyName,
    uint256 _ratePenalty
  )
    external
    onlyOwner
    returns (bool)
  {
     
    require(_ratePenalty < 1000);

    Settings storage _settings = currencySettings[toUpperCase(_currencyName)];
    _settings.ratePenalty = _ratePenalty;
    emit SettingsUpdated(_currencyName);
    return true;
  }

   
  function setCallbackGasPrice(uint256 _gasPrice)
    external
    onlyOwner
    returns (bool)
  {
     
    IExchangeRateProvider provider = IExchangeRateProvider(
      registry.getContractAddress("ExchangeRateProvider")
    );
    provider.setCallbackGasPrice(_gasPrice);
    emit SettingsUpdated("ALL");
    return true;
  }

   
   
  function toggleRatesActive()
    external
    onlyOwner
    returns (bool)
  {
    ratesActive = !ratesActive;
    emit SettingsUpdated("ALL");
    return true;
  }

   
   
   

   
   
   

   
  function getCurrencySettings(string _queryTypeString)
    public
    view
    returns (uint256, uint256, string, uint256)
  {
    Settings memory _settings = currencySettings[_queryTypeString];
    return (
      _settings.callInterval,
      _settings.callbackGasLimit,
      _settings.queryString,
      _settings.ratePenalty
    );
  }

   
  function getRate(string _queryTypeString)
    external
    view
    returns (uint256)
  {
    uint256 _rate = rates[keccak256(abi.encodePacked(toUpperCase(_queryTypeString)))];
    require(_rate > 0);
    return _rate;
  }

   
   
  function getRate32(bytes32 _queryType32)
    external
    view
    returns (uint256)
  {
    uint256 _rate = rates[_queryType32];
    require(_rate > 0);
    return _rate;
  }

   
   
   

   
   
   

   
   
  function toUpperCase(string _base)
    public
    pure
    returns (string)
  {
    bytes memory _stringBytes = bytes(_base);
    for (
      uint _byteCounter = 0;
      _byteCounter < _stringBytes.length;
      _byteCounter++
    ) {
      if (
        _stringBytes[_byteCounter] >= 0x61 &&
        _stringBytes[_byteCounter] <= 0x7A
      ) {
        _stringBytes[_byteCounter] = bytes1(
          uint8(_stringBytes[_byteCounter]) - 32
        );
      }
    }
    return string(_stringBytes);
  }

   
   
   

   
   
  function killProvider(address _address)
    public
    onlyOwner
  {
     
    IExchangeRateProvider provider = IExchangeRateProvider(
      registry.getContractAddress("ExchangeRateProvider")
    );
    provider.selfDestruct(_address);
  }
}