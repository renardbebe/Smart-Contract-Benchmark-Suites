 

pragma solidity ^0.4.19;

 

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
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

 

contract Owned {
  event OwnerAddition(address indexed owner);

  event OwnerRemoval(address indexed owner);

   
  mapping (address => bool) public isOwner;

  address[] public owners;

  address public operator;

  modifier onlyOwner {

    require(isOwner[msg.sender]);
    _;
  }

  modifier onlyOperator {
    require(msg.sender == operator);
    _;
  }

  function setOperator(address _operator) external onlyOwner {
    require(_operator != address(0));
    operator = _operator;
  }

  function removeOwner(address _owner) public onlyOwner {
    require(owners.length > 1);
    isOwner[_owner] = false;
    for (uint i = 0; i < owners.length - 1; i++) {
      if (owners[i] == _owner) {
        owners[i] = owners[SafeMath.sub(owners.length, 1)];
        break;
      }
    }
    owners.length = SafeMath.sub(owners.length, 1);
    OwnerRemoval(_owner);
  }

  function addOwner(address _owner) external onlyOwner {
    require(_owner != address(0));
    if(isOwner[_owner]) return;
    isOwner[_owner] = true;
    owners.push(_owner);
    OwnerAddition(_owner);
  }

  function setOwners(address[] _owners) internal {
    for (uint i = 0; i < _owners.length; i++) {
      require(_owners[i] != address(0));
      isOwner[_owners[i]] = true;
      OwnerAddition(_owners[i]);
    }
    owners = _owners;
  }

  function getOwners() public constant returns (address[])  {
    return owners;
  }

}

 

 
 
pragma solidity ^0.4.19;

contract Token {
     
     
    uint256 public totalSupply;

     
     
    function balanceOf(address _owner) public constant returns (uint256 balance);

     
     
     
     
    function transfer(address _to, uint256 _value) public returns (bool success);

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

     
     
     
     
    function approve(address _spender, uint256 _value) public returns (bool success);

     
     
     
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

 

 
pragma solidity ^0.4.19;


contract StandardToken is Token {

    function transfer(address _to, uint256 _value) public returns (bool success) {
         
         
         
         
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
         
         
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value);
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}

 

contract Validating {

  modifier validAddress(address _address) {
    require(_address != address(0x0));
    _;
  }

  modifier notZero(uint _number) {
    require(_number != 0);
    _;
  }

  modifier notEmpty(string _string) {
    require(bytes(_string).length != 0);
    _;
  }

}

 

 
contract Fee is Owned, Validating, StandardToken {

   
  event Burn(address indexed from, uint256 value);

  string public name;                    
  uint8 public decimals;                 
  string public symbol;                  
  string public version = 'F0.2';        
  address public minter;

  modifier onlyMinter {
    require(msg.sender == minter);
    _;
  }

   
  function Fee(
  address[] _owners,
  string _tokenName,
  uint8 _decimalUnits,
  string _tokenSymbol
  )
  public
  notEmpty(_tokenName)
  notEmpty(_tokenSymbol)
  {
    setOwners(_owners);
    name = _tokenName;
    decimals = _decimalUnits;
    symbol = _tokenSymbol;
  }

   
   
  function setMinter(address _minter) external onlyOwner validAddress(_minter) {
    minter = _minter;
  }

   
   
  function burnTokens(uint _value) public notZero(_value) {
    require(balances[msg.sender] >= _value);
    balances[msg.sender] = SafeMath.sub(balances[msg.sender], _value);
    totalSupply = SafeMath.sub(totalSupply, _value);
    Burn(msg.sender, _value);
  }

   
   
   
   
  function sendTokens(address _to, uint _value) public onlyMinter validAddress(_to) notZero(_value) {
    balances[_to] = SafeMath.add(balances[_to], _value);
    totalSupply = SafeMath.add(totalSupply, _value);
    Transfer(0x0, _to, _value);
  }
}