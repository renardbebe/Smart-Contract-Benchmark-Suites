 

pragma solidity ^0.4.24;



 



 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


 
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}


 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }

}


 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

    uint256 _allowance = allowed[_from][msg.sender];

     
     

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval (address _spender, uint _addedValue)
    returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue)
    returns (bool success) {
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



 



 

contract RxEALTokenContract is StandardToken {

   

   
  string public constant name = "RxEAL";
  string public constant symbol = "RXL";
  uint256 public constant decimals = 18;

   

   
   
  uint256 public constant INITIAL_SUPPLY = 96000000 * (10 ** decimals);
   
  address public vault = this;
   
  address public salesAgent;
   
  mapping (address => bool) public owners;

   

   
  event OwnershipGranted(address indexed _owner, address indexed revoked_owner);
  event OwnershipRevoked(address indexed _owner, address indexed granted_owner);
  event SalesAgentPermissionsTransferred(address indexed previousSalesAgent, address indexed newSalesAgent);
  event SalesAgentRemoved(address indexed currentSalesAgent);
  event Burn(uint256 value);

   

   
  modifier onlyOwner() {
    require(owners[msg.sender] == true);
    _;
  }

   

   
  function RxEALTokenContract() {
    owners[msg.sender] = true;
    totalSupply = INITIAL_SUPPLY;
    balances[vault] = totalSupply;
  }

   
  function grantOwnership(address _owner) onlyOwner public {
    require(_owner != address(0));
    owners[_owner] = true;
    OwnershipGranted(msg.sender, _owner);
  }

   
  function revokeOwnership(address _owner) onlyOwner public {
    require(_owner != msg.sender);
    owners[_owner] = false;
    OwnershipRevoked(msg.sender, _owner);
  }

   
  function transferSalesAgentPermissions(address _salesAgent) onlyOwner public {
    SalesAgentPermissionsTransferred(salesAgent, _salesAgent);
    salesAgent = _salesAgent;
  }

   
  function removeSalesAgent() onlyOwner public {
    SalesAgentRemoved(salesAgent);
    salesAgent = address(0);
  }

   
  function transferTokensFromVault(address _from, address _to, uint256 _amount) public {
    require(salesAgent == msg.sender);
    balances[vault] = balances[vault].sub(_amount);
    balances[_to] = balances[_to].add(_amount);
    Transfer(_from, _to, _amount);
  }

   
  function burn(uint256 _value) onlyOwner public {
    require(_value > 0);
    balances[vault] = balances[vault].sub(_value);
    totalSupply = totalSupply.sub(_value);
    Burn(_value);
  }

}



 



contract RxEALDistributionTokens {

  address public owner;
  RxEALTokenContract internal token;

  address[] internal addresses = [
    0x2a3B2C39AE3958B875033349fd573eD14886C2Ee,
    0x2d039F29929f2560e66A4A41656CBdE3D877951D,
    0x44b12554bDB95c40fd7A58d5745c8B33ab20e7B3
  ];

  uint256[] internal values = [
    600,
    600,
    1800
  ];

  constructor() public {
    owner = msg.sender;
    token = RxEALTokenContract(0xD6682Db9106e0cfB530B697cA0EcDC8F5597CD15);
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address _newOwner) public onlyOwner {
    owner = _newOwner;
  }

  function _distribution(address[] _to, uint256[] _value) internal {
    assert(_to.length == _value.length);
    assert(_to.length <= 1000);

    for (uint8 i = 0; i < _to.length; i++) {
      uint256 _real_value = _value[i] * (10 ** token.decimals());
      token.transferTokensFromVault(msg.sender, _to[i], _real_value);
    }
  }

  function distributeTokens() public onlyOwner {
    _distribution(addresses, values);
  }

  function distributeTokens2(address[] _to, uint256[] _value) public onlyOwner {
    _distribution(_to, _value);
  }

}