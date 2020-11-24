 

 

 

pragma solidity ^0.4.4;
 

 



 
 
contract Owned {
   
  modifier onlyowner() {
    if (msg.sender != owner) {
      throw;
    }

    _;
  }

   
  address public owner;
}

 


 
 


contract Token {

     
    function totalSupply() constant returns (uint256 supply) {}

     
     
    function balanceOf(address _owner) constant returns (uint256 balance) {}

     
     
     
     
    function transfer(address _to, uint256 _value) returns (bool success) {}

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}

     
     
     
     
    function approve(address _spender, uint256 _value) returns (bool success) {}

     
     
     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


contract StandardToken is Token {

    function transfer(address _to, uint256 _value) returns (bool) {
         
         
         
         
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
         
         
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply;
}


 

 



 
 
contract Issued {
   
   
  function setIssuer(address _issuer) public {}
}



 
 
contract IssuedToken is Owned, Issued, StandardToken {
  function transfer(address _to, uint256 _value) public returns (bool) {
     
     
     
    if (msg.sender == issuer && (lastIssuance == 0 || block.number < lastIssuance)) {
       
      balances[_to] += _value;

       
      totalSupply += _value;

       
      return true;
    } else {
      if (freezePeriod == 0 || block.number > freezePeriod) {
         
        return super.transfer(_to, _value);
      }
    }
  }

  function transferFrom(address _from, address _to, uint256 _value)
    public
    returns (bool success) {
     
    if (freezePeriod == 0 || block.number > freezePeriod) {
       
      return super.transferFrom(_from, _to, _value);
    }
  }

  function setIssuer(address _issuer) public onlyowner() {
     
    if (issuer == address(0)) {
      issuer = _issuer;
    } else {
      throw;
    }
  }

  function IssuedToken(
    address[] _addrs,
    uint256[] _amounts,
    uint256 _freezePeriod,
    uint256 _lastIssuance,
    address _owner,
    string _name,
    uint8 _decimals,
    string _symbol) {
     
    for (uint256 i = 0; i < _addrs.length; i ++) {
       
      balances[_addrs[i]] += _amounts[i];

       
      totalSupply += _amounts[i];
    }

     
    freezePeriod = _freezePeriod;

     
    owner = _owner;

     
    lastIssuance = _lastIssuance;

     
    name = _name;

     
    decimals = _decimals;

     
    symbol = _symbol;
  }

   
  uint256 public freezePeriod;

   
  uint256 public lastIssuance;

   
  address public issuer;

   
  string public name;

   
  uint8 public decimals;

   
  string public symbol;

   
  string public version = "WFIT1.0";
}


 
 
contract PrivateServiceRegistryInterface {
   
   
   
  function register(address _service) internal returns (uint256 serviceId) {}

   
   
   
  function isService(address _service) public constant returns (bool) {}

   
   
   
  function services(uint256 _serviceId) public constant returns (address _service) {}

   
   
   
  function ids(address _service) public constant returns (uint256 serviceId) {}

  event ServiceRegistered(address _sender, address _service);
}

contract PrivateServiceRegistry is PrivateServiceRegistryInterface {

  modifier isRegisteredService(address _service) {
     
    if (services.length > 0) {
      if (services[ids[_service]] == _service && _service != address(0)) {
        _;
      }
    }
  }

  modifier isNotRegisteredService(address _service) {
     
    if (!isService(_service)) {
      _;
    }
  }

  function register(address _service)
    internal
    isNotRegisteredService(_service)
    returns (uint serviceId) {
     
    serviceId = services.length++;

     
    services[serviceId] = _service;

     
    ids[_service] = serviceId;

     
    ServiceRegistered(msg.sender, _service);
  }

  function isService(address _service)
    public
    constant
    isRegisteredService(_service)
    returns (bool) {
    return true;
  }

  address[] public services;
  mapping(address => uint256) public ids;
}

 
 
contract IssuedTokenFactory is PrivateServiceRegistry {
  function createIssuedToken(
    address[] _addrs,
    uint256[] _amounts,
    uint256 _freezePeriod,
    uint256 _lastIssuance,
    string _name,
    uint8 _decimals,
    string _symbol)
  public
  returns (address tokenAddress) {
     
    tokenAddress = address(new IssuedToken(
      _addrs,
      _amounts,
      _freezePeriod,
      _lastIssuance,
      msg.sender,
      _name,
      _decimals,
      _symbol));

     
    register(tokenAddress);
  }
}